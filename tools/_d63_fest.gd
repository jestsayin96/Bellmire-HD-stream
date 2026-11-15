extends SceneTree
## D63 - THE FESTIVAL IS AN EVENT. Boots the REAL Bellmire, holds midday, enlists two
## heroes, walks one of them far from the square, then:
##  A  a market-day festival: the square DRESSES (pennants, poles, lanterns), the music
##     moves to "festival", the crowd DOES things (fest_dance/drink/haggle/cheer acts),
##     notables are sent, the far hero JOINS (comes within 14 m) and acts, goods SELL
##     (treasury up), a caravan is called in; it ends -> dressing struck, closing line,
##     music back to day.
##  B  a caused festival (level) opens with its own reason line; a raid-caused one is
##     refused inside FEST_GAP.
##  C  a VIEWER-BOUGHT festival through the real EventSub tier path (_do_bits_tier 500):
##     named for the (hostile-named, sanitised) buyer, longer than any timed one, dressed
##     bigger (more pennants, every lantern lit).
##  D  a gift bought DURING a raid waits, then starts when the raid is driven off.
## Prints D63_FEST OK. Writes renders/cycles/d63/fest_test.txt.
var _t: Node3D
var _f := 0
var _fails := 0
var _log: Array = []
var _phase := "boot"
var _mark := 0
var _far_uid := ""
var _treas0 := 0
var _mk := Vector3.ZERO
var _market_pennants := 0
var _feed0 := 0
var _acts0 := {}
var _caravan_called := false

func _check(name: String, ok: bool) -> void:
	var s := ("PASS " if ok else "FAIL ") + name
	print(s)
	_log.append(s)
	if not ok:
		_fails += 1

func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)

func _feed_since(n: int) -> Array:
	var fd: Array = _t.get("feed")
	return fd.slice(n)

