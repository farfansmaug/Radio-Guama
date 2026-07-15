import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/providers.dart';
import '../../core/constants/app_constants.dart';

/// Persistent floating action button for live audio control
/// Appears on all screens and maintains global audio state
class PersistentAudioFAB extends ConsumerStatefulWidget {
  const PersistentAudioFAB({super.key});

  @override
  ConsumerState<PersistentAudioFAB> createState() => _PersistentAudioFABState();
}

class _PersistentAudioFABState extends ConsumerState<PersistentAudioFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = ScaleTween(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(liveAudioStateProvider);
    
    // Animate when playing state changes
    if (audioState.isPlaying) {
      _animationController.repeat(reverse: true);
    } else {
      _animationController.stop();
      _animationController.reset();
    }

    return GestureDetector(
      onTap: () {
        ref.read(liveAudioStateProvider.notifier).togglePlayPause();
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Animated sound waves (when playing)
            if (audioState.isPlaying) ...[
              _SoundWave(animationController: _animationController, delay: 0),
              _SoundWave(animationController: _animationController, delay: 0.2),
              _SoundWave(animationController: _animationController, delay: 0.4),
            ],
            
            // Center icon
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  ref.read(liveAudioStateProvider.notifier).togglePlayPause();
                },
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: audioState.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          audioState.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated sound wave indicator
class _SoundWave extends StatelessWidget {
  final AnimationController animationController;
  final double delay;

  const _SoundWave({
    required this.animationController,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final value = (animationController.value + delay) % 1.0;
        final scale = 1.0 + (value * 0.5);
        final opacity = 1.0 - value;
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(opacity * 0.5),
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }
}

class ScaleTween extends Tween<double> {
  ScaleTween({required double begin, required double end}) 
      : super(begin: begin, end: end);
}
