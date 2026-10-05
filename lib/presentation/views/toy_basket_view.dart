import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/game_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/math_problem.dart';
import '../providers/game_state_provider.dart';
import '../widgets/character_avatar.dart';
import '../widgets/count_object.dart';
import '../widgets/feedback_overlay.dart';
import '../widgets/number_button.dart';

/// "Bingo's Toy Basket": the core, text-free math activity.
class ToyBasketView extends ConsumerWidget {
  const ToyBasketView({super.key});

  static const homeButtonKey = ValueKey('toy-basket-home');
  static const playAreaKey = ValueKey('toy-basket-play-area');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(GameConstants.spacing),
          child: Column(
            children: [
              _Header(state: game),
              const SizedBox(height: GameConstants.spacing),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _PlayArea(
                      key: playAreaKey,
                      problem: game.problem,
                      wiggleCount: game.wiggleCount,
                      problemNumber: game.problemNumber,
                    ),
                    FeedbackOverlay(
                      visible: game.isCelebrating,
                      levelUp: game.leveledUp,
                      burstKey: game.problemNumber,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GameConstants.spacing),
              _AnswerBar(state: game, onAnswer: notifier.submitAnswer),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox.square(
          dimension: GameConstants.minTouchTarget,
          child: IconButton.filled(
            key: ToyBasketView.homeButtonKey,
            tooltip: 'Home',
            iconSize: 34,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.heelerBlue,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.home_rounded),
          ),
        ),
        Expanded(
          child: Center(
            child: CharacterAvatar(
              character: PupCharacter.bingo,
              mood: state.mood,
              size: 96,
              reactionKey: (state.problemNumber, state.wiggleCount),
            ),
          ),
        ),
        _BandBadge(band: state.progress.band, level: state.progress.level),
      ],
    );
  }
}

/// Text-free progress indicator: one paw per band, dots for level.
class _BandBadge extends StatelessWidget {
  const _BandBadge({required this.band, required this.level});

  final int band;
  final int level;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Band $band, level $level',
      child: SizedBox(
        width: GameConstants.minTouchTarget,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < band; i++)
                  const Icon(
                    Icons.pets,
                    size: 18,
                    color: AppColors.bingoOrangeDark,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= GameConstants.levelsPerBand; i++)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= level
                          ? AppColors.heelerBlue
                          : AppColors.white,
                      border: Border.all(color: AppColors.ink, width: 1.5),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws the current problem with toys, a basket and Bingo's paws.
class _PlayArea extends StatelessWidget {
  const _PlayArea({
    super.key,
    required this.problem,
    required this.wiggleCount,
    required this.problemNumber,
  });

  final MathProblem problem;
  final int wiggleCount;
  final int problemNumber;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final objectSize = math
            .min(constraints.maxHeight * 0.2, constraints.maxWidth * 0.15)
            .clamp(32.0, 72.0);

        final Widget content = switch (problem.operator) {
          MathOperator.subitize || MathOperator.count => _Basket(
            child: CountObjectGroup(
              type: problem.objectType,
              count: problem.firstOperand,
              objectSize: objectSize,
            ),
          ),
          MathOperator.add => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: _Basket(
                  child: CountObjectGroup(
                    type: problem.objectType,
                    count: problem.firstOperand,
                    objectSize: objectSize,
                  ),
                ),
              ),
              const _OperatorIcon(icon: Icons.add_rounded),
              _BingoHolding(
                type: problem.objectType,
                count: problem.secondOperand,
                objectSize: objectSize,
              ),
            ],
          ),
          MathOperator.subtract => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: _Basket(
                  child: CountObjectGroup(
                    type: problem.objectType,
                    count: problem.firstOperand,
                    fadedCount: problem.secondOperand,
                    objectSize: objectSize,
                  ),
                ),
              ),
              const _OperatorIcon(icon: Icons.remove_rounded),
              _BouncingAway(
                type: problem.objectType,
                count: problem.secondOperand,
                objectSize: objectSize,
              ),
            ],
          ),
        };

        // A fresh problem pops in; wrong answers wiggle the whole group.
        return Center(
          child: content
              .animate(key: ValueKey(('enter', problemNumber)))
              .fadeIn(duration: 250.ms)
              .scaleXY(
                begin: 0.85,
                end: 1,
                duration: 300.ms,
                curve: Curves.easeOutBack,
              )
              .animate(key: ValueKey(('wiggle', problemNumber, wiggleCount)))
              .shake(
                hz: 4,
                offset: const Offset(10, 0),
                rotation: 0,
                duration: wiggleCount == 0
                    ? Duration.zero
                    : GameConstants.wiggleDuration,
              ),
        );
      },
    );
  }
}

