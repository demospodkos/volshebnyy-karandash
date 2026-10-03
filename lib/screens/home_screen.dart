import 'package:flutter/material.dart';
import 'drawing_screen.dart';
import 'story_level_screen.dart';

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
              const SizedBox(height: 16),
              // Title
              Text(
                'Волшебный\nкарандаш',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                  color: const Color(0xFF2D2D2D),
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.08),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Рисуй • Слушай • Создавай',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 20),

              // Story level button (featured)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StoryLevelScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6BCB77), Color(0xFF4CAF50)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6BCB77).withOpacity(0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text('🐛', style: TextStyle(fontSize: 36)),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Помоги гусенице!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Сюжетный уровень',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Worlds grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
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

              const SizedBox(height: 12),

              // Free draw
              ElevatedButton(
                onPressed: () => _openDrawing(context, 'free'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  'Свободное рисование ✨',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
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
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 42)),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
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
