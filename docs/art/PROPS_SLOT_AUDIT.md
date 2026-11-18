# THE BARREL FINDING, MEASURED ACROSS assets/props/ - AND OVERTURNED
17 Nov 2026, 17:35-18:20 CT. Art lane. Instrument: `tools/art/propslots.py`.
Report: `renders/art/props/_slot_audit.json`. Pictures:
`renders/art/props/_barrel_a_whole.png`, `_barrel_b_cap110.png`,
`_barrel_c_slot0.png`.

## THE ROW
The team lead carried this lane's own 16:58 finding: `Barrel.gltf` is one
object whose two material slots "sit at the same radius to within 1 mm", which
Z-fights into torn shards **while every opacity check reads green**, and the
lane wrote "other models in this pack may be built the same way". The row:
measure that instead of guessing - how many objects in `assets/props/` carry
two or more slots at a coincident radius?

## THE ANSWER: NONE, INCLUDING THE BARREL. THE FINDING WAS WRONG.
94 .gltf files, 43 with a multi-slot object, 44 multi-slot objects, 52
measurable slot pairs, 22 pairs unmeasurable by the radial test and reported
as unmeasurable rather than as passes. **Zero pairs are coincident within
1 mm.** The Barrel is not one either, and three instruments in a row said so
before I believed them:

- **MEAN RADIUS.** Barrel slot 0 `MI_Trim_Furniture` (the staves, 392 faces,
  r 0.072-0.343) and slot 1 `MI_Trim_Metal` (the hoops, 432 faces,
  r 0.283-0.346). **Mean radii 51 mm apart.** The "1 mm" of the original note
  is the gap between the two slots' *overall maximum* radii (0.34299 vs
  0.34611 - in fact 3.1 mm), taken at two different heights on a cask whose
  staves bulge. Two numbers that never coexist at the same z.
- **TRIANGLE INTERSECTION** (BVH overlap, shallow crossings only, seam pairs
  excluded): **zero** between the Barrel's two slots. They do not touch.
- **SURFACE DISTANCE** (nearest point on the other slot's surface, not the
  nearest face centre): minimum **2.245 mm**, and the normals where they are
  closest are **perpendicular** (|n.n| = 0.023) - the hoop's edge against the
  stave wall. Only 12 of 392 stave faces come within 10 mm of a near-parallel
  hoop face. That is a hoop sitting proud of a barrel, which is what a hoop is.

## SO WHAT TORE THE CASK? OUR OWN FACE CAP, AND A PICTURE SETTLES IT.
Three renders of the same file through one camera:
- **`_barrel_a_whole.png`** - both slots, all 824 faces, untouched: **a clean
  hooped cask.** No shards, no tearing, no z-fighting anywhere on it.
- **`_barrel_b_cap110.png`** - the same file through the Tapster's pass-1
  `max_faces=110`, i.e. **DECIMATE RATIO 0.1335**: staves torn into fins,
  hoops shredded into floating slivers, holes through the body. **This is the
  picture the lane called z-fighting.**
- **`_barrel_c_slot0.png`** - slot 0 alone at its own 392 faces: clean.
The Barrel is **240 loose parts**; a decimate that keeps one face in seven
cannot preserve a model built as separate staves and rings. The Tapster's
"fix" - dropping slot 1 - worked for a reason nobody checked: with the metal
gone, 392 faces fell **under** the 440-face cap it was given in the same
change, so the cask simply stopped being decimated. **The cap was the cause and
the cap was the cure; the slot was never involved.**

## WHAT THIS MEANS FOR EVERY FUTURE BODY BUILT FROM THIS PACK
1. **Nothing in `assets/props/` needs avoiding on slot grounds.** There is no
   Barrel class to avoid, because the Barrel is not in it.
2. **Cap by the model, not by a number.** Read the primitive and face counts
   off the .gltf first - the Tapster's pass 2 did exactly that for the bottle
   and the mug and both came out right. A flat cap applied to a many-part
   model is the fault that has now cost two passes.
3. The closest thing to a real z-fight risk in the pack is reported anyway,
   with its method: 21 slot pairs across 20 files have faces within 5 mm of a
   near-parallel surface of another slot (worst by area: Whetstone, Stall_Empty,
   Workbench, Mug), and 19 pairs across 18 files have shallow triangle
   intersections. **None of these is the Barrel**, and none has been seen to
   tear - they are listed so the next lane to decimate one of them looks first.

## WHAT THE INSTRUMENT CANNOT SEE, WRITTEN BEFORE THE NUMBERS WERE READ
- The radial test is cylindrical about each object's local Z; a crossing about
  another axis is invisible to it, and those pairs are counted as
  **unmeasurable**, never as clean.
- No test looks at material colour: two coincident surfaces of the same colour
  do not visibly tear. This counts the geometry half.
- `ok` is false unless the control (the Barrel) is flagged. It went false three
  times, which is the only reason this document says "the finding was wrong"
  instead of "zero found, the Barrel and nothing else".
