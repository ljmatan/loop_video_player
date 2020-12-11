import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

void main() {
  // Go full screen
  // SystemChrome.setEnabledSystemUIOverlays([]);

  // Define your own status and / or main bar colors
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.black,
  ));

  // Precache images
  final binding = WidgetsFlutterBinding.ensureInitialized();
  binding.addPostFrameCallback((_) async {
    BuildContext context = binding.renderViewElement;
    if (context != null) {
      for (int i = 1; i < 4; i++) {
        await precacheImage(AssetImage('assets/pictures/$i.png'), context);
      }
    }
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Loop Video Player',
      home: Scaffold(
        backgroundColor: Colors.black,
        body: LoopVideoPlayer(),
      ),
    );
  }
}

class LoopVideoPlayer extends StatefulWidget {
  LoopVideoPlayer({Key key}) : super(key: key);

  @override
  _LoopVideoPlayerState createState() => _LoopVideoPlayerState();
}

class _LoopVideoPlayerState extends State<LoopVideoPlayer> {
  // Video files
  static const String _video1 = 'assets/videos/running.mp4';
  static const String _video2 = 'assets/videos/running2.mp4';
  static const String _video3 = 'assets/videos/running3.mp4';

  // Image files
  static const String _image1 = 'assets/pictures/1.png';
  static const String _image2 = 'assets/pictures/2.png';
  static const String _image3 = 'assets/pictures/3.png';

  final VideoPlayerController _controller1 =
      VideoPlayerController.asset(_video1)..setLooping(true);
  final VideoPlayerController _controller2 =
      VideoPlayerController.asset(_video2)..setLooping(true);
  final VideoPlayerController _controller3 =
      VideoPlayerController.asset(_video3)..setLooping(true);

  VideoPlayerController _controller;
  VideoPlayerController get controller => _controller;

  Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();

    // Create and store the VideoPlayerControllers.
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

      await Future.delayed(_controller1.value.duration);
      _controller1.seekTo(const Duration());

      // Set image display
      setState(() => _imageDisplayed = _image1);

      // Display the first image for 5 seconds
      await Future.delayed(
        const Duration(seconds: 5),
        // After 5 seconds, display the second image
        () => setState(() => _imageDisplayed = _image2),
      );

      await Future.delayed(
          const Duration(seconds: 5),
          // Remove the second image and play the video
          () => setState(() {
                _controller = _controller2;
                _imageDisplayed = null;
              }));

      _controller.play();
      await Future.delayed(_controller2.value.duration);
      _controller2.seekTo(const Duration());

      setState(() => _controller = _controller3);
      _controller.play();
      await Future.delayed(_controller3.value.duration);
      _controller3.seekTo(const Duration());

      setState(() => _imageDisplayed = _image3);
      await Future.delayed(const Duration(seconds: 5), () {
        _started = false;
        setState(() {
          _controller = _controller1;
          _imageDisplayed = null;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        // If future has error display the error text
        if (snapshot.hasError)
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                snapshot.error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        else if (snapshot.connectionState == ConnectionState.done) {
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
    );
  }

  @override
  void dispose() {
    // Ensure disposing of the VideoPlayerController to free up resources.
    _controller.dispose();
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();

    // Exit fullscreen
    // SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);

    super.dispose();
  }
}
