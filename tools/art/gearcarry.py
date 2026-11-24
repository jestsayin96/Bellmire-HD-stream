"""_gearcarry - READ the engine's carry for ONE arbitrary res:// path.

WHY THIS FILE EXISTS, AND IT IS A FAULT IN MY OWN INSTRUMENT.
`_wandfit.py` pass 1 wrote, correctly and out loud, that `gear.gd` has no ROW
for `assets/gear/wand_crystal.glb`, recorded `carry_assumed: "staff"`, and
measured the staff basis. The team lead read the file, agreed it did not guess
- and then read the part I stopped at. `gear.gd` keys BOTH accessors by PATH
and BOTH END IN A DEFAULT ARM:

  held_rot   (gear.gd:250-271) -> `return Vector3.ZERO`
  hand_scale (gear.gd:290-315) -> `return 0.62 if path.begins_with(KIT) else 1.0`

and `KIT` is `res://assets/gear/` (gear.gd:10), which is exactly where the wand
sits. SO THERE IS NO HOLE. The carry the engine would give this model today is
DETERMINATE, with no wiring from any lane, and it is held_rot (0,0,0) at
hand_scale 0.62 - not the staff's (0,0,90) at 1.9. My register said "no entry,
so assumed" where the honest reading is "no ROW, and the FALLBACK is the
answer". Same family as weaponfit's FAULT 5 and FAULT 6 in a new shape: that
time the register never read gear.gd at all, this time it read it for a row and
stopped where there was none instead of reading the branch that catches
everything else.

SO THIS IS A READER, NOT A CONSTANT. It walks the real branches of the real
function in SOURCE ORDER, resolves gear.gd's own path consts, and evaluates
them against the path under test exactly as the engine would. If the game build
ever gives the wand a row, this file picks it up on the next run instead of
going stale. RED ON EMPTY and RED ON UNPARSED: if the function body cannot be
found, or if any `return` in it was not turned into an arm, this raises rather
than falling back to a number with a decimal point on it.
"""
import re

_CONST = re.compile(r'^\s*const\s+([A-Z_][A-Z_0-9]*)\s*:=\s*"([^"]*)"')
_FUNC = re.compile(r'^\s*static\s+func\s+([A-Za-z_][A-Za-z_0-9]*)\s*\(')


def read_consts(src):
    out = {}
    for line in src.splitlines():
        m = _CONST.match(line)
        if m:
            out[m.group(1)] = m.group(2)
    return out


def func_body(src, name):
    """The lines of one static func, by indentation. Red on empty."""
    lines = src.splitlines()
    start = None
    for i, line in enumerate(lines):
        m = _FUNC.match(line)
        if m and m.group(1) == name:
            start = i + 1
            break
    if start is None:
        raise SystemExit("GEARCARRY FAIL - no `static func %s(` in gear.gd. "
                         "Refusing to assume a carry I cannot read." % name)
    body = []
    for line in lines[start:]:
        if line.strip() == "":
            continue
        if not line[:1].isspace():
            break
        body.append(line)
    if not body:
        raise SystemExit("GEARCARRY FAIL - `%s` has an empty body." % name)
    return body


def _expr(txt, consts):
    """`DUN + "staff_"` / `ART` / `"lit"` -> the literal string it builds."""
    txt = txt.strip()
    out = ""
    for part in txt.split("+"):
        part = part.strip()
        if part.startswith('"') and part.endswith('"'):
            out += part[1:-1]
        elif part in consts:
            out += consts[part]
        else:
            raise SystemExit("GEARCARRY FAIL - cannot resolve %r in gear.gd "
                             "(known consts: %s)" % (part, ", ".join(sorted(consts))))
    return out


_IF_BEGINS = re.compile(r'^\s*if\s+path\.begins_with\((.+)\)\s*:\s*$')
_IF_ENDS = re.compile(r'^\s*if\s+path\.ends_with\((.+)\)\s*:\s*$')
_IF_EQ = re.compile(r'^\s*if\s+path\s*==\s*(.+?)\s*:\s*$')
_RET = re.compile(r'^\s*return\s+(.+?)\s*$')
_RET_TERN = re.compile(r'^\s*return\s+(.+?)\s+if\s+path\.begins_with\((.+?)\)\s+else\s+(.+?)\s*$')


