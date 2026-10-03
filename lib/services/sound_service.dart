import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Real-time sound feedback for drawing.
/// Each color maps to a xylophone-style note.
class SoundService {
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;
  SoundService._();

  final AudioPlayer _notePlayer = AudioPlayer();
  final AudioPlayer _magicPlayer = AudioPlayer();
  bool _ready = false;

  // Color value → note name (for sample lookup)
  static const Map<int, String> _colorToNote = {
    0xFFFF6B6B: 'c5', // Red
    0xFFFFD93D: 'd5', // Yellow
    0xFF6BCB77: 'e5', // Green
    0xFF4D96FF: 'f5', // Blue
    0xFF9B59B6: 'g5', // Purple
    0xFFFF8C42: 'a5', // Orange
  };

  Future<void> init() async {
    try {
      await _notePlayer.setReleaseMode(ReleaseMode.stop);
      await _notePlayer.setVolume(0.75);
      await _magicPlayer.setReleaseMode(ReleaseMode.stop);
      await _magicPlayer.setVolume(0.85);
      _ready = true;
      debugPrint('SoundService ready');
    } catch (e) {
      debugPrint('SoundService init error: $e');
    }
  }

  /// Play a short xylophone-style note for the given color.
  Future<void> playColorNote(Color color, {double velocity = 1.0}) async {
    if (!_ready) return;

    final note = _colorToNote[color.value] ?? 'c5';
    final vol = (0.4 + velocity.clamp(0.0, 1.0) * 0.5).clamp(0.0, 1.0);

    try {
      await _notePlayer.setVolume(vol);
      // Tries to play sample. If file missing, fails silently.
      await _notePlayer.play(AssetSource('sounds/xylo_$note.wav'));
    } catch (e) {
      // Sample not present yet — expected during development
      debugPrint('♪ $note (sample missing)');
    }
  }

  /// Magical transformation sound (AI complete).
  Future<void> playMagicSound() async {
    if (!_ready) return;
    try {
      await _magicPlayer.play(AssetSource('sounds/magic_sparkle.wav'));
    } catch (e) {
      debugPrint('✨ Magic sound (sample missing)');
    }
  }

  /// Soft success chime.
  Future<void> playSuccess() async {
    if (!_ready) return;
    try {
      await _magicPlayer.play(AssetSource('sounds/success.wav'));
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _notePlayer.dispose();
    await _magicPlayer.dispose();
  }
}
