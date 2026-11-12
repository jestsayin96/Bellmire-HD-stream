extends SceneTree
## L17: the spotlight lanes. Queues per lane, the free !look only into an empty points
## lane, layouts off / pair / grid, timers run out and the queue moves on, test verbs
## local-only, F10 labels. Prints L17_TEST OK. (The look: tools/_l17_shot.gd.)
var _fail := 0
var _f := 0
var _t: Node3D
var _r: Roster
var _s: Spotlight
var _c: ChatCmd

func _ok(c: bool, what: String) -> void:
	print(("  ok  " if c else "  FAIL ") + what)
	if not c:
		_fail += 1

func _initialize() -> void:
	# a stand-in town: the spotlight only needs roster, chat, heroes and a market
	_t = Node3D.new()
	_t.set_script(load("res://tools/_l17_town.gd"))
	root.add_child(_t)
	_r = Roster.new()
	_t.add_child(_r)
	_t.set("roster", _r)
	_c = ChatCmd.new(_r)
	_t.add_child(_c)
	_t.set("chat", _c)
	for v in [["u1", "Ash"], ["u2", "Bree"], ["u3", "Cole"], ["u4", "Dara"], ["u5", "Eli"]]:
		_r.fresh(v[0], v[1], "knight", "human")
		var b := Node3D.new()
		_t.add_child(b)
		b.position = Vector3(randf() * 10.0, 0, randf() * 10.0)
		(_t.get("heroes") as Dictionary)[v[0]] = b
	_s = Spotlight.of(_t)

func _process(_d: float) -> bool:
	_f += 1
	if _f < 3:
		return false
	_ok(_s != null and Spotlight.of(_t) == _s, "one spotlight per town")
	_ok(Spotlight.bits_seconds(1) == 15.0 and Spotlight.bits_seconds(50) == 20.0 and Spotlight.bits_seconds(500) == 30.0, "bits 15 / 20 / 30 s")
	_ok(_s._layout == "off" and not _s.visible, "nobody spotlit: the director full screen")
	# free !look -> points lane, 10 s
	var o := _c.handle("u1", "Ash", "!look")
	_ok(o.begins_with("Spotlight on Ash") and (_s.lanes["points"]["cur"] as Dictionary).get("uid") == "u1", "!look opens the points lane: " + o)
	_ok(is_equal_approx(float(_s.lanes["points"]["cur"]["seconds"]), Spotlight.LOOK_S), "a look lasts 10 s")
	_ok(_s._layout == "pair_points" and get_root().disable_3d, "one lane: side by side, the main view stops drawing 3D")
	o = _c.handle("u2", "Bree", "!look")
	_ok(o.contains("busy") and (_s.lanes["points"]["q"] as Array).is_empty(), "a second !look waits, not queued: " + o)
	# test verbs: Twitch ids cannot use them
	o = _c.handle("u3", "Cole", "!testbits 500")
	_ok(o == "" and (_s.lanes["bits"]["cur"] as Dictionary).is_empty(), "!testbits is ignored from a Twitch id")
	o = _c.handle("local_mre", "MrE", "!testbits 500 cole")
	_ok((_s.lanes["bits"]["cur"] as Dictionary).get("uid") == "u3" and is_equal_approx(float(_s.lanes["bits"]["cur"]["seconds"]), 30.0), "!testbits 500 cole: Cole, 30 s in bits")
	_ok(_s._layout.begins_with("grid"), "two lanes busy: the 2x2")
	_ok((_s._panes["wide"]["box"] as Control).visible, "the empty lane shows the wide town view")
	_c._last.clear()
	o = _c.handle("local_mre", "MrE", "!testsub dara")
	_ok((_s.lanes["subs"]["cur"] as Dictionary).get("uid") == "u4" and not (_s._panes["wide"]["box"] as Control).visible, "!testsub dara: subs lane, all three panes, no wide view")
	_c._last.clear()
	o = _c.handle("local_mre", "MrE", "!testpoints eli")
	_ok((_s.lanes["points"]["q"] as Array).size() == 1 and o.contains("queue (#1)"), "a redeem queues behind the look: " + o)
	_c._last.clear()
	o = _c.handle("u2", "Bree", "!look")
	_ok(o.contains("busy"), "a look never queues behind a redeem")
	# labels: name, people, calling, reason; F10 hides them
	var lb: Label = _s._panes["bits"]["label"]
	_ok(lb.visible and lb.text.contains("Cole") and lb.text.contains("Knight") and lb.text.contains("cheered 500 bits"), "pane label: " + lb.text)
	_s.set_labels(false)
	_ok(not lb.visible, "F10 hides the labels")
	_s.set_labels(true)
	# the timer runs out: the look ends, the queued redeem takes the lane
	_s.lanes["points"]["cur"]["left"] = 0.0
	_s._process(0.016)
	_ok((_s.lanes["points"]["cur"] as Dictionary).get("uid") == "u5" and is_equal_approx(float(_s.lanes["points"]["cur"]["seconds"]), 15.0), "the look ends, Eli's 15 s redeem moves up")
	# a hero who is gone frees their lane
	_r.heroes.erase("u3")
	_s._process(0.016)
	_ok((_s.lanes["bits"]["cur"] as Dictionary).is_empty(), "a gone hero frees the bits lane")
	for l in Spotlight.LANES:
		_s.lanes[l]["cur"] = {}
		_s.lanes[l]["q"] = []
	_s._relayout()
	_ok(_s._layout == "off" and not get_root().disable_3d, "all lanes empty: back to the director full screen, 3D on")
	# !help knows !look
	_ok(ChatCmd.help_line("look").contains("10"), "!help look reads from commands.json")
	_ok(ChatCmd.canonical("spotlight") == "look", "!spotlight is an alias of !look")
	print("L17_TEST OK" if _fail == 0 else "L17_TEST FAIL %d" % _fail)
	return true
