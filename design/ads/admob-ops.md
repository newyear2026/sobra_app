# AdMob 주간 운영

Sobra 광고를 늘리기 전에, 이미 있는 보상형·네이티브가 **유효 노출로 쌓이는지**를 본다.
Play 콘솔 수익과 AdMob 지급은 계정이 다르다. 세금·지급 프로필을 한쪽에만 맞추지 않는다.

최종 갱신: 2026-11-08

---

## 매주 볼 숫자

AdMob → 앱 → 광고 단위별로 본다. 합산만 보면 어느 포맷이 비었는지 모른다.

| 지표 | 보는 이유 |
| --- | --- |
| 요청 | SDK가 실제로 물어보는지 |
| 매칭(채우율) | 유닛·앱 검토·지역 문제인지 |
| 노출 | 로드만 되고 보이지 않는지 |
| eCPM | 포맷을 늘릴지, 숫자를 줄일지 |
| 무효 트래픽 | 실기기 테스트 클릭이 계정을 다치는지 |

출시 직후 낮으면 포맷을 추가하지 않는다. 먼저 앱 검토 승인, 광고 단위 상태, 테스트/프로덕션 유닛 혼선을 확인한다.

가계부 카테고리는 네트워크가 보수적으로 심의할 수 있다. 거래 금액·메모·영수증은 AdMob에 넘기지 않는 현재 정책을 유지한다.

---

## 보상형 광고가 표시되지 않을 때

Firebase Analytics에서 Sobrita 앱/데이터 스트림으로 필터링하고
`rewarded_ad_lifecycle` 이벤트의 `stage`와 실패 시의 `reason`을 확인한다.
기기에서 바로 볼 때는 logcat의 `Rewarded ad` 로그를 사용한다.
개발 빌드의 Firebase 수집은 README의 `TELEMETRY_ENABLED=true` 설정으로 켠다.

| stage | 의미 |
| --- | --- |
| `loadRequested` | SDK에 광고 로드 요청을 보냄 |
| `loaded` | 현재 요청의 광고를 받아 표시할 수 있는 슬롯에 보관함 |
| `loadFailed` | 로드 실패·시간 초과 또는 응답 시점에 광고 동의가 유효하지 않음 |
| `showRequested` | 표시 메서드 호출. 동의·준비 상태를 확인하는 단계도 포함 |
| `showed` | SDK가 전체 화면 표시를 확인함 |
| `impression` | SDK의 실제 노출 콜백을 받음 |
| `showFailed` | 표시 실패·시간 초과 또는 동의/준비 상태로 표시하지 못함 |
| `rewardEarned` | SDK가 보상 조건 충족을 확인함 |
| `dismissed` | 광고가 닫힘. 보상 조건 충족 여부와 별개 |

- `loaded`만 있고 `showRequested`가 없으면 미리 받은 광고를 표시하려는 시도가 없었다.
  앱 시작 시 사전 로드하는 현재 동작에서는 요청 수만 늘 수 있다.
- `loadFailed`/`showFailed`의 `reason`으로 `timeout`, `networkError`, `noFill`,
  `invalidRequest`, `appNotForeground`, `notReady`, `platformError` 등을 구분한다.
  로드와 표시의 SDK 오류 코드는 의미가 달라 각각 분류한다.
- Google 이외 도메인이나 알려지지 않은 SDK 코드는 `otherSdkError`로 기록한다.
  원래 도메인/숫자 코드는 기기 로그에서 확인한다. Analytics에는 정해진 enum 이름만 보낸다.
- 표시 시간 초과는 기다림을 끝내는 안전장치다. 이미 화면에 나온 광고를 제거하지 않으며,
  늦게 온 실제 노출·닫힘 콜백은 기록할 수 있다.
- `rewardEarned`는 SDK 확인이다. 실제 아이템 진행도 반영 여부는 기존
  `rewarded_ad_result`의 `counted` 및 `item_unlocked`로 확인한다.

노출은 `impression` 콜백으로만 기록한다. SDK 오류 원문·응답 ID·보상 금액은
분석 이벤트에 넣지 않는다. 확인은 테스트 광고로 하고 운영 AdMob 집계와 구분한다.
단계/실패 원인을 일반 Analytics 보고서에서 나눠 보려면 `stage`, `reason`을
이벤트 범위 맞춤 측정기준으로 등록한다. 실기기 검증에는 DebugView를 사용할 수 있다.

---

## 결제 프로필

- **Google Play**: 인앱 결제(캐릭터, 팩. 광고 제거는 팩에 포함)
- **AdMob**: 보상형·네이티브 광고 수익

RFC / W-8BEN 등은 두 콘솔에 각각 있어야 한다. Play에서 끝난 일이 AdMob 지급을 켜 주지 않는다.

