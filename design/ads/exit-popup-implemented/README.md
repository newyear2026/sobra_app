# 구현 화면 캡처

## 실제 기기 지연 로딩 검증

- `late-load/before.png`: 광고 준비 전, 광고 없이 즉시 열린 팝업.
- `late-load/after.png`: 실제 SDK 광고 로딩 완료 후에도 같은 팝업 유지.
- 두 캡처는 별도로 촬영했으며 SHA-256까지 동일하다. 팝업은 368×177 dp,
  종료·취소 버튼의 좌표와 크기도 로딩 중 7회 측정 및 완료 후 모두 같았다.
- `late-load/sequence.mp4`: 약 29초 실제 Android 화면 녹화.
- `late-load/reopened-with-ad.png`: 닫았다 다시 열면 준비된 광고가 표시됨.
- `late-load/validation.json`, `late-load/sdk-events.log`: 실제 SDK 로딩/노출
  이벤트와 전후 좌표. 열린 동안 노출 0회, 다시 연 뒤 실제 노출 1회.
- 재현을 위해 **디버그 프리뷰에서 요청 시작만 잠시 보류**했다. 요청을
  진행한 뒤 약 2.93초 만에 실제 Google 테스트 광고가 로딩됐다. 광고
  응답이나 이미지를 모의로 대체하지 않았으며 프로덕션 팝업 코드는 그대로다.
- 재현 도구: `tool/capture_exit_late_load.py`. 프리뷰 빌드에
  `--dart-define=SOBRA_EXIT_PREVIEW_HOLD_AD_REQUEST=true`를 추가한다.

## 실제 SDK 광고 캡처 — 2026-11-07

- `device-small.png`: 실제 Google 테스트 광고, 자동 선택된 320×100 dp 소형.
- `device-medium.png`: 실제 Google 테스트 광고, 자동 선택된 320×350 dp 중형.
- `device-small-validator.png`: AdMob 검사기의 “No implementation issues found” 결과.
- `device-*-after.png` 및 대응 XML: 시간 경과 후에도 두 종료/취소 버튼의 좌표가 동일함을 확인한 증거.
- `device-validation.json`: 실제 네이티브 뷰 크기, 버튼 좌표 및 SDK 노출 확인 결과.
- 읽기 전용 독립 Android 16 에뮬레이터에서 `adb screencap`으로 직접 저장했다. 광고 이미지를 교체하거나 합성하지 않았다.
- 실제 종료 버튼을 눌러 Android 런처로 돌아가는 것까지 확인했다.

## 이전 위젯 렌더링 캡처

- `small.png`: 실제 Flutter 위젯, 360×580 dp 화면, 320×100 dp 광고 슬롯.
- `medium.png`: 실제 Flutter 위젯, 390×844 dp 화면, 320×350 dp 광고 슬롯.
- `without-ad.png`: 준비된 광고가 없는 상태. 이후 광고가 로딩되어도 변하지 않는다.
- 출력 밀도는 2배다. 광고 부분만 Google 공식 템플릿 참고 이미지이며, 실제 네트워크 광고의 캡처는 아니다. 실제 SDK에는 앱의 청록색 CTA 스타일을 전달한다.

참고 이미지 출처: [Google Native Templates](https://developers.google.com/admob/android/native/templates).
Flutter 기준: [Native templates](https://developers.google.com/admob/flutter/native/templates).

재현: `flutter test --no-pub tool/render_exit_popup_test.dart`

라이브 SDK 확인용 디버그 진입점: `tool/preview_exit_popup.dart`.
테스트 광고만 사용하며 가계부 데이터는 메모리에만 저장한다.
