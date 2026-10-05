import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/game_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/math_problem.dart';

/// A single high-contrast, custom-drawn toy (bone or ball).
class CountObject extends StatelessWidget {
  const CountObject({
    super.key,
    required this.type,
    this.size = GameConstants.countObjectSize,
    this.faded = false,
  });

  final CountObjectType type;
  final double size;

  /// Faded objects are ones "leaving" in a subtraction problem.
  final bool faded;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: faded ? 0.35 : 1,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: switch (type) {
            CountObjectType.bone => const BonePainter(),
            CountObjectType.ball => const BallPainter(),
          },
        ),
      ),
    );
  }
}

/// A chunky dog bone with a thick dark outline.
class BonePainter extends CustomPainter {
  const BonePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final knob = h * 0.17;
    final shaft = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.2, h * 0.38, w * 0.8, h * 0.62),
      Radius.circular(h * 0.06),
    );

    final path = Path()
      ..addRRect(shaft)
      ..addOval(
        Rect.fromCircle(center: Offset(w * 0.18, h * 0.36), radius: knob),
      )
      ..addOval(
        Rect.fromCircle(center: Offset(w * 0.18, h * 0.64), radius: knob),
      )
      ..addOval(
        Rect.fromCircle(center: Offset(w * 0.82, h * 0.36), radius: knob),
      )
      ..addOval(
        Rect.fromCircle(center: Offset(w * 0.82, h * 0.64), radius: knob),
      );

    final outline = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2, w * 0.08)
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = AppColors.boneWhite;

    // Stroke first then fill: leaves a clean outer outline without inner seams.
    canvas
      ..drawPath(path, outline)
      ..drawPath(path, fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A bright two-tone ball with a shine highlight.
class BallPainter extends CustomPainter {
  const BallPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.42;
    final circle = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(center, radius, Paint()..color = AppColors.ballRed);

    // Yellow stripe across the middle.
    canvas.save();
    canvas.clipPath(Path()..addOval(circle));
    canvas.drawRect(
      Rect.fromCenter(center: center, width: radius * 2, height: radius * 0.6),
      Paint()..color = AppColors.sandyYellow,
    );
    canvas.restore();

    canvas.drawCircle(
      center.translate(-radius * 0.4, -radius * 0.45),
      radius * 0.16,
      Paint()..color = AppColors.white.withValues(alpha: 0.85),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2, size.width * 0.07),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A group of [count] objects laid out compactly (dice-like for ≤3).
class CountObjectGroup extends StatelessWidget {
  const CountObjectGroup({
    super.key,
    required this.type,
    required this.count,
    this.fadedCount = 0,
    this.objectSize = GameConstants.countObjectSize,
  });

  final CountObjectType type;
  final int count;

  /// The last [fadedCount] objects are drawn faded (leaving the basket).
  final int fadedCount;
  final double objectSize;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < count; i++)
          CountObject(
            key: ValueKey('count-object-$i'),
            type: type,
            size: objectSize,
            faded: i >= count - fadedCount,
          ),
      ],
    );
  }
}
