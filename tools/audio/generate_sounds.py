"""Genera todos los sonidos de Lumen de forma procedural.

Todo se sintetiza desde cero con numpy (sin muestras externas), así que los
sonidos son 100 % propios y no hay licencias que revisar.

Uso (necesita numpy e imageio-ffmpeg):
    pip install numpy imageio-ffmpeg
    python tools/audio/generate_sounds.py

Salida en assets/sounds/:
    ambient/  bucles sin corte (lluvia, mar, bosque, ruido suave, música calma)
    breathing/ señales de inhalar / sostener / exhalar y cuenco final
    sfx/      acierto, error, lección completada, pop, giro, compromiso

Los bucles son perfectamente periódicos: el ruido se genera en el dominio de
frecuencia, las modulaciones tienen ciclos enteros dentro del bucle y la
reverberación se aplica como convolución circular.
"""

import os
import subprocess
import tempfile
import wave

import imageio_ffmpeg
import numpy as np

SR = 44100
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'sounds'))
rng = np.random.default_rng(20260916)


# ═══════════════════════════════════════════════════════════════════════════
# Utilidades
# ═══════════════════════════════════════════════════════════════════════════
def t_axis(seconds):
    return np.arange(int(seconds * SR)) / SR


def spectral_noise(n, slope=0.0, low=20.0, high=20000.0, soft=1.0):
    """Ruido periódico de n muestras con espectro ~ 1/f^slope entre low y high."""
    spec = rng.normal(size=n // 2 + 1) + 1j * rng.normal(size=n // 2 + 1)
    f = np.fft.rfftfreq(n, 1 / SR)
    f[0] = 1.0
    shape = f ** (-slope / 2)
    # bordes suaves en vez de corte duro
    shape *= 1 / (1 + (low / f) ** (2 * soft))
    shape *= 1 / (1 + (f / high) ** (2 * soft))
    shape[0] = 0
    x = np.fft.irfft(spec * shape, n)
    return x / (np.max(np.abs(x)) + 1e-12)


def fft_filter(x, low=20.0, high=20000.0, order=2):
    n = len(x)
    f = np.fft.rfftfreq(n, 1 / SR)
    f[0] = 1.0
    h = 1 / np.sqrt(1 + (low / f) ** (2 * order)) / np.sqrt(1 + (f / high) ** (2 * order))
    h[0] = 0
    return np.fft.irfft(np.fft.rfft(x) * h, n)


def circular_reverb(x, seconds=2.8, mix=0.35, bright=6000.0):
    """Reverb por convolución circular: el bucle sigue siendo continuo."""
    n = len(x)
    ir_len = min(n, int(seconds * SR))
    ir = np.zeros(n)
    ir[:ir_len] = rng.normal(size=ir_len) * np.exp(-6.9 * np.arange(ir_len) / ir_len)
    ir = fft_filter(ir, 80, bright)
    wet = np.fft.irfft(np.fft.rfft(x) * np.fft.rfft(ir), n)
    wet *= np.sqrt(np.mean(x ** 2)) / (np.sqrt(np.mean(wet ** 2)) + 1e-12)
    return (1 - mix) * x + mix * wet


def oneshot_reverb(x, seconds=1.5, mix=0.3, bright=6000.0):
    """Reverb para sonidos cortos: rellena con silencio para que la cola no
    dé la vuelta al inicio (la convolución circular lo haría) y recorta."""
    padded = np.pad(x, (0, int((seconds + 0.2) * SR)))
    y = circular_reverb(padded, seconds, mix, bright)
    level = np.abs(y)
    keep = np.nonzero(level > np.max(level) * 10 ** (-55 / 20))[0]
    end = keep[-1] + 1 if len(keep) else len(y)
    y = y[:end]
    fade = min(len(y), int(0.05 * SR))
    y[-fade:] *= np.linspace(1, 0, fade)
    return y


def add_wrapped(buf, clip, start):
    """Suma clip en buf desde start, dando la vuelta al final (bucles)."""
    n = len(buf)
    idx = (np.arange(len(clip)) + start) % n
    np.add.at(buf, idx, clip)


def envelope(n, attack, release, curve=3.0):
    env = np.ones(n)
    a = min(n, int(attack * SR))
    if a > 0:
        env[:a] = np.linspace(0, 1, a) ** 2
    r = int(release * SR)
    tail = np.exp(-curve * np.arange(n - a) / max(1, r))
    env[a:] *= tail
    return env


def note(freq, seconds, partials, attack=0.005, decay=1.0, detune=0.0):
    """Tono con parciales [(ratio, amplitud, factor_decay)]."""
    t = t_axis(seconds)
    out = np.zeros_like(t)
    for ratio, amp, dec in partials:
        f = freq * ratio
        if f > SR / 2.2:
            continue
        env = envelope(len(t), attack, decay * dec)
        out += amp * env * np.sin(2 * np.pi * f * t + rng.uniform(0, 2 * np.pi))
        if detune:
            out += amp * 0.6 * env * np.sin(2 * np.pi * (f + detune) * t)
    fade = min(len(t), int(0.02 * SR))
    out[-fade:] *= np.linspace(1, 0, fade)
    return out


MARIMBA = [(1, 1.0, 1.0), (3.93, 0.25, 0.25), (9.2, 0.06, 0.1)]
BELL = [(1, 1.0, 1.0), (2.0, 0.35, 0.7), (2.76, 0.3, 0.55), (5.4, 0.12, 0.3), (8.93, 0.05, 0.2)]
GLASS = [(1, 1.0, 1.0), (2.0, 0.18, 0.6), (3.0, 0.06, 0.4)]


def midi(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def normalize(x, peak_db=-3.0):
    return x / (np.max(np.abs(x)) + 1e-12) * 10 ** (peak_db / 20)


def normalize_rms(x, rms_db=-20.0, peak_db=-1.5):
    x = x / (np.sqrt(np.mean(x ** 2)) + 1e-12) * 10 ** (rms_db / 20)
    peak = np.max(np.abs(x))
    limit = 10 ** (peak_db / 20)
    if peak > limit:
        x = np.tanh(x / limit) * limit  # limitador suave
    return x


def export(x, rel_path, bitrate='96k'):
    path = os.path.join(ROOT, rel_path)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    pcm = np.clip(x, -1, 1)
    pcm = (pcm * 32767).astype(np.int16)
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp:
        wav_path = tmp.name
    with wave.open(wav_path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
    subprocess.run(
        [ffmpeg, '-y', '-loglevel', 'error', '-i', wav_path,
         '-codec:a', 'libmp3lame', '-b:a', bitrate, path],
        check=True,
    )
    os.remove(wav_path)
    print(f'  {rel_path:34s} {len(x) / SR:5.1f}s  {os.path.getsize(path) / 1024:6.0f} KB')


# ═══════════════════════════════════════════════════════════════════════════
# Ambientes (bucles)
# ═══════════════════════════════════════════════════════════════════════════
LOOP = 48.0  # segundos
N = int(LOOP * SR)
t_loop = np.arange(N) / SR


def periodic_lfo(cycles, phase=0.0):
    return 0.5 + 0.5 * np.sin(2 * np.pi * cycles * t_loop / LOOP + phase)


def rain():
    bed = spectral_noise(N, slope=0.6, low=300, high=9000)
    bed *= 0.85 + 0.15 * periodic_lfo(3) * periodic_lfo(7, 1.3)
    rumble = spectral_noise(N, slope=2.0, low=30, high=250) * 0.35
    drops = np.zeros(N)
    for _ in range(int(LOOP * 14)):
        f = rng.uniform(1800, 5200)
        dur = rng.uniform(0.012, 0.04)
        tt = t_axis(dur)
        clip = np.sin(2 * np.pi * f * tt * (1 - tt * 6)) * np.exp(-tt / (dur / 5))
        add_wrapped(drops, clip * rng.uniform(0.05, 0.25), int(rng.uniform(0, N)))
    drops = fft_filter(drops, 1200, 8000)
    return normalize_rms(bed + rumble + drops * 0.8, -21)


def ocean():
    low = spectral_noise(N, slope=1.6, low=40, high=900)
    high = spectral_noise(N, slope=0.8, low=700, high=7000)
    # olas de distinta duración, todas con ciclos enteros en el bucle
    swell = (periodic_lfo(5) ** 2 * 0.6 + periodic_lfo(4, 2.1) ** 3 * 0.4)
    wash = np.roll(swell, int(0.9 * SR)) ** 2.2
    x = low * (0.25 + 0.75 * swell) + high * (0.05 + 0.6 * wash)
    return normalize_rms(circular_reverb(x, 1.5, 0.2, 5000), -21)


def forest():
    wind = spectral_noise(N, slope=1.2, low=120, high=2500)
    wind *= 0.35 + 0.65 * periodic_lfo(3) * periodic_lfo(2, 0.7)
    leaves = spectral_noise(N, slope=0.3, low=2500, high=9000)
    leaves *= periodic_lfo(6, 1.1) ** 4 * 0.25
    birds = np.zeros(N)
    t0 = 1.0
    while t0 < LOOP:
        base = rng.uniform(2600, 4200)
        for k in range(rng.integers(2, 6)):
            dur = rng.uniform(0.06, 0.16)
            tt = t_axis(dur)
            sweep = base * (1 + rng.uniform(-0.25, 0.3) * tt / dur)
            vib = 1 + 0.03 * np.sin(2 * np.pi * rng.uniform(25, 45) * tt)
            phase = 2 * np.pi * np.cumsum(sweep * vib) / SR
            env = np.sin(np.pi * tt / dur) ** 2
            clip = np.sin(phase) * env * rng.uniform(0.15, 0.35)
            add_wrapped(birds, clip, int((t0 + k * rng.uniform(0.12, 0.22)) * SR))
        t0 += rng.uniform(2.5, 6.5)
    birds = circular_reverb(birds, 1.8, 0.45, 9000)
    return normalize_rms(wind * 0.8 + leaves + birds * 0.9, -22)


def soft_noise():
    x = spectral_noise(N, slope=1.1, low=60, high=6000)
    x *= 0.92 + 0.08 * periodic_lfo(2)
    return normalize_rms(x, -22)


def calm_music():
    """Pad ambiental: 4 acordes de 12 s con campanitas pentatónicas."""
    chord_len = LOOP / 4
    chords = [
        [48, 55, 64, 71],  # Cmaj7
        [45, 52, 60, 67, 71],  # Am9 (sin fundamental repetida)
        [41, 48, 57, 64],  # Fmaj7
        [43, 50, 59, 62, 69],  # G6/9
    ]
    pad = np.zeros(N)
    for ci, chord in enumerate(chords):
        seg = int(chord_len * SR * 1.5)  # se solapan para transiciones suaves
        tt = t_axis(chord_len * 1.5)
        env = np.sin(np.pi * np.clip(tt / (chord_len * 1.5), 0, 1)) ** 1.5
        seg_sig = np.zeros(seg)
        for m in chord:
            f = midi(m)
            for detune in (-0.12, 0.0, 0.14):
                ff = f * 2 ** (detune / 12)
                seg_sig += np.sin(2 * np.pi * ff * tt + rng.uniform(0, 6.28))
                seg_sig += 0.25 * np.sin(2 * np.pi * 2 * ff * tt)
                seg_sig += 0.08 * np.sin(2 * np.pi * 3 * ff * tt)
        start = int((ci * chord_len - chord_len * 0.25) * SR)
        add_wrapped(pad, seg_sig * env, start)
    pad = fft_filter(pad, 60, 2200)
    # respiración lenta del pad
    pad *= 0.8 + 0.2 * periodic_lfo(6)

    bells = np.zeros(N)
    pentatonic = [72, 74, 76, 79, 81, 84, 86, 88]
    beat = 60 / 64
    step = 0.0
    while step < LOOP:
        if rng.random() < 0.42:
            m = pentatonic[rng.integers(0, len(pentatonic))]
            clip = note(midi(m), 3.5, GLASS, attack=0.004, decay=0.9)
            add_wrapped(bells, clip * rng.uniform(0.08, 0.18), int(step * SR))
        step += beat * rng.choice([1, 1, 2])
    mix = pad / (np.max(np.abs(pad)) + 1e-12) * 0.55 + bells
    mix = circular_reverb(mix, 3.5, 0.5, 5500)
    return normalize_rms(mix, -21)


# ═══════════════════════════════════════════════════════════════════════════
# Respiración
# ═══════════════════════════════════════════════════════════════════════════
def breath_inhale():
    a = note(midi(72), 1.8, GLASS, attack=0.12, decay=1.1)
    b = note(midi(79), 1.6, GLASS, attack=0.12, decay=1.0)
    x = np.zeros(int(2.2 * SR))
    x[: len(a)] += a * 0.7
    x[int(0.22 * SR): int(0.22 * SR) + len(b)] += b * 0.8
    return normalize(oneshot_reverb(x, 1.6, 0.35), -6)


def breath_exhale():
    a = note(midi(79), 2.0, GLASS, attack=0.1, decay=1.3)
    b = note(midi(72), 2.2, GLASS, attack=0.12, decay=1.5)
    x = np.zeros(int(2.8 * SR))
    x[: len(a)] += a * 0.6
    x[int(0.3 * SR): int(0.3 * SR) + len(b)] += b * 0.75
    return normalize(oneshot_reverb(x, 1.8, 0.35), -7)


def breath_hold():
    x = note(midi(76), 1.8, BELL, attack=0.01, decay=0.8)
    return normalize(oneshot_reverb(x, 1.4, 0.3), -9)


def singing_bowl():
    f = 196.0
    t = t_axis(7.0)
    x = np.zeros_like(t)
    for ratio, amp, dec in [(1, 1.0, 6.0), (2.71, 0.5, 4.0), (5.15, 0.22, 2.5), (8.1, 0.1, 1.5)]:
        env = np.exp(-t / dec) * (1 - np.exp(-t / 0.004))
        beat = 1 + 0.25 * np.sin(2 * np.pi * (0.7 + ratio * 0.15) * t)
        x += amp * env * beat * np.sin(2 * np.pi * f * ratio * t)
    x[-SR // 4:] *= np.linspace(1, 0, SR // 4)
    return normalize(oneshot_reverb(x, 2.5, 0.25), -4)


# ═══════════════════════════════════════════════════════════════════════════
# Efectos de interfaz
# ═══════════════════════════════════════════════════════════════════════════
def sfx_correct():
    a = note(midi(88), 0.5, MARIMBA, decay=0.18)
    b = note(midi(93), 0.7, MARIMBA, decay=0.25)
    x = np.zeros(int(0.9 * SR))
    x[: len(a)] += a * 0.8
    x[int(0.09 * SR): int(0.09 * SR) + len(b)] += b
    return normalize(oneshot_reverb(x, 0.6, 0.15), -5)


def sfx_wrong():
    a = note(midi(62), 0.4, [(1, 1, 1), (2, 0.15, 0.5)], attack=0.01, decay=0.15)
    b = note(midi(58), 0.5, [(1, 1, 1), (2, 0.15, 0.5)], attack=0.01, decay=0.2)
    x = np.zeros(int(0.7 * SR))
    x[: len(a)] += a * 0.8
    x[int(0.11 * SR): int(0.11 * SR) + len(b)] += b
    return normalize(fft_filter(x, 120, 2500), -9)


def sfx_complete():
    notes = [72, 76, 79, 84]
    x = np.zeros(int(2.6 * SR))
    for i, m in enumerate(notes):
        clip = note(midi(m), 1.8, BELL, decay=0.7) * (0.7 + 0.1 * i)
        s = int(i * 0.1 * SR)
        x[s: s + len(clip)] += clip
    for _ in range(9):  # brillitos
        clip = note(midi(rng.choice([91, 96, 98, 100, 103])), 0.6, GLASS, decay=0.25)
        s = int(rng.uniform(0.45, 1.0) * SR)
        x[s: s + len(clip)] += clip * rng.uniform(0.08, 0.2)
    return normalize(oneshot_reverb(x, 1.8, 0.3), -3)


def sfx_pop():
    t = t_axis(0.09)
    f = 950 * np.exp(-t * 18) + 380
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.025)
    return normalize(x, -10)


def sfx_flip():
    n = int(0.35 * SR)
    noise = rng.normal(size=n)
    t = np.arange(n) / n
    env = np.sin(np.pi * t) ** 2
    lo = fft_filter(noise, 300, 1500) * (1 - t)
    hi = fft_filter(noise, 1500, 6000) * t
    return normalize((lo + hi) * env, -14)


def sfx_commit():
    t = t_axis(1.6)
    swell = np.zeros_like(t)
    for m in (60, 67, 72):
        swell += np.sin(2 * np.pi * midi(m) * t)
    swell *= np.clip(t / 0.8, 0, 1) ** 2 * np.exp(-np.clip(t - 0.8, 0, None) / 0.3)
    chime = note(midi(84), 1.4, BELL, decay=0.6)
    x = np.zeros(int(2.4 * SR))
    x[: len(swell)] += fft_filter(swell, 80, 1800) * 0.25
    s = int(0.78 * SR)
    x[s: s + len(chime)] += chime
    return normalize(oneshot_reverb(x, 1.6, 0.3), -4)


# ═══════════════════════════════════════════════════════════════════════════
# Segunda tanda: identidad sonora de lecciones, rutas e hitos de la app.
# Todo en Do mayor pentatónica (Do Re Mi Sol La) para que suene coherente.
# ═══════════════════════════════════════════════════════════════════════════
KALIMBA = [(1, 1.0, 1.0), (2.0, 0.1, 0.35), (5.4, 0.07, 0.12)]
PENTA = [0, 2, 4, 7, 9]


def penta(base_midi, degree):
    """Nota pentatónica de Do: el grado sube por la escala y las octavas."""
    return base_midi + 12 * (degree // 5) + PENTA[degree % 5]


def place(buf, clip, start_s, gain=1.0):
    s0 = int(start_s * SR)
    end = min(len(buf), s0 + len(clip))
    if end > s0:
        buf[s0:end] += clip[: end - s0] * gain


def silence(seconds):
    return np.zeros(int(seconds * SR))


def sparkles(buf, start, end, count, gain=0.12):
    for _ in range(count):
        m = penta(91, int(rng.integers(0, 8)))
        place(buf, note(midi(m), 0.5, GLASS, decay=0.18), rng.uniform(start, end), gain * rng.uniform(0.6, 1.2))


# ── Lecciones ──────────────────────────────────────────────────────────────
def sfx_combo(level):
    """Acierto en racha: la nota sube con cada acierto seguido (0-5)."""
    root = midi(penta(84, level))
    x = silence(1.0)
    place(x, note(root, 0.7, MARIMBA, decay=0.22), 0, 0.9)
    place(x, note(root * 1.5, 0.8, BELL, decay=0.3), 0.06, 0.45)
    place(x, note(root * 2, 0.6, GLASS, decay=0.2), 0.12, 0.2)
    return normalize(oneshot_reverb(x, 0.8, 0.2), -5)


def sfx_note(i):
    """Notas para ordenar pasos: al acertar en orden se arma una melodía."""
    x = note(midi(penta(72, i)), 1.2, KALIMBA, attack=0.002, decay=0.5)
    return normalize(oneshot_reverb(x, 0.9, 0.25), -6)


def sfx_tick():
    t = t_axis(0.05)
    x = np.sin(2 * np.pi * 1850 * t) * np.exp(-t / 0.006)
    x += 0.4 * np.sin(2 * np.pi * 3100 * t) * np.exp(-t / 0.003)
    return normalize(x, -16)


def sfx_toggle(on):
    t = t_axis(0.12)
    f = (880 if on else 660) * (1 + (0.25 if on else -0.2) * np.clip(t / 0.05, 0, 1))
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.03)
    return normalize(x, -13)


def sfx_bubble():
    t = t_axis(0.14)
    f = 320 + 900 * (1 - np.exp(-t / 0.03))
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.035) * (1 - np.exp(-t / 0.003))
    return normalize(oneshot_reverb(x, 0.4, 0.15), -11)


def sfx_swipe():
    n = int(0.22 * SR)
    noise = rng.normal(size=n)
    tt = np.arange(n) / n
    x = (fft_filter(noise, 900, 3000) * (1 - tt) + fft_filter(noise, 3000, 8000) * tt) * np.sin(np.pi * tt) ** 1.5
    return normalize(x, -15)


def sfx_hold_rise():
    """Suena mientras se mantiene presionado el compromiso (1.3 s)."""
    t = t_axis(1.35)
    prog = np.clip(t / 1.3, 0, 1)
    x = np.zeros_like(t)
    for m, g in ((60, 0.5), (67, 0.35), (72, 0.3)):
        f = midi(m) * (1 + 0.5 * prog ** 1.6)
        trem = 1 + (0.15 + 0.35 * prog) * np.sin(2 * np.pi * (4 + 10 * prog) * t)
        x += g * np.sin(2 * np.pi * np.cumsum(f) / SR) * trem
    x *= prog ** 1.2
    fade = int(0.05 * SR)
    x[-fade:] *= np.linspace(1, 0, fade)
    return normalize(fft_filter(x, 100, 5000), -9)


def sfx_tap_node():
    x = note(midi(79), 0.25, [(1, 1, 1), (2.76, 0.2, 0.3)], attack=0.001, decay=0.06)
    return normalize(x, -12)


# ── Hitos ──────────────────────────────────────────────────────────────────
def sfx_unlock():
    x = silence(1.6)
    for i, m in enumerate([79, 84, 88, 91]):
        place(x, note(midi(m), 0.9, GLASS, decay=0.35), i * 0.07, 0.6)
    sparkles(x, 0.25, 0.7, 6)
    return normalize(oneshot_reverb(x, 1.2, 0.3), -5)


def sfx_route_complete():
    x = silence(4.5)
    chords = [[60, 64, 67, 72], [65, 69, 72, 77], [67, 71, 74, 79], [72, 76, 79, 84]]
    for ci, chord in enumerate(chords):
        start = ci * 0.42 if ci < 3 else 1.35
        dur = 0.9 if ci < 3 else 2.8
        for m in chord:
            place(x, note(midi(m), dur, BELL, decay=0.5 if ci < 3 else 1.1), start, 0.35)
        place(x, note(midi(chord[0] - 12), dur, [(1, 1, 1), (2, 0.3, 0.6)], attack=0.02, decay=0.8), start, 0.4)
    for i, m in enumerate([84, 88, 91, 96]):
        place(x, note(midi(m), 1.2, GLASS, decay=0.5), 1.35 + i * 0.09, 0.3)
    sparkles(x, 1.6, 2.8, 14, 0.14)
    return normalize(oneshot_reverb(x, 2.2, 0.35), -3)


def sfx_level_up():
    x = silence(2.8)
    for i in range(10):
        place(x, note(midi(penta(60, i)), 0.5, MARIMBA, decay=0.18), i * 0.055, 0.55)
    for m in (72, 76, 79, 84):
        place(x, note(midi(m), 2.0, BELL, decay=0.9), 0.6, 0.35)
    sparkles(x, 0.7, 1.6, 10)
    return normalize(oneshot_reverb(x, 1.8, 0.3), -3)


def sfx_achievement():
    x = silence(2.6)
    place(x, note(midi(76), 1.6, BELL, decay=0.8), 0, 0.6)
    place(x, note(midi(84), 1.8, BELL, decay=0.9), 0.14, 0.7)
    place(x, note(midi(91), 1.8, GLASS, decay=0.8), 0.28, 0.4)
    sparkles(x, 0.3, 1.2, 12)
    return normalize(oneshot_reverb(x, 1.8, 0.35), -3)


def sfx_reward():
    x = silence(1.6)
    coin = [(1, 1, 1), (2.0, 0.3, 0.5), (4.1, 0.15, 0.3)]
    for i in range(7):
        m = penta(88, int(rng.integers(0, 6)))
        place(x, note(midi(m), 0.45, coin, decay=0.12), i * 0.075, 0.5)
    place(x, note(midi(96), 0.9, GLASS, decay=0.4), 0.55, 0.4)
    return normalize(oneshot_reverb(x, 1.0, 0.25), -5)


def sfx_checkin():
    x = silence(1.9)
    place(x, note(midi(76), 1.4, GLASS, attack=0.02, decay=0.8), 0, 0.7)
    place(x, note(midi(81), 1.5, GLASS, attack=0.02, decay=0.9), 0.18, 0.8)
    place(x, note(midi(57), 1.6, [(1, 1, 1), (2, 0.3, 0.6)], attack=0.25, decay=0.8), 0, 0.25)
    return normalize(oneshot_reverb(x, 1.4, 0.3), -6)


def sfx_habit():
    x = silence(0.9)
    place(x, note(midi(79), 0.6, KALIMBA, attack=0.002, decay=0.25), 0, 0.8)
    place(x, note(midi(84), 0.8, KALIMBA, attack=0.002, decay=0.35), 0.09, 1.0)
    return normalize(oneshot_reverb(x, 0.8, 0.2), -6)


def sfx_save():
    n = int(0.3 * SR)
    tt = np.arange(n) / n
    swish = fft_filter(rng.normal(size=n), 1500, 7000) * np.sin(np.pi * tt) ** 2 * 0.25
    x = silence(1.3)
    place(x, swish, 0)
    place(x, note(midi(72), 1.0, BELL, decay=0.5), 0.2, 0.6)
    return normalize(oneshot_reverb(x, 1.0, 0.25), -7)


def sfx_plant():
    t = t_axis(0.35)
    thump = np.sin(2 * np.pi * (140 * np.exp(-t * 6) + 70) * t) * np.exp(-t / 0.08)
    soil = fft_filter(rng.normal(size=len(t)), 200, 1800) * np.exp(-t / 0.05) * 0.3
    x = silence(1.4)
    place(x, thump + soil, 0, 0.8)
    place(x, note(midi(84), 0.8, GLASS, decay=0.3), 0.22, 0.35)
    place(x, note(midi(88), 0.8, GLASS, decay=0.3), 0.3, 0.3)
    return normalize(oneshot_reverb(x, 0.9, 0.2), -6)


def sfx_harvest():
    x = silence(1.8)
    for i, m in enumerate([72, 76, 79, 84, 88]):
        place(x, note(midi(m), 0.8, KALIMBA, attack=0.002, decay=0.35), i * 0.08, 0.7)
    sparkles(x, 0.4, 0.9, 8)
    return normalize(oneshot_reverb(x, 1.2, 0.25), -4)


def sfx_booster():
    t = t_axis(1.1)
    f = midi(79) * (1 + 1.0 * (t / 1.1) ** 1.5)
    shimmer = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.pi * np.clip(t / 1.1, 0, 1))
    shimmer *= 1 + 0.4 * np.sin(2 * np.pi * 14 * t)
    x = silence(1.6)
    place(x, shimmer, 0, 0.35)
    sparkles(x, 0.2, 1.0, 10, 0.15)
    return normalize(oneshot_reverb(x, 1.0, 0.3), -6)


def sfx_buy():
    coin = [(1, 1, 1), (2.4, 0.4, 0.4)]
    x = silence(1.0)
    place(x, note(midi(84), 0.4, coin, decay=0.1), 0, 0.7)
    place(x, note(midi(91), 0.7, coin, decay=0.2), 0.08, 0.8)
    return normalize(oneshot_reverb(x, 0.7, 0.2), -6)


# ── Ambientes por ruta (bucles) ─────────────────────────────────────────────
def soft_pad(chords, seconds_each, octave_gain=0.25, cutoff=1800):
    """Pad de acordes que se funden en bucle (misma técnica que calm_music)."""
    pad = np.zeros(N)
    for ci, chord in enumerate(chords):
        tt = t_axis(seconds_each * 1.5)
        env = np.sin(np.pi * np.clip(tt / (seconds_each * 1.5), 0, 1)) ** 1.5
        seg = np.zeros(len(tt))
        for m in chord:
            f = midi(m)
            for det in (-0.1, 0.0, 0.12):
                ff = f * 2 ** (det / 12)
                seg += np.sin(2 * np.pi * ff * tt + rng.uniform(0, 6.28))
                seg += octave_gain * np.sin(2 * np.pi * 2 * ff * tt)
        add_wrapped(pad, seg * env, int((ci * seconds_each - seconds_each * 0.25) * SR))
    pad = fft_filter(pad, 50, cutoff)
    return pad / (np.max(np.abs(pad)) + 1e-12)


def night():
    """Autoconocimiento: grillos y un pad nocturno muy suave."""
    crickets = np.zeros(N)
    for voice in range(3):
        f = rng.uniform(4000, 5200)
        t0 = rng.uniform(0, 1)
        period = rng.uniform(0.7, 1.3)
        while t0 < LOOP:
            dur = rng.uniform(0.12, 0.2)
            tt = t_axis(dur)
            am = (np.sin(2 * np.pi * rng.uniform(28, 40) * tt) > 0.2).astype(float)
            chirp = np.sin(2 * np.pi * f * tt) * am * np.sin(np.pi * tt / dur)
            add_wrapped(crickets, chirp * rng.uniform(0.08, 0.16) * (0.6 + 0.2 * voice), int(t0 * SR))
            t0 += period * rng.uniform(0.85, 1.15)
    crickets = fft_filter(crickets, 3000, 9000)
    pad = soft_pad([[45, 52, 59, 64], [41, 48, 55, 60], [43, 50, 57, 62], [45, 52, 60, 64]], LOOP / 4, 0.15, 1100)
    air = spectral_noise(N, slope=1.5, low=80, high=900) * 0.15
    mix = crickets * 1.4 + pad * 0.35 + air
    return normalize_rms(circular_reverb(mix, 2.5, 0.35, 7000), -23)


def stream():
    """Mindfulness: un arroyo con burbujeo y algún pájaro lejano."""
    bed = spectral_noise(N, slope=0.9, low=250, high=5000) * 0.5
    bed *= 0.8 + 0.2 * periodic_lfo(9) * periodic_lfo(5, 0.4)
    bubbles = np.zeros(N)
    for _ in range(int(LOOP * 45)):
        f0 = rng.uniform(500, 1600)
        dur = rng.uniform(0.015, 0.05)
        tt = t_axis(dur)
        f = f0 * (1 + 2.5 * tt / dur)
        clip = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tt / (dur / 3))
        add_wrapped(bubbles, clip * rng.uniform(0.03, 0.12), int(rng.uniform(0, N)))
    birds = np.zeros(N)
    t0 = 3.0
    while t0 < LOOP:
        base = rng.uniform(2800, 3800)
        for k in range(rng.integers(2, 4)):
            dur = rng.uniform(0.08, 0.14)
            tt = t_axis(dur)
            f = base * (1 + rng.uniform(-0.2, 0.25) * tt / dur)
            clip = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.pi * tt / dur) ** 2
            add_wrapped(birds, clip * 0.12, int((t0 + k * 0.16) * SR))
        t0 += rng.uniform(7, 12)
    mix = bed + fft_filter(bubbles, 400, 4000) * 1.3 + circular_reverb(birds, 2.0, 0.5, 9000)
    return normalize_rms(mix, -22)


