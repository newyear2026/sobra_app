#!/usr/bin/env python3
"""Build a readable report from the final two recorded Android runs."""
import html
import json
from pathlib import Path

root = Path(__file__).resolve().parent
runs = [("운동화", "shoe_android16_v3"), ("iPhone 15", "iphone_android16_v3_retry")]
rows = []
for label, run in runs:
    data = json.loads((root / "results" / f"{run}.json").read_text())
    o = data["finalObservation"]
    price = o.get("primaryPrice")
    photo = o.get("mainImage")
    rows.append({"label": label, "id": run, "report": data, "observation": o,
                 "price": "MX$" + price["numeric"] if price else "자동 확정 안 함",
                 "image": f'{photo["naturalWidth"]}×{photo["naturalHeight"]}' if photo else "가져오지 못함"})

env = rows[0]["report"]
summary = {
    "date": "2026-11-09", "android": env["androidRelease"], "apiLevel": env["androidSdk"],
    "webViewVersion": env["webViewVersion"], "targetSdk": env["targetSdk"],
    "finalSamples": [{"label": r["label"], "run": r["id"], "success": r["report"]["success"],
                      "price": r["price"], "image": r["image"], "url": r["report"]["requestedUrl"]} for r in rows],
    "setup": "Separate native Android WebView test app. Its data was cleared before each final run. No official product API integration, API key, manual login, cookie import, UA override, proxy, or challenge bypass.",
    "limits": ["One Android 16 emulator and one installed WebView version; no physical-device matrix.",
               "Two full product URLs, not short sharing links or all product layouts.",
               "Product image URLs and loaded dimensions verified; purchase/checkout not tested.",
               "Native WebView feasibility test, not integrated with the production Flutter app.",
               "The retailer's app-opening promotion overlays the page; no website overlay was modified.",
               "The first v0.3 iPhone attempt timed out (net::ERR_TIMED_OUT); one unchanged retry succeeded. This is not a 100% reliability result."],
    "additionalImageCheck": {"context":"Host-side anonymous public CDN request for the sneaker image URL extracted on Android", "httpStatus":206, "contentType":"image/webp", "bytesRead":128}
}
(root / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n")

md = ["# Android WebView — 메르카도리브레 실제 테스트", "",
      f'2026-11-09 · Android {env["androidRelease"]} / API {env["androidSdk"]} · WebView {env["webViewVersion"]} · targetSdk {env["targetSdk"]}', "",
      "독립 테스트 앱에서 두 정식 상품 URL을 열어 사진과 주 판매가격을 읽었습니다. 각 최종 테스트 전에 테스트 앱 데이터만 초기화했습니다.", "",
      "| 상품 | 사진 | 주 판매가격 | 결과 |", "|---|---|---|---|"]
for r in rows:
    md.append(f'| {r["label"]} | {r["image"]} 로드 | {r["price"]} | {"성공" if r["report"]["success"] else "부분 성공 / 미확정"} |')
md += ["", "## 확인한 내용", "",
       "- 공식 상품 API 연결·API 키·로그인·쿠키 가져오기·User-Agent 변경 없이 기본 Android WebView를 사용했습니다.",
       "- JavaScript와 DOM storage를 활성화했습니다. 사이트가 자체적으로 설정하는 일반 쿠키는 허용했습니다.",
       "- 상품명, 주 가격행, 로드된 상품 갤러리 이미지 URL과 실제 이미지 크기를 함께 확인했습니다.",
       "- 할부금·색상 옵션 카드 가격은 목표 금액에서 제외했습니다. 남은 주 가격이 여러 개로 충돌하면 자동 확정하지 않습니다.",
       "- 화면 캡처는 테스트 앱이 자신의 Window를 PixelCopy로 저장한 실제 실행 화면입니다. 이미지 생성이나 화면 재구성은 하지 않았습니다.",
       "- 운동화는 사이즈 미선택 상태의 표시가격입니다. iPhone은 파란색 128GB 상품입니다. 배송비·쿠폰·결제 최종가격은 검증하지 않았습니다.",
       "- 메르카도리브레의 ‘앱 열기’ 프로모션 팝업이 관찰됐습니다. 팝업을 수정하거나 자동으로 닫지는 않았습니다. 추출 가격은 사진 아래 상품 DOM에서 읽으며 화면 캡처에서는 스크롤 아래에 있을 수 있습니다.", "",
       "- v0.3 iPhone 첫 요청은 연결 시간 초과(`net::ERR_TIMED_OUT`)가 있었고, 동일 설정으로 한 번 재시도해 성공했습니다. 자동 가져오기의 상시 성공을 확인한 결과는 아닙니다.",
       "- Android에서 읽은 운동화 사진 URL을 호스트에서도 비로그인 요청해 HTTP 206 / image/webp 응답을 추가 확인했습니다.", "",
       "## 범위와 다음 단계", "",
       "Android 16 에뮬레이터 한 대의 WebView 134에서 확인한 초기 가능성 테스트입니다. 실제 기기·다른 WebView 버전·단축 공유 링크·다른 상품 구조·옵션 변경 후 가격 갱신은 추가 검증이 필요합니다. Sobrita 본 앱에는 아직 통합하지 않았습니다.", "",
       "다음 구현은 앱 안의 상품 페이지에서 ‘이 상품으로 목표 만들기’를 누르면 읽은 내용을 확인 화면에 채우고, 누락되거나 모호한 값은 사용자가 직접 입력하도록 연결하는 흐름입니다.", "",
       "## 결과 파일", "", "[실제 화면 모아보기](report.html) · [요약 JSON](summary.json) · [재현 방법](PROBE.md) · [테스트 APK](sobrita-link-probe-debug.apk)"]
for r in rows:
    md += [f'- {r["label"]}: [결과 JSON](results/{r["id"]}.json) · [실행 화면](results/{r["id"]}.png)']
(root / "README.md").write_text("\n".join(md) + "\n")

cards = []
for r in rows:
    data = r["report"]
    state = "사진·가격 추출 성공" if data["success"] else "가격 자동 확정 안 함"
    cards.append(f'<section><h2>{html.escape(r["label"])}</h2><p class="result">{state} · {html.escape(r["price"])}</p><p>{html.escape(r["observation"]["productTitle"] or "")}</p><a href="results/{r["id"]}.png"><img src="results/{r["id"]}.png" alt="{html.escape(r["label"])} 실제 Android 테스트 화면"></a><p><a href="results/{r["id"]}.json">상세 JSON</a> · <a href="{html.escape(data["requestedUrl"],quote=True)}">테스트한 상품</a></p></section>')
page = '''<!doctype html><html lang="ko"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Android WebView 실제 테스트</title><style>*{box-sizing:border-box}body{margin:0;background:#f5f7fa;color:#17294a;font-family:-apple-system,BlinkMacSystemFont,"Apple SD Gothic Neo",sans-serif}main{max-width:1000px;margin:auto;padding:36px 24px}h1{font-size:28px}p{line-height:1.7;color:#53637a}a{color:#007f80}.grid{display:grid;grid-template-columns:1fr 1fr;gap:28px}section{min-width:0}img{width:100%;height:auto;display:block;border:1px solid #d9e1e8}.result{color:#007f80;font-weight:700}footer{margin-top:28px;border-top:1px solid #d9e1e8;padding-top:20px}@media(max-width:650px){.grid{grid-template-columns:1fr}h1{font-size:24px}}</style><main><h1>Android에서도 사진·가격 가져오기</h1>'''
page += f'<p>2026년 11월 9일 · Android {env["androidRelease"]} 에뮬레이터 · WebView {env["webViewVersion"]}<br>각 상품을 테스트 앱의 초기 상태에서 열었습니다. 별도 로그인이나 쇼핑몰 API 연결을 사용하지 않았습니다.</p><div class="grid">'+"".join(cards)+'</div>'
page += '<footer><p>실제 테스트 앱 화면입니다. 어두워진 부분은 메르카도리브레의 앱 열기 안내창이 덮고 있는 상태입니다. 상단 흰 영역은 추출 결과를 표시하는 테스트 앱 영역입니다.</p><p>iPhone 첫 요청에는 연결 시간 초과가 있었고 동일 설정의 재시도에서 성공했습니다. 표시가격은 테스트 시점의 값이며 배송비·옵션·최종 결제가격을 보장하지 않습니다. 두 정식 상품 URL과 한 Android 환경에서의 검증이며, 본 앱 통합과 실기기 검증은 아직 진행하지 않았습니다.</p><p><a href="README.md">검증 범위</a> · <a href="PROBE.md">재현 방법</a> · <a href="summary.json">요약 데이터</a></p></footer></main></html>'
(root / "report.html").write_text(page)
print(json.dumps(summary, ensure_ascii=False, indent=2))
