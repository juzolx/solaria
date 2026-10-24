"""Frame sheet + GIF previews for the FEMALE body idle/attack clips (generated from make_anims.py).
/c/ai/ComfyUI/python_embeded/python.exe -I make_anims.py"""
import os, sys
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(HERE, "..", "hero", "tools"))
import hero
import make_sheets as MS

A = os.path.join(HERE, "female", "anims")
C = 84  # her attack canvas; idle (64) is centred on it


def clip(name):
    d = os.path.join(A, name)
    out = []
    for f in sorted(os.listdir(d)):
        im = Image.open(os.path.join(d, f)).convert("RGBA")
        if im.width != C:
            p = Image.new("RGBA", (C, C)); p.alpha_composite(im, ((C - im.width) // 2, (C - im.height) // 2)); im = p
        out.append(im)
    return out


def scene(frame, feet):
    """Battle mockup, hero frame placed where ours stands: feet row of its clip at y 603, centre x 203."""
    m = MS.mockup(Image.new("RGBA", (80, 80)))
    d = ImageDraw.Draw(m)
    d.rectangle([0, 40, 430, 68], fill=(18, 14, 22, 255))
    d.text((16, 44), "PixelLab hero (female): idle -> attack", font=MS.F_S, fill=MS.GOLD)
    sh = Image.new("RGBA", (138, 24), (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([0, 0, 137, 23], fill=(40, 46, 70, 150))
    ImageDraw.Draw(sh).ellipse([6, 3, 131, 20], fill=(8, 8, 16, 150))
    m.alpha_composite(sh, (203 - 69, 603 - 14))
    z = hero.zoom(frame, 3)
    m.alpha_composite(z, (203 - z.width // 2, 603 - feet * 3))
    return m


def feet_row(frames):
    return max(f.getbbox()[3] for f in frames)


def gif(frames, path, z, ms):
    ims = []
    for f in frames:
        b = Image.new("RGBA", f.size, MS.PANEL); b.alpha_composite(f)
        ims.append(hero.zoom(b, z).convert("P", palette=Image.ADAPTIVE) if z > 1 else b.convert("P", palette=Image.ADAPTIVE))
    ims[0].save(path, save_all=True, append_images=ims[1:], duration=ms, loop=0, disposal=2)


def main():
    clips = {k: clip(k) for k in ["idle_north", "attack_north", "idle_south", "attack_south"]}
    fi, fa = feet_row(clips["idle_north"]), feet_row(clips["attack_north"])
    S = MS.Sheet(40 + 9 * 280, 1360, "PixelLab hero (female) - idle + attack frames (3x)",
                 "Idle: breathing-idle template, 4 frames. Attack: custom v3 'overhead diagonal slash', 9 frames (frame 0 = rest pose).")
    y = 110
    for k, lab in [("idle_north", "1  Idle - NORTH (battle view)"), ("attack_north", "2  Attack - NORTH (battle view): overhead slash"),
                   ("idle_south", "3  Idle - SOUTH (front)"), ("attack_south", "4  Attack - SOUTH (front)")]:
        S.panel(20, y, 9 * 280, 302, lab)
        for i, f in enumerate(clips[k]):
            S.put(f, 40 + i * 278, y + 36, 3, bg=(52, 48, 60, 255))
            S.d.text((44 + i * 278, y + 40), str(i), font=MS.F_S, fill=MS.DIM)
        y += 312
    S.im.convert("RGB").save(os.path.join(HERE, "female", "02_FEMALE_anim_frames.png"))
    for k, ms in [("idle_north", 220), ("idle_south", 220), ("attack_north", 90), ("attack_south", 90)]:
        gif(clips[k], os.path.join(HERE, "female", f"03_FEMALE_{k}_4x.gif"), 4, ms)
    # phone battle loop: idle x2, attack, idle
    seq = [(f, fi) for f in clips["idle_north"] * 2] + [(f, fa) for f in clips["attack_north"]] + [(f, fi) for f in clips["idle_north"]]
    durs = [220] * 8 + [90] * 9 + [220] * 4
    frames = [scene(f, ft).convert("RGB").convert("P", palette=Image.ADAPTIVE) for f, ft in seq]
    frames[0].save(os.path.join(HERE, "female", "04_FEMALE_battle_loop_430x932.gif"), save_all=True,
                   append_images=frames[1:], duration=durs, loop=0)


if __name__ == "__main__":
    main()
