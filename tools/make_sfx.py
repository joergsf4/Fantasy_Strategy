#!/usr/bin/env python3
"""Erzeugt die Soundeffekte per Klangsynthese (numpy/scipy) nach game/assets/sfx/<name>_<n>.wav.

Aufruf: python3 tools/make_sfx.py [Teil-Name]
Jeder Klang entsteht in mehreren Varianten (anderer Zufallswert), das Spiel waehlt zufaellig und verstimmt leicht.
Alles ist deterministisch (feste Seeds), also reproduzierbar.
"""
import sys
from pathlib import Path

import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100
OUT = Path(__file__).resolve().parent.parent / "game" / "assets" / "sfx"


# ---------------------------------------------------------------- Bausteine
class Sig(np.ndarray):
    """Signal: Addition zweier unterschiedlich langer Signale haengt das kuerzere hinten mit Stille auf."""

    def __add__(self, o):
        return _padded(self, o, np.add)

    __radd__ = __add__

    def __sub__(self, o):
        return _padded(self, o, np.subtract)


def _padded(a, b, op):
    a = np.asarray(a)
    b = np.asarray(b)
    if a.ndim == 0 or b.ndim == 0 or len(a) == len(b):
        return op(a, b).view(Sig)
    n = max(len(a), len(b))
    return op(np.pad(a, (0, n - len(a))), np.pad(b, (0, n - len(b)))).view(Sig)


def S(x):
    return np.asarray(x, dtype=np.float64).view(Sig)


def t_(dur: float) -> np.ndarray:
    return np.arange(int(SR * dur)) / SR


def noise(rng, n):
    return S(rng.uniform(-1, 1, n))


def filt(x, kind, freq, order=2):
    sos = signal.butter(order, freq, btype=kind, fs=SR, output="sos")
    return S(signal.sosfilt(sos, x))


def modal(rng, freqs, decays, amps, dur, detune=0.015):
    """Gedaempfte Schwingungen (Metall/Holz): Obertoene mit eigener Abklingzeit."""
    t = t_(dur)
    out = np.zeros_like(t)
    for f, d, a in zip(freqs, decays, amps):
        f2 = f * (1 + rng.uniform(-detune, detune))
        out += a * np.sin(2 * np.pi * f2 * t + rng.uniform(0, 6.28)) * np.exp(-t / d)
    return S(out)


def thump(f0, f1, dur, decay):
    """Sinus mit fallender Tonhoehe: dumpfer Schlag."""
    t = t_(dur)
    f = f1 + (f0 - f1) * np.exp(-t / (decay * 0.5))
    ph = 2 * np.pi * np.cumsum(f) / SR
    return S(np.sin(ph) * np.exp(-t / decay))


def click(rng, dur=0.012, cutoff=6000):
    n = int(SR * dur)
    return S(filt(noise(rng, n), "high", cutoff) * np.exp(-np.arange(n) / (SR * dur * 0.3)))


def dec(dur, tau):
    return S(np.exp(-t_(dur) / tau))


def mix(*parts):
    n = max(len(p[0]) + int(p[1] * SR) for p in parts)
    out = np.zeros(n)
    for x, off, gain in parts:
        i = int(off * SR)
        out[i:i + len(x)] += x * gain
    return S(out)


def sweep_noise(rng, dur, f_from, f_to, peak=0.4, q=1.2):
    """Rauschen mit wanderndem Bandpass (Wusch), schnell hoch, langsam runter."""
    n = int(SR * dur)
    x = noise(rng, n)
    out = np.zeros(n)
    steps = 12
    for i in range(steps):
        a, b = i * n // steps, (i + 1) * n // steps
        f = f_from * (f_to / f_from) ** (i / (steps - 1))
        lo, hi = f / (1 + 1 / q), min(f * (1 + 1 / q), SR * 0.45)
        sos = signal.butter(2, [lo, hi], btype="band", fs=SR, output="sos")
        out[a:b] = signal.sosfilt(sos, x)[a:b]
    t = np.arange(n) / SR
    e = np.where(t < dur * peak, t / (dur * peak), np.exp(-(t - dur * peak) / (dur * 0.3)))
    return S(out * e)


