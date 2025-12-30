import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'logic.dart';
import 'audio_manager.dart';
import 'storage.dart';
import 'assets.dart';
import '../widgets/premium_dialog.dart';

class PuzzleGame extends StatefulWidget {
  final int level;
  const PuzzleGame({super.key, required this.level});

  @override
  State<PuzzleGame> createState() => _PuzzleGameState();
}

class _PuzzleGameState extends State<PuzzleGame> {
  late PuzzleLogic logic;
  bool _isLoading = false;
  int moves = 0;
  int makeEasyUses = 0;
  int maxMoves = 0;
  late int gridSize;
  late String imagePath;
  bool showNumbers = false;
  List<int>? initialTiles;
  final _audioManager = AudioManager();
  final _storage = GameStorage();
  late ConfettiController _confettiController;
  int _targetMoves = 0; // For progress bar calculation
  bool isPremium = false;
  int? _hintTileIndex;
  bool _isGuideMode = false;
  int _maxMakeEasyUses = 2; // Always 2 uses per level
  int _hintsRemaining = 0; // Number of hints left to show sequentially

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Initialize storage and check premium status
    _storage.initialize().then((_) {
      final premiumStatus = _storage.getPremiumStatus();
      if (mounted) {
        setState(() {
          isPremium = premiumStatus;
        });
      }
    });

    _initLevel();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _initLevel() {
    int shuffleMoves = -1;

    if (widget.level <= 10) {
      gridSize = 2;
      shuffleMoves = 10;
    } else if (widget.level <= 20) {
      gridSize = 3;
      shuffleMoves = 30;
    } else {
      gridSize = 4;
      shuffleMoves = 60;
    }

    imagePath = PuzzleAssets.getImageForLevel(widget.level);

    _targetMoves = shuffleMoves == -1 ? gridSize * gridSize * 3 : shuffleMoves;
    if (_targetMoves < 10) _targetMoves = 10; // Minimum target

    logic = PuzzleLogic(gridSize);

    if (shuffleMoves != -1) {
      logic.shuffleByMoves(shuffleMoves);
    } else {
      logic.shuffle();
    }

    // Save the initial state for restart
    initialTiles = List.from(logic.tiles);

    moves = 0;
    makeEasyUses = 0;
    _maxMakeEasyUses = 2; // Fixed limit of 2 uses
    _isGuideMode = false;
    _hintTileIndex = null;
    _hintsRemaining = 0;

    maxMoves = _calculateMaxMoves(_targetMoves, gridSize);
  }

  int _calculateMaxMoves(int target, int gridSize) {
    double multiplier = 1.5;
    if (gridSize == 4) multiplier = 2.0;
    if (gridSize >= 5) multiplier = 2.5;

    return (target * multiplier).toInt() + 5;
  }

  void _handleTileTap(int index) {
    if (moves >= maxMoves) {
      _showOutOfMovesDialog();
      return;
    }

    if (logic.move(index)) {
      _audioManager.playClick(); // Play click sound
      setState(() {
        moves++;

        if (_isGuideMode) {
          _hintTileIndex = logic.getHint();
        } else if (_hintsRemaining > 0) {
          // Decrement hints remaining
          _hintsRemaining--;
          if (_hintsRemaining >= 0) {
            _hintTileIndex = logic.getHint();
          } else {
            _hintTileIndex = null; // Done with sequence
          }
        } else {
          _hintTileIndex = null; // Clear manual single hint if any
        }
      });
      if (logic.isSolved) {
        _isGuideMode = false;
        _hintsRemaining = 0;
        _showWinDialog();
      }
    }
  }

  void _restartLevel() {
    setState(() {
      // Restore from initial state
      if (initialTiles != null) {
        logic.tiles = List.from(initialTiles!);
        moves = 0;
      } else {
        _initLevel();
      }
    });
  }

  void _nextLevel() {
    if (widget.level < 30) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PuzzleGame(level: widget.level + 1),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          color: Colors.black87,
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.purpleAccent),
                SizedBox(height: 16),
                Text(
                  'Analyzing Puzzle...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _hideLoadingDialog() {
    Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog
  }

