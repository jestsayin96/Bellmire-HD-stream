class_name TwitchEventSub
extends Node
## Twitch phase 2 (T1): follows, subs, bits and channel points, and replies in chat.
##  - EventSub WebSocket as the broadcaster (bits:read, channel:read:subscriptions,
##    moderator:read:followers, channel:read:redemptions).
##  - BOTH tokens (broadcaster user://twitch_token.json, bot user://twitch_bot_token.json)
##    refreshed on a timer well before they run out (~4 h), validated every hour, and
##    refreshed at once on any 401. Refresh tokens of a public client are single use:
##    the new pair is written to a .tmp file and renamed over the old one.
##  - Bellmire's OWN channel point rewards, made with Bellmire's client id; redemptions
##    are matched BY REWARD ID only. fightoverlay's rewards are never touched.
##  - bits / subs / points -> town.spotlight(uid, lane, seconds, reason); follows -> a
##    Chronicle line only.
##  - chat replies: ChatCmd's  signal twitch_reply(user_login, text)  (laptop side) ->
##    queue, rate limit, "@name " prefix, Send Chat Message as bellmirebro.
## Settings: res://local/twitch.cfg then user://twitch.cfg, section [twitch]
## (client_id, broadcaster_user_id, bot_user_id, eventsub = false turns this off).

signal spotlight_wanted(uid: String, lane: String, seconds: float, reason: String)
signal log_line(text: String)

const WS_URL := "wss://eventsub.wss.twitch.tv/ws"
const HELIX := "https://api.twitch.tv/helix"
const TOKEN_URL := "https://id.twitch.tv/oauth2/token"
const VALIDATE_URL := "https://id.twitch.tv/oauth2/validate"
const TOKEN_FILE := "user://twitch_token.json"
const BOT_TOKEN_FILE := "user://twitch_bot_token.json"
const REWARD_FILE := "user://twitch_rewards.json"
const CFGS := ["res://local/twitch.cfg", "user://twitch.cfg"]

const REFRESH_EARLY := 900.0        # refresh 15 min before expiry
const VALIDATE_EVERY := 3600.0      # Twitch asks apps to validate hourly
const CHAT_GAP := 1.6               # s between bot messages (mod limit is 100 / 30 s)
const CHAT_QUEUE_MAX := 15
const CHAT_MAX_LEN := 480
const SEEN_MAX := 300
const CHAT_STALE := 90.0            # D70.3: s a queued line may wait before it is too old to say
const VIEWERS_FILE := "user://d70_viewers.json"   # D70: who was welcomed, uid -> Twitch login
const ALWAYS_TOLD := ["fell", "lord", "rare"]   # D70.2: rare by nature, never spaced out by a burst of learns
const MOMENT_GAP := 45.0            # D70.2: s between two non-death moments for one viewer

## words fightoverlay acts on - no Bellmire reward title may contain one
const FORBIDDEN := ["boss", "monster", "spawn", "raid", "mob", "goblin", "horde", "loot",
        "drop", "chest", "treasure", "invade", "titan"]
## Bellmire's rewards: key -> settings. The key is ours; Twitch gives the id.
const REWARDS := {
    "spotlight": {"title": "Spotlight my hero", "cost": 500, "action": "spotlight",
        "prompt": "The eye of Bellmire turns to your hero for a while. Raise one first with !enlist.",
        "background_color": "#2AA198", "lane": "points", "seconds": 15.0},
    "delve": {"title": "Send my hero delving", "cost": 400, "action": "delve",
        "prompt": "Your hero sets out for the scar with the next party. Raise one first with !enlist.",
        "background_color": "#B5462E"},
    "fish": {"title": "Send my hero fishing", "cost": 150, "action": "fish",
        "prompt": "Your hero heads to the docks to fish. Raise one first with !enlist.",
        "background_color": "#2E7DB5"},
    "join": {"title": "Join the delve", "cost": 300, "action": "join",
        "prompt": "Your hero joins the party forming at the scar mouth. Raise one first with !enlist.",
        "background_color": "#B58E2E"},
    "patch": {"title": "Patch up my hero", "cost": 250, "action": "patch",
        "prompt": "Your hero is handed a healing potion for the next delve. Raise one first with !enlist.",
        "background_color": "#4BB54B"},
    "rally": {"title": "Rally my hero", "cost": 600, "action": "rally",
        "prompt": "Your hero is rallied - stronger, swifter, fearless, and mending - for their next delve. Raise one first with !enlist.",
        "background_color": "#9B59B6", "lane": "points", "seconds": 15.0},
    # T5: the viewer's roll - a d20 for the town, resolved in the game (see viewer_roll)
    "roll": {"title": "Roll for Bellmire", "cost": 750, "action": "roll",
        "prompt": "A d20 for the town. Type build, festival, or a law by name - anything else and fate picks. 20 is a triumph; 1 backfires.",
        "background_color": "#C9A227", "user_input": true},
}

var town: Node                       # spotlight(uid, lane, seconds, reason), feed, roster, chat
var enabled := true
var offline := false                 # tests: no sockets, no HTTP
var dry_run_chat := false            # tests: chat goes to sent_chat, not Twitch
var client_id := ""
var broadcaster_id := "138821183"
var bot_id := "1609188025"

var tokens := {"broadcaster": {}, "bot": {}}
var expires_at := {"broadcaster": 0.0, "bot": 0.0}     # unix seconds
var _refreshing := {"broadcaster": false, "bot": false}
var _token_dead := {"broadcaster": false, "bot": false}
var _validate_t := VALIDATE_EVERY
var reward_ids := {}                 # key -> Twitch reward id (ours)
var rewards_ok := false
var rewards_note := ""
var rewards_resync := false          # cfg [twitch] rewards_resync: force (re)adopt/create missing rewards this run

var _ws := WebSocketPeer.new()
var _ws_next: WebSocketPeer = null   # session_reconnect: the new socket until it says welcome
var _was_open := false
var _opened := false                 # the socket is only polled once _start has opened it
var _retry_in := -1.0
var _backoff := 2.0
var session_id := ""
var _keepalive := 30.0
var _quiet := 0.0
var _seen: Array = []
var subs_ok: Array = []
var subs_failed: Array = []

var _chat_q: Array = []              # [login, text]
var _chat_t := 0.0
var _chat_recent := {}               # message -> unix time sent (Twitch drops repeats)
var sent_chat: Array = []            # what was (or in dry run, would be) posted
var spotlights: Array = []           # [uid, lane, seconds, reason] - for tests and the log
var refreshes := {"broadcaster": 0, "bot": 0}

func setup(t: Node) -> void:
    town = t
    process_mode = Node.PROCESS_MODE_ALWAYS     # sockets keep alive while the game is paused
    _load_cfg()
    if town and town.get("chat") != null:
        var c: Object = town.get("chat")
        if c.has_signal("twitch_reply") and not c.is_connected("twitch_reply", _on_twitch_reply):
            c.connect("twitch_reply", _on_twitch_reply)
        if "bits_tier_fn" in c:
            c.set("bits_tier_fn", Callable(self, "_do_bits_tier"))
    if OS.get_cmdline_args().has("--script"):
        viewers_path = "user://d70_viewers_test.json"   # harnesses never touch the real list
    _viewers_load()
    if town and town.get("roster") != null:
        var ro: Object = town.get("roster")
        if ro.has_signal("hero_moment") and not ro.is_connected("hero_moment", on_hero_moment):
            ro.connect("hero_moment", on_hero_moment)
    if not enabled or offline:
        return
    if client_id == "":
        _say_log("TWITCH_EVENTSUB off: no client_id in local/twitch.cfg or user://twitch.cfg")
        enabled = false
        return
    if not _load_token("broadcaster"):
        _say_log("TWITCH_EVENTSUB off: no broadcaster token in " + TOKEN_FILE)
        enabled = false
        return
    _load_token("bot")
    _load_rewards()
    _start()

func _start() -> void:
    await _validate("broadcaster")
    if tokens["bot"].size() > 0:
        await _validate("bot")
    if _token_dead["broadcaster"]:
        return
    await ensure_rewards()
    _open()
    # L35: seed the subscriber pane with real channel subs
    _fetch_subs()

