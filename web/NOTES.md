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

---

## Addendum: the SSS+ grimoire elevation (second pass)

The brief asks for a dark-fantasy grimoire with named components. Notes behind
the second pass:

### Tier styling (SSS / SS / S / A ...)
- The canonical order is SSS > SS > S > A > B, descending, borrowed straight
  from gacha/fighting-game tier lists. The colour convention is consistent
  across them: gold/bright for the top, cooling and muting as you go down.
- The hard rule from accessibility: the TIER LETTERS carry the meaning, never
  the colour alone - the same rule that kept the boards colourblind-safe before.
- Assignment: there is no "meta viability" here, so tier = rank bracket over the
  ranked field (value > 0). SSS = 1st, SS = 2nd-3rd, S = 4th-6th, A = 7th-10th.
  Robust for a 2-hero night and a 200-hero one alike. The exact numeric rank is
  still shown, so the tier is a flourish on top of the real position, not a
  replacement for it.

### Illuminated initials / drop caps
- Kept as CSS-styled first letters (Gloock, gold), NOT images: web drop caps
  render differently across browsers and an image would mean an asset + an
  <img> src, which the security rules fence off. A styled ::first-letter is
  decorative only and degrades to a plain capital if it renders oddly.
- Foliate-initial principle: keep the structure, vary the ornament. The initial
  is the one ornament that changes per section; everything else holds.

### Item icons (gear + chronicle types)
- Drawn by hand as inline SVG <symbol>s in index.html - my own simple glyphs, so
  CC0 by origin, no third-party asset, no <img> request, no CDN. Referenced with
  <use href="#ic-..."> where the id is ALWAYS a fixed, page-authored string from
  a whitelist; a snapshot value only ever SELECTS which known icon, it is never
  written into the DOM as markup. A weapon name maps to a category (blade /
  ranged / arcane / blunt) by keyword; an unknown weapon falls back to a blade.
- This is the safe way to honour "gear with item icons" and "per-type icons"
  without touching the no-third-party / no-snapshot-as-markup rules.

### The HP bar, and an honesty problem
- The snapshot carries hp but NO max hp. A current/max depletion bar needs a
  denominator the data does not provide, and inventing one would break the
  honesty the rest of the page keeps.
- So the HP bar is forward-compatible: if the publisher ever adds max_hp /
  hp_max / maxhp, the bar becomes a true current/max gauge that colours by
  ratio (green / amber / red). Until then it renders as a full "vitality" bar
  with the HP number on it - a styled display of the known value, making no
  claim that the hero is injured. One line flips it to real depletion the day
  the desktop publishes the max. (A data-contract note for the desktop side,
  not something the hub can decide on its own.)

### Ornate borders
- A restrained double-rule (an inked frame with a hairline inside it) plus small
  gold corner ticks, done entirely in CSS - no background images. The NOTES-1
  warning against kitsch still governs: ornament is spent on the initials, the
  tier emblems, the corners and the band, and nowhere else.

---

## H5: the Twitch chat embed (opt-in) and the one CSP change
- The page's whole security stance is "no third party". The chat embed is the single
  deliberate exception, so it is OPT-IN: the iframe is built only when the viewer clicks
  "Load Twitch chat". A viewer who never clicks never contacts Twitch.
- The CSP gains exactly one directive: `frame-src https://www.twitch.tv https://embed.twitch.tv`
  (two named hosts, no wildcard). Everything else is unchanged, so the embed cannot add
  scripts, styles, connections or images to this page. Full before/after + reasoning is in
  docs/HUB_SECURITY.md, flagged for the supervisor.
- The iframe src is the official chat embed, channel = the constant TWITCH_CHANNEL, parent =
  this page's own hostname. No snapshot value ever touches the URL.
- The clickable d20 the phase also asks for already exists - the die rolls on click/Enter/Space.

---

## H6: device-code sign-in (scaffolding, gated on Mr. E)
- Why: so a viewer spotlights their own hero instead of scrolling - "not peeping toms on
  others' stats." Device-code grant suits a page with no server (no redirect URI to host).
- Gated: TWITCH_CLIENT_ID ships empty, so the button only explains it needs Mr. E; no call is
  made. A ?twitch_client= test hook exercises the flow end-to-end without baking an id in.
