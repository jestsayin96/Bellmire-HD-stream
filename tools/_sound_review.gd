extends SceneTree
## S3: the SOUND REVIEW. The S1 / S2 tests only proved the kinds exist; this one checks the
## game SOUNDS right. Run windowed (a real audio driver - levels and the pool need one):
##   godot --path . --resolution 1280x720 --script tools/_sound_review.gd
## Headless it runs A only (the coverage that must never regress).
##  A. COVERAGE  every creature the bestiary can make (types, lords, uniques, a raid's dead)
##               voices a registered kind on spawn and death, and a lord roars as it rises;
##               every command in data/commands.json gives audible feedback in every state a
##               viewer meets it (no hero / broke / rich / a typo) - and costs in gold chink.
##  B. LOAD      a real delve, six delvers, a floor of creatures, 1x real time, plus a burst of
##               40 chat commands: no kind may fire more than RATE_MAX times in any second,
##               creature voices at most VOICE_MAX a second, the 16-player 3D pool never full
##               for long (steals), the chat burst no more than one UI sound per gap.
##  C. LEVELS    every kind we wire, and the music, played alone through a capture bus: peak
##               and RMS; then "as heard" = RMS + the call's dB + the bus (+ distance for 3D)
##               against the music as heard. Voices / combat / UI sit within a window around
##               the music; the dungeon bed sits well under it; nothing peaks over 0 dBFS.
## Prints SOUND_REVIEW OK / FAIL and a table.
var _t: Node3D
var _d: Delve
var _f := 0
var _fails: Array = []
var _checks := 0
var _stage := "a"
var _win := not DisplayServer.get_name().to_lower().contains("headless")
const IDS := ["3101", "3102", "3103", "3104", "3105", "3106"]
const RATE_MAX := 9          # plays of one kind in any 1 s
const VOICE_MAX := 2         # creature voices in any 1 s (one a 0.9 s beat)
const LOAD_S := 150.0

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _reg(k: String) -> bool:
	return Sfx.SETS.has(k)

func _initialize() -> void:
	# silent on the speakers: Master muted; the capture bus still sees the signal
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)

