import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/providers.dart';
import '../../core/constants/app_constants.dart';

/// Full-screen podcast player with all controls
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(podcastAudioStateProvider);
    final audioService = ref.watch(podcastAudioServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reproductor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              audioService.stop();
              context.pop();
            },
          ),
        ],
      ),
      body: audioState.currentEpisode == null
          ? const Center(
              child: Text('No hay episodio seleccionado'),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Episode artwork
                        Hero(
                          tag: 'episode_artwork',
                          child: Container(
                            width: 280,
                            height: 280,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: audioState.currentEpisode.imageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: audioState.currentEpisode.imageUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.podcast, size: 80),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.podcast, size: 80),
                                    ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Episode title
                        Text(
                          audioState.currentEpisode.title ?? '',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Feed source
                        Text(
                          audioState.currentEpisode.feedSource ?? '',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Progress slider
                        StreamBuilder<Duration>(
                          stream: audioService.positionStream,
                          builder: (context, snapshot) {
                            final position = snapshot.data ?? Duration.zero;
                            final duration = audioState.duration ?? Duration.zero;
                            
                            return Column(
                              children: [
                                SliderTheme(
                                  data: SliderThemeData(
                                    activeTrackColor: AppColors.primary,
                                    inactiveTrackColor: AppColors.primary.withOpacity(0.3),
                                    thumbColor: AppColors.primary,
                                    overlayColor: AppColors.primary.withOpacity(0.2),
                                    trackHeight: 4,
                                  ),
                                  child: Slider(
                                    value: position.inMilliseconds.toDouble().clamp(
                                          0,
                                          duration.inMilliseconds.toDouble(),
                                        ),
                                    min: 0,
                                    max: duration.inMilliseconds.toDouble(),
                                    onChanged: (value) {
                                      audioService.seek(Duration(milliseconds: value.toInt()));
                                    },
                                  ),
                                ),
                                
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_formatDuration(position)),
                                      Text(_formatDuration(duration)),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Playback controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Previous button
                            IconButton(
                              icon: const Icon(Icons.skip_previous),
                              iconSize: 40,
                              onPressed: audioState.currentIndex > 0
                                  ? () => ref
                                      .read(podcastAudioStateProvider.notifier)
                                      .playPrevious()
                                  : null,
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Rewind 15s
                            IconButton(
                              icon: const Icon(Icons.replay_15),
                              iconSize: 32,
                              onPressed: () => audioService.skipBackward(),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Play/Pause button
                            StreamBuilder<bool>(
                              stream: audioService.playerStateStream.map((s) => s.playing),
                              builder: (context, snapshot) {
                                final isPlaying = snapshot.data ?? false;
                                return Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.4),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      isPlaying ? Icons.pause : Icons.play_arrow,
                                      color: Colors.white,
                                    ),
                                    iconSize: 40,
                                    onPressed: () => ref
                                        .read(podcastAudioStateProvider.notifier)
                                        .togglePlayPause(),
                                  ),
                                );
                              },
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Forward 15s
                            IconButton(
                              icon: const Icon(Icons.forward_15),
                              iconSize: 32,
                              onPressed: () => audioService.skipForward(),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Next button
                            IconButton(
                              icon: const Icon(Icons.skip_next),
                              iconSize: 40,
                              onPressed: audioState.currentIndex < audioState.playlist.length - 1
                                  ? () => ref
                                      .read(podcastAudioStateProvider.notifier)
                                      .playNext()
                                  : null,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Speed control
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Velocidad: '),
                            ...['0.5x', '1.0x', '1.5x', '2.0x'].map((speed) {
                              final value = double.parse(speed.replaceAll('x', ''));
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: ChoiceChip(
                                  label: Text(speed),
                                  selected: false, // Would need to track current speed
                                  onSelected: (selected) {
                                    if (selected) {
                                      audioService.setSpeed(value);
                                    }
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
