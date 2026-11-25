"""tools/art/_lock.py - THE ART LANE'S RUN_LOCK.txt WRITER. BIND YOUR STAMPS HERE.

WHY THIS FILE EXISTS, SAID PLAINLY:
  On 24 Nov 2026 the art lane's 22:42 RUNNING/IDLE pair went into docs/RUN_LOCK.txt
  with FOUR UNFORMATTED `%s` PLACEHOLDERS where the timestamps belong. The prose
  inside the IDLE carried claim 22:42:46 / cap 23:07:46 / declared 22:50:46, which is
  the only reason it was not scored as a lock fault - but no other lane should have to
  read art's prose to find art's stamp.

  THE ROOT CAUSE WAS NOT A TYPO: THERE WAS NO HELPER. Every art seat retyped the lock
  template inline in a one-shot bridge call, so the `%` template and its arguments
  lived in two places that nothing checked against each other. A seat that forgot the
  `% (a, b, c, d)` tail shipped `%s` and the file took it silently.

  THE FIX IS STRUCTURAL: there is no template to forget any more. Stamps are bound by
  f-string inside this module from real datetimes, and _bound() REFUSES to return a
  line that still carries an unbound placeholder or that is missing a stamp. A lane
  that cannot write a bad line cannot ship one.

RULES THIS MODULE ENFORCES (all of them are Mr. E's or the team lead's, not mine):
  - CENTRAL TIME, read off the machine. In November CT is CST = UTC MINUS 6. A stamp
    ahead of the machine is a future stamp. We take the OS's own local offset rather
    than hardcoding -06:00, and assert it is a whole number of minutes.
  - cap = claim + 25 minutes EXACTLY, derived, never typed. (A sibling lane wrote a
    cap one second over its true cap this same evening by typing it.)
  - declared finish is a real declaration: it must be at or before the cap and at or
    after the claim, or this module raises rather than writing a finish nobody means.
  - THE LOCK LIVES IN R, NOT IN W5. W5's docs/RUN_LOCK.txt copy is stale to
    20 Nov 12:15 - a lane that reads the lock out of its own worktree is reading four
    days of nothing. LOCK_PATH below points at R on purpose.
  - RED ON EMPTY: an empty body, an empty lane, an empty release note is a raise,
    not a blank line appended to the shared lock file.

NOT a Godot script, not a .gd, nothing outside tools/art/. Runs on Blender's python
on the Windows side (there is no system python on cruzader), import it by path.
"""

from __future__ import annotations

import datetime as _dt
import os
import re

# The lock lives in the MAIN repo's working tree. Do not point this at W5.
LOCK_PATH = r"C:\hd adventure\jests-hd-medieval-adventure\docs\RUN_LOCK.txt"

CAP_MINUTES = 25
LANE = "art"

# Anything that means "a stamp did not get bound". `%s` is the one that actually
# shipped; the rest are the near neighbours of the same mistake.
_UNBOUND = re.compile(r"%[sdrfi]\b|%\([a-zA-Z_]+\)|\{[a-zA-Z_][a-zA-Z_0-9]*\}|\{\}|<stamp>|None")

_STAMP = re.compile(r"\b\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}\b")


def now() -> _dt.datetime:
    """Machine-local aware 'now', seconds resolution. CT on cruzader."""
    return _dt.datetime.now().astimezone().replace(microsecond=0)


def iso(dt: _dt.datetime) -> str:
    """Full stamp WITH the offset, e.g. 2026-11-24T23:41:02-06:00."""
    if dt.tzinfo is None:
        raise ValueError("iso(): naive datetime - a stamp with no offset is not a stamp")
    off = dt.utcoffset()
    if off is None or off.total_seconds() % 60 != 0:
        raise ValueError(f"iso(): offset is not whole minutes: {off!r}")
    return dt.isoformat(timespec="seconds")


def clock(dt: _dt.datetime) -> str:
    """Bare wall clock, e.g. 23:41:02 - for the cap/declared shorthand."""
    return dt.strftime("%H:%M:%S")


