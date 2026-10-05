/// Shared gameplay, UX and timing constants.
abstract final class GameConstants {
  // --- Touch & layout -------------------------------------------------------
  /// Minimum interactive size (logical points) for every tappable element.
  static const double minTouchTarget = 60.0;

  /// Default rendered size of an answer button (comfortably above minimum).
  static const double numberButtonSize = 76.0;

  static const double playButtonSize = 168.0;
  static const double cornerRadius = 24.0;
  static const double spacing = 16.0;
  static const double countObjectSize = 48.0;

  // --- Timings --------------------------------------------------------------
  /// Delay between a correct answer and the next problem.
  static const Duration autoAdvanceDelay = Duration(seconds: 3);
  static const Duration wiggleDuration = Duration(milliseconds: 500);
  static const Duration celebrationDuration = Duration(milliseconds: 900);
  static const Duration buttonPressDuration = Duration(milliseconds: 120);

  // --- Adaptive engine ------------------------------------------------------
  static const int correctStreakToLevelUp = 3;
  static const int incorrectStreakToLevelDown = 2;
  static const int minBand = 1;
  static const int maxBand = 3;
  static const int levelsPerBand = 3;

  /// Every quantity and answer stays within this range.
  static const int minNumber = 1;
  static const int maxNumber = 5;

  /// Band 1 subitizing tops out at 3 items (instant recognition range).
  static const int subitizeMax = 3;

  /// Answer choices shown on the action bar.
  static const List<int> answerChoices = [1, 2, 3, 4, 5];
}
