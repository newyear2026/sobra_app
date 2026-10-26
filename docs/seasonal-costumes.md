# 2026 가을 축제 코스튬

구현 기준일: 2026-10-24. 기존 캐릭터를 그대로 두고 캐릭터별 외형만 선택한다.
캐릭터 목록에는 Michi 카드 하나만 나오며 드라큘라 Michi를 별도 캐릭터로 등록하지 않는다.

## 획득과 사용

- 기기 현지 날짜 기준 **2026-10-23부터 2026-11-03까지** 홈 또는 컬렉션의 ‘가을 축제 선물’에서 12종을 한 번에 무료로 받는다. 온보딩 완료 후 노출되며 자동 팝업은 없다.
- 받은 의상은 기한 없이 보관한다. 이벤트 종료는 신규 수령만 막는다.
- 캐릭터 해제 조건은 기존 정책을 따른다. 아직 없는 캐릭터의 의상도 보관하고, 해당 캐릭터를 얻은 뒤 착용할 수 있다.
- `꾸미기 → 캐릭터 → 의상 바꾸기`에서 선택한 캐릭터의 기본 모습과 소장 의상만 표시한다.
- ‘이 의상 입히기’는 방에 미리 적용한다. 최종 저장은 꾸미기의 ‘완료’이며 ‘되돌리기’와 뒤로 가기 정책도 방 편집과 같다.
- 홈, 방, 컬렉션 썸네일, 공통 반응·축하 장면과 Android 홈 위젯에 저장된 의상을 반영한다.
- 한국어·스페인어·영어·포르투갈어·일본어·프랑스어·독일어 문구를 제공한다.

| 기존 캐릭터 ID | 이벤트 의상 |
| --- | --- |
| michi | 드라큘라 |
| poodle | 프랑켄슈타인 |
| schnauzer | 늑대인간 |
| guinea-pig | 호박 |
| capybara | 미라 |
| alpaca | 카트리나 |
| raccoon | 유령 해적 |
| platypus | 늪지 괴물 |
| rabbit | 달빛 마녀 |
| penguin | 칼라베라 음악가 |
| quokka | 허수아비 |
| maltese | 꼬마 유령 |

## 저장과 복원

`lib/models/character_costume.dart`가 캠페인 날짜, 기존 캐릭터와 의상 매핑의 기준이다.
의상 ID는 `autumn-2026-{characterId}`, 캠페인 ID는 `autumn-2026`이다.
다음 시즌을 추가하려면 기존 소유 ID를 바꾸지 않고 새 캠페인과 의상 정의를 추가해야 한다.
2027년에 자동으로 재개되는 반복 이벤트가 아니다.

저장 스키마 11에는 `ownedCostumeIds`, `claimedCostumeCampaignIds`, `costumeSelections`가 추가된다.
스키마 10 이하에서는 빈 값으로 시작한다. 백업으로 무료 의상과 수령 기록을 이전할 수 있으며,
오래된 백업을 가져와도 현재 기기에서 받은 의상은 회수되지 않는다.
유료 캐릭터 소유권은 기존 구매 복원 정책을 따르며 의상 백업으로 해제되지 않는다.
알 수 없는 미래 의상 ID는 보존하되 기본 모습으로 표시한다.

선물 지급과 방·캐릭터·의상 저장은 각각 직렬화된 저장 작업이다.
날짜와 중복 수령 여부를 저장 작업 안에서 다시 검사한다.
저장 실패 시 소유권, 선택, 방 편집을 롤백하고 성공 알림을 보내지 않는다.

## 이미지와 모션 형식

연속 프레임 v2는 `assets/costumes/autumn_2026/motion_v2/`의 **72개 투명 WebP(색상 q90, 알파 무손실)**이다.
12종 각각 대기·걱정 8프레임과 이동·계산·저축·축하 12프레임, 총 64프레임 구성을 제공한다.
각 시트는 4열이며 8프레임은 2행, 12프레임은 3행이다. 눈·귀·발·소품 동작을 프레임마다 그렸다.
이전 3×2 자세 시트는 원화 기록으로 남고 앱 번들에는 넣지 않는다.
PNG 원본은 `motion-v2/raw/{id}/`에 보존한다. `python3 tool/package_costume_motion_assets.py`(Pillow 필요)로
색상은 품질 90 손실 WebP, 알파는 무손실로 인코딩한다. 변환 후 알파 채널이 원본과 바이트 단위로 같은지,
알파 가중 PSNR이 28dB 이상인지 검사한다. 알파가 같으므로 원본 PNG로 측정한 프레임 좌표가 그대로 맞는다.

