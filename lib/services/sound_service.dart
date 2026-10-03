import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Instrument modes for drawing feedback.
enum Instrument { xylophone, otamatone, theremin }

/// Real-time procedural sound for drawing.
/// Supports xylophone, otamatone (nasal wah) and theremin (gliding vibrato).
class SoundService {
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;
  SoundService._();

  final AudioPlayer _notePlayer = AudioPlayer();
  final AudioPlayer _fxPlayer = AudioPlayer();
  bool _ready = false;

  Instrument instrument = Instrument.xylophone;

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
      debugPrint('SoundService ready (xylo + otamatone + theremin)');
    } catch (e) {
      debugPrint('SoundService init error: $e');
    }
  }

  /// Play a note for the current instrument.
  /// [speed] 0..1 — used by otamatone/theremin for expression.
  Future<void> playColorNote(
    Color color, {
    double velocity = 1.0,
    double speed = 0.5,
  }) async {
    if (!_ready) return;
    final freq = _colorFreq[color.value] ?? 523.25;
    final vol = (0.3 + velocity.clamp(0.0, 1.0) * 0.5).clamp(0.0, 1.0);

    try {
      late Uint8List bytes;
      switch (instrument) {
        case Instrument.xylophone:
          bytes = _synthXylo(freq, duration: 0.30, volume: vol);
          break;
        case Instrument.otamatone:
          bytes = _synthOtamatone(freq, duration: 0.45, volume: vol, speed: speed);
          break;
        case Instrument.theremin:
          bytes = _synthTheremin(freq, duration: 0.55, volume: vol * 0.85, speed: speed);
          break;
      }
      await _notePlayer.stop();
      await _notePlayer.play(BytesSource(bytes));
    } catch (e) {
      debugPrint('playColorNote: $e');
    }
  }

  Future<void> playMagicSound() async {
    if (!_ready) return;
    try {
      await _fxPlayer.play(BytesSource(_synthChirp(duration: 0.55, volume: 0.4)));
    } catch (e) {
      debugPrint('playMagicSound: $e');
    }
  }

  Future<void> playSuccess() async {
    if (!_ready) return;
    try {
      await _fxPlayer.play(BytesSource(_synthSuccess(volume: 0.4)));
    } catch (_) {}
  }

  // ─── Xylophone ───────────────────────────────────────────
  /// Bright wooden hit, quick attack, fast decay.
  Uint8List _synthXylo(double freq, {double duration = 0.30, double volume = 0.4}) {
    const sr = 22050;
    final n = (sr * duration).round();
    final samples = Int16List(n);
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      final env = min(1.0, t * 50) * exp(-t * 8);
      final wave = sin(2 * pi * freq * t) * 0.8 +
          sin(2 * pi * freq * 2.02 * t) * 0.2;
      samples[i] = (volume * 32767 * env * wave).round().clamp(-32767, 32767);
    }
    return _toWav(samples, sr);
  }

  // ─── Otamatone ───────────────────────────────────────────
  /// Nasal "wah" character: square-ish wave + formant sweep + vibrato.
  Uint8List _synthOtamatone(
    double freq, {
    double duration = 0.45,
    double volume = 0.4,
    double speed = 0.5,
  }) {
    const sr = 22050;
    final n = (sr * duration).round();
    final samples = Int16List(n);

    // Faster strokes → more "wah" and higher vibrato depth
    final wahAmount = 0.3 + speed * 0.5;
    final vibDepth = 4.0 + speed * 8.0;

    for (int i = 0; i < n; i++) {
      final t = i / sr;
      final env = min(1.0, t * 20) * exp(-t * 3.5);

      // Vibrato
      final vib = sin(2 * pi * 5.5 * t) * vibDepth;
      final f = freq + vib;

      // Soft square (odd harmonics) for nasal body
      final phase = 2 * pi * f * t;
      var wave = sin(phase);
      wave += sin(phase * 3) / 3 * 0.7;
      wave += sin(phase * 5) / 5 * 0.4;

      // Simple formant-style amplitude modulation ("wah")
      final formant = 0.55 + wahAmount * 0.45 * sin(2 * pi * (2.0 + speed * 3) * t);
      wave *= formant;

      samples[i] = (volume * 32767 * env * wave).round().clamp(-32767, 32767);
    }
    return _toWav(samples, sr);
  }

  // ─── Theremin ────────────────────────────────────────────
  /// Pure sine with strong vibrato and slight pitch glide.
  Uint8List _synthTheremin(
    double freq, {
    double duration = 0.55,
    double volume = 0.35,
    double speed = 0.5,
  }) {
    const sr = 22050;
    final n = (sr * duration).round();
    final samples = Int16List(n);

    final vibRate = 5.0 + speed * 2.0;
    final vibDepth = 8.0 + speed * 12.0; // Hz
    final glide = freq * (0.04 + speed * 0.06); // start slightly below

    for (int i = 0; i < n; i++) {
      final t = i / sr;
      // Soft attack, long sustain feel
      final env = min(1.0, t * 8) * exp(-t * 2.2);

      // Pitch glide into the note
      final glideAmt = glide * exp(-t * 6);
      final vib = sin(2 * pi * vibRate * t) * vibDepth;
      final f = freq - glideAmt + vib;

      final wave = sin(2 * pi * f * t);
      samples[i] = (volume * 32767 * env * wave).round().clamp(-32767, 32767);
    }
    return _toWav(samples, sr);
  }

  // ─── FX ──────────────────────────────────────────────────
  Uint8List _synthChirp({double duration = 0.55, double volume = 0.35}) {
    const sr = 22050;
    final n = (sr * duration).round();
    final samples = Int16List(n);
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      final freq = 450 + 1400 * (t / duration);
      var env = exp(-t * 2.8);
      if (t > duration * 0.85) env *= (duration - t) / (duration * 0.15);
      samples[i] =
          (volume * 32767 * env * sin(2 * pi * freq * t)).round().clamp(-32767, 32767);
    }
    return _toWav(samples, sr);
  }

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
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, 1, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little);
    buffer.setUint16(32, 2, Endian.little);
    buffer.setUint16(34, 16, Endian.little);
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
