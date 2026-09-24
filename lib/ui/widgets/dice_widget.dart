import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/theme/app_theme.dart';

/// A realistic dice: an ivory cube with rounded edges and sunken pips.
///
/// While [isRolling] it tumbles in 3D. When the roll lands it turns so the
/// rolled face looks straight at the player, perfectly square and upright,
/// and stays that way until the next roll.
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

/// Rotation (about X, then Y) that turns each face towards the viewer.
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
  final math.Random _rng = math.Random();

  // Orientation as a unit quaternion, plus a world-space spin.
  _Quat _q = _Quat.identity;
  _V3 _omega = const _V3(0, 0, 0);

  // Vertical bounce (px above the table) and its velocity.
  double _h = 0, _vh = 0;

  // Landing: slerp from the tumbling orientation to the rolled face.
  _Quat _from = _Quat.identity, _to = _Quat.identity;
  double _settleT = 1;
  double _hFrom = 0;
  double _viewFrom = 0;

  double _view = 0; // 1 = angled 3D view while tumbling, 0 = face-on
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _q = _faceQuat(widget.value, 0);
    _ticker = createTicker(_tick)..start();
  }

  @override
  void didUpdateWidget(DiceWidget old) {
    super.didUpdateWidget(old);
    if (!old.isRolling && widget.isRolling) {
      _throw();
    } else if (old.isRolling && !widget.isRolling) {
      _land(widget.value);
    } else if (!widget.isRolling && old.value != widget.value) {
      _land(widget.value);
    }
  }

  /// Toss the dice: a quick upward hop and a strong spin about a mostly
  /// horizontal axis, like a dice flicked out of the hand.
  void _throw() {
    final axis = _V3(
      (_rng.nextBool() ? 1 : -1) * (0.8 + _rng.nextDouble() * 0.4),
      (_rng.nextDouble() - 0.5) * 1.2,
      (_rng.nextDouble() - 0.5) * 0.6,
    ).normalized();
    _omega = axis * (17 + _rng.nextDouble() * 6);
    _vh = widget.size * 6.2;
    _settleT = 1;
  }

  /// Turn smoothly onto [value], choosing whichever of the four upright
  /// orientations of that face is closest so it tips over naturally.
  void _land(int value) {
    var best = _faceQuat(value, 0);
    var bestDot = -1.0;
    for (var k = 0; k < 4; k++) {
      final t = _faceQuat(value, k);
      final d = _q.dot(t).abs();
      if (d > bestDot) {
        bestDot = d;
        best = t;
      }
    }
    _from = _q;
    _to = _q.dot(best) < 0 ? best.negated() : best;
    _hFrom = _h;
    _viewFrom = _view;
    _settleT = 0;
    _omega = const _V3(0, 0, 0);
  }

  void _tick(Duration elapsed) {
    final dt =
        ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.034).toDouble();
    _last = elapsed;
    _time += dt;
    final s = widget.size;

    if (widget.isRolling) {
      // Spin, slowed a little by air/table friction.
      final speed = _omega.length;
      if (speed > 0) {
        _q = (_Quat.axisAngle(_omega * (1 / speed), speed * dt) * _q)
            .normalized();
      }
      _omega = _omega * math.exp(-1.6 * dt);
      // Gravity and bounces.
      _vh -= s * 60 * dt;
      _h += _vh * dt;
      if (_h < 0) {
        _h = 0;
        _vh = -_vh * 0.45;
        // Each impact knocks the spin a little.
        _omega = (_omega +
                _V3(_rng.nextDouble() - 0.5, _rng.nextDouble() - 0.5,
                        _rng.nextDouble() - 0.5) *
                    6) *
            0.85;
      }
      _view = math.min(1, _view + dt * 8);
    } else if (_settleT < 1) {
      _settleT = math.min(1, _settleT + dt / 0.24);
      final e = Curves.easeOutCubic.transform(_settleT);
      _q = _Quat.slerp(_from, _to, e);
      _h = _hFrom * (1 - e);
      _view = _viewFrom * (1 - Curves.easeInOut.transform(_settleT));
      if (_settleT >= 1) {
        _q = _to;
        _h = 0;
        _view = 0;
      }
    } else {
      _h = widget.canRoll ? (math.sin(_time * 3) + 1) * s * 0.025 : 0;
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
        ? 0.5 + 0.35 * math.sin(_time * 4)
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
          width: s * 1.3,
          height: s * 1.3,
          child: CustomPaint(
            painter: _DicePainter(
              rotation: _q.toMatrix(),
              view: _view,
              bounce: _h,
              glow: glow,
              dimmed: !widget.canRoll && !widget.isRolling,
            ),
          ),
        ),
      ),
    );
  }
}

