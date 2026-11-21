#!/usr/bin/env python3
"""BACK-LAMP GUARD - ALL 44 LIVE BODIES, EVERY RUN, ONE VERDICT.

WHY THIS EXISTS. On 21 Nov the census found that three bodies (ratcatcher,
pitman, paviser) were still shot on the OLD world-fixed rig: one coloured lamp
behind, no floor. They were repaired per body, and `minibossfit.py` now
defaults EVENLIGHT=1 / GROUND=1 so a NEW body cannot be born wrong. What that
leaves open is DRIFT: a body re-rendered later with `--worldlight` or
`--noground`, by hand or by a stale command line, goes back to the old look and
nothing says so. The team lead asked for one sweep that re-reads all 44 after
any per-body pass. This is it. It reads the shipped PNGs - no Blender, no
re-render, a couple of seconds.

WHAT IT ASSERTS, per body, on the three shipped views:
  ARM 1 - EVEN LIGHT. back/side chromaticity distance from the FRONT view
          (`_backlamp.dist_from_front`) is at or under BACK_MAX / SIDE_MAX.
          The old rig leaves one coloured lamp behind, so the back view's
          colour swings away from the front's; the even rig carries key, fill
          and rim round with the camera and all three views agree.
  ARM 2 - A FLOOR. every view composites at least GROUND_MIN ground pixels.
          A body standing on nothing is the other half of the old rig.

*** THE THRESHOLDS ARE MEASURED, NOT CHOSEN, AND THE MARGINS ARE PUBLISHED. ***
Measured 21 Nov 2026 over all 44 live bodies plus the two known OLD-RIG bodies
still on disk:
    worst live back distance   boiler        0.11890
    lowest old-rig back dist   sealer_ctl13  0.19374   (beadle_world 0.20386)
    BACK_MAX = 0.1550          +30% over the worst live, -20% under the lowest
                               known old-rig body.
    lowest live ground count   relief back   1405 px
    old-rig ground count       0 px on every view of both
    GROUND_MIN = 300           4.7x under the lowest live, and the thing it
                               separates is a count of ZERO.

*** AND THE REASON BOILER AND GREENER SIT HIGH IS NOT A LAMP - I LOOKED. ***
`_backlamp_look.png` (committed beside this) is front/side/back for boiler,
greener, snuffer, a low control (dyer) and both arms of the A/B. In
`beadle_world` the whole back view turns warm brass against a cool front: that
is a cast and you can see it across every material at once. In boiler and
greener the light is the same neutral in all three views; what changes is WHAT
IS FACING THE CAMERA - boiler's big pale vessel and greener's teal plants cover
different fractions of the frame from behind, which moves a MEAN chromaticity
without any lamp moving. The statistic cannot tell a cast from a change of mix,
so the bar is set above the worst honest body and the picture is the reason it
is allowed to be.

*** AN ATTEMPT I THREW AWAY, AND IT WOULD HAVE BEEN THE BETTER INSTRUMENT. ***
A cast moves every material; a change of mix moves none of them. So I built a
statistic that should separate the two: quantize chroma into a 64x64 histogram,
and for each back pixel measure the distance to the nearest OCCUPIED FRONT bin
- a re-weighting scores ~0 because every back material is in the front palette,
a cast scores the size of the cast. **IT FAILED ITS OWN CALIBRATION.**
beadle_world 0.01242 vs beadle_even 0.00862 is a 1.4x separation, and boiler
(0.01020, a body I have looked at and know is clean) lands BETWEEN THE TWO ARMS
OF A KNOWN A/B. With many materials the front palette covers chroma space
densely enough to absorb a cast. An instrument that puts a known-good body
inside a known A/B is not an instrument, so it is not in this file.
A second attempt - the smallest per-luminance-band chroma delta, five bands -
DOES rank both old-rig bodies above all 44 (sealer_ctl13 0.0810, beadle_world
0.0726, worst live greener 0.0521) but separates 1.39x where the plain mean
separates 1.63x. It is published per body as `band_floor`, as a second opinion
for a reader, and IT DECIDES NOTHING. One deciding arm, measured margins.

*** RED ON EMPTY, FOUR WAYS. *** A guard that reads nothing must never read
green: (a) zero bodies audited is VOID; (b) the roster is taken from TWO
independent authorities - `minibosses.ORDER` parsed out of the source, and the
non-retired rows of `_fit_report.json` - and they must agree exactly, or VOID;
(c) a missing or blank view is RED, not a clean zero; (d) THE RED ARM IS FIRED
ON EVERY RUN - beadle_world must FAIL both arms and beadle_even must PASS both,
on the same pass, with the same code. If the calibration pair is absent or does
not split, the verdict is VOID and no body is called green.

    python3 tools/art/_backlamp_guard.py            # verdict to stdout
    python3 tools/art/_backlamp_guard.py --json ... # write the report
"""
import json, os, re, sys

