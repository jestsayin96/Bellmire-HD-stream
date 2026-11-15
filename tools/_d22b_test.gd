extends SceneTree
## D22b TEST - the music moods. Boots the real Town and walks the music through
## every mood on a script, at 1x so the fades run in real seconds:
##   day -> night (dusk) ; a 1 s flicker back to day must NOT move the music (HOLD) ;
##   night -> day (the day bed must RESUME, not restart) ; a raid (fast in) ; the raid
##   driven off (slow out + the victory sting) ; a delve (the lofi bed) ; the delve
##   lost with no survivors (the defeat sting) ; home -> day.
## Checks: the generated files are the ones playing, each transition used its own
## crossfade length, the crossfade is equal-power, the stings fired once each and a
## second sting inside STING_GAP is held back, no SCRIPT ERROR.
## Env: D22B_REC=1 (windowed only) records the Master bus to renders/cycles/d22b/moods.wav
## and writes renders/cycles/d22b/moods_marks.txt (second -> event) for the review picture.
var _t: Node3D
var _f := 0
var _t0 := 0
var _fails := 0
var _step := 0
var _marks: Array = []
var _rec: AudioEffectRecord
var _fake_delve: Node = null
var _mid_power := []
var _flap_n := -1
var _victory_at := -1
var _hour := 11.0              # the clock is PINNED to this every frame (a game day is short)

func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	print("D22B_TEST start")

func _el() -> float:
	return float(Time.get_ticks_msec() - _t0) / 1000.0

func _mark(what: String) -> void:
	_marks.append("%.2f %s" % [_el(), what])
	print("D22B %.1fs %s (mood=%s)" % [_el(), what, Sfx.live().mood if Sfx.live() else "?"])

func _clock(h: float) -> void:
	_hour = h
	_t.get("economy").clock = h / 24.0

func _process(_dt: float) -> bool:
	_f += 1
	if _f == 30:
		var rd = _t.get("raids")
		if rd:
			rd.set("_raid_t", 99999.0)
			rd.set("force_level", 4)
		_clock(11.0)
		if OS.get_environment("D22B_REC") == "1" and DisplayServer.get_name() != "headless":
			_rec = AudioEffectRecord.new()
			AudioServer.add_bus_effect(0, _rec)
			_rec.set_recording_active(true)
			print("D22B recording Master")
		_t0 = Time.get_ticks_msec()
		_mark("start, late morning")
	if _f <= 30:
		return false
	var sfx = Sfx.live()
	if sfx == null:
		print("D22B_TEST FAIL no Sfx"); return true
	var e := _el()
	_t.get("economy").clock = _hour / 24.0
	# sample the crossfade's power halfway through any running fade
	if sfx._fade > 0.0 and sfx._duck <= 0.0 and sfx._sting_duck <= 0.0 and absf(sfx._fade - sfx._fade_len * 0.5) < 0.05:
		var a := db_to_linear((sfx._music[sfx._cur] as AudioStreamPlayer).volume_db)
		var b := db_to_linear((sfx._music[1 - sfx._cur] as AudioStreamPlayer).volume_db)
		_mid_power.append(a * a + b * b)
	match _step:
		0:
			if e > 8.0:
				_clock(20.0); _mark("dusk (clock -> 20:00)"); _step = 1
		1:
			if e > 24.0:
				_flap_n = sfx.transitions.size()
				_clock(11.0); _mark("flicker to day for 1 s"); _step = 2
		2:
			if e > 25.0:
				_clock(20.0); _mark("flicker back to night"); _step = 3
		3:
			if e > 30.0:
				_check(sfx.transitions.size() == _flap_n and sfx.mood == "night", "a 1 s flicker did not move the music (HOLD)")
				_clock(11.0); _mark("dawn (clock -> 11:00)"); _step = 4
		4:
			if e > 44.0:
				var rd = _t.get("raids")
				rd.raid("road"); _mark("raid forced"); _step = 5
		5:
			if e > 60.0:
				var rd = _t.get("raids")
				for r in rd.raiders:
					if is_instance_valid(r["node"]): (r["node"] as Node).queue_free()
				rd.raiders.clear()
				_mark("raiders cleared - the raid is driven off"); _step = 6
		6:
			if sfx.stings.has("victory") and _victory_at < 0:
				_victory_at = Time.get_ticks_msec()
				Sfx.victory()        # a second sting inside STING_GAP must be held back
				_mark("victory sting heard")
			if e > 76.0:
				_fake_delve = Delve.new()
				_t.set("delve", _fake_delve)
				_mark("a delve goes below"); _step = 7
		7:
			if e > 96.0:
				_fake_delve.emit_signal("ended", [])
				_mark("the delve is lost - no survivors"); _step = 8
		8:
			if e > 99.0:
				_t.set("delve", null)
				_fake_delve.free()
				_mark("the delve is over"); _step = 9
		9:
			if e > 112.0:
				_report(); return true
	return false

