"""_floorgeom_proof - THE RED ARMS for tools/art/floorgeom.py.

A gate's number is worth nothing until the gate has been MADE to fail on
purpose.  This builds throwaway copies of scripts/floorgen.gd in a temp tree
and asserts the reader moves, withholds, or errors as it should.

*** REWRITTEN 2026-11-20 06:4x CT, AND WHY. ***
The team lead ran the previous version against the merged tree: 7 checks FAILED
and - far worse - ARM B PASSED FOR THE WRONG REASON.  Every arm edited the file
with `t.replace("lid.position = Vector3(0, 7.0, 0)", ...)`.  S56 moved that
literal 7.0 -> 10.0, so the replace matched ZERO lines and silently did nothing:
arm B then read the UNEDITED live tree, which already said 10.0, printed PASS,
and proved nothing at all.  That is the decorative-gate fault class, inside the
instrument built to catch it.  Two rules came out of it and both are code here:

  1. NO ARM HARD-CODES A FLOORGEN NUMBER - not 7.0, and not 10.0 either, or the
     next ruling puts us right back here.  Each arm reads the literal the file
     ACTUALLY carries (via `independent()` below) and edits that text.
  2. A REPLACE THAT MATCHES ZERO LINES IS A HARD ERROR.  `must_replace` counts
     its matches and raises.  A no-op edit can never again read as a pass.

Arm A cross-checks the reader against `independent()` - a second, deliberately
dumber parser written in THIS file - rather than against numbers typed by hand.
A gate that agrees only with itself is not checked.

  A  as shipped                 -> reader agrees with an independent read, no errors
  B  lid moved BOTH ways        -> underside tracks the file; the verdict flips
  C  lid position line gone     -> lid None, verdict WITHHELD, hard error
  D  lid y an expression        -> not-a-literal error, no guess
  E  HALL_W renamed             -> corridor WITHHELD (span verdict cannot be faked)
  F  two SHADOWS_ONLY anchors   -> ambiguous, errors, no number
  G  the harness's own guard    -> a zero-match edit RAISES (this is arm B's bug)
  H  a SECOND lid .position     -> ambiguous, errors, no number (found 06:5x CT - the
                                   windowed read called a lid at 1.50 m "UNDER-LID, 2.90 clear")

Run:  python3 tools/art/_floorgeom_proof.py <repo>
"""
import os
import re
import shutil
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import floorgeom  # noqa: E402

# The two bestiary-carried variants, from renders/art/variants/_register.json.
# These are ART's own measured numbers, not floorgen's, so they are allowed to
# be literals here - but no LID or CORRIDOR number is.
BROOD = (10.4063, 6.60)      # span, height - the variant that went through it
LAST = (6.4807, 6.20)


class ProofError(RuntimeError):
    """The harness itself is broken - never reported as a creature's FAIL."""


def must_replace(txt, old, new, want=1):
    """Replace, and RAISE unless it matched exactly `want` times.

    THIS IS THE WHOLE FIX.  `str.replace` on a literal that has moved returns
    the string untouched and tells you nothing; every arm below went green on
    an unedited tree because of it.
    """
    n = txt.count(old)
    if n != want:
        raise ProofError("edit matched %d lines, wanted %d: %r" % (n, want, old))
    return txt.replace(old, new)


def must_sub(txt, pattern, repl, want=1, flags=re.M):
    """Regex form of must_replace.  Zero matches is a hard error, not a no-op."""
    out, n = re.subn(pattern, repl, txt, flags=flags)
    if n != want:
        raise ProofError("regex matched %d lines, wanted %d: %r" % (n, want, pattern))
    return out