import numpy as np
# --- PNG READER WITH A FALLBACK, ADDED 21 NOV 2026 12:5x CT BY THE ART LANE ---
# THE FAULT THIS FIXES IS MY OWN GATE FAILING CLOSED WITHOUT SAYING SO.
# renders/art/minibosses/_tither_guard.log, committed beside the 45th body,
# reads `RC=0` on the wrapper and then
#     ModuleNotFoundError: No module named 'PIL'
# because the guard was launched through BLENDER, and Blender ships numpy and
# NOT PIL - the exact constraint this lane's own charter states in capitals.
# So the second art gate did not fail red and did not fail green: it did not
# RUN, and the wrapper's RC=0 made that look like a pass to anyone reading the
# log tail. An instrument that cannot run is not a pass, and one that cannot
# run while printing RC=0 is worse than one that is missing.
# The shim below gives the same `Image.open(p).convert("RGBA")` surface off
# bpy when PIL is absent, so the guard now runs under BOTH interpreters and
# the RGBA bytes are identical either way (bpy pixels are float 0..1 in
# bottom-up scanline order and are flipped and scaled back to uint8 here).
try:
    from PIL import Image                                    # noqa: F401
except ModuleNotFoundError:                                  # pragma: no cover
    import numpy as _np

    class _BpyRGBA(object):
        def __init__(self, arr):
            self._a = arr

        def convert(self, mode="RGBA"):
            if mode != "RGBA":
                raise ValueError("_BpyRGBA only serves RGBA, asked for %s" % mode)
            return self

        def __array__(self, dtype=None):
            return self._a if dtype is None else self._a.astype(dtype)

    class Image(object):
        @staticmethod
        def open(path):
            import bpy
            img = bpy.data.images.load(str(path), check_existing=False)
            try:
                w, h = img.size
                buf = _np.empty(w * h * 4, dtype=_np.float32)
                img.pixels.foreach_get(buf)
                a = buf.reshape(h, w, 4)[::-1]          # bpy is bottom-up
                return _BpyRGBA((_np.clip(a, 0.0, 1.0) * 255.0 + 0.5)
                                .astype(_np.uint8))
            finally:
                bpy.data.images.remove(img)

_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, _HERE)
import _backlamp as BL                                           # noqa: E402

W5 = os.path.dirname(os.path.dirname(_HERE))
ROOT = BL.ROOT
SRC = os.path.join(_HERE, "minibosses.py")
FIT = os.path.join(ROOT, "_fit_report.json")

BACK_MAX = 0.1550
SIDE_MAX = 0.1550
GROUND_MIN = 300
CAL_BAD = "beadle_world"      # old world-fixed rig, same body, same everything
CAL_GOOD = "beadle_even"      # even rig


def roster():
    """TWO AUTHORITIES. A single regex over one file is how three seats in this
    house have published a wrong constant; if the two disagree the run is VOID
    rather than quietly taking whichever came first."""
    src = open(SRC, encoding="utf-8", errors="replace").read()
    order = []
    for m in re.finditer(r"^ORDER\s*=\s*(?:ORDER\s*\+\s*)?(\[[^\]]*\])\s*$",
                         src, re.M):
        order += [x.strip().strip('"\'') for x in
                  m.group(1)[1:-1].split(",") if x.strip()]
    live_fit = None
    if os.path.exists(FIT):
        try:
            pairs = json.load(open(FIT, encoding="utf-8"))["pairs"]
            live_fit = sorted(k for k in pairs if not k.endswith("_chibi"))
        except Exception:
            live_fit = None
    return order, live_fit


