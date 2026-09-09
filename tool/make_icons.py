#!/usr/bin/env python3
"""Word Quest – Android launcher icon + splash generator.

Rebuilds android/app/src/main/res/{mipmap*,drawable*} artwork from logo.png
so the repository logo ships as the launcher icon, launcher round icon,
adaptive icon foreground and splash artwork.

Run from the repository root:
    python3 tool/make_icons.py        (requires: pip install pillow)
"""
import math
import os
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "android", "app", "src", "main", "res")

# pastel gradient
TOP = (236, 229, 251)      # soft lavender
BOTTOM = (255, 231, 239)   # soft blush
BG_HEX = "#ECE5FB"

MIPMAPS = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
BASE_LEGACY = 48   # px at mdpi for a legacy launcher icon
BASE_ADAPT = 108   # px at mdpi for an adaptive icon canvas
BASE_SPLASH = 96   # dp splash logo canvas


def vertical_gradient(size):
    w, h = size
    img = Image.new("RGB", size)
    px = img.load()
    for y in range(h):
        t = y / max(1, h - 1)
        r = int(TOP[0] + (BOTTOM[0] - TOP[0]) * t)
        g = int(TOP[1] + (BOTTOM[1] - TOP[1]) * t)
        b = int(TOP[2] + (BOTTOM[2] - TOP[2]) * t)
        for x in range(w):
            px[x, y] = (r, g, b)
    return img


def fit_logo(logo, canvas, fraction=0.56):
    """Returns logo pasted centred, covering `fraction` of `canvas`."""
    side = int(min(canvas.size) * fraction)
    lw, lh = logo.size
    scale = side / max(lw, lh)
    logo = logo.resize((max(1, int(lw * scale)), max(1, int(lh * scale))), Image.LANCZOS)
    canvas.paste(logo, ((canvas.width - logo.width) // 2,
                        (canvas.height - logo.height) // 2), logo)
    return canvas


def rounded(canvas, radius_frac=0.22):
    """Rounds the corners of an RGBA canvas (used for the round icon)."""
    mask = Image.new("L", canvas.size, 0)
    d = ImageDraw.Draw(mask)
    rad = int(min(canvas.size) * radius_frac)
    d.rounded_rectangle([0, 0, canvas.width - 1, canvas.height - 1], radius=rad, fill=255)
    out = Image.new("RGBA", canvas.size)
    out.paste(canvas, (0, 0), mask)
    return out


def main():
    logo = Image.open(os.path.join(ROOT, "logo.png")).convert("RGBA")

    for dpi, mult in MIPMAPS.items():
        mdir = os.path.join(RES, f"mipmap-{dpi}")
        os.makedirs(mdir, exist_ok=True)
        # legacy square + round icons
        for name in ("ic_launcher", "ic_launcher_round"):
            size = int(BASE_LEGACY * mult)
            bg = vertical_gradient((size, size)).convert("RGBA")
            fit_logo(logo, bg)
            out = bg if name == "ic_launcher" else rounded(bg)
            out.save(os.path.join(mdir, f"{name}.png"))
        # adaptive foreground (logo only, no background)
        fsize = int(BASE_ADAPT * mult)
        fg = Image.new("RGBA", (fsize, fsize), (0, 0, 0, 0))
        fit_logo(logo, fg, fraction=0.60)
        fg.save(os.path.join(mdir, "ic_launcher_foreground.png"))

    # drawable resources
    ddir = os.path.join(RES, "drawable")
    os.makedirs(ddir, exist_ok=True)

    background_xml = f'''<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <gradient
        android:angle="315"
        android:startColor="#E4DBF8"
        android:endColor="#FFE1ED"
        android:type="linear" />
</shape>
'''
    with open(os.path.join(ddir, "ic_launcher_background.xml"), "w") as f:
        f.write(background_xml)

    def launch_xml(with_logo):
        logo_item = ""
        if with_logo:
            logo_item = '''    <item>
        <bitmap
            android:gravity="center"
            android:src="@drawable/splash_logo" />
    </item>
'''
        return f'''<?xml version="1.0" encoding="utf-8"?>
<!-- Pastel launch background used while the Flutter engine starts. -->
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <shape android:shape="rectangle">
            <gradient
                android:angle="315"
                android:startColor="#EFE9FB"
                android:endColor="#FFE9F1"
                android:type="linear" />
        </shape>
    </item>
{logo_item}</layer-list>
'''

    # API < 21: gradient only (no bitmap layer support below v21)
    sdir = os.path.join(RES, "drawable")
    os.makedirs(sdir, exist_ok=True)
    with open(os.path.join(sdir, "launch_background.xml"), "w") as f:
        f.write(launch_xml(False))
    # API >= 21: gradient + centred logo
    sdir = os.path.join(RES, "drawable-v21")
    os.makedirs(sdir, exist_ok=True)
    with open(os.path.join(sdir, "launch_background.xml"), "w") as f:
        f.write(launch_xml(True))

    # density-specific splash logo pngs used by drawable-v21 variant
    for dpi, mult in MIPMAPS.items():
        sdir = os.path.join(RES, f"drawable-{dpi}")
        os.makedirs(sdir, exist_ok=True)
        size = int(BASE_SPLASH * mult)
        sp = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        fit_logo(logo, sp, fraction=0.5)
        sp.save(os.path.join(sdir, "splash_logo.png"))

    print("icons written to", RES)


if __name__ == "__main__":
    main()
