"""_floorgeom_proof - THE RED ARMS for tools/art/floorgeom.py.

A gate's number is worth nothing until the gate has been MADE to fail on
purpose.  This builds throwaway copies of scripts/floorgen.gd in a temp tree
and asserts the reader moves, withholds, or errors as it should:

  A  as shipped      lid y 7.0  -> underside 6.50, corridor 11.0
  B  supervisor's    lid y 10.0 -> underside 9.50 and Broodglut turns UNDER-LID
  C  lid line gone              -> lid None, verdict WITHHELD, hard error
  D  lid y an expression        -> not-a-literal error, no guess
  E  HALL_W renamed             -> corridor WITHHELD (span verdict cannot be faked)
  F  two SHADOWS_ONLY anchors   -> ambiguous, errors, no number

Run:  python3 tools/art/_floorgeom_proof.py <repo>
"""
import os
import re
import shutil
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import floorgeom  # noqa: E402

BROOD = (10.4063, 6.60)      # span, height - the variant that went through it
LAST = (6.4807, 6.20)


def tree(src_repo, edit):
    d = tempfile.mkdtemp(prefix="floorgeom_")
    os.makedirs(os.path.join(d, "scripts"))
    p = os.path.join(d, floorgeom.GD_REL)
    with open(os.path.join(src_repo, floorgeom.GD_REL), encoding="utf-8") as f:
        txt = f.read()
    with open(p, "w", encoding="utf-8") as f:
        f.write(edit(txt))
    return d


def main():
    repo = sys.argv[1] if len(sys.argv) > 1 else "."
    fails = []

    def ck(name, cond, saw):
        print(("  PASS " if cond else "  FAIL ") + name + "   saw: " + str(saw))
        if not cond:
            fails.append(name)

    print("A  as shipped")
    g = floorgeom.read(repo)
    vb, eb = floorgeom.verdict(g, *BROOD)
    vl, el = floorgeom.verdict(g, *LAST)
    ck("A corridor 11.0 / lid 6.50, no errors",
       g["corridor_clear_m"] == 11.0 and g["lid_underside_m"] == 6.5 and not g["errors"],
       (g["corridor_clear_m"], g["lid_underside_m"], g["errors"]))
    ck("A broodglut THROUGH-LID by 0.10, corridor-safe",
       vb["lid"] == "THROUGH-LID" and vb["lid_clear_m"] == -0.1
       and vb["corridor"] == "CORRIDOR-SAFE" and vb["fits"] is False and not eb,
       (vb["lid"], vb["lid_clear_m"], vb["corridor"], vb["fits"]))
    ck("A lastcuff UNDER-LID by 0.30 and fits",
       vl["lid"] == "UNDER-LID" and vl["lid_clear_m"] == 0.3 and vl["fits"] is True and not el,
       (vl["lid"], vl["lid_clear_m"], vl["fits"]))

    print("B  supervisor's ruling: lid y 7.0 -> 10.0")
    d = tree(repo, lambda t: t.replace("lid.position = Vector3(0, 7.0, 0)",
                                       "lid.position = Vector3(0, 10.0, 0)"))
    g = floorgeom.read(d)
    vb, eb = floorgeom.verdict(g, *BROOD)
    ck("B underside 9.50 read, not 6.50", g["lid_underside_m"] == 9.5, g["lid_underside_m"])
    ck("B broodglut turns UNDER-LID with 2.90 clear",
       vb["lid"] == "UNDER-LID" and vb["lid_clear_m"] == 2.9 and vb["fits"] is True and not eb,
       (vb["lid"], vb["lid_clear_m"], vb["fits"]))
    shutil.rmtree(d, ignore_errors=True)

    print("C  the lid's position line deleted")
    d = tree(repo, lambda t: t.replace("    lid.position = Vector3(0, 7.0, 0)\n", ""))
    g = floorgeom.read(d)
    vb, eb = floorgeom.verdict(g, *BROOD)
    ck("C lid_underside_m is None, never a default",
       g["lid_underside_m"] is None and g["lid_y_m"] is None, g["lid_underside_m"])
    ck("C height verdict WITHHELD and a hard error is raised",
       vb["lid"] is None and vb["fits"] is False
       and any("lid underside" in e for e in eb), (vb["lid"], eb))
    ck("C the span verdict still works - one blind eye is not two",
       vb["corridor"] == "CORRIDOR-SAFE", vb["corridor"])
    shutil.rmtree(d, ignore_errors=True)

    print("D  lid y written as an expression")
    d = tree(repo, lambda t: t.replace("lid.position = Vector3(0, 7.0, 0)",
                                       "lid.position = Vector3(0, LID_Y + 1.0, 0)"))
    g = floorgeom.read(d)
    ck("D refuses to guess: lid None + not-a-literal error",
       g["lid_underside_m"] is None and any("not a plain literal" in e for e in g["errors"]),
       g["errors"])
    shutil.rmtree(d, ignore_errors=True)

    print("E  HALL_W renamed out from under the gate")
    d = tree(repo, lambda t: re.sub(r"^const HALL_W := 3", "const HALLW := 3", t, flags=re.M))
    g = floorgeom.read(d)
    vb, eb = floorgeom.verdict(g, *BROOD)
    ck("E corridor clear None + matched-0-lines error",
       g["corridor_clear_m"] is None and any("HALL_W matched 0" in e for e in g["errors"]),
       g["errors"])
    ck("E span verdict WITHHELD, not defaulted to 11.0",
       vb["corridor"] is None and vb["fits"] is False
       and any("corridor clear" in e for e in eb), (vb["corridor"], eb))
    ck("E the lid eye still works", vb["lid"] == "THROUGH-LID", vb["lid"])
    shutil.rmtree(d, ignore_errors=True)

    print("F  a second SHADOWS_ONLY mesh appears")
    d = tree(repo, lambda t: t.replace(
        "    lid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY",
        "    lid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY\n"
        "    other.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY"))
    g = floorgeom.read(d)
    ck("F ambiguity is an error, not a pick",
       g["lid_underside_m"] is None and any("SHADOWS_ONLY" in e for e in g["errors"]),
       g["errors"])
    shutil.rmtree(d, ignore_errors=True)

    print("\nFLOORGEOM_PROOF " + ("GREEN - 6 arms, all moved" if not fails
                                  else "RED - " + "; ".join(fails)))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
