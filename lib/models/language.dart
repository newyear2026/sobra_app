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

  /// Korean was gated to debug builds for as long as there was no Hangul to
  /// set it in: Pixelify Sans carries none, so the text fell back to the
  /// system face and the typography stopped being one thing. It ships now
  /// because `AppType.fallback` names a pixel Hangul face sized to Sobra's
  /// own — see `tool/build_hangul_fallback.py`. The translation was never what
  /// held it back.
  korean('ko');

  // Nothing passes `shipped` today; see the field for why it stays.
  // ignore: unused_element_parameter
  const SobraLanguage(this.code, {this.shipped = true});

  /// The stored language code, or null for "follow the phone".
  final String? code;

  /// Whether a release build offers this language at all.
  ///
  /// Nothing sets it false today — Korean was the last to need it. It stays
  /// because the next language will arrive translated before it is ready to
  /// be seen, and this is where that waiting happens.
  final bool shipped;

  /// The languages this build can actually show.
  static List<SobraLanguage> get available => [
    for (final language in values)
      if (language.shipped || kDebugMode) language,
  ];

  /// The locales this build supports, English first.
  ///
  /// Order is load-bearing: Flutter falls back to the head of the list when a
  /// phone is set to none of these. That phone belongs to somebody spending
  /// euros, reais or yen, who is likelier to read English than Spanish. A
  /// Spanish phone of any country still matches `es` on its own, so Mexico
  /// loses nothing to the order.
  static List<Locale> get supportedLocales => [
    for (final language in [english, ...available.where((l) => l != english)])
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
