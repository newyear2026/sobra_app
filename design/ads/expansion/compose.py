"""Stitch the proposed ad pieces into the real screens.

Run after `flutter test test/ad_expansion_proposal_test.dart --update-goldens`.
Reads raw/screen-*.png, raw/el-*.png and raw/anchors.json; writes
01..04 phone mockups and 00-overview.png next to this file.
"""

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).parent
RAW = HERE / "raw"
SCALE = 2
PHONE_H = 892  # logical px, ~19.5:9 at 412 wide
SURFACE = (255, 253, 247)
MARK = (212, 85, 63)
KO = "/System/Library/Fonts/AppleSDGothicNeo.ttc"


def font(size, bold=False):
    return ImageFont.truetype(KO, size, index=6 if bold else 0)


SCENES = [
    ("01-mission-xp.png", "missions", "missions", False),
    ("02-weekly-item.png", "collection", "collection", False),
    ("03-budget-native.png", "budget", "native", True),
    ("04-settlement-native.png", "settlement", "native", False),
]

CAPTIONS = [
    (
        "1  미션 XP 2배",
        "보상형 · 하루 1회 · 오늘의 미션 화면",
        ["오늘 받은 XP만큼 한 번 더 받기", "매일 다시 생기는 보상형 자리",
         "원칙 2(컬렉션만) 예외 필요"],
    ),
    (
        "2  이번 주 광고 아이템",
        "보상형 · 주마다 교체 · 컬렉션 맨 위",
        ["원칙 변경 없음", "매주 꾸미기 그림 1개 필요",
         "컬렉션 방문이 적으면 효과도 작음"],
    ),
    (
        "3  예산 탭 하단 네이티브",
        "네이티브 · 카테고리 목록 끝 · 5분 간격 공유",
        ["탭이라 방문이 많음", "맨 아래라 스크롤해야 보임",
         "늘어나는 양은 내역 탭과 겹치지 않는 방문만큼"],
    ),
    (
        "4  결산 네이티브",
        "네이티브 · 주기마다 1번 · 공유 카드 아래",
        ["주기 마감 때만 열림", "노출량이 작아 후순위",
         "'Listo' 버튼과 간격 유지"],
    ),
]


def compose(screen_name, element_name, scrolled):
    anchors = json.loads((RAW / "anchors.json").read_text())[screen_name]
    screen = Image.open(RAW / f"screen-{screen_name}.png").convert("RGB")
    element = Image.open(RAW / f"el-{element_name}.png").convert("RGB")
    y = int(anchors["insertAt"])
    nav = int(anchors["nav"])
    w, h = screen.size
    body = screen.crop((0, 0, w, h - nav))
    nav_strip = screen.crop((0, h - nav, w, h)) if nav else None
    eh = element.height

    stitched = Image.new("RGB", (w, body.height + eh), SURFACE)
    stitched.paste(body.crop((0, 0, w, y)), (0, 0))
    stitched.paste(element, (0, y))
    stitched.paste(body.crop((0, y, w, body.height)), (0, y + eh))

    view_h = PHONE_H - nav
    top = 0
    if scrolled:
        top = max(0, y + eh + 40 - view_h)
    view = stitched.crop((0, top, w, top + view_h))
    phone = Image.new("RGB", (w, PHONE_H), SURFACE)
    phone.paste(view, (0, 0))
    if nav_strip:
        phone.paste(nav_strip, (0, view_h))

    phone = phone.resize((w * SCALE, PHONE_H * SCALE), Image.NEAREST)
    draw = ImageDraw.Draw(phone)
    y0 = (y - top) * SCALE + 4
    y1 = (y - top + eh) * SCALE - 4
    _dashed_rect(draw, (8, y0, w * SCALE - 8, y1), MARK, 4)
    label = "새 광고 자리"
    f = font(22, bold=True)
    tw = draw.textlength(label, font=f)
    lx = w * SCALE - 8 - tw - 20
    ly = y0 - 34 if y0 > 40 else y1 + 4
    draw.rectangle((lx, ly, lx + tw + 20, ly + 32), fill=MARK)
    draw.text((lx + 10, ly + 3), label, font=f, fill="white")
    return phone


def _dashed_rect(draw, box, color, width, dash=16, gap=10):
    x0, y0, x1, y1 = box
    for (ax, ay, bx, by) in [(x0, y0, x1, y0), (x1, y0, x1, y1),
                             (x1, y1, x0, y1), (x0, y1, x0, y0)]:
        length = max(abs(bx - ax), abs(by - ay))
        steps = range(0, int(length), dash + gap)
        for s in steps:
            e = min(s + dash, length)
            if ax == bx:
                sign = 1 if by > ay else -1
                draw.line((ax, ay + sign * s, ax, ay + sign * e),
                          fill=color, width=width)
            else:
                sign = 1 if bx > ax else -1
                draw.line((ax + sign * s, ay, ax + sign * e, ay),
                          fill=color, width=width)


def framed(phone):
    pad = 14
    framed = Image.new("RGB", (phone.width + pad * 2, phone.height + pad * 2),
                       (32, 40, 72))
    framed.paste(phone, (pad, pad))
    return framed


def main():
    phones = []
    for out, screen, element, scrolled in SCENES:
        phone = compose(screen, element, scrolled)
        phone.save(HERE / out)
        phones.append(framed(phone))

    gutter = 56
    pw, ph = phones[0].size
    header = 150
    caption_h = 250
    board_w = gutter + len(phones) * (pw + gutter)
    board = Image.new("RGB", (board_w, header + ph + caption_h + gutter),
                      (246, 239, 224))
    d = ImageDraw.Draw(board)
    d.text((gutter, 44), "Sobrita 광고 추가 후보", font=font(52, True),
           fill=(32, 40, 72))
    d.text((gutter + 640, 62),
           "실제 화면 위에 제안한 광고만 덧붙인 시안 · 2026-11-09 · 번호는 추천 순서",
           font=font(28), fill=(84, 94, 126))
    for i, phone in enumerate(phones):
        x = gutter + i * (pw + gutter)
        board.paste(phone, (x, header))
        title, sub, notes = CAPTIONS[i]
        cy = header + ph + 28
        d.text((x, cy), title, font=font(38, True), fill=(32, 40, 72))
        d.text((x, cy + 56), sub, font=font(26, True), fill=(14, 122, 114))
        for j, note in enumerate(notes):
            d.text((x, cy + 100 + j * 40), "· " + note, font=font(26),
                   fill=(78, 88, 120))
    board.save(HERE / "00-overview.png")


if __name__ == "__main__":
    main()
