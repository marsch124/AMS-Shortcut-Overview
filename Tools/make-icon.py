#!/usr/bin/env python3
"""Draws the AMS Shortcut Overview app icon: flat indigo squircle, white line-drawn keycap (AMS Icon Library "keycap")."""
import math, os, shutil, subprocess, tempfile
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SS = 4
S = 1024 * SS
TEAL = (0x53, 0x4A, 0xB7, 255)
WHITE = (255, 255, 255, 255)

def render(stroke):
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Apple-style squircle: superellipse |x/a|^n + |y/a|^n = 1, n=4.5, a=412 (824 px tile)
    n_exp, a_rad, N = 4.5, 412 * SS, 1440
    pts = []
    for i in range(N):
        t = 2 * math.pi * i / N
        c, sn = math.cos(t), math.sin(t)
        pts.append((S / 2 + a_rad * math.copysign(abs(c) ** (2 / n_exp), c),
                    S / 2 + a_rad * math.copysign(abs(sn) ** (2 / n_exp), sn)))
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).polygon(pts, fill=255)
    tile = Image.new("RGBA", (S, S), TEAL)
    img.paste(tile, (0, 0), mask)

    scale = 640 * SS / 24
    # the 24-unit grid (not the drawing) is centred in the tile
    cx, cy = 12.0, 12.0  # centre of the drawing (x 3.5..20.5, y 4.5..19.5)
    ox, oy = S / 2 - cx * scale, S / 2 - cy * scale
    P = lambda x, y: (ox + x * scale, oy + y * scale)
    r = stroke * scale / 2
    step = 1.5 * SS

    def dab(pt):
        d.ellipse([pt[0] - r, pt[1] - r, pt[0] + r, pt[1] + r], fill=WHITE)

    def line(a, b):
        (ax, ay), (bx, by) = P(*a), P(*b)
        n = max(1, int(math.hypot(bx - ax, by - ay) / step))
        for i in range(n + 1):
            t = i / n
            dab((ax + (bx - ax) * t, ay + (by - ay) * t))

    def arc(cx_, cy_, rad, a0, a1):
        c = P(cx_, cy_)
        R = rad * scale
        n = max(1, int(abs(a1 - a0) * math.pi / 180 * R / step))
        for i in range(n + 1):
            a = math.radians(a0 + (a1 - a0) * i / n)
            dab((c[0] + R * math.cos(a), c[1] + R * math.sin(a)))

    # Library icon "keycap": base rounded square + inset top face (24-grid)
    def rrect(x0, y0, x1, y1, rad):
        arc(x1 - rad, y0 + rad, rad, -90, 0); line((x1, y0 + rad), (x1, y1 - rad))
        arc(x1 - rad, y1 - rad, rad, 0, 90); line((x1 - rad, y1), (x0 + rad, y1))
        arc(x0 + rad, y1 - rad, rad, 90, 180); line((x0, y1 - rad), (x0, y0 + rad))
        arc(x0 + rad, y0 + rad, rad, 180, 270); line((x0 + rad, y0), (x1 - rad, y0))
    rrect(3.5, 4.5, 20.5, 19.5, 3.5)
    rrect(7, 8, 17, 14.5, 2)
    return img.resize((1024, 1024), Image.LANCZOS)

img = render(1.7)
heavy = render(2.4)
os.makedirs(os.path.join(ROOT, "Docs"), exist_ok=True)
os.makedirs(os.path.join(ROOT, "App", "Resources"), exist_ok=True)
img.save(os.path.join(ROOT, "Docs", "icon-1024.png"))

tmp = tempfile.mkdtemp()
iconset = os.path.join(tmp, "AppIcon.iconset")
os.makedirs(iconset)
for base in (16, 32, 128, 256, 512):
    for mult, suffix in ((1, ""), (2, "@2x")):
        px = base * mult
        (heavy if px <= 64 else img).resize((px, px), Image.LANCZOS).save(os.path.join(iconset, f"icon_{base}x{base}{suffix}.png"))
subprocess.run(["iconutil", "-c", "icns", iconset, "-o", os.path.join(ROOT, "App", "Resources", "AppIcon.icns")], check=True)
shutil.rmtree(tmp)
print("ok")