func _check(ok: bool, what: String) -> void:
	print("D22B %s %s" % ["PASS" if ok else "FAIL", what])
	if not ok: _fails += 1

func _find(tr: Array, a: String, b: String) -> Dictionary:
	for x in tr:
		if String(x["from"]) == a and String(x["to"]) == b:
			return x
	return {}

func _report() -> void:
	var sfx = Sfx.live()
	if _rec:
		_rec.set_recording_active(false)
		var wav := _rec.get_recording()
		if wav:
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://renders/cycles/d22b"))
			wav.save_to_wav(ProjectSettings.globalize_path("res://renders/cycles/d22b/moods.wav"))
			var f := FileAccess.open("res://renders/cycles/d22b/moods_marks.txt", FileAccess.WRITE)
			for m in _marks: f.store_line(m)
			f.close()
			print("D22B recorded renders/cycles/d22b/moods.wav")
	var tr: Array = sfx.transitions
	var seq := []
	for x in tr:
		seq.append("%s>%s(%.1fs,@%.1f)" % [x["from"], x["to"], x["fade"], x["resumed"]])
	print("D22B transitions %s" % [seq])
	print("D22B stings %s skipped=%d mid_power=%s" % [sfx.stings, sfx.stings_skipped, _mid_power])
	print("D22B paths %s resume %s" % [sfx._paths, sfx._resume])
	for w in ["day", "night", "raid", "delve"]:
		var l: Array = sfx._music_list(w)
		_check(l.size() > 0 and String(l[0]).begins_with("music/bellmire_"), "%s plays the generated bed (%s)" % [w, l])
	for f in sfx.STINGS.values():
		_check(ResourceLoader.exists(sfx.DIR + String(f)), "sting file %s" % f)
	var dn := _find(tr, "day", "night")
	_check(not dn.is_empty() and is_equal_approx(float(dn["fade"]), 8.0), "day -> night, 8 s fade")
	var nd := _find(tr, "night", "day")
	_check(not nd.is_empty() and is_equal_approx(float(nd["fade"]), 8.0) and float(nd["resumed"]) > 1.0, "night -> day, 8 s fade, the day bed RESUMED (at %.1fs)" % (float(nd.get("resumed", 0.0))))
	var dr := _find(tr, "day", "raid")
	_check(not dr.is_empty() and is_equal_approx(float(dr["fade"]), 1.5) and float(dr["resumed"]) == 0.0, "day -> raid, 1.5 s fade, cue from the top")
	var rdy := _find(tr, "raid", "day")
	_check(not rdy.is_empty() and is_equal_approx(float(rdy["fade"]), 6.0), "raid -> day, 6 s fade")
	var dd := _find(tr, "day", "delve")
	_check(not dd.is_empty() and is_equal_approx(float(dd["fade"]), 5.0), "day -> delve, 5 s fade")
	var dvd := _find(tr, "delve", "day")
	_check(not dvd.is_empty() and is_equal_approx(float(dvd["fade"]), 5.0), "delve -> day, 5 s fade")
	_check(int(sfx.stings.get("victory", 0)) == 1, "the raid driven off played the victory sting once")
	_check(int(sfx.stings.get("defeat", 0)) == 1, "the lost delve played the defeat sting once")
	_check(sfx.stings_skipped >= 1, "a second sting inside STING_GAP was held back")
	var pw_ok := not _mid_power.is_empty()
	for p in _mid_power:
		if p < 0.85 or p > 1.15: pw_ok = false
	_check(pw_ok, "equal-power crossfade (power at mid-fade ~1.0: %s)" % [_mid_power])
	_check(sfx.mood == "day", "back to day at the end")
	print("D22B_TEST %s (%d fails)" % ["OK" if _fails == 0 else "FAIL", _fails])
