import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoLogo extends StatefulWidget {
  const VideoLogo({super.key});

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
    _controller = VideoPlayerController.asset('assets/images/ani_logo_Fortune141_01.mp4')
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized
        if (mounted) {
          setState(() {
            _initialized = true;
          });
          _controller.play();
          _controller.setLooping(true);
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