def _bound(line: str, stamps_expected: int) -> str:
    """THE GUARD. A line that still carries a placeholder never leaves this module."""
    if not line or not line.strip():
        raise ValueError("_bound(): empty lock line - RED ON EMPTY")
    hit = _UNBOUND.search(line)
    if hit:
        raise ValueError(
            f"_bound(): UNBOUND PLACEHOLDER {hit.group(0)!r} at char {hit.start()} - "
            "this is the exact 22:42 fault; bind the argument, do not write the line"
        )
    found = len(_STAMP.findall(line))
    if found < stamps_expected:
        raise ValueError(
            f"_bound(): {found} full stamps in the line, expected at least "
            f"{stamps_expected} - a lock line with no readable stamp is the fault"
        )
    if "\n" in line:
        raise ValueError("_bound(): newline inside a lock line - one line per entry")
    return line


def window(claim: _dt.datetime | None = None,
           declared_minutes: int = 20,
           declared: _dt.datetime | None = None):
    """Derive (claim, cap, declared). cap is ALWAYS claim+25, computed not typed."""
    claim = claim or now()
    cap = claim + _dt.timedelta(minutes=CAP_MINUTES)
    if declared is None:
        if declared_minutes <= 0:
            raise ValueError("window(): declared_minutes must be > 0 - declare a finish you mean")
        declared = claim + _dt.timedelta(minutes=declared_minutes)
    if declared < claim:
        raise ValueError("window(): declared finish is before the claim")
    if declared > cap:
        raise ValueError(
            f"window(): declared finish {clock(declared)} is past the cap {clock(cap)} - "
            "split the job and carry the remainder, do not declare a crossing"
        )
    return claim, cap, declared


def running_line(body: str,
                 claim: _dt.datetime,
                 cap: _dt.datetime,
                 declared: _dt.datetime,
                 free_because: str = "",
                 lane: str = LANE) -> str:
    """The RUNNING line. Four bound stamps: claim (twice, head and parenthetical), cap, declared."""
    if not body or not body.strip():
        raise ValueError("running_line(): empty body - say what the window is for")
    tail = f" {free_because.strip()}" if free_because and free_because.strip() else ""
    line = (f"RUNNING {iso(claim)} ({lane}: claim {iso(claim)}, "
            f"cap claim+{CAP_MINUTES} = {iso(cap)}, declared finish {iso(declared)}; "
            f"{body.strip()}{tail})")
    return _bound(line, stamps_expected=4)


def idle_line(note: str,
              claim: _dt.datetime,
              cap: _dt.datetime,
              declared: _dt.datetime,
              released: _dt.datetime | None = None,
              lane: str = LANE) -> str:
    """The IDLE line. Releases the window immediately, whatever the RUNNING declared."""
    if not note or not note.strip():
        raise ValueError("idle_line(): empty note - RED ON EMPTY")
    released = released or now()
    crossing = "released PAST the declared finish" if released > declared else "released inside the declared finish"
    over_cap = " AND PAST THE CAP" if released > cap else ""
    line = (f"IDLE {iso(released)} - {lane}: {note.strip()} "
            f"Claim {iso(claim)}, cap {clock(cap)}, declared {clock(declared)}, "
            f"released {iso(released)} - {crossing}{over_cap}. ({lane})")
    return _bound(line, stamps_expected=3)


def tail(n: int = 12, path: str = LOCK_PATH):
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        lines = fh.read().rstrip("\n").split("\n")
    return lines[-n:]


def holder(path: str = LOCK_PATH):
    """Who holds the lock, by THE YIELD RULE: a RUNNING is live until an IDLE from the
    SAME LANE follows it. Returns (lane_or_None, evidence_line)."""
    lines = [l for l in tail(400, path) if l.strip()]
    for i in range(len(lines) - 1, -1, -1):
        l = lines[i]
        if l.startswith("RUNNING"):
            lane = _lane_of(l)
            for later in lines[i + 1:]:
                if later.startswith("IDLE") and _lane_of(later) == lane:
                    return None, later
            return (lane or "unknown"), l
        if l.startswith("IDLE"):
            return None, l
    return None, ""


