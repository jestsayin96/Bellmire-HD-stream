"""_crew_face.py - does the Rammer's crew figure have a FACING at stream distance?

THE BEADLE TAUGHT THIS. There the team lead found, by looking, that a pale band
wrapping the head read the same from front and back - the figure had no facing -
and every number in the register passed. So the crew figure gets asked the same
question with a number that can go red: in the operator's own head box, how many
pixels does the VIEWER see that are bright enough to read as goggles, from the
front and from the back?

It counts the near-white disc pixels inside the head box of the SHIPPED renders.
RED when: a box is empty of body pixels (the box is wrong), or the front count is
zero (no face to see at all). The finding is the DIFFERENCE: a figure with facing
shows the discs from one side and not the other.

WHAT IT CANNOT SEE: it is one threshold on one pair of renders at one distance.
It cannot tell a goggle from any other near-white chip, and it says nothing about
the side view. The picture is still the evidence; this only makes the claim movable.
"""
import sys
import numpy as np
from PIL import Image

BOXES = {  # x0, y0, x1, y1 - the operator's head in each shipped render
    "front": ("renders/art/minibosses/rammer/hero_front.png", (545, 240, 660, 340)),
    "back":  ("renders/art/minibosses/rammer/hero_back.png",  (105, 260, 220, 360)),
}
ERRORS = []

def read(path, box):
    im = np.array(Image.open(path).convert("RGBA")).astype(np.int16)
    x0, y0, x1, y1 = box
    crop = im[y0:y1, x0:x1]
    a = crop[..., 3] > 8
    if a.sum() < 200:
        ERRORS.append(f"{path}: only {int(a.sum())} opaque px in the head box - box is wrong")
        return None
    R, G, B = crop[..., 0], crop[..., 1], crop[..., 2]
    bright = a & (R > 195) & (G > 195) & (B > 185)
    return {"opaque_px": int(a.sum()), "bright_px": int(bright.sum()),
            "bright_frac": round(float(bright.sum()) / float(a.sum()), 4)}

if __name__ == "__main__":
    out = {}
    for k, (p, b) in BOXES.items():
        out[k] = read(p, b)
    if out.get("front") and out["front"]["bright_px"] == 0:
        ERRORS.append("front: ZERO bright pixels - the figure has no visible face from the front")
    if out.get("front") and out.get("back"):
        out["delta_bright_px"] = out["front"]["bright_px"] - out["back"]["bright_px"]
        out["reads_as_facing"] = bool(out["delta_bright_px"] > 50)
    out["errors"] = ERRORS
    out["verdict"] = "RED" if ERRORS else "GREEN"
    import json; print(json.dumps(out, indent=2))
    sys.exit(1 if ERRORS else 0)