def mountain():
    """Resiliencia: viento de montaña con campanas de viento."""
    wind = spectral_noise(N, slope=1.4, low=90, high=1400)
    wind *= 0.3 + 0.7 * (periodic_lfo(3) * 0.6 + periodic_lfo(5, 1.7) * 0.4) ** 2
    whistle = spectral_noise(N, slope=0.2, low=900, high=1300) * periodic_lfo(4, 0.9) ** 3 * 0.12
    chimes = np.zeros(N)
    t0 = 2.0
    while t0 < LOOP:
        for k in range(rng.integers(3, 7)):
            m = penta(84, int(rng.integers(0, 7)))
            clip = note(midi(m), 3.0, BELL, attack=0.002, decay=1.2)
            add_wrapped(chimes, clip * rng.uniform(0.05, 0.12), int((t0 + k * rng.uniform(0.12, 0.35)) * SR))
        t0 += rng.uniform(5, 9)
    mix = wind * 0.8 + whistle + circular_reverb(chimes, 3.0, 0.45, 8000)
    return normalize_rms(mix, -22)


def sunrise():
    """Autoestima: pad luminoso con arpegio lento, como un amanecer."""
    chords = [[60, 64, 67, 71, 74], [57, 64, 67, 72], [53, 60, 64, 69], [55, 62, 67, 71]]
    pad = soft_pad(chords, LOOP / 4, 0.3, 2600)
    arp = np.zeros(N)
    step = 60 / 72 / 2
    i = 0
    while i * step < LOOP:
        chord = chords[int((i * step) // (LOOP / 4)) % 4]
        m = chord[i % len(chord)] + 12
        clip = note(midi(m), 1.6, GLASS, attack=0.004, decay=0.6)
        add_wrapped(arp, clip * (0.1 if i % 2 else 0.14), int(i * step * SR))
        i += 1
    mix = pad * 0.5 + arp
    return normalize_rms(circular_reverb(mix, 3.2, 0.45, 6500), -21)


def kalimba_loop():
    """Relaciones: kalimba cálida con frases que se responden."""
    pad = soft_pad([[48, 55, 64], [45, 52, 60], [41, 48, 57], [43, 50, 59]], LOOP / 4, 0.1, 900)
    kal = np.zeros(N)
    beat = 60 / 84
    motifs = [[4, 5, 7, 5], [7, 9, 7, 4], [2, 4, 5, 4], [5, 4, 2, 0]]
    t0 = 0.0
    phrase = 0
    while t0 < LOOP - 0.1:
        for k, deg in enumerate(motifs[phrase % len(motifs)]):
            clip = note(midi(penta(60, deg)), 1.5, KALIMBA, attack=0.002, decay=0.6)
            add_wrapped(kal, clip * rng.uniform(0.15, 0.22), int((t0 + k * beat) * SR))
        t0 += beat * 6
        phrase += 1
    mix = pad * 0.3 + kal
    return normalize_rms(circular_reverb(mix, 2.2, 0.35, 6000), -21)


def music_box():
    """Amor: caja musical tierna en 3/4."""
    beat = 60 / 76
    melody = [9, 7, 5, 7, 9, 9, 9, None, 7, 7, 7, None, 9, 11, 11, None,
              9, 7, 5, 7, 9, 9, 9, 9, 7, 7, 9, 7, 5, None]
    tine = [(1, 1, 1), (3.0, 0.25, 0.3), (6.2, 0.1, 0.12)]
    box = np.zeros(N)
    t0 = 0.0
    idx = 0
    while t0 < LOOP - 0.05:
        deg = melody[idx % len(melody)]
        if deg is not None:
            clip = note(midi(penta(72, deg)), 2.0, tine, attack=0.001, decay=0.7)
            add_wrapped(box, clip * 0.2, int(t0 * SR))
        if idx % 3 == 0:
            bass_deg = [0, 5, 3, 4][(idx // 3) % 4]
            bass = note(midi(penta(48, bass_deg)), 2.4, [(1, 1, 1), (2, 0.2, 0.5)], attack=0.01, decay=0.9)
            add_wrapped(box, bass * 0.12, int(t0 * SR))
        t0 += beat
        idx += 1
    return normalize_rms(circular_reverb(box, 2.6, 0.4, 7000), -21)


# ── Repaso diario ───────────────────────────────────────────────────────────
def sfx_card_deal():
    """Tarjeta que se desliza sobre la mesa + un toque suave al asentarse."""
    n = int(0.18 * SR)
    tt = np.arange(n) / n
    slide = fft_filter(rng.normal(size=n), 2000, 9000) * (tt ** 0.5) * np.exp(-tt * 3) * 0.35
    x = silence(0.45)
    place(x, slide, 0)
    place(x, note(midi(88), 0.3, [(1, 1, 1), (2.76, 0.2, 0.3)], attack=0.001, decay=0.05), 0.15, 0.25)
    return normalize(x, -12)


def sfx_review_start():
    x = silence(1.4)
    for i, m in enumerate([72, 76, 79, 84, 88]):
        place(x, note(midi(m), 0.7, GLASS, attack=0.004, decay=0.25), i * 0.05, 0.5 + i * 0.05)
    sparkles(x, 0.25, 0.6, 5, 0.1)
    return normalize(oneshot_reverb(x, 1.0, 0.3), -6)


def sfx_star(i):
    """Una estrella del resultado: cada una más aguda (Mi, Sol, Do)."""
    m = [88, 91, 96][i]
    x = silence(1.2)
    place(x, note(midi(m), 1.0, BELL, attack=0.001, decay=0.45), 0, 0.8)
    place(x, note(midi(m + 12), 0.6, GLASS, decay=0.2), 0.03, 0.25)
    return normalize(oneshot_reverb(x, 0.9, 0.3), -6)


def sfx_review_perfect():
    x = silence(3.2)
    melody = [(72, 0.0), (76, 0.12), (79, 0.24), (84, 0.36), (79, 0.52), (84, 0.64), (88, 0.76)]
    for m, t in melody:
        place(x, note(midi(m), 0.9, KALIMBA, attack=0.002, decay=0.35), t, 0.6)
        place(x, note(midi(m + 12), 0.6, GLASS, decay=0.2), t + 0.01, 0.15)
    for m in (72, 76, 79, 84, 91):
        place(x, note(midi(m), 2.2, BELL, decay=1.0), 0.95, 0.25)
    sparkles(x, 1.0, 2.0, 14, 0.13)
    return normalize(oneshot_reverb(x, 2.0, 0.35), -3)


# ── Lumi, la compañera ──────────────────────────────────────────────────────
def lumi_blip(freq, dur, rise=0.35, vibrato=0.0):
    """Un "bip" tierno: seno con subida de tono, un poco de octava y vibrato."""
    t = t_axis(dur)
    f = freq * (1 + rise * np.clip(t / (dur * 0.6), 0, 1) ** 0.7)
    if vibrato:
        f *= 1 + vibrato * np.sin(2 * np.pi * 18 * t)
    phase = 2 * np.pi * np.cumsum(f) / SR
    env = np.sin(np.pi * np.clip(t / dur, 0, 1)) ** 1.2
    return (np.sin(phase) + 0.18 * np.sin(2 * phase)) * env


def sfx_lumi_chirp(variant):
    """Tres voces de Lumi al tocarla: siempre alegres, nunca iguales."""
    x = silence(0.6)
    if variant == 0:  # "bi-bip"
        place(x, lumi_blip(midi(84), 0.08), 0, 0.8)
        place(x, lumi_blip(midi(91), 0.11), 0.09, 0.9)
    elif variant == 1:  # "uii" que sube
        place(x, lumi_blip(midi(79), 0.22, rise=0.6, vibrato=0.015), 0, 0.9)
    else:  # "bip-bup-bip"
        place(x, lumi_blip(midi(88), 0.07), 0, 0.8)
        place(x, lumi_blip(midi(84), 0.07, rise=-0.1), 0.08, 0.7)
        place(x, lumi_blip(midi(91), 0.1), 0.16, 0.9)
    return normalize(oneshot_reverb(x, 0.5, 0.15), -9)


def sfx_lumi_hello():
    """Lumi aparece para hablar: tres notas que suben y un brillito."""
    x = silence(1.0)
    for i, m in enumerate([79, 84, 88]):
        place(x, lumi_blip(midi(m), 0.09, rise=0.15), i * 0.09, 0.75)
    place(x, note(midi(96), 0.5, GLASS, decay=0.2), 0.3, 0.2)
    return normalize(oneshot_reverb(x, 0.8, 0.25), -10)


def main():
    print('Ambientes (bucles de %.0f s):' % LOOP)
    export(rain(), 'ambient/rain.mp3', '80k')
    export(ocean(), 'ambient/ocean.mp3', '80k')
    export(forest(), 'ambient/forest.mp3', '80k')
    export(soft_noise(), 'ambient/soft_noise.mp3', '64k')
    export(calm_music(), 'ambient/calm_music.mp3', '96k')
    print('Respiración:')
    export(breath_inhale(), 'breathing/inhale.mp3')
    export(breath_hold(), 'breathing/hold.mp3')
    export(breath_exhale(), 'breathing/exhale.mp3')
    export(singing_bowl(), 'breathing/bowl.mp3')
    print('Efectos:')
    export(sfx_correct(), 'sfx/correct.mp3')
    export(sfx_wrong(), 'sfx/wrong.mp3')
    export(sfx_complete(), 'sfx/complete.mp3')
    export(sfx_pop(), 'sfx/pop.mp3')
    export(sfx_flip(), 'sfx/flip.mp3')
    export(sfx_commit(), 'sfx/commit.mp3')

    # Segunda tanda (va al final para no alterar los sonidos anteriores:
    # comparten el mismo generador aleatorio con semilla fija).
    print('Lecciones:')
    for level in range(6):
        export(sfx_combo(level), f'sfx/combo_{level}.mp3')
    for i in range(8):
        export(sfx_note(i), f'sfx/note_{i}.mp3')
    export(sfx_tick(), 'sfx/tick.mp3')
    export(sfx_toggle(True), 'sfx/toggle_on.mp3')
    export(sfx_toggle(False), 'sfx/toggle_off.mp3')
    export(sfx_bubble(), 'sfx/bubble.mp3')
    export(sfx_swipe(), 'sfx/swipe.mp3')
    export(sfx_hold_rise(), 'sfx/hold_rise.mp3')
    export(sfx_tap_node(), 'sfx/tap_node.mp3')
    print('Hitos:')
    export(sfx_unlock(), 'sfx/unlock.mp3')
    export(sfx_route_complete(), 'sfx/route_complete.mp3')
    export(sfx_level_up(), 'sfx/level_up.mp3')
    export(sfx_achievement(), 'sfx/achievement.mp3')
    export(sfx_reward(), 'sfx/reward.mp3')
    export(sfx_checkin(), 'sfx/checkin.mp3')
    export(sfx_habit(), 'sfx/habit.mp3')
    export(sfx_save(), 'sfx/save.mp3')
    export(sfx_plant(), 'sfx/plant.mp3')
    export(sfx_harvest(), 'sfx/harvest.mp3')
    export(sfx_booster(), 'sfx/booster.mp3')
    export(sfx_buy(), 'sfx/buy.mp3')
    print('Ambientes por ruta:')
    export(night(), 'ambient/night.mp3', '64k')
    export(stream(), 'ambient/stream.mp3', '80k')
    export(mountain(), 'ambient/mountain.mp3', '80k')
    export(sunrise(), 'ambient/sunrise.mp3', '64k')
    export(kalimba_loop(), 'ambient/kalimba.mp3', '64k')
    export(music_box(), 'ambient/music_box.mp3', '64k')

    # Tercera tanda: repaso diario
    print('Repaso diario:')
    export(sfx_card_deal(), 'sfx/card_deal.mp3')
    export(sfx_review_start(), 'sfx/review_start.mp3')
    for i in range(3):
        export(sfx_star(i), f'sfx/star_{i}.mp3')
    export(sfx_review_perfect(), 'sfx/review_perfect.mp3')

    # Cuarta tanda: la voz de Lumi
    print('Lumi:')
    for v in range(3):
        export(sfx_lumi_chirp(v), f'sfx/lumi_chirp_{v}.mp3')
    export(sfx_lumi_hello(), 'sfx/lumi_hello.mp3')


if __name__ == '__main__':
    main()
