# SHEIN Android WebView diagnostic

Standalone native debug app, separate from Sobrita and the previous Mercado Libre probe. Package: `com.sobrita.sheinprobe`, Activity: `.ProbeActivity`, target API 36 / min API 24.

## Build

`python3 build_probe.py` uses the installed SDK/JDK offline and writes `sobrita-shein-probe-debug.apk`. The APK uses a local test-only key and must not be used as a production app.

## Run

```sh
adb -s emulator-5556 install -r sobrita-shein-probe-debug.apk
adb -s emulator-5556 shell am start -n com.sobrita.sheinprobe/.ProbeActivity --es run_id shein_default
```

Default public product URL:

`https://www.shein.com.mx/Women-Long-Dresses-p-568117802.html`

The `url` intent extra permits HTTPS product paths ending `-p-<number>.html` on `shein.com.mx` and its subdomains, `mx.shein.com`, or `m.shein.com`. Other initial URLs are rejected. Normal in-page navigation is limited to HTTPS SHEIN domains.

## Evidence and limits

- Original Android WebView User-Agent; JavaScript and DOM storage enabled, ordinary cookie behavior.
- No shopping API, account login, cookie import/export, proxy, UA spoofing, CAPTCHA action or SSL bypass.
- Public DOM evidence: visible headings, title, selected Open Graph/price metadata, Product JSON-LD summaries, price candidates with local context/ancestor classes, large loaded image candidates, and the first 12,000 characters of rendered body text.
- Cookies, local/session storage, private JavaScript globals and account credentials are not read.
- Login and challenge states, including `/risk/challenge`, are recorded and end collection at the first observation. No challenge is solved.
- Deadline is 25 seconds. Completion means **diagnostic complete**, never automatically means product extraction succeeded. `extractionConfirmed` is always false; candidate evidence requires review.
- JSON includes Android/WebView versions, main-frame errors and observations. PixelCopy captures the test app's own window about 800ms after completion.

Results are `files/<run_id>.json` and `files/<run_id>.png` inside this test app. Log tag: `SobritaSheinProbe`.

```sh
adb -s emulator-5556 exec-out run-as com.sobrita.sheinprobe cat files/shein_default.json > shein_default.json
adb -s emulator-5556 exec-out run-as com.sobrita.sheinprobe cat files/shein_default.png > shein_default.png
```

Reusing a run ID overwrites only that test app's same-named files. Use the explicit emulator serial, not an unauthorized physical device. The separate Mercado Libre probe and main Sobrita app sources were preserved.
