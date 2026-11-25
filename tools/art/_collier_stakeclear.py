"""
COLLIER PASS 11, OPTION (b): CAN THE STAKE RING BE ROTATED OFF THE VENTS?

WHAT THIS IS, AND WHAT IT IS NOT.
  This is a CHEAP ANALYTIC PREDICTOR of one single question: does a stake of
  the clamp's eight-fold withy ring stand in front of a vent mouth on the
  FRONT camera?  It is plane geometry read straight off the shipped
  constants in `minibosses.py` (`collier()`), not a render and not a
  raycast.  It exists to turn a sweep that would cost eight Blender renders
  into ONE number the next firing renders once.

  IT CANNOT SEE, and the list below is the honest list of what it is blind
  to - the 17 Nov pass-11 lesson, third time on this body:
    - the PLUGS and the SODS.  It models stakes only.  The -78 vent is
      killed by the plug bundle and the -10 vent is nicked by the sod at
      bearing 8; this instrument says nothing about either and must not be
      read as clearing them.
    - the LASHING RING at z 0.430-0.474, and therefore the ring-gap risk
      that is the whole reason the 0.360 row height is still behind a flag.
    - whether eight stakes rotated off their shipped bearings still READ as
      a staked clamp, or read as a gap on one flank.  Pass 5's FIX M walked
      stake heads off the earth while fixing something else; a rotation can
      do the same thing to the -X flank where the plug cradle sits.
    - the SIDE and BACK cameras entirely.
  So a green here is permission to RENDER one candidate, nothing more.

THE VALIDATION ARM RUNS EVERY TIME AND THE SCRIPT IS USELESS WITHOUT IT.
  AND MY FIRST VERSION OF THE ARM WAS ITSELF WRONG, WHICH IS RECORDED HERE
  RATHER THAN QUIETLY FIXED.  Rev 0 tested this model against the raycast's
  ATTRIBUTION column and went RED, because the model puts a stake in front
  of -78 where the raycast names `plugs`.  A BVH raycast attributes each ray
  to its FIRST hit, so the attribution column can name the NEAREST occluder
  and can never rule out a second one behind it.  Testing against it made a
  correct prediction look wrong.  The arm now tests against the VISIBILITY
  column - what the viewer's camera actually gets - which is the falsifiable
  thing, and it keeps teeth in both directions (see `validate`).
  THE FIX CHANGED A FINDING, not just a verdict: -78 has TWO occluders, the
  plug bundle AND a stake.  So shortlist option (c), lifting the plug bundle
  clear of the -78 sight line, would NOT on its own heal -78.  Nothing in
  the tree said that before this run.
  `tools/art/_collier_occlude.py` measured the shipped body with a BVH
  raycast off the real mouth solid.  Its attribution, by bearing:
      -78  stopped by `plugs` 11/13      -42  stopped by nothing
      -10  stopped by `clamp`  1/13      +24  stopped by `clamp` 13/13
  The 1/13 at -10 is the sod, NOT a stake (pass 10 correction (d): there is
  no stake at bearing 0; they sit at 22.5 + 45i).  So the raycast says
  EXACTLY ONE vent is behind a stake, and it is +24, behind the +22.5 stake.
  If this model cannot reproduce that - one vent occluded, that vent +24 -
  it is wrong and prints RED and no sweep is reported.  It also goes RED ON
  EMPTY: a sweep that evaluates zero candidates, or a validation that
  compares zero vents, is RED, not green.
"""
import math

# ---- shipped constants, copied from minibosses.py collier() ------------
STAKE_N      = 8
STAKE_BASE   = 22.5          # bearing of stake 0; ring is BASE + 45*i
STAKE_LO_R   = 0.928
STAKE_HI_R   = 0.572
STAKE_LO_OFF = (0.000, -0.030, 0.050)
STAKE_HI_OFF = (0.150, -0.104, 0.812)
STAKE_RADII  = (0.040, 0.034, 0.026)      # at t = 0, 0.5, 1

VENT_ARC   = (-78.0, -42.0, -10.0, 24.0)  # pass 8, frozen
MOUTH_R    = 0.760        # centre of the mouth solid along d
MOUTH_HALF = 0.041        # half of scone h=0.082, along the axis d
MOUTH_RAD  = 0.081        # mouth cone radius, perpendicular to d
MOUTH_YOFF = -0.040

def _ventz(i, flat360=False):
    """Shipped pass-8 stagger, or the staged flat row."""
    return 0.360 if flat360 else (0.250 + 0.048 * (1 if i in (1, 2) else 0))

