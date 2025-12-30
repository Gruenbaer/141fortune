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
  
  @override
  void initState() {
    super.initState();
    // Initialize video from assets
    _controller = VideoPlayerController.asset('assets/images/FoulAndFortuneAnimated.mp4')
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized
        if (mounted) {
          setState(() {
            _initialized = true;
          });
          _controller.play();
          _controller.setLooping(true); // Loop video
          _controller.setVolume(0.0); // Enforce mute as requested
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      // Placeholder: Static Image (No clock!)
      return Center(
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent, // or Colors.black ??
            boxShadow: [
               BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
            ],
            border: Border.all(color: const Color(0xFFB8860B).withOpacity(0.5), width: 2), 
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/static_logo.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    return Center(
      child: Container(
        width: 200, // Reduced from 250 (-20%)
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Transparent background, effectively just the clip
          color: Colors.transparent,
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
          ],
          // Border can be kept or removed. "Rest transparent" might imply strictly the video?
          // I'll keep a thin border to define the 'Round' shape clearly against backgrounds
          border: Border.all(color: const Color(0xFFB8860B).withOpacity(0.5), width: 2), 
        ),
        child: ClipOval(
          child: FittedBox(
            fit: BoxFit.cover, 
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
        ),
      ),
    );
  }
}
