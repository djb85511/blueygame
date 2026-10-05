import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/game_constants.dart';
import '../../core/theme/app_colors.dart';

/// Non-punitive celebration layer shown after a correct answer.
///
/// Renders a burst of stars and a big bouncing star. It never blocks taps
/// and there is deliberately no counterpart for incorrect answers: those
/// are handled with a gentle wiggle on the tapped element only.
class FeedbackOverlay extends StatelessWidget {
  const FeedbackOverlay({
    super.key,
    required this.visible,
    this.levelUp = false,
    this.burstKey,
  });

  final bool visible;

  /// Adds an extra ring of stars when the child moves up a level.
  final bool levelUp;

  /// Changing this replays the burst.
  final Object? burstKey;

  static const List<Color> _starColors = [
    AppColors.bingoOrange,
    AppColors.heelerBlue,
    AppColors.coral,
    AppColors.grassGreen,
    AppColors.sandyYellow,
  ];

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final starCount = levelUp ? 16 : 10;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final reach =
              math.min(constraints.maxWidth, constraints.maxHeight) * 0.42;
          return Stack(
            key: ValueKey(('burst', burstKey)),
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < starCount; i++)
                _burstStar(i, starCount, reach),
              Icon(
                    Icons.star_rounded,
                    size: 140,
                    color: AppColors.sandyYellow,
                    shadows: const [
                      Shadow(
                        color: AppColors.ink,
                        blurRadius: 0,
                        offset: Offset(3, 3),
                      ),
                    ],
                  )
                  .animate()
                  .scaleXY(
                    begin: 0,
                    end: 1,
                    duration: GameConstants.celebrationDuration,
                    curve: Curves.elasticOut,
                  )
                  .then(delay: 600.ms)
                  .fadeOut(duration: 500.ms),
            ],
          );
        },
      ),
    );
  }

  Widget _burstStar(int index, int total, double reach) {
    final angle = (index / total) * 2 * math.pi;
    final distance = reach * (index.isEven ? 1.0 : 0.7);
    return Icon(
          Icons.star_rounded,
          size: index.isEven ? 44 : 30,
          color: _starColors[index % _starColors.length],
        )
        .animate()
        .move(
          begin: Offset.zero,
          end: Offset(math.cos(angle) * distance, math.sin(angle) * distance),
          duration: 700.ms,
          curve: Curves.easeOutCubic,
        )
        .rotate(begin: 0, end: 0.5, duration: 700.ms)
        .fadeOut(delay: 900.ms, duration: 500.ms);
  }
}
