# Seamless cat loading loop — 2026-11-09

The original deposit and proud pause now lead into a coin-retrieval gesture.
The cat lowers a paw, brings a new coin from beside its body, then raises it
toward the jar. The final pose uses exactly the original first pose's pixels,
so the cycle boundary does not reset to a different pose. The cycle has 20
displayed frames and lasts 3400ms. Startup readiness still ends it immediately.

## Assets and generation

- Tool: built-in `image_gen`, transparent RGBA edit with the existing atlas and
  two approved endpoint screenshots as references. No fallback CLI was used.
- Source art: `design/startup/coin-reset-bridge-v1.png`.
- Full final prompt: `design/startup/coin-reset-bridge-prompt.txt`.
- Prompt intent: preserve the approved navy cat and mint jar; create eight
  return poses from the empty-pawed proud pose to the initial coin-holding pose.
  Keep the jar/feet registered and never reverse the coin out of the jar.
- The build uses seven new poses and the exact original first pose as the eighth.
- Production atlas: `assets/startup/coin-loop-native.png` (4 columns × 5 rows).
- `python3 tool/build_startup_drawables.py` registers the exported cells, builds
  the shared palette atlas and native vector, and generates both Flutter's
  `lib/widgets/coin_loading_timeline.dart` and Android's duration resource.
  The generator asserts exact first/last pixel equality.

Original illustrations remain available. Export registration adjusts only the
new cells' scale/placement; new pose artwork comes from the image-generation tool.

## Verification

- Startup and welcome widget tests: 20 passed, including identical decoded
  first/last pose pixels, repeated playback, immediate ready/error handoff,
  retry, reduced motion and responsive layouts.
- Focused Flutter analysis: no issues.
- Android arm64 debug APK build: passed.
- Generated XML: all 20 animators repeat on the same 3400ms timeline.
- `git diff --check`: passed.
- Android API 36 emulator: multiple complete cycles, retrieval gesture and
  normal welcome destination observed. No Flutter unhandled exception or fatal
  app crash was found in the captured app log.

## Evidence

- `native-launch.mp4`: original emulator recording.
- `seamless-loop.mp4`: original-speed excerpt from 1.2 to 13.2 seconds, showing
  the loading motion and transition to welcome on this fresh test installation.
- `native-poses.png`: sampled playback poses.
- `after-launch.png`: normal destination.
- `app-logcat.txt`: captured app log.
- `sobrita-seamless-startup-arm64-debug.apk`: verified debug build.

This is emulator behavior verification, not release startup benchmarking.
Physical devices and iOS were not runtime-tested for this change.
