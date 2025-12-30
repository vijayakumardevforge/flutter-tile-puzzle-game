import 'package:collection/collection.dart';

// Top-level function for compute
List<int>? solvePuzzleInBackground(Map<String, dynamic> params) {
  final startState = params['startState'] as List<int>;
  final size = params['size'] as int;
  final solver = PuzzleSolver(startState, size);
  return solver.solve();
}

class PuzzleSolver {
  final List<int> startState;
  final int size;

  PuzzleSolver(this.startState, this.size);

  List<int>? solve() {
    // A* algorithm
    final goalState = List.generate(size * size, (i) => i + 1);
    goalState[size * size - 1] = 0;

    final openSet = PriorityQueue<_Node>((a, b) => a.f.compareTo(b.f));
    final closedSet = <String>{};

    final startNode = _Node(
      state: startState,
      g: 0,
      h: _calculateHeuristic(startState),
      parent: null,
      moveIndex: -1,
    );

    openSet.add(startNode);

    int iterations = 0;
    // Limit iterations to prevent freezing UI on hard puzzles
    // 4x4 can be hard. 100,000 should handle most reasonable depths.
    int maxIterations = 100000;

    while (openSet.isNotEmpty) {
      if (iterations++ > maxIterations) return null; // Too hard/slow

      final currentNode = openSet.removeFirst();
      final stateStr = currentNode.state.join(',');

      if (closedSet.contains(stateStr)) continue;
      closedSet.add(stateStr);

      if (_isSolved(currentNode.state)) {
        // Reconstruct path
        final path = <int>[];
        var node = currentNode;
        while (node.parent != null) {
          path.add(node.moveIndex);
          node = node.parent!;
        }
        return path.reversed.toList();
      }

      for (final neighbor in _getNeighbors(currentNode.state)) {
        if (closedSet.contains(neighbor.state.join(','))) continue;

        final newNode = _Node(
          state: neighbor.state,
          g: currentNode.g + 1,
          h: _calculateHeuristic(neighbor.state),
          parent: currentNode,
          moveIndex: neighbor.moveIndex,
        );

        openSet.add(newNode);
      }
    }
    return null;
  }

  bool _isSolved(List<int> state) {
    for (int i = 0; i < state.length - 1; i++) {
      if (state[i] != i + 1) return false;
    }
    return true;
  }

  int _calculateHeuristic(List<int> state) {
    int distance = 0;
    int linearConflict = 0;

    for (int i = 0; i < state.length; i++) {
      int value = state[i];
      if (value == 0) continue;
      // Target position
      int targetRow = (value - 1) ~/ size;
      int targetCol = (value - 1) % size;
      // Current position
      int currentRow = i ~/ size;
      int currentCol = i % size;
      distance +=
          (targetRow - currentRow).abs() + (targetCol - currentCol).abs();
    }

    // Linear Conflict Calculation
    // Row Linear Conflict
    for (int row = 0; row < size; row++) {
      for (int i = 0; i < size; i++) {
        int indexI = row * size + i;
        int valI = state[indexI];
        if (valI == 0) continue;
        int targetRowI = (valI - 1) ~/ size;

        // If tile I is in its correct row
        if (targetRowI == row) {
          for (int j = i + 1; j < size; j++) {
            int indexJ = row * size + j;
            int valJ = state[indexJ];
            if (valJ == 0) continue;
            int targetRowJ = (valJ - 1) ~/ size;

            // If tile J is also in its correct row
            if (targetRowJ == row) {
              // But target col of I > target col of J (Reversed order in row)
              // Tiles must cross each other
              int targetColI = (valI - 1) % size;
              int targetColJ = (valJ - 1) % size;

              if (targetColI > targetColJ) {
                linearConflict += 2;
              }
            }
          }
        }
      }
    }

    // Col Linear Conflict
    for (int col = 0; col < size; col++) {
      for (int i = 0; i < size; i++) {
        int indexI = i * size + col;
        int valI = state[indexI];
        if (valI == 0) continue;
        int targetColI = (valI - 1) % size;

        if (targetColI == col) {
          for (int j = i + 1; j < size; j++) {
            int indexJ = j * size + col;
            int valJ = state[indexJ];
            if (valJ == 0) continue;
            int targetColJ = (valJ - 1) % size;

            if (targetColJ == col) {
              int targetRowI = (valI - 1) ~/ size;
              int targetRowJ = (valJ - 1) ~/ size;

              if (targetRowI > targetRowJ) {
                linearConflict += 2;
              }
            }
          }
        }
      }
    }

    return distance + linearConflict;
  }

  List<_Neighbor> _getNeighbors(List<int> state) {
    final neighbors = <_Neighbor>[];
    int emptyIndex = state.indexOf(0);
    int row = emptyIndex ~/ size;
    int col = emptyIndex % size;

    final moves = [
      if (row > 0) emptyIndex - size, // Up
      if (row < size - 1) emptyIndex + size, // Down
      if (col > 0) emptyIndex - 1, // Left
      if (col < size - 1) emptyIndex + 1, // Right
    ];

    for (var moveIndex in moves) {
      final newState = List<int>.from(state);
      newState[emptyIndex] = newState[moveIndex];
      newState[moveIndex] = 0;
      neighbors.add(_Neighbor(newState, moveIndex));
    }
    return neighbors;
  }
}

class _Node {
  final List<int> state;
  final int g;
  final int h;
  final _Node? parent;
  final int moveIndex; // The tile index that was moved (swapped with empty)

  _Node({
    required this.state,
    required this.g,
    required this.h,
    this.parent,
    required this.moveIndex,
  });

  int get f => g + h;
}

class _Neighbor {
  final List<int> state;
  final int moveIndex;
  _Neighbor(this.state, this.moveIndex);
}
