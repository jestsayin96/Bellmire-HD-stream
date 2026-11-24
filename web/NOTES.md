# Research notes for the hub's phase-1 elevation

PUBLIC: gh-pages serves web/ at its root, so this file is served at /NOTES.md
to anyone who asks (as is web/tools/). Nothing in it is secret; it is kept here
on purpose, as the reasons behind the design. Written before the rebuild, so the
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

## H6: device-code sign-in (LIVE - see the Nov 12 doc-accuracy fix further down)
- Why: so a viewer spotlights their own hero instead of scrolling - "not peeping toms on
  others' stats." Device-code grant suits a page with no server (no redirect URI to host).
- LIVE (corrected Nov 15, 2026): TWITCH_CLIENT_ID is Mr. E's registered public client id, baked
  as a non-overridable const; the ?twitch_client= test hook was REMOVED as a phishing vector.
  Clicking "Sign in with Twitch" starts the real device-code grant. Nothing contacts Twitch
  before the click. Verified end-to-end Nov 15: Mr. E signed in on the live page, his own hero
  card rendered and the pin-your-hero flow worked. This bullet previously read "ships empty, the
  button only explains it needs Mr. E" - that was already false and is what kept making hub runs
  report the client id as an open item for Mr. E. It is NOT open.
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


============================================================
BANDS BELOW (H10) - the delving parties on the hub
============================================================

Mr. E (Phase Y): the on-stream party band "covers up most of the screen", so it leaves the
stream (D46) and moves to the hub, "which has the room". The hub shows ALL active parties, not
just the one the stream could fit.

Why it lives here and not on stream: the stream is being stripped to Mr. E's six elements
(COORDINATION 13); a multi-member band board is detail that belongs where there is room to read
it. The hub already carries the hero sheets, so the bands-below view is the same honest data in
a place with space.

The contract (p.parties, optional, pinned for D46 - also in docs/HUB_SECURITY.md):
  parties: [ { name, floor, members: [ { name, hp, max_hp, status, class } ] } ]
  - name    band display name   (aliases band/party/title)   viewer text
  - floor   integer floor        (alias depth)
  - members name (who/hero), hp (health), max_hp (hp_max/maxhp/hpmax),
            status ok|fallen|burning|<other> (state/condition), class (calling)

Honesty, as everywhere else on this page:
  - No parties field, or an empty array  -> "No bands are delving right now." Never a fake band.
  - max_hp present -> a real depletion bar; absent -> a flat vitality bar; no hp -> no bar.
  - status ok -> no tag (the bar says enough); fallen -> skull + greyed + empty bar;
    burning -> flame + warm edge; anything else -> its own word as plain text, no icon.
  - The hub DISPLAYS; it never initiates a delve or writes anything. Read-only, as Phase 2 demands.

Security: identical discipline to the rolls feed. Every band/member string is hostile Twitch
text and reaches the DOM only via el()/textContent; HP widths are CSSOM numbers; status only
picks a whitelisted class + ICON_SET glyph. Verified with ?mock=bands and a live v2 payload.


---

## 5. H11 - what left the stream (the Satchel + "my hero")

D48/L63 take the unit frame and the Satchel off the stream; their content moves here.

**The Satchel (sell prices).** The on-stream Satchel showed a viewer their sellable items and
the counter's prices. The hub shows the same on the hero sheet, read-only from the snapshot and
forward-compatible exactly like the HP/XP bars: the block appears only once the publisher sends
the items, and invents nothing. Prices and the total are page-computed (tabular, per the
numbers research above); item names are viewer text through el()/textContent. Contract (also in
docs/HUB_SECURITY.md): per-hero `satchel` = array of {name, qty, sell, kind}; aliases inventory/
items, and value/sell_price/price/worth for the price; optional `satchel_total` for the
counter's authoritative payout; a `sell` on the equipped weapon/armour lists it too.

**"My hero" pin.** The stream always kept a viewer's own hero in view; a login-less page cannot,
so the hub lets a viewer pin ONE hero by name (a button on the sheet, or automatically on Twitch
sign-in). It is remembered in the browser (localStorage, the hero NAME only - never a token or
id) so the hero floats to the top, opens and is highlighted next visit. This is the neighbourhood
-view idea (section 3) carried to the whole page, and the no-login stand-in for the Satchel's
always-on "your hero". Research consensus on personalization: the single most-used view is "me" -
surface the viewer's own row first and everything else reads as context around it.


## H13 - a no-scroll hub (Nov 15)

Mr. E wanted a viewer never to have to scroll the hub end to end. The hub kept
all its sections - Boards, Heroes, Bands, Chronicle, the die, Guild Roll, the
Fallen, Lore, Chat, Commands - and the nav carried links to each, but the page
was one long column; on a phone or a laptop the die, the Roll and the Fallen
sat several screens below.

The simplest honest change: turn the <nav> into tabs. One click, one section,
the choice remembered for next time. The nav is already sticky and already
reads as a table of contents - all it needed was for the links to behave like
tabs. I chose <button role="tab"> over anchors because the behaviour is now
"switch what is shown" rather than "jump to an anchor"; the WAI-ARIA tabs
pattern says buttons.

The state lives in localStorage (bellmire.tab). Every read is run through
ctrlStrip + a 25-char cap and then matched against a whitelist of ten known
tab ids before it is used for anything - the stored value never becomes a
selector or a URL, only an index into a page-authored list. In a private
window the page falls back to the default tab silently.

renderNothing's .hide class still wins in CSS. A viewer who clicks Boards
when the town has not reported in still sees only the big-msg banner - the
nav tells the honest story too, by never pretending there is content behind
every tab.

No animation, no scroll trickery, no viewport-math. A phone, a desktop and
an overlay all get the same ten-button row with the same one-click reach.

---

## H14: the Chronicle remembers

A rolling per-browser history (localStorage key `bellmire.chron.v1`, newest first, capped at 300 rows / 48 h / ~120 KB, oldest dropped first) is folded in from every live snapshot. Live lines show first, then an "Earlier" divider and day dividers in the town's voice. De-duplication is by kind+text against the live set. Remembered rows are re-validated field by field on read and drawn through the same chronShape/el()/textContent path as live ones. No new fetch, origin, write path or CSP change; storage absent/full/throwing leaves the page working with no history.

