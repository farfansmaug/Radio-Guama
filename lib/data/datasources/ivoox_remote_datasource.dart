import 'package:xml/xml.dart';
import 'dart:convert';
import '../constants/env.dart';
import '../models/episode.dart';
import '../../core/network/http_client.dart';

/// Data source for parsing Ivoox RSS feeds
class IvooxRemoteDataSource {
  final HttpClient _httpClient = HttpClient();

  /// Fetch and parse all configured Ivoox feeds
  Future<List<Episode>> getAllEpisodes() async {
    final allEpisodes = <Episode>[];

    for (final feedUrl in Env.ivooxFeeds) {
      try {
        final episodes = await _parseFeed(feedUrl);
        allEpisodes.addAll(episodes);
      } catch (e) {
        print('[IvooxRemote] Error parsing feed $feedUrl: $e');
      }
    }

    // Sort by publication date (newest first)
    allEpisodes.sort((a, b) => b.pubDate.compareTo(a.pubDate));
    return allEpisodes;
  }

  /// Fetch and parse a single Ivoox feed
  Future<List<Episode>> getEpisodesFromFeed(String feedUrl) async {
    return await _parseFeed(feedUrl);
  }

  /// Parse an RSS feed and extract episodes
  Future<List<Episode>> _parseFeed(String feedUrl) async {
    try {
      final response = await _httpClient.get(
        feedUrl,
        options: Options(
          headers: {'Accept': 'application/rss+xml, application/xml, text/xml'},
        ),
      );

      final xmlString = response.data.toString();
      final document = XmlDocument.parse(xmlString);
      final episodes = <Episode>[];

      // Find the channel element
      final channel = document.findAllElements('channel').firstOrNull;
      if (channel == null) {
        print('[IvooxRemote] No channel found in feed');
        return [];
      }

      // Extract feed title/source name
      String feedSource = 'Unknown';
      final titleElement = channel.findElements('title').firstOrNull;
      if (titleElement != null && titleElement.text.isNotEmpty) {
        feedSource = titleElement.text.trim();
      }

      // Parse each item (episode)
      final items = channel.findAllElements('item');
      for (final item in items) {
        final episode = _parseItem(item, feedSource);
        if (episode != null) {
          episodes.add(episode);
        }
      }

      return episodes;
    } catch (e) {
      print('[IvooxRemote] Error parsing feed: $e');
      rethrow;
    }
  }

  /// Parse a single RSS item into an Episode
  Episode? _parseItem(XmlElement item, String feedSource) {
    try {
      // Extract title
      final title = item.findElements('title').firstOrNull?.text.trim() ?? '';
      if (title.isEmpty) return null; // Skip items without title

      // Extract link
      final link = item.findElements('link').firstOrNull?.text.trim() ?? '';

      // Extract description/summary
      final description =
          item.findElements('description').firstOrNull?.text.trim();
      final summary = _extractItunesField(item, 'summary');

      // Extract publication date
      DateTime pubDate = DateTime.now();
      final pubDateStr = item.findElements('pubDate').firstOrNull?.text;
      if (pubDateStr != null) {
        try {
          pubDate = _parseRssDate(pubDateStr);
        } catch (e) {
          print('[IvooxRemote] Error parsing date: $e');
        }
      }

      // Extract audio URL from enclosure
      String audioUrl = '';
      final enclosure = item.findElements('enclosure').firstOrNull;
      if (enclosure != null) {
        audioUrl = enclosure.getAttribute('url') ?? '';
      }

      // If no enclosure, try to find audio in content or iTunes link
      if (audioUrl.isEmpty) {
        final content = item.findElements('content').firstOrNull?.text;
        if (content != null) {
          // Try to extract audio URL from content
          final audioMatch = RegExp(r'src=["\'](.*?)["\']')
              .firstMatch(content);
          if (audioMatch != null) {
            audioUrl = audioMatch.group(1) ?? '';
          }
        }
      }

      if (audioUrl.isEmpty) return null; // Skip items without audio

      // Extract image from iTunes image
      String? imageUrl;
      final itunesImage = item.findElements('image', namespace: 'itunes').firstOrNull;
      if (itunesImage != null) {
        imageUrl = itunesImage.getAttribute('href');
      }

      // Extract duration from iTunes duration
      int? duration;
      final itunesDuration = item.findElements('duration', namespace: 'itunes').firstOrNull;
      if (itunesDuration != null) {
        duration = _parseDuration(itunesDuration.text);
      }

      // Create unique ID from GUID or link
      String id = item.findElements('guid').firstOrNull?.text ?? link;
      if (id.isEmpty) {
        id = '${feedSource}_$title';
      }

      return Episode(
        id: id,
        title: title,
        description: description ?? summary,
        audioUrl: audioUrl,
        pubDate: pubDate,
        durationSeconds: duration,
        imageUrl: imageUrl,
        feedSource: feedSource,
        link: link,
      );
    } catch (e) {
      print('[IvooxRemote] Error parsing item: $e');
      return null;
    }
  }

  /// Extract iTunes-specific field
  String? _extractItunesField(XmlElement item, String fieldName) {
    final element = item.findElements(fieldName, namespace: 'itunes').firstOrNull;
    return element?.text.trim();
  }

  /// Parse RSS date format (RFC 822)
  DateTime _parseRssDate(String dateStr) {
    // Common RSS date format: "Mon, 01 Jan 2024 12:00:00 +0000"
    final formats = [
      'EEE, dd MMM yyyy HH:mm:ss Z',
      'EEE, dd MMM yyyy HH:mm:ss z',
      'dd MMM yyyy HH:mm:ss Z',
    ];

    for (final format in formats) {
      try {
        // Note: intl package would be better for proper parsing
        // This is a simplified approach
        return DateTime.parse(dateStr);
      } catch (e) {
        continue;
      }
    }

    // Fallback: try direct parsing
    return DateTime.tryParse(dateStr) ?? DateTime.now();
  }

  /// Parse duration string (HH:MM:SS or MM:SS)
  int? _parseDuration(String durationStr) {
    final parts = durationStr.split(':');
    if (parts.length == 3) {
      return (int.tryParse(parts[0]) ?? 0) * 3600 +
          (int.tryParse(parts[1]) ?? 0) * 60 +
          (int.tryParse(parts[2]) ?? 0);
    } else if (parts.length == 2) {
      return (int.tryParse(parts[0]) ?? 0) * 60 +
          (int.tryParse(parts[1]) ?? 0);
    }
    return int.tryParse(durationStr);
  }
}
