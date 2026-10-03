import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import '../services/ai_service.dart';
import '../widgets/particle_system.dart';
import '../widgets/magic_overlay.dart';

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
  Offset? _lastPoint;
  DateTime? _lastTime;

  final SoundService _sound = SoundService();
  final AiService _ai = AiService();
  final ParticleSystem _particles = ParticleSystem();

  late AnimationController _particleTicker;
  bool _isTransforming = false;
  Instrument _instrument = Instrument.xylophone;

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
    _sound.instrument = _instrument;

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

  void _setInstrument(Instrument inst) {
    setState(() {
      _instrument = inst;
      _sound.instrument = inst;
    });
    // Preview the instrument
    _sound.playColorNote(_currentColor, velocity: 0.7, speed: 0.5);
  }

  void _onPanStart(DragStartDetails details) {
    if (_isTransforming) return;
    final pos = details.localPosition;
    _lastPoint = pos;
    _lastTime = DateTime.now();
    setState(() {
      _currentStroke = _Stroke(
        color: _currentColor,
        width: _strokeWidth,
        points: [pos],
      );
      _strokes.add(_currentStroke!);
    });
    _sound.playColorNote(_currentColor, speed: 0.4);
    _particles.emit(origin: pos, color: _currentColor, count: 6, speed: 50);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentStroke == null || _isTransforming) return;
    final pos = details.localPosition;
    final now = DateTime.now();

    double speed = 0.5;
    if (_lastPoint != null && _lastTime != null) {
      final dt = now.difference(_lastTime!).inMilliseconds.clamp(1, 200) / 1000.0;
      final dist = (pos - _lastPoint!).distance;
      speed = (dist / dt / 800).clamp(0.0, 1.0); // normalize
    }
    _lastPoint = pos;
    _lastTime = now;

    setState(() {
      _currentStroke!.points.add(pos);
    });

    // Periodic notes while drawing (especially nice for theremin/otamatone)
    if (_currentStroke!.points.length % 6 == 0) {
      _sound.playColorNote(_currentColor, velocity: 0.5 + speed * 0.4, speed: speed);
    }
    if (_currentStroke!.points.length % 4 == 0) {
      _particles.emit(origin: pos, color: _currentColor, count: 2, speed: 30);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _currentStroke = null;
    _lastPoint = null;
    _lastTime = null;
  }

  void _clear() {
    setState(() => _strokes.clear());
    _particles.clear();
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.removeLast());
  }

  Future<void> _runMagic() async {
    if (_isTransforming || _strokes.isEmpty) return;

    setState(() => _isTransforming = true);

    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height * 0.38);
    _particles.emitMagicBurst(center);
    await _sound.playMagicSound();

    final result = await _ai.transformScribbles(
      strokes: _strokes.map((s) => s.points).toList(),
      worldId: widget.worldId,
    );

    if (!mounted) return;

    setState(() => _isTransforming = false);
    await _sound.playSuccess();

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'magic',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return MagicOverlay(
          result: result,
          onDismiss: () => Navigator.of(context).pop(),
        );
      },
    );
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

            // Instrument selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _InstrumentChip(
                    label: 'Ксилофон',
                    emoji: '🎹',
                    selected: _instrument == Instrument.xylophone,
                    onTap: () => _setInstrument(Instrument.xylophone),
                  ),
                  const SizedBox(width: 8),
                  _InstrumentChip(
                    label: 'Отаматон',
                    emoji: '🎵',
                    selected: _instrument == Instrument.otamatone,
                    onTap: () => _setInstrument(Instrument.otamatone),
                  ),
                  const SizedBox(width: 8),
                  _InstrumentChip(
                    label: 'Терменвокс',
                    emoji: '🌀',
                    selected: _instrument == Instrument.theremin,
                    onTap: () => _setInstrument(Instrument.theremin),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
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
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
              child: Column(
                children: [
                  SizedBox(
                    height: 48,
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
                            width: 44,
                            height: 44,
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
                  const SizedBox(height: 12),
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

class _InstrumentChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _InstrumentChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFF6B6B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFFFF6B6B) : Colors.grey.shade300,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF6B6B).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            width: 52,
            height: 52,
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
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