  void _showOptionsDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      // ...
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.purple.shade900, Colors.indigo.shade900],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'OPTIONS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 32),

              _buildOptionOptionRow(
                icon: Icons.diamond,
                label: 'Get Premium',
                color: Colors.amber,
                onTap: () {
                  Navigator.pop(context);
                  if (isPremium) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You are already a Premium member!'),
                        backgroundColor: Colors.amber,
                      ),
                    );
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) => PremiumSubscriptionDialog(
                        onSubscribe: () async {
                          await _storage.savePremiumStatus(true);
                          setState(() {
                            isPremium = true;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Premium Activated!'),
                                backgroundColor: Colors.amber,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),

              _buildOptionOptionRow(
                icon: Icons.visibility,
                label: 'Show Numbers',
                color: Colors.blueAccent,
                onTap: () {
                  setState(() {
                    showNumbers = !showNumbers;
                  });
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
              _buildOptionOptionRow(
                icon: Icons.auto_fix_high,
                label: 'Make Easy (${_maxMakeEasyUses - makeEasyUses} left)',
                color: Colors.purpleAccent,
                onTap: () {
                  if (makeEasyUses >= _maxMakeEasyUses) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'No "Make Easy" uses left for this level!',
                        ),
                      ),
                    );
                    return;
                  }

                  // Calculate hints to give
                  int hintsToGive = 2;
                  if (widget.level <= 10)
                    hintsToGive = 2; // Keep at 2 for Lv 1-10
                  else if (widget.level <= 20)
                    hintsToGive = 10;
                  else
                    hintsToGive = 15;

                  hintsToGive = 15;

                  VoidCallback onUse = () async {
                    _showLoadingDialog();
                    int? hint = await logic.getHintAsync();
                    _hideLoadingDialog();

                    setState(() {
                      if (hint != null) {
                        _hintTileIndex = hint;
                        _hintsRemaining = hintsToGive - 1;
                        makeEasyUses++;
                      }
                    });
                  };

                  if (isPremium) {
                    Navigator.pop(context); // Pop options first
                    onUse();
                  } else {
                    Navigator.pop(context);
                    _showAdPrompt('Watch Ad for $hintsToGive Hints?', onUse);
                  }
                },
              ),

              const SizedBox(height: 16),
              _buildOptionOptionRow(
                icon: Icons.auto_awesome, // Changed icon
                label: 'Skip Level (Guide)',
                color: Colors.orangeAccent,
                onTap: () {
                  Navigator.pop(context); // Pop options

                  VoidCallback onActivate = () async {
                    _showLoadingDialog();
                    int? hint = await logic.getHintAsync();
                    _hideLoadingDialog();

                    setState(() {
                      _isGuideMode = true;
                      _hintTileIndex = hint;
                    });
                  };

                  if (isPremium) {
                    onActivate();
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) => PremiumSubscriptionDialog(
                        onSubscribe: () async {
                          await _storage.savePremiumStatus(true);
                          setState(() {
                            isPremium = true;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Premium Activated!'),
                                backgroundColor: Colors.amber,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.close, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'EXIT GAME',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdPrompt(String message, VoidCallback onWatch) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.purple.shade900, Colors.deepPurple.shade900],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.amber, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Exciting Icon
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Icon(
                    Icons.card_giftcard,
                    color: Colors.amber,
                    size: 48,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                "SPECIAL OFFER!",
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                message, // e.g. "Watch Ad for 5 Hints?"
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 32),

              // Big CTA Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Simulate Ad
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Watching Ad... Reward Granted!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    onWatch();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 10,
                    shadowColor: Colors.greenAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_fill, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'WATCH & GET FREE!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Subtle Cancel
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'No thanks, I can solve this',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOutOfMovesDialog() {
    logic.stopTimer();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.red.shade900.withOpacity(0.95),
                Colors.orange.shade900.withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white24, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'OUT OF MOVES!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You have run out of moves.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 32),

              // Button 1: Watch Ad (+15 Moves)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (isPremium) {
                      setState(() {
                        maxMoves += 15;
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Free +15 Moves (Premium)!'),
                          backgroundColor: Colors.amber,
                        ),
                      );
                    } else {
                      // Simulate Ad Watch
                      setState(() {
                        maxMoves += 15;
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Received +15 Moves!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPremium
                        ? Colors.amber.shade800
                        : Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPremium ? Icons.star : Icons.play_circle_fill,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isPremium ? 'GET +15 MOVES (FREE)' : 'GET +15 MOVES',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Button 2: Restart Level
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    _restartLevel();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.refresh, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'RESTART LEVEL',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionOptionRow({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  int _calculateStars() {
    if (moves <= _targetMoves) return 5;
    if (moves <= _targetMoves * 1.25) return 4;
    if (moves <= _targetMoves * 1.5) return 3;
    if (moves <= _targetMoves * 1.75) return 2;
    return 1;
  }

  void _showWinDialog() {
    logic.stopTimer(); // Stop the timer
    _audioManager.playWin(); // Play win sound
    _confettiController.play();

    final int stars = _calculateStars();

    // Save Progress
    _storage.saveLevelScore(widget.level, logic.elapsedSeconds, moves, stars);

    bool isLastLevel = widget.level >= 30;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade900.withOpacity(0.95),
                Colors.indigo.shade900.withOpacity(0.95),
                Colors.deepPurple.shade900.withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white24, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Vibrant Title
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Colors.lightBlueAccent,
                    Colors.purpleAccent,
                    Colors.pinkAccent,
                  ],
                ).createShader(bounds),
                child: const Text(
                  'LEVEL COMPLETE!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      index < stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: index < stars ? Colors.amber : Colors.white24,
                      size: 42,
                      shadows: index < stars
                          ? [
                              Shadow(
                                color: Colors.amber.withOpacity(0.6),
                                blurRadius: 10,
                              ),
                            ]
                          : [],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Stats
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pets, size: 16, color: Colors.white70),
                    const SizedBox(width: 8),
                    Text(
                      '$moves / $maxMoves Moves',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Image Preview (Small)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white30),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 10),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imagePath,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _restartLevel();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh_rounded, color: Colors.white70),
                          SizedBox(width: 8),
                          Text(
                            'Replay',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _nextLevel();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor:
                            Colors.transparent, // Use gradient container
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.blueAccent, Colors.purpleAccent],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          height:
                              50, // Match typical button height manually since we wrapped in Ink
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLastLevel ? 'Finish' : 'Next',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageTile(int index, int tileValue) {
    int row = (tileValue - 1) ~/ gridSize;
    int col = (tileValue - 1) % gridSize;

    return LayoutBuilder(
      builder: (context, constraints) {
        double tileSize = constraints.maxWidth;
        double totalSize = tileSize * gridSize;

        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: totalSize,
                maxWidth: totalSize,
                minHeight: totalSize,
                maxHeight: totalSize,
                child: Transform.translate(
                  offset: Offset(-col * tileSize, -row * tileSize),
                  child: Image.asset(
                    imagePath,
                    width: totalSize,
                    height: totalSize,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            if (showNumbers)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$tileValue',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (_hintTileIndex == index)
              LayoutBuilder(
                builder: (context, constraints) {
                  int empty = logic.emptyTileIndex;
                  IconData icon = Icons.help_outline;
                  // Determine direction
                  if (empty == index - 1)
                    icon = Icons.arrow_back_rounded;
                  else if (empty == index + 1)
                    icon = Icons.arrow_forward_rounded;
                  else if (empty == index - gridSize)
                    icon = Icons.arrow_upward_rounded;
                  else if (empty == index + gridSize)
                    icon = Icons.arrow_downward_rounded;

                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                        border: Border.all(color: Colors.purple, width: 2),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.purple,
                        size: tileSize * 0.4,
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildProgressBar() {
    double progress = moves / maxMoves;
    if (progress > 1.0) progress = 1.0;

    Color barColor;
    if (progress < 0.5) {
      barColor = Color.lerp(
        Colors.green,
        Colors.lightGreenAccent,
        progress * 2,
      )!;
    } else {
      barColor = Color.lerp(
        Colors.lightGreenAccent,
        Colors.redAccent,
        (progress - 0.5) * 2,
      )!;
    }

    return Center(
      child: SizedBox(
        width: 300,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              const Icon(Icons.pets, color: Colors.white70, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.05, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: barColor.withOpacity(0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Allow gradient to show through
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove default back button
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: null,
        title: Text(
          'Level ${widget.level}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: GestureDetector(
              onTap: _showOptionsDialog,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
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
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildProgressBar(),
                        const SizedBox(height: 32),
                        AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Stack(
                              children: [
                                GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: gridSize,
                                        mainAxisSpacing: 2,
                                        crossAxisSpacing: 2,
                                      ),
                                  itemCount: gridSize * gridSize,
                                  itemBuilder: (context, index) {
                                    final tileValue = logic.tiles[index];
                                    if (tileValue == 0) return const SizedBox();

                                    return GestureDetector(
                                      onTap: () => _handleTileTap(index),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.3,
                                              ),
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: _buildImageTile(
                                          index,
                                          tileValue,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _restartLevel,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                                side: const BorderSide(color: Colors.white30),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.refresh, size: 28),
                                SizedBox(width: 8),
                                Text(
                                  'Restart Level',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [
                    Colors.green,
                    Colors.blue,
                    Colors.pink,
                    Colors.orange,
                    Colors.purple,
                  ],
                  numberOfParticles: 30,
                  gravity: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
