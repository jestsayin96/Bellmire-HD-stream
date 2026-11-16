extends SceneTree
## D91d: map the north-houses pocket at (33.6, -70.3) - every solid footprint near it and an
## ASCII map of where a body centre may stand (solid_at with FOOT_R), so the source can be fixed.
var _t: Node3D
var _f := 0
var C := Vector2(33.6, -70.3)
func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	if OS.get_environment("POCKET_AT") != "":
		var a := OS.get_environment("POCKET_AT").split(",")
		C = Vector2(float(a[0]), float(a[1]))
func _process(_d: float) -> bool:
	_f += 1
	if _f < 120:
		return false
	var srs: Array = _t.get("_solid_rects")
	var nf: int = int(_t.get("crevices_closed"))
	for i in range(srs.size() - nf, srs.size()):
		if (srs[i][0] as Vector2).distance_to(C) < 9.0:
			print("FILLER c=", srs[i][0], " he=", srs[i][3])
	var grid: Dictionary = _t.call("_solid_grid")
	var seen := {}
	for k in grid:
		for r in grid[k]:
			var c: Vector2 = r[0]
			if c.distance_to(C) < 9.0 and not seen.has(str(r)):
				seen[str(r)] = true
				print("RECT c=", c, " ax=", r[1], " he=", r[3])
	for p in _t.get("plots"):
		var pp: Vector3 = p["pos"]
		if Vector2(pp.x, pp.z).distance_to(C) < 12.0:
			print("PLOT ", p.get("kind", "?"), " pos=", pp, " yaw=", p.get("yaw"), " door=", _t.call("_door", p), " door_in=", p.get("door_in"))
	var st: Array = [_t]
	while not st.is_empty():
		var n: Node = st.pop_back()
		for ch in n.get_children():
			st.append(ch)
		if n is Node3D and n != _t:
			var gp: Vector3 = (n as Node3D).global_position
			for q in [Vector2(34.90924, -69.94432), Vector2(30.92458, -70.5061)]:
				if Vector2(gp.x, gp.z).distance_to(q) < 1.2 and n.get_parent() == _t:
					print("NODE near ", q, ": ", n.name, " ", n.scene_file_path, " at ", gp, " rotY=", (n as Node3D).rotation.y, " meta=", n.get_meta_list())
	var nav = _t.get("nav")
	for zi in range(-30, 31):
		var z := C.y + float(zi) * 0.2
		var line := "%7.1f " % z
		for xi in range(-30, 31):
			var x := C.x + float(xi) * 0.2
			var q := Vector3(x, 0, z)
			line += "#" if not (_t.call("solid_at", q, 0.15) as Array).is_empty() else ("+" if xi == 0 and zi == 0 else ".")
		print(line)
	print("CREVICES_CLOSED ", _t.get("crevices_closed"), " of ", (_t.get("_crevice_goods") as Array).size())
	quit()
	return true
