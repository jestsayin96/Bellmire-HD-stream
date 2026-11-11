class_name TwitchChat
extends Node
## Live Twitch chat, phase 1: READ ONLY, anonymous (no token, nothing sent to chat).
## Twitch IRC over WebSocket -> filter -> town.chat_line(uid, display, text),
## the same entry point the local chat box uses. ChatCmd is untouched.

const URL := "wss://irc-ws.chat.twitch.tv:443"
const CFG := "user://twitch.cfg"
const COOLDOWN_MS := 3000
const PER_FRAME := 4

var town: Node                      # anything with chat_line(uid, display, text)
var channel := "jestsayin96"
var enabled := true
var ignore: Array = ["streamelements", "nightbot", "streamlabs", "moobot", "fossabot"]

var _ws := WebSocketPeer.new()
var _was_open := false
var _retry_in := -1.0               # < 0: not waiting to reconnect
var _backoff := 2.0
var _queue: Array = []              # [uid, display, text]
var _last := {}                     # uid -> ticks ms of last accepted command
var _buf := ""

func setup(t: Node) -> void:
    town = t
    _load_cfg()
    if enabled:
        _open()

func _load_cfg() -> void:
    var c := ConfigFile.new()
    if FileAccess.file_exists(CFG) and c.load(CFG) == OK:
        channel = String(c.get_value("twitch", "channel", channel)).to_lower()
        enabled = bool(c.get_value("twitch", "enabled", enabled))
        ignore = c.get_value("twitch", "ignore", ignore)
    else:
        c.set_value("twitch", "channel", channel)
        c.set_value("twitch", "enabled", enabled)
        c.set_value("twitch", "ignore", ignore)
        c.save(CFG)                 # a file Mr. E can edit

func _open() -> void:
    _ws = WebSocketPeer.new()
    _was_open = false
    if _ws.connect_to_url(URL) != OK:
        print("TWITCH connect failed")
        _schedule_retry()

func _schedule_retry() -> void:
    _retry_in = _backoff
    print("TWITCH reconnecting in %.0f s" % _backoff)
    _backoff = minf(_backoff * 2.0, 60.0)

func _process(delta: float) -> void:
    if not enabled:
        return
    if _retry_in >= 0.0:
        _retry_in -= delta
        if _retry_in < 0.0:
            _open()
        return
    _ws.poll()
    match _ws.get_ready_state():
        WebSocketPeer.STATE_OPEN:
            if not _was_open:
                # only once the socket is open can the login be sent
                _was_open = true
                _backoff = 2.0
                _ws.send_text("CAP REQ :twitch.tv/tags twitch.tv/commands")
                _ws.send_text("NICK justinfan%d" % (10000 + randi() % 89999))
                _ws.send_text("JOIN #" + channel)
                print("TWITCH joined #", channel)
            while _ws.get_available_packet_count() > 0:
                _feed(_ws.get_packet().get_string_from_utf8())
        WebSocketPeer.STATE_CLOSED:
            print("TWITCH closed (%d)" % _ws.get_close_code())
            _schedule_retry()
    _drain()

## raw socket text -> lines -> actions. Public so the test tool can drive it.
func _feed(text: String) -> void:
    _buf += text
    var lines := _buf.split("\r\n")
    _buf = lines[lines.size() - 1]          # keep any half line for next time
    for i in range(lines.size() - 1):
        _line(lines[i])

func _line(line: String) -> void:
    var m := TwitchChat.parse(line)
    match String(m.get("kind", "")):
        "ping":
            _send("PONG :" + String(m["arg"]))
        "reconnect":
            _ws.close()
        "msg":
            accept(m)

func _send(s: String) -> void:
    if _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
        _ws.send_text(s)
    sent.append(s)                          # for the test tool

var sent: Array = []

## filters: commands only, no bots, 3 s per user. Returns true if queued.
func accept(m: Dictionary) -> bool:
    var text: String = String(m["text"]).strip_edges()
    if not text.begins_with("!"):
        return false
    var login: String = String(m["login"]).to_lower()
    if ignore.has(login):
        return false
    var uid: String = String(m["uid"]) if String(m["uid"]) != "" else "tw_" + login
    var now := Time.get_ticks_msec()
    if _last.has(uid) and now - int(_last[uid]) < COOLDOWN_MS:
        return false
    _last[uid] = now
    var disp: String = String(m["display"]) if String(m["display"]) != "" else login
    _queue.append([uid, disp, text])
    return true

func _drain() -> void:
    var n := 0
    while not _queue.is_empty() and n < PER_FRAME:
        var q: Array = _queue.pop_front()
        if town and town.has_method("chat_line"):
            town.chat_line(q[0], q[1], q[2])
        n += 1

## One IRC line -> {kind: ping|reconnect|msg|other, ...}.
## "@tag=v;tag2=v :login!login@login.tmi.twitch.tv PRIVMSG #chan :text"
static func parse(line: String) -> Dictionary:
    var rest := line.strip_edges(false, true)
    var tags := {}
    if rest.begins_with("@"):
        var sp := rest.find(" ")
        if sp < 0:
            return {"kind": "other"}
        for kv in rest.substr(1, sp - 1).split(";"):
            var eq := kv.find("=")
            if eq > 0:
                tags[kv.substr(0, eq)] = kv.substr(eq + 1).replace("\\s", " ")
        rest = rest.substr(sp + 1)
    var prefix := ""
    if rest.begins_with(":"):
        var sp2 := rest.find(" ")
        if sp2 < 0:
            return {"kind": "other"}
        prefix = rest.substr(1, sp2 - 1)
        rest = rest.substr(sp2 + 1)
    if rest.begins_with("PING"):
        var a := rest.find(":")
        return {"kind": "ping", "arg": rest.substr(a + 1) if a >= 0 else "tmi.twitch.tv"}
    if rest.begins_with("RECONNECT"):
        return {"kind": "reconnect"}
    if rest.begins_with("PRIVMSG "):
        var c := rest.find(" :")
        if c < 0:
            return {"kind": "other"}
        var login := prefix.get_slice("!", 0)
        return {"kind": "msg", "uid": String(tags.get("user-id", "")), "login": login,
                "display": String(tags.get("display-name", "")),
                "badges": String(tags.get("badges", "")),
                "chan": rest.substr(8, c - 8).strip_edges(),
                "text": rest.substr(c + 2)}
    return {"kind": "other"}
