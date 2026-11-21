"""_el_gc_ab - THE GROUND-CONTACT RIG FIX, A/B'D ON THE TWO BODIES THE TEAM
LEAD NAMED.

20 Nov 2026, instalment 5. Instalments 3 and 4 named ground contact five times
across four bodies and called it rig-level twice without fixing it. This is the
fix proved the only way this lane is allowed to prove anything: render the SAME
body twice with ONE flag different, count the pixels that moved, and look at
the picture.

CONTROL  = renders/art/minibosses/<key>/        (shipped, --evenlight, no floor)
TREATED  = renders/art/minibosses/<key>_gc/     (--evenlight --ground)

GOES RED ON EMPTY TWICE OVER:
  - a view whose diff is 0 means the flag did nothing and is reported as such;
  - the shadow instrument inside minibossfit reports an ERROR, not a zero, when
    the unoccluded floor render comes back empty.
"""
import os, sys, json, subprocess, time
import numpy as np
import bpy

W5 = r"C:\hd adventure\bellmire-art"
BLENDER = r"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"
FIT = os.path.join(W5, "tools", "art", "minibossfit.py")
MBROOT = os.path.join(W5, "renders", "art", "minibosses")
VIEWS = ("hero_front.png", "hero_side.png", "hero_back.png")
KEYS = sys.argv[sys.argv.index("--") + 1].split(",") if "--" in sys.argv else []


def say(*a):
    print("GC|", *a); sys.stdout.flush()


def load_rgba(path):
    img = bpy.data.images.load(path, check_existing=False)
    img.colorspace_settings.name = 'Non-Color'
    w, h = img.size
    px = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(px)
    bpy.data.images.remove(img)
    return (px.reshape(h, w, 4)[::-1] * 255.0).round().astype(np.int16)


report = {"instalment": 5, "what": "ground-contact rig fix A/B", "keys": [], "errors": []}

for key in KEYS:
    row = {"key": key}
    ctl = os.path.join(MBROOT, key)
    trt = os.path.join(MBROOT, key + "_gc")
    missing = [v for v in VIEWS if not os.path.isfile(os.path.join(ctl, v))]
    if missing:
        row["skipped"] = "control missing %s" % missing
        report["keys"].append(row); report["errors"].append(row["skipped"]); continue
    t0 = time.time()
    p = subprocess.run([BLENDER, "-b", "-noaudio", "-P", FIT, "--",
                        "--repo", W5, "--only", key, "--evenlight", "--ground",
                        "--tag", "_gc", "--name", "_gc13"],
                       capture_output=True, text=True, timeout=2400)
    row["rc"] = p.returncode
    row["secs"] = round(time.time() - t0, 1)
    tail = [l for l in p.stdout.splitlines() if l.startswith("MINIBOSSFIT_REPORT")]
    if tail:
        try:
            r = json.loads(tail[-1].split("MINIBOSSFIT_REPORT", 1)[1])
            row["verdict"] = r.get("verdict"); row["fit_errors"] = r.get("errors")
            row["blind_views"] = r.get("blind_views"); row["blank"] = r.get("blank")
        except Exception as e:
            row["parse_err"] = str(e)
    else:
        row["parse_err"] = "no MINIBOSSFIT_REPORT line"
        row["stdout_tail"] = p.stdout[-600:]
        row["stderr_tail"] = p.stderr[-600:]
    if p.returncode == 0:
        moved, alpha = {}, {}
        for v in VIEWS:
            cp, tp = os.path.join(ctl, v), os.path.join(trt, v)
            if not os.path.isfile(tp):
                moved[v] = "TREATED MISSING"; continue
            a, b = load_rgba(cp), load_rgba(tp)
            if a.shape != b.shape:
                moved[v] = "SHAPE %s vs %s" % (a.shape, b.shape); continue
            d = np.abs(a - b).max(axis=2)
            k = v.replace("hero_", "").replace(".png", "")
            moved[k] = [int((d > 0).sum()), int((d > 2).sum())]
            # the shadow is new ALPHA where there was none - count it directly
            new = (a[:, :, 3] <= 5) & (b[:, :, 3] > 5)
            alpha[k] = {"new_alpha_px": int(new.sum()),
                        "mean_new_alpha": round(float(b[:, :, 3][new].mean()), 2) if new.any() else 0.0,
                        "subject_px_touched": int(((a[:, :, 3] > 250) &
                                                   (np.abs(a - b).max(axis=2) > 2)).sum())}
        row["moved_px"] = moved
        row["shadow"] = alpha
    say(json.dumps(row))
    report["keys"].append(row)

gcreg = os.path.join(MBROOT, "_fit_gc13.json")
if os.path.isfile(gcreg):
    try:
        with open(gcreg) as f:
            reg = json.load(f)
        report["ground_rows"] = {k: v.get("ground") for k, v in reg.get("pairs", {}).items()}
    except Exception as e:
        report["errors"].append("register read: %s" % e)

with open(os.path.join(W5, "_el_gc_ab.json"), "w") as f:
    json.dump(report, f, indent=1)
say("==DONE==")
