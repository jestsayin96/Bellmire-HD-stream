extends SceneTree
## S31 System 5 FIT SHOT (the acceptance test the 03:58 row asked for): a REAL posed KayKit hero body
## (the same bare body + Idle pose _d95_fit.gd uses) standing on a FLOOR, turned the way the delve turns
## a body (rotation.y = atan2(dx, dz) toward what it faces - delve.gd 1445/1637), and the REAL
## Delve._show_vial called on it: one drink (mending) and one floor find (gatewater). Tweens are frozen
## at their first frame so the shot shows where the bottle STARTS. Front and side of each, plus one
## stream-distance shot -> renders/cycles/s31/. Prints S31_FIT lines (measured, metres) and
## S31_FIT OK|FAIL. Run WINDOWED (it renders); it quits itself.
const OUT := "res://renders/cycles/s31/"
var _f := 0
var _i := 0
var _cam: Camera3D
var _stage: Node3D
var _dl: Node
var _r: Roster
var _heroes: Array = []      # [host, model, key, on_floor]
var _shots: Array = []
var errs: Array = []

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_stage = Node3D.new()
	root.add_child(_stage)
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.30, 0.31, 0.34)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.75, 0.80)
	e.ambient_light_energy = 0.7
	e.tonemap_mode = Environment.TONE_MAPPER_AGX
	we.environment = e
	_stage.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-50), deg_to_rad(150), 0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	_stage.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation = Vector3(deg_to_rad(-30), deg_to_rad(-30), 0)
	fill.light_energy = 0.5
	_stage.add_child(fill)
	var fl := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(200, 200)
	fl.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.42, 0.40, 0.37)
	fl.material_override = fm
	_stage.add_child(fl)
	_cam = Camera3D.new()
	_stage.add_child(_cam)
	_r = Roster.new()
	_stage.add_child(_r)
	_dl = load("res://scripts/delve.gd").new()
	_stage.add_child(_dl)
	var x := 0.0
	for pair in [["mending", false], ["gatewater", true]]:
		var host := Node3D.new()
		_stage.add_child(host)
		host.position = Vector3(x, 0, 0)
		var face := Vector3(x, 0, -6.0)          # it faces the front camera, turned the delve's way
		host.rotation.y = atan2(face.x - x, face.z - 0.0)
		var m: Node3D = (load("res://addons/kaykit_character_pack_adventures/Characters/gltf/" + String(Roster.CLASSES["knight"]["model"])) as PackedScene).instantiate()
		host.add_child(m)
		Gear.strip_props(m)
		var ap := Rig.find(m)
		if ap:
			Rig.prep(ap)
			Rig.play(ap, "Idle")
		_heroes.append([host, m, String(pair[0]), bool(pair[1])])
		var n := "floor" if pair[1] else "drink"
		_shots.append([n + "_1front", Vector3(x, 1.1, -4.2), Vector3(x, 0.9, 0)])
		_shots.append([n + "_2side", Vector3(x - 3.5, 1.1, 0), Vector3(x, 0.9, 0)])
		x += 6.0
	_shots.append(["both_3stream", Vector3(3.0, 9.0, -14.0), Vector3(3.0, 0.8, 0)])

func _aabb(n: Node) -> AABB:
	var out := AABB()
	var first := true
	for c in n.find_children("*", "MeshInstance3D", true, false):
		var mi := c as MeshInstance3D
		var a := mi.global_transform * mi.get_aabb()
		out = a if first else out.merge(a)
		first = false
	return out

func _process(_d: float) -> bool:
	_f += 1
	if _f == 30:
		for h in _heroes:
			_dl._show_vial({"body": h[0]}, h[2], h[3])
		for t in get_processed_tweens():
			t.pause()        # freeze each bottle where it STARTS
	if _f == 34:
		var vials: Array = []
		for c in _dl.get_children():
			if String(c.name).begins_with("Vial_"):
				vials.append(c)
		if vials.size() != 2:
			errs.append("expected 2 vials, live path made %d" % vials.size())
		for i in range(mini(vials.size(), _heroes.size())):
			var host: Node3D = _heroes[i][0]
			var m: Node3D = _heroes[i][1]
			var v: Node3D = vials[i]
			var hb := _aabb(m)
			var vb := _aabb(v)
			var head_y := -1.0
			var sk := m.find_children("*", "Skeleton3D", true, false)
			if not sk.is_empty():
				var s := sk[0] as Skeleton3D
				var bi := s.find_bone("head")
				if bi >= 0:
					head_y = (s.global_transform * s.get_bone_global_pose(bi)).origin.y
			var facing := host.global_transform.basis.z.normalized()   # +z is where a KayKit body looks
			var off := vb.get_center() - host.global_position
			var ahead := Vector3(off.x, 0, off.z).dot(facing)
			print("S31_FIT %s %s: hero top %.2f m, head bone %.2f m | vial %.2f m tall, centre y %.2f, min y %.3f, ahead of face %.2f m, ratio vial/hero %.2f" % [
				"floor" if _heroes[i][3] else "drink", v.name, hb.end.y, head_y, vb.size.y, vb.get_center().y, vb.position.y, ahead, vb.size.y / maxf(hb.size.y, 0.01)])
			var body_front := -INF
			var vial_back := INF
			for k in range(8):
				body_front = maxf(body_front, (hb.get_endpoint(k) - host.global_position).dot(facing))
				vial_back = minf(vial_back, (vb.get_endpoint(k) - host.global_position).dot(facing))
			# INFO ONLY, NOT A CHECK: a skinned mesh's AABB is its REST bounds, so "body reaches" over-reads (0.77 m
			# for a knight whose visor ends ~0.45 m out). Burial in the helmet is judged on the side shot, which is
			# how the 0.35 m cut was caught - an instrument that over-reads must not be allowed to read red or green.
			print("S31_FIT INFO %s: rest-AABB body front %.2f m ahead of root (over-reads), bottle near face %.2f m" % [v.name, body_front, vial_back])
			if ahead <= 0.05:
				errs.append("%s bottle is BEHIND or inside the body (ahead %.2f m)" % [v.name, ahead])
			if _heroes[i][3]:
				if vb.position.y < -0.02 or vb.position.y > 0.08:
					errs.append("floor bottle not on the floor (min y %.3f)" % vb.position.y)
			else:
				if head_y > 0.0 and absf(vb.get_center().y - head_y) > 0.45:
					errs.append("drink bottle %.2f m off the head" % (vb.get_center().y - head_y))
	if _f < 40:
		return false
	if (_f - 40) % 10 == 0:
		if _i > 0:
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "%s.png" % _shots[_i - 1][0]))
		if _i >= _shots.size():
			print("S31_FIT saved %d shots to %s" % [_shots.size(), OUT])
			if errs.is_empty():
				print("S31_FIT OK")
			else:
				print("S31_FIT FAIL ", errs)
			return true
		var s: Array = _shots[_i]
		_cam.fov = 40.0
		_cam.global_position = s[1]
		_cam.look_at(s[2], Vector3.UP)
		_i += 1
	return false
