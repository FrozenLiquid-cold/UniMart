class Post {
  final String id;
  final String title;
  final String description;
  final double price;
  final String category;
  final String type; // 'item' or 'skill'
  final List<String> images;
  final List<String> tags;
  final String userId;
  final DateTime createdAt;
  final User? user;

  Post({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.type,
    required this.images,
    required this.tags,
    required this.userId,
    required this.createdAt,
    this.user,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      type: json['type'] ?? 'item',
      images: List<String>.from(json['images'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      userId: json['userId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}

class User {
  final String id;
  final String name;
  final String? email;
  final String? studentId;
  final String? university;
  final bool verified;
  final String? bio;
  final List<String>? followers;
  final List<String>? following;
  final List<String>? savedPosts;

  User({
    required this.id,
    required this.name,
    this.email,
    this.studentId,
    this.university,
    this.verified = false,
    this.bio,
    this.followers,
    this.following,
    this.savedPosts,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      studentId: json['studentId'],
      university: json['university'],
      verified: json['verified'] ?? false,
      bio: json['bio'],
      followers: json['followers'] != null
          ? List<String>.from(json['followers'])
          : null,
      following: json['following'] != null
          ? List<String>.from(json['following'])
          : null,
      savedPosts: json['savedPosts'] != null
          ? List<String>.from(json['savedPosts'])
          : null,
    );
  }
}