- Read-only and minimal: no scopes (we need only the user's own login), token in memory only
  (never storage, never our backend), no viewer write. The two connect-src hosts are documented
  and flagged in docs/HUB_SECURITY.md. Phase 3 (any write path) stays off until the RLS is designed.

---

## H4: the Boards and the town-status strip
The grimoire pass already gave the Boards their tiers (SSS/SS/S/A/B), the featured leader,
value bars and the find-your-hero row, and the Guild Roll and the Fallen were in place from
phase 1. H4's remaining pieces were the explicit sort affordance and the town-status strip.

### Sort tabs
- The five board tabs ARE the sort - each ranks the field by its own metric (gold, deepest,
  deadliest, delves, standing). They were unlabelled, so a "Sort heroes by" eyebrow now sits
  above them and the tablist's accessible name became "Sort the boards by". No new board: the
  research in section 3 caps it at five, and that still holds.

### Town-status strip (day / pop / treasury / raids) - and an honesty line on raids
- The strip shows every field the publisher's town block carries: town level, souls (the
  population), the day, the treasury and renown. To these H4 adds a real **growth-to-the-next-
  level bar**: `town.score / town.next_level_at`, both already published, drawn the same safe
  way as the hero HP/XP bars (the fill is a CSSOM number set with setProperty, never snapshot
  text; it only draws when next_level_at > 0, so there is no invented denominator).
- **Raids is a data-contract gap, not a rendering one.** `_town_block` in
  `scripts/snapshot_pub.gd` publishes name/level/souls/day/treasury/renown/next_level_at/score
  and NO raids count. A raids number on the strip today would be invented, which the honesty
  rule on this page forbids - and deriving one from the chronicle's last-50 "raid" lines would
  be a total built from a window, which is the same sin. So the strip is **forward-compatible**:
  the day the desktop adds a numeric raids field to the town block, the strip lights up a pill
  for it with no further page change. The hub reads, in order:
    - `raids_turned` / `raids_repelled` / `raids_held` / `raids_won`  -> labelled "Raids turned back"
    - a bare `raids`                                                  -> labelled "Raids"
  A field present as 0 shows 0 (an honest "none repelled"); an absent field shows nothing. This
  is the same pattern as the hp_max / xp_next contract notes above - one line on the desktop
  side flips it on, and it is the desktop's call whether that number is worth publishing.

---

## H1 verification pass (Nov 12, 2026) - 3 widths, the overlay, and the hostile name

H1's DONE line asks for "before/after at 3 widths; security invariants + hostile-name
test pass." This run rendered the BUILT page headlessly (Chromium) with the Supabase row
stubbed to a fixed payload and ?mock=crowd - which plants the attacker name
`<img src=x onerror=alert(1)>` as both a hero name and a chronicle line - at four viewports:

- 320 px  (a Twitch panel is ~318 px): single column, no horizontal scroll (scrollWidth == clientWidth).
- 768 px  (tablet): the duo, boards and chronicle resolve to two columns cleanly.
- 1280 px (desktop): the full grimoire - illuminated heads, gold corner ticks, tier
  medallions (SSS/SS/S/A/B), the featured leader row, value bars, class-crest hero sheets
  (HP/XP bars, stat block, gear cards, dye swatch), the 3D d20, the icon-badged chronicle.
- overlay (?overlay=1, 440x1080 OBS source): transparent ground, slim masthead, town strip,
  top-five board and the live feed; the interactive furniture is hidden.

Security + hostile-name test, EVERY viewport (320 / 768 / 1280 / overlay / ?open=1 / reduced-motion):
- No dialog fired - the onerror never executed.
- Zero <img> elements on the page: no snapshot value ever became an element, an src or an href.
- The hostile string rendered as LITERAL TEXT in the hero card, the board row and the chronicle
  line (textContent via el(), brackets intact).
- No page errors, no console errors. ?state=empty and ?state=fail show their honest messages.

