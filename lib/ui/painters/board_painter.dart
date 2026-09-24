import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../game/engine/board_config.dart';
import '../board/board_geometry.dart';

/// Paints the static Ludo board: a carved bronze frame with golden lotus
/// medallions, four yards set into little Himalayan scenes, engraved ivory
/// tiles, colour lanes and a golden lotus at the centre.
///
/// Pawns are drawn by [BoardView] on top, so this never repaints in play.
class BoardPainter extends CustomPainter {
  const BoardPainter();

  static Color _shade(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  static const _gold = Color(0xFFE2B54A);
  static const _goldDark = Color(0xFF9A6B1B);
  static const _goldLight = Color(0xFFFFE8A3);
  static const _ivory = Color(0xFFFFFBF1);
  static const _ivoryDark = Color(0xFFEDE2CB);

  @override
  void paint(Canvas canvas, Size size) {
    final g = BoardGeometry(size.width);
    _drawFrame(canvas, g);
    for (var p = 0; p < 4; p++) {
      _drawYard(canvas, g, p);
    }
    _drawTrack(canvas, g);
    _drawCentre(canvas, g);
    _drawEntryArrows(canvas, g);
    _drawCornerMedallions(canvas, g);
  }

  // ─── Frame ───────────────────────────────────────────────────────────

  void _drawFrame(Canvas canvas, BoardGeometry g) {
    final s = g.size, f = g.frame;
    final outer = Offset.zero & Size(s, s);
    final r = Radius.circular(f * 0.7);

    canvas.drawRRect(
      RRect.fromRectAndRadius(outer, r),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6E3B1A), Color(0xFF3A1D0C), Color(0xFF5C3014)],
        ).createShader(outer),
    );
    // Gold trims.
    for (final (inset, width) in [(f * 0.16, f * 0.09), (f * 0.78, f * 0.05)]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(outer.deflate(inset), Radius.circular(f * 0.5)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_goldLight, _gold, _goldDark, _gold],
          ).createShader(outer),
      );
    }
    // Studs along the frame.
    final stud = Paint()..color = _gold;
    final studShade = Paint()..color = Colors.black.withValues(alpha: 0.35);
    final step = g.cell * 1.5;
    for (var x = f + step; x < s - f - step * 0.5; x += step) {
      for (final p in [
        Offset(x, f * 0.47),
        Offset(x, s - f * 0.47),
        Offset(f * 0.47, x),
        Offset(s - f * 0.47, x),
      ]) {
        canvas.drawCircle(p + Offset(0, f * 0.04), f * 0.1, studShade);
        canvas.drawCircle(p, f * 0.1, stud);
      }
    }

    // Grout behind the tiles.
    final inner = Rect.fromLTWH(f, f, s - f * 2, s - f * 2);
    canvas.drawRect(inner, Paint()..color = const Color(0xFFB88F4E));
  }

  void _drawCornerMedallions(Canvas canvas, BoardGeometry g) {
    final s = g.size, f = g.frame;
    final m = f * 1.9;
    for (final c in [
      Offset(f * 0.62, f * 0.62),
      Offset(s - f * 0.62, f * 0.62),
      Offset(f * 0.62, s - f * 0.62),
      Offset(s - f * 0.62, s - f * 0.62),
    ]) {
      final rect = Rect.fromCenter(center: c, width: m, height: m);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            rect.shift(Offset(0, f * 0.08)), Radius.circular(m * 0.18)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.4)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, f * 0.12),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(m * 0.18)),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_goldLight, _gold, _goldDark],
          ).createShader(rect),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(m * 0.08), Radius.circular(m * 0.14)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = m * 0.03
          ..color = _goldDark.withValues(alpha: 0.8),
      );
      _lotus(canvas, c, m * 0.36, _goldDark.withValues(alpha: 0.85),
          _goldLight, centre: const Color(0xFF7A4E10));
    }
  }

  // ─── Yards ───────────────────────────────────────────────────────────

  static const _yardOrigins = [
    Point(0, 0), // red   (rows 0-5, cols 0-5)
    Point(0, 9), // green
    Point(9, 9), // yellow
    Point(9, 0), // blue
  ];

  void _drawYard(Canvas canvas, BoardGeometry g, int p) {
    final o = _yardOrigins[p];
    final color = NepaliColors.playerColor(p);
    final c = g.cell;
    final block = g.blockRect(o.x, o.y, 6, 6).deflate(c * 0.06);
    final rr = RRect.fromRectAndRadius(block, Radius.circular(c * 0.35));

    canvas.save();
    canvas.clipRRect(rr);
    _scene(canvas, block, color, p);
    canvas.restore();
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = c * 0.1
        ..shader = const LinearGradient(
          colors: [_goldLight, _goldDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(block),
    );

    // Big ring + ivory mandala disc.
    final centre = block.center;
    final ringR = c * 2.55;
    canvas.drawCircle(
      centre + Offset(0, c * 0.12),
      ringR,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, c * 0.25),
    );
    canvas.drawCircle(
      centre,
      ringR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.1,
          colors: [_shade(color, 0.18), color, _shade(color, -0.22)],
        ).createShader(Rect.fromCircle(center: centre, radius: ringR)),
    );
    // Engraved notches around the ring.
    final notch = Paint()
      ..color = _shade(color, -0.3).withValues(alpha: 0.55)
      ..strokeWidth = c * 0.03;
    for (var i = 0; i < 48; i++) {
      final a = i / 48 * pi * 2;
      final d = Offset(cos(a), sin(a));
      canvas.drawLine(centre + d * (ringR - c * 0.08),
          centre + d * (ringR - c * 0.2), notch);
    }
    for (final (rad, w) in [(ringR - c * 0.02, c * 0.05), (c * 2.16, c * 0.07)]) {
      canvas.drawCircle(
          centre,
          rad,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = w
            ..color = _gold);
    }
    final discR = c * 2.12;
    canvas.drawCircle(
      centre,
      discR,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.2, -0.3),
          colors: [_ivory, Color(0xFFF6EDD9), Color(0xFFE6D6B5)],
          stops: [0.0, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: centre, radius: discR)),
    );
    _mandala(canvas, centre, discR * 0.95, const Color(0xFFCDB88E));

    // Four sockets.
    for (final cell in BoardConfig.yardPositions[p]) {
      final sc = g.cellCentre(cell.x, cell.y);
      final r = c * 0.43;
      canvas.drawCircle(
        sc,
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, -0.4),
            colors: [
              _shade(color, -0.2).withValues(alpha: 0.55),
              _shade(color, 0.1).withValues(alpha: 0.25),
              _ivory,
            ],
            stops: const [0.0, 0.8, 1.0],
          ).createShader(Rect.fromCircle(center: sc, radius: r)),
      );
      canvas.drawCircle(
          sc,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = c * 0.05
            ..color = color.withValues(alpha: 0.7));
    }
  }

  /// A little Himalayan scene behind each yard: tinted sky, snowy peaks,
  /// green hills, pagodas in the corners and a string of prayer flags.
  void _scene(Canvas canvas, Rect r, Color color, int p) {
    final w = r.width, h = r.height;
    // Sky – each yard gets its own time of day.
    const skies = [
      [Color(0xFFFFB27A), Color(0xFFFFE1B8)], // red: sunset
      [Color(0xFF8FD0F2), Color(0xFFE8F6E8)], // green: fresh morning
      [Color(0xFFFFC94D), Color(0xFFFFF0C2)], // yellow: golden hour
      [Color(0xFF6FA8E8), Color(0xFFDDEBFA)], // blue: clear day
    ];
    canvas.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: skies[p],
        ).createShader(r),
    );
    // Far snowy range.
    final ridge = Path()..moveTo(r.left, r.top + h * 0.42);
    const peaks = [0.1, 0.22, 0.34, 0.5, 0.63, 0.78, 0.9, 1.0];
    const heights = [0.2, 0.08, 0.26, 0.05, 0.2, 0.1, 0.24, 0.32];
    for (var i = 0; i < peaks.length; i++) {
      ridge.lineTo(r.left + w * peaks[i], r.top + h * heights[i]);
      if (i < peaks.length - 1) {
        ridge.lineTo(r.left + w * (peaks[i] + peaks[i + 1]) / 2,
            r.top + h * (0.3 + 0.05 * (i % 2)));
      }
    }
    ridge
      ..lineTo(r.right, r.bottom)
      ..lineTo(r.left, r.bottom)
      ..close();
    canvas.drawPath(ridge, Paint()..color = const Color(0xFF8C9BB5));
    // Snow caps.
    final snow = Paint()..color = Colors.white.withValues(alpha: 0.9);
    for (var i = 0; i < peaks.length; i++) {
      final tip = Offset(r.left + w * peaks[i], r.top + h * heights[i]);
      final d = w * 0.045;
      canvas.drawPath(
          Path()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(tip.dx + d, tip.dy + d * 1.3)
            ..lineTo(tip.dx + d * 0.2, tip.dy + d * 1.0)
            ..lineTo(tip.dx - d * 0.4, tip.dy + d * 1.4)
            ..lineTo(tip.dx - d, tip.dy + d * 1.2)
            ..close(),
          snow);
    }
    // Rolling hills tinted towards the player's colour.
    final hill = Color.lerp(const Color(0xFF3F7D3A), color, 0.25)!;
    canvas.drawPath(
      Path()
        ..moveTo(r.left, r.top + h * 0.62)
        ..quadraticBezierTo(
            r.left + w * 0.3, r.top + h * 0.5, r.left + w * 0.55, r.top + h * 0.64)
        ..quadraticBezierTo(
            r.left + w * 0.8, r.top + h * 0.76, r.right, r.top + h * 0.6)
        ..lineTo(r.right, r.bottom)
        ..lineTo(r.left, r.bottom)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_shade(hill, 0.1), _shade(hill, -0.18)],
        ).createShader(r),
    );
    // Pagodas in the two outer corners (the ring covers the middle).
    final roof = _shade(color, -0.25);
    _pagoda(canvas, Offset(r.left + w * 0.11, r.bottom - h * 0.02), w * 0.2,
        roof);
    _pagoda(canvas, Offset(r.right - w * 0.11, r.bottom - h * 0.02), w * 0.17,
        roof);
    _pagoda(canvas, Offset(r.right - w * 0.1, r.top + h * 0.33), w * 0.12,
        roof);
    // Prayer flags across the top-left corner.
    const flags = [
      Color(0xFF1E6FD9),
      Colors.white,
      Color(0xFFD62828),
      Color(0xFF2A9D48),
      Color(0xFFF2C230),
    ];
    final a = Offset(r.left, r.top + h * 0.05);
    final b = Offset(r.left + w * 0.42, r.top);
    canvas.drawLine(
        a,
        b,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.3)
          ..strokeWidth = 1);
    for (var i = 0; i < 7; i++) {
      final t = (i + 0.5) / 7;
      final pt = Offset.lerp(a, b, t)!;
      canvas.drawRect(
          Rect.fromLTWH(pt.dx - w * 0.022, pt.dy, w * 0.044, h * 0.06),
          Paint()..color = flags[i % flags.length]);
    }
  }

  /// Tiered Newari-style pagoda silhouette standing on [base].
  void _pagoda(Canvas canvas, Offset base, double w, Color roof) {
    final wall = Paint()..color = const Color(0xFF7A2E1A);
    final roofPaint = Paint()..color = roof;
    final trim = Paint()..color = _gold;
    var y = base.dy;
    var width = w;
    canvas.drawRect(
        Rect.fromLTWH(base.dx - width * 0.55, y - w * 0.12, width * 1.1, w * 0.12),
        Paint()..color = const Color(0xFF5B4632));
    y -= w * 0.12;
    for (var tier = 0; tier < 3; tier++) {
      final bodyH = w * (0.3 - tier * 0.05);
      canvas.drawRect(
          Rect.fromLTWH(base.dx - width * 0.32, y - bodyH, width * 0.64, bodyH),
          wall);
      y -= bodyH;
      final roofH = w * 0.18;
      final roofPath = Path()
        ..moveTo(base.dx - width * 0.62, y + roofH * 0.15)
        ..quadraticBezierTo(base.dx - width * 0.4, y, base.dx - width * 0.25,
            y - roofH * 0.7)
        ..lineTo(base.dx + width * 0.25, y - roofH * 0.7)
        ..quadraticBezierTo(
            base.dx + width * 0.4, y, base.dx + width * 0.62, y + roofH * 0.15)
        ..close();
      canvas.drawPath(roofPath, roofPaint);
      canvas.drawLine(
          Offset(base.dx - width * 0.6, y + roofH * 0.12),
          Offset(base.dx + width * 0.6, y + roofH * 0.12),
          trim..strokeWidth = max(0.8, w * 0.02));
      y -= roofH * 0.7;
      width *= 0.72;
    }
    // Golden finial.
    canvas.drawCircle(Offset(base.dx, y - w * 0.05), w * 0.05, trim);
  }

  // ─── Track ───────────────────────────────────────────────────────────

  /// Which arm a track cell sits on, as the colour owning that arm.
  static int _armOwner(Point<int> cell) {
    if (cell.x < 6) return 1; // top arm – green
    if (cell.y > 8) return 2; // right arm – yellow
    if (cell.x > 8) return 3; // bottom arm – blue
    return 0; // left arm – red
  }

  void _drawTrack(Canvas canvas, BoardGeometry g) {
    final starts = {
      for (var p = 0; p < 4; p++)
        BoardConfig.mainTrack[BoardConfig.playerStartGlobalIndex[p]]: p,
    };
    for (var i = 0; i < BoardConfig.mainTrack.length; i++) {
      final cell = BoardConfig.mainTrack[i];
      final owner = starts[cell];
      if (owner != null) {
        final color = NepaliColors.playerColor(owner);
        _tile(canvas, g, cell.x, cell.y, color, engrave: false);
        _lotus(canvas, g.cellCentre(cell.x, cell.y), g.cell * 0.36,
            Colors.white.withValues(alpha: 0.95), Colors.white,
            centre: _shade(color, -0.1));
      } else {
        _tile(canvas, g, cell.x, cell.y, _ivory);
        if (BoardConfig.safeCellsGlobal.contains(i)) {
          final c = g.cellCentre(cell.x, cell.y);
          final col = NepaliColors.playerColor(_armOwner(cell));
          _star(canvas, c + Offset(0, g.cell * 0.04), g.cell * 0.34,
              Colors.black.withValues(alpha: 0.2));
          _star(canvas, c, g.cell * 0.34, col,
              highlight: _shade(col, 0.25));
        }
      }
    }
    for (var p = 0; p < 4; p++) {
      for (final cell in BoardConfig.playerHomeColumn(p)) {
        _tile(canvas, g, cell.x, cell.y, NepaliColors.playerColor(p));
      }
    }
  }

  /// Raised, bevelled tile with a faint engraved lotus diamond.
  void _tile(Canvas canvas, BoardGeometry g, int row, int col, Color color,
      {bool engrave = true}) {
    final c = g.cell;
    final rect = g.cellRect(row, col).deflate(c * 0.045);
    final radius = Radius.circular(c * 0.12);
    final isIvory = color == _ivory;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.shift(Offset(0, c * 0.06)), radius),
      Paint()..color = isIvory ? const Color(0xFFCDBB97) : _shade(color, -0.28),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isIvory
              ? const [_ivory, Color(0xFFF7F0E0), _ivoryDark]
              : [_shade(color, 0.12), color, _shade(color, -0.08)],
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(c * 0.03), radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = c * 0.03
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.6),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(rect),
    );
    if (!engrave) return;
    // Engraved diamond with inner petals.
    final cc = rect.center;
    final s = c * 0.26;
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(0.6, c * 0.018)
      ..color = isIvory
          ? const Color(0xFFD6C6A4)
          : Colors.white.withValues(alpha: 0.28);
    canvas.drawPath(
        Path()
          ..moveTo(cc.dx, cc.dy - s)
          ..lineTo(cc.dx + s, cc.dy)
          ..lineTo(cc.dx, cc.dy + s)
          ..lineTo(cc.dx - s, cc.dy)
          ..close(),
        ink);
    for (var k = 0; k < 4; k++) {
      final a = k * pi / 2;
      canvas.drawCircle(cc + Offset(cos(a), sin(a)) * s * 0.45, s * 0.2, ink);
    }
  }

  // ─── Centre ──────────────────────────────────────────────────────────

  void _drawCentre(Canvas canvas, BoardGeometry g) {
    final area = g.blockRect(6, 6, 3, 3);
    final c = area.center;
    final tl = area.topLeft, tr = area.topRight;
    final bl = area.bottomLeft, br = area.bottomRight;
    // Each triangle points from its colour's lane into the middle:
    // red ← left, green ↑ top, yellow → right, blue ↓ bottom.
    final tris = [
      [bl, tl],
      [tl, tr],
      [tr, br],
      [br, bl],
    ];
    for (var p = 0; p < 4; p++) {
      final color = NepaliColors.playerColor(p);
      final a = tris[p][0], b = tris[p][1];
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy)
        ..close();
      final mid = Offset.lerp(a, b, 0.5)!;
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment(
              (mid.dx - c.dx) / (area.width / 2),
              (mid.dy - c.dy) / (area.height / 2),
            ),
            end: Alignment.center,
            colors: [_shade(color, 0.1), _shade(color, -0.2)],
          ).createShader(area),
      );
      // Engraved chevrons pointing inwards.
      final ink = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = g.cell * 0.03
        ..color = Colors.white.withValues(alpha: 0.3);
      for (final t in [0.25, 0.45]) {
        final pa = Offset.lerp(a, c, t)!;
        final pb = Offset.lerp(b, c, t)!;
        final pm = Offset.lerp(mid, c, t + 0.18)!;
        canvas.drawPath(
            Path()
              ..moveTo(pa.dx, pa.dy)
              ..lineTo(pm.dx, pm.dy)
              ..lineTo(pb.dx, pb.dy),
            ink);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = g.cell * 0.05
          ..color = _gold,
      );
    }

    // Golden lotus.
    final r = g.cell * 0.78;
    canvas.drawCircle(
      c + Offset(0, g.cell * 0.1),
      r * 0.9,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, g.cell * 0.15),
    );
    _lotus(canvas, c, r, _gold, _goldLight,
        centre: const Color(0xFFB8860B), outline: _goldDark);
  }

  /// Arrows on the cells where each colour turns into its lane.
  void _drawEntryArrows(Canvas canvas, BoardGeometry g) {
    const arrows = [
      (Point(7, 0), 0.0), // red →
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
      final s = g.cell * 0.3;
      final tri = Path()
        ..moveTo(-s * 0.7, -s * 0.8)
        ..lineTo(s * 0.9, 0)
        ..lineTo(-s * 0.7, s * 0.8)
        ..close();
      canvas.drawPath(tri.shift(Offset(0, g.cell * 0.04)),
          Paint()..color = Colors.black.withValues(alpha: 0.25));
      canvas.drawPath(tri, Paint()..color = NepaliColors.playerColor(p));
      canvas.restore();
    }
  }

  // ─── Ornaments ───────────────────────────────────────────────────────

  /// Eight-petal lotus.
  void _lotus(Canvas canvas, Offset c, double r, Color petal, Color light,
      {required Color centre, Color? outline}) {
    for (var layer = 0; layer < 2; layer++) {
      final rr = layer == 0 ? r : r * 0.66;
      final offset = layer == 0 ? 0.0 : pi / 8;
      for (var i = 0; i < 8; i++) {
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(i * pi / 4 + offset);
        final petalRect = Rect.fromCenter(
            center: Offset(0, -rr * 0.55), width: rr * 0.42, height: rr * 0.95);
        final path = Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(petalRect.left, petalRect.center.dy, 0, -rr)
          ..quadraticBezierTo(petalRect.right, petalRect.center.dy, 0, 0)
          ..close();
        canvas.drawPath(
          path,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: layer == 0 ? [petal, light] : [light, petal],
            ).createShader(petalRect),
        );
        if (outline != null) {
          canvas.drawPath(
              path,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = max(0.6, r * 0.03)
                ..color = outline);
        }
        canvas.restore();
      }
    }
    canvas.drawCircle(c, r * 0.2, Paint()..color = centre);
    canvas.drawCircle(c - Offset(r * 0.06, r * 0.06), r * 0.07,
        Paint()..color = Colors.white.withValues(alpha: 0.6));
  }

  /// Faint engraved mandala on the yard discs.
  void _mandala(Canvas canvas, Offset c, double r, Color ink) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(0.6, r * 0.012)
      ..color = ink.withValues(alpha: 0.7);
    for (final k in [0.35, 0.62, 0.92]) {
      canvas.drawCircle(c, r * k, p);
    }
    for (var i = 0; i < 16; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(i * pi / 8);
      canvas.drawPath(
          Path()
            ..moveTo(0, -r * 0.35)
            ..quadraticBezierTo(r * 0.12, -r * 0.62, 0, -r * 0.9)
            ..quadraticBezierTo(-r * 0.12, -r * 0.62, 0, -r * 0.35),
          p);
      canvas.restore();
    }
  }

  void _star(Canvas canvas, Offset c, double r, Color color,
      {Color? highlight}) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rr = i.isEven ? r : r * 0.42;
      final a = i * pi / 5 - pi / 2;
      final pt = c + Offset(cos(a), sin(a)) * rr;
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
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

  @override
  bool shouldRepaint(BoardPainter oldDelegate) => false;
}
