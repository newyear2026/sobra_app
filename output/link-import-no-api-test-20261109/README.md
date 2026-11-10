# 멕시코 상품 링크 가져오기 — API 없는 실제 테스트

## 후속 검증: 일반 브라우저에서는 메르카도리브레 한 상품 확인 성공

같은 날 추가로 일반 데스크톱 브라우저에서 위 운동화 링크를 열었고, 별도 로그인 조작 없이 상품 화면이 표시됐습니다. 대표 사진이 실제로 로드된 것(600×600)과 사진 URL, 표시가격 **1,699페소**를 읽었습니다. 화면 상단은 `Crea tu cuenta`/`Ingresa` 상태였습니다. 사이즈는 `Elige`로 아직 선택하지 않았습니다.

이 결과는 **직접 HTTP 요청 실패와 구분해야 합니다.** 브라우저 환경에서는 한 상품의 화면을 읽는 데 성공했지만, Android WebView에서의 재현이나 완전 자동 가져오기를 검증한 것은 아닙니다. 브라우저 쿠키를 읽거나 내보내지 않았고, 세션에 쿠키가 전혀 없다고 검증하지도 않았습니다. 두 방식의 결과가 달라진 정확한 원인은 분리 검증하지 않았습니다.

이를 바탕으로 제안할 수 있는 다음 검증은 `앱 안에서 상품 페이지 열기 → 사용자가 상품 확인 → 이 상품으로 목표 만들기 → 사진·가격 확인` 흐름입니다. 페이지를 읽을 수 있는 WebView 구현이 필요하며, Chrome Custom Tabs는 앱에 전체 DOM 접근을 제공하지 않으므로 단순히 Custom Tab을 여는 것만으로 구현되지는 않습니다. [Android WebView](https://developer.android.com/reference/android/webkit/WebView), [Chrome Custom Tabs 접근 범위](https://chromium.googlesource.com/chromium/src/+/main/docs/security/custom-tabs-faq.md)

[브라우저 관찰 기록](mercadolibre/browser-result.json)

아래는 앞서 수행한 **직접 HTTP 요청 테스트**의 원래 결과입니다.

2026년 11월 9일 약 14:02–14:04, 멕시코시티 시간(20:02–20:04 UTC)에 공개 상품 페이지 네 개를 테스트했습니다.

## 결과

| 쇼핑몰 / 상품 | 상품 사진 | 페이지의 판매가격 | 결과 |
|---|---|---|---|
| [Amazon México — adidas 60s 4.0, 검정 24.5cm](https://www.amazon.com.mx/adidas-Tenis-Hombre-Casual-Negro/dp/B0DHZVB27Q) | 추출 성공, 공개 JPEG 응답 확인 | $1,349.00 | 성공 |
| [Amazon México — adidas Response Runner 2, 검정 26.5cm](https://www.amazon.com.mx/dp/B0F1X7M849) | 추출 성공, 공개 JPEG 응답 확인 | $1,242.66 | 성공 |
| [Mercado Libre — adidas JQ8645 운동화](https://articulo.mercadolibre.com.mx/MLM-3990889244-tenis-adidas-correr-hombre-negro-jq8645-_JM?searchVariation=190036940257) | 추출 실패 | 추출 실패 | 계정 확인 화면으로 이동 |
| [Mercado Libre — iPhone 15 128GB](https://www.mercadolibre.com.mx/apple-iphone-15-128-gb-azul-distribuidor-autorizado/p/MLM1027172667) | 추출 실패 | 추출 실패 | 계정 확인 화면으로 이동 |

가격은 테스트 당시 응답에서 선택된 옵션의 표시값입니다. 결제·배송비·쿠폰은 확인하지 않았습니다. `$`의 통화는 멕시코 사이트에 근거해 MXN으로 추정했으며, 구조화된 통화 필드를 별도로 추출한 것은 아닙니다.

## 테스트 방법

- 사용자가 요청한 공개 링크에 일반 HTTPS GET 요청을 보냈습니다.
- 쇼핑몰 API, API 키, 로그인, 저장된 쿠키, 유료 수집 서비스, 우회 프록시를 사용하지 않았습니다.
- User-Agent는 `Sobrita-LinkPreview-Test/1.0`으로 명시했습니다. 브라우저나 검색봇으로 가장하지 않았습니다.
- JavaScript나 브라우저는 실행하지 않았습니다. 응답 HTML에서 상품 정보 후보와 실제 상품 영역을 확인했습니다.
- 검색은 대표 상품 링크를 찾는 데만 사용했습니다. 검색 결과의 사진·가격을 가져오기 성공으로 계산하지 않았습니다.
- 초기 샌드박스 요청은 DNS 제한으로 실패했습니다. 네트워크 접근이 승인된 후 실제 사이트 응답으로 테스트했습니다. 해당 DNS 오류는 쇼핑몰 실패로 계산하지 않았습니다.

## 아마존에서 확인한 점

두 상품 모두 HTTP 200으로 상품 HTML을 반환했습니다. 대표 사진은 `#landingImage`의 `data-old-hires`/`src`, 실제 판매가격은 `#corePrice_feature_div .apex-pricetopay-value .a-offscreen` 영역에서 추출했습니다.

두 사진 URL에 소량의 이미지 바이트를 요청해 HTTP 206, `image/jpeg`, JPEG 시그니처를 확인했습니다. 전체 이미지 다운로드나 시각 비교를 수행한 것은 아닙니다.

첫 상품의 할부금 `$224.83`, 두 번째 상품의 할부금 `$414.22`와 기준가격 `$1,499.00`은 목표 가격 후보에서 제외했습니다.

이 두 응답에서는 범용 Open Graph 상품정보나 Product JSON-LD가 발견되지 않았습니다. **단순 링크 미리보기 추출만으로는 충분하지 않았고 아마존의 상품 HTML 구조를 읽는 별도 처리가 필요했습니다.** 페이지 구조 변경 시 추출 로직을 수정해야 할 수 있습니다.

## 메르카도리브레에서 확인한 점

첫 기본 curl 요청에서는 HTTP 403 오류 화면이 반환되었습니다. 재현 스크립트의 두 상품 요청에서는 최종 HTTP 200이었지만, 목적지는 `/gz/account-verification`이었습니다. 화면에는 `Para continuar, ingresa a tu cuenta`(계속하려면 계정에 로그인)가 표시되었습니다.

상품 사진·가격 데이터는 없었습니다. 발견한 Mercado Libre 로고는 상품 사진으로 계산하지 않았습니다. 계정 확인 화면에서 테스트를 중단했습니다.

## 제품에 적용할 판단

아마존은 API 없이 가져오는 시험 구현의 가능성을 확인했습니다. 메르카도리브레는 이번 비로그인 직접 요청 방식으로 성공하지 못했습니다. 따라서 초기 제품에서 두 쇼핑몰 모두 자동으로 가져온다고 안내할 근거는 없습니다.

가져오기에 성공하면 내용을 미리 채우고 사용자가 가격·옵션을 확인하게 합니다. 실패하면 상품 링크를 보관하고 목표 이름·금액을 직접 입력하게 하며 사진은 선택 사항으로 둡니다.

이는 쇼핑몰마다 두 상품, 한 네트워크 환경, 한 시점의 표본 테스트입니다. 모든 상품·짧은 공유 링크·다른 사용자 환경·지속적인 가격 갱신·앱 단말에서의 동작은 검증하지 않았습니다. 앱 소스에는 적용하지 않았습니다.

## 재현 자료

- [Amazon 결과 JSON](amazon/results.json)
- [Amazon 재현 스크립트](amazon/test_amazon.py)
- [Mercado Libre 결과 JSON](mercadolibre/results.json)
- [Mercado Libre 재현 스크립트](mercadolibre/probe.py)

각 Python 스크립트 실행은 공개 상품 페이지에 새 요청을 보내고 같은 폴더의 결과 JSON을 덮어씁니다. 결과·가격은 달라질 수 있습니다. Mercado Libre 스크립트는 시스템 `curl`을 사용합니다.
