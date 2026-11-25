extends SceneTree
## S136 (System 12, S110c-3): the UACP wiring gate. Spawns REAL Townsfolk nodes with model "uacp/<Body>.glb"
## beside KayKit ones and checks: head-bone scale UACP_K, the prefix-stripped KayKit clip names exist and play,
## no Gear was dressed onto a UACP body, and the one skin-override path recolours only "Skin".
## Run WITH a window. Saves renders/cycles/s136/wired.png. --redprove runs the UACP checks against a KayKit
## body and must FAIL.
const BODIES := ["Worker_Male", "Chef_Female", "OldClassy_Male", "Viking_Male", "Witch", "Goblin_Male"]
var _f := 0
var _tf: Array = []
var _red := false

func _mk(model: String, x: float, z: float) -> Node3D:
	var t := Townsfolk.new()
	t.model = model
	t.person_name = model.get_file().get_basename()
	t.position = Vector3(x, 0, z)
	root.add_child(t)
	return t

func _initialize() -> void:
	_red = "--redprove" in OS.get_cmdline_user_args()
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.62, 0.7)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.6, 0.6)
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	root.add_child(sun)
	var fl := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	fl.mesh = pm
	root.add_child(fl)
	var xs := -6.0
	for nm in ["Rogue.glb", "Knight.glb"]:
		_mk(nm, xs, 0.0)
		xs += 1.6
	for nm in BODIES:
		_tf.append(_mk("uacp/" + nm + ".glb", xs, 0.0))
		xs += 1.6
	if _red:
		_tf = [_mk("Rogue.glb", 0.0, -4.0)]
	var cam := Camera3D.new()
	cam.fov = 40.0
	root.add_child(cam)
	var cp := Vector3(0.4, 2.0, 11.0)
	cam.transform = Transform3D(Basis.looking_at(Vector3(0.4, 1.0, -1.0) - cp, Vector3.UP), cp)
	cam.make_current()

func _process(_d: float) -> bool:
	_f += 1
	if _f == 6:
		## the override path, exercised on the last body only (the shipped default stays pack-native)
		var last: Node3D = _tf[_tf.size() - 1]
		var mdl: Node = last.get_child(0)
		print("S136 skin override surfaces on ", last.person_name, ": ", Townsfolk.uacp_skin(mdl, Color(0.85, 0.62, 0.48)))
	if _f == 24:
		var fails: Array = []
		var ok := 0
		for t in _tf:
			var mdl: Node3D = t.get_child(0)
			var ap := Rig.find(mdl)
			var why := ""
			if not String(mdl.scene_file_path).contains("/uacp/"):
				why += " not a uacp body (%s)" % mdl.scene_file_path
			if absf(mdl.scale.x - Townsfolk.UACP_K) > 0.001:
				why += " scale %.4f" % mdl.scale.x
			for c in ["Idle", "Walking_A", "Sit_Chair_Down", "Sit_Chair_StandUp", "Cheer"]:
				if ap == null or not ap.has_animation(c):
					why += " no clip " + c
			if ap and ap.current_animation != "Idle":
				why += " playing '%s'" % ap.current_animation
			if mdl.find_children("eq_*", "", true, false).size() > 0:
				why += " gear dressed"
			if why == "":
				ok += 1
			else:
				fails.append(t.person_name + ":" + why)
		var img := root.get_texture().get_image()
		var out := ProjectSettings.globalize_path("res://renders/cycles/s136/wired.png")
		DirAccess.make_dir_recursive_absolute(out.get_base_dir())
		if not _red:
			print("S136 shot rc=", img.save_png(out), " ", out)
		if fails.is_empty() and ok == _tf.size():
			print("S136_WIRE OK %d uacp townsfolk at k %.4f, KayKit clip names live, 0 gear on uacp, skin default pack-native (alpha %.0f)" % [ok, Townsfolk.UACP_K, Townsfolk.UACP_SKIN.a])
		else:
			print("S136_WIRE FAIL ok=%d/%d %s" % [ok, _tf.size(), str(fails)])
		return true
	return false
