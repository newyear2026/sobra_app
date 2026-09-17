"""Captures the six store screens from the app running on an Android device.

`build_screenshots.py` frames these; this is what produces them, and it exists
so that the next release's listing is a re-run rather than an afternoon.

It drives the app through Flutter's semantics tree rather than through pixel
coordinates. `adb shell uiautomator dump` returns every node Flutter exposes to
Android accessibility, with its label and its bounds, so a button is found by
what it says instead of by where it was the last time someone looked. That
matters here more than usual: the same walk has to run in three languages, and
the only things addressed by position are the five tab bar slots, which do not
move, and the cash field, which has no label until it has a value.

    python3 design/store/capture.py ko 한국어

The second argument is optional and is the label of the row in the app's own
Language setting, so the walk sets the language it is about to photograph.

What it expects of the device, none of which it does for you:

  * A RELEASE build installed. Debug and profile builds resolve the AdMob test
    unit and set `nativeGraceDays` to 0, so a test creative can appear in the
    ledger; release gives a new install a seven-day quiet period and the
    screenshots come back ad-free. Play does not allow ads in screenshots.
  * Believable data. The captures are only as honest as what is in the app:
    a budget in the currency the listing targets, a cycle several days in, and
    a handful of expenses across a few days so the ledger groups by date. The
    app takes "today" from the device, so the way to get a cycle that is partly
    spent — and a ledger with more than one date heading in it — is to walk the
    emulator's clock forward between entries, in Settings > Date & time with
    automatic date off. `adb shell date` cannot do it on a Play image.
    Aim for a daily allowance that divides evenly: the home screen's headline
    number is the budget left at the start of the day over the days remaining,
    so $4,500 with nine days left reads $500 rather than $524.44.
  * The system UI in demo mode, which is what fixes the status bar at 9:41 with
    a full battery and no notification icons:

        adb shell settings put global sysui_demo_allowed 1
        adb shell am broadcast -a com.android.systemui.demo -e command enter
        adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0941
        adb shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false
        adb shell am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4 -e fully true
        adb shell am broadcast -a com.android.systemui.demo -e command network -e mobile hide
        adb shell am broadcast -a com.android.systemui.demo -e command notifications -e visible false

    The `fully true` is not optional: without it the emulator draws the wifi
    glyph with the no-internet exclamation, and it is legible at listing size.
"""

from __future__ import annotations

import os
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE / "shots"
ADB = Path(os.environ.get("ANDROID_HOME", Path.home() / "Library/Android/sdk")) / "platform-tools/adb"

# The tab bar, which is the one thing addressed by position: its five slots are
# fixed by the layout and carry labels that change with the language.
NAV = {"home": 109, "activity": 327, "add": 540, "budget": 753, "me": 971}
NAV_Y = 1999
CASH_FIELD = (540, 504)

TABS = r"^(Home|홈|Inicio)\n"
ROOM = r"Open my room|내 방 열기|Abrir mi casa"
CASH = r"Estimated cash|예상 현금|Efectivo estimado|Cash not set up|현금 미설정"
LANGUAGE = r"^(Language|언어|Idioma)\b"

SCREENS = ["1-home", "2-entry", "3-budget", "4-activity", "5-room", "6-cash"]


def adb(*args) -> str:
    return subprocess.run([str(ADB), *args], capture_output=True, text=True).stdout


# "Sobrita isn't responding", in the three languages the device may be in. On a
# loaded host the emulator drops enough frames to raise it, and it survives a
# force-stop, so it has to be answered rather than stepped around.
ANR_WAIT = r"^(Wait|기다리기|Esperar)$"


def dismiss_anr() -> bool:
    hit = find(ANR_WAIT)
    if not hit:
        return False
    touch(hit[1], hit[2], settle=3)
    return True


def tree() -> ET.Element:
    for _ in range(4):
        adb("shell", "uiautomator", "dump", "/sdcard/ui.xml")
        xml = adb("shell", "cat", "/sdcard/ui.xml")
        if "<hierarchy" in xml:
            try:
                return ET.fromstring(xml)
            except ET.ParseError:
                pass
        time.sleep(1)
    raise SystemExit("could not read the semantics tree — is the app in the foreground?")


