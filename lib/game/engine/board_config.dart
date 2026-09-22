import 'dart:math';

/// Defines the Ludo board layout — all 52 main-track cells plus
/// each player's 5-cell home column and yard positions.
/// Every position is expressed as (row, col) on a 15×15 grid.
class BoardConfig {
  // ──────────────────────────────────────────────────────────────
  // Main track: 52 cells, clockwise, index 0 = Red's entry point.
  // ──────────────────────────────────────────────────────────────
  static const List<Point<int>> mainTrack = [
    // 0-4: Red entry → going right along row 6
    Point(6, 1), Point(6, 2), Point(6, 3), Point(6, 4), Point(6, 5),
    // 5-10: up col 6
    Point(5, 6), Point(4, 6), Point(3, 6), Point(2, 6), Point(1, 6), Point(0, 6),
    // 11-12: across top
    Point(0, 7), Point(0, 8),
    // 13-17: Green entry → down col 8
    Point(1, 8), Point(2, 8), Point(3, 8), Point(4, 8), Point(5, 8),
    // 18-23: right along row 6 (right half)
    Point(6, 9), Point(6, 10), Point(6, 11), Point(6, 12), Point(6, 13), Point(6, 14),
    // 24-25: down right edge
    Point(7, 14), Point(8, 14),
    // 26-30: Yellow entry → left along row 8
    Point(8, 13), Point(8, 12), Point(8, 11), Point(8, 10), Point(8, 9),
    // 31-36: down col 8 (bottom)
    Point(9, 8), Point(10, 8), Point(11, 8), Point(12, 8), Point(13, 8), Point(14, 8),
    // 37-38: across bottom
    Point(14, 7), Point(14, 6),
    // 39-43: Blue entry → up col 6 (bottom)
    Point(13, 6), Point(12, 6), Point(11, 6), Point(10, 6), Point(9, 6),
    // 44-49: left along row 8
    Point(8, 5), Point(8, 4), Point(8, 3), Point(8, 2), Point(8, 1), Point(8, 0),
    // 50-51: up left edge → Red's gateway to home column
    Point(7, 0), Point(6, 0),
  ];

  // ──────────────────────────────────────────────────────────────
  // Home columns: 5 coloured cells per player leading to centre.
  // Index 0 = first cell entered, index 4 = last before centre.
  // ──────────────────────────────────────────────────────────────
  static const List<Point<int>> redHomeColumn = [
    Point(7, 1), Point(7, 2), Point(7, 3), Point(7, 4), Point(7, 5),
  ];
  static const List<Point<int>> greenHomeColumn = [
    Point(1, 7), Point(2, 7), Point(3, 7), Point(4, 7), Point(5, 7),
  ];
  static const List<Point<int>> yellowHomeColumn = [
    Point(7, 13), Point(7, 12), Point(7, 11), Point(7, 10), Point(7, 9),
  ];
  static const List<Point<int>> blueHomeColumn = [
    Point(13, 7), Point(12, 7), Point(11, 7), Point(10, 7), Point(9, 7),
  ];

  /// Centre cell — a token placed here is finished.
  static const Point<int> centre = Point(7, 7);

  // ──────────────────────────────────────────────────────────────
  // Yard positions (4 tokens per player, 2×2 grid inside yard).
  // ──────────────────────────────────────────────────────────────
  static const List<List<Point<int>>> yardPositions = [
    // Red (top-left)
    [Point(2, 2), Point(2, 3), Point(3, 2), Point(3, 3)],
    // Green (top-right)
    [Point(2, 11), Point(2, 12), Point(3, 11), Point(3, 12)],
    // Yellow (bottom-right)
    [Point(11, 11), Point(11, 12), Point(12, 11), Point(12, 12)],
    // Blue (bottom-left)
    [Point(11, 2), Point(11, 3), Point(12, 2), Point(12, 3)],
  ];

  // ──────────────────────────────────────────────────────────────
  // Player metadata
  // ──────────────────────────────────────────────────────────────

  /// Global track index where each player's token enters the board.
  static const List<int> playerStartGlobalIndex = [0, 13, 26, 39];