def tone(freq, dur, wave="sine", vib=0.0, vib_rate=6.0, f_end=None):
    t = t_(dur)
    f = np.full_like(t, freq) if f_end is None else freq * (f_end / freq) ** (t / dur)
    if vib:
        f = f * (1 + vib * np.sin(2 * np.pi * vib_rate * t))
    ph = 2 * np.pi * np.cumsum(f) / SR
    if wave == "saw":
        return S(2 * ((ph / (2 * np.pi)) % 1) - 1)
    if wave == "square":
        return S(np.sign(np.sin(ph)))
    return S(np.sin(ph))


def fade(x, a=0.002, r=0.01):
    n = len(x)
    e = np.ones(n)
    na, nr = int(SR * a), int(SR * r)
    e[:na] = np.linspace(0, 1, na)
    e[-nr:] = np.linspace(1, 0, nr)
    return S(x * e)


def band(rng, dur, lo, hi, tau):
    n = int(SR * dur)
    return S(filt(noise(rng, n), "band", [lo, hi]) * np.exp(-np.arange(n) / (SR * tau)))


# ---------------------------------------------------------------- Klaenge
# Waffenschicht (womit zugeschlagen wird)
def w_wood(rng):
    return modal(rng, [310, 690, 1180, 1900], [0.05, 0.035, 0.025, 0.015], [1, 0.7, 0.4, 0.2], 0.22) + 0.5 * click(rng, 0.01, 3000)


def w_metal(rng):
    return modal(rng, [1650, 2520, 3880, 5340, 7300], [0.22, 0.18, 0.12, 0.09, 0.05], [1, 0.8, 0.6, 0.35, 0.2], 0.45) + 0.8 * click(rng, 0.012, 5000)


def w_fist(rng):
    n = int(SR * 0.05)
    return thump(115, 48, 0.2, 0.07) + 0.4 * filt(noise(rng, n), "low", 900) * np.exp(-np.arange(n) / (SR * 0.015))


# Zielschicht (was getroffen wird)
def t_armor(rng):
    return modal(rng, [480, 1090, 1730, 2480, 3300], [0.16, 0.12, 0.09, 0.07, 0.04], [1, 0.8, 0.55, 0.4, 0.25], 0.4) + 0.5 * click(rng, 0.01, 4000)


def t_wood(rng):
    return modal(rng, [170, 390, 720, 1150], [0.07, 0.05, 0.035, 0.02], [1, 0.8, 0.45, 0.25], 0.22) + 0.3 * click(rng, 0.008, 2000)


def t_flesh(rng):
    return band(rng, 0.12, 500, 3200, 0.025) * 1.1 + 0.9 * thump(150, 70, 0.14, 0.04)


def t_face(rng):
    """Faust auf Gesicht: kurzes Klatschen mit knackigem Hoehenanteil und Nachsacken."""
    smack = band(rng, 0.16, 900, 4500, 0.02)
    crack = 0.5 * modal(rng, [2100, 3100], [0.015, 0.01], [1, 0.7], 0.08)
    return mix((smack * 1.2, 0, 1), (crack, 0, 1), (thump(190, 80, 0.16, 0.05), 0, 1))


def t_stone(rng):
    return band(rng, 0.25, 200, 1800, 0.05) + 0.8 * thump(100, 60, 0.25, 0.08)


def crit(rng):
    return mix((modal(rng, [2400, 3600, 5200], [0.2, 0.15, 0.1], [1, 0.7, 0.5], 0.5), 0, 0.6), (thump(90, 40, 0.3, 0.12), 0, 1.0), (click(rng, 0.01, 6000), 0, 0.5))


def block(rng):
    return mix((t_wood(rng), 0, 1.0), (modal(rng, [2800, 4200], [0.1, 0.06], [0.6, 0.4], 0.2), 0.0, 0.7))


