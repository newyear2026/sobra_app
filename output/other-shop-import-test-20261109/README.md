# 다른 멕시코 쇼핑몰 링크 — 소규모 HTTP 확인

2026-11-09. 공식 API·로그인·쿠키 가져오기 없이 공개 상품 페이지를 일반 HTTP GET으로 한 번씩 확인했습니다. JavaScript 실행이나 Android WebView 테스트는 하지 않았습니다. `User-Agent: Sobrita-LinkPreview-Test/1.0`, `Accept: text/html`, `Accept-Language: es-MX,es;q=0.9`를 사용했습니다.

| 쇼핑몰 | 검사한 상품 | 결과 |
|---|---|---|
| Walmart México | [Apple AirPods 4 Blancos](https://www.walmart.com.mx/ip/audifonos-inalambricos-apple-airpods-4-blancos/00019594968846) | HTML 200. 상품명·사진 URL·MXN 1,499 추출 성공 |
| Liverpool | [Adidas Grand Court](https://www.liverpool.com.mx/tienda/pdp/tenis-de-gamuza-grand-court-para-hombre/1175694731) | HTTP 403 Access Denied. 상품 정보 추출 실패 |

Walmart는 HTML에 포함된 JSON-LD `Product.offers.price`와 페이지 초기 데이터 `product.priceInfo.currentPrice`가 1499로 일치했습니다. 이전 가격 2999는 제외했습니다. 상품 대표 이미지에 비로그인 범위 요청을 보내 HTTP 206, `image/jpeg`, JPEG 헤더를 확인했습니다. 사진 파일 전체를 다운로드하거나 Android에서 렌더링한 검증은 아닙니다.

Liverpool은 웹 검색에서 상품이 확인됐지만 이번 일반 HTTP 요청은 차단됐습니다. Android에서도 실패한다는 뜻은 아니며, WebView에서는 별도 확인이 필요합니다. 다른 경로·사용자 에이전트·쿠키 등으로 차단 우회를 시도하지 않았습니다.

상품 1개씩에 대한 초기 확인입니다. 지역, 매장, 판매자, 옵션, 로그인, 쿠폰, 배송 조건에 따른 최종 가격은 확인하지 않았습니다. 상품 링크 자동 가져오기 구현은 사이트별 처리와 사용자 확인 단계가 필요합니다. Sobrita 본 앱 소스는 변경하지 않았습니다.

Amazon México는 [앞선 테스트](../link-import-no-api-test-20261109/amazon/README.md)에서 두 상품의 제목·사진·판매가(MXN 1,349 / 1,242.66)가 일반 HTML 요청으로 확인됐습니다. Amazon도 Android WebView에서의 확인은 별개입니다.

검증 파일: [요약 결과](results.json), [HTTP 기록](http_results.json), [이미지 응답 검사](walmart_image_check.json). `python3 summarize.py`는 저장된 HTML과 JSON으로 요약 결과를 재생성합니다.
