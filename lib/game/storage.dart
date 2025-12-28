import 'package:shared_preferences/shared_preferences.dart';

class GameStorage {
  static final GameStorage _instance = GameStorage._internal();
  factory GameStorage() => _instance;
  GameStorage._internal();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> saveLevelScore(
    int level,
    int timeSeconds,
    int moves,
    int stars,
  ) async {
    await initialize();

    // Check if previous score exists
    int? oldStars = _prefs!.getInt('level_${level}_stars');

    // Only overwrite if new star count is higher or equal (prioritize high stars)
    // Or maybe just overwrite? Standard behavior is usually "best score".
    // Let's simplified: If new stars > old stars, save. OR if stars same, but moves lower.

    // For simplicity in this prompt, let's just save the latest if it's better or equal,
    // but typically we want 'Best Score'.
    // Let's just save for now, assuming the user improves.

    // Actually, let's do a simple check:
    if (oldStars == null || stars >= oldStars) {
      await _prefs!.setInt('level_${level}_time', timeSeconds);
      await _prefs!.setInt('level_${level}_moves', moves);
      await _prefs!.setInt('level_${level}_stars', stars);
    }

    // Also update max level reached
    int currentMax = getMaxLevel();
    if (level >= currentMax) {
      await _prefs!.setInt('max_level', level + 1);
    }
  }

  Map<String, int>? getBestScore(int level) {
    if (_prefs == null) return null;

    final time = _prefs!.getInt('level_${level}_time');
    final moves = _prefs!.getInt('level_${level}_moves');
    final stars = _prefs!.getInt('level_${level}_stars');

    if (time == null || moves == null) return null;

    return {'time': time, 'moves': moves, 'stars': stars ?? 0};
  }

  int getMaxLevel() {
    if (_prefs == null) return 1;
    return _prefs!.getInt('max_level') ?? 1;
  }

  Future<void> resetAllProgress() async {
    await initialize();
    final keys = _prefs!.getKeys();
    for (final key in keys) {
      if (key.startsWith('level_') || key == 'max_level') {
        await _prefs!.remove(key);
      }
    }
  }
}