func _load_cfg() -> void:
    for path in CFGS:
        var c := ConfigFile.new()
        if FileAccess.file_exists(path) and c.load(path) == OK:
            client_id = String(c.get_value("twitch", "client_id", client_id))
            broadcaster_id = String(c.get_value("twitch", "broadcaster_user_id", broadcaster_id))
            bot_id = String(c.get_value("twitch", "bot_user_id", bot_id))
            if not bool(c.get_value("twitch", "enabled", true)):
                enabled = false
            if not bool(c.get_value("twitch", "eventsub", true)):
                enabled = false
            if bool(c.get_value("twitch", "rewards_resync", false)):
                rewards_resync = true

func _say_log(s: String) -> void:
    print(s)
    log_line.emit(s)

func _feed_line(s: String) -> void:
    if town and town.get("feed") != null:
        (town.get("feed") as Array).append(s)
    print("FEED ", s)

# ---------------------------------------------------------------- tokens

func _token_path(who: String) -> String:
    return TOKEN_FILE if who == "broadcaster" else BOT_TOKEN_FILE

func _load_token(who: String) -> bool:
    var path := _token_path(who)
    if not FileAccess.file_exists(path):
        return false
    var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if typeof(j) != TYPE_DICTIONARY or String(j.get("access_token", "")) == "":
        return false
    tokens[who] = j
    # obtained_at is ours; older files only have the file's own time
    var got := float(j.get("obtained_at", FileAccess.get_modified_time(path)))
    expires_at[who] = got + float(j.get("expires_in", 0))
    return true

func _save_token(who: String, j: Dictionary) -> bool:
    var path := _token_path(who)
    var tmp := path + ".tmp"
    var f := FileAccess.open(tmp, FileAccess.WRITE)
    if f == null:
        _say_log("TWITCH_EVENTSUB could not write " + tmp)
        return false
    f.store_string(JSON.stringify(j, "  "))
    f.close()
    # read it back before it replaces the only good copy
    var back: Variant = JSON.parse_string(FileAccess.get_file_as_string(tmp))
    if typeof(back) != TYPE_DICTIONARY or String(back.get("refresh_token", "")) != String(j.get("refresh_token", "")):
        _say_log("TWITCH_EVENTSUB token file did not read back - kept the old one")
        return false
    var d := DirAccess.open("user://")
    var err := d.rename(tmp.get_file(), path.get_file())
    if err != OK:
        _say_log("TWITCH_EVENTSUB rename failed (%d)" % err)
        return false
    return true

func seconds_left(who: String) -> float:
    return expires_at[who] - Time.get_unix_time_from_system()

## test hook: pretend the token runs out now; the timer refreshes it next frame
func force_expiry(who: String) -> void:
    expires_at[who] = Time.get_unix_time_from_system() - 1.0

func refresh(who: String) -> bool:
    if _refreshing[who] or tokens[who].is_empty() or offline:
        return false
    _refreshing[who] = true
    var body := "client_id=%s&grant_type=refresh_token&refresh_token=%s" % [
            client_id.uri_encode(), String(tokens[who].get("refresh_token", "")).uri_encode()]
    var r := await _http(HTTPClient.METHOD_POST, TOKEN_URL,
            ["Content-Type: application/x-www-form-urlencoded"], body)
    _refreshing[who] = false
    var j: Variant = r["json"]
    if int(r["code"]) == 200 and typeof(j) == TYPE_DICTIONARY and String(j.get("access_token", "")) != "":
        var nt: Dictionary = j
        if String(nt.get("refresh_token", "")) == "":
            nt["refresh_token"] = tokens[who].get("refresh_token", "")
        nt["obtained_at"] = int(Time.get_unix_time_from_system())
        if not _save_token(who, nt):
            # keep using the new pair in memory: the old refresh token is spent
            _say_log("TWITCH_EVENTSUB %s token refreshed but NOT saved" % who)
        tokens[who] = nt
        expires_at[who] = float(nt["obtained_at"]) + float(nt.get("expires_in", 0))
        refreshes[who] += 1
        _say_log("TWITCH_EVENTSUB %s token refreshed, %.0f min left" % [who, seconds_left(who) / 60.0])
        return true
    if int(r["code"]) == 400 or int(r["code"]) == 401:
        _token_dead[who] = true
        _say_log("TWITCH_EVENTSUB %s token can not be refreshed (%d) - re-authorize it" % [who, int(r["code"])])
    else:
        expires_at[who] = Time.get_unix_time_from_system() + REFRESH_EARLY - 60.0   # try again in a minute
        _say_log("TWITCH_EVENTSUB %s refresh failed (%d), retry in 60 s" % [who, int(r["code"])])
    return false

func _validate(who: String) -> void:
    if tokens[who].is_empty() or offline:
        return
    var r := await _http(HTTPClient.METHOD_GET, VALIDATE_URL,
            ["Authorization: OAuth " + String(tokens[who]["access_token"])], "")
    if int(r["code"]) == 200 and typeof(r["json"]) == TYPE_DICTIONARY:
        expires_at[who] = Time.get_unix_time_from_system() + float(r["json"].get("expires_in", 0))
        _say_log("TWITCH_EVENTSUB %s token valid (%s), %.0f min left" % [who, String(r["json"].get("login", "?")), seconds_left(who) / 60.0])
    elif int(r["code"]) == 401:
        _say_log("TWITCH_EVENTSUB %s token invalid - refreshing" % who)
        await refresh(who)

func _tick_tokens(delta: float) -> void:
    for who in ["broadcaster", "bot"]:
        if tokens[who].is_empty() or _token_dead[who] or _refreshing[who]:
            continue
        if seconds_left(who) < REFRESH_EARLY:
            refresh(who)
    _validate_t -= delta
    if _validate_t <= 0.0:
        _validate_t = VALIDATE_EVERY
        _validate("broadcaster")
        _validate("bot")

# ---------------------------------------------------------------- HTTP

## one request -> {code, json}. A 401 on a Helix call refreshes that token and retries once.
func _http(method: int, url: String, headers: Array, body: String) -> Dictionary:
    var h := HTTPRequest.new()
    h.timeout = 15.0
    add_child(h)
    var err := h.request(url, PackedStringArray(headers), method, body)
    if err != OK:
        h.queue_free()
        return {"code": 0, "json": null}
    var res: Array = await h.request_completed
    h.queue_free()
    var txt := (res[3] as PackedByteArray).get_string_from_utf8()
    return {"code": int(res[1]), "json": JSON.parse_string(txt) if txt != "" else null}

func _helix(who: String, method: int, path: String, body: Variant = null) -> Dictionary:
    for attempt in 2:
        var hd := ["Client-Id: " + client_id,
                "Authorization: Bearer " + String(tokens[who].get("access_token", ""))]
        var b := ""
        if body != null:
            hd.append("Content-Type: application/json")
            b = JSON.stringify(body)
        var r := await _http(method, HELIX + path, hd, b)
        # a 401 for a missing scope is not an old token - refreshing will not help
        if int(r["code"]) == 401 and attempt == 0 and not _token_dead[who] and _err_text(r).find("scope") < 0:
            if await refresh(who):
                continue
        return r
    return {"code": 0, "json": null}

# ---------------------------------------------------------------- rewards

func _load_rewards() -> void:
    if FileAccess.file_exists(REWARD_FILE):
        var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(REWARD_FILE))
        if typeof(j) == TYPE_DICTIONARY:
            reward_ids = j

func _save_rewards() -> void:
    var f := FileAccess.open(REWARD_FILE, FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify(reward_ids, "  "))

static func title_ok(title: String) -> bool:
    var t := title.to_lower()
    for w in FORBIDDEN:
        if t.find(w) >= 0:
            return false
    return true

