# EVEN-LIGHT PROBE. For a body whose authoring light is UNKNOWN, answer the
# question with pixels rather than a date: re-render it with --evenlight into a
# TAG directory (nothing shipped is touched) and diff each view against the
# shipped one. 0 differing pixels => the shipped view was ALREADY even-lit.
# A large diff => it was not. The instrument must be able to return both.
import os, sys, json, subprocess, time
import numpy as np
import bpy

W5 = r"C:\hd adventure\bellmire-art"
BLENDER = r"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"
FIT = os.path.join(W5, "tools", "art", "minibossfit.py")
MBROOT = os.path.join(W5, "renders", "art", "minibosses")
VIEWS = ("hero_front.png", "hero_side.png", "hero_back.png")
TAG = "_p4probe"
KEYS = sys.argv[sys.argv.index("--") + 1].split(",") if "--" in sys.argv else []

def say(*a):
    print("ELP|", *a); sys.stdout.flush()

def load_rgba(path):
    img = bpy.data.images.load(path, check_existing=False)
    img.colorspace_settings.name = 'Non-Color'
    w, h = img.size
    px = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(px)
    bpy.data.images.remove(img)
    return (px.reshape(h, w, 4) * 255.0).round().astype(np.int16)

out = {"probe": "evenlight", "keys": [], "errors": []}
for key in KEYS:
    row = {"key": key}
    t0 = time.time()
    p = subprocess.run([BLENDER, "-b", "-noaudio", "-P", FIT, "--",
                        "--repo", W5, "--only", key, "--evenlight", "--tag", TAG],
                       capture_output=True, text=True, timeout=1800)
    row["rc"] = p.returncode; row["secs"] = round(time.time() - t0, 1)
    if p.returncode != 0:
        row["stderr_tail"] = p.stderr[-400:]
        out["errors"].append(key); out["keys"].append(row); say(json.dumps(row)); continue
    ship = os.path.join(MBROOT, key)
    prob = os.path.join(MBROOT, key + TAG)
    d = {}
    for v in VIEWS:
        a_p, b_p = os.path.join(ship, v), os.path.join(prob, v)
        if not (os.path.isfile(a_p) and os.path.isfile(b_p)):
            d[v] = "MISSING"; continue
        a, b = load_rgba(a_p), load_rgba(b_p)
        if a.shape != b.shape:
            d[v] = "SHAPE %s vs %s" % (a.shape, b.shape); continue
        m = np.abs(a - b).max(axis=2)
        d[v.replace("hero_","").replace(".png","")] = [int((m > 0).sum()), int((m > 2).sum())]
    row["diff_vs_shipped"] = d
    out["keys"].append(row); say(json.dumps(row))

with open(os.path.join(W5, "_el_probe_report.json"), "w") as f:
    json.dump(out, f, indent=1)
say("==DONE==")
