#!/usr/bin/env python3
"""Generate retro chiptune-style SFX as 16-bit mono WAV files (44100 Hz).

Stdlib only: wave, struct, math, random. Run from the repo root:

    python3 tools/generate_sfx.py

Output goes to assets/audio/sfx/.
"""

import math
import os
import random
import struct
import wave

SR = 44100          # sample rate (Hz)
PEAK = 0.6          # hard limiter target, keeps levels well below clipping
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "..", "assets", "audio", "sfx")

random.seed(0x600D1E)  # deterministic output


# ---------------------------------------------------------------------------
# Note names -> frequency (equal temperament, A4 = 440 Hz)
# ---------------------------------------------------------------------------

_NAMES = "C C# D D# E F F# G G# A A# B".split()


def freq(note):
    """'A4' -> 440.0, 'C5' -> 523.25 ..."""
    name, octave = note[:-1], int(note[-1])
    midi = (octave + 1) * 12 + _NAMES.index(name)
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


# ---------------------------------------------------------------------------
# Envelopes (return per-sample multiplier for index i of n total samples)
# ---------------------------------------------------------------------------

def pluck_env(i, _n, attack, tau):
    """Linear attack then exponential decay with time constant tau (sec)."""
    a = max(1, int(attack * SR))
    if i < a:
        return i / a
    return math.exp(-(i - a) / (tau * SR))


def hold_env(i, n, attack, release):
    """Linear attack, full sustain, linear release to zero."""
    a = max(1, int(attack * SR))
    r = max(1, int(release * SR))
    if i < a:
        return i / a
    if i >= n - r:
        return max(0.0, (n - i) / r)
    return 1.0


# ---------------------------------------------------------------------------
# Oscillators
# ---------------------------------------------------------------------------

def _osc(kind, phase, duty):
    """One oscillator sample for phase in [0, 1). Noise ignores phase."""
    if kind == "sine":
        return math.sin(2.0 * math.pi * phase)
    if kind == "square":
        return 1.0 if phase < duty else -1.0
    if kind == "tri":
        return 1.0 - 4.0 * abs(phase - 0.5)
    if kind == "saw":
        return 2.0 * phase - 1.0
    if kind == "noise":
        return random.uniform(-1.0, 1.0)
    raise ValueError("unknown waveform: %r" % kind)


def tone(kind, f0, dur, vol=0.5, attack=0.005, tau=None, release=None,
         slide_to=None, vibrato_hz=0.0, vibrato_depth=0.0, duty=0.5):
    """Synthesize a single tone/noise burst -> list of float samples.

    kind        sine | square | tri | saw | noise
    f0          start frequency (Hz); ignored for noise
    slide_to    if set, exponential pitch glide toward this frequency
    tau         pluck envelope decay constant (sec); default 25% of dur
    release     if set, use hold_env with this release time instead of pluck
    vibrato_*   frequency wobble (Hz / fractional depth)
    """
    n = max(1, int(dur * SR))
    if tau is None:
        tau = dur * 0.25
    out = []
    phase = 0.0
    for i in range(n):
        t = i / SR
        f = f0
        if slide_to and f0 > 0:
            f = f0 * (slide_to / f0) ** (i / n)
        if vibrato_hz:
            f *= 1.0 + vibrato_depth * math.sin(2.0 * math.pi * vibrato_hz * t)
        phase = (phase + f / SR) % 1.0
        env = (hold_env(i, n, attack, release) if release is not None
               else pluck_env(i, n, attack, tau))
        out.append(vol * env * _osc(kind, phase, duty))
    return out


def sequence(notes, kind="square", vol=0.5, **kw):
    """Concatenate tones from a list of (note_or_hz, dur) pairs."""
    out = []
    for f, d in notes:
        f = freq(f) if isinstance(f, str) else f
        out.extend(tone(kind, f, d, vol=vol, **kw))
    return out


# ---------------------------------------------------------------------------
# Filters and modulation
# ---------------------------------------------------------------------------

def lowpass(samples, cutoff_hz):
    """One-pole lowpass filter, fixed cutoff."""
    alpha = (1.0 / SR) / (1.0 / (2.0 * math.pi * cutoff_hz) + 1.0 / SR)
    out, y = [], 0.0
    for x in samples:
        y += alpha * (x - y)
        out.append(y)
    return out


