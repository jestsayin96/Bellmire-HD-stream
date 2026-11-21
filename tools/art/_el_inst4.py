# EVEN LIGHT, INSTALMENT 4 - driver. Runs as `blender -b -noaudio -P this`.
# Per body: snapshot the three shipped hero views, re-render all three with
# --evenlight, then count the pixels that MOVED, per view, with numpy.
# A view whose diff is 0 was ALREADY even-lit and is reported as such - the
# instrument must be able to say "nothing changed" or it proves nothing.
import os, sys, json, shutil, subprocess, time
import numpy as np
import bpy

W5 = r"C:\hd adventure\bellmire-art"
BLENDER = r"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"
FIT = os.path.join(W5, "tools", "art", "minibossfit.py")
MBROOT = os.path.join(W5, "renders", "art", "minibosses")
BEFORE = os.path.join(W5, "_scratch", "_el_inst4_before")
VIEWS = ("hero_front.png", "hero_side.png", "hero_back.png")
KEYS = sys.argv[sys.argv.index("--") + 1].split(",") if "--" in sys.argv else []

def say(*a):
    print("EL4|", *a); sys.stdout.flush()

def load_rgba(path):
    img = bpy.data.images.load(path, check_existing=False)
    img.colorspace_settings.name = 'Non-Color'
    w, h = img.size
    px = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(px)
    bpy.data.images.remove(img)
    return (px.reshape(h, w, 4) * 255.0).round().astype(np.int16)

def diffcount(a, b):
    if a.shape != b.shape:
        return -1, -1
    d = np.abs(a - b).max(axis=2)
    return int((d > 0).sum()), int((d > 2).sum())

report = {"instalment": 4, "keys": [], "errors": []}
os.makedirs(BEFORE, exist_ok=True)

for key in KEYS:
    row = {"key": key}
    kdir = os.path.join(MBROOT, key)
    bdir = os.path.join(BEFORE, key)
    os.makedirs(bdir, exist_ok=True)
    missing = [v for v in VIEWS if not os.path.isfile(os.path.join(kdir, v))]
    if missing:
        row["skipped"] = "missing views: %s" % missing
        report["keys"].append(row); report["errors"].append(row["skipped"]); continue
    for v in VIEWS:
        shutil.copy2(os.path.join(kdir, v), os.path.join(bdir, v))
    t0 = time.time()
    p = subprocess.run([BLENDER, "-b", "-noaudio", "-P", FIT, "--",
                        "--repo", W5, "--only", key, "--evenlight"],
                       capture_output=True, text=True, timeout=1800)
    row["rc"] = p.returncode
    row["secs"] = round(time.time() - t0, 1)
    tail = [l for l in p.stdout.splitlines() if l.startswith("MINIBOSSFIT_REPORT")]
    if tail:
        try:
            r = json.loads(tail[-1].split("MINIBOSSFIT_REPORT", 1)[1])
            row["verdict"] = r.get("verdict"); row["fit_errors"] = r.get("errors")
            row["blind_views"] = r.get("blind_views"); row["blank"] = r.get("blank")
            row["ratios"] = r.get("ratios"); row["proving"] = r.get("proving")
        except Exception as e:
            row["parse_err"] = str(e)
    else:
        row["parse_err"] = "no MINIBOSSFIT_REPORT line"
        row["stderr_tail"] = p.stderr[-400:]
    if p.returncode == 0:
        moved = {}
        for v in VIEWS:
            try:
                a = load_rgba(os.path.join(bdir, v))
                b = load_rgba(os.path.join(kdir, v))
                moved[v.replace("hero_", "").replace(".png", "")] = diffcount(a, b)
            except Exception as e:
                moved[v] = "ERR %s" % e
        row["moved_px"] = moved
    say(json.dumps(row))
    report["keys"].append(row)

with open(os.path.join(W5, "_el_inst4_report.json"), "w") as f:
    json.dump(report, f, indent=1)
say("==DONE==")
