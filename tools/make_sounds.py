"""Renders every Solaria sound effect and music loop to sounds/*.wav.

Run:  python3 tools/make_sounds.py
Everything is synthesized from scratch (no samples), so it's free to use.
"""
import os
import wave
import numpy as np
from scipy.signal import butter, sosfilt

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "sounds")
rng = np.random.default_rng(7)


# ---------------------------------------------------------------- basics
def t_of(dur):
    return np.arange(int(dur * SR)) / SR


def freq_curve(f0, f1, n, curve=1.0):
    k = np.linspace(0, 1, n) ** curve
    return f0 * (f1 / f0) ** k if f0 > 0 and f1 > 0 else f0 + (f1 - f0) * k


def osc(kind, f0, dur, f1=None, duty=0.5, curve=1.0):
    n = int(dur * SR)
    f = freq_curve(f0, f1 if f1 else f0, n, curve)
    ph = np.cumsum(f) / SR
    x = ph % 1.0
    if kind == "sine":
        return np.sin(2 * np.pi * ph)
    if kind == "square":
        return np.where(x < duty, 1.0, -1.0)
    if kind == "saw":
        return 2 * x - 1
    if kind == "tri":
        return 1 - 4 * np.abs(x - 0.5)
    raise ValueError(kind)


def noise(dur):
    return rng.uniform(-1, 1, int(dur * SR))


def env(n, a=0.002, d=0.1, s=0.0, r=0.05, hold=0.0):
    """Attack / decay to sustain / hold / release, length n samples."""
    out = np.zeros(n)
    ai, di, hi = int(a * SR), int(d * SR), int(hold * SR)
    i = 0
    seg = min(ai, n)
    out[:seg] = np.linspace(0, 1, seg, endpoint=False) if seg else 0
    i = seg
    seg = min(di, n - i)
    if seg > 0:
        out[i:i + seg] = 1 + (s - 1) * (1 - np.exp(-5 * np.linspace(0, 1, seg))) / (1 - np.exp(-5))
        i += seg
    seg = min(hi, n - i)
    if seg > 0:
        out[i:i + seg] = s
        i += seg
    if i < n:
        start = out[i - 1] if i > 0 else s
        out[i:] = start * np.exp(-np.linspace(0, 1, n - i) * (5.0 / max(r, 1e-3)) * ((n - i) / SR))
    return out


def perc(n, a=0.001, decay=0.1):
    t = np.arange(n) / SR
    e = np.exp(-t / decay)
    ai = max(1, int(a * SR))
    e[:ai] *= np.linspace(0, 1, ai)
    return e


def lp(x, cutoff, order=2):
    return sosfilt(butter(order, min(cutoff, SR / 2 - 100), "low", fs=SR, output="sos"), x)


def hp(x, cutoff, order=2):
    return sosfilt(butter(order, cutoff, "high", fs=SR, output="sos"), x)


def bp(x, lo, hi, order=2):
    return sosfilt(butter(order, [lo, min(hi, SR / 2 - 100)], "band", fs=SR, output="sos"), x)


def sweep_filter(x, f0, f1, kind="band", width=0.6, steps=48):
    """Filter in chunks with a moving cutoff (cheap time-varying filter)."""
    out = np.zeros_like(x)
    chunks = np.array_split(np.arange(len(x)), steps)
    for i, idx in enumerate(chunks):
        if len(idx) == 0:
            continue
        f = f0 * (f1 / f0) ** (i / max(1, steps - 1))
        lo, hi = f * (1 - width / 2), f * (1 + width / 2)
        seg = x[max(0, idx[0] - 256):idx[-1] + 1]
        y = bp(seg, max(30, lo), hi) if kind == "band" else lp(seg, f)
        out[idx] = y[-len(idx):]
    return out


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[:len(p)] += p
    return out


def at(x, sec, total=None):
    """Delay a sound by sec seconds."""
    pad = np.zeros(int(sec * SR))
    y = np.concatenate([pad, x])
    if total:
        y = np.pad(y, (0, max(0, int(total * SR) - len(y))))[:int(total * SR)]
    return y


def reverb(x, wet=0.25, size=1.0, tail=0.8, damp=4000):
    """Small Schroeder-style reverb."""
    x = np.concatenate([x, np.zeros(int(tail * SR))])
    out = np.zeros_like(x)
    for d, g in [(0.0297, 0.77), (0.0371, 0.75), (0.0411, 0.73), (0.0437, 0.71)]:
        di = int(d * size * SR)
        y = np.copy(x)
        # feedback comb via block recursion
        for start in range(di, len(y), di):
            end = min(start + di, len(y))
            y[start:end] += g * y[start - di:end - di]
        out += y
    out = lp(out / 4, damp)
    for d, g in [(0.005, 0.7), (0.0017, 0.7)]:
        di = int(d * SR)
        y = np.zeros_like(out)
        buf = np.copy(out)
        y[:di] = -g * buf[:di]
        for i in range(di, len(out), di):
            end = min(i + di, len(out))
            y[i:end] = -g * buf[i:end] + buf[i - di:end - di] + g * y[i - di:end - di]
        out = y
    return x * (1 - wet) + out * wet


