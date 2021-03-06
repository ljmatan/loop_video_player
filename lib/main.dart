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
    if (context != null)
      for (int i = 1; i < 4; i++)
        await precacheImage(AssetImage('assets/pictures/$i.png'), context);
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

  static final VideoPlayerController _controller1 =
      VideoPlayerController.asset(_video1)..setLooping(true);
  static final VideoPlayerController _controller2 =
      VideoPlayerController.asset(_video2)..setLooping(true);
  static final VideoPlayerController _controller3 =
      VideoPlayerController.asset(_video3)..setLooping(true);

  static VideoPlayerController _controller;
  static VideoPlayerController get controller => _controller;

  static Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();

    // Create and store the VideoPlayerControllers.
    _controller2.initialize();
    _controller3.initialize();

    // Initialize the controller and store the Future for later use.
    _initializeVideoPlayerFuture =
        _controller1.initialize().whenComplete(() async {
      _controller = _controller1;
      // Slow down the first video to 50% playback speed
      await _controller1.setPlaybackSpeed(0.5);
    });
  }

  static String _imageDisplayed;

  // Image preview time in seconds
  static const int _imagePreviewTime = 5;

  static bool _started = false;

  static String _videoToDisplay;

  Future<void> _loopVideos() async {
    _started = true;

    // Play the video
    _controller.play();
    // Wait until the video is finished
    await Future.delayed(_controller1.value.duration);
    // Pause the video
    _controller.pause();

    // Show buttons for video selection
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FlatButton(
                  color: Colors.blue,
                  child: const Text(
                    'Video 2',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    _videoToDisplay = _video2;
                    Navigator.pop(context);
                  },
                ),
                FlatButton(
                  color: Colors.blue,
                  child: const Text(
                    'Video 3',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    _videoToDisplay = _video3;
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
        // Ensures the buttons are not removed on back button press
        onWillPop: () async => false,
      ),
    );

    // Set image display
    setState(() => _imageDisplayed = _image1);

    // Display the first image for 5 seconds
    await Future.delayed(
      const Duration(seconds: _imagePreviewTime),
      // After 5 seconds, display the second image
      () => setState(() => _imageDisplayed = _image2),
    );

    await Future.delayed(const Duration(seconds: _imagePreviewTime));

    if (_videoToDisplay == null || _videoToDisplay == _video2) {
      // Remove the second image and play the video
      setState(() {
        _controller = _controller2;
        _imageDisplayed = null;
      });

      _controller.play();
      await Future.delayed(_controller2.value.duration);
    }

    if (_videoToDisplay == null || _videoToDisplay == _video3) {
      setState(() {
        if (_imageDisplayed != null) _imageDisplayed = null;
        _controller = _controller3;
      });

      _controller.play();
      await Future.delayed(_controller3.value.duration);
    }

    setState(() => _imageDisplayed = _image3);

    await Future.delayed(
      const Duration(seconds: _imagePreviewTime),
      () => setState(() {
        _started = false;
        _controller = _controller1;
        _imageDisplayed = null;
        _videoToDisplay = null;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        // If future throws exception display the error text
        if (snapshot.hasError)
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                snapshot.error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        else if (snapshot.connectionState == ConnectionState.done) {
          if (!_started) _loopVideos();
          return Center(
            child: _imageDisplayed != null
                ? Image.asset(_imageDisplayed)
                // If the VideoPlayerController has finished initialization, use
                // the data it provides to limit the aspect ratio of the video.
                : AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    // Use the VideoPlayer widget to display the video.
                    child: VideoPlayer(controller),
                  ),
          );
        } else
          // If the VideoPlayerController is still initializing, show a
          // loading spinner.
          return const Center(child: CircularProgressIndicator());
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