def whoosh_s(rng):
    return sweep_noise(rng, 0.2, 700, 2800, peak=0.45)


def whoosh_l(rng):
    return sweep_noise(rng, 0.32, 400, 2400, peak=0.5, q=0.9)


# Fernkampf
def bow_shot(rng):
    t = t_(0.35)
    string = np.sin(2 * np.pi * (180 + rng.uniform(-10, 10)) * t * (1 + 0.15 * np.exp(-t / 0.03))) * np.exp(-t / 0.07)
    return mix((string * 0.9, 0, 1), (sweep_noise(rng, 0.15, 1500, 4500, 0.3), 0.01, 0.35))


def arrow_hit(rng):
    return mix((band(rng, 0.07, 1500, 6000, 0.015), 0, 0.8), (thump(220, 90, 0.14, 0.04), 0.0, 0.9))


def shuriken_throw(rng):
    return sweep_noise(rng, 0.26, 2500, 7000, 0.35, q=1.5)


def shuriken_hit(rng):
    return modal(rng, [3200, 4700, 6100], [0.08, 0.06, 0.04], [1, 0.7, 0.5], 0.2) + click(rng, 0.008, 6000)


def zap(rng):
    n = int(SR * 0.2)
    return fade(tone(1800, 0.2, "square", f_end=300) * dec(0.2, 0.08) * 0.5 + 0.3 * filt(noise(rng, n), "high", 3000) * dec(0.2, 0.05))


def cannon(rng):
    n = int(SR * 0.7)
    return fade(thump(120, 30, 0.7, 0.2) + 0.8 * filt(noise(rng, n), "low", 1400) * dec(0.7, 0.12), 0.001, 0.05)


def rocket_launch(rng):
    return mix((sweep_noise(rng, 0.7, 500, 3500, 0.7, q=0.7), 0, 0.8), (thump(150, 50, 0.3, 0.1), 0, 0.7))


def explosion(rng):
    n = int(SR * 1.1)
    rumble = filt(noise(rng, n), "low", 700, 3) * dec(1.1, 0.28)
    crack = filt(noise(rng, int(SR * 0.15)), "high", 800) * dec(0.15, 0.03)
    return fade(mix((rumble * 1.4, 0, 1), (thump(95, 28, 1.0, 0.25), 0, 1.1), (crack, 0, 0.25)), 0.001, 0.08)


def chomp(rng):
    def clack():
        return modal(rng, [900, 1500, 2300], [0.03, 0.02, 0.012], [1, 0.8, 0.4], 0.1) + 0.6 * click(rng, 0.008, 3500)
    return mix((clack(), 0, 1), (clack(), 0.09, 0.8), (clack(), 0.17, 1.0))


# Faehigkeiten
def heal(rng):
    parts = []
    for i, f in enumerate([660, 830, 990, 1320]):
        s = (tone(f, 0.35) * 0.6 + tone(f * 2, 0.35) * 0.2) * dec(0.35, 0.12)
        parts.append((s, i * 0.07, 0.6))
    return mix(*parts)


def buff(rng):
    s = tone(330, 0.5, f_end=880) * dec(0.5, 0.3) * 0.5 + tone(660, 0.5, f_end=1760) * dec(0.5, 0.25) * 0.25
    return fade(s + 0.2 * sweep_noise(rng, 0.5, 2000, 6000, 0.6))


def debuff(rng):
    return fade(tone(520, 0.5, "saw", f_end=140) * dec(0.5, 0.25) * 0.3 + 0.2 * tone(260, 0.5, f_end=70))


def taunt(rng):
    t = t_(0.55)
    horn = filt(tone(196, 0.55, "saw", vib=0.01), "low", 1100) * np.where(t < 0.1, t / 0.1, 1) * np.exp(-np.maximum(t - 0.3, 0) / 0.1)
    return fade(horn * 0.6 + 0.4 * filt(tone(294, 0.55, "saw"), "low", 900) * np.exp(-t / 0.4))


