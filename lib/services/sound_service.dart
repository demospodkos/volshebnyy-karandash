import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Real-time xylophone-style sound for drawing.
/// Generates WAV tones in memory — no external sample files required.
class SoundService {
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;
  SoundService._();

  final AudioPlayer _notePlayer = AudioPlayer();
  final AudioPlayer _fxPlayer = AudioPlayer();
  bool _ready = false;

  static const Map<int, double> _colorFreq = {
    0xFFFF6B6B: 523.25, // C5 Red
    0xFFFFD93D: 587.33, // D5 Yellow
    0xFF6BCB77: 659.25, // E5 Green
    0xFF4D96FF: 698.46, // F5 Blue
    0xFF9B59B6: 783.99, // G5 Purple
    0xFFFF8C42: 880.00, // A5 Orange
  };

  Future<void> init() async {
    try {
      await _notePlayer.setReleaseMode(ReleaseMode.stop);
      await _fxPlayer.setReleaseMode(ReleaseMode.stop);
      _ready = true;
      debugPrint('SoundService ready (procedural tones)');
    } catch (e) {
      debugPrint('SoundService init error: $e');
    }
  }

  Future<void> playColorNote(Color color, {double velocity = 1.0}) async {
    if (!_ready) return;
    final freq = _colorFreq[color.value] ?? 523.25;
    final vol = (0.35 + velocity.clamp(0.0, 1.0) * 0.45).clamp(0.0, 1.0);
    try {
      final bytes = _synthXylo(freq, duration: 0.32, volume: vol);
      await _notePlayer.stop();
      await _notePlayer.play(BytesSource(bytes));
    } catch (e) {
      debugPrint('playColorNote: $e');
    }
  }

  Future<void> playMagicSound() async {
    if (!_ready) return;
    try {
      final bytes = _synthChirp(duration: 0.55, volume: 0.4);
      await _fxPlayer.play(BytesSource(bytes));
    } catch (e) {
      debugPrint('playMagicSound: $e');
    }
  }

  Future<void> playSuccess() async {
    if (!_ready) return;
    try {
      final bytes = _synthSuccess(volume: 0.4);
      await _fxPlayer.play(BytesSource(bytes));
    } catch (_) {}
  }

  /// Soft xylophone-like tone with quick attack and exponential decay.
  Uint8List _synthXylo(double freq, {double duration = 0.32, double volume = 0.4}) {
    const sr = 22050;
    final n = (sr * duration).round();
    final samples = Int16List(n);
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      final env = min(1.0, t * 45) * exp(-t * 7);
      // slight overtone for wooden character
      final wave = sin(2 * pi * freq * t) * 0.85 +
          sin(2 * pi * freq * 2.01 * t) * 0.15;
      samples[i] = (volume * 32767 * env * wave).round().clamp(-32767, 32767);
    }
    return _toWav(samples, sr);
  }

  /// Rising sparkle for magic transformation.
  Uint8List _synthChirp({double duration = 0.55, double volume = 0.35}) {
    const sr = 22050;
    final n = (sr * duration).round();
    final samples = Int16List(n);
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      final freq = 450 + 1400 * (t / duration);
      var env = exp(-t * 2.8);
      if (t > duration * 0.85) {
        env *= (duration - t) / (duration * 0.15);
      }
      samples[i] =
          (volume * 32767 * env * sin(2 * pi * freq * t)).round().clamp(-32767, 32767);
    }
    return _toWav(samples, sr);
  }

  /// Two-note success chime.
  Uint8List _synthSuccess({double volume = 0.4}) {
    const sr = 22050;
    const duration = 0.5;
    final n = (sr * duration).round();
    final samples = Int16List(n);
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      final freq = t < 0.2 ? 659.25 : 880.0;
      final localT = t < 0.2 ? t : t - 0.2;
      final env = exp(-localT * 6) * volume;
      samples[i] =
          (32767 * env * sin(2 * pi * freq * t)).round().clamp(-32767, 32767);
    }
    return _toWav(samples, sr);
  }

  /// Build a minimal mono 16-bit PCM WAV.
  Uint8List _toWav(Int16List samples, int sampleRate) {
    final dataSize = samples.length * 2;
    final buffer = ByteData(44 + dataSize);

    void writeString(int offset, String s) {
      for (int i = 0; i < s.length; i++) {
        buffer.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    writeString(0, 'RIFF');
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little); // PCM chunk size
    buffer.setUint16(20, 1, Endian.little); // audio format = PCM
    buffer.setUint16(22, 1, Endian.little); // mono
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    buffer.setUint16(32, 2, Endian.little); // block align
    buffer.setUint16(34, 16, Endian.little); // bits per sample
    writeString(36, 'data');
    buffer.setUint32(40, dataSize, Endian.little);

    for (int i = 0; i < samples.length; i++) {
      buffer.setInt16(44 + i * 2, samples[i], Endian.little);
    }
    return buffer.buffer.asUint8List();
  }

  Future<void> dispose() async {
    await _notePlayer.dispose();
    await _fxPlayer.dispose();
  }
}
