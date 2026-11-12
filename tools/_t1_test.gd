extends SceneTree
## T1 - Twitch phase 2, offline test (no sockets, no HTTP). Drives TwitchEventSub with
## EventSub frames shaped like Twitch's own and checks lanes, seconds, the reward-id
## rule, follows, repeats, the chat queue and the token expiry timer. Prints T1_TEST OK.

class FakeRoster extends RefCounted:
    var heroes := {"111": {"name": "BigAxe"}, "222": {"name": "MossyMage"}, "333": {"name": "Corvin"}, "444": {"name": "Gifter"}}
    func get_hero(uid: String) -> Dictionary:
        return heroes.get(uid, {})

class FakeChat extends Node:
    signal twitch_reply(user_login: String, text: String)

class FakeTown extends Node:
    var feed: Array = []
    var roster := FakeRoster.new()
    var chat := FakeChat.new()
    var spots: Array = []
    func spotlight(uid: String, lane: String, seconds: float, reason: String) -> void:
        spots.append([uid, lane, seconds, reason])

var _fails := 0
var _n := 0
var ev: TwitchEventSub
var town: FakeTown
var _f := 0
var _t0 := 0.0

func _check(name: String, ok: bool) -> void:
    print(("PASS " if ok else "FAIL ") + name)
    if not ok:
        _fails += 1

func _frame(kind: String, event: Dictionary, mid := "") -> String:
    _n += 1
    return JSON.stringify({
        "metadata": {"message_id": mid if mid != "" else "m%d" % _n, "message_type": "notification",
            "message_timestamp": "2026-11-12T00:00:00Z", "subscription_type": kind, "subscription_version": "1"},
        "payload": {"subscription": {"id": "s1", "type": kind, "status": "enabled"}, "event": event}})

func _user(id: String, name: String) -> Dictionary:
    return {"user_id": id, "user_login": name.to_lower(), "user_name": name,
        "broadcaster_user_id": "138821183", "broadcaster_user_login": "jestsayin96"}

