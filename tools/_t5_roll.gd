extends SceneTree
## T5 TEST - THE VIEWER'S ROLL. Loads the real town, fires viewer rolls through an OFFLINE
## TwitchEventSub (no sockets, no HTTP) and asserts: the five bands, what the viewer typed picks
## the action, every outcome CHANGES the town (smithy level, festival, renown, stores, treasury)
## including the failures, a real redemption event rolls with no hero needed, the Chronicle says
## it in plain words with the Commander's verdict, and the snapshot publishes `rolls` in the hub's
## contract (n, by, what, result, tier, cost, at - names cleaned). Windowed, it also shoots the
## smithy rack and the square before/after. Prints T5_ROLL OK/FAIL.
var _t: Node3D
var _es: TwitchEventSub
var _f := 0
var _checks := 0
var _fails: Array = []
var _shots := false
var _cam: Camera3D

func _ok(c: bool, what: String) -> void:
	_checks += 1
	if not c:
		_fails.append(what)
	print("  %s %s" % ["ok  " if c else "FAIL", what])

func _initialize() -> void:
	_shots = DisplayServer.get_name() != "headless"
	root.size = Vector2i(1920, 1080)
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)

func _feed_has(s: String) -> bool:
	for l in (_t.get("feed") as Array):
		if str(l).contains(s):
			return true
	return false

func _smithy_cam() -> void:
	var fr: Array = (_t.get("_shop_frame") as Dictionary).get("blacksmith", [])
	var y: Vector3 = fr[0]
	var side: Vector3 = fr[1]
	var f: Vector3 = fr[2]
	var rp := y + side * -1.8 + f * 1.4
	rp.y = float(_t.call("height_at", rp.x, rp.z))
	_cam.global_position = rp + f * 3.6 + Vector3(0, 1.8, 0)
	_cam.look_at(rp + Vector3(0, 1.0, 0), Vector3.UP)

func _square_cam() -> void:
	var m: Vector3 = _t.get("_market_pos")
	_cam.global_position = m + Vector3(14, 11, 14)
	_cam.look_at(m + Vector3(0, 1, 0), Vector3.UP)

func _shot(n: String) -> void:
	if _shots:
		root.get_texture().get_image().save_png("res://renders/cycles/t5/%s.png" % n)
		print("T5SHOT ", n)

