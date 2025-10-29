import 'package:flutter/material.dart';
import 'tokens.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTokens.primary500,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppTokens.surface,
      textTheme: TextTheme(
        displaySmall: const TextStyle(
          fontSize: AppTokens.fsDisplay,
          height: 40 / AppTokens.fsDisplay,
          fontWeight: FontWeight.w600,
          color: AppTokens.textPrimary,
        ),
        headlineLarge: const TextStyle(
          fontSize: AppTokens.fsH1,
          height: 32 / AppTokens.fsH1,
          fontWeight: FontWeight.w600,
          color: AppTokens.textPrimary,
        ),
        headlineMedium: const TextStyle(
          fontSize: AppTokens.fsH2,
          height: 28 / AppTokens.fsH2,
          fontWeight: FontWeight.w600,
          color: AppTokens.textPrimary,
        ),
        headlineSmall: const TextStyle(
          fontSize: AppTokens.fsH3,
          height: 26 / AppTokens.fsH3,
          fontWeight: FontWeight.w600,
          color: AppTokens.textPrimary,
        ),
        bodyLarge: const TextStyle(
          fontSize: AppTokens.fsBody,
          height: 24 / AppTokens.fsBody,
          fontWeight: FontWeight.w400,
          color: AppTokens.textPrimary,
        ),
        bodyMedium: const TextStyle(
          fontSize: AppTokens.fsSmall,
          height: 20 / AppTokens.fsSmall,
          fontWeight: FontWeight.w400,
          color: AppTokens.textSecondary,
        ),
        labelSmall: const TextStyle(
          fontSize: 12,
          height: 16 / 12,
          color: AppTokens.textSecondary,
        ),
      ),
      dividerColor: AppTokens.border,
    );
  }

  static ThemeData dark() {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    const textPrimary = Color(0xFFE5E7EB);
    const textSecondary = Color(0xFF9CA3AF);
    const surface = Color(0xFF0B0F14);
    const surfaceVariant = Color(0xFF111827);
    const border = Color(0xFF1F2937);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTokens.primary500,
        brightness: Brightness.dark,
      ).copyWith(
        surface: surface,
        surfaceVariant: surfaceVariant,
      ),
      scaffoldBackgroundColor: surface,
      textTheme: TextTheme(
        displaySmall: const TextStyle(
          fontSize: AppTokens.fsDisplay,
          height: 40 / AppTokens.fsDisplay,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineLarge: const TextStyle(
          fontSize: AppTokens.fsH1,
          height: 32 / AppTokens.fsH1,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: const TextStyle(
          fontSize: AppTokens.fsH2,
          height: 28 / AppTokens.fsH2,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: const TextStyle(
          fontSize: AppTokens.fsH3,
          height: 26 / AppTokens.fsH3,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: const TextStyle(
          fontSize: AppTokens.fsBody,
          height: 24 / AppTokens.fsBody,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: const TextStyle(
          fontSize: AppTokens.fsSmall,
          height: 20 / AppTokens.fsSmall,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelSmall: const TextStyle(
          fontSize: 12,
          height: 16 / 12,
          color: textSecondary,
        ),
      ),
      dividerColor: border,
    );
  }
}
