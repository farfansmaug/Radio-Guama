import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/news_screen.dart';
import '../presentation/screens/podcast_screen.dart';
import '../presentation/screens/post_detail_screen.dart';
import '../presentation/screens/player_screen.dart';

/// GoRouter configuration for app navigation
/// Supports deep linking and persistent audio player

// Route paths
class AppRoutes {
  static const String home = '/';
  static const String news = '/news';
  static const String newsCategory = '/news/category/:categoryId';
  static const String podcasts = '/podcasts';
  static const String podcastEpisodes = '/podcasts/:feedSource';
  static const String postDetail = '/post/:postId';
  static const String player = '/player';
}

/// Router provider - creates the GoRouter instance
final GoRouter router = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    // Home screen
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    
    // News screen (categories list)
    GoRoute(
      path: AppRoutes.news,
      name: 'news',
      builder: (context, state) => const NewsScreen(),
    ),
    
    // News by category
    GoRoute(
      path: AppRoutes.newsCategory,
      name: 'newsCategory',
      builder: (context, state) {
        final categoryId = int.parse(state.pathParameters['categoryId'] ?? '0');
        return NewsCategoryScreen(categoryId: categoryId);
      },
    ),
    
    // Podcasts screen
    GoRoute(
      path: AppRoutes.podcasts,
      name: 'podcasts',
      builder: (context, state) => const PodcastsScreen(),
    ),
    
    // Podcast episodes by feed
    GoRoute(
      path: AppRoutes.podcastEpisodes,
      name: 'podcastEpisodes',
      builder: (context, state) {
        final feedSource = state.pathParameters['feedSource'] ?? '';
        return PodcastEpisodesScreen(feedSource: feedSource);
      },
    ),
    
    // Post detail
    GoRoute(
      path: AppRoutes.postDetail,
      name: 'postDetail',
      builder: (context, state) {
        final postId = int.parse(state.pathParameters['postId'] ?? '0');
        return PostDetailScreen(postId: postId);
      },
    ),
    
    // Full-screen player
    GoRoute(
      path: AppRoutes.player,
      name: 'player',
      builder: (context, state) => const PlayerScreen(),
    ),
  ],
  
  // Error handler for route not found
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Página no encontrada',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'La ruta "${state.uri.path}" no existe',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('Ir al Inicio'),
          ),
        ],
      ),
    ),
  ),
);
