"""Instalment 5 adoption pass: --evenlight --ground over the whole 44.

Why all 44 and not the 18 still on the old light: a contact sheet where some
cells have a floor and some do not is worse than either. The 26 already even-lit
change ONLY by gaining a shadow; the 18 change by both, and the two are
separable in the numbers - a ground pixel is new alpha where the control had
none, an even-light pixel is a changed pixel where alpha was already opaque.

Each body is judged on its own: verdict, errors, blind_views, blank check, and
the per-view ground row, which is RED ON EMPTY by construction.
"""
import os, sys, json, subprocess, time
W5 = r"C:\hd adventure\bellmire-art"
BLENDER = r"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"
FIT = os.path.join(W5, "tools", "art", "minibossfit.py")
MB = os.path.join(W5, "renders", "art", "minibosses")
KEYS = sys.argv[sys.argv.index("--") + 1].split(",")

report = {"instalment": 5, "pass": "adoption", "keys": [], "errors": []}
for key in KEYS:
    t0 = time.time()
    p = subprocess.run([BLENDER, "-b", "-noaudio", "-P", FIT, "--",
                        "--repo", W5, "--only", key, "--evenlight", "--ground"],
                       capture_output=True, text=True, timeout=1800)
    row = {"key": key, "rc": p.returncode, "secs": round(time.time() - t0, 1)}
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
        row["stderr_tail"] = p.stderr[-400:]
    if row.get("verdict") != "GREEN" or row["rc"] != 0:
        report["errors"].append(key)
    print("I5|", json.dumps(row)); sys.stdout.flush()
    report["keys"].append(row)

reg = os.path.join(MB, "_fit_report.json")
try:
    with open(reg) as f:
        R = json.load(f)
    g = {}
    for k, v in R.get("pairs", {}).items():
        gr = v.get("ground")
        if gr:
            g[k] = {vw: {"shadow_px": r["shadow_px"], "max": r["max"],
                         "rim": r.get("rim_filled_px"), "error": r["error"],
                         "edge": r.get("shadow_edge")} for vw, r in gr.items()}
    report["ground"] = g
    report["ground_bodies"] = len(g)
    report["ground_errors"] = [k for k, vv in g.items()
                               for vw, r in vv.items() if r["error"]]
    report["no_shadow_views"] = [(k, vw) for k, vv in g.items()
                                 for vw, r in vv.items() if r["shadow_px"] == 0]
except Exception as e:
    report["errors"].append("register: %s" % e)

with open(os.path.join(W5, "_el_inst5_batch.json"), "w") as f:
    json.dump(report, f, indent=1)
print("I5| ==DONE==", json.dumps({"errors": report["errors"],
      "ground_bodies": report.get("ground_bodies"),
      "ground_errors": report.get("ground_errors"),
      "no_shadow_views": report.get("no_shadow_views")}))
