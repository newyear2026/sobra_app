# SHEIN Android WebView 실제 확인

2026-11-09, Android 16 / API 36, Android System WebView 134.0.6998.135. 별도 신규 테스트 패키지 `com.sobrita.sheinprobe`에서 공식 API·로그인·가져온 쿠키·User-Agent 변경 없이 공개 상품 링크를 열었습니다. Sobrita 본 앱은 변경하지 않았습니다.

입력: https://www.shein.com.mx/Women-Long-Dresses-p-568117802.html

결과: 모바일 `https://m.shein.com.mx/risk/challenge`로 이동했습니다. 보안 확인 경로를 감지한 첫 관찰에서 진단을 종료했으며 사진·가격 후보는 모두 0개였습니다. 로그인이나 보안 확인을 통과시키려는 시도는 하지 않았습니다. 캡처 시 페이지는 아직 로딩 중이어서 본문이 비어 있습니다. 이번 결과는 자동 추출 성공을 확인하지 못했다는 뜻이며, 모든 SHEIN 상품이나 모든 사용자 환경에서 불가능하다는 결론은 아닙니다.

일반 호스트 HTTP 요청도 같은 상품에서 `/risk/challenge`로 이동했습니다. [HTTP 기록](../shein-link-precheck-20261109/result.json).

- [Android 진단 JSON](results/shein_default.json)
- [실제 실행 화면](results/shein_default.png)
- [실행 방법](PROBE.md)

## 현재까지 쇼핑몰별 검증 범위

| 쇼핑몰 | 일반 웹페이지 요청 | Android WebView |
|---|---|---|
| Mercado Libre | 보안 확인 이동 | 2개 상품 사진·판매가 성공 |
| Amazon México | 2개 상품 사진·판매가 성공 | 2개 상품 사진·판매가 성공 |
| Walmart México | 1개 상품 사진·판매가 성공 | WebView134 보안 확인 중단 / WebView156 직접 열림·사진·표시가격 성공 |
| SHEIN México | 보안 확인 이동 | 1개 상품 보안 확인 이동, 추출 중단 |
| Liverpool | 1개 상품 403 접근 차단 | 미검증 |

[Mercado Libre 실제 테스트](../android-mercado-webview-test-20261109/README.md) · [Amazon 테스트](../link-import-no-api-test-20261109/amazon/README.md) · [Walmart·Liverpool 테스트](../other-shop-import-test-20261109/README.md)

모든 결과는 제한된 상품과 환경의 초기 검증입니다. 각 사이트용 추출 처리, 금액 확인·수정 화면, 실패 시 직접 입력 경로가 필요하며 본 앱의 출시된 지원 기능을 뜻하지 않습니다.

후속 검증: [Amazon·Walmart Android 실제 테스트](../android-amazon-walmart-webview-test-20261109/README.md). 위 비교표에 해당 결과를 반영했습니다.

수동 확인 후 후속 결과: [SHEIN 사용자 보안 확인 후 Android 테스트](../android-shein-manual-verification-20261109/README.md). WebView156에서 사용자가 보안 확인을 완료한 뒤 실제 사진과 페이지 내 MXN463.56 가격정보를 읽었습니다. 화면의 현재 판매가격은 미확정이며, 이전 WebView134 자동 테스트와 구분한 부분 검증입니다.

월마트 후속 검증: [Android에서 보안 확인 없이 사진·표시가격 읽기 성공](../android-walmart-manual-verification-20261109/README.md). 수동 보안 확인 완료 후의 경로는 해당 실행에서 미검증입니다.
