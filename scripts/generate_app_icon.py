#!/usr/bin/env python3
"""Generate the SplitLLM app-icon source images (assets/icon/*) with Pillow.

The mark is a disc split by an S-curve — two halves in the app's Material
dark-theme colors (purple #BB86FC / teal #03DAC6) on the navy gradient used
across the app. Outputs:

  app_icon.png               1024x1024 full-bleed (iOS icon + Android legacy)
  app_icon_foreground.png    1024x1024 transparent (Android adaptive foreground)
  splash_icon.png            1024x1024 transparent (splash mark, treated as 4x)
  splash_icon_android12.png  1152x1152 (Android 12+ splash; keep the mark
                             inside the central 768px circle)

After changing this file:
  python3 scripts/generate_app_icon.py
  dart run flutter_launcher_icons
  dart run flutter_native_splash:create
"""

from pathlib import Path

from PIL import Image, ImageDraw

SS = 4  # supersampling factor; drawn large, downscaled with LANCZOS

BG_TOP = (26, 26, 46)  # #1A1A2E
BG_BOTTOM = (22, 33, 62)  # #16213E
PURPLE = (187, 134, 252)  # #BB86FC — theme primary
TEAL = (3, 218, 198)  # #03DAC6 — theme secondary

OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "icon"


def draw_mark(size: int) -> Image.Image:
    """Transparent square with the split-disc mark filling it edge to edge."""
    big = size * SS
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    r = big // 2
    cx = big // 2

    # Halves: PIL angles start at 3 o'clock and grow clockwise.
    d.pieslice([0, 0, big - 1, big - 1], 90, 270, fill=PURPLE)  # left
    d.pieslice([0, 0, big - 1, big - 1], 270, 450, fill=TEAL)  # right

    # Yin-yang lobes turn the straight divider into an S-curve ("S" for Split).
    d.ellipse([cx - r // 2, 0, cx + r // 2, r], fill=PURPLE)  # top lobe
    d.ellipse([cx - r // 2, r, cx + r // 2, big], fill=TEAL)  # bottom lobe

    return img.resize((size, size), Image.LANCZOS)


def gradient_background(size: int) -> Image.Image:
    img = Image.new("RGB", (size, size))
    for y in range(size):
        t = y / (size - 1)
        row = tuple(
            round(BG_TOP[c] + (BG_BOTTOM[c] - BG_TOP[c]) * t) for c in range(3)
        )
        img.paste(Image.new("RGB", (size, 1), row), (0, y))
    return img.convert("RGBA")


def compose(canvas: Image.Image, mark_size: int) -> Image.Image:
    mark = draw_mark(mark_size)
    offset = ((canvas.width - mark_size) // 2, (canvas.height - mark_size) // 2)
    canvas.alpha_composite(mark, offset)
    return canvas


def transparent(size: int) -> Image.Image:
    return Image.new("RGBA", (size, size), (0, 0, 0, 0))


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    # Full-bleed icon: mark at 62% so it breathes inside iOS' rounded mask.
    compose(gradient_background(1024), 634).save(OUT_DIR / "app_icon.png")

    # Adaptive foreground: Android guarantees only the central 66% is visible.
    compose(transparent(1024), 560).save(OUT_DIR / "app_icon_foreground.png")

    # Splash mark (flutter_native_splash treats the source as 4x → 256dp).
    compose(transparent(1024), 512).save(OUT_DIR / "splash_icon.png")

    # Android 12 splash: 1152px canvas, mark inside the 768px safe circle.
    compose(transparent(1152), 640).save(OUT_DIR / "splash_icon_android12.png")

    for name in sorted(p.name for p in OUT_DIR.glob("*.png")):
        print(f"wrote assets/icon/{name}")


if __name__ == "__main__":
    main()
