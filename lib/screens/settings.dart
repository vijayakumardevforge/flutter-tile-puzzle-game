import 'package:flutter/material.dart';
import '../game/audio_manager.dart';
import '../game/storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _audioManager = AudioManager();
  final _storage = GameStorage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
          child: ListView(
            children: [
              SwitchListTile(
                title: const Text(
                  'Sound Effects',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Enable tile click and win sounds',
                  style: TextStyle(color: Colors.white70),
                ),
                value: !_audioManager.isMuted,
                activeColor: Colors.blueAccent,
                onChanged: (bool value) {
                  _audioManager.toggleMute();
                  setState(() {});
                },
              ),
              SwitchListTile(
                title: const Text(
                  'Background Music',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Play ambient music during gameplay',
                  style: TextStyle(color: Colors.white70),
                ),
                value: _audioManager.isMusicEnabled,
                activeColor: Colors.blueAccent,
                onChanged: (bool value) {
                  _audioManager.toggleMusic();
                  setState(() {});
                },
              ),
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(Icons.restore, color: Colors.orangeAccent),
                title: const Text(
                  'Reset All Progress',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Clear all high scores and start fresh',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.grey.shade900,
                      title: const Text(
                        'Reset Progress?',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'This will delete all your high scores. This action cannot be undone.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text(
                            'CANCEL',
                            style: TextStyle(color: Colors.white60),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                          ),
                          child: const Text('RESET'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await _storage.resetAllProgress();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Progress reset successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