## EDIT-PROOF reward handling. Bellmire's own rewards are matched BY STORED ID, so Mr. E
## can freely edit a reward's title, cost, colour, icon or prompt on Twitch and the game
## stays connected to it (the id never changes). What the game will NOT do is resurrect a
## reward he removed: once we hold saved ids, a reward whose id has vanished is left OFF
## (not recreated as a duplicate). The game only CREATES or re-ADOPTS rewards when it is
## bootstrapping - the first run with no saved ids file, or an explicit resync
## ([twitch] rewards_resync=true in local/twitch.cfg or user://twitch.cfg). On a resync it
## adopts an existing reward by exact title before making a new one, so it never dupes.
func ensure_rewards() -> void:
    if offline:
        return
    var r := await _helix("broadcaster", HTTPClient.METHOD_GET,
            "/channel_points/custom_rewards?broadcaster_id=%s&only_manageable_rewards=true" % broadcaster_id)
    if int(r["code"]) != 200:
        rewards_ok = false
        rewards_note = _err_text(r)
        _say_log("TWITCH_EVENTSUB rewards unavailable (%d %s). Spotlight-by-points is off; bits, subs and follows still work. The broadcaster token needs channel:manage:redemptions." % [int(r["code"]), rewards_note])
        return
    var mine := {}                  # id -> title (our client's current rewards on the channel)
    for rw in (r["json"] as Dictionary).get("data", []):
        mine[String(rw["id"])] = String(rw["title"])
    # bootstrap = we may adopt/create missing rewards this run; otherwise we touch nothing
    # the broadcaster has changed. First ever run (no file) or an explicit resync bootstraps.
    var bootstrap := reward_ids.is_empty() or rewards_resync
    for key in REWARDS:
        var want: Dictionary = REWARDS[key]
        # a stored id that is still on the channel -> keep it as-is, whatever its title/cost/
        # colour are now. This is what makes editing a reward on Twitch safe.
        if reward_ids.has(key) and mine.has(String(reward_ids[key])):
            continue
        var had_saved := reward_ids.has(key)
        reward_ids.erase(key)
        # steady state (not bootstrapping): a reward we knew is gone -> the broadcaster deleted
        # it on purpose. Leave it off; do NOT recreate a ghost duplicate.
        if had_saved and not bootstrap:
            _say_log("TWITCH_EVENTSUB reward '%s' is no longer on the channel - its redemptions are off. Set [twitch] rewards_resync=true to remake it." % want["title"])
            continue
        # bootstrap/resync: adopt an existing reward by exact title (recovers a lost ids file
        # without duplicating), else fall through and make it.
        for id in mine:
            if mine[id] == String(want["title"]):
                reward_ids[key] = id
        if reward_ids.has(key):
            continue
        # no saved id and not bootstrapping -> never spawn a reward on our own
        if not bootstrap:
            continue
        if not title_ok(String(want["title"])):
            _say_log("TWITCH_EVENTSUB reward title %s uses a fightoverlay word - not made" % want["title"])
            continue
        var c := await _helix("broadcaster", HTTPClient.METHOD_POST,
                "/channel_points/custom_rewards?broadcaster_id=%s" % broadcaster_id,
                {"title": want["title"], "cost": want["cost"], "prompt": want["prompt"],
                 "background_color": want["background_color"], "is_enabled": true,
                 "is_user_input_required": bool(want.get("user_input", false))})
        if int(c["code"]) == 200:
            reward_ids[key] = String(c["json"]["data"][0]["id"])
            _say_log("TWITCH_EVENTSUB made reward %s (%s)" % [want["title"], reward_ids[key]])
        else:
            rewards_note = _err_text(c)
            _say_log("TWITCH_EVENTSUB could not make reward %s (%d %s)" % [want["title"], int(c["code"]), rewards_note])
    if rewards_resync:
        _say_log("TWITCH_EVENTSUB rewards resync done - set rewards_resync back to false to keep edits safe.")
    rewards_resync = false
    rewards_ok = not reward_ids.is_empty()
    _save_rewards()

func _err_text(r: Dictionary) -> String:
    if typeof(r["json"]) == TYPE_DICTIONARY:
        return String(r["json"].get("message", ""))
    return ""

func reward_key(reward_id: String) -> String:
    for key in reward_ids:
        if String(reward_ids[key]) == reward_id:
            return key
    return ""

func _settle(redemption_id: String, reward_id: String, ok: bool) -> void:
    if offline or redemption_id == "":
        return
    var r := await _helix("broadcaster", HTTPClient.METHOD_PATCH,
            "/channel_points/custom_rewards/redemptions?broadcaster_id=%s&reward_id=%s&id=%s" % [broadcaster_id, reward_id, redemption_id],
            {"status": "FULFILLED" if ok else "CANCELED"})
    if int(r["code"]) != 200:
        _say_log("TWITCH_EVENTSUB could not mark redemption (%d %s)" % [int(r["code"]), _err_text(r)])

# ---------------------------------------------------------------- the socket

func _open(url := WS_URL) -> void:
    _ws = WebSocketPeer.new()
    _ws.inbound_buffer_size = 1 << 18
    _opened = true
    _was_open = false
    session_id = ""
    _retry_in = -1.0
    if _ws.connect_to_url(url) != OK:
        _schedule_retry()

func _schedule_retry() -> void:
    _retry_in = _backoff
    _say_log("TWITCH_EVENTSUB reconnecting in %.0f s" % _backoff)
    _backoff = minf(_backoff * 2.0, 120.0)

func _process(delta: float) -> void:
    _tick_receipts(delta)
    if not enabled or offline:
        _tick_chat(delta)
        return
    _tick_tokens(delta)
    _tick_chat(delta)
    _tick_subs_refresh(delta)
    if _token_dead["broadcaster"] or not _opened:
        return
    if _ws_next:
        _ws_next.poll()
        while _ws_next and _ws_next.get_available_packet_count() > 0:
            on_message(_ws_next.get_packet().get_string_from_utf8(), true)
    if _retry_in >= 0.0:
        _retry_in -= delta
        if _retry_in < 0.0:
            _open()
        return
    _ws.poll()
    match _ws.get_ready_state():
        WebSocketPeer.STATE_OPEN:
            _was_open = true
            while _ws.get_available_packet_count() > 0:
                on_message(_ws.get_packet().get_string_from_utf8())
            _quiet += delta
            if session_id != "" and _quiet > _keepalive + 10.0:
                _say_log("TWITCH_EVENTSUB no keepalive for %.0f s - reconnecting" % _quiet)
                _ws.close()
        WebSocketPeer.STATE_CLOSED:
            if session_id != "" or _was_open:
                _say_log("TWITCH_EVENTSUB closed (%d %s)" % [_ws.get_close_code(), _ws.get_close_reason()])
            session_id = ""
            _schedule_retry()

## one socket message. Public so the test tool can drive it with recorded frames.
func on_message(text: String, from_next := false) -> void:
    var j: Variant = JSON.parse_string(text)
    if typeof(j) != TYPE_DICTIONARY:
        return
    var meta: Dictionary = j.get("metadata", {})
    var pay: Dictionary = j.get("payload", {})
    var mid := String(meta.get("message_id", ""))
    if mid != "":
        if _seen.has(mid):
            return                       # Twitch may send a message twice
        _seen.append(mid)
        if _seen.size() > SEEN_MAX:
            _seen.pop_front()
    _quiet = 0.0
    match String(meta.get("message_type", "")):
        "session_welcome":
            var s: Dictionary = pay.get("session", {})
            _keepalive = float(s.get("keepalive_timeout_seconds", 30))
            _backoff = 2.0
            if from_next:
                # the reconnect socket took over; subscriptions came with it
                _ws.close()
                _ws = _ws_next
                _ws_next = null
                session_id = String(s.get("id", ""))
                _say_log("TWITCH_EVENTSUB moved to the new session")
            else:
                session_id = String(s.get("id", ""))
                _say_log("TWITCH_EVENTSUB welcome, session %s, keepalive %.0f s" % [session_id.left(8), _keepalive])
                if not offline:
                    subscribe_all()
        "session_keepalive":
            pass
        "session_reconnect":
            var url := String(pay.get("session", {}).get("reconnect_url", ""))
            if url != "" and not offline:
                _ws_next = WebSocketPeer.new()
                _ws_next.inbound_buffer_size = 1 << 18
                _ws_next.connect_to_url(url)
        "revocation":
            var sub: Dictionary = pay.get("subscription", {})
            _say_log("TWITCH_EVENTSUB revoked %s (%s)" % [sub.get("type", "?"), sub.get("status", "?")])
            if String(sub.get("status", "")) == "authorization_revoked":
                _token_dead["broadcaster"] = true
        "notification":
            handle_event(String(pay.get("subscription", {}).get("type", "")), pay.get("event", {}))

