import 'package:hive_flutter/hive_flutter.dart';

/// Comment model for WordPress comments

@HiveType(typeId: 3)
class Comment {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int postId;

  @HiveField(2)
  final String authorName;

  @HiveField(3)
  final String authorEmail;

  @HiveField(4)
  final String content;

  @HiveField(5)
  final DateTime date;

  @HiveField(6)
  final int? parent; // Parent comment ID (for replies)

  @HiveField(7)
  final String status; // approved, hold, spam, trash

  Comment({
    required this.id,
    required this.postId,
    required this.authorName,
    required this.authorEmail,
    required this.content,
    required this.date,
    this.parent,
    this.status = 'hold',
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      postId: json['post'] ?? 0,
      authorName: json['author_name'] ?? 'Anonymous',
      authorEmail: json['author_email'] ?? '',
      content: json['content']['rendered'] ?? json['content'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      parent: json['parent'],
      status: json['status'] ?? 'hold',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post': postId,
      'author_name': authorName,
      'author_email': authorEmail,
      'content': {'rendered': content},
      'date': date.toIso8601String(),
      'parent': parent,
      'status': status,
    };
  }

  /// Create a new comment for submission (before it has an ID)
  Map<String, dynamic> toSubmissionJson(int postId) {
    return {
      'post': postId,
      'author_name': authorName,
      'author_email': authorEmail,
      'content': content,
    };
  }

  @override
  String toString() => 'Comment(id: $id, post: $postId, author: $authorName)';
}
