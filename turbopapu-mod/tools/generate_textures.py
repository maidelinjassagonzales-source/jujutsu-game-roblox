#!/usr/bin/env python3
"""Genera todas las texturas del mod TurboPapu (pixel art) con Pillow.

Uso:  python3 tools/generate_textures.py
Puedes reemplazar cualquier PNG generado por uno dibujado a mano: el mod solo
necesita que el archivo exista con el mismo nombre y tamaño.
"""
import math
import os
import random
from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "src", "main", "resources", "assets", "turbopapu")
TEX = os.path.join(ROOT, "textures")
rng = random.Random(778)


def hexc(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def shade(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c[:3]) + (c[3],)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(4))


def save(img, *path):
    p = os.path.join(TEX, *path)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    img.save(p)
    print("ok", os.path.relpath(p, ROOT))


def rect(img, x, y, w, h, color, noise=0.0):
    for i in range(x, x + w):
        for j in range(y, y + h):
            c = color
            if noise:
                c = shade(color, 1 + (rng.random() - 0.5) * noise)
            img.putpixel((i, j), c)


def faces(u, v, w, h, d):
    """Regiones UV de un cuboide de Minecraft."""
    return {
        "top": (u + d, v, w, d),
        "bottom": (u + d + w, v, w, d),
        "right": (u, v + d, d, h),
        "front": (u + d, v + d, w, h),
        "left": (u + d + w, v + d, d, h),
        "back": (u + 2 * d + w, v + d, w, h),
    }


def cube(img, u, v, w, h, d, color, noise=0.08, overrides=None):
    for name, (x, y, fw, fh) in faces(u, v, w, h, d).items():
        c = (overrides or {}).get(name, color)
        rect(img, x, y, fw, fh, c, noise)


