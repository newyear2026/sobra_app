# Sobra 캐릭터 애니메이션 규격 v2

캐릭터의 외형이 바뀌어도 앱의 상태와 동작 의미가 흔들리지 않도록, 파일명은
행동 묘사가 아니라 아래 여섯 가지 **역할(role)** 을 사용한다.

| 역할 | 의미 | 기본 재생 | 기존 Michi 동작 |
| --- | --- | --- | --- |
| `idle` | 대기·휴식 | 반복 | `idle` |
| `activity` | 이동·진행 중 | 반복 | `walk` |
| `processing` | 계산·분석 중 | 반복 | `calculate` |
| `positive` | 저축·긍정적 변화 | 반복 | `saving` |
| `success` | 완료·성취 | 1회 후 유지 프레임 표시 | `celebrate` |
| `warning` | 주의·예산 초과 | 1회 후 유지 프레임 표시 | `concern` |

## 필수 이미지 계약

- 가로형 PNG 스프라이트 시트 1개에 프레임 8개
- 전체 크기 `2560×360px`, 개별 프레임 `320×360px`
- RGBA 투명 배경, 최근접 보간(Nearest Neighbor), 프레임 간 팔레트 유지
- 캐릭터 기준점 `x=160`, 바닥선 `y=344`
- 상하좌우 최소 안전 여백 `16px`
- 여덟 프레임의 합집합 영역을 비율 유지한 채 안전영역 안에서 최대화
- 파일명 `{role}-8.png`
- 폴더 `assets/characters/{characterId}/`

캐릭터별 세부 정보와 타이밍은 같은 폴더의 `character.yaml`에 기록한다.
새 캐릭터는 여섯 역할을 모두 제공해야 하며, 앱에서는
`CharacterSprite(characterId: ..., role: ...)`로 호출한다.
앱의 캐릭터별 `CharacterDefinition`도 같은 값을 사용하며, 캐릭터 고유의
`playRange`, `posterFrame`, `holdFrame`이 다른 캐릭터에 전파되면 안 된다.

## 재생 프레임 계약

- 프레임 번호는 `0`부터 시작한다.
- `playRange: [start, end]`는 실제로 재생할 프레임 구간이며 양 끝을 포함한다.
- `posterFrame`은 축소 모션 또는 정적 표시에서 사용하는 대표 프레임이다.
- `holdFrame`을 생략하면 1회 재생 후 `playRange`의 마지막 프레임을 유지한다.
- `holdFrame`은 루프용으로 제작된 기존 에셋의 호환에만 사용한다.
- 신규 `once-hold` 에셋은 `playRange`의 마지막 프레임 자체가 유지 가능한
  포즈여야 한다.

## 품질 확인

1. 여덟 프레임 모두 비어 있지 않은지 확인한다.
2. 발이 땅에 닿는 프레임은 공통 바닥선을 유지한다.
3. 루프 동작은 8→1 전환에서 튀지 않아야 한다.
4. 신규 `success`와 `warning`은 재생 구간의 마지막 프레임만 보여도 의미가
   전달되어야 한다.
5. 축소 모션 설정에서는 매니페스트의 `posterFrame`을 사용한다.

Michi 원본을 다시 정규화하거나 규격을 검사하려면 다음을 실행한다.
(Python Pillow 패키지가 필요하다.)

```sh
python3 tool/normalize_character_sprites.py
python3 tool/normalize_character_sprites.py --check
```

새 캐릭터의 원본 여섯 시트를 역할 이름으로 준비한 뒤 같은 도구를 재사용한다.

```text
design/animations/luna/
├── idle-8.png
├── activity-8.png
├── processing-8.png
├── positive-8.png
├── success-8.png
└── warning-8.png
```

```sh
python3 tool/normalize_character_sprites.py \
  --character-id luna \
  --source-dir design/animations/luna
python3 tool/normalize_character_sprites.py --character-id luna --check
```

생성 후 `assets/characters/luna/character.yaml`을 Michi 매니페스트에서 복사해
캐릭터 이름과 필요한 접근성 문구를 바꾸고, `pubspec.yaml`에 새 폴더를 등록한다.
