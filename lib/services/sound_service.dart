import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Simple real-time sound feedback for drawing.
/// Maps color → musical note (xylophone style).
class SoundService {
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;
  SoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool _ready = false;

  // Approximate frequencies for a bright xylophone feel (C major)
  static const Map<int, double> _noteFreq = {
    0xFFFF6B6B: 523.25, // C5 Red
    0xFFFFD93D: 587.33, // D5 Yellow
    0xFF6BCB77: 659.25, // E5 Green
    0xFF4D96FF: 698.46, // F5 Blue
    0xFF9B59B6: 783.99, // G5 Purple
    0xFFFF8C42: 880.00, // A5 Orange
  };

  Future<void> init() async {
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(0.7);
      _ready = true;
    } catch (e) {
      debugPrint('SoundService init error: $e');
    }
  }

  /// Play a short note for the given color.
  /// In production this will use pre-rendered samples or a synth.
  Future<void> playColorNote(Color color, {double velocity = 1.0}) async {
    if (!_ready) return;

    final freq = _noteFreq[color.value] ?? 523.25;

    // Temporary: we trigger a short system-like feedback.
    // Real implementation will load .wav samples from assets/sounds/
    // or use a pure Dart synth / flutter_soloud / just_audio + generated tones.
    try {
      // Placeholder for real sample playback
      // await _player.play(AssetSource('sounds/xylo_${freq.round()}.wav'));
      debugPrint('♪ Playing note ${freq.toStringAsFixed(1)} Hz for color ${color.value.toRadixString(16)}');
    } catch (e) {
      debugPrint('playColorNote error: $e');
    }
  }

  Future<void> playMagicSound() async {
    // Special sound for AI transformation
    debugPrint('✨ Magic transformation sound');
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}

// Temporary helper so we can import Color without circular deps
class Color {
  final int value;
  const Color(this.value);
}
