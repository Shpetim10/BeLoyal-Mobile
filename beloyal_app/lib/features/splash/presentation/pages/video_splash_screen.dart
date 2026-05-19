import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/widgets/besa_loader.dart';

class VideoSplashScreen extends StatefulWidget {
  final bool isAppReady;
  final VoidCallback onVideoFinished;

  const VideoSplashScreen({
    super.key,
    required this.isAppReady,
    required this.onVideoFinished,
  });

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;
  bool _isVideoCompleted = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize subtle loading animation (opacity pulse)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialize Video
    _controller =
        VideoPlayerController.asset(
            'assets/animation/besahub_splash_screen.mp4',
          )
          ..initialize().then((_) {
            if (mounted) {
              setState(() {
                _isVideoInitialized = true;
              });
              // Ensuring no silent audio glitch
              _controller.setVolume(0.0);
              _controller.play();
            }
          });

    _controller.addListener(_videoListener);
  }

  void _videoListener() {
    if (!_isVideoCompleted && _isVideoInitialized) {
      final position = _controller.value.position;
      final duration = _controller.value.duration;

      // Check if video has reached its end (with a tiny buffer to catch edge cases)
      if (position >= duration && duration > Duration.zero) {
        if (mounted) {
          setState(() {
            _isVideoCompleted = true;
          });
          widget.onVideoFinished();
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Slate 900 background to perfectly match the dark theme and avoid white flash
    const bgColor = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fallback background color before video initializes
          Container(color: bgColor),

          // Main Video Player
          if (_isVideoInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),

          // Loader Overlay when video completes but app is still initializing
          if (_isVideoCompleted && !widget.isAppReady)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _pulseAnimation,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BesaLoader(size: 32),
                    SizedBox(height: 16),
                    Text(
                      'Optimizing your experience...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
