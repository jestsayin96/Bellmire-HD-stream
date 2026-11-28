"""
_tiergate.py - THE TIER RICHNESS GATE. Standalone. No Blender required to RUN it.

WHY THIS FILE IS SEPARATE FROM townlib.py
-----------------------------------------
townlib.py, townbuildgen.py and hallgen.py were modified at 07:34 CT on 28 Nov
and HAVE NEVER BEEN RUN (the Blender bridge has been down since 01:34). Adding a
gate INTO townlib.py would stack a fourth unrun change on three unrun changes and
make the first failure impossible to attribute. This file is standalone and was
RUN and RED/GREEN-proved on the two shipped sheets the hour it was written.
Fold it into townlib.py on the first run with a live bridge, AFTER the three
existing generators have been run once.

WHY IT DOES NOT IMPORT PIL
--------------------------
There is no system Python on cruzader, and Blender there has numpy but NO PIL.
A gate that only runs under PIL is a gate that cannot run on the machine that
makes the renders. `load_rgb` therefore tries PIL first (dev box / container)
and falls back to bpy.data.images (cruzader), reading Non-Color so sRGB bytes
round-trip.

WHAT THIS GATE CANNOT SEE - SAID BEFORE THE NUMBERS
---------------------------------------------------
  - WHETHER THE SUBJECT IS THE RIGHT SUBJECT. It measures the pixels inside the
    span it is given. A span containing the wrong building, or the hero, scores
    normally. Spans are supplied by the caller and are not verified.
  - OCCLUSION. This is the fault that motivated the file. A tier can carry plenty
    of bronze and still read flat because the geometry above it casts the bronze
    into shadow or hides it. `warm_frac` counts the bronze it can SEE, so it
    reports the symptom correctly and says NOTHING about the cause. A RED here
    means "the top tier does not read rich", never "the top tier lacks material".
    DO NOT let a RED send you straight to the material. LOOK AT THE PICTURE.
  - SHAPE, silhouette, proportion, or whether the tier is the right object.
  - Anything at a scale finer than the sheet's own resolution. A detail that
    reads at 4x zoom and vanishes at sheet scale is correctly scored as absent,
    because sheet scale is stream distance.
"""

import numpy as np

RED, GREEN = "RED", "GREEN"


def load_rgb(path):
    """float32 HxWx3 in 0..255. PIL where it exists, bpy on cruzader."""
    try:
        from PIL import Image
        return np.asarray(Image.open(path).convert("RGB")).astype(np.float32)
    except ImportError:
        import bpy
        img = bpy.data.images.load(path, check_existing=True)
        img.colorspace_settings.name = "Non-Color"   # sRGB bytes round-trip
        w, h = img.size
        buf = np.empty(w * h * 4, dtype=np.float32)
        img.pixels.foreach_get(buf)
        a = buf.reshape(h, w, 4)[::-1, :, :3] * 255.0   # bpy is bottom-up
        return np.ascontiguousarray(a)


def _metrics(a, x0, x1, bg_value=12.0):
    """chroma / warm / value over the SUBJECT pixels of one span."""
    sub = a[:, x0:x1]
    if sub.size == 0:
        return None                                   # RED ON EMPTY
    val = sub.mean(2)
    subject = val > bg_value
    n = int(subject.sum())
    if n == 0:
        return None                                   # RED ON EMPTY: no subject
    r, b = sub[:, :, 0], sub[:, :, 2]
    chroma = sub.max(2) - sub.min(2)
    warm = ((r - b) > 18) & (chroma > 20) & subject
    return {
        "subject_px": n,
        "chroma_mean": float(chroma[subject].mean()),
        "warm_frac": float(warm.sum()) / n,
        "value_mean": float(val[subject].mean()),
    }


def _ground_edges(a, x0, x1, y0, y1, thresh=6.0):
    """Edge incident in the ground annulus at a tier's foot.

    Paving stones make edges; bare ground does not. This is the ONE richness cue
    chroma is blind to, because paving is the same grey as the ground it sits on.
    """
    patch = a[y0:y1, x0:x1]
    if patch.size == 0 or patch.shape[0] < 2 or patch.shape[1] < 2:
        return None                                   # RED ON EMPTY
    g = patch.mean(2)
    gx = (np.abs(np.diff(g, axis=1)) > thresh).mean() * 100.0
    gy = (np.abs(np.diff(g, axis=0)) > thresh).mean() * 100.0
    return float(gx + gy)


