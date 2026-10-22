import 'clip_player_io.dart'
    if (dart.library.js_interop) 'clip_player_web.dart' as impl;

/// Outcome of [ClipPlayer.play].
enum ClipResult {
  played,

  /// The browser refused to start audio without a tap (autoplay policy).
  blocked,

  /// A newer play() or stop() replaced this clip before it started.
  superseded,

  /// Missing file or decoder error.
  failed,
}

/// Plays one bundled audio clip at a time; a new clip stops the current one.
///
/// On web this uses a single, reused `<audio>` element. Once a tap has
/// started it, the browser lets later clips autoplay without another tap.
/// (audioplayers' web plugin builds a new element per clip and routes it
/// through a Web Audio context, which browsers keep muted without a tap.)
abstract class ClipPlayer {
  factory ClipPlayer() = impl.PlatformClipPlayer;

  /// True once any clip has played in this page. On web this means the
  /// browser has unlocked audio, so autoplay will work from here on.
  static bool unlocked = false;

  /// Starts [asset] (a bundled asset key such as
  /// "assets/audio/diagnostic/q1_frage.mp3"). On web, the clip is started
  /// synchronously, so calling this from a tap handler counts as a tap.
  Future<ClipResult> play(String asset);

  Future<void> stop();

  /// Fires when a clip plays to its end (not on stop or replacement).
  Stream<void> get onComplete;

  Future<void> dispose();
}
