extends SceneTree
## D91 TOWN HALF of the done test (game build, 2026-11-16).
##   D91T_MODE=soak : D91T_SECS of town (default 1200 = 20 min), EVERY body pair sampled EVERY
##                    frame: frames with two centres closer than the sum of their body_r, and
##                    bodies standing inside a registered solid footprint (houses, stalls,
##                    tables, bushes, trees, rocks - town.solid_at). Each fault is ATTRIBUTED
##                    (who, doing what, inside what) so a failure says where to look.
##   D91T_MODE=shot : windowed, the bushes and the crowd at the market, renders/cycles/d91c/
## A body on a seat (sat / its last step onto one / just risen from one, not yet stepped off) or on the door leg into a house is
## MEANT to be inside a footprint - the bench or the doorway - and is counted apart, not hidden.
const OUT := "res://renders/cycles/d91c/"
var _mode := "soak"
var _secs := 1200.0
var _t: Node3D
var _f := 0
var _game := 0.0
var _frames := 0
var _ov_frames := 0
var _ov_cm := 0
var _ov_pairs := 0
var _worst := 0.0
var _in_solid := 0
var _in_seat := 0
var _in_door := 0
var _checks := 0
var _maxn := 0
var _ov_by := {}
var _in_by := {}
var _what_by := {}
var _fail := 0
var _dbg := 0
var _dbg2 := 0

