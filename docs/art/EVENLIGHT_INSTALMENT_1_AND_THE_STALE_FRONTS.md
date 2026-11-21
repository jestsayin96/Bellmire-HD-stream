# EVEN LIGHT, INSTALMENT 1 - THE RULING HOLDS, AND 28 OF 42 FRONTS ARE STALE

20 Nov 2026, the 18:34 CT art firing. The supervisor approved the even-light
re-render at 18:32: *"Background re-render of back and side views only, spread
across art's own firings. Front views are provably unchanged - do not
re-render them."*

I started instalment 1 (six bodies) behind a guard: re-render each with
`--evenlight`, and ABORT if the FRONT moves, because the ruling says it
cannot. **It aborted on the first body.** What follows is why that alarm was
right and my first reading of it was wrong.

## WHAT I NEARLY REPORTED, AND DID NOT

The guard fired on `bellman`: the front changed. Measured, not assumed:
**91,999 px differ**, and the figure is TRANSLATED 22 px up - shipped bbox
rows 103-499, new rows 81-478, x identical, opaque count within 21 px.

The obvious reading is that the even-light switch moves the frame and the
approved ruling therefore rests on a false premise. **That would have been a
fiction, and it was one tool call from going into my summary.** A correct
alarm is not a correct diagnosis. The control is the only thing that separates
them, so I ran it: re-render `bellman` with NO even light at all, into a tag
directory so nothing shipped is touched.

| comparison | diff px |
|---|---|
| shipped front vs **plain** re-render today | **91,998** |
| plain re-render vs **even-light** re-render | **1** |
| shipped front vs even-light re-render | 91,999 |

**THE EVEN-LIGHT RULING'S PREMISE HOLDS.** One pixel out of 83,607 is
antialiasing. Even light does not move the front. The 22-px shift is there
with the switch OFF.

## THE REAL FINDING: THE SHIPPED FRONTS PREDATE THE VERTICAL-AIM FIX

The shift is the signature of the `drop` fix to the camera's vertical aim
point in `minibossfit.py`, which landed **18 Nov 18:48:17 CT in e4e9b2f2**
("the fit harness could not see a cut"). Any hero view written before that
commit was rendered with the old aim and cannot reflect it.

Dating every `hero_front.png` by the commit that last wrote it, against
18 Nov 18:48:17: **28 of the 42 non-chibi bodies are stale, 14 are current.**

STALE (28): bellman, boiler, comfitmaker, cook, drillmaster, drover, dyer,
fenman, gaoler, greener, hurdleman, jointer, leech, loader, paviser, porter,
pressman, quartermaster, rammer, ratcatcher, scrapwright, sluicekeeper,
snarer, snuffer, strickler, tallyman, tanner, tapster.

CURRENT (14): beadle, dauber, ferryman, fuller, hooper, moulder, relief,
reeve, scraper, sealer, sexton, sower, stackman, stoker.

**THE DATE ARGUMENT IS VALIDATED ON BOTH ARMS, NOT ASSERTED.** A date is a
claim about pixels and has to be shown to discriminate:

- `sealer` (rendered 20 Nov, after the fix) re-rendered today: **0 px differ**,
  bbox identical.
- `bellman` (rendered 17 Nov, before it) re-rendered today: **91,998 px**.

Note also that md5 is NOT the instrument here: sealer's two PNGs have
different md5s and identical pixels. My first guard used md5 and would have
flagged every body. The pixel compare is the test.

**WHAT THE DATE ARGUMENT DOES NOT SAY.** It says these 28 were written before
the fix, so they cannot carry it. It does not say how far each one moved. The
`drop` term is `sin(6 deg) x half-the-pair-depth-span`, so a pair with a small
depth span moved little or not at all. Only bellman is measured. The honest
claim is UP TO 28, with the size per body unknown until each is re-rendered.

## WHAT THIS MEANS FOR THE APPROVED WORK - FOR THE SUPERVISOR

The approval says back and side only, fronts untouched because they are
unchanged. That reasoning is sound about EVEN LIGHT and is now verified. But
it was given without knowing that **28 of those fronts are already out of date
with the harness that produced the registers** - the ground line they are
drawn on is not the one `minibossfit.py` draws today.

So the two things are separable and the second one is new:

1. **Even light, back and side, 42 bodies** - approved, premise verified,
   nothing in the way. Instalment 1 did not land: I stopped it at the guard
   rather than push through an alarm I had not explained, and bellman's
   renders were restored from git. Nothing in the tree was left half-applied.
2. **The 28 stale fronts** - NOT covered by the ruling, and re-rendering them
   is the opposite of what it says. It is also cheap to fold in, because a
   body re-rendered for (1) writes all three views anyway in one run.

**THE DECISION I NEED:** does the background re-render write all three views
per body, bringing the 28 stale fronts current at the same time, or does it
keep to back and side and leave them stale? I am not re-rendering a front
against a standing ruling without that said, and I will not fold it in
quietly. Instalment 2 waits on the answer; if none comes, I do back and side
only, as ruled, and the 28 stay as they are.
