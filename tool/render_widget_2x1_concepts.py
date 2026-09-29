"""Render 2×1 widget design concepts with the app's exact character art.

The character pixels come from frame 0 of each idle sprite sheet. No character
is redrawn or generated, so the four previews match the assets the app uses.
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "design/widget-2x1-concepts"
CHARACTERS = (
    ("Michi", "michi"),
    ("Poodle", "poodle"),
    ("Schnauzer", "schnauzer"),
    ("Guinea Pig", "guinea-pig"),
)
INK = "#202848"
SOFT_INK = "#4E5878"
TEAL = "#0E7A72"
PAPER = "#FFFDF7"
SHEET = "#F4F1F7"
CARD_W, CARD_H = 590, 240


def pixel_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    font = ImageFont.truetype(ROOT / "assets/fonts/PixelifySans.ttf", size)
    if bold:
        font.set_variation_by_axes([700])
    return font


def hangul_font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(ROOT / "assets/fonts/SobraHangul-Bold.ttf", size)


def character_frame(character_id: str, width: int) -> Image.Image:
    sheet = Image.open(ROOT / f"assets/characters/{character_id}/idle-8.png").convert("RGBA")
    if sheet.size != (2560, 360):
        raise ValueError(f"Unexpected idle sheet size for {character_id}: {sheet.size}")
    return sheet.crop((0, 0, 320, 360)).resize(
        (width, round(width * 360 / 320)), Image.Resampling.NEAREST
    )


def text(draw: ImageDraw.ImageDraw, xy: tuple[int, int], value: str,
         size: int, color: str, bold: bool = True) -> None:
    draw.text(xy, value, font=pixel_font(size, bold), fill=color, anchor="lt")


def draw_widget(canvas: Image.Image, x: int, y: int, variant: int,
                character_id: str) -> None:
    draw = ImageDraw.Draw(canvas)
    rect = (x, y, x + CARD_W, y + CARD_H)
    draw.rounded_rectangle((x + 8, y + 8, x + CARD_W + 8, y + CARD_H + 8),
                           radius=28, fill="#D3D4DD")
    draw.rounded_rectangle(rect, radius=28,
                           fill=TEAL if variant == 3 else PAPER,
                           outline=INK, width=5)

    if variant == 1:
        text(draw, (x + 34, y + 51), "Hoy te queda", 31, INK)
        text(draw, (x + 31, y + 105), "$9,000", 82, TEAL)
        text(draw, (x + 318, y + 143), "MXN", 25, SOFT_INK)
        sprite = character_frame(character_id, 169)
        canvas.alpha_composite(sprite, (x + 412, y + CARD_H - sprite.height - 3))

    elif variant == 2:
        draw.rounded_rectangle((x + 5, y + 5, x + 207, y + CARD_H - 5),
                               radius=23, fill=INK)
        draw.rectangle((x + 181, y + 5, x + 207, y + CARD_H - 5), fill=INK)
        draw.ellipse((x + 23, y + 39, x + 185, y + 201), fill="#F6EFE0")
        sprite = character_frame(character_id, 169)
        canvas.alpha_composite(sprite, (x + 17, y + CARD_H - sprite.height - 4))
        text(draw, (x + 232, y + 52), "Hoy te queda", 29, INK)
        text(draw, (x + 228, y + 108), "$9,000", 69, TEAL)
        text(draw, (x + 491, y + 145), "MXN", 23, SOFT_INK)

    else:
        draw.ellipse((x + 423, y + 36, x + 575, y + 188), fill="#F6EFE0")
        text(draw, (x + 35, y + 50), "Hoy te queda", 31, PAPER)
        text(draw, (x + 33, y + 105), "$9,000", 81, PAPER)
        text(draw, (x + 320, y + 143), "MXN", 25, PAPER)
        sprite = character_frame(character_id, 150)
        canvas.alpha_composite(sprite, (x + 425, y + CARD_H - sprite.height - 4))


def render(variant: int, title: str) -> None:
    canvas = Image.new("RGBA", (1340, 900), SHEET)
    draw = ImageDraw.Draw(canvas)
    text(draw, (56, 33), "2 x 1", 35, INK)
    draw.text((185, 30), title, font=hangul_font(36), fill=INK, anchor="lt")
    draw.text((56, 82), "실제 앱 캐릭터 이미지로 확인한 위젯 시안",
              font=hangul_font(20), fill=SOFT_INK, anchor="lt")
    positions = ((56, 165), (696, 165), (56, 535), (696, 535))
    for (name, character_id), (x, y) in zip(CHARACTERS, positions):
        text(draw, (x, y - 33), name, 23, INK)
        draw_widget(canvas, x, y, variant, character_id)
    draw.text((56, 832), "금액은 예시입니다. 실제 위젯은 선택한 캐릭터와 예산 정보를 표시합니다.",
              font=hangul_font(18), fill=SOFT_INK, anchor="lt")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(OUTPUT / f"option-{variant}.png", optimize=True)


if __name__ == "__main__":
    for number, name in enumerate(("균형형", "캐릭터 강조형", "금액 강조형"), start=1):
        render(number, name)
