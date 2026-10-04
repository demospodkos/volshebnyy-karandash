import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum Instrument { xylophone, otamatone, theremin }

/// Continuous procedural sound while the finger draws.
class SoundService {
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;
  SoundService._();

  final AudioPlayer _notePlayer = AudioPlayer();
  final AudioPlayer _fxPlayer = AudioPlayer();
  bool _ready = false;
  bool _isDrawing = false;
  DateTime _lastPlay = DateTime.fromMillisecondsSinceEpoch(0);

  Instrument instrument = Instrument.xylophone;

  static const Map<int, double> _colorFreq = {
    0xFFFF6B6B: 523.25,
    0xFFFFD93D: 587.33,
    0xFF6BCB77: 659.25,
    0xFF4D96FF: 698.46,
    0xFF9B59B6: 783.99,
    0xFFFF8C42: 880.00,
  };

  Future<void> init() async {
    try {
      await _notePlayer.setReleaseMode(ReleaseMode.stop);
      await _fxPlayer.setReleaseMode(ReleaseMode.stop);
      _ready = true;
    } catch (e) {
      debugPrint('SoundService init error: $e');
    }
  }

  /// Finger down — start continuous tone.
  Future<void> startDrawing(Color color, {double speed = 0.4}) async {
    _isDrawing = true;
    await _playNow(color, velocity: 0.8, speed: speed, continuous: true);
  }

  /// Finger moving — keep tone alive (re-triggers often).
  Future<void> whileDrawing(Color color, {double speed = 0.5}) async {
    if (!_isDrawing || !_ready) return;

    final intervalMs = switch (instrument) {
      Instrument.xylophone => 90,
      Instrument.otamatone => 70,
      Instrument.theremin => 55,
    };

    final now = DateTime.now();
    if (now.difference(_lastPlay).inMilliseconds < intervalMs) return;

    await _playNow(
      color,
      velocity: 0.55 + speed * 0.35,
      speed: speed,
      continuous: true,
    );
  }

  /// Finger up — stop sound.
  Future<void> stopDrawing() async {
    _isDrawing = false;
    try {
      await _notePlayer.stop();
    } catch (_) {}
  }

  Future<void> playColorNote(
    Color color, {
    double velocity = 1.0,
    double speed = 0.5,
  }) async {
    await _playNow(color, velocity: velocity, speed: speed, continuous: false);
  }

  Future<void> _playNow(
    Color color, {
    required double velocity,
    required double speed,
    required bool continuous,
  }) async {
    if (!_ready) return;
    final freq = _colorFreq[color.value] ?? 523.25;
    final vol = (0.28 + velocity.clamp(0.0, 1.0) * 0.5).clamp(0.0, 1.0);

    try {
      late Uint8List bytes;
      switch (instrument) {
        case Instrument.xylophone:
          bytes = _synthXylo(freq, duration: continuous ? 0.22 : 0.30, volume: vol);
          break;
        case Instrument.otamatone:
          bytes = _synthOtamatone(
            freq,
            duration: continuous ? 0.28 : 0.45,
            volume: vol,
            speed: speed,
            sustain: continuous,
          );
          break;
        case Instrument.theremin:
          bytes = _synthTheremin(
            freq,
            duration: continuous ? 0.32 : 0.55,
            volume: vol * 0.9,
            speed: speed,
            sustain: continuous,
          );
          break;
      }
      _lastPlay = DateTime.now();
      if (instrument == Instrument.xylophone || !continuous) {
        await _notePlayer.stop();
      }
      await _notePlayer.play(BytesSource(bytes));
    } catch (e) {
      debugPrint('play: $e');
    }
  }

  Future<void> playMagicSound() async {
    if (!_ready) return;
    try {
      await _fxPlayer.play(BytesSource(_synthChirp(duration: 0.55, volume: 0.4)));
    } catch (_) {}
  }

  Future<void> playSuccess() async {
    if (!_ready) return;
    try {
      await _fxPlayer.play(BytesSource(_synthSuccess(volume: 0.4)));
    } catch (_) {}
  }

  Uint8List _synthXylo(double freq, {double duration = 0.22, double volume = 0.4}) {
    const sr = 22050;
    final n = (sr * duration).round();
    final samples = Int16List(n);
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      final env = min(1.0, t * 55) * exp(-t * 10);
      final wave = sin(2 * pi * freq * t) * 0.8 +
          sin(2 * pi * freq * 2.02 * t) * 0.2;
      samples[i] = (volume * 32767 * env * wave).round().clamp(-32767, 32767);
    }
    return _toWav(samples, sr);
  }

  Uint8List _synthOtamatone(
    double freq, {
    double duration = 0.28,
    double volume = 0.4,
    double speed = 0.5,
    bool sustain = false,
  }) {
    const sr = 22050;
    final n = (sr * duration).round();
    final samples = Int16List(n);
    final wahAmount = 0.3 + speed * 0.5;
    final vibDepth = 4.0 + speed * 8.0;
    final decay = sustain ? 1.8 : 3.5;

    for (int i = 0; i < n; i++) {
      final t = i / sr;
      final attack = min(1.0, t * 25);
      final release = sustain
          ? (t > duration * 0.7 ? (duration - t) / (duration * 0.3) : 1.0)
          : 1.0;
      final env = attack * exp(-t * decay) * release;

      final vib = sin(2 * pi * 5.5 * t) * vibDepth;
      final f = freq + vib;
      final phase = 2 * pi * f * t;
      var wave = sin(phase) + sin(phase * 3) / 3 * 0.7 + sin(phase * 5) / 5 * 0.4;
      wave *= 0.55 + wahAmount * 0.45 * sin(2 * pi * (2.0 + speed * 3) * t);

      samples[i] = (volume * 32767 * env * wave).round().clamp(-32767, 32767);
    }
    return _toWav(samples, sr);
  }

  Uint8List _synthTheremin(
    double freq, {
    double duration = 0.32,
    double volume = 0.35,
    double speed = 0.5,
    bool sustain = false,
  }) {
    const sr = 22050;
    final n = (sr * duration).round();
    final samples = Int16List(n);
    final vibRate = 5.0 + speed * 2.0;
    final vibDepth = 8.0 + speed * 12.0;
    final decay = sustain ? 1.2 : 2.2;

    for (int i = 0; i < n; i++) {
      final t = i / sr;
      final attack = min(1.0, t * 12);
      final release = sustain
          ? (t > duration * 0.65 ? (duration - t) / (duration * 0.35) : 1.0)
          : 1.0;
      final env = attack * exp(-t * decay) * release;
      final vib = sin(2 * pi * vibRate * t) * vibDepth;
      samples[i] = (volume * 32767 * env * sin(2 * pi * (freq + vib) * t))
          .round()
          .clamp(-32767, 32767);
    }
    return _toWav(samples, sr);
  }

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
      samples[i] =
          (32767 * exp(-localT * 6) * volume * sin(2 * pi * freq * t))
              .round()
              .clamp(-32767, 32767);
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
