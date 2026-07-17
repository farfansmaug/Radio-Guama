import '../models/episode.dart';
import '../datasources/ivoox_remote_datasource.dart';
import '../../core/storage/storage_helper.dart';

/// Repository for Ivoox podcast episodes
/// Handles both remote fetching and local caching
class IvooxRepository {
  final IvooxRemoteDataSource _remoteDataSource = IvooxRemoteDataSource();
  final StorageHelper _storage = StorageHelper();

  /// Get all episodes from all feeds (with caching)
  Future<List<Episode>> getAllEpisodes({bool forceRefresh = false}) async {
    // Try cache first
    if (!forceRefresh) {
      final cachedEpisodes = _getCachedEpisodes();
      if (cachedEpisodes.isNotEmpty) {
        return cachedEpisodes;
      }
    }

    // Fetch from remote
    try {
      final episodes = await _remoteDataSource.getAllEpisodes();
      await _cacheEpisodes(episodes);
      return episodes;
    } catch (e) {
      print('[IvooxRepo] Error getting all episodes: $e');
      // Return cached data even if stale on error
      return _getCachedEpisodes();
    }
  }

  /// Get episodes from a specific feed
  Future<List<Episode>> getEpisodesByFeed(String feedUrl, {bool forceRefresh = false}) async {
    // Try cache first
    if (!forceRefresh) {
      final cachedEpisodes = _getCachedEpisodesByFeed(feedUrl);
      if (cachedEpisodes.isNotEmpty) {
        return cachedEpisodes;
      }
    }

    // Fetch from remote
    try {
      final episodes = await _remoteDataSource.getEpisodesFromFeed(feedUrl);
      await _cacheEpisodes(episodes);
      return episodes;
    } catch (e) {
      print('[IvooxRepo] Error getting episodes from feed: $e');
      return _getCachedEpisodesByFeed(feedUrl);
    }
  }

  /// Get episodes grouped by feed source
  Future<Map<String, List<Episode>>> getEpisodesGroupedByFeed({bool forceRefresh = false}) async {
    final allEpisodes = await getAllEpisodes(forceRefresh: forceRefresh);
    final grouped = <String, List<Episode>>{};

    for (final episode in allEpisodes) {
      if (!grouped.containsKey(episode.feedSource)) {
        grouped[episode.feedSource] = [];
      }
      grouped[episode.feedSource]!.add(episode);
    }

    // Sort each group by date
    grouped.forEach((key, value) {
      value.sort((a, b) => b.pubDate.compareTo(a.pubDate));
    });

    return grouped;
  }

  // ==================== CACHING METHODS ====================

  List<Episode> _getCachedEpisodes() {
    try {
      final box = _storage.episodesBox;
      final episodes = <Episode>[];
      
      for (final key in box.keys) {
        final data = box.get(key);
        if (data is Map<String, dynamic>) {
          episodes.add(Episode.fromJson(data));
        }
      }
      
      // Sort by date (newest first)
      episodes.sort((a, b) => b.pubDate.compareTo(a.pubDate));
      return episodes;
    } catch (e) {
      print('[IvooxRepo] Error reading cached episodes: $e');
      return [];
    }
  }

  List<Episode> _getCachedEpisodesByFeed(String feedUrl) {
    final allCached = _getCachedEpisodes();
    return allCached.where((e) => e.feedSource == feedUrl).toList();
  }

  Future<void> _cacheEpisodes(List<Episode> episodes) async {
    try {
      final box = _storage.episodesBox;
      for (final episode in episodes) {
        await box.put(episode.id, episode.toJson());
      }
    } catch (e) {
      print('[IvooxRepo] Error caching episodes: $e');
    }
  }

  /// Clear all cached episode data
  Future<void> clearCache() async {
    await _storage.episodesBox.clear();
  }
}