2026-10-26에 무손실에서 q90으로 바꿨다. 무손실 72장은 129,016,404바이트로, 기존 에셋에 더하면 기기당 다운로드가
Play 한도(200MB)를 넘을 상황이었다. q90은 원본 PNG 172,526,878바이트 대비 32,221,380바이트(81.3% 감소)이며,
시트별 알파 가중 PSNR은 29.2~38.2dB이다. 무늬가 촘촘해 수치는 낮지만 화면 크기와 확대 비교에서 차이가 보이지 않았다.
비교 이미지는 `design/seasonal/2026-halloween-dia-de-muertos/compression/webp-q90-q80-compare.png`이다.
`test/character_costume_animation_test.dart`가 72장 합계 40MB 미만을 검사한다.

`CostumeMotionPainter`는 등록된 실제 프레임을 재생한다. 기준 캔버스는 320×360,
바닥선은 y=344이다. 소스 아틀라스는 변경하지 않고 프레임별 좌표로 접지·배율·축하 점프를 정렬한다.
대기 2.8초, 이동 1.8초, 계산 3.6초, 저축 4초는 반복하며 마지막 자세를 처음과 연결한다.
계산기는 루프 내내 보관하고, 저축에서는 동전을 놓지 않고 들었다 내리는 동작으로 연결한다.
축하는 2.2초의 준비·점프·착지 후 대기 원화로 유지한다. 해적 너구리는 해부 구조를 수정한 자체 착지 프레임을 유지한다. 걱정은 1.6초 후 걱정 자세를 유지한다.
동작 줄이기에서는 각 역할의 대표 프레임으로 정지하며 재생 토큰과 완료 콜백도 기존 계약을 따른다.
Android 위젯도 동일 시퀀스에서 실제로 그린 대기 4장 또는 저축 5장을 추출한다.

이미지는 내장 **image_gen** 도구로 제작했다. 새 생성 프롬프트와 파일 대응 기록은
`design/seasonal/2026-halloween-dia-de-muertos/motion-v2/generation-manifest.json`에 보관한다.
`python3 tool/build_costume_motion_metadata.py`는 투명도·프레임 분리·원화 중복을 검사하고
`motion_v2/layout.json`, `lib/data/costume_motion_atlases.dart`와 검증 보고서만 작성한다. PNG를 수정하지 않는다.
과거 자세 시트 프롬프트는 `motion-v1/generation-prompts.json`에 보존한다.

## 팔다리 구조 수정

사용자가 지적한 중복 발을 기존 원화와 대조해 다음 여섯 시트, 72프레임을 수정했다.
원본은 `motion-v3-anatomy/before/`, 내장 image_gen 수정 프롬프트와 결과는
`motion-v3-anatomy/generation-manifest.json`, 확대 검수표와 재생 GIF는 같은 폴더에 있다.
그 외 66개 시트의 원본과 앱 이미지가 바뀌지 않은 것도 해시로 확인한다.

| 시트 | 팔다리 구조 |
| --- | --- |
| 카피바라 저축 | 뒷발 둘은 바닥, 앞발 하나는 배 위, 다른 앞발은 동전. 바닥에 남은 앞발 복제 제거 |
| 토끼 저축 | 앞발 둘은 각각 빗자루·동전, 바닥에는 뒷발 둘만 표시 |
| 알파카 저축 | 바닥의 다리 셋과 기존 앞다리에서 이어지는 들어 올린 다리 하나. 목에서 나온 추가 팔 제거 |
| Happy 저축 | 뒷발 둘·배 위 앞발·동전 앞발. 망토 오른쪽 아래에 남은 작은 다섯 번째 발도 제거 |
| Miru 저축 | 검은 뒷발 부츠 둘·바닥 앞발 하나·동전 앞발 하나. 시작·끝의 중복 앞발 제거 |
| 해적 너구리 축하 | 앞발 둘·뒷발 둘을 같은 다리로 이어서 점프·착지. 들어 올린 앞발의 바닥 복제 제거 |

팔다리 수와 연결은 확대된 프레임과 움직임으로 직접 검수한다.
투명도·분리 좌표·프레임 수의 자동 검사는 별도로 실행한다.
검수 화면 재생성: `flutter test tool/render_costume_anatomy_review_test.dart`.

