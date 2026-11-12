extends SceneTree
## L18: free chat in the main view. The director's hero shot favours the freshest
## chatter, "Now watching: ..." names them, their name glows ~5 s after a command,
## a free !look borrows the points lane only when it is empty. Prints L18_TEST OK.
## (The look: tools/_l18_shot.gd.)
var _fail := 0
var _f := 0
var _t: Node3D
var _eye: RtsCamera

func _ok(c: bool, what: String) -> void:
	print(("  ok  " if c else "  FAIL ") + what)
	if not c:
		_fail += 1

func _say(uid: String, nm: String, msg: String) -> String:
	(_t.get("chat") as ChatCmd)._last.erase(uid)
	return _t.call("chat_line", uid, nm, msg)

func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)

func _process(_d: float) -> bool:
	_f += 1
	if _f == 20:
		_eye = RtsCamera.new()
		_t.add_child(_eye)
		_eye.setup(_t)
		for v in [["9101", "Ash", "!enlist knight dwarf"], ["9102", "Bree", "!enlist mage elf"], ["9103", "Cole", "!enlist rogue halfling"]]:
			_say(v[0], v[1], v[2])
		_eye.director._set_on(true)
	if _f == 60:
		var dir: AutoDirector = _eye.director
		var hs: Dictionary = _t.get("heroes")
		_ok(hs.has("9101") and hs.has("9102") and hs.has("9103"), "three heroes raised in town")
		# a while later Bree speaks up: she is the freshest
		ChatCmd.last_cmd["9101"] = Time.get_ticks_msec() - 90000
		ChatCmd.last_cmd["9103"] = Time.get_ticks_msec() - 60000
		_say("9102", "Bree", "!hero")
		var best := dir._best()
		_ok(String(best.get("key", "")) == "chat_9102", "the director's pick is the freshest chatter: %s" % best.get("key"))
		_ok(float(best.get("pri", 0.0)) > 35.0 and float(best.get("pri", 0.0)) <= 50.0, "a chatter ranks over a random hero (30-35), under fights (75+) and lords (100): %.1f" % float(best.get("pri", 0.0)))
		# nobody has spoken for 2 minutes: back to a random hero
		for u in ["9101", "9102", "9103"]:
			ChatCmd.last_cmd[u] = Time.get_ticks_msec() - 130000
		best = dir._best()
		_ok(String(best.get("key", "")).begins_with("hero_"), "after 2 quiet minutes, any hero again: %s" % best.get("key"))
		# the banner
		_ok(dir.banner_text(hs["9102"]) == "Now watching: Bree the Elf Mage", "banner: " + dir.banner_text(hs["9102"]))
		_ok(dir.banner_text(_t) == "", "no banner on anything that is not a viewer's hero")
		ChatCmd.last_cmd["9102"] = Time.get_ticks_msec()
		dir._cut(dir._best())
		dir._banner_tick()
		_ok(dir._banner != null and dir._banner.visible and dir._banner.text.contains("Bree"), "the banner is up on the director's shot of Bree")
		dir._paused_for = 5.0
		dir._banner_tick()
		_ok(not dir._banner.visible, "the banner hides while the camera is in your hands")
		dir._paused_for = 0.0
		# the glow
		var lb := (hs["9102"] as HeroBody)._name_label()
		HeroBody.glow(lb, 99.0)
		var m0 := lb.modulate          # the gold before any glow
		var k := HeroBody.glow(lb, 0.5)
		_ok(k > 1.1 and not lb.modulate.is_equal_approx(m0), "a fresh command: the name glows and grows (x%.2f)" % k)
		k = HeroBody.glow(lb, 6.0)
		_ok(is_equal_approx(k, 1.0) and lb.modulate.is_equal_approx(m0), "after 5 s the name is back to its gold")
		# free !look: only into an empty points lane
		var o := _say("9103", "Cole", "!look")
		_ok(o.begins_with("Spotlight on Cole"), "!look: " + o)
		o = _say("9101", "Ash", "!look")
		_ok(o.contains("busy"), "a second !look waits: " + o)
		print("L18_TEST OK" if _fail == 0 else "L18_TEST FAIL %d" % _fail)
		return true
	return false
