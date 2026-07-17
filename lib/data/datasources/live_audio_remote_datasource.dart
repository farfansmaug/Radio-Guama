import '../../core/constants/env.dart';
import '../../core/network/http_client.dart';

/// Data source for live audio stream operations
class LiveAudioRemoteDataSource {
  final HttpClient _httpClient = HttpClient();

  /// Get the live audio stream URL
  String get streamUrl => Env.liveAudioUrl;

  /// Check if the stream is accessible (basic connectivity check)
  Future<bool> isStreamAvailable() async {
    try {
      // Make a HEAD request to check availability without downloading
      final response = await _httpClient.get(
        streamUrl,
        options: Options(
          method: 'HEAD',
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('[LiveAudioRemote] Stream availability check failed: $e');
      return false;
    }
  }

  /// Get stream metadata (if available from Icecast server)
  Future<Map<String, dynamic>?> getStreamMetadata() async {
    try {
      // Icecast typically provides status-json.xsl for metadata
      // This is a placeholder - actual implementation depends on server config
      final response = await _httpClient.get(
        'https://icecast.teveo.cu/status-json.xsl',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('[LiveAudioRemote] Error fetching stream metadata: $e');
      return null;
    }
  }
}
