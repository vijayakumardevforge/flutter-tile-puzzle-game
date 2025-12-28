import 'package:flutter/material.dart';
import '../game/ui.dart';
import '../game/storage.dart';

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    // Get the highest level reached (default to 1)
    final int maxLevel = GameStorage().getMaxLevel();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Level',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 120, // Width of each grid item
            childAspectRatio: 1.0,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: 30, // Total 30 levels (10 Easy, 10 Medium, 10 Hard)
          itemBuilder: (context, index) {
            final int level = index + 1;
            final bool isLocked = level > maxLevel;
            final Map<String, int>? bestScore = GameStorage().getBestScore(
              level,
            );

            return GestureDetector(
              onTap: () async {
                if (!isLocked) {
                  // Wait for the game screen to close
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PuzzleGame(level: level),
                    ),
                  );
                  // Refresh the UI to show new stars/unlocks
                  setState(() {});
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isLocked ? Colors.white10 : Colors.blueAccent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isLocked
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                  gradient: isLocked
                      ? null
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.blue.shade400, Colors.blue.shade700],
                        ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLocked)
                      const Icon(Icons.lock, color: Colors.white38, size: 32)
                    else ...[
                      Text(
                        '$level',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (bestScore != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              starIndex < (bestScore['stars'] ?? 0)
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 12,
                            );
                          }),
                        ),
                        // Moves count removed to declutter and focus on stars as requested
                        // If desired, can add back small text below
                      ],
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
