import 'package:flutter/material.dart';

/// Sobra's colour tokens.
///
/// Every accent that can sit on its own soft tint has a matching `*Ink`
/// variant. The plain accent is for fills, borders and icons; the `Ink`
/// variant is the only one allowed for text on that tint, because the plain
/// one does not reach 4.5:1 there.
abstract final class AppColors {
  // Grounds.
  static const paper = Color(0xFFF6EFE0);
  static const paperLight = Color(0xFFFBF5E9);
  static const surface = Color(0xFFFFFDF7);
  static const beige = Color(0xFFEFE7D6);
  static const line = Color(0xFFE7DDC8);

  // Ink scale. On surface: 14.2 : 6.9 : 5.4.
  static const ink = Color(0xFF202848);
  static const inkSoft = Color(0xFF4E5878);
  static const muted = Color(0xFF5F6885);

  // Accents. `Ink` variants reach 4.5:1 on their own soft tint.
  static const teal = Color(0xFF0E7A72);
  static const tealSoft = Color(0xFFD8EDEA);
  static const tealInk = Color(0xFF0B6660);
  static const cash = Color(0xFFC0873A);
  static const cashSoft = Color(0xFFF7E9CE);
  static const cashInk = Color(0xFF845A1E);
  static const danger = Color(0xFFD4553F);
  static const dangerSoft = Color(0xFFFBE1DA);
  static const dangerInk = Color(0xFFA63A25);

  // Category accents.
  static const blue = Color(0xFF39558E);
  static const blueSoft = Color(0xFFDCE4F2);
  static const violet = Color(0xFF6E4A8C);
  static const violetSoft = Color(0xFFE7DCF0);
  static const green = Color(0xFF4F7B52);
  static const rose = Color(0xFFB74769);
  static const indigo = Color(0xFF4F5FA3);
  static const plum = Color(0xFF854D7E);
  static const slate = Color(0xFF596174);
}

/// Typography tokens.
///
/// PixelifySans is a *variable* font with a `wght` axis of 400–700 and no
/// static faces. Flutter does not map [TextStyle.fontWeight] onto a variable
/// axis, so weight has to travel through [TextStyle.fontVariations] instead —
/// setting `fontWeight` alone leaves every level rendering at 400.
///
/// Only two weights exist: [regular] and [bold]. There is no w800/w900 in the
/// font, so hierarchy comes from size and from the ink scale, not from more
/// weight steps. Nothing goes below [minFontSize]; the glyphs are a pixel grid
/// and they fall apart under it.
abstract final class AppType {
  static const family = 'PixelifySans';
  static const minFontSize = 12.0;

  static const regular = <FontVariation>[FontVariation('wght', 400)];
  static const bold = <FontVariation>[FontVariation('wght', 700)];
}

/// A [TextStyle] on the Sobra type ramp.
///
/// Prefer `Theme.of(context).textTheme` where a named level fits; use this for
/// one-off sizes so the weight still goes through the variable axis.
TextStyle pixelText({
  required double size,
  bool bold = false,
  Color color = AppColors.ink,
  double? height,
}) => TextStyle(
  fontFamily: AppType.family,
  fontSize: size < AppType.minFontSize ? AppType.minFontSize : size,
  fontVariations: bold ? AppType.bold : AppType.regular,
  color: color,
  height: height,
  letterSpacing: 0,
);

const _shape = RoundedRectangleBorder(borderRadius: BorderRadius.zero);