def independent(repo):
    """A SECOND, DUMBER READER, written here on purpose.

    Arm A used to assert `lid_underside_m == 6.5` - a number typed by a human
    out of a file that then changed under it.  Instead this walks the file with
    its own regexes and hands back both the VALUES and the exact LINE TEXT the
    other arms edit.  It goes RED ON EMPTY: anything it cannot see raises, so a
    missing anchor can never silently shrink the proof.
    """
    path = os.path.join(repo, floorgeom.GD_REL)
    if not os.path.isfile(path):
        raise ProofError("independent: %s not found" % path)
    with open(path, encoding="utf-8", errors="replace") as f:
        lines = f.read().splitlines()

    out = {}
    for name in ("G", "WALL_IN", "HALL_W"):
        hits = [ln for ln in lines
                if re.match(r"^\s*const\s+%s\s*:?=\s*-?[0-9]*\.?[0-9]+" % name, ln)]
        if len(hits) != 1:
            raise ProofError("independent: const %s matched %d lines" % (name, len(hits)))
        out[name] = float(re.search(r":?=\s*(-?[0-9]*\.?[0-9]+)", hits[0]).group(1))
        out["line_" + name] = hits[0]

    anchors = [i for i, ln in enumerate(lines)
               if ".cast_shadow" in ln and "SHADOW_CASTING_SETTING_SHADOWS_ONLY" in ln]
    if len(anchors) != 1:
        raise ProofError("independent: %d SHADOWS_ONLY anchors" % len(anchors))
    a = anchors[0]
    out["line_anchor"] = lines[a]
    var = lines[a].strip().split(".cast_shadow")[0].strip()

    def one_above(rx, what):
        hits = [ln for ln in lines[max(0, a - 24):a + 1] if re.search(rx, ln)]
        if len(hits) != 1:
            raise ProofError("independent: %d %s lines above the anchor" % (len(hits), what))
        return hits[0]

    pos_all = [ln for ln in lines
               if re.search(r"\b%s\.position\s*=.*Vector3" % re.escape(var), ln)]
    if len(pos_all) != 1:
        raise ProofError("independent: %d `%s.position =` lines IN THE FILE - the lid's y is "
                         "ambiguous" % (len(pos_all), var))
    out["line_pos"] = pos_all[0]
    out["line_size"] = one_above(r"\.size\s*=.*Vector3", "lid mesh .size")

    def y_of(line, what):
        inner = re.search(r"Vector3\s*\((.*)\)", line).group(1)
        parts = [p.strip() for p in inner.split(",")]
        if len(parts) != 3 or not re.fullmatch(r"-?[0-9]*\.?[0-9]+", parts[1]):
            raise ProofError("independent: %s y is not a plain literal: %r" % (what, line))
        return parts[1]

    out["lid_y_txt"] = y_of(out["line_pos"], "lid position")
    out["thick_txt"] = y_of(out["line_size"], "lid size")
    out["lid_y"] = float(out["lid_y_txt"])
    out["thick"] = float(out["thick_txt"])
    out["underside"] = round(out["lid_y"] - out["thick"] / 2.0, 4)
    out["corridor"] = round(out["HALL_W"] * out["G"] - 2 * out["WALL_IN"], 4)
    return out


def pos_line_with(ind, y_text):
    """The live `.position` line with ONLY its y token swapped for `y_text`.

    No arm writes a whole line of its own: every edit is a surgical swap inside
    the text the file really carries, which is why a moved literal can no
    longer slip past as a no-op.
    """
    old = ind["line_pos"]
    i = old.index(ind["lid_y_txt"], old.index("Vector3"))
    return old[:i] + str(y_text) + old[i + len(ind["lid_y_txt"]):]


def moved_pos_line(ind, new_y):
    """The live `.position` line moved to `new_y` - no literal assumed."""
    return pos_line_with(ind, repr(round(float(new_y), 4)))


def tree(src_repo, edit):
    d = tempfile.mkdtemp(prefix="floorgeom_")
    os.makedirs(os.path.join(d, "scripts"))
    p = os.path.join(d, floorgeom.GD_REL)
    with open(os.path.join(src_repo, floorgeom.GD_REL), encoding="utf-8") as f:
        txt = f.read()
    with open(p, "w", encoding="utf-8") as f:
        f.write(edit(txt))          # edit() raises if its anchor is gone
    return d


