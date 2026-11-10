# Amazon México / Walmart México — Android WebView diagnostic

Independent native test APK: `sobrita-shop-probe-debug.apk`; package `com.sobrita.shopprobe`; Activity `.ProbeActivity`; target API 36, min API 24. Sobrita and prior diagnostic projects are unchanged.

## Version 0.4 refinement — current test

Version 0.3 rejected a loaded canonical MAIN image measuring 337×142 because its arbitrary minimum height was 150. Version 0.4 keeps the same named primary-image and explicit MAIN-gallery selection, but tests image loading with HTTPS source, `complete`, and positive `naturalWidth` and `naturalHeight`. There is no arbitrary minimum-resolution gate. This establishes that the chosen product image loaded, not that it is high resolution or suitable for enlargement. Record the measured dimensions and review the actual screenshot separately.

Version 0.2 missed some mobile title/image elements; version 0.3 also excluded the small loaded image described above. Earlier run records remain as failure evidence. Final report runs are `amazon1_v4` and `amazon2_v4`; Walmart continues to use the already-recorded `walmart_diagnostic` challenge result and is not retried.

## Version 0.3 refinement — historical

Version 0.2 is preserved in `assets/extract-v2.js` and `sobrita-shop-probe-v2.apk`.

The product title uses visible `#productTitle` when available; otherwise it uses the actual document title with the official Amazon marketplace suffix removed. `productTitleSource` identifies which source supplied the value. Visible h1 elements also record ID/class/text and ancestor provenance.

The primary image test distinguishes **loaded DOM image** from **CSS visibility**. Only named primary images or images in explicit MAIN-gallery containers qualify; a completed HTTPS image with natural dimensions at least 200×150 can be read even if CSS visibility/layout differs. Named `#main-image` has priority over `#landingImage`, then the explicit MAIN wrapper. Differing URLs within the chosen group remain unconfirmed. `mainImageDiagnostics` records source URL, completion, natural size, element style/layout, ancestor styles and gallery membership. No webpage style is altered.

For visibility diagnostics, element-computed visibility is inspected; ancestor `visibility:hidden` alone is not treated as conclusive because a child can override it. Ancestor `display:none` and hidden attributes remain exclusions from the separate visibility check. The native status now reads **LOADED PHOTO + PRICE**, and the report uses `loaded_primary_gallery_dom` so that an image download is not conflated with a fully visible UI state. Parent tests review the screenshot separately.

## Version 0.2 refinement

The original candidate-only JavaScript is preserved as `assets/extract-diagnostic.js`, and the original signed APK as `sobrita-shop-probe-diagnostic.apk`.

Amazon extraction now reads only `.apex-pricetopay-value` in explicit main-price containers, including the observed `#corePriceDisplay_mobile_feature_div`. Integer/fraction text must form a positive amount; associated `.a-offscreen` price text, if present, must agree. Reference, installment and option/swatch contexts are excluded. All remaining eligible main-price amounts must agree; no first-or-cheapest rule is used.

Product title comes from `#productTitle`. A loaded visible `img#main-image` or `img#landingImage` must belong to a known primary image-gallery container; it must have natural dimensions at least 200×150. Multiple differing primary-image URLs remain unconfirmed. The price, image URL and title must match across two observations before native completion reports extraction success. Native status and the saved screenshot show the extracted amount and image dimensions.

Currency is explicitly **inferred as MXN from amazon.com.mx**, not claimed as an independently extracted structured currency field. No fixed product price or image fixture is used.

Walmart remains diagnostic-only. The observed identity-verification/challenge route is recorded without retrying or interacting. `extractionConfirmed` stays false for Walmart. The collector prints compact result values and candidate counts; full diagnostic evidence remains in the saved JSON.

## Build and run

`python3 build_probe.py` builds/signs offline with the installed Android SDK and JDK. This is a local debug key and APK, not a production release.

```sh
adb -s emulator-5556 install -r sobrita-shop-probe-debug.apk
adb -s emulator-5556 shell am start -n com.sobrita.shopprobe/.ProbeActivity --es run_id amazon1_default
```

The default URL is `https://www.amazon.com.mx/adidas-Tenis-Hombre-Casual-Negro/dp/B0DHZVB27Q`.

Pass `--es url` for either additional sample:

- `https://www.amazon.com.mx/dp/B0F1X7M849`
- `https://www.walmart.com.mx/ip/audifonos-inalambricos-apple-airpods-4-blancos/00019594968846`

Only HTTPS Amazon México/Walmart México hosts and product paths are allowed initially. Normal navigation stays on their respective domains/subdomains. No short-link test or auth flow is performed.

`python3 collect_result.py <run_id>` reads only this test package's own JSON/PNG from emulator-5556 into `results/`. It polls at most 40 seconds. It does not install, launch, clear or change the test app. Use unique run IDs to preserve observations.

## Method

- Native Android WebView, original User-Agent, JavaScript and DOM storage enabled, ordinary cookie behavior.
- No API client/key, login, imported cookies, cookie/storage inspection, private JS globals, proxy, UA spoofing, CAPTCHA solving or SSL override.
- Rendered DOM evidence includes h1/productTitle, title, selected Open Graph/price metadata, Product JSON-LD summaries, current-page price candidates with nearby text and ancestor classes, loaded large image candidates, and the first 14,000 characters of visible body text.
- Amazon main-price locations and representative image IDs are prioritized as candidates. Walmart hero-price markup, JSON-LD Product data, and `img#hero-image-default-0` are prioritized. The generic visibility-based diagnostic candidates are distinct from the current named primary-gallery extraction, which can confirm loaded images even when CSS hides them. These priorities do not by themselves assert correctness.
- Candidate collection occurs 2.5 seconds after page completion and at 8/16/28 seconds; final deadline 30 seconds.
- Detected login, visible security challenge, denied page title, or CAPTCHA route ends the run without interaction. Challenge detection uses visible UI/title/URL; arbitrary script contents mentioning CAPTCHA are not scanned.
- Candidate-only completion is **DIAGNOSTIC COMPLETE**. The current native status is **LOADED PHOTO + PRICE** only for Amazon after the current checks and two matching observations described above. Selected options, inferred currency, loaded image dimensions, and screenshot still require review before applying the data to a savings goal.
- JSON records Android/WebView versions, main-frame errors and observations. A PNG of this test app's own window is saved about 800ms after completion.

Log tag: `SobritaShopProbe`. App-private outputs: `files/<run_id>.json` and `files/<run_id>.png`. The default app state can retain its own ordinary site cookies between runs; reports should state whether each run was cold or reused that state.
