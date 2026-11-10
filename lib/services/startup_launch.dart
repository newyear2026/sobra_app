import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The system icon's real geometry, so OEM insets/density don't move the cat.
class StartupLaunchState {
  const StartupLaunchState({required this.bounds, this.startedAt});

  final Rect bounds;
  final DateTime? startedAt;
}

class StartupLaunch {
  static const channel = MethodChannel('com.sobra.app/startup');

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<StartupLaunchState?> read() async {
    if (!_supported) return null;
    try {
      final data = await channel.invokeMapMethod<String, dynamic>('read');
      if (data == null) return null;
      final x = data['centerX'] as num?;
      final y = data['centerY'] as num?;
      final size = data['size'] as num?;
      if (x == null || y == null || size == null || size <= 0) return null;
      final startedAt = data['startedAt'] as num?;
      return StartupLaunchState(
        bounds: Rect.fromCenter(
          center: Offset(x.toDouble(), y.toDouble()),
          width: size.toDouble(),
          height: size.toDouble(),
        ),
        startedAt: startedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(startedAt.toInt()),
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<void> release() async {
    if (!_supported) return;
    try {
      await channel.invokeMethod<void>('release');
    } on MissingPluginException {
      // Web, desktop and older installed native builds use the Flutter screen.
    } on PlatformException {
      // Native launch decoration must not break the ready app or retry UI.
    }
  }
}
