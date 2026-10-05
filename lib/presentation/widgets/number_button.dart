import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/game_constants.dart';
import '../../core/theme/app_colors.dart';

/// Visual feedback state of a [NumberButton].
enum NumberButtonFeedback { none, correct, tryAgain }

/// Large answer button showing a numeral plus matching dots, so children
/// who cannot yet read numerals can still match quantities.
///
/// Always at least [GameConstants.minTouchTarget] in both dimensions.
class NumberButton extends StatelessWidget {
  const NumberButton({
    super.key,
    required this.value,
    required this.onPressed,
    this.size = GameConstants.numberButtonSize,
    this.feedback = NumberButtonFeedback.none,
    this.feedbackKey,
  });

  final int value;
  final VoidCallback? onPressed;
  final double size;
  final NumberButtonFeedback feedback;

  /// Changing this replays the feedback animation (e.g. repeated wiggles).
  final Object? feedbackKey;

  @override
  Widget build(BuildContext context) {
    final dimension = math.max(size, GameConstants.minTouchTarget);
    final isCorrect = feedback == NumberButtonFeedback.correct;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(dimension * 0.3),
      side: BorderSide(
        color: isCorrect ? AppColors.ink : AppColors.heelerBlueDark,
        width: isCorrect ? 5 : 3,
      ),
    );

    final Widget button = Semantics(
      button: true,
      label: '$value',
      child: SizedBox.square(
        dimension: dimension,
        // A transparent Material keeps the full square (corners included)
        // hit-testable; the rounded look is painted with Ink.
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(dimension * 0.3),
            splashColor: AppColors.sandyYellow,
            child: Ink(
              decoration: ShapeDecoration(
                color: isCorrect ? AppColors.grassGreen : AppColors.white,
                shape: shape,
                shadows: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.35),
                    offset: Offset(0, isCorrect ? 6 : 3),
                    blurRadius: isCorrect ? 8 : 3,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(dimension * 0.08),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: FittedBox(
                        child: Text(
                          '$value',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: _Pips(count: value)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return switch (feedback) {
      NumberButtonFeedback.correct =>
        button
            .animate(key: ValueKey(('correct', feedbackKey)))
            .scaleXY(
              begin: 1,
              end: 1.25,
              duration: 220.ms,
              curve: Curves.easeOut,
            )
            .then()
            .scaleXY(
              begin: 1,
              end: 1 / 1.25,
              duration: 380.ms,
              curve: Curves.elasticOut,
            ),
      NumberButtonFeedback.tryAgain =>
        button
            .animate(key: ValueKey(('wiggle', feedbackKey)))
            .shake(
              hz: 4,
              offset: const Offset(6, 0),
              rotation: 0,
              duration: GameConstants.wiggleDuration,
            ),
      NumberButtonFeedback.none => button,
    };
  }
}

/// Row of small dots matching the button's numeral.
class _Pips extends StatelessWidget {
  const _Pips({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dot = math.min(
          constraints.maxHeight * 0.7,
          constraints.maxWidth / (count * 1.6),
        );
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              Container(
                width: dot,
                height: dot,
                margin: EdgeInsets.symmetric(horizontal: dot * 0.25),
                decoration: const BoxDecoration(
                  color: AppColors.bingoOrangeDark,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        );
      },
    );
  }
}