def nodes():
    """Every labelled node, as (label, centre x, centre y)."""
    found = []
    for el in tree().iter("node"):
        label = ((el.get("content-desc") or "") + "\n" + (el.get("text") or "")).strip()
        if not label:
            continue
        x1, y1, x2, y2 = map(int, re.findall(r"-?\d+", el.get("bounds")))
        found.append((label, (x1 + x2) // 2, (y1 + y2) // 2))
    return found


def find(pattern):
    rx = re.compile(pattern, re.I)
    return next((n for n in nodes() if rx.search(n[0])), None)


def wait(pattern, timeout=60):
    """Wait for a node, clearing the not-responding dialog wherever it lands.

    On a loaded host that dialog can appear between any two taps, so every wait
    answers it rather than only the ones that expect it."""
    end = time.time() + timeout
    while time.time() < end:
        hit = find(pattern)
        if hit:
            return hit
        dismiss_anr()
        time.sleep(1.5)
    raise SystemExit(f"never saw {pattern!r}")


def touch(x, y, settle=1.2):
    adb("shell", "input", "tap", str(x), str(y))
    time.sleep(settle)


def tap(pattern, timeout=40):
    _, x, y = wait(pattern, timeout)
    touch(x, y)


def swipe(x1, y1, x2, y2, ms=350):
    adb("shell", "input", "swipe", str(x1), str(y1), str(x2), str(y2), str(ms))
    time.sleep(1.0)


def back():
    adb("shell", "input", "keyevent", "KEYCODE_BACK")
    time.sleep(2)


def scroll_to(pattern, tries=8):
    for _ in range(tries):
        hit = find(pattern)
        if hit:
            return hit
        if not dismiss_anr():
            swipe(540, 1600, 540, 700)
    return find(pattern)


def to_top(times=5):
    for _ in range(times):
        swipe(540, 700, 540, 1850, 200)
    time.sleep(1.2)


APP = "com.sobra.app.sobra_app/.MainActivity"


def restart():
    """Get back to a known place: answer any system dialog, then relaunch."""
    dismiss_anr()
    adb("shell", "am", "force-stop", APP.split("/")[0])
    time.sleep(2)
    adb("shell", "am", "start", "-n", APP)
    time.sleep(14)
    dismiss_anr()


def nav(tab: str):
    """Reach a tab. A pushed route hides the tab bar, so back out of it first."""
    for attempt in range(2):
        for _ in range(4):
            if find(TABS):
                touch(NAV[tab], NAV_Y, settle=3)
                return
            if not dismiss_anr():
                back()
        restart()
    raise SystemExit("could not get back to the tab bar")


def grab(locale: str, name: str) -> Path:
    png = subprocess.run([str(ADB), "exec-out", "screencap", "-p"], capture_output=True).stdout
    path = OUT / locale / f"{name}.png"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(png)
    return path


def set_language(option: str):
    nav("me")
    scroll_to(LANGUAGE)
    tap(LANGUAGE)
    time.sleep(2)
    tap(rf"^{option}$")
    time.sleep(3)


def capture(locale: str):
    nav("home"); to_top(); grab(locale, "1-home")
    nav("add"); to_top(); grab(locale, "2-entry")
    nav("budget"); to_top(); grab(locale, "3-budget")
    nav("activity"); to_top(); grab(locale, "4-activity")

    nav("home"); to_top()
    tap(ROOM); time.sleep(3.5); grab(locale, "5-room")
    back()

    nav("home"); to_top()
    scroll_to(CASH)
    tap(CASH); time.sleep(3.5)
    # A count is typed and never saved: the screen is worth photographing at the
    # moment it shows the difference, which is while you are still standing
    # there with the money in your hand.
    touch(*CASH_FIELD, settle=1.5)
    adb("shell", "input", "text", "1630")
    time.sleep(1.5)
    back()                       # closes the keyboard, not the route
    grab(locale, "6-cash")
    back()
    nav("home"); to_top()

    for name in SCREENS:
        print("captured", (OUT / locale / f"{name}.png").relative_to(HERE))


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__.strip().splitlines()[0] + "\n\nusage: capture.py <locale> [language row label]")
    if len(sys.argv) > 2:
        set_language(sys.argv[2])
    capture(sys.argv[1])


if __name__ == "__main__":
    main()
