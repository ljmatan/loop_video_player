import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Loop Video Player',
      home: LoopVideoPlayer(),
    );
  }
}

class LoopVideoPlayer extends StatefulWidget {
  LoopVideoPlayer({Key key}) : super(key: key);

  @override
  _LoopVideoPlayerState createState() => _LoopVideoPlayerState();
}

class _LoopVideoPlayerState extends State<LoopVideoPlayer> {
  final VideoPlayerController _controller1 =
      VideoPlayerController.asset('assets/videos/running.mp4')
        ..setLooping(true);
  final VideoPlayerController _controller2 =
      VideoPlayerController.asset('assets/videos/running2.mp4')
        ..setLooping(true);
  final VideoPlayerController _controller3 =
      VideoPlayerController.asset('assets/videos/running3.mp4')
        ..setLooping(true);

  VideoPlayerController _controller;
  VideoPlayerController get controller => _controller;

  Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();

    // Create and store the VideoPlayerController. The VideoPlayerController
    // offers several different constructors to play videos from assets, files,
    // or the internet.
    _controller2.initialize();
    _controller3.initialize();

    // Initialize the controller and store the Future for later use.
    _initializeVideoPlayerFuture = _controller1
        .initialize()
        .whenComplete(() => _controller = _controller1);
  }

  String _imageDisplayed;

  bool _started = false;

  Future<void> _loopVideos() async {
    if (!_started) {
      _started = true;

      // Play the video
      _controller.play();

      await Future.delayed(_controller1.value.duration)
          .whenComplete(() => _controller1.seekTo(const Duration()));

      // Set image display
      setState(() => _imageDisplayed = 'assets/pictures/1.png');

      // Display the first image for 5 seconds
      await Future.delayed(
        const Duration(seconds: 5),
        // After 5 seconds, display the second image
        () => setState(() => _imageDisplayed = 'assets/pictures/2.png'),
      );
      await Future.delayed(
          const Duration(seconds: 5),
          // Remove the second image and play the video
          () => setState(() {
                _controller = _controller2;
                _imageDisplayed = null;
              }));

      _controller.play();
      await Future.delayed(_controller2.value.duration)
          .whenComplete(() => _controller2.seekTo(const Duration()));

      setState(() => _controller = _controller3);
      _controller.play();
      await Future.delayed(_controller3.value.duration)
          .whenComplete(() => _controller3.seekTo(const Duration()));

      setState(() => _imageDisplayed = 'assets/pictures/3.png');
      await Future.delayed(const Duration(seconds: 5), () {
        _started = false;
        setState(() {
          _controller = _controller1;
          _imageDisplayed = null;
        });
        // Run the function again after the 3rd video had finished playing
        _loopVideos();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the VideoPlayerController has finished initialization, use
            // the data it provides to limit the aspect ratio of the video.
            _loopVideos();
            return Center(
              child: _imageDisplayed != null
                  ? Image.asset(_imageDisplayed)
                  : Builder(
                      builder: (context) => AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        // Use the VideoPlayer widget to display the video.
                        child: VideoPlayer(controller),
                      ),
                    ),
            );
          } else {
            // If the VideoPlayerController is still initializing, show a
            // loading spinner.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    // Ensure disposing of the VideoPlayerController to free up resources.
    _controller.dispose();
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }
}
