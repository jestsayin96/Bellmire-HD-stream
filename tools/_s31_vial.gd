extends SceneTree
## S31 System 5 gate: every potion in data/potions.json maps to a colour kind and a bottle model
## that exists, all three kinds are populated, and a picture of the three tinted bottles is saved.
## Prints S31_VIAL OK|FAIL. Run WINDOWED (it renders); it quits itself.
var _f := 0
var errs: Array = []
var _dl: Node
var _cam: Camera3D
var _calls: Array = []
func _initialize() -> void:
	var D = load("res://scripts/delve.gd")
	var ps: Dictionary = Roster.potions().get("potions", {})
	var cnt := {"heal": 0, "speed": 0, "ward": 0}
	for k in ps:
		var kind: String = D.vial_kind(ps[k])
		cnt[kind] = int(cnt.get(kind, 0)) + 1
		if not ResourceLoader.exists(D.vial_model(kind)):
			errs.append("no model for " + kind)
	if ps.size() < 50:
		errs.append("only %d potions read" % ps.size())
	for kind in cnt:
		if int(cnt[kind]) == 0:
			errs.append("kind %s empty" % kind)
	print("S31_VIAL counts ", cnt, " of ", ps.size())
	var root := Node3D.new()
	get_root().add_child(root)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.12, 0.11, 0.10)
	env.environment.ambient_light_color = Color(0.5, 0.5, 0.5)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	root.add_child(sun)
	# the REAL path: Delve._show_vial on three stand-in bodies - two drinks and one floor find
	var dl = D.new()
	root.add_child(dl)
	_dl = dl
	var x := -1.0
	for pair in [["mending", false], ["sawyers_dram", false], ["gatewater", true]]:
		var body := Node3D.new()
		root.add_child(body)
		body.position = Vector3(x, 0, 0)
		body.rotation.y = PI          # -z (the body's forward) toward the camera
		x += 1.0
		_calls.append([{"body": body}, String(pair[0]), bool(pair[1])])
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.position = Vector3(0, 0.9, 3.4)
	cam.current = true
	_cam = cam
func _process(_d: float) -> bool:
	_f += 1
	if _f == 2:
		# inside the tree only now - _initialize runs before the root enters it
		_cam.look_at(Vector3(0, 0.7, 0))
		for c in _calls:
			_dl._show_vial(c[0], c[1], c[2])
	if _f == 14:
		var kinds: Array = []
		for c in _dl.get_children():
			if String(c.name).begins_with("Vial_"):
				kinds.append(String(c.name))
		kinds.sort()
		print("S31_VIAL live vials ", kinds)
		if kinds != ["Vial_heal", "Vial_speed", "Vial_ward"]:
			errs.append("live path made %s" % [kinds])
		var img := get_root().get_texture().get_image()
		img.save_png("res://renders/s31_vials.png")
		print("S31_VIAL saved renders/s31_vials.png")
		if errs.is_empty():
			print("S31_VIAL OK")
		else:
			print("S31_VIAL FAIL ", errs)
		quit()
	return false