func _process(_d: float) -> bool:
	_f += 1
	var eco = _t.get("economy")
	if eco and _f > 30:
		eco.clock = 0.50          # hold midday
		eco._dis_cool = 1e9       # no disaster mid-test
	var rd = _t.get("raids")
	if rd and _phase != "D_raid" and _f > 30:
		rd.set("_raid_t", 9999.0)  # no surprise raids; D brings its own
	match _phase:
		"boot":
			if _f == 600:
				_t.call("chat_line", "d63a", "D63Alda", "!enlist")
				_t.call("chat_line", "d63b", "D63Bram", "!enlist")
			if _f == 660:
				_mk = _t.get("_market_pos")
				var hs: Dictionary = _t.get("heroes")
				_check("0 two heroes raised", hs.has("d63a") and hs.has("d63b"))
				if hs.has("d63b"):
					_far_uid = "d63b"
					var b: HeroBody = hs["d63b"]
					var far: Vector3 = _t.call("keep_walkable", _mk + Vector3(38, 0, 6))
					b.global_position = Vector3(far.x, float(_t.call("height_at", far.x, far.z)), far.z)
					b.set("_idle_home", b.global_position)
					b.stay = true
					b._route = []
				_t.set("festival", false)
				_t.set("_fest_gap", 999.0)
				_treas0 = int(eco.treasury)
				_feed0 = (_t.get("feed") as Array).size()
				_acts0 = Townsfolk.acts.duplicate()
				_check("A0 market festival starts", bool(_t.call("start_festival", "market")))
				_market_pennants = int(_t.get("fest_dress_n"))
				var dr = _t.get("_fest_dress")
				_check("A1 square dressed (%d pennants, %d nodes)" % [_market_pennants, dr.get_child_count() if dr else 0],
					dr != null and _market_pennants >= 40 and dr.get_child_count() >= 8)
				_caravan_called = float(_t.get("_caravan_t")) <= 15.0 or not (_t.get("_caravans") as Array).is_empty()
				_check("A2 a caravan is called in", _caravan_called)
				_t.set("_fest_left", 999.0)
				_phase = "A_run"
				_mark = _f
		"A_run":
			if (_f - _mark) % 300 == 0:
				var hb: HeroBody = (_t.get("heroes") as Dictionary).get(_far_uid)
				if hb:
					print("D63DBG t=%d d=%.1f route=%d stay=%s errand='%s' idle_t=%.1f home=%s" % [_f - _mark,
						Vector2(hb.global_position.x - _mk.x, hb.global_position.z - _mk.z).length(),
						hb._route.size(), str(hb.stay), hb.errand, float(hb.get("_idle_t")), str(hb.get("_idle_home"))])
			# ~45 s at 60 fps; a strolling hero (D58 gait) still on the road gets up to 30 s more to arrive
			var hb2: HeroBody = (_t.get("heroes") as Dictionary).get(_far_uid)
			var dnow := Vector2(hb2.global_position.x - _mk.x, hb2.global_position.z - _mk.z).length() if hb2 else 999.0
			if _f - _mark >= 2700 and (dnow < 14.0 or _f - _mark >= 4500 or hb2 == null or hb2._route.is_empty()):
				var mood := Sfx.live().mood if Sfx.live() else "?"
				_check("A3 music lifts to festival (mood=%s)" % mood, mood == "festival")
				var kinds := {}
				for k in Townsfolk.acts.keys():
					if String(k).begins_with("fest_"):
						kinds[k] = int(Townsfolk.acts[k]) - int(_acts0.get(k, 0))
				var n_kinds := 0
				for k in kinds:
					if int(kinds[k]) > 0:
						n_kinds += 1
				_check("A4 the crowd does things %s" % str(kinds), n_kinds >= 3)
				var nb = _t.get("notables")
				_check("A5 notables sent to the square (%d)" % int(nb.get("fest_sent")), int(nb.get("fest_sent")) >= 3)
				var b: HeroBody = (_t.get("heroes") as Dictionary).get(_far_uid)
				var dd := Vector2(b.global_position.x - _mk.x, b.global_position.z - _mk.z).length() if b else 999.0
				_check("A6 the far hero joined the festival (%.1f m from the square)" % dd, dd < 14.0)
				_check("A7 heroes act at the festival (%d)" % HeroBody.fest_acts, HeroBody.fest_acts > 0)
				_check("A8 goods sold (%d lots, %d gold)" % [int(_t.get("fest_trades")), int(_t.get("fest_gold"))],
					int(_t.get("fest_trades")) >= 2 and int(eco.treasury) > _treas0 - 50)
				var n := (_t.get("feed") as Array).size()
				_t.set("_fest_left", 0.0)
				_phase = "A_end"
				_mark = _f
				_feed0 = n
		"A_end":
			if _f - _mark == 10:
				_check("A9 festival over, dressing struck", not bool(_t.get("festival")) and _t.get("_fest_dress") == null)
				var lines := _feed_since(_feed0)
				var closing := ""
				for l in lines:
					if "winds down" in String(l) or "festival" in String(l).to_lower() or "lots sold" in String(l):
						closing = String(l)
				_check("A10 closing line reports the trade: '%s'" % closing, "lots sold" in closing)
			if _f - _mark == 900:
				var mood := Sfx.live().mood if Sfx.live() else "?"
				_check("A11 music returns to the day bed (mood=%s)" % mood, mood == "day")
				# B: a caused festival names its reason; a raid one inside the gap is refused
				_t.set("_fest_gap", 0.0)
				_check("B1 raid-caused festival refused inside FEST_GAP", not bool(_t.call("start_festival", "raid")))
				_feed0 = (_t.get("feed") as Array).size()
				_check("B2 level festival starts", bool(_t.call("start_festival", "level")))
				var ln := String((_t.get("feed") as Array).back())
				_check("B3 its line names the reason: '%s'" % ln, ln != "" and not ("music, stalls, and a crowd" in ln))
				_t.call("_end_festival")
				# C: a viewer-bought festival via the real EventSub path
				var es := TwitchEventSub.new()
				es.set("town", _t)
				root.add_child(es)
				_feed0 = (_t.get("feed") as Array).size()
				es.call("_do_bits_tier", "d63a", 500, "Bad\u0007Buyer{town}<b>WithAVeryLongName")
				var fl := " | ".join(_feed_since(_feed0))
				_check("C1 a paid festival runs and is big", bool(_t.get("festival")) and bool(_t.get("fest_big")))
				_check("C2 it lasts longer than any timed one (%.0f s)" % float(_t.get("_fest_left")), float(_t.get("_fest_left")) >= 150.0)
				_check("C3 more dressing than the baseline (%d vs %d)" % [int(_t.get("fest_dress_n")), _market_pennants],
					int(_t.get("fest_dress_n")) > _market_pennants)
				var lit := 0
				for l in (_t.get("_fest_lights") as Array):
					if is_instance_valid(l) and (l as OmniLight3D).visible:
						lit += 1
				_check("C4 every lantern lit for a gift (%d)" % lit, lit >= 4)
				var buyer := String(_t.get("fest_buyer"))
				_check("C5 named for the buyer, sanitised and capped: '%s'" % buyer,
					buyer != "" and buyer.length() <= 25 and not ("{" in buyer) and not ("<" in buyer) and buyer.find(char(7)) < 0)
				_check("C6 the Chronicle names them: %s" % fl, buyer in fl)
				_t.call("_end_festival")
				# D: a gift during a raid waits for the raid to end
				rd.set("force_level", 5)
				rd.call("raid", "d63 test")
				_phase = "D_raid"
				_mark = _f
		"D_raid":
			if _f - _mark == 120:
				var ok := not bool(_t.call("start_festival", "gift", [], "D63Patron"))
				_check("D1 a gift under a raid waits (raid live=%s)" % str(rd.get("_live")), ok and not (_t.get("_fest_pending") as Dictionary).is_empty())
				for r in (rd.get("raiders") as Array).duplicate():
					rd.call("_raider_falls", r, "shot")
			if _f - _mark == 600:
				_check("D2 the waiting gift starts once the raid is driven off",
					bool(_t.get("festival")) and String(_t.get("fest_buyer")) == "D63Patron")
				_finish()
				return true
	if _f > 20000:
		_check("timeout", false)
		_finish()
		return true
	return false

func _finish() -> void:
	var out := ProjectSettings.globalize_path("res://renders/cycles/d63")
	DirAccess.make_dir_recursive_absolute(out)
	var f := FileAccess.open(out + "/fest_test.txt", FileAccess.WRITE)
	if f:
		f.store_string("\n".join(_log) + "\nfest_log " + str(_t.get("fest_log")) + "\n")
	print("FEST_LOG ", _t.get("fest_log"))
	print("D63_FEST OK" if _fails == 0 else "D63_FEST FAIL %d" % _fails)