def lowpass_sweep(samples, c0, c_mid, c1):
    """Lowpass whose cutoff sweeps c0 -> c_mid -> c1 across the buffer (whoosh)."""
    n = len(samples)
    out, y = [], 0.0
    for i, x in enumerate(samples):
        c = c0 + (c_mid - c0) * (i / (n * 0.5)) if i < n * 0.5 \
            else c_mid + (c1 - c_mid) * ((i - n * 0.5) / (n * 0.5))
        alpha = (1.0 / SR) / (1.0 / (2.0 * math.pi * max(40.0, c)) + 1.0 / SR)
        y += alpha * (x - y)
        out.append(y)
    return out


def tremolo(samples, hz, depth):
    """Amplitude wobble: depth 0..1."""
    return [s * (1.0 - depth * 0.5 * (1.0 + math.sin(2.0 * math.pi * hz * i / SR)))
            for i, s in enumerate(samples)]


# ---------------------------------------------------------------------------
# Mixing / output
# ---------------------------------------------------------------------------

def mix_at(parts, peak=PEAK):
    """Mix [(samples, offset_sec, gain), ...] and limit to `peak`."""
    n = 0
    for s, off, _g in parts:
        n = max(n, int(off * SR) + len(s))
    out = [0.0] * n
    for s, off, g in parts:
        base = int(off * SR)
        for i, x in enumerate(s):
            out[base + i] += x * g
    m = max(1e-9, max(abs(x) for x in out))
    if m > peak:
        out = [x * peak / m for x in out]
    return out


def write_wav(name, samples):
    path = os.path.join(OUT_DIR, name)
    frames = struct.pack(
        "<%dh" % len(samples),
        *[int(max(-1.0, min(1.0, s)) * 32767.0) for s in samples])
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(frames)
    return path


# ---------------------------------------------------------------------------
# Sound effects
# ---------------------------------------------------------------------------

def ui_click():
    # ~60 ms soft click: quick triangle blip sliding down
    return mix_at([(tone("tri", 1400, 0.06, vol=0.5, attack=0.002,
                         tau=0.012, slide_to=900), 0.0, 1.0)])


def spawn():
    # ~120 ms soft pop: sine pitch-pop up + faint octave sparkle
    pop = tone("sine", 320, 0.12, vol=0.55, attack=0.004, tau=0.045,
               slide_to=640)
    sparkle = tone("tri", 1280, 0.05, vol=0.12, attack=0.003, tau=0.02)
    return mix_at([(pop, 0.0, 1.0), (sparkle, 0.03, 1.0)])


def merge():
    # ~200 ms two-tone rising blip: square E5 then A5, tri octave layer
    blip = sequence([("E5", 0.08), ("A5", 0.12)], kind="square",
                    vol=0.4, attack=0.004, tau=0.05)
    layer = sequence([("E6", 0.08), ("A6", 0.12)], kind="tri",
                     vol=0.15, attack=0.004, tau=0.05)
    return mix_at([(blip, 0.0, 1.0), (layer, 0.0, 1.0)])


def kill():
    # ~300 ms noise burst + low thud (goblin dies)
    noise = lowpass(tone("noise", 0, 0.3, vol=0.5, attack=0.002, tau=0.07),
                    2500)
    thud = tone("sine", 110, 0.3, vol=0.6, attack=0.003, tau=0.1,
                slide_to=45)
    crunch = tone("square", 150, 0.08, vol=0.2, attack=0.002, tau=0.03,
                  slide_to=60)
    return mix_at([(noise, 0.0, 1.0), (thud, 0.0, 1.0),
                   (crunch, 0.01, 1.0)])


def coin():
    # ~250 ms bright square arpeggio ding (classic B5 -> E6 coin)
    ding = sequence([("B5", 0.08), ("E6", 0.17)], kind="square",
                    vol=0.4, attack=0.003, tau=0.06)
    layer = sequence([("B6", 0.08), ("E7", 0.17)], kind="tri",
                     vol=0.12, attack=0.003, tau=0.06)
    return mix_at([(ding, 0.0, 1.0), (layer, 0.0, 1.0)])


