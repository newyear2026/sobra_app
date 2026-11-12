# Amazon México: API 없는 링크 정보 추출 테스트

결과: 테스트한 상품 링크 2개에서 사진과 현재 기본 구매 가격을 추출했습니다. 이 결과는 모든 상품·모든 접속 환경의 성공을 보장하지 않습니다.

방법: Python 표준 라이브러리로 공개 상품 HTML을 직접 GET했습니다. API 키, 로그인, 쿠키, 브라우저 실행, 프록시, 유료 수집 서비스를 사용하지 않았습니다. User-Agent는 `Sobrita-LinkPreview-Test/1.0`입니다. 기본 sandbox는 DNS 제한으로 접속하지 못했고, 네트워크 허용 실행에서는 실제 HTTP 200 응답을 받았습니다. 우회나 CAPTCHA 해결은 수행하지 않았습니다.

## 관측 결과

- URL: https://www.amazon.com.mx/adidas-Tenis-Hombre-Casual-Negro/dp/B0DHZVB27Q
  - UTC: 2026-11-09T20:02:30.659061+00:00
  - 페이지 제목: adidas 60s 4.0 Tenis para Hombre, Color Negro de Adulto 24.5 cm : Amazon.com.mx: Ropa, Zapatos y Accesorios
  - HTTP: 200
  - 현재 기본 구매 가격: $1,349.00
  - 가격 추출 위치: `#corePrice_feature_div .apex-pricetopay-value .a-offscreen`
  - 대표 이미지: https://m.media-amazon.com/images/I/41htbB8LhEL._AC_SL1100_.jpg
  - 이미지 확인: HTTP 206, image/jpeg, JPEG 헤더 확인
  - 제외한 가격: [{"display": "$224.83", "reason": "installment amount"}]

- URL: https://www.amazon.com.mx/dp/B0F1X7M849
  - UTC: 2026-11-09T20:02:34.234096+00:00
  - 페이지 제목: adidas Tenis Response Runner 2 Unisex Correr Negro 26.5 cm : Amazon.com.mx: Ropa, Zapatos y Accesorios
  - HTTP: 200
  - 현재 기본 구매 가격: $1,242.66
  - 가격 추출 위치: `#corePrice_feature_div .apex-pricetopay-value .a-offscreen`
  - 대표 이미지: https://m.media-amazon.com/images/I/61IrMdcYjaL._AC_SL1500_.jpg
  - 이미지 확인: HTTP 206, image/jpeg, JPEG 헤더 확인
  - 제외한 가격: [{"display": "$1,499.00", "reason": "reference/list price"}, {"display": "$414.22", "reason": "installment amount"}]

## 구현 판단

- 두 페이지에서 일반 Open Graph 상품 메타 정보와 Product JSON-LD는 발견하지 못했습니다. 성공한 방식은 Amazon 전용 HTML 요소 추출입니다.
- 대표 이미지는 `img#landingImage`의 `data-old-hires` 또는 `src`에서 가져왔습니다.
- 가격은 선택된 상품 ASIN의 기본 구매 영역에서 읽었으며, 할부 1회 금액과 원래 가격을 제외했습니다.
- 표시 금액의 통화 MXN은 amazon.com.mx 마켓을 근거로 추정했으며 별도의 구조화 통화 필드를 얻은 것은 아닙니다.
- 배송비·추가 쿠폰·회원 가격·다른 사이즈 가격은 확인하지 않았습니다.
- 페이지 구조 변경이나 접속 조건에 따라 실패할 수 있으므로 수동 확인·수정 화면이 필요합니다.
- `results.json`은 추출 필드와 HTTP 결과를 저장합니다. 원문 HTML·세션 쿠키는 저장하지 않습니다.

재실행: `python3 test_amazon.py` (공개 인터넷 접근 필요)