def note(n):
    """MIDI note number to Hz."""
    return 440.0 * 2 ** ((n - 69) / 12)


def norm(x, peak=0.9):
    m = np.max(np.abs(x))
    return x / m * peak if m > 0 else x


def fade_out(x, sec=0.02):
    n = min(len(x), int(sec * SR))
    x = np.copy(x)
    x[-n:] *= np.linspace(1, 0, n)
    return x


def save(name, x, peak=0.9, rate=SR, loop=False):
    if loop:  # filter twice around so the loop point stays seamless
        x = hp(np.concatenate([x, x]), 25)[len(x):]
        x = norm(x, peak)
    else:
        x = fade_out(norm(hp(x, 25), peak))
        k = int(0.002 * SR)
        x[:k] *= np.linspace(0, 1, k)
    if rate != SR:
        idx = np.arange(0, len(x), SR / rate)
        x = np.interp(idx, np.arange(len(x)), x)
    data = (np.clip(x, -1, 1) * 32767).astype("<i2").tobytes()
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(data)


# ---------------------------------------------------------------- building blocks
def thump(f0=160, f1=50, dur=0.12, decay=0.05):
    return osc("sine", f0, dur, f1, curve=0.4) * perc(int(dur * SR), 0.001, decay)


def snap(dur=0.05, lo=1500, hi=8000, decay=0.015):
    return bp(noise(dur), lo, hi) * perc(int(dur * SR), 0.0005, decay)


def bell(f, dur=1.0, decay=0.35, bright=1.0):
    n = int(dur * SR)
    out = np.zeros(n)
    for ratio, amp, dk in [(1, 1, 1), (2.0, 0.5 * bright, 0.6), (2.76, 0.35 * bright, 0.45), (5.4, 0.2 * bright, 0.25), (8.93, 0.1 * bright, 0.15)]:
        out += amp * osc("sine", f * ratio, dur) * perc(n, 0.001, decay * dk)
    return out


def pluck(f, dur=0.4, decay=0.12, kind="square", duty=0.25, cutoff=3500):
    n = int(dur * SR)
    return lp(osc(kind, f, dur, duty=duty), cutoff) * perc(n, 0.002, decay)


def coin(f1, f2, gap=0.06, dur=0.35):
    a = osc("square", f1, gap, duty=0.5) * 0.6
    b = osc("square", f2, dur - gap, duty=0.5) * perc(int((dur - gap) * SR), 0.0, 0.09)
    return lp(np.concatenate([a, b]), 6000)


def arp(notes, step, dur_each, kind="square", decay=0.12, duty=0.25, cutoff=5000):
    total = step * (len(notes) - 1) + dur_each
    out = np.zeros(int(total * SR) + 1)
    for i, m in enumerate(notes):
        p = pluck(note(m), dur_each, decay, kind, duty, cutoff)
        s = int(i * step * SR)
        out[s:s + len(p)] += p
    return out


def chord_pad(notes, dur, a=0.05, r=0.6, kind="saw", cutoff=2500, detune=0.004):
    n = int(dur * SR)
    out = np.zeros(n)
    for m in notes:
        for d in (-detune, detune):
            out += osc(kind, note(m) * (1 + d), dur)
    out = lp(out, cutoff) / (len(notes) * 2)
    return out * env(n, a, 0.2, 0.7, r, hold=max(0, dur - a - 0.2 - r))


def whoosh(dur=0.22, f0=600, f1=3000, amp_peak=0.4):
    n = int(dur * SR)
    x = sweep_filter(noise(dur), f0, f1, width=0.8)
    shape = np.sin(np.pi * np.linspace(0, 1, n) ** amp_peak)
    return x * shape


