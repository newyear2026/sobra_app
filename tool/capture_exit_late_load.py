"""Capture a real Android late-fill check using the debug preview's VM probes.

Requires preview_exit_popup.dart built with
--dart-define=SOBRA_EXIT_PREVIEW_HOLD_AD_REQUEST=true on an isolated emulator.
The SDK request is held until the first screenshot, then really sent to AdMob.
"""

import argparse
import json
import re
import subprocess
import time
import urllib.parse
import urllib.request
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--serial", default="emulator-5580")
    parser.add_argument("--adb", default="/Users/jaewook/Library/Android/sdk/platform-tools/adb")
    parser.add_argument("--output", default="design/ads/exit-popup-implemented/late-load")
    args = parser.parse_args()
    output = Path(args.output)
    output.mkdir(parents=True, exist_ok=True)
    command = [args.adb, "-s", args.serial]

    def adb(*parts, timeout=30):
        return subprocess.check_output(command + list(parts), timeout=timeout).decode().strip()

    def capture(name):
        with (output / name).open("wb") as target:
            subprocess.run(command + ["exec-out", "screencap", "-p"], stdout=target, check=True, timeout=15)

    package = "com.sobra.app.sobra_app"
    print(adb("shell", "am", "start", "-W", "-n", f"{package}/.MainActivity", timeout=60), flush=True)
    pid = adb("shell", "pidof", package)
    deadline = time.monotonic() + 40
    match = None
    while time.monotonic() < deadline:
        logs = adb("logcat", "-d", f"--pid={pid}", "-s", "flutter:I")
        match = re.search(r"Dart VM service is listening on http://127\.0\.0\.1:(\d+)(/\S+/)", logs)
        if match:
            break
        time.sleep(.5)
    if not match:
        raise RuntimeError("No Dart VM service from the preview app")
    port = adb("forward", "tcp:0", f"tcp:{match[1]}")
    base = f"http://127.0.0.1:{port}{match[2]}"

    def rpc(method, **parameters):
        query = urllib.parse.urlencode(parameters)
        with urllib.request.urlopen(base + method + ("?" + query if query else ""), timeout=15) as response:
            data = json.load(response)
        if "error" in data:
            raise RuntimeError(data["error"])
        return data["result"]

    isolates = rpc("getVM")["isolates"]
    isolate = next(item["id"] for item in isolates if item.get("name") == "main")

    def snapshot():
        return rpc("ext.sobra.exitSnapshot", isolateId=isolate)

    video = None
    try:
        deadline = time.monotonic() + 35
        while time.monotonic() < deadline:
            initial = snapshot()
            if initial["phase"] == "request_held":
                break
            time.sleep(.5)
        assert initial["phase"] == "request_held", initial
        assert not initial["requestReleased"]
        assert not initial["boxes"]
        print("Google test-ad request held; production home visible.", flush=True)
        video = subprocess.Popen(
            command + ["shell", "screenrecord", "--size", "720x1600", "--bit-rate", "2000000", "--time-limit", "25", "/sdcard/sobra-exit-late.mp4"],
            stdout=subprocess.DEVNULL, stderr=subprocess.PIPE,
        )
        time.sleep(.5)
        started = time.monotonic()
        adb("shell", "input", "keyevent", "4")
        deadline = time.monotonic() + 3
        while time.monotonic() < deadline:
            appeared = snapshot()
            if "exit-dialog-frame" in appeared["boxes"]:
                break
            time.sleep(.05)
        assert "exit-dialog-frame" in appeared["boxes"], appeared
        appearance_ms = round((time.monotonic() - started) * 1000, 1)
        time.sleep(.5)  # Let the normal route fade finish before pixel comparison.
        before = snapshot()
        assert before["phase"] == "request_held"
        assert "exit-native-ad-slot" not in before["boxes"]
        assert before["impressions"] == 0
        capture("before.png")
        print(f"Ad-free dialog confirmed in {appearance_ms} ms including adb/RPC overhead; before.png saved.", flush=True)

        rpc("ext.sobra.releaseExitAdRequest", isolateId=isolate)
        samples = []
        deadline = time.monotonic() + 25
        while time.monotonic() < deadline:
            current = snapshot()
            samples.append(current)
            assert current["boxes"] == before["boxes"], (before, current)
            assert current["impressions"] == 0
            if current["phase"] == "ready":
                break
            if current["phase"] == "no_fill":
                raise RuntimeError("Real SDK returned no fill; repeat with a new preview process")
            time.sleep(.5)
        assert current["phase"] == "ready", current
        time.sleep(1)
        after = snapshot()
        assert after["boxes"] == before["boxes"]
        assert after["impressions"] == 0
        capture("after.png")
        print("Real SDK ad is ready; dialog frame and both buttons are unchanged; after.png saved.", flush=True)

        video.wait(timeout=30)
        if video.returncode:
            raise RuntimeError(video.stderr.read().decode())
        adb("pull", "/sdcard/sobra-exit-late.mp4", str(output / "sequence.mp4"))

        cancel = after["boxes"]["exit-cancel"]
        density = after["density"]
        adb("shell", "input", "tap", str(round((cancel["x"] + cancel["width"] / 2) * density)), str(round((cancel["y"] + cancel["height"] / 2) * density)))
        time.sleep(.5)
        adb("shell", "input", "keyevent", "4")
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            reopened = snapshot()
            if reopened["impressions"] > 0 and "exit-native-ad-slot" in reopened["boxes"]:
                break
            time.sleep(.5)
        assert reopened["impressions"] > 0, reopened
        assert "exit-native-ad-slot" in reopened["boxes"], reopened
        capture("reopened-with-ad.png")

        report = {
            "method": "Actual Android SDK test ad; request start held only in the debug preview, then released while the unchanged production dialog remains open",
            "device_serial": args.serial,
            "appearance_confirmed_ms_including_adb_rpc_overhead": appearance_ms,
            "before": before,
            "after": after,
            "samples_during_load": samples,
            "all_sampled_geometry_identical": True,
            "ad_inserted_after_load": False,
            "reopened": reopened,
            "reopened_real_sdk_impression": True,
        }
        (output / "validation.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
        (output / "sdk-events.log").write_text(adb("logcat", "-d", f"--pid={pid}", "-s", "flutter:I", "AndroidRuntime:E") + "\n")
        print("PASS: no insertion or movement after real load; closing/reopening shows the cached ad and records a real SDK impression.", flush=True)
    finally:
        adb("forward", "--remove", f"tcp:{port}")
        if video is not None and video.poll() is None:
            video.wait(timeout=30)


if __name__ == "__main__":
    main()