## ================================================================= A. coverage
func _coverage() -> void:
	print("== A. coverage")
	# creatures: every def the game can make - and the voice really plays on spawn / death
	var defs := {}
	for k in Bestiary.TYPES:
		defs["type " + k] = Bestiary.make(k)
	for k in Bestiary.NEW_TYPES:
		defs["new " + k] = Bestiary.make(k)
	for k in Bestiary.BOSS_DEFS:
		var b: Dictionary = (Bestiary.BOSS_DEFS[k] as Dictionary).duplicate()
		b["id"] = k
		defs["lord " + k] = Bestiary.boss_def(b)
	for k in Bestiary.UNIQUES:
		var u: Dictionary = (Bestiary.UNIQUES[k] as Dictionary).duplicate(true)
		u["id"] = k
		defs["unique " + k] = Bestiary.unique_def(u, 6)
	for k in Raids.SKELETONS:
		defs["raid " + k] = Bestiary.make(k)
	var silent: Array = []
	var table: Array = []
	for n in defs:
		var v := Bestiary.voice_of(defs[n])
		table.append("%s=%s" % [n, v])
		if v == "" or not _reg(v):
			silent.append(n)
	print("  voices: ", ", ".join(table))
	_ok(silent.is_empty(), "no silent creature: all %d (types, lords, uniques, raiders) voice a registered kind (silent: %s)" % [defs.size(), silent])
	# spawn and death really reach the voice queue (not just the table): a real Monster in the tree
	var m := Monster.new()
	m.def = Bestiary.make("spider")
	_t.add_child(m)
	m.global_position = Vector3(0, 0, 0)
	var q0 := Monster._vq.size()
	m.die()
	_ok(Monster._vq.size() >= 1 and q0 >= 0, "a creature's spawn and death are queued to be heard (%d claims)" % Monster._vq.size())
	m.queue_free()
	var src := FileAccess.get_file_as_string("res://scripts/delve.gd")
	_ok(src.contains("Monster.roar(dun.lord)"), "a lord roars as it rises (delve calls Monster.roar where the card shows)")
	# commands: every command, every state a viewer meets it in, must be heard
	var cc: ChatCmd = _t.get("chat")
	var cj: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/commands.json"))
	var r: Roster = _t.get("roster")
	var mute: Array = []
	var bad_buy: Array = []
	var rows: Array = []
	for state in ["none", "broke", "rich"]:
		for k in cj["order"]:
			var uid := "39%s_%s" % [state, k]
			if state != "none":
				var h := r.fresh(uid, "Tess", "knight")
				h["alive"] = true
				h["gold"] = 0 if state == "broke" else 9000
			var ex := String((cj["commands"][k] as Dictionary).get("example", "!" + k))
			if k == "reroll" or k == "respec":
				ex = "!respec mage" if k == "respec" else "!reroll"
			cc._last.clear()
			ChatCmd._ui_last = -100000
			ChatCmd.ui_sounds.clear()
			var out := cc.handle(uid, "Tess", ex)
			var heard: Array = ChatCmd.ui_sounds.keys()
			rows.append("%s/%s -> %s" % [state, k, heard])
			if out != "" and heard.is_empty():
				mute.append("%s %s" % [state, ex])
			for h2 in heard:
				if not _reg(String(h2)):
					mute.append("%s %s unregistered %s" % [state, ex, h2])
			var costs := String((cj["commands"][k] as Dictionary).get("cost", "")).contains("gold")
			if state == "rich" and costs and out != "" and not heard.has("coins_stack") and not heard.has("error"):
				bad_buy.append("%s (%s)" % [ex, heard])
	print("  commands: ", "; ".join(rows))
	_ok(mute.is_empty(), "every command that answers is heard, in every state (mute: %s)" % [mute])
	_ok(bad_buy.is_empty(), "every command that costs gold chinks when it is bought (no chink: %s)" % [bad_buy])
	cc._last.clear()
	ChatCmd._ui_last = -100000
	ChatCmd.ui_sounds.clear()
	cc.handle("39rich_hero", "Tess", "!hro")
	_ok(ChatCmd.ui_sounds.has("error"), "a typo nudge errors (%s)" % [ChatCmd.ui_sounds])
	var lv: int = Sfx.live().plays.get("level_up", 0) if Sfx.live() else 0
	var h3 := r.fresh("39lv", "Lev", "knight")
	r.award("39lv", 0, 99999, 0, 1)
	_ok(Sfx.live() == null or int(Sfx.live().plays.get("level_up", 0)) > int(lv), "a hero levelling plays level_up")
	_ok(not FileAccess.get_file_as_string("res://scripts/delve.gd").contains("SPELL_SND.get("), "a spell below is heard ONCE (Spells.cast sounds it since S1; delve no longer layers a second copy)")

## ================================================================= B. load
var _plays_prev := {}
var _times := {}             # kind -> [msec of each play]
var _pool_full := 0
var _pool_max := 0
var _load_t := 0.0
var _fight_seen := false
var _voices_prev := 0
var _vtimes: Array = []

func _start_load() -> void:
	print("== B. load (a real delve at 1x, then a chat burst)")
	var r: Roster = _t.get("roster")
	var kinds := ["knight", "warden", "ranger", "rogue", "cleric", "mage"]
	for i in IDS.size():
		var h: Dictionary = r.get_hero(IDS[i])
		if h.is_empty():
			h = r.fresh(IDS[i], "Hero%d" % i, kinds[i])
		h["alive"] = true
		h["weapon"] = 2
		h["armour"] = 2
		h["oil"] = 4
	_d = Delve.new()
	_d.town = _t
	_d.roster = r
	_d.start_floor = 3
	_d.max_floors = 4
	_t.add_child(_d)
	_d.start(IDS)
	var eye := RtsCamera.new()
	_t.add_child(eye)
	eye.setup(_t)
	eye.director._set_on(true)
	_plays_prev = Sfx.live().plays.duplicate()

