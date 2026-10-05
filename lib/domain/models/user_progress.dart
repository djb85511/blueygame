import 'package:flutter/foundation.dart';

import '../../core/constants/game_constants.dart';

/// Persisted learner progress through the adaptive bands.
@immutable
class UserProgress {
  const UserProgress({
    this.band = GameConstants.minBand,
    this.level = 1,
    this.streakCorrect = 0,
    this.streakIncorrect = 0,
    this.lastPlayed,
  });

  static const UserProgress initial = UserProgress();

  /// 1 = Bingo's Band, 2 = Bluey's Crew, 3 = Heeler Family.
  final int band;

  /// Level within the band (1..[GameConstants.levelsPerBand]).
  final int level;
  final int streakCorrect;
  final int streakIncorrect;
  final DateTime? lastPlayed;

  /// Single increasing difficulty index (0-based) across all bands.
  int get difficultyIndex =>
      (band - GameConstants.minBand) * GameConstants.levelsPerBand +
      (level - 1);

  bool get isAtMinimum => band == GameConstants.minBand && level == 1;

  bool get isAtMaximum =>
      band == GameConstants.maxBand && level == GameConstants.levelsPerBand;

  UserProgress copyWith({
    int? band,
    int? level,
    int? streakCorrect,
    int? streakIncorrect,
    DateTime? lastPlayed,
  }) {
    return UserProgress(
      band: band ?? this.band,
      level: level ?? this.level,
      streakCorrect: streakCorrect ?? this.streakCorrect,
      streakIncorrect: streakIncorrect ?? this.streakIncorrect,
      lastPlayed: lastPlayed ?? this.lastPlayed,
    );
  }

  Map<String, dynamic> toJson() => {
    'band': band,
    'level': level,
    'streakCorrect': streakCorrect,
    'streakIncorrect': streakIncorrect,
    'lastPlayed': lastPlayed?.toIso8601String(),
  };

  /// Tolerant of missing or out-of-range values from older saves.
  factory UserProgress.fromJson(Map<String, dynamic> json) {
    int readInt(String key, int fallback) {
      final value = json[key];
      return value is num ? value.toInt() : fallback;
    }

    final lastPlayedRaw = json['lastPlayed'];
    return UserProgress(
      band: readInt(
        'band',
        GameConstants.minBand,
      ).clamp(GameConstants.minBand, GameConstants.maxBand),
      level: readInt('level', 1).clamp(1, GameConstants.levelsPerBand),
      streakCorrect: readInt('streakCorrect', 0).clamp(0, 1 << 30),
      streakIncorrect: readInt('streakIncorrect', 0).clamp(0, 1 << 30),
      lastPlayed: lastPlayedRaw is String
          ? DateTime.tryParse(lastPlayedRaw)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UserProgress &&
      other.band == band &&
      other.level == level &&
      other.streakCorrect == streakCorrect &&
      other.streakIncorrect == streakIncorrect &&
      other.lastPlayed == lastPlayed;

  @override
  int get hashCode =>
      Object.hash(band, level, streakCorrect, streakIncorrect, lastPlayed);

  @override
  String toString() =>
      'UserProgress(band: $band, level: $level, streakCorrect: $streakCorrect, '
      'streakIncorrect: $streakIncorrect, lastPlayed: $lastPlayed)';
}