def band_floor(key, n=5):
    """SECOND OPINION, DECIDES NOTHING. Smallest per-luminance-band chroma
    delta between back and front. A cast floors every band; a change of mix
    leaves at least one band near zero."""
    def bands(p):
        a = np.asarray(Image.open(p).convert("RGBA")).astype(np.float64) / 255.0
        rgb, al = a[..., :3], a[..., 3]
        c = rgb[al > 0.9]
        if c.size == 0:
            return None
        s = c.sum(axis=1)
        ok = s > 0.06
        c, s = c[ok], s[ok]
        if len(s) < 500:
            return None
        ch = c / s[:, None]
        lum = s / 3.0
        qs = np.quantile(lum, np.linspace(0, 1, n + 1))
        out = []
        for i in range(n):
            m = (lum >= qs[i]) & (lum <= qs[i + 1])
            out.append(ch[m][:, :2].mean(axis=0) if m.sum() > 50 else None)
        return out
    try:
        f = bands(os.path.join(ROOT, key, "hero_front.png"))
        b = bands(os.path.join(ROOT, key, "hero_back.png"))
    except Exception:
        return None
    if not f or not b:
        return None
    d = [float(np.abs(bb - ff).sum()) for ff, bb in zip(f, b)
         if ff is not None and bb is not None]
    return round(min(d), 5) if len(d) == n else None


def judge(key):
    """One body, three views, both arms. Faults are NAMED, not counted."""
    row = BL.body(key)
    faults = list(row["errors"])          # missing / blank views come through
    out = {"key": key, "faults": faults, "views": {}}
    for tag in ("front", "side", "back"):
        v = row["views"].get(tag)
        if not v or v.get("missing") or v.get("blank"):
            if not faults:
                faults.append("%s: no view on disk" % tag)
            out["views"][tag] = {"ok": False}
            continue
        d = v.get("dist_from_front")
        g = v.get("ground_px", 0)
        cap = 0.0 if tag == "front" else (SIDE_MAX if tag == "side" else BACK_MAX)
        lit_ok = True if tag == "front" else (d is not None and d <= cap)
        gnd_ok = g >= GROUND_MIN
        if not lit_ok:
            faults.append("%s: chroma %.5f from front, over %.4f - reads as a "
                          "second lamp, not the even rig" % (tag, d, cap))
        if not gnd_ok:
            faults.append("%s: %d ground px, under %d - this body stands on "
                          "nothing" % (tag, g, GROUND_MIN))
        out["views"][tag] = {"dist_from_front": d, "ground_px": g,
                             "lit_ok": lit_ok, "gnd_ok": gnd_ok,
                             "ok": lit_ok and gnd_ok}
    out["band_floor"] = band_floor(key)
    vs = [v for v in out["views"].values() if "lit_ok" in v]
    out["lit_ok"] = bool(vs) and all(v["lit_ok"] for v in vs)
    out["gnd_ok"] = bool(vs) and all(v["gnd_ok"] for v in vs)
    out["ok"] = not faults
    return out


