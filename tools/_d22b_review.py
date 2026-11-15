# D22b: draw the transition review - loudness over time of the recorded Master bus, with the
# test's own marks (renders/cycles/d22b/moods_marks.txt). Usage: python3 tools/_d22b_review.py
import wave, numpy as np, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
w = wave.open("renders/cycles/d22b/moods.wav")
sr, ch, n = w.getframerate(), w.getnchannels(), w.getnframes()
a = np.frombuffer(w.readframes(n), dtype=np.int16 if w.getsampwidth() == 2 else np.int32).astype(np.float64)
a = a.reshape(-1, ch).mean(axis=1) / (32768.0 if w.getsampwidth() == 2 else 2**31)
win = int(sr * 0.25)
m = len(a) // win
rms = np.sqrt((a[: m * win].reshape(m, win) ** 2).mean(axis=1) + 1e-12)
db = 20 * np.log10(rms)
t = np.arange(m) * 0.25
marks = [l.strip().split(" ", 1) for l in open("renders/cycles/d22b/moods_marks.txt") if l.strip()]
fig, ax = plt.subplots(2, 1, figsize=(16, 8), gridspec_kw={"height_ratios": [2, 1]})
ax[0].plot(t, db, lw=1)
ax[0].set_ylabel("RMS dBFS (250 ms)"); ax[0].set_ylim(-70, 0); ax[0].grid(alpha=.3)
for s, what in marks:
    x = float(s); ax[0].axvline(x, color="r", alpha=.4); ax[0].text(x + .3, -5, what, rotation=90, va="top", fontsize=7)
ax[0].set_title("D22b music moods - Master bus, %.0f s, peak %.1f dBFS, clipped %d" % (len(a) / sr, 20 * np.log10(np.abs(a).max() + 1e-12), int((np.abs(a) >= 0.999).sum())))
ax[1].specgram(a[::2], NFFT=2048, Fs=sr / 2, noverlap=1024, cmap="magma"); ax[1].set_ylim(0, 6000); ax[1].set_ylabel("Hz"); ax[1].set_xlabel("s")
plt.tight_layout(); plt.savefig("renders/cycles/d22b/moods_review.png", dpi=90)
print("REVIEW", len(a) / sr, "s", "peak", float(np.abs(a).max()))
