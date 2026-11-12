Sobrita 한국어·일본어 홍보 영상

한국어: sobrita-promo-ko-1080x1920.mp4
日本語: sobrita-promo-ja-1080x1920.mp4
규격: 각각 20초 / 1080×1920 / 세로 9:16 / 30fps
인코딩: H.264 MP4 / yuv420p / AAC 스테레오

원본과 같은 5개 장면 구성으로 제작했습니다.
화면의 광고 문구와 실제 앱 UI를 한국어·일본어로 현지화했습니다.
지출 입력 장면은 한국어 KRW, 일본어 JPY 예시 데이터를 사용합니다.
예시 금액은 환율 환산값이 아닙니다.
일부 캐릭터 유료 안내와 데모 데이터 안내를 각 언어로 유지했습니다.
원본에는 내레이션이 없으며, 배경음악은 재인코딩 없이 그대로 사용했습니다.
원본과 완성본의 AAC 오디오 해시가 동일함을 확인했습니다.
각 MP4의 600프레임, 길이, 해상도를 확인하고 전체 디코딩 검사도 통과했습니다.

포스터 JPG는 영상의 1초 지점에서 추출했습니다.
생성 및 검증 정보: manifest.json, validation-ko.json, validation-ja.json
제작 소스: tool/render_promo_video_localized_test.dart (프로젝트 기준)
영상 결합 스크립트: output/sobrita-videos-ko-ja-20261020/encode_videos.py

다시 만들기 (프로젝트 루트에서):
python3 output/sobrita-videos-ko-ja-20261020/prepare_fonts.py
flutter test --no-pub tool/render_promo_video_localized_test.dart --dart-define=PROMO_LANGUAGE=ko --reporter expanded
flutter test --no-pub tool/render_promo_video_localized_test.dart --dart-define=PROMO_LANGUAGE=ja --reporter expanded
python3 output/sobrita-videos-ko-ja-20261020/encode_videos.py

기존 원본 파일과 앱 소스는 수정하지 않았습니다.
