import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// On-device AI-style transformation of scribbles.
///
/// Uses stroke geometry analysis (length, curvature proxy, spread)
/// to pick a confident result. Structure is ready for a real TFLite
/// classifier: replace `_analyze` with interpreter.run(...).
class AiService {
  static final AiService _instance = AiService._();
  factory AiService() => _instance;
  AiService._();

  bool _isReady = false;
  final _rng = Random();

  Future<void> init() async {
    // Ready for: tflite_flutter Interpreter.fromAsset(...)
    _isReady = true;
    debugPrint('AiService ready (geometry analyzer)');
  }

  Future<AiTransformResult> transformScribbles({
    required List<List<Offset>> strokes,
    required String worldId,
  }) async {
    if (!_isReady) await init();

    // Feels like inference
    await Future.delayed(Duration(milliseconds: 900 + _rng.nextInt(500)));

    final features = _extractFeatures(strokes);
    return _analyze(features, worldId);
  }

  _StrokeFeatures _extractFeatures(List<List<Offset>> strokes) {
    if (strokes.isEmpty) {
      return _StrokeFeatures(0, 0, 0, 0, 0);
    }

    double totalLen = 0;
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;
    int points = 0;

    for (final stroke in strokes) {
      points += stroke.length;
      for (int i = 0; i < stroke.length; i++) {
        final p = stroke[i];
        minX = min(minX, p.dx);
        minY = min(minY, p.dy);
        maxX = max(maxX, p.dx);
        maxY = max(maxY, p.dy);
        if (i > 0) {
          totalLen += (stroke[i] - stroke[i - 1]).distance;
        }
      }
    }

    final width = (maxX - minX).clamp(1.0, 10000.0);
    final height = (maxY - minY).clamp(1.0, 10000.0);
    final aspect = width / height;
    final density = points / (width * height / 1000 + 1);

    return _StrokeFeatures(
      strokes.length.toDouble(),
      totalLen,
      aspect,
      density,
      points.toDouble(),
    );
  }

  AiTransformResult _analyze(_StrokeFeatures f, String worldId) {
    final complexity = (f.strokeCount * 0.4 + f.totalLength / 200 + f.pointCount / 80)
        .clamp(0.0, 15.0);

    late String type, title, message, emoji;

    // World bias + geometry hints
    switch (worldId) {
      case 'butterfly':
        type = 'butterfly';
        title = 'Бабочка';
        emoji = '🦋';
        if (f.aspect > 1.3) {
          message = 'Крылья получились широкие и красивые!';
        } else if (complexity > 5) {
          message = 'Вау! Бабочка с узорными крыльями!';
        } else {
          message = 'Из твоих линий родилась нежная бабочка!';
        }
        break;
      case 'ocean':
        type = 'fish';
        title = 'Рыбка';
        emoji = '🐠';
        message = f.totalLength > 400
            ? 'Большая весёлая рыбка поплыла!'
            : 'Каракули превратились в рыбку!';
        break;
      case 'forest':
        type = 'flower';
        title = 'Цветок';
        emoji = '🌸';
        message = complexity > 4
            ? 'Вырос яркий волшебный цветок!'
            : 'Появился нежный цветочек!';
        break;
      case 'sky':
        type = 'cloud';
        title = 'Облачко';
        emoji = '☁️';
        message = 'Мягкое волшебное облачко в небе!';
        break;
      default:
        if (f.aspect > 0.85 && f.aspect < 1.2 && complexity > 3) {
          type = 'star';
          title = 'Звезда';
          emoji = '⭐';
          message = 'Ты нарисовал сияющую звезду!';
        } else if (f.strokeCount >= 3) {
          type = 'rainbow';
          title = 'Радуга';
          emoji = '🌈';
          message = 'Получилась волшебная радуга!';
        } else {
          type = 'heart';
          title = 'Сердечко';
          emoji = '❤️';
          message = 'Ты создал тёплое сердечко!';
        }
    }

    final confidence = (0.72 + complexity / 35 + f.density / 20).clamp(0.75, 0.96);

    return AiTransformResult(
      type: type,
      title: title,
      message: message,
      emoji: emoji,
      confidence: confidence,
    );
  }
}

class _StrokeFeatures {
  final double strokeCount;
  final double totalLength;
  final double aspect;
  final double density;
  final double pointCount;

  _StrokeFeatures(
    this.strokeCount,
    this.totalLength,
    this.aspect,
    this.density,
    this.pointCount,
  );
}

class AiTransformResult {
  final String type;
  final String title;
  final String message;
  final String emoji;
  final double confidence;

  AiTransformResult({
    required this.type,
    required this.title,
    required this.message,
    required this.emoji,
    required this.confidence,
  });
}