---

## 광고 단위 (Android)

앱 ID: `ca-app-pub-2706404530136726~6701842938`

| 포맷 | 프로덕션 | 로컬 디버그/프로필(Google 샘플) |
| --- | --- | --- |
| 보상형 | `…/2239406637` | `ca-app-pub-3940256099942544/5224354917` |
| 거래 내역 네이티브 | `…/9277878691` | `ca-app-pub-3940256099942544/2247696110` |
| 예산 탭 네이티브 (`native_budget`) | **아직 없음** — 만들기 전까지 거래 내역 유닛을 씀 | `ca-app-pub-3940256099942544/2247696110` |
| 종료 팝업 소형·중형 (`native_exit`) | `…/3965250332` | `ca-app-pub-3940256099942544/2247696110` |

`native_budget`은 AdMob → 앱 → 광고 단위 추가 → 네이티브 고급형으로 만든다(형식 설정은 거래 내역 유닛과 같게).
만든 ID를 `AdMobConfig._androidBudgetNativeProduction`에 넣어야 콘솔에서 예산 탭 노출을 따로 볼 수 있다.
릴리즈 빌드에 바로 쓰려면 `--dart-define=SOBRA_BUDGET_NATIVE_AD_UNIT_ID=…`로도 된다.

소형·중형은 이미지·동영상을 허용하는 기존 `native_exit` 하나를 공유한다.
`SOBRA_EXIT_NATIVE_AD_UNIT_ID` 빌드 설정이 있으면 두 크기에 공통 적용된다.
별도의 소형 광고 단위를 만들거나 추가 ID를 연결할 필요가 없다.

Android 소형 팩토리는 수신한 소재의 동영상 여부를 확인한다. 이미지면 소형에 표시하고,
동영상이면 표시 전에 해제하여 광고 없는 팝업을 연다. 중형은 MediaView로 이미지·동영상을
모두 표시한다. 소형은 요청 단계에서 이미지만 제한하는 방식이 아니므로, 동영상 응답이나
미준비 상태에서는 광고가 생략될 수 있다. AdMob 콘솔 설정은 이 작업에서 변경하지 않았다.

릴리즈 빌드는 **기본으로 실제 광고를 게재한다.** 2026-10-12까지는 반대로 플래그를 켜야 광고가 나왔고,
그 플래그 없이 빌드한 1.0.5~1.0.12가 광고 없이 프로덕션에 나갔다. 그래서 기본값을 뒤집었다.

Google 샘플 유닛은 스토어에 게시하지 않는 로컬 빌드에서만 사용한다. 테스트 기기로 등록하지 않은
테스터에게 배포할 광고 없는 릴리즈 빌드가 필요하면
`flutter build appbundle --release --dart-define=SOBRA_DISABLE_LIVE_ADS=true`로 빌드한다.
개발 기기에서 프로덕션 광고를 누르지 않는다. 이미 배포된 릴리즈 빌드는 새 빌드로 교체될 때까지
기존 광고 설정을 계속 사용한다.

빌드에 광고가 들어갔는지 확인: AAB에서 `base/lib/arm64-v8a/libapp.so`를 꺼내
`strings libapp.so | grep -ci ConsentInformation`이 0이면 광고가 꺼진 빌드다.

iOS 유닛은 아직 만들지 않는다. `AdMobConfig.isSupported`가 Android만 연다.

---

## Play Console에 등록할 상품

비소모성. 코드의 ID와 한 글자도 달라지면 가격이 안 뜨고 살 수 없다.

| 상품 ID | 역할 |
| --- | --- |
| `sobra.supporter.bundle` | Los amigos de Michi: Tranqui·Lana·Bandi + 일반 광고 제거 (MX$89) |
| `sobra.character.capybara` / `.alpaca` / `.raccoon` | 개별 캐릭터 Tranqui·Lana·Bandi (각 MX$39). 팩에도 들어 있다 |
| `sobra.character.platypus` / `.rabbit` | 개별 캐릭터 Pico·Bunny (각 MX$39) |

- `sobra.character.10`은 이름이 정해지기 전까지 등록하지 않는다. 제품 ID는 한 번 만들면 다시 쓸 수 없다.
- `sobra.ads.remove`(일반 광고 제거 단품)는 2026-09-29 출시 전에 폐기했다. 광고 제거는 팩으로만 판다. 등록하지 않고, 이미 만들었다면 비활성화한다.

---

## 하지 않는 것

- 앱에 AdSense 스크립트·웹뷰 광고
- 고정 배너, 앱 오픈, 강제 전면
- 일 노출이 수천에 못 미치는 동안의 미디에이션
- iOS AdMob (유닛·ATT를 만든 뒤에만)
