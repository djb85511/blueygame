import 'dart:math';

import 'package:bluey_number_adventures/core/audio/audio_service.dart';
import 'package:bluey_number_adventures/core/theme/app_theme.dart';
import 'package:bluey_number_adventures/domain/models/math_problem.dart';
import 'package:bluey_number_adventures/domain/models/user_progress.dart';
import 'package:bluey_number_adventures/domain/services/adaptive_engine.dart';
import 'package:bluey_number_adventures/presentation/providers/game_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Engine that serves a fixed sequence of problems (cycling) while keeping
/// the real progression logic.
class ScriptedEngine extends AdaptiveEngine {
  ScriptedEngine(this.problems) : super(random: Random(1));

  final List<MathProblem> problems;
  int _index = 0;

  @override
  MathProblem generateProblem(UserProgress progress) =>
      problems[_index++ % problems.length];
}

const threeBones = MathProblem(
  operands: [3],
  operator: MathOperator.subitize,
  correctAnswer: 3,
  objectType: CountObjectType.bone,
);

const twoPlusOneBalls = MathProblem(
  operands: [2, 1],
  operator: MathOperator.add,
  correctAnswer: 3,
  objectType: CountObjectType.ball,
);

const fiveMinusTwoBones = MathProblem(
  operands: [5, 2],
  operator: MathOperator.subtract,
  correctAnswer: 3,
  objectType: CountObjectType.bone,
);

Future<ProviderContainer> pumpWithProviders(
  WidgetTester tester,
  Widget home, {
  List<MathProblem> problems = const [threeBones, twoPlusOneBalls],
  MockAudioService? audio,
  Map<String, Object> prefs = const {},
  Size surface = const Size(800, 600),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  SharedPreferences.setMockInitialValues(prefs);
  final sharedPrefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      audioServiceProvider.overrideWithValue(audio ?? MockAudioService()),
      adaptiveEngineProvider.overrideWithValue(ScriptedEngine(problems)),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(useGoogleFonts: false),
        home: home,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
  return container;
}
