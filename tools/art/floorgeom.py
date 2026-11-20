"""floorgeom - READ THE DUNGEON'S OWN NUMBERS OUT OF scripts/floorgen.gd.

WHY THIS FILE EXISTS, 2026-11-20 02:4x CT.

minibossgen's corridor gate compared FOOTPRINT SPAN and nothing else, and it
carried the corridor clear as a Python literal (`3 * 4.0 - 2 * 0.5`) copied out
of floorgen.gd by hand.  monstervariants' record carried `corridor_clear=11.0`
and `> 11.0` as two more literals.  So:

  * A 6.60 m Broodglut passed a GREEN verdict while standing 0.10 m through a
    shadows-only lid at 6.50 m that NO GATE HAD EVER MEASURED.  There was no
    height term to fail.
  * Every one of those literals is a copy of a number owned by another file.
    The supervisor ruled at 02:12 CT that the lid rises from y=7.0 to y=10.0.
    A gate holding a literal of a number under review is the next stale
    comment, so this file holds no literals at all.

WHAT IS PARSED (all of it out of scripts/floorgen.gd, with line numbers kept so
the register can say WHERE each number came from):

  const G := 4.0          the cell, metres
  const WALL_IN := 0.5    how far a wall reaches into its cell
  const HALL_W := 3       corridor width in cells (D91 stage 3)
  the lid block           anchored on the single SHADOWS_ONLY line: the lid's
                          own `.position = Vector3(0, y, 0)` - which must be the
                          ONLY such assignment IN THE FILE, because a later one
                          is what the engine would actually ship - and the
                          BoxMesh's `.size = Vector3(_, thick, _)` above it.

  corridor_clear_m = HALL_W * G - 2 * WALL_IN
  lid_underside_m  = lid_y - lid_thick / 2

*** THIS READER GOES RED ON EMPTY.  IT NEVER SUBSTITUTES A DEFAULT. ***
That is the whole point and it is the trap this lane has already been bitten by
twice (System 1's unmovable instrument, pass 11's mask_of).  If a number cannot
be read, `errors` is non-empty and the VALUE IS None - so a caller that uses it
arithmetically raises instead of quietly gating against 6.50 or 11.0 forever
after someone renames the variable.  A gate that cannot see the lid must not
report a creature as under it.
"""
import hashlib
import os
import re
import shutil
import subprocess
import tempfile

GD_REL = os.path.join("scripts", "floorgen.gd")

_CONST = r"^\s*const\s+%s\s*:?=\s*([0-9]*\.?[0-9]+)\s*(?:#.*)?$"
# Vector3(a, b, c) - each component a plain literal or a simple expression; only
# the component we need has to be a literal, and it has to BE a literal.
_V3 = re.compile(r"Vector3\s*\((.*)\)\s*$")


def _split3(inner):
    """Split a Vector3's argument text on top-level commas."""
    out, depth, cur = [], 0, ""
    for ch in inner:
        if ch in "([":
            depth += 1
        elif ch in ")]":
            depth -= 1
        if ch == "," and depth == 0:
            out.append(cur)
            cur = ""
        else:
            cur += ch
    out.append(cur)
    return [s.strip() for s in out]


def _lit(text):
    """A plain float literal, or None.  '7.0' yes; 'y + 1' no; '10' yes."""
    t = text.strip()
    return float(t) if re.fullmatch(r"-?[0-9]*\.?[0-9]+", t) else None


