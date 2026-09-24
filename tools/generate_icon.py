"""Original app icon + logo: crimson tile, gold Nepali sun, isometric white die."""
import math
import os
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "images")
os.makedirs(OUT, exist_ok=True)
S = 1024  # draw big, downsample for crisp edges


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def radial_bg(size, inner, outer):
    img = Image.new("RGB", (size, size), outer)
    px = img.load()
    c = size / 2
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - c * 0.85, y - c * 0.7) / (size * 0.85)
            px[x, y] = lerp(inner, outer, min(1.0, d))
    return img


def sun(draw, cx, cy, r, color, points=12):
    pts = []
    for i in range(points * 2):
        a = math.pi * i / points - math.pi / 2
        rr = r if i % 2 == 0 else r * 0.72
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    draw.polygon(pts, fill=color)
    draw.ellipse([cx - r * 0.55, cy - r * 0.55, cx + r * 0.55, cy + r * 0.55], fill=color)


def die(img, cx, cy, s):
    """Isometric cube with 3 visible faces: top=1? we show 5 on top, 6 left, 4 right."""
    d = ImageDraw.Draw(img, "RGBA")
    h = s * 0.5
    top = [(cx, cy - s), (cx + s * 0.87, cy - h), (cx, cy), (cx - s * 0.87, cy - h)]
    left = [(cx - s * 0.87, cy - h), (cx, cy), (cx, cy + s), (cx - s * 0.87, cy + h)]
    right = [(cx + s * 0.87, cy - h), (cx, cy), (cx, cy + s), (cx + s * 0.87, cy + h)]
    # drop shadow
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).polygon([(x + s * 0.12, y + s * 0.2) for x, y in
                                [top[0], top[1], right[3], right[2], left[3], left[0]]],
                               fill=(0, 0, 0, 120))
    sh = sh.filter(ImageFilter.GaussianBlur(s * 0.12))
    img.alpha_composite(sh)
    d = ImageDraw.Draw(img, "RGBA")
    d.polygon(top, fill=(255, 255, 255, 255))
    d.polygon(left, fill=(226, 222, 214, 255))
    d.polygon(right, fill=(200, 194, 184, 255))
    edge = (120, 20, 30, 255)
    for poly in (top, left, right):
        d.line(poly + [poly[0]], fill=edge, width=max(2, int(s * 0.025)), joint="curve")

    def pip(face, u, v, r, col):
        # face corners: p0 (u=0,v=0), p1 (u=1,v=0), p3 (u=0,v=1)
        p0, p1, _, p3 = face
        x = p0[0] + (p1[0] - p0[0]) * u + (p3[0] - p0[0]) * v
        y = p0[1] + (p1[1] - p0[1]) * u + (p3[1] - p0[1]) * v
        d.ellipse([x - r, y - r * 0.8, x + r, y + r * 0.8], fill=col)

    red, dark = (200, 16, 46, 255), (60, 20, 24, 255)
    r = s * 0.085
    # top: 1 big red pip
    pip(top, 0.5, 0.5, r * 1.6, red)
    # left: 4
    for u, v in [(0.28, 0.28), (0.72, 0.28), (0.28, 0.72), (0.72, 0.72)]:
        pip([left[0], left[1], left[2], left[3]], u, v, r, dark)
    # right: 6 → using (right[1] as origin)
    rf = [right[1], right[0], right[3], right[2]]
    for u, v in [(0.3, 0.25), (0.3, 0.5), (0.3, 0.75), (0.7, 0.25), (0.7, 0.5), (0.7, 0.75)]:
        pip(rf, u, v, r * 0.9, dark)


def make_icon(size):
    base = radial_bg(256, (230, 57, 70), (110, 8, 22)).resize((S, S), Image.BICUBIC).convert("RGBA")
    d = ImageDraw.Draw(base, "RGBA")
    # gold sun behind the die
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sun(ImageDraw.Draw(glow), S * 0.5, S * 0.44, S * 0.40, (255, 214, 90, 150))
    glow = glow.filter(ImageFilter.GaussianBlur(S * 0.03))
    base.alpha_composite(glow)
    crisp = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    cd = ImageDraw.Draw(crisp)
    sun(cd, S * 0.5, S * 0.44, S * 0.36, (240, 170, 30, 255))
    sun(cd, S * 0.5, S * 0.44, S * 0.30, (255, 206, 72, 255))
    base.alpha_composite(crisp.filter(ImageFilter.GaussianBlur(1.2)))
    # thin gold frame
    m = S * 0.06
    d.rounded_rectangle([m, m, S - m, S - m], radius=S * 0.18, outline=(245, 200, 66, 200), width=int(S * 0.018))
    die(base, S * 0.5, S * 0.52, S * 0.26)
    # rounded mask
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, S, S], radius=S * 0.22, fill=255)
    out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    out.paste(base, (0, 0), mask)
    return out.resize((size, size), Image.LANCZOS)


if __name__ == "__main__":
    big = make_icon(512)
    big.save(os.path.join(OUT, "logo.png"))
    for folder, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        p = os.path.join(OUT, "mipmap-" + folder)
        os.makedirs(p, exist_ok=True)
        make_icon(px).save(os.path.join(p, "ic_launcher.png"))
    print("done")
