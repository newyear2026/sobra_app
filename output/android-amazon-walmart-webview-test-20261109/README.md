# Amazon·Walmart Android WebView 실제 테스트

2026-11-09 · Android 16 / API 36 에뮬레이터 · Android System WebView 134.0.6998.135

| 쇼핑몰·상품 | 사진 | 표시 판매가격 | Android 결과 |
|---|---|---|---|
| Amazon · 운동화 1 | 2165×900 로드 | MX$1,349.00 | 성공 |
| Amazon · 운동화 2 | 337×158 로드 | MX$1,242.66 | 성공 |
| Walmart · AirPods 4 | 가져오지 못함 | 가져오지 못함 | 보안 확인으로 중단 |

## 해석과 범위

- 별도 테스트 앱의 기본 Android WebView로 상품 링크를 열었습니다. 공식 쇼핑 API, API 키, 수동 로그인, 사용자 에이전트 변경, 외부 쿠키 가져오기는 사용하지 않았습니다.
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

## 원본 증거

[실제 화면 모아보기](report.html) · [요약 JSON](summary.json) · [재현 방법](PROBE.md)

- Amazon · 운동화 1: [adidas 60s 4.0 Tenis para Hombre, Color Negro de Adulto 24.5 cm](https://www.amazon.com.mx/adidas-Tenis-Hombre-Casual-Negro/dp/B0DHZVB27Q) · [결과 JSON](results/amazon1_v4_capture_retry2.json) · [실행 화면](results/amazon1_v4_capture_retry2.png) · 2026-11-09T22:02:16.195Z
- Amazon · 운동화 2: [adidas Tenis Response Runner 2 Unisex Correr Negro 26.5 cm](https://www.amazon.com.mx/dp/B0F1X7M849) · [결과 JSON](results/amazon2_v4.json) · [실행 화면](results/amazon2_v4.png) · 2026-11-09T21:59:01.187Z
- Walmart · AirPods 4: [Apple AirPods 4 — 요청한 상품](https://www.walmart.com.mx/ip/audifonos-inalambricos-apple-airpods-4-blancos/00019594968846) · [결과 JSON](results/walmart_diagnostic.json) · [실행 화면](results/walmart_diagnostic.png) · 2026-11-09T21:49:41.833Z

[Walmart 일반 HTML 검사 기록](../other-shop-import-test-20261109/README.md)

후속 월마트 결과: [다른 Android 환경에서 보안 확인 없이 사진·표시가격 읽기 성공](../android-walmart-manual-verification-20261109/README.md). WebView156에서 AirPods4 사진612×612 및MXN1,499.00를 확인했습니다. 사용자가 수동 보안 확인을 하지 않은 사례로, 앞선 WebView134 실패와 구분합니다.
