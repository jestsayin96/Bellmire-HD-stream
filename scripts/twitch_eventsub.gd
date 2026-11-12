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

## words fightoverlay acts on - no Bellmire reward title may contain one
const FORBIDDEN := ["boss", "monster", "spawn", "raid", "mob", "goblin", "horde", "loot",
        "drop", "chest", "treasure", "invade", "titan"]
## Bellmire's rewards: key -> settings. The key is ours; Twitch gives the id.
const REWARDS := {
    "spotlight": {"title": "Spotlight my hero", "cost": 500,
        "prompt": "The eye of Bellmire turns to your hero for a while. Raise one first with !enlist.",
        "background_color": "#2AA198", "lane": "points", "seconds": 15.0},
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

## Finds Bellmire's own rewards (only_manageable_rewards = made by this client id) and
## makes any that are missing. Matching is by id; a title is only used to adopt a reward
## this same client id already made (a lost rewards file).
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
    var mine := {}                  # id -> title
    for rw in (r["json"] as Dictionary).get("data", []):
        mine[String(rw["id"])] = String(rw["title"])
    for key in REWARDS:
        var want: Dictionary = REWARDS[key]
        if reward_ids.has(key) and mine.has(String(reward_ids[key])):
            continue
        reward_ids.erase(key)
        for id in mine:
            if mine[id] == String(want["title"]):
                reward_ids[key] = id
        if reward_ids.has(key):
            continue
        if not title_ok(String(want["title"])):
            _say_log("TWITCH_EVENTSUB reward title %s uses a fightoverlay word - not made" % want["title"])
            continue
        var c := await _helix("broadcaster", HTTPClient.METHOD_POST,
                "/channel_points/custom_rewards?broadcaster_id=%s" % broadcaster_id,
                {"title": want["title"], "cost": want["cost"], "prompt": want["prompt"],
                 "background_color": want["background_color"], "is_enabled": true})
        if int(c["code"]) == 200:
            reward_ids[key] = String(c["json"]["data"][0]["id"])
            _say_log("TWITCH_EVENTSUB made reward %s (%s)" % [want["title"], reward_ids[key]])
        else:
            rewards_note = _err_text(c)
            _say_log("TWITCH_EVENTSUB could not make reward %s (%d %s)" % [want["title"], int(c["code"]), rewards_note])
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
    if not enabled or offline:
        _tick_chat(delta)
        return
    _tick_tokens(delta)
    _tick_chat(delta)
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
                return
            _feed_line("%s cheers %d bits for Bellmire!" % [who, bits])
            _spot(uid, "bits", bits_seconds(bits), "cheered %d bits" % bits)
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
            if not _has_hero(uid):
                _feed_line("%s calls for the spotlight, but has no hero yet - !enlist first. Points returned." % who)
                if login != "":
                    _on_twitch_reply(login, "you need a hero first - type !enlist. Your points were returned.")
                _settle(String(e.get("id", "")), rid, false)
                return
            _spot(uid, String(want["lane"]), float(want["seconds"]), "redeemed " + String(rw.get("title", want["title"])))
            _settle(String(e.get("id", "")), rid, true)

func _has_hero(uid: String) -> bool:
    if town == null or town.get("roster") == null:
        return true
    var r: Object = town.get("roster")
    return r.has_method("get_hero") and not (r.call("get_hero", uid) as Dictionary).is_empty()

func _spot(uid: String, lane: String, seconds: float, reason: String) -> void:
    spotlights.append([uid, lane, seconds, reason])
    spotlight_wanted.emit(uid, lane, seconds, reason)
    if town and town.has_method("spotlight"):
        town.call("spotlight", uid, lane, seconds, reason)
    else:
        print("SPOTLIGHT %s %s %.0fs %s (town.spotlight not built yet - L17)" % [uid, lane, seconds, reason])

# ---------------------------------------------------------------- chat replies

## ChatCmd.twitch_reply(user_login, text): the plain answer; the prefix and pacing are ours
func _on_twitch_reply(user_login: String, text: String) -> void:
    var t := text.strip_edges()
    if t == "" or user_login == "":
        return
    if _chat_q.size() >= CHAT_QUEUE_MAX:
        _chat_q.pop_front()              # oldest answer is the stalest
    _chat_q.append([user_login, t])

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
    var m := chat_line_for(String(q[0]), String(q[1]))
    var now := Time.get_unix_time_from_system()
    if _chat_recent.has(m) and now - float(_chat_recent[m]) < 30.0:
        return                           # Twitch drops a repeat inside 30 s anyway
    _chat_recent[m] = now
    for k in _chat_recent.keys():
        if now - float(_chat_recent[k]) > 60.0:
            _chat_recent.erase(k)
    _chat_t = CHAT_GAP
    sent_chat.append(m)
    if dry_run_chat or offline or tokens["bot"].is_empty() or _token_dead["bot"]:
        return
    _send_chat(m)

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
