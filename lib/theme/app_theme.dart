import 'package:flutter/material.dart';

/// SkillSwap brand: soft lavender surfaces with a purple -> blue gradient.
class Brand {
  Brand._();
  static const primary = Color(0xFF7C6BF0);
  static const purple = Color(0xFF9B4DF5);
  static const blue = Color(0xFF3B82F6);
  static const ink = Color(0xFF1E1B3A);
  static const lavender = Color(0xFFEEEBFF);
  static const page = Color(0xFFF7F5FF);
  static const border = Color(0xFFD5D2E6);
  static const gradient = LinearGradient(
    colors: [purple, blue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

ThemeData buildAppTheme() {
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Brand.primary),
    scaffoldBackgroundColor: Brand.page,
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(0, 48), shape: shape),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48), shape: shape),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Brand.lavender,
      surfaceTintColor: Colors.transparent,
    ),
  );
}

/// Rounded, white, outlined text field used on the auth and profile screens.
InputDecoration fieldDecoration({
  String? label,
  String? hint,
  Widget? suffix,
  bool alignLabelWithHint = false,
}) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    suffixIcon: suffix,
    alignLabelWithHint: alignLabelWithHint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: border(Brand.border),
    enabledBorder: border(Brand.border),
    focusedBorder: border(Brand.primary, 1.6),
    errorBorder: border(Colors.red.shade400),
    focusedErrorBorder: border(Colors.red.shade400, 1.6),
  );
}