def main():
    repo = sys.argv[1] if len(sys.argv) > 1 else "."
    fails = []

    def ck(name, cond, saw):
        print(("  PASS " if cond else "  FAIL ") + name + "   saw: " + str(saw))
        if not cond:
            fails.append(name)

    try:
        ind = independent(repo)
    except ProofError as e:
        print("  HARNESS ERROR reading %s: %s" % (repo, e))
        print("\nFLOORGEOM_PROOF RED - the proof could not read floorgen.gd")
        return 2
    print("live literals, read not assumed: lid y %s, thick %s -> underside %s; "
          "corridor %s  (%s)" % (ind["lid_y_txt"], ind["thick_txt"], ind["underside"],
                                 ind["corridor"], ind["line_pos"].strip()))

    print("A  as shipped - the reader must agree with an INDEPENDENT read")
    g = floorgeom.read(repo)
    vb, eb = floorgeom.verdict(g, *BROOD)
    vl, el = floorgeom.verdict(g, *LAST)
    ck("A reader's corridor and lid equal the independent read, no errors",
       g["corridor_clear_m"] == ind["corridor"] and g["lid_underside_m"] == ind["underside"]
       and g["lid_y_m"] == ind["lid_y"] and g["lid_thick_m"] == ind["thick"]
       and not g["errors"],
       (g["corridor_clear_m"], g["lid_underside_m"], g["errors"]))
    for nm, (span, h), v, e in (("broodglut", BROOD, vb, eb), ("lastcuff", LAST, vl, el)):
        want_lid = "THROUGH-LID" if h > ind["underside"] else "UNDER-LID"
        want_cor = "ROOM-LOCKED" if span > ind["corridor"] else "CORRIDOR-SAFE"
        ck("A %s verdict matches the independent numbers (%s / %s)" % (nm, want_lid, want_cor),
           v["lid"] == want_lid and v["corridor"] == want_cor
           and v["lid_clear_m"] == round(ind["underside"] - h, 3)
           and v["fits"] is (want_lid == "UNDER-LID" and want_cor == "CORRIDOR-SAFE")
           and not e,
           (v["lid"], v["lid_clear_m"], v["corridor"], v["fits"]))

    print("B  the lid moved BOTH ways off whatever the file carries")
    # Chosen from broodglut's own height, NOT from a floorgen literal, so these
    # two arms stay meaningful at any lid the supervisor rules for.
    y_low = BROOD[1] - 0.10 + ind["thick"] / 2.0      # underside = h - 0.10 -> THROUGH
    y_high = BROOD[1] + 2.90 + ind["thick"] / 2.0     # underside = h + 2.90 -> UNDER
    seen = {}
    for tag, new_y, want_lid, want_clear in (("B1 low", y_low, "THROUGH-LID", -0.1),
                                             ("B2 high", y_high, "UNDER-LID", 2.9)):
        d = tree(repo, lambda t, ny=new_y: must_replace(t, ind["line_pos"],
                                                        moved_pos_line(ind, ny)))
        g = floorgeom.read(d)
        vb, eb = floorgeom.verdict(g, *BROOD)
        want_under = round(new_y - ind["thick"] / 2.0, 4)
        seen[tag] = g["lid_underside_m"]
        ck("%s: underside tracks the edited file (%s)" % (tag, want_under),
           g["lid_underside_m"] == want_under and not g["errors"], g["lid_underside_m"])
        ck("%s: broodglut reads %s with %s clear" % (tag, want_lid, want_clear),
           vb["lid"] == want_lid and vb["lid_clear_m"] == want_clear and not eb,
           (vb["lid"], vb["lid_clear_m"]))
        shutil.rmtree(d, ignore_errors=True)
    ck("B the two arms read DIFFERENT undersides - the reader is not a constant",
       seen.get("B1 low") != seen.get("B2 high"), seen)

    print("C  the lid's position line deleted")
    d = tree(repo, lambda t: must_replace(t, ind["line_pos"] + "\n", ""))
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
    d = tree(repo, lambda t: must_replace(t, ind["line_pos"],
                                          pos_line_with(ind, "LID_Y + 1.0")))
    g = floorgeom.read(d)
    ck("D refuses to guess: lid None + not-a-literal error",
       g["lid_underside_m"] is None and any("not a plain literal" in e for e in g["errors"]),
       g["errors"])
    shutil.rmtree(d, ignore_errors=True)

    print("E  HALL_W renamed out from under the gate")
    d = tree(repo, lambda t: must_sub(t, r"^(\s*const\s+)HALL_W(\s*:?=)", r"\1HALLW\2"))
    g = floorgeom.read(d)
    vb, eb = floorgeom.verdict(g, *BROOD)
    ck("E corridor clear None + matched-0-lines error",
       g["corridor_clear_m"] is None and any("HALL_W matched 0" in e for e in g["errors"]),
       g["errors"])
    ck("E span verdict WITHHELD, not defaulted",
       vb["corridor"] is None and vb["fits"] is False
       and any("corridor clear" in e for e in eb), (vb["corridor"], eb))
    ck("E the lid eye still works", vb["lid"] is not None, vb["lid"])
    shutil.rmtree(d, ignore_errors=True)

    print("F  a second SHADOWS_ONLY mesh appears")
    d = tree(repo, lambda t: must_replace(
        t, ind["line_anchor"],
        ind["line_anchor"] + "\n"
        + ind["line_anchor"].replace(ind["line_anchor"].strip().split(".cast_shadow")[0].strip()
                                     + ".cast_shadow", "other.cast_shadow", 1)))
    g = floorgeom.read(d)
    ck("F ambiguity is an error, not a pick",
       g["lid_underside_m"] is None and any("SHADOWS_ONLY" in e for e in g["errors"]),
       g["errors"])
    shutil.rmtree(d, ignore_errors=True)

    print("G  THE HARNESS'S OWN GUARD - a zero-match edit must RAISE, not pass")
    # This is arm B's exact bug, reproduced on purpose: a hard-coded lid literal
    # that is NOT the one the file carries.  The old harness went green here.
    stale = float(ind["lid_y"]) + 3.0
    stale_line = moved_pos_line(ind, stale)
    raised = None
    try:
        tree(repo, lambda t: must_replace(t, stale_line, stale_line))
        raised = False
    except ProofError as e:
        raised = str(e)
    ck("G a stale hard-coded lid line is a HARD ERROR (matched 0)",
       isinstance(raised, str) and "matched 0 lines" in raised, raised)
    # and the guard must NOT cry wolf on an anchor that is really there
    ok = None
    try:
        d = tree(repo, lambda t: must_replace(t, ind["line_pos"], ind["line_pos"]))
        ok = floorgeom.read(d)["lid_underside_m"] == ind["underside"]
        shutil.rmtree(d, ignore_errors=True)
    except ProofError as e:
        ok = "RAISED: " + str(e)
    ck("G the guard passes a real anchor through untouched", ok is True, ok)

    print("H  a SECOND lid .position assignment appears BELOW the anchor")
    # THE BLIND SPOT THIS LANE SHIPPED.  The reader used to scan only 24 lines
    # ABOVE the SHADOWS_ONLY anchor, so the assignment the engine would really
    # obey was invisible: 6.60 m Broodglut read UNDER-LID with 2.90 m clear
    # while the lid sat at 1.50 m and it was 5.10 m through it, errors EMPTY.
    low = pos_line_with(ind, "2.0")
    d = tree(repo, lambda t: must_replace(t, ind["line_anchor"],
                                          ind["line_anchor"] + "\n" + low))
    g = floorgeom.read(d)
    vb, eb = floorgeom.verdict(g, *BROOD)
    ck("H two lid y assignments is an ERROR, not a pick",
       g["lid_underside_m"] is None and g["lid_y_m"] is None
       and any("ambiguous" in e for e in g["errors"]), (g["lid_y_m"], g["errors"]))
    ck("H the height verdict is WITHHELD, not the stale 2.90 clear",
       vb["lid"] is None and vb["lid_clear_m"] is None and vb["fits"] is False and eb,
       (vb["lid"], vb["lid_clear_m"]))
    shutil.rmtree(d, ignore_errors=True)

    print("\nFLOORGEOM_PROOF " + ("GREEN - 8 arms, all moved" if not fails
                                  else "RED - " + "; ".join(fails)))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