def _lane_of(line: str):
    m = re.search(r"\((?:[Aa]rt|ART)\b", line)
    if m:
        return "art"
    m = re.match(r"RUNNING\s+\S+\s+\(([^,;:)]+)", line)
    if m:
        return m.group(1).strip().lower().split(" b")[0].strip()
    m = re.match(r"IDLE\s+\S+\s+-\s+([^:,]+)", line)
    if m:
        return m.group(1).strip().lower()
    return None


def append(line: str, path: str = LOCK_PATH, blank_before: bool = False) -> dict:
    """Append ONE already-bound line. Re-checks the guard at the file boundary."""
    _bound(line, stamps_expected=3)
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        data = fh.read()
    if not data.endswith("\n"):
        data += "\n"
    if blank_before and not data.endswith("\n\n"):
        data += "\n"
    data += line + "\n"
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(data)
    return {"wrote": line, "bytes": len(data), "path": path}


def selftest() -> dict:
    """Prove the guard BOTH WAYS. A check that only ever passes is not a check."""
    out = {"pass": [], "fail": []}
    t0 = _dt.datetime(2026, 11, 24, 23, 40, 0,
                      tzinfo=_dt.timezone(_dt.timedelta(hours=-6)))
    claim, cap, declared = window(claim=t0, declared_minutes=20)

    # GREEN ARM: a real line binds and carries its stamps.
    r = running_line("selftest, writes nothing", claim, cap, declared, "Lock free: selftest.")
    i = idle_line("selftest note.", claim, cap, declared, released=t0 + _dt.timedelta(minutes=5))
    for name, line, want in (("running", r, "23:40:00-06:00"), ("idle", i, "00:05:00")):
        if want.split("-")[0] in line or want in line:
            out["pass"].append(f"{name} line carries its stamp")
        else:
            out["fail"].append(f"{name} line lost its stamp: {line}")
    if "cap claim+25 = 2026-11-25T00:05:00-06:00" in r:
        out["pass"].append("cap is derived claim+25, not typed")
    else:
        out["fail"].append("cap not derived: " + r)

    # RED ARM 1: the 22:42 fault itself must be REFUSED.
    try:
        _bound("RUNNING %s (art: claim %s, cap claim+25 = %s, declared finish %s; x)", 4)
        out["fail"].append("THE 22:42 LINE WAS ACCEPTED - the guard cannot see the fault")
    except ValueError as e:
        out["pass"].append("22:42 %s line refused: " + str(e)[:60])

    # RED ARM 2: empty body / empty note are refused (RED ON EMPTY).
    for fn, args in (("running_line", ("  ", claim, cap, declared)),
                     ("idle_line", ("", claim, cap, declared))):
        try:
            (running_line if fn == "running_line" else idle_line)(*args)
            out["fail"].append(f"{fn} accepted an empty body")
        except ValueError:
            out["pass"].append(f"{fn} refused an empty body")

    # RED ARM 3: a declared finish past the cap is refused, not written.
    try:
        window(claim=t0, declared_minutes=40)
        out["fail"].append("a declared finish past the cap was accepted")
    except ValueError:
        out["pass"].append("declared finish past cap refused - split, do not cross")

    # RED ARM 4: a stampless line is refused even if it has no placeholder.
    try:
        _bound("RUNNING now (art: claim now, cap soon; x)", 4)
        out["fail"].append("a stampless line was accepted")
    except ValueError:
        out["pass"].append("stampless line refused")

    out["verdict"] = "GREEN" if not out["fail"] else "RED"
    out["n_pass"], out["n_fail"] = len(out["pass"]), len(out["fail"])
    if out["n_pass"] == 0:                      # RED ON EMPTY, applied to the test itself
        out["verdict"] = "RED"
        out["fail"].append("selftest ran zero assertions")
    return out


if __name__ == "__main__":
    import json
    print(json.dumps(selftest(), indent=1))
