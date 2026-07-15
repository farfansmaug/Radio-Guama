import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/env.dart';
import 'providers.dart';
import 'routes.dart';
import '../services/background_download_service.dart';
import '../core/storage/storage_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive storage
  final storage = StorageHelper();
  await storage.init();

  // Initialize background download service
  final bgService = BackgroundDownloadService();
  await bgService.initialize();

  // Start initial sync if not done
  if (!storage.isInitialDownloadComplete) {
    // Run in background without waiting
    bgService.performSync().catchError((e) {
      print('[Main] Initial sync failed: $e');
    });
  }

  runApp(const ProviderScope(child: RadioGuamaApp()));
}

class RadioGuamaApp extends ConsumerWidget {
  const RadioGuamaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: router,
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary1,
        tertiary: AppColors.accent,
        surface: AppColors.surface,
        background: AppColors.background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        // Add custom text theme if needed
      ),
    );
  }
}