def arms(src, name, consts):
    """Every branch of the function, in source order.
    Each arm: (kind, needle, value_text). kind in begins/ends/eq/default."""
    body = func_body(src, name)
    code = []
    for line in body:
        s = line.split("##")[0].split("#")[0].rstrip()
        if s.strip():
            code.append(s)
    out, pend, n_ret = [], None, 0
    for s in code:
        if _RET.match(s):
            n_ret += 1
        t = _RET_TERN.match(s)
        if t:
            if pend is not None:
                raise SystemExit("GEARCARRY FAIL - ternary return under a "
                                 "condition in %s; unhandled shape: %r" % (name, s))
            out.append(("begins", _expr(t.group(2), consts), t.group(1)))
            out.append(("default", None, t.group(3)))
            continue
        r = _RET.match(s)
        if r:
            if pend is None:
                out.append(("default", None, r.group(1)))
            else:
                out.append((pend[0], pend[1], r.group(1)))
                pend = None
            continue
        for rx, kind in ((_IF_BEGINS, "begins"), (_IF_ENDS, "ends"), (_IF_EQ, "eq")):
            m = rx.match(s)
            if m:
                if pend is not None:
                    raise SystemExit("GEARCARRY FAIL - two conditions with no "
                                     "return between them in %s" % name)
                pend = (kind, _expr(m.group(1), consts))
                break
        else:
            if not s.strip().startswith(("if ", "return")):
                continue
            raise SystemExit("GEARCARRY FAIL - unparsed line in %s: %r. This "
                             "file will not score a carry it did not read "
                             "whole." % (name, s))
    if pend is not None:
        raise SystemExit("GEARCARRY FAIL - trailing condition with no return in %s" % name)
    if len(out) < n_ret:
        raise SystemExit("GEARCARRY FAIL - %s has %d `return`s and I built %d "
                         "arms. Something in that function is a shape I do not "
                         "read, so every number below would be a guess."
                         % (name, n_ret, len(out)))
    if not out or out[-1][0] != "default":
        raise SystemExit("GEARCARRY FAIL - %s has no final default arm, so a "
                         "path that matches nothing has no answer." % name)
    return out


def _match(kind, needle, path):
    if kind == "default":
        return True
    if kind == "begins":
        return path.startswith(needle)
    if kind == "ends":
        return path.endswith(needle)
    return path == needle


def evaluate(src, name, path, consts):
    """(value_text, arm_index, arm_description) - first match wins, as GDScript."""
    aa = arms(src, name, consts)
    for i, (kind, needle, val) in enumerate(aa):
        if _match(kind, needle, path):
            desc = "default" if kind == "default" else "%s %r" % (kind, needle)
            return val, i, desc, len(aa)
    raise SystemExit("GEARCARRY FAIL - no arm of %s matched %r" % (name, path))


def vec3(txt):
    t = txt.strip()
    if t == "Vector3.ZERO":
        return [0.0, 0.0, 0.0]
    m = re.match(r'^Vector3\(([^)]*)\)$', t)
    if not m:
        raise SystemExit("GEARCARRY FAIL - not a Vector3 literal: %r" % txt)
    parts = [p.strip() for p in m.group(1).split(",")]
    if len(parts) != 3:
        raise SystemExit("GEARCARRY FAIL - Vector3 with %d parts: %r" % (len(parts), txt))
    try:
        return [float(p) for p in parts]
    except ValueError:
        raise SystemExit("GEARCARRY FAIL - non-numeric Vector3: %r" % txt)


def carry(gear_path, res_path):
    with open(gear_path, encoding="utf-8", errors="replace") as fh:
        src = fh.read()
    consts = read_consts(src)
    rt, ri, rd, rn = evaluate(src, "held_rot", res_path, consts)
    hs, hi, hd, hn = evaluate(src, "hand_scale", res_path, consts)
    try:
        scale = float(hs)
    except ValueError:
        raise SystemExit("GEARCARRY FAIL - hand_scale arm is not a number: %r" % hs)
    return dict(res_path=res_path,
                held_rot_deg=vec3(rt), held_rot_arm=rd,
                held_rot_arm_index=ri, held_rot_arms=rn,
                hand_scale=scale, hand_scale_arm=hd,
                hand_scale_arm_index=hi, hand_scale_arms=hn,
                consts={k: v for k, v in consts.items() if k in ("KIT", "DUN", "ART", "ADV")})
