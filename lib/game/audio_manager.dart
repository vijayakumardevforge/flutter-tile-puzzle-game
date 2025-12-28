import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  // Create a pool of players for SFX to allow overlapping sounds
  final List<AudioPlayer> _sfxPool = List.generate(3, (_) => AudioPlayer());
  int _poolIndex = 0;

  final AudioPlayer _winPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();

  bool _isMuted = false;
  bool _isMusicEnabled = true;
  bool _isInitialized = false;

  bool get isMuted => _isMuted;
  bool get isMusicEnabled => _isMusicEnabled;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _isMuted = prefs.getBool('audio_muted') ?? false;
    _isMusicEnabled = prefs.getBool('music_enabled') ?? true;

    _bgmPlayer.setReleaseMode(ReleaseMode.loop);

    // Pre-configure players for lower latency if possible
    for (var player in _sfxPool) {
      await player.setReleaseMode(ReleaseMode.stop);
    }

    _isInitialized = true;
  }

  Future<void> playClick() async {
    if (_isMuted) return;
    try {
      // Use round-robin pool for clicks
      final player = _sfxPool[_poolIndex];
      _poolIndex = (_poolIndex + 1) % _sfxPool.length;

      await player.stop(); // Stop potential previous play
      await player.setVolume(0.3); // Lower volume (30%)
      await player.play(AssetSource('audio/click.wav'));
    } catch (e) {
      print('Audio Error: $e');
    }
  }

  Future<void> playWin() async {
    if (_isMuted) return;
    try {
      await _winPlayer.stop(); // Ensure it restarts
      await _winPlayer.setVolume(1.0); // 100% volume for win!
      await _winPlayer.play(AssetSource('audio/win.wav'));
    } catch (e) {
      print('Audio Error: $e');
    }
  }

  Future<void> playBackgroundMusic() async {
    if (_isMuted || !_isMusicEnabled) return;
    try {
      if (_bgmPlayer.state == PlayerState.playing)
        return; // Don't restart if already playing

      await _bgmPlayer.setVolume(0.2); // Low volume for BGM
      await _bgmPlayer.play(AssetSource('audio/background.mp3'));
    } catch (e) {
      print('BGM Error: $e'); // Print error to help debug
    }
  }

  Future<void> stopBackgroundMusic() async {
    await _bgmPlayer.stop();
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_muted', _isMuted);

    if (_isMuted) {
      await _bgmPlayer.pause();
    } else if (_isMusicEnabled) {
      await _bgmPlayer.resume();
    }
  }

  Future<void> toggleMusic() async {
    _isMusicEnabled = !_isMusicEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_enabled', _isMusicEnabled);

    if (!_isMusicEnabled) {
      await _bgmPlayer.pause();
    } else if (!_isMuted) {
      await _bgmPlayer.resume();
    }
  }

  void dispose() {
    for (var player in _sfxPool) {
      player.dispose();
    }
    _winPlayer.dispose();
    _bgmPlayer.dispose();
  }
}