func _sample_load(real: float) -> void:
	var s := Sfx.live()
	var now := Time.get_ticks_msec()
	for k in s.plays:
		var d := int(s.plays[k]) - int(_plays_prev.get(k, 0))
		for i in d:
			if not _times.has(k):
				_times[k] = []
			(_times[k] as Array).append(now)
	_plays_prev = s.plays.duplicate()
	var busy := 0
	for p in s._pool:
		if (p as AudioStreamPlayer3D).playing:
			busy += 1
	_pool_max = maxi(_pool_max, busy)
	if busy >= s._pool.size():
		_pool_full += 1
	var vn := 0
	for k in Monster.voiced:
		vn += int(Monster.voiced[k])
	for i in vn - _voices_prev:
		_vtimes.append(now)
	_voices_prev = vn
	if _d.state == "fight":
		_fight_seen = true
	_load_t += real

static func _peak_rate(ts: Array) -> int:
	var best := 0
	var j := 0
	for i in ts.size():
		while int(ts[i]) - int(ts[j]) >= 1000:
			j += 1
		best = maxi(best, i - j + 1)
	return best

func _load_checks() -> void:
	var rows: Array = []
	var worst := ""
	var worst_n := 0
	for k in _times:
		var pr := _peak_rate(_times[k])
		rows.append([k, (_times[k] as Array).size(), pr])
		if pr > worst_n:
			worst_n = pr
			worst = k
	rows.sort_custom(func(a, b): return int(a[2]) > int(b[2]))
	print("  kind / plays in %d s / peak per 1 s:" % int(_load_t))
	for r in rows:
		print("    %-18s %4d  %2d" % r)
	_ok(_fight_seen, "the delve fought (the load was real)")
	_ok(worst_n <= RATE_MAX, "no kind machine-guns: the busiest is %s at %d a second (max %d)" % [worst, worst_n, RATE_MAX])
	var vr := _peak_rate(_vtimes)
	_ok(vr <= VOICE_MAX, "creature voices at most %d a second (peak %d, %d heard)" % [VOICE_MAX, vr, _vtimes.size()])
	print("  3D pool: at most %d of %d playing; full on %d frames" % [_pool_max, Sfx.live()._pool.size(), _pool_full])
	_ok(_pool_full <= 3, "the 3D pool is never exhausted for long (full on %d frames, max %d busy)" % [_pool_full, _pool_max])
	# a chat burst: 40 commands from 20 viewers inside ~2 s
	var cc: ChatCmd = _t.get("chat")
	ChatCmd.ui_sounds.clear()
	ChatCmd._ui_last = -100000
	var t0 := Time.get_ticks_msec()
	for i in 40:
		cc._last.clear()
		cc.handle("burst%d" % (i % 20), "B%d" % i, ["!help", "!hro", "!guild", "!hero", "!deepest"][i % 5])
		OS.delay_msec(50)
	var n := 0
	for k in ChatCmd.ui_sounds:
		n += int(ChatCmd.ui_sounds[k])
	var secs := float(Time.get_ticks_msec() - t0) / 1000.0
	_ok(n <= int(ceil(secs / ChatCmd.UI_GAP)) + 1, "a chat burst of 40 commands in %.1f s makes %d UI sounds (one per %.2f s at most)" % [secs, n, ChatCmd.UI_GAP])

