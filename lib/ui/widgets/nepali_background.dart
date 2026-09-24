import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../audio/audio_manager.dart';
import '../../core/theme/app_theme.dart';

/// Deep crimson evening sky over the Himalaya, with a string of prayer
/// flags and a faint Dhaka weave. Used behind the home and game screens.
class NepaliBackground extends StatelessWidget {
  final Widget child;
  final bool showFlags;

  const NepaliBackground({super.key, required this.child, this.showFlags = true});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: _BackgroundPainter(showFlags)),
          ),
        ),
        child,
      ],
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final bool showFlags;
  _BackgroundPainter(this.showFlags);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Sky.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5A0F1E), Color(0xFF2E0710), Color(0xFF14040A)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(rect),
    );
    // Warm glow behind the peaks.
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.72),
      size.width * 0.7,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFF8A3D).withValues(alpha: 0.22),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(
            center: Offset(size.width * 0.7, size.height * 0.72),
            radius: size.width * 0.7)),
    );

    // Stars.
    final rnd = math.Random(42);
    final star = Paint();
    for (var i = 0; i < 60; i++) {
      final p = Offset(rnd.nextDouble() * size.width,
          rnd.nextDouble() * size.height * 0.55);
      star.color = Colors.white.withValues(alpha: 0.15 + rnd.nextDouble() * 0.45);
      canvas.drawCircle(p, 0.6 + rnd.nextDouble() * 1.1, star);
    }

    // Dhaka weave (very faint diamonds).
    final weave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = NepaliColors.gold.withValues(alpha: 0.05);
    const s = 26.0;
    for (var y = 0.0; y < size.height; y += s) {
      for (var x = (y / s).floor().isEven ? 0.0 : s / 2; x < size.width; x += s) {
        canvas.drawPath(
            Path()
              ..moveTo(x, y - s * 0.3)
              ..lineTo(x + s * 0.3, y)
              ..lineTo(x, y + s * 0.3)
              ..lineTo(x - s * 0.3, y)
              ..close(),
            weave);
      }
    }

    _mountains(canvas, size, 0.70, 0.20, const Color(0xFF4A1426), 7, 3,
        snow: true);
    _mountains(canvas, size, 0.80, 0.16, const Color(0xFF2A0A15), 11, 9,
        snow: true);
    _mountains(canvas, size, 0.90, 0.10, const Color(0xFF16050B), 17, 21);

    if (showFlags) _prayerFlags(canvas, size);
  }

  void _mountains(Canvas canvas, Size size, double baseY, double amp,
      Color color, int peaks, int seed,
      {bool snow = false}) {
    final rnd = math.Random(seed);
    final pts = <Offset>[Offset(0, size.height)];
    final step = size.width / peaks;
    final tops = <Offset>[];
    for (var i = 0; i <= peaks; i++) {
      final x = i * step;
      final valley = size.height * (baseY - amp * (0.2 + rnd.nextDouble() * 0.3));
      final peak = size.height * (baseY - amp * (0.6 + rnd.nextDouble() * 0.4));
      pts.add(Offset(x, valley));
      if (i < peaks) {
        final top = Offset(x + step * (0.35 + rnd.nextDouble() * 0.3), peak);
        pts.add(top);
        tops.add(top);
      }
    }
    pts.add(Offset(size.width, size.height));
    canvas.drawPath(Path()..addPolygon(pts, true), Paint()..color = color);

    if (!snow) return;
    final snowPaint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    for (final t in tops) {
      final w = step * 0.18;
      final h = size.height * amp * 0.18;
      canvas.drawPath(
        Path()
          ..moveTo(t.dx, t.dy)
          ..lineTo(t.dx + w, t.dy + h)
          ..lineTo(t.dx + w * 0.3, t.dy + h * 0.75)
          ..lineTo(t.dx - w * 0.2, t.dy + h * 1.05)
          ..lineTo(t.dx - w * 0.8, t.dy + h * 0.9)
          ..close(),
        snowPaint,
      );
    }
  }

  /// Lungta: blue, white, red, green, yellow flags on a sagging string.
  void _prayerFlags(Canvas canvas, Size size) {
    const colors = [
      Color(0xFF1E6FD9),
      Color(0xFFF5F5F5),
      Color(0xFFD62828),
      Color(0xFF2A9D48),
      Color(0xFFF2C230),
    ];
    final y0 = size.height * 0.012;
    final sag = size.height * 0.05;
    double yAt(double x) {
      final t = x / size.width;
      return y0 + sag * 4 * t * (1 - t);
    }

    final string = Path()..moveTo(0, yAt(0));
    for (var x = 0.0; x <= size.width; x += 8) {
      string.lineTo(x, yAt(x));
    }
    canvas.drawPath(
        string,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: 0.35));

    final w = size.width / 22;
    var i = 0;
    for (var x = w * 0.5; x < size.width - w * 0.5; x += w * 1.05) {
      final y = yAt(x + w / 2);
      final c = colors[i++ % colors.length];
      canvas.save();
      canvas.translate(x + w / 2, y);
      canvas.rotate(math.sin(i * 1.3) * 0.06);
      final r = Rect.fromLTWH(-w / 2, 0, w * 0.9, w * 1.15);
      canvas.drawRect(r, Paint()..color = c.withValues(alpha: 0.8));
      canvas.drawRect(
          r,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.25)],
            ).createShader(r));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => old.showFlags != showFlags;
}

/// A chunky, glossy game button with a gold rim that presses down on tap.
class GlossyButton extends StatefulWidget {
  final String label;
  final String? emoji;
  final VoidCallback? onTap;
  final List<Color> colors;
  final double height;

  const GlossyButton({
    super.key,
    required this.label,
    this.emoji,
    this.onTap,
    this.colors = const [Color(0xFFE8394A), Color(0xFFA50F22)],
    this.height = 62,
  });

  @override
  State<GlossyButton> createState() => _GlossyButtonState();
}

class _GlossyButtonState extends State<GlossyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final depth = _down ? 2.0 : 6.0;
    final bottom = HSLColor.fromColor(widget.colors.last)
        .withLightness(
            (HSLColor.fromColor(widget.colors.last).lightness - 0.15)
                .clamp(0.0, 1.0))
        .toColor();
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        AudioManager().playButtonTap();
        widget.onTap?.call();
      },
      child: SizedBox(
        height: widget.height + 6,
        child: Stack(
          children: [
            // 3D side of the button.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: widget.height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bottom,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 70),
              left: 0,
              right: 0,
              top: 6 - depth,
              height: widget.height,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: widget.colors,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: NepaliColors.goldLight, width: 1.8),
                ),
                child: Stack(
                  children: [
                    // Gloss.
                    Positioned(
                      left: 6,
                      right: 6,
                      top: 3,
                      height: widget.height * 0.42,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.38),
                              Colors.white.withValues(alpha: 0.02),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.emoji != null) ...[
                            Text(widget.emoji!,
                                style: const TextStyle(fontSize: 26)),
                            const SizedBox(width: 12),
                          ],
                          Text(
                            widget.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(
                                    color: Colors.black45,
                                    offset: Offset(0, 2),
                                    blurRadius: 3),
                              ],
                            ),
                          ),
                        ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
