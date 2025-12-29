import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoLogo extends StatefulWidget {
  final VoidCallback? onUserInteraction;
  final bool soundEnabled;
  
  const VideoLogo({super.key, this.onUserInteraction, this.soundEnabled = true});

  @override
  State<VideoLogo> createState() => _VideoLogoState();
}

class _VideoLogoState extends State<VideoLogo> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  static bool _hasPlayedSound = false; // Track if sound has ever played
  bool _isFadingOut = false;

  @override
  void initState() {
    super.initState();
    // Initialize video from assets
    _controller = VideoPlayerController.asset('assets/images/ani_logo_Fortune141_01.mp4')
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized
        if (mounted) {
          setState(() {
            _initialized = true;
          });
          _controller.play();
          _controller.setLooping(true); // Loop video
          
          // Only play sound on first cold start AND if sound is enabled
          if (!_hasPlayedSound && widget.soundEnabled) {
            _controller.setVolume(0.0); // // Start with full volume
            _hasPlayedSound = true; // Mark as played
            
            // Add listener to fade out sound after first play
            _controller.addListener(_handleVideoProgress);
          } else {
            _controller.setVolume(0.0); // Mute if already played
          }
        }
      });
  }

  
  void _handleVideoProgress() {
    if (_controller.value.isPlaying && !_isFadingOut) {
      final position = _controller.value.position.inMilliseconds;
      final duration = _controller.value.duration.inMilliseconds;
      
      // Start fading out at 80% of first playthrough
      if (position > duration * 0.8 && position < duration) {
        final fadeProgress = (position - duration * 0.8) / (duration * 0.2);
        _controller.setVolume((1.0 - fadeProgress).clamp(0.0, 1.0));
      } else if (position >= duration) {
        // Mute after first play
        _controller.setVolume(0.0);
        _controller.removeListener(_handleVideoProgress);
      }
    }
  }
  
  void fadeOutSound() {
    if (!_isFadingOut && _controller.value.volume > 0) {
      setState(() {
        _isFadingOut = true;
      });
      
      // Quick fade out over 500ms
      final startVolume = _controller.value.volume;
      final startTime = DateTime.now();
      
      void fade() {
        if (!mounted) return;
        
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;
        final progress = (elapsed / 500).clamp(0.0, 1.0);
        final newVolume = (startVolume * (1.0 - progress)).clamp(0.0, 1.0);
        
        _controller.setVolume(newVolume);
        
        if (progress < 1.0) {
          Future.delayed(const Duration(milliseconds: 16), fade);
        } else {
          _controller.removeListener(_handleVideoProgress);
        }
      }
      
      fade();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleVideoProgress);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      // Fallback or Loading while initializing (using app_logo as placeholder to prevent jump)
      return Image.asset(
        'assets/images/app_logo.png',
        width: 250,
        height: 250,
        fit: BoxFit.contain,
      );
    }

    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 5)),
          ],
          border: Border.all(color: const Color(0xFFB8860B), width: 4), // Brass Ring
        ),
        child: ClipOval(
          child: FittedBox(
            fit: BoxFit.cover, 
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              // Scale up by 15% to crop out white borders (zooming in)
              child: Transform.scale(
                scale: 1.15, 
                child: VideoPlayer(_controller),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
