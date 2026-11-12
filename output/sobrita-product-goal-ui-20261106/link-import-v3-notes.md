# Sobrita 제품 목표 · 링크 우선 등록 제안 v3

2026-11-06. 디자인 제안이며 구현 또는 특정 쇼핑몰 호환성 검증을 완료한 상태가 아닙니다.

## 권장 진입점

- 쇼핑 앱/브라우저의 공유 메뉴에서 Sobrita를 선택합니다.
- Sobrita 목표 만들기에서 상품 링크를 붙여 넣습니다.
- 두 진입점은 같은 가져오기 및 확인 화면으로 연결됩니다.
- 사진/캡처 직접 선택과 사진 없는 등록은 보조 경로로 남깁니다.

## 확인 화면

- 가져올 수 있는 이미지, 상품 이름, 가격/통화를 먼저 채웁니다.
- 사용자가 이름과 목표 가격을 수정하거나 이미지를 변경할 수 있습니다.
- 이미 모은 돈은 접힌 선택 항목으로 둡니다.
- 기본 CTA는 Crear meta 하나입니다.
- 가격은 가져온 시점의 참고 값입니다. 자동 가격 추적은 포함하지 않습니다.
- 목표 금액은 사용자가 확인한 금액을 보존합니다.

## 부분 실패

사진/이름/가격 중 일부를 못 가져오더라도 가져온 정보와 링크를 보존합니다. 누락된 필수 항목만 입력받습니다. 사진은 필수가 아닙니다. 모든 상품 링크를 지원한다고 표시하지 않습니다.

## 확인된 기술 근거

- Android는 ACTION_SEND와 text/plain 등의 공유 데이터를 앱이 수신할 수 있습니다: https://developer.android.com/develop/ui/compose/sharing/receive
- Open Graph의 og:title/og:image/og:url에서 제목과 대표 이미지 후보를 읽을 수 있습니다: https://ogp.me/
- 제공되는 경우 Product/Offer 구조화 데이터에 상품명/이미지/가격/통화가 담길 수 있습니다: https://developers.google.com/search/docs/appearance/structured-data/product-snippet
- 개별 쇼핑몰에서 해당 정보가 실제로 접근 가능한지는 별도 테스트가 필요합니다. URL만으로 자동 수집 성공을 보장하지 않습니다.

시안의 tienda.example은 예시 도메인입니다. 이미지와 금액도 예시 데이터입니다.
생성 방식: 내장 ImageGen. 전체 프롬프트: create-link-v3-prompt.txt.