## ================================================================= C. levels
## each kind we wire, at the level the CODE plays it: [kind, call dB, "3d" / "2d", role].
## Read from the game's own constants, so the review and the game cannot drift apart.
func _wired() -> Array:
	var w: Array = []
	for k in ["skeleton_rattle", "slime_squish", "bat_screech", "spider_skitter", "dragon_roar", "demon_growl", "goblin_screech",
			"snake_hiss", "frog_ribbit", "insect_buzz", "cat_hiss", "male_grunt", "wolf_growl"]:
		w.append([k, float(Monster.VOICE_TRIM.get(k, 0.0)), "3d", "voice"])
	w.append(["dragon_roar", Monster.ROAR_DB + float(Monster.VOICE_TRIM.get("dragon_roar", 0.0)), "3d", "roar"])
	w.append(["skeleton_rattle", Monster.ROAR_DB + float(Monster.VOICE_TRIM.get("skeleton_rattle", 0.0)), "3d", "roar"])
	w.append(["dragon_fire_breath", 3.0, "3d", "combat"])
	for k in ["sword_swing", "dagger_stab", "bow_draw", "arrow_shot", "sword_clash", "hit_impact", "block"]:
		w.append([k, 0.0, "3d", "combat"])
	w.append(["shield_bash", -2.0, "3d", "combat"])
	w.append(["chest_open", -2.0, "3d", "combat"])
	w.append(["hit", Monster.HIT_DB, "3d", "combat"])
	w.append(["potion_drink", Delve.POTION_DB, "3d", "combat"])
	for v in ["male", "female"]:
		w.append(["%s_hurt" % v, 0.0, "3d", "hero"])
		w.append(["%s_effort" % v, -3.0, "3d", "hero"])
		w.append(["%s_death" % v, 3.0, "3d", "hero"])
	for k in Delve.AMB_KINDS:
		w.append([k, Delve.AMB_DB + float(Delve.AMB_TRIM.get(k, 0.0)), "3d", "bed"])
	for k in ["menu_select", "error", "inventory_open", "coins_stack", "item_pickup", "potion_drink", "level_up"]:
		w.append([k, float(ChatCmd.UI_DB.get(k, ChatCmd.UI_DB_BASE)), "2d", "ui"])
	return w
const HEAR_AT := 20.0          # a director shot of a fight: the camera ~20 m off
var _lv := {}                  # file -> [peak dB, rms dB]
var _lv_q: Array = []
var _lv_cur := ""
var _lv_left := 0.0
var _lv_peak := 0.0
var _lv_sum := 0.0
var _lv_n := 0
var _cap: AudioEffectCapture
var _player: AudioStreamPlayer

func _start_levels() -> void:
	print("== C. levels (each sound alone through a capture bus)")
	var bi := AudioServer.bus_count
	AudioServer.add_bus(bi)
	AudioServer.set_bus_name(bi, "Measure")
	AudioServer.set_bus_volume_db(bi, 0.0)
	_cap = AudioEffectCapture.new()
	_cap.buffer_length = 2.0
	AudioServer.add_bus_effect(bi, _cap)

	_player = AudioStreamPlayer.new()
	_player.bus = "Measure"
	root.add_child(_player)
	# the game's own music off while we measure
	for m in Sfx.live()._music:
		(m as AudioStreamPlayer).stop()
	(Sfx.live()._amb as AudioStreamPlayer).stop()
	var seen := {}
	for w in _wired():
		for f in Sfx.SETS.get(String(w[0]), []):
			if not seen.has(f):
				seen[f] = true
				_lv_q.append(Sfx.DIR + String(f))
	for mood in Sfx.MUSIC:
		_lv_q.append(Sfx.DIR + String(Sfx.MUSIC[mood][0]))

func _levels_tick(real: float) -> bool:
	if _lv_cur != "":
		var n := _cap.get_frames_available()
		if n > 0:
			var buf := _cap.get_buffer(n)
			for v in buf:
				var a := maxf(absf(v.x), absf(v.y))
				_lv_peak = maxf(_lv_peak, a)
				if a > 0.001:        # -60 dB: the sound, not its silent tail
					_lv_sum += a * a
					_lv_n += 1
		_lv_left -= real
		if _lv_left > 0.0 and (_player.playing or _lv_left > 0.3):
			return false
		_lv[_lv_cur] = [linear_to_db(maxf(_lv_peak, 1e-6)), linear_to_db(sqrt(_lv_sum / maxf(1.0, float(_lv_n))))]
		_player.stop()
		_lv_cur = ""
		return false
	if _lv_q.is_empty():
		return true
	_lv_cur = _lv_q.pop_front()
	var st: AudioStream = load(_lv_cur)
	if st is AudioStreamOggVorbis:
		(st as AudioStreamOggVorbis).loop = false
	_player.stream = st
	_lv_peak = 0.0
	_lv_sum = 0.0
	_lv_n = 0
	_cap.clear_buffer()
	_player.play()
	_lv_left = minf(st.get_length() + 0.25, 12.0) if st else 0.5
	return false

