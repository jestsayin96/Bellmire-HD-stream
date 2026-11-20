"""_bg_frame_ab.py - DID THE EAR TURN CAUSE THE FRAME CLIP, OR WAS IT ALREADY THERE?

The pass-3 fit reported frame_edge front {left 228, right 20} where the
committed pass-2 register recorded zeros on every edge. The ear turn only ever
makes the creature NARROWER in x, so blaming it is a guess. This runs the same
pipeline twice in one process - ears off, then ears on - and prints both
frame_edge dicts, so the charge lands where the measurement says.

  blender -b -noaudio -P tools/art/_bg_frame_ab.py -- --repo <W5>
"""
import bpy, sys, os, json

argv = sys.argv[sys.argv.index("--")+1:]
repo = argv[argv.index("--repo")+1]
sys.path.append(os.path.join(repo, "tools", "art"))
import monstervariants as MV

out = {}
for tag, pitch, yaw in (("ears_off", 0.0, 0.0), ("ears_on", 40.0, 45.0)):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    MV.VARIANTS["broodglut"]["ear_pitch_deg"] = pitch
    MV.VARIANTS["broodglut"]["ear_yaw_deg"] = yaw
    rec = MV.fit("broodglut", repo)
    if isinstance(rec, tuple):
        rec = rec[0]
    out[tag] = {k: rec.get(k) for k in
                ("frame_edge", "fits_frame", "pair_w", "span_x", "span_y",
                 "creature_h", "frame_w", "frame_h", "blanks", "errors")}
    print("AB", tag, json.dumps(out[tag].get("frame_edge")),
          "fits", out[tag].get("fits_frame"), "pair_w", out[tag].get("pair_w"))

with open(os.path.join(repo, "renders", "art", "variants", "_frame_ab.json"),
          "w", encoding="utf-8") as f:
    json.dump(out, f, indent=1)
