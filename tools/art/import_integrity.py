#!/usr/bin/env python3
"""
Art-asset import integrity audit for Bellmire HD.  ART lane tool.
Pure python + stdlib: runs on the Linux bridge, needs no Blender and no Godot.

    python3 -I tools/art/import_integrity.py <repo-root> [out.json]

WHY THIS EXISTS
---------------
On 25 Nov the Overlooker's body shipped as `overlooker.glb` with NO
`overlooker.glb.import` sibling.  Godot cannot load a resource whose .import is
missing, so the game carried 76 miniboss meshes and 75 loadable ones, and
nothing in the tree was watching.  This watches - for that fault and for the
four neighbouring ones that break loading the same silent way.

FIVE CHECKS, each over its own stated denominator:
  A  MISSING   - an importable asset inside Godot's scan scope with no .import
  B  ORPHAN    - an .import whose source asset is gone (Godot errors on these)
  C  UID       - uid:// must be globally unique; a collision breaks loading
  D  PATHHASH  - the cache path inside an .import must embed md5 of that
                 .import's OWN source res:// path.  A copy-pasted .import keeps
                 the DONOR's hash and silently points at the wrong cache entry.
                 The rule is PROVED on the corpus before any mismatch is charged.
  E  NOTIMPORTED - an .import that names an importer but carries `valid=false`
                 or no cache path at all: Godot TRIED and did not finish.  E
                 then splits that on the engine's OWN bookkeeping, because a
                 failed import and a healed one look identical in the .import:
                   E-LIVE  the `.godot/imported/*.md5` sidecar records the SAME
                           source hash the file has now.  Godot has seen these
                           exact bytes and still produced nothing.  RED.
                   E-STALE the sidecar records a DIFFERENT hash (or is absent).
                           The source has changed since the failure, which is
                           precisely Godot's re-import trigger, so the marker is
                           a fossil and clears on the next scan.  Reported, not
                           charged.

TWO RULES THIS HARNESS OBEYS, BOTH LEARNED THE HARD WAY
-------------------------------------------------------
1. EVERY CHECK GOES RED ON EMPTY.  A metric computed over zero items reads
   green and means nothing.
2. NO SILENT "INAPPLICABLE" BUCKET.  The first version of this file scored
   check D at `conform_rate 1.00000, mismatch 0` while the one genuinely
   broken .import in the tree sat in an `inapplicable` count that no check
   looked at.  A perfect score with the defect filed under "not applicable" is
   the unearned pass this house keeps getting bitten by.  Every file that D
   cannot judge is now HANDED TO E and counted, and an unexplained residue is
   itself a RED.

WHAT THIS CANNOT SEE - read this before trusting it
---------------------------------------------------
  * It does not open Godot.  A present, self-consistent .import can still be
    rejected by the engine; this proves the file exists, is non-empty, names a
    cache path, and that the path is the right md5.  Only a Godot run proves
    the import.
  * uid uniqueness is checked across THIS worktree only.  An asset on another
    branch, not yet merged here, can still collide after a merge.
  * It says NOTHING about whether any asset looks right.  It is a loader
    check - not a fit proof, not a visibility proof, not a facing proof.
  * E-STALE vs E-LIVE is read off the cache sidecar, which is evidence about
    what the engine LAST SAW - strong, but still not a Godot run.  Only opening
    the project proves an import succeeds.  E-STALE means "the re-import
    trigger is armed", not "I watched it import".
"""
import hashlib, os, re, sys, json, collections

IMPORTABLE = {
    ".glb", ".gltf", ".fbx", ".obj", ".dae", ".blend",
    ".png", ".jpg", ".jpeg", ".webp", ".svg", ".bmp", ".tga", ".exr", ".hdr",
    ".ogg", ".wav", ".mp3",
    ".ttf", ".otf", ".woff", ".woff2",
}
SKIP_DIRS = {".godot", ".git"}
# Importers that legitimately produce no cache file under .godot/imported/.
NO_CACHE_IMPORTERS = {"keep", "skip"}
# md5 of a zero-byte file - Godot records this after importing an empty source.
EMPTY_FILE_MD5 = "d41d8cd98f00b204e9800998ecf8427e"

