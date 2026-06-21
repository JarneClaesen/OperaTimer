import 'package:flutter/material.dart';

/// Central design system for OperaTimer, built in the spirit of Google's
/// Material 3 Expressive language: vibrant tonal color, bold emphasized
/// typography, large and varied rounded shapes, prominent containment, and
/// generous spacing.
///
/// Flutter's framework does not yet ship the M3 Expressive *components*
/// (button groups, FAB menus, the expressive loading indicator, motion-physics,
/// etc.), so this expresses the language with stable Material 3 APIs:
///   * the real `DynamicSchemeVariant.expressive` color algorithm,
///   * an emphasized type scale (heavier weights, tighter display tracking),
///   * a shared shape scale skewed toward large/extra-large rounding,
///   * stadium-shaped buttons and rounded FABs.
class AppTheme {
  AppTheme._();

  // --- Shape scale -----------------------------------------------------------
  // Expressive leans on large, friendly corners. These are the radii used
  // across the app so every surface feels part of one family.
  static const double radiusXs = 12;
  static const double radiusSm = 16;
  static const double radiusMd = 20;
  static const double radiusLg = 28;
  static const double radiusXl = 36;

  // Declared const (via BorderRadius.all + Radius.circular, both const) so they
  // can be used inside const widget expressions throughout the app.
  static const BorderRadius brSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(radiusXl));

  static const RoundedRectangleBorder shapeMd =
      RoundedRectangleBorder(borderRadius: brMd);
  static const RoundedRectangleBorder shapeLg =
      RoundedRectangleBorder(borderRadius: brLg);
  static const RoundedRectangleBorder shapeXl =
      RoundedRectangleBorder(borderRadius: brXl);

  // --- Semantic accents ------------------------------------------------------
  // The timer's two live states. Kept vivid and consistent everywhere they
  // appear (timeline nodes, glowing borders, status chips, floating timer).
  static const Color warningColor = Color(0xFFFFB300); // amber 600
  static const Color warningOn = Color(0xFF3E2D00);
  static const Color playTimeColor = Color(0xFF34C759); // vivid green
  static const Color playTimeOn = Color(0xFF06320F);

  // --- Themes ----------------------------------------------------------------
  static ThemeData dark(Color seed) => _build(seed, Brightness.dark);
  static ThemeData light(Color seed) => _build(seed, Brightness.light);

  static ThemeData _build(Color seed, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      // `vibrant` keeps the PRIMARY anchored to the chosen seed hue while
      // pushing chroma for an energetic, expressive palette. (The `expressive`
      // variant deliberately rotates the primary hue away from the seed — e.g.
      // a burgundy seed comes out blue — which isn't what we want when the user
      // has explicitly picked an app colour.)
      dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
    );

    final textTheme = _emphasizedTextTheme(brightness);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,

      // Buttons: tall, pill-shaped, with emphasized labels — the expressive
      // "big friendly target" feel.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: const StadiumBorder(),
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),

      // FABs use a large rounded-rectangle (squircle-ish) instead of a circle,
      // matching the expressive shape language.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: shapeLg,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
        extendedTextStyle:
            textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: shapeMd,
        insetPadding: const EdgeInsets.all(16),
      ),
    );
  }

  /// An emphasized take on the M3 type scale: display/headline/title styles are
  /// bolder and the big numerals are tightly tracked, which is the hallmark of
  /// expressive typography.
  static TextTheme _emphasizedTextTheme(Brightness brightness) {
    final base = (brightness == Brightness.dark
            ? ThemeData.dark(useMaterial3: true)
            : ThemeData.light(useMaterial3: true))
        .textTheme;
    return base.copyWith(
      displayLarge: base.displayLarge
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1.5),
      displayMedium: base.displayMedium
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1),
      displaySmall: base.displaySmall
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineLarge: base.headlineLarge
          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineMedium:
          base.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
