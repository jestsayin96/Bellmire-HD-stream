"""THE RATCATCHER FRAME FIX, 20 Nov 2026 23:4x CT.

Two keys only, and they are the only two the new MARGIN_X can bite:
ratcatcher pair_w 5.59 and boiler 5.51 are the only rows in the register wider
than FRAME_W - MARGIN_X = 5.48. Everything else already has its air.
Rendered one key per subprocess, exactly as instalment 5's adoption pass did,
with the same --evenlight --ground so the two cells stay comparable with the
other 42. The sheet pass afterwards is NOT optional: a per-key run writes
_hero_scale.png out of its own keys alone, which is why the master sheet on
disk is a THREE-cell remnant of the last instalment-5 subprocess.
"""
import os, sys, json, subprocess, time
W5 = r"C:\hd adventure\bellmire-art"
BLENDER = r"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"
FIT = os.path.join(W5, "tools", "art", "minibossfit.py")
KEYS = ["ratcatcher", "boiler"]
out = []
for key in KEYS:
    t0 = time.time()
    p = subprocess.run([BLENDER, "-b", "-noaudio", "-P", FIT, "--",
                        "--repo", W5, "--only", key, "--evenlight", "--ground"],
                       capture_output=True, text=True, timeout=1800)
    row = {"key": key, "rc": p.returncode, "secs": round(time.time() - t0, 1)}
    tail = [l for l in p.stdout.splitlines() if l.startswith("MINIBOSSFIT_REPORT")]
    if tail:
        r = json.loads(tail[-1].split("MINIBOSSFIT_REPORT", 1)[1])
        row.update(verdict=r.get("verdict"), errors=r.get("errors"),
                   blind=r.get("blind_views"), blank=r.get("blank"),
                   rows_judged=r.get("rows_judged"), rendered=r.get("rendered"),
                   ratio=r.get("ratios", {}).get(key))
    else:
        row["stderr_tail"] = p.stderr[-900:]
    print("MF|", json.dumps(row)); sys.stdout.flush()
    out.append(row)
# the master sheet, rebuilt over all 44 - no --only, --sheet skips rendering
t0 = time.time()
p = subprocess.run([BLENDER, "-b", "-noaudio", "-P", FIT, "--",
                    "--repo", W5, "--sheet"],
                   capture_output=True, text=True, timeout=1800)
tail = [l for l in p.stdout.splitlines() if l.startswith("MINIBOSSFIT_REPORT")]
row = {"key": "_SHEET_ALL_44", "rc": p.returncode, "secs": round(time.time()-t0,1)}
if tail:
    r = json.loads(tail[-1].split("MINIBOSSFIT_REPORT", 1)[1])
    row.update(verdict=r.get("verdict"), errors=r.get("errors")[:6],
               blind=r.get("blind_views")[:4], blank=r.get("blank"),
               rows_judged=r.get("rows_judged"), rendered=r.get("rendered"),
               stale_margin=r.get("stale_margin"))
else:
    row["stderr_tail"] = p.stderr[-900:]
print("MF|", json.dumps(row)); sys.stdout.flush()
print("MF_DONE")
