extends SceneTree
## L25 render: generated floors with the placement fit checks OFF ("before") and ON ("after"),
## an overview and a close look at the entry stairs. Run windowed:
##   godot --path . --resolution 1600x900 --script tools/_l25_shot.gd
## Saves renders/cycles/20261112_l25/<floor>_<before|after>_{wide,stairs,room}.png
const OUT := "res://renders/cycles/20261112_l25"
const FLOORS := [1, 3, 6]
var _cam: Camera3D
var _host: Node3D
var _jobs: Array = []        # [floor, fit, view]
var _f := 0
var _info := {}

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.02, 0.02, 0.03)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.35, 0.33, 0.42)
	e.ambient_light_energy = 0.6
	e.tonemap_mode = Environment.TONE_MAPPER_AGX
	we.environment = e
	root.add_child(we)
	_cam = Camera3D.new()
	_cam.fov = 55.0
	root.add_child(_cam)
	_cam.make_current()
	for fl in FLOORS:
		for fit in [false, true]:
			for view in ["wide", "stairs", "room"]:
				_jobs.append([fl, fit, view])

func _process(_dt: float) -> bool:
	_f += 1
	if _f % 12 != 1:
		return false
	if _host and _f % 12 == 1 and _info.has("job"):
		var j: Array = _info["job"]
		var img := root.get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path(OUT + "/f%d_%s_%s.png" % [j[0], "after" if j[1] else "before", j[2]]))
	if _jobs.is_empty():
		print("L25_SHOT done")
		return true
	var job: Array = _jobs.pop_front()
	var key := "%d_%s" % [job[0], job[1]]
	if _info.get("key", "") != key:
		if _host:
			_host.free()
		_host = Node3D.new()
		root.add_child(_host)
		FloorGen.fit_checks = bool(job[1])
		var info := FloorGen.build(_host, int(job[0]), Vector3.ZERO)
		_info = {"key": key, "info": info}
	_info["job"] = job
	var info: Dictionary = _info["info"]
	var en: Vector3 = info["entry"]
	var lamp: Vector3 = info["lamp"]
	match String(job[2]):
		"wide":
			_cam.global_position = lamp + Vector3(0, 46, 34)
			_cam.look_at(lamp, Vector3.UP)
		"stairs":
			_cam.global_position = en + Vector3(5.5, 4.5, -7.5)
			_cam.look_at(en + Vector3(0, 1.6, 1.0), Vector3.UP)
		"room":
			_cam.global_position = lamp + Vector3(9, 7, 11)
			_cam.look_at(lamp + Vector3(0, 0.8, 0), Vector3.UP)
	return false