func _initialize() -> void:
    town = FakeTown.new()
    root.add_child(town)
    town.add_child(town.chat)
    ev = TwitchEventSub.new()
    ev.offline = true
    ev.dry_run_chat = true
    root.add_child(ev)
    ev.setup(town)
    ev.reward_ids = {"spotlight": "bm-reward-1"}

    # welcome / keepalive frames parse without a socket
    ev.on_message(JSON.stringify({"metadata": {"message_id": "w1", "message_type": "session_welcome"},
        "payload": {"session": {"id": "sess-abc", "status": "connected", "keepalive_timeout_seconds": 10}}}))
    _check("1 welcome -> session id + keepalive", ev.session_id == "sess-abc" and is_equal_approx(ev._keepalive, 10.0))

    # bits: 15 / 20 / 30 s by size
    var c := _user("111", "BigAxe")
    c["bits"] = 10
    c["is_anonymous"] = false
    ev.on_message(_frame("channel.cheer", c))
    c = c.duplicate()
    c["bits"] = 60
    ev.on_message(_frame("channel.cheer", c))
    c = c.duplicate()
    c["bits"] = 500
    ev.on_message(_frame("channel.cheer", c))
    _check("2 cheers -> bits lane 15/20/30 s", town.spots.size() == 3
        and town.spots[0] == ["111", "bits", 15.0, "cheered 10 bits"]
        and town.spots[1][2] == 20.0 and town.spots[2][2] == 30.0 and town.spots[2][3] == "cheered 500 bits")
    var anon := {"user_id": null, "user_login": null, "user_name": null, "is_anonymous": true, "bits": 100}
    ev.on_message(_frame("channel.cheer", anon))
    _check("3 anonymous cheer -> Chronicle only", town.spots.size() == 3 and String(town.feed.back()).find("stranger") >= 0)

    # subs
    var s := _user("222", "MossyMage")
    s["tier"] = "1000"
    s["is_gift"] = false
    ev.on_message(_frame("channel.subscribe", s))
    _check("4 new sub -> subs lane 30 s", town.spots.back() == ["222", "subs", 30.0, "subscribed"])
    var rs := _user("333", "Corvin")
    rs["cumulative_months"] = 7
    rs["streak_months"] = 3
    rs["tier"] = "1000"
    rs["message"] = {"text": "hi", "emotes": []}
    ev.on_message(_frame("channel.subscription.message", rs))
    _check("5 resub -> subs lane 30 s", town.spots.back() == ["333", "subs", 30.0, "resubscribed - 7 months"])
    var g := _user("444", "Gifter")
    g["total"] = 5
    g["tier"] = "1000"
    g["is_anonymous"] = false
    var before := town.spots.size()
    ev.on_message(_frame("channel.subscription.gift", g))
    for i in 5:     # the five gifted subs arrive as channel.subscribe is_gift - no extra panes
        var r := _user("90%d" % i, "Lucky%d" % i)
        r["is_gift"] = true
        r["tier"] = "1000"
        ev.on_message(_frame("channel.subscribe", r))
    _check("6 gift bomb -> one 30 s pane for the gifter", town.spots.size() == before + 1
        and town.spots.back() == ["444", "subs", 30.0, "gifted 5 subs"])

    # follow -> a Chronicle line, never a pane
    before = town.spots.size()
    var fl := _user("555", "NewFriend")
    fl["followed_at"] = "2026-11-12T00:00:00Z"
    ev.on_message(_frame("channel.follow", fl))
    _check("7 follow -> Chronicle only", town.spots.size() == before and String(town.feed.back()).find("NewFriend") >= 0)

    # channel points: ours by id -> points lane; fightoverlay's (even a matching title) ignored
    var rd := _user("111", "BigAxe")
    rd["id"] = "red-1"
    rd["user_input"] = ""
    rd["status"] = "unfulfilled"
    rd["reward"] = {"id": "bm-reward-1", "title": "Spotlight my hero", "cost": 500, "prompt": ""}
    ev.on_message(_frame("channel.channel_points_custom_reward_redemption.add", rd))
    _check("8 our reward id -> points lane 15 s", town.spots.back() == ["111", "points", 15.0, "redeemed Spotlight my hero"])
    before = town.spots.size()
    var feed_n := town.feed.size()
    for t in ["Summon the Boss", "Spawn a Monster", "Drop Loot", "Spotlight my hero"]:
        var fo := rd.duplicate()
        fo["id"] = "red-x"
        fo["reward"] = {"id": "fightoverlay-" + t, "title": t, "cost": 300, "prompt": ""}
        ev.on_message(_frame("channel.channel_points_custom_reward_redemption.add", fo))
    _check("9 other app's rewards ignored (by id, not title)", town.spots.size() == before and town.feed.size() == feed_n)
    var nohero := _user("999", "Nobody")
    nohero["id"] = "red-2"
    nohero["reward"] = {"id": "bm-reward-1", "title": "Spotlight my hero", "cost": 500}
    ev.on_message(_frame("channel.channel_points_custom_reward_redemption.add", nohero))
    _check("10 no hero -> no pane, refund line + chat answer", town.spots.size() == before
        and String(town.feed.back()).find("Points returned") >= 0 and ev._chat_q.size() == 1)

    # repeats: the same message id twice is handled once
    before = town.spots.size()
    var dup := _frame("channel.cheer", c, "dup-1")
    ev.on_message(dup)
    ev.on_message(dup)
    _check("11 repeated message id handled once", town.spots.size() == before + 1)

    # reward titles stay clear of fightoverlay's words
    var all_ok := true
    for k in TwitchEventSub.REWARDS:
        all_ok = all_ok and TwitchEventSub.title_ok(String(TwitchEventSub.REWARDS[k]["title"]))
    _check("12 Bellmire reward titles avoid fightoverlay words", all_ok
        and not TwitchEventSub.title_ok("Drop a Chest") and not TwitchEventSub.title_ok("Raid the town"))

    # chat: the laptop's signal -> queue with @name, paced, repeats dropped
    ev._chat_q.clear()
    ev._chat_t = 0.0
    town.chat.twitch_reply.emit("bigaxe", "BigAxe the knight, level 3, AC 16")
    town.chat.twitch_reply.emit("mossymage", "MossyMage carries a staff")
    town.chat.twitch_reply.emit("mossymage", "MossyMage carries a staff")
    town.chat.twitch_reply.emit("x", "y".repeat(700))
    _check("13 twitch_reply connected and queued", ev._chat_q.size() == 4)
    _check("14 long answer cut to 480", ev.chat_line_for("x", "y".repeat(700)).length() == 480)

    # token timer: a fresh token is not due; a forced expiry is
    ev.tokens["broadcaster"] = {"access_token": "a", "refresh_token": "r", "expires_in": 14000}
    ev.expires_at["broadcaster"] = Time.get_unix_time_from_system() + 14000.0
    _check("15 fresh token not due", ev.seconds_left("broadcaster") > TwitchEventSub.REFRESH_EARLY)
    ev.force_expiry("broadcaster")
    _check("16 forced expiry -> due", ev.seconds_left("broadcaster") < TwitchEventSub.REFRESH_EARLY)
    _t0 = Time.get_ticks_msec() / 1000.0

func _process(_delta: float) -> bool:
    _f += 1
    var el := Time.get_ticks_msec() / 1000.0 - _t0
    if el > 6.0:
        # chat pacing: 3 sent in ~6 s (1.6 s gap), the repeat dropped
        print("T1 sent chat: ", ev.sent_chat)
        _check("17 chat paced 1.6 s and @prefixed", ev.sent_chat.size() >= 3 and ev.sent_chat.size() <= 4
            and String(ev.sent_chat[0]) == "@bigaxe BigAxe the knight, level 3, AC 16")
        var reps := 0
        for m in ev.sent_chat:
            if m == "@mossymage MossyMage carries a staff":
                reps += 1
        _check("18 repeat inside 30 s dropped", reps == 1)
        print("T1_TEST ", "OK" if _fails == 0 else "%d FAILED" % _fails)
        quit(1 if _fails > 0 else 0)
    return false
