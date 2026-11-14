extends SceneTree
## D44b per-frame: which leg (townsfolk._dbg_leg) commits an in_solid position?
var _t: Node3D
var _f := 0
var _tally := {0:0, 1:0, 2:0, 3:0}
var _samples := 0
var _in := 0
var _ex: Array = []
var _houses: Array = []
func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
func _inside_rect(p: Vector3, r: Array, shrink: float) -> bool:
	var d := Vector2(p.x, p.z) - (r[0] as Vector2)
	var he: Vector2 = r[3]
	return absf(d.dot(r[1])) < he.x - shrink and absf(d.dot(r[2])) < he.y - shrink
func _house_rects() -> Array:
	var out: Array = []
	var hb: Dictionary = _t.get("_house_box")
	for plot in _t.get("plots"):
		var sh: String = String(plot.get("shape", "a"))
		if not hb.has(sh):
			continue
		var yaw: float = float(plot["yaw"])
		var ax := Vector2(cos(yaw), -sin(yaw))
		var az := Vector2(sin(yaw), cos(yaw))
		var pp: Vector3 = plot["pos"]
		var off: Vector2 = hb[sh][1]
		out.append([Vector2(pp.x, pp.z) + ax * off.x + az * off.y, ax, az, hb[sh][0]])
	return out
func _process(_d: float) -> bool:
	_f += 1
	if _f == 3:
		_houses = _house_rects()
	if _f > 120 and _f <= 6000:
		var rects: Array = _t.get("_solid_rects")
		for v in _t.get("people"):
			if v.inside or not v.visible:
				continue
			var p: Vector3 = v.global_position
			var ends: Array = [v.home, v.work, v.home_in, v.work_in, v._enter_at]
			for st in v.stops:
				ends.append(st[0])
			var near_end := false
			for e in ends:
				if e is Vector3 and e != Vector3.ZERO and Vector2(p.x - e.x, p.z - e.z).length() < 3.0:
					near_end = true
			if near_end or v._route.is_empty():
				continue
			_samples += 1
			var hit := false
			for r in _houses:
				if _inside_rect(p, r, 0.6):
					hit = true
					break
			if not hit:
				for r in rects:
					if _inside_rect(p, r, 0.15):
						hit = true
						break
			if hit:
				_in += 1
				var leg: int = int(v._dbg_leg)
				_tally[leg] = int(_tally.get(leg, 0)) + 1
				if _ex.size() < 30:
					_ex.append("leg=%d %s %s (%.1f,%.1f) r=%d" % [leg, v.role, v.person_name, p.x, p.z, v._route.size()])
	if _f >= 6000:
		print("D44_PERFRAME in_solid_frames=", _in, "/", _samples, " tally(0norm/1door/2seat/3ghost)=", _tally)
		print("EX ", _ex)
		return true
	return false
