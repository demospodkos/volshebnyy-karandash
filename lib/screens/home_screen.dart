import 'package:flutter/material.dart';
import 'drawing_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Title
              Text(
                'Волшебный\nкарандаш',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                  color: Color(0xFF2D2D2D),
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Рисуй • Слушай • Создавай',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              // Worlds grid
              Expanded(
                flex: 3,
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _WorldCard(
                      title: 'Сад бабочек',
                      color: const Color(0xFFFFB6C1),
                      emoji: '🦋',
                      onTap: () => _openDrawing(context, 'butterfly'),
                    ),
                    _WorldCard(
                      title: 'Океан',
                      color: const Color(0xFF87CEEB),
                      emoji: '🌊',
                      onTap: () => _openDrawing(context, 'ocean'),
                    ),
                    _WorldCard(
                      title: 'Лес',
                      color: const Color(0xFF90EE90),
                      emoji: '🌲',
                      onTap: () => _openDrawing(context, 'forest'),
                    ),
                    _WorldCard(
                      title: 'Небо',
                      color: const Color(0xFFE6E6FA),
                      emoji: '☁️',
                      onTap: () => _openDrawing(context, 'sky'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Free draw button
              ElevatedButton(
                onPressed: () => _openDrawing(context, 'free'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Свободное рисование ✨',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _openDrawing(BuildContext context, String world) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DrawingScreen(worldId: world),
      ),
    );
  }
}

class _WorldCard extends StatelessWidget {
  final String title;
  final Color color;
  final String emoji;
  final VoidCallback onTap;

  const _WorldCard({
    required this.title,
    required this.color,
    required this.emoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2D2D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
