# Sobra

Sobra is an offline-first, pixel-art budget companion for Mexico. The v1 app
uses MXN, a quincena budget cycle, manual expense entry, category limits, cash
reconciliation, and five original eight-frame cat animations.

## Run

```sh
flutter pub get
flutter run
```

## Verify

```sh
flutter analyze
flutter test
flutter build web
```

All personal budget data is stored locally with `shared_preferences`. The
settings screen can copy a JSON backup to the clipboard.
