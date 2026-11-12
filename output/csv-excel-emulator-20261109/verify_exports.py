"""Compare files pulled from the emulator with its pre-test ledger."""
import csv
import datetime as dt
from decimal import Decimal
import json
from pathlib import Path
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).parent
NS = {'s': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
prefs = ET.parse('/private/tmp/sobrita-export-before-20261109.xml').getroot()
state = json.loads(next(x.text for x in prefs if x.get('name') == 'flutter.sobra_state_v2'))
expected = []
for key, sign in [('transactions', -1), ('incomes', 1)]:
    for row in state[key]:
        at = dt.datetime.fromisoformat(row['occurredAt'])
        note = row.get('note', '').strip()
        if row.get('isPendingCashAdjustment'):
            note = '확인이 필요한 차액'
        expected.append((at, note, Decimal(sign * row['amountCentavos']) / 100))
expected.sort(key=lambda row: row[0])

report = []
for file in sorted(ROOT.glob('*.csv')):
    raw = file.read_bytes()
    assert raw.startswith(b'\xef\xbb\xbf')
    rows = list(csv.reader(raw.decode('utf-8-sig').splitlines(keepends=True), strict=True))
    assert rows[0] == ['날짜', '시간', '유형', '분류', '메모', '결제', '금액', '통화']
    assert len(rows) == len(expected) + 1
    for values, (at, note, amount) in zip(rows[1:], expected):
        assert len(values) == 8
        assert values[0] == at.strftime('%Y-%m-%d')
        assert values[1] == at.strftime('%H:%M')
        assert values[4] == note
        assert Decimal(values[6]) == amount
        assert values[7] == state['currencyCode']
    report.append({'file': file.name, 'rows': len(expected), 'matches_device_ledger': True})

for file in sorted(ROOT.glob('*.xlsx')):
    with zipfile.ZipFile(file) as archive:
        for name in archive.namelist():
            if name.endswith(('.xml', '.rels')):
                ET.fromstring(archive.read(name))
        strings = [''.join(si.itertext()) for si in ET.fromstring(archive.read('xl/sharedStrings.xml'))]
        sheet = ET.fromstring(archive.read('xl/worksheets/sheet1.xml'))
        rows = sheet.findall('s:sheetData/s:row', NS)
        assert len(rows) == len(expected) + 1
        assert not sheet.findall('.//s:f', NS)
        for row, (at, note, amount) in zip(rows[1:], expected):
            cells = {c.get('r').rstrip('0123456789'): c for c in row}
            assert cells['G'].get('t', 'n') == 'n'
            assert Decimal(cells['G'].find('s:v', NS).text) == amount
            assert cells['E'].get('t') == 's'
            assert strings[int(cells['E'].find('s:v', NS).text)] == note
            assert strings[int(cells['H'].find('s:v', NS).text)] == state['currencyCode']
            serial = Decimal(cells['A'].find('s:v', NS).text)
            assert serial == (at.date() - dt.date(1899, 12, 30)).days
            time = Decimal(cells['B'].find('s:v', NS).text)
            assert abs(time * 1440 - (at.hour * 60 + at.minute)) < Decimal('0.00001')
    report.append({'file': file.name, 'rows': len(expected), 'numeric_amounts': True,
                   'notes_are_text': True, 'formulas': 0, 'matches_device_ledger': True})

assert any(x['file'].endswith('.csv') for x in report), 'CSV missing'
assert any(x['file'].endswith('.xlsx') for x in report), 'XLSX missing'
(ROOT / 'file-validation.json').write_text(json.dumps(report, indent=2, ensure_ascii=False))
print(json.dumps(report, indent=2, ensure_ascii=False))