func _sub_list() -> Array:
    var b := {"broadcaster_user_id": broadcaster_id}
    return [
        ["channel.cheer", "1", b],
        ["channel.subscribe", "1", b],
        ["channel.subscription.message", "1", b],
        ["channel.subscription.gift", "1", b],
        ["channel.follow", "2", {"broadcaster_user_id": broadcaster_id, "moderator_user_id": broadcaster_id}],
        ["channel.channel_points_custom_reward_redemption.add", "1", b],
        # Custom Power-ups (bit-cost rewards): fire the town-wide tier for the bits spent.
        # v1, needs bits:read (already held). Payload: event.custom_power_up.{id,title,bits}.
        ["channel.custom_power_up_redemption.add", "1", b],
    ]

func subscribe_all() -> void:
    subs_ok.clear()
    subs_failed.clear()
    var sid := session_id
    for s in _sub_list():
        if session_id != sid:
            return                       # the socket went away mid-way; the new welcome redoes it
        var r := await _helix("broadcaster", HTTPClient.METHOD_POST, "/eventsub/subscriptions",
                {"type": s[0], "version": s[1], "condition": s[2],
                 "transport": {"method": "websocket", "session_id": sid}})
        if int(r["code"]) == 202 or int(r["code"]) == 409:
            subs_ok.append(s[0])
        else:
            subs_failed.append("%s %d %s" % [s[0], int(r["code"]), _err_text(r)])
    _say_log("TWITCH_EVENTSUB subscribed %d of %d%s" % [subs_ok.size(), _sub_list().size(),
            "" if subs_failed.is_empty() else " - failed: " + ", ".join(subs_failed)])

# ---------------------------------------------------------------- channel subscribers
## L35: fetch the real subscriber list from the Helix API so the subs pane has
## bodies to cycle through even before anyone subs this session.
var _subs_refresh_t := 0.0
const SUBS_REFRESH := 600.0      # re-fetch every 10 min

func _fetch_subs() -> void:
    if offline or _token_dead["broadcaster"]:
        return
    var all_uids: Array = []
    var cursor := ""
    for page in 5:     # cap at 5 pages (~500 subs max)
        var url := "/subscriptions?broadcaster_id=%s&first=100" % broadcaster_id
        if cursor != "":
            url += "&after=" + cursor
        var r := await _helix("broadcaster", HTTPClient.METHOD_GET, url)
        if int(r["code"]) != 200:
            _say_log("TWITCH_EVENTSUB sub list unavailable (%d)" % int(r["code"]))
            break
        var j: Dictionary = r["json"] if typeof(r["json"]) == TYPE_DICTIONARY else {}
        var data: Array = j.get("data", []) if typeof(j.get("data")) == TYPE_ARRAY else []
        for s in data:
            var uid := String((s as Dictionary).get("user_id", ""))
            if uid != "" and uid != broadcaster_id:
                all_uids.append(uid)
        var pag: Dictionary = j.get("pagination", {}) if typeof(j.get("pagination")) == TYPE_DICTIONARY else {}
        cursor = String(pag.get("cursor", ""))
        if cursor == "" or data.size() < 100:
            break
    if all_uids.is_empty():
        _say_log("TWITCH_EVENTSUB no channel subs found (or affiliate not reached)")
        return
    _say_log("TWITCH_EVENTSUB seeded subs pane with %d subscriber(s)" % all_uids.size())
    # feed into Spotlight._subs_seen (oldest first so newest is at front)
    if town:
        var spot := Spotlight.of(town)
        if spot:
            for uid in all_uids:
                spot._subs_note(uid)
    _subs_refresh_t = SUBS_REFRESH

func _tick_subs_refresh(delta: float) -> void:
    _subs_refresh_t -= delta
    if _subs_refresh_t <= 0.0:
        _subs_refresh_t = SUBS_REFRESH
        _fetch_subs()

# ---------------------------------------------------------------- events -> the town

static func bits_seconds(bits: int) -> float:
    if bits >= 100:
        return 30.0
    if bits >= 50:
        return 20.0
    return 15.0

func handle_event(kind: String, e: Dictionary) -> void:
    var uid := String(e.get("user_id", "")) if e.get("user_id") != null else ""
    var who := String(e.get("user_name", "")) if e.get("user_name") != null else ""
    var login := String(e.get("user_login", "")) if e.get("user_login") != null else ""
    match kind:
        "channel.cheer":
            var bits := int(e.get("bits", 0))
            if bool(e.get("is_anonymous", false)) or uid == "":
                _feed_line("A stranger tosses %d bits into Bellmire's well." % bits)
                _do_bits_tier("", bits)
                return
            _feed_line("%s cheers %d bits for Bellmire!" % [who, bits])
            _spot(uid, "bits", bits_seconds(bits), "cheered %d bits" % bits)
            _do_bits_tier(uid, bits, who)
        "channel.custom_power_up_redemption.add":
            # a bought Power-up: its bit cost drives the same town-wide tier as a cheer
            var pu: Dictionary = e.get("custom_power_up", {}) if typeof(e.get("custom_power_up")) == TYPE_DICTIONARY else {}
            var pbits := int(pu.get("bits", 0))
            var ptitle := String(pu.get("title", "a Power-up"))
            if uid == "":
                _feed_line("A stranger spends %d bits on %s for Bellmire." % [pbits, ptitle])
                _do_bits_tier("", pbits)
                return
            _feed_line("%s redeems %s (%d bits) for Bellmire!" % [who, ptitle, pbits])
            _spot(uid, "bits", bits_seconds(pbits), "redeemed %s" % ptitle)
            _do_bits_tier(uid, pbits, who)
        "channel.subscribe":
            if bool(e.get("is_gift", false)):
                _feed_line("%s is gifted a place in the guild." % who)    # the gifter has the pane
                return
            _feed_line("%s joins the guild of Bellmire!" % who)
            _spot(uid, "subs", 30.0, "subscribed")
        "channel.subscription.message":
            var months := int(e.get("cumulative_months", 0))
            _feed_line("%s renews their oath to Bellmire - %d months." % [who, months])
            _spot(uid, "subs", 30.0, "resubscribed - %d months" % months)
        "channel.subscription.gift":
            var n := int(e.get("total", 1))
            if bool(e.get("is_anonymous", false)) or uid == "":
                _feed_line("A hooded stranger gifts %d guild places." % n)
                return
            _feed_line("%s gifts %d guild place%s!" % [who, n, "" if n == 1 else "s"])
            _spot(uid, "subs", 30.0, "gifted %d sub%s" % [n, "" if n == 1 else "s"])
        "channel.follow":
            _feed_line("%s now follows the banner of Bellmire." % who)
        "channel.channel_points_custom_reward_redemption.add":
            var rw: Dictionary = e.get("reward", {})
            var rid := String(rw.get("id", ""))
            var key := reward_key(rid)
            if key == "":
                return                   # not ours (fightoverlay's or any other) - leave it alone
            var want: Dictionary = REWARDS[key]
            if String(want.get("action", "")) == "roll":
                # T5: a roll is for the TOWN - no hero needed to cast it
                viewer_roll(uid, who, String(e.get("user_input", "")) if e.get("user_input") != null else "",
                        0, "%d points" % int(rw.get("cost", want["cost"])))
                _settle(String(e.get("id", "")), rid, true)
                return
            if not _has_hero(uid):
                _feed_line("%s calls for the spotlight, but has no hero yet - !enlist first. Points returned." % who)
                if login != "":
                    _on_twitch_reply(login, "you need a hero first - type !enlist. Your points were returned.")
                _settle(String(e.get("id", "")), rid, false)
                return
            # S125 (supervisor 23:54 directive §3): the receipt is written BEFORE the settle,
            # marked settled after it, and checked against the hero's real state later
            var rc := _receipt_open(uid, login, String(want.get("action", "spotlight")),
                    String(e.get("id", "")), rid)
            _do_reward(uid, want, String(rw.get("title", want["title"])))
            _settle_receipt(rc, String(e.get("id", "")), rid)

