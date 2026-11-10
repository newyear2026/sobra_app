"""Build a Korean report from completed, actual Android probe evidence.

No network access and no modification of probe sources or raw evidence.
Missing or unconfirmed final runs fail clearly before report files are written.
"""
from pathlib import Path
from decimal import Decimal, InvalidOperation
import html
import json
import struct
import zlib

ROOT = Path(__file__).resolve().parent
RUNS = [('Amazon · 운동화 1', 'amazon1_v4_capture_retry2'),
        ('Amazon · 운동화 2', 'amazon2_v4'),
        ('Walmart · AirPods 4', 'walmart_diagnostic')]


def require(condition, message):
    if not condition:
        raise ValueError(message)


def load_run(label, run_id):
    result_path = ROOT / 'results' / f'{run_id}.json'
    image_path = ROOT / 'results' / f'{run_id}.png'
    for path in (result_path, image_path):
        if not path.is_file():
            raise FileNotFoundError(f'Final evidence missing: {path}')
    data = json.loads(result_path.read_text())
    obs = data.get('finalObservation')
    require(isinstance(obs, dict), f'{run_id}: finalObservation missing')
    require(data.get('androidSdk') == 36, f'{run_id}: unexpected Android API')
    require(data.get('targetSdk') == 36, f'{run_id}: unexpected target SDK')
    require(str(data.get('webViewVersion', '')).startswith('134.'), f'{run_id}: unexpected WebView version')
    for flag in ('uaOverride', 'officialApiUsed', 'manualLoginUsed', 'cookiesImported'):
        require(data.get(flag) is False, f'{run_id}: expected {flag}=false')
    with image_path.open('rb') as stream:
        header = stream.read(24)
    require(header[:8] == b'\x89PNG\r\n\x1a\n', f'{run_id}: invalid screenshot PNG')
    png = image_path.read_bytes()
    offset, last_chunk = 8, None
    while offset + 12 <= len(png):
        size = struct.unpack('>I', png[offset:offset+4])[0]
        end = offset + size + 12
        require(end <= len(png), f'{run_id}: truncated PNG chunk')
        require(zlib.crc32(png[offset+4:offset+8+size]) == struct.unpack('>I', png[offset+8+size:end])[0], f'{run_id}: PNG CRC mismatch')
        last_chunk = png[offset+4:offset+8]
        offset = end
    require(last_chunk == b'IEND' and offset == len(png), f'{run_id}: incomplete screenshot PNG')
    dimensions = struct.unpack('>II', header[16:24])
    require(all(v > 0 for v in dimensions), f'{run_id}: invalid screenshot dimensions')
    row = {
        'label': label, 'runId': run_id, 'requestedUrl': data.get('requestedUrl'),
        'observedAtUtc': obs.get('observedAtUtc', data.get('finishedAtUtc')),
        'androidRelease': data.get('androidRelease'), 'androidSdk': data.get('androidSdk'),
        'webViewVersion': data.get('webViewVersion'), 'extractorVersion': data.get('extractorVersion'),
        'screenshot': f'results/{run_id}.png', 'screenshotDimensions': list(dimensions),
        'evidence': f'results/{run_id}.json', 'completionReason': data.get('completionReason'),
        'mainFrameErrors': data.get('mainFrameErrors', []),
    }
    if run_id.startswith('amazon'):
        confirmed = data.get('success') is True or data.get('extractionConfirmed') is True
        require(confirmed and obs.get('photoAndPriceReadable') is True,
                f'{run_id}: final extraction is not confirmed')
        require(data.get('matchingSuccessfulObservations', 0) >= 2,
                f'{run_id}: fewer than two matching successful observations')
        require(not obs.get('challenge') and not obs.get('accountVerification'),
                f'{run_id}: verification/challenge cannot be counted as success')
        price, picture = obs.get('primaryPrice'), obs.get('mainImage')
        require(isinstance(price, dict) and isinstance(picture, dict),
                f'{run_id}: primaryPrice/mainImage missing')
        try:
            amount = Decimal(str(price['amount']))
        except (KeyError, InvalidOperation) as exc:
            raise ValueError(f'{run_id}: numeric primary price missing') from exc
        require(amount.is_finite() and amount > 0, f'{run_id}: invalid primary price')
        require(picture.get('src', '').startswith('https://'), f'{run_id}: invalid image URL')
        require(picture.get('naturalWidth', 0) > 0 and picture.get('naturalHeight', 0) > 0,
                f'{run_id}: product image has not loaded')
        require(isinstance(obs.get('productTitle'), str) and obs['productTitle'].strip(),
                f'{run_id}: product title missing')
        row.update(status='success', productTitle=obs['productTitle'],
                   productTitleSource=obs.get('productTitleSource'),
                   primaryPrice=price, mainImage=picture,
                   priceDisplay=f'MX${amount:,.2f}',
                   currencyNote='MXN: amazon.com.mx 마켓을 근거로 추정',
                   currencyEvidence=obs.get('currencyEvidence'))
    else:
        require(obs.get('challenge') is True, f'{run_id}: expected security challenge evidence')
        require(data.get('extractionConfirmed') is False, f'{run_id}: unexpected extraction claim')
        require(not obs.get('priceCandidates') and not obs.get('largeImageCandidates'),
                f'{run_id}: report requires review of unexpected Walmart candidates')
        row.update(status='blocked', productTitle='Apple AirPods 4 — 요청한 상품',
                   priceDisplay='가져오지 못함', primaryPrice=None, mainImage=None,
                   pageTitle=obs.get('pageTitle'), pageUrl=obs.get('pageUrl'),
                   reason='본인/로봇 확인 화면에서 테스트 중단; 확인 절차를 우회하지 않음')
    return row