def scared(rng):
    t = t_(0.9)
    shimmer = 0.06 * filt(noise(rng, len(t)), "high", 5000) * np.sin(np.pi * t / 0.9) ** 2
    return fade((tone(110, 0.9, f_end=82) * 0.5 + shimmer) * np.exp(-t / 0.7), 0.01, 0.1)


def laser_charge(rng):
    return fade(tone(220, 0.6, "saw", f_end=1600) * 0.22 * np.linspace(0.2, 1, int(SR * 0.6)) + 0.15 * tone(440, 0.6, f_end=3200), 0.01, 0.03)


def laser_fire(rng):
    n = int(SR * 0.5)
    return fade(mix((filt(noise(rng, n), "band", [1500, 7000]) * dec(0.5, 0.2) * 0.5, 0, 1), (tone(1400, 0.5, "saw", f_end=200) * 0.3 * dec(0.5, 0.15), 0, 1)))


def fire_whoosh(rng):
    return sweep_noise(rng, 0.7, 300, 1800, 0.35, q=0.6) * 0.9 + 0.3 * filt(noise(rng, int(SR * 0.7)), "low", 600) * dec(0.7, 0.3)


def splash(rng):
    bub = tone(rng.uniform(500, 1500), 0.08, f_end=rng.uniform(1500, 2500)) * dec(0.08, 0.03) * 0.3
    return mix((band(rng, 0.5, 600, 5000, 0.1), 0, 0.8), (bub, 0.08, 0.7), (bub, 0.16, 0.5))


def poof(rng):
    n = int(SR * 0.4)
    return fade(filt(noise(rng, n), "low", 1800) * dec(0.4, 0.09) * 0.9 + 0.5 * thump(130, 60, 0.4, 0.07))


def boing(rng):
    return fade(tone(220, 0.4, vib=0.06, vib_rate=14, f_end=520) * dec(0.4, 0.2) * 0.5)


def quack(rng):
    t = t_(0.28)
    x = tone(400, 0.28, "saw", f_end=280) * (0.5 + 0.5 * np.sin(2 * np.pi * 60 * t))
    return fade(filt(x, "band", [500, 2500]) * np.exp(-t / 0.15) * 0.8)


def ribbit(rng):
    t = t_(0.3)
    x = tone(130, 0.3, "saw") * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 28 * t)))
    return fade(filt(x, "band", [200, 900]) * np.exp(-t / 0.2))


def flee_zip(rng):
    return fade(tone(300, 0.35, "saw", f_end=2400) * 0.15 * dec(0.35, 0.2) + sweep_noise(rng, 0.35, 800, 4000, 0.3))


def wave(rng):
    return fade(tone(500, 0.6, f_end=140) * 0.4 * dec(0.6, 0.3) + 0.2 * sweep_noise(rng, 0.6, 3000, 800, 0.2))


def defend(rng):
    return fade(mix((t_wood(rng), 0, 0.8), (modal(rng, [800, 1200], [0.25, 0.2], [0.5, 0.3], 0.4), 0.0, 0.6)))


# Welt
def wall_break(rng):
    n = int(SR * 1.2)
    rocks = np.zeros(n)
    for _ in range(14):
        s = int(rng.uniform(0, 0.8) * SR)
        c = band(rng, 0.08, rng.uniform(200, 600), rng.uniform(1500, 3500), 0.02)
        rocks[s:s + len(c)] += c[: n - s] * rng.uniform(0.3, 1.0)
    return fade(mix((thump(90, 30, 0.7, 0.18), 0, 1.0), (filt(noise(rng, n), "low", 500) * dec(1.2, 0.3) * 0.7, 0, 1), (rocks, 0, 0.9)), 0.001, 0.1)


def gate_open(rng):
    t = t_(0.9)
    creak = filt(tone(95, 0.9, "saw", vib=0.06, vib_rate=9, f_end=140), "band", [150, 900]) * np.sin(np.pi * t / 0.9) ** 0.7
    return fade(mix((creak * 0.7, 0, 1), (thump(80, 40, 0.3, 0.1), 0.65, 1.1)), 0.02, 0.08)