def read(repo, _ref_depth=0):
    """Parse scripts/floorgen.gd.  Never raises; reports what it could not see."""
    path = os.path.join(repo, GD_REL)
    out = {
        "gd": GD_REL, "cell_m": None, "wall_in_m": None, "hall_w": None,
        "corridor_clear_m": None, "lid_y_m": None, "lid_thick_m": None,
        "lid_underside_m": None, "at": {}, "errors": [],
        "provenance": None,
    }
    if not os.path.isfile(path):
        out["errors"].append("floorgeom: %s not found" % path)
        if _ref_depth == 0:
            out["provenance"] = _provenance(repo, path, out)
        return out
    with open(path, encoding="utf-8", errors="replace") as f:
        lines = f.read().splitlines()

    for name, key in (("G", "cell_m"), ("WALL_IN", "wall_in_m"), ("HALL_W", "hall_w")):
        rx = re.compile(_CONST % name)
        hits = [(i + 1, m.group(1)) for i, ln in enumerate(lines) for m in [rx.match(ln)] if m]
        if len(hits) != 1:
            out["errors"].append("floorgeom: const %s matched %d lines, wanted 1"
                                 % (name, len(hits)))
            continue
        out[key] = float(hits[0][1])
        out["at"][key] = "%s:%d" % (GD_REL, hits[0][0])
    if out["hall_w"] is not None:
        out["hall_w"] = int(out["hall_w"])

    # THE LID.  Anchor on the one thing that says what it is FOR - a mesh that
    # casts shadows and is never drawn - not on the variable being called "lid".
    anchors = [i for i, ln in enumerate(lines)
               if "SHADOW_CASTING_SETTING_SHADOWS_ONLY" in ln and ".cast_shadow" in ln]
    if len(anchors) != 1:
        out["errors"].append("floorgeom: %d SHADOWS_ONLY cast_shadow lines in %s, wanted 1"
                             % (len(anchors), GD_REL))
    else:
        a = anchors[0]
        var = lines[a].strip().split(".cast_shadow")[0].strip()
        win = lines[max(0, a - 24):a + 1]
        base = max(0, a - 24)
        # THE LID'S y IS COUNTED ACROSS THE WHOLE FILE, NOT JUST ABOVE THE ANCHOR.
        # 2026-11-20 06:5x CT: windowing it was a LYING GATE.  A second
        # `lid.position = Vector3(0, 2.0, 0)` one line BELOW the anchor is what
        # the engine actually ships, and the windowed read could not see it: it
        # reported UNDER-LID with 2.90 m clear for a 6.60 m Broodglut standing
        # 5.10 m THROUGH a lid at 1.50 m, with `errors` empty.  Found by this
        # lane's own red arm H, not in production.  Two assignments is now
        # AMBIGUOUS and ambiguity is an error, never a pick - the same policy
        # this file already applies to the SHADOWS_ONLY anchor.
        pos = [(i + 1, ln) for i, ln in enumerate(lines)
               if re.search(r"\b%s\.position\s*=" % re.escape(var), ln)]
        siz = [(base + i + 1, ln) for i, ln in enumerate(win)
               if re.search(r"\.size\s*=", ln) and "Vector3" in ln]
        if len(pos) != 1:
            out["errors"].append("floorgeom: %d `%s.position =` lines in %s, wanted 1 - "
                                 "the lid's y is ambiguous and is NOT guessed"
                                 % (len(pos), var, GD_REL))
        if len(siz) != 1:
            out["errors"].append("floorgeom: %d mesh `.size = Vector3(` lines above the lid "
                                 "anchor, wanted 1" % len(siz))
        if len(pos) == 1:
            m = _V3.search(pos[0][1])
            c = _split3(m.group(1)) if m else []
            y = _lit(c[1]) if len(c) == 3 else None
            if y is None:
                out["errors"].append("floorgeom: lid y is not a plain literal at %s:%d (%r)"
                                     % (GD_REL, pos[0][0], pos[0][1].strip()))
            else:
                out["lid_y_m"] = y
                out["at"]["lid_y_m"] = "%s:%d" % (GD_REL, pos[0][0])
        if len(siz) == 1:
            m = _V3.search(siz[0][1])
            c = _split3(m.group(1)) if m else []
            t = _lit(c[1]) if len(c) == 3 else None
            if t is None:
                out["errors"].append("floorgeom: lid thickness is not a plain literal at "
                                     "%s:%d (%r)" % (GD_REL, siz[0][0], siz[0][1].strip()))
            else:
                out["lid_thick_m"] = t
                out["at"]["lid_thick_m"] = "%s:%d" % (GD_REL, siz[0][0])

    if out["cell_m"] is not None and out["wall_in_m"] is not None and out["hall_w"] is not None:
        out["corridor_clear_m"] = round(out["hall_w"] * out["cell_m"] - 2 * out["wall_in_m"], 4)
    if out["lid_y_m"] is not None and out["lid_thick_m"] is not None:
        out["lid_underside_m"] = round(out["lid_y_m"] - out["lid_thick_m"] / 2.0, 4)
    if _ref_depth == 0:
        out["provenance"] = _provenance(repo, path, out)
    return out


