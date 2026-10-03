import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import '../services/ai_service.dart';
import '../widgets/particle_system.dart';

class DrawingScreen extends StatefulWidget {
  final String worldId;

  const DrawingScreen({super.key, required this.worldId});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen>
    with TickerProviderStateMixin {
  final List<_Stroke> _strokes = [];
  _Stroke? _currentStroke;
  Color _currentColor = const Color(0xFFFF6B6B);
  final double _strokeWidth = 9.0;

  final SoundService _sound = SoundService();
  final AiService _ai = AiService();
  final ParticleSystem _particles = ParticleSystem();

  late AnimationController _particleTicker;
  bool _isTransforming = false;
  String? _magicMessage;

  final List<Color> _palette = const [
    Color(0xFFFF6B6B),
    Color(0xFFFFD93D),
    Color(0xFF6BCB77),
    Color(0xFF4D96FF),
    Color(0xFF9B59B6),
    Color(0xFFFF8C42),
  ];

  @override
  void initState() {
    super.initState();
    _sound.init();
    _ai.init();

    _particleTicker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
        _particles.update(1 / 60);
        if (_particles.particles.isNotEmpty) setState(() {});
      });
    _particleTicker.repeat();
  }

  @override
  void dispose() {
    _particleTicker.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_isTransforming) return;
    final pos = details.localPosition;
    setState(() {
      _currentStroke = _Stroke(
        color: _currentColor,
        width: _strokeWidth,
        points: [pos],
      );
      _strokes.add(_currentStroke!);
    });
    _sound.playColorNote(_currentColor);
    _particles.emit(origin: pos, color: _currentColor, count: 6, speed: 50);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentStroke == null || _isTransforming) return;
    final pos = details.localPosition;
    setState(() {
      _currentStroke!.points.add(pos);
    });
    if (_currentStroke!.points.length % 4 == 0) {
      _particles.emit(origin: pos, color: _currentColor, count: 2, speed: 30);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _currentStroke = null;
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _magicMessage = null;
    });
    _particles.clear();
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.removeLast());
  }

  Future<void> _runMagic() async {
    if (_isTransforming || _strokes.isEmpty) return;

    setState(() {
      _isTransforming = true;
      _magicMessage = null;
    });

    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height * 0.38);
    _particles.emitMagicBurst(center);
    await _sound.playMagicSound();

    final result = await _ai.transformScribbles(
      strokes: _strokes.map((s) => s.points).toList(),
      worldId: widget.worldId,
    );

    if (!mounted) return;

    setState(() {
      _isTransforming = false;
      _magicMessage = result.message;
    });

    await _sound.playSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      _worldTitle(widget.worldId),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: _isTransforming
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Icon(Icons.auto_awesome_rounded, size: 24),
                    color: const Color(0xFFFF6B6B),
                    onPressed: _runMagic,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Stack(
                    children: [
                      GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: CustomPaint(
                          painter: _DrawingPainter(_strokes),
                          size: Size.infinite,
                        ),
                      ),
                      IgnorePointer(
                        child: CustomPaint(
                          painter: ParticlePainter(_particles.particles),
                          size: Size.infinite,
                        ),
                      ),
                      if (_magicMessage != null)
                        Positioned(
                          left: 20,
                          right: 20,
                          bottom: 24,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B6B),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF6B6B).withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Text(
                              _magicMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                children: [
                  SizedBox(
                    height: 52,
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
                            width: 46,
                            height: 46,
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
                                        color: color.withOpacity(0.55),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ToolButton(icon: Icons.undo_rounded, label: 'Отмена', onTap: _undo),
                      _ToolButton(icon: Icons.delete_outline_rounded, label: 'Очистить', onTap: _clear),
                      _ToolButton(
                        icon: Icons.auto_awesome,
                        label: 'Магия',
                        color: const Color(0xFFFF6B6B),
                        onTap: _runMagic,
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
      case 'butterfly': return 'Сад бабочек 🦋';
      case 'ocean': return 'Океан 🌊';
      case 'forest': return 'Лес 🌲';
      case 'sky': return 'Небо ☁️';
      default: return 'Свободное рисование';
    }
  }
}

class _Stroke {
  final Color color;
  final double width;
  final List<Offset> points;
  _Stroke({required this.color, required this.width, required this.points});
}

class _DrawingPainter extends CustomPainter {
  final List<_Stroke> strokes;
  _DrawingPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        canvas.drawCircle(stroke.points.first, stroke.width / 2, paint);
        continue;
      }
      final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
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
  final Color? color;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF2D2D2D);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 24, color: c),
          ),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
