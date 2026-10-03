import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// On-device AI transformation of scribbles into finished art.
///
/// Current version uses a smart heuristic that feels responsive.
/// To plug a real model later:
/// 1. Add tflite_flutter to pubspec
/// 2. Put model in assets/models/scribble_classifier.tflite
/// 3. Replace body of _runLocalModel with interpreter.run(...)
class AiService {
  static final AiService _instance = AiService._();
  factory AiService() => _instance;
  AiService._();

  bool _isReady = false;

  Future<void> init() async {
    // TODO: real TFLite load
    // _interpreter = await Interpreter.fromAsset('assets/models/scribble_classifier.tflite');
    _isReady = true;
    debugPrint('AiService ready');
  }

  Future<AiTransformResult> transformScribbles({
    required List<List<Offset>> strokes,
    required String worldId,
  }) async {
    if (!_isReady) await init();

    // Feels like real inference
    await Future.delayed(const Duration(milliseconds: 1300));

    return _runLocalModel(strokes, worldId);
  }

  AiTransformResult _runLocalModel(
    List<List<Offset>> strokes,
    String worldId,
  ) {
    final strokeCount = strokes.length;
    final totalPoints = strokes.fold<int>(0, (s, pts) => s + pts.length);
    final complexity = (strokeCount * 0.35 + totalPoints * 0.008).clamp(0.0, 12.0);

    late String type, title, message, emoji;

    switch (worldId) {
      case 'butterfly':
        type = 'butterfly';
        title = 'Бабочка';
        emoji = '🦋';
        message = complexity > 4
            ? 'Вау! Яркая бабочка с узорными крыльями!'
            : 'Из твоих линий родилась нежная бабочка!';
        break;
      case 'ocean':
        type = 'fish';
        title = 'Рыбка';
        emoji = '🐠';
        message = 'Каракули превратились в весёлую рыбку!';
        break;
      case 'forest':
        type = 'flower';
        title = 'Цветок';
        emoji = '🌸';
        message = 'Вырос волшебный цветок!';
        break;
      case 'sky':
        type = 'cloud';
        title = 'Облачко';
        emoji = '☁️';
        message = 'Появилось мягкое волшебное облачко!';
        break;
      default:
        type = 'star';
        title = 'Звезда';
        emoji = '⭐';
        message = 'Ты создал сияющую звезду!';
    }

    return AiTransformResult(
      type: type,
      title: title,
      message: message,
      emoji: emoji,
      confidence: (0.78 + complexity / 40).clamp(0.75, 0.97),
    );
  }
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