/// Orientation that shows [value] to the viewer, turned [k] quarter-turns
/// in the picture plane (all four look upright and square).
_Quat _faceQuat(int value, int k) {
  final r = _faceRotation[value.clamp(1, 6)]!;
  final face = _Quat.axisAngle(const _V3(1, 0, 0), r.$1) *
      _Quat.axisAngle(const _V3(0, 1, 0), r.$2);
  return _Quat.axisAngle(const _V3(0, 0, 1), k * math.pi / 2) * face;
}

/// Minimal unit-quaternion helper for smooth 3D rotation.
class _Quat {
  final double w, x, y, z;
  const _Quat(this.w, this.x, this.y, this.z);
  static const identity = _Quat(1, 0, 0, 0);

  factory _Quat.axisAngle(_V3 axis, double angle) {
    final h = angle / 2, s = math.sin(h);
    return _Quat(math.cos(h), axis.x * s, axis.y * s, axis.z * s);
  }

  _Quat operator *(_Quat o) => _Quat(
        w * o.w - x * o.x - y * o.y - z * o.z,
        w * o.x + x * o.w + y * o.z - z * o.y,
        w * o.y - x * o.z + y * o.w + z * o.x,
        w * o.z + x * o.y - y * o.x + z * o.w,
      );

  double dot(_Quat o) => w * o.w + x * o.x + y * o.y + z * o.z;
  _Quat negated() => _Quat(-w, -x, -y, -z);

  _Quat normalized() {
    final l = math.sqrt(dot(this));
    return _Quat(w / l, x / l, y / l, z / l);
  }

  static _Quat slerp(_Quat a, _Quat b, double t) {
    var d = a.dot(b);
    var bb = b;
    if (d < 0) {
      d = -d;
      bb = b.negated();
    }
    if (d > 0.9995) {
      return _Quat(
        a.w + (bb.w - a.w) * t,
        a.x + (bb.x - a.x) * t,
        a.y + (bb.y - a.y) * t,
        a.z + (bb.z - a.z) * t,
      ).normalized();
    }
    final th = math.acos(d);
    final sa = math.sin((1 - t) * th) / math.sin(th);
    final sb = math.sin(t * th) / math.sin(th);
    return _Quat(a.w * sa + bb.w * sb, a.x * sa + bb.x * sb,
        a.y * sa + bb.y * sb, a.z * sa + bb.z * sb);
  }

  /// Row-major 3×3 rotation matrix.
  List<double> toMatrix() {
    return [
      1 - 2 * (y * y + z * z), 2 * (x * y - w * z), 2 * (x * z + w * y),
      2 * (x * y + w * z), 1 - 2 * (x * x + z * z), 2 * (y * z - w * x),
      2 * (x * z - w * y), 2 * (y * z + w * x), 1 - 2 * (x * x + y * y),
    ];
  }
}

// ─── 3D maths ─────────────────────────────────────────────────────────