Conclusion: H1 meets its DONE criteria. No code change was made - the look is already complete
and correct, and spending more ornament would break the anti-kitsch rule above. This note is the
evidence for the supervisor's review gate. (Verified with fallback display metrics where the
self-hosted Gloock woff2 was present; the live checks ?state=empty/fail/stale, ?mock=chronicle/crowd
and ?open=1 all pass.)

## H1 follow-up (Nov 12, 2026) - a real bug the verification pass had missed

The previous H1 run concluded "no code change - the look is already complete" and recorded a
verification pass. Re-reading style.css this run turned up an actual defect, not a matter of taste:

- The d20 GEOMETRY section of style.css ended with a block of stray JavaScript - a `//` line
  (illegal in CSS) and a full `const D20_FACES = [ ... ];` array. This is gen_d20.py's JS output,
  which belongs in app.js (where a correct, separate copy already lives and drives the die). It had
  been pasted into the stylesheet by mistake.
- Why it mattered: CSS has no `//` comment, so the parser treated `// ... const D20_FACES = [...];`
  as a malformed selector prelude and kept consuming tokens until the next `{` - which was the
  `footer {...}` rule. The footer rule was swallowed into the invalid selector and DROPPED, so the
  footer rendered unstyled (left-aligned, full-opacity, 16.5px instead of centred, .55, .82rem).
- Fix: deleted the stray JS block (~1.9 KB). The `.d20face.fN` transform rules and the
  `/* edge ... */` geometry comment above it are valid CSS and were kept. app.js is untouched, so
  the die is unaffected - it never read the CSS copy.

Security: CSS-only change. No snapshot value, no `el()` path, no CSP, no URL/src/href touched.

Re-verified the BUILT page headlessly (Chromium, Supabase row stubbed): at 320/768/1280 + overlay,
and ?mock=crowd / ?mock=chronicle / ?open=1 (the `<img src=x onerror=alert(1)>` attacker name as a
hero name AND a chronicle line): no dialog fired, zero <img> elements, no `img[src=x]`, the hostile
string renders as literal text in span.hname and p.cline (brackets intact), no page errors, no
horizontal overflow at 320. ?state=empty/fail/stale show their honest messages. Footer now computes
to text-align:center, opacity:.55, font-size:.82rem at every width - the fix confirmed.


## H6 doc-accuracy fix (Nov 12, 2026) - the sign-in is LIVE now, so the comments must say so

Context: a later commit (`hub: wire the Bellmire Hub Login client id`) baked Mr. E's registered
public client id into `TWITCH_CLIENT_ID` and removed the `?twitch_client=` runtime override. That
made the H6 device-code sign-in LIVE (read-only). But three places still described it as inert:
- index.html (CSP comment): "That flow is INERT ... so no call is made to those hosts today."
- index.html (heroes section): "Gated: with no registered client id the button only explains that
  it needs Mr. E."
- app.js (H6 comment): "GATED on Mr. E: TWITCH_CLIENT_ID is a placeholder ... makes NO network call."
- docs/HUB_SECURITY.md (H6 supervisor checklist, item 2): "TWITCH_CLIENT_ID ships empty (gated);
  grep confirms the flow is dead without it" - which also contradicted the doc's own later section
  "The client id is fixed in the page".

Those are now false and would mislead the supervisor's security review into thinking the two Twitch
connect-src hosts are dormant. Fixed, DOCUMENTATION ONLY - no code behaviour changed:
- Rewrote the three comments to state the id is registered and the flow is live but strictly
  READ-ONLY: clicking "Sign in with Twitch" starts the device-code grant; nothing contacts Twitch
  before the click; the token is the viewer's own, in memory only, never sent to our backend.
- Reconciled HUB_SECURITY.md's H6 section with its own "client id is fixed in the page" section:
  retitled "Gated on Mr. E" -> "Now live (read-only)", and rewrote the supervisor checklist to
  verify the REAL invariants (id is the non-overridable baked const; token never persisted/never
  to Supabase; no scopes; nothing contacts Twitch on page load - only on the click).
- Kept the empty-id branch in twitchSignIn() as a defensive fallback; relabelled its comment.