# ---------------------------------------------------------------- sound effects
def make_sfx():
    S = {}
    # Combat
    S["hit"] = mix(thump(170, 55, 0.13, 0.045), snap(0.06, 1200, 6000, 0.012) * 0.7, lp(noise(0.09), 900) * perc(int(0.09 * SR), 0.001, 0.03) * 0.5)
    S["crit"] = reverb(mix(thump(200, 45, 0.2, 0.07) * 1.2, snap(0.08, 2000, 12000, 0.02),
                           bell(1350, 0.35, 0.18, 0.6) * 0.35, osc("square", 900, 0.12, 250, duty=0.3) * perc(int(0.12 * SR), 0.001, 0.04) * 0.25), 0.15, 0.7, 0.3)
    S["hurt"] = mix(thump(120, 45, 0.16, 0.06), lp(noise(0.14), 600) * perc(int(0.14 * SR), 0.001, 0.05) * 0.8,
                    osc("square", 220, 0.1, 110, duty=0.4) * perc(int(0.1 * SR), 0.001, 0.03) * 0.2)
    S["tap"] = mix(thump(260, 90, 0.07, 0.02), snap(0.03, 2500, 9000, 0.006) * 0.5)
    S["kill"] = reverb(mix(thump(140, 35, 0.35, 0.12) * 1.1,
                           lp(noise(0.4), 2200) * env(int(0.4 * SR), 0.005, 0.35, 0.0, 0.05) * 0.6,
                           osc("square", 520, 0.25, 90, duty=0.3, curve=0.6) * perc(int(0.25 * SR), 0.001, 0.08) * 0.25), 0.2, 0.8, 0.4)
    S["dodge"] = whoosh(0.2, 900, 4500) * 0.9
    S["burn"] = mix(*[at(bp(noise(0.03), 1500, 7000) * perc(int(0.03 * SR), 0.0005, 0.006) * rng.uniform(0.3, 1), rng.uniform(0, 0.3)) for _ in range(14)],
                    lp(noise(0.35), 500) * env(int(0.35 * SR), 0.03, 0.3, 0.0, 0.05) * 0.5)
    tw = []
    for i in range(3):
        f = 1800 + 400 * i
        tw.append(at(osc("sine", f, 0.18, f * 1.5) * perc(int(0.18 * SR), 0.002, 0.06), i * 0.09))
    S["stun"] = reverb(mix(thump(150, 60, 0.1, 0.04), *tw), 0.25, 0.8, 0.4)
    S["buff"] = reverb(mix(osc("tri", 300, 0.45, 900, curve=0.7) * env(int(0.45 * SR), 0.02, 0.4, 0, 0.05) * 0.5,
                           sweep_filter(noise(0.45), 500, 5000, width=0.4) * np.linspace(0.2, 1, int(0.45 * SR)) * 0.3,
                           at(bell(note(84), 0.5, 0.2) * 0.3, 0.3)), 0.3, 1.0, 0.5)
    S["ability"] = reverb(mix(whoosh(0.18, 400, 3500) * 0.8, at(thump(180, 40, 0.25, 0.08), 0.12) * 1.1,
                              at(snap(0.1, 1500, 10000, 0.03), 0.12) * 0.8, at(osc("saw", 110, 0.25, 55) * perc(int(0.25 * SR), 0.002, 0.1) * 0.3, 0.12)), 0.2, 0.9, 0.4)
    S["potion"] = reverb(mix(*[at(osc("sine", f, 0.07, f * 1.6, curve=0.5) * perc(int(0.07 * SR), 0.002, 0.03) * 0.6, i * 0.055)
                               for i, f in enumerate([420, 520, 470, 640, 560, 780])],
                             at(osc("sine", 300, 0.35, 900) * env(int(0.35 * SR), 0.05, 0.3, 0, 0.05) * 0.35, 0.3),
                             at(bell(note(88), 0.6, 0.25) * 0.25, 0.42)), 0.25, 1.0, 0.5)
    S["death"] = reverb(mix(arp([64, 60, 57, 52], 0.18, 0.5, "square", 0.25, 0.5, 2500) * 0.6,
                            chord_pad([40, 47, 52], 1.6, 0.05, 0.9, "saw", 900) * 0.8,
                            thump(90, 30, 0.6, 0.25)), 0.35, 1.3, 1.0)
    S["floor"] = reverb(mix(bell(note(72), 0.6, 0.2) * 0.6, at(bell(note(79), 0.8, 0.3) * 0.7, 0.12),
                            at(osc("sine", 120, 0.3, 60) * perc(int(0.3 * SR), 0.003, 0.1) * 0.5, 0.0)), 0.3, 1.0, 0.7)
    S["boss_intro"] = reverb(mix(thump(80, 28, 1.0, 0.4) * 1.3, lp(noise(1.6), 300) * env(int(1.6 * SR), 0.3, 1.0, 0.0, 0.3) * 0.7,
                                 chord_pad([33, 40, 45, 48], 1.6, 0.01, 1.0, "saw", 1400) * 1.2,
                                 at(chord_pad([34, 41, 46], 1.0, 0.01, 0.6, "saw", 1100) * 0.8, 0.6),
                                 at(thump(90, 30, 0.6, 0.2), 0.6)), 0.3, 1.4, 1.2)
    # Loot by rarity (0 = common ... 3 = epic)
    S["loot_0"] = mix(osc("tri", note(79), 0.12) * perc(int(0.12 * SR), 0.001, 0.04))
    S["loot_1"] = reverb(arp([79, 84], 0.06, 0.25, "square", 0.08, 0.25, 4500) * 0.7, 0.15, 0.8, 0.3)
    S["loot_2"] = reverb(arp([76, 81, 88], 0.06, 0.35, "square", 0.1, 0.25, 6000) * 0.7, 0.2, 0.9, 0.4)
    S["loot_3"] = reverb(mix(arp([72, 79, 84, 91], 0.06, 0.4, "square", 0.12, 0.125, 7000) * 0.6,
                             at(bell(note(96), 0.7, 0.25) * 0.25, 0.18)), 0.3, 1.0, 0.6)
    S["loot"] = S["loot_1"]
    S["legendary"] = reverb(mix(arp([72, 76, 79, 84, 88, 91], 0.07, 0.5, "square", 0.15, 0.25, 7000) * 0.5,
                                at(chord_pad([60, 67, 72, 76], 1.3, 0.02, 0.8, "saw", 3500) * 0.6, 0.35),
                                at(bell(note(96), 1.2, 0.4) * 0.3, 0.35), at(bell(note(91), 1.2, 0.4) * 0.25, 0.42)), 0.35, 1.2, 1.0)
    S["unique"] = reverb(mix(arp([60, 64, 67, 72, 76, 79, 84], 0.075, 0.5, "saw", 0.15, 0.5, 5000) * 0.4,
                             at(chord_pad([48, 55, 60, 64, 67], 1.8, 0.03, 1.0, "saw", 3000) * 0.8, 0.5),
                             at(bell(note(84), 1.5, 0.5) * 0.35, 0.5), at(bell(note(88), 1.5, 0.5) * 0.3, 0.58),
                             at(bell(note(91), 1.5, 0.5) * 0.3, 0.66), at(thump(100, 40, 0.5, 0.2), 0.5)), 0.4, 1.4, 1.4)
    S["level_up"] = reverb(mix(arp([67, 71, 74, 79, 83], 0.07, 0.4, "square", 0.12, 0.5, 6000) * 0.5,
                               at(chord_pad([55, 62, 67, 71], 1.0, 0.02, 0.6, "saw", 3500) * 0.6, 0.3),
                               at(bell(note(91), 0.9, 0.3) * 0.3, 0.3)), 0.3, 1.1, 0.8)
    S["spec"] = reverb(mix(chord_pad([50, 57, 62, 66], 2.0, 0.6, 0.8, "saw", 2500) * 0.9,
                           at(arp([74, 78, 81, 86, 90], 0.09, 0.6, "square", 0.2, 0.25, 6000) * 0.45, 0.5),
                           at(bell(note(86), 1.6, 0.6) * 0.35, 0.9), at(thump(90, 35, 0.5, 0.2), 0.9),
                           sweep_filter(noise(1.0), 300, 6000, width=0.5) * np.linspace(0, 1, SR) ** 2 * 0.25), 0.4, 1.5, 1.5)
    # UI
    S["click"] = mix(osc("tri", 1400, 0.02, 900) * perc(int(0.02 * SR), 0.0005, 0.006), snap(0.012, 3000, 9000, 0.003) * 0.3)
    S["equip"] = reverb(mix(bp(noise(0.12), 800, 4000) * perc(int(0.12 * SR), 0.0005, 0.025) * 0.8,
                            osc("sine", 620, 0.25) * perc(int(0.25 * SR), 0.001, 0.06) * 0.4,
                            osc("sine", 1730, 0.25) * perc(int(0.25 * SR), 0.001, 0.04) * 0.3,
                            at(bp(noise(0.08), 1000, 5000) * perc(int(0.08 * SR), 0.0005, 0.015) * 0.5, 0.07)), 0.15, 0.6, 0.25)
    S["buy"] = reverb(mix(coin(note(83), note(88), 0.07, 0.4) * 0.6, at(coin(note(83), note(88), 0.05, 0.3) * 0.3, 0.09)), 0.15, 0.8, 0.3)
    S["sell"] = reverb(mix(*[at(coin(note(n1), note(n2), 0.04, 0.22) * 0.4, i * 0.06) for i, (n1, n2) in enumerate([(79, 84), (81, 86), (83, 88)])]), 0.15, 0.8, 0.3)
    crunch = lp(noise(0.3) * (rng.uniform(0, 1, int(0.3 * SR)) > 0.6), 3000)
    S["salvage"] = mix(crunch * env(int(0.3 * SR), 0.002, 0.28, 0, 0.02) * 0.9, thump(130, 45, 0.18, 0.06), at(bp(noise(0.1), 2000, 6000) * perc(int(0.1 * SR), 0.0005, 0.02) * 0.4, 0.08))
    clang = lambda: mix(bell(1050, 0.4, 0.12, 1.5) * 0.4, snap(0.05, 2000, 9000, 0.01) * 0.8, thump(160, 60, 0.1, 0.03) * 0.6)
    S["craft"] = reverb(mix(clang(), at(clang(), 0.16), at(arp([84, 88, 91], 0.05, 0.3, "sine", 0.12, 0.5, 9000) * 0.35, 0.32)), 0.2, 0.9, 0.5)
    S["error"] = mix(osc("square", 180, 0.09, duty=0.4) * perc(int(0.09 * SR), 0.002, 0.05) * 0.4, at(osc("square", 140, 0.12, duty=0.4) * perc(int(0.12 * SR), 0.002, 0.06) * 0.4, 0.1))
    for name, x in S.items():
        save(name, x, 0.85 if name not in ("click", "tap", "loot_0") else 0.6)
    return list(S)


