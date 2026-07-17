import 'package:hive_flutter/hive_flutter.dart';

/// Episode model for Ivoox podcast episodes

@HiveType(typeId: 2)
class Episode {
  @HiveField(0)
  final String id; // Unique identifier (URL or GUID)

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final String audioUrl;

  @HiveField(4)
  final DateTime pubDate;

  @HiveField(5)
  final int? durationSeconds;

  @HiveField(6)
  final String? imageUrl;

  @HiveField(7)
  final String feedSource; // Which Ivoox feed this episode belongs to

  @HiveField(8)
  final String link;

  Episode({
    required this.id,
    required this.title,
    this.description,
    required this.audioUrl,
    required this.pubDate,
    this.durationSeconds,
    this.imageUrl,
    required this.feedSource,
    required this.link,
  });

  factory Episode.fromRssItem(Map<String, dynamic> item, String feedSource) {
    // Extract audio URL from enclosure
    String audioUrl = '';
    if (item['enclosure'] != null) {
      audioUrl = item['enclosure']['url'] ?? '';
    }

    // Extract image from iTunes image or enclosure
    String? imageUrl;
    if (item['itunes:image'] != null) {
      imageUrl = item['itunes:image']['href'];
    }

    // Parse duration if available
    int? duration;
    if (item['itunes:duration'] != null) {
      duration = _parseDuration(item['itunes:duration']);
    }

    return Episode(
      id: item['guid']?.toString() ?? item['link'] ?? '',
      title: item['title'] ?? '',
      description: item['description'] ?? item['summary'],
      audioUrl: audioUrl,
      pubDate: item['pubDate'] != null ? DateTime.parse(item['pubDate']) : DateTime.now(),
      durationSeconds: duration,
      imageUrl: imageUrl,
      feedSource: feedSource,
      link: item['link'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'audioUrl': audioUrl,
      'pubDate': pubDate.toIso8601String(),
      'durationSeconds': durationSeconds,
      'imageUrl': imageUrl,
      'feedSource': feedSource,
      'link': link,
    };
  }

  static int? _parseDuration(dynamic duration) {
    if (duration is int) return duration;
    if (duration is String) {
      final parts = duration.split(':');
      if (parts.length == 3) {
        return (int.tryParse(parts[0]) ?? 0) * 3600 +
            (int.tryParse(parts[1]) ?? 0) * 60 +
            (int.tryParse(parts[2]) ?? 0);
      } else if (parts.length == 2) {
        return (int.tryParse(parts[0]) ?? 0) * 60 +
            (int.tryParse(parts[1]) ?? 0);
      }
    }
    return null;
  }

  String get formattedDuration {
    if (durationSeconds == null) return '';
    final hours = durationSeconds! ~/ 3600;
    final minutes = (durationSeconds! % 3600) ~/ 60;
    final seconds = durationSeconds! % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  String toString() => 'Episode(id: $id, title: $title)';
}