def _d(deg):
    a = math.radians(deg)
    return (math.sin(a), -math.cos(a))

def stake_at(bearing_deg, z):
    """Screen-x, depth-y and radius of a stake where it crosses height z.
    Linear in z along the tube; the mid control point's +0.016 z bump is
    ignored and is worth 0.016 m = 2 px, which is recorded not hidden."""
    t = (z - STAKE_LO_OFF[2]) / (STAKE_HI_OFF[2] - STAKE_LO_OFF[2])
    if not (0.0 <= t <= 1.0):
        return None
    sx, sy = _d(bearing_deg)
    r = STAKE_LO_R + t * (STAKE_HI_R - STAKE_LO_R)
    x = sx * r + STAKE_LO_OFF[0] + t * (STAKE_HI_OFF[0] - STAKE_LO_OFF[0])
    y = sy * r + STAKE_LO_OFF[1] + t * (STAKE_HI_OFF[1] - STAKE_LO_OFF[1])
    if t <= 0.5:
        rad = STAKE_RADII[0] + (t / 0.5) * (STAKE_RADII[1] - STAKE_RADII[0])
    else:
        rad = STAKE_RADII[1] + ((t - 0.5) / 0.5) * (STAKE_RADII[2] - STAKE_RADII[1])
    return x, y, rad

def vent_at(bearing_deg, z):
    """Screen-x centre, x half-extent and nearest depth-y of a vent mouth."""
    sx, sy = _d(bearing_deg)
    x = sx * MOUTH_R
    y = sy * MOUTH_R + MOUTH_YOFF
    # the axis contributes |sin| of its half-length; the disc contributes
    # |cos| of its radius, the perpendicular in the horizontal plane.
    half = MOUTH_HALF * abs(sx) + MOUTH_RAD * abs(sy)
    # nearest point of the solid to the camera (-Y), along the axis
    y_near = y - MOUTH_HALF * abs(sy) - MOUTH_RAD * abs(sx)
    return x, half, y_near

def covered_share(vent_bearing, z, stake_base):
    """Share of the vent's screen-x width that stakes stand in front of."""
    vx, vhalf, vy = vent_at(vent_bearing, z)
    lo, hi = vx - vhalf, vx + vhalf
    spans = []
    for i in range(STAKE_N):
        s = stake_at(stake_base + 45.0 * i, z)
        if s is None:
            continue
        sx, sy, srad = s
        if sy >= vy:            # behind the vent: cannot occlude it
            continue
        a, b = max(lo, sx - srad), min(hi, sx + srad)
        if b > a:
            spans.append((a, b))
    if not spans:
        return 0.0, []
    spans.sort()
    merged = [list(spans[0])]
    for a, b in spans[1:]:
        if a <= merged[-1][1]:
            merged[-1][1] = max(merged[-1][1], b)
        else:
            merged.append([a, b])
    tot = sum(b - a for a, b in merged)
    width = hi - lo
    return (tot / width if width > 0 else 0.0), merged

HIT = 0.10   # a stake across >=10% of a vent's screen width is "in front of it"

def validate():
    """Test against the raycast's VISIBILITY column, not its attribution.

    Two-sided, and both sides have teeth:
      (A) every vent the raycast SAW (vis >= 0.50) must have ZERO stake
          cover here.  -42 renders 460 px and -10 renders 449 px; a model
          that puts a stake across either is refuted by the picture.
      (B) +24 is attributed to `clamp` 13/13 - a POSITIVE attribution, which
          is falsifiable - so the model must put a stake across it.
    What the arm deliberately does NOT assert: that -78 is stake-free.  The
    raycast cannot answer that (the plugs are hit first), so asserting it
    either way would be inventing evidence.
    """
    # measured by tools/art/_collier_occlude.py on the shipped body
    MEASURED_VIS = {-78.0: 0.00, -42.0: 0.74, -10.0: 0.91, 24.0: 0.00}
    STAKE_ATTRIB = {24.0: True}          # raycast named a clamp stake here
    rows, fails = [], []
    for i, b in enumerate(VENT_ARC):
        z = _ventz(i)
        share, _ = covered_share(b, z, STAKE_BASE)
        vis = MEASURED_VIS[b]
        rows.append((b, z, share, vis))
        if vis >= 0.50 and share >= HIT:
            fails.append("vent %+.1f renders clearly (vis %.2f) but the model "
                         "puts a stake across %.0f%% of it" % (b, vis, share * 100))
        if STAKE_ATTRIB.get(b) and share < HIT:
            fails.append("the raycast attributes vent %+.1f to a clamp stake "
                         "13/13 but the model finds no stake there" % b)
    if not rows:
        return False, "RED ON EMPTY: validation compared zero vents", rows
    if not any(v >= 0.50 for _, _, _, v in rows):
        return False, ("RED ON EMPTY: no vent in the comparison has a measured "
                       "visibility >= 0.50, so arm (A) tested nothing"), rows
    if fails:
        return False, "RED: " + "; ".join(fails), rows
    extra = [b for (b, _, sh, v) in rows
             if sh >= HIT and not STAKE_ATTRIB.get(b)]
    note = ("model agrees with every measured visibility; it additionally "
            "finds a stake in front of %s, which the raycast cannot confirm "
            "or deny because the plugs are hit first"
            % (", ".join("%+.0f" % b for b in extra) if extra else "nothing"))
    return True, note, rows