  /// Home column for each player index.
  static List<List<Point<int>>> homeColumns(int playerIndex) {
    switch (playerIndex) {
      case 0: return redHomeColumn as List<List<Point<int>>>;
      case 1: return greenHomeColumn as List<List<Point<int>>>;
      case 2: return yellowHomeColumn as List<List<Point<int>>>;
      case 3: return blueHomeColumn as List<List<Point<int>>>;
      default: throw ArgumentError('Invalid player index: $playerIndex');
    }
  }

  static List<Point<int>> playerHomeColumn(int playerIndex) {
    switch (playerIndex) {
      case 0: return redHomeColumn;
      case 1: return greenHomeColumn;
      case 2: return yellowHomeColumn;
      case 3: return blueHomeColumn;
      default: throw ArgumentError('Invalid player index: $playerIndex');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Safe cells (global main-track indices — tokens here cannot
  // be captured, except at opponent starts).
  // ──────────────────────────────────────────────────────────────
  static const Set<int> safeCellsGlobal = {0, 8, 13, 21, 26, 34, 39, 47};

  /// Convert a player-local track position (0-51) to a global index.
  static int localToGlobal(int playerIndex, int localPos) {
    return (playerStartGlobalIndex[playerIndex] + localPos) % 52;
  }

  /// Convert a global track position to a player-local position.
  static int globalToLocal(int playerIndex, int globalPos) {
    final start = playerStartGlobalIndex[playerIndex];
    return (globalPos - start + 52) % 52;
  }

  /// Returns the board cell for a token at [localPos] for [playerIndex].
  /// localPos: -1 = yard, 0-51 = main track, 52-56 = home column, 57 = finished
  static Point<int>? boardCell(int playerIndex, int localPos, int tokenIndexInYard) {
    if (localPos == -1) {
      return yardPositions[playerIndex][tokenIndexInYard];
    }
    if (localPos >= 57) {
      return centre;
    }
    if (localPos >= 52) {
      final homeCol = playerHomeColumn(playerIndex);
      final homeIdx = localPos - 52;
      if (homeIdx < homeCol.length) return homeCol[homeIdx];
      return centre;
    }
    // Main track
    final globalIdx = localToGlobal(playerIndex, localPos);
    return mainTrack[globalIdx];
  }

  /// Is the given global cell a safe cell?
  static bool isGlobalSafe(int globalIndex) {
    return safeCellsGlobal.contains(globalIndex);
  }

  /// Player start positions are always safe.
  static bool isGlobalPlayerStart(int globalIndex) {
    return playerStartGlobalIndex.contains(globalIndex);
  }

  // ──────────────────────────────────────────────────────────────
  // Board colour regions — used by the painter to fill cells.
  // ──────────────────────────────────────────────────────────────

  /// Returns true if (row, col) is inside the given player's home yard.
  static bool isInYard(int playerIndex, int row, int col) {
    switch (playerIndex) {
      case 0: return row >= 1 && row <= 4 && col >= 1 && col <= 4;
      case 1: return row >= 1 && row <= 4 && col >= 10 && col <= 13;
      case 2: return row >= 10 && row <= 13 && col >= 10 && col <= 13;
      case 3: return row >= 10 && row <= 13 && col >= 1 && col <= 4;
      default: return false;
    }
  }

  /// Returns the colour region of a cell at (row, col): 0-3 for player, -1 for neutral.
  static int cellColorRegion(int row, int col) {
    // Home columns
    if (col == 7 && row >= 1 && row <= 5) return 1; // Green
    if (col == 7 && row >= 9 && row <= 13) return 3; // Blue
    if (row == 7 && col >= 1 && col <= 5) return 0; // Red
    if (row == 7 && col >= 9 && col <= 13) return 2; // Yellow
    // Yard interiors
    if (row >= 1 && row <= 4 && col >= 1 && col <= 4) return 0; // Red
    if (row >= 1 && row <= 4 && col >= 10 && col <= 13) return 1; // Green
    if (row >= 10 && row <= 13 && col >= 10 && col <= 13) return 2; // Yellow
    if (row >= 10 && row <= 13 && col >= 1 && col <= 4) return 3; // Blue
    // Center triangle regions
    if (row == 7 && col == 7) return -2; // centre (rainbow)
    return -1; // neutral
  }

  /// Coloured starting cells for player entry (their start square is coloured).
  static bool isPlayerEntryCell(int row, int col) {
    return mainTrack.indexOf(Point(row, col)) != -1 &&
        playerStartGlobalIndex.any((i) => mainTrack[i] == Point(row, col));
  }
}
