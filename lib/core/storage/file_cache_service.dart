import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../network/http_client.dart';

/// Service for downloading and caching files (images, audio, etc.)
class FileCacheService {
  final HttpClient _httpClient = HttpClient();

  /// Get the cache directory path
  Future<String> get _cacheDirPath async {
    final dir = await getApplicationCacheDirectory();
    return dir.path;
  }

  /// Get the images cache directory
  Future<String> get _imagesCacheDirPath async {
    final baseDir = await _cacheDirPath;
    final imagesDir = Directory('$baseDir/images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir.path;
  }

  /// Get the audio cache directory
  Future<String> get _audioCacheDirPath async {
    final baseDir = await _cacheDirPath;
    final audioDir = Directory('$baseDir/audio');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir.path;
  }

  /// Download and cache an image
  /// Returns the local file path if successful, null otherwise
  Future<String?> cacheImage(String imageUrl, String fileName) async {
    try {
      final cacheDir = await _imagesCacheDirPath;
      final filePath = '$cacheDir/$fileName';
      final file = File(filePath);

      // Check if already cached
      if (await file.exists()) {
        return filePath;
      }

      // Download the image
      await _httpClient.downloadFile(
        imageUrl,
        filePath,
        onProgress: (received, total) {
          // Could emit progress here if needed
        },
      );

      if (await file.exists()) {
        return filePath;
      }
      return null;
    } catch (e) {
      print('[FileCache] Error caching image: $e');
      return null;
    }
  }

  /// Get cached image file path if it exists
  Future<String?> getCachedImagePath(String fileName) async {
    final cacheDir = await _imagesCacheDirPath;
    final file = File('$cacheDir/$fileName');
    if (await file.exists()) {
      return file.path;
    }
    return null;
  }

  /// Cache an episode audio file
  Future<String?> cacheEpisodeAudio(String audioUrl, String episodeId) async {
    try {
      final cacheDir = await _audioCacheDirPath;
      // Sanitize episodeId for filename
      final safeId = episodeId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final filePath = '$cacheDir/episode_$safeId.mp3';
      final file = File(filePath);

      // Check if already cached
      if (await file.exists()) {
        return filePath;
      }

      // Download the audio
      await _httpClient.downloadFile(
        audioUrl,
        filePath,
        onProgress: (received, total) {
          final progress = (received / total * 100).toStringAsFixed(1);
          print('[FileCache] Downloading episode: $progress%');
        },
      );

      if (await file.exists()) {
        return filePath;
      }
      return null;
    } catch (e) {
      print('[FileCache] Error caching episode audio: $e');
      return null;
    }
  }

  /// Get cached audio file path if it exists
  Future<String?> getCachedAudioPath(String episodeId) async {
    final cacheDir = await _audioCacheDirPath;
    final safeId = episodeId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final file = File('$cacheDir/episode_$safeId.mp3');
    if (await file.exists()) {
      return file.path;
    }
    return null;
  }

  /// Clear image cache
  Future<void> clearImageCache() async {
    try {
      final cacheDir = await _imagesCacheDirPath;
      final dir = Directory(cacheDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
      }
    } catch (e) {
      print('[FileCache] Error clearing image cache: $e');
    }
  }

  /// Clear audio cache
  Future<void> clearAudioCache() async {
    try {
      final cacheDir = await _audioCacheDirPath;
      final dir = Directory(cacheDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
      }
    } catch (e) {
      print('[FileCache] Error clearing audio cache: $e');
    }
  }

  /// Get total cache size in bytes
  Future<int> getCacheSize() async {
    try {
      final cacheDir = await _cacheDirPath;
      final dir = Directory(cacheDir);
      if (!await dir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      print('[FileCache] Error getting cache size: $e');
      return 0;
    }
  }
}
