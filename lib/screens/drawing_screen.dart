import 'dart:ui' as ui;
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
  final double _baseWidth = 10.0;
  Offset? _lastPoint;
  DateTime? _lastTime;
  double _traveled = 0; // distance since last sound tick

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
    _sound.stopDrawing();
    _particleTicker.dispose();
    super.dispose();
  }

  void _setInstrument(Instrument inst) {
    setState(() {
      _instrument = inst;
      _sound.instrument = inst;
    });
    _sound.playColorNote(_currentColor, velocity: 0.75, speed: 0.5);
  }

  void _onPanStart(DragStartDetails details) {
    if (_isTransforming) return;
    final pos = details.localPosition;
    _lastPoint = pos;
    _lastTime = DateTime.now();
    _traveled = 0;

    setState(() {
      _currentStroke = _Stroke(
        color: _currentColor,
        widths: [_baseWidth],
        points: [pos],
      );
      _strokes.add(_currentStroke!);
    });

    _sound.startDrawing(_currentColor, speed: 0.5);
    _particles.emit(origin: pos, color: _currentColor, count: 10, speed: 70);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentStroke == null || _isTransforming) return;
    final pos = details.localPosition;
    final now = DateTime.now();

    double speed = 0.4;
    double dist = 0;
    if (_lastPoint != null && _lastTime != null) {
      dist = (pos - _lastPoint!).distance;
      final dt =
          now.difference(_lastTime!).inMilliseconds.clamp(1, 200) / 1000.0;
      speed = (dist / dt / 700).clamp(0.0, 1.0);
    }

    // Variable width: faster = slightly thinner
    final w = (_baseWidth * (1.15 - speed * 0.35)).clamp(6.0, 14.0);

    setState(() {
      _currentStroke!.points.add(pos);
      _currentStroke!.widths.add(w);
    });

    _traveled += dist;
    // Sound tied to distance traveled (~12 px) — stable continuous feel
    if (_traveled >= 12) {
      _traveled = 0;
      _sound.whileDrawing(_currentColor, speed: speed);
    }

    if (_currentStroke!.points.length % 3 == 0) {
      _particles.emit(
        origin: pos,
        color: _currentColor,
        count: 3,
        speed: 25 + speed * 40,
      );
    }

    _lastPoint = pos;
    _lastTime = now;
  }

  void _onPanEnd(DragEndDetails details) {
    _currentStroke = null;
    _lastPoint = null;
    _lastTime = null;
    _traveled = 0;
    _sound.stopDrawing();
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
    await _sound.stopDrawing();

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
      pageBuilder: (_, __, ___) => MagicOverlay(
        result: result,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F2),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      _worldTitle(widget.worldId),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
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

            // Instruments
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 4),
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

            // Canvas
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 2, 12, 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFFFFF), Color(0xFFFFF5EB)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: const Color(0xFFFF6B6B).withOpacity(0.06),
                      blurRadius: 40,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      // soft paper texture hint
                      Positioned.fill(
                        child: CustomPaint(painter: _PaperPainter()),
                      ),
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

            // Palette + tools
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
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
                            duration: const Duration(milliseconds: 180),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? Colors.black87
                                    : Colors.white.withOpacity(0.8),
                                width: selected ? 3 : 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(selected ? 0.55 : 0.25),
                                  blurRadius: selected ? 14 : 6,
                                  spreadRadius: selected ? 1 : 0,
                                  offset: const Offset(0, 3),
                                ),
                              ],
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
                      _ToolButton(
                          icon: Icons.undo_rounded, label: 'Отмена', onTap: _undo),
                      _ToolButton(
                          icon: Icons.delete_outline_rounded,
                          label: 'Очистить',
                          onTap: _clear),
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
      case 'butterfly':
        return 'Сад бабочек 🦋';
      case 'ocean':
        return 'Океан 🌊';
      case 'forest':
        return 'Лес 🌲';
      case 'sky':
        return 'Небо ☁️';
      default:
        return 'Свободное рисование';
    }
  }
}

// ─── Widgets ───────────────────────────────────────────────

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
                      color: const Color(0xFFFF6B6B).withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
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
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 12,
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

// ─── Drawing data ──────────────────────────────────────────

class _Stroke {
  final Color color;
  final List<double> widths;
  final List<Offset> points;
  _Stroke({required this.color, required this.widths, required this.points});
}

class _DrawingPainter extends CustomPainter {
  final List<_Stroke> strokes;
  _DrawingPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      // Soft glow under the stroke
      final glow = Paint()
        ..color = stroke.color.withOpacity(0.22)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final paint = Paint()
        ..color = stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        final w = stroke.widths.isNotEmpty ? stroke.widths.first : 10.0;
        glow.strokeWidth = w + 6;
        paint.strokeWidth = w;
        canvas.drawCircle(stroke.points.first, w / 2, glow);
        canvas.drawCircle(stroke.points.first, w / 2, paint);
        continue;
      }

      // Smooth path with mid-point quadratic curves
      final path = Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        final p0 = stroke.points[i - 1];
        final p1 = stroke.points[i];
        final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
        path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      }
      path.lineTo(stroke.points.last.dx, stroke.points.last.dy);

      final avgW = stroke.widths.isEmpty
          ? 10.0
          : stroke.widths.reduce((a, b) => a + b) / stroke.widths.length;

      glow.strokeWidth = avgW + 8;
      paint.strokeWidth = avgW;

      canvas.drawPath(path, glow);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter old) => true;
}

class _PaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // very subtle dots for paper feel
    final paint = Paint()..color = const Color(0x08000000);
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x + 4, y + 4), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