def tier_material_gate(path, spans, order, ground_bands=None, verbose=True):
    """RED unless the TOP tier is the richest tier in its own ladder.

    spans:        {"t1": (x0, x1), ...}   explicit. Auto-segmentation was tried
                  and FAILS on these sheets - the hall's three tiers touch and
                  resolve as one run, 411..1302. Explicit crops are not laziness.
    order:        ["t1","t2","t3"] poorest -> richest, as DECLARED by the ladder.
    ground_bands: {"t1": (x0,x1,y0,y1), ...} optional; enables the paving check.
    """
    a = load_rgb(path)
    errors, rows = [], {}

    for name in order:
        if name not in spans:
            errors.append(f"{name}: NO SPAN GIVEN -> RED ON EMPTY")
            continue
        m = _metrics(a, *spans[name])
        if m is None:
            errors.append(f"{name}: span has NO SUBJECT PIXELS -> RED ON EMPTY")
            continue
        rows[name] = m

    if len(rows) < 2:
        return {"verdict": RED, "errors": errors or ["fewer than two measurable tiers"],
                "rows": rows}

    top = order[-1]
    if top in rows:
        tc = rows[top]["chroma_mean"]
        tw = rows[top]["warm_frac"]
        for other in order[:-1]:
            if other not in rows:
                continue
            if tc <= rows[other]["chroma_mean"]:
                errors.append(
                    f"TOP TIER NOT RICHEST: {top} chroma {tc:.1f} <= {other} "
                    f"{rows[other]['chroma_mean']:.1f}")
            if tw <= rows[other]["warm_frac"]:
                errors.append(
                    f"TOP TIER NOT WARMEST: {top} warm {tw*100:.2f}% <= {other} "
                    f"{rows[other]['warm_frac']*100:.2f}%")

    if ground_bands:
        gvals = {}
        for name in order:
            if name in ground_bands:
                e = _ground_edges(a, *ground_bands[name])
                if e is None:
                    errors.append(f"{name}: ground band EMPTY -> RED ON EMPTY")
                else:
                    gvals[name] = e
        if top in gvals:
            for other in order[:-1]:
                if other in gvals and gvals[top] < gvals[other]:
                    errors.append(
                        f"GROUND DRESSING REGRESSES: {top} edge {gvals[top]:.1f} "
                        f"< {other} {gvals[other]:.1f} - the prosperous tier has "
                        f"the barest ground")
        for k, v in gvals.items():
            rows.setdefault(k, {})["ground_edge"] = v

    verdict = RED if errors else GREEN
    if verbose:
        print(f"  verdict: {verdict}")
        for name in order:
            if name in rows:
                r = rows[name]
                print(f"    {name}: chroma {r.get('chroma_mean', float('nan')):6.2f}  "
                      f"warm {r.get('warm_frac', 0)*100:6.2f}%  "
                      f"ground_edge {r.get('ground_edge', float('nan')):6.2f}")
        for e in errors:
            print(f"    ! {e}")
    return {"verdict": verdict, "errors": errors, "rows": rows}


# ---------------------------------------------------------------- selftest
# Spans are explicit because AUTO-SEGMENTATION FAILS on these sheets: a column
# profile of the hall sheet resolves all three tiers as ONE run, 411..1302,
# because the buildings touch. Reproduced 28 Nov 09:38 CT before hardcoding.
WELL = "renders/art/town/_tiers_side_by_side.png"
HALL = "renders/art/town/hall/_tiers_side_by_side.png"

WELL_SPANS  = {"t1": (240, 520), "t2": (520, 840), "t3": (840, 1200)}
WELL_GROUND = {"t1": (250, 520, 455, 510), "t2": (545, 835, 470, 540),
               "t3": (860, 1200, 545, 605)}
HALL_SPANS  = {"t1": (400, 620), "t2": (620, 900), "t3": (900, 1320)}
HALL_GROUND = {"t1": (400, 620, 640, 690), "t2": (620, 900, 660, 710),
               "t3": (900, 1320, 680, 730)}

if __name__ == "__main__":
    import sys
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    print("[1] WELL ladder - KNOWN BAD, must be RED")
    r1 = tier_material_gate(f"{root}/{WELL}", WELL_SPANS, ["t1", "t2", "t3"],
                            ground_bands=WELL_GROUND)
    print("\n[2] HALL ladder - KNOWN GOOD, must be GREEN")
    r2 = tier_material_gate(f"{root}/{HALL}", HALL_SPANS, ["t1", "t2", "t3"],
                            ground_bands=HALL_GROUND)
    ok = r1["verdict"] == RED and r2["verdict"] == GREEN
    print("\nSELFTEST", "PASS" if ok else "FAIL")
    sys.exit(0 if ok else 1)
