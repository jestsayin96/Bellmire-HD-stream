#!/usr/bin/env python3
"""
Self-test for tools/art/import_integrity.py.  ART lane tool.
Pure python + stdlib; needs no Blender and no Godot.

    python3 -I tools/art/import_integrity_selftest.py [scratch-dir]

WHY THIS EXISTS
---------------
"An instrument that cannot move is not a pass."  At System 1 this lane nearly
called a real fix dead because two metrics did not move, and at pass 11 it
shipped `head_glow_px: 156` beside its own sentence saying the head had no face.
A harness is only evidence if you have SEEN IT GO RED on a fault you planted,
and SEEN IT GO GREEN on a tree you know is clean.

So this builds throwaway fixture trees, plants ONE fault in each, and asserts
the audit's verdict and the specific check that must fire:

  clean      -> GREEN, no fails
  A missing  -> RED, A fires        (the Overlooker fault: asset, no .import)
  B orphan   -> RED, B fires        (.import whose asset is gone)
  C uid      -> RED, C fires        (two .import files sharing one uid)
  D unproven -> RED, D says the RULE is unproven on a tiny corpus and
                      DELIBERATELY charges no individual file
  D charges  -> RED, D names the guilty file once the corpus (200 clean) has
                      established the rule
  E live     -> RED, E-LIVE fires   (valid=false AND the cache sidecar records
                      the hash the file has NOW: Godot saw these bytes and
                      produced nothing.  This is the fault the FIRST version of
                      the audit filed under a silent "inapplicable" count and
                      scored 1.00000 anyway)
  E stale    -> GREEN, nothing charged (valid=false but the sidecar records a
                      DIFFERENT - here zero-byte - hash, so the source changed
                      after the failure and Godot will re-import.  Charging this
                      would be crying wolf; the audit must tell the two apart)
  empty      -> RED on all five, because a metric over zero items is not a pass

Fixtures are written under a scratch dir OUTSIDE the repo and removed after.
"""
import hashlib, os, shutil, sys, tempfile, importlib.util

HERE = os.path.dirname(os.path.abspath(__file__))