## Mr. E: a redeemed reward -> the right action. Every one also spotlights the
## hero so viewers watch what they paid for (the points pane then rests on them).
func _do_reward(uid: String, want: Dictionary, title: String) -> void:
    match String(want.get("action", "spotlight")):
        "delve":
            if town and town.has_method("_on_delve"):
                town.call("_on_delve", uid)
            _spot(uid, "points", 15.0, "sent their hero delving")
        "join":
            if town and town.has_method("_on_delve"):
                town.call("_on_delve", uid)
            _spot(uid, "points", 15.0, "joined the delve party")
        "fish":
            if town and town.has_method("_on_fish"):
                town.call("_on_fish", uid)
            _spot(uid, "points", 15.0, "sent their hero fishing")
        "patch":
            var r = town.get("roster") if town else null
            if r and r.has_method("get_hero"):
                var h: Dictionary = r.call("get_hero", uid)
                if not h.is_empty():
                    h["potions"] = int(h.get("potions", 0)) + 1
            _spot(uid, "points", 10.0, "is handed a healing potion")
        "rally":
            if town and town.has_method("_on_rally"):
                town.call("_on_rally", uid)
            _spot(uid, "points", 15.0, "rallies their hero for the next delve")
        _:
            _spot(uid, String(want.get("lane", "points")), float(want.get("seconds", 15.0)), "redeemed " + title)

func _has_hero(uid: String) -> bool:
    if town == null or town.get("roster") == null:
        return true
    var r: Object = town.get("roster")
    return r.has_method("get_hero") and not (r.call("get_hero", uid) as Dictionary).is_empty()

# ---------------------------------------------------------------- S125 the receipt ledger
## Supervisor directive 23:54 CT 24 Nov §3 (Mr. E's authority): a viewer who paid must get
## what they paid for. Every redeemed hero reward writes a receipt BEFORE the settle, is marked
## settled after it, and RECEIPT_CHECK_S later the hero's real state is compared with what the
## action should have left. A match -> verified and pruned. A miss -> the action is retried
## ONCE. A second miss -> the viewer is told in chat and the failure is logged for Mr. E.
## In memory only, one session. IT NEVER REFUNDS: a refund is a different Helix call that a
## human (or a later feature) makes from the logged redemption_id.
const RECEIPT_CHECK_S := 8.0         # inside the directive's 5-10 s window
const RECEIPT_FAILED_MAX := 50
const RECEIPT_WORDS := {"delve": "delve", "join": "place in the delve party", "fish": "fishing trip",
        "patch": "healing potion", "rally": "rally", "spotlight": "spotlight"}
var _receipts: Array = []            # open receipts, pruned once verified or failed
var receipts_verified := 0
var receipts_retried := 0
var receipts_failed: Array = []      # the failures, kept for Mr. E's log (capped)
var _rc_clock := 0.0

func _receipt_open(uid: String, login: String, action: String, redemption_id: String, reward_id: String) -> Dictionary:
    var expected := {"kind": action}
    if action == "patch":
        expected["potions"] = _hero_potions(uid) + 1
    var rc := {"uid": uid, "login": login, "action": action, "timestamp": Time.get_unix_time_from_system(),
            "expected_state": expected, "redemption_id": redemption_id, "reward_id": reward_id,
            "settled": false, "verified": false, "retries": 0, "due": _rc_clock + RECEIPT_CHECK_S}
    _receipts.append(rc)
    return rc

func _settle_receipt(rc: Dictionary, redemption_id: String, reward_id: String) -> void:
    await _settle(redemption_id, reward_id, true)
    rc["settled"] = true

func _hero_potions(uid: String) -> int:
    var r = town.get("roster") if town else null
    if r == null or not r.has_method("get_hero"):
        return 0
    return int((r.call("get_hero", uid) as Dictionary).get("potions", 0))

## does the hero's real state show the action happened? Read off the town, never off the receipt.
func receipt_met(rc: Dictionary) -> bool:
    var uid := String(rc["uid"])
    var ex: Dictionary = rc["expected_state"]
    if town == null:
        return false
    match String(ex.get("kind", "")):
        "patch":
            return _hero_potions(uid) >= int(ex.get("potions", 1))
        "delve", "join":
            var c = town.get("chat")
            if c != null:
                var away = c.get("away")
                var q = c.get("delve_queue")
                if (away is Dictionary and away.has(uid)) or (q is Array and q.has(uid)):
                    return true
            var mouth = town.get("_at_mouth")
            if mouth is Array and mouth.has(uid):
                return true
            return town.get("delve") != null      # the party already went below with them
        "fish":
            var hs = town.get("heroes")
            if not (hs is Dictionary) or not hs.has(uid):
                return false
            var b: Node = hs[uid]
            if String(b.get("errand")) == "fish":
                return true
            for ch in b.get_children():
                if ch is Angler:
                    return true
            return false
        "rally":
            var r = town.get("roster")
            if r != null and r.has_method("get_hero"):
                if float((r.call("get_hero", uid) as Dictionary).get("rally_secs", 0.0)) > 0.0:
                    return true
            return town.get("delve") != null      # a live delve takes the rally on the combatant (apply_rally)
        _:
            for s in spotlights:
                if String(s[0]) == uid:
                    return true
            return false

func _receipt_retry(rc: Dictionary) -> void:
    var action := String(rc["action"])
    for key in REWARDS:
        if String(REWARDS[key].get("action", "")) == action:
            _do_reward(String(rc["uid"]), REWARDS[key], String(REWARDS[key]["title"]))
            return

func _tick_receipts(delta: float) -> void:
    _rc_clock += delta
    if _receipts.is_empty():
        return
    var keep: Array = []
    for rc in _receipts:
        if _rc_clock < float(rc["due"]):
            keep.append(rc)
            continue
        if receipt_met(rc):
            rc["verified"] = true
            receipts_verified += 1
            continue
        if int(rc["retries"]) == 0:
            rc["retries"] = 1
            receipts_retried += 1
            _say_log("TWITCH_EVENTSUB RECEIPT RETRY %s for %s (redemption %s): state did not match %s" % [
                    rc["action"], rc["uid"], rc["redemption_id"], JSON.stringify(rc["expected_state"])])
            _receipt_retry(rc)
            rc["due"] = _rc_clock + RECEIPT_CHECK_S
            keep.append(rc)
            continue
        rc["failed"] = true
        receipts_failed.append(rc)
        if receipts_failed.size() > RECEIPT_FAILED_MAX:
            receipts_failed.pop_front()
        _say_log("TWITCH_EVENTSUB RECEIPT FAILED %s for %s (redemption %s, reward %s, settled %s): retry did not take - NOT refunded" % [
                rc["action"], rc["uid"], rc["redemption_id"], rc["reward_id"], str(rc["settled"])])
        if String(rc["login"]) != "":
            _on_twitch_reply(String(rc["login"]), "your %s didn't go through - the builders have been told. Your points are safe." % String(RECEIPT_WORDS.get(rc["action"], rc["action"])))
    _receipts = keep

func _spot(uid: String, lane: String, seconds: float, reason: String) -> void:
    spotlights.append([uid, lane, seconds, reason])
    spotlight_wanted.emit(uid, lane, seconds, reason)
    if town and town.has_method("spotlight"):
        town.call("spotlight", uid, lane, seconds, reason)
    elif town:
        Spotlight.spotlight(town, uid, lane, seconds, reason)
    else:
        print("SPOTLIGHT %s %s %.0fs %s (no town)" % [uid, lane, seconds, reason])

# ---------------------------------------------------------------- T5 the viewer's roll
## Mr. E: "the heart of viewer interaction". A viewer spends points to attempt something for
## the town - raise a building, call a festival, push a law - and a d20 decides how it goes.
## The roll resolves HERE, in the game; the hub only DISPLAYS it (snapshot `rolls`, H9/H27).
## The words are the content writer's: lore_lines "propositions".entries (the laws, each with
## its good and bad consequence) and "e3po".viewer_roll crit/high/low/fumble (the Commander's
## verdict, published as part of the roll's `result`). The bands, readable without D&D:
##   20 a triumph (crit) . 13-19 it goes well (good) . 8-12 a mixed result (mixed)
##   2-7 it goes badly (bad) . 1 a fumble - it backfires (fumble)
const ROLL_MAX := 20
const ROLL_WORDS := {"crit": "a triumph", "good": "it goes well", "mixed": "a mixed result",
        "bad": "it goes badly", "fumble": "a fumble, and it backfires"}
const ROLL_VERDICT := {"crit": "crit", "good": "high", "mixed": "low", "bad": "low", "fumble": "fumble"}
var rolls: Array = []                # newest first: {n, by, what, result, tier, cost, at, kind}
var laws_passed: Array = []          # [title, tier] - what the town has voted in by the die
var _roll_lore := {}