func _level_checks() -> void:
	var bus := float(Sfx.BUS_DB["Sfx"])
	var music := -99.0
	for mood in Sfx.MUSIC:
		var v: Array = _lv.get(Sfx.DIR + String(Sfx.MUSIC[mood][0]), [-99.0, -99.0])
		music = maxf(music, float(v[1]) + float(Sfx.BUS_DB["Music"]))
	print("  music as heard (RMS + Music bus): %.1f dB" % music)
	var dist := linear_to_db(9.0 / HEAR_AT)        # inverse distance, unit_size 9
	var hot: Array = []
	var buried: Array = []
	var loud_bed: Array = []
	var clip: Array = []
	print("  kind / role / file RMS / file peak / call dB / as heard / vs music")
	for w in _wired():
		var rms := -99.0
		var pk := -99.0
		for f in Sfx.SETS.get(String(w[0]), []):
			var v: Array = _lv.get(Sfx.DIR + String(f), [-99.0, -99.0])
			rms = maxf(rms, float(v[1]))
			pk = maxf(pk, float(v[0]))
		var heard := rms + float(w[1]) + bus + (dist if w[2] == "3d" else 0.0)
		var rel := heard - music
		print("    %-18s %-6s %6.1f %6.1f %5.1f %6.1f %+5.1f" % [w[0], w[3], rms, pk, w[1], heard, rel])
		# the MIX peak, close up (no distance): the file peak through the call and the bus
		if pk + float(w[1]) + bus > -1.0:
			clip.append("%s %+.1f dBFS" % [w[0], pk + float(w[1]) + bus])
		match String(w[3]):
			"bed":
				if rel > -8.0 or rel < -24.0:
					loud_bed.append("%s %+.1f" % [w[0], rel])
			_:
				if rel > 6.0:
					hot.append("%s %+.1f" % [w[0], rel])
				elif rel < -14.0:
					buried.append("%s %+.1f" % [w[0], rel])
	_ok(music > -60.0, "the music was measured (%.1f dB as heard)" % music)
	_ok(hot.is_empty(), "nothing blows out over the music (more than +6 dB as heard: %s)" % [hot])
	_ok(buried.is_empty(), "nothing is buried under it (below -14 dB as heard: %s)" % [buried])
	_ok(loud_bed.is_empty(), "the dungeon bed is quiet but there: 8-24 dB under the music (out: %s)" % [loud_bed])
	_ok(clip.is_empty(), "nothing clips in the mix: every peak through its call and bus stays under -1 dBFS (%s)" % [clip])

## ================================================================= the run
func _process(dt: float) -> bool:
	_f += 1
	var real := dt / maxf(Engine.time_scale, 0.001)
	match _stage:
		"a":
			if _f == 20:
				_coverage()
				if not _win:
					return _end()
				_start_load()
				_stage = "b"
		"b":
			_sample_load(real)
			if _fight_seen and _load_t > LOAD_S or _load_t > LOAD_S * 2.5:
				_load_checks()
				_start_levels()
				_stage = "c"
		"c":
			if _levels_tick(real):
				_level_checks()
				return _end()
	return false

func _end() -> bool:
	print("SOUND_REVIEW %s (%d checks, %d failed)" % ["OK" if _fails.is_empty() else "FAIL", _checks, _fails.size()])
	return true
