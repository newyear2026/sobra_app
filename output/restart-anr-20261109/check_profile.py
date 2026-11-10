import json
from io import BytesIO
import subprocess
import time
from pathlib import Path
from PIL import Image

OUT = Path(__file__).resolve().parent
ADB = '/Users/jaewook/Library/Android/sdk/platform-tools/adb'
PACKAGE = 'com.sobra.app.sobra_app'

def adb(*args, binary=False, timeout=45):
    result = subprocess.run([ADB, '-s', 'emulator-5554', *args],
                            capture_output=True, timeout=timeout, check=True)
    return result.stdout if binary else result.stdout.decode()

def wait_screen(name, selected_x):
    started = time.monotonic()
    while time.monotonic() - started < 180:
        png = adb('exec-out', 'screencap', '-p', binary=True)
        im = Image.open(BytesIO(png)).convert('RGB')
        if (im.getpixel((10, 300)) == (255, 253, 247)
                and im.getpixel((selected_x, 1920)) == (14, 122, 114)):
            (OUT / name).write_bytes(png)
            return round(time.monotonic() - started, 2)
        time.sleep(2)
    (OUT / ('timeout-' + name)).write_bytes(png)
    raise AssertionError('Screen was not ready: ' + name)


results = []
for index in range(1, 2):
    adb('shell', 'am', 'force-stop', PACKAGE)
    launch = adb('shell', 'am', 'start', '-n', PACKAGE + '/.MainActivity')
    (OUT / f'profile-cold-{index}-launch.txt').write_text(launch)
    home_wait_seconds = wait_screen(f'profile-cold-{index}-home.png', 5)
    pid = adb('shell', 'pidof', PACKAGE).strip()
    # Bottom navigation bounds were read from the live UI hierarchy.
    adb('shell', 'input', 'tap', '325', '2000')
    ledger_wait_seconds = wait_screen(f'profile-cold-{index}-ledger.png', 230)
    last_anr = adb('shell', 'dumpsys', 'activity', 'lastanr')
    (OUT / f'profile-cold-{index}-lastanr.txt').write_text(last_anr)
    logs = adb('logcat', '-d', '--pid=' + pid)
    (OUT / f'profile-cold-{index}-runtime.log').write_text(logs)
    result = dict(index=index, pid=pid, launch=launch,
                  home_wait_seconds=home_wait_seconds,
                  ledger_wait_seconds=ledger_wait_seconds,
                  no_anr_since_boot='no ANR has occurred since boot' in last_anr,
                  rewarded_preload='Rewarded ad loadRequested' in logs,
                  fatal_exception='FATAL EXCEPTION' in logs)
    results.append(result)
    (OUT / 'profile-cold-restarts.json').write_text(json.dumps(results, indent=2))
    print(json.dumps(result), flush=True)
    assert result['no_anr_since_boot'] and not result['fatal_exception']
    assert not result['rewarded_preload']
