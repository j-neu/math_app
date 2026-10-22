import 'dart:async';
import 'dart:io' show File;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'clip_player.dart';

class PlatformClipPlayer implements ClipPlayer {
  final AudioPlayer _player = AudioPlayer();
  final Map<String, String> _tempFiles = {};
  int _token = 0;

  PlatformClipPlayer() {
    // Asset keys are passed as-is ("assets/audio/...", "Research/...");
    // audioplayers' default 'assets/' prefix would double them.
    _player.audioCache = AudioCache(prefix: '');
  }

  @override
  Stream<void> get onComplete => _player.onPlayerComplete;

  @override
  Future<ClipResult> play(String asset) async {
    final token = ++_token;
    try {
      await _player.stop();
      Source source;
      if (defaultTargetPlatform == TargetPlatform.windows) {
        // audioplayers_windows doesn't resolve AssetSource paths reliably;
        // extract to a temp file once per asset and reuse.
        var path = _tempFiles[asset];
        if (path == null) {
          final data = await rootBundle.load(asset);
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/${asset.split('/').last}');
          await file.writeAsBytes(data.buffer.asUint8List());
          path = _tempFiles[asset] = file.path;
        }
        source = DeviceFileSource(path);
      } else {
        source = AssetSource(asset);
      }
      if (token != _token) return ClipResult.superseded;
      await _player.play(source);
      ClipPlayer.unlocked = true;
      return ClipResult.played;
    } catch (_) {
      return token == _token ? ClipResult.failed : ClipResult.superseded;
    }
  }

  @override
  Future<void> stop() async {
    _token++;
    await _player.stop();
  }

  @override
  Future<void> dispose() => _player.dispose();
}
