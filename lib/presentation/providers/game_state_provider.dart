import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/audio/audio_service.dart';
import '../../core/constants/game_constants.dart';
import '../../domain/models/math_problem.dart';
import '../../domain/models/user_progress.dart';
import '../../domain/services/adaptive_engine.dart';
import '../../domain/services/storage_service.dart';

// --- Dependency providers ---------------------------------------------------

/// Must be overridden with a loaded instance (see `main.dart`).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override sharedPreferencesProvider'),
);

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(ref.watch(sharedPreferencesProvider)),
);

final audioServiceProvider = Provider<AudioService>(
  (ref) => const SynthAudioService(),
);

final adaptiveEngineProvider = Provider<AdaptiveEngine>(
  (ref) => AdaptiveEngine(),
);

// --- Game state ---------------------------------------------------------------

enum GamePhase {
  /// Waiting for the child to choose an answer.
  playing,

  /// Correct answer chosen; celebration runs until auto-advance.
  celebrating,
}

/// How Bingo reacts on screen.
enum CharacterMood { idle, happy, encouraging }

@immutable
class GameState {
  const GameState({
    required this.progress,
    required this.problem,
    this.phase = GamePhase.playing,
    this.lastIncorrectAnswer,
    this.wiggleCount = 0,
    this.mood = CharacterMood.idle,
    this.leveledUp = false,
    this.problemNumber = 0,
  });

  final UserProgress progress;
  final MathProblem problem;
  final GamePhase phase;

  /// Most recent incorrect answer for this problem (drives the button wiggle).
  final int? lastIncorrectAnswer;

  /// Increments on every incorrect tap so wiggle animations replay.
  final int wiggleCount;
  final CharacterMood mood;

  /// Whether the last correct answer advanced the learner's level.
  final bool leveledUp;

  /// Increments each time a new problem is shown.
  final int problemNumber;

  bool get isCelebrating => phase == GamePhase.celebrating;

  GameState copyWith({
    UserProgress? progress,
    MathProblem? problem,
    GamePhase? phase,
    int? Function()? lastIncorrectAnswer,
    int? wiggleCount,
    CharacterMood? mood,
    bool? leveledUp,
    int? problemNumber,
  }) {
    return GameState(
      progress: progress ?? this.progress,
      problem: problem ?? this.problem,
      phase: phase ?? this.phase,
      lastIncorrectAnswer: lastIncorrectAnswer != null
          ? lastIncorrectAnswer()
          : this.lastIncorrectAnswer,
      wiggleCount: wiggleCount ?? this.wiggleCount,
      mood: mood ?? this.mood,
      leveledUp: leveledUp ?? this.leveledUp,
      problemNumber: problemNumber ?? this.problemNumber,
    );
  }
}

/// Drives the game lifecycle: answer → feedback → auto-advance.
class GameNotifier extends StateNotifier<GameState> {
  GameNotifier({
    required AdaptiveEngine engine,
    required StorageService storage,
    required this._audio,
    this._autoAdvanceDelay = GameConstants.autoAdvanceDelay,
  }) : _engine = engine,
       _storage = storage,
       super(_initialState(engine, storage));

  final AdaptiveEngine _engine;
  final StorageService _storage;
  final AudioService _audio;
  final Duration _autoAdvanceDelay;
  Timer? _advanceTimer;

  static GameState _initialState(
    AdaptiveEngine engine,
    StorageService storage,
  ) {
    final progress = storage.loadProgress();
    return GameState(
      progress: progress,
      problem: engine.generateProblem(progress),
    );
  }

  /// Handles a tap on an answer button.
  void submitAnswer(int answer) {
    if (state.isCelebrating) return;

    final before = state.progress;
    final updated = _engine.evaluateAnswer(before, answer, state.problem);
    unawaited(_storage.saveProgress(updated));

    if (state.problem.isCorrect(answer)) {
      final leveledUp = updated.difficultyIndex > before.difficultyIndex;
      state = state.copyWith(
        progress: updated,
        phase: GamePhase.celebrating,
        lastIncorrectAnswer: () => null,
        mood: CharacterMood.happy,
        leveledUp: leveledUp,
      );
      unawaited(_audio.play(leveledUp ? SoundCue.levelUp : SoundCue.success));
      _advanceTimer?.cancel();
      _advanceTimer = Timer(_autoAdvanceDelay, nextProblem);
    } else {
      // Gentle: same problem stays up so the child can simply try again.
      state = state.copyWith(
        progress: updated,
        lastIncorrectAnswer: () => answer,
        wiggleCount: state.wiggleCount + 1,
        mood: CharacterMood.encouraging,
        leveledUp: false,
      );
      unawaited(_audio.play(SoundCue.gentleRetry));
    }
  }

  /// Presents a fresh problem for the current progress.
  void nextProblem() {
    _advanceTimer?.cancel();
    _advanceTimer = null;
    if (!mounted) return;
    state = GameState(
      progress: state.progress,
      problem: _generateDistinct(state.progress, state.problem),
      problemNumber: state.problemNumber + 1,
    );
  }

  /// Avoids showing the identical problem twice in a row where possible.
  MathProblem _generateDistinct(UserProgress progress, MathProblem previous) {
    var problem = _engine.generateProblem(progress);
    for (var i = 0; i < 4 && problem == previous; i++) {
      problem = _engine.generateProblem(progress);
    }
    return problem;
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    super.dispose();
  }
}

final gameStateProvider =
    StateNotifierProvider.autoDispose<GameNotifier, GameState>((ref) {
      return GameNotifier(
        engine: ref.watch(adaptiveEngineProvider),
        storage: ref.watch(storageServiceProvider),
        audio: ref.watch(audioServiceProvider),
      );
    });
