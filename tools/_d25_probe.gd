extends SceneTree
## D25 WIDENED placement probe. Beyond D18a (which only tested mk_house/lm_ nodes),
## this collects oriented XZ footprints for EVERY visible substantial structure -
## town houses, growth SPECIALS (market hall / stables / guild / bathhouse / mage
## tower), valley cottages and barns - plus field rects (town._fields), and reports:
##   BLD  building-into-building overlaps (pen > tol)
##   FLD  a building standing on a field, or field-into-field
##   ROAD a town building footprint sitting on a paved road
## Exemptions: wall segments (continuous), the guild+its own house (coexist by
## design), a structure vs its own parent/child. Runs at the live town level and
## again at TOP level. Set D25_LEVEL to force a level. Prints D25_PROBE OK / FAIL.
var _t: Node3D
var _f := 0
const PEN_TOL := 0.6
const WALL_HE := Vector2(1.9, 1.1)

func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)

func _obb_of(n: Node3D) -> Array:
	var box := AABB(); var first := true
	var inv: Transform3D = n.global_transform.affine_inverse()
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		if m.mesh == null or not m.is_visible_in_tree(): continue
		var ab: AABB = (inv * m.global_transform) * m.mesh.get_aabb()
		box = ab if first else box.merge(ab); first = false
	if first: return []
	var sc: float = n.scale.x
	var he := Vector2(box.size.x, box.size.z) * 0.5 * sc
	var hgt: float = box.size.y * n.scale.y
	var yaw: float = n.global_rotation.y
	var ax := Vector2(cos(yaw), -sin(yaw))
	var az := Vector2(sin(yaw), cos(yaw))
	var cen := box.get_center() * sc
	var c2 := Vector2(n.global_position.x, n.global_position.z) + ax * cen.x + az * cen.z
	return [c2, ax, az, he, hgt]

func _field_obb(fe: Array) -> Array:
	var c: Vector3 = fe[0]; var fw: Vector3 = fe[1]; var sd: Vector3 = fe[2]
	var hw: float = fe[3]; var hd: float = fe[4]
	return [Vector2(c.x, c.z), Vector2(sd.x, sd.z), Vector2(fw.x, fw.z), Vector2(hw, hd), 0.0]

func _pen(a: Array, b: Array) -> float:
	var ca: Vector2 = a[0]; var cb: Vector2 = b[0]
	var axes := [a[1], a[2], b[1], b[2]]
	var d := cb - ca; var minp := 1e9
	for axv in axes:
		var ax: Vector2 = axv
		var ra: float = absf((a[1] as Vector2).dot(ax)) * (a[3] as Vector2).x + absf((a[2] as Vector2).dot(ax)) * (a[3] as Vector2).y
		var rb: float = absf((b[1] as Vector2).dot(ax)) * (b[3] as Vector2).x + absf((b[2] as Vector2).dot(ax)) * (b[3] as Vector2).y
		var pen: float = ra + rb - absf(d.dot(ax))
		if pen <= 0.0: return 0.0
		minp = minf(minp, pen)
	return minp

func _on_road(r: Array) -> bool:
	var c: Vector2 = r[0]; var ax: Vector2 = r[1]; var az: Vector2 = r[2]; var he: Vector2 = r[3]
	# shrink 0.6 m so eaves overhanging a kerb don't count; interior on paving does
	var ix: float = maxf(he.x - 0.6, 0.3); var iz: float = maxf(he.y - 0.6, 0.3)
	for i in range(5):
		for j in range(5):
			var q := c + ax * ix * (float(i) / 2.0 - 1.0) + az * iz * (float(j) / 2.0 - 1.0)
			if (_t.call("road_dist", Vector3(q.x, 0.0, q.y)) as float) < 0.2:
				return true
	return false

