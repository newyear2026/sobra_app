"""Before/after board for the per-slot native ad gap (2026-11-10).

Stitches the real QA captures of Movimientos, Presupuesto and the exit
dialog into one image: before, one ledger ad held the other two slots for
five minutes; after, every slot keeps its own gap.

Run from the repo root: python3 design/ads/native-gap-per-slot/compose.py
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).parent
QA = ROOT / "design" / "qa"
EXIT = ROOT / "design" / "ads" / "exit-popup-implemented"
KO = "/System/Library/Fonts/AppleSDGothicNeo.ttc"

PAPER = (247, 243, 233)
INK = (30, 37, 66)
MUTED = (110, 112, 125)
TEAL = (15, 123, 108)
CORAL = (212, 85, 63)
CORAL_SOFT = (250, 226, 218)
TEAL_SOFT = (214, 238, 232)
GRAY_SOFT = (228, 226, 220)

PHONE_W, PHONE_H = 520, 1125
NAV_H = 72


def font(size, bold=False):
    return ImageFont.truetype(KO, size, index=6 if bold else 0)


def screen(path, top, remove_ad=None):
    """A phone-sized window of a tall golden with its bottom nav kept."""
    src = Image.open(path).convert("RGB")
    if remove_ad:
        x0, y0, x1, y1 = remove_ad
        bg = src.getpixel((10, y0 - 6))
        ImageDraw.Draw(src).rectangle((x0, y0, x1, y1), fill=bg)
    body_h = PHONE_H - NAV_H
    out = Image.new("RGB", (PHONE_W, PHONE_H), src.getpixel((10, top)))
    out.paste(src.crop((0, top, PHONE_W, top + body_h)), (0, 0))
    out.paste(src.crop((0, src.height - NAV_H, PHONE_W, src.height)), (0, body_h))
    return out


def exit_screen(path):
    return Image.open(path).convert("RGB").resize((PHONE_W, PHONE_H), Image.LANCZOS)


LEDGER_TOP, BUDGET_TOP = 0, 440
# Ad card bounds in each golden's own coordinates.
LEDGER_AD = (58, 574, 462, 679)
BUDGET_AD = (58, 1383, 462, 1490)
EXIT_AD = (46, 355, 474, 737)  # in the resized 520-wide exit capture


def framed(img, ad_box=None, blocked=False):
    pad = 14
    card = Image.new("RGB", (PHONE_W + pad * 2, PHONE_H + pad * 2), INK)
    card.paste(img, (pad, pad))
    d = ImageDraw.Draw(card)
    if ad_box:
        x0, y0, x1, y1 = ad_box
        d.rounded_rectangle(
            (x0 + pad - 8, y0 + pad - 8, x1 + pad + 8, y1 + pad + 8),
            radius=12, outline=TEAL, width=7,
        )
    if blocked:
        veil = Image.new("RGBA", card.size, (40, 40, 50, 70))
        card = Image.alpha_composite(card.convert("RGBA"), veil).convert("RGB")
    return card


def pill(d, cx, y, text, fg, bg, size=34):
    f = font(size, bold=True)
    w = d.textlength(text, font=f)
    h = size + 26
    d.rounded_rectangle((cx - w / 2 - 26, y, cx + w / 2 + 26, y + h), radius=h // 2, fill=bg)
    d.text((cx, y + h / 2), text, font=f, fill=fg, anchor="mm")


def main():
    ledger_ad = screen(QA / "native-ad-ledger.png", LEDGER_TOP)
    budget_ad = screen(QA / "native-ad-budget.png", BUDGET_TOP)
    budget_empty = screen(QA / "native-ad-budget.png", BUDGET_TOP, remove_ad=BUDGET_AD)
    exit_ad = exit_screen(EXIT / "medium.png")
    exit_empty = exit_screen(EXIT / "without-ad.png")

    def shift(box, top):
        return (box[0], box[1] - top, box[2], box[3] - top)

    rows = [
        (
            "변경 전  ·  5분 간격 하나를 세 자리가 함께 씀",
            [
                (framed(ledger_ad, shift(LEDGER_AD, LEDGER_TOP)), "광고 노출", True),
                (framed(budget_empty, blocked=True), "자리 없음", False),
                (framed(exit_empty, blocked=True), "광고 없이 종료 창", False),
            ],
            "내역에서 광고가 나온 뒤 5분 동안 예산 · 종료 자리 모두 막힘",
            "세션 결과: 네이티브 광고 1회",
        ),
        (
            "변경 후  ·  자리마다 5분 간격을 따로 셈",
            [
                (framed(ledger_ad, shift(LEDGER_AD, LEDGER_TOP)), "광고 노출", True),
                (framed(budget_ad, shift(BUDGET_AD, BUDGET_TOP)), "광고 노출", True),
                (framed(exit_ad, EXIT_AD), "광고 노출", True),
            ],
            None,
            "세션 결과: 네이티브 광고 최대 3회",
        ),
    ]
    steps = ["0:00  내역 탭", "1:00  예산 탭", "3:00  뒤로가기 → 종료"]

    margin, gap = 90, 70
    card_w = PHONE_W + 28
    card_h = PHONE_H + 28
    width = margin * 2 + card_w * 3 + gap * 2
    row_h = 90 + 64 + card_h + 100 + 64 + 30 + 110
    height = 170 + row_h * 2 + 40
    board = Image.new("RGB", (width, height), PAPER)
    d = ImageDraw.Draw(board)

    d.text((margin, 60), "네이티브 광고 5분 간격: 자리별 분리", font=font(56, True), fill=INK)
    d.text(
        (margin, 130),
        "같은 4분짜리 세션  ·  실제 앱 화면 (QA 캡처)  ·  초록 테두리 = 광고 카드",
        font=font(32), fill=MUTED,
    )

    y = 210
    for title, cards, bar, result in rows:
        d.text((margin, y), title, font=font(44, True), fill=INK)
        y += 90
        for i, (card, badge, shown) in enumerate(cards):
            x = margin + i * (card_w + gap)
            d.text((x + card_w / 2, y + 22), steps[i], font=font(34, True), fill=INK, anchor="mm")
            board.paste(card, (x, y + 64))
            pill(
                d, x + card_w / 2, y + 64 + card_h + 20, badge,
                TEAL if shown else MUTED, TEAL_SOFT if shown else GRAY_SOFT,
            )
        y += 64 + card_h + 100
        if bar:
            d.rounded_rectangle((margin, y, width - margin, y + 64), radius=10, fill=CORAL_SOFT)
            d.text((width / 2, y + 32), bar, font=font(32, True), fill=CORAL, anchor="mm")
        else:
            for i, name in enumerate(["내역", "예산", "종료"]):
                x = margin + i * (card_w + gap)
                d.rounded_rectangle((x, y, x + card_w, y + 64), radius=10, fill=CORAL_SOFT)
                d.text((x + card_w / 2, y + 32), f"{name}만 5분 막힘", font=font(32, True), fill=CORAL, anchor="mm")
        y += 64 + 30
        d.text((margin, y), result, font=font(38, True), fill=TEAL if bar is None else INK)
        y += 110

    out = HERE / "native-gap-per-slot.png"
    board.save(out)
    print(out, board.size)


if __name__ == "__main__":
    main()
