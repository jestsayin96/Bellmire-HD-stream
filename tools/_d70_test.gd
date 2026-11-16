extends SceneTree
## D70 .1/.2/.3 - the bot knows who it is talking to. Offline, dry-run chat, no sockets.
## Drives the REAL TwitchChat parser + accept() (IRC lines with Twitch's first-msg tag), the REAL
## Roster (award/kill emit hero_moment) and the REAL TwitchEventSub queue. Prints a transcript.

class FakeChat extends Node:
    signal twitch_reply(user_login: String, text: String)

class FakeTown extends Node:
    var feed: Array = []
    var chat := FakeChat.new()
    var roster: Roster
    func chat_line(_u: String, _d: String, _m: String) -> String:
        return ""

var _fails := 0
var _checks := 0
var logs: Array = []

func _check(name: String, ok: bool) -> void:
    _checks += 1
    print(("PASS " if ok else "FAIL ") + name)
    if not ok:
        _fails += 1

func _pump(ev) -> void:
    for _i in range(64):
        if ev._chat_q.is_empty():
            break
        ev._chat_t = 0.0
        ev._tick_chat(0.016)

func _irc(uid: String, login: String, text: String, first: bool) -> String:
    return "@badge-info=;display-name=%s;first-msg=%s;user-id=%s :%s!%s@%s.tmi.twitch.tv PRIVMSG #jestsayin96 :%s" \
        % [login.replace("\n", "").replace(" ", ""), "1" if first else "0", uid, login, login, login, text]

