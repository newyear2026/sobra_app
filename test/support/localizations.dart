import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';

/// What `SobraApp` installs, so a test that renders one screen resolves text
/// the same way the running app does.
///
/// A widget that looks up [AppLocalizations] throws without these, which is
/// the failure mode a test harness should not have to rediscover.
const sobraLocalizationsDelegates = <LocalizationsDelegate<Object?>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// One locale on purpose: a harness that builds a single screen should not
/// depend on what language the test runner happens to prefer. Tests that pump
/// the whole app go through its own list instead, and pin the device with
/// [useSpanishDevice].
const sobraSupportedLocales = <Locale>[Locale('es', 'MX')];

/// Runs the test as though the phone were set to Mexican Spanish.
///
/// `SobraApp` follows the device unless the user picked a language, and these
/// tests were written against its Spanish copy. Pinning the device keeps them
/// testing behaviour rather than whichever locale the runner defaults to.
void useSpanishDevice(WidgetTester tester) {
  tester.platformDispatcher
    ..localeTestValue = const Locale('es', 'MX')
    ..localesTestValue = const <Locale>[Locale('es', 'MX')];
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
}
