import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../game/engine/board_config.dart';
import '../../game/engine/player.dart';

/// Custom painter for the 15×15 Ludo board.
/// Draws the board grid, coloured zones, safe-cell stars, home column paths,
/// and all token pieces.
class BoardPainter extends CustomPainter {
  final List<Player> players;
  final Set<int> highlightedTokenIds; // token ids the current player can move
  final int currentPlayerIndex;

  BoardPainter({
    required this.players,
    this.highlightedTokenIds = const {},
    required this.currentPlayerIndex,
  });

  static const int _gridSize = 15;

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / _gridSize;

    _drawBoardBackground(canvas, size, cellSize);
    _drawCells(canvas, cellSize);
    _drawHomeColumnPaths(canvas, cellSize);
    _drawCentreTriangles(canvas, cellSize);
    _drawYardAreas(canvas, cellSize);
    _drawSafeStars(canvas, cellSize);
    _drawTokens(canvas, cellSize);
  }

  // ─────────────────────────────────────────────────────────────
  // Board background
  // ─────────────────────────────────────────────────────────────

  void _drawBoardBackground(Canvas canvas, Size size, double cellSize) {
    final paint = Paint()
      ..color = NepaliColors.boardBackground
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      paint,
    );

    // Dhaka-inspired decorative border
    final borderPaint = Paint()
      ..color = NepaliColors.boardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = cellSize * 0.06;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cellSize * 0.1, cellSize * 0.1,
            size.width - cellSize * 0.2, size.height - cellSize * 0.2),
        const Radius.circular(10),
      ),
      borderPaint,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Grid cells
  // ─────────────────────────────────────────────────────────────

  void _drawCells(Canvas canvas, double cellSize) {
    for (int row = 0; row < _gridSize; row++) {
      for (int col = 0; col < _gridSize; col++) {
        _drawCell(canvas, row, col, cellSize);
      }
    }
  }

  void _drawCell(Canvas canvas, int row, int col, double cellSize) {
    final rect = _cellRect(row, col, cellSize);
    final region = BoardConfig.cellColorRegion(row, col);

    Color fillColor;
    if (region >= 0) {
      fillColor = NepaliColors.playerColor(region).withValues(alpha: 0.55);
    } else if (region == -2) {
      fillColor = Colors.transparent; // centre drawn separately
    } else {
      fillColor = NepaliColors.neutralCell;
    }

    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, paint);

    // Cell border
    final borderPaint = Paint()
      ..color = NepaliColors.boardBorder.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRect(rect, borderPaint);
  }

  Rect _cellRect(int row, int col, double cellSize) {
    return Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize);
  }

  // ─────────────────────────────────────────────────────────────
  // Home-column paths (the coloured channel leading to centre)
  // ─────────────────────────────────────────────────────────────

  void _drawHomeColumnPaths(Canvas canvas, double cellSize) {
    // Already painted by _drawCells via cellColorRegion, but add richer tint.
    final columns = [
      BoardConfig.redHomeColumn,
      BoardConfig.greenHomeColumn,
      BoardConfig.yellowHomeColumn,
      BoardConfig.blueHomeColumn,
    ];
    for (int pi = 0; pi < 4; pi++) {
      final col = columns[pi];
      final paint = Paint()
        ..color = NepaliColors.playerColor(pi).withValues(alpha: 0.72)
        ..style = PaintingStyle.fill;
      for (final p in col) {
        canvas.drawRect(_cellRect(p.x, p.y, cellSize), paint);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Centre (rainbow triangles)
  // ─────────────────────────────────────────────────────────────

  void _drawCentreTriangles(Canvas canvas, double cellSize) {
    final cx = 7 * cellSize + cellSize / 2;
    final cy = 7 * cellSize + cellSize / 2;
    final r = cellSize * 1.5;

    final colors = [
      NepaliColors.redPlayer,
      NepaliColors.greenPlayer,
      NepaliColors.yellowPlayer,
      NepaliColors.bluePlayer,
    ];
    final angles = [pi, pi / 2, 0, -pi / 2]; // pointing N/E/S/W

    for (int i = 0; i < 4; i++) {
      final angle = angles[i];
      final path = Path()
        ..moveTo(cx, cy)
        ..lineTo(cx + r * cos(angle - pi / 4), cy + r * sin(angle - pi / 4))
        ..lineTo(cx + r * cos(angle + pi / 4), cy + r * sin(angle + pi / 4))
        ..close();
      canvas.drawPath(path, Paint()..color = colors[i].withValues(alpha: 0.85));
    }

    // Centre star
    final starPaint = Paint()
      ..color = NepaliColors.gold
      ..style = PaintingStyle.fill;
    _drawStar(canvas, Offset(cx, cy), cellSize * 0.4, starPaint);
  }

  void _drawStar(Canvas canvas, Offset centre, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? radius : radius * 0.4;
      final angle = (i * pi / 5) - pi / 2;
      final p = Offset(centre.dx + r * cos(angle), centre.dy + r * sin(angle));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  // ─────────────────────────────────────────────────────────────
  // Yard areas (large coloured squares with inner white circle)
  // ─────────────────────────────────────────────────────────────

  void _drawYardAreas(Canvas canvas, double cellSize) {
    final yardBounds = [
      const Rect.fromLTWH(0, 0, 6, 6), // Red
      const Rect.fromLTWH(9, 0, 6, 6), // Green
      const Rect.fromLTWH(9, 9, 6, 6), // Yellow
      const Rect.fromLTWH(0, 9, 6, 6), // Blue
    ];

    for (int pi = 0; pi < 4; pi++) {
      final b = yardBounds[pi];
      final rect = Rect.fromLTWH(b.left * cellSize, b.top * cellSize,
          b.width * cellSize, b.height * cellSize);

      // Background
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cellSize * 0.5)),
        Paint()..color = NepaliColors.playerColor(pi).withValues(alpha: 0.8),
      );

      // Inner white rounded square
      final innerPadding = cellSize * 0.5;
      final innerRect = rect.deflate(innerPadding);
      canvas.drawRRect(
        RRect.fromRectAndRadius(innerRect, Radius.circular(cellSize * 0.4)),
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );

      // Decorative Dhaka-style border on yard
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cellSize * 0.5)),
        Paint()
          ..color = NepaliColors.playerColor(pi).withValues(alpha: 1.0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = cellSize * 0.08,
      );

      // Draw 4 small token placeholders in yard
      final yardCentres = BoardConfig.yardPositions[pi];
      for (int ti = 0; ti < 4; ti++) {
        final pos = yardCentres[ti];
        final centre = Offset(
          (pos.y + 0.5) * cellSize,
          (pos.x + 0.5) * cellSize,
        );
        canvas.drawCircle(
          centre,
          cellSize * 0.32,
          Paint()..color = NepaliColors.playerColor(pi).withValues(alpha: 0.2),
        );
        canvas.drawCircle(
          centre,
          cellSize * 0.32,
          Paint()
            ..color = NepaliColors.playerColor(pi)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Safe-cell stars
  // ─────────────────────────────────────────────────────────────

  void _drawSafeStars(Canvas canvas, double cellSize) {
    const safes = BoardConfig.safeCellsGlobal;
    for (final globalIdx in safes) {
      final cell = BoardConfig.mainTrack[globalIdx];
      final centre = Offset(
        (cell.y + 0.5) * cellSize,
        (cell.x + 0.5) * cellSize,
      );
      _drawStar(
        canvas,
        centre,
        cellSize * 0.3,
        Paint()..color = NepaliColors.safeCellStar,
      );
    }

    // Player start cells get a special star in their colour.
    for (int pi = 0; pi < 4; pi++) {
      final globalIdx = BoardConfig.playerStartGlobalIndex[pi];
      final cell = BoardConfig.mainTrack[globalIdx];
      final centre = Offset(
        (cell.y + 0.5) * cellSize,
        (cell.x + 0.5) * cellSize,
      );
      _drawStar(
        canvas,
        centre,
        cellSize * 0.3,
        Paint()..color = NepaliColors.playerColor(pi),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Tokens
  // ─────────────────────────────────────────────────────────────

  void _drawTokens(Canvas canvas, double cellSize) {
    // Gather all token positions indexed by board cell.
    // Multiple tokens on same cell → cluster them.
    final Map<String, List<_TokenInfo>> cellMap = {};

    for (int pi = 0; pi < players.length; pi++) {
      final player = players[pi];
      for (int ti = 0; ti < player.tokens.length; ti++) {
        final token = player.tokens[ti];
        if (token.isFinished) continue;

        final cell = BoardConfig.boardCell(pi, token.position, ti);
        if (cell == null) continue;

        final key = '${cell.x},${cell.y}';
        cellMap.putIfAbsent(key, () => []);
        cellMap[key]!.add(_TokenInfo(
          playerIndex: pi,
          tokenId: token.id,
          localPos: token.position,
          cell: cell,
          isHighlighted: pi == currentPlayerIndex &&
              highlightedTokenIds.contains(token.id),
        ));
      }
    }

    for (final tokens in cellMap.values) {
      _drawTokenGroup(canvas, tokens, cellSize);
    }
  }

  void _drawTokenGroup(
      Canvas canvas, List<_TokenInfo> tokens, double cellSize) {
    final count = tokens.length;
    final cellCentre = Offset(
      (tokens.first.cell.y + 0.5) * cellSize,
      (tokens.first.cell.x + 0.5) * cellSize,
    );

    if (count == 1) {
      _drawSingleToken(canvas, tokens.first, cellCentre, cellSize * 0.36);
      return;
    }

    // Cluster multiple tokens in a 2×2 arrangement.
    final offsets = [
      const Offset(-0.22, -0.22),
      const Offset(0.22, -0.22),
      const Offset(-0.22, 0.22),
      const Offset(0.22, 0.22),
    ];
    for (int i = 0; i < count && i < 4; i++) {
      final off = offsets[i] * cellSize;
      _drawSingleToken(canvas, tokens[i], cellCentre + off, cellSize * 0.26);
    }
  }

  void _drawSingleToken(
      Canvas canvas, _TokenInfo info, Offset centre, double radius) {
    final color = NepaliColors.playerColor(info.playerIndex);

    // Shadow
    canvas.drawCircle(
      centre + const Offset(2, 3),
      radius,
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // Body
    canvas.drawCircle(centre, radius, Paint()..color = color);

    // Sheen
    canvas.drawCircle(
      centre - Offset(radius * 0.3, radius * 0.3),
      radius * 0.35,
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );

    // Outer ring (white)
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.18,
    );

    // Highlight ring if this token can be moved
    if (info.isHighlighted) {
      canvas.drawCircle(
        centre,
        radius + 3,
        Paint()
          ..color = NepaliColors.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // Token number
    final tp = TextPainter(
      text: TextSpan(
        text: '${info.tokenId + 1}',
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.85,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      centre - Offset(tp.width / 2, tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) => true;
}

class _TokenInfo {
  final int playerIndex;
  final int tokenId;
  final int localPos;
  final Point<int> cell;
  final bool isHighlighted;

  _TokenInfo({
    required this.playerIndex,
    required this.tokenId,
    required this.localPos,
    required this.cell,
    this.isHighlighted = false,
  });
}