class _V3 {
  final double x, y, z;
  const _V3(this.x, this.y, this.z);
  _V3 operator +(_V3 o) => _V3(x + o.x, y + o.y, z + o.z);
  _V3 operator *(double k) => _V3(x * k, y * k, z * k);
  double dot(_V3 o) => x * o.x + y * o.y + z * o.z;
  double get length => math.sqrt(dot(this));
  _V3 normalized() => this * (1 / length);
  _V3 mat(List<double> m) => _V3(
        m[0] * x + m[1] * y + m[2] * z,
        m[3] * x + m[4] * y + m[5] * z,
        m[6] * x + m[7] * y + m[8] * z,
      );

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

// z points at the viewer; y points down the screen.
const _faces = [
  _Face(1, _V3(0, 0, 1), _V3(1, 0, 0), _V3(0, 1, 0)),
  _Face(6, _V3(0, 0, -1), _V3(-1, 0, 0), _V3(0, 1, 0)),
  _Face(2, _V3(0, -1, 0), _V3(1, 0, 0), _V3(0, 0, 1)),
  _Face(5, _V3(0, 1, 0), _V3(1, 0, 0), _V3(0, 0, -1)),
  _Face(3, _V3(1, 0, 0), _V3(0, 0, -1), _V3(0, 1, 0)),
  _Face(4, _V3(-1, 0, 0), _V3(0, 0, 1), _V3(0, 1, 0)),
];

// Pip centres in face coordinates (-1..1), classic layouts.
const _d = 0.5;
const _pips = {
  1: [Offset(0, 0)],
  2: [Offset(-_d, -_d), Offset(_d, _d)],
  3: [Offset(-_d, -_d), Offset(0, 0), Offset(_d, _d)],
  4: [Offset(-_d, -_d), Offset(_d, -_d), Offset(-_d, _d), Offset(_d, _d)],
  5: [
    Offset(-_d, -_d),
    Offset(_d, -_d),
    Offset(0, 0),
    Offset(-_d, _d),
    Offset(_d, _d),
  ],
  6: [
    Offset(-_d, -_d),
    Offset(-_d, 0),
    Offset(-_d, _d),
    Offset(_d, -_d),
    Offset(_d, 0),
    Offset(_d, _d),
  ],
};

class _DicePainter extends CustomPainter {
  final List<double> rotation;
  final double view, bounce, glow;
  final bool dimmed;

  _DicePainter({
    required this.rotation,
    required this.view,
    required this.bounce,
    required this.glow,
    required this.dimmed,
  });

  static const _viewX = -0.45;
  static const _viewY = -0.55;
  static const _light = _V3(-0.45, -0.6, 0.66);

  static const _ivory = Color(0xFFFBF8F1);
  static const _edge = Color(0xFFD9D1C2);
  static const _pip = Color(0xFF1B1B1F);
  static const _pipRed = Color(0xFFC8102E);

  _V3 _xf(_V3 p) =>
      p.mat(rotation).rotY(_viewY * view).rotX(_viewX * view);

  @override
  void paint(Canvas canvas, Size size) {
    final half = size.width * 0.3;
    final centre = Offset(size.width / 2, size.height * 0.46 - bounce);
    const dist = 6.0;

    Offset proj(_V3 p) {
      final k = dist / (dist - p.z);
      return centre + Offset(p.x, p.y) * half * k;
    }

    // Glow + contact shadow on the "table".
    final ground = Offset(size.width / 2, size.height * 0.46 + half * 1.2);
    final lift = (bounce / (size.width * 0.2)).clamp(0.0, 0.6);
    if (glow > 0) {
      canvas.drawOval(
        Rect.fromCenter(center: ground, width: half * 3.2, height: half * 0.9),
        Paint()
          ..color = NepaliColors.goldLight.withValues(alpha: glow * 0.55)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, half * 0.35),
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
          center: ground,
          width: half * 2.3 * (1 - lift),
          height: half * 0.5 * (1 - lift)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5 * (1 - lift))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, half * 0.16),
    );

