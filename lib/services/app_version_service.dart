import 'package:package_info_plus/package_info_plus.dart';

/// The running build, as the Acerca de rows report it.
class AppVersion {
  const AppVersion({required this.version, required this.buildNumber});

  /// The three-part name — `1.0.0`. This is what a [ReleaseNote] is keyed on.
  final String version;

  /// The build behind it — `versionCode` on Android, `CFBundleVersion` on iOS.
  /// Two builds of the same version differ only here, which is exactly what a
  /// support question needs and what a release note must ignore.
  final String buildNumber;

  String get displayLabel => '$version ($buildNumber)';
}

typedef AppVersionLoader = Future<AppVersion?> Function();

/// Reads the version out of the platform, or null if it cannot be had.
///
/// Null rather than a hard-coded stand-in: the plugin is unavailable in a
/// widget test and on any host without the channel, and a literal written
/// here would go stale the first time the real version moved past it — while
/// still looking authoritative on screen. The rows show a dash instead, and
/// the notes screen simply marks no card as current.
Future<AppVersion?> loadAppVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    return AppVersion(version: info.version, buildNumber: info.buildNumber);
  } on Object {
    return null;
  }
}
