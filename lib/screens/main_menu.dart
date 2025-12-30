import 'package:flutter/material.dart';

import '../game/instructions.dart';
import '../game/audio_manager.dart';
import '../game/ui.dart'; // Added
import '../game/storage.dart'; // Added
import '../widgets/premium_dialog.dart';

import 'settings.dart';
import 'level_selection.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  void initState() {
    super.initState();
    // Start background music when menu opens
    AudioManager().playBackgroundMusic();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade900,
              Colors.indigo.shade900,
              Colors.blue.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Premium Button (Top Left)
              Positioned(
                top: 16,
                left: 16,
                child: GestureDetector(
                  onTap: () async {
                    await GameStorage().initialize();
                    if (GameStorage().getPremiumStatus()) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '🌟 You are already a Premium VIP! Thank you for your support! 🌟',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: Colors.amber,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                      return;
                    }
                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      builder: (context) => PremiumSubscriptionDialog(
                        onSubscribe: () async {
                          await GameStorage().savePremiumStatus(true);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '🌟 Premium Activated! Welcome to the VIP Club! 🌟',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: Colors.amber,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.workspace_premium, // Crown-like icon
                      color: Colors.amber,
                      size: 32,
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title with glow effect
                    Text(
                      'Tile',
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 20.0,
                            color: Colors.purple.shade300,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Vision',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w300,
                        color: Colors.white70,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 60),

                    // Play Button
                    _buildMenuButton(
                      context,
                      icon: Icons.play_arrow,
                      label: 'PLAY',
                      onTap: () async {
                        // Initialize storage to be sure
                        await GameStorage().initialize();
                        // Get highest unlocked level
                        final level = GameStorage().getMaxLevel();

                        if (context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PuzzleGame(level: level),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Levels Button
                    _buildMenuButton(
                      context,
                      icon: Icons.grid_view,
                      label: 'LEVELS',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LevelSelectionScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // How to Play Button
                    _buildMenuButton(
                      context,
                      icon: Icons.help_outline,
                      label: 'HOW TO PLAY',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const InstructionScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Settings Button
                    _buildMenuButton(
                      context,
                      icon: Icons.settings,
                      label: 'SETTINGS',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 280,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade600, Colors.purple.shade800],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.shade900.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 15),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
