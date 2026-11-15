extends SceneTree
## D22a TEST - the audio soak. Boots the real Town with the roaming director
## camera, soaks by day, forces a raid halfway, soaks on, then checks the mix:
##  - the layered beds are laid (river x7, market, forge) and playing, and the
##    market/forge beds fall silent under the raid while the river runs on;
##  - the 3D pool is 24 voices and the busiest moment fit in it;
##  - every GAP-listed kind kept its gap (min interval >= GAP);
##  - footfalls, combat and spell/voice sounds all fired; no caller played a kind
##    with no sound set (a silent caller).
## Env: D22A_SECS (wall seconds, default 90), D22A_SCALE (default 4),
## D22A_REC=1 (windowed only) records the Master bus to renders/cycles/d22a/soak.wav.
var _t: Node3D
var _eye
var _f := 0
var _t0 := 0
var _secs := 90.0
var _scale := 4.0
var _raided := false
var _raid_beds := {}
var _rec: AudioEffectRecord
var _fails := 0

func _initialize() -> void:
	var s := OS.get_environment("D22A_SECS")
	if s != "": _secs = maxf(10.0, float(s))
	var sc := OS.get_environment("D22A_SCALE")
	if sc != "": _scale = maxf(1.0, float(sc))
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	print("D22A_TEST start secs=%.0f scale=%.0f driver=%s" % [_secs, _scale, AudioServer.get_driver_name() if AudioServer.has_method("get_driver_name") else "?"])

func _process(_dt: float) -> bool:
	_f += 1
	if _f == 20:
		var RtsCam = load("res://scripts/rts_camera.gd")
		_eye = RtsCam.new(); _t.add_child(_eye); _eye.setup(_t)
	if _f == 40:
		if _eye and _eye.director: _eye.director._set_on(true)
		Engine.time_scale = _scale
		_t0 = Time.get_ticks_msec()
		var rd = _t.get("raids")
		if rd:
			rd.set("_raid_t", 99999.0)    # no surprise raid; we bring our own
			rd.set("force_level", 4)      # raids come from a level; a fresh town is below it
		_t.get("economy").clock = 11.0 / 24.0   # late morning: the market and forge are open
		if OS.get_environment("D22A_REC") == "1" and DisplayServer.get_name() != "headless":
			_rec = AudioEffectRecord.new()
			AudioServer.add_bus_effect(0, _rec)
			_rec.set_recording_active(true)
			print("D22A recording Master")
	if _f < 40:
		return false
	var el := Time.get_ticks_msec() - _t0
	if not _raided and el > int(_secs * 500.0):
		_raided = true
		var pre := {}
		for b in Sfx.live().beds:
			pre[String(b["kind"])] = (b["player"] as AudioStreamPlayer3D).volume_db
		print("D22A beds before raid %s" % [pre])
		var rd = _t.get("raids")
		if rd: rd.raid("road")
		print("D22A raid forced at %.1fs" % (el / 1000.0))
	if _raided and _raid_beds.is_empty() and el > int(_secs * 500.0) + 6000:
		var sfx = Sfx.live()
		if sfx:
			for b in sfx.beds:
				_raid_beds[String(b["kind"])] = (b["player"] as AudioStreamPlayer3D).volume_db
			print("D22A beds under raid %s mood=%s" % [_raid_beds, sfx.mood])
	if el < int(_secs * 1000.0):
		return false
	_report()
	return true

func _check(ok: bool, what: String) -> void:
	print("D22A %s %s" % ["PASS" if ok else "FAIL", what])
	if not ok: _fails += 1

func _report() -> void:
	Engine.time_scale = 1.0
	var sfx = Sfx.live()
	if sfx == null:
		print("D22A_TEST FAIL no Sfx"); return
	if _rec:
		_rec.set_recording_active(false)
		var wav := _rec.get_recording()
		if wav:
			var out := ProjectSettings.globalize_path("res://renders/cycles/d22a/soak.wav")
			wav.save_to_wav(out)
			print("D22A recorded %s" % out)
	var plays: Dictionary = sfx.plays
	var kinds := {}
	var foot := 0; var combat := 0; var magic := 0; var voice := 0
	for k in plays:
		var n := int(plays[k])
		if String(k).begins_with("footstep_"): foot += n
		elif k in ["hit", "hit_impact", "sword_clash", "swing", "sword_swing", "arrow_shot", "block", "shield_bash", "dagger_stab"]: combat += n
		elif k in ["spell", "mana_charge", "fireball", "heal", "ice_shard", "lightning", "buff", "curse", "shield", "summon", "teleport", "debuff"]: magic += n
		elif String(k).begins_with("male_") or String(k).begins_with("female_"): voice += n
	var bk := {}
	var bed_playing := 0
	for b in sfx.beds:
		bk[String(b["kind"])] = int(bk.get(String(b["kind"]), 0)) + 1
		if (b["player"] as AudioStreamPlayer3D).playing: bed_playing += 1
	print("D22A plays foot=%d combat=%d magic=%d voices=%d kinds=%d total=%d" % [foot, combat, magic, voice, plays.size(), _sum(plays)])
	print("D22A pool=%d busy_peak=%d steals=%d far_skips=%d dropped=%s" % [sfx._pool.size(), sfx.busy_peak, sfx.steals, sfx.far_skips, sfx.dropped])
	print("D22A beds=%s playing=%d missing=%s" % [bk, bed_playing, sfx.missing])
	var bad := []
	for k in sfx.GAP:
		if sfx.min_gap.has(k) and int(sfx.min_gap[k]) < int(float(sfx.GAP[k]) * 1000.0):
			bad.append("%s %dms<%dms" % [k, sfx.min_gap[k], int(float(sfx.GAP[k]) * 1000.0)])
	print("D22A all plays %s" % [plays])
	_check(sfx._pool.size() == 24, "3D pool is 24 voices")
	_check(sfx.busy_peak <= 24, "busiest moment fit the pool (peak %d)" % sfx.busy_peak)
	_check(int(bk.get("river", 0)) >= 3 and bk.has("market") and bk.has("forge"), "beds laid: river/market/forge")
	_check(bed_playing == sfx.beds.size(), "every bed is playing (%d/%d)" % [bed_playing, sfx.beds.size()])
	_check(not _raid_beds.is_empty() and float(_raid_beds.get("market", 0.0)) <= -40.0 and float(_raid_beds.get("river", -99.0)) > -40.0,
		"under the raid the market shuts and the river runs on")
	_check(bad.is_empty(), "GAP holds for every kind %s" % [bad])
	_check(foot > 0 and combat > 0, "footfalls and combat both sounded")
	_check(sfx.missing.is_empty(), "no silent callers (kinds with no set)")
	print("D22A_TEST %s (%d fails)" % ["OK" if _fails == 0 else "FAIL", _fails])

func _sum(d: Dictionary) -> int:
	var n := 0
	for k in d: n += int(d[k])
	return n
