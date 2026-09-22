import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

/// Animated dice widget with Nepali styling.
class DiceWidget extends StatefulWidget {
  final int value;
  final bool isRolling;
  final bool canRoll;
  final VoidCallback? onRoll;

  const DiceWidget({
    super.key,
    required this.value,
    this.isRolling = false,
    this.canRoll = true,
    this.onRoll,
  });

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget> with TickerProviderStateMixin {
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRolling && !oldWidget.isRolling) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.canRoll && !widget.isRolling ? widget.onRoll : null,
      child: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          final shake = sin(_shakeController.value * pi * 8) * 6.0;
          return Transform.translate(
            offset: Offset(widget.isRolling ? shake : 0, 0),
            child: child,
          );
        },
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: widget.canRoll ? Colors.white : Colors.grey[200],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.canRoll
                  ? NepaliColors.primary
                  : Colors.grey[400]!,
              width: 2.5,
            ),
            boxShadow: widget.canRoll
                ? [
                    BoxShadow(
                      color: NepaliColors.primary.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: widget.isRolling
              ? _buildRolling()
              : _buildDotPattern(widget.value),
        ),
      )
          .animate(target: widget.canRoll && !widget.isRolling ? 1 : 0)
          .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 600.ms)
          .then()
          .scale(begin: const Offset(1.05, 1.05), end: const Offset(1, 1), duration: 600.ms),
    );
  }

  Widget _buildRolling() {
    return const Center(
      child: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          color: NepaliColors.primary,
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildDotPattern(int value) {
    return CustomPaint(
      painter: _DiceDotPainter(value: value),
    );
  }
}

double sin(double x) => _sin(x);
double pi = 3.14159265358979;

double _sin(double x) {
  // Quick approximation for animation shake
  return (x - x * x * x / 6 + x * x * x * x * x / 120);
}

class _DiceDotPainter extends CustomPainter {
  final int value;
  _DiceDotPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NepaliColors.primary
      ..style = PaintingStyle.fill;

    final dotRadius = size.width * 0.09;
    final positions = _dotPositions(value, size);
    for (final pos in positions) {
      canvas.drawCircle(pos, dotRadius, paint);
    }
  }

  List<Offset> _dotPositions(int value, Size s) {
    final w = s.width;
    final h = s.height;
    final q1 = Offset(w * 0.28, h * 0.28);
    final q2 = Offset(w * 0.72, h * 0.28);
    final q3 = Offset(w * 0.28, h * 0.72);
    final q4 = Offset(w * 0.72, h * 0.72);
    final m1 = Offset(w * 0.28, h * 0.5);
    final m2 = Offset(w * 0.72, h * 0.5);
    final c  = Offset(w * 0.5,  h * 0.5);

    switch (value) {
      case 1: return [c];
      case 2: return [q1, q4];
      case 3: return [q2, c, q3];
      case 4: return [q1, q2, q3, q4];
      case 5: return [q1, q2, c, q3, q4];
      case 6: return [q1, q2, m1, m2, q3, q4];
      default: return [];
    }
  }

  @override
  bool shouldRepaint(_DiceDotPainter old) => old.value != value;
}
