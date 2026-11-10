# 금액 목표 — 실제 Flutter 구현 화면

현재 `SobraApp`, `HomeScreen`, `SavingsGoalCard`, `SavingsGoalScreen`을 테스트용 데이터로 렌더링한 이미지입니다. 이미지 생성 시안이나 설치된 에뮬레이터 캡처가 아닙니다. 기존 캐릭터 방, 실제 픽셀 폰트, 하단 메뉴를 그대로 사용합니다.

- `01-home-empty-ko.png`: 상품에 한정하지 않는 ‘무엇을 위해 모으고 싶나요?’ 초기 안내.
- `02-goal-type-choice-ko.png`: 금액 목표 / 사고 싶은 물건 선택.
- `03-amount-goal-editor-ko.png`: 사진·링크 없이 ‘1억 모으기’ 설정. 목표 100,000,000원, 이미 모은 금액 10,000,000원, 목표 날짜 선택 사항.
- `04-home-amount-goal-ko.png`: 방 아래의 금액 목표 카드. 사진 대신 목표 아이콘, 10% 진행률.

예시는 테스트 저장소의 통화를 명시적으로 KRW로 설정했습니다. 한국어를 선택했다고 통화가 자동 변경되거나, 실제 사용자 설정과 잔액이 바뀌지 않습니다. 날짜는 2026-11-09 오전 10시이며 모든 금액은 예시입니다. 논리 화면 390×844, PNG 780×1688입니다.

## 검증

12개 위젯 테스트 통과. 금액 목표 저장·재편집, 1억 원 단위 정확성, 링크 없는 상품 목표의 종류 유지, 상품에서 금액 목표로 바꿀 때 링크·사진·쇼핑몰 정보 제거, 기존 링크 가져오기·통화 불일치·삭제, 320dp/1.6배 글자 크기, 목표 생성 전후 캐릭터 방의 위치·정사각형 크기와 하단 메뉴 유지 등을 확인했습니다.

## 재생성

```sh
flutter test --no-pub --dart-define=CAPTURE_GOAL_UI=true test/savings_goal_screen_test.dart --plain-name 'home keeps its room and five tabs when the goal changes'
```

캡처 플래그가 없으면 테스트는 이미지 파일을 쓰지 않습니다.

[화면 모아보기](gallery.html)
