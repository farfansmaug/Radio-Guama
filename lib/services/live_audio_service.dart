import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../constants/env.dart';
import '../datasources/live_audio_remote_datasource.dart';

/// Service for managing live audio streaming
/// Handles play/pause, state management, and background playback
class LiveAudioService {
  final AudioPlayer _player = AudioPlayer();
  final LiveAudioRemoteDataSource _dataSource = LiveAudioRemoteDataSource();
  
  bool _isPlaying = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Stream URL getter
  String get streamUrl => _dataSource.streamUrl;

  // State getters
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ProcessingState get processingState => _player.processingState;
  Duration? get position => _player.position;
  Duration? get duration => _player.duration;

  /// Initialize the audio service
  Future<void> init() async {
    // Configure audio session for background playback
    await _player.setAudioSession(await AudioSession.instance);
    
    // Listen to player state changes
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      // Notify listeners of state change (could use streams/notifiers)
    });

    _player.processingStateStream.listen((state) {
      switch (state) {
        case ProcessingState.loading:
          _isLoading = true;
          _errorMessage = null;
          break;
        case ProcessingState.ready:
          _isLoading = false;
          _errorMessage = null;
          break;
        case ProcessingState.completed:
          _isLoading = false;
          break;
        default:
          _isLoading = false;
      }
    });

    _player.playerStateStream.listen((event) {
      if (_player.processingState == ProcessingState.completed) {
        // For live stream, we typically don't stop on completion
        // but could restart if needed
      }
    });
  }

  /// Start or resume playback
  Future<void> play() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      
      if (_player.audioSource == null) {
        // First time playing - set the audio source
        final audioSource = AudioSource.uri(
          Uri.parse(streamUrl),
          tag: MediaItem(
            id: 'live_stream',
            title: 'Radio Guamá En Vivo',
            artist: 'Radio Guamá',
            artUri: Uri.parse('https://www.radioguama.cu/logo.png'),
          ),
        );
        await _player.setAudioSource(audioSource);
      }
      
      await _player.play();
      _isPlaying = true;
    } catch (e) {
      _errorMessage = 'Error al iniciar el stream: $e';
      _isPlaying = false;
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      await _player.pause();
      _isPlaying = false;
    } catch (e) {
      _errorMessage = 'Error al pausar: $e';
      rethrow;
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Stop playback and release resources
  Future<void> stop() async {
    try {
      await _player.stop();
      _isPlaying = false;
      _isLoading = false;
    } catch (e) {
      _errorMessage = 'Error al detener: $e';
      rethrow;
    }
  }

  /// Seek to position (not typically used for live streams)
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      print('[LiveAudio] Seek error: $e');
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Set playback speed (0.5 to 2.0)
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed.clamp(0.5, 2.0));
  }

  /// Check if stream is available
  Future<bool> checkStreamAvailability() async {
    return await _dataSource.isStreamAvailable();
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
