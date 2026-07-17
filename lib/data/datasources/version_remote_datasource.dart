import '../../core/constants/env.dart';
import '../../core/network/http_client.dart';

/// Data source for version checking operations
class VersionRemoteDataSource {
  final HttpClient _httpClient = HttpClient();

  /// Check for app version updates
  /// Expected JSON response: {"versionCode": 2, "versionName": "1.1.0", "downloadUrl": "...", "releaseNotes": "..."}
  Future<Map<String, dynamic>?> checkVersion() async {
    try {
      // Note: The actual endpoint may need to be created on the WordPress site
      // For now, we simulate a response structure
      final response = await _httpClient.get(
        Env.versionCheckUrl,
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
      print('[VersionRemote] Error checking version: $e');
      // Return null to indicate no update check possible
      return null;
    }
  }

  /// Simulate version check for development/testing
  /// Remove this in production and use actual endpoint
  Future<Map<String, dynamic>?> checkVersionSimulated() async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Simulate response - in real scenario, this comes from server
      // For demo purposes, we'll return current version (no update)
      return {
        'versionCode': Env.appVersionCode,
        'versionName': Env.appVersion,
        'downloadUrl': 'https://www.radioguama.cu/download/app.apk',
        'releaseNotes': 'No hay cambios.',
        'mandatory': false,
      };
    } catch (e) {
      print('[VersionRemote] Simulated check failed: $e');
      return null;
    }
  }

  /// Compare versions and determine if update is needed
  bool isNewerVersionAvailable({
    required int remoteVersionCode,
    required String? remoteVersionName,
  }) {
    return remoteVersionCode > Env.appVersionCode;
  }
}
