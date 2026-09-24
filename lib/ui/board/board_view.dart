import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/theme/app_theme.dart';
import '../../game/engine/board_config.dart';
import '../../game/engine/player.dart';
import '../../game/engine/token.dart';
import '../painters/board_painter.dart';
import 'board_geometry.dart';

/// Tilt used for the 3D view, in radians.
const double kBoardTilt3D = 0.62;

/// The playable board: a perspective-tilted 3D board with upright,
/// shaded pawns that hop cell-by-cell, bob when they can be moved, and
/// can be tapped directly.
class BoardView extends StatefulWidget {
  final List<Player> players;
  final int currentPlayerIndex;

  /// Token ids of the current player that can legally move right now.
  final Set<int> movableTokenIds;

  /// Positions to show instead of the engine's value while a move is being
  /// animated, keyed by `'$playerIndex:$tokenId'`.
  final Map<String, int> positionOverrides;

  /// Called when the player taps one of the [movableTokenIds].
  final ValueChanged<Token>? onTokenTap;

  /// true = tilted 3D view, false = flat top-down view.
  final bool tilted;

  const BoardView({
    super.key,
    required this.players,
    required this.currentPlayerIndex,
    this.movableTokenIds = const {},
    this.positionOverrides = const {},
    this.onTokenTap,
    this.tilted = true,
  });

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _PawnAnim {
  Offset from; // cell units (u = col, v = row)
  Offset to;
  double t = 1; // 0..1 progress of current hop
  double duration = 0.18;
  double lift = 0.45; // arc height in cells
  double scale; // shrink when sharing a cell
  _PawnAnim(Offset p, this.scale)
      : from = p,
        to = p;

  Offset get pos {
    final e = Curves.easeInOut.transform(t);
    return Offset.lerp(from, to, e)!;
  }

  double get height => math.sin(math.pi * t) * lift;
}

class _BoardViewState extends State<BoardView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<int> _frame = ValueNotifier(0);
  Duration _last = Duration.zero;
  double _time = 0;

  final Map<String, _PawnAnim> _anims = {};
  BoardCamera? _camera;

  @override
  void initState() {
    super.initState();
    _syncTargets(initial: true);
    _ticker = createTicker(_tick)..start();
  }

