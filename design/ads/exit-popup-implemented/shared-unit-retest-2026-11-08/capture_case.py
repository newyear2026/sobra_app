import hashlib
import json
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from pathlib import Path

ADB = '/Users/jaewook/Library/Android/sdk/platform-tools/adb'
SERIAL = 'emulator-5592'
PACKAGE = 'com.sobra.app.sobra_app'
UNIT = 'ca-app-pub-2706404530136726/3965250332'
OUT = Path('/Users/jaewook/dev_app/sobra_app/design/ads/exit-popup-implemented/shared-unit-retest-2026-11-08')


def adb(*args):
    return subprocess.run([ADB, '-s', SERIAL, *args], check=True,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                          timeout=55).stdout


def log(pid):
    return adb('logcat', '-d', '--pid=' + pid, '-v', 'time',
               'flutter:I', 'SobraExitAds:I', 'Ads:I', 'AndroidRuntime:E', '*:S').decode()


def capture(name):
    remote = '/sdcard/sobra-exit-qa.xml'
    adb('shell', 'uiautomator', 'dump', remote)
    adb('pull', remote, str(OUT / (name + '.xml')))
    (OUT / (name + '.png')).write_bytes(adb('exec-out', 'screencap', '-p'))
    data = []
    for node in ET.parse(OUT / (name + '.xml')).iter('node'):
        a = node.attrib
        if a.get('text') or a.get('content-desc') or 'native_ad_view' in a.get('resource-id', ''):
            data.append({k: a[k] for k in ('text', 'content-desc', 'resource-id', 'bounds') if a.get(k)})
    (OUT / (name + '-ui.json')).write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
    return data


def run_case(size, name, expected_unit):
    adb('shell', 'am', 'force-stop', PACKAGE)
    adb('shell', 'wm', 'size', '945x1523' if size == 'small' else 'reset')
    adb('shell', 'input', 'keyevent', '82')
    print(adb('shell', 'am', 'start', '-W', '-n', PACKAGE + '/.MainActivity').decode(), flush=True)
    pid = adb('shell', 'pidof', PACKAGE).decode().strip()
    logs = ''
    for _ in range(20):
        logs = log(pid)
        if 'EXIT_PREVIEW ' + size + ': ready' in logs or 'EXIT_PREVIEW ' + size + ': no fill' in logs or 'FATAL EXCEPTION' in logs:
            break
        time.sleep(1.5)
    (OUT / (name + '-sdk.log')).write_text(logs)
    assert '"buildMode":"release"' in logs, logs
    assert '"adUnitId":"' + expected_unit + '"' in logs, logs
    assert 'This request is sent from a test device.' in logs, logs
    assert 'FATAL EXCEPTION' not in logs, logs
    assert ': ready' in logs or ': no fill' in logs, logs
    adb('shell', 'input', 'keyevent', '4')
    ui = capture(name)
    logs = log(pid)
    (OUT / (name + '-sdk.log')).write_text(logs)
    events = [json.loads(line.split('EXIT_PREVIEW_EVENT ', 1)[1]) for line in logs.splitlines() if 'EXIT_PREVIEW_EVENT ' in line]
    outcome = 'video_skipped' if 'Skipped video creative' in logs else 'ready' if ': ready' in logs else 'no_fill'
    result = {'name': name, 'size': size, 'pid': pid, 'unitId': expected_unit,
              'outcome': outcome, 'events': events, 'testDevice': True,
              'nativeViewBounds': [n['bounds'] for n in ui if 'native_ad_view' in n.get('resource-id', '')],
              'buttons': {n['content-desc']: n['bounds'] for n in ui if n.get('content-desc') in ('취소', '종료')}}
    (OUT / (name + '.json')).write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(result, ensure_ascii=False), flush=True)


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    if sys.argv[1] == 'case':
        run_case(sys.argv[2], sys.argv[3], sys.argv[4] if len(sys.argv) > 4 else UNIT)
    elif sys.argv[1] == 'capture':
        print(json.dumps(capture(sys.argv[2]), ensure_ascii=False))
