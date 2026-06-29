import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

abstract final class AppComponentStyles {
  static ButtonStyle primaryButton(ColorScheme colorScheme) =>
      ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        textStyle: AppTextStyles.label,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: const StadiumBorder(),
      );

  static ButtonStyle secondaryButton(ColorScheme colorScheme) =>
      ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        textStyle: AppTextStyles.label,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: const StadiumBorder(),
      );

  static ButtonStyle dangerButton(ColorScheme colorScheme) =>
      ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.error.withValues(alpha: 0.14),
        foregroundColor: AppColors.error,
        textStyle: AppTextStyles.label,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: const StadiumBorder(),
      );

  static InputDecorationTheme inputDecorationTheme(
    ColorScheme colorScheme,
    bool isDark,
  ) => InputDecorationTheme(
    filled: true,
    fillColor: colorScheme.surface,
    hintStyle: AppTextStyles.bodyMuted.copyWith(
      color: colorScheme.onSurfaceVariant,
    ),
    prefixIconColor: colorScheme.onSurfaceVariant,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    border: const OutlineInputBorder(
      borderRadius: AppRadii.input,
      borderSide: BorderSide.none,
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: AppRadii.input,
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AppRadii.input,
      borderSide: BorderSide(
        color: colorScheme.primary.withValues(alpha: 0.65),
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: AppRadii.input,
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: AppRadii.input,
      borderSide: const BorderSide(color: AppColors.error),
    ),
  );

  static ChipThemeData chipTheme(ColorScheme colorScheme, bool isDark) =>
      ChipThemeData(
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.primary,
        disabledColor: AppColors.surfaceLow,
        labelStyle: AppTextStyles.label.copyWith(
          fontSize: 13,
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: AppTextStyles.label.copyWith(
          fontSize: 13,
          color: colorScheme.onPrimary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: const StadiumBorder(),
        side: BorderSide.none,
        brightness: isDark ? Brightness.dark : Brightness.light,
      );

  static AppBarTheme appBarTheme(Color bg, Color fg) => AppBarTheme(
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: bg,
    foregroundColor: fg,
    iconTheme: IconThemeData(color: fg),
    titleTextStyle: AppTextStyles.title.copyWith(color: fg),
  );

  static BoxDecoration cardDecoration(Color surfaceColor, bool isDark) =>
      BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadii.card,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowWarm,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      );

  static BoxDecoration bottomNavigationSurface(
    ColorScheme colorScheme,
    bool isDark,
  ) => BoxDecoration(
    color: colorScheme.surface,
    border: Border.all(
      color: colorScheme.outlineVariant.withValues(alpha: 0.45),
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowWarm.withValues(alpha: 0.24),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );

  static LinearGradient cardOverlayGradient = const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.overlayGradientStart, AppColors.overlayGradientEnd],
  );
}
