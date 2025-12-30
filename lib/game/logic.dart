import 'dart:math';
import 'dart:math';
import 'package:flutter/foundation.dart'; // For compute
import 'solver.dart';

class PuzzleLogic {
  final int size;
  late List<int> tiles;

  // Timer and move tracking
  int elapsedSeconds = 0;
  int moveCount = 0;
  DateTime? _startTime;
  bool _isTimerRunning = false;

  PuzzleLogic(this.size) {
    tiles = List.generate(size * size, (index) => index);
  }

  // 0 represents the empty tile
  int get emptyTileIndex => tiles.indexOf(0);

  void startTimer() {
    if (!_isTimerRunning) {
      _startTime = DateTime.now();
      _isTimerRunning = true;
    }
  }

  void stopTimer() {
    if (_isTimerRunning && _startTime != null) {
      elapsedSeconds = DateTime.now().difference(_startTime!).inSeconds;
      _isTimerRunning = false;
    }
  }

  void updateTimer() {
    if (_isTimerRunning && _startTime != null) {
      elapsedSeconds = DateTime.now().difference(_startTime!).inSeconds;
    }
  }

  void resetTimer() {
    elapsedSeconds = 0;
    moveCount = 0;
    _startTime = null;
    _isTimerRunning = false;
  }

  bool move(int tileIndex) {
    int emptyIndex = emptyTileIndex;

    // Check if adjacent
    int row = tileIndex ~/ size;
    int col = tileIndex % size;
    int emptyRow = emptyIndex ~/ size;
    int emptyCol = emptyIndex % size;

    if ((row == emptyRow && (col - emptyCol).abs() == 1) ||
        (col == emptyCol && (row - emptyRow).abs() == 1)) {
      // Swap
      tiles[emptyIndex] = tiles[tileIndex];
      tiles[tileIndex] = 0;
      moveCount++;
      startTimer(); // Start timer on first move
      return true;
    }
    return false;
  }

  void resetToSolved() {
    tiles = List.generate(size * size, (index) => index + 1);
    tiles[size * size - 1] = 0; // Empty tile at the end
  }

  void shuffleByMoves(int moveCount) {
    resetToSolved();
    final random = Random();
    int lastMoveIndex = -1;

    for (int i = 0; i < moveCount; i++) {
      int emptyIndex = emptyTileIndex;
      int row = emptyIndex ~/ size;
      int col = emptyIndex % size;

      List<int> neighbors = [];

      // Check Up
      if (row > 0) neighbors.add(emptyIndex - size);
      // Check Down
      if (row < size - 1) neighbors.add(emptyIndex + size);
      // Check Left
      if (col > 0) neighbors.add(emptyIndex - 1);
      // Check Right
      if (col < size - 1) neighbors.add(emptyIndex + 1);

      // Remove the tile we just moved (to avoid immediate undo)
      if (lastMoveIndex != -1) {
        neighbors.remove(lastMoveIndex);
      }

      if (neighbors.isEmpty && lastMoveIndex != -1) {
        neighbors.add(lastMoveIndex);
      }

      int moveIndex = neighbors[random.nextInt(neighbors.length)];

      // Perform swap directly
      tiles[emptyIndex] = tiles[moveIndex];
      tiles[moveIndex] = 0;

      lastMoveIndex = emptyIndex;
    }
  }

  void shuffle() {
    tiles.shuffle();
    if (!isSolvable()) {
      // If not solvable, swap the first two non-empty tiles to flip parity
      if (tiles[0] == 0 || tiles[1] == 0) {
        int temp = tiles[size * size - 1];
        tiles[size * size - 1] = tiles[size * size - 2];
        tiles[size * size - 2] = temp;
      } else {
        int temp = tiles[0];
        tiles[0] = tiles[1];
        tiles[1] = temp;
      }
    }
  }

  bool isSolvable() {
    int inversions = 0;
    List<int> currentTiles = List.from(tiles);
    currentTiles.remove(0);

    for (int i = 0; i < currentTiles.length; i++) {
      for (int j = i + 1; j < currentTiles.length; j++) {
        if (currentTiles[i] > currentTiles[j]) {
          inversions++;
        }
      }
    }

    int emptyIndex = tiles.indexOf(0);
    int emptyRowFromBottom = size - (emptyIndex ~/ size);

    if (size % 2 == 0) {
      if (emptyRowFromBottom % 2 == 0) {
        return inversions % 2 != 0;
      } else {
        return inversions % 2 == 0;
      }
    } else {
      return inversions % 2 == 0;
    }
  }

  void makeEasy() {
    // 1. Identify all tiles that are NOT in their correct position (excluding empty tile)
    List<int> misplacedIndices = [];
    for (int i = 0; i < tiles.length; i++) {
      if (tiles[i] != 0 && tiles[i] != i + 1) {
        misplacedIndices.add(i);
      }
    }

    if (misplacedIndices.isEmpty) return;

    // 2. Determine how many to fix (e.g., 50% of misplaced ones)
    int toFix = (misplacedIndices.length * 0.5).ceil();
    if (toFix < 1) toFix = 1;

    // 3. Fix them one by one
    for (int i = 0; i < toFix; i++) {
      // Find the first misplaced slot
      int currentSlotIndex = -1;
      for (int j = 0; j < tiles.length; j++) {
        if (tiles[j] != 0 && tiles[j] != j + 1) {
          currentSlotIndex = j;
          break;
        }
      }

      if (currentSlotIndex == -1) break; // All solved

      int targetValue = currentSlotIndex + 1;
      int targetTileIndex = tiles.indexOf(targetValue);

      // Swap to put the correct tile in currentSlotIndex
      if (targetTileIndex != -1) {
        tiles[targetTileIndex] = tiles[currentSlotIndex];
        tiles[currentSlotIndex] = targetValue;
      }
    }

    // 4. Ensure solvability
    if (!isSolvable()) {
      // Swap two arbitrary tiles that are NOT the ones we just fixed if possible.
      // The simplest way to not break the "first N fixed" logic is to swap the LAST two tiles.
      // If one of them is empty, swap with the one before it.
      int n = tiles.length;
      int i1 = n - 1;
      int i2 = n - 2;

      // If last tile is empty, use n-2 and n-3
      if (tiles[i1] == 0) {
        i1 = n - 2;
        i2 = n - 3;
      } else if (tiles[i2] == 0) {
        // If second to last is empty, use n-1 and n-3
        i2 = n - 3;
      }

      if (i1 >= 0 && i2 >= 0) {
        int temp = tiles[i1];
        tiles[i1] = tiles[i2];
        tiles[i2] = temp;
      }
    }
  }

  // Returns the index of the tile that should be moved
  int? getHint() {
    final solver = PuzzleSolver(tiles, size);
    final solution = solver.solve();
    if (solution != null && solution.isNotEmpty) {
      return solution.first;
    }
    return null;
  }

  // Async version using compute
  Future<int?> getHintAsync() async {
    final solution = await compute(solvePuzzleInBackground, {
      'startState': tiles,
      'size': size,
    });
    if (solution != null && solution.isNotEmpty) {
      return solution.first;
    }
    return null;
  }

  bool get isSolved {
    for (int i = 0; i < tiles.length - 1; i++) {
      if (tiles[i] != i + 1) return false;
    }
    return true;
  }
}