def switch(rng):
    return mix((modal(rng, [1400, 2200], [0.03, 0.02], [1, 0.6], 0.1), 0, 0.8), (thump(110, 60, 0.18, 0.05), 0.09, 1.0))


def chest_open(rng):
    t = t_(0.45)
    creak = filt(tone(320, 0.45, "saw", vib=0.04, vib_rate=11, f_end=520), "band", [250, 1400]) * np.sin(np.pi * t / 0.45)
    g1 = tone(2093, 0.25) * dec(0.25, 0.08) * 0.25
    g2 = tone(2637, 0.25) * dec(0.25, 0.08) * 0.25
    return fade(mix((creak * 0.5, 0, 1), (thump(100, 55, 0.2, 0.06), 0.4, 0.9), (g1, 0.45, 1), (g2, 0.52, 1)))


def coin(rng):
    return mix((tone(1568, 0.15) * dec(0.15, 0.05) * 0.5, 0, 1), (tone(2093, 0.4) * dec(0.4, 0.14) * 0.5, 0.07, 1))


def extinguish(rng):
    return fade(filt(noise(rng, int(SR * 0.8)), "high", 2500) * dec(0.8, 0.3) * 0.6)


def rope(rng):
    return mix((click(rng, 0.02, 1500), 0, 0.8), (sweep_noise(rng, 0.2, 400, 1500, 0.2), 0.03, 0.5))


def baby(rng):
    t = t_(0.5)
    x = tone(520, 0.5, "saw", vib=0.04, vib_rate=7, f_end=410) * np.sin(np.pi * np.clip(t / 0.5, 0, 1)) ** 0.6
    return fade(filt(x, "band", [400, 2800]) * 0.5)


def death(rng):
    return mix((poof(rng), 0, 1), (tone(380, 0.35, f_end=140) * dec(0.35, 0.15) * 0.18, 0, 1))


def fire_loop(rng):
    n = int(SR * 1.2)
    x = filt(noise(rng, n), "band", [200, 3000]) * 0.15
    for _ in range(40):
        s = int(rng.uniform(0, 1.1) * SR)
        c = click(rng, 0.01, 2500) * rng.uniform(0.2, 0.7)
        x[s:s + len(c)] += c[: n - s]
    return x


# Oberflaeche
def ui_click(rng):
    return modal(rng, [1200, 1800], [0.03, 0.02], [1, 0.4], 0.08)


def ui_hover(rng):
    return modal(rng, [2000], [0.015], [0.6], 0.04)


def ui_back(rng):
    return tone(520, 0.1, f_end=330) * dec(0.1, 0.05) * 0.5


def dialog_tick(rng):
    return modal(rng, [1700, 2600], [0.012, 0.008], [1, 0.5], 0.04) * 0.6


def turn_start(rng):
    return modal(rng, [196, 392, 588, 880], [0.9, 0.6, 0.4, 0.25], [1, 0.6, 0.3, 0.15], 1.2, 0.005) * 0.6 + 0.3 * np.pad(click(rng, 0.008, 1500), (0, int(SR * 1.2) - int(SR * 0.008)))


def victory(rng):
    parts = []
    for i, f in enumerate([523, 659, 784, 1047]):
        parts.append(((tone(f, 0.6) * 0.5 + tone(f * 2, 0.6) * 0.15) * dec(0.6, 0.3), i * 0.14, 0.7))
    parts.append(((tone(523, 1.0) + tone(659, 1.0) + tone(784, 1.0)) * dec(1.0, 0.5) * 0.18, 0.5, 1))
    return mix(*parts)


def defeat(rng):
    parts = []
    for i, f in enumerate([392, 349, 311, 262]):
        parts.append((tone(f, 0.7, "saw") * 0.18 * dec(0.7, 0.35), i * 0.2, 1))
    return filt(mix(*parts), "low", 1800)


def item_use(rng):
    parts = []
    for i in range(3):
        parts.append((tone(rng.uniform(250, 400), 0.1, f_end=rng.uniform(600, 900)) * dec(0.1, 0.04) * 0.5, i * 0.11, 1))
    return mix(*parts)


