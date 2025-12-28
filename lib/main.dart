import 'package:flutter/material.dart';
import 'screens/main_menu.dart';
import 'game/audio_manager.dart';
import 'game/storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await AudioManager().initialize();
  await GameStorage().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tile Vision',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      home: const MainMenuScreen(),
    );
  }
}