Security: comment/markdown only. No `el()` path, no CSP directive, no URL/src/href, no snapshot
field touched. Re-verified the BUILT page headlessly (Chromium, Supabase row stubbed with the
attacker name `<img src=x onerror=alert(1)>` as every hero/town/fallen/chronicle/command field) at
320 / 768 / 1280 / overlay / ?open=1 / reduced-motion and ?mock=crowd / ?mock=chronicle /
?state=empty / ?state=fail / ?state=stale: no dialog fired, zero <img> elements, the hostile string
renders as literal text, the `<colour>` !dye canary keeps its angle brackets, no page/console
errors, no horizontal overflow at 320, and NOTHING contacts Twitch on load (the sign-in is
click-gated). All four security invariants intact. Held for the supervisor's review as before.


## Share polish (Nov 12, 2026) - favicon, social card, and the honest 200-hero mock

Three small additions Mr. E approved, all read-only, none touching the snapshot path:

- **Favicon**: an inline `data:` SVG of the crest (shield + teal scar) in a `<link rel="icon">`.
  No new request, no asset file, allowed by the CSP's existing `img-src 'self' data:`. Every
  visit used to 404 on /favicon.ico; now it doesn't.
- **Social card**: Open Graph + Twitter meta so a shared hub link unfurls with a title card in
  Discord/Twitter instead of a bare URL. `og:image` points at **web/og.png** (1200x630), my own
  drawing: the index.html crest + the Gloock wordmark on the page's night/gold/teal palette.
  Generator committed at **web/tools/og.html** (render with headless Chrome at 1200x630), so the
  card is reproducible; Gloock is OFL (web/fonts/). Crawlers fetch og:image from OUTSIDE the page,
  so there is no CSP change and nothing in the meta carries snapshot data. The og:url/og:image
  host is the repo's GitHub Pages origin - flagged in index.html for the supervisor to confirm
  at review.
- **?mock=crowd now plants 200 heroes** (was 40). H3's DONE line says "?mock=crowd 200 fast",
  and 40 never exercised HERO_PAGE=60. Verified: 60 cards drawn, "Show more (60 of 200)", the
  boards rank the field, full render ~0.6 s headless.

Re-verified after the change (headless Chromium, Supabase stubbed, hostile name
`<img src=x onerror=alert(1)>` planted): all eleven modes (320/768/1280/overlay/?open=1/
reduced-motion x crowd/chronicle/empty/fail/stale) - no dialog, zero <img> ELEMENTS on the page
(the favicon is a <link>, not an <img>; the og meta is head-only), hostile string literal, the
<colour> canary intact, no console/page errors, no overflow at 320, nothing contacts Twitch on
load. Invariants intact; held for the supervisor's review as before.

### Data-contract wishlist for the desktop (one-liners in scripts/snapshot_pub.gd, its call)
Already-built hub features light up with no page change the day the publisher sends:
- `max_hp` (or hp_max/maxhp) per hero -> real HP depletion bars, coloured by ratio
- `xp_next` per hero -> real XP-to-next-level bars
- `raids_turned` (or raids) in the town block -> a "Raids turned back" pill on the town strip


## H8 (Nov 12, 2026) - the guild chat goes native; the iframe embed is retired

Mr. E opened the live page on Brave and the embed's input was dead: the Twitch page inside the
iframe cannot keep its login anywhere third-party cookies are blocked, which is Brave and Safari
by default and Chrome increasingly. "We should not need another pop up for chat." He chose the
full replacement over keeping the embed as a fallback.

So the hub now speaks Twitch chat's own protocol (IRC over WebSocket, wss://irc-ws.chat.twitch.tv)
itself. Reading is anonymous - works for every viewer instantly, no login, no cookies. Talking
reuses the H6 sign-in, whose grant now carries chat:read chat:edit; the viewer's line goes to
Twitch as themselves. Still opt-in (nothing contacts Twitch until "Open the guild chat" is
clicked), still zero writes to our backend. Full security reasoning + the CSP delta (frame-src
REMOVED, one wss host added to connect-src) in docs/HUB_SECURITY.md, H8 - flagged for review.

Design choices and their reasons:
- Plain text only, no emote images or badges: an emote would mean building an <img> src from wire
  data, which the security rules forbid, and a third-party image host besides. The trade was put
  to Mr. E and accepted.
