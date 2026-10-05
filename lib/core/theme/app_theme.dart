import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/game_constants.dart';
import 'app_colors.dart';

/// Preschool-friendly theme: chunky rounded shapes and generous padding.
abstract final class AppTheme {
  /// [useGoogleFonts] can be disabled (e.g. in tests) to avoid runtime
  /// font fetching.
  static ThemeData light({bool useGoogleFonts = true}) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.heelerBlue,
        primary: AppColors.heelerBlue,
        secondary: AppColors.bingoOrange,
        tertiary: AppColors.coral,
        surface: AppColors.cream,
      ),
      scaffoldBackgroundColor: AppColors.sandyYellowLight,
    );

    final textTheme = useGoogleFonts
        ? GoogleFonts.fredokaTextTheme(base.textTheme)
        : base.textTheme;

    final roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GameConstants.cornerRadius),
    );

    return base.copyWith(
      textTheme: textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(
            GameConstants.minTouchTarget,
            GameConstants.minTouchTarget,
          ),
          padding: const EdgeInsets.all(GameConstants.spacing),
          shape: roundedShape,
          backgroundColor: AppColors.bingoOrange,
          foregroundColor: AppColors.ink,
          elevation: 4,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(
            GameConstants.minTouchTarget,
            GameConstants.minTouchTarget,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        shape: roundedShape,
        color: AppColors.cream,
        margin: const EdgeInsets.all(GameConstants.spacing),
      ),
    );
  }
}