def sweep(flat360=False, step=1.0):
    """Rotate the whole ring and find bases where NO vent is behind a stake."""
    out = []
    n = 0
    base = 0.0
    while base < 45.0 - 1e-9:        # 45 deg is the ring's full period
        n += 1
        worst, worst_b = 0.0, None
        for i, b in enumerate(VENT_ARC):
            share, _ = covered_share(b, _ventz(i, flat360), base)
            if share > worst:
                worst, worst_b = share, b
        out.append((base, worst, worst_b))
        base += step
    if n == 0:
        raise SystemExit("RED ON EMPTY: the sweep evaluated zero candidates")
    return out

if __name__ == "__main__":
    ok, msg, rows = validate()
    print("=== VALIDATION ARM (shipped pass-8 body, stake base %.1f) ===" % STAKE_BASE)
    for b, z, share, vis in rows:
        print("  vent %+6.1f  z %.3f   stake cover %.3f   measured vis %.2f %s"
              % (b, z, share, vis, "<-- behind a stake" if share >= HIT else ""))
    print(("  VALIDATION: %s" % msg))
    if not ok:
        raise SystemExit("RED - sweep NOT reported, the predictor is not trusted")
    step = 1.0
    for flat, label in ((False, "pass-8 staggered row"), (True, "staged flat row z=0.360")):
        res = sweep(flat360=flat, step=step)
        clear = [(b, w) for b, w, _ in res if w < HIT]
        print("\n=== SWEEP, %s: %d candidate bases, %d clear ===" % (label, len(res), len(clear)))
        if not clear:
            print("  NO rotation of the ring clears every vent. Option (b) is dead for this row.")
        else:
            # *** THE RING'S PERIOD IS 45 DEG, SO 44 AND 0 ARE ADJACENT. ***
            # Rev 1 of this script printed the wrap-around band as TWO bands
            # and so reported two candidate centres where there is one. A
            # sweep over a circular parameter that does not wrap is reading
            # its own seam as a boundary.
            bs = [b for b, _ in clear]
            runs, cur = [], [bs[0], bs[0]]
            for b in bs[1:]:
                if b - cur[1] <= step + 1e-9:
                    cur[1] = b
                else:
                    runs.append(tuple(cur)); cur = [b, b]
            runs.append(tuple(cur))
            if (len(runs) > 1 and abs(runs[0][0] - 0.0) < 1e-9
                    and abs(runs[-1][1] - (45.0 - step)) < 1e-9):
                a0, b0 = runs[-1][0], runs[0][1] + 45.0
                runs = [(a0, b0)] + runs[1:-1]
                print("  (the sweep wraps: the band across 45/0 is ONE band, not two)")
            for a, b in runs:
                mid = ((a + b) / 2.0) % 45.0
                mv = mid - STAKE_BASE
                if mv < -22.5: mv += 45.0
                if mv >  22.5: mv -= 45.0
                print("  clear band %5.1f ... %5.1f deg (width %4.1f)  centre %5.1f"
                      "   shipped %.1f, move %+.1f" % (a, b, b - a, mid, STAKE_BASE, mv))
        print("  per-vent stake cover AT THE SHIPPED BASE %.1f:" % STAKE_BASE)
        for i, b in enumerate(VENT_ARC):
            sh, _ = covered_share(b, _ventz(i, flat), STAKE_BASE)
            print("      vent %+6.1f  z %.3f   cover %.3f" % (b, _ventz(i, flat), sh))
        worstrow = max(res, key=lambda r: r[1])
        print("  worst base in sweep: %.1f deg, cover %.3f on vent %+.1f"
              % (worstrow[0], worstrow[1], worstrow[2] if worstrow[2] is not None else 0.0))