func _initialize() -> void:
    var town := FakeTown.new()
    town.name = "Town"
    root.add_child(town)
    town.add_child(town.chat)
    town.roster = Roster.new()
    town.add_child(town.roster)
    var ev := TwitchEventSub.new()
    ev.name = "TwitchEventSub"
    ev.offline = true
    ev.dry_run_chat = true
    town.add_child(ev)
    ev.setup(town)
    ev.log_line.connect(func(s: String) -> void: logs.append(s))
    _check("0 harness uses the test viewers file, not the real one", ev.viewers_path == "user://d70_viewers_test.json")
    if FileAccess.file_exists(ev.viewers_path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(ev.viewers_path))
    ev._viewers_load()
    var tc := TwitchChat.new()
    tc.enabled = false
    tc.town = town
    root.add_child(tc)

    # .1 THE FIRST-TIMER
    var p := TwitchChat.parse(_irc("5001", "newcomer_a", "hi all", true))
    _check("1 parser reads Twitch's first-msg tag", bool(p.get("first", false)))
    tc._feed(_irc("5001", "newcomer_a", "hi all", true) + "\r\n")
    _pump(ev)
    _check("2 first-timer welcomed once, by Twitch login", ev.sent_chat.size() == 1 and String(ev.sent_chat[0]).begins_with("@newcomer_a welcome to Bellmire!") and String(ev.sent_chat[0]).find("!enlist") >= 0)
    tc._feed(_irc("5001", "newcomer_a", "anyone here?", true) + "\r\n")   # a second flagged line
    tc._feed(_irc("5001", "newcomer_a", "hello again", false) + "\r\n")
    _pump(ev)
    _check("3 never twice in a session", ev.sent_chat.size() == 1)
    ev._viewers_load()                                                    # a restart reloads the file
    tc._feed(_irc("5001", "newcomer_a", "back again", true) + "\r\n")
    _pump(ev)
    _check("4 never twice across a restart (persisted)", ev.sent_chat.size() == 1 and ev.welcomed.has("5001"))
    tc._feed(_irc("5002", "regular_b", "!stats", false) + "\r\n")
    _pump(ev)
    _check("5 a regular (no first-msg) is not welcomed", ev.sent_chat.size() == 1)
    town.roster.fresh("5003", "Hasone", "knight")
    tc._feed(_irc("5003", "hasone", "first words", true) + "\r\n")
    _pump(ev)
    _check("6 a first-timer who already has a hero is not chased", ev.sent_chat.size() == 1 and ev.welcomed.has("5003"))
    tc._feed(_irc(ev.bot_id, "bellmirebro", "beep", true) + "\r\n")
    tc._feed(_irc(ev.broadcaster_id, "jestsayin96", "yo", true) + "\r\n")
    _pump(ev)
    _check("7 the bot and Mr. E are never welcomed", ev.sent_chat.size() == 1)
    tc._feed(_irc("5004", "Evil\nName/", "hi", true) + "\r\n")
    _pump(ev)
    _check("8 a login is reduced to [a-z0-9_] before it is used", ev.sent_chat.size() == 2 and String(ev.sent_chat[1]).begins_with("@evilname welcome"))

    # .2 THEIR HERO'S MOMENTS
    ev.sent_chat.clear()
    var hero_name := "/ban Mr.E\nPWNED"            # a hostile viewer-set name must never reach chat
    town.roster.fresh("5002", hero_name, "knight")
    var h: Dictionary = town.roster.get_hero("5002")
    h["name"] = hero_name
    town.roster.award("5002", 0, 999999, 0, 0)       # many levels at once
    _pump(ev)
    var lvl_lines := ev.sent_chat.size()
    _check("9 a burst of level-ups is ONE line to the owner, not one per level", lvl_lines <= 1)
    if lvl_lines == 1:
        _check("10 the moment addresses the owner by Twitch login", String(ev.sent_chat[0]).begins_with("@regular_b your hero"))
    else:
        print("NOTE no unlock/rank moment fired from the award (still fine)")
    ev.sent_chat.clear()
    var said := town.roster.kill("5002", "a bog wight", 4, 3)
    _pump(ev)
    _check("11 a death is told to its owner, one line", ev.sent_chat.size() == 1 and String(ev.sent_chat[0]) == "@regular_b your hero fell on floor 4 to a bog wight at level %d. !reroll to rise again." % int(h["level"]))
    var all := "\n".join(ev.sent_chat)
    _check("12 the hostile hero name never reached chat (.4)", all.find("PWNED") < 0 and all.find("/ban") < 0 and said.find("PWNED") >= 0)
    ev.sent_chat.clear()
    town.roster.fresh("6001", "Nobody", "mage")
    var told: bool = ev.on_hero_moment("6001", "fell", "your hero fell.")
    _check("13 no Twitch login known -> nothing said, and it says why", not told and ev.sent_chat.is_empty())

    # .3 THE ROOM: nothing waits to be dumped late
    ev.sent_chat.clear(); ev._chat_q.clear(); ev._chat_recent.clear()
    ev._on_twitch_reply("regular_b", "an old line")
    ev._chat_q[0][2] = Time.get_unix_time_from_system() - TwitchEventSub.CHAT_STALE - 5.0
    _pump(ev)
    var stale_logged := false
    for l in logs:
        if String(l).find("chat skipped (stale") >= 0:
            stale_logged = true
    _check("14 a line older than CHAT_STALE is dropped and logged, never sent", ev.sent_chat.is_empty() and stale_logged)
    var f := FileAccess.get_file_as_string(ev.viewers_path)
    _check("15 the persisted file holds only uids, logins and times (no queued news)", f.find("\"welcomed\"") >= 0 and f.find("fell") < 0 and f.find("welcome to") < 0)
    DirAccess.remove_absolute(ProjectSettings.globalize_path(ev.viewers_path))

    print("TRANSCRIPT (dry-run chat, in order):")
    for l in logs:
        if String(l).find("D70") >= 0 or String(l).find("chat not sent (dry_run_chat)") >= 0:
            print("  ", l)
    print("D70_TEST %s %d checks, %d failed" % ["OK" if _fails == 0 else "FAIL", _checks, _fails])
    quit(0 if _fails == 0 else 1)