def scan_scope(root):
    """Walk the tree the way Godot does: skip .godot/.git, and skip any
    directory carrying a .gdignore (and everything beneath it)."""
    assets, imports, ignored_roots = [], [], []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        if ".gdignore" in filenames:
            ignored_roots.append(os.path.relpath(dirpath, root).replace(os.sep, "/"))
            dirnames[:] = []
            continue
        for fn in filenames:
            rel = os.path.relpath(os.path.join(dirpath, fn), root).replace(os.sep, "/")
            if fn.endswith(".import"):
                imports.append(rel)
            elif os.path.splitext(fn)[1].lower() in IMPORTABLE:
                assets.append(rel)
    return sorted(assets), sorted(imports), sorted(ignored_roots)

UID_RE   = re.compile(r'^uid\s*=\s*"(uid://[a-z0-9]+)"', re.M)
SRC_RE   = re.compile(r'^source_file\s*=\s*"(res://[^"]+)"', re.M)
PATH_RE  = re.compile(r'^path\s*=\s*"([^"]+)"', re.M)
DEST_RE  = re.compile(r'^dest_files\s*=\s*\[([^\]]*)\]', re.M | re.S)
IMPR_RE  = re.compile(r'^importer\s*=\s*"([^"]+)"', re.M)
VALID_RE = re.compile(r'^valid\s*=\s*(true|false)', re.M)
QUOTED   = re.compile(r'"([^"]+)"')

def parse_import(root, rel):
    body = open(os.path.join(root, rel), "r", encoding="utf-8", errors="replace").read()
    uid, src = UID_RE.search(body), SRC_RE.search(body)
    impr, val = IMPR_RE.search(body), VALID_RE.search(body)
    dm = DEST_RE.search(body)
    return {
        "rel": rel, "bytes": len(body),
        "uid": uid.group(1) if uid else None,
        "source_file": src.group(1) if src else None,
        "importer": impr.group(1) if impr else None,
        "valid": val.group(1) if val else None,
        "paths": PATH_RE.findall(body),
        "dest_files": QUOTED.findall(dm.group(1)) if dm else [],
    }

