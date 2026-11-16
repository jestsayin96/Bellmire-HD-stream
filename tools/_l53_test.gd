extends SceneTree
## L53 (raised by the content writer): gear.gd _hat had match-cases for only four hat keys. Every
## other hat in data/items.json fell through to `hat.mesh = crown` with CylinderMesh still at its
## DEFAULTS - top 0.5, bottom 1.0, height 2.0 - i.e. a two-metre pale cone on the hero's head.
## This test is driven BY THE DATA, not by a list I typed: it reads every cosmetic with
## kind == "hat" out of data/items.json and builds each one, so the next hat the content writer
## adds is checked automatically instead of silently regressing.
##   A. every hat key in the data produces a hat piece at all
##   B. none of them is left at CylinderMesh's untouched defaults (the actual bug)
##   C. the hats are not all the same shape - a coif must not look like a kettle-helm
##   D. an unknown key degrades to a sane cap rather than the 2 m cone
## Headless: mesh construction, no HUD. Prints L53_TEST OK / FAIL.
var _fails: Array = []
var _checks := 0

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

## a bare skeleton with the one bone _piece needs
func _rig() -> Array:
	var root := Node3D.new()
	root.name = "model"
	var sk := Skeleton3D.new()
	root.add_child(sk)
	sk.add_bone("head")
	get_root().add_child(root)
	return [root, sk]

## build one hat and describe the shape it produced
func _shape_of(key: String) -> Dictionary:
	var r := _rig()
	var root: Node3D = r[0]
	var sk: Skeleton3D = r[1]
	Gear._hat(root, sk, key)
	var found: MeshInstance3D = null
	var st: Array = [sk]
	while not st.is_empty():
		var c: Node = st.pop_back()
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
			found = c
			break
		for g in c.get_children():
			st.append(g)
	var out := {"key": key, "has": found != null, "cls": "", "dims": Vector3.ZERO, "kids": 0}
	if found != null:
		var m: Mesh = found.mesh
		out["cls"] = m.get_class()
		out["kids"] = found.get_child_count()
		if m is CylinderMesh:
			out["dims"] = Vector3((m as CylinderMesh).top_radius, (m as CylinderMesh).bottom_radius, (m as CylinderMesh).height)
		elif m is SphereMesh:
			out["dims"] = Vector3((m as SphereMesh).radius, (m as SphereMesh).height, 0)
		elif m is TorusMesh:
			out["dims"] = Vector3((m as TorusMesh).inner_radius, (m as TorusMesh).outer_radius, 0)
	root.queue_free()
	return out

## CylinderMesh straight out of the box - what the fall-through used to leave behind
func _is_default_cyl(s: Dictionary) -> bool:
	if String(s["cls"]) != "CylinderMesh":
		return false
	var d: Vector3 = s["dims"]
	return is_equal_approx(d.x, 0.5) and is_equal_approx(d.y, 1.0) and is_equal_approx(d.z, 2.0)

func _initialize() -> void:
	# ---- the hat keys come from the DATA, so a new one is covered without touching this test
	var f := FileAccess.open("res://data/items.json", FileAccess.READ)
	var hats: Array = []
	if f != null:
		var j = JSON.parse_string(f.get_as_text())
		if j is Dictionary and (j as Dictionary).has("cosmetics"):
			var cos: Dictionary = (j as Dictionary)["cosmetics"]
			for k in cos:
				if String((cos[k] as Dictionary).get("kind", "")) == "hat":
					hats.append(String(k))
	hats.sort()
	print("L53: %d hat keys in data/items.json: %s" % [hats.size(), str(hats)])
	_ok(hats.size() > 0, "the hat keys were read out of the data (%d)" % hats.size())

	var shapes: Array = []
	var defaulted: Array = []
	var missing: Array = []
	for k in hats:
		var s := _shape_of(k)
		shapes.append(s)
		if not bool(s["has"]):
			missing.append(k)
		elif _is_default_cyl(s):
			defaulted.append(k)
		print("   %-14s %-14s dims %s  children %d" % [k, s["cls"], str(s["dims"]), int(s["kids"])])

	_ok(missing.is_empty(), "A: every hat key builds a hat piece (none missing: %s)" % str(missing))
	_ok(defaulted.is_empty(),
		"B: NO hat is left at CylinderMesh's untouched defaults - the 2 m cone (%s)" % str(defaulted))

	# ---- C. they must not all be the same silhouette
	var sigs := {}
	for s in shapes:
		sigs["%s|%s|%d" % [String(s["cls"]), str(s["dims"]), int(s["kids"])]] = true
	print("L53: %d distinct silhouettes across %d hats" % [sigs.size(), shapes.size()])
	_ok(sigs.size() >= 5, "C: the hats are tellable apart (%d distinct silhouettes for %d hats)" % [sigs.size(), shapes.size()])

	# ---- D. an unknown key must degrade, not break
	var unknown := _shape_of("a_hat_nobody_has_written_yet")
	print("L53: unknown key -> %s dims %s" % [String(unknown["cls"]), str(unknown["dims"])])
	_ok(bool(unknown["has"]) and not _is_default_cyl(unknown),
		"D: an UNKNOWN hat key degrades to a sane cap, not the 2 m cone")

	print("CHECKS ", _checks, " FAILS ", _fails.size())
	for x in _fails:
		print("  - ", x)
	print("L53_TEST ", "OK" if _fails.is_empty() else "FAIL")
	quit()
