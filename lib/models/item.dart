class Seller {
  final String id;
  final String name;
  final String avatar;
  final double rating;
  final bool isFollowing;
  final int followers;

  const Seller({
    required this.id,
    required this.name,
    required this.avatar,
    required this.rating,
    required this.isFollowing,
    this.followers = 0,
  });

  Seller copyWith({
    String? id,
    String? name,
    String? avatar,
    double? rating,
    bool? isFollowing,
    int? followers,
  }) {
    return Seller(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      rating: rating ?? this.rating,
      isFollowing: isFollowing ?? this.isFollowing,
      followers: followers ?? this.followers,
    );
  }
}

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String text;
  final String timestamp;

  const Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.text,
    required this.timestamp,
  });
}

class Item {
  final String id;
  final String title;
  final String description;
  final double price;
  final String image;
  final String category;
  final String condition;
  final String postedAt;
  final Seller seller;
  final bool saved;
  final List<Comment> comments;
  final int commentsCount;
  final int likes;
  final bool likedByMe;

  const Item({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.image,
    required this.category,
    required this.condition,
    required this.postedAt,
    required this.seller,
    this.saved = false,
    this.comments = const [],
    this.commentsCount = 0,
    this.likes = 0,
    this.likedByMe = false,
  });

  Item copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? image,
    String? category,
    String? condition,
    String? postedAt,
    Seller? seller,
    bool? saved,
    List<Comment>? comments,
    int? commentsCount,
    int? likes,
    bool? likedByMe,
  }) {
    return Item(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      image: image ?? this.image,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      postedAt: postedAt ?? this.postedAt,
      seller: seller ?? this.seller,
      saved: saved ?? this.saved,
      comments: comments ?? this.comments,
      commentsCount: commentsCount ?? this.commentsCount,
      likes: likes ?? this.likes,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }
}

class NotificationItem {
  final String id;
  final String type;
  final String userName;
  final String userAvatar;
  final String text;
  final String timestamp;
  final bool read;
  final String? itemId;
  final String? fromUserId;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.userName,
    required this.userAvatar,
    required this.text,
    required this.timestamp,
    this.read = false,
    this.itemId,
    this.fromUserId,
  });
}

class ChatMessage {
  final String id;
  final String text;
  final bool isOwn;
  final String timestamp;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isOwn,
    required this.timestamp,
  });
}