class _OperatorIcon extends StatelessWidget {
  const _OperatorIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.fromBorderSide(
            BorderSide(color: AppColors.ink, width: 3),
          ),
        ),
        child: Icon(icon, size: 36, color: AppColors.ink),
      ),
    );
  }
}

/// A woven basket frame around a group of toys.
class _Basket extends StatelessWidget {
  const _Basket({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 140,
        minHeight: 120,
        maxWidth: 320,
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.basketBrown,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12),
          bottom: Radius.circular(40),
        ),
        border: Border.all(color: AppColors.ink, width: 5),
        boxShadow: const [
          BoxShadow(color: AppColors.basketBrownDark, offset: Offset(0, 6)),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.sandyYellow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.basketBrownDark, width: 3),
        ),
        child: Center(widthFactor: 1, heightFactor: 1, child: child),
      ),
    );
  }
}

/// Bingo holding extra toys to add to the basket.
class _BingoHolding extends StatelessWidget {
  const _BingoHolding({
    required this.type,
    required this.count,
    required this.objectSize,
  });

  final CountObjectType type;
  final int count;
  final double objectSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CharacterAvatar(
          character: PupCharacter.bingo,
          mood: CharacterMood.happy,
          size: objectSize * 1.3,
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.bingoOrange,
            borderRadius: BorderRadius.circular(GameConstants.cornerRadius),
            border: Border.all(color: AppColors.ink, width: 4),
          ),
          child: CountObjectGroup(
            type: type,
            count: count,
            objectSize: objectSize,
          ),
        ),
      ],
    );
  }
}

/// Toys bouncing out of the basket in a subtraction problem.
class _BouncingAway extends StatelessWidget {
  const _BouncingAway({
    required this.type,
    required this.count,
    required this.objectSize,
  });

  final CountObjectType type;
  final int count;
  final double objectSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.north_east_rounded,
          size: objectSize,
          color: AppColors.coral,
        ),
        CountObjectGroup(type: type, count: count, objectSize: objectSize)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: 0,
              end: -8,
              duration: 600.ms,
              curve: Curves.easeInOut,
            ),
      ],
    );
  }
}

/// Bottom action bar of answer buttons 1–5.
class _AnswerBar extends StatelessWidget {
  const _AnswerBar({required this.state, required this.onAnswer});

  final GameState state;
  final ValueChanged<int> onAnswer;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final value in GameConstants.answerChoices)
          NumberButton(
            key: ValueKey('number-button-$value'),
            value: value,
            onPressed: state.isCelebrating ? null : () => onAnswer(value),
            feedback: _feedbackFor(value),
            feedbackKey: (state.problemNumber, state.wiggleCount),
          ),
      ],
    );
  }

  NumberButtonFeedback _feedbackFor(int value) {
    if (state.isCelebrating && state.problem.isCorrect(value)) {
      return NumberButtonFeedback.correct;
    }
    if (!state.isCelebrating && state.lastIncorrectAnswer == value) {
      return NumberButtonFeedback.tryAgain;
    }
    return NumberButtonFeedback.none;
  }
}
