import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum Instrument { xylophone, otamatone, theremin }

/// Reliable continuous sound while drawing.
/// Uses two alternating players so the tone never drops out.
class SoundService {
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;
  SoundService._();

  final AudioPlayer _a = AudioPlayer();
  final AudioPlayer _b = AudioPlayer();
  final AudioPlayer _fx = AudioPlayer();
  AudioPlayer get _next => _useA ? _a : _b;
  bool _useA = true;

  bool _ready = false;
  bool _drawing = false;
  DateTime _lastTrigger = DateTime.fromMillisecondsSinceEpoch(0);

  // Cache: instrument+color → wav bytes
  final Map<String, Uint8List> _cache = {};

  Instrument instrument = Instrument.xylophone;

  static const Map<int, double> _freq = {
    0xFFFF6B6B: 523.25,
    0xFFFFD93D: 587.33,
    0xFF6BCB77: 659.25,
    0xFF4D96FF: 698.46,
    0xFF9B59B6: 783.99,
    0xFFFF8C42: 880.00,
  };

  Future<void> init() async {
    try {
      for (final p in [_a, _b, _fx]) {
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setVolume(0.7);
      }
      // Pre-warm cache for all colors
      for (final c in _freq.keys) {
        for (final inst in Instrument.values) {
          _getWav(Color(c), inst, continuous: true);
        }
      }
      _ready = true;
      debugPrint('SoundService ready (dual player + cache)');
    } catch (e) {
      debugPrint('SoundService init: $e');
    }
  }

  Future<void> startDrawing(Color color, {double speed = 0.5}) async {
    if (!_ready) return;
    _drawing = true;
    await _trigger(color, speed: speed, force: true);
  }

  Future<void> whileDrawing(Color color, {double speed = 0.5}) async {
    if (!_ready || !_drawing) return;

    // Interval depends on instrument — continuous feel without spam
    final ms = switch (instrument) {
      Instrument.xylophone => 110,
      Instrument.otamatone => 140,
      Instrument.theremin => 160,
    };

    if (DateTime.now().difference(_lastTrigger).inMilliseconds < ms) return;
    await _trigger(color, speed: speed, force: false);
  }

  Future<void> stopDrawing() async {
    _drawing = false;
    try {
      await Future.wait([_a.stop(), _b.stop()]);
    } catch (_) {}
  }

  Future<void> playColorNote(Color color, {double velocity = 1.0, double speed = 0.5}) async {
    if (!_ready) return;
    await _trigger(color, speed: speed, force: true, oneShot: true);
  }

  Future<void> _trigger(
    Color color, {
    required double speed,
    required bool force,
    bool oneShot = false,
  }) async {
    try {
      final bytes = _getWav(color, instrument, continuous: !oneShot);
      final player = _next;
      _useA = !_useA;
      _lastTrigger = DateTime.now();

      // Fire-and-forget on alternate player — no await stop of the other
      // so audio never gaps
      player.stop().then((_) {
        player.play(BytesSource(bytes));
      }).catchError((_) {});
    } catch (e) {
      debugPrint('trigger: $e');
    }
  }

  Uint8List _getWav(Color color, Instrument inst, {required bool continuous}) {
    final key = '${inst.name}_${color.value}_$continuous';
    return _cache.putIfAbsent(key, () {
      final f = _freq[color.value] ?? 523.25;
      switch (inst) {
        case Instrument.xylophone:
          return _xylo(f, continuous ? 0.20 : 0.28);
        case Instrument.otamatone:
          return _otamatone(f, continuous ? 0.35 : 0.42);
        case Instrument.theremin:
          return _theremin(f, continuous ? 0.40 : 0.50);
      }
    });
  }

  // ── Synths (pre-cached) ──────────────────────────────────

