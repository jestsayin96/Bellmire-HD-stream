extends SceneTree
## D58 PROBE - gait quality on folk that ARE walking. Per sample (every 0.5 s,
## 30 s after warmup) for up to 10 ordinary walkers: measured speed (_vs), the
## clip, its speed_scale, and SLIP = ground speed / (clip m/s * speed_scale)
## (1.0 = feet planted; >1 skate forward, <1 moonwalk). Also counts walk<->jog
## flips per agent (clip snapping) and the cadence (speed_scale) distribution.
## --headless --script. Prints D58_PROBE lines.
var _t
var _f := 0
var _ids: Array = []
var _rows := {}
var _flips := {}
var _last := {}
func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
func _ordinary(p) -> bool:
	return p is Townsfolk and p.rank < 0 and not p.stay and p.cart == null and not p.inside
func _sample() -> void:
	if _ids.size() < 10:
		for p in _t.get("people"):
			if _ids.size() >= 10: break
			if is_instance_valid(p) and _ordinary(p) and float(p.get("_vs")) > 0.4 and not _ids.has(p.get_instance_id()):
				_ids.append(p.get_instance_id())
	for id in _ids:
		var p = instance_from_id(id)
		if p == null or not is_instance_valid(p): continue
		var ap: AnimationPlayer = p.get("_anim")
		if ap == null: continue
		var clip := String(ap.current_animation)
		var vs: float = float(p.get("_vs")) / maxf(float(p.size_k), 0.2)
		var sc: float = ap.speed_scale
		var slip := -1.0
		if Rig.GAIT_MPS.has(clip):
			slip = vs / (float(Rig.GAIT_MPS[clip]) * maxf(sc, 0.01))
		if not _rows.has(id): _rows[id] = []
		(_rows[id] as Array).append([vs, clip, sc, slip])
		var g := String(ap.get_meta("rig_gait", ""))
		if _last.has(id) and _last[id] != g: _flips[id] = int(_flips.get(id, 0)) + 1
		_last[id] = g
func _process(_dt: float) -> bool:
	_f += 1
	if _f >= 600 and _f % 30 == 0:
		_sample()
	if _f >= 600 + 60 * 30:
		_report()
		return true
	return false
func _report() -> void:
	var allv: Array = []; var alls: Array = []
	var slips := 0; var gaitn := 0; var cad_hi := 0
	var clips := {}
	for id in _rows:
		var rs: Array = _rows[id]
		var line := ""
		var mv := 0.0; var ms := 0.0; var n := 0
		for r in rs:
			clips[r[1]] = int(clips.get(r[1], 0)) + 1
			if r[3] >= 0.0:
				gaitn += 1
				allv.append(r[0]); alls.append(r[2])
				mv += r[0]; ms += r[2]; n += 1
				if absf(r[3] - 1.0) > 0.25: slips += 1
				if r[1] == "Walking_A" and r[2] > 1.5: cad_hi += 1
		var p = instance_from_id(id)
		var nm: String = String(p.person_name) if p and is_instance_valid(p) else "?"
		var tail := ""
		for i in range(0, rs.size(), 6):
			var r = rs[i]
			tail += " %.2f/%s/%.2f/%.2f" % [r[0], String(r[1]).substr(0, 9), r[2], r[3]]
		print("D58_PROBE agent %s n=%d mean_v=%.2f mean_scale=%.2f flips=%d |%s" % [nm, n, mv / maxf(n, 1), ms / maxf(n, 1), int(_flips.get(id, 0)), tail])
	# correlation v vs speed_scale
	var r := 0.0
	var N := allv.size()
	if N > 2:
		var ax := 0.0; var ay := 0.0
		for i in N: ax += allv[i]; ay += alls[i]
		ax /= N; ay /= N
		var sxy := 0.0; var sxx := 0.0; var syy := 0.0
		for i in N:
			sxy += (allv[i] - ax) * (alls[i] - ay); sxx += pow(allv[i] - ax, 2); syy += pow(alls[i] - ay, 2)
		r = sxy / sqrt(maxf(sxx * syy, 1e-9))
	var tf := 0
	for id in _flips: tf += int(_flips[id])
	print("D58_PROBE summary agents=%d gait_samples=%d corr(v,scale)=%.3f slip>25%%=%d walk_cadence>1.5=%d gait_flips=%d clips=%s" % [_rows.size(), gaitn, r, slips, cad_hi, tf, str(clips)])
	quit()
