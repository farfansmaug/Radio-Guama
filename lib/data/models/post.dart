import 'package:hive_flutter/hive_flutter.dart';

/// Post model for WordPress posts
part 'post.g.dart';

@HiveType(typeId: 1)
class Post {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String content;

  @HiveField(4)
  final String? excerpt;

  @HiveField(5)
  final String? featuredImageUrl;

  @HiveField(6)
  final List<int> categories; // Category IDs

  @HiveField(7)
  final String slug;

  @HiveField(8)
  final String link;

  @HiveField(9)
  final int? author;

  @HiveField(10)
  final bool commentStatusOpen;

  @HiveField(11)
  final DateTime? modified;

  Post({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    this.excerpt,
    this.featuredImageUrl,
    required this.categories,
    required this.slug,
    required this.link,
    this.author,
    this.commentStatusOpen = true,
    this.modified,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    // Extract featured image URL
    String? imageUrl;
    if (json['featured_media'] != null && json['_embedded'] != null) {
      final embedded = json['_embedded'];
      if (embedded['wp:featuredmedia'] != null &&
          (embedded['wp:featuredmedia'] as List).isNotEmpty) {
        final media = embedded['wp:featuredmedia'][0];
        imageUrl = media['source_url'];
      }
    }

    // Extract categories
    List<int> categories = [];
    if (json['categories'] != null) {
      categories = List<int>.from(json['categories']);
    }

    return Post(
      id: json['id'] ?? 0,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      title: _decodeHtml(json['title']['rendered'] ?? ''),
      content: _decodeHtml(json['content']['rendered'] ?? ''),
      excerpt: json['excerpt']['rendered'],
      featuredImageUrl: imageUrl,
      categories: categories,
      slug: json['slug'] ?? '',
      link: json['link'] ?? '',
      author: json['author'],
      commentStatusOpen: json['comment_status'] == 'open',
      modified: json['modified'] != null ? DateTime.parse(json['modified']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'title': title,
      'content': content,
      'excerpt': excerpt,
      'featuredImageUrl': featuredImageUrl,
      'categories': categories,
      'slug': slug,
      'link': link,
      'author': author,
      'commentStatusOpen': commentStatusOpen,
      'modified': modified?.toIso8601String(),
    };
  }

  // Simple HTML decoder for WordPress content
  static String _decodeHtml(String html) {
    return html
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#8211;', '-')
        .replaceAll('&#8212;', '—')
        .replaceAll('&#8216;', '\'')
        .replaceAll('&#8217;', '\'')
        .replaceAll('&#8220;', '"')
        .replaceAll('&#8221;', '"');
  }

  @override
  String toString() => 'Post(id: $id, title: $title, date: $date)';
}