- Name colours from a fixed six-colour page palette by hash - never the wire's colour tag, so no
  attacker-influenced style, and the palette stays the page's own.
- CLEARCHAT matches on LOGIN (not display-name - a real bug the fake-socket test caught before it
  shipped: a banned user's lines would not have cleared). CLEARMSG, NOTICE, USERNOTICE, PING and
  RECONNECT are all handled; CHAT_MAX 150 lines; scroll pins to the bottom only when the viewer
  is already there; 1.2 s client-side send spacing.
- Outgoing ctrlStrip kills CR/LF (IRC command injection) and caps at 450 chars.

Verified before push:
- Fake-socket protocol test: handshake (CAP/NICK justinfan/JOIN) exact; hostile display-name
  `<img src=x onerror=alert(1)>` (IRCv3-escaped on the wire) AND hostile message text render as
  literal text; PING answered; CLEARMSG and CLEARCHAT remove the right lines; unauthenticated
  send puts NOTHING on the wire; no dialogs, zero <img>, no overflow at 320 (a real grid
  min-content blowout at 320 was found and fixed with min-width:0 on the chat panel).
- ?mock=chat renders the hostile name as text with the input honestly disabled.
- The full 11-mode harness still passes untouched.
- REAL protocol check from this desktop's own network: Twitch answered our exact handshake with
  CAP ACK, 001 Welcome, JOIN #jestsayin96 and ROOMSTATE. (The page's own socket couldn't be
  exercised end-to-end from the build sandbox - its proxy blocks raw WebSockets - which is also
  why the "lost its footing" retry state is known to render correctly.)


## H9 - the town's rolls on the die (2026-11-13)

Mr. E's Phase-N ruling: a viewer spends channel points or bits and a d20 decides how a town
action goes (upgrade a building, pass a law, set off an event). The supervisor's architecture
ruling is that the roll is resolved IN THE GAME (T5) and the hub only DISPLAYS it - the page
stays read-only and never trips the Phase-3 RLS gate. H9 is the hub half: the die section now
shows the town's rolls, read from the snapshot, and the big d20 animates to the latest one.

Why it lives in the existing die section rather than a new panel: the d20 was already the page's
one piece of motion and the obvious home for "a roll and its outcome". The local tap-to-roll
stays (it is honestly yours - it happens in your browser, the town never hears it); when the
town rolls, the same die shows that instead. One stage, two sources, clearly labelled.

Forward-compatible, the same discipline as the HP/XP bars and the raids pill: the publisher
(scripts/snapshot_pub.gd on main, DESKTOP BUILD) sends no `rolls` yet, so the section shows an
honest empty state and the die stays the local fun die. It lights up with NO page change the day
the field arrives. The hub makes no claim about a roll until the game sends it, and never derives
an outcome tier from the number - a low roll is only "bad" if the game says so.

### The data contract (publisher: add `rolls` to the snapshot payload, newest first)
An array of objects; every field optional and defended. Canonical key, then accepted aliases:
- `n`      - the face rolled, 1..20            (aliases: roll, d20, face, value)
- `by`     - the roller's Twitch display name  (aliases: who, name, viewer)  [viewer text]
- `what`   - what was attempted / the proposition (aliases: title, proposition, action) [viewer text]
- `tier`   - the outcome band: one of crit | good | mixed | bad | fumble (aliases in TIER_ALIAS)
- `result` - the plain-language outcome         (aliases: s, text, line)  [viewer text]
- `cost`   - what was spent, e.g. "500 channel points"  (alias: spent)
- `at`     - ISO timestamp                      (alias: time)

Outcome tiers are deliberately WORD-first (Triumph / It goes well / A mixed result / It goes
badly / A fumble), readable to someone who has never played D&D (T5's requirement); colour only
reinforces them. Keep the result sentences plain, and always ship at least one failure outcome,
not only wins - the feed is honest about backfires. Rendering is the same security as the
chronicle: every string is textContent via el(); `tier` only selects a whitelisted class; `n`
only picks a fixed rotation matrix; nothing becomes a URL. Local check: ?mock=roll (it carries
the hostile-name canary as the roller). Reviewed in docs/HUB_SECURITY.md (H9).
