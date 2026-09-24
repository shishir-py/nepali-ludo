import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Layout of the flat (un-tilted) board: a carved wooden frame around the
/// classic 15×15 Ludo grid. All board painters work in these coordinates.
class BoardGeometry {
  /// Side length of the flat board square in logical pixels.
  final double size;

  const BoardGeometry(this.size);

  /// Width of the wooden frame around the grid.
  double get frame => size * 0.058;

  /// Side length of one grid cell.
  double get cell => (size - frame * 2) / 15;

  /// Point on the board in *cell units*: u = column, v = row
  /// (so the centre of cell (row, col) is `at(col + 0.5, row + 0.5)`).
  Offset at(double u, double v) => Offset(frame + u * cell, frame + v * cell);

  Offset cellCentre(int row, int col) => at(col + 0.5, row + 0.5);

  Rect cellRect(int row, int col) =>
      Rect.fromLTWH(frame + col * cell, frame + row * cell, cell, cell);

  /// Rectangle spanning [rows] × [cols] cells starting at (row, col).
  Rect blockRect(int row, int col, int rows, int cols) => Rect.fromLTWH(
      frame + col * cell, frame + row * cell, cols * cell, rows * cell);
}

/// A perspective "camera" that tilts the flat board backwards (top edge
/// further away) and fits the result into a viewport.
///
/// The same matrix drives the [Transform] widget that renders the board and
/// the manual projection used to stand pawns upright on top of it, so the
/// two layers always line up.
class BoardCamera {
  /// Maps flat-board pixels (x, y, z) to viewport pixels.
  final Matrix4 matrix;

  /// Extra uniform scale applied so the tilted board fits the viewport.
  final double fitScale;

  /// Tilt angle in radians (0 = top-down).
  final double tilt;

  final BoardGeometry geometry;

  BoardCamera._(this.matrix, this.fitScale, this.tilt, this.geometry);

  /// Thickness of the wooden board slab, in flat-board pixels.
  static double slabThickness(double boardSize) => boardSize * 0.035;

  factory BoardCamera.fit({
    required double boardSize,
    required Size viewport,
    required double tilt,
  }) {
    final c = boardSize / 2;
    // Camera distance ≈ 2.4 board widths — enough perspective to read as 3D
    // without distorting the far rows too much.
    final perspective = 1 / (boardSize * 2.4);
    final rot = Matrix4.identity()
      ..setEntry(3, 2, perspective)
      ..rotateX(-tilt);
    final m = Matrix4.translationValues(c, c, 0)
        .multiplied(rot)
        .multiplied(Matrix4.translationValues(-c, -c, 0));

    final t = slabThickness(boardSize);
    final pts = <Offset>[
      _project(m, 0, 0, 0),
      _project(m, boardSize, 0, 0),
      _project(m, 0, boardSize, 0),
      _project(m, boardSize, boardSize, 0),
      _project(m, 0, boardSize, t),
      _project(m, boardSize, boardSize, t),
    ];
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final p in pts) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }
    // Head-room above the far edge so pawns standing on row 0 aren't clipped.
    minY -= boardSize * 0.05 * math.sin(tilt).abs();

    final bw = maxX - minX, bh = maxY - minY;
    final k = math.min(viewport.width / bw, viewport.height / bh) * 0.98;
    final dx = (viewport.width - bw * k) / 2 - minX * k;
    final dy = (viewport.height - bh * k) / 2 - minY * k;
    final fit = Matrix4.translationValues(dx, dy, 0)
        .multiplied(Matrix4.diagonal3Values(k, k, 1));

    return BoardCamera._(
        fit.multiplied(m), k, tilt, BoardGeometry(boardSize));
  }

  static Offset _project(Matrix4 m, double x, double y, double z) {
    final s = m.storage;
    final px = s[0] * x + s[4] * y + s[8] * z + s[12];
    final py = s[1] * x + s[5] * y + s[9] * z + s[13];
    final w = s[3] * x + s[7] * y + s[11] * z + s[15];
    return Offset(px / w, py / w);
  }

  /// Project a flat-board point to the viewport.
  Offset project(Offset p, [double z = 0]) =>
      _project(matrix, p.dx, p.dy, z);

  /// How many viewport pixels one flat-board pixel covers at [p]
  /// (bigger near the viewer, smaller far away).
  double scaleAt(Offset p) {
    final s = matrix.storage;
    final w = s[3] * p.dx + s[7] * p.dy + s[15];
    return fitScale / w;
  }

  /// Projected outline of a circle lying flat on the board.
  Path groundCircle(Offset centre, double radius, {int segments = 24}) {
    final path = Path();
    for (var i = 0; i <= segments; i++) {
      final a = i / segments * math.pi * 2;
      final p = project(centre + Offset(math.cos(a), math.sin(a)) * radius);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }
}
