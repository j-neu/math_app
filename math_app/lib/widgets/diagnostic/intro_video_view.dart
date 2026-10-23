import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// The intro video, shown before a new diagnostic starts (web only).
///
/// The child taps ▶ to start it: browsers only play sound after a tap.
/// When it ends, "Los geht's!" calls [onStart], and that tap also lets the
/// first question's audio play. If the video can't load, the child gets
/// "Los geht's!" straight away.
///
/// With [canSkip] (the child has started this diagnostic before), a
/// "Video überspringen" button under the video goes straight to [onStart].
class IntroVideoView extends StatefulWidget {
  final VoidCallback onStart;
  final bool canSkip;

  /// Where the video is served. `math_app/web/intro_video.mp4` is copied
  /// to the site root by `flutter build web`.
  final Uri? videoUrl;

  const IntroVideoView({
    super.key,
    required this.onStart,
    this.canSkip = false,
    this.videoUrl,
  });

  @override
  State<IntroVideoView> createState() => _IntroVideoViewState();
}

enum _Phase { loading, ready, playing, finished, failed }

class _IntroVideoViewState extends State<IntroVideoView> {
  static const _green = Color(0xFF4CAF50);

  late final VideoPlayerController _controller;
  _Phase _phase = _Phase.loading;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      widget.videoUrl ?? Uri.base.resolve('/intro_video.mp4'),
    );
    _controller.addListener(_onVideoChanged);
    _controller.initialize().then((_) {
      if (mounted) setState(() => _phase = _Phase.ready);
    }, onError: (Object e) {
      debugPrint('intro video failed: $e');
      if (mounted) setState(() => _phase = _Phase.failed);
    });
  }

  void _onVideoChanged() {
    final v = _controller.value;
    if (v.hasError && _phase != _Phase.failed) {
      setState(() => _phase = _Phase.failed);
      return;
    }
    if (_phase == _Phase.playing && v.isInitialized && v.isCompleted) {
      setState(() => _phase = _Phase.finished);
    }
  }

  /// Called straight from a tap: play() must start before any await, or
  /// the browser no longer counts it as a tap and mutes the sound.
  void _play() {
    setState(() => _phase = _Phase.playing);
    _controller.play(); // rewinds by itself when the video has ended
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _Phase.failed) {
      return Center(child: _startButton());
    }
    return LayoutBuilder(builder: (context, constraints) {
      // Leave room for the buttons below the video.
      final maxWidth = (constraints.maxHeight - 140) * 16 / 9;
      final width = maxWidth.clamp(280.0, constraints.maxWidth - 32).clamp(0.0, 1100.0);
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: width,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const ColoredBox(color: Colors.black),
                        if (_phase != _Phase.loading) VideoPlayer(_controller),
                        if (_phase == _Phase.loading)
                          const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        if (_phase == _Phase.ready) _bigPlayOverlay(),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (widget.canSkip && _phase != _Phase.finished)
                OutlinedButton.icon(
                  // Straight from the tap, so the question audio may play.
                  onPressed: () {
                    _controller.pause();
                    widget.onStart();
                  },
                  icon: const Icon(Icons.skip_next_rounded, size: 28),
                  label: const Text('Video überspringen'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 18),
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                ),
              if (_phase == _Phase.finished)
                Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _play,
                      icon: const Icon(Icons.replay_rounded, size: 28),
                      label: const Text('Nochmal ansehen'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 18),
                        textStyle: const TextStyle(fontSize: 20),
                      ),
                    ),
                    _startButton(),
                  ],
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _bigPlayOverlay() {
    return Material(
      color: Colors.black38,
      child: InkWell(
        onTap: _play,
        child: Center(
          child: Semantics(
            button: true,
            label: 'Video abspielen',
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: _green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  size: 96, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _startButton() {
    return FilledButton.icon(
      onPressed: widget.onStart,
      icon: const Icon(Icons.play_arrow_rounded, size: 40),
      label: const Text("Los geht's!"),
      style: FilledButton.styleFrom(
        backgroundColor: _green,
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
        textStyle: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      ),
    );
  }
}
