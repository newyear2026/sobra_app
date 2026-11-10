# Walmart manual-verification WebView diagnostic

Independent package `com.sobrita.walmartmanual`, Activity `.ProbeActivity`, v0.1, min SDK 24 / target SDK 36. Default Android WebView user agent, JavaScript and DOM storage enabled, normal cookie state retained. No official API, login automation, security-prompt interaction, or bypass. APK was built offline; device installation and execution belong to the parent task.

Opening the app loads the public product page and leaves security verification to the user. No automatic extraction occurs. The native button **보안 확인 후 정보 읽기** or an `action=inspect` intent collects two snapshots two seconds apart without reloading the WebView. Security/auth screens yield only URL path, title, and short status; their body or puzzle text is never inspected. Public product pages yield diagnostic DOM candidates, not a claim that the primary price/photo were correctly extracted.

Example commands (parent operator only):

```sh
ADB=/Users/jaewook/Library/Android/sdk/platform-tools/adb
"$ADB" -s emulator-5554 install -r output/android-walmart-manual-verification-20261109/sobrita-walmart-manual-debug.apk
"$ADB" -s emulator-5554 shell am start -n com.sobrita.walmartmanual/.ProbeActivity --es run_id walmart_manual_open --es url https://www.walmart.com.mx/ip/audifonos-inalambricos-apple-airpods-4-blancos/00019594968846
"$ADB" -s emulator-5554 shell am start -n com.sobrita.walmartmanual/.ProbeActivity --es action inspect --es run_id walmart_before_manual
python3 output/android-walmart-manual-verification-20261109/collect_result.py walmart_before_manual
```

The `inspect` intent must target the existing Activity. Do not force-stop, relaunch with the normal action, clear data/cookies, or reinstall while preserving the user's active verification session. The collector accepts an optional second argument for device serial; its default is `emulator-5554`.

`manualVerificationCompleted` defaults to JSON null (unknown). The button and `action=inspect` do not establish that verification was completed. Only after explicit user confirmation may the operator add `--ez user_confirmed_verification true`; this remains user-provided evidence, not an automatic inference.

For a necessary extraction-selector correction after verification, the operator can place a controlled, pure public-DOM diagnostic script in the package's private `files/extract-override.js` with `adb exec-in run-as com.sobrita.walmartmanual sh -c 'cat > files/extract-override.js' < <reviewed-script-path>`. Each inspection reads that override if present, otherwise the bundled asset, and records `extractorOverrideUsed`. Override scripts must preserve challenge/auth refusal and never manipulate the page or inspect cookies, storage, login data, or private application globals. No reload or reinstall is needed.

Outputs are app-private `files/<run_id>.json` and `.png`; use unique run IDs. Both are written to temporary files and atomically renamed. PNG captures only this Activity's window using PixelCopy with a view-draw fallback. The collector requires complete PNG magic and terminal IEND bytes before saving. It prints compact metadata and candidate counts. Android and the current WebView version are recorded at runtime; results apply only to that actual environment.

Build again with `python3 output/android-walmart-manual-verification-20261109/build_probe.py`. This directory is the only task-owned source output; earlier test harnesses and the production app are preserved.

Walmart diagnostics prioritize the exact `[data-testid="price-wrap"] [data-seo-id="hero-price"][itemprop="price"]` selector and `#hero-image-default-0`. Other price candidates are explicitly excluded from primary selection; hero image candidates record loading, dimensions, visibility, and metadata matches. No fixed product price is embedded. Main-frame navigation stays on HTTPS walmart.com.mx and its subdomains; ordinary HTTPS subframes can load normally. Security/authentication pages are guarded before reading product content.
