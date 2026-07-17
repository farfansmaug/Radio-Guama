import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../models/episode.dart';

/// Service for managing podcast audio playback
/// Handles play/pause, seek, next/previous, and background playback
class PodcastAudioService {
  final AudioPlayer _player = AudioPlayer();
  
  List<Episode> _playlist = [];
  int _currentIndex = -1;
  bool _isInitialized = false;

  // State getters
  Episode? get currentEpisode => _currentIndex >= 0 && _currentIndex < _playlist.length 
      ? _playlist[_currentIndex] 
      : null;
  
  int get currentIndex => _currentIndex;
  List<Episode> get playlist => List.unmodifiable(_playlist);
  bool get hasNext => _currentIndex < _playlist.length - 1;
  bool get hasPrevious => _currentIndex > 0;
  bool get isPlaying => _player.playing;
  ProcessingState get processingState => _player.processingState;
  Duration? get position => _player.position;
  Duration? get duration => _player.duration;

  /// Initialize the audio service
  Future<void> init() async {
    if (_isInitialized) return;
    
    // Configure audio session for background playback
    await _player.setAudioSession(await AudioSession.instance);
    
    // Listen to player state changes
    _player.playerStateStream.listen((state) {
      // Handle playback state changes
    });

    _player.processingStateStream.listen((state) {
      // Handle processing state changes
      if (state == ProcessingState.completed) {
        // Auto-play next episode when current one finishes
        if (hasNext) {
          playNext();
        }
      }
    });

    _isInitialized = true;
  }

  /// Set the playlist and optionally start playing from a specific index
  Future<void> setPlaylist(List<Episode> episodes, {int startIndex = 0}) async {
    _playlist = List.from(episodes);
    _currentIndex = startIndex.clamp(0, episodes.isNotEmpty ? episodes.length - 1 : 0);
    
    if (_playlist.isNotEmpty && _currentIndex >= 0) {
      await _loadEpisode(_playlist[_currentIndex]);
    }
  }

  /// Load a single episode
  Future<void> _loadEpisode(Episode episode) async {
    try {
      final audioSource = AudioSource.uri(
        Uri.parse(episode.audioUrl),
        tag: MediaItem(
          id: episode.id,
          title: episode.title,
          artist: episode.feedSource,
          artUri: episode.imageUrl != null ? Uri.parse(episode.imageUrl) : null,
          duration: episode.durationSeconds != null 
              ? Duration(seconds: episode.durationSeconds!) 
              : null,
        ),
      );
      
      await _player.setAudioSource(audioSource);
    } catch (e) {
      print('[PodcastAudio] Error loading episode: $e');
      rethrow;
    }
  }

  /// Start or resume playback
  Future<void> play() async {
    try {
      await _player.play();
    } catch (e) {
      print('[PodcastAudio] Error playing: $e');
      rethrow;
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      print('[PodcastAudio] Error pausing: $e');
      rethrow;
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Play the next episode in the playlist
  Future<void> playNext() async {
    if (!hasNext) return;
    
    _currentIndex++;
    await _loadEpisode(_playlist[_currentIndex]);
    await play();
  }

  /// Play the previous episode in the playlist
  Future<void> playPrevious() async {
    if (!hasPrevious) return;
    
    _currentIndex--;
    await _loadEpisode(_playlist[_currentIndex]);
    await play();
  }

  /// Seek to a specific position
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      print('[PodcastAudio] Seek error: $e');
    }
  }

  /// Seek by relative amount (e.g., forward/backward 15 seconds)
  Future<void> seekRelative(Duration offset) async {
    final newPosition = (_player.position + offset).clamp(
      Duration.zero,
      _player.duration ?? Duration.zero,
    );
    await seek(newPosition);
  }

  /// Skip forward 15 seconds
  Future<void> skipForward() => seekRelative(const Duration(seconds: 15));

  /// Skip backward 15 seconds
  Future<void> skipBackward() => seekRelative(const Duration(seconds: -15));

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Set playback speed (0.5 to 2.0)
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed.clamp(0.5, 2.0));
  }

  /// Stop playback and clear playlist
  Future<void> stop() async {
    try {
      await _player.stop();
      _playlist.clear();
      _currentIndex = -1;
    } catch (e) {
      print('[PodcastAudio] Error stopping: $e');
    }
  }

  /// Dispose of resources
  Future<void> dispose() async {
    await _player.dispose();
  }

  /// Get player state stream for reactive UI updates
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  
  /// Get processing state stream
  Stream<ProcessingState> get processingStateStream => _player.processingStateStream;
  
  /// Get position stream
  Stream<Duration> get positionStream => _player.positionStream;
}
