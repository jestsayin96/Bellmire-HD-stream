# Research notes for the hub's phase-1 elevation

Not published (nothing here is served). Written before the rebuild, so the
choices below have a reason behind them rather than a taste behind them.
Sources are named inline; where a source is a vendor blog I took the principle,
not the pitch.

The diagnosis Mr. E gave: "correct, not crafted - flat parchment panels,
leaderboards with no rank emphasis, the d20 is just a section." The research
below says the same thing in a more useful way, so it is organised by what I
am actually going to change.

---

## 1. The real problem: seven identical boxes

Every section of the hub today is the same parchment panel with the same
border, the same padding and the same title. Dashboard writing is blunt about
this being the central failure mode:

- "Never four identical cards in a row" - vary section types, and build
  hierarchy from **spacing and typography**, not from wrapping everything in a
  box (styleseed screen guides; Glide's dashboard-screen skill, which goes
  further: "DO NOT use cards for entire sections ... not everything needs a
  card border").
- The **information pyramid**: one hero element, then a small set of key
  numbers, then a supporting list. **Density increases as you scroll** - a big
  hero number at the top, 13-14px detail rows at the bottom.
- Vercel's dashboard is the cited masterclass in restraint: monochrome, ONE
  accent colour, no gradients or flourishes, and a hierarchy you can say out
  loud - name > status > latest > metrics.
- "The best ones feel almost empty at first glance, then reveal depth."

**Borrowing:** stop making every section a panel. The town header becomes a
real hero. The Boards and the Chronicle keep a panel because they are discrete
objects. The Guild Roll, the Fallen and the Commands step down to lighter
treatments - a rule and a title on the dark ground, not another bordered box.
Spacing and type carry the rest. One accent (teal) stays one accent.

## 2. Numbers

- Stripe and Plausible both set figures in a monospace/tabular face because
  "dashboards show lots of numbers; make them scannable" - optical alignment
  means 1,234 and 849 line up digit for digit down a column.
- Decorative/display faces confuse **1 / l / I** and **0 / O**. In a game
  economy screen "that kind of confusion is not cute. It creates mistakes, and
  mistakes feel like unfairness" (geekvibesnation on game-UI typography).

**Borrowing:** every figure on this page gets `font-variant-numeric:
tabular-nums` and is set in the UI face, never the display serif. Ranks,
gold, floors, kills, the die's result - all tabular, all aligned.

## 3. Leaderboards

This is the area with the most settled research, and most of it is about the
people who are NOT winning.

- Top-3 emphasis is real and measured: across 9 leaderboard types x 3 domains,
  people consistently preferred the board more when their name was in the top
  three, and the drop from "top" to "middle" to "bottom" was significant every
  time (Designing Leaderboards for Gamification, CHI).
- But: "any leaderboard that shows absolute ranking to users who cannot
  realistically reach the top is actively hostile to retention" - a pure global
  top-10 motivates the top 5-10% and demoralises the rest (Chou, Octalysis).
- The fix is the **neighbourhood view**: show the viewer their own position
  with rows around it, so the next rank is reachable. "Centre the list on the
  player rather than the top, since the five rows above and below are the only
  ones with motivational content" (wandr studio).
- **Cap at 3-5 primary boards**; more creates ranking fatigue. (We have five.
  That is the ceiling - do not add a sixth.)
- **Transparency**: "a player who cannot explain why they are ranked where they
  are will assume the rank is arbitrary or rigged, and that assumption does not
  require any actual unfairness to take hold."
- The screenshot test: if nobody wants to screenshot their #1, the board is not
  working.

**Borrowing:**
- The leader gets a genuinely featured row - bigger, its own treatment, not
  just the first `<li>`.
- Top three get rank sigils in gold / silver / bronze. Metal AND the numeral
  AND position, so the distinction never rests on colour alone.
- **Value bars** behind each row, scaled to the leader, so the spread is
  visible - you can see at a glance whether second place is close or nowhere.
- **A "find your hero" field on the boards**: type a name and that hero's real
  row and real rank pin underneath the top ten, even if they are 34th. This is
  the neighbourhood view, as far as a page with no login can go, and it is the
  single highest-value thing in this research. Phase 2's Twitch login turns it
  automatic.
- Keep saying in words which board counts the fallen and which counts the
  living - that is the transparency point, and it was already right.

## 4. The die

Consistent across every implementation I looked at (D&D Beyond's 3D dice, the
roll-for-brew CSS d20 issue + PR, altftool's roller, the Dice Roller 3D
extension):

- **Decide the value first, animate to it.** Every one of them does this, and
  altftool says it plainly: "the result is decided the instant you press Roll
  ... the animation never changes the outcome." (Already true of ours.)
- **A linear infinite spin reads as a loading spinner, not a thrown die.** This
  is the exact complaint in roll-for-brew #606 - and it is exactly what ours
  does today. The fix is a choreographed **throw -> tumble -> bounce -> settle**
  with real easing, not a constant rotation.
- Land on a **known orientation plus whole extra 360 turns**, so the die never
  snaps backwards between rolls (webdevpuneet).
- Budget: ~800 ms tumble, ~1-2 s total. Longer is not more satisfying.
- **Disable the trigger for the duration** and only report the number when the
  animation ends, so the displayed result can never desync from the die.
  (Already true of ours.)
- Crit flourish is standard: gold on a natural 20, red on a natural 1, plus a
  flash/punch on landing.
- A real CSS 3D icosahedron (preserve-3d, 20 triangular faces) is what makes it
  read as a die rather than a badge.
- Respect `prefers-reduced-motion`. (Already true of ours.)

**Borrowing:** all of the above. The die becomes a true CSS 3D icosahedron with
a choreographed throw, a squash on landing, and a flourish on 20 and 1 - and it
gets the top of the page's attention budget rather than being the second-to-last
section.

## 5. Fantasy UI that reads premium, not kitsch

- **Two faces, with separated roles.** "A display font can own branding,
  headers, and big, slow moments. A readable text font can own body copy,
  numbers, settings and dense screens. Forcing one font to be both actor and
  stagehand is where trouble starts."
- "**Avoid medieval overload**: if everything is ornamental, nothing becomes
  the highlight" (maisfontes, on RPG typography).
- "Parchment backgrounds and similar busyness are an abomination" for long text
  - and texture cuts contrast, which decorative faces can least afford
  (skeletoncodemachine; maisfontes).
- Use high contrast; test the type on the real background, not on white.

**Borrowing:** Gloock (the title card's face, SIL OFL, self-hosted in
web/fonts/) for the wordmark and section titles ONLY. The UI face keeps every
body string and every number. Parchment stays as a surface for content but
gets quieter and more even - it is a material, not a texture show. The
ornament budget is spent in three places only: the rank sigils, a thin
harlequin diamond band, and the bell. Everything else is plain.

## 6. Twitch companion pages

- Twitch **panels are 318px wide**; the mobile slot is essentially a panel.
  Several of the extension write-ups stress a touch-first layout because the
  overlay's hover model does not exist on a phone.
- "With no live card it shows a one-line note, because Twitch has already
  allocated the space and **a blank rectangle is worse**" (EDNexus) - which is
  the same instinct as our existing "the town has not reported in" state.
- Status/staleness belongs in a live region for screen readers, and a staleness
  rule should be explicit. (Ours is: 5 minutes, and it says so.)

**Borrowing:** test at **320px**, not just 390 - if this is ever dropped into a
Twitch panel it has to survive 318px without horizontal scroll. Every control
stays a real tap target. Nothing depends on hover. The honest "as of <time>"
line and the empty/stale/error states stay exactly as they are.

---

## What I am deliberately NOT doing

- No avatars or hero portraits on the boards. The payload carries no image, and
  docs/HUB_SECURITY.md forbids building an image src out of snapshot data.
  Sigils are drawn from the hero's own letters instead.
- No movement arrows ("up 2 since yesterday"). The snapshot is a single current
  row with no history, so any such arrow would be invented. The honesty rule on
  this page outranks the nice-to-have.
- No sound on the die. Unprompted audio on a page you opened beside a live
  stream is hostile, and it would be the one thing guaranteed to get the hub
  closed.
- No sixth board. The research caps it at five.
- Nothing from phase 2 or 3.