  @override
  void didUpdateWidget(BoardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTargets();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final dt =
        ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05).toDouble();
    _last = elapsed;
    _time += dt;
    for (final a in _anims.values) {
      if (a.t < 1) a.t = math.min(1, a.t + dt / a.duration);
    }
    _frame.value++;
  }

  // ─── Targets ─────────────────────────────────────────────────────────

  static String keyOf(int p, int t) => '$p:$t';

  int _positionOf(int p, Token t) =>
      widget.positionOverrides[keyOf(p, t.id)] ?? t.position;

  /// Where a finished pawn stands: inside its colour's centre triangle.
  static const _finishDir = [
    Offset(-1, 0), // red – left
    Offset(0, -1), // green – top
    Offset(1, 0), // yellow – right
    Offset(0, 1), // blue – bottom
  ];

  void _syncTargets({bool initial = false}) {
    // Group by cell to cluster pawns sharing a square.
    final byCell = <String, List<(int, Token)>>{};
    for (var p = 0; p < widget.players.length; p++) {
      final player = widget.players[p];
      for (var i = 0; i < player.tokens.length; i++) {
        final tok = player.tokens[i];
        final pos = _positionOf(player.index, tok);
        final String key;
        if (pos >= 57) {
          key = 'fin:${player.index}';
        } else {
          final cell = BoardConfig.boardCell(player.index, pos, i)!;
          key = '${cell.x},${cell.y}';
        }
        byCell.putIfAbsent(key, () => []).add((i, tok));
      }
    }

    final seen = <String>{};
    for (var p = 0; p < widget.players.length; p++) {
      final player = widget.players[p];
      for (var i = 0; i < player.tokens.length; i++) {
        final tok = player.tokens[i];
        final pos = _positionOf(player.index, tok);
        Offset target;
        double scale = 1;
        if (pos >= 57) {
          final d = _finishDir[player.index];
          final perp = Offset(-d.dy, d.dx);
          target = const Offset(7.5, 7.5) + d * 0.95 + perp * ((tok.id - 1.5) * 0.3);
          scale = 0.6;
        } else {
          final cell = BoardConfig.boardCell(player.index, pos, i)!;
          target = Offset(cell.y + 0.5, cell.x + 0.5);
          final group = byCell['${cell.x},${cell.y}']!;
          if (group.length > 1 && pos >= 0) {
            final idx = group.indexWhere((e) => identical(e.$2, tok));
            final a = idx / group.length * math.pi * 2 - math.pi / 4;
            target += Offset(math.cos(a), math.sin(a)) * 0.2;
            scale = 0.78;
          }
        }

        final k = keyOf(player.index, tok.id);
        seen.add(k);
        final anim = _anims[k];
        if (anim == null || initial) {
          _anims[k] = _PawnAnim(target, scale);
          continue;
        }
        anim.scale = scale;
        if ((anim.to - target).distance > 0.001) {
          anim.from = anim.pos;
          anim.to = target;
          anim.t = 0;
          final dist = (anim.to - anim.from).distance;
          if (dist <= 1.6) {
            anim.duration = 0.17;
            anim.lift = 0.45;
          } else {
            // Long flights: captured pawn flying home, or leaving the yard.
            anim.duration = (0.3 + dist * 0.035).clamp(0.3, 0.75);
            anim.lift = (0.8 + dist * 0.08).clamp(0.8, 2.2);
          }
        }
      }
    }
    _anims.removeWhere((k, _) => !seen.contains(k));
  }

  // ─── Tap handling ────────────────────────────────────────────────────

  void _handleTap(Offset local) {
    final cam = _camera;
    if (cam == null || widget.onTokenTap == null) return;
    final player = widget.players.firstWhere(
      (p) => p.index == widget.currentPlayerIndex,
      orElse: () => widget.players.first,
    );
    Token? best;
    var bestDist = double.infinity;
    for (final tok in player.tokens) {
      if (!widget.movableTokenIds.contains(tok.id)) continue;
      final a = _anims[keyOf(player.index, tok.id)];
      if (a == null) continue;
      final base = cam.geometry.at(a.pos.dx, a.pos.dy);
      final screen = cam.project(base);
      final unit = cam.geometry.cell * cam.scaleAt(base);
      // Pawn body spans from its base up to ~1 cell above it.
      final bodyCentre = screen - Offset(0, unit * 0.45);
      final d = (local - bodyCentre).distance;
      final reach = unit * 0.8 + 10;
      if (d < reach && d < bestDist) {
        best = tok;
        bestDist = d;
      }
    }
    if (best != null) widget.onTokenTap!(best);
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final viewport = constraints.biggest;
      final boardSize = math.min(viewport.width, viewport.height);
      return TweenAnimationBuilder<double>(
        tween: Tween(end: widget.tilted ? kBoardTilt3D : 0.0),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
        builder: (context, tilt, _) {
          final cam = BoardCamera.fit(
              boardSize: boardSize, viewport: viewport, tilt: tilt);
          _camera = cam;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _handleTap(d.localPosition),
            child: SizedBox(
              width: viewport.width,
              height: viewport.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _SlabPainter(cam)),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Transform(
                      transform: cam.matrix,
                      child: SizedBox(
                        width: boardSize,
                        height: boardSize,
                        child: const RepaintBoundary(
                          child: CustomPaint(painter: BoardPainter()),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PawnPainter(
                        camera: cam,
                        players: widget.players,
                        anims: _anims,
                        movable: widget.movableTokenIds,
                        currentPlayer: widget.currentPlayerIndex,
                        clock: () => _time,
                        repaint: _frame,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}

// ─── Slab + shadow under the board ────────────────────────────────────

class _SlabPainter extends CustomPainter {
  final BoardCamera cam;
  _SlabPainter(this.cam);

  @override
  void paint(Canvas canvas, Size size) {
    final s = cam.geometry.size;
    final t = BoardCamera.slabThickness(s);

    Path quad(List<Offset> pts) => Path()..addPolygon(pts, true);

    // Soft drop shadow.
    final shadow = quad([
      cam.project(const Offset(0, 0), t * 2),
      cam.project(Offset(s, 0), t * 2),
      cam.project(Offset(s, s), t * 2),
      cam.project(Offset(0, s), t * 2),
    ]).shift(Offset(0, s * cam.fitScale * 0.03));
    canvas.drawPath(
      shadow,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, s * cam.fitScale * 0.035),
    );

    // Front edge of the wooden slab.
    final a = cam.project(Offset(0, s));
    final b = cam.project(Offset(s, s));
    final c = cam.project(Offset(s, s), t);
    final d = cam.project(Offset(0, s), t);
    if ((d.dy - a.dy) > 0.5) {
      final r = Rect.fromPoints(a, c);
      canvas.drawPath(
        quad([a, b, c, d]),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6B3515), Color(0xFF3A1A08)],
          ).createShader(r),
      );
      canvas.drawLine(
          a,
          b,
          Paint()
            ..color = const Color(0xFFFFD35C).withValues(alpha: 0.7)
            ..strokeWidth = 1.2);
    }
  }

  @override
  bool shouldRepaint(_SlabPainter old) => old.cam.tilt != cam.tilt ||
      old.cam.fitScale != cam.fitScale;
}

// ─── Pawns ────────────────────────────────────────────────────────────

class _PawnPainter extends CustomPainter {
  final BoardCamera camera;
  final List<Player> players;
  final Map<String, _PawnAnim> anims;
  final Set<int> movable;
  final int currentPlayer;
  final double Function() clock;

  _PawnPainter({
    required this.camera,
    required this.players,
    required this.anims,
    required this.movable,
    required this.currentPlayer,
    required this.clock,
    required Listenable repaint,
  }) : super(repaint: repaint);

  static Color _shade(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final g = camera.geometry;
    final time = clock();
    final pulse = (math.sin(time * math.pi * 2 * 1.2) + 1) / 2; // 0..1

    final items = <_PawnDraw>[];
    for (final player in players) {
      for (final tok in player.tokens) {
        final a = anims['${player.index}:${tok.id}'];
        if (a == null) continue;
        final isMovable =
            player.index == currentPlayer && movable.contains(tok.id);
        final flat = g.at(a.pos.dx, a.pos.dy);
        final base = camera.project(flat);
        final unit = g.cell * camera.scaleAt(flat) * a.scale;
        var lift = a.height * unit;
        if (isMovable && a.t >= 1) {
          lift += unit * 0.12 * math.sin(time * math.pi * 2 * 1.4).abs();
        }
        items.add(_PawnDraw(
          player: player.index,
          flat: flat,
          base: base,
          unit: unit,
          lift: lift,
          movable: isMovable,
          scale: a.scale,
        ));
      }
    }
    items.sort((x, y) => x.base.dy.compareTo(y.base.dy));

    // 1. Ground shadows + glow rings (all under every pawn).
    for (final it in items) {
      final r = g.cell * 0.34 * it.scale;
      final fade = (1 - it.lift / (it.unit * 2.5)).clamp(0.25, 1.0);
      canvas.drawPath(
        camera.groundCircle(it.flat + Offset(r * 0.25, r * 0.3), r * fade),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.38 * fade)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, it.unit * 0.08),
      );
      if (it.movable) {
        final ringR = g.cell * (0.46 + 0.06 * pulse) * it.scale;
        canvas.drawPath(
          camera.groundCircle(it.flat, ringR),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = it.unit * 0.09
            ..color = NepaliColors.goldLight.withValues(alpha: 0.5 + 0.5 * pulse)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, it.unit * 0.03),
        );
      }
    }

    // 2. Pawns, far to near.
    for (final it in items) {
      _drawPawn(canvas, it);
    }
  }

  void _drawPawn(Canvas canvas, _PawnDraw it) {
    final color = NepaliColors.playerColor(it.player);
    final dark = _shade(color, -0.25);
    final light = _shade(color, 0.22);
    final u = it.unit;
    final x = it.base.dx;
    final y = it.base.dy - it.lift;

    final baseR = u * 0.34;
    final baseH = u * 0.13;
    final neckR = u * 0.11;
    final height = u * 0.92;
    final headR = u * 0.2;
    final headY = y - height * 0.8;
    const squash = 0.42;

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, u * 0.025)
      ..color = _shade(color, -0.4).withValues(alpha: 0.8);

    // Base: a short cylinder.
    final baseRect = Rect.fromCenter(
        center: Offset(x, y), width: baseR * 2, height: baseR * 2 * squash);
    final baseTop = baseRect.shift(Offset(0, -baseH));
    final baseSide = Path()
      ..moveTo(baseRect.left, baseRect.center.dy)
      ..arcTo(baseRect, math.pi, -math.pi, false)
      ..lineTo(baseTop.right, baseTop.center.dy)
      ..arcTo(baseTop, 0, math.pi, false)
      ..close();
    final sideShader = LinearGradient(
      colors: [dark, color, light, color, dark],
      stops: const [0.0, 0.3, 0.45, 0.7, 1.0],
    ).createShader(baseRect);
    canvas.drawPath(baseSide, Paint()..shader = sideShader);
    canvas.drawPath(baseSide, outline);
    canvas.drawOval(baseTop, Paint()..color = light);

    // Body: a bell curve rising from the base to the neck.
    final bodyBottom = baseTop.center.dy;
    final neckY = y - height * 0.6;
    final bw = baseR * 0.82;
    final body = Path()
      ..moveTo(x - bw, bodyBottom)
      ..cubicTo(x - bw, bodyBottom - (bodyBottom - neckY) * 0.45, x - neckR,
          neckY + (bodyBottom - neckY) * 0.35, x - neckR, neckY)
      ..lineTo(x + neckR, neckY)
      ..cubicTo(x + neckR, neckY + (bodyBottom - neckY) * 0.35, x + bw,
          bodyBottom - (bodyBottom - neckY) * 0.45, x + bw, bodyBottom)
      ..arcTo(
          Rect.fromCenter(
              center: Offset(x, bodyBottom),
              width: bw * 2,
              height: bw * 2 * squash),
          0,
          math.pi,
          false)
      ..close();
    final bodyRect = Rect.fromLTRB(x - bw, neckY, x + bw, bodyBottom);
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          colors: [dark, color, light, color, dark],
          stops: const [0.0, 0.28, 0.42, 0.72, 1.0],
        ).createShader(bodyRect),
    );
    canvas.drawPath(body, outline);

    // Collar ring.
    final collar = Rect.fromCenter(
        center: Offset(x, neckY),
        width: neckR * 3.2,
        height: neckR * 3.2 * squash);
    canvas.drawOval(collar, Paint()..color = NepaliColors.goldLight);
    canvas.drawOval(
        collar,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.6, u * 0.02)
          ..color = const Color(0xFF8B6914));

    // Head: glossy sphere.
    final head = Offset(x, headY);
    canvas.drawCircle(
      head,
      headR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.95,
          colors: [Colors.white, light, color, dark],
          stops: const [0.0, 0.25, 0.65, 1.0],
        ).createShader(Rect.fromCircle(center: head, radius: headR)),
    );
    canvas.drawCircle(head, headR, outline);
    // Specular highlight on the body.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(x - bw * 0.35, bodyBottom - (bodyBottom - neckY) * 0.5),
          width: bw * 0.22,
          height: (bodyBottom - neckY) * 0.5),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(_PawnPainter old) => true;
}

class _PawnDraw {
  final int player;
  final Offset flat;
  final Offset base;
  final double unit;
  final double lift;
  final bool movable;
  final double scale;
  _PawnDraw({
    required this.player,
    required this.flat,
    required this.base,
    required this.unit,
    required this.lift,
    required this.movable,
    required this.scale,
  });
}
