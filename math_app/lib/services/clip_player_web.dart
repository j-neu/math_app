import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

import 'clip_player.dart';

class PlatformClipPlayer implements ClipPlayer {
  final web.HTMLAudioElement _el = web.HTMLAudioElement()..preload = 'auto';
  final _complete = StreamController<void>.broadcast();
  late final StreamSubscription<web.Event> _endedSub;
  int _token = 0;

  PlatformClipPlayer() {
    _endedSub = _el.onEnded.listen((_) => _complete.add(null));
  }

  @override
  Stream<void> get onComplete => _complete.stream;

  @override
  Future<ClipResult> play(String asset) async {
    final token = ++_token;
    // Everything up to play() runs synchronously, so a tap handler that
    // calls this still counts as the user gesture the browser needs.
    _el.pause();
    _el.src = ui_web.assetManager.getAssetUrl(asset);
    try {
      await _el.play().toDart;
      ClipPlayer.unlocked = true;
      return ClipResult.played;
    } catch (e) {
      if (token != _token) return ClipResult.superseded;
      if (e.toString().contains('NotAllowedError')) return ClipResult.blocked;
      return ClipResult.failed;
    }
  }

  @override
  Future<void> stop() async {
    _token++;
    _el.pause();
  }

  @override
  Future<void> dispose() async {
    _token++;
    _el.pause();
    _el.removeAttribute('src');
    await _endedSub.cancel();
    await _complete.close();
  }
}