ThemeData buildSobraTheme() {
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: AppColors.ink, width: 2.5),
  );

  final textTheme = TextTheme(
    displayLarge: pixelText(size: 46, bold: true),
    displayMedium: pixelText(size: 38, bold: true),
    displaySmall: pixelText(size: 32, bold: true),
    headlineLarge: pixelText(size: 30, bold: true),
    headlineMedium: pixelText(size: 28, bold: true),
    headlineSmall: pixelText(size: 24, bold: true),
    titleLarge: pixelText(size: 20, bold: true),
    titleMedium: pixelText(size: 17, bold: true),
    titleSmall: pixelText(size: 15, bold: true),
    bodyLarge: pixelText(size: 15, height: 1.4),
    bodyMedium: pixelText(size: 14, color: AppColors.inkSoft, height: 1.45),
    bodySmall: pixelText(size: 12, color: AppColors.muted, height: 1.45),
    labelLarge: pixelText(size: 16, bold: true),
    labelMedium: pixelText(size: 13, bold: true),
    labelSmall: pixelText(size: 12, bold: true, color: AppColors.muted),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      brightness: Brightness.light,
      surface: AppColors.surface,
      error: AppColors.danger,
      primary: AppColors.teal,
      onPrimary: Colors.white,
      secondary: AppColors.cash,
      outline: AppColors.ink,
    ),
    fontFamily: AppType.family,
    textTheme: textTheme,

    // The pixel language has no ripple: a press moves the surface down onto
    // its own drop shadow instead of spreading a circle across it.
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: border,
      enabledBorder: border,
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.teal, width: 3),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.danger, width: 3),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.danger, width: 3),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: pixelText(size: 14, color: AppColors.muted),
      floatingLabelStyle: pixelText(
        size: 13,
        bold: true,
        color: AppColors.teal,
      ),
      hintStyle: pixelText(size: 14, color: AppColors.muted),
      suffixStyle: pixelText(size: 13, bold: true, color: AppColors.muted),
      errorStyle: pixelText(size: 12, color: AppColors.dangerInk),
    ),

    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),

    // Every Material default below leaks a rounded, elevated surface into a
    // design that is square-cornered and flat everywhere else.
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: _shape,
        foregroundColor: AppColors.tealInk,
        textStyle: pixelText(size: 14, bold: true),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: _shape,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        disabledForegroundColor: AppColors.muted,
        side: const BorderSide(color: AppColors.ink, width: 2.5),
        textStyle: pixelText(size: 15, bold: true),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.ink, width: 2.5),
        ),
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.line,
        disabledForegroundColor: AppColors.muted,
        textStyle: pixelText(size: 15, bold: true),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(_shape),
        side: const WidgetStatePropertyAll(
          BorderSide(color: AppColors.ink, width: 2.5),
        ),
        textStyle: WidgetStatePropertyAll(pixelText(size: 14, bold: true)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.tealSoft
              : AppColors.surface,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.tealInk
              : AppColors.ink,
        ),
        iconColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.tealInk
              : AppColors.ink,
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.ink, width: 3),
      ),
      titleTextStyle: pixelText(size: 19, bold: true),
      contentTextStyle: pixelText(size: 14, color: AppColors.inkSoft),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.ink, width: 3),
      ),
      headerBackgroundColor: AppColors.teal,
      headerForegroundColor: Colors.white,
      dayShape: const WidgetStatePropertyAll(_shape),
      todayBorder: const BorderSide(color: AppColors.teal, width: 2.5),
      headerHeadlineStyle: pixelText(size: 28, bold: true, color: Colors.white),
      headerHelpStyle: pixelText(size: 13, bold: true, color: Colors.white),
      dayStyle: pixelText(size: 14),
      yearStyle: pixelText(size: 15, bold: true),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.ink, width: 2.5),
      ),
      textStyle: pixelText(size: 14, bold: true),
    ),
    menuTheme: const MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.surface),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: AppColors.ink, width: 2.5),
          ),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.ink, width: 2.5),
      ),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.tealSoft,
      checkmarkColor: AppColors.tealInk,
      showCheckmark: false,
      side: const BorderSide(color: AppColors.ink, width: 2.5),
      labelStyle: pixelText(size: 14, bold: true),
      secondaryLabelStyle: pixelText(
        size: 14,
        bold: true,
        color: AppColors.tealInk,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.white
            : AppColors.surface,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.teal
            : AppColors.line,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(AppColors.ink),
      trackOutlineWidth: const WidgetStatePropertyAll(2.5),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.ink, width: 3),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: pixelText(size: 14, color: Colors.white),
      actionTextColor: AppColors.tealSoft,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: const Border.fromBorderSide(
        BorderSide(color: AppColors.ink, width: 2),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: const BoxDecoration(
        color: AppColors.ink,
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.ink, width: 2),
        ),
      ),
      textStyle: pixelText(size: 12, color: Colors.white),
    ),
  );
}
