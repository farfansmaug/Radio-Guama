import 'package:hive_flutter/hive_flutter.dart';
import '../constants/env.dart';

/// Hive storage helper for initializing boxes and adapters
class StorageHelper {
  static final StorageHelper _instance = StorageHelper._internal();
  factory StorageHelper() => _instance;
  StorageHelper._internal();

  bool _isInitialized = false;

  /// Initialize Hive and register all adapters
  Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Register adapters (typeIds must match those in models)
    // Note: You need to run `flutter pub run build_runner build` to generate .g.dart files
    // Hive.registerAdapter(CategoryAdapter());
    // Hive.registerAdapter(PostAdapter());
    // Hive.registerAdapter(EpisodeAdapter());
    // Hive.registerAdapter(CommentAdapter());

    // Open boxes
    await Hive.openBox<dynamic>(Env.postsBox);
    await Hive.openBox<dynamic>(Env.categoriesBox);
    await Hive.openBox<dynamic>(Env.episodesBox);
    await Hive.openBox<dynamic>(Env.commentsBox);
    await Hive.openBox<dynamic>(Env.settingsBox);

    _isInitialized = true;
    print('[Storage] Hive initialized successfully');
  }

  /// Get posts box
  Box<dynamic> get postsBox => Hive.box<dynamic>(Env.postsBox);

  /// Get categories box
  Box<dynamic> get categoriesBox => Hive.box<dynamic>(Env.categoriesBox);

  /// Get episodes box
  Box<dynamic> get episodesBox => Hive.box<dynamic>(Env.episodesBox);

  /// Get comments box
  Box<dynamic> get commentsBox => Hive.box<dynamic>(Env.commentsBox);

  /// Get settings box
  Box<dynamic> get settingsBox => Hive.box<dynamic>(Env.settingsBox);

  /// Save a value to settings
  Future<void> saveSetting(String key, dynamic value) async {
    await settingsBox.put(key, value);
  }

  /// Get a value from settings
  T? getSetting<T>(String key, {T? defaultValue}) {
    return settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  /// Check if initial download has been completed
  bool get isInitialDownloadComplete {
    return getSetting<bool>('initialDownloadComplete', defaultValue: false) ?? false;
  }

  /// Mark initial download as complete
  Future<void> markInitialDownloadComplete() async {
    await saveSetting('initialDownloadComplete', true);
  }

  /// Get last sync timestamp for a given entity type
  DateTime? getLastSyncTime(String entityType) {
    final timestamp = getSetting<int>('lastSync_$entityType');
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  /// Set last sync timestamp
  Future<void> setLastSyncTime(String entityType, DateTime time) async {
    await saveSetting('lastSync_$entityType', time.millisecondsSinceEpoch);
  }

  /// Clear all data (for debugging or reset)
  Future<void> clearAllData() async {
    await postsBox.clear();
    await categoriesBox.clear();
    await episodesBox.clear();
    await commentsBox.clear();
    await saveSetting('initialDownloadComplete', false);
  }

  /// Close Hive
  Future<void> close() async {
    await Hive.close();
    _isInitialized = false;
  }
}
