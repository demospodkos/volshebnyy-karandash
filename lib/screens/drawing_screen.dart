import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class DrawingScreen extends StatefulWidget {
  final String worldId;

  const DrawingScreen({super.key, required this.worldId});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  final List<_Stroke> _strokes = [];
  _Stroke? _currentStroke;
  Color _currentColor = const Color(0xFFFF6B6B);
  double _strokeWidth = 8.0;

  // Simple color → note mapping (xylophone style)
  final Map<Color, double> _colorFrequencies = {
    const Color(0xFFFF6B6B): 523.25, // C5 Red
    const Color(0xFFFFD93D): 587.33, // D5 Yellow
    const Color(0xFF6BCB77): 659.25, // E5 Green
    const Color(0xFF4D96FF): 698.46, // F5 Blue
    const Color(0xFF9B59B6): 783.99, // G5 Purple
    const Color(0xFFFF8C42): 880.00, // A5 Orange
  };

  final List<Color> _palette = [
    const Color(0xFFFF6B6B),
    const Color(0xFFFFD93D),
    const Color(0xFF6BCB77),
    const Color(0xFF4D96FF),
    const Color(0xFF9B59B6),
    const Color(0xFFFF8C42),
  ];

  final AudioPlayer _player = AudioPlayer();

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentStroke = _Stroke(
        color: _currentColor,
        width: _strokeWidth,
        points: [details.localPosition],
      );
      _strokes.add(_currentStroke!);
    });
    _playNoteForColor(_currentColor);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentStroke == null) return;
    setState(() {
      _currentStroke!.points.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _currentStroke = null;
  }

  Future<void> _playNoteForColor(Color color) async {
    // Placeholder: real implementation will use generated sine or sample
    // For now we just trigger a short sound (will be replaced with proper audio engine)
    try {
      // In real version we use a proper synth or preloaded samples
      // await _player.play(AssetSource('sounds/note_${color.value}.wav'));
    } catch (_) {}
  }

  void _clear() {
    setState(() {
      _strokes.clear();
    });
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    _worldTitle(widget.worldId),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.auto_fix_high),
                    tooltip: 'Магия AI',
                    onPressed: () {
                      // TODO: trigger AI transformation
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('AI-магия скоро будет готова ✨')),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Canvas
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: CustomPaint(
                      painter: _DrawingPainter(_strokes),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ),

            // Color palette + tools
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                children: [
                  // Colors
                  SizedBox(
                    height: 56,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _palette.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final color = _palette[index];
                        final selected = color == _currentColor;
                        return GestureDetector(
                          onTap: () => setState(() => _currentColor = color),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? Colors.black87 : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: color.withOpacity(0.5),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tools
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ToolButton(
                        icon: Icons.undo_rounded,
                        label: 'Отменить',
                        onTap: _undo,
                      ),
                      _ToolButton(
                        icon: Icons.delete_outline_rounded,
                        label: 'Очистить',
                        onTap: _clear,
                      ),
                      _ToolButton(
                        icon: Icons.auto_awesome,
                        label: 'Магия',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('AI превратит каракули в рисунок ✨'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _worldTitle(String id) {
    switch (id) {
      case 'butterfly':
        return 'Сад бабочек';
      case 'ocean':
        return 'Океан';
      case 'forest':
        return 'Лес';
      case 'sky':
        return 'Небо';
      default:
        return 'Свободное рисование';
    }
  }
}

class _Stroke {
  final Color color;
  final double width;
  final List<Offset> points;

  _Stroke({
    required this.color,
    required this.width,
    required this.points,
  });
}

class _DrawingPainter extends CustomPainter {
  final List<_Stroke> strokes;

  _DrawingPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 26, color: const Color(0xFF2D2D2D)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
