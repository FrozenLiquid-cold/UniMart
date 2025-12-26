import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/item.dart';
import '../services/auth_service.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Convert Firestore document to Item model
  static Item _itemFromFirestore(Map<String, dynamic> data, String docId) {
    final Object? rawSeller = data['seller'];
    final Map<String, dynamic> sellerData = rawSeller is Map<String, dynamic>
        ? rawSeller
        : <String, dynamic>{};
    final likedBy = List<String>.from(data['likedBy'] ?? []);
    final commentsCount = (data['commentsCount'] as int?) ?? 0;
    final currentUserId = AuthService.getUser()?['id'] as String?;
    final Object? createdAtField = data['createdAt'];
    final Timestamp? createdAtTs = createdAtField is Timestamp
        ? createdAtField
        : null;
    final String postedAt = createdAtTs != null
        ? _formatTimestamp(createdAtTs.toDate())
        : (data['postedAt'] as String? ?? '');

    return Item(
      id: data['id'] as String? ?? docId,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      image: data['image'] as String? ?? '',
      category: data['category'] as String? ?? '',
      condition: data['condition'] as String? ?? '',
      postedAt: postedAt,
      seller: Seller(
        id: sellerData['id'] as String? ?? '',
        name: sellerData['name'] as String? ?? '',
        avatar: sellerData['avatar'] as String? ?? '',
        rating: (sellerData['rating'] as num?)?.toDouble() ?? 0.0,
        isFollowing: false, // Will be updated separately if needed
        followers: (sellerData['followers'] as int?) ?? 0,
      ),
      saved: false, // Will be checked separately
      comments: const [], // Loaded separately via comments subcollection
      commentsCount: commentsCount,
      likes: (data['likes'] as int?) ?? 0,
      likedByMe: currentUserId != null && likedBy.contains(currentUserId),
    );
  }

  /// Convert Item model to Firestore document
  static Map<String, dynamic> _itemToFirestore(Item item) {
    return {
      'id': item.id,
      'title': item.title,
      'description': item.description,
      'price': item.price,
      'image': item.image,
      'category': item.category,
      'condition': item.condition,
      'sellerId': item.seller.id,
      'seller': {
        'id': item.seller.id,
        'name': item.seller.name,
        'avatar': item.seller.avatar,
        'rating': item.seller.rating,
        'followers': item.seller.followers,
      },
      'likes': item.likes,
      'likedBy': [], // Managed separately in transactions
      'commentsCount': item.commentsCount,
      'postedAt': item.postedAt,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Get all items stream (real-time)
  static Stream<List<Item>> getItemsStream() {
    return _firestore
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs.map((
            QueryDocumentSnapshot<Map<String, dynamic>> doc,
          ) {
            final data = doc.data();
            return _itemFromFirestore(data, doc.id);
          }).toList();
        });
  }

  /// Get items by category
  static Stream<List<Item>> getItemsByCategoryStream(String category) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('items')
        .orderBy('createdAt', descending: true);

    if (category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      return snapshot.docs.map((
        QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) {
        final data = doc.data();
        return _itemFromFirestore(data, doc.id);
      }).toList();
    });
  }

  /// Get items by seller
  static Stream<List<Item>> getItemsBySellerStream(String sellerId) {
    return _firestore
        .collection('items')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs.map((
            QueryDocumentSnapshot<Map<String, dynamic>> doc,
          ) {
            final data = doc.data();
            return _itemFromFirestore(data, doc.id);
          }).toList();
        });
  }

  /// Create new item
  static Future<String> createItem(Item item) async {
    try {
      final user = AuthService.getUser();
      if (user == null) throw Exception('User not authenticated');

      final itemRef = _firestore.collection('items').doc();
      final itemData = _itemToFirestore(item);
      itemData['id'] = itemRef.id;
      itemData['sellerId'] = user['id'] as String;

      // Update seller info in item
      itemData['seller'] = {
        'id': user['id'] as String,
        'name': user['name'] as String? ?? '',
        'avatar': user['avatar'] as String? ?? '',
        'rating': (user['rating'] as num?)?.toDouble() ?? 0.0,
        'followers': (user['followers'] as int?) ?? 0,
      };

      await itemRef.set(itemData);

      return itemRef.id;
    } catch (e) {
      throw Exception('Failed to create item: $e');
    }
  }

  /// Update item
  static Future<void> updateItem(Item item) async {
    try {
      final itemData = _itemToFirestore(item);
      itemData['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('items').doc(item.id).update(itemData);
    } catch (e) {
      throw Exception('Failed to update item: $e');
    }
  }

  /// Delete item
  static Future<void> deleteItem(String itemId) async {
    try {
      await _firestore.collection('items').doc(itemId).delete();
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  /// Toggle like on item
  static Future<void> toggleLike(String itemId, String userId) async {
    try {
      final itemRef = _firestore.collection('items').doc(itemId);

      await _firestore.runTransaction((transaction) async {
        final itemDoc = await transaction.get(itemRef);
        if (!itemDoc.exists) {
          throw Exception('Item not found');
        }

        final data = itemDoc.data();
        if (data == null) {
          throw Exception('Item data not found');
        }
        final likedBy = List<String>.from(data['likedBy'] ?? []);
        final isLiked = likedBy.contains(userId);
        final currentLikes = (data['likes'] as int?) ?? 0;
        final sellerId = data['sellerId'] as String;

        if (isLiked) {
          likedBy.remove(userId);
          transaction.update(itemRef, {
            'likes': currentLikes - 1,
            'likedBy': likedBy,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          likedBy.add(userId);
          transaction.update(itemRef, {
            'likes': currentLikes + 1,
            'likedBy': likedBy,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Create notification if not liking own item
          if (sellerId != userId) {
            _createLikeNotification(itemId, sellerId, userId);
          }
        }
      });
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  /// Create like notification (async)
  static void _createLikeNotification(
    String itemId,
    String itemOwnerId,
    String likerId,
  ) async {
    try {
      final likerDoc = await _firestore.collection('users').doc(likerId).get();
      final likerData = likerDoc.data() ?? {};

      await _firestore
          .collection('users')
          .doc(itemOwnerId)
          .collection('notifications')
          .add({
            'userId': itemOwnerId,
            'fromUserId': likerId,
            'type': 'like',
            'userName': likerData['name'] as String? ?? 'Someone',
            'userAvatar': likerData['avatar'] as String? ?? '',
            'text': 'liked your item',
            'itemId': itemId,
            'read': false,
            'timestamp': _formatTimestamp(DateTime.now()),
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      // Silently fail - notifications are not critical
      debugPrint('Failed to create notification: $e');
    }
  }

  /// Format timestamp to human readable
  static String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  /// Get comments for an item
  static Stream<List<Comment>> getCommentsStream(String itemId) {
    return _firestore
        .collection('items')
        .doc(itemId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs.map((
            QueryDocumentSnapshot<Map<String, dynamic>> doc,
          ) {
            final data = doc.data();
            final Object? createdAtField = data['createdAt'];
            final Timestamp? createdAt = createdAtField is Timestamp
                ? createdAtField
                : null;
            final String timestamp = createdAt != null
                ? _formatTimestamp(createdAt.toDate())
                : (data['timestamp'] as String? ?? '');
            return Comment(
              id: data['id'] as String? ?? doc.id,
              userId: data['userId'] as String? ?? '',
              userName: data['userName'] as String? ?? '',
              userAvatar: data['userAvatar'] as String? ?? '',
              text: data['text'] as String? ?? '',
              timestamp: timestamp,
            );
          }).toList();
        });
  }

  /// Add comment to item
  static Future<void> addComment(String itemId, String text) async {
    try {
      final user = AuthService.getUser();
      if (user == null) throw Exception('User not authenticated');

      final commentRef = _firestore
          .collection('items')
          .doc(itemId)
          .collection('comments')
          .doc();

      final itemRef = _firestore.collection('items').doc(itemId);

      await _firestore.runTransaction((transaction) async {
        // Add comment
        transaction.set(commentRef, {
          'id': commentRef.id,
          'itemId': itemId,
          'userId': user['id'] as String,
          'userName': user['name'] as String? ?? '',
          'userAvatar': user['avatar'] as String? ?? '',
          'text': text,
          'timestamp': _formatTimestamp(DateTime.now()),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Increment comments count
        transaction.update(itemRef, {
          'commentsCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Create notification
      final itemDoc = await itemRef.get();
      final itemData = itemDoc.data();
      final itemOwnerId = itemData?['sellerId'] as String?;

      if (itemOwnerId != null && itemOwnerId != user['id']) {
        await _firestore
            .collection('users')
            .doc(itemOwnerId)
            .collection('notifications')
            .add({
              'userId': itemOwnerId,
              'fromUserId': user['id'] as String,
              'type': 'comment',
              'userName': user['name'] as String? ?? 'Someone',
              'userAvatar': user['avatar'] as String? ?? '',
              'text': 'commented on your post',
              'itemId': itemId,
              'read': false,
              'timestamp': _formatTimestamp(DateTime.now()),
              'createdAt': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Build stable chat ID for two users
  static String _chatIdForUsers(String userId1, String userId2) {
    if (userId1 == userId2) {
      return userId1;
    }
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Stream chat messages between two users (ordered oldest first)
  static Stream<List<ChatMessage>> getChatMessagesStream(
    String currentUserId,
    String otherUserId,
  ) {
    final chatId = _chatIdForUsers(currentUserId, otherUserId);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs.map((
            QueryDocumentSnapshot<Map<String, dynamic>> doc,
          ) {
            final data = doc.data();
            final senderId = data['senderId'] as String? ?? '';
            final Object? createdAtField = data['createdAt'];
            final Timestamp? createdAt = createdAtField is Timestamp
                ? createdAtField
                : null;
            final String timestamp = createdAt != null
                ? _formatTimestamp(createdAt.toDate())
                : (data['timestamp'] as String? ?? '');
            return ChatMessage(
              id: data['id'] as String? ?? doc.id,
              text: data['text'] as String? ?? '',
              isOwn: senderId == currentUserId,
              timestamp: timestamp,
            );
          }).toList();
        });
  }

  /// Send chat message between two users
  static Future<void> sendChatMessage(
    String senderId,
    String receiverId,
    String text,
  ) async {
    if (senderId == receiverId) {
      throw Exception('Cannot message yourself');
    }
    if (text.trim().isEmpty) {
      return;
    }

    try {
      final chatId = _chatIdForUsers(senderId, receiverId);
      final chatRef = _firestore.collection('chats').doc(chatId);
      final messageRef = chatRef.collection('messages').doc();
      final now = DateTime.now();

      await _firestore.runTransaction((transaction) async {
        transaction.set(messageRef, {
          'id': messageRef.id,
          'chatId': chatId,
          'senderId': senderId,
          'receiverId': receiverId,
          'text': text,
          'timestamp': _formatTimestamp(now),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.set(chatRef, {
          'id': chatId,
          'participants': [senderId, receiverId],
          'lastMessage': text,
          'lastTimestamp': _formatTimestamp(now),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get chats for a user (recent first)
  static Stream<List<Map<String, dynamic>>> getUserChatsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final Object? updatedAtField = data['updatedAt'];
            final Timestamp? updatedAt = updatedAtField is Timestamp
                ? updatedAtField
                : null;
            final String lastTimestamp = updatedAt != null
                ? _formatTimestamp(updatedAt.toDate())
                : (data['lastTimestamp'] as String? ?? '');

            return {'id': doc.id, ...data, 'lastTimestamp': lastTimestamp};
          }).toList();
        });
  }

  /// Get a single item by id
  static Future<Item?> getItemById(String itemId) async {
    try {
      final doc = await _firestore.collection('items').doc(itemId).get();
      final data = doc.data();
      if (data == null) return null;
      return _itemFromFirestore(data, doc.id);
    } catch (e) {
      return null;
    }
  }

  /// Get seller model for a user id
  static Future<Seller?> getSellerById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      if (data == null) {
        return null;
      }
      return Seller(
        id: userId,
        name: data['name'] as String? ?? '',
        avatar: data['avatar'] as String? ?? '',
        rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
        isFollowing: false,
        followers: (data['followers'] as int?) ?? 0,
      );
    } catch (e) {
      return null;
    }
  }

  /// Toggle follow relationship
  static Future<void> toggleFollow(String followerId, String followedId) async {
    // Always use the authenticated Firebase UID as the follower id so it
    // matches request.auth.uid in security rules.
    final String? authUid = AuthService.getToken();
    final String effectiveFollowerId = authUid ?? followerId;

    if (effectiveFollowerId == followedId) {
      throw Exception('Cannot follow yourself');
    }

    try {
      final followId = '${effectiveFollowerId}_$followedId';
      final followRef = _firestore.collection('follows').doc(followId);
      bool created = false;

      await _firestore.runTransaction((transaction) async {
        final followDoc = await transaction.get(followRef);

        if (!followDoc.exists) {
          created = true;
          transaction.set(followRef, {
            'id': followId,
            'followerId': effectiveFollowerId,
            'followedId': followedId,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Unfollow
          transaction.delete(followRef);
        }
      });

      // Create notification only when a new follow is created
      if (created) {
        final followerDoc = await _firestore
            .collection('users')
            .doc(effectiveFollowerId)
            .get();
        final followerData = followerDoc.data() ?? {};
        await _firestore
            .collection('users')
            .doc(followedId)
            .collection('notifications')
            .add({
              'userId': followedId,
              'fromUserId': effectiveFollowerId,
              'type': 'follow',
              'userName': followerData['name'] as String? ?? 'Someone',
              'userAvatar': followerData['avatar'] as String? ?? '',
              'text': 'started following you',
              'read': false,
              'timestamp': _formatTimestamp(DateTime.now()),
              'createdAt': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      debugPrint('toggleFollow failed: $e');
      throw Exception('Failed to toggle follow: $e');
    }
  }

  /// Check if user is following another user
  static Future<bool> isFollowing(String followerId, String followedId) async {
    try {
      final followId = '${followerId}_$followedId';
      final followDoc = await _firestore
          .collection('follows')
          .doc(followId)
          .get();
      return followDoc.exists;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, String>>> _getUserSummariesByIds(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return [];

    final List<Map<String, String>> results = [];
    const int batchSize = 10;

    for (var i = 0; i < userIds.length; i += batchSize) {
      final batch = userIds.sublist(
        i,
        i + batchSize > userIds.length ? userIds.length : i + batchSize,
      );

      final snapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final studentId = data['studentId'] as String? ?? '';
        results.add({
          'id': doc.id,
          'name': data['name'] as String? ?? '',
          'username': studentId.isNotEmpty ? '@$studentId' : '',
          'avatar': data['avatar'] as String? ?? '',
        });
      }
    }

    return results;
  }

  static Future<List<Map<String, String>>> getFollowersList(
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('follows')
          .where('followedId', isEqualTo: userId)
          .get();

      final followerIds = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return data['followerId'] as String? ?? '';
          })
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      return _getUserSummariesByIds(followerIds);
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, String>>> getFollowingList(
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: userId)
          .get();

      final followedIds = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return data['followedId'] as String? ?? '';
          })
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      return _getUserSummariesByIds(followedIds);
    } catch (e) {
      return [];
    }
  }

  /// Get user's saved posts
  static Future<List<String>> getSavedPosts(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data();
      return List<String>.from(data?['savedPosts'] ?? []);
    } catch (e) {
      return [];
    }
  }

  /// Toggle save post
  static Future<void> toggleSavePost(String userId, String itemId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();
      final savedPosts = List<String>.from(userDoc.data()?['savedPosts'] ?? []);
      final bool wasSaved = savedPosts.contains(itemId);

      if (wasSaved) {
        savedPosts.remove(itemId);
      } else {
        savedPosts.add(itemId);
      }

      await userRef.update({
        'savedPosts': savedPosts,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Keep in-memory session user in sync so UI can read savedPosts immediately
      final sessionUser = AuthService.getUser();
      final String? token = AuthService.getToken();
      if (sessionUser != null && token != null) {
        final Map<String, dynamic> updatedUser = Map<String, dynamic>.from(
          sessionUser,
        );
        updatedUser['savedPosts'] = savedPosts;
        await AuthService.setSession(token, updatedUser);
      }
    } catch (e) {
      throw Exception('Failed to toggle save: $e');
    }
  }

  /// Stream notifications for a user (most recent first)
  static Stream<List<NotificationItem>> getUserNotificationsStream(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final Object? createdAtField = data['createdAt'];
            final Timestamp? createdAt = createdAtField is Timestamp
                ? createdAtField
                : null;
            final String timestamp = createdAt != null
                ? _formatTimestamp(createdAt.toDate())
                : (data['timestamp'] as String? ?? '');

            return NotificationItem(
              id: data['id'] as String? ?? doc.id,
              type: data['type'] as String? ?? 'other',
              userName: data['userName'] as String? ?? 'Someone',
              userAvatar: data['userAvatar'] as String? ?? '',
              text: data['text'] as String? ?? '',
              timestamp: timestamp,
              read: data['read'] as bool? ?? false,
              itemId: data['itemId'] as String?,
              fromUserId: data['fromUserId'] as String?,
            );
          }).toList();
        });
  }

  /// Mark a single notification as read
  static Future<void> markNotificationRead(
    String userId,
    String notificationId,
  ) async {
    try {
      final notifRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId);
      // Security rules only allow updating the 'read' field on notifications.
      await notifRef.update(<String, dynamic>{'read': true});
    } catch (e) {
      // Non-critical; ignore failures
      debugPrint('markNotificationRead failed: $e');
    }
  }
}
