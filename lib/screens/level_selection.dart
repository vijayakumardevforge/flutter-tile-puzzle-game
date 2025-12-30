import 'package:flutter/material.dart';
import 'dart:ui';
import '../game/ui.dart';
import '../game/storage.dart';
import '../game/assets.dart';

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
            final bool isUnlocked = level <= maxLevel;
            final bool isHidden = !isUnlocked; // Hide everything that is locked

            final String imagePath = PuzzleAssets.getImageForLevel(level);

            final Map<String, int>? bestScore = GameStorage().getBestScore(
              level,
            );

            return GestureDetector(
              onTap: () async {
                if (isUnlocked) {
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
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image Layer
                      if (!isHidden)
                        Image.asset(imagePath, fit: BoxFit.cover)
                      else
                        ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Image.asset(imagePath, fit: BoxFit.cover),
                        ),

                      // Overlay for locking/dimming
                      if (!isUnlocked)
                        Container(color: Colors.black.withOpacity(0.5)),

                      // Content Layer
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isHidden)
                              const Icon(
                                Icons.lock,
                                color: Colors.white54,
                                size: 40,
                              )
                            else
                              Text(
                                '$level',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(color: Colors.black, blurRadius: 10),
                                  ],
                                ),
                              ),

                            // Stars if unlocked
                            if (isUnlocked && bestScore != null) ...[
                              const SizedBox(height: 4),
                              /* Fixed: using spread operator properly for list of widgets */
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (starIndex) {
                                  final bool isEarned =
                                      starIndex < (bestScore['stars'] ?? 0);
                                  return Icon(
                                    isEarned
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: isEarned
                                        ? Colors.amberAccent
                                        : Colors.white24,
                                    size: 18,
                                    shadows: isEarned
                                        ? [
                                            const Shadow(
                                              color: Colors.orange,
                                              blurRadius: 2,
                                            ),
                                            Shadow(
                                              color: Colors.amber.withOpacity(
                                                0.8,
                                              ),
                                              blurRadius: 8,
                                            ),
                                          ]
                                        : [],
                                  );
                                }),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