  Uint8List _xylo(double freq, double dur) {
    const sr = 22050;
    final n = (sr * dur).round();
    final s = Int16List(n);
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      final env = min(1.0, t * 60) * exp(-t * 12);
      final w = sin(2 * pi * freq * t) * 0.82 +
          sin(2 * pi * freq * 2.01 * t) * 0.18;
      s[i] = (0.55 * 32767 * env * w).round().clamp(-32767, 32767);
    }
    return _wav(s, sr);
  }

  Uint8List _otamatone(double freq, double dur) {
    const sr = 22050;
    final n = (sr * dur).round();
    final s = Int16List(n);
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      final attack = min(1.0, t * 30);
      final release = t > dur * 0.75 ? (dur - t) / (dur * 0.25) : 1.0;
      final env = attack * exp(-t * 1.6) * release;
      final vib = sin(2 * pi * 5.5 * t) * 6.0;
      final phase = 2 * pi * (freq + vib) * t;
      var w = sin(phase) + sin(phase * 3) / 3 * 0.65 + sin(phase * 5) / 5 * 0.35;
      w *= 0.6 + 0.4 * sin(2 * pi * 2.5 * t); // wah
      s[i] = (0.5 * 32767 * env * w).round().clamp(-32767, 32767);
    }
    return _wav(s, sr);
  }

  Uint8List _theremin(double freq, double dur) {
    const sr = 22050;
    final n = (sr * dur).round();
    final s = Int16List(n);
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      final attack = min(1.0, t * 15);
      final release = t > dur * 0.7 ? (dur - t) / (dur * 0.3) : 1.0;
      final env = attack * exp(-t * 1.0) * release;
      final vib = sin(2 * pi * 5.0 * t) * 10.0;
      s[i] = (0.45 * 32767 * env * sin(2 * pi * (freq + vib) * t))
          .round()
          .clamp(-32767, 32767);
    }
    return _wav(s, sr);
  }

  Future<void> playMagicSound() async {
    if (!_ready) return;
    try {
      await _fx.play(BytesSource(_chirp()));
    } catch (_) {}
  }

  Future<void> playSuccess() async {
    if (!_ready) return;
    try {
      await _fx.play(BytesSource(_success()));
    } catch (_) {}
  }

  Uint8List _chirp() {
    const sr = 22050;
    const dur = 0.5;
    final n = (sr * dur).round();
    final s = Int16List(n);
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      final f = 400.0 + 1500 * (t / dur);
      var env = exp(-t * 2.5);
      if (t > dur * 0.85) env *= (dur - t) / (dur * 0.15);
      s[i] = (0.4 * 32767 * env * sin(2 * pi * f * t)).round().clamp(-32767, 32767);
    }
    return _wav(s, sr);
  }

  Uint8List _success() {
    const sr = 22050;
    const dur = 0.45;
    final n = (sr * dur).round();
    final s = Int16List(n);
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      final f = t < 0.18 ? 659.25 : 880.0;
      final lt = t < 0.18 ? t : t - 0.18;
      s[i] = (0.4 * 32767 * exp(-lt * 6) * sin(2 * pi * f * t))
          .round()
          .clamp(-32767, 32767);
    }
    return _wav(s, sr);
  }

  Uint8List _wav(Int16List samples, int sr) {
    final dataSize = samples.length * 2;
    final buf = ByteData(44 + dataSize);
    void str(int o, String s) {
      for (int i = 0; i < s.length; i++) {
        buf.setUint8(o + i, s.codeUnitAt(i));
      }
    }
    str(0, 'RIFF');
    buf.setUint32(4, 36 + dataSize, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    buf.setUint32(16, 16, Endian.little);
    buf.setUint16(20, 1, Endian.little);
    buf.setUint16(22, 1, Endian.little);
    buf.setUint32(24, sr, Endian.little);
    buf.setUint32(28, sr * 2, Endian.little);
    buf.setUint16(32, 2, Endian.little);
    buf.setUint16(34, 16, Endian.little);
    str(36, 'data');
    buf.setUint32(40, dataSize, Endian.little);
    for (int i = 0; i < samples.length; i++) {
      buf.setInt16(44 + i * 2, samples[i], Endian.little);
    }
    return buf.buffer.asUint8List();
  }

  Future<void> dispose() async {
    await _a.dispose();
    await _b.dispose();
    await _fx.dispose();
  }
}
