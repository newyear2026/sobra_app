#!/usr/bin/env python3
"""Read only this disposable test package's results from emulator-5554."""
import json
from pathlib import Path
import re
import subprocess
import sys
import time

run_id = sys.argv[1]
assert re.fullmatch(r"[a-zA-Z0-9_-]+", run_id)
root = Path(__file__).resolve().parent / "results"
root.mkdir(exist_ok=True)
adb = "/Users/jaewook/Library/Android/sdk/platform-tools/adb"
serial = sys.argv[2] if len(sys.argv) > 2 else "emulator-5554"
base = [adb, "-s", serial, "exec-out", "run-as", "com.sobrita.sheinmanual", "cat"]
deadline = time.monotonic() + 40
for extension in ("json", "png"):
    while time.monotonic() < deadline:
        result = subprocess.run(base + [f"files/{run_id}.{extension}"], capture_output=True, timeout=10)
        if result.returncode == 0 and result.stdout:
            if extension == "json":
                try:
                    data = json.loads(result.stdout)
                except (ValueError, UnicodeDecodeError):
                    time.sleep(2)
                    continue
                assert data["runId"] == run_id
            else:
                if not (result.stdout.startswith(b"\x89PNG\r\n\x1a\n") and result.stdout.endswith(b"\x00\x00\x00\x00IEND\xaeB\x60\x82")):
                    time.sleep(2)
                    continue
            (root / f"{run_id}.{extension}").write_bytes(result.stdout)
            print(f"Saved {run_id}.{extension}", flush=True)
            break
        time.sleep(2)
    else:
        raise SystemExit(f"Timed out waiting for {run_id}.{extension}")
observation=data.get("finalObservation") or {}
summary={k:data.get(k) for k in ("runId","androidRelease","webViewVersion","manualVerificationCompleted","manualVerificationEvidence","completionReason","mainFrameErrors")}
summary.update({k:observation.get(k) for k in ("pageUrl","pageTitle","accountVerification","challenge","status","bodyInspected","extractionConfirmed")})
summary["candidateCounts"]={k:len(observation.get(k) or []) for k in ("headings","structuredProducts","priceCandidates","largeImageCandidates")}
print(json.dumps(summary,ensure_ascii=False,indent=2))
