extends SceneTree
var _t: Node3D
var _f := 0
func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
func _process(_d: float) -> bool:
	_f += 1
	if _f < 10: return false
	var plots: Array = _t.get("plots")
	var n_on := 0
	for pl in plots:
		if not pl.has("node"): continue
		if bool(_t.call("_rect_on_road", _t.call("_rect", pl))):
			n_on += 1
			var keys := []
			for k in ["landmark","shop","tower","back","special","district","shape"]:
				if pl.has(k): keys.append("%s=%s" % [k, str(pl[k])])
			var p: Vector3 = pl["pos"]
			print("ONROAD (%d,%d) flags: %s" % [int(p.x), int(p.z), ", ".join(keys)])
	print("TOTAL on-road plots-with-node: %d  (plots=%d)" % [n_on, plots.size()])
	return true