## 검증과 확인 화면

- 날짜 경계, 동시 중복 수령, 캐릭터 잠금, 이벤트 이후·재시작·백업 복원, 저장 실패 롤백을 테스트한다.
- 모든 앱용 이미지의 투명도·8/12개 연속 프레임·표시 영역과 Dart/Android 메타데이터 일치를 검사한다.
- 대기·한 번의 축하 완료·동작 줄이기, 의상 미리보기·되돌리기·완료·취소 흐름을 테스트한다.
- 320×568 화면의 한국어·독일어 1.6배 글씨에서 선택 창을 검사한다.
- 실제 Flutter 위젯 트리의 캡처: `design/seasonal/2026-halloween-dia-de-muertos/implementation/`.
- 캡처 재생성: `flutter test test/character_costume_flow_test.dart --dart-define=COSTUME_SCREENSHOTS=true`.
- 전체 프레임 검수표: `motion-v2/contacts/{id}.png`. 생성 명령은 `flutter test tool/render_costume_contacts_test.dart`.
- 실제 앱 렌더러의 모션 GIF: `motion-v2/previews/{id}.gif`와 `gallery.gif`.
  `flutter test tool/render_costume_motion_previews_test.dart` 다음 `sh tool/encode_costume_motion_previews.sh`로 재생성한다.
- Android 코드는 debug APK 빌드로 확인한다. 실기기 홈 런처의 위젯 표시 검수와 스토어 배포는 별도다.

2026-10-24 연속 모션 v2 검증 결과: `flutter analyze --no-pub lib test tool/render_costume_contacts_test.dart tool/render_costume_motion_previews_test.dart` 오류·경고 없음.
`flutter test --no-pub --dart-define=COSTUME_SCREENSHOTS=true` 전체 **911개 통과, 3개 건너뜀**.
`flutter build apk --debug --no-pub` 성공. 결과는 `build/app/outputs/flutter-apk/app-debug.apk`이며,
APK 내부에 코스튬 WebP 72개(당시 무손실)와 `motion_v2/layout.json`이 포함되고, 이전 정지 자세 시트가 포함되지 않은 것을 확인했다.
검수표와 재생 미리보기 출력 테스트 2개도 통과했다. 각 캐릭터 GIF는 48프레임/4.8초,
12종 대기 모션 모음은 28프레임/2.8초이며 실제 앱의 프레임 선택·접지·착지 렌더러를 그대로 사용한다.
팔다리 수정 후 모션·착지 및 렌더링 검증 8개가 통과했고, APK의 여섯 수정 이미지가
확대 검수한 파일과 같은지도 해시로 대조했다. 수정본 모음은 `motion-v3-anatomy/repaired-motions.gif`이다.
q90 전환 뒤에는 앱 이미지가 원본과 바이트 단위로 같지 않으며, 대조 기준은 `motion-v2/raw/`의 PNG이다.

2026-10-26 q90 전환 검증 결과: `flutter analyze --no-pub lib test` 오류·경고 없음.
`flutter test --no-pub --dart-define=COSTUME_SCREENSHOTS=true` 전체 **912개 통과, 3개 건너뜀**.
debug APK에 q90 WebP 72개(약 32.4MB)가 포함된 것을 확인했다.
`flutter build apk --release --split-per-abi --target-platform android-arm64` 결과는 **201.6MB**이다.
방 배경 70.5MB, 기본 캐릭터 69.2MB, 코스튬 32.2MB가 대부분이었다.
같은 날 방·가구·기본 캐릭터 PNG 135장도 q90 WebP로 바꿨다(`tool/package_app_art.py`, 원본은 `design/png-sources/`).
139,619,550바이트가 22,159,376바이트로 줄었고, 시트별 알파 가중 PSNR 최저값은 32.2dB이다.
그 뒤 같은 명령으로 빌드한 arm64 릴리스 APK는 **84.2MB**이다. `test/app_art_budget_test.dart`가
방·캐릭터·코스튬 폴더에 PNG가 없고 합계가 70MB 미만인지 검사한다. 시각 회귀 기준 이미지 44장은
압축 색 차이(평균 2단계 미만)만 확인한 뒤 갱신했다. 전체 테스트 913개 통과, 3개 건너뜀.
