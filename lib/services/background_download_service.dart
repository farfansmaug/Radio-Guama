import 'dart:async';
import 'package:workmanager/workmanager.dart';
import '../core/constants/env.dart';
import '../../data/repositories/wordpress_repository.dart';
import '../../data/repositories/ivoox_repository.dart';
import '../../core/storage/storage_helper.dart';

/// Background download service for syncing content
/// Uses Workmanager for periodic background tasks
class BackgroundDownloadService {
  static final BackgroundDownloadService _instance = 
      BackgroundDownloadService._internal();
  factory BackgroundDownloadService() => _instance;
  BackgroundDownloadService._internal();

  final WordPressRepository _wordpressRepo = WordPressRepository();
  final IvooxRepository _ivooxRepo = IvooxRepository();
  final StorageHelper _storage = StorageHelper();

  /// Initialize workmanager and register tasks
  Future<void> initialize() async {
    // Initialize Workmanager
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Set to false in production
    );

    // Register periodic background task
    // Note: Android restricts background tasks; this is best-effort
    await Workmanager().registerPeriodicTask(
      Env.backgroundDownloadTask,
      Env.backgroundDownloadTask,
      frequency: const Duration(hours: 6), // Minimum 15 minutes on Android
      initialDelay: const Duration(seconds: 30), // Wait 30s after app start
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
        // requiresCharging: true, // Optional: only sync when charging
      ),
    );

    print('[BackgroundDownload] Workmanager initialized');
  }

  /// Perform the actual download/sync operation
  /// Called both by Workmanager and manually
  Future<void> performSync() async {
    try {
      print('[BackgroundDownload] Starting sync...');

      // Sync categories
      await _wordpressRepo.getCategories(forceRefresh: true);
      print('[BackgroundDownload] Categories synced');

      // Sync posts for each category (last 30 per category)
      final categoryIds = [
        CategoryIds.destacada,
        CategoryIds.ultimasNoticias,
        CategoryIds.deNuestrosProgramas,
        CategoryIds.deportes,
        CategoryIds.cultura,
        CategoryIds.opinion,
      ];

      for (final categoryId in categoryIds) {
        await _wordpressRepo.getPosts(
          categoryId: categoryId,
          page: 1,
          perPage: 30,
          forceRefresh: true,
        );
        print('[BackgroundDownload] Posts synced for category $categoryId');
      }

      // Sync podcast episodes
      await _ivooxRepo.getAllEpisodes(forceRefresh: true);
      print('[BackgroundDownload] Episodes synced');

      // Mark initial download as complete
      await _storage.markInitialDownloadComplete();
      
      // Update sync timestamp
      await _storage.setLastSyncTime('all', DateTime.now());

      print('[BackgroundDownload] Sync completed successfully');
    } catch (e) {
      print('[BackgroundDownload] Sync failed: $e');
      rethrow;
    }
  }

  /// Cancel all background tasks
  Future<void> cancelAll() async {
    await Workmanager().cancelAll();
    print('[BackgroundDownload] All tasks cancelled');
  }

  /// Check if background tasks are registered
  Future<bool> isRegistered() async {
    // Workmanager doesn't provide a direct way to check registration
    // This is a placeholder - you may need to track state separately
    return true;
  }
}

/// Callback dispatcher for Workmanager (must be top-level function)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case Env.backgroundDownloadTask:
          final service = BackgroundDownloadService();
          await service.performSync();
          break;
        default:
          print('[BackgroundDownload] Unknown task: $task');
      }
      return Future.value(true);
    } catch (e) {
      print('[BackgroundDownload] Task execution error: $e');
      return Future.value(false);
    }
  });
}

/// Category IDs helper (duplicated from constants for Workmanager compatibility)
class CategoryIds {
  static const int destacada = 1;
  static const int ultimasNoticias = 2;
  static const int deNuestrosProgramas = 3;
  static const int deportes = 4;
  static const int cultura = 5;
  static const int opinion = 6;
}