def load_audit():
    spec = importlib.util.spec_from_file_location(
        "import_integrity", os.path.join(HERE, "import_integrity.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

def write_import(root, asset, uid, hash_mode="AUTO", extra=None):
    """hash_mode: AUTO = correct md5 of own path; NONE = no path/dest_files;
    anything else is used verbatim as the cache hash (a donor's hash)."""
    src = "res://" + asset
    name = asset.split("/")[-1]
    body = ['[remap]', '', 'importer="texture"', 'type="CompressedTexture2D"',
            'uid="%s"' % uid]
    if extra:
        body.append(extra)
    if hash_mode != "NONE":
        h = hashlib.md5(src.encode()).hexdigest() if hash_mode == "AUTO" else hash_mode
        body.append('path="res://.godot/imported/%s-%s.ctex"' % (name, h))
    body += ['', '[deps]', '', 'source_file="%s"' % src]
    if hash_mode != "NONE":
        body.append('dest_files=["res://.godot/imported/%s-%s.ctex"]' % (name, h))
    os.makedirs(os.path.dirname(os.path.join(root, asset)), exist_ok=True)
    open(os.path.join(root, asset + ".import"), "w").write("\n".join(body) + "\n")

def sidecar(root, asset_rel, source_md5):
    """Plant the `.godot/imported/<name>-<md5-of-res-path>.md5` sidecar Godot
    writes to record the source hash it last imported from."""
    src = "res://" + asset_rel
    want = hashlib.md5(src.encode()).hexdigest()
    d = os.path.join(root, ".godot", "imported")
    os.makedirs(d, exist_ok=True)
    open(os.path.join(d, "%s-%s.md5" % (asset_rel.split("/")[-1], want)), "w").write(
        'source_md5="%s"\n' % source_md5)

def asset(root, rel, data="x"):
    os.makedirs(os.path.dirname(os.path.join(root, rel)), exist_ok=True)
    open(os.path.join(root, rel), "w").write(data)

def clean_tree(root, n=3):
    for i in range(n):
        a = "assets/a%03d.png" % i
        asset(root, a); write_import(root, a, "uid://clean%03d" % i)

def main(scratch=None):
    audit = load_audit()
    base = scratch or tempfile.mkdtemp(prefix="import_integrity_selftest_")
    os.makedirs(base, exist_ok=True)
    results, failures = [], []

    def case(name, build, expect_verdict, expect_prefix=None, forbid_prefix=None):
        root = os.path.join(base, name)
        shutil.rmtree(root, ignore_errors=True); os.makedirs(root)
        build(root)
        rep = audit.main(root)
        ok = rep["verdict"] == expect_verdict
        fired = None
        if expect_prefix is not None:
            fired = [f for f in rep["fails"] if f.startswith(expect_prefix)]
            ok = ok and bool(fired)
        if forbid_prefix is not None:
            ok = ok and not any(f.startswith(forbid_prefix) for f in rep["fails"])
        if expect_verdict == "GREEN":
            ok = ok and not rep["fails"]
        # the accounting identity must hold in every case
        acc = rep.get("accounting", {})
        if acc and acc.get("parsed") != acc.get("accounted"):
            ok = False
        results.append((name, rep["verdict"], "OK" if ok else "BROKEN",
                        (fired or rep["fails"] or [""])[0][:95]))
        if not ok:
            failures.append(name)

    case("clean", lambda r: clean_tree(r), "GREEN")

    def b_a(r): clean_tree(r); asset(r, "assets/lonely.png")
    case("A_missing", b_a, "RED", "A:")

    def b_b(r): clean_tree(r); write_import(r, "assets/ghost.png", "uid://ghost")
    case("B_orphan", b_b, "RED", "B:")

    def b_c(r):
        clean_tree(r); asset(r, "assets/dupe.png")
        write_import(r, "assets/dupe.png", "uid://clean000")
    case("C_uid_collision", b_c, "RED", "C:")

    def b_d_unproven(r):
        clean_tree(r); asset(r, "assets/pasted.png")
        write_import(r, "assets/pasted.png", "uid://pasted", "de" * 16)
    case("D_rule_unproven", b_d_unproven, "RED", "D: the md5 path-hash rule holds on only")

    def b_d_charges(r):
        clean_tree(r, 200); asset(r, "assets/pasted.png")
        write_import(r, "assets/pasted.png", "uid://pasted",
                     hashlib.md5(b"res://assets/a000.png").hexdigest())
    case("D_charges_at_scale", b_d_charges, "RED", "D: rule proved on")

    # E-LIVE: the sidecar records the SAME hash the file has now, so Godot has
    # seen these exact bytes and still produced nothing.  Must be charged.
    def b_e_live(r):
        clean_tree(r); asset(r, "assets/broke.png", "live-failure-bytes")
        write_import(r, "assets/broke.png", "uid://broke", "NONE", extra="valid=false")
        sidecar(r, "assets/broke.png", hashlib.md5(b"live-failure-bytes").hexdigest())
    case("E_live_failure", b_e_live, "RED", "E-LIVE:")

    # E-STALE: the sidecar records the md5 of a ZERO-BYTE file but the source has
    # since been regenerated.  Godot's re-import trigger is armed, so this is a
    # fossil and must NOT be charged.  (This is the real turbary_hood shape.)
    def b_e_stale(r):
        clean_tree(r); asset(r, "assets/healed.png", "regenerated-bytes")
        write_import(r, "assets/healed.png", "uid://healed", "NONE", extra="valid=false")
        sidecar(r, "assets/healed.png", "d41d8cd98f00b204e9800998ecf8427e")
    case("E_stale_marker_not_charged", b_e_stale, "GREEN", None, forbid_prefix="E-LIVE:")

    case("empty", lambda r: os.makedirs(os.path.join(r, "assets"), exist_ok=True),
         "RED", "A RED ON EMPTY")

    print("%-22s %-7s %-7s %s" % ("CASE", "VERDICT", "RESULT", "FIRST FAIL"))
    for n, v, s, f in results:
        print("%-22s %-7s %-7s %s" % (n, v, s, f))
    if not scratch:
        shutil.rmtree(base, ignore_errors=True)
    print()
    if failures:
        print("SELFTEST RED - these cases did not behave: %s" % ", ".join(failures))
        return 1
    print("SELFTEST GREEN - %d/%d cases behaved; every check moved and the "
          "accounting identity held in all of them." % (len(results), len(results)))
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else None))