def hurt():
    # ~350 ms descending sawtooth (player takes damage)
    saw = tone("saw", 380, 0.35, vol=0.45, attack=0.005, release=0.08,
               slide_to=90)
    grit = lowpass(tone("noise", 0, 0.15, vol=0.15, attack=0.003,
                        tau=0.05), 1800)
    return mix_at([(saw, 0.0, 1.0), (grit, 0.0, 1.0)])


def horde_attack():
    # ~500 ms heavy low boom + noise rumble
    boom = tone("sine", 72, 0.5, vol=0.7, attack=0.004, tau=0.16,
                slide_to=36)
    rumble = lowpass(tone("noise", 0, 0.5, vol=0.35, attack=0.01,
                          tau=0.14), 600)
    knock = tone("square", 55, 0.1, vol=0.25, attack=0.003, tau=0.05,
                 slide_to=40)
    return mix_at([(boom, 0.0, 1.0), (rumble, 0.0, 1.0),
                   (knock, 0.0, 1.0)])


def chest():
    # ~400 ms coin sparkle + low creak
    sparkle = sequence([("E6", 0.05), ("G6", 0.05), ("B6", 0.05),
                        ("E7", 0.12)], kind="square", vol=0.3,
                       attack=0.003, tau=0.05)
    shimmer = sequence([("E7", 0.05), ("G7", 0.05), ("B7", 0.05)],
                       kind="tri", vol=0.12, attack=0.003, tau=0.04)
    creak = tone("saw", 65, 0.3, vol=0.22, attack=0.03, release=0.1,
                 vibrato_hz=7.0, vibrato_depth=0.18)
    return mix_at([(sparkle, 0.0, 1.0), (shimmer, 0.02, 1.0),
                   (creak, 0.1, 1.0)])


def fire():
    # ~450 ms filtered noise whoosh (fire scroll AoE)
    whoosh = lowpass_sweep(
        tone("noise", 0, 0.45, vol=0.55, attack=0.06, release=0.25),
        500, 3800, 700)
    body = tone("saw", 140, 0.4, vol=0.12, attack=0.05, release=0.2,
                slide_to=70)
    return mix_at([(whoosh, 0.0, 1.0), (body, 0.02, 1.0)])


def poison():
    # ~400 ms bubbly descending wobble
    wobble = tone("sine", 480, 0.4, vol=0.45, attack=0.01, release=0.1,
                  slide_to=170, vibrato_hz=9.0, vibrato_depth=0.12)
    bubbles = []
    t = 0.05
    while t < 0.36:
        bubbles.append((tone("sine", random.uniform(300, 950), 0.04,
                             vol=0.18, attack=0.004, tau=0.02),
                        t, 1.0))
        t += random.uniform(0.04, 0.08)
    return mix_at([(wobble, 0.0, 1.0)] + bubbles)


def rope():
    # ~200 ms quick zip/swish: fast rising saw + sweeping noise
    zip_tone = tone("saw", 500, 0.14, vol=0.3, attack=0.004, tau=0.05,
                    slide_to=1700)
    swish = lowpass_sweep(
        tone("noise", 0, 0.2, vol=0.35, attack=0.01, release=0.08),
        1200, 6000, 2500)
    return mix_at([(zip_tone, 0.0, 1.0), (swish, 0.0, 1.0)])


def levelup():
    # ~500 ms rising 4-note arpeggio
    arp = sequence([("C5", 0.1), ("E5", 0.1), ("G5", 0.1), ("C6", 0.2)],
                   kind="square", vol=0.4, attack=0.004, tau=0.07)
    layer = sequence([("C6", 0.1), ("E6", 0.1), ("G6", 0.1), ("C7", 0.2)],
                     kind="tri", vol=0.14, attack=0.004, tau=0.07)
    return mix_at([(arp, 0.0, 1.0), (layer, 0.0, 1.0)])


def shop():
    # ~350 ms bell chime: inharmonic partials decaying at different rates
    f = freq("E6")
    chime = mix_at([
        (tone("sine", f, 0.35, vol=0.45, attack=0.002, tau=0.22), 0, 1.0),
        (tone("sine", f * 2.76, 0.3, vol=0.2, attack=0.002, tau=0.1), 0, 1.0),
        (tone("sine", f * 5.4, 0.2, vol=0.1, attack=0.002, tau=0.05), 0, 1.0),
    ], peak=1.0)
    return mix_at([(chime, 0.0, 1.0)])


