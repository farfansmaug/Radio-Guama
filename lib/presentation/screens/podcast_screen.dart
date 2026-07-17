import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/episode.dart';
import '../../data/repositories/ivoox_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../app/routes.dart';
import '../../app/providers.dart';

/// Podcasts screen showing feed sources
class PodcastsScreen extends ConsumerWidget {
  const PodcastsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(ivooxRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.podcasts),
      ),
      body: FutureBuilder<Map<String, List<Episode>>>(
        future: repo.getEpisodesGroupedByFeed(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar podcasts',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref.invalidate(ivooxRepositoryProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final groupedEpisodes = snapshot.data ?? {};

          if (groupedEpisodes.isEmpty) {
            return const Center(
              child: Text('No hay podcasts disponibles'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => repo.getAllEpisodes(forceRefresh: true),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedEpisodes.length,
              itemBuilder: (context, index) {
                final feedSource = groupedEpisodes.keys.elementAt(index);
                final episodes = groupedEpisodes[feedSource]!;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.podcast,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                    title: Text(
                      feedSource,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${episodes.length} episodios',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => context.push(
                      AppRoutes.podcastEpisodes,
                      pathParameters: {'feedSource': Uri.encodeComponent(feedSource)},
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Podcast episodes screen for a specific feed
class PodcastEpisodesScreen extends ConsumerWidget {
  final String feedSource;

  const PodcastEpisodesScreen({super.key, required this.feedSource});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(ivooxRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(feedSource),
      ),
      body: FutureBuilder<List<Episode>>(
        future: repo.getEpisodesByFeed(feedSource),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar episodios',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref.invalidate(ivooxRepositoryProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final episodes = snapshot.data as List<Episode>? ?? [];

          if (episodes.isEmpty) {
            return const Center(
              child: Text('No hay episodios disponibles'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => repo.getEpisodesByFeed(feedSource, forceRefresh: true),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: episodes.length,
              itemBuilder: (context, index) {
                final episode = episodes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: episode.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              episode.imageUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.podcast),
                                );
                              },
                            ),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.podcast),
                          ),
                    title: Text(
                      episode.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (episode.description != null && episode.description!.isNotEmpty)
                          Text(
                            episode.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              DateFormat('dd MMM yyyy').format(episode.pubDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (episode.formattedDuration.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                '• ${episode.formattedDuration}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_circle_outline),
                      onPressed: () {
                        // Set playlist and start playing
                        ref.read(podcastAudioServiceProvider).setPlaylist(episodes, startIndex: index);
                        ref.read(podcastAudioServiceProvider).play();
                      },
                    ),
                    onTap: () {
                      // Navigate to full player screen
                      ref.read(podcastAudioServiceProvider).setPlaylist(episodes, startIndex: index);
                      context.push(AppRoutes.player);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