def main():
    rep = {"thresholds": {"back_max": BACK_MAX, "side_max": SIDE_MAX,
                          "ground_min": GROUND_MIN},
           "errors": [], "bodies": [], "verdict": None, "ok": False}
    order, live_fit = roster()
    rep["roster"] = {"from_source": len(order),
                     "from_fit_report": (len(live_fit) if live_fit else None)}
    if not order:
        rep["errors"].append("VOID: the roster parse returned ZERO bodies. A "
                             "guard that audits nothing is not green.")
    if live_fit is not None and sorted(order) != live_fit:
        rep["errors"].append(
            "VOID: the two roster authorities disagree - source has %d, the fit "
            "register has %d live rows; only-in-source %s, only-in-register %s"
            % (len(order), len(live_fit), sorted(set(order) - set(live_fit)),
               sorted(set(live_fit) - set(order))))
    elif live_fit is None:
        rep["errors"].append("VOID: _fit_report.json unreadable - the roster "
                             "has only one authority this run.")

    # *** THE RED ARM, FIRED BEFORE ANY BODY IS BELIEVED - AND FIRED PER ARM.
    # My first build of this calibrated the WHOLE verdict on the pair and read
    # VOID on its first run, correctly: `beadle_even` is an even-LIGHT body
    # with NO FLOOR (it was shot before --ground existed, as _backlamp's own
    # ground_px docstring says). So the pair proves ARM 1 and cannot prove the
    # green side of ARM 2. Each arm is now calibrated on evidence that exists:
    #   ARM 1 - the A/B pair, same body both ways: bad must FAIL the light
    #           test, good must PASS it.
    #   ARM 2 - the red side is the same pair (both are floorless, 0 px, so a
    #           no-floor body MUST fire the arm); the green side is the live
    #           population's own minimum, which must clear GROUND_MIN with
    #           room - asserted below, after the bodies are read.
    cal = {}
    for k, want_lit in ((CAL_BAD, False), (CAL_GOOD, True)):
        if not os.path.isdir(os.path.join(ROOT, k)):
            rep["errors"].append("VOID: calibration body %s is not on disk - "
                                 "the arm cannot be fired, so nothing is green."
                                 % k)
            cal[k] = None
            continue
        j = judge(k)
        cal[k] = {"lit_ok": j["lit_ok"], "gnd_ok": j["gnd_ok"],
                  "back": j["views"].get("back", {}),
                  "band_floor": j["band_floor"], "faults": j["faults"]}
        if j["lit_ok"] != want_lit:
            rep["errors"].append(
                "VOID: ARM 1 calibration failed - %s should have come out %s on "
                "the light test and came out %s. An instrument that cannot tell "
                "the two arms of a known A/B apart is not an instrument."
                % (k, "PASS" if want_lit else "FAIL",
                   "PASS" if j["lit_ok"] else "FAIL"))
        if j["gnd_ok"]:
            rep["errors"].append(
                "VOID: ARM 2 red side failed - %s has no floor and the ground "
                "arm did not fire on it. An arm that cannot go red is not an arm."
                % k)
    rep["calibration"] = cal

    for k in order:
        rep["bodies"].append(judge(k))
    red = [b["key"] for b in rep["bodies"] if not b["ok"]]
    rep["red"] = red
    rep["audited"] = len(rep["bodies"])
    if rep["audited"] == 0:
        rep["errors"].append("VOID: zero bodies audited.")
    worst = [(b["views"].get("back", {}).get("dist_from_front") or 0, b["key"])
             for b in rep["bodies"]]
    worst.sort(reverse=True)
    rep["worst_back"] = [{"key": k, "dist": d} for d, k in worst[:5]]
    rep["margin"] = {
        "worst_live_back": (worst[0][0] if worst else None),
        "headroom_to_back_max": (round(BACK_MAX - worst[0][0], 5) if worst else None),
        "cal_bad_back": (cal.get(CAL_BAD) or {}).get("back", {}).get("dist_from_front"),
        "cal_good_back": (cal.get(CAL_GOOD) or {}).get("back", {}).get("dist_from_front")}
    # ARM 2, GREEN SIDE: the live population's own floor minimum must clear
    # the bar with room, or the threshold is sitting on top of the data and
    # the arm is one re-render away from firing on an honest body.
    gmins = [min((v.get("ground_px") or 0) for v in b["views"].values()
                 if "ground_px" in v)
             for b in rep["bodies"] if b["views"]]
    rep["ground_min_live"] = (min(gmins) if gmins else None)
    if rep["ground_min_live"] is not None and not red:
        if rep["ground_min_live"] < GROUND_MIN * 2:
            rep["errors"].append(
                "VOID: ARM 2 green side is too tight - the lowest live ground "
                "count is %d against a bar of %d. Re-measure the bar."
                % (rep["ground_min_live"], GROUND_MIN))
    rep["ok"] = (not rep["errors"]) and (not red) and rep["audited"] > 0
    rep["verdict"] = ("VOID" if rep["errors"] and not red else
                      ("GREEN" if rep["ok"] else "RED"))
    if rep["errors"]:
        rep["verdict"] = "VOID"
    return rep


if __name__ == "__main__":
    out = None
    if "--json" in sys.argv:
        out = sys.argv[sys.argv.index("--json") + 1]
    r = main()
    if out:
        os.makedirs(os.path.dirname(out), exist_ok=True)
        json.dump(r, open(out, "w"), indent=1)
    print("BACKLAMP_GUARD %s  audited=%d  red=%s  errors=%d"
          % (r["verdict"], r["audited"], r["red"], len(r["errors"])))
    for e in r["errors"]:
        print("  ERR", e)
    for b in r["bodies"]:
        if not b["ok"]:
            for f in b["faults"]:
                print("  RED %s: %s" % (b["key"], f))
    m = r["margin"]
    print("  worst live back %.5f (cap %.4f, headroom %.5f); calibration "
          "bad=%.5f good=%.5f"
          % (m["worst_live_back"], BACK_MAX, m["headroom_to_back_max"],
             m["cal_bad_back"] or -1, m["cal_good_back"] or -1))
    sys.exit(0 if r["ok"] else 1)
