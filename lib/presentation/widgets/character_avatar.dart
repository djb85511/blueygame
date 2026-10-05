import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../providers/game_state_provider.dart';

enum PupCharacter { bingo, bluey }

/// Scalable vector pup avatar that reacts to the game's [mood].
class CharacterAvatar extends StatelessWidget {
  const CharacterAvatar({
    super.key,
    this.character = PupCharacter.bingo,
    this.mood = CharacterMood.idle,
    this.size = 120,
    this.reactionKey,
  });

  final PupCharacter character;
  final CharacterMood mood;
  final double size;

  /// Changing this replays the reaction animation.
  final Object? reactionKey;

  @override
  Widget build(BuildContext context) {
    final Widget avatar = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: PupPainter(character: character, mood: mood),
      ),
    );

    final Widget animated = switch (mood) {
      CharacterMood.happy =>
        avatar
            .animate(key: ValueKey(('happy', reactionKey)))
            .scaleXY(
              begin: 0.9,
              end: 1.1,
              duration: 250.ms,
              curve: Curves.easeOut,
            )
            .then()
            .moveY(begin: 0, end: -12, duration: 200.ms, curve: Curves.easeOut)
            .then()
            .moveY(begin: 0, end: 12, duration: 250.ms, curve: Curves.bounceOut)
            .scaleXY(begin: 1.1, end: 1.0, duration: 250.ms),
      CharacterMood.encouraging =>
        avatar
            .animate(key: ValueKey(('encourage', reactionKey)))
            .rotate(begin: 0, end: 0.03, duration: 180.ms)
            .then()
            .rotate(begin: 0, end: -0.03, duration: 180.ms),
      CharacterMood.idle => avatar,
    };

    return Semantics(
      label: '${character.name} is ${mood.name}',
      image: true,
      child: animated,
    );
  }
}

/// Paints a friendly cartoon heeler pup face.
class PupPainter extends CustomPainter {
  const PupPainter({required this.character, required this.mood});

  final PupCharacter character;
  final CharacterMood mood;

  Color get _fur => character == PupCharacter.bingo
      ? AppColors.bingoOrange
      : AppColors.heelerBlue;
  Color get _furDark => character == PupCharacter.bingo
      ? AppColors.bingoOrangeDark
      : AppColors.heelerBlueDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final outline = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fur = Paint()..color = _fur;
    final furDark = Paint()..color = _furDark;
    final cream = Paint()..color = AppColors.cream;
    final ink = Paint()..color = AppColors.ink;

    // Ears (tall, pointed).
    final leftEar = Path()
      ..moveTo(w * 0.18, h * 0.42)
      ..lineTo(w * 0.22, h * 0.04)
      ..lineTo(w * 0.44, h * 0.28)
      ..close();
    final rightEar = Path()
      ..moveTo(w * 0.82, h * 0.42)
      ..lineTo(w * 0.78, h * 0.04)
      ..lineTo(w * 0.56, h * 0.28)
      ..close();
    for (final ear in [leftEar, rightEar]) {
      canvas
        ..drawPath(ear, furDark)
        ..drawPath(ear, outline);
    }

    // Head.
    final head = Rect.fromLTRB(w * 0.12, h * 0.2, w * 0.88, h * 0.92);
    canvas
      ..drawOval(head, fur)
      ..drawOval(head, outline);

    // Muzzle.
    final muzzle = Rect.fromLTRB(w * 0.3, h * 0.55, w * 0.7, h * 0.9);
    canvas
      ..drawOval(muzzle, cream)
      ..drawOval(muzzle, outline);

    // Eyes: happy pups get closed "smiling" eyes.
    final eyeY = h * 0.47;
    for (final x in [w * 0.36, w * 0.64]) {
      if (mood == CharacterMood.happy) {
        final arc = Rect.fromCenter(
          center: Offset(x, eyeY + h * 0.02),
          width: w * 0.12,
          height: h * 0.1,
        );
        canvas.drawArc(arc, 3.4, 2.6, false, outline);
      } else {
        canvas.drawCircle(Offset(x, eyeY), w * 0.055, ink);
        canvas.drawCircle(
          Offset(x - w * 0.015, eyeY - h * 0.02),
          w * 0.018,
          Paint()..color = AppColors.white,
        );
      }
    }

    // Nose.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.64),
        width: w * 0.14,
        height: h * 0.08,
      ),
      ink,
    );

    // Mouth.
    final mouthRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.72),
      width: mood == CharacterMood.happy ? w * 0.24 : w * 0.16,
      height: mood == CharacterMood.happy ? h * 0.14 : h * 0.08,
    );
    if (mood == CharacterMood.happy) {
      final mouth = Path()
        ..moveTo(mouthRect.left, mouthRect.top)
        ..arcTo(mouthRect, 3.14159, -3.14159, false)
        ..close();
      canvas
        ..drawPath(mouth, Paint()..color = AppColors.coral)
        ..drawPath(mouth, outline);
    } else {
      canvas.drawArc(mouthRect, 0.3, 2.5, false, outline);
    }

    // Cheek blush.
    final blush = Paint()..color = AppColors.coral.withValues(alpha: 0.45);
    canvas
      ..drawCircle(Offset(w * 0.24, h * 0.62), w * 0.05, blush)
      ..drawCircle(Offset(w * 0.76, h * 0.62), w * 0.05, blush);
  }

  @override
  bool shouldRepaint(PupPainter oldDelegate) =>
      oldDelegate.character != character || oldDelegate.mood != mood;
}