    // Body silhouette: rounded hull of every projected corner. The gaps
    // between the rounded faces show this darker ivory as rounded edges.
    final corners = <Offset>[
      for (final x in [-1.0, 1.0])
        for (final y in [-1.0, 1.0])
          for (final z in [-1.0, 1.0]) proj(_xf(_V3(x, y, z))),
    ];
    final hull = _roundedPolygon(_convexHull(corners), 0.22);
    final hullBounds = hull.getBounds();
    canvas.drawPath(
      hull,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dimmed
              ? const [Color(0xFFE2DCD0), Color(0xFFB9B1A3)]
              : const [Color(0xFFF1EBDF), _edge, Color(0xFFB8AE9C)],
        ).createShader(hullBounds),
    );

    // Visible faces, far to near.
    final visible = <(_Face, _V3)>[];
    for (final f in _faces) {
      final n = _xf(f.n);
      if (n.z > 0.02) visible.add((f, n));
    }
    visible.sort((x, y) => x.$2.z.compareTo(y.$2.z));

    final ll = math.sqrt(_light.dot(_light));
    for (final (face, n) in visible) {
      final diffuse = (n.dot(_light) / ll).clamp(0.0, 1.0);
      final shade = 0.62 + 0.38 * diffuse;
      // Faces seen edge-on fade into the bevel instead of popping.
      final facing = ((n.z - 0.02) / 0.25).clamp(0.0, 1.0);

      // Face = square inset a little so the rounded edge shows around it.
      const inset = 0.86;
      final quad = [
        face.n + face.u * -inset + face.v * -inset,
        face.n + face.u * inset + face.v * -inset,
        face.n + face.u * inset + face.v * inset,
        face.n + face.u * -inset + face.v * inset,
      ].map((p) => proj(_xf(p))).toList();
      final path = _roundedPolygon(quad, 0.2);
      final bounds = path.getBounds();
      final base = dimmed ? const Color(0xFFEAE4D8) : _ivory;
      final lit = Color.lerp(Colors.black, base, shade)!;
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(lit, Colors.white, 0.35)!.withValues(alpha: facing),
              lit.withValues(alpha: facing),
            ],
          ).createShader(bounds),
      );

      // Sunken pips.
      final isOne = face.value == 1;
      final r = isOne ? 0.3 : 0.19;
      final colour = isOne ? _pipRed : _pip;
      for (final p in _pips[face.value]!) {
        final c3 = face.n * 1.001 + face.u * p.dx + face.v * p.dy;
        final ring = <Offset>[];
        for (var i = 0; i < 18; i++) {
          final t = i / 18 * math.pi * 2;
          ring.add(proj(_xf(c3 +
              face.u * (math.cos(t) * r) +
              face.v * (math.sin(t) * r))));
        }
        final pipPath = Path()..addPolygon(ring, true);
        final pb = pipPath.getBounds();
        canvas.drawPath(
          pipPath,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.35, -0.4),
              radius: 0.9,
              colors: [
                Color.lerp(colour, Colors.black, 0.45)!,
                colour,
                Color.lerp(colour, Colors.white, 0.18)!,
              ],
              stops: const [0.0, 0.7, 1.0],
            ).createShader(pb)
            ..color = colour.withValues(alpha: facing),
        );
        // Light catching the lower rim of the dimple.
        canvas.drawArc(
          pb.deflate(pb.width * 0.08),
          math.pi * 0.1,
          math.pi * 0.8,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(0.8, pb.width * 0.08)
            ..color = Colors.white.withValues(alpha: 0.45 * facing),
        );
      }
    }

    // Soft specular sheen on the upper-left of the body.
    canvas.drawCircle(
      hullBounds.topLeft + Offset(hullBounds.width * 0.3, hullBounds.height * 0.25),
      half * 0.45,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, half * 0.3),
    );
  }

  /// Andrew's monotone chain convex hull.
  static List<Offset> _convexHull(List<Offset> pts) {
    final p = [...pts]..sort((a, b) =>
        a.dx != b.dx ? a.dx.compareTo(b.dx) : a.dy.compareTo(b.dy));
    double cross(Offset o, Offset a, Offset b) =>
        (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);
    final lower = <Offset>[];
    for (final q in p) {
      while (lower.length >= 2 &&
          cross(lower[lower.length - 2], lower.last, q) <= 0) {
        lower.removeLast();
      }
      lower.add(q);
    }
    final upper = <Offset>[];
    for (final q in p.reversed) {
      while (upper.length >= 2 &&
          cross(upper[upper.length - 2], upper.last, q) <= 0) {
        upper.removeLast();
      }
      upper.add(q);
    }
    lower.removeLast();
    upper.removeLast();
    return [...lower, ...upper];
  }

  /// Polygon with each corner rounded off by [fraction] of its edges.
  static Path _roundedPolygon(List<Offset> pts, double fraction) {
    final n = pts.length;
    final path = Path();
    if (n < 3) return path;
    for (var i = 0; i < n; i++) {
      final prev = pts[(i - 1 + n) % n];
      final cur = pts[i];
      final next = pts[(i + 1) % n];
      final a = Offset.lerp(cur, prev, fraction)!;
      final b = Offset.lerp(cur, next, fraction)!;
      if (i == 0) {
        path.moveTo(a.dx, a.dy);
      } else {
        path.lineTo(a.dx, a.dy);
      }
      path.quadraticBezierTo(cur.dx, cur.dy, b.dx, b.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_DicePainter old) => true;
}
