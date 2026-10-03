import 'dart:math';
import 'package:flutter/material.dart';

class Particle {
  Offset position;
  Offset velocity;
  double life;
  double maxLife;
  Color color;
  double size;

  Particle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.maxLife,
    required this.color,
    required this.size,
  });

  bool get isDead => life <= 0;

  void update(double dt) {
    position += velocity * dt;
    velocity *= 0.96; // friction
    life -= dt;
  }
}

class ParticleSystem extends ChangeNotifier {
  final List<Particle> particles = [];
  final Random _rng = Random();

  void emit({
    required Offset origin,
    required Color color,
    int count = 12,
    double speed = 80,
  }) {
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final s = speed * (0.4 + _rng.nextDouble() * 0.8);
      particles.add(Particle(
        position: origin,
        velocity: Offset(cos(angle) * s, sin(angle) * s),
        life: 0.4 + _rng.nextDouble() * 0.5,
        maxLife: 0.9,
        color: color.withOpacity(0.85),
        size: 2.5 + _rng.nextDouble() * 3.5,
      ));
    }
    notifyListeners();
  }

  void emitMagicBurst(Offset origin) {
    final colors = [
      const Color(0xFFFFD700),
      const Color(0xFFFF69B4),
      const Color(0xFF00E5FF),
      const Color(0xFFFF8C00),
      Colors.white,
    ];
    for (int i = 0; i < 40; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final s = 60 + _rng.nextDouble() * 140;
      particles.add(Particle(
        position: origin,
        velocity: Offset(cos(angle) * s, sin(angle) * s - 40),
        life: 0.8 + _rng.nextDouble() * 0.7,
        maxLife: 1.5,
        color: colors[_rng.nextInt(colors.length)].withOpacity(0.9),
        size: 3 + _rng.nextDouble() * 5,
      ));
    }
    notifyListeners();
  }

  void update(double dt) {
    for (final p in particles) {
      p.update(dt);
    }
    particles.removeWhere((p) => p.isDead);
    if (particles.isNotEmpty) notifyListeners();
  }

  void clear() {
    particles.clear();
    notifyListeners();
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final progress = (p.life / p.maxLife).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withOpacity(progress * 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(p.position, p.size * progress, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