func _run_level(lv: int, growth) -> Dictionary:
	if growth:
		growth.show_level(lv, true)
	var items: Array = []   # [label, obb, root_node_or_null]
	# town houses (visible)
	for plot in _t.get("plots"):
		if not plot.has("node"): continue
		var h = plot["node"]
		if not is_instance_valid(h) or not (h as Node3D).visible: continue
		var ob := _obb_of(h)
		if ob.is_empty(): continue
		items.append(["house", ob, h, plot])
	# growth specials (visible)
	if growth:
		for key in growth.specials:
			var sp = growth.specials[key]
			var nd = sp["node"]
			if not is_instance_valid(nd) or not (nd as Node3D).visible: continue
			var ob2 := _obb_of(nd)
			if ob2.is_empty(): continue
			items.append([key, ob2, nd, sp["plot"]])
	# valley cottages + large structures
	var valley = _t.get("valley")
	if valley:
		for node in (valley as Node3D).find_children("*", "Node3D", false, false):
			var n2: Node3D = node
			var ob3 := _obb_of(n2)
			if ob3.is_empty(): continue
			# structure only: tall enough and wide enough (skip scarecrows, fences, crops, props)
			if float(ob3[4]) < 3.0: continue
			if maxf((ob3[3] as Vector2).x, (ob3[3] as Vector2).y) < 2.2: continue
			if minf((ob3[3] as Vector2).x, (ob3[3] as Vector2).y) < 1.2: continue
			items.append(["valley", ob3, n2, {}])
	# fields
	var fields: Array = []
	for fe in _t.get("_fields"):
		fields.append(_field_obb(fe))
	# ---- building vs building ----
	var bld_hits: Array = []
	for i in range(items.size()):
		for j in range(i + 1, items.size()):
			var A: Array = items[i]; var B: Array = items[j]
			# wall exempt
			if (A[1][3] as Vector2).is_equal_approx(WALL_HE) or (B[1][3] as Vector2).is_equal_approx(WALL_HE): continue
			# guild + its own house coexist: same plot
			var sameplot: bool = (A[3] is Dictionary and B[3] is Dictionary and not (A[3] as Dictionary).is_empty() and A[3] == B[3])
			if sameplot and (String(A[0]) == "guild" or String(B[0]) == "guild"): continue
			var pen := _pen(A[1], B[1])
			if pen > PEN_TOL:
				var c: Vector2 = A[1][0]
				bld_hits.append("%s <-> %s pen=%.2f at (%d,%d)" % [A[0], B[0], pen, int(c.x), int(c.y)])
	# ---- building vs field, field vs field ----
	var fld_hits: Array = []
	for i in range(items.size()):
		for fe in fields:
			var pen := _pen(items[i][1], fe)
			if pen > 1.2:   # a field edge can kiss a wall; flag only real intrusion
				var c: Vector2 = items[i][1][0]
				fld_hits.append("%s on FIELD pen=%.2f at (%d,%d)" % [items[i][0], pen, int(c.x), int(c.y)])
				break
	for i in range(fields.size()):
		for j in range(i + 1, fields.size()):
			var pen := _pen(fields[i], fields[j])
			if pen > 1.2:
				var c: Vector2 = fields[i][0]
				fld_hits.append("FIELD<->FIELD pen=%.2f at (%d,%d)" % [pen, int(c.x), int(c.y)])
	# ---- town building on road ----
	# Use the game's OWN structural footprint rule (_rect/_rect_on_road), which
	# measures the base house box - NOT the mesh AABB, which would include the
	# door-side hanging sign and planters that overhang the street by design.
	var road_hits: Array = []
	for it in items:
		if String(it[0]) == "valley": continue
		var plot = it[3]
		var on := false
		if plot is Dictionary and not (plot as Dictionary).is_empty() and (plot as Dictionary).has("pos"):
			var pd := plot as Dictionary
			# landmarks/shops/towers front a plaza or street by design (a forecourt,
			# a shopfront, a wall tower) - their footprint meeting paving is intended.
			if pd.has("landmark") or pd.has("shop") or pd.has("tower"):
				on = false
			else:
				on = bool(_t.call("_rect_on_road", _t.call("_rect", plot)))
		else:
			on = _on_road(it[1])
		if on:
			var c: Vector2 = it[1][0]
			road_hits.append("%s ON ROAD at (%d,%d)" % [it[0], int(c.x), int(c.y)])
	print("D25_LVL %d: structures=%d fields=%d  BLD=%d FLD=%d ROAD=%d" % [lv, items.size(), fields.size(), bld_hits.size(), fld_hits.size(), road_hits.size()])
	for s in bld_hits: print("  BLD  ", s)
	for s in fld_hits: print("  FLD  ", s)
	for s in road_hits: print("  ROAD ", s)
	return {"bld": bld_hits.size(), "fld": fld_hits.size(), "road": road_hits.size()}

func _process(_d: float) -> bool:
	_f += 1
	if _f < 10: return false
	var growth = _t.get("growth")
	var live: int = int(growth.level) if growth else 0
	var forced := OS.get_environment("D25_LEVEL")
	var levels := [live]
	var top := int(growth.TOP_LEVEL) if growth else live
	if forced != "":
		levels = [int(forced)]
	elif top != live:
		levels = [live, top]
	var tot := {"bld": 0, "fld": 0, "road": 0}
	for lv in levels:
		var r := _run_level(lv, growth)
		tot["bld"] += r["bld"]; tot["fld"] += r["fld"]; tot["road"] += r["road"]
	if tot["bld"] == 0 and tot["fld"] == 0 and tot["road"] == 0:
		print("D25_PROBE OK")
	else:
		print("D25_PROBE FAIL bld=%d fld=%d road=%d" % [tot["bld"], tot["fld"], tot["road"]])
	return true