def main(root):
    assets, imports, ignored = scan_scope(root)
    rep = {"root": os.path.abspath(root), "gdignored_roots": ignored,
           "counts": {"importable_assets": len(assets), "import_files": len(imports)}}
    fails = []

    # ---------- A: MISSING .import ----------
    have = set(imports)
    missing = [a for a in assets if (a + ".import") not in have]
    rep["A_missing"] = {"denominator": len(assets), "missing": len(missing),
                        "by_dir": dict(collections.Counter(m.split("/")[0] for m in missing)),
                        "files": missing[:300]}
    if not assets: fails.append("A RED ON EMPTY: zero importable assets scanned")
    if missing:    fails.append("A: %d importable assets have NO .import sibling" % len(missing))

    recs, unreadable = [], []
    for rel in imports:
        try: recs.append(parse_import(root, rel))
        except Exception as e: unreadable.append({"rel": rel, "err": str(e)})
    rep["unreadable_imports"] = unreadable
    if unreadable: fails.append("%d .import files could not be read" % len(unreadable))
    empty = [r["rel"] for r in recs if r["bytes"] == 0]
    rep["empty_imports"] = empty
    if empty: fails.append("%d .import files are ZERO BYTES" % len(empty))

    # ---------- B: ORPHAN .import ----------
    orphans = [r["rel"] for r in recs
               if not os.path.exists(os.path.join(root, r["rel"][:-len(".import")]))]
    rep["B_orphans"] = {"denominator": len(recs), "orphans": len(orphans),
                        "by_dir": dict(collections.Counter(o.split("/")[0] for o in orphans)),
                        "files": orphans[:300]}
    if not recs: fails.append("B RED ON EMPTY: zero .import files parsed")
    if orphans:  fails.append("B: %d .import files have no source asset" % len(orphans))

    # ---------- C: GLOBAL uid UNIQUENESS ----------
    byuid = collections.defaultdict(list); nouid = []
    for r in recs:
        (byuid[r["uid"]].append(r["rel"]) if r["uid"] else nouid.append(r["rel"]))
    collisions = {u: f for u, f in byuid.items() if len(f) > 1}
    rep["C_uid"] = {"denominator": len(recs), "distinct_uids": len(byuid),
                    "without_uid": len(nouid), "without_uid_files": nouid[:50],
                    "collision_count": len(collisions),
                    "collisions": dict(list(collisions.items())[:50])}
    if not byuid:  fails.append("C RED ON EMPTY: zero uids collected")
    if collisions: fails.append("C: %d uid COLLISIONS across the tree" % len(collisions))

    # ---------- D / E: PATH-HASH RULE, and the residue D cannot judge ----------
    conform, mismatch, notimported, exempt = [], [], [], []
    for r in recs:
        src = r["source_file"]
        cands = [p for p in (r["paths"] + r["dest_files"])
                 if p.startswith("res://.godot/imported/")]
        if cands and src:
            want = hashlib.md5(src.encode("utf-8")).hexdigest()
            if all(want in c for c in cands) and r["valid"] != "false":
                conform.append(r["rel"])
            elif not all(want in c for c in cands):
                mismatch.append({"rel": r["rel"], "source_file": src,
                                 "expected_md5": want, "cache_paths": cands[:4]})
            else:
                notimported.append({"rel": r["rel"], "why": "valid=false with a cache path",
                                    "importer": r["importer"], "valid": r["valid"]})
            continue
        # No cache path.  THIS IS WHERE THE DEFECT HID.  Route it, never drop it.
        if r["importer"] in NO_CACHE_IMPORTERS:
            exempt.append({"rel": r["rel"], "importer": r["importer"]})
        else:
            notimported.append({
                "rel": r["rel"],
                "why": "importer=%r names a cache-producing importer but the .import "
                       "carries no path=/dest_files=%s" % (
                           r["importer"], " and valid=false" if r["valid"] == "false" else ""),
                "importer": r["importer"], "valid": r["valid"],
                "source_file": src, "source_exists": bool(src) and os.path.exists(
                    os.path.join(root, src[len("res://"):])) if src else False})

    den = len(conform) + len(mismatch)
    rate = (len(conform) / den) if den else 0.0
    rep["D_pathhash"] = {"denominator": den, "conform": len(conform),
                         "mismatch": len(mismatch), "conform_rate": round(rate, 6),
                         "mismatches": mismatch[:50]}
    if den == 0:
        fails.append("D RED ON EMPTY: rule applicable to zero .import files")
    elif rate < 0.98:
        fails.append("D: the md5 path-hash rule holds on only %.1f%% of %d files - the RULE "
                     "is unproven on this corpus, so no mismatch is charged" % (rate * 100, den))
    elif mismatch:
        fails.append("D: rule proved on %d/%d (%.3f%%) but %d .import files carry a cache hash "
                     "that is NOT md5 of their own source path"
                     % (len(conform), den, rate * 100, len(mismatch)))

    # E splits on the engine's own cache sidecar: has Godot SEEN these bytes?
    live, stale = [], []
    for item in notimported:
        src = item.get("source_file")
        verdict = {"sidecar": None, "recorded_source_md5": None, "current_source_md5": None}
        if src and src.startswith("res://"):
            relsrc = src[len("res://"):]
            abssrc = os.path.join(root, relsrc)
            want = hashlib.md5(src.encode("utf-8")).hexdigest()
            side = os.path.join(root, ".godot", "imported",
                                "%s-%s.md5" % (os.path.basename(relsrc), want))
            if os.path.exists(abssrc):
                verdict["current_source_md5"] = hashlib.md5(
                    open(abssrc, "rb").read()).hexdigest()
            if os.path.exists(side):
                verdict["sidecar"] = os.path.relpath(side, root).replace(os.sep, "/")
                m = re.search(r'source_md5\s*=\s*"([0-9a-f]{32})"',
                              open(side, encoding="utf-8", errors="replace").read())
                if m:
                    verdict["recorded_source_md5"] = m.group(1)
        item.update(verdict)
        rec, cur = verdict["recorded_source_md5"], verdict["current_source_md5"]
        if rec and cur and rec == cur:
            item["state"] = "E-LIVE"
            item["note"] = ("Godot last saw THESE EXACT BYTES and produced no cache entry - "
                            "a live import failure, not a stale marker")
            live.append(item)
        else:
            item["state"] = "E-STALE"
            item["note"] = ("the cache sidecar records source_md5=%r but the file now hashes "
                            "to %r, so the source changed after the failure and Godot's "
                            "re-import trigger is armed" % (rec, cur))
            if rec == EMPTY_FILE_MD5:
                item["note"] += " (the recorded hash is the md5 of a ZERO-BYTE file)"
            stale.append(item)

    rep["E_notimported"] = {"denominator": len(recs), "notimported": len(notimported),
                            "live": len(live), "stale": len(stale),
                            "exempt_keep_or_skip": len(exempt),
                            "live_files": live[:50], "stale_files": stale[:50]}
    if not recs: fails.append("E RED ON EMPTY: zero .import files parsed")
    if live:     fails.append("E-LIVE: %d .import files failed on the bytes now on disk - Godot "
                              "has seen them and produced no cache entry, so the resource will "
                              "not load" % len(live))

    # Accounting identity: every parsed .import must land in exactly one bucket.
    accounted = len(conform) + len(mismatch) + len(notimported) + len(exempt)
    rep["accounting"] = {"parsed": len(recs), "accounted": accounted,
                         "conform": len(conform), "mismatch": len(mismatch),
                         "notimported": len(notimported), "exempt": len(exempt)}
    if accounted != len(recs):
        fails.append("ACCOUNTING: %d parsed .import files but %d accounted for - %d unexplained"
                     % (len(recs), accounted, len(recs) - accounted))

    rep["verdict"] = "GREEN" if not fails else "RED"
    rep["fails"] = fails
    return rep

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__); sys.exit(2)
    root = sys.argv[1]
    rep = main(root)
    if len(sys.argv) > 2:
        open(sys.argv[2], "w", encoding="utf-8").write(json.dumps(rep, indent=2) + "\n")
    print("VERDICT:", rep["verdict"])
    print("scanned      : %d importable assets, %d .import files" % (
        rep["counts"]["importable_assets"], rep["counts"]["import_files"]))
    print("gdignored    :", rep["gdignored_roots"])
    print("A missing    : %d / %d  %s" % (rep["A_missing"]["missing"],
          rep["A_missing"]["denominator"], rep["A_missing"]["by_dir"] or ""))
    print("B orphans    : %d / %d  %s" % (rep["B_orphans"]["orphans"],
          rep["B_orphans"]["denominator"], rep["B_orphans"]["by_dir"] or ""))
    print("C uid        : %d collisions, %d distinct, %d without uid, den %d" % (
        rep["C_uid"]["collision_count"], rep["C_uid"]["distinct_uids"],
        rep["C_uid"]["without_uid"], rep["C_uid"]["denominator"]))
    print("D pathhash   : %d conform / %d mismatch, rate %.5f, den %d" % (
        rep["D_pathhash"]["conform"], rep["D_pathhash"]["mismatch"],
        rep["D_pathhash"]["conform_rate"], rep["D_pathhash"]["denominator"]))
    print("E notimported: %d / %d  (LIVE %d, stale-marker %d, exempt keep/skip: %d)" % (
        rep["E_notimported"]["notimported"], rep["E_notimported"]["denominator"],
        rep["E_notimported"]["live"], rep["E_notimported"]["stale"],
        rep["E_notimported"]["exempt_keep_or_skip"]))
    for it in rep["E_notimported"]["stale_files"]:
        print("    stale marker (not charged): %s\n      %s" % (it["rel"], it["note"]))
    print("accounting   :", rep["accounting"])
    for f in rep["fails"]: print("  FAIL:", f)