# ------------------------------------------------------------------ Turbopapuense
def turbopapuense(dormido):
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    blue, purple, orange, yellow = hexc("3B3FD8"), hexc("7B3FC4"), hexc("F2A33A"), hexc("F6C453")
    f = faces(0, 0, 12, 12, 12)
    for name, (x, y, w, h) in f.items():
        for i in range(w):
            for j in range(h):
                t = (i / (w - 1) * 0.6 + j / (h - 1) * 0.6)
                if name in ("top",):
                    t *= 0.4
                if name in ("bottom",):
                    t = 0.9
                if name == "back":
                    t = 1 - i / (w - 1) * 0.6 + j / (h - 1) * 0.2
                t = max(0, min(1, t))
                c = lerp(blue, purple, t / 0.4) if t < 0.4 else lerp(purple, orange, (t - 0.4) / 0.4) if t < 0.8 else lerp(orange, yellow, (t - 0.8) / 0.2)
                img.putpixel((x + i, y + j), shade(c, 1 + (rng.random() - 0.5) * 0.06))
    fx, fy, _, _ = f["front"]
    navy, white, teal, dark = hexc("1B1440"), hexc("FFFFFF"), hexc("2EC4C4"), hexc("0E4F5C")
    if not dormido:
        # Cejas enfadadas
        for i in range(3):
            img.putpixel((fx + 1 + i, fy + 2 + i // 2), navy)
            img.putpixel((fx + 10 - i, fy + 2 + i // 2), navy)
        # Ojos
        for ex in (fx + 3, fx + 7):
            rect(img, ex, fy + 4, 2, 3, navy)
            img.putpixel((ex, fy + 4), white)
        # Boca abierta (gritando al micro)
        rect(img, fx + 4, fy + 8, 4, 3, teal)
        rect(img, fx + 5, fy + 9, 2, 2, dark)
    else:
        for ex in (fx + 2, fx + 7):
            rect(img, ex, fy + 5, 3, 1, navy)
        rect(img, fx + 5, fy + 9, 2, 1, dark)
        # Z de dormido en la frente
        for p in [(9, 1), (10, 1), (11, 1), (10, 2), (9, 3), (10, 3), (11, 3)]:
            img.putpixel((fx + p[0] - 1, fy + p[1]), white)
    # Cascos, micro
    cube(img, 0, 34, 14, 2, 4, hexc("1E1E24"))
    cube(img, 36, 32, 2, 5, 5, hexc("2B2B33"), overrides={"right": hexc("3E3E4A"), "left": hexc("3E3E4A")})
    cube(img, 36, 44, 2, 5, 5, hexc("2B2B33"), overrides={"right": hexc("3E3E4A"), "left": hexc("3E3E4A")})
    cube(img, 50, 32, 1, 1, 5, hexc("111111"))
    # Bracitos y patas
    cube(img, 28, 24, 3, 3, 3, orange)
    cube(img, 40, 24, 3, 3, 3, purple)
    cube(img, 0, 24, 3, 5, 4, orange, overrides={"bottom": hexc("B86E1E")})
    cube(img, 14, 24, 3, 5, 4, orange, overrides={"bottom": hexc("B86E1E")})
    return img


# ------------------------------------------------------------------ Humanoides (layout de skin 64x64)
HEAD, HAT = (0, 0, 8, 8, 8), (32, 0, 8, 8, 8)
BODY = (16, 16, 8, 12, 4)
RARM, LARM = (40, 16, 4, 12, 4), (32, 48, 4, 12, 4)
RLEG, LLEG = (0, 16, 4, 12, 4), (16, 48, 4, 12, 4)


def front(box):
    return faces(*box)["front"][:2]


def humanoid(skin, hair, shirt, pants, shoes, sleeves=None, hair_style="short"):
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    cube(img, *HEAD, skin, 0.05)
    f = faces(*HEAD)
    # Pelo: arriba, atrás y laterales superiores
    rect(img, *f["top"], hair, 0.15)
    rect(img, *f["back"], hair, 0.15)
    for side in ("right", "left"):
        x, y, w, h = f[side]
        rect(img, x, y, w, 3 if hair_style == "short" else 6, hair, 0.15)
    fx, fy = front(HEAD)
    rect(img, fx, fy, 8, 2, hair, 0.15)
    # Ojos
    for ex in (fx + 1, fx + 5):
        rect(img, ex, fy + 4, 2, 1, hexc("FFFFFF"))
        img.putpixel((ex + (1 if ex == fx + 1 else 0), fy + 4), hexc("2B1D0E"))
    rect(img, fx + 3, fy + 6, 2, 1, shade(skin, 0.75))
    cube(img, *BODY, shirt)
    cube(img, *RARM, sleeves or shirt)
    cube(img, *LARM, sleeves or shirt)
    for arm in (RARM, LARM):
        for name, (x, y, w, h) in faces(*arm).items():
            if name not in ("top", "bottom"):
                rect(img, x, y + h - 3, w, 3, skin, 0.05)
        x, y, w, h = faces(*arm)["bottom"]
        rect(img, x, y, w, h, skin)
    cube(img, *RLEG, pants)
    cube(img, *LLEG, pants)
    for leg in (RLEG, LLEG):
        for name, (x, y, w, h) in faces(*leg).items():
            if name not in ("top", "bottom"):
                rect(img, x, y + h - 2, w, 2, shoes, 0.05)
        x, y, w, h = faces(*leg)["bottom"]
        rect(img, x, y, w, h, shoes)
    return img


def headphones(img, color, cup):
    """Cascos en la capa del sombrero."""
    f = faces(*HAT)
    x, y, w, h = f["top"]
    rect(img, x, y + 3, w, 2, color)
    for side in ("right", "left"):
        x, y, w, h = f[side]
        rect(img, x + 2, y, 1, 3, color)
        rect(img, x + 2, y + 3, 4, 4, cup)


def chest_logo(img, pixels, color, ox=2, oy=3):
    bx, by = front(BODY)
    for (px, py) in pixels:
        img.putpixel((bx + ox + px, by + oy + py), color)


ICEBERG = [(1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (3, 1), (0, 2), (1, 2), (2, 2), (3, 2)]


def alphatemp(evil=False):
    skin = hexc("C9A88C") if evil else hexc("E0B08A")
    img = humanoid(skin, hexc("3B2416"), hexc("5A0E0E") if evil else hexc("8FD3F4"),
                   hexc("111111") if evil else hexc("1E3A5F"), hexc("2A2A2A") if evil else hexc("F0F0F0"))
    headphones(img, hexc("111111"), hexc("FF2222") if evil else hexc("2EC4C4"))
    chest_logo(img, ICEBERG, hexc("FF4444") if evil else hexc("FFFFFF"))
    chest_logo(img, [(0, 3), (1, 3), (2, 3), (3, 3)], hexc("1A1A1A") if evil else hexc("2C7FB8"))
    fx, fy = front(HEAD)
    if evil:
        for ex in (fx + 1, fx + 5):
            rect(img, ex, fy + 4, 2, 1, hexc("FF1111"))
        rect(img, fx + 2, fy + 6, 4, 1, hexc("3A0000"))
        img.putpixel((fx + 2, fy + 5), hexc("3A0000"))
        img.putpixel((fx + 5, fy + 5), hexc("3A0000"))
    return img


def william():
    orange, dark = hexc("F08A24"), hexc("B85E10")
    img = humanoid(orange, orange, hexc("1A1A1A"), hexc("1A1A1A"), hexc("0D0D0D"), sleeves=hexc("1A1A1A"))
    f = faces(*HEAD)
    for name, (x, y, w, h) in f.items():
        rect(img, x, y, w, h, orange, 0.1)
    # Rayas de pez y bigotes
    for name in ("right", "left", "back"):
        x, y, w, h = f[name]
        for i in range(0, w, 3):
            rect(img, x + i, y + 2, 1, 5, dark)
    fx, fy = front(HEAD)
    rect(img, fx + 4, fy + 2, 3, 3, hexc("FFFFFF"))
    rect(img, fx + 5, fy + 3, 1, 1, hexc("000000"))
    rect(img, fx + 1, fy + 2, 3, 3, hexc("0D0D0D"))  # parche
    rect(img, fx, fy + 1, 8, 1, hexc("0D0D0D"))  # cinta del parche
    for i in range(3):
        img.putpixel((fx + i, fy + 6), dark)
        img.putpixel((fx + 7 - i, fy + 6), dark)
    # Traje: camisa blanca y corbata
    bx, by = front(BODY)
    rect(img, bx + 2, by, 4, 5, hexc("F5F5F5"))
    rect(img, bx + 3, by + 1, 2, 6, hexc("C9C9C9"))
    # Manos-aleta
    for arm in (RARM, LARM):
        for name, (x, y, w, h) in faces(*arm).items():
            if name not in ("top",):
                rect(img, x, y + max(0, h - 3), w, min(3, h), orange)
    # Tricornio
    cube(img, 0, 32, 10, 1, 10, hexc("151515"), overrides={"top": hexc("1E1E1E")})
    x, y, w, h = faces(0, 32, 10, 1, 10)["top"]
    for i in range(w):
        img.putpixel((x + i, y), hexc("D4AF37"))
        img.putpixel((x + i, y + h - 1), hexc("D4AF37"))
    cube(img, 40, 32, 6, 3, 6, hexc("151515"))
    cx, cy, _, _ = faces(40, 32, 6, 3, 6)["front"]
    for p in [(2, 0), (3, 0), (2, 1), (3, 1), (1, 2), (4, 2)]:
        img.putpixel((cx + p[0], cy + p[1]), hexc("FFFFFF"))
    cube(img, 0, 48, 1, 3, 2, dark)
    cube(img, 0, 54, 4, 2, 1, hexc("F7B27A"))
    return img


def juanma():
    img = humanoid(hexc("E8B996"), hexc("6E6259"), hexc("7B4A2A"), hexc("CDB891"), hexc("4A2A12"))
    fx, fy = front(HEAD)
    # Gafas
    for ex in (fx, fx + 5):
        rect(img, ex, fy + 3, 3, 1, hexc("111111"))
        img.putpixel((ex, fy + 4), hexc("111111"))
        img.putpixel((ex + 2, fy + 4), hexc("111111"))
    rect(img, fx + 3, fy + 3, 2, 1, hexc("111111"))
    rect(img, fx + 1, fy + 7, 6, 1, shade(hexc("6E6259"), 1.2))
    bx, by = front(BODY)
    rect(img, bx + 2, by, 4, 12, hexc("F5F5F5"))
    rect(img, bx + 3, by + 1, 2, 7, hexc("8B0000"))
    # Bufanda argentina (celeste y blanca)
    for name, (x, y, w, h) in faces(*BODY).items():
        if name in ("front", "back", "right", "left"):
            for i in range(w):
                img.putpixel((x + i, y), hexc("75AADB") if i % 2 == 0 else hexc("FFFFFF"))
                img.putpixel((x + i, y + 1), hexc("FFFFFF") if i % 2 == 0 else hexc("75AADB"))
    rect(img, bx + 1, by + 2, 1, 6, hexc("75AADB"))
    rect(img, bx + 1, by + 4, 1, 1, hexc("F6B40E"))  # sol de mayo
    return img


def guinxu():
    """Guinxu: pelo largo castaño oscuro con raya en medio, gafas negras rectangulares, perilla y
    camiseta negra con los kanji 空手 en blanco."""
    hair = hexc("3B2A20")
    skin = hexc("E2B79A")
    img = humanoid(skin, hair, hexc("141414"), hexc("2B3340"), hexc("111111"), sleeves=hexc("141414"))
    fx, fy = front(HEAD)
    # Flequillo con raya en medio que enmarca la cara.
    rect(img, fx, fy, 8, 1, hair, 0.15)
    rect(img, fx, fy + 1, 1, 7, hair, 0.15)
    rect(img, fx + 7, fy + 1, 1, 7, hair, 0.15)
    img.putpixel((fx + 3, fy + 1), hair)
    img.putpixel((fx + 4, fy + 1), hair)
    # Gafas negras rectangulares.
    for ex in (fx + 1, fx + 4):
        rect(img, ex, fy + 3, 3, 1, hexc("0A0A0A"))
        img.putpixel((ex, fy + 4), hexc("0A0A0A"))
        img.putpixel((ex + 2, fy + 4), hexc("0A0A0A"))
        img.putpixel((ex + 1, fy + 4), hexc("3B2416"))
    # Bigote y perilla.
    rect(img, fx + 3, fy + 6, 2, 1, shade(hair, 1.1))
    rect(img, fx + 3, fy + 7, 2, 1, shade(hair, 1.2))
    # Toda la cabeza menos la cara, de pelo.
    for name in ("right", "left", "back", "top"):
        x, y, w, h = faces(*HEAD)[name]
        rect(img, x, y, w, h, hair, 0.15)
    # Melena: arriba, espalda y mechones laterales.
    for box in [(0, 32, 9, 2, 9), (36, 32, 9, 14, 1), (0, 43, 1, 12, 6)]:
        for name, (x, y, w, h) in faces(*box).items():
            for i in range(w):
                for j in range(h):
                    img.putpixel((x + i, y + j), shade(hair, 0.85 + 0.3 * ((i * 7 + j) % 5) / 5))
    # Kanji 空手 en blanco en la camiseta.
    bx, by = front(BODY)
    kanji = [(3, 1), (4, 1), (2, 2), (5, 2), (3, 3), (4, 3), (2, 4), (3, 4), (4, 4), (5, 4),
             (3, 6), (4, 6), (2, 7), (3, 7), (4, 7), (5, 7), (3, 8), (4, 8), (4, 9), (3, 10), (4, 10)]
    for (px, py) in kanji:
        img.putpixel((bx + px, by + py), hexc("F0F0F0"))
    return img


def elink():
    skin = hexc("C68E63")
    img = humanoid(skin, hexc("1A1A1A"), hexc("151515"), hexc("151515"), hexc("0A0A0A"))
    fx, fy = front(HEAD)
    rect(img, fx + 1, fy + 6, 6, 1, hexc("1A1A1A"))  # bigote estilo Mario
    rect(img, fx + 2, fy + 7, 4, 1, shade(skin, 0.7))
    # Gorra roja con el "64"
    f = faces(*HAT)
    rect(img, *f["top"], hexc("E53935"))
    for name in ("front", "back", "right", "left"):
        x, y, w, h = f[name]
        rect(img, x, y, w, 3, hexc("E53935"))
    hx, hy, _, _ = f["front"]
    rect(img, hx + 2, hy, 4, 3, hexc("FFFFFF"))
    for p in [(2, 0), (2, 1), (2, 2), (3, 2), (4, 0), (4, 1), (4, 2), (5, 1)]:
        img.putpixel((hx + 1 + p[0] - 1, hy + p[1]), hexc("E53935") if p[0] in (2, 4) and p[1] == 1 else hexc("1A1A1A"))
    # Chaqueta de Michael Jackson
    bx, by = front(BODY)
    rect(img, bx + 3, by, 2, 12, hexc("F5F5F5"))
    for j in range(1, 10, 2):
        img.putpixel((bx + 2, by + j), hexc("D4AF37"))
        img.putpixel((bx + 5, by + j), hexc("D4AF37"))
    # Guante blanco en una mano y calcetines blancos
    for name, (x, y, w, h) in faces(*RARM).items():
        if name != "top":
            rect(img, x, y + max(0, h - 3), w, min(3, h), hexc("FFFFFF"))
    for leg in (RLEG, LLEG):
        for name, (x, y, w, h) in faces(*leg).items():
            if name not in ("top", "bottom"):
                rect(img, x, y + h - 4, w, 2, hexc("FFFFFF"))
    return img


def fat(skin, hair, shirt, pants, shoes, belly_shirt_rows=4):
    img = humanoid(skin, hair, shirt, pants, shoes, hair_style="long")
    cube(img, 0, 32, 10, 8, 6, shirt)
    x, y, w, h = faces(0, 32, 10, 8, 6)["front"]
    rect(img, x, y + belly_shirt_rows, w, h - belly_shirt_rows, skin, 0.04)
    img.putpixel((x + w // 2, y + belly_shirt_rows + 2), shade(skin, 0.6))  # ombligo
    x, y, w, h = faces(0, 32, 10, 8, 6)["bottom"]
    rect(img, x, y, w, h, skin)
    return img


def sualenidus():
    img = fat(hexc("E0AC8A"), hexc("2B1D14"), hexc("B57EDC"), hexc("3A3A3A"), hexc("FF4655"))
    fx, fy = front(HEAD)
    # Gafas de sol redondas rojas
    for ex in (fx, fx + 5):
        rect(img, ex, fy + 3, 3, 2, hexc("D93636"))
        img.putpixel((ex, fy + 3), hexc("FF9A9A"))
    rect(img, fx + 3, fy + 3, 2, 1, hexc("C9A227"))
    # Sonrisa loca
    rect(img, fx + 1, fy + 6, 6, 1, hexc("5A1A1A"))
    img.putpixel((fx + 1, fy + 5), hexc("5A1A1A"))
    img.putpixel((fx + 6, fy + 5), hexc("5A1A1A"))
    rect(img, fx + 2, fy + 6, 4, 1, hexc("FFFFFF"))
    # Barba de 3 días
    for i in range(8):
        if i % 2 == 0:
            img.putpixel((fx + i, fy + 7), shade(hexc("2B1D14"), 1.4))
    # Cascos blancos al cuello
    for name, (x, y, w, h) in faces(*BODY).items():
        if name != "bottom":
            rect(img, x, y, w, 1, hexc("F0F0F0"))
    # "V" roja de Valorant en el pecho
    chest_logo(img, [(0, 0), (4, 0), (0, 1), (4, 1), (1, 2), (3, 2), (2, 3)], hexc("FF4655"), ox=1, oy=3)
    # Flores de lavanda en la camiseta
    for (px, py) in [(1, 8), (6, 9), (3, 10)]:
        chest_logo(img, [(px, py)], hexc("7E57C2"), ox=0, oy=0)
    return img


def verity():
    """Verity (versión gorda): pelota amarilla con cara sonriente y sonrisa de dientes. Textura 128x128."""
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    yellow = hexc("FFD60A")
    boxes = [(0, 0, 16, 20, 16), (0, 36, 18, 14, 18), (0, 68, 20, 8, 20)]
    for box in boxes:
        for name, (x, y, w, h) in faces(*box).items():
            for i in range(w):
                for j in range(h):
                    # Sombreado suave: más claro arriba, más oscuro abajo y en los bordes.
                    edge = abs(i - (w - 1) / 2) / max(1, w / 2)
                    f = 1.08 - 0.12 * edge
                    if name == "top":
                        f = 1.12 - 0.1 * edge
                    elif name == "bottom":
                        f = 0.72
                    img.putpixel((x + i, y + j), shade(yellow, f))
    black, white, gray = hexc("111111"), hexc("FFFFFF"), hexc("B8B8B8")
    # Ojos en la cara del anillo central (18x14).
    fx, fy, _, _ = faces(0, 36, 18, 14, 18)["front"]
    for ex in (5, 11):
        rect(img, fx + ex, fy + 1, 2, 4, black)
        img.putpixel((fx + ex, fy + 1), shade(black, 1))
    # Sonrisa de dientes en la barriga (20x8).
    bx, by, _, _ = faces(0, 68, 20, 8, 20)["front"]
    img.putpixel((bx + 2, by), black)
    img.putpixel((bx + 17, by), black)
    rect(img, bx + 3, by + 1, 14, 1, black)
    for j in (2, 3, 4):
        img.putpixel((bx + 3, by + j), black)
        img.putpixel((bx + 16, by + j), black)
        rect(img, bx + 4, by + j, 12, 1, white)
    rect(img, bx + 4, by + 5, 12, 1, black)
    rect(img, bx + 5, by + 5, 10, 1, white)
    img.putpixel((bx + 4, by + 5), black)
    img.putpixel((bx + 15, by + 5), black)
    rect(img, bx + 5, by + 6, 10, 1, black)
    # Separación de dientes.
    for i in range(6, 15, 2):
        for j in (2, 3, 4, 5):
            img.putpixel((bx + i, by + j), gray)
    rect(img, bx + 4, by + 3, 12, 1, gray)
    return img


# ------------------------------------------------------------------ Items 16x16
def item(draw_fn):
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    draw_fn(img, ImageDraw.Draw(img))
    return img


def outline(img):
    """Contorno oscuro estilo Minecraft."""
    out = img.copy()
    for x in range(16):
        for y in range(16):
            if img.getpixel((x, y))[3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < 16 and 0 <= ny < 16 and img.getpixel((nx, ny))[3] > 0:
                        out.putpixel((x, y), (30, 20, 30, 255))
                        break
    return out


def draw_casco(img, d):
    d.rectangle([5, 3, 10, 13], fill=hexc("E8E8E8"))
    d.polygon([(5, 3), (7, 0), (8, 0), (10, 3)], fill=hexc("F2A33A"))
    d.rectangle([6, 5, 9, 7], fill=hexc("6EC6FF"))
    d.rectangle([5, 10, 10, 10], fill=hexc("F2A33A"))
    d.rectangle([3, 11, 4, 14], fill=hexc("3B3FD8"))
    d.rectangle([11, 11, 12, 14], fill=hexc("3B3FD8"))


def draw_motor(img, d):
    d.rectangle([3, 2, 12, 9], fill=hexc("5A5A66"))
    d.rectangle([4, 3, 11, 4], fill=hexc("8A8A99"))
    d.rectangle([7, 5, 8, 7], fill=hexc("FF3B30"))
    d.polygon([(4, 10), (11, 10), (13, 14), (2, 14)], fill=hexc("3A3A44"))
    d.rectangle([5, 14, 10, 15], fill=hexc("F2A33A"))
    d.point([(6, 15), (9, 15)], fill=hexc("FFE066"))


def draw_combustible(img, d):
    d.rectangle([4, 4, 11, 14], fill=hexc("C0392B"))
    d.rectangle([5, 5, 10, 13], fill=hexc("E74C3C"))
    d.rectangle([6, 2, 9, 3], fill=hexc("7F8C8D"))
    d.rectangle([6, 7, 9, 10], fill=hexc("F2A33A"))
    d.point([(7, 8), (8, 9)], fill=hexc("3B3FD8"))


def draw_nucleo(img, d):
    d.polygon([(8, 1), (13, 7), (8, 14), (3, 7)], fill=hexc("9FE3FF"))
    d.polygon([(8, 1), (13, 7), (8, 8)], fill=hexc("D9F5FF"))
    d.polygon([(8, 8), (3, 7), (8, 14)], fill=hexc("4FB6E8"))
    d.point([(8, 6), (7, 7)], fill=hexc("FFFFFF"))


def draw_mapa(img, d):
    d.rectangle([2, 3, 13, 12], fill=hexc("1B1440"))
    d.rectangle([2, 3, 13, 3], fill=hexc("D4AF37"))
    d.rectangle([2, 12, 13, 12], fill=hexc("D4AF37"))
    for p in [(4, 5), (11, 6), (6, 10), (9, 4), (12, 10)]:
        d.point(p, fill=hexc("FFFFFF"))
    d.ellipse([7, 6, 10, 9], fill=hexc("F2A33A"))
    d.point([(7, 6)], fill=hexc("3B3FD8"))
    d.line([(4, 5), (6, 10), (8, 8)], fill=hexc("FF4655"))


def draw_cohete(img, d):
    d.polygon([(10, 1), (14, 1), (14, 5)], fill=hexc("F2A33A"))
    d.polygon([(4, 7), (10, 1), (14, 5), (8, 11)], fill=hexc("EDEDED"))
    d.ellipse([8, 4, 10, 6], fill=hexc("6EC6FF"))
    d.polygon([(4, 7), (2, 8), (3, 10), (6, 9)], fill=hexc("3B3FD8"))
    d.polygon([(8, 11), (7, 13), (5, 12), (6, 9)], fill=hexc("3B3FD8"))
    d.polygon([(5, 9), (7, 11), (2, 15), (1, 14)], fill=hexc("FF8C1A"))
    d.point([(2, 14), (3, 13)], fill=hexc("FFE066"))


def draw_carta(img, d):
    d.rectangle([1, 3, 14, 12], fill=hexc("F8EBC6"))
    d.polygon([(1, 3), (8, 8), (14, 3)], fill=hexc("E8D29A"))
    d.line([(1, 3), (8, 8), (14, 3)], fill=hexc("B89A5A"))
    d.ellipse([6, 7, 9, 10], fill=hexc("F2A33A"))
    d.point([(7, 8), (8, 8)], fill=hexc("3B3FD8"))


def draw_iceberg(img, d):
    d.rectangle([0, 11, 15, 15], fill=hexc("2C7FB8"))
    d.polygon([(2, 11), (6, 3), (8, 5), (10, 2), (14, 11)], fill=hexc("D9F5FF"))
    d.polygon([(6, 3), (8, 5), (7, 11), (4, 11)], fill=hexc("9FE3FF"))
    d.line([(0, 11), (15, 11)], fill=hexc("FFFFFF"))


def draw_mate(img, d):
    d.ellipse([3, 5, 12, 14], fill=hexc("8D5524"))
    d.ellipse([4, 4, 11, 7], fill=hexc("5B8C2A"))
    d.rectangle([4, 9, 11, 10], fill=hexc("75AADB"))
    d.line([(9, 6), (13, 0)], fill=hexc("C0C0C0"), width=1)
    d.point([(13, 0)], fill=hexc("E0E0E0"))


def draw_estrella(img, d):
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        r = 7 if i % 2 == 0 else 3
        pts.append((7.5 + math.cos(a) * r, 8 + math.sin(a) * r))
    d.polygon(pts, fill=hexc("FFD400"))
    d.rectangle([6, 6, 6, 8], fill=hexc("111111"))
    d.rectangle([9, 6, 9, 8], fill=hexc("111111"))


# ------------------------------------------------------------------ Bloque, efectos, GUI
def fragmento():
    img = Image.new("RGBA", (16, 16))
    for x in range(16):
        for y in range(16):
            img.putpixel((x, y), shade(hexc("2A1F3D"), 0.8 + rng.random() * 0.4))
    d = ImageDraw.Draw(img)
    d.line([(0, 4), (5, 6), (9, 3), (15, 7)], fill=hexc("F2A33A"))
    d.line([(2, 13), (7, 10), (11, 12), (15, 11)], fill=hexc("FF7A1A"))
    d.line([(6, 6), (7, 10)], fill=hexc("F6C453"))
    for p in [(3, 9), (12, 2), (10, 14)]:
        d.point(p, fill=hexc("6E5BFF"))
    return img


def regolito():
    """Polvo lunar naranja con motas moradas y mini cráteres."""
    img = Image.new("RGBA", (16, 16))
    base = hexc("E8963A")
    for x in range(16):
        for y in range(16):
            c = shade(base, 0.85 + rng.random() * 0.3)
            if rng.random() < 0.08:
                c = hexc("9A5BC4")
            img.putpixel((x, y), c)
    for (cx, cy) in [(4, 4), (11, 10), (3, 12)]:
        img.putpixel((cx, cy), shade(base, 0.6))
        img.putpixel((cx + 1, cy), shade(base, 0.7))
        img.putpixel((cx, cy + 1), shade(base, 1.2))
    return img


def roca():
    """Roca lunar morada con vetas naranjas."""
    img = Image.new("RGBA", (16, 16))
    base = hexc("5B3F8C")
    for x in range(16):
        for y in range(16):
            img.putpixel((x, y), shade(base, 0.8 + rng.random() * 0.35))
    d = ImageDraw.Draw(img)
    d.line([(1, 3), (5, 5), (8, 4)], fill=shade(hexc("F2A33A"), 0.85))
    d.line([(9, 12), (14, 10)], fill=shade(hexc("F2A33A"), 0.85))
    d.point([(12, 3), (3, 10), (7, 14)], fill=hexc("3B2A5E"))
    return img


def mudokon(abe=False):
    """Mudokon de Oddworld: piel verde grisácea, ojos naranjas, boca cosida, taparrabos."""
    skin = hexc("7FA08A") if abe else hexc("6E8C6A")
    img = humanoid(skin, skin, skin, skin, shade(skin, 0.85))
    f = faces(*HEAD)
    for name, (x, y, w, h) in f.items():
        rect(img, x, y, w, h, skin, 0.08)
    fx, fy = front(HEAD)
    for ex in (fx + 1, fx + 5):
        rect(img, ex, fy + 2, 2, 2, hexc("1A1A1A"))
        img.putpixel((ex + (1 if ex == fx + 1 else 0), fy + 2), hexc("E07A1F"))
        img.putpixel((ex + (1 if ex == fx + 1 else 0), fy + 3), hexc("F2A33A"))
    rect(img, fx + 2, fy + 6, 4, 1, hexc("3A2A1A"))
    for i in range(2, 6):
        img.putpixel((fx + i, fy + 5 + (i % 2) * 2), hexc("3A2A1A"))
    rect(img, fx + 3, fy + 4, 2, 1, shade(skin, 0.7))
    # Taparrabos
    for leg in (RLEG, LLEG):
        for name, (x, y, w, h) in faces(*leg).items():
            if name not in ("top", "bottom"):
                rect(img, x, y, w, 4, hexc("6B4A2B"), 0.15)
    for name, (x, y, w, h) in faces(*BODY).items():
        if name not in ("top", "bottom"):
            rect(img, x, y + h - 2, w, 2, hexc("6B4A2B"), 0.15)
    # Costillas marcadas
    bx, by = front(BODY)
    for j in (3, 5, 7):
        rect(img, bx + 1, by + j, 2, 1, shade(skin, 0.8))
        rect(img, bx + 5, by + j, 2, 1, shade(skin, 0.8))
    if abe:
        # La coleta de Abe
        hx, hy, w, h = faces(*HAT)["back"]
        rect(img, hx + 3, hy, 2, 7, hexc("3B2A1A"))
        tx, ty, w, h = faces(*HAT)["top"]
        rect(img, tx + 3, ty + 5, 2, 3, hexc("3B2A1A"))
    return img


SOURCE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "source")
AROY_PORTRAITS = ["aroy_feliz", "aroy_risa", "aroy_serio", "aroy_feliz_verde", "aroy_risa_verde"]


def aroy_portraits():
    """Retratos de Aroy (la lata de leche de coco) para los diálogos: 160x256."""
    for name in AROY_PORTRAITS:
        im = Image.open(os.path.join(SOURCE, name + ".png")).convert("RGBA")
        save(im.resize((160, 256), Image.LANCZOS), "portrait", name + ".png")


def aroy_entity():
    """Lata Aroy-D en 3D. Modelo declarado a 64x128 y textura HD x4 (256x512)."""
    K = 4
    img = Image.new("RGBA", (64 * K, 128 * K), (0, 0, 0, 0))
    src = Image.open(os.path.join(SOURCE, "aroy_feliz.png")).convert("RGBA")
    label = src.crop((15, 70, 630, 980)).convert("RGBA")
    front_img = label.resize((12 * K, 18 * K), Image.LANCZOS)
    top_c, bottom_c = hexc("1A0F06"), hexc("8A3A10")

    def side(x, y, w, h):
        for j in range(h * K):
            c = lerp(top_c, bottom_c, (j / (h * K)) ** 1.4)
            for i in range(w * K):
                edge = abs(i - (w * K - 1) / 2) / (w * K / 2)
                img.putpixel((x * K + i, y * K + j), shade((c[0], c[1], c[2], 255), 1.05 - 0.25 * edge))

    def lid(x, y, w, h, color):
        for i in range(w * K):
            for j in range(h * K):
                dx = (i - (w * K - 1) / 2) / (w * K / 2)
                dy = (j - (h * K - 1) / 2) / (h * K / 2)
                r = math.hypot(dx, dy)
                f = 0.75 if 0.78 < r < 0.9 else 1.0 - 0.15 * r
                img.putpixel((x * K + i, y * K + j), shade(color, f))

    silver = hexc("C9CCD2")
    # Cuerpo 12x18x12
    f = faces(0, 0, 12, 18, 12)
    for name in ("right", "left"):
        side(*f[name])
    for name in ("front", "back"):
        x, y, w, h = f[name]
        img.paste(front_img, (x * K, y * K))
    lid(*f["top"], silver)
    lid(*f["bottom"], silver)
    # Cuerpo girado 9x18x9 (redondea la lata)
    f = faces(0, 32, 9, 18, 9)
    for name in ("right", "left", "front", "back"):
        side(*f[name])
    lid(*f["top"], silver)
    lid(*f["bottom"], silver)
    # Bordes metálicos
    for v in (64, 80):
        for name, (x, y, w, h) in faces(0, v, 13, 1, 13).items():
            if name in ("top", "bottom"):
                lid(x, y, w, h, silver)
            else:
                for i in range(w * K):
                    for j in range(h * K):
                        img.putpixel((x * K + i, y * K + j), shade(silver, 0.8 + 0.3 * (j / (h * K))))
    return img


def leche_de_coco_item():
    im = Image.open(os.path.join(SOURCE, "aroy_feliz.png")).convert("RGBA")
    im = im.resize((10, 16), Image.LANCZOS)
    out = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    out.paste(im, (3, 0), im)
    for x in range(16):
        for y in range(16):
            r, g, b, a = out.getpixel((x, y))
            out.putpixel((x, y), (r, g, b, 255 if a > 100 else 0))
    return out


def effect_dormido():
    img = Image.new("RGBA", (18, 18), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for (x, y, s) in [(1, 9, 7), (8, 4, 5), (13, 1, 4)]:
        d.line([(x, y), (x + s, y)], fill=hexc("B57EDC"), width=1)
        d.line([(x + s, y), (x, y + s)], fill=hexc("B57EDC"), width=1)
        d.line([(x, y + s), (x + s, y + s)], fill=hexc("B57EDC"), width=1)
    return img


def effect_despierto():
    img = Image.new("RGBA", (18, 18), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([3, 6, 13, 16], fill=hexc("8D5524"))
    d.ellipse([4, 5, 12, 8], fill=hexc("5B8C2A"))
    d.line([(10, 7), (15, 0)], fill=hexc("C0C0C0"))
    return img


def planet(size=256):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    c = size / 2
    r = size * 0.36
    blue, purple, orange, yellow = hexc("3B3FD8"), hexc("7B3FC4"), hexc("F2A33A"), hexc("F6C453")
    for x in range(size):
        for y in range(size):
            dx, dy = x - c, y - c
            if dx * dx + dy * dy <= r * r:
                t = max(0, min(1, ((dx + dy) / (2 * r)) + 0.5))
                col = lerp(blue, purple, t / 0.4) if t < 0.4 else lerp(purple, orange, (t - 0.4) / 0.35) if t < 0.75 else lerp(orange, yellow, (t - 0.75) / 0.25)
                light = 1.15 - math.hypot(dx + r * 0.3, dy + r * 0.3) / (2.2 * r)
                img.putpixel((x, y), shade(col, light))
    d = ImageDraw.Draw(img)
    s = size / 256
    navy, white, teal = hexc("1B1440"), hexc("FFFFFF"), hexc("2EC4C4")
    # Cascos gamer
    d.arc([c - r - 14 * s, c - r - 16 * s, c + r + 14 * s, c + r + 10 * s], 190, 350, fill=hexc("1E1E24"), width=int(12 * s))
    d.rounded_rectangle([c - r - 22 * s, c - 30 * s, c - r + 6 * s, c + 26 * s], radius=int(8 * s), fill=hexc("2B2B33"))
    d.rounded_rectangle([c + r - 6 * s, c - 30 * s, c + r + 22 * s, c + 26 * s], radius=int(8 * s), fill=hexc("2B2B33"))
    d.line([(c - r - 4 * s, c + 20 * s), (c - 40 * s, c + 52 * s)], fill=hexc("111111"), width=int(5 * s))
    d.ellipse([c - 46 * s, c + 46 * s, c - 32 * s, c + 58 * s], fill=hexc("111111"))
    # Cejas, ojos, boca
    d.line([(c - 52 * s, c - 40 * s), (c - 16 * s, c - 24 * s)], fill=navy, width=int(8 * s))
    d.line([(c + 52 * s, c - 40 * s), (c + 16 * s, c - 24 * s)], fill=navy, width=int(8 * s))
    for ex in (-34, 34):
        d.ellipse([c + (ex - 10) * s, c - 22 * s, c + (ex + 10) * s, c + 8 * s], fill=navy)
        d.ellipse([c + (ex - 6) * s, c - 18 * s, c + (ex - 1) * s, c - 10 * s], fill=white)
    d.ellipse([c - 20 * s, c + 22 * s, c + 20 * s, c + 52 * s], fill=teal, outline=navy, width=int(4 * s))
    d.ellipse([c - 10 * s, c + 34 * s, c + 10 * s, c + 50 * s], fill=hexc("0E4F5C"))
    # Nubes
    for (cx, cy, k) in [(40, 60, 1.0), (215, 170, 1.2), (60, 205, 0.8)]:
        for (ox, oy, rr) in [(0, 0, 16), (14, -6, 14), (28, 2, 12), (-12, 4, 11)]:
            d.ellipse([(cx + ox * k - rr * k) * s, (cy + oy * k - rr * k) * s, (cx + ox * k + rr * k) * s, (cy + oy * k + rr * k) * s],
                      fill=hexc("E6EEFF"), outline=hexc("2B3A8C"))
    return img


def main():
    save(turbopapuense(False), "entity", "turbopapuense.png")
    save(turbopapuense(True), "entity", "turbopapuense_dormido.png")
    save(alphatemp(False), "entity", "alphatemp.png")
    save(alphatemp(True), "entity", "alphafaterfur.png")
    save(william(), "entity", "william_piraton.png")
    # juanma.png viene del mod LoyolaQuest (skin HD de Aroy); no se genera.
    save(guinxu(), "entity", "guinxu.png")
    save(elink(), "entity", "elink_64.png")
    save(sualenidus(), "entity", "sualenidus.png")
    save(verity(), "entity", "verity_gorda.png")
    for name, fn in [("casco_cohete", draw_casco), ("motor_turbo", draw_motor), ("combustible_papu", draw_combustible),
                     ("nucleo_iceberg", draw_nucleo), ("mapa_estelar", draw_mapa), ("cohete", draw_cohete),
                     ("carta_de_auxilio", draw_carta), ("iceberg_de_bolsillo", draw_iceberg), ("mate", draw_mate),
                     ("estrella_de_poder", draw_estrella)]:
        save(outline(item(fn)), "item", name + ".png")
    save(fragmento(), "block", "fragmento_meteorito.png")
    save(regolito(), "block", "regolito_papu.png")
    save(roca(), "block", "roca_papu.png")
    save(mudokon(False), "entity", "mudokon.png")
    save(mudokon(True), "entity", "abe.png")
    aroy_portraits()
    save(aroy_entity(), "entity", "aroy.png")
    save(leche_de_coco_item(), "item", "leche_de_coco.png")
    save(effect_dormido(), "mob_effect", "dormido.png")
    save(effect_despierto(), "mob_effect", "despierto.png")
    p = planet(256)
    save(p, "gui", "planeta_turbopapu.png")
    icon = p.resize((128, 128), Image.LANCZOS)
    icon.save(os.path.join(ROOT, "icon.png"))
    print("ok icon.png")


if __name__ == "__main__":
    main()
