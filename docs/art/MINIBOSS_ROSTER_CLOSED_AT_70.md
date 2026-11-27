# THE MINIBOSS ROSTER IS CLOSED AT 70. THE HAMMERMAN IS THE LAST.

27 Nov 2026, 14:3x-15:0x CT. Art lane. Asked for by the team lead's 13:58 block:
*"YOU CALLED THE HAMMERMAN 'THE 70th AND THE LAST'. SAY PLAINLY WHETHER YOU MEAN
IT... it changes what every lane plans for and it must not live only in a commit
subject."*

## THE LINE, AND IT IS THE WHOLE POINT OF THIS FILE

**THE MINIBOSS ROSTER IS CLOSED AT 70 BODIES. THE HAMMERMAN ("Alltold") IS THE
LAST ONE. THE ART LANE WILL NOT INVENT A 71st.** From here the art lane's
miniboss work is PASSES ON WHAT EXISTS, not new bodies.

## THE COUNT, MEASURED THIS RUN AND NOT REMEMBERED

Off `tools/art/minibosses.py`, brace-matching every `BUILDERS = {` and
`BUILDERS.update({`, keys taken at depth 1 - not a flat regex, and not the first
textual hit of the name, which is the mistake that has now cost four seats on
`Delve.MB_NAME`:

      84 unique builder keys
    - 12 `*_chibi` variants
    -  2 with no `.glb` on disk (`drillmaster_tall`, `drillmaster_chibi_tall`)
    = **70 base bodies, each with a shipped `.glb`**

Cross-checked the other way: 83 `.glb` in `assets/monsters/minibosses/`, of which
`broodglut` and `lastcuff` have no builder (they are not miniboss bodies). The 70
agrees with the team lead's independently measured 70 on merged tree 70c3c8a5.

## WHY CLOSED, IN THREE LINES

1. **ALL FOURTEEN FLOORGEN THEMES HAVE BEEN COVERED SINCE THE 33rd.** Everything
   after that has been depth, not coverage. A 71st adds a body to a theme that
   already has five.
2. **THE ENGINE IS TWO BODIES BEHIND US.** 70 bodies against 68 names in
   `Delve.MB_NAME`; `shearman` and `hammerman` have zero hits in `scripts/`.
   Making a 71st widens a gap that already exists. Mr. E's ruling that nothing
   we make is wasted is a reason to keep the queue honest, not to lengthen it.
3. **THE BAR WAS ONE IDEA THAT CHANGES THE FIGHT.** At 70 the ideas that are
   left are re-skins of ideas already in. The standing permission to invent
   (17:43) is a permission, not an obligation, and the honest use of a dry hour
   now is to make the 70 read better.

## WHAT THIS CHANGES FOR OTHER LANES

- **GAME BUILD / CONTENT:** the target is fixed. 70 is the final denominator for
  the naming cascade, the feed keys and the published count. It will not move
  again on the art lane's account.
- **THIS IS REVERSIBLE AND MR. E OVERRIDES IT.** It is the art lane's own call
  about its own queue, written down because the team lead is right that it
  cannot live in a commit subject. If Mr. E wants a 71st he says so and he gets
  one.
