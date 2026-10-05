import 'dart:math';

import '../../core/constants/game_constants.dart';
import '../models/math_problem.dart';
import '../models/user_progress.dart';

/// Generates band-appropriate problems and adapts difficulty.
///
/// * Band 1 (Bingo's Band): subitizing 1–3, counting up to 5.
/// * Band 2 (Bluey's Crew): ±1 with every number in 1–5.
/// * Band 3 (Heeler Family): ±2 with every number in 1–5.
///
/// Within a band, level 1 eases in, level 2 introduces the other skill and
/// level 3 mixes everything. Three correct answers in a row move up one
/// level, two incorrect answers in a row move down one level; moving past
/// either end of a band crosses into the neighbouring band.
class AdaptiveEngine {
  AdaptiveEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  MathProblem generateProblem(UserProgress progress) {
    final objectType =
        CountObjectType.values[_random.nextInt(CountObjectType.values.length)];

    switch (progress.band) {
      case 1:
        return _bandOne(progress.level, objectType);
      case 2:
        return _arithmetic(progress.level, 1, objectType);
      default:
        return _arithmetic(progress.level, 2, objectType);
    }
  }

  /// Returns the learner's progress after [selectedAnswer] for [problem].
  UserProgress evaluateAnswer(
    UserProgress progress,
    int selectedAnswer,
    MathProblem problem, {
    DateTime? now,
  }) {
    final playedAt = now ?? DateTime.now();

    if (problem.isCorrect(selectedAnswer)) {
      final streak = progress.streakCorrect + 1;
      if (streak >= GameConstants.correctStreakToLevelUp) {
        return _shift(progress, 1).copyWith(lastPlayed: playedAt);
      }
      return progress.copyWith(
        streakCorrect: streak,
        streakIncorrect: 0,
        lastPlayed: playedAt,
      );
    }

    final streak = progress.streakIncorrect + 1;
    if (streak >= GameConstants.incorrectStreakToLevelDown) {
      return _shift(progress, -1).copyWith(lastPlayed: playedAt);
    }
    return progress.copyWith(
      streakCorrect: 0,
      streakIncorrect: streak,
      lastPlayed: playedAt,
    );
  }

  /// Moves [delta] levels across the band/level ladder and resets streaks.
  UserProgress _shift(UserProgress progress, int delta) {
    const perBand = GameConstants.levelsPerBand;
    const maxIndex =
        (GameConstants.maxBand - GameConstants.minBand + 1) * perBand - 1;
    final index = (progress.difficultyIndex + delta).clamp(0, maxIndex);
    return UserProgress(
      band: GameConstants.minBand + index ~/ perBand,
      level: index % perBand + 1,
      lastPlayed: progress.lastPlayed,
    );
  }

  MathProblem _bandOne(int level, CountObjectType objectType) {
    final bool subitize = switch (level) {
      1 => true,
      2 => _random.nextBool(),
      _ => false,
    };

    if (subitize) {
      final n = _between(GameConstants.minNumber, GameConstants.subitizeMax);
      return MathProblem(
        operands: [n],
        operator: MathOperator.subitize,
        correctAnswer: n,
        objectType: objectType,
      );
    }

    // Counting: level 2 reaches 4, level 3 reaches the full 5.
    final top = level >= 3
        ? GameConstants.maxNumber
        : GameConstants.maxNumber - 1;
    final n = _between(GameConstants.minNumber, top);
    return MathProblem(
      operands: [n],
      operator: MathOperator.count,
      correctAnswer: n,
      objectType: objectType,
    );
  }

  /// Addition/subtraction by [step], keeping operands and answers in 1–5.
  MathProblem _arithmetic(int level, int step, CountObjectType objectType) {
    final bool add = switch (level) {
      1 => true,
      2 => false,
      _ => _random.nextBool(),
    };

    if (add) {
      final a = _between(
        GameConstants.minNumber,
        GameConstants.maxNumber - step,
      );
      return MathProblem(
        operands: [a, step],
        operator: MathOperator.add,
        correctAnswer: a + step,
        objectType: objectType,
      );
    }

    final a = _between(GameConstants.minNumber + step, GameConstants.maxNumber);
    return MathProblem(
      operands: [a, step],
      operator: MathOperator.subtract,
      correctAnswer: a - step,
      objectType: objectType,
    );
  }

  int _between(int min, int max) => min + _random.nextInt(max - min + 1);
}
