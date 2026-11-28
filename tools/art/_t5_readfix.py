"""_t5_readfix - PRESCRIPTIONS THAT `_t5_rx.py` STRUCTURALLY CANNOT REACH.

THE LIMITATION IN MY OWN PRESCRIPTION TOOL, NAMED. `_t5_rx.py` searches
ROTATION ONLY, at the hand_scale gear.gd already ships. That is the right
default - scale is the engine's business and a rotation is cheap - but it
means that when NO rotation reads at the shipped scale, the tool has no move
left and emits the least-bad rotation with no sign that it is least-bad. The
legendary dagger is exactly that cell: every upright carry at hand_scale 0.5
renders the blade as a hairline, and `_t5_rx.py` had no way to say so.

THE DAGGER, SETTLED BY MEASUREMENT AND BY LOOKING, 27 NOV 2026.
  Shipped: gear.gd held_rot Vector3.ZERO, hand_scale 0.5 (gear.gd:305-306).
  Prescribed before today: (-90, 0, 90) at the shipped 0.5. Upright, clip
  0.352, and BLIND - `vis` front 403 / side 957 / back 190 against a 900 px
  floor, one proving view of the two required.
  My own earlier prescription was hand_scale 0.5 -> ~0.75. I MEASURED IT AND
  THEN LOOKED AT IT, AND IT IS WRONG. It does clear the gate (front 1159) and
  the picture is still a gold HAIRLINE, now a 1.04 m one - because the front
  camera sees the blade's 0.11 m EDGE, and `WF.VIS_MIN`'s own comment says 900
  px means "about 30x30", which assumes a compact shape. 1,159 pixels smeared
  down an 18-px-wide line passes a gate it was never meant to pass. That is my
  own `vis` gate being cleared by a lath, and the `show` gate cannot catch it
  because `show` is scale-invariant: best_minor and mid_px grow together.
  THE REAL CAUSE IS FACING, NOT SIZE. `_t5_dagcensus` enumerated all 64 grid
  triples with NO gate filtering: 24 stand the blade upright and EIGHT of them
  put the broad 0.2972 m axis along world X, where the front and back cameras
  see the face. My own `_t5_dagread` stage 1 had thrown every one of them away
  before printing, because it filtered on clip_frac <= 0.37 and the best,
  (0, 0, 90), misses by 1.4 points at 0.384. A search that discards a
  candidate silently reports "it does not exist" when the truth is "I did not
  look at it", and that is the fault of mine this file exists to record.
  clip_frac FALLS as the weapon grows, so the fix is the one combination
  neither tool had tried: face-front AND a modest bump.
  PRESCRIBED: held_rot (0, 0, 90) - the triple gear.gd already ships for the
  bow, the one cell confirmed correct by eye - at hand_scale 0.60.
  Measured on the posed knight by `_t5_dagface`: hang 0.1 deg, ground 0,
  clip_frac 0.346 (ceiling 0.37), border 0.000, show 1.066, blade 0.834 m,
  `vis` front 1598 / side 567 / back 1219 - front and back prove, 78% and 35%
  clear of the floor. The side now sees the edge and does not prove; two of
  three is what WF.MIN_PROVING asks and the two that prove are the two a
  viewer sees most.
  WHAT IT COSTS, SAID OUT LOUD: 0.834 m against 0.695 m shipped. gear.gd:304
  records the .blend at 1.39 m and picked 0.5 to put it "at a long knife".
  0.60 is longer than the pack daggers at their own shipped scale. I LOOKED
  at the render and it still reads as a knife - leaf blade, pommel below the
  fist, tip below the chin - which the 0.75 scale-only arm does not. The
  alternative is 0.55 (0.764 m), which also passes but leaves the back view
  only 3% clear of the floor; 0.60 was chosen for the margin a gate re-run
  every hour needs. BOTH RENDERS ARE ON DISK UNDER renders/art/gear_t5/_rx/
  _dagface/cells/ AND MR. E CAN OVERRULE THE LENGTH BY LOOKING.

THIS FILE PRESCRIBES. IT DOES NOT SHIP. gear.gd is the game build's and the
engine delta is carried in `_t5_rxproof.json.engine_delta` for that lane.
"""

READ_RX = {
    "dagger": {
        "prescribed_triple": [0.0, 0.0, 90.0],
        "prescribed_grip_x": 0.0,
        "prescribed_hand_scale": 0.60,
        "engine_hand_scale": 0.5,
        "source": "_t5_dagface",
        "reason": ("the shipped 0.5 renders the blade edge-on to the front "
                   "and back cameras as a hairline; (0,0,90) turns the face "
                   "to them and 0.60 carries clip_frac under the ceiling"),
        "rejected": {
            "(-90,0,90) @ 0.75": ("clears vis at 1159 px and STILL reads as a "
                                  "hairline - a 1.04 m one. Gate cleared, "
                                  "picture not fixed."),
            "(0,0,90) @ 0.55": ("passes, 0.764 m, but the back view is 929 px "
                                "against a 900 px floor - 3% of margin"),
            "any yaw at hand_scale <= 0.65": ("_t5_dagyaw, 36 candidates, 0 "
                                              "clean: the z term is the "
                                              "STAND-UP term, not a facing "
                                              "term - at z=0 the blade lies "
                                              "flat at hang 89.9"),
        },
    },
}


def apply(rx, log=None):
    """Overlay the readability prescriptions onto an `rx` mapping in place.

    Returns the list of kinds changed. RED ON A MISSING KIND: a prescription
    for a cell the tier does not carry is a stale entry, not a no-op.
    """
    changed = []
    for kind, fix in READ_RX.items():
        if kind not in rx:
            raise SystemExit("READFIX FAIL - prescription for %r but the tier "
                             "has no such cell. Stale entry, not a skip."
                             % kind)
        rec = rx[kind]
        rec["prescribed_triple"] = list(fix["prescribed_triple"])
        rec["prescribed_grip_x"] = fix["prescribed_grip_x"]
        rec["prescribed_hand_scale"] = fix["prescribed_hand_scale"]
        rec["prescribed_by"] = fix["source"]
        rec["prescribed_reason"] = fix["reason"]
        rec["prescribed_rejected"] = fix["rejected"]
        rec["changed"] = True
        changed.append(kind)
        if log:
            print("%s READFIX %s -> rot %s hand_scale %s (%s)"
                  % (log, kind, fix["prescribed_triple"],
                     fix["prescribed_hand_scale"], fix["source"]), flush=True)
    return changed