def main():
    rows = [load_run(label, run_id) for label, run_id in RUNS]
    summary = {
        'testDate': '2026-11-09', 'environment': 'Android 16 / API 36 emulator · Android WebView 134',
        'officialApiUsed': False, 'manualLoginUsed': False, 'uaOverride': False,
        'cookiesImported': False, 'testAppDataResetBeforeFinalRuns': True,
        'productionAppIntegrated': False,
        'scope': 'Two Amazon product links and one Walmart product link; one Android emulator environment',
        'runs': rows,
        'additionalAttempts': [{'runId': 'amazon1_v4_capture_retry', 'error': 'net::ERR_NAME_NOT_RESOLVED', 'followup': 'An unchanged retry succeeded.'}],
        'limitations': [
            'Amazon MXN currency is inferred from the marketplace, not asserted as an explicit page currency field.',
            'Walmart anonymous host HTML succeeded earlier, but this Android WebView run stopped at a security challenge.',
            'Physical devices, other Android/WebView versions, shortened share links, changed options and checkout totals were not verified.',
        ],
    }
    table = ['| 쇼핑몰·상품 | 사진 | 표시 판매가격 | Android 결과 |',
             '|---|---|---|---|']
    for row in rows:
        picture = row['mainImage']
        photo = f"{picture['naturalWidth']}×{picture['naturalHeight']} 로드" if picture else '가져오지 못함'
        table.append(f"| {row['label']} | {photo} | {row['priceDisplay']} | {'성공' if row['status']=='success' else '보안 확인으로 중단'} |")
    notes = '''- 별도 테스트 앱의 기본 Android WebView로 상품 링크를 열었습니다. 공식 쇼핑 API, API 키, 수동 로그인, 사용자 에이전트 변경, 외부 쿠키 가져오기는 사용하지 않았습니다.
- 각 최종 실행 전 테스트 앱 데이터만 초기화했습니다. JavaScript와 DOM storage를 활성화했으며 사이트가 스스로 설정한 일반 쿠키는 허용했습니다.
- Amazon은 상품명, 주 판매가격, WebView가 실제로 로드한 공식 상품 갤러리 사진을 확인했습니다. 할부금·정가·추천 상품 가격·옵션 가격은 주 판매가격으로 채택하지 않습니다.
- 모바일 상품명 요소를 읽을 수 없는 경우에는 해당 상품 페이지 제목에서 Amazon 접미사를 제거한 값을 사용합니다. 정확한 제목 출처는 각 JSON의 `productTitleSource`에 기록합니다.
- 사진은 공식 주 갤러리의 HTTPS 이미지이며 로드가 완료되고 자연 너비·높이가 모두 0보다 큰지로 검증합니다. 임의의 최소 해상도는 성공 조건에 넣지 않았습니다. 작은 원본 이미지도 포함될 수 있어 고해상도나 확대 품질을 보장하는 결과는 아닙니다.
- CSS로 가려져 있거나 스크롤 밖에 있는 갤러리 이미지도 포함할 수 있으므로, 추출한 사진이 화면 캡처에 그대로 보인다는 뜻은 아닙니다.
- 초기 v2 규칙에서는 모바일 상품명·사진 일부가 누락됐고, v3에서는 실제 로드된 작은 사진이 최소 크기 조건 때문에 제외됐습니다. 해당 기록을 보존하고, 로드 여부와 화질 조건을 구분한 v4로 다시 실행한 결과를 위 표에 사용했습니다. 모든 상품과 상태에서 항상 성공한다는 검증은 아닙니다.
- Amazon 금액의 MXN 표시는 **amazon.com.mx 마켓을 근거로 한 추정**입니다. 화면의 달러 기호만으로 통화가 직접 확인됐다고 주장하지 않습니다. 구체적인 통화 근거는 각 JSON에 보존합니다.
- Walmart는 `Verifica tu identidad` 보안 확인 화면으로 이동해 사진과 가격을 가져오지 못했습니다. 확인 버튼을 자동으로 누르거나 확인 절차를 우회하지 않았습니다.
- 앞선 호스트의 일반 HTML 요청에서는 같은 Walmart 상품의 제목·사진·MXN 1,499를 읽었습니다. Android WebView 결과와는 별개입니다. 이번 Android 실패를 모든 환경에서 영구적으로 불가능하다는 뜻으로 해석할 수 없습니다.
- 첫 Amazon v4 성공 실행의 PNG는 저장 중 수집되어 불완전했습니다. 수집기에 PNG 완료 확인을 추가했고, 화면 확보 재실행 중 DNS 오류(`net::ERR_NAME_NOT_RESOLVED`)가 한 번 발생했습니다. 동일 설정의 다음 재시도에서 성공했습니다. 갤러리에는 해당 재시도의 완전한 원본 PNG를 사용하며, 모든 PNG 청크 CRC와 IEND를 검증했습니다.
- 첨부 화면은 테스트 앱이 자신의 실제 Window를 캡처한 PNG입니다. 생성 이미지나 재구성한 시안이 아닙니다.
- Sobrita 본 앱 소스에는 적용하지 않았습니다. 실기기, 다른 Android/WebView 버전, 단축 공유 링크, 옵션 변경 후 가격, 배송비·쿠폰·결제 최종가격은 검증하지 않았습니다.
'''
    md = '# Amazon·Walmart Android WebView 실제 테스트\n\n'
    md += '2026-11-09 · Android 16 / API 36 에뮬레이터 · Android System WebView 134.0.6998.135\n\n'
    md += '\n'.join(table) + '\n\n## 해석과 범위\n\n' + notes
    md += '\n## 원본 증거\n\n[실제 화면 모아보기](report.html) · [요약 JSON](summary.json) · [재현 방법](PROBE.md)\n\n'
    for row in rows:
        md += f"- {row['label']}: [{row['productTitle']}]({row['requestedUrl']}) · [결과 JSON]({row['evidence']}) · [실행 화면]({row['screenshot']}) · {row['observedAtUtc']}\n"
    md += '\n[Walmart 일반 HTML 검사 기록](../other-shop-import-test-20261109/README.md)\n'
    esc = html.escape
    cards = []
    for row in rows:
        ok = row['status'] == 'success'
        detail = f"사진 {row['mainImage']['naturalWidth']}×{row['mainImage']['naturalHeight']} · 판매가격 추출" if ok else '보안 확인 화면 · 사진·가격 미추출'
        cards.append(f'''<article class="card"><header><span class="badge {'ok' if ok else 'blocked'}">{'성공' if ok else '보안 확인'}</span><h2>{esc(row['label'])}</h2><p class="name">{esc(row['productTitle'])}</p><p class="amount">{esc(row['priceDisplay'])}</p><p>{esc(detail)}</p></header><a href="{esc(row['screenshot'])}"><img src="{esc(row['screenshot'])}" alt="{esc(row['label'])} 실제 Android 실행 화면" loading="lazy"></a><footer><a href="{esc(row['evidence'])}">원본 JSON</a> · <a href="{esc(row['requestedUrl'])}">상품 링크</a><p>{esc(row['observedAtUtc'] or '')}</p></footer></article>''')
    page = '''<!doctype html><html lang="ko"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Amazon·Walmart Android 실제 테스트</title><style>
*{box-sizing:border-box}body{margin:0;background:#f5f7f8;color:#172b3a;font-family:-apple-system,BlinkMacSystemFont,"Apple SD Gothic Neo",sans-serif;line-height:1.6}main{max-width:1180px;margin:auto;padding:40px 24px}h1{font-size:28px;line-height:1.35;margin:0 0 12px}h2{font-size:19px;margin:8px 0}.sub{color:#5d6b75}.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:22px;margin:28px 0}.card{background:white;border:1px solid #dbe3e8;border-radius:16px;overflow:hidden}.card header{padding:22px;min-height:248px}.card img{display:block;width:100%;height:auto;border-top:1px solid #edf1f3;border-bottom:1px solid #edf1f3}.card footer{padding:16px 22px;font-size:13px;overflow-wrap:anywhere}.name{font-size:14px;min-height:44px;margin:8px 0}.amount{font-size:24px;font-weight:750;margin:10px 0}.badge{display:inline-block;font-size:12px;font-weight:700;padding:3px 9px;border-radius:20px}.ok{background:#dff4eb;color:#126344}.blocked{background:#fff1d6;color:#875609}.notes{background:white;border:1px solid #dbe3e8;border-radius:16px;padding:24px}.notes p{margin:0 0 12px}a{color:#087c83}footer p{color:#697780;font-size:12px}@media(max-width:850px){.grid{grid-template-columns:1fr;max-width:420px;margin:28px auto}.card header{min-height:0}main{padding:28px 18px}}
</style><main><h1>Amazon·Walmart<br>Android에서 직접 확인한 결과</h1><p class="sub">2026-11-09 · Android 16 에뮬레이터 · WebView 134<br>공식 API·로그인·사용자 에이전트 변경 없이 실행한 별도 테스트 앱</p>'''
    page += '<div class="grid">' + ''.join(cards) + '</div><section class="notes"><h2>결과를 읽을 때</h2>'
    for text in [
        'Amazon 두 상품은 공식 주 갤러리에서 로드된 사진과 주 판매가격을 가져왔습니다. 자연 너비·높이가 0보다 큰 로드 완료 이미지가 대상이며 고해상도·확대 품질을 보장하지 않습니다. 화면 밖 또는 CSS로 가려진 갤러리 사진도 포함할 수 있습니다. 상품명은 필요할 때 상품 페이지 제목을 사용합니다.',
        '할부금·정가·옵션·추천 상품 가격은 제외했습니다. MXN은 amazon.com.mx 마켓을 근거로 추정한 통화입니다. v2의 모바일 요소 처리와 v3의 작은 이미지 제외 조건을 보완한 v4로 재실행한 결과이며, 모든 링크의 상시 성공을 뜻하지 않습니다.',
        'Walmart는 보안 확인 화면에서 중단했습니다. 같은 상품이 일반 HTML 요청으로 읽힌 기록과 구분해야 합니다. 이번 결과가 모든 환경에서 영구적으로 불가능하다는 뜻은 아닙니다.',
        '첫 Amazon 상품의 화면 확보 재실행 중 일시적인 주소 해석 오류가 한 번 있었고, 동일 설정의 재시도에서 성공했습니다. 상시 성공을 보장하는 결과는 아닙니다.',
        '각 최종 실행 전 테스트 앱 데이터를 초기화했습니다. 첨부 이미지는 실제 실행 화면 캡처입니다. Sobrita 본 앱에는 아직 적용하지 않았습니다.',
        '실기기·다른 Android/WebView 버전·단축 링크·옵션 변경·배송비·쿠폰·결제 최종가격은 추가 검증이 필요합니다.',
    ]:
        page += '<p>' + esc(text) + '</p>'
    page += '<p><a href="README.md">상세 기록</a> · <a href="summary.json">요약 JSON</a> · <a href="../other-shop-import-test-20261109/README.md">Walmart 일반 HTML 기록</a></p></section></main></html>'
    (ROOT / 'summary.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2))
    (ROOT / 'README.md').write_text(md)
    (ROOT / 'report.html').write_text(page)
    print(json.dumps({'written': ['summary.json', 'README.md', 'report.html'],
                      'runs': [{'runId': row['runId'], 'status': row['status'], 'price': row['priceDisplay']} for row in rows]}, ensure_ascii=False))


if __name__ == '__main__':
    main()
