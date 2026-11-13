extends SceneTree
## T3 - the Twitch reply path must be LOUD. Offline, no sockets, no HTTP.
## Proves: a reply either reaches chat (dry-run: sent_chat) or is logged with a
## reason; and the duplicate guard is PER-USER (one viewer's repeat cannot mute
## another's identical answer). Drives TwitchEventSub directly.

class FakeChat extends Node:
    signal twitch_reply(user_login: String, text: String)

class FakeTown extends Node:
    var feed: Array = []
    var chat := FakeChat.new()

var _fails := 0
var logs: Array = []

func _check(name: String, ok: bool) -> void:
    print(("PASS " if ok else "FAIL ") + name)
    if not ok:
        _fails += 1

func _log_has(sub: String) -> bool:
    for l in logs:
        if String(l).find(sub) >= 0:
            return true
    return false

func _on_log(s: String) -> void:
    logs.append(s)

func _pump(ev) -> void:
    for _i in range(64):
        if ev._chat_q.is_empty():
            break
        ev._chat_t = 0.0
        ev._tick_chat(0.016)

func _initialize() -> void:
    var town := FakeTown.new()
    root.add_child(town)
    town.add_child(town.chat)
    var ev := TwitchEventSub.new()
    ev.offline = true
    ev.dry_run_chat = true
    root.add_child(ev)
    ev.setup(town)
    ev.log_line.connect(_on_log)

    # 1-3 happy path: a reply reaches chat, and the dry-run hold is logged with its reason
    logs.clear()
    ev._chat_q.clear(); ev._chat_recent.clear(); ev.sent_chat.clear()
    town.chat.twitch_reply.emit("alice", "Alice the knight, level 3")
    _check("1 reply queued", ev._chat_q.size() == 1)
    _pump(ev)
    _check("2 reply reached chat (sent_chat)", ev.sent_chat.has("@alice Alice the knight, level 3"))
    _check("3 dry-run hold logged with reason+user", _log_has("chat not sent (dry_run_chat)") and _log_has("@alice"))

    # 4-5 per-user dedup: the SAME user's repeat is sent once AND the drop is logged
    ev._chat_q.clear(); ev._chat_recent.clear(); ev.sent_chat.clear(); logs.clear()
    town.chat.twitch_reply.emit("bob", "No hero yet - type !enlist")
    town.chat.twitch_reply.emit("bob", "No hero yet - type !enlist")
    _pump(ev)
    var bob_count := 0
    for m in ev.sent_chat:
        if m == "@bob No hero yet - type !enlist":
            bob_count += 1
    _check("4 same user's repeat sent once", bob_count == 1)
    _check("5 duplicate drop logged with reason+user", _log_has("chat skipped (duplicate within 30s)") and _log_has("@bob"))

    # 6-8 per-user dedup: two DIFFERENT users, identical text, BOTH get through, nothing dropped
    ev._chat_q.clear(); ev._chat_recent.clear(); ev.sent_chat.clear(); logs.clear()
    town.chat.twitch_reply.emit("cara", "No hero yet - type !enlist")
    town.chat.twitch_reply.emit("drew", "No hero yet - type !enlist")
    _pump(ev)
    _check("6 user A got the answer", ev.sent_chat.has("@cara No hero yet - type !enlist"))
    _check("7 user B got the SAME answer (not muted by A)", ev.sent_chat.has("@drew No hero yet - type !enlist"))
    _check("8 no duplicate drop across different users", not _log_has("chat skipped (duplicate within 30s)"))

    # 9 empty reply is logged, not silently dropped
    logs.clear()
    ev._on_twitch_reply("", "")
    _check("9 empty reply logged", _log_has("chat skipped (empty reply)"))

    # 10-11 queue overflow drops the oldest AND logs it
    ev._chat_q.clear(); logs.clear()
    for i in range(TwitchEventSub.CHAT_QUEUE_MAX + 2):
        ev._on_twitch_reply("u%d" % i, "line %d" % i)
    _check("10 queue capped at CHAT_QUEUE_MAX", ev._chat_q.size() == TwitchEventSub.CHAT_QUEUE_MAX)
    _check("11 queue-full drop logged", _log_has("chat skipped (queue full, dropped oldest)"))

    # 12 a live fault (no bot token) is logged with the reason, not silent (bug (a))
    ev.dry_run_chat = false
    ev.offline = false
    ev.tokens["bot"] = {}
    ev._chat_q.clear(); ev._chat_recent.clear(); ev.sent_chat.clear(); logs.clear()
    ev._on_twitch_reply("erin", "Erin the mage")
    _pump(ev)
    _check("12 missing-token hold logged with reason+user", _log_has("chat not sent (no bot token)") and _log_has("@erin"))

    print("T3_TEST ", "OK" if _fails == 0 else "%d FAILED" % _fails)
    quit(1 if _fails > 0 else 0)