static func roll_tier(face: int) -> String:
    if face >= 20:
        return "crit"
    if face >= 13:
        return "good"
    if face >= 8:
        return "mixed"
    if face >= 2:
        return "bad"
    return "fumble"

func _roll_lore_load() -> void:
    if not _roll_lore.is_empty():
        return
    _roll_lore = {"verdict": {}, "laws": []}
    var f := FileAccess.open("res://data/lore_lines.json", FileAccess.READ)
    if f == null:
        return
    var j = JSON.parse_string(f.get_as_text())
    if typeof(j) != TYPE_DICTIONARY:
        return
    var e3 = (j as Dictionary).get("e3po", {})
    if typeof(e3) == TYPE_DICTIONARY and typeof((e3 as Dictionary).get("viewer_roll")) == TYPE_DICTIONARY:
        _roll_lore["verdict"] = (e3 as Dictionary)["viewer_roll"]
    var pr = (j as Dictionary).get("propositions", {})
    if typeof(pr) == TYPE_DICTIONARY and typeof((pr as Dictionary).get("entries")) == TYPE_ARRAY:
        _roll_lore["laws"] = (pr as Dictionary)["entries"]

func _random_law() -> Dictionary:
    _roll_lore_load()
    var laws: Array = _roll_lore["laws"]
    if laws.is_empty():
        return {}
    return laws[randi() % laws.size()]

## what the viewer typed -> {kind: build|event|law, law: {...}}. A law named by its title wins;
## then a keyword; anything else (or nothing) and fate chooses.
func roll_intent(text: String) -> Dictionary:
    _roll_lore_load()
    var t := text.to_lower().strip_edges()
    if t != "":
        for law in (_roll_lore["laws"] as Array):
            var bare := String((law as Dictionary).get("title", "")).to_lower().trim_prefix("the ")
            if bare.length() >= 4 and t.contains(bare):
                return {"kind": "law", "law": law}
        for w in ["build", "raise", "upgrade", "smith", "forge", "shop"]:
            if t.contains(w):
                return {"kind": "build"}
        for w in ["festival", "feast", "fair", "event", "celebrat"]:
            if t.contains(w):
                return {"kind": "event"}
        for w in ["law", "decree", "proposition", "vote"]:
            if t.contains(w):
                return {"kind": "law", "law": _random_law()}
    var k := String(["build", "event", "law"][randi() % 3])
    return {"kind": "law", "law": _random_law()} if k == "law" else {"kind": k}

## one line from e3po.viewer_roll.<pool>
func _roll_verdict(tier: String) -> String:
    _roll_lore_load()
    var pool = (_roll_lore["verdict"] as Dictionary).get(String(ROLL_VERDICT.get(tier, "low")), [])
    if typeof(pool) != TYPE_ARRAY or (pool as Array).is_empty():
        return ""
    var entry = (pool as Array)[randi() % (pool as Array).size()]
    return String((entry as Dictionary).get("line", "")) if typeof(entry) == TYPE_DICTIONARY else String(entry)

## Resolve one viewer roll and apply it to the town. face 1-20 forces the die (tests); 0 rolls.
## Returns the published row. Every outcome CHANGES something - nothing is flavour only.
func viewer_roll(uid: String, who: String, text := "", face := 0, cost := "") -> Dictionary:
    var n := face if face >= 1 and face <= 20 else randi_range(1, 20)
    var tier := roll_tier(n)
    var intent := roll_intent(text)
    var nm := who.strip_edges() if who.strip_edges() != "" else "A viewer"
    var out := {}
    match String(intent["kind"]):
        "build":
            out = _roll_build(nm, tier)
        "event":
            out = _roll_event(nm, tier)
        _:
            out = _roll_law(nm, tier, intent.get("law", {}))
    var verdict := _roll_verdict(tier)
    _feed_line("%s rolls a %d to %s - %s. %s" % [nm, n, String(out["doing"]), String(ROLL_WORDS[tier]), String(out["line"])])
    if town and town.has_method("tag_feed"):
        town.call("tag_feed", "town", [nm])
    var nb = town.get("notables") if town else null
    if verdict != "" and nb and nb.has_method("e3po_line"):
        nb.call("e3po_line", verdict)            # shouted above the Commander and to the Chronicle
    var row := {"n": n, "by": nm, "what": String(out["what"]),
        "result": String(out["line"]) + ((" " + verdict) if verdict != "" else ""),
        "tier": tier, "cost": cost, "kind": String(intent["kind"]),
        "at": Time.get_datetime_string_from_system(true) + "Z"}
    rolls.push_front(row)
    if rolls.size() > ROLL_MAX:
        rolls.resize(ROLL_MAX)
    if town and "viewer_rolls" in town:
        town.set("viewer_rolls", rolls)
    if uid != "":
        _spot(uid, "points", 15.0, "rolled a %d for the town" % n)
    return row

func _eco() -> Economy:
    return town.get("economy") as Economy if town and town.get("economy") != null else null

func _treasury(eco: Economy, d: int) -> void:
    if eco:
        eco.treasury = maxi(0, eco.treasury + d)
        eco.changed.emit()

func _renown(eco: Economy, d: int) -> void:
    if eco:
        eco.renown = maxi(0, eco.renown + d)
        eco.changed.emit()

func _stock_cut(eco: Economy, g: String, frac: float) -> void:
    if eco:
        eco.stock[g] = maxf(0.0, float(eco.stock.get(g, 0.0)) * (1.0 - frac))

## BUILD: raise the smithy (D64a's raise_shop - the counter's ceiling, and the rack shows it)
func _roll_build(nm: String, tier: String) -> Dictionary:
    var eco := _eco()
    var o := {"what": "Raise the smithy", "doing": "raise the smithy"}
    match tier:
        "crit", "good", "mixed":
            var want := 2 if tier == "crit" else 1
            var got := eco.raise_shop("smithy", want, nm) if eco else 0
            if got == 0:
                _treasury(eco, 120)
                o["line"] = "The smithy is already the finest Bellmire can build, so the guild banks 120 gold instead."
            elif tier == "crit":
                o["line"] = "The smithy goes up %d level%s in a single day - rarer steel on the counter from now on." % [got, "" if got == 1 else "s"]
            elif tier == "good":
                o["line"] = "The smithy is raised a level, on time and square."
            else:
                _treasury(eco, -60)
                o["line"] = "The smithy goes up a level, but the builders run long and the treasury pays 60 gold more for it."
        "bad":
            _stock_cut(eco, "wood", 0.3)
            o["line"] = "The scaffold goes up crooked and has to come down again. The smithy stays as it was, and a third of the timber is wasted."
        _:
            _stock_cut(eco, "wood", 0.5)
            _treasury(eco, -40)
            o["line"] = "A forge spark catches the scaffold. Half the timber burns, and the town pays 40 gold to put it out."
    return o

## EVENT: call a festival (town.start_festival - the square is dressed and the stalls come out)
func _roll_event(nm: String, tier: String) -> Dictionary:
    var eco := _eco()
    var o := {"what": "Call a festival", "doing": "call a festival"}
    var raid := town != null and town.has_method("is_raid_on") and bool(town.call("is_raid_on"))
    match tier:
        "crit", "good":
            if town and town.has_method("start_festival"):
                town.call("start_festival", "gift", [], nm)
            if tier == "crit" and eco:
                _restock_full(eco)
            if raid:
                o["line"] = "The town agrees to a festival in their name - it starts the moment the raid is beaten."
            elif tier == "crit":
                o["line"] = "Bellmire throws a festival in their name, and the stores are filled to the brim for it."
            else:
                o["line"] = "Bellmire throws a festival in their name."
        "mixed":
            var ok := town != null and town.has_method("start_festival") and bool(town.call("start_festival", "market", [], ""))
            if ok:
                o["line"] = "A small market fair gets going - not the festival they wanted, but the square is busy."
            else:
                if eco:
                    eco.stock["food"] = float(eco.stock.get("food", 0.0)) + 20.0
                o["line"] = "The festival is called off, but the stalls sell what they brought - a little more food in the stores."
        "bad":
            _stock_cut(eco, "food", 0.2)
            o["line"] = "Nobody comes. The food laid out for the feast spoils in the sun."
        _:
            _treasury(eco, -60)
            _renown(eco, -1)
            o["line"] = "The feast turns into a brawl. The guard breaks it up and the town pays 60 gold in damages."
    return o

