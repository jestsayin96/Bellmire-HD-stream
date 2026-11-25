# COLLIER PASS 15 - THE FACE WAS INSIDE THE SKULL

25 Nov 2026, ART lane, taken from the 10:58 CT plan row, option (A):
"FIX THE COLLIER'S HEAD FACING, the fault you found by looking and no number
in your lane reports."

## THE FAULT, AND THE CAUSE IS ARITHMETIC

Pass 14 reported "his head has almost no facing" as an eye judgement and could
not say why. It is not a taste call. The head is an ellipsoid of radii
(0.198, 0.204, 0.206) and every face feature was placed well inside it:

| piece       | outer face reached | head surface at that height | buried by |
|-------------|--------------------|-----------------------------|-----------|
| brow band   | y -0.165           | y -0.197                    | 0.032     |
| sockets     | y -0.164           | y -0.192                    | 0.028     |
| mouth cloth | y -0.155           | y -0.187                    | 0.032     |

All three sat about 0.03 m INSIDE the skull. The only part of any of them that
ever rendered was the sliver the sphere's curvature left behind near the
silhouette - the two small slanted marks on the shipped hero_front.png. The
head therefore carried no facing worth the name. That is FAULT 7 shipped, and
it is the Beadle's fault in a different mechanism: the Beadle's facing wrapped,
the collier's was never on the outside at all.

A flat box cannot simply be pushed out. At the brow band's own ends (x +-0.146)
the sphere has receded to y -0.128, so a box set proud at the centre stands
0.08 m off the head at its tips: wings, not a brow. That is very likely why it
was sunk in the first place. The face now FOLLOWS THE SURFACE - `_face(xf, zf,
out)` returns a point on the ellipsoid itself with a true outward normal, and
the brow is a tapered tube swept along it, the rag a `surf` patch thickened
along its own normals, the sockets flat inset discs.

## WHAT I GOT WRONG, IN ORDER, AND WHAT DISPROVED IT

Pass 15 bought the facing and broke the side silhouette: it added 130 px of
NEW outline outside the shipped one on hero_side.png, reading as a dark hook
hanging off the side of his head. I then guessed the cause three times and was
wrong three times. Each time a render, not an argument, settled it.

1. "It is the brow's end caps." Tapered them -> 115 px. Barely moved.
2. "It is the brow and rag reaching too far round." Swept the whole face span
   1.00 -> 0.78 -> 0.58 -> 0.40: 115 -> 113 -> 113 -> 112. **A cause that does
   not move when you shrink it is not the cause.**
3. "It is the sockets, which never scaled with that span and were round balls
   standing 0.042 proud." Flattening them helped (130 -> 104 with the old
   brow/rag) but did not clear it.

The honest instrument was ABLATION, not reasoning: turn each piece off and
re-render. On the candidate (88 px): no brow -> 47, no rag -> 52, no eyes ->
82. Brow ~41 px, rag ~36 px, flattened eyes ~6 px. Everything that sits on the
front of a round head contributes, which points at the view and the pose
rather than at any one piece.

4. "Then it is proudness, or the 16-segment sphere sagging inside its ideal
   surface." An out-sweep says proudness is half of it and the rest is
   unexplained: +0.012 = 88, +0.0054 = 71, FLUSH = 48, -0.0042 = 48,
   -0.0090 = 39. **The facet prediction failed** - insetting by the predicted
   sag changed nothing.

SHIPPED AT FLUSH (`COLLIER_FACE_OUT=0.0`): the face sits exactly on the skull.
Proudness buys nothing but silhouette, and insetting past flush buys almost
nothing while walking back toward the burial this pass exists to fix.

## WHAT IS STILL WRONG, AND I CAN SEE IT

- **A ~48 px dark nub on the side view, at eye height, with a thin dark line
  curving down from it.** It reads as a small clip or handle stuck to the side
  of his head, not as a face in profile. Its cause is NOT established - the
  four explanations above are all disproved or partial. It is smaller than the
  130 px pass 15 started with and it is not gone.
- The front face is a strong read at full size and a legible dark band at the
  360p rung, but **at 360p it reads as "a head with a front", not as a face.**
  The knight beside it reads as a face at the same size.
- **The operator is still brown-on-brown with the clamp he stands on.** Not
  touched this pass; it is a separate finding and still open.

## THE INSTRUMENT, AND WHAT IT CANNOT SEE

`tools/art/_facingread.py` (Linux bridge, needs PIL) puts the front beside the
MIRRORED back over the head silhouette only and counts the pixels that differ,
at the _streamscale rungs. It is the viewer's question: if they match, the body
has no facing. No MIN_FACING_PX - the 05:58 ruling of 25 Nov applies; only ZERO
is a verdict on its own.

**IT DID NOT DECIDE THIS PASS, AND THE WRITE-UP WOULD BE DISHONEST IF IT
CLAIMED OTHERWISE.** Two faults of my own in it, both caught by its own guards:

1. It located the subject by `mean(R-G)`, which put the head window on the
   HERO in all four arms. Earth brown is warm everywhere, so a mean over a
   mostly-grey knight came out lower than a mean over a brown clamp. The
   `both views picked the same half` guard fired and VOIDED the comparison
   rather than printing a number. It now counts strongly-red cape pixels.
2. Restricted to the whole head window it read 78.5% differing on the CONTROL
   and 89.2% on the fix. A metric that is already at 78% before the change
   cannot see a face: the hat brim is front-only and the shading differs
   front-to-back on any round head. Cut to the head-above-the-neck mask it
   still reads 78% / 89%.

So the number beside this pass is the SILHOUETTE-BREAK count and the
ablation, and the verdict is the picture. When a number and a picture
disagree, the picture is the evidence.

## PROOF

- `renders/art/minibosses/collier/hero_{front,side,back}.png` - on a real
  KayKit knight, idle, three views, looked at.
- `renders/art/minibosses/_p15_face/` - cmp3 (p14ctl / p15 / p15c, three
  views), pick (the out-sweep by eye), stream360 (the 360p rung), head_sheet.
- Register GREEN: errors [], blind_views [], unproved_cells [],
  frame_edge 0 on every edge of every view (border), blank 186 files /
  0 failures / 62 cells. collier ratio 0.86 of hero, span 2.16 m,
  CORRIDOR-SAFE, UNDER-LID.
- Front and back silhouettes are UNCHANGED by this pass (0 added, 0 lost).
  The facing does not wrap: the back view is pixel-identical to the control.
