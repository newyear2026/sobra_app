#!/usr/bin/env python3
"""Read only this disposable test package's results from emulator-5556."""
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
base = [adb, "-s", "emulator-5556", "exec-out", "run-as", "com.sobrita.shopprobe", "cat"]
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
                if not (result.stdout.startswith(b"\x89PNG\r\n\x1a\n") and result.stdout.endswith(b"\x00\x00\x00\x00IEND\xaeB`\x82")):
                    time.sleep(2)
                    continue
            (root / f"{run_id}.{extension}").write_bytes(result.stdout)
            print(f"Saved {run_id}.{extension}", flush=True)
            break
        time.sleep(2)
    else:
        raise SystemExit(f"Timed out waiting for {run_id}.{extension}")
observation=data.get("finalObservation") or {}
summary={k:data.get(k) for k in ("runId","androidRelease","webViewVersion","extractorVersion","extractionConfirmed","matchingSuccessfulObservations","completionReason","mainFrameErrors")}
summary.update({k:observation.get(k) for k in ("pageTitle","accountVerification","challenge","productTitle","productTitleSource","imageEvidenceMode","primaryPrice","currencyEvidence")})
photo=observation.get("mainImage")
summary["mainImage"]={k:photo.get(k) for k in ("selector","src","naturalWidth","naturalHeight","gallerySource","complete","renderedVisible","loadedPrimaryGalleryImage")} if photo else None
summary["candidateCounts"]={key:len(observation.get(key) or []) for key in ("priceCandidates","primaryPriceCandidates","largeImageCandidates","mainImageCandidates","mainImageDiagnostics","structuredProducts")}
print(json.dumps(summary,ensure_ascii=False,indent=2))
