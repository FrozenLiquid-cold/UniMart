# Firebase Firestore Database Setup Guide

Complete Firestore collection structure and security rules for your Campus Marketplace Flutter app.

## Table of Contents
1. [Overview](#overview)
2. [Authentication with Student ID](#authentication-with-student-id)
3. [Collections Structure](#collections-structure)
4. [Security Rules](#security-rules)
5. [Required Indexes](#required-indexes)
6. [Implementation Guide](#implementation-guide)
7. [Migration from Mock Data](#migration-from-mock-data)

---

## Overview

This app is a campus marketplace where students can:
- **Post items** for sale (Books, Electronics, Transport, Dorm items, Clothes, Others)
- **Browse marketplace** with category filters
- **Like and save** items
- **Comment** on items
- **Follow** other users
- **Chat** with sellers
- **View profiles** and user listings
- **Manage notifications**

### Key Features:
- ✅ **Student ID Authentication** (not email)
- ✅ Real-time item updates
- ✅ Like/follow functionality
- ✅ Comments system
- ✅ Messaging system
- ✅ User profiles with followers
- ✅ Notification system

---

## Authentication with Student ID

### Important: Your app uses Student ID for login, NOT email!

### Implementation Options:

#### Option 1: Firebase Custom Authentication (Recommended for Production)
1. Create a Cloud Function that:
   - Validates studentId + password
   - Queries Firestore: `users.where('studentId', '==', loginStudentId).limit(1)`
   - Verifies password hash
   - Creates custom Firebase Auth token
   - Returns token to client

2. Client-side flow:
```dart
// 1. Query user by studentId
final userQuery = await FirebaseFirestore.instance
  .collection('users')
  .where('studentId', isEqualTo: studentId)
  .limit(1)
  .get();

if (userQuery.docs.isEmpty) throw Exception('Invalid Student ID');

// 2. Verify password (use backend or hash comparison)
// 3. Get custom token from Cloud Function
// 4. Sign in with custom token
await FirebaseAuth.instance.signInWithCustomToken(customToken);
```

#### Option 2: Supabase (Easier for Custom Auth)
- Supabase supports custom authentication flows
- Query users by studentId field
- Returns JWT with user data
- Better suited for Student ID authentication

#### Option 3: Custom Backend API
- Your own authentication server
- Validates studentId + password
- Returns session token
- Map studentId to Firebase UID or use custom tokens

### User Document Structure:
```json
{
  "id": "firebase_uid_or_custom_id",
  "studentId": "STU12345",  // REQUIRED - used for login
  "email": "student@university.edu",  // Optional - for notifications only
  "name": "Student Name",
  "passwordHash": "bcrypt_hash",  // If using custom auth
  "avatar": "https://api.dicebear.com/...",
  "bio": "Engineering Student...",
  "rating": 4.8,
  "followers": 312,
  "following": ["user_id_1", "user_id_2"],
  "savedPosts": ["item_id_1", "item_id_2"],
  "university": "University Name",
  "verified": false,
  "createdAt": "2024-01-15T10:00:00Z",
  "updatedAt": "2024-01-20T14:30:00Z"
}
```

**Critical Index:** Create index on `studentId` field for fast login queries!

---

## Collections Structure

### 1. **users** Collection
Stores all user profile information.

**Document ID:** Firebase UID or custom user ID

**Document Structure:**
```json
{
  "id": "string",
  "studentId": "string (REQUIRED - UNIQUE)",
  "name": "string (REQUIRED)",
  "email": "string (optional)",
  "avatar": "string (URL)",
  "bio": "string",
  "rating": "number (double, default: 0.0)",
  "followers": "number (int, default: 0)",
  "following": ["array of user IDs"],
  "savedPosts": ["array of item IDs"],
  "university": "string",
  "verified": "boolean (default: false)",
  "passwordHash": "string (if using custom auth)",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Example:**
```json
{
  "id": "u1",
  "studentId": "STU12345",
  "name": "Sarah Chen",
  "email": "sarah@university.edu",
  "avatar": "https://api.dicebear.com/7.x/avataaars/svg?seed=Sarah",
  "bio": "Engineering Student | Tech enthusiast",
  "rating": 4.8,
  "followers": 312,
  "following": ["u2", "u3"],
  "savedPosts": ["item2", "item4"],
  "university": "State University",
  "verified": false,
  "createdAt": "2024-01-15T10:00:00Z",
  "updatedAt": "2024-01-20T14:30:00Z"
}
```

**Subcollection: notifications**
- Path: `users/{userId}/notifications/{notificationId}`
- See [Notifications](#4-notifications-collection) below

---

### 2. **items** Collection
Stores marketplace listings/posts.

**Document ID:** Auto-generated item ID

**Document Structure:**
```json
{
  "id": "string",
  "title": "string (REQUIRED)",
  "description": "string (REQUIRED)",
  "price": "number (double, REQUIRED)",
  "image": "string (URL, REQUIRED)",
  "category": "string (REQUIRED - Books|Electronics|Transport|Dorm|Clothes|Others|custom)",
  "condition": "string (Brand New|Like New|Good|Fair)",
  "sellerId": "string (REQUIRED - user ID)",
  "seller": {
    "id": "string",
    "name": "string",
    "avatar": "string (URL)",
    "rating": "number (double)",
    "followers": "number (int)"
  },
  "likes": "number (int, default: 0)",
  "likedBy": ["array of user IDs who liked"],
  "commentsCount": "number (int, default: 0)",
  "postedAt": "string (human readable, e.g., '2 hours ago')",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Example:**
```json
{
  "id": "item1",
  "title": "Engineering Textbooks Bundle",
  "description": "Complete set of first-year engineering textbooks...",
  "price": 150.0,
  "image": "https://images.unsplash.com/...",
  "category": "Books",
  "condition": "Like New",
  "sellerId": "u1",
  "seller": {
    "id": "u1",
    "name": "Sarah Chen",
    "avatar": "https://api.dicebear.com/...",
    "rating": 4.8,
    "followers": 312
  },
  "likes": 42,
  "likedBy": ["u2", "u3", "u4"],
  "commentsCount": 1,
  "postedAt": "2 hours ago",
  "createdAt": "2024-01-20T12:00:00Z",
  "updatedAt": "2024-01-20T15:30:00Z"
}
```

**Important Notes:**
- `seller` object is denormalized (stored in item) for faster reads
- When seller profile updates, use Cloud Function to update all their items
- `category` can be custom if user selects "Others" and enters custom category

**Subcollection: comments**
- Path: `items/{itemId}/comments/{commentId}`
- See [Comments](#3-comments-collection) below

---

### 3. **comments** Collection
Stores comments on items.

**Collection Path:** `items/{itemId}/comments`

**Document ID:** Auto-generated comment ID

**Document Structure:**
```json
{
  "id": "string",
  "itemId": "string",
  "userId": "string",
  "userName": "string",
  "userAvatar": "string (URL)",
  "text": "string (REQUIRED)",
  "timestamp": "string (human readable, e.g., '1 hour ago')",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Example:**
```json
{
  "id": "c1",
  "itemId": "item1",
  "userId": "u2",
  "userName": "Mike Johnson",
  "userAvatar": "https://api.dicebear.com/...",
  "text": "Are these the 2024 editions?",
  "timestamp": "1 hour ago",
  "createdAt": "2024-01-20T13:00:00Z",
  "updatedAt": "2024-01-20T13:00:00Z"
}
```

**Cloud Function:** When comment is created, increment `items/{itemId}.commentsCount`

---

### 4. **notifications** Collection
Stores user notifications.

**Collection Path:** `users/{userId}/notifications`

**Document ID:** Auto-generated notification ID

**Document Structure:**
```json
{
  "id": "string",
  "userId": "string",
  "type": "string (follow|comment|like|message|save)",
  "userName": "string",
  "userAvatar": "string (URL)",
  "text": "string",
  "itemId": "string (optional - for item-related notifications)",
  "read": "boolean (default: false)",
  "timestamp": "string (human readable)",
  "createdAt": "timestamp"
}
```

**Example:**
```json
{
  "id": "n1",
  "userId": "u1",
  "type": "follow",
  "userName": "Alex Kim",
  "userAvatar": "https://api.dicebear.com/...",
  "text": "started following you",
  "read": false,
  "timestamp": "2 hours ago",
  "createdAt": "2024-01-20T10:00:00Z"
}
```

**Cloud Functions:** Create notifications when:
- User follows another user
- User comments on your item
- User likes your item
- User saves your item
- User sends you a message

---

### 5. **chats** Collection
Stores chat conversations between users.

**Document ID:** Auto-generated chat ID (or composite like `{userId1}_{userId2}`)

**Document Structure:**
```json
{
  "id": "string",
  "participants": ["array of 2 user IDs"],
  "participantIds": ["sorted array for querying"],
  "lastMessage": {
    "text": "string",
    "senderId": "string",
    "timestamp": "timestamp"
  },
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Example:**
```json
{
  "id": "chat1",
  "participants": ["u1", "u2"],
  "participantIds": ["u1", "u2"],
  "lastMessage": {
    "text": "Hi! Is this item still available?",
    "senderId": "u1",
    "timestamp": "2024-01-20T10:30:00Z"
  },
  "createdAt": "2024-01-20T10:00:00Z",
  "updatedAt": "2024-01-20T10:30:00Z"
}
```

**Subcollection: messages**
- Path: `chats/{chatId}/messages/{messageId}`
- Document Structure:
```json
{
  "id": "string",
  "chatId": "string",
  "senderId": "string",
  "text": "string (REQUIRED)",
  "timestamp": "string (human readable)",
  "createdAt": "timestamp",
  "read": "boolean (default: false)"
}
```

**Cloud Function:** When message is created, update `chats/{chatId}.lastMessage` and `updatedAt`

---

### 6. **follows** Collection (Optional but Recommended)
Stores follow relationships for efficient querying.

**Document ID:** Composite ID like `{followerId}_{followedId}`

**Document Structure:**
```json
{
  "id": "string",
  "followerId": "string",
  "followedId": "string",
  "createdAt": "timestamp"
}
```

**Example:**
```json
{
  "id": "u1_u2",
  "followerId": "u1",
  "followedId": "u2",
  "createdAt": "2024-01-20T10:00:00Z"
}
```

**Cloud Function:** When follow is created/deleted:
1. Update `users/{followerId}.following` array
2. Update `users/{followedId}.followers` count
3. Create notification for followed user

**Alternative:** Store `following` and `followers` arrays directly in user documents (simpler but less scalable)

---

## Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isValidUser(userId) {
      return isAuthenticated() && 
             request.resource.data.keys().hasAll(['id', 'name', 'studentId']) &&
             request.resource.data.id == userId &&
             request.resource.data.id == request.auth.uid &&
             request.resource.data.studentId is string &&
             request.resource.data.studentId.size() > 0;
    }
    
    function onlyFieldsChanged(fields) {
      let changedFields = request.resource.data.diff(resource.data).affectedKeys();
      return changedFields.hasOnly(fields);
    }
    
    // Users collection
    match /users/{userId} {
      // Anyone authenticated can read user profiles
      allow read: if isAuthenticated();
      
      // Users can create their own profile with valid studentId
      allow create: if isValidUser(userId);
      
      // Users can update their own profile
      // Allow updating following/savedPosts arrays
      allow update: if isOwner(userId) &&
                     request.resource.data.id == userId &&
                     (request.resource.data.studentId == resource.data.studentId || !request.resource.data.diff(resource.data).affectedKeys().hasAny(['studentId']));
      
      // Users can delete their own profile
      allow delete: if isOwner(userId);
      
      // Notifications subcollection
      match /notifications/{notificationId} {
        // Users can only read their own notifications
        allow read: if isOwner(userId);
        
        // System creates notifications (via Cloud Functions)
        // Allow authenticated users to create (for testing, restrict in production)
        allow create: if isAuthenticated();
        
        // Users can update their own notifications (mark as read)
        allow update: if isOwner(userId) &&
                       onlyFieldsChanged(['read']);
        
        // Users can delete their own notifications
        allow delete: if isOwner(userId);
      }
    }
    
    // Items collection
    match /items/{itemId} {
      // Anyone authenticated can read items
      allow read: if isAuthenticated();
      
      // Only authenticated users can create items
      allow create: if isAuthenticated() &&
                     request.resource.data.sellerId == request.auth.uid &&
                     request.resource.data.keys().hasAll([
                       'title', 'description', 'price', 'category', 
                       'condition', 'sellerId', 'seller', 'image'
                     ]) &&
                     request.resource.data.likes == 0 &&
                     request.resource.data.commentsCount == 0;
      
      // Item owner can update their own items
      // Anyone can update likes/commentsCount (using transactions)
      allow update: if isAuthenticated() && (
        resource.data.sellerId == request.auth.uid ||
        onlyFieldsChanged(['likes', 'likedBy', 'commentsCount'])
      );
      
      // Item owner can delete their own items
      allow delete: if isAuthenticated() &&
                     resource.data.sellerId == request.auth.uid;
      
      // Comments subcollection
      match /comments/{commentId} {
        // Anyone authenticated can read comments
        allow read: if isAuthenticated();
        
        // Anyone authenticated can create comments
        allow create: if isAuthenticated() &&
                       request.resource.data.userId == request.auth.uid &&
                       request.resource.data.itemId == itemId;
        
        // Comment owner can update their own comments
        allow update: if isAuthenticated() &&
                       resource.data.userId == request.auth.uid;
        
        // Comment owner can delete their own comments
        allow delete: if isAuthenticated() &&
                       resource.data.userId == request.auth.uid;
      }
    }
    
    // Chats collection
    match /chats/{chatId} {
      // Users can read chats they're part of
      allow read: if isAuthenticated() &&
                   request.auth.uid in resource.data.participants;
      
      // Users can create chats they're part of
      allow create: if isAuthenticated() &&
                     request.auth.uid in request.resource.data.participants &&
                     request.resource.data.participants.size() == 2;
      
      // Users can update chats they're part of
      allow update: if isAuthenticated() &&
                     request.auth.uid in resource.data.participants;
      
      // Messages subcollection
      match /messages/{messageId} {
        // Users can read messages in chats they're part of
        allow read: if isAuthenticated() &&
                     request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
        
        // Users can create messages in chats they're part of
        allow create: if isAuthenticated() &&
                       request.resource.data.senderId == request.auth.uid &&
                       request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
        
        // Users can update their own messages (for read receipts)
        allow update: if isAuthenticated() &&
                       resource.data.senderId == request.auth.uid &&
                       onlyFieldsChanged(['read']);
      }
    }
    
    // Follows collection (if using separate collection)
    match /follows/{followId} {
      // Users can read follows
      allow read: if isAuthenticated();
      
      // Users can create their own follow relationships
      allow create: if isAuthenticated() &&
                     request.resource.data.followerId == request.auth.uid &&
                     request.resource.data.followerId != request.resource.data.followedId;
      
      // Users can delete their own follow relationships
      allow delete: if isAuthenticated() &&
                     resource.data.followerId == request.auth.uid;
    }
  }
}
```

---

## Required Indexes

Create these composite indexes in Firestore Console:

### 1. **users** collection:
- `studentId` (Ascending) - **REQUIRED for login queries**
- `followers` (Descending)
- `rating` (Descending)

### 2. **items** collection:
- `category` (Ascending) + `createdAt` (Descending) - For category filtering
- `sellerId` (Ascending) + `createdAt` (Descending) - For user's items
- `createdAt` (Descending) - For newest items
- `likes` (Descending) - For most liked items
- `price` (Ascending) + `category` (Ascending) - For price range queries

### 3. **notifications** subcollection:
- `userId` (Ascending) + `createdAt` (Descending) - Collection group query
- `userId` (Ascending) + `read` (Ascending) + `createdAt` (Descending) - Unread notifications

### 4. **chats** collection:
- `participants` (Array) + `updatedAt` (Descending) - For user's chats

### 5. **comments** subcollection:
- `itemId` (Ascending) + `createdAt` (Ascending) - Collection group query

### 6. **follows** collection:
- `followerId` (Ascending) + `createdAt` (Descending)
- `followedId` (Ascending) + `createdAt` (Descending)

---

## Implementation Guide

### 1. **Student ID Authentication**

```dart
// Login with Student ID
Future<void> loginWithStudentId(String studentId, String password) async {
  // Option 1: Query Firestore and use Custom Token
  final userQuery = await FirebaseFirestore.instance
    .collection('users')
    .where('studentId', isEqualTo: studentId)
    .limit(1)
    .get();

  if (userQuery.docs.isEmpty) {
    throw Exception('Invalid Student ID');
  }

  final userDoc = userQuery.docs.first;
  final userData = userDoc.data();
  
  // Verify password (use secure hash comparison)
  final isValidPassword = await verifyPassword(password, userData['passwordHash']);
  if (!isValidPassword) {
    throw Exception('Invalid password');
  }

  // Get custom token from Cloud Function
  final customToken = await getCustomToken(userDoc.id);
  
  // Sign in with custom token
  final credential = await FirebaseAuth.instance.signInWithCustomToken(customToken);
  
  // Store user data
  await AuthService.setSession(credential.user!.uid, userData);
}
```

### 2. **Real-time Item Updates**

```dart
// Listen to items collection
StreamSubscription<List<Item>> listenToItems() {
  return FirebaseFirestore.instance
    .collection('items')
    .orderBy('createdAt', descending: true)
    .snapshots()
    .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Item.fromFirestore(data);
      }).toList();
    }).listen((items) {
      // Update ItemStore
      ItemStore.instance.updateItems(items);
    });
}
```

### 3. **Like Functionality**

```dart
Future<void> toggleLike(String itemId, String userId) async {
  final itemRef = FirebaseFirestore.instance.collection('items').doc(itemId);
  
  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final itemDoc = await transaction.get(itemRef);
    if (!itemDoc.exists) return;

    final data = itemDoc.data()!;
    final likedBy = List<String>.from(data['likedBy'] ?? []);
    final isLiked = likedBy.contains(userId);
    
    if (isLiked) {
      likedBy.remove(userId);
      transaction.update(itemRef, {
        'likes': (data['likes'] ?? 0) - 1,
        'likedBy': likedBy,
      });
    } else {
      likedBy.add(userId);
      transaction.update(itemRef, {
        'likes': (data['likes'] ?? 0) + 1,
        'likedBy': likedBy,
      });
      
      // Create notification (via Cloud Function or client)
      await createLikeNotification(
        itemId: itemId,
        itemOwnerId: data['sellerId'],
        likerId: userId,
      );
    }
  });
}
```

### 4. **Follow Functionality**

```dart
Future<void> toggleFollow(String followerId, String followedId) async {
  final followId = '${followerId}_${followedId}';
  final followRef = FirebaseFirestore.instance.collection('follows').doc(followId);
  final followerRef = FirebaseFirestore.instance.collection('users').doc(followerId);
  final followedRef = FirebaseFirestore.instance.collection('users').doc(followedId);
  
  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final followDoc = await transaction.get(followRef);
    final followedDoc = await transaction.get(followedRef);
    final followerDoc = await transaction.get(followerRef);
    
    if (!followDoc.exists) {
      // Follow
      transaction.set(followRef, {
        'id': followId,
        'followerId': followerId,
        'followedId': followedId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Update follower's following array
      final following = List<String>.from(followerDoc.data()!['following'] ?? []);
      following.add(followedId);
      transaction.update(followerRef, {'following': following});
      
      // Update followed's followers count
      transaction.update(followedRef, {
        'followers': (followedDoc.data()!['followers'] ?? 0) + 1,
      });
      
      // Create notification
      await createFollowNotification(followerId: followerId, followedId: followedId);
    } else {
      // Unfollow
      transaction.delete(followRef);
      
      // Update arrays
      final following = List<String>.from(followerDoc.data()!['following'] ?? []);
      following.remove(followedId);
      transaction.update(followerRef, {'following': following});
      
      transaction.update(followedRef, {
        'followers': (followedDoc.data()!['followers'] ?? 0) - 1,
      });
    }
  });
}
```

### 5. **Create New Item**

```dart
Future<String> createItem(Item item) async {
  final user = AuthService.getUser();
  final sellerId = user!['id'] as String;
  
  final itemRef = FirebaseFirestore.instance.collection('items').doc();
  
  final itemData = {
    'id': itemRef.id,
    'title': item.title,
    'description': item.description,
    'price': item.price,
    'image': item.image,
    'category': item.category,
    'condition': item.condition,
    'sellerId': sellerId,
    'seller': {
      'id': sellerId,
      'name': user['name'],
      'avatar': user['avatar'] ?? '',
      'rating': user['rating'] ?? 0.0,
      'followers': user['followers'] ?? 0,
    },
    'likes': 0,
    'likedBy': [],
    'commentsCount': 0,
    'postedAt': formatTimestamp(DateTime.now()),
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
  
  await itemRef.set(itemData);
  
  // Update user's followers count (when they post)
  await FirebaseFirestore.instance
    .collection('users')
    .doc(sellerId)
    .update({
      'followers': FieldValue.increment(1),
    });
  
  return itemRef.id;
}
```

### 6. **Add Comment**

```dart
Future<void> addComment(String itemId, String text) async {
  final user = AuthService.getUser();
  final userId = user!['id'] as String;
  
  final commentRef = FirebaseFirestore.instance
    .collection('items')
    .doc(itemId)
    .collection('comments')
    .doc();
  
  final itemRef = FirebaseFirestore.instance.collection('items').doc(itemId);
  
  await FirebaseFirestore.instance.runTransaction((transaction) async {
    // Add comment
    transaction.set(commentRef, {
      'id': commentRef.id,
      'itemId': itemId,
      'userId': userId,
      'userName': user['name'],
      'userAvatar': user['avatar'] ?? '',
      'text': text,
      'timestamp': formatTimestamp(DateTime.now()),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Increment comments count
    transaction.update(itemRef, {
      'commentsCount': FieldValue.increment(1),
    });
  });
  
  // Create notification (via Cloud Function)
  final itemDoc = await itemRef.get();
  final itemOwnerId = itemDoc.data()!['sellerId'];
  await createCommentNotification(
    itemId: itemId,
    itemOwnerId: itemOwnerId,
    commenterId: userId,
  );
}
```

---

## Migration from Mock Data

### Step 1: Set up Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create new project
3. Enable Firestore Database (Start in production mode)
4. Copy security rules from above
5. Create all required indexes

### Step 2: Import Users
```dart
// Convert mock users to Firestore
for (final mockItem in mockItems) {
  final seller = mockItem.seller;
  
  // Check if user exists
  final userQuery = await FirebaseFirestore.instance
    .collection('users')
    .where('id', isEqualTo: seller.id)
    .limit(1)
    .get();
  
  if (userQuery.docs.isEmpty) {
    await FirebaseFirestore.instance.collection('users').doc(seller.id).set({
      'id': seller.id,
      'studentId': 'STU${seller.id}', // Generate student ID
      'name': seller.name,
      'avatar': seller.avatar,
      'rating': seller.rating,
      'followers': seller.followers,
      'following': [],
      'savedPosts': [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
```

### Step 3: Import Items
```dart
for (final mockItem in mockItems) {
  await FirebaseFirestore.instance.collection('items').doc(mockItem.id).set({
    'id': mockItem.id,
    'title': mockItem.title,
    'description': mockItem.description,
    'price': mockItem.price,
    'image': mockItem.image,
    'category': mockItem.category,
    'condition': mockItem.condition,
    'sellerId': mockItem.seller.id,
    'seller': {
      'id': mockItem.seller.id,
      'name': mockItem.seller.name,
      'avatar': mockItem.seller.avatar,
      'rating': mockItem.seller.rating,
      'followers': mockItem.seller.followers,
    },
    'likes': mockItem.likes,
    'likedBy': [], // Initialize empty, update later
    'commentsCount': mockItem.comments.length,
    'postedAt': mockItem.postedAt,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
  
  // Import comments
  for (final comment in mockItem.comments) {
    await FirebaseFirestore.instance
      .collection('items')
      .doc(mockItem.id)
      .collection('comments')
      .doc(comment.id)
      .set({
        'id': comment.id,
        'itemId': mockItem.id,
        'userId': comment.userId,
        'userName': comment.userName,
        'userAvatar': comment.userAvatar,
        'text': comment.text,
        'timestamp': comment.timestamp,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
  }
}
```

### Step 4: Set up Cloud Functions
Create Cloud Functions for:
1. **Update seller data** across all items when profile changes
2. **Create notifications** automatically
3. **Update follower counts** when follows change
4. **Generate custom auth tokens** for Student ID login
5. **Format timestamps** (e.g., "2 hours ago")

---

## Next Steps

1. ✅ Set up Firebase project
2. ✅ Enable Firestore Database
3. ✅ Copy security rules
4. ✅ Create required indexes
5. ✅ Set up authentication (Student ID)
6. ✅ Create Cloud Functions
7. ✅ Update Flutter app to use Firestore
8. ✅ Test all functionality
9. ✅ Deploy to production

---

## Important Notes

- **Student ID must be unique** - Add unique constraint in backend
- **Password hashing** - Use bcrypt or Argon2, never store plain passwords
- **Denormalization** - Seller data is stored in items for performance
- **Transactions** - Use for atomic updates (likes, follows, comments)
- **Indexes** - Create before querying, otherwise you'll get errors
- **Security** - Test rules thoroughly, especially Student ID authentication
- **Scalability** - Consider pagination for large collections

---

For questions or issues, refer to:
- [Firebase Documentation](https://firebase.google.com/docs)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Cloud Functions](https://firebase.google.com/docs/functions)
