"""Builds the Play Console phone screenshots (1080x1920) from real captures.

A store listing is read as one image: the icon, the feature graphic and the
screenshot strip sit within a screen's width of each other. So the screenshots
are built on the same two things the other two are built on — the ink navy and
the graph-paper grid at the icon's own 32px pitch — and the phone is framed the
way the app frames its own cards, with a hard two-and-a-half-pixel border and an
offset shadow rather than a rounded glossy device mock. Nothing here is a
rounded rectangle, because nothing in the app is: `_shape` in app_theme.dart is
`BorderRadius.zero` and the frame follows it.

The screens inside the frames are captures from the release build running on a
phone, not mockups, so what the listing promises is what installs. `capture.py`
next door takes them, and says what it needs of the device — a release build in
particular, because a debug build resolves the AdMob test unit and Play does not
allow ads in a screenshot.

Type follows the app. Latin runs are set in PixelifySans, the app's own face,
and Hangul in Noto Sans KR — which is not a compromise but a copy of what the
app itself does: Flutter falls back to the platform's Hangul face for every
Korean string in the app, and on Android that face is Noto Sans CJK. So the
headline over a Korean screenshot is set in the same two faces, in the same
pairing, as the screen beneath it. Runs are split per character and drawn on a
shared baseline, which is what a text engine would do and what PIL will not.

Three locales come out of one copy table. The feature graphic could stay
textless and serve all three; a screenshot cannot, because the screen inside it
is already in one language and a headline in another would read as an error.

Play wants 16:9 or 9:16 and each side between 320 and 3840px; 1080x1920 is the
9:16 that matches the capture's own width, so the screen is placed at a whole
fraction of its pixels and the pixel art stays on the pixel grid.
"""

from __future__ import annotations

import importlib.util
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
SHOTS = HERE / "shots"
OUT = HERE / "screenshots"


def _icons():
    """The icon builder, imported for its palette and its grid."""
    path = HERE.parent / "icon" / "build_icons.py"
    spec = importlib.util.spec_from_file_location("build_icons", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)  # main() is __main__-guarded, so this is inert
    return module


icons = _icons()

WIDTH, HEIGHT = 1080, 1920
CELL = 32                      # the icon's pitch, so all three assets share a sheet

# AppColors, and two lifts of it. The app's teal and cash gold are drawn on
# cream and are far too dark to sit on the navy field — teal at #0E7A72 is a
# 1.9:1 contrast against it — so each gets a tint that holds the same hue at the
# lightness this background needs.
CREAM = (0xFC, 0xEE, 0xD3)     # the calico's body: the icon's own lightest value
PAPER = (0xF6, 0xEF, 0xE0)     # AppColors.paper
TEAL_LIFT = (0x6F, 0xD6, 0xC6)
MUTED = (0x9E, 0xAA, 0xC8)     # AppColors.muted, lifted off the navy

FRAME_BORDER = 7
SHADOW_OFFSET = 14
SHADOW = (0x14, 0x19, 0x30)

SCREEN_WIDTH = 720             # 1080 * 2/3, keeping the capture on whole pixels
SCREEN_TOP = 452

# The phone's status bar is cropped off every capture. The frame is holding the
# app, not the handset, and the clock and signal bars are the one part of the
# image that is neither Sobrita nor true of the reader's phone. It also keeps a
# capture honest when the device it came from had no working network: the
# emulator draws its wifi glyph with a no-internet mark, and cropping is a
# cleaner answer than a status bar that has to be faked back in. Measured, not
# guessed: the bar's glyphs end at y=49 on every screen and the app's own
# padding runs well past y=99.
STATUS_BAR = 56

HEAD_SIZE = 66
HEAD_LEAD = 90
SUB_SIZE = 34
MARGIN = 84

PIXEL_FONT = REPO / "assets" / "fonts" / "PixelifySans.ttf"
HANGUL_FONT = HERE / "fonts" / "NotoSansKR-Bold.ttf"

# One row per screenshot: the capture's basename, then per locale a headline
# (one entry per line) and a single supporting line. The headlines name what the
# screen below already shows, in the app's own register — plain, unhurried, and
# never a promise the screen does not keep.
COPY = {
    "1-home": {
        "en": (["Today's money,", "already worked out"], "Your quincena, divided into days."),
        "ko": (["오늘 쓸 돈은", "이미 정해져 있어요"], "급여일까지 남은 돈을 하루 단위로."),
        "es": (["Lo de hoy,", "ya calculado"], "Tu quincena, repartida por día."),
    },
    "2-entry": {
        "en": (["Log it in", "three taps"], "Amount, category, saved."),
        "ko": (["세 번 누르면", "기록 끝"], "금액, 분류, 저장."),
        "es": (["Anótalo en", "tres toques"], "Monto, categoría, listo."),
    },
    "3-budget": {
        "en": (["Every category", "has a ceiling"], "See where the quincena goes."),
        "ko": (["분류마다", "한도가 있어요"], "이번 주기의 돈이 어디로 가는지."),
        "es": (["Cada categoría", "con su límite"], "Mira a dónde se va la quincena."),
    },
    "4-activity": {
        "en": (["Your days,", "side by side"], "One bar a day against your limit."),
        "ko": (["하루하루를", "나란히"], "하루치 지출을 한도와 나란히."),
        "es": (["Tus días,", "uno junto a otro"], "Cada día frente a tu límite."),
    },
    "5-room": {
        "en": (["Someone keeps", "the numbers with you"], "Michi counts. You keep the room."),
        "ko": (["혼자 세지 않아도", "괜찮아요"], "숫자는 미치가, 방은 당신이."),
        "es": (["Alguien lleva", "la cuenta contigo"], "Michi, con los números; tú, con la casa."),
    },
    "6-cash": {
        "en": (["Count the cash,", "find the gap"], "It finds the expense you never wrote down."),
        "ko": (["지갑을 세면", "차이가 보여요"], "기록하지 않은 지출을 찾아줘요."),
        "es": (["Cuenta el efectivo", "y aparece el hueco"], "Encuentra el gasto que no anotaste."),
    },
}

