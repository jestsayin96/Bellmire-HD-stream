"""Red-proof for townlib.ladder_gate - runs with NO Blender and NO bridge.

It loads the REAL shipped `ladder_gate` out of `townlib.py` by AST and execs
only that function, so this validates the code that ships rather than a copy
pasted next to it. `townlib` itself imports bpy and cannot be imported here.

Cases are the four REAL recorded sheets on disk (three well runs from the
06:4x-06:50 logs, one hall run from its _report.json) plus synthetic negative
controls for the faults no real run happens to contain. A gate is only proved
by what it REJECTS, so every control must go RED.
"""
import ast, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))


def load_gate():
    src = open(os.path.join(HERE, "townlib.py"), encoding="utf8").read()
    tree = ast.parse(src)
    ns = {}
    for node in tree.body:
        if isinstance(node, ast.Assign) and getattr(
                node.targets[0], "id", "") == "LADDER_H_FRAC_FLOOR":
            exec(compile(ast.Module([node], []), "<townlib>", "exec"), ns)
        if isinstance(node, ast.FunctionDef) and node.name == "ladder_gate":
            exec(compile(ast.Module([node], []), "<townlib>", "exec"), ns)
    if "ladder_gate" not in ns:
        print("RED ON EMPTY: ladder_gate not found in townlib.py")
        sys.exit(1)
    return ns["ladder_gate"], ns["LADDER_H_FRAC_FLOOR"]


def well_runs():
    out = {}
    for name, f in [("well 06:46 draft", "_townbuild_gen.log"),
                    ("well 06:49", "_townbuild_gen2.log"),
                    ("well 06:50 shipped", "_townbuild_gen3.log")]:
        p = os.path.join(REPO, "bellmire-art", f)
        if not os.path.exists(p):
            p = os.path.join(os.getcwd(), f)
        if not os.path.exists(p):
            continue
        t = open(p, encoding="utf8", errors="replace").read()
        i = t.rfind("TOWNBUILD ")
        if i < 0:
            continue
        r = json.loads(t[i + 10:t.index("\n", i)])
        out[name] = {
            "sil": r["sheet"]["silhouette"],
            "order": ["well_t1", "well_t2", "well_t3"],
            # townbuild dims are [x, y, HEIGHT]
            "h_m": {k: v["dims"][2] for k, v in r["tiers"].items()},
            "growth": "free",
            "was": r["verdict"],
        }
    return out


def hall_run():
    p = os.path.join(os.getcwd(), "renders", "art", "town", "hall", "_report.json")
    if not os.path.exists(p):
        return {}
    r = json.load(open(p, encoding="utf8"))
    sil = r.get("sheet", {}).get("silhouette")
    if not sil:
        return {}
    # heights measured by _glbprobe (dims_m is [x, HEIGHT, z])
    g = os.path.join(os.getcwd(), "renders", "art", "town",
                     "_glbprobe_all_buildings.json")
    h = {}
    if os.path.exists(g):
        for f in json.load(open(g, encoding="utf8"))["files"]:
            m = re.match(r"town_(hall_t\d)\.glb$", f.get("file", ""))
            if m and f.get("dims_m"):
                h[m.group(1)] = f["dims_m"][1]
    return {"hall 08:50 shipped": {
        "sil": sil, "order": ["hall_t1", "hall_t2", "hall_t3"],
        "h_m": h, "growth": "monotonic", "was": r.get("verdict"),
        "resy": 820}}


def main():
    gate, floor = load_gate()
    RY = 760
    cases, fails = [], 0

    real = well_runs()
    real.update(hall_run())
    expect = {"well 06:46 draft": "RED", "well 06:49": "GREEN",
              "well 06:50 shipped": "GREEN", "hall 08:50 shipped": "GREEN"}
    for name, c in real.items():
        errs = gate(c["sil"], c["order"], c["h_m"], c.get("resy", RY),
                    growth=c["growth"])
        cases.append((name, "RED" if errs else "GREEN",
                      expect.get(name, "?"), c["was"], errs))

    # ---- synthetic negative controls: each MUST go RED ----
    good = real.get("well 06:50 shipped")
    if good:
        s, o, hm = good["sil"], good["order"], good["h_m"]
        drop = {k: v for k, v in s.items() if k != "well_t2"}
        cases.append(("CTRL tier absent", None, "RED", "-",
                      gate(drop, o, hm, RY)))
        zero = dict(s); zero["well_t2"] = {"px": 0, "h_px": 0, "w_px": 0}
        cases.append(("CTRL tier blank", None, "RED", "-",
                      gate(zero, o, hm, RY)))
        same = {k: dict(s["well_t2"]) for k in o}
        cases.append(("CTRL all tiers identical", None, "RED", "-",
                      gate(same, o, hm, RY)))
        half = {k: dict(v) for k, v in s.items()}
        half["well_t3"] = {"px": s["well_t3"]["px"] // 4,
                           "h_px": s["well_t3"]["h_px"] // 2,
                           "w_px": s["well_t3"]["w_px"] // 2}
        cases.append(("CTRL one tier half scale", None, "RED", "-",
                      gate(half, o, hm, RY)))
        cases.append(("CTRL empty sil", None, "RED", "-", gate({}, o, hm, RY)))
        cases.append(("CTRL zero sheet height", None, "RED", "-",
                      gate(s, o, hm, 0)))
        cases.append(("CTRL well declared monotonic (hall rule)", None, "RED",
                      "-", gate(s, o, hm, RY, growth="monotonic")))

    print("%-42s %-6s %-8s %-7s %s"
          % ("case", "gate", "expected", "old", "errors"))
    for name, got, exp, was, errs in cases:
        got = got or ("RED" if errs else "GREEN")
        ok = (got == exp)
        fails += (0 if ok else 1)
        print("%-42s %-6s %-8s %-7s %s %s"
              % (name, got, exp, was, "OK " if ok else "FAIL", errs or ""))

    print("\nfloor in use: %0.2f of sheet height" % floor)
    print("VERDICT: %s  (%d case(s) failed)"
          % ("GREEN" if fails == 0 else "RED", fails))
    sys.exit(1 if fails else 0)


main()