def pickup(rng):
    return mix((tone(880, 0.1) * dec(0.1, 0.04) * 0.5, 0, 1), (tone(1320, 0.2) * dec(0.2, 0.08) * 0.5, 0.07, 1))


# name -> (Funktion, Varianten, Zielpegel in dBFS)
SOUNDS = {
    "w_wood": (w_wood, 3, -6), "w_metal": (w_metal, 3, -8), "w_fist": (w_fist, 3, -4),
    "t_armor": (t_armor, 3, -6), "t_wood": (t_wood, 3, -6), "t_flesh": (t_flesh, 3, -5), "t_face": (t_face, 3, -5), "t_stone": (t_stone, 2, -6),
    "crit": (crit, 2, -5), "block": (block, 2, -6), "whoosh_s": (whoosh_s, 3, -10), "whoosh_l": (whoosh_l, 3, -10),
    "bow_shot": (bow_shot, 2, -8), "arrow_hit": (arrow_hit, 3, -7), "shuriken_throw": (shuriken_throw, 2, -10), "shuriken_hit": (shuriken_hit, 2, -8),
    "zap": (zap, 2, -9), "cannon": (cannon, 2, -4), "rocket_launch": (rocket_launch, 2, -6), "explosion": (explosion, 2, -3), "chomp": (chomp, 2, -6),
    "heal": (heal, 1, -9), "buff": (buff, 1, -10), "debuff": (debuff, 1, -10), "taunt": (taunt, 1, -8), "scared": (scared, 1, -10),
    "laser_charge": (laser_charge, 1, -10), "laser_fire": (laser_fire, 1, -7), "fire_whoosh": (fire_whoosh, 2, -8), "splash": (splash, 2, -8),
    "poof": (poof, 2, -7), "boing": (boing, 1, -9), "quack": (quack, 2, -8), "ribbit": (ribbit, 2, -8), "flee_zip": (flee_zip, 1, -9),
    "wave": (wave, 1, -10), "defend": (defend, 1, -8), "death": (death, 2, -7),
    "wall_break": (wall_break, 1, -4), "gate_open": (gate_open, 1, -8), "switch": (switch, 1, -8), "chest_open": (chest_open, 1, -8),
    "coin": (coin, 1, -9), "extinguish": (extinguish, 1, -9), "rope": (rope, 1, -9), "baby": (baby, 2, -9), "fire_loop": (fire_loop, 1, -18),
    "ui_click": (ui_click, 1, -9), "ui_hover": (ui_hover, 1, -16), "ui_back": (ui_back, 1, -11), "dialog_tick": (dialog_tick, 3, -18),
    "turn_start": (turn_start, 1, -9), "victory": (victory, 1, -7), "defeat": (defeat, 1, -8), "item_use": (item_use, 1, -9), "pickup": (pickup, 1, -9),
}


def hash_name(s: str) -> int:
    h = 0
    for ch in s:
        h = (h * 131 + ord(ch)) % (2**31)
    return h


def render(name: str, fn, variant: int, peak_db: float) -> np.ndarray:
    rng = np.random.default_rng(hash_name(name) + variant * 7919)
    x = np.nan_to_num(np.asarray(fn(rng), dtype=np.float64))
    x = x - np.mean(x)
    x = filt(x, "high", 40, 1)   # Gleichanteil und Brummen weg
    m = np.max(np.abs(x)) or 1.0
    x = x / m * 10 ** (peak_db / 20)
    return fade(x, 0.001, 0.008)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    only = sys.argv[1] if len(sys.argv) > 1 else ""
    n = 0
    for name, (fn, variants, peak) in SOUNDS.items():
        if only not in name:
            continue
        for v in range(1, variants + 1):
            x = render(name, fn, v, peak)
            wavfile.write(OUT / f"{name}_{v}.wav", SR, (x * 32767).astype(np.int16))
            n += 1
    print(f"{n} Dateien in {OUT}")


if __name__ == "__main__":
    main()