ORDER = ["1-home", "2-entry", "3-budget", "4-activity", "5-room", "6-cash"]
LOCALES = ["en", "ko", "es"]


def grid_field(width: int, height: int) -> Image.Image:
    """Navy with the icon's faint graph-paper grid, at the icon's pitch."""
    field = Image.new("RGBA", (width, height), (*icons.NAVY, 255))
    lines = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    pen = ImageDraw.Draw(lines)
    stroke = max(1, round(width / 512))
    ink = (*icons.GRID, icons.GRID_ALPHA)
    for x in range(CELL, width, CELL):
        pen.line([(x, 0), (x, height)], fill=ink, width=stroke)
    for y in range(CELL, height, CELL):
        pen.line([(0, y), (width, y)], fill=ink, width=stroke)
    return Image.alpha_composite(field, lines)


class Type:
    """PixelifySans with a Hangul face behind it, split per character.

    PIL has no font fallback, so a Korean headline set in PixelifySans alone
    comes out as a row of empty boxes. This walks the string, breaks it where
    the coverage changes, and draws each run from a shared baseline.
    """

    def __init__(self, size: int, weight: int = 700):
        self.latin = ImageFont.truetype(str(PIXEL_FONT), size)
        self.latin.set_variation_by_axes([weight])
        self.hangul = ImageFont.truetype(str(HANGUL_FONT), size)
        self.covered = _coverage(PIXEL_FONT)

    def runs(self, text: str):
        out = []
        for ch in text:
            font = self.latin if ord(ch) in self.covered else self.hangul
            if out and out[-1][0] is font:
                out[-1][1] += ch
            else:
                out.append([font, ch])
        return out

    def width(self, text: str) -> float:
        return sum(font.getlength(run) for font, run in self.runs(text))

    def draw(self, pen: ImageDraw.ImageDraw, xy, text: str, fill):
        x, baseline = xy
        for font, run in self.runs(text):
            pen.text((x, baseline), run, font=font, fill=fill, anchor="ls")
            x += font.getlength(run)


def _coverage(path: Path) -> set[int]:
    from fontTools.ttLib import TTFont

    with TTFont(str(path)) as font:
        return set(font.getBestCmap())


def frame(canvas: Image.Image, shot: Image.Image, top: int) -> None:
    """Place the capture in the app's own card: hard border, offset shadow."""
    scale = SCREEN_WIDTH / shot.width
    screen = shot.resize((SCREEN_WIDTH, round(shot.height * scale)), Image.LANCZOS)

    left = (WIDTH - SCREEN_WIDTH) // 2
    box = (
        left - FRAME_BORDER,
        top - FRAME_BORDER,
        left + screen.width + FRAME_BORDER,
        top + screen.height + FRAME_BORDER,
    )
    pen = ImageDraw.Draw(canvas)
    pen.rectangle(
        [box[0] + SHADOW_OFFSET, box[1] + SHADOW_OFFSET, box[2] + SHADOW_OFFSET, box[3] + SHADOW_OFFSET],
        fill=(*SHADOW, 255),
    )
    pen.rectangle(box, fill=(*CREAM, 255))
    canvas.paste(screen, (left, top))


def build(locale: str, name: str) -> Path:
    lines, sub = COPY[name][locale]
    shot = Image.open(SHOTS / locale / f"{name}.png").convert("RGB")
    shot = shot.crop((0, STATUS_BAR, shot.width, shot.height))

    canvas = grid_field(WIDTH, HEIGHT)
    pen = ImageDraw.Draw(canvas)

    head = Type(HEAD_SIZE)
    small = Type(SUB_SIZE, weight=400)

    # Copy is edited here far more often than the layout is, so a line that has
    # outgrown the column fails the build rather than reaching the console.
    room = WIDTH - 2 * MARGIN
    for line in lines + [sub]:
        font = head if line in lines else small
        if font.width(line) > room:
            raise SystemExit(f'{locale}/{name}: "{line}" is wider than the column')

    baseline = 190
    for line in lines:
        head.draw(pen, (MARGIN, baseline), line, (*CREAM, 255))
        baseline += HEAD_LEAD
    small.draw(pen, (MARGIN, baseline + 22), sub, (*TEAL_LIFT, 255))

    frame(canvas, shot, SCREEN_TOP)

    OUT.mkdir(parents=True, exist_ok=True)
    out = OUT / locale / f"{name}.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(out)   # RGB because Play rejects an alpha channel
    return out


def main() -> None:
    for locale in LOCALES:
        for name in ORDER:
            print("wrote", build(locale, name).relative_to(HERE))


if __name__ == "__main__":
    main()