func _initialize() -> void:
	_mode = OS.get_environment("D91T_MODE") if OS.get_environment("D91T_MODE") != "" else "soak"
	if OS.get_environment("D91T_SECS") != "":
		_secs = float(OS.get_environment("D91T_SECS"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)

func _tag(b: Node) -> String:
	if b.get("kind") != null and b.get("role") == null:
		return "animal:" + String(b.get("kind"))
	var s := String(b.get("role")) if b.get("role") != null else String(b.name)
	if int(b.get("rank") if b.get("rank") != null else -1) >= 0:
		s = "hero"
	if b.get("_sat") == true:
		s += "/sat"
	elif int(b.get("_seat_i") if b.get("_seat_i") != null else -1) >= 0:
		s += "/to-seat"
	if b.get("stay") == true:
		s += "/post"
	if b.get("leader") != null and is_instance_valid(b.get("leader")):
		s += "/pair"
	if b.get("cart") != null:
		s += "/cart"
	if b.get("_at_fest") == true:
		s += "/fest"
	if b.get("_fleeing") == true:
		s += "/flee"
	return s

func _bodies() -> Array:
	var out: Array = []
	for o in _t.get("people"):
		if is_instance_valid(o) and (o as Node3D).visible and not o.get("inside") == true:
			out.append(o)
	for a in _t.get("animals"):
		if is_instance_valid(a) and (a as Node3D).visible and float(a.get("float_y")) == INF:
			out.append(a)
	return out

## the name of whatever registered the footprint r (nearest prop/scene to its centre)
func _what(r: Array) -> String:
	var he: Vector2 = r[3]
	if he.x > 2.2 or he.y > 2.2:
		return "house/large(%.1fx%.1f)" % [he.x * 2.0, he.y * 2.0]
	var c: Vector2 = r[0]
	var best := ""
	var bd := 3.0
	for ch in _t.get_children():
		if not (ch is Node3D):
			continue
		var p: Vector3 = (ch as Node3D).global_position
		var d := Vector2(p.x - c.x, p.z - c.y).length()
		if d < bd and String(ch.scene_file_path) != "":
			bd = d
			best = String(ch.scene_file_path).get_file().get_basename()
	return best if best != "" else "rect(%.1fx%.1f)" % [he.x * 2.0, he.y * 2.0]

func _sample() -> void:
	var bodies := _bodies()
	_maxn = maxi(_maxn, bodies.size())
	var grid := {}
	for b in bodies:
		var p: Vector3 = (b as Node3D).global_position
		var k := Vector2i(floori(p.x * 0.5), floori(p.z * 0.5))
		if not grid.has(k):
			grid[k] = []
		(grid[k] as Array).append(b)
	var any := false
	var cm := false
	for b in bodies:
		var a: Node3D = b
		var pa := a.global_position
		var ra := Crowd.body_r(a)
		var ka := Vector2i(floori(pa.x * 0.5), floori(pa.z * 0.5))
		for dx in range(-1, 2):
			for dz in range(-1, 2):
				var cell = grid.get(Vector2i(ka.x + dx, ka.y + dz))
				if cell == null:
					continue
				for o in cell:
					if o.get_instance_id() <= a.get_instance_id():
						continue
					var pb: Vector3 = (o as Node3D).global_position
					if absf(pa.y - pb.y) > 3.0:
						continue
					var L := Vector2(pa.x - pb.x, pa.z - pb.z).length()
					var ov := ra + Crowd.body_r(o) - L
					if ov > 0.0:
						any = true
						_ov_pairs += 1
						_worst = maxf(_worst, ov)
						if ov > 0.01:
							cm = true
						var ta := _tag(a)
						var tb := _tag(o)
						var key := (ta + " + " + tb) if ta < tb else (tb + " + " + ta)
						_ov_by[key] = int(_ov_by.get(key, 0)) + 1
						if _dbg2 < 10:
							_dbg2 += 1
							print("D91T_OV f=%d %s(leg%s) + %s(leg%s) at %s over %.2f" % [_frames, ta, str(a.get("_dbg_leg")), tb, str(o.get("_dbg_leg")), str(pa), ov])
	if any:
		_ov_frames += 1
	if cm:
		_ov_cm += 1
	for b in bodies:
		_checks += 1
		var r: Array = _t.call("solid_at", (b as Node3D).global_position, -0.05)
		if r.is_empty():
			continue
		var seat: bool = b.get("_sat") == true or b.get("_dbg_leg") == 2
		var door := int(b.get("_dbg_leg") if b.get("_dbg_leg") != null else 0) == 1
		if seat:
			_in_seat += 1
			continue
		if door:
			_in_door += 1
			continue
		_in_solid += 1
		if _dbg < 12 and b.get("_dbg_leg") == 0:
			_dbg += 1
			print("D91T_IN %s %s at %s wait=%.1f route=%d stuck_route" % [_tag(b), String(b.get("person_name")), str((b as Node3D).global_position), float(b.get("_wait")), (b.get("_route") as Array).size()])
		var tg := _tag(b) + ("/leg%d" % int(b.get("_dbg_leg")) if b.get("_dbg_leg") != null else "")
		_in_by[tg] = int(_in_by.get(tg, 0)) + 1
		if _what_by.size() < 400 or _what_by.has(tg):
			var w := _what(r)
			_what_by[w] = int(_what_by.get(w, 0)) + 1

func _top(d: Dictionary, n: int) -> String:
	var ks := d.keys()
	ks.sort_custom(func(x, y): return int(d[x]) > int(d[y]))
	var s := ""
	for i in range(mini(n, ks.size())):
		s += "\n    %6d  %s" % [int(d[ks[i]]), ks[i]]
	return s

func _report() -> void:
	print("D91 TOWN: %.0f s, %d frames, up to %d bodies on the street" % [_game, _frames, _maxn])
	print("  overlap frames %d (>1 cm: %d), overlapping pair-samples %d, worst %.3f m" % [_ov_frames, _ov_cm, _ov_pairs, _worst])
	print("  body-frames inside a footprint %d of %d (apart: %d on a seat, %d on a door leg)" % [_in_solid, _checks, _in_seat, _in_door])
	var sn := int(_t.get("settle_n"))
	print("  the late settle: %d runs, %.3f ms a run, %.2f ms a frame (%d set out of a footprint)" % [sn, float(_t.get("settle_us")) / maxf(1.0, float(sn)) / 1000.0, float(_t.get("settle_us")) / maxf(1.0, float(_f)) / 1000.0, int(_t.get("settled_out"))])
	print("  of which gathering + footprint sweep %.3f ms a run; %.2f passes a run" % [float(_t.get("settle_prep_us")) / maxf(1.0, float(sn)) / 1000.0, float(Crowd.passes_run) / maxf(1.0, float(sn))])
	print("  OVERLAPS BY WHO:" + _top(_ov_by, 25))
	print("  IN A FOOTPRINT BY WHO:" + _top(_in_by, 15))
	print("  IN A FOOTPRINT BY WHAT:" + _top(_what_by, 15))
	var ok := func(c: bool, what: String) -> void:
		print(("  ok   " if c else "  FAIL ") + what)
		if not c:
			_fail += 1
	ok.call(_frames > 1000, "the soak ran (%d frames)" % _frames)
	ok.call(_ov_cm == 0, "no frame with two bodies closer than the sum of their body_r by more than 1 cm (%d)" % _ov_cm)
	ok.call(_ov_frames == 0, "no frame with any overlap at all (%d, worst %.4f m)" % [_ov_frames, _worst])
	ok.call(_in_solid == 0, "no body inside a registered footprint (%d body-frames)" % _in_solid)
	print("D91_TOWN %s (%d failed)" % ["OK" if _fail == 0 else "FAIL", _fail])

func _process(delta: float) -> bool:
	_f += 1
	if _f < 120:
		return false
	_game += delta
	_frames += 1
	_sample()
	if _frames % 3000 == 0:
		print("  t=%.0fs frames=%d overlap_frames=%d (>1cm %d, worst %.3f) in_footprint=%d bodies<=%d" % [_game, _frames, _ov_frames, _ov_cm, _worst, _in_solid, _maxn])
	if _game >= _secs:
		_report()
		return true
	return false