## LAW: push a proposition. Renown moves - and renown is half of the town's score, so a law can
## lift Bellmire a level or pull it back down.
func _roll_law(nm: String, tier: String, law: Dictionary) -> Dictionary:
    var eco := _eco()
    var title := String(law.get("title", "A new law"))
    var good := String(law.get("good", "The town is pleased."))
    var bad := String(law.get("bad", "The town grumbles."))
    var o := {"what": "Push " + title, "doing": "push " + title}
    match tier:
        "crit":
            _renown(eco, 2)
            _treasury(eco, 50)
            o["line"] = "%s passes by acclaim. %s" % [title, good]
        "good":
            _renown(eco, 1)
            o["line"] = "%s passes. %s" % [title, good]
        "mixed":
            o["line"] = "%s passes, and both sides of it come true. %s %s" % [title, good, bad]
        "bad":
            _renown(eco, -1)
            o["line"] = "%s passes, and it goes wrong. %s" % [title, bad]
        _:
            _renown(eco, -1)
            _treasury(eco, -40)
            o["line"] = "%s is shouted down, and the backlash comes anyway. %s" % [title, bad]
    if tier != "fumble":
        laws_passed.append([title, tier])
    return o

# ---------------------------------------------------------------- bit tiers
## Mr. E: cheered bits -> town-wide effects. Five tiers; the buyer's hero gets
## personal bonuses at tier 3+. Anonymous cheers still fire the town-wide part
## (uid == "" means no personal bonus). All tiers include the lower ones.

const BIT_TIERS := [
    {"min": 1,    "name": "Town Heal"},
    {"min": 50,   "name": "Blessed Supplies"},
    {"min": 150,  "name": "Fortune's Favour"},
    {"min": 500,  "name": "Festival of Plenty"},
    {"min": 1000, "name": "Summon the Host"},
]

## Which tier index (0-4) does this cheer land in?
static func bits_tier(bits: int) -> int:
    var t := 0
    for i in BIT_TIERS.size():
        if bits >= int(BIT_TIERS[i]["min"]):
            t = i
    return t

## D63.7: the name a paid festival is given - the viewer's display name (control chars
## stripped, capped at 25 like every W1a string), else their hero's, else nobody
static func _buyer_name(buyer: String, hero: String) -> String:
    var n := buyer if buyer != "" else hero
    var out := ""
    for ch in n:
        if ch.unicode_at(0) >= 32 and ch != "<" and ch != ">" and ch != "{" and ch != "}":
            out += ch
    return out.strip_edges().left(25)

func _do_bits_tier(uid: String, bits: int, buyer := "") -> void:
    if town == null:
        return
    var tier := bits_tier(bits)
    var r = town.get("roster") if town else null
    var eco = town.get("economy") if town else null
    var who := ""
    var h := {}
    if uid != "" and r and r.has_method("get_hero"):
        h = r.call("get_hero", uid) as Dictionary
        who = String(h.get("name", "")) if not h.is_empty() else ""

    # ---- Tier 0 (1-49): Town Heal
    if r and r.has_method("grant_all"):
        r.call("grant_all", 0, 1)
    if eco:
        _restock_half(eco)
    _feed_line("Bellmire's well glows - every hero is handed a Draught of Mending and the stores are restocked.")

    if tier < 1:
        return

    # ---- Tier 1 (50-149): Blessed Supplies
    if r and r.has_method("grant_all"):
        r.call("grant_all", 0, 3)    # +3 more (4 total with tier 0)
    if eco:
        _restock_full(eco)
    # +1 random brew to the buyer's hero
    if not h.is_empty() and r:
        var brew_key := _random_brew_key()
        if brew_key != "":
            r.call("add_brew", h, brew_key, 1)
            var brew_name: String = String(Roster.potion(brew_key).get("name", brew_key))
            _feed_line("%s is given a %s from the grateful apothecary." % [who, brew_name])
    _feed_line("Blessed supplies arrive - the stores overflow with fresh goods!")

    if tier < 2:
        return

    # ---- Tier 2 (150-499): Fortune's Favour
    if r and r.has_method("grant_all"):
        r.call("grant_all", 10, 4)   # +10 gold +4 more potions (8 total)
    # +2 random brews to buyer
    if not h.is_empty() and r:
        for i in 2:
            var brew_key := _random_brew_key()
            if brew_key != "":
                r.call("add_brew", h, brew_key, 1)
        # free forge upgrade
        if r.has_method("buy_weapon"):
            # give gold to cover the cost, then forge
            var old_gold: int = int(h.get("gold", 0))
            h["gold"] = old_gold + 9999
            r.call("buy_weapon", uid)
            r.call("buy_armour", uid)
            h["gold"] = old_gold      # refund what wasn't spent
    _feed_line("Fortune smiles on Bellmire! Gold rains, brews flow, and the smith works overtime.")

    if tier < 3:
        return

    # ---- Tier 3 (500-999): Festival of Plenty
    # D63.7: the festival that starts is THEIRS - named for the buyer, longer, dressed in
    # gold (town.start_festival "gift"). The old path set the flag with no timer, so a paid
    # festival could end the very next frame. Under a raid it waits for the raid to end.
    if town.has_method("start_festival"):
        var heroes_for: Array = [who] if who != "" else []
        town.call("start_festival", "gift", heroes_for, _buyer_name(buyer, who))
    # production boost 4x for 30 min
    if eco:
        eco.set("dis_work_k", 4.0)
        _create_timer(1800.0, func(): if eco: eco.set("dis_work_k", 1.0))
    # top tier forge for buyer
    if not h.is_empty() and r:
        var top: int = mini(Roster.forged_max(Roster.WEAPONS), Roster.town_tier)
        if int(h.get("weapon", 0)) < top:
            h["weapon"] = top
        top = mini(Roster.forged_max(Roster.ARMOUR), Roster.town_tier)
        if int(h.get("armour", 0)) < top:
            h["armour"] = top
    _feed_line("A Festival of Plenty! Music fills the square, caravans race to Bellmire, and the forge burns white-hot!")

    if tier < 4:
        return

    # ---- Tier 4 (1000+): Summon the Host
    # trigger a raid immediately
    var raids_node = town.get("raids") if town else null
    if raids_node and raids_node.has_method("raid"):
        raids_node.call("raid", "bits_summon")
    # if town survives, the grant comes when the raid ends (wired separately);
    # for now, give the upfront bonus
    if r and r.has_method("grant_all"):
        r.call("grant_all", 50, 4)
    # top everything for buyer
    if not h.is_empty() and r:
        var top: int = mini(Roster.forged_max(Roster.WEAPONS), Roster.town_tier)
        h["weapon"] = top
        top = mini(Roster.forged_max(Roster.ARMOUR), Roster.town_tier)
        h["armour"] = top
    _feed_line("THE HOST IS SUMMONED! A mighty force marches on Bellmire - every hero to the walls!")

func _restock_half(eco: Node) -> void:
    var caps := {"food": 200.0, "wood": 120.0, "stone": 80.0, "ore": 50.0, "gear": 30.0, "potion": 20.0}
    for g in caps:
        var target: float = float(caps[g]) * 0.5
        if float(eco.stock.get(g, 0.0)) < target:
            eco.stock[g] = target

func _restock_full(eco: Node) -> void:
    var caps := {"food": 200.0, "wood": 120.0, "stone": 80.0, "ore": 50.0, "gear": 30.0, "potion": 20.0}
    for g in caps:
        if float(eco.stock.get(g, 0.0)) < float(caps[g]):
            eco.stock[g] = float(caps[g])

func _random_brew_key() -> String:
    var ps: Dictionary = Roster.potions().get("potions", {})
    if ps.is_empty():
        return "mending"
    var keys: Array = ps.keys()
    # filter to brews the town can actually make
    var valid: Array = []
    for k in keys:
        if int((ps[k] as Dictionary).get("tier", 1)) <= Roster.town_tier:
            valid.append(k)
    if valid.is_empty():
        return "mending"
    return String(valid[randi() % valid.size()])

func _create_timer(secs: float, cb: Callable) -> void:
    var t := Timer.new()
    t.wait_time = secs
    t.one_shot = true
    t.autostart = true
    add_child(t)
    t.timeout.connect(func():
        cb.call()
        t.queue_free()
    )

# ---------------------------------------------------------------- chat replies

