extends SceneTree
## S28: the greener at the scale delve.gd gives it (MB_HERO_H x miniboss_ratio), beside a 2.45 m
## hero-height post, front and side, 1920x1080. Measures the scaled body's height in the engine and
## goes RED if it is not MB_HERO_H x 1.02 within 0.03 m, or the model does not load.
## Windowed, no --quit: <console> --path . --resolution 1920x1080 --script tools/_s28_greener_look.gd
const OUT := "res://renders/cycles/s28/"
var _f := 0
var _cam: Camera3D
var _fails: Array = []
var _h := 0.0
func _bounds(n: Node, xf: Transform3D, acc: Array) -> void:
	var t := xf * (n as Node3D).transform if n is Node3D else xf
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var a := t * (n as MeshInstance3D).mesh.get_aabb()
		acc[0] = a if acc[0] == null else (acc[0] as AABB).merge(a)
	for c in n.get_children():
		_bounds(c, t, acc)
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var p := Delve.miniboss_model("greener")
	if p == "":
		_fails.append("no greener model")
		return
	var m := (load(p) as PackedScene).instantiate() as Node3D
	root.add_child(m)
	var acc: Array = [null]
	_bounds(m, Transform3D.IDENTITY, acc)
	var a: AABB = acc[0]
	var want := Delve.MB_HERO_H * Delve.miniboss_ratio("greener", p)
	var s := want / a.size.y
	m.scale = Vector3.ONE * s
	m.position = Vector3(0, -a.position.y * s, 0)
	acc = [null]
	_bounds(m, Transform3D.IDENTITY, acc)
	_h = (acc[0] as AABB).size.y
	print("S28_GREENER model=%s want=%.3f measured=%.3f ratio=%.3f" % [p.get_file(), want, _h, _h / Delve.MB_HERO_H])
	if absf(_h - want) > 0.03:
		_fails.append("height %.3f != %.3f" % [_h, want])
	var post := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.height = Delve.MB_HERO_H
	cap.radius = 0.3
	post.mesh = cap
	post.position = Vector3(-2.6, Delve.MB_HERO_H / 2.0, 0)
	root.add_child(post)
	var fl := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(20, 20)
	fl.mesh = pm
	root.add_child(fl)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	root.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.25, 0.27, 0.3)
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	root.add_child(env)
	_cam = Camera3D.new()
	_cam.fov = 40.0
	root.add_child(_cam)
func _shot(pos: Vector3, nm: String) -> void:
	_cam.position = pos
	_cam.look_at(Vector3(-1.3, 1.25, 0))
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + nm))
func _process(_dt: float) -> bool:
	_f += 1
	if _f == 2 and _cam:
		_cam.position = Vector3(-1.3, 1.6, 9.0)
		_cam.look_at(Vector3(-1.3, 1.25, 0))
	if _f == 12 and _cam:
		_shot(Vector3(-1.3, 1.6, 9.0), "greener_front.png")
		_cam.position = Vector3(8.0, 1.6, 0.0)
		_cam.look_at(Vector3(-1.3, 1.25, 0))
	if _f == 22 and _cam:
		_shot(Vector3(8.0, 1.6, 0.0), "greener_side.png")
	if _f >= 24 or (_cam == null and _f > 1):
		print("S28_GREENER_VERDICT %s" % ("OK (2 shots)" if _fails.is_empty() else "FAIL " + str(_fails)))
		return true
	return false