def verdict(geom, span_m, height_m):
    """The two-term gate.  Returns (dict, hard_errors).

    span   > corridor clear  -> ROOM-LOCKED   (the game build gates its spawn)
    height > lid underside   -> THROUGH-LID   (its head is in the sun-blocker)

    A number the reader could not see yields verdict None and a hard error, so
    an unreadable floorgen.gd fails the gate instead of passing it.
    """
    errs = list(geom["errors"])
    cc, lid = geom["corridor_clear_m"], geom["lid_underside_m"]
    v = {
        "corridor_clear_m": cc, "lid_underside_m": lid,
        "corridor": None, "corridor_margin_m": None,
        "lid": None, "lid_clear_m": None, "read_from": dict(geom["at"]),
    }
    if cc is None:
        errs.append("floorgeom: no corridor clear - span verdict withheld")
    else:
        v["corridor"] = "ROOM-LOCKED" if span_m > cc else "CORRIDOR-SAFE"
        v["corridor_margin_m"] = round(cc - span_m, 3)
    if lid is None:
        errs.append("floorgeom: no lid underside - height verdict withheld")
    else:
        v["lid"] = "THROUGH-LID" if height_m > lid else "UNDER-LID"
        v["lid_clear_m"] = round(lid - height_m, 3)
    v["fits"] = bool(v["corridor"] == "CORRIDOR-SAFE" and v["lid"] == "UNDER-LID")
    return v, errs


# ---------------------------------------------------------------------------
# PROVENANCE.  Added 2026-11-20 07:5x CT, and WHY.
#
# `_leech_span.json` published `lid_y_m 7.0 / lid_underside_m 6.5` with an
# `errors: []` beside it.  Both were TRUE OF THE TREE IT READ (W5, pre-S56) and
# FALSE OF THE DUNGEON THAT SHIPS (origin/main carries 10.0).  The register did
# not have that fault because a human wrote `read_from_tree` into it by hand -
# so the correct number was in the file a reader would quote LEAST, and the
# quotable one carried no tree at all.  The team lead found it, 06:58 CT row 2.
#
# The fix is not a comment.  A floorgeom number now carries the tree it came
# out of, the sha of the file it was parsed from, the lid line verbatim, and a
# TERM-BY-TERM comparison against `origin/main`'s floorgen.gd - and a publisher
# calls `require_current()`, which REFUSES to write the number out at all when
# the two disagree.  Refuse or flag, never quietly publish.
#
# Why terms and not a file sha: any unrelated edit to floorgen.gd changes the
# sha, and a gate that cries wolf gets switched off.  The sha is recorded for
# the record; the DRIFT VERDICT is computed off the seven numbers this file
# actually derives, which are the only things a floorgeom consumer can be
# wrong about.
#
# GOES RED ON EMPTY, like the rest of this file: a comparison that ran over
# zero terms is a drift entry, not a silent agreement, and a tree whose
# `origin/main` cannot be read is UNVERIFIED - which `require_current` also
# refuses, because "I could not check" is not "it agrees".
# ---------------------------------------------------------------------------

REF = "origin/main"
TERMS = ("cell_m", "wall_in_m", "hall_w", "corridor_clear_m",
         "lid_y_m", "lid_thick_m", "lid_underside_m")


class StaleTreeError(RuntimeError):
    """A floorgeom number was about to be published out of a tree that does not
    agree with origin/main, or out of a tree nobody could check."""


def _git(repo, *args):
    """(ok, text).  Never raises; a dead git is UNVERIFIED, never a pass."""
    try:
        p = subprocess.run(["git", "-C", repo] + list(args), capture_output=True,
                           timeout=60)
    except Exception as e:                                  # noqa: BLE001
        return False, "git failed to run: %r" % (e,)
    if p.returncode != 0:
        return False, (p.stderr or b"").decode("utf-8", "replace").strip()
    return True, (p.stdout or b"").decode("utf-8", "replace")


def drift_vs(geom, ref_geom):
    """Term-by-term comparison of two parsed trees.  Returns a list of lines.

    EMPTY MEANS AGREED, and it can only be empty if terms were actually
    compared: a pair with nothing comparable yields a drift line saying so,
    because this lane has shipped a metric computed over zero pairs before.
    """
    out, n = [], 0
    for k in TERMS:
        a, b = geom.get(k), ref_geom.get(k)
        if a is None or b is None:
            out.append("%s: unreadable in %s (tree %r, %s %r)"
                       % (k, "tree" if a is None else REF, a, REF, b))
            continue
        n += 1
        if a != b:
            out.append("%s: tree %s, %s %s" % (k, a, REF, b))
    if n == 0:
        out.append("provenance: compared 0 terms - this is NOT agreement")
    return out


