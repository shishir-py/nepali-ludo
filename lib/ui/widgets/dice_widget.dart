import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/theme/app_theme.dart';

/// A real 3D dice cube, rendered with perspective and lighting.
///
/// While [isRolling] is true it tumbles and bounces; when rolling stops it
/// settles on the face showing [value]. When [canRoll] is true it hovers
/// with a pulsing golden glow to invite a tap.
class DiceWidget extends StatefulWidget {
  final int value;
  final bool isRolling;
  final bool canRoll;
  final VoidCallback? onRoll;
  final double size;

  const DiceWidget({
    super.key,
    required this.value,
    this.isRolling = false,
    this.canRoll = true,
    this.onRoll,
    this.size = 84,
  });

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

/// Rotation (about X then Y) that brings each face to the front.
const Map<int, (double, double)> _faceRotation = {
  1: (0.0, 0.0),
  6: (0.0, math.pi),
  3: (0.0, -math.pi / 2),
  4: (0.0, math.pi / 2),
  2: (-math.pi / 2, 0.0),
  5: (math.pi / 2, 0.0),
};

class _DiceWidgetState extends State<DiceWidget>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double _time = 0;

  // Current orientation.
  double _a = 0, _b = 0;
  // Settle tween.
  double _fromA = 0, _fromB = 0, _toA = 0, _toB = 0;
  double _settleT = 1;
  double _bounce = 0; // px, upwards
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    final r = _faceRotation[widget.value.clamp(1, 6)]!;
    _a = r.$1;
    _b = r.$2;
    _ticker = createTicker(_tick)..start();
  }

  @override
  void didUpdateWidget(DiceWidget old) {
    super.didUpdateWidget(old);
    final landed = old.isRolling && !widget.isRolling;
    final changedWhileIdle =
        !widget.isRolling && old.value != widget.value && !landed;
    if (landed || changedWhileIdle) _startSettle(widget.value);
  }

  void _startSettle(int value) {
    final target = _faceRotation[value.clamp(1, 6)]!;
    _fromA = _a;
    _fromB = _b;
    // Always finish rotating forwards with at least one extra turn.
    double forward(double from, double to) {
      var t = to;
      while (t < from + math.pi) {
        t += math.pi * 2;
      }
      return t;
    }

    _toA = forward(_fromA, target.$1);
    _toB = forward(_fromB, target.$2);
    _settleT = 0;
  }

  void _tick(Duration elapsed) {
    final dt =
        ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05).toDouble();
    _last = elapsed;
    _time += dt;

    if (widget.isRolling) {
      _a += dt * 11;
      _b += dt * 15;
      _bounce = (math.sin(_time * 18)).abs() * widget.size * 0.14;
    } else if (_settleT < 1) {
      _settleT = math.min(1, _settleT + dt / 0.55);
      final e = Curves.easeOutBack.transform(_settleT);
      _a = _fromA + (_toA - _fromA) * e;
      _b = _fromB + (_toB - _fromB) * e;
      _bounce = (1 - _settleT) * (math.sin(_settleT * math.pi * 3)).abs() *
          widget.size * 0.1;
    } else {
      _bounce = widget.canRoll
          ? (math.sin(_time * 3) + 1) * widget.size * 0.03
          : 0;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final glow = widget.canRoll && !widget.isRolling
        ? 0.45 + 0.35 * math.sin(_time * 4)
        : 0.0;
    final wobble = widget.canRoll && !widget.isRolling && _settleT >= 1
        ? math.sin(_time * 2.2) * 0.08
        : 0.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (widget.canRoll && !widget.isRolling) widget.onRoll?.call();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1,
        duration: const Duration(milliseconds: 90),
        child: SizedBox(
          width: s * 1.25,
          height: s * 1.25,
          child: CustomPaint(
            painter: _DicePainter(
              a: _a + wobble,
              b: _b + wobble * 0.7,
              bounce: _bounce,
              glow: glow,
              dimmed: !widget.canRoll && !widget.isRolling,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 3D maths ─────────────────────────────────────────────────────────

class _V3 {
  final double x, y, z;
  const _V3(this.x, this.y, this.z);
  _V3 operator +(_V3 o) => _V3(x + o.x, y + o.y, z + o.z);
  _V3 operator *(double k) => _V3(x * k, y * k, z * k);
  double dot(_V3 o) => x * o.x + y * o.y + z * o.z;

  _V3 rotX(double a) {
    final c = math.cos(a), s = math.sin(a);
    return _V3(x, y * c - z * s, y * s + z * c);
  }

  _V3 rotY(double b) {
    final c = math.cos(b), s = math.sin(b);
    return _V3(x * c + z * s, y, -x * s + z * c);
  }
}

class _Face {
  final int value;
  final _V3 n, u, v;
  const _Face(this.value, this.n, this.u, this.v);
}

// z points towards the viewer; y points down (screen space).
const _faces = [
  _Face(1, _V3(0, 0, 1), _V3(1, 0, 0), _V3(0, 1, 0)),
  _Face(6, _V3(0, 0, -1), _V3(-1, 0, 0), _V3(0, 1, 0)),
  _Face(2, _V3(0, -1, 0), _V3(1, 0, 0), _V3(0, 0, 1)),
  _Face(5, _V3(0, 1, 0), _V3(1, 0, 0), _V3(0, 0, -1)),
  _Face(3, _V3(1, 0, 0), _V3(0, 0, -1), _V3(0, 1, 0)),
  _Face(4, _V3(-1, 0, 0), _V3(0, 0, 1), _V3(0, 1, 0)),
];

const _pipLayout = {
  1: [Offset(0, 0)],
  2: [Offset(-0.5, -0.5), Offset(0.5, 0.5)],
  3: [Offset(-0.5, -0.5), Offset(0, 0), Offset(0.5, 0.5)],
  4: [Offset(-0.5, -0.5), Offset(0.5, -0.5), Offset(-0.5, 0.5), Offset(0.5, 0.5)],
  5: [
    Offset(-0.5, -0.5),
    Offset(0.5, -0.5),
    Offset(0, 0),
    Offset(-0.5, 0.5),
    Offset(0.5, 0.5)
  ],
  6: [
    Offset(-0.5, -0.55),
    Offset(-0.5, 0),
    Offset(-0.5, 0.55),
    Offset(0.5, -0.55),
    Offset(0.5, 0),
    Offset(0.5, 0.55)
  ],
};

class _DicePainter extends CustomPainter {
  final double a, b, bounce, glow;
  final bool dimmed;
  _DicePainter({
    required this.a,
    required this.b,
    required this.bounce,
    required this.glow,
    required this.dimmed,
  });

  // Fixed viewing angle so three faces are visible.
  static const _viewX = -0.42;
  static const _viewY = -0.55;
  static const _light = _V3(-0.45, -0.65, 0.62);

  _V3 _xf(_V3 p) => p.rotY(b).rotX(a).rotY(_viewY).rotX(_viewX);

  @override
  void paint(Canvas canvas, Size size) {
    final half = size.width * 0.28;
    final centre = Offset(size.width / 2, size.height * 0.45 - bounce);
    const dist = 5.0;

    Offset proj(_V3 p) {
      final k = dist / (dist - p.z);
      return centre + Offset(p.x, p.y) * half * k;
    }

    // Ground shadow + glow.
    final ground = Offset(size.width / 2, size.height * 0.45 + half * 1.35);
    final shrink = 1 - (bounce / (size.width * 0.2)).clamp(0.0, 0.6);
    if (glow > 0) {
      canvas.drawOval(
        Rect.fromCenter(
            center: ground, width: half * 3.4, height: half * 1.0),
        Paint()
          ..color = NepaliColors.goldLight.withValues(alpha: glow * 0.6)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, half * 0.35),
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
          center: ground, width: half * 2.4 * shrink, height: half * 0.55 * shrink),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45 * shrink)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, half * 0.18),
    );

    // Visible faces, far to near.
    final visible = <(_Face, _V3, double)>[];
    for (final f in _faces) {
      final n = _xf(f.n);
      if (n.z > 0.01) visible.add((f, n, n.z));
    }
    visible.sort((x, y) => x.$3.compareTo(y.$3));

    const l = _light;
    final ll = math.sqrt(l.dot(l));
    for (final (face, n, _) in visible) {
      final corners = [
        face.n + face.u * -1 + face.v * -1,
        face.n + face.u * 1 + face.v * -1,
        face.n + face.u * 1 + face.v * 1,
        face.n + face.u * -1 + face.v * 1,
      ].map((p) => proj(_xf(p))).toList();

      final diffuse = (n.dot(l) / ll).clamp(0.0, 1.0);
      final shade = 0.58 + 0.42 * diffuse;
      final base = dimmed ? const Color(0xFFE6E0D6) : const Color(0xFFFFFDF6);
      final faceColor = Color.lerp(Colors.black, base, shade)!;

      final path = Path()..addPolygon(corners, true);
      final bounds = path.getBounds();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(faceColor, Colors.white, 0.25)!,
              faceColor,
            ],
          ).createShader(bounds),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = half * 0.07
          ..color = const Color(0xFFBFB6A6),
      );

      // Pips.
      final pips = _pipLayout[face.value]!;
      final pipR = face.value == 1 ? 0.3 : 0.19;
      final pipColor =
          face.value == 1 ? NepaliColors.primary : const Color(0xFF3A0D12);
      for (final p in pips) {
        final centre3 = face.n * 1.001 + face.u * p.dx + face.v * p.dy;
        final pts = <Offset>[];
        for (var i = 0; i < 14; i++) {
          final ang = i / 14 * math.pi * 2;
          final q = centre3 +
              face.u * (math.cos(ang) * pipR) +
              face.v * (math.sin(ang) * pipR);
          pts.add(proj(_xf(q)));
        }
        final pipPath = Path()..addPolygon(pts, true);
        canvas.drawPath(
            pipPath,
            Paint()
              ..color = Color.lerp(Colors.black, pipColor, 0.6 + 0.4 * shade)!);
      }
    }

    // Specular sheen across the whole cube.
    final top = proj(_xf(const _V3(-0.5, -1, -0.5)));
    canvas.drawCircle(
      top,
      half * 0.35,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, half * 0.25),
    );
  }

  @override
  bool shouldRepaint(_DicePainter old) => true;
}
