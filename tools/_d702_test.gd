extends SceneTree
## D70.2 remainder - the two hero moments that had no hook: CAME HOME WITH SOMETHING RARE, and
## STRUCK THE BLOW THAT FELLED A LORD. Offline, dry-run chat, no sockets. Real Roster, real
## TwitchEventSub queue, real Delve._on_kill and Delve._finish. Prints a transcript.

class FakeChat extends Node:
	signal twitch_reply(user_login: String, text: String)

class FakeTown extends Node3D:
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

func _initialize() -> void:
	var town := FakeTown.new()
	town.name = "Town"
	root.add_child(town)
	town.add_child(town.chat)
	town.roster = Roster.new()
	town.add_child(town.roster)
	var r: Roster = town.roster
	var ev := TwitchEventSub.new()
	ev.name = "TwitchEventSub"
	ev.offline = true
	ev.dry_run_chat = true
	town.add_child(ev)
	ev.setup(town)
	ev.log_line.connect(func(s: String) -> void: logs.append(s))
	_check("0 harness uses the test viewers file", ev.viewers_path == "user://d70_viewers_test.json")
	for u in ["7001", "7002", "7003", "7004"]:
		ev.logins[u] = "viewer_" + u

	# RARE: found below, told on the way HOME, once
	var h1: Dictionary = r.fresh("7001", "/me PWNED\nx", "knight")
	h1["name"] = "/me PWNED\nx"
	h1["weapon"] = 2; h1["armour"] = 4
	var line := r.find_gear("7001", 8, 0.0, false)
	_pump(ev)
	_check("1 a rare find (tier %d) is said in the feed but NOT told yet - they are still below" % int(h1["weapon"]), line != "" and int(h1["weapon"]) >= Roster.RARE_TIER and ev.sent_chat.is_empty())
	var told := r.came_home("7001")
	_pump(ev)
	var what := r.weapon_name(h1)
	_check("2 home -> ONE line to the owner by login", told and ev.sent_chat.size() == 1 and String(ev.sent_chat[0]).begins_with("@viewer_7001 your hero came home from floor 8 carrying ") and String(ev.sent_chat[0]).find(what) >= 0)
	_check("3 never twice", not r.came_home("7001"))
	_check("4 the hostile hero name never reached chat", "\n".join(ev.sent_chat).find("PWNED") < 0)
	ev.sent_chat.clear()
	var h2: Dictionary = r.fresh("7002", "Plain", "knight")
	h2["weapon"] = 0; h2["armour"] = 0
	r.find_gear("7002", 8, 0.0, false)
	_check("5 an ordinary find (tier %d) is not a moment" % int(h2["weapon"]), not r.came_home("7002"))
	var h3: Dictionary = r.fresh("7003", "Doomed", "knight")
	h3["weapon"] = 2; h3["armour"] = 4
	r.find_gear("7003", 9, 0.0, false)
	r.kill("7003", "a bog wight", 9, 1)
	_pump(ev)
	ev.sent_chat.clear()
	_check("6 a hero who died below did not come home with anything", not r.came_home("7003"))

	# LORD: the delver whose blow it was, and only them
	var d := Delve.new()
	d.roster = r
	d.floor_no = 12
	d.town = town
	root.add_child(d)
	var dh := DungeonHD.new()
	d.dun = dh
	var lord := Monster.new()
	lord.def = {"name": "the Ninth Abbot", "boss": true}
	dh.lord = lord
	var h4: Dictionary = r.fresh("7004", "Slayer", "knight")
	var m4 := {"uid": "7004", "h": h4, "body": null, "hp": 50.0, "max": 50.0, "saved": false, "swing": 0.0}
	var m1 := {"uid": "7001", "h": h1, "body": null, "hp": 50.0, "max": 50.0, "saved": false, "swing": 0.0}
	d.party = [m4, m1]
	var thing := Monster.new()
	thing.def = {"name": "rat", "boss": false}
	d._on_kill(thing, m4)
	_pump(ev)
	_check("7 an ordinary kill is not a moment", ev.sent_chat.is_empty())
	lord.state = Monster.S.DEAD
	d._on_kill(lord, {})
	_pump(ev)
	_check("8 a lord dying with no delver's blow (a trap, a burn) tells nobody", ev.sent_chat.is_empty())
	ev._moment_t["7004"] = Time.get_unix_time_from_system()      # a learn just went out to this viewer
	d._on_kill(lord, m4)
	_pump(ev)
	_check("9 the blow that felled a lord -> ONE line to THAT owner, even inside the 45 s gap", ev.sent_chat.size() == 1 and String(ev.sent_chat[0]) == "@viewer_7004 your hero struck the blow that felled the Ninth Abbot on floor 12.")
	_check("10 the other delver is not told they felled it", "\n".join(ev.sent_chat).find("viewer_7001") < 0)
	var ok_learn: bool = ev.on_hero_moment("7004", "learned", "your hero learned a thing.")
	_check("11 an ordinary moment right after is still spaced out", not ok_learn)

	# HOME, through the real Delve._finish
	ev.sent_chat.clear()
	h1["weapon"] = 3; h1["armour"] = 4
	r.find_gear("7001", 12, 0.0, false)
	d._finish()
	_pump(ev)
	var homers := 0
	for s in ev.sent_chat:
		if String(s).find("came home from floor 12") >= 0:
			homers += 1
	_check("12 Delve._finish tells the rare find on the way home, once", homers == 1 and String(ev.sent_chat[0]).begins_with("@viewer_7001 "))
	_check("13 nothing viewer-set in any line", "\n".join(ev.sent_chat).find("PWNED") < 0 and "\n".join(ev.sent_chat).find("/me") < 0)
	if FileAccess.file_exists(ev.viewers_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ev.viewers_path))
	print("TRANSCRIPT (dry-run chat, in order):")
	for l in logs:
		if String(l).find("D70") >= 0 or String(l).find("chat not sent (dry_run_chat)") >= 0:
			print("  ", l)
	print("D702_TEST %s %d checks, %d failed" % ["OK" if _fails == 0 else "FAIL", _checks, _fails])
	quit(0 if _fails == 0 else 1)
