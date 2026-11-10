# Android restart / ANR investigation — 2026-11-09

## Evidence and conclusion

The original input ANR occurred at device time 19:15:24, before an export was
requested. Android waited 5,006 ms for a motion event. The existing process had
been alive for approximately 2 hours 13 minutes.

The saved trace in `../csv-excel-emulator-20261109/anr-traces.txt` shows:

- Native WebView frames on the main thread, reached through the Android looper.
- 11,361 major page faults in the app during the sampled interval.
- 29% system I/O wait and 28% CPU usage in `kswapd0`.
- Memory pressure `some avg10=15.02`, I/O pressure `some avg10=42.29`.
- A Play Store process-start ANR approximately 25 seconds earlier.

This supports severe memory/I/O pressure as a contributing factor. It does not
identify a single faulty application statement or prove that ads alone caused
the ANR. Android's [ANR diagnosis guidance](https://developer.android.com/topic/performance/anrs/diagnose-and-fix-anrs)
distinguishes system overload from app blocking and cautions against treating an
idle/late `nativePollOnce` stack as a precise root cause.

The Mac also had only about 300 MB free at the start of this investigation and
about 8 GB of swap in use. An attempted APK build actually failed with
`No space left on device` (`build.log`). Multiple emulators were running.

## Changes

- Removed unconditional rewarded-ad preloading from app startup. The collection
  already has an entry preload; it now waits for consent readiness before using
  that one preload opportunity. Late consent completion triggers that request,
  while later notifications do not create repeat requests.
- Kept native-ad consent gating and the existing exit-ad behavior intact.
- Added a regression test for delayed consent and a no-fill result, verifying
  zero requests before consent and exactly one afterward.
- Rebooted only the Sobrita test emulator, preserving app data. Removed 416 MB
  of regenerable old profile build outputs and the incomplete native-library
  output from the failed build. Built only the required ARM64 target. Stopped
  this project's confirmed-idle Gradle 8.14 daemon after building.

The ad change reduces avoidable startup work; it is a mitigation, not proof
that the original system-pressure ANR can never recur.

## Automated verification

- 59 tests passed: collection screen, rewarded-ad port, startup (`tests.log`).
- Static analysis of the three changed Dart files: no issues (`analyze.log`).
- ARM64 debug APK built and installed with `adb install -r`, preserving data
  (`build-arm64.log`).

## Device verification notes

Device: `emulator-5554`, Pixel_3 AVD, Android 16, 2 GB guest RAM.

The first post-install launch reached the home screen and the ledger tab.
The first exploratory cold-start loop (`cold-restarts.json`, cold-1 through
cold-3) sampled too early: `am start -W` timed out while the splash was still
visible. These early samples are **not** counted as successful screen tests.
The third process subsequently reached home, captured in
`ready-after-cold-3.png`.

A Flutter hot restart completed in 16,495 ms and reached home
(`hot-restart-ready.png`). Android reported no ANR since the emulator reboot
(`hot-restart-lastanr.txt`). The immediate ledger screenshot was taken before
the tap had rendered and is not counted as a successful ledger check.

Further complete cold-start checks wait for the observed home and selected
ledger navigation colors before recording a result. Their screenshots are
also reviewed visually; the readiness wait is not a performance benchmark.

Cold starts 4 and 5 both reached home and responded to a tap on the ledger tab.
The home-readiness observation waits were 69.49 s and 63.68 s; ledger screen
observation waits were 7.18 s and 6.69 s, including ADB/screenshot overhead.
Both resulting ledger screenshots were visually checked. Neither process logged
a fatal exception or a rewarded preload at startup, and Android continued to
report no ANR since boot (`verified-cold-restarts.json`).

This is functional restart verification, **not** a passing startup-performance
benchmark. Slow debug cold launch remains observable in the constrained emulator
environment. A controlled release/profile run on a physical device or an idle
host would be needed to evaluate real startup performance independently.

An additional ARM64 profile build also reached home and the ledger without a
new ANR or fatal exception (`profile-cold-restarts.json`). Its observation waits
were 52.30 s to home and 11.15 s for the ledger. The slow launch therefore cannot
be attributed exclusively to Dart debug mode. This was one run on the same
loaded emulator host, not a controlled before/after benchmark. The profile
build used test ads and was replaced with the debug build after the comparison.

## Export regression check

After the restart checks, both CSV and XLSX were actually selected in the debug
app. Android's native share UI showed each correct filename (`csv-share.xml`,
`xlsx-share.xml`). The pulled files `final.csv` and `final.xlsx` matched all eight
pre-test ledger rows. XLSX amounts were numeric, notes were text, and there were
no formula cells (`file-validation.json`, `verify_exports.py`).

All persisted state keys were compared before and after the debug checks. Only
the expected native-ad impression timestamp changed; transactions, incomes,
currency, language, budgets, schedules and room selections were preserved
(`state-preservation.json`). No share recipient was selected.

After the profile comparison and debug restoration, existing persisted fields
again matched except for the native-ad impression timestamp. The concurrently
updated savings-goal implementation had added four empty-list defaults during
the profile run; these are recorded separately in
`final-state-preservation.json`. No existing financial records or preferences
were altered.

Remaining investigation: isolate host contention by running Sobrita alone.
The other two emulators belong to RandomFocus and Loopet, so permission was
requested before terminating them. They were left running while awaiting the
answer. The original ANR's exact causal code path remains unproven; the slow
startup observation remains an open performance issue.

At the end, the Loopet emulator had exited independently; RandomFocus remained
running. No other project's emulator was terminated by this investigation.
The restored debug app reached home (`restored-debug-home.png`), and the final
Android ANR report still contained no ANR since reboot (`final-lastanr.txt`).
