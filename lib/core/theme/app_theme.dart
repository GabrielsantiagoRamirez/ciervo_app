import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_component_styles.dart';
import 'app_radii.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData day() {
    const colorScheme = ColorScheme.light(
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
      onPrimary: Color(0xFF111111),
      onSecondary: AppColors.textPrimary,
      surface: AppColors.daySurface,
      onSurface: AppColors.dayText,
      onSurfaceVariant: AppColors.dayTextMuted,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.dayBackground,
      canvasColor: AppColors.daySurface,
      colorScheme: colorScheme,
      textTheme: const TextTheme(
        displaySmall: AppTextStyles.display,
        headlineMedium: AppTextStyles.headline,
        titleLarge: AppTextStyles.title,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.bodyMuted,
        labelLarge: AppTextStyles.label,
      ).copyWith(
        displaySmall: AppTextStyles.display.copyWith(color: AppColors.dayText),
        headlineMedium: AppTextStyles.headline.copyWith(color: AppColors.dayText),
        titleLarge: AppTextStyles.title.copyWith(color: AppColors.dayText),
        bodyLarge: AppTextStyles.body.copyWith(color: AppColors.dayText),
        bodyMedium: AppTextStyles.body.copyWith(color: AppColors.dayText),
        bodySmall: AppTextStyles.bodyMuted.copyWith(color: AppColors.dayTextMuted),
        labelLarge: AppTextStyles.label.copyWith(color: AppColors.dayText),
      ),
      appBarTheme: AppComponentStyles.appBarTheme(
        AppColors.dayBackground,
        AppColors.dayText,
      ),
      cardTheme: CardThemeData(
        color: AppColors.daySurface,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
      ),
      chipTheme: AppComponentStyles.chipTheme(colorScheme, false),
      inputDecorationTheme: AppComponentStyles.inputDecorationTheme(colorScheme, false),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: AppComponentStyles.primaryButton(colorScheme),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.dayTextMuted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }

  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
      onPrimary: Color(0xFF111111),
      onSecondary: AppColors.textPrimary,
      surface: AppColors.surfaceHigh,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textMuted,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.backgroundAlt,
      colorScheme: colorScheme,
      textTheme: const TextTheme(
        displaySmall: AppTextStyles.display,
        headlineMedium: AppTextStyles.headline,
        titleLarge: AppTextStyles.title,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.bodyMuted,
        labelLarge: AppTextStyles.label,
      ).copyWith(
        displaySmall: AppTextStyles.display.copyWith(color: AppColors.textPrimary),
        headlineMedium: AppTextStyles.headline.copyWith(color: AppColors.textPrimary),
        titleLarge: AppTextStyles.title.copyWith(color: AppColors.textPrimary),
        bodyLarge: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
        bodyMedium: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
        bodySmall: AppTextStyles.bodyMuted.copyWith(color: AppColors.textMuted),
        labelLarge: AppTextStyles.label.copyWith(color: AppColors.textPrimary),
      ),
      appBarTheme: AppComponentStyles.appBarTheme(AppColors.background, AppColors.textPrimary),
      cardTheme: CardThemeData(
        color: AppColors.surfaceHigh,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
      ),
      chipTheme: AppComponentStyles.chipTheme(colorScheme, true),
      inputDecorationTheme: AppComponentStyles.inputDecorationTheme(colorScheme, true),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: AppComponentStyles.primaryButton(colorScheme),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }
}