## H15 - every hero gets a crest
- `coat(name, size)` in app.js (sizes sm/md/lg are page classes). Hero card: right of the summary. Opened sheet: large, left of the pin button. Boards: inline before the name for places 1-5.
- Whitelists: 7 divisions x 4x3 tincture pairs x 2-3 charge tinctures x 8 charges. 200-hero mock: 187 distinct, 0 identical neighbours. Same name gives the same arms every load.
- Local checks run (headless Edge, file://): ?mock=crowd, ?mock=crowd&open=1, ?mock=chronicle, ?state=empty, ?state=fail, ?state=stale. Hostile name renders as text with a valid crest and no <img> is created.
- Hero first paint (crowd mock, headless virtual-time clock): before 1006.3 ms, after 1007.1 ms. That clock is quantised, so read it as no measurable change. Recipe cost is about 0.36 microseconds per name.
- Not visually reviewed by me: no screenshot viewer was available on this run. Mr. E or the supervisor should eyeball the card and sheet at 390 and 1280.

## H16 - the Hall of the Fallen
- `renderFallen` now draws a memorial card per fallen hero: crest (H15 `coat`, md, desaturated), name, class/level, earned title, epitaph, then facts - Taken by (cause, day), Deepest, Slain, Wore (weapon + armour with whitelisted icons). Every fact is optional; a missing/zero/non-numeric one is simply not drawn (no "undefined", no guessed placeholder). All text via el()/textContent; icons via ICON_SET only.
- Epitaphs: the frozen lore (H12) carries NO epitaph set, so the hub shows only `f.epitaph` from the snapshot. No parallel list was invented.
- Fields I wanted that the snapshot may lack (supervisor to raise with the game build worker): `weapon` and `armour` worn at death (string or {name}), `title`, and `epitaph` on every fallen row; `cause`/`killed_by`, `day`, `deepest`, `kills`, `level`, `class` are already read when present.
- Local check: `?mock=fallen` (rich row, hostile-name row with hostile cause/epitaph/gear, name-only row, odd-types row). Hostile strings render as literal text; no element created from them. Run via headless Edge dump-dom: ?mock=fallen, crowd, chronicle, state=empty/fail/stale all render, no "undefined". Not visually reviewed (no screenshot viewer on this run) - eyeball at 390 and 1280.


## H17 - the hub on a phone (Nov 15)
Layout refinement only (palette, Gloock wordmark, tab model, CSP untouched; no new font/CDN/fetch).
- Tab strip: >= 44px tall snap-scrolling rail; show() in app.js centres the lit tab via nav.scrollLeft (never scrolls the page sideways).
- All tappables >= 44px at <= 760px (tabs, chips, linkbtn, retry, pin, sign-in, chat load, hero summary); text fields 16px (no iOS focus-zoom); small print floor 12px.
- `html, body { overflow-x: clip }` as a backstop. Measured with headless Chrome in a 390/360/768/1280 iframe over mock=crowd, ?state=empty/fail/stale, ?mock=chronicle, ?open=1: zero horizontal scroll, no sub-44px tap target, no sub-12px text, every tab reachable. Hostile name renders as literal text (0 <img> created).
- Not captured: pixel screenshots (no image viewer in the build session); measured via DOM geometry instead.

## H18 - The State of Bellmire (Town tab)

A new **Town** tab (`#state`, second tab) shows the place itself, in three parts. No new fetch, no new origin, no CSP change (byte-identical), no snapshot value used as a URL/src/href/style.

- **H18.1 The ladder.** The 12 rungs come from the frozen lore (`growth_tiers`, H12), read as-is. `town.level` (1-based, matching `Economy.TOWN_LEVELS`) lights the current rung (teal), fills the ones behind (gold) and names the ones ahead (dim); the caption says how many stages are left. Beside it, stat tiles: level, day, souls, treasury, raids turned back, renown, and a growth bar from `score / next_level_at`. A field the town block lacks simply gets no tile; none at all gives "The town has not sent its numbers yet." Dimness is never the only signal - every rung carries a screen-reader state word and every building a visible "standing / not yet raised" tag.
- **H18.2 What stands.** If the snapshot sends `town.buildings` (or top-level `buildings`) - an array of strings or `{name, built, does}` - the roster is LIVE: those rows are solid, and canon buildings the town did not list appear as dim outlines. Otherwise it renders the canon set (page-owned names + the frozen `see` line per tier) and is labelled honestly "canon, not live - read from the town's level"; built/unbuilt is then derived from the level. Icons: eight new page-owned symbols (`hut well stall chapel anvil tower ford wall`) added to `ICON_SET`; a building name only picks WHICH whitelisted icon by keyword.
- **H18.3 What has befallen it.** Newest-first timeline built from the H14 browser history (`chronMem`), filtered to `raid` entries plus `town` entries that read as growth/disaster/festival (and never the daily "Day N begins" line). Empty history says "Bellmire has known only quiet days." Per-browser, 48 h at most.
- Local check: `?mock=town` (every new field, hostile town/building/event names, all rendering as text). `?mock=chronicle` exercises the "no new fields" path.

**Fields I wanted and the snapshot lacks** (supervisor to raise with the game build worker):
- `town.buildings`: `[{name, built, does}]` - the roster is canon-only until it exists, and the frozen lore has no "what it DOES" line per building (the canon rows show the tier's `see` line instead; the content writer could add a short `does` per building to lore_lines.json).
- A per-entry in-game `day` on chronicle rows, so the timeline can be stamped "Day 17" in the town's own count; today it is stamped by the viewer's clock (Today / Yesterday / N days gone).
- Disaster and festival as their own chronicle `t` kinds; today they arrive as `town` and are recognised by keyword.

## H19 - the Bestiary (Nov 15)

A Bestiary tab after Lore: 8 deep lords, 5 named ones and 17 monster families (grouped from the frozen
`events.monster_camps`), each with a page-owned roundel sigil. Sigils reuse the H15 hash machinery
(`crestRecipe("sigil|" + name)`) but index a separate ring/field/charge whitelist (fangs, horns, eye, claw,
flame, wings, coil, broken crown, crossed bones), so a monster's mark never looks like a hero's crest. Same
name -> same sigil on every reload. The name only ever picks indices; no snapshot string reaches an
attribute, URL or style.

- MET vs RUMOUR: an entry is Met when the browser's own remembered Chronicle (the H14 history) names it
  (name, or for a family its singular/plural or a camp name). A Met card shows the frozen intro line (lords/named)
  or the frozen camp "while" lines (families), how many remembered lines name it and when last. Anything else is a RUMOUR:
  sigil and name only, a veiled town-voice line, no intro, no data. Chronicle lines themselves are NOT quoted
  (a remembered line could carry a depth figure; this section never states one).
- Optional snapshot numbers are read from `p.bestiary[<page-owned key>]` only if the publisher sends them
  (`faced`, `killed`, `deepest`, `standing`), via own-property lookup, numeric-coerced and capped. Today it sends none.
- The entry list scrolls inside the panel (H13); one column at 390 (H17).
- `?mock=bestiary` shows a met lord with numbers, a hostile lord name, a met family and the rumours.

### Fields the Bestiary wanted and did not get (honest gaps - game build / publisher owner)

- Per-lord and per-family records in the snapshot: `bestiary.<key>.faced`, `.killed`, `.deepest`, `.standing`
  (supported by the page, never sent).
- Tells and a description per lord: `bosses.json` is not in the frozen lore bundle (only `lord_intros`,
  `unique_intros`, `events.monster_camps`), so no tells/description are shown. Needs a lore refresh (content worker).
- A structured "monster met" signal: Met is inferred from remembered Chronicle text, so a beast the town
  met before this browser began remembering (or more than 48 h ago) reads as a rumour here.

## H20 - the hero sheet is a character sheet (Nov 15)

The hero card's open body is now a proper sheet (`heroSheet(h, mode)` in app.js), and every
fallen memorial gets a lazily-built "Read their sheet" built from the same function
(`mode = "fallen"`). Blocks: identity (crest, name, title, calling, level, pin), condition chips
with an honest "last seen", HP/XP, Abilities, Combat, Gear by slot (nine slots; an empty slot is
drawn as an empty slot, never omitted), Carrying/Satchel/cosmetics, Record, "Their own
chronicle" (H20.3: the H14 history - live plus remembered in this browser, about 48 h - filtered
to lines that name the hero as a whole word) and a foot line listing what the town did not send.

Local check: `?mock=sheets&open=all` shows a bare level-1 hero, a kitted veteran, a hostile-named
mage and a fallen hero's sheet (open the Fallen tab: `#fallen`). `?open=all` opens the first six
heroes and every fallen sheet.

Nothing is derived. No initiative-from-DEX, no estimated max HP, no guessed slot contents.

### Snapshot fields the sheet wanted and did NOT get (for the game-build owner, snapshot_pub)
These render as deliberate dashed empty cells and are named on each sheet's foot line. Aliases the
page already accepts are in brackets - the publisher may send any of them.
- `max_hp` [hp_max, maxhp, hpmax] - HP is a flat vitality bar without it.
- `xp_next` [next_xp, xp_to_next, to_next].
- `stats` {str,dex,con,int,wis,cha} - present in the real snapshot but absent on fresh heroes.
- `ac`, `hp`, `to_hit`, `prof`, `saves` - drawn empty if missing (e.g. a fallen row carries none).
- `initiative` [init] and `speed`.
- `gear` / `equipment` object keyed `main_hand, off_hand, head, body, hands, feet, cloak, neck, ring`
  (string or {name}). Only weapon (main hand) and armour (body) are published today; the other
  seven slots are drawn empty with a "not published yet" tooltip.
- `status` / `state` / `activity` / `where` on the hero - the sheet reads band membership from
  `parties` and wounded from hp/max_hp, but cannot say "resting" or "in town" without a field.
- ~~a per-hero last-seen time~~ - shipped in v=4 (`h.last_seen`), read since H23; older publishers still get the whole-town fallback and the named gap.
- On fallen rows: `species`, `ac`, `stats`, `weapon`/`armour` as slots, level history.
- Wanted but not drawn as cells: background/origin, alignment, skills and proficiencies,
  spells and slots, hit dice, a full inventory.
- Personal history is only as good as the chronicle: lines must contain the hero's name verbatim.
  A per-hero event feed (best depth, notable kills, deaths with day) from the publisher would
  replace the name-match.


## H21 - the campaign journal (Nov 15)

The Chronicle tab is now a journal, built only from what the page already has (the live snapshot's
`chronicle` plus the H14 browser history). No new fetch, no new origin, no CSP change, no write path.

- **H21.1 Episodes.** The snapshot carries no town-day on chronicle lines, so stretches are made by
  session instead: a new stretch starts after a 90-minute quiet gap or after 6 hours of length. Each has a
  town-voice heading (`Now, as the town tells it` / `Earlier today, by the bells` / ...), a clock range, a line
  count and a one-line sense ("A hard stretch - 1 death, 1 raid.") made only from page-owned words and counts.
  The newest stretch is open, older ones fold; a filter or a moment link opens what it needs. Open/fold is a
  button with `aria-expanded`.
- **H21.2 Filters.** A hero select (roster from the snapshot, whole-word name match - same `namesIn` as the
  H20 sheet) and an event select (Raids, Disasters, Festivals, Deaths, Delves, Town growth - kind plus page-owned
  keyword lists) join the existing kind chips and search. Hero + event + kind-off state persists in
  `localStorage["bellmire.chron.f.v1"]` and is re-validated on read. Search text is not persisted.
- **H21.3 While you were away.** `bellmire.chron.seen.v1` holds when this browser last looked (written while the
  tab is visible and when it is hidden/closed). If the gap is 30+ minutes the Chronicle opens with a card: line
  count by kind and up to five lines that matter (deaths > raids > town > delves, disaster/festival lines lifted).
  It says so when it may be incomplete: the town only reports its latest 50 lines, this browser keeps ~2 days /
  300 lines, and the page can only remember what it saw. `?away=6` (hours, 0.5-72) simulates a gap locally.
- **H21.4 Moment links.** Every remembered line has a page-assigned integer id (`bellmire.chron.seq.v1` counter,
  stored on the history rows). The Link button sets `#moment-<n>` and copies the address; opening it switches to
  the Chronicle, opens that stretch, scrolls to and outlines the line. The id is only compared to row ids. Links
  are per-browser: a browser that does not remember that line says so plainly instead of guessing.

Not in the snapshot, so not possible yet: the in-game town day on each chronicle line (a `day` field would
replace the session heuristic), and a structured hero/kind per line (the hero filter name-matches the text).
Note: the older `setUpTabs()` in app.js is dead code (the nav uses buttons now; live tabs are `wireTabs`).

## H23 - accept v=4, read last_seen / events, two render fixes
- `KNOWN_V` is now 1-4. An unknown version still shows the honest "newer dialect" banner. A v=3 payload (no new fields) draws exactly as before.
- `h.last_seen` (ISO string, validated with `CHRON_AT_OK`, then only fed to `ago()`) gives each sheet its own "Last seen N ago"; when the whole town is stale the line says so too. Absent -> the old whole-town line and the named gap.
- `h.events` (newest-first `[{t, s, at}]`, up to 6) builds "Their own chronicle" through the same `chronEntries`/`chronShape` + `el()` path as a live line. Empty or absent -> the H20 whole-word name match against the H14 history.
- Fix: each gear slot's text block (`.stx`) was built but never appended to its cell, so every slot drew as just an icon. Now attached.
- Fix: the heroCard crest printed "[object SVGSVGElement]" because the H19 Bestiary's `sigil()` (returns an SVG) silently shadowed the initials helper of the same name. The initials helper is now `initials()`.
- No CSP change, no new fetch/origin, no write path. `?mock=sheets` now carries last_seen, events and slot names (including a hostile `last_seen` that must be ignored).

## H24 - the finder (find anything, from anywhere)

One search field under the status line, over everything the page already holds in memory: living heroes, the fallen, bands (and their members), the Bestiary's lords and kin, and remembered Chronicle lines (the H14 browser history). Page-local only - no fetch, no origin, no write path, CSP untouched.

- Opens a result by landing on the thing itself: a hero's own card (opened), the grave in The Fallen, the band card, the lord's Bestiary entry (filter reset to All), or the remembered moment in the journal via the H21.4 `#moment-<n>` id.
- Results address their target by an INTEGER the page owns (`data-fi`, `data-bi`, the moment's `n`). No snapshot string goes into a selector, URL, href, src or style. Every result row is built with `el()`.
- Honest empty state: says the finder only knows what this browser has seen (the live town + about two days of remembered Chronicle), and says so plainly when the town has not reported at all.
- Keyboard: `/` focuses the field (never while typing in another input - the guild chat is safe), Up/Down choose, Enter opens, Escape closes (a second Escape clears). Min 2 characters, query capped at 60, control characters stripped.
- Ranking: names that START with the query first, then word-start, then anywhere; stable across kinds (hero, fallen, band, lord, moment). 6 per kind, 24 total.
- `beastBook()` was factored out of `renderBestiary` so the Bestiary and the finder read the same list.

## H25 - the Night Watch (long-session mode)

A button under the status line (`#watchBtn`, "Night watch" / "Back to the full page") flips ONE class, `watch`, on `<html>`; every change is CSS. It never touches the DOM the renderers build.

- **Dimmed watch (.1)**: redefines the same tokens (parchment pulled back, ink kept dark, teal and gold toned down, night ground deeper). Faded rows (`opacity` .55-.88) return to full opacity in this mode; the three small status tags carry their own fixed colour pairs.
- **Ambient layout (.2)**: shows only the town strip, the status line, the Chronicle and Bands below, side by side from 900 px and stacked under it. The finder, tab bar, Chronicle filters/search/away card, footer and the harlequin band fold away. The other tabs stay in the DOM (hidden), so the Back button restores everything.
- **Quiet (.3)**: all animation/transition is off in this mode (the 60 s refresh re-runs `feedin` on every row in the full page, which reads as a flash). Chronicle and Bands scroll inside fixed-height boxes, the status and town rows keep a minimum height. Nothing in the page calls `focus()` on a refresh; the watch button keeps focus through updates. `prefers-reduced-motion` is therefore honoured by construction.
- **Remembered (.4)**: key `bellmire.watch.v1`, value `watch` only. Read back through `ctrlStrip`, capped at 12 chars and compared to the single literal; anything else (including `<img src=x onerror=alert(1)>`) is ignored. Storage that throws leaves the full page. `?watch=1` turns it on for one visit without storing.
- Known limit: the class is applied when `app.js` runs (CSP forbids an inline pre-paint script), so a remembered watch mode can show one frame of the full page before dimming.

Measured (headless Chrome, 1280x800, `?watch=1` with `?mock=bands`, `?mock=chronicle`, `?mock=crowd`, `?state=stale|empty|fail`; worst colour stop vs the effective background, element opacity included; threshold 4.5:1, 3:1 for large text). 0 failures; lowest is 4.60:1.

| text style | worst ratio |
|---|---|
| `h2.title fg=rgb(79, 26, 12)` | 4.60 |
| `p.eyebrow fg=rgb(79, 26, 12)` | 4.60 |
| `span.bmtag.st-other fg=rgb(23, 15, 8)` | 5.05 |
| `small fg=rgb(42, 27, 12)` | 5.43 |
| `span.bmcls fg=rgb(42, 27, 12)` | 5.43 |
| `span.hpk fg=rgb(42, 27, 12)` | 5.43 |
| `p.note fg=rgb(42, 27, 12)` | 5.43 |
| `p.note.quiet fg=rgb(42, 27, 12)` | 5.43 |
| `p.empty fg=rgb(42, 27, 12)` | 5.43 |
| `button.watchbtn fg=rgb(7, 16, 15)` | 5.64 |
| `span.cep-title fg=rgb(79, 26, 12)` | 5.69 |
| `span.bandfloor fg=rgb(220, 207, 169)` | 6.05 |
| `span.bmname fg=rgb(23, 15, 8)` | 6.17 |
| `span.hpv fg=rgb(23, 15, 8)` | 6.17 |
| `span.tk fg=rgb(173, 154, 114)` | 6.53 |
| `span fg=rgb(173, 154, 114)` | 6.59 |
| `span.bmtag.st-burning fg=rgb(239, 226, 191)` | 6.60 |
| `p.sub fg=rgb(173, 154, 114)` | 6.60 |
| `span.tv fg=rgb(170, 156, 120)` | 6.61 |
| `span.tv.growv fg=rgb(170, 156, 120)` | 6.61 |
| `b fg=rgb(170, 156, 120)` | 6.68 |
| `h1.wordmark fg=rgb(170, 156, 120)` | 6.68 |
| `span.cep-when fg=rgb(42, 27, 12)` | 6.70 |
| `span.cep-sense fg=rgb(34, 22, 11)` | 7.11 |
| `span.watchhint fg=rgb(173, 154, 114)` | 7.27 |
| `button.cmoment fg=rgb(11, 79, 76)` | 7.33 |
| `span.hd fg=rgb(11, 8, 5)` | 7.85 |
| `span.bmtag.st-fallen fg=rgb(230, 217, 184)` | 8.04 |
| `span.ckind fg=rgb(79, 26, 12)` | 11.03 |
| `span.bandmeta fg=rgb(42, 27, 12)` | 13.00 |
| `time.cwhen fg=rgb(42, 27, 12)` | 13.00 |
| `span.bandname fg=rgb(23, 15, 8)` | 14.79 |
| `p.cline fg=rgb(23, 15, 8)` | 14.79 |

Quiet-update check: with `?watch=1&mock=bands` and `?mock=chronicle`, `load()` called twice with the page idle: 0 layout-shift entries, 0 running animations, every section's top/height identical before and after, scroll position unchanged, focus stays on `#watchBtn`. (Mock data is constant, so this proves the render path is geometry-stable, not that real changes are small.)

Gaps, honestly: no desktop recording was made (headless capture only, no video); screenshots of full vs watch at 1280 and watch at 390 were taken but are not committed.

## H22 - the first minute (newcomer welcome)

A short welcome block sits between the status line and the finder: what Bellmire is (static copy, town's voice, about
sixty words), ONE live line, and three doors. The live line is built in `paintWelcome()` from the payload `render()`
last drew plus the same `last` / `lastError` / `STALE_MIN` the status line uses, so it is honest in every state: live
("Live, updated N min ago"), stale or failed-refresh (the numbers are kept but prefixed "As of ..."), empty ("has not
reported in yet") and failed fetch ("out of reach just now"). It says only what the snapshot carries - town stage from
the lore tier names, heroes on the roll, heroes abroad (only when a bands field exists), and the newest Chronicle line.
The doors (Get a hero / Watch what is happening / Learn the rules) switch to the Commands, Chronicle and die tabs via
`setActiveTab()`; the markup only carries a page-owned `data-door` id that is matched against `TABS`. They link, they do
not restate. "Got it - don't show this again" stores `seen` under `bellmire.welcome.v1` (per browser, whitelist-checked on
read); a small "What is Bellmire?" button in the watch bar brings it back for the visit without un-dismissing. It is an
ordinary block in the flow - no overlay, no sticky, no gate - the doors stack on a phone and sit three-across from 680 px.
Hidden in Night watch. `?welcome=1` forces it open for local checks.

## H26 - the journal stops guessing

D60 (the town's own calendar) means each Chronicle row may now carry `day`, and tagged rows carry `kind` and `who`.
`chronShape` validates all three (`day` a whole number 0..999999, `kind` a bounded identifier, `who` at most 6 names of
40 chars, control characters stripped) and the H14 browser memory stores and re-validates them (`histClean`).
- **Days, not stretches (.1).** A row with a `day` is grouped by it ("Day 41"); a row without one (v=3-era payload, untagged
  row) falls back to the H21 90-minute wall-clock heuristic. Every group says which basis it is on ("Grouped by the town's own
  day" / "No town day on these lines - grouped by gaps in this browser's clock, a guess") and the footer note counts both.
- **Who, from the payload (.2).** Hero filter and the sheet's "Their own chronicle" use `who` when a row has it; only a row
  with no `who` falls back to the whole-word name match, and that row is marked "inferred from name" (the filter note counts them).
- **Filter by kind (.3).** The Event select prefers `kind` (raid, disaster/hunger, festival, death, delve, find, growth, and
  a new "Town life" for day/treasury/caravan/arrival/watch/rally). Untagged rows are matched by wording as before and the note
  says how many lines carry no kind and how many of the shown ones were matched by wording.
- **Honest (.4).** Everything through el()/textContent; no field becomes a URL/src/href/style. index.html untouched - CSP byte-identical. KNOWN_V unchanged.
Local checks: `?mock=journal` (days + kind + who, hostile `<img>` in a `who` entry and a non-identifier `kind`, which is treated as
untagged) and `?mock=journal3` (the same rows with the fields stripped = a v=3 payload, old grouping with the fallback labelled).
Headless Chromium over a stubbed snapshot: 0 dialogs, 0 <img>, no horizontal overflow at 390; ?state=empty/fail/stale, ?mock=chronicle,
?mock=crowd, ?open=1 and ?mock=sheets&open=all all render.

## H27 - Tales of the Die (the night's rolls get a board)
The town's rolls (H9, `p.rolls`) are now kept the way H14 keeps the Chronicle: per-browser, newest first, capped. localStorage key
`bellmire.rolls.v1`, at most 100 rows / 48 h / 60 KB (oldest dropped first). Each pass folds the live rolls into the memory, de-duplicates on
(at, by, face, result), keeps a roll's first-seen time `k` for rolls the publisher sends without `at`, and persists. Every stored row is
re-validated on read (`rollsClean`: normalizeRolls + control-char strip + timestamp regex), so a tampered store cannot inject anything.
- Board: day dividers in the town's own voice (`dayVoice`, same as the Chronicle), each roll = roller, what they paid for (`what`, `cost`),
  the number, the tier tag and the outcome line (`result`, exactly what the publisher sent).
- A crit is the 20 (or, face unknown, tier crit); a fumble is the 1 (or tier fumble). Crit = restrained gold (field, face, tier tag); fumble =
  ink-soft, dashed face, no red - no new colour. A tally chip pair above the list counts crits/fumbles in the rolls SHOWN, so it always matches.
- Empty (nothing live, nothing remembered): "No rolls yet tonight." With the town silent but rolls remembered, the board shows them and says so.
- Storage absent/full/throwing: renders from the live rolls only. No new fetch/origin, no write path, CSP untouched (index.html only gained the
  page-owned `<p id="rollTally">`). KNOWN_V unchanged.
- FIELD WANTED, NOT PRESENT: the brief says crit/fumble outcome lines are `viewer_roll` in lore_lines.json (C-cycle 38). `data/lore_lines.json` on
  hub/main has NO `viewer_roll` key, so nothing is frozen into the hub for them; the board shows the publisher's own `result` and draws no line
  when it is absent. If the publisher omits `result` for crit/fumble, ask the game build to send it (or land the lines and a later H item freezes them).
Local check: `?mock=roll` (crit, fumble, two ordinary, one hostile-name roller `<img src=x onerror=alert(1)>`). Headless Chromium over a stubbed
snapshot: 5 rows, 1 crit + 1 fumble matching the chips, reload with no mock keeps all 5, a multi-day store divides Today/Yesterday, a tampered
store (hostile strings, junk rows, bad timestamp) renders as text, 0 dialogs, 0 <img>/<script> in the feed, no horizontal scroll at 390,
?state=empty/fail/stale, ?mock=chronicle, ?mock=crowd and ?open=1 all render with 0 page errors.

## H28 - a hero you can point at (deep link)
- `#hero-<n>` opens that hero's sheet. n is an integer the PAGE computes: 32-bit FNV-1a of the lower-cased name (`heroAddr`). No name is ever in the URL.
- The "Copy a link to this hero" control on a living hero's sheet writes `<page address>#hero-<n>` to the clipboard (falls back to the address bar when the clipboard is refused). Fallen heroes have no link control (the finder and Fallen tab cover them).
- An address that matches nobody on the roll (or is malformed, e.g. `#hero-abc`, too many digits) lands on Heroes with the plain note "That hero is not on tonight's roll." No error, no blank page.
- Applied after each render only when the address changes, so the 60 s refresh never re-lands the viewer. Two heroes whose names collide on the 32-bit hash would open the first one on the roll (vanishingly unlikely).
- Known limit: the link is per NAME; a renamed hero's old link goes to the note. The snapshot carries no stable hero id (a field the hub would prefer).

## H30 - the Satchel tab (fourteenth)
Signed-in viewer only (twLogin from H6; hero matched by exact login; the H11 pin is NOT used). Carried items with weight/value/value-per-pound sort (default), slot chips, text filter; carry bar (hpbar, CSSOM number) with 1/3 and 2/3 ticks = 5e encumbered/heavy; vault; own orders; stone (double press). Buttons send chat commands via satSend() -> satCommand(): fixed verb table + ONE argument stripped of C0/C1/U+2028/9 and capped at 80, so a name cannot carry a second line or command. Mocks: ?mock=satchel (derived from STR) satchel0 (empty) satchel1 (light) satchel3 (encumbered) satchel2 (heavy) satchelout (signed out); mock buttons print the command instead of sending.
ASSUMED command names (not in the plan, confirm with D81): !withdraw (vault take-out), !stone. Edit SAT_VERBS / SAT_STONE only.
Publisher contract read (v5+): hero.satchel[{name,qty,weight,sell,slot,rarity,worn}], hero.carry{weight,cap,band}|hero.encumbrance, hero.vault[]|{items,slots}, hero.where. Missing = "not published", never faked.
Item icons (D73 PNGs) NOT used: they live outside web/ and a snapshot value cannot choose a src; glyphs from ICON_SET instead. Needs Mr. E's call (copy a curated set into web/ + whitelist).

## H31 - the Season tab
Fifteenth tab ("Season"), the hub home of the L66 leaderboard (the stream keeps no leaderboard, COORDINATION 13).
Four cards, top ten each, living + fallen: Went deepest (`deepest`), Earned most, Died hardest (fallen only, by deepest
floor), Lived longest. Honest gaps: the publisher sends only current `gold` today, so "Earned most" ranks gold held and
says so; no age/born_day fields exist yet, so "Lived longest" shows an explanatory empty state. Both light up by
themselves when the fields arrive (names in HUB_SECURITY.md). Checks: ?mock=season | season0 | season3.

## Version-gate re-verification (hub run, 2026-11-16 ~21:40 UTC)
Headless Chromium, real-shaped snapshots (publisher v4 shape: shops[{name,level,sells_to}] with no stock/caravan/orders yet), hostile name `<img src=x onerror=alert(1)>` in hero, satchel row and shop name.
- v4 and v5 payloads: Shops tab lights up by itself (levels, "sells up to" with rarity slug incl. "very rare"); Satchel renders; no page errors; 0 dialogs; hostile names are text (no injected <img>).
- Stale (30 min old): "Last word from the town 30 minutes ago ... may be out of date". ?state=stale, ?state=empty, ?state=fail, ?mock=chronicle, ?mock=crowd, ?open=1 all behave.
- Unknown v9: honest "needs an update" problem, no tab content.
- Still open on the GAME BUILD side: snapshot_pub.gd sends shops WITHOUT `stock`, and no `caravan`/`trader`/`orders` yet, so each shelf honestly reads "The shelf has not been published yet." The hub needs no change; it lights up when those fields arrive (items.json shop_stock / trader_cargo wiring in the publisher).

- 2026-11-16 ~17:40 CT hub run: lane STOOD DOWN. Read WORK_PLAN hub row (H14-H31 all ticked) + H29/H30 items; H29 point 6 still blocked on the game build publisher (snapshot_pub.gd sends shops without stock/caravan/orders). Checked app.js: node --check OK, no innerHTML on snapshot data (2 page-owned sites), CSP meta present. No defect found, no web/ code changed.

## H32 - navigating like Twitch (passes 1-2 so far)

Read as: Twitch's STRUCTURE and INTERACTION, not its colours (the palette ruling stands) and never its
brand. Pass 1 - a fixed top bar and a three-column shell, three independent scroll regions, no page
scroll. Pass 2 - the left rail: a listbox of live things. A hero mid-delve is a live channel: sigil for
the avatar, name, "Floor 7 - The Ford Wardens", a LIVE dot and, where Twitch puts the viewer count, the
FLOOR (it moves and it is what a delve is about). A band's number is its head-count; an idle hero shows
level, dimmed. Live first, idle below, the fallen not on the rail (they have their own tab). The rail
collapses to sigils only. Picking an entry opens the new "Live" stage: a dark player banner, an info row
(title / who / tags / Follow) and the full sheet beneath. The LIVE dot is red (`--live`), a functional
signal used nowhere else. Welcome panel placement and chat are still to do (passes 3 and 5).
- H32 pass 3: Guild chat is now a persistent right column (collapsible; on a narrow screen a top-bar button
  opens it full-screen). It remains opt-in - the viewer still presses "Open the guild chat" - because
  auto-connecting to Twitch on page load would change the privacy behaviour H8 was built around. That is
  Mr. E's call (see the run summary). The "Guild chat" tab is gone; the column replaces it.
- H32 pass 4: Shops stock is a card grid (picture, name, rarity pill, price; rarity as a frame) with a hover/focus
  preview overlay; Bestiary cards lift on hover/focus; Lore chapters are browse cards. Pictures are derived
  160 px WebP thumbnails (1.94 MB for 463) chosen by a generated name whitelist - see docs/HUB_SECURITY.md.
- H32 pass 5 (polish): thin dark scrollbars on the three scroll regions (the narrow top strip showed a white native bar); a fade on the right edge of the section bar and the active tab scrolled into view, so a clipped tab reads as "more this way"; a skip link to the stage; keyboard shortcuts while not typing - "[" folds the rail, "]" folds/opens the chat, "g" focuses the rail (the listbox keeps Up/Down/Home/End/Enter). Layout and keys only: no data, no CSP change, no new storage key. Live dot stayed red (--live): it does not fight the gold because it is 8 px and used only for the dot and the LIVE badge.

## H32 acceptance run (hub, 2026-11-16 ~21:45 CT - was headed with the 2026-11-17 UTC date first; CT leads on this ledger)
No code changed. Headless Chromium 1440x900 against the merged tree (hub + origin/main), Supabase fetch stubbed with a v5 payload containing a hostile hero name and hostile shop name.
- ?state=empty, ?state=fail, ?state=stale, ?mock=chronicle, ?mock=crowd (60-row rail page), ?open=1, ?mock=bands (6 rail rows), ?mock=shops, ?mock=bestiary, ?mock=lore, payload v=9: 0 page errors, 0 dialogs, 0 injected <img>, document scrollHeight - innerHeight = 0 in every case (H13 holds), honest status line text per state, unknown version shows no town data.
- Hostile `<img src=x onerror=alert(1)>` renders as literal text in rail, shop names, caravan stock and bestiary cards.
- LOOKED AT: Shops card grid (picture, rarity pill + rarity frame, price; bare / not-published shelves read honestly), Bestiary cards, Lore chapter cards, the 420 px one-column layout (rail becomes a top strip, chat a top-bar button). Item pictures in the capture are the generic gem because only 10 thumbnails were staged for the run; the real set is web/icons/items/.
- Live dot: red (--live), unchanged.

## H32 real-set LOOK (hub, 2026-11-17 ~01:00 CT, after the halt was lifted)
No code changed. Headless Chromium against the merged tree (hub + origin/main 93770e6) with the Supabase fetch stubbed by a v5 payload: a 465-item Blacksmith shelf built from the REAL whitelist names plus a hostile item name and a hostile shop name (`<b>x</b>`), a 30-item Chandler, a bare Provisioner.
- Real thumbnails (web/icons/items, 463 files, 1.94 MB): at 1440x900 and 420x800, 216 shelf images rendered (the rest are lazy, below the fold), 0 broken, 216 of 216 `loading="lazy"`.
- H13: document scrollHeight - innerHeight = 0 and scrollWidth - innerWidth = 0 at BOTH widths, with the real images loaded. The grid scrolls inside the stage.
- Security: hostile item and shop names render as literal text, 0 injected `<img>`, 0 dialogs, 0 page errors. An unknown item name falls to the generic gem (honest fallback, never a guessed path).
- LOOKED AT (1440 screenshot, hover shot, 420 shot): rarity frames and pills read correctly (epic purple, rare blue, uncommon green, legendary gold, common bare), prices align, the hover/focus preview enlarges the card and adds "Costs N gold - N on the shelf". Seen and judged fine: on a first visit the Welcome panel sits above the stage and pushes the shelves below the fold (it is dismissible and was ruled to stay above the stage); at 420 px the rail is a thin top strip with a clipped sentence when nobody is on the roll. Names truncate with an ellipsis in the narrow cards ("Unknown Thing Not In..") - full name is in the hover preview.
- Live dot: red (--live), unchanged. The UNCOMMON pill clip fix (cf40e31) was the only change the earlier look needed; this ledger entry is the record that was missing.
- Housekeeping: the seven loose files in the worktree (_h32_shot_a..f.png, web_look.tar, _plan_tmp.txt) are NOT committed - superseded by this look, and web_look.tar is 3 MB of binary git would keep forever. The attempt to delete them from the worktree was refused by the permission gate, so they are still sitting there untracked: Mr. E or the supervisor can delete them, or give the hub a go-ahead.

## H32 icon refresh (hub, 2026-11-17 ~02:00 CT, after the halt was released)
Art's System 1 (rarity hue ladder + icon origin fix, origin/main 2473836) replaced the pictures under assets/icons/items and added 57, so the 463 thumbnails were stale. Re-ran web/tools/make_item_icons.py --commit 2473836: 520 WebP at 2,341,956 bytes (budget 6 MB), whitelist block in app.js regenerated, one name conflict recorded in the manifest (Scarglass Ring dropped for Scar Ring). The converter's rmtree now ignores errors so it can overwrite in place where deletion is not permitted; it still reads-never-writes assets/.
- LOOKED AT: headless Chromium 1440x900 and 420x800, Supabase stubbed with a 401-item Blacksmith shelf from the real manifest names plus a hostile item and a hostile shop name. 158 item images rendered (rest lazy), 0 broken, scrollHeight/scrollWidth overflow 0 at both widths, 0 page errors, 0 dialogs, 0 injected <img>. Hostile names render as literal text and fall to the generic gem. Real pictures show (amulet, banner) inside rarity frames and pills.
- Wrong in the picture: the welcome card pushes the first shelf row below the fold at 900 high on a first visit (dismissible, not changed). In my stub the rarity pill is cycled by me, so a "COMMON" pill on a purple-tinted amulet is the stub, not the page.
- No CSP change, no innerHTML added, live dot unchanged (--live red). Stale files from renamed icons, if any, remain on disk until a delete-permitted run; they are not in the whitelist.

## H32 standing check (hub, 2026-11-17 ~02:45 CT, after merging origin/main 463ab1b)
No code changed; H32 passes 1-5 are all in (ticked whole at ddee675) and the thumbnails are the 520-file set. Re-checked the tree by grep and measurement: `node --check app.js` OK; the only two innerHTML sites are the page-owned status line and failed-fetch box; CSP unchanged (img-src 'self' data:, no new origin); web/icons/items = 520 WebP, 2,430,050 bytes on disk (manifest count 520, budget 6 MB). No new screenshot this hour - nothing visual changed since the 02:00 look. Live dot: red (--live). The nine loose files in the worktree root (_h32_shot_a..f.png, _plan_tmp.txt, web_look.tar, web_look2.tar) stay untracked: deleting is refused on this machine and 6 MB of binary is not worth keeping in git.

## H32 standing check (hub, 2026-11-17 ~20:38 CT, after merging origin/main and origin/hub)
No code changed. `git diff HEAD origin/main -- web/ docs/HUB_SECURITY.md` is empty; the icon manifest source commit (2473836) has no later change under assets/icons/items, so the 520 thumbnails are not stale. Measured: `node --check app.js` OK; innerHTML only at the two page-owned sites (status line, failed-fetch box), no outerHTML/insertAdjacentHTML/document.write/eval/new Function; CSP unchanged (img-src 'self' data:, no new origin); web/icons/items = 520 WebP, 2,430,050 bytes (budget 6 MB). No screenshot this hour - nothing visual changed since the 02:00 look. Not re-run headless: state tests (?state=empty/fail/stale, ?mock=chronicle/crowd, ?open=1, hostile name) - web/ is byte-identical to the build they last passed on. Live dot: red (--live). Loose untracked files (_h32_shot_a..f.png, _plan_tmp.txt, web_look.tar, web_look2.tar) stay untracked: delete refused on this machine, 6 MB binary not worth keeping in git.

## H32 LIVE-PAGE LOOK (hub, 2026-11-17 ~22:50 CT, after merging origin/main)
Row from the team lead's 21:58 block: look at the PUBLISHED page in a real browser. No code changed. Real browser = Claude's built-in browser pane (the cloud sandbox cannot reach github.io: ERR_TUNNEL_CONNECTION_FAILED, so no screenshot file was kept; the pane screenshot was viewed).
- LOADS: https://jestsayin96.github.io/Bellmire-HD-stream/ title "Bellmire HD - the Guild Hall"; CSP meta present.
- style.css and app.js: both 200; style.css parsed 1009 CSS rules; Gloock woff2 200; Supabase snapshot fetch 200. --live resolves to #e5484d (red live dot).
- CONSOLE: 0 messages (no errors, no warnings).
- ICONS: the live snapshot carries no shop data ("Bellmire has not reported its shops yet", game last ran 2 days ago), so the Shops tab has no item pictures to render (0 images in DOM, 0 broken). Resolved by direct probe instead: icons/items/amulet/bell_amulet.webp and barracks_key.webp each load, 160 px wide.
- RARITY FRAMES per rung: NOT checkable on the live page - no items are served, and the served style.css is the old ladder (hub's change is unpublished, as expected). Left alone.
- LOOKED AT: rail, stage, welcome card, stale banner ("Last word from the town 2 days ago") and right chat column all render and read correctly in the pane. Pane was ~800x600 and reported innerWidth 0, so scrollHeight-innerHeight=55 from that run is NOT a valid H13 measurement; not recorded as a finding.
- Served build is at least the H32 layout; I did not diff it against gh-pages 40223be (no access to that branch from here by design).

## MR. E'S OBSERVATION ON THE LIVE PAGE - FOR THE TEAM LEAD (hub, 2026-11-17 ~23:00 CT)
Mr. E, verbatim, looking at the published page: "if you go all the way down its cut off after shops. please include that in your report when team lead views it."
- WHAT HE SEES: the section bar (Live, Boards, Town, Heroes, Bands, Chronicle, The die, Guild Roll, The Fallen, Lore, Bestiary, Shops ...) is clipped at the right edge after "Shops". The tabs that follow (Your Satchel, The Season, and anything after) are cut off; only a sliver of the next tab shows. My own 22:50 look saw the same: "Satchel" half-visible at the right edge.
- WHAT IT IS, AS FAR AS I CAN TELL: the bar scrolls horizontally inside its own region (H32 pass 5 added a right-edge fade and scrolls the active tab into view as the "more this way" hint). At Mr. E's width that hint is not reading - he took it as the end of the list, so the last tabs look missing, i.e. unreachable.
- STATUS: REPORTED, NOT FIXED. I changed no code this run and have not tested a fix. It is a layout fault on the served page, and any change to web/ would bring the hostile-name and ?state/?mock checks back. If the team lead wants it taken, it is a hub row: make the clipped tabs obviously reachable (visible scroll arrows or a wrap/overflow menu) without breaking H13 no-scroll or the tablist roles.

## web/tools/sheet_overlap.js - does it belong under web/? (hub run, 18 Nov 2026 15:39 CT)
Answer: YES, it stays. It is a Node + Playwright harness, not page code: index.html and app.js
never reference it and a browser cannot run it. But web/tools/ is already the hub's tools dir and
gh-pages already carries three other dev tools from it (gen_d20.py, make_item_icons.py, og.html), so
publishing it adds no new KIND of file. Grepped clean of any token/secret/key (the only "Bearer"
strings in web/ are the two page constants in app.js: publishable key + Twitch client id).
docs/ and tools/ at the repo root are not hub-owned, so moving it out would mean writing to files
this lane may not touch. Measured publish delta, gh-pages^{tree} 2d14aa9 vs HEAD:web 35eb801:
3 files, +60/-24 = app.js -14, style.css +25/-10, tools/sheet_overlap.js +45 (new, inert).

## What the 14 deleted lines of app.js carried, and what carries it now (hub run, 18 Nov 2026 16:4x CT)
Asked by the team lead (16:0x block, row 4) so the person authorising a push knows what leaves the page.
THE DELETION: `function shopGood(g, passing)` - the old one-line-per-item shop stock row (a `li.shop-good`
with name, "xN" quantity, rarity label and a coin price). 14 lines removed, zero added.
WHAT IT DID: drew a stock/cargo item as a flat list row; passing-caravan rows got the `passing` class and
a rarity class frame.
WHAT CARRIES IT NOW: `shopCard(g, passing, shopName)` (app.js ~3768, H32 pass 4), called at the shelf
(~3823) and the caravan cargo (~3843). Same inputs and same fields - name (control chars stripped, 60 cap,
"(unnamed)" fallback), rarity (rarityClass frame + 16-char pill), cost (coin icon, "-" fallback), qty (now
shown in the hover/focus preview as "N on the shelf"), and `passing` (class + "Passing through with the
caravan" line). Every string still goes through el()/textContent; the picture is the itemPic() whitelist.
WHY IT IS SAFE TO LEAVE: `grep -n shopGood web/app.js` now returns nothing - the function had ZERO callers
after pass 4, so no behaviour leaves the page. The `.shop-good` CSS is NOT dead: the order rows
(app.js ~3858 and ~4133) still use the class, so style.css keeps those rules.
CHECKS (measured): node --check app.js OK; innerHTML at app.js:255 and :301 only, both page-owned;
zero outerHTML / insertAdjacentHTML / document.write / eval / new Function in code. No browser run: this
run changed only NOTES.md, so the hostile-name test is not owed. Not claiming READY TO PUBLISH.

## 20 Nov 2026, 18:4x CT - HUB firing: payload ask (answers the team lead's 17:58 row)
Measured: origin/gh-pages^{tree} = origin/hub:web = origin/main:web = 9ca8051e (delta ZERO). web/ unchanged; no READY TO PUBLISH claim.
THE ONE-LINE PAYLOAD ASK (owner: snapshot_pub.gd, currently PAYLOAD_V 5): bump to v6 and add, per hero in the heroes rows, "mana" / "mana_max" (ints, roster.gd h["mana"], h["mana_max"], 0/0 for non-casters), and per delving band in `parties` a "miniboss" key (the MB_NAME key string, "" when none) so the hub can show a boss-fight chip and a mana bar. Today the hub carries zero mana and zero miniboss fields (app.js has no reference to either). Hub will gate on v>=6 and fall back honestly on v5.

V6 PAYLOAD CONSUMED (20 Nov 19:40 CT, hub). KNOWN_V now accepts "6". Per hero: manaBar() draws an MP bar only when mana_max > 0 (non-casters 0/0 and v5 rows show nothing). Per band: parties[].miniboss is accepted only if it is a snake_case token (^[a-z][a-z0-9_]{0,39}$), shown as "Boss fight - <Title Case>" in the band header via el()/textContent; anything else is dropped. ?mock=v6 exercises both with hostile strings. The game still publishes PAYLOAD_V 5 (scripts/snapshot_pub.gd:48), so live pages show neither yet - the hub falls back honestly. Mana fill is a functional blue (the one new bar colour). No CSP change, no new data source.

## 20 Nov 2026, 20:4x CT - HUB firing: boss chip shows the NAME (answers the team lead's 19:58 HUB row)
Amended v6 ask: parties[].miniboss_name = the MB_NAME display value ("Shacklemaw"); parties[].miniboss (the key) may ride alongside for matching but is never shown. Chip = "Boss fight - <miniboss_name>" via el()/textContent; name must match letters/digits/space/'-.,, <=40 chars, else dropped. A band with only a key shows NO chip. ?mock=v6 now has: named band (chip), hostile key+name (no chip, no <img>), key-only band (no chip). Snapshot_pub.gd owner: send miniboss_name; the hub ignores the key for display.

## 24 Nov 2026, 12:4x CT - HUB firing: the zero-byte icon (answers the team lead's 12:37 HUB row)
`web/icons/items/hat/turbary_hood.webp` was 0 bytes on main from 17 Nov 07:42 while `_manifest.json` still said 2718. It was the ONLY zero-byte file under web/, assets/, data/ and scripts/ (measured: `find ... -size 0`). Regenerated from `assets/icons/items/hat/turbary_hood.png` with the generator's own parameters (160 px, webp q85, method 6): it is now **2718 bytes - byte-identical to the manifest figure**, decodes as 160x160 RGBA. The other 519 were not touched; app.js is byte-identical (the ITEM_ICONS whitelist block did not change).
GUARD: `make_item_icons.py` gained `verify_icons()` and a `--verify` mode (no writes). Every .webp under web/icons/items must be non-empty, equal the manifest's byte count, decode, and be THUMB x THUMB; manifest entries missing on disk are red too. The full generator now runs the same check before its budget check and exits non-zero. RED-PROVED: a copy with the file re-zeroed prints `ZERO BYTES: hat/turbary_hood.webp`; the real tree prints `verify: GREEN (0 problem(s))`.
CHECKS: node --check app.js OK; innerHTML still at app.js:255 and :301 only. The browser hostile-name run was NOT repeated: no code path changed, only one binary thumbnail and the offline tool. Not claiming READY TO PUBLISH (one icon + tool change; nothing the supervisor was asked about).

- 24 Nov 15:4x CT standing audit (no row owed): web/ tree c03fa129 == origin/main:web == origin/gh-pages tree (publish 7, 5ce35f33, 15:30 CT). Zero 0-byte files in web/icons/items on hub and on gh-pages. app.js: innerHTML only at :255 and :301 (page-owned); zero outerHTML/insertAdjacentHTML/document.write/eval/new Function; node --check OK; CSP meta present. web/ unchanged this run, so the hostile-name test is not re-owed.
