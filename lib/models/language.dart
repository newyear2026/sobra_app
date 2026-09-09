import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The languages Sobra ships, plus the option of following the phone.
///
/// A language is always named in itself — somebody looking for "English" in a
/// Spanish UI is looking for the word "English", not "Inglés" — so only the
/// automatic option is a translated string.
enum SobraLanguage {
  automatic(null),
  spanish('es'),
  english('en'),

  /// Korean exists so the person building Sobra can read their own app. It is
  /// gated to debug builds because the pixel font carries no Hangul: the text
  /// falls back to the system face and the typography stops being one thing.
  /// Shipping it is a font decision, not a translation one — lift [shipped]
  /// once there is a Hangul pixel face to set it in.
  korean('ko', shipped: false);

  const SobraLanguage(this.code, {this.shipped = true});

  /// The stored language code, or null for "follow the phone".
  final String? code;

  /// Whether a release build offers this language at all.
  final bool shipped;

  /// The languages this build can actually show.
  static List<SobraLanguage> get available => [
    for (final language in values)
      if (language.shipped || kDebugMode) language,
  ];

  /// The locales this build supports, Spanish first.
  ///
  /// Order is load-bearing: Flutter falls back to the head of the list, and a
  /// phone set to none of these should land on Sobra's own language.
  static List<Locale> get supportedLocales => [
    for (final language in available)
      if (language.code != null) Locale(language.code!),
  ];

  /// Reads a stored code, ignoring one this build cannot show.
  ///
  /// A code saved by a debug build survives in the data after a release build
  /// drops that language. Falling back to [automatic] keeps the picker and the
  /// screen saying the same thing.
  static SobraLanguage fromCode(String? code) => available.firstWhere(
    (value) => value.code == code,
    orElse: () => automatic,
  );
}
