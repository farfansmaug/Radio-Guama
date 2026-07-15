// Environment configuration
class Env {
  // WordPress API
  static const String wordpressBaseUrl = 'https://www.radioguama.cu';
  static const String wordpressApiBase = '$wordpressBaseUrl/wp-json/wp/v2';

  // Live Audio Stream
  static const String liveAudioUrl = 'https://icecast.teveo.cu/ngcdcV3k';

  // Ivoox RSS Feeds (Podcasts)
  static const List<String> ivooxFeeds = [
    'https://www.ivoox.com/programa1.rss', // Replace with actual feed
    'https://www.ivoox.com/programa2.rss', // Replace with actual feed
    'https://www.ivoox.com/programa3.rss', // Replace with actual feed
  ];

  // Version Check
  static const String versionCheckUrl = 'https://www.radioguama.cu/download/version.json';

  // App Version (should match pubspec.yaml)
  static const String appVersion = '1.0.0';
  static const int appVersionCode = 1;

  // Hive Box Names
  static const String postsBox = 'posts';
  static const String categoriesBox = 'categories';
  static const String episodesBox = 'episodes';
  static const String commentsBox = 'comments';
  static const String settingsBox = 'settings';

  // Download Background Task
  static const String backgroundDownloadTask = 'backgroundDownload';
}
