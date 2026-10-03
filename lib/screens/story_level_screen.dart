import 'package:flutter/material.dart';
import 'drawing_screen.dart';

/// Story level: "Help the caterpillar"
/// Child draws lines that become part of the path / cocoon.
class StoryLevelScreen extends StatefulWidget {
  const StoryLevelScreen({super.key});

  @override
  State<StoryLevelScreen> createState() => _StoryLevelScreenState();
}

class _StoryLevelScreenState extends State<StoryLevelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _stars = 0;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onMagicComplete() {
    setState(() {
      _completed = true;
      _stars = 3;
    });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFF0),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Помоги гусенице! 🐛',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Story description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Нарисуй волшебный путь или кокон,\nчтобы гусеница превратилась в бабочку',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Stars progress
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: i < _stars ? Colors.amber : Colors.grey[400],
                    size: 32,
                  ),
                );
              }),
            ),

            const SizedBox(height: 8),

            // Drawing area (reuses DrawingScreen logic conceptually)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      // Background story elements
                      Positioned(
                        bottom: 30,
                        left: 24,
                        child: Text(
                          '🐛',
                          style: TextStyle(fontSize: _completed ? 0 : 48),
                        ),
                      ),
                      Positioned(
                        top: 40,
                        right: 30,
                        child: Text(
                          _completed ? '🦋' : '🍎',
                          style: const TextStyle(fontSize: 52),
                        ),
                      ),

                      // Actual drawing happens in DrawingScreen
                      // For now we open the full drawing screen
                      Center(
                        child: _completed
                            ? ScaleTransition(
                                scale: CurvedAnimation(
                                  parent: _controller,
                                  curve: Curves.elasticOut,
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('🦋', style: TextStyle(fontSize: 90)),
                                    SizedBox(height: 16),
                                    Text(
                                      'Ура! Бабочка родилась!',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const DrawingScreen(
                                        worldId: 'butterfly',
                                      ),
                                    ),
                                  );
                                  // After returning we consider it complete for demo
                                  _onMagicComplete();
                                },
                                icon: const Icon(Icons.brush_rounded),
                                label: const Text('Начать рисовать'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6BCB77),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_completed)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Дальше →', style: TextStyle(fontSize: 18)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
