import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/live_audio_service.dart';
import '../services/podcast_audio_service.dart';
import '../data/repositories/wordpress_repository.dart';
import '../data/repositories/ivoox_repository.dart';

/// Global providers for Riverpod state management

// ==================== AUDIO PROVIDERS ====================

/// Provider for LiveAudioService singleton
final liveAudioServiceProvider = Provider<LiveAudioService>((ref) {
  final service = LiveAudioService();
  // Only init once, not on every provider access
  return service;
});

/// Provider for PodcastAudioService singleton
final podcastAudioServiceProvider = Provider<PodcastAudioService>((ref) {
  final service = PodcastAudioService();
  // Only init once, not on every provider access
  return service;
});

// ==================== REPOSITORY PROVIDERS ====================

/// Provider for WordPressRepository
final wordpressRepositoryProvider = Provider<WordPressRepository>((ref) {
  return WordPressRepository();
});

/// Provider for IvooxRepository
final ivooxRepositoryProvider = Provider<IvooxRepository>((ref) {
  return IvooxRepository();
});

// ==================== STATE NOTIFIERS ====================

/// State notifier for live audio playback state
class LiveAudioStateNotifier extends StateNotifier<LiveAudioState> {
  final LiveAudioService _service;

  LiveAudioStateNotifier(this._service) : super(LiveAudioState()) {
    // Listen to player state changes
    _service.playerStateStream.listen((state) {
      state = state.copyWith(
        isPlaying: state.playing,
        isLoading: _service.isLoading,
        errorMessage: _service.errorMessage,
      );
    });

    _service.processingStateStream.listen((processingState) {
      state = state.copyWith(
        isLoading: _service.isLoading,
      );
    });
  }

  Future<void> togglePlayPause() async {
    await _service.togglePlayPause();
    state = state.copyWith(isPlaying: _service.isPlaying);
  }

  Future<void> play() async {
    await _service.play();
    state = state.copyWith(isPlaying: true);
  }

  Future<void> pause() async {
    await _service.pause();
    state = state.copyWith(isPlaying: false);
  }

  Future<void> stop() async {
    await _service.stop();
    state = LiveAudioState();
  }
}

class LiveAudioState {
  final bool isPlaying;
  final bool isLoading;
  final String? errorMessage;

  LiveAudioState({
    this.isPlaying = false,
    this.isLoading = false,
    this.errorMessage,
  });

  LiveAudioState copyWith({
    bool? isPlaying,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LiveAudioState(
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final liveAudioStateProvider = StateNotifierProvider<LiveAudioStateNotifier, LiveAudioState>((ref) {
  final service = ref.watch(liveAudioServiceProvider);
  return LiveAudioStateNotifier(service);
});

/// State notifier for podcast playback state
class PodcastAudioStateNotifier extends StateNotifier<PodcastAudioState> {
  final PodcastAudioService _service;

  PodcastAudioStateNotifier(this._service) : super(PodcastAudioState()) {
    // Listen to player state changes
    _service.playerStateStream.listen((state) {
      state = state.copyWith(
        isPlaying: _service.isPlaying,
        currentPosition: _service.position,
        duration: _service.duration,
      );
    });

    _service.positionStream.listen((position) {
      state = state.copyWith(currentPosition: position);
    });
  }

  void setPlaylist(List<dynamic> episodes, {int startIndex = 0}) {
    // Note: episodes should be of type Episode
    state = state.copyWith(
      playlist: episodes,
      currentIndex: startIndex,
      currentEpisode: episodes.isNotEmpty ? episodes[startIndex] : null,
    );
  }

  Future<void> togglePlayPause() async {
    await _service.togglePlayPause();
    state = state.copyWith(isPlaying: _service.isPlaying);
  }

  Future<void> playNext() async {
    await _service.playNext();
    state = state.copyWith(
      currentIndex: _service.currentIndex,
      currentEpisode: _service.currentEpisode,
    );
  }

  Future<void> playPrevious() async {
    await _service.playPrevious();
    state = state.copyWith(
      currentIndex: _service.currentIndex,
      currentEpisode: _service.currentEpisode,
    );
  }

  Future<void> seek(Duration position) async {
    await _service.seek(position);
  }

  Future<void> stop() async {
    await _service.stop();
    state = PodcastAudioState();
  }
}

class PodcastAudioState {
  final bool isPlaying;
  final dynamic currentEpisode;
  final List<dynamic> playlist;
  final int currentIndex;
  final Duration? currentPosition;
  final Duration? duration;

  PodcastAudioState({
    this.isPlaying = false,
    this.currentEpisode,
    this.playlist = const [],
    this.currentIndex = -1,
    this.currentPosition,
    this.duration,
  });

  PodcastAudioState copyWith({
    bool? isPlaying,
    dynamic currentEpisode,
    List<dynamic>? playlist,
    int? currentIndex,
    Duration? currentPosition,
    Duration? duration,
  }) {
    return PodcastAudioState(
      isPlaying: isPlaying ?? this.isPlaying,
      currentEpisode: currentEpisode ?? this.currentEpisode,
      playlist: playlist ?? this.playlist,
      currentIndex: currentIndex ?? this.currentIndex,
      currentPosition: currentPosition ?? this.currentPosition,
      duration: duration ?? this.duration,
    );
  }
}

final podcastAudioStateProvider = StateNotifierProvider<PodcastAudioStateNotifier, PodcastAudioState>((ref) {
  final service = ref.watch(podcastAudioServiceProvider);
  return PodcastAudioStateNotifier(service);
});
