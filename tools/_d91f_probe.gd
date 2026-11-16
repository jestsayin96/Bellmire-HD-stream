extends SceneTree
## D91f: print every store yard (origin, side, fwd), its house door, and every prop within 6 m of
## the D91e crush point (33.44,-71.14), in yard coordinates. Read-only.
var _t: Node3D
var _f := 0
func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
func _process(_d: float) -> bool:
	_f += 1
	if _f < 5:
		return false
	var P := Vector3(33.44, 0, -71.14)
	if OS.get_environment("D91F_P") != "":
		var xy := OS.get_environment("D91F_P").split(",")
		P = Vector3(float(xy[0]), 0, float(xy[1]))
	for plot in _t.get("plots"):
		if not plot.has("shop"):
			continue
		var y: Vector3 = plot["yard"]
		if String(plot["shop"]) != "store" and Vector2(y.x - P.x, y.z - P.z).length() > 12.0:
			continue
		var yaw: float = float(plot["yaw"])
		var f := Vector3(sin(yaw), 0, cos(yaw))
		var s: Vector3 = plot["side"]
		print("SHOP %s pos=%s yard=%s side=%s f=%s door=%s" % [plot["shop"], plot["pos"], y, s, f, plot.get("door", "-")])
		var rel := func(w: Vector3) -> String:
			var d := w - y
			return "(x=%.2f z=%.2f)" % [d.x * s.x + d.z * s.z, d.x * f.x + d.z * f.z]
		print("  crush at ", rel.call(P))
		for other in _t.get("plots"):
			if other.has("door") and Vector2((other["door"] as Vector3).x - P.x, (other["door"] as Vector3).z - P.z).length() < 6.0:
				print("  DOOR ", other["door"], " yard", rel.call(other["door"]), " shop=", other.get("shop", "-"))
		for c in _t.get_children():
			if c is Node3D and c.scene_file_path != "" and Vector2(c.position.x - P.x, c.position.z - P.z).length() < 6.0:
				print("  PROP %s at %s yard%s" % [c.scene_file_path.get_file(), c.position, rel.call(c.position)])
	print("ALL near crush:")
	for c in _t.get_children():
		if c is Node3D and Vector2(c.position.x - P.x, c.position.z - P.z).length() < 5.0:
			print("  NEAR %s %s at %s" % [c.name, c.scene_file_path.get_file(), c.position])
	for plot in _t.get("plots"):
		if plot.has("door") and Vector2((plot["door"] as Vector3).x - P.x, (plot["door"] as Vector3).z - P.z).length() < 6.0:
			print("  DOORPLOT pos=%s yaw=%s door=%s shop=%s" % [plot["pos"], plot["yaw"], plot["door"], plot.get("shop", "-")])
	return true
