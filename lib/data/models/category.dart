import 'package:hive_flutter/hive_flutter.dart';

/// Category model for WordPress categories
part 'category.g.dart';

@HiveType(typeId: 0)
class Category {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String slug;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final int count; // Number of posts in this category

  @HiveField(5)
  final String? link;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.count = 0,
    this.link,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      count: json['count'] ?? 0,
      link: json['link'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'count': count,
      'link': link,
    };
  }

  @override
  String toString() => 'Category(id: $id, name: $name, slug: $slug)';
}