# ---------------------------------------------------------------- music
SCALES = {"dorian": [0, 2, 3, 5, 7, 9, 10], "minor": [0, 2, 3, 5, 7, 8, 10], "phrygian": [0, 1, 3, 5, 7, 8, 10],
          "harmonic": [0, 2, 3, 5, 7, 8, 11], "lydian": [0, 2, 4, 6, 7, 9, 11], "major": [0, 2, 4, 5, 7, 9, 11]}


def degree(root, scale, d):
    sc = SCALES[scale]
    return root + 12 * (d // 7) + sc[d % 7]


def kick(dur=0.3):
    return thump(140, 40, dur, 0.09) * 1.2


def snare(dur=0.2):
    return mix(bp(noise(dur), 1500, 8000) * perc(int(dur * SR), 0.001, 0.05) * 0.6, osc("tri", 190, dur, 160) * perc(int(dur * SR), 0.001, 0.04) * 0.5)


def hat(dur=0.05, decay=0.012):
    return hp(noise(dur), 7000) * perc(int(dur * SR), 0.0005, decay) * 0.35


def place(buf, x, sec, gain=1.0):
    s = int(sec * SR) % len(buf)
    end = s + len(x)
    if end <= len(buf):
        buf[s:end] += x * gain
    else:  # wrap around so the loop is seamless
        k = len(buf) - s
        buf[s:] += x[:k] * gain
        buf[:end - len(buf)] += x[k:] * gain


def song(cfg):
    bpm, root, scale, prog, bars = cfg["bpm"], cfg["root"], cfg["scale"], cfg["prog"], cfg["bars"]
    beat = 60.0 / bpm
    bar = beat * 4
    total = bar * bars
    buf = np.zeros(int(total * SR))
    layers = {k: np.zeros_like(buf) for k in ("pad", "bass", "lead", "arp", "drums", "fx")}
    lead_rng = np.random.default_rng(cfg.get("seed", 1))
    for b in range(bars):
        d = prog[b % len(prog)]
        t0 = b * bar
        chord = [degree(root, scale, d), degree(root, scale, d + 2), degree(root, scale, d + 4)]
        # Pad
        if cfg.get("pad"):
            pad = chord_pad([m + 12 for m in chord] + [chord[0] + 24], bar + 0.4, 0.4, 0.5, cfg.get("pad_kind", "saw"), cfg.get("pad_cut", 1600), 0.005)
            place(layers["pad"], pad, t0)
        # Bass
        bass_pat = cfg.get("bass", [0, None, None, None])
        steps = len(bass_pat)
        for i, step in enumerate(bass_pat):
            if step is None:
                continue
            m = chord[0] - 12 + step
            dur = bar / steps * 0.95
            x = lp(osc(cfg.get("bass_kind", "tri"), note(m), dur), 900) * env(int(dur * SR), 0.005, dur * 0.6, 0.6, 0.05)
            place(layers["bass"], x, t0 + i * bar / steps)
        # Arpeggio
        if cfg.get("arp"):
            pattern = cfg["arp"]
            n = len(pattern)
            for i, k in enumerate(pattern):
                if k is None:
                    continue
                m = chord[k % 3] + 12 * (1 + k // 3)
                x = pluck(note(m), bar / n * 2.5, cfg.get("arp_decay", 0.15), cfg.get("arp_kind", "square"), 0.25, cfg.get("arp_cut", 3000))
                place(layers["arp"], x, t0 + i * bar / n)
        # Lead: sparse melody from chord tones and scale steps
        if cfg.get("lead"):
            slots = cfg["lead"]
            for i in range(slots):
                if lead_rng.random() < cfg.get("lead_rest", 0.4):
                    continue
                dd = d + lead_rng.choice([0, 2, 4, 7, 1, 5])
                m = degree(root, scale, dd) + 24
                length = bar / slots * lead_rng.choice([1, 1, 2])
                kind = cfg.get("lead_kind", "bell")
                x = bell(note(m), length + 0.6, length * 0.6, 0.6) if kind == "bell" else \
                    lp(osc(kind, note(m), length, duty=0.25), 3000) * env(int(length * SR), 0.01, length * 0.5, 0.5, 0.1)
                place(layers["lead"], x, t0 + i * bar / slots)
        # Drums
        drums = cfg.get("drums")
        if drums:
            for i, ch in enumerate(drums):
                pos = t0 + i * bar / len(drums)
                if ch in "kK":
                    place(layers["drums"], kick(), pos, 1.0 if ch == "K" else 0.6)
                if ch in "sS":
                    place(layers["drums"], snare(), pos, 0.8 if ch == "S" else 0.4)
                if ch in "h":
                    place(layers["drums"], hat(), pos)
                if ch == "o":
                    place(layers["drums"], hat(0.15, 0.06), pos)
    # Ambience
    if cfg.get("wind"):
        w = sweep_filter(noise(total), 300, 900, width=0.7, steps=120)
        w *= 0.6 + 0.4 * np.sin(2 * np.pi * np.arange(len(w)) / len(w) * 2)
        layers["fx"] += w * cfg["wind"]
    if cfg.get("drip"):
        for i in range(int(total * cfg["drip"])):
            f = rng.uniform(1200, 2400)
            x = osc("sine", f, 0.08, f * 1.8, curve=0.4) * perc(int(0.08 * SR), 0.001, 0.02)
            place(layers["fx"], x, rng.uniform(0, total), 0.3)
    if cfg.get("crackle"):
        for i in range(int(total * cfg["crackle"])):
            x = bp(noise(0.02), 1500, 6000) * perc(int(0.02 * SR), 0.0005, 0.004)
            place(layers["fx"], x, rng.uniform(0, total), rng.uniform(0.1, 0.4))
    gains = cfg.get("gains", {})
    for k, v in layers.items():
        g = gains.get(k, {"pad": 0.35, "bass": 0.5, "lead": 0.3, "arp": 0.22, "drums": 0.5, "fx": 0.15}[k])
        buf += v * g
    # Reverb with the tail wrapped to the start so the loop is seamless
    wet = reverb(buf, cfg.get("verb", 0.3), 1.3, 2.0, 3500)
    tail = wet[len(buf):]
    wet = wet[:len(buf)]
    wet[:len(tail)] += tail
    return wet


MUSIC = {
    # Mossy Hollows - calm forest, gentle plucks
    "zone_0": {"bpm": 92, "root": 50, "scale": "dorian", "prog": [0, 3, 5, 4], "bars": 8, "pad": True, "pad_cut": 1300,
               "bass": [0, None, 7, None], "arp": [0, 1, 2, 1, 3, 2, 1, 2], "arp_kind": "tri", "arp_cut": 2500,
               "lead": 4, "lead_kind": "bell", "drums": "K.h.s.h.K.hKs.h.", "wind": 0.6, "seed": 3,
               "gains": {"drums": 0.25, "lead": 0.22}},
    # Sunken Catacombs - slow, eerie, dripping
    "zone_1": {"bpm": 70, "root": 45, "scale": "phrygian", "prog": [0, 1, 0, 5], "bars": 8, "pad": True, "pad_kind": "tri", "pad_cut": 900,
               "bass": [0, None, None, None, 0, None, 1, None], "lead": 4, "lead_kind": "bell", "lead_rest": 0.55,
               "drip": 0.7, "wind": 0.5, "verb": 0.45, "seed": 9, "gains": {"pad": 0.5, "lead": 0.25}},
    # Charybdis' sea - swaying, watery arpeggios
    "zone_2": {"bpm": 84, "root": 47, "scale": "minor", "prog": [0, 5, 3, 6], "bars": 8, "pad": True, "pad_cut": 1500,
               "bass": [0, None, None, 4, None, None, 7, None], "arp": [0, 2, 4, 2, 1, 3, 5, 3, 0, 2, 4, 2, 1, 3, 5, 3],
               "arp_kind": "sine", "arp_decay": 0.25, "arp_cut": 5000, "lead": 2, "lead_kind": "tri", "wind": 0.9,
               "drums": "K...o...K.K.o...", "seed": 5, "gains": {"drums": 0.25, "arp": 0.25}},
    # Surtr's fire - driving, harmonic minor, crackling
    "zone_3": {"bpm": 112, "root": 43, "scale": "harmonic", "prog": [0, 0, 5, 4], "bars": 8, "pad": True, "pad_cut": 1800,
               "bass": [0, 0, 12, 0, 0, 7, 0, 12], "bass_kind": "saw", "arp": [0, 1, 2, 3, 2, 1, 0, None], "arp_cut": 2600,
               "lead": 8, "lead_kind": "square", "lead_rest": 0.5, "drums": "K.h.S.hhK.K.S.ho", "crackle": 25, "seed": 2,
               "gains": {"bass": 0.45, "drums": 0.45, "lead": 0.18}},
    # Typhon's storm - big, dramatic, lydian
    "zone_4": {"bpm": 100, "root": 48, "scale": "lydian", "prog": [0, 1, 5, 4], "bars": 8, "pad": True, "pad_cut": 2200,
               "bass": [0, None, 0, 7, None, 0, 12, None], "bass_kind": "saw", "arp": [0, 2, 1, 3, 2, 4, 3, 5, 4, 3, 2, 1, 0, 1, 2, 3],
               "arp_kind": "square", "arp_cut": 4000, "lead": 4, "lead_kind": "bell", "drums": "K.hhS.h.KKhhS.ho",
               "wind": 1.2, "seed": 4, "gains": {"drums": 0.45, "arp": 0.18}},
    # The Hushwood - hushed, mournful, music-box bells over mist
    "zone_5": {"bpm": 66, "root": 52, "scale": "minor", "prog": [0, 5, 3, 4], "bars": 8, "pad": True, "pad_kind": "tri", "pad_cut": 1100,
               "bass": [0, None, None, None, None, None, 5, None], "arp": [4, 2, 0, 2, 4, 5, 4, 2], "arp_kind": "sine", "arp_decay": 0.4,
               "arp_cut": 3000, "lead": 2, "lead_kind": "bell", "lead_rest": 0.6, "wind": 0.8, "verb": 0.5, "seed": 31,
               "gains": {"pad": 0.5, "arp": 0.2, "lead": 0.22}},
    # The Glimmer Court - playful, twinkling, a little wrong
    "zone_6": {"bpm": 118, "root": 57, "scale": "lydian", "prog": [0, 1, 0, 4], "bars": 8, "pad": True, "pad_cut": 2600,
               "bass": [0, None, 7, None, 0, None, 11, None], "arp": [0, 2, 4, 6, 4, 2, 7, 4, 0, 4, 2, 6, 4, 7, 6, 4],
               "arp_kind": "square", "arp_cut": 6000, "arp_decay": 0.12, "lead": 4, "lead_kind": "bell", "lead_rest": 0.4,
               "drums": "K.h.s.hhK.h.s.h.", "seed": 33, "gains": {"drums": 0.22, "arp": 0.16, "lead": 0.2}},
    # The Ironroot Deeps - marching, anvil-heavy, low
    "zone_7": {"bpm": 96, "root": 38, "scale": "dorian", "prog": [0, 0, 6, 0, 3, 3, 4, 4], "bars": 8, "pad": True, "pad_cut": 1200,
               "bass": [0, None, 0, 0, None, 0, 7, None], "bass_kind": "saw", "arp": [0, None, 4, None, 7, None, 4, None],
               "arp_kind": "tri", "arp_cut": 2000, "lead": 8, "lead_kind": "square", "lead_rest": 0.5,
               "drums": "K..sK.o.K..sKKo.", "crackle": 12, "seed": 35, "gains": {"bass": 0.5, "drums": 0.55, "lead": 0.16}},
    # The Gilded Spire - bright, choral, hopeful but cold
    "zone_8": {"bpm": 80, "root": 55, "scale": "major", "prog": [0, 4, 5, 3], "bars": 8, "pad": True, "pad_cut": 3200,
               "bass": [0, None, None, None, 4, None, None, None], "arp": [0, 2, 4, 7, 4, 2], "arp_kind": "sine", "arp_decay": 0.35,
               "arp_cut": 7000, "lead": 2, "lead_kind": "bell", "lead_rest": 0.35, "verb": 0.55, "wind": 0.4, "seed": 37,
               "gains": {"pad": 0.6, "arp": 0.2, "lead": 0.24}},
    # The Cinder Abyss - heavy, harmonic minor, hellish drums
    "zone_9": {"bpm": 124, "root": 41, "scale": "harmonic", "prog": [0, 1, 0, 6, 0, 1, 4, 4], "bars": 8, "pad": True, "pad_cut": 1400,
               "bass": [0, 0, 1, 0, 0, 12, 0, 1], "bass_kind": "saw", "arp": [0, 3, 1, 3, 4, 3, 1, 3], "arp_kind": "saw", "arp_cut": 2400,
               "lead": 4, "lead_kind": "saw", "lead_rest": 0.4, "drums": "K.hKS.hhK.KhS.SK", "crackle": 30, "seed": 39,
               "gains": {"bass": 0.55, "drums": 0.55, "lead": 0.17, "arp": 0.16}},
    # Boss - fast, heavy, menacing
    "boss": {"bpm": 140, "root": 40, "scale": "phrygian", "prog": [0, 0, 1, 0, 5, 5, 1, 6], "bars": 8, "pad": True, "pad_cut": 1500,
             "bass": [0, 0, 12, 0, 0, 1, 0, 12, 0, 0, 12, 0, 7, 0, 6, 0], "bass_kind": "saw",
             "arp": [0, 3, 1, 3, 2, 3, 1, 3], "arp_kind": "square", "arp_cut": 3000, "lead": 4, "lead_kind": "saw", "lead_rest": 0.3,
             "drums": "K.hhS.hhK.KhS.Sh", "seed": 13, "verb": 0.2, "gains": {"bass": 0.55, "drums": 0.6, "lead": 0.2, "pad": 0.3}},
}


def make_sfx_v2():
    """Sounds added in the Foundation update. Made after everything else (with
    their own random seed) so the older sounds come out exactly the same."""
    global rng
    rng = np.random.default_rng(77)
    S = {}
    # An Epic-or-better monster shows up: low swell + warning bells
    S["rare_spawn"] = reverb(mix(chord_pad([38, 45, 50], 1.1, 0.25, 0.6, "saw", 900) * 0.8,
                                 at(bell(note(74), 0.8, 0.3) * 0.35, 0.25), at(bell(note(73), 0.9, 0.35) * 0.35, 0.45),
                                 thump(70, 30, 0.6, 0.25)), 0.35, 1.2, 0.9)
    # A Signature item: the biggest fanfare in the game
    S["signature"] = reverb(mix(arp([60, 64, 67, 71, 72, 76, 79, 83, 84], 0.065, 0.6, "saw", 0.18, 0.5, 6000) * 0.4,
                                at(chord_pad([48, 55, 60, 64, 71], 2.4, 0.03, 1.4, "saw", 3200) * 0.85, 0.55),
                                *[at(bell(note(n), 1.8, 0.6) * 0.3, 0.55 + i * 0.07) for i, n in enumerate([84, 88, 91, 95])],
                                at(thump(90, 35, 0.7, 0.3) * 1.2, 0.55),
                                at(sweep_filter(noise(1.2), 400, 9000, width=0.4) * np.linspace(1, 0, int(1.2 * SR)) * 0.25, 0.55)), 0.45, 1.6, 1.8)
    # Achievement: short bright jingle
    S["achievement"] = reverb(mix(arp([76, 79, 84, 88], 0.08, 0.35, "square", 0.12, 0.25, 7000) * 0.5,
                                  at(bell(note(91), 0.8, 0.3) * 0.35, 0.3)), 0.3, 1.0, 0.6)
    # A dungeon event starts
    S["event"] = reverb(mix(arp([67, 74, 67, 74], 0.07, 0.25, "square", 0.08, 0.5, 4000) * 0.45,
                            at(osc("tri", 300, 0.3, 600) * env(int(0.3 * SR), 0.02, 0.25, 0, 0.05) * 0.3, 0.1)), 0.25, 0.9, 0.5)
    # Guide book page turn
    S["page"] = mix(bp(noise(0.22), 1500, 7000) * env(int(0.22 * SR), 0.03, 0.18, 0, 0.03) * 0.5,
                    at(bp(noise(0.06), 3000, 9000) * perc(int(0.06 * SR), 0.0005, 0.015) * 0.4, 0.16))
    for name, x in S.items():
        save(name, x, 0.6 if name == "page" else 0.85)
    return list(S)


MENU_MUSIC = {"bpm": 76, "root": 50, "scale": "dorian", "prog": [0, 5, 3, 4, 0, 5, 6, 4], "bars": 8, "pad": True, "pad_cut": 1600,
              "bass": [0, None, None, None, 7, None, None, None], "arp": [0, 2, 4, 2, 1, 3, 5, 3], "arp_kind": "sine",
              "arp_decay": 0.3, "arp_cut": 3500, "lead": 2, "lead_kind": "bell", "lead_rest": 0.45, "wind": 0.5,
              "verb": 0.4, "seed": 21, "gains": {"pad": 0.55, "arp": 0.22, "lead": 0.2}}


def make_sfx_v3():
    """Sounds for realms, races and hidden classes (own seed, so older sounds don't change)."""
    global rng
    rng = np.random.default_rng(91)
    S = {}
    # Awakening: rising choir and a big shimmer
    S["awaken"] = reverb(mix(chord_pad([48, 55, 60, 64], 1.8, 0.4, 1.0, "saw", 2400) * 0.7,
                             arp([60, 64, 67, 72, 76, 79, 84], 0.09, 0.5, "tri", 0.15, 0.5, 6000) * 0.35,
                             at(bell(note(84), 1.4, 0.5) * 0.3, 0.7), at(thump(80, 32, 0.6, 0.3), 0.7)), 0.5, 1.6, 1.6)
    # Transformation: a dark, wrong-sounding swell
    S["transform"] = reverb(mix(chord_pad([36, 37, 43], 1.6, 0.6, 0.8, "saw", 700) * 0.9,
                                at(bell(note(61), 1.0, 0.4) * 0.3, 0.5), at(bell(note(60), 1.2, 0.4) * 0.3, 0.8),
                                at(thump(55, 25, 0.8, 0.4) * 1.2, 0.2)), 0.45, 1.4, 1.4)
    # Hidden class: silence, then a deep gong and bells
    S["hidden"] = reverb(mix(at(thump(45, 20, 1.2, 0.6) * 1.3, 0.2),
                             at(chord_pad([43, 50, 55, 62], 2.0, 0.05, 1.6, "tri", 1800) * 0.8, 0.25),
                             *[at(bell(note(n), 1.6, 0.6) * 0.28, 0.5 + i * 0.12) for i, n in enumerate([74, 79, 83, 86])]), 0.5, 1.8, 2.0)
    # Escape: quick footsteps whoosh
    S["escape"] = mix(sweep_filter(noise(0.35), 3000, 600, width=0.5) * env(int(0.35 * SR), 0.01, 0.3, 0, 0.04) * 0.5,
                      *[at(bp(noise(0.04), 200, 900) * perc(int(0.04 * SR), 0.001, 0.02) * 0.6, i * 0.07) for i in range(4)])
    # A portal opens
    S["portal"] = reverb(mix(sweep_filter(noise(1.0), 300, 5000, width=0.3) * env(int(1.0 * SR), 0.4, 0.5, 0, 0.1) * 0.3,
                             chord_pad([50, 57, 62, 69], 1.2, 0.5, 0.6, "sine", 3000) * 0.6), 0.45, 1.4, 1.0)
    for name, x in S.items():
        save(name, x, 0.85)
    return list(S)


if __name__ == "__main__":
    import sys
    os.makedirs(OUT, exist_ok=True)
    if "--realms" in sys.argv:
        for name in ("zone_5", "zone_6", "zone_7", "zone_8", "zone_9"):
            x = song(MUSIC[name])
            save("music_" + name, x, 0.8, rate=32000, loop=True)
            print(name, "%.1fs" % (len(x) / SR))
        print("realm sfx:", make_sfx_v3())
        sys.exit(0)
    if "--new" not in sys.argv:
        names = make_sfx()
        print("sfx:", len(names))
        for name, cfg in MUSIC.items():
            x = song(cfg)
            save("music_" + name, x, 0.8, rate=32000, loop=True)
            print(name, "%.1fs" % (len(x) / SR))
    print("new sfx:", make_sfx_v2())
    x = song(MENU_MUSIC)
    save("music_menu", x, 0.8, rate=32000, loop=True)
    print("menu %.1fs" % (len(x) / SR))