def _provenance(repo, path, out):
    """Which tree, which file, which commit - and does it still match the ref."""
    p = {
        "repo": os.path.abspath(repo),
        "worktree": os.path.basename(os.path.abspath(repo)) or None,
        "gd": GD_REL.replace("\\", "/"),
        "gd_sha256_8": None,
        "gd_lid_line": None,
        "branch": None, "head": None,
        "ref": REF, "ref_commit": None, "ref_gd_sha256_8": None,
        "verified": False, "matches_ref": None, "drift": [], "notes": [],
    }
    if os.path.isfile(path):
        with open(path, "rb") as f:
            raw = f.read()
        p["gd_sha256_8"] = hashlib.sha256(raw).hexdigest()[:8]
        loc = out["at"].get("lid_y_m")
        if loc:
            try:
                n = int(loc.rsplit(":", 1)[1])
                p["gd_lid_line"] = raw.decode("utf-8", "replace").splitlines()[n - 1].strip()
            except Exception:                                # noqa: BLE001
                p["notes"].append("provenance: could not re-read the lid line at %s" % loc)
    else:
        p["notes"].append("provenance: %s not found - nothing to stamp" % path)
        return p

    ok, br = _git(repo, "rev-parse", "--abbrev-ref", "HEAD")
    if ok:
        p["branch"] = br.strip()
    ok, hd = _git(repo, "rev-parse", "HEAD")
    if ok and re.fullmatch(r"[0-9a-f]{40}", hd.strip()):
        p["head"] = hd.strip()
    ok, rc = _git(repo, "rev-parse", REF)
    if ok and re.fullmatch(r"[0-9a-f]{40}", rc.strip()):
        p["ref_commit"] = rc.strip()

    ok, blob = _git(repo, "--no-pager", "show", "%s:%s" % (REF, GD_REL.replace("\\", "/")))
    if not ok:
        p["notes"].append("provenance UNVERIFIED: could not read %s:%s out of %s (%s)"
                          % (REF, GD_REL.replace("\\", "/"), p["repo"], blob[:200]))
        return p
    p["ref_gd_sha256_8"] = hashlib.sha256(blob.encode("utf-8")).hexdigest()[:8]

    d = tempfile.mkdtemp(prefix="floorgeom_ref_")
    try:
        rp = os.path.join(d, GD_REL)
        os.makedirs(os.path.dirname(rp))
        with open(rp, "w", encoding="utf-8", newline="") as f:
            f.write(blob)
        ref_geom = read(d, _ref_depth=1)
    finally:
        shutil.rmtree(d, ignore_errors=True)
    if ref_geom["errors"]:
        p["notes"].append("provenance: %s's own floorgen.gd did not parse clean: %s"
                          % (REF, "; ".join(ref_geom["errors"])))
    p["verified"] = True
    p["drift"] = drift_vs(out, ref_geom)
    p["matches_ref"] = not p["drift"]
    return p


def stamp(geom):
    """One line a summary or a log can carry without losing the tree."""
    p = geom.get("provenance") or {}
    state = ("AGREES WITH " + REF) if p.get("matches_ref") else (
        "DRIFTED FROM " + REF if p.get("verified") else "UNVERIFIED")
    return ("floorgeom %s: tree %s (branch %s) %s sha %s vs %s sha %s%s"
            % (state, p.get("repo"), p.get("branch"), p.get("gd"),
               p.get("gd_sha256_8"), p.get("ref_commit"), p.get("ref_gd_sha256_8"),
               ("  DRIFT: " + "; ".join(p["drift"])) if p.get("drift") else ""))


def require_current(geom, allow_stale=False, allow_unverified=False):
    """*** CALL THIS BEFORE PUBLISHING ANY FLOORGEOM NUMBER. ***

    Raises StaleTreeError when the floorgen.gd that was parsed disagrees with
    origin/main's, or when nobody could check.  Pass allow_stale=True only to
    FLAG rather than refuse - and then the flag must be written into whatever
    you publish, which is why this returns the provenance block.
    """
    p = geom.get("provenance") or {}
    if p.get("drift") and not allow_stale:
        raise StaleTreeError(
            "REFUSING to publish a floorgeom number: " + stamp(geom)
            + "  - read the tree that ships, or pass allow_stale and say so in the file.")
    if not p.get("verified") and not (allow_unverified or allow_stale):
        raise StaleTreeError("REFUSING to publish an UNVERIFIED floorgeom number: "
                             + stamp(geom) + "  notes: " + "; ".join(p.get("notes") or []))
    return p