func _process(_d: float) -> bool:
	_f += 1
	var eco: Economy = _t.get("economy")
	if _f == 20:
		print("T5_ROLL start")
		_es = TwitchEventSub.new()
		_es.offline = true
		_es.dry_run_chat = true
		_es.town = _t
		_t.add_child(_es)
		_cam = Camera3D.new()
		_t.add_child(_cam)
		_cam.make_current()
		_cam.fov = 42.0
		eco.clock = 0.45                      # midday: a festival may start
		eco.shop_raised["smithy"] = 0
		eco.shop_grown["smithy"] = 1
		eco._apply_shop_caps()
		_smithy_cam()
	if _f == 50:
		_shot("t5_smithy_before")
		# 1 the bands
		var bands := []
		for n in [1, 2, 7, 8, 12, 13, 19, 20]:
			bands.append(TwitchEventSub.roll_tier(n))
		_ok(bands == ["fumble", "bad", "bad", "mixed", "mixed", "good", "good", "crit"], "bands 1/2-7/8-12/13-19/20 -> %s" % str(bands))
		# 2 what the viewer typed picks the action
		_ok(String(_es.roll_intent("build the smithy please")["kind"]) == "build", "'build' -> build")
		_ok(String(_es.roll_intent("FESTIVAL!!")["kind"]) == "event", "'festival' -> event")
		var gl: Dictionary = _es.roll_intent("i vote for the gallows law")
		_ok(String(gl["kind"]) == "law" and String((gl.get("law", {}) as Dictionary).get("title", "")) == "The Gallows Law", "a law named by title -> that law")
		var fate := String(_es.roll_intent("")["kind"])
		_ok(fate in ["build", "event", "law"], "nothing typed -> fate picks (%s)" % fate)
		_ok((_es._roll_lore["laws"] as Array).size() >= 17 and ((_es._roll_lore["verdict"] as Dictionary).get("crit", []) as Array).size() > 0, "words read from lore_lines propositions + e3po.viewer_roll")
		# 3 BUILD, a 20: the smithy goes up two levels and the counter's ceiling with it
		var lv := eco.shop_level()
		var row := _es.viewer_roll("1001", "CoffeeCat", "build", 20, "750 points")
		print("    feed: ", (_t.get("feed") as Array).slice(-3))
		_ok(eco.shop_level() == mini(lv + 2, Economy.SHOP_MAX_LEVEL) and Roster.town_tier == eco.shop_level(), "build 20: smithy %d -> %d, ceiling %d" % [lv, eco.shop_level(), Roster.town_tier])
		_ok(String(row["tier"]) == "crit" and _feed_has("CoffeeCat rolls a 20 to raise the smithy - a triumph."), "Chronicle: 'CoffeeCat rolls a 20 to raise the smithy - a triumph.'")
		var crit_pool: Array = (_es._roll_lore["verdict"] as Dictionary)["crit"]
		var has_verdict := false
		for v in crit_pool:
			if String(row["result"]).ends_with(String(v)):
				has_verdict = true
		_ok(has_verdict, "the result carries the Commander's crit verdict")
	if _f == 80:
		_shot("t5_smithy_after_crit")
		# 4 BUILD, a 1: it backfires - timber burns, gold is paid, the smithy does not move
		var lv := eco.shop_level()
		eco.stock["wood"] = 100.0
		eco.treasury = 500
		var row := _es.viewer_roll("1002", "Grimble", "upgrade", 1)
		_ok(String(row["tier"]) == "fumble" and eco.shop_level() == lv and is_equal_approx(float(eco.stock["wood"]), 50.0) and eco.treasury == 460, "build 1 BACKFIRES: smithy stays %d, wood 100->%.0f, treasury 500->%d" % [lv, eco.stock["wood"], eco.treasury])
		_ok(_feed_has("Grimble rolls a 1 to raise the smithy - a fumble, and it backfires."), "Chronicle names the fumble")
		# 5 BUILD, a 5: it goes badly - a third of the timber wasted
		var row5 := _es.viewer_roll("1003", "Pell", "build", 5)
		_ok(String(row5["tier"]) == "bad" and is_equal_approx(float(eco.stock["wood"]), 35.0) and eco.shop_level() == lv, "build 5 goes badly: wood 50->%.0f, smithy unchanged" % eco.stock["wood"])
		# 6 EVENT, a 15: a festival in their name
		if bool(_t.get("festival")):
			_t.call("_end_festival")
		var nf := (_t.get("fest_log") as Array).size()
		var row6 := _es.viewer_roll("1004", "Marigold", "festival", 15)
		var fl: Array = _t.get("fest_log")
		_ok(String(row6["tier"]) == "good" and bool(_t.get("festival")) and fl.size() == nf + 1 and String((fl.back() as Array)[2]) == "Marigold", "event 15: a festival starts, paid for by Marigold")
		_square_cam()
	if _f == 140:
		_shot("t5_square_festival")
		# 7 EVENT, a 4: nobody comes, the feast food spoils
		eco.stock["food"] = 100.0
		var row7 := _es.viewer_roll("1005", "Tobble", "a feast", 4)
		_ok(String(row7["tier"]) == "bad" and is_equal_approx(float(eco.stock["food"]), 80.0), "event 4 goes badly: food 100->%.0f" % eco.stock["food"])
		# 8 LAW: renown moves both ways, and the law's own consequence is the line
		eco.renown = 5
		var row8 := _es.viewer_roll("1006", "Wren", "Debtors' Pardon", 17)
		_ok(eco.renown == 6 and String(row8["result"]).begins_with("Debtors' Pardon passes. The poor breathe again"), "law 17: renown 5->6, the law's good line")
		var row9 := _es.viewer_roll("1007", "Wren", "Debtors' Pardon", 3)
		_ok(eco.renown == 5 and String(row9["result"]).contains("The lenders shut their purses"), "law 3: renown 6->5, the law's bad line")
		_ok(String(row9["what"]) == "Push Debtors' Pardon", "what = 'Push Debtors' Pardon'")
		# 9 a real redemption event: no hero needed, input read, points settled (offline)
		_es.reward_ids = {"roll": "rid-roll"}
		var before := _es.rolls.size()
		_es.handle_event("channel.channel_points_custom_reward_redemption.add", {
			"id": "red-1", "user_id": "424242", "user_login": "nohero", "user_name": "NoHeroYet",
			"user_input": "build", "reward": {"id": "rid-roll", "title": "Roll for Bellmire", "cost": 750}})
		var top: Dictionary = _es.rolls[0] if not _es.rolls.is_empty() else {}
		_ok(_es.rolls.size() == before + 1 and String(top.get("by", "")) == "NoHeroYet" and String(top.get("kind", "")) == "build" and String(top.get("cost", "")) == "750 points", "redemption rolls for a viewer with NO hero: %s" % str(top))
		_ok(not _feed_has("NoHeroYet calls for the spotlight, but has no hero"), "no 'enlist first' refusal for a roll")
		# 10 the snapshot publishes it, hostile name cleaned
		_es.viewer_roll("1008", "<img src=x onerror=alert(1)>\u0007Bad", "festival", 10)
		var snap := SnapshotPublisher.new()
		snap.town = _t
		var p: Dictionary = snap.build_payload()
		var rs: Array = p.get("rolls", [])
		_ok(int(p["v"]) == 4 and rs.size() == _es.rolls.size() and rs.size() <= 20, "payload v4 carries rolls (%d)" % rs.size())
		var r0: Dictionary = rs[0] if not rs.is_empty() else {}
		_ok(int(r0.get("n", 0)) == 10 and String(r0.get("tier", "")) == "mixed" and not String(r0.get("by", "")).contains("<") and not String(r0.get("by", "")).contains("\u0007") and String(r0.get("by", "")).length() <= 25, "newest first, hostile name cleaned: %s" % String(r0.get("by", "")))
		var shape_ok := true
		for r in rs:
			for k in ["n", "by", "what", "result", "cost", "at"]:
				if not (r as Dictionary).has(k):
					shape_ok = false
			if not String((r as Dictionary).get("tier", "")) in ["crit", "good", "mixed", "bad", "fumble"]:
				shape_ok = false
			if int((r as Dictionary)["n"]) < 1 or int((r as Dictionary)["n"]) > 20 or String((r as Dictionary)["result"]).ends_with("…"):
				shape_ok = false
		_ok(shape_ok, "every row: n 1-20, by/what/result/cost/at, whitelisted tier, result never cut")
		print(JSON.stringify(rs.slice(0, 3), "  "))
		var fails := 0
		for r in rs:
			if String((r as Dictionary)["tier"]) in ["bad", "fumble"]:
				fails += 1
		_ok(fails >= 3, "failure outcomes demonstrated, not only successes (%d)" % fails)
		print("T5_ROLL %s %d/%d" % ["OK" if _fails.is_empty() else "FAIL", _checks - _fails.size(), _checks])
		for x in _fails:
			print("  FAILED: ", x)
		return true
	return false