def victory():
    # ~1.2 s triumphant major arpeggio fanfare ending on a held chord
    run = sequence([("C5", 0.13), ("E5", 0.13), ("G5", 0.13),
                    ("C6", 0.18), ("E6", 0.13), ("G6", 0.5)],
                   kind="square", vol=0.38, attack=0.004, tau=0.09)
    chord = mix_at([
        (tone("square", freq("C6"), 0.45, vol=0.25, attack=0.005,
              release=0.25), 0, 1.0),
        (tone("square", freq("E6"), 0.45, vol=0.25, attack=0.005,
              release=0.25), 0, 1.0),
        (tone("tri", freq("C7"), 0.45, vol=0.2, attack=0.005,
              release=0.25), 0, 1.0),
    ], peak=1.0)
    bass = sequence([("C3", 0.13), ("C3", 0.13), ("G3", 0.13),
                     ("C4", 0.31)], kind="tri", vol=0.22, attack=0.004,
                    tau=0.1)
    return mix_at([(run, 0.0, 1.0), (chord, 0.62, 1.0),
                   (bass, 0.0, 1.0)])


def gameover():
    # ~1.2 s sad descending minor phrase (triangle lead, soft sub)
    lead = sequence([("A4", 0.25), ("F4", 0.25), ("E4", 0.28),
                     ("A3", 0.42)], kind="tri", vol=0.45, attack=0.01,
                    tau=0.16)
    sub = sequence([("A3", 0.25), ("F3", 0.25), ("E3", 0.28),
                    ("A2", 0.42)], kind="sine", vol=0.2, attack=0.01,
                   tau=0.16)
    return mix_at([(lead, 0.0, 1.0), (sub, 0.0, 1.0)])


def streak():
    # ~350 ms excited fast ascending run (kill streak banner)
    run = sequence([("C5", 0.04), ("D5", 0.04), ("E5", 0.04),
                    ("F5", 0.04), ("G5", 0.04), ("A5", 0.04),
                    ("B5", 0.04), ("C6", 0.08)], kind="square",
                   vol=0.38, attack=0.003, tau=0.04)
    top = sequence([("C6", 0.08)], kind="tri", vol=0.15,
                   attack=0.003, tau=0.05)
    return mix_at([(run, 0.0, 1.0), (top, 0.28, 1.0)])


def golden():
    # ~500 ms sparkly shimmering glissando (rare golden goblin)
    gliss = tremolo(tone("sine", 1200, 0.42, vol=0.35, attack=0.01,
                         release=0.15, slide_to=3600),
                    hz=13.0, depth=0.5)
    sparkles = []
    t = 0.03
    while t < 0.44:
        sparkles.append((tone("sine", random.uniform(2200, 5200), 0.05,
                              vol=0.16, attack=0.003, tau=0.025),
                         t, 1.0))
        t += random.uniform(0.03, 0.07)
    chime = sequence([("E7", 0.06), ("G7", 0.1)], kind="tri", vol=0.15,
                     attack=0.003, tau=0.06)
    return mix_at([(gliss, 0.0, 1.0), (chime, 0.36, 1.0)] + sparkles)


# ---------------------------------------------------------------------------

SFX = [
    ("ui_click.wav", ui_click),
    ("spawn.wav", spawn),
    ("merge.wav", merge),
    ("kill.wav", kill),
    ("coin.wav", coin),
    ("hurt.wav", hurt),
    ("horde_attack.wav", horde_attack),
    ("chest.wav", chest),
    ("fire.wav", fire),
    ("poison.wav", poison),
    ("rope.wav", rope),
    ("levelup.wav", levelup),
    ("shop.wav", shop),
    ("victory.wav", victory),
    ("gameover.wav", gameover),
    ("streak.wav", streak),
    ("golden.wav", golden),
]


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, fn in SFX:
        samples = fn()
        path = write_wav(name, samples)
        dur = len(samples) / SR
        print("%-18s %6.0f ms  %d samples -> %s"
              % (name, dur * 1000, len(samples), os.path.relpath(path)))


if __name__ == "__main__":
    main()
