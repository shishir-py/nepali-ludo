import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../game/engine/board_config.dart';
import '../board/board_geometry.dart';

/// Paints the static, flat Ludo board with raised "3D" tiles, a carved
/// wooden frame with a Dhaka-weave band, sunken yard wells and a golden
/// Nepali sun in the centre.
///
/// The board is painted flat; [BoardView] tilts it in perspective and draws
/// the pawns on top with their own painter, so this never needs to repaint
/// during play.
class BoardPainter extends CustomPainter {
  const BoardPainter();

  static Color _shade(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final g = BoardGeometry(size.width);
    _drawFrame(canvas, g);
    _drawTrackTiles(canvas, g);
    for (var p = 0; p < 4; p++) {
      _drawYard(canvas, g, p);
    }
    _drawCentre(canvas, g);
    _drawSafeStars(canvas, g);
    _drawEntryArrows(canvas, g);
  }

  // ─── Frame ───────────────────────────────────────────────────────────

  void _drawFrame(Canvas canvas, BoardGeometry g) {
    final outer = Offset.zero & Size(g.size, g.size);
    final r = Radius.circular(g.size * 0.03);

    // Carved wood.
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer, r),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8A4B22), Color(0xFF5B2C10), Color(0xFF7A3E18)],
        ).createShader(outer),
    );
    // Wood grain.
    final grain = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..strokeWidth = g.size * 0.002;
    for (var i = 0; i < 40; i++) {
      final y = g.size * (i / 40) + sin(i * 1.7) * 2;
      canvas.drawLine(Offset(0, y), Offset(g.size, y + sin(i) * 4), grain);
    }

    // Dhaka-weave band: alternating red / gold / green triangles.
    final band = g.frame * 0.55;
    final bandPaint = Paint();
    final colors = [
      NepaliColors.dhakaRed,
      NepaliColors.goldLight,
      NepaliColors.dhakaGreen,
      NepaliColors.goldLight,
    ];
    final step = band;
    var k = 0;
    for (var x = g.frame * 0.25; x < g.size - g.frame * 0.25; x += step) {
      bandPaint.color = colors[k++ % 4].withValues(alpha: 0.85);
      // top
      canvas.drawPath(
          Path()
            ..moveTo(x, g.frame * 0.22)
            ..lineTo(x + step, g.frame * 0.22)
            ..lineTo(x + step / 2, g.frame * 0.22 + band)
            ..close(),
          bandPaint);
      // bottom
      final by = g.size - g.frame * 0.22;
      canvas.drawPath(
          Path()
            ..moveTo(x, by)
            ..lineTo(x + step, by)
            ..lineTo(x + step / 2, by - band)
            ..close(),
          bandPaint);
      // left & right (reuse x as y)
      canvas.drawPath(
          Path()
            ..moveTo(g.frame * 0.22, x)
            ..lineTo(g.frame * 0.22, x + step)
            ..lineTo(g.frame * 0.22 + band, x + step / 2)
            ..close(),
          bandPaint);
      final rx = g.size - g.frame * 0.22;
      canvas.drawPath(
          Path()
            ..moveTo(rx, x)
            ..lineTo(rx, x + step)
            ..lineTo(rx - band, x + step / 2)
            ..close(),
          bandPaint);
    }

    // Inner gold bead + recessed play area.
    final inner = Rect.fromLTWH(
        g.frame, g.frame, g.size - g.frame * 2, g.size - g.frame * 2);
    canvas.drawRect(
      inner.inflate(g.frame * 0.12),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE08A), Color(0xFFB8860B), Color(0xFFFFD35C)],
        ).createShader(inner),
    );
    canvas.drawRect(inner, Paint()..color = const Color(0xFFEFE3C6));
    // Inner shadow along top/left to make the play area look sunken.
    canvas.drawRect(
      inner,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: const Alignment(-0.9, -0.9),
          colors: [Colors.black.withValues(alpha: 0.25), Colors.transparent],
        ).createShader(inner),
    );
  }

  // ─── Track tiles ─────────────────────────────────────────────────────

  void _drawTrackTiles(Canvas canvas, BoardGeometry g) {
    final startCells = {
      for (var p = 0; p < 4; p++)
        BoardConfig.mainTrack[BoardConfig.playerStartGlobalIndex[p]]: p,
    };
    // Main track (neutral or player start).
    for (final cell in BoardConfig.mainTrack) {
      final owner = startCells[cell];
      _tile(
        canvas,
        g,
        cell.x,
        cell.y,
        owner == null ? const Color(0xFFFFFBF2) : NepaliColors.playerColor(owner),
      );
    }
    // Home columns.
    for (var p = 0; p < 4; p++) {
      for (final cell in BoardConfig.playerHomeColumn(p)) {
        _tile(canvas, g, cell.x, cell.y, NepaliColors.playerColor(p));
      }
    }
  }

  /// A raised tile: darker "side" offset downwards, then a gradient top face
  /// with a light bevel on the upper-left edge.
  void _tile(Canvas canvas, BoardGeometry g, int row, int col, Color color) {
    final rect = g.cellRect(row, col).deflate(g.cell * 0.05);
    final radius = Radius.circular(g.cell * 0.14);
    final depth = g.cell * 0.07;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.shift(Offset(0, depth)), radius),
      Paint()..color = _shade(color, -0.28),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_shade(color, 0.10), color, _shade(color, -0.06)],
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(g.cell * 0.03), radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = g.cell * 0.035
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(rect),
    );
  }

  // ─── Yards ───────────────────────────────────────────────────────────

  static const _yardOrigins = [
    Point(0, 0), // red: rows 0-5, cols 0-5
    Point(0, 9), // green
    Point(9, 9), // yellow
    Point(9, 0), // blue
  ];

  void _drawYard(Canvas canvas, BoardGeometry g, int p) {
    final o = _yardOrigins[p];
    final color = NepaliColors.playerColor(p);
    final rect = g.blockRect(o.x, o.y, 6, 6).deflate(g.cell * 0.12);
    final r = Radius.circular(g.cell * 0.55);
    final depth = g.cell * 0.14;

    // Block side + drop shadow.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.shift(Offset(0, depth * 1.6)), r),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, g.cell * 0.2),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.shift(Offset(0, depth)), r),
      Paint()..color = _shade(color, -0.3),
    );
    // Top face.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, r),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          radius: 1.2,
          colors: [_shade(color, 0.14), color, _shade(color, -0.12)],
        ).createShader(rect),
    );
    // Subtle dhaka diamonds on the block.
    final diamond = Paint()..color = Colors.white.withValues(alpha: 0.10);
    for (var i = 0; i < 6; i++) {
      for (var j = 0; j < 6; j++) {
        if ((i + j).isOdd) continue;
        final c = g.at(o.y + j + 0.5, o.x + i + 0.5);
        final s = g.cell * 0.18;
        canvas.drawPath(
            Path()
              ..moveTo(c.dx, c.dy - s)
              ..lineTo(c.dx + s, c.dy)
              ..lineTo(c.dx, c.dy + s)
              ..lineTo(c.dx - s, c.dy)
              ..close(),
            diamond);
      }
    }

    // Sunken cream well.
    final well = g.blockRect(o.x + 1, o.y + 1, 4, 4).deflate(g.cell * 0.12);
    final wr = Radius.circular(g.cell * 0.45);
    canvas.drawRRect(RRect.fromRectAndRadius(well, wr),
        Paint()..color = const Color(0xFFFFF7E6));
    canvas.drawRRect(
      RRect.fromRectAndRadius(well, wr),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: const Alignment(0, -0.55),
          colors: [
            Colors.black.withValues(alpha: 0.28),
            Colors.black.withValues(alpha: 0.0),
          ],
        ).createShader(well),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(well, wr),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = g.cell * 0.06
        ..color = NepaliColors.gold,
    );

    // Four token sockets.
    for (final cell in BoardConfig.yardPositions[p]) {
      final c = g.cellCentre(cell.x, cell.y);
      final rad = g.cell * 0.42;
      canvas.drawCircle(
        c,
        rad,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, -0.35),
            colors: [
              _shade(color, -0.25),
              _shade(color, 0.05),
              _shade(color, 0.25),
            ],
            stops: const [0.0, 0.75, 1.0],
          ).createShader(Rect.fromCircle(center: c, radius: rad)),
      );
      canvas.drawCircle(
        c,
        rad,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = g.cell * 0.05
          ..color = Colors.white.withValues(alpha: 0.7),
      );
    }
  }

  // ─── Centre ──────────────────────────────────────────────────────────

  void _drawCentre(Canvas canvas, BoardGeometry g) {
    final area = g.blockRect(6, 6, 3, 3);
    final c = area.center;
    final tl = area.topLeft, tr = area.topRight;
    final bl = area.bottomLeft, br = area.bottomRight;
    // Each player's triangle faces their home column:
    // red ← left, green ↑ top, yellow → right, blue ↓ bottom.
    final tris = [
      [tl, bl], // red (left)
      [tl, tr], // green (top)
      [tr, br], // yellow (right)
      [bl, br], // blue (bottom)
    ];
    for (var p = 0; p < 4; p++) {
      final color = NepaliColors.playerColor(p);
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(tris[p][0].dx, tris[p][0].dy)
        ..lineTo(tris[p][1].dx, tris[p][1].dy)
        ..close();
      final mid = Offset((tris[p][0].dx + tris[p][1].dx) / 2,
          (tris[p][0].dy + tris[p][1].dy) / 2);
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment(
              (mid.dx - c.dx) / (area.width / 2),
              (mid.dy - c.dy) / (area.height / 2),
            ),
            end: Alignment.center,
            colors: [_shade(color, 0.08), _shade(color, -0.18)],
          ).createShader(area),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = g.cell * 0.04
          ..color = Colors.white.withValues(alpha: 0.6),
      );
    }

    // Golden Nepali sun medallion.
    final rad = g.cell * 0.72;
    canvas.drawCircle(
      c + Offset(0, g.cell * 0.08),
      rad,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, g.cell * 0.12),
    );
    _sun(canvas, c, rad, const Color(0xFFB8860B));
    _sun(canvas, c, rad * 0.9, null);
  }

  void _sun(Canvas canvas, Offset c, double r, Color? solid) {
    final path = Path();
    const points = 12;
    for (var i = 0; i < points * 2; i++) {
      final a = pi * i / points - pi / 2;
      final rr = i.isEven ? r : r * 0.74;
      final p = c + Offset(cos(a), sin(a)) * rr;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    final paint = Paint();
    if (solid != null) {
      paint.color = solid;
    } else {
      paint.shader = const RadialGradient(
        center: Alignment(-0.3, -0.35),
        colors: [Color(0xFFFFF3B0), Color(0xFFFFC93C), Color(0xFFD39A12)],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    }
    canvas.drawPath(path, paint);
  }

  // ─── Safe stars & arrows ─────────────────────────────────────────────

  void _drawSafeStars(Canvas canvas, BoardGeometry g) {
    for (final idx in BoardConfig.safeCellsGlobal) {
      final cell = BoardConfig.mainTrack[idx];
      final c = g.cellCentre(cell.x, cell.y);
      final isStart = BoardConfig.playerStartGlobalIndex.contains(idx);
      _star(canvas, c + Offset(0, g.cell * 0.04), g.cell * 0.33,
          Colors.black.withValues(alpha: 0.25));
      _star(canvas, c, g.cell * 0.33,
          isStart ? Colors.white : const Color(0xFFB8860B),
          highlight: isStart ? null : const Color(0xFFFFE08A));
    }
  }

  void _star(Canvas canvas, Offset c, double r, Color color,
      {Color? highlight}) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rr = i.isEven ? r : r * 0.42;
      final a = i * pi / 5 - pi / 2;
      final p = c + Offset(cos(a), sin(a)) * rr;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    final paint = Paint();
    if (highlight != null) {
      paint.shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: [highlight, color],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    } else {
      paint.color = color;
    }
    canvas.drawPath(path, paint);
  }

  /// Arrows on the cell where each colour turns into its home column.
  void _drawEntryArrows(Canvas canvas, BoardGeometry g) {
    const arrows = [
      (Point(7, 0), 0.0), // red → right
      (Point(0, 7), pi / 2), // green ↓
      (Point(7, 14), pi), // yellow ←
      (Point(14, 7), -pi / 2), // blue ↑
    ];
    for (var p = 0; p < 4; p++) {
      final (cell, angle) = arrows[p];
      final c = g.cellCentre(cell.x, cell.y);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(angle);
      final s = g.cell * 0.32;
      final path = Path()
        ..moveTo(-s, -s * 0.35)
        ..lineTo(s * 0.1, -s * 0.35)
        ..lineTo(s * 0.1, -s * 0.8)
        ..lineTo(s, 0)
        ..lineTo(s * 0.1, s * 0.8)
        ..lineTo(s * 0.1, s * 0.35)
        ..lineTo(-s, s * 0.35)
        ..close();
      canvas.drawPath(path.shift(Offset(0, g.cell * 0.04)),
          Paint()..color = Colors.black.withValues(alpha: 0.25));
      canvas.drawPath(path, Paint()..color = NepaliColors.playerColor(p));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) => false;
}
