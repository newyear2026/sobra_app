# Android WebView feasibility probe

This standalone debug app tests two previously observed public Mercado Libre product URLs. It does not modify or install over Sobrita. Package: `com.sobrita.linkprobe`; Activity: `.ProbeActivity`.

## Build

Run `python3 build_probe.py` from this directory or provide its full path. The script uses the existing Android SDK platform 35, build tools 35.0.0, and Android Studio's bundled JDK. It performs no dependency download. The resulting `sobrita-link-probe-debug.apk` is signed with a local test-only key generated under `build/`; do not use this key or APK for a production release.

## Test behavior

- Android's native `android.webkit.WebView` with its original User-Agent.
- JavaScript and DOM storage enabled; standard WebView cookie behavior. The site may set its own ordinary cookies. No cookie values, login sessions, or storage contents are inspected or exported.
- No shopping API, API keys, imported browser cookies, manual login, user-agent spoofing, proxy, CAPTCHA action or SSL bypass.
- Initial navigation permits only the two hardcoded public product URLs. In-page navigation remains on HTTPS Mercado Libre domains. Other app intents and domains are not launched.
- After page load, read visible product heading, primary product price and rendered product-gallery images through `evaluateJavascript`.
- Version 0.3 targets Android API 36, min API 24. It is compiled using installed platform 35; no new SDK download is needed.
- Only `.ui-pdp-price__second-line .andes-money-amount` can supply the primary price. Generic `.ui-pdp-price .andes-money-amount` candidates are recorded for review but always rejected with `outside_primary_price_row`; they are never a fallback. Previous/list prices and installment contexts are also excluded. Returned candidates include the selector, rejection reason and a short public price context. Multiple differing primary-row amounts yield no accepted price.
- Prices inside `.ui-pdp-variations`, `.ui-pdp-outside_variations` or `.ui-pdp-outside-variations` are rejected as `variant_option_price`, even when their internal markup resembles the main price row. This excludes color-option card prices. Each candidate records up to eight ancestor tag/class pairs and its matching variation-container class, so its context can be verified. The extractor never chooses the first or cheapest amount among conflicting eligible values.
- Image sources: rendered `.ui-pdp-gallery img` / `img.ui-pdp-image`, complete with natural dimensions at least 200×150. Site logos and tiny thumbnails do not qualify.
- Success requires product heading, valid main price, loaded product image, and no detected account/challenge/error page. HTTP 200 alone never indicates success.
- It normally finalizes after two successful observations. Account/challenge pages finalize without interacting. The deadline is 60 seconds.
- The report contains Android/device/WebView version, default UA, navigation URL, main-frame network errors and extraction observations. It does not store complete HTML, cookies, account identifiers or credentials.
- After completion, PixelCopy captures only this test app's own window into a PNG. On PixelCopy failure, the app uses its own view drawing as a fallback.

## Run on an authorized emulator

Use the explicit emulator serial for every adb command. Do not run against an unauthorized physical device.

```sh
adb -s emulator-5556 install -r sobrita-link-probe-debug.apk
adb -s emulator-5556 shell am start -n com.sobrita.linkprobe/.ProbeActivity --es run_id shoe_default
```

The default URL is:

`https://articulo.mercadolibre.com.mx/MLM-3990889244-tenis-adidas-correr-hombre-negro-jq8645-_JM?searchVariation=190036940257`

To test the second URL, pass `--es url` with this exact value and a different run ID:

`https://www.mercadolibre.com.mx/apple-iphone-15-128-gb-azul-distribuidor-autorizado/p/MLM1027172667`

Watch the `SobritaLinkProbe` log tag. Completion writes `files/<run_id>.json`; the PNG follows about 800ms later. A run ID accepts only letters, digits, underscore and hyphen. Reusing a run ID overwrites that run's artifacts in the test app. Separate run IDs preserve separate observations.

```sh
adb -s emulator-5556 exec-out run-as com.sobrita.linkprobe cat files/shoe_default.json > shoe_default.json
adb -s emulator-5556 exec-out run-as com.sobrita.linkprobe cat files/shoe_default.png > shoe_default.png
```

These commands access only this debuggable test app's own files. App-private storage persists between runs unless the test app is explicitly cleared/uninstalled. Reports should identify whether a run started from a fresh install or reused its own prior ordinary browser state.

## Scope

This is a feasibility harness, not production import code. It does not establish universal success across product layouts, selected shoe sizes, price changes, regions, physical devices, share links or WebView versions. Review extracted price/image and the screenshot together before reporting success. Initial displayed price may precede size selection and exclude shipping or coupons.
