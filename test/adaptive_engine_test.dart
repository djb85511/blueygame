import 'dart:math';

import 'package:bluey_number_adventures/core/constants/game_constants.dart';
import 'package:bluey_number_adventures/domain/models/math_problem.dart';
import 'package:bluey_number_adventures/domain/models/user_progress.dart';
import 'package:bluey_number_adventures/domain/services/adaptive_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AdaptiveEngine engine;

  setUp(() => engine = AdaptiveEngine(random: Random(42)));

  List<MathProblem> sample(UserProgress progress, [int n = 500]) =>
      List.generate(n, (_) => engine.generateProblem(progress));

  UserProgress answerCorrectly(UserProgress p, int times) {
    for (var i = 0; i < times; i++) {
      final problem = engine.generateProblem(p);
      p = engine.evaluateAnswer(p, problem.correctAnswer, problem);
    }
    return p;
  }

  UserProgress answerIncorrectly(UserProgress p, int times) {
    for (var i = 0; i < times; i++) {
      final problem = engine.generateProblem(p);
      final wrong = problem.correctAnswer == 1 ? 2 : 1;
      p = engine.evaluateAnswer(p, wrong, problem);
    }
    return p;
  }

  group('Band 1 (Bingo\'s Band)', () {
    test('level 1 only produces subitizing problems within 1–3', () {
      final problems = sample(const UserProgress(band: 1, level: 1));
      for (final p in problems) {
        expect(p.operator, MathOperator.subitize);
        expect(p.operands, hasLength(1));
        expect(p.correctAnswer, inInclusiveRange(1, GameConstants.subitizeMax));
        expect(p.correctAnswer, p.firstOperand);
      }
      // Every value in the subitizing range is reachable.
      expect(problems.map((p) => p.correctAnswer).toSet(), {1, 2, 3});
    });

    test('subitizing never exceeds 3 at any band 1 level', () {
      for (var level = 1; level <= GameConstants.levelsPerBand; level++) {
        for (final p in sample(UserProgress(band: 1, level: level))) {
          if (p.operator == MathOperator.subitize) {
            expect(p.correctAnswer, lessThanOrEqualTo(3));
          }
        }
      }
    });

    test('counting problems stay within 1–5 and reach 5 at level 3', () {
      final problems = sample(const UserProgress(band: 1, level: 3));
      for (final p in problems) {
        expect(p.operator, MathOperator.count);
        expect(p.correctAnswer, inInclusiveRange(1, 5));
      }
      expect(problems.map((p) => p.correctAnswer).toSet(), {1, 2, 3, 4, 5});
    });

    test('level 2 mixes subitizing and counting', () {
      final ops = sample(const UserProgress(band: 1, level: 2))
          .map((p) => p.operator)
          .toSet();
      expect(ops, {MathOperator.subitize, MathOperator.count});
    });
  });

  group('Bands 2 and 3 arithmetic', () {
    for (final (band, step) in [(2, 1), (3, 2)]) {
      test('band $band uses ±$step with all numbers in 1–5', () {
        final ops = <MathOperator>{};
        for (var level = 1; level <= GameConstants.levelsPerBand; level++) {
          for (final p in sample(UserProgress(band: band, level: level))) {
            ops.add(p.operator);
            expect(p.operands, hasLength(2));
            expect(p.secondOperand, step);
            expect(p.firstOperand, inInclusiveRange(1, 5));
            expect(p.correctAnswer, inInclusiveRange(1, 5));
            final expected = p.operator == MathOperator.add
                ? p.firstOperand + step
                : p.firstOperand - step;
            expect(p.correctAnswer, expected);
          }
        }
        expect(ops, {MathOperator.add, MathOperator.subtract});
      });
    }
  });

  group('Progression', () {
    test('3 consecutive correct answers level up and reset streaks', () {
      var p = const UserProgress(band: 1, level: 1);
      p = answerCorrectly(p, 2);
      expect((p.band, p.level, p.streakCorrect), (1, 1, 2));

      p = answerCorrectly(p, 1);
      expect((p.band, p.level), (1, 2));
      expect(p.streakCorrect, 0);
      expect(p.streakIncorrect, 0);
    });

    test('levelling up past the top level moves into the next band', () {
      var p = const UserProgress(band: 1, level: 3);
      p = answerCorrectly(p, 3);
      expect((p.band, p.level), (2, 1));

      p = answerCorrectly(const UserProgress(band: 2, level: 3), 3);
      expect((p.band, p.level), (3, 1));
    });

    test('a full climb reaches Heeler Family and caps there', () {
      var p = UserProgress.initial;
      p = answerCorrectly(p, 3 * 8);
      expect(p.isAtMaximum, isTrue);
      p = answerCorrectly(p, 3);
      expect((p.band, p.level), (3, 3));
    });

    test('2 consecutive incorrect answers level down', () {
      var p = const UserProgress(band: 2, level: 2);
      p = answerIncorrectly(p, 1);
      expect((p.band, p.level, p.streakIncorrect), (2, 2, 1));

      p = answerIncorrectly(p, 1);
      expect((p.band, p.level), (2, 1));
      expect(p.streakIncorrect, 0);
    });

    test(
      'levelling down from a band\'s first level drops to previous band',
      () {
        final p = answerIncorrectly(const UserProgress(band: 3, level: 1), 2);
        expect((p.band, p.level), (2, 3));
      },
    );

    test('difficulty never drops below Band 1 level 1', () {
      final p = answerIncorrectly(UserProgress.initial, 6);
      expect((p.band, p.level), (1, 1));
    });

    test('a correct answer breaks an incorrect streak and vice versa', () {
      var p = const UserProgress(band: 2, level: 2);
      p = answerIncorrectly(p, 1);
      p = answerCorrectly(p, 1);
      expect(p.streakIncorrect, 0);
      expect(p.streakCorrect, 1);
      p = answerIncorrectly(p, 1);
      expect(p.streakCorrect, 0);
      expect((p.band, p.level), (2, 2));
    });

    test('alternating answers never change level', () {
      var p = const UserProgress(band: 2, level: 2);
      for (var i = 0; i < 10; i++) {
        p = answerCorrectly(p, 2);
        p = answerIncorrectly(p, 1);
      }
      expect((p.band, p.level), (2, 2));
    });

    test('evaluateAnswer stamps lastPlayed', () {
      final now = DateTime(2026, 10, 5, 9);
      const problem = MathProblem(
        operands: [2],
        operator: MathOperator.subitize,
        correctAnswer: 2,
        objectType: CountObjectType.bone,
      );
      final p = engine.evaluateAnswer(
        UserProgress.initial,
        2,
        problem,
        now: now,
      );
      expect(p.lastPlayed, now);
    });
  });

  group('UserProgress serialization', () {
    test('round-trips through JSON', () {
      final p = UserProgress(
        band: 2,
        level: 3,
        streakCorrect: 1,
        streakIncorrect: 0,
        lastPlayed: DateTime.utc(2026, 1, 2, 3, 4),
      );
      expect(UserProgress.fromJson(p.toJson()), p);
    });

    test('fromJson clamps invalid values and tolerates missing keys', () {
      final p = UserProgress.fromJson({'band': 9, 'level': -2});
      expect((p.band, p.level, p.streakCorrect, p.lastPlayed), (3, 1, 0, null));
    });

    test('copyWith overrides only given fields', () {
      const p = UserProgress(band: 2, level: 2, streakCorrect: 1);
      final q = p.copyWith(level: 3);
      expect((q.band, q.level, q.streakCorrect), (2, 3, 1));
    });
  });
}
