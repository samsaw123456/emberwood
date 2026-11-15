"""Compose the app icon from the game's licensed SunnyLand fox and trees (Pillow)."""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/app"


def main() -> None:
    OUTPUT.mkdir(exist_ok=True)
    image = Image.new("RGBA", (128, 128), "#92a998")
    draw = ImageDraw.Draw(image)
    draw.rectangle((0, 72, 128, 128), fill="#526e60")
    for x, y, width in [(9, 5, 9), (109, 0, 10), (28, 0, 5), (91, 0, 5)]:
        draw.rectangle(
            (x, y, x + width, 112), fill="#294f49" if width > 5 else "#6c8875"
        )
    for box in [(0, 0, 42, 17), (0, 11, 28, 35), (89, 0, 128, 25), (105, 16, 128, 52)]:
        draw.rectangle(box, fill="#24483f")
    tree = Image.open(ROOT / "assets/pixel/nature/sunnyland/tree.png").convert("RGBA")
    for point in [(-24, 31), (81, 27)]:
        image.alpha_composite(tree.resize((76, 71), Image.Resampling.NEAREST), point)
    draw.rectangle((0, 112, 128, 128), fill="#283f36")
    draw.rectangle((0, 110, 128, 113), fill="#86a057")
    fox = Image.open(ROOT / "assets/pixel/characters/sunnyland/fox-idle-frame-01.png")
    fox = fox.convert("RGBA")
    fox = fox.crop(fox.getbbox())
    fox = fox.resize((fox.width * 4, fox.height * 4), Image.Resampling.NEAREST)
    image.alpha_composite(fox, ((128 - fox.width) // 2, 113 - fox.height))
    for size in [16, 24, 32, 48, 64, 128, 256, 512]:
        name = "emberwood.png" if size == 512 else f"emberwood-{size}.png"
        image.resize((size, size), Image.Resampling.NEAREST).save(OUTPUT / name)


if __name__ == "__main__":
    main()
