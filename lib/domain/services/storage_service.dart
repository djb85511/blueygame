import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_progress.dart';

/// Persists [UserProgress] with SharedPreferences.
class StorageService {
  StorageService(this._prefs);

  static const String progressKey = 'user_progress_v1';

  final SharedPreferences _prefs;

  UserProgress loadProgress() {
    final raw = _prefs.getString(progressKey);
    if (raw == null) return UserProgress.initial;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return UserProgress.fromJson(decoded);
      }
    } on FormatException catch (e) {
      debugPrint('StorageService: corrupt progress, resetting ($e)');
    }
    return UserProgress.initial;
  }

  Future<bool> saveProgress(UserProgress progress) =>
      _prefs.setString(progressKey, jsonEncode(progress.toJson()));

  Future<bool> clearProgress() => _prefs.remove(progressKey);
}