## ChatCmd.twitch_reply(user_login, text): the plain answer; the prefix and pacing are ours
func _on_twitch_reply(user_login: String, text: String) -> void:
    var t := text.strip_edges()
    if t == "" or user_login == "":
        _say_log("TWITCH_EVENTSUB chat skipped (empty reply) login='%s' text='%s'" % [user_login, text])
        return
    if _chat_q.size() >= CHAT_QUEUE_MAX:
        var dropped: Array = _chat_q.pop_front()   # oldest answer is the stalest
        _say_log("TWITCH_EVENTSUB chat skipped (queue full, dropped oldest) @%s: %s" % [String(dropped[0]), String(dropped[1])])
    _chat_q.append([user_login, t, Time.get_unix_time_from_system()])

func chat_line_for(user_login: String, text: String) -> String:
    var m := "@%s %s" % [user_login, text]
    if m.length() > CHAT_MAX_LEN:
        m = m.left(CHAT_MAX_LEN - 3) + "..."
    return m

func _tick_chat(delta: float) -> void:
    _chat_t -= delta
    if _chat_t > 0.0 or _chat_q.is_empty():
        return
    var q: Array = _chat_q.pop_front()
    var login := String(q[0])
    var text := String(q[1])
    var m := chat_line_for(login, text)
    var now := Time.get_unix_time_from_system()
    # D70.3: news goes out while the room is there or not at all. A line that sat in the queue
    # past CHAT_STALE (a stall, a token refresh, a long pause) is dropped, never dumped late.
    if q.size() > 2 and now - float(q[2]) > CHAT_STALE:
        _say_log("TWITCH_EVENTSUB chat skipped (stale %.0fs) @%s: %s" % [now - float(q[2]), login, text])
        return
    # Per-user duplicate guard, keyed on (login, text): one viewer's repeat must
    # never mute another viewer's identical answer. Twitch itself drops a repeat
    # of the bot's own previous message inside 30 s; this mirrors that, per user.
    var key := login + "\u0001" + text
    if _chat_recent.has(key) and now - float(_chat_recent[key]) < 30.0:
        _say_log("TWITCH_EVENTSUB chat skipped (duplicate within 30s) @%s: %s" % [login, text])
        return
    _chat_recent[key] = now
    for k in _chat_recent.keys():
        if now - float(_chat_recent[k]) > 60.0:
            _chat_recent.erase(k)
    _chat_t = CHAT_GAP
    sent_chat.append(m)
    var hold := _send_hold_reason()
    if hold != "":
        _say_log("TWITCH_EVENTSUB chat not sent (%s) @%s: %s" % [hold, login, text])
        return
    _send_chat(m)

## The reason the current chat line cannot go out, or "" if it can. Named so every
## suppressed reply is logged with its cause instead of returning silently (T3).
func _send_hold_reason() -> String:
    if dry_run_chat:
        return "dry_run_chat"
    if offline:
        return "offline"
    if tokens["bot"].is_empty():
        return "no bot token"
    if _token_dead["bot"]:
        return "bot token dead"
    return ""

func _send_chat(m: String) -> void:
    var r := await _helix("bot", HTTPClient.METHOD_POST, "/chat/messages",
            {"broadcaster_id": broadcaster_id, "sender_id": bot_id, "message": m})
    if int(r["code"]) == 429:
        _chat_t = 10.0                   # slow right down
    if int(r["code"]) != 200:
        _say_log("TWITCH_EVENTSUB chat not sent (%d %s)" % [int(r["code"]), _err_text(r)])
    elif typeof(r["json"]) == TYPE_DICTIONARY:
        var d: Array = r["json"].get("data", [])
        if not d.is_empty() and not bool(d[0].get("is_sent", true)):
            _say_log("TWITCH_EVENTSUB chat dropped: " + str(d[0].get("drop_reason")))

# ---------------------------------------------------------------- D70 who the bot is talking to
## .1 THE FIRST-TIMER: Twitch flags a viewer's first message EVER in this channel (IRC tag
## first-msg=1). That viewer - and only that viewer, exactly once, ever - is told they can have a
## hero and how. Persisted per uid in VIEWERS_FILE, so a restart, a second flagged line or a
## reconnect never says it twice. A viewer who already has a hero is not told (they found it).
## .2 THEIR HERO'S MOMENTS: roster.hero_moment(uid, kind, text) -> one line to the OWNER by login.
## The login is the one Twitch gave us (IRC prefix), kept per uid so a viewer who is away still
## hears it the next time the game is up AND the moment happens - nothing is ever saved for later.
## .3 THE ROOM: the game only runs while Mr. E streams (his ruling, 14:38), so being up is the
## signal; CHAT_STALE drops anything that waited too long. No news is queued across sessions.
## .4 holds: every line here is game-made text after "@<twitch login> "; no viewer-set string.
var viewers_path := VIEWERS_FILE
var welcomed := {}                  # uid -> unix time welcomed
var logins := {}                    # uid -> twitch login (Twitch-issued, [a-z0-9_] only)
var _moment_t := {}                 # uid -> unix time of the last non-death moment
var welcome_line := "welcome to Bellmire! Type !enlist and a hero of your own walks into this town - !help shows the rest."

func _viewers_load() -> void:
    welcomed = {}
    logins = {}
    if not FileAccess.file_exists(viewers_path):
        return
    var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(viewers_path))
    if typeof(j) == TYPE_DICTIONARY:
        if typeof(j.get("welcomed")) == TYPE_DICTIONARY:
            welcomed = j["welcomed"]
        if typeof(j.get("logins")) == TYPE_DICTIONARY:
            logins = j["logins"]

func _viewers_save() -> void:
    var f := FileAccess.open(viewers_path, FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify({"welcomed": welcomed, "logins": logins}))
        f.close()

static func clean_login(s: String) -> String:
    var out := ""
    for ch in s.to_lower():
        if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") or ch == "_":
            out += ch
    return out.left(25)

## Called by TwitchChat for EVERY chat line. Returns true if a welcome was queued.
func saw_viewer(uid: String, login: String, first := false) -> bool:
    var lg := clean_login(login)
    if uid == "" or lg == "":
        return false
    if String(logins.get(uid, "")) != lg:
        logins[uid] = lg
        _viewers_save()
    if not first or welcomed.has(uid):
        return false
    if uid == broadcaster_id or uid == bot_id:
        return false
    welcomed[uid] = Time.get_unix_time_from_system()   # marked BEFORE the check below: never chase
    _viewers_save()
    if _has_hero_strict(uid):
        _say_log("TWITCH_EVENTSUB D70 first-timer %s already has a hero - not welcomed" % lg)
        return false
    _on_twitch_reply(lg, welcome_line)
    _say_log("TWITCH_EVENTSUB D70 welcomed first-timer %s" % lg)
    return true

func _has_hero_strict(uid: String) -> bool:
    if town == null or town.get("roster") == null:
        return false
    var r: Object = town.get("roster")
    return r.has_method("get_hero") and not (r.call("get_hero", uid) as Dictionary).is_empty()

static func _declaw(s: String, cap := 200) -> String:
    var out := ""
    for ch in s:
        var c := ch.unicode_at(0)
        out += " " if (c < 32 or (c >= 127 and c < 160) or c == 0x2028 or c == 0x2029 or (c >= 0x200B and c <= 0x200F) or (c >= 0x202A and c <= 0x202E) or c == 0xFEFF) else ch
    return out.strip_edges().left(cap)

## roster.hero_moment -> one line to the hero's owner. Deaths, lords and rare finds always go; others are spaced
## MOMENT_GAP per viewer so a three-level delve is one line, not three. Returns true if queued.
func on_hero_moment(uid: String, kind: String, text: String) -> bool:
    var lg := String(logins.get(uid, ""))
    if lg == "":
        _say_log("TWITCH_EVENTSUB D70 moment for %s not told (no Twitch login known): %s" % [uid, kind])
        return false
    var now := Time.get_unix_time_from_system()
    if not kind in ALWAYS_TOLD:
        if _moment_t.has(uid) and now - float(_moment_t[uid]) < MOMENT_GAP:
            _say_log("TWITCH_EVENTSUB D70 moment for %s spaced out (%s)" % [lg, kind])
            return false
    _moment_t[uid] = now
    _on_twitch_reply(lg, _declaw(text))
    return true

