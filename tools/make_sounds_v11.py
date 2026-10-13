"""v0.11 sound pass: evolution, elements, combos, milestones, companions.

Run:  python3 tools/make_sounds_v11.py   (uses the building blocks in make_sounds.py)
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_sounds import *


def make_sfx_v11():
    S = {}
    # Evolution: a rising sweep into a big major chord and bells
    S["evolve"] = reverb(mix(
        sweep_filter(noise(1.2), 200, 8000, width=0.5) * np.linspace(0, 1, int(1.2 * SR)) ** 2 * 0.35,
        osc("saw", 110, 1.2, 440, curve=0.6) * env(int(1.2 * SR), 0.4, 0.8, 0, 0.05) * 0.15,
        at(thump(110, 30, 0.7, 0.3) * 1.2, 1.1),
        at(chord_pad([48, 55, 60, 64, 67, 72], 2.2, 0.01, 1.4, "saw", 4000) * 0.9, 1.1),
        at(arp([72, 76, 79, 84, 88, 91, 96], 0.06, 0.6, "square", 0.2, 0.25, 7000) * 0.4, 1.15),
        at(bell(note(96), 1.8, 0.6) * 0.35, 1.5), at(bell(note(91), 1.8, 0.6) * 0.3, 1.58)), 0.4, 1.5, 1.5)
    # Hitting a weakness: the normal hit with a bright ping on top
    S["weak_hit"] = mix(thump(190, 50, 0.14, 0.05), snap(0.06, 2500, 11000, 0.015) * 0.8,
                        at(bell(1760, 0.25, 0.08, 1.2) * 0.35, 0.01))
    # Resisted: a dull thud
    S["resisted"] = mix(lp(thump(110, 50, 0.12, 0.05), 600), lp(noise(0.06), 500) * perc(int(0.06 * SR), 0.001, 0.02) * 0.4)
    # Freeze: icy crackle rising
    crack = mix(*[at(bp(noise(0.02), 4000, 12000) * perc(int(0.02 * SR), 0.0005, 0.004) * rng.uniform(0.3, 1), rng.uniform(0, 0.35)) for _ in range(18)])
    S["freeze"] = reverb(mix(crack, osc("sine", 1200, 0.4, 2400) * env(int(0.4 * SR), 0.02, 0.35, 0, 0.05) * 0.2,
                             at(bell(note(100), 0.5, 0.2) * 0.25, 0.25)), 0.3, 0.9, 0.5)
    # Shatter: glass burst
    S["shatter"] = reverb(mix(thump(220, 60, 0.15, 0.04), hp(noise(0.5), 3000) * env(int(0.5 * SR), 0.001, 0.45, 0, 0.05) * 0.7,
                              *[at(bell(rng.uniform(2500, 5000), 0.3, 0.06, 1.5) * 0.15, rng.uniform(0, 0.15)) for _ in range(8)]), 0.25, 0.8, 0.4)
    # A combo (conduct, toxic, purge): zap + chime
    S["combo"] = reverb(mix(osc("square", 1600, 0.15, 300, duty=0.2) * perc(int(0.15 * SR), 0.001, 0.05) * 0.4,
                            bp(noise(0.12), 2000, 8000) * perc(int(0.12 * SR), 0.001, 0.03) * 0.6,
                            at(arp([84, 91], 0.05, 0.3, "tri", 0.1, 0.5, 8000) * 0.4, 0.06)), 0.2, 0.8, 0.4)
    # Milestone / checkpoint: a small fanfare
    S["milestone"] = reverb(mix(arp([67, 72, 76, 79], 0.09, 0.5, "square", 0.15, 0.25, 6000) * 0.5,
                                at(chord_pad([55, 60, 64, 67], 1.0, 0.02, 0.6, "saw", 3000) * 0.5, 0.36),
                                at(thump(100, 40, 0.4, 0.15), 0.36)), 0.3, 1.0, 0.7)
    # Companion: two cheerful chirps
    S["pet"] = reverb(mix(osc("sine", 1500, 0.07, 2300, curve=0.5) * perc(int(0.07 * SR), 0.002, 0.03) * 0.5,
                          at(osc("sine", 1700, 0.09, 2700, curve=0.5) * perc(int(0.09 * SR), 0.002, 0.04) * 0.5, 0.1)), 0.15, 0.6, 0.3)
    # Curse taken: low ominous swell
    S["curse"] = reverb(mix(chord_pad([37, 44, 49], 1.2, 0.2, 0.7, "saw", 700) * 0.9, lp(noise(1.2), 300) * env(int(1.2 * SR), 0.3, 0.8, 0, 0.1) * 0.5), 0.4, 1.3, 1.0)
    # Boss enrage: alarm stab
    S["enrage"] = mix(osc("saw", 220, 0.35, 180) * env(int(0.35 * SR), 0.005, 0.3, 0, 0.03) * 0.5,
                      osc("saw", 233, 0.35, 190) * env(int(0.35 * SR), 0.005, 0.3, 0, 0.03) * 0.5, thump(90, 30, 0.4, 0.15))
    for name, x in S.items():
        save(name, x, 0.85)
    return list(S)


# The boss theme's second phase: same key, faster and heavier (plays below half health or when enraged)
BOSS2 = {"bpm": 152, "root": 40, "scale": "phrygian", "prog": [0, 0, 1, 0, 5, 5, 1, 6], "bars": 8, "pad": True, "pad_cut": 1900,
         "bass": [0, 0, 12, 0, 0, 12, 0, 12, 0, 0, 12, 0, 7, 7, 6, 6], "bass_kind": "saw",
         "arp": [0, 3, 1, 3, 2, 3, 1, 3, 0, 4, 1, 4, 2, 4, 1, 4], "arp_kind": "square", "arp_cut": 4200, "lead": 6, "lead_kind": "saw", "lead_rest": 0.2,
         "drums": "KhKhShKhKhKhSKSh", "seed": 21, "verb": 0.18, "gains": {"bass": 0.6, "drums": 0.75, "lead": 0.24, "pad": 0.32}}


def make_boss2():
    x = song(BOSS2)
    save("music_boss2", x, 0.82, rate=32000, loop=True)
    return len(x) / SR


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    if "--music" in sys.argv:
        print("boss2 seconds:", make_boss2())
    else:
        print("v11 sfx:", make_sfx_v11())
