extends SceneTree
## L28c: FPS with a real delve floor. Run WINDOWED (never headless):
##   godot --path . --resolution 1920x1080 --script tools/_l28_fps.gd
## Builds a DungeonHD at Delve.DELVE_Y in lane 0 (residents and all), looks at it with the
## game's camera (fov 55, pitch -48, 34 m back, orbiting the lamp slowly) through the floor's
## own environment, vsync off, and averages FPS over L28_FPS_SECS (default 10) per theme after
## a 1.5 s settle. Also counts the floor's lights / shadowed lights / particle emitters / decals.
## L28_FPS_TAG names the run (before / after); results go to stdout and
## renders/cycles/20261112_l28/fps_<tag>.txt.
## L28_FPS_THEMES=crypt,firepit limits the themes; a boss floor is measured as "boss".
const OUT := "res://renders/cycles/20261112_l28"
var _cam: Camera3D
var _we: WorldEnvironment
var _jobs: Array = []
var _host: Node3D
var _cur := {}
var _t := 0.0
var _frames := 0
var _secs := 10.0
var _tag := "run"
var _lines: PackedStringArray = []
var _yaw := 0.0
var _worst := 0.0

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	if OS.get_environment("L28_FPS_SECS") != "":
		_secs = float(OS.get_environment("L28_FPS_SECS"))
	if OS.get_environment("L28_FPS_TAG") != "":
		_tag = OS.get_environment("L28_FPS_TAG")
	_we = WorldEnvironment.new()
	_we.environment = Environment.new()
	root.add_child(_we)
	# the town's sun sits above every lid in the game; keep one so the light count is honest
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.shadow_enabled = true
	root.add_child(sun)
	_cam = Camera3D.new()
	_cam.fov = 55.0
	_cam.far = 400.0
	root.add_child(_cam)
	_cam.make_current()
	var want := OS.get_environment("L28_FPS_THEMES")
	for th in FloorGen.all_themes().keys():
		if want != "" and not want.split(",").has(String(th)):
			continue
		var fl := _floor_of(String(th), false)
		if fl > 0:
			_jobs.append([String(th), fl])
	if want == "" or want.split(",").has("boss"):
		for f in range(2, 80):
			if Bestiary.is_boss_floor(f):
				_jobs.append(["boss", f])
				break
	_lines.append("L28_FPS %s  %s  %.0f s/theme  %s" % [_tag, Time.get_datetime_string_from_system(), _secs,
		RenderingServer.get_video_adapter_name()])

func _floor_of(theme: String, boss: bool) -> int:
	for f in range(2, 80):
		if FloorGen.theme_for(f) == theme and Bestiary.is_boss_floor(f) == boss:
			return f
	return -1

func _count(n: Node, c: Dictionary) -> void:
	if n is Light3D:
		c["lights"] += 1
		if (n as Light3D).shadow_enabled:
			c["shadow"] += 1
	elif n is GPUParticles3D:
		c["emit"] += 1
	elif n is Decal:
		c["decals"] += 1
	for k in n.get_children():
		_count(k, c)

func _start(job: Array) -> void:
	if _host:
		_host.free()
	_host = Node3D.new()
	root.add_child(_host)
	var d := DungeonHD.new()
	d.floor_no = int(job[1])
	d.position = Vector3(0, -400.0, 0)
	_host.add_child(d)
	var fe = d.env()
	_we.environment = fe if fe is Environment else Environment.new()
	var c := {"lights": 0, "shadow": 0, "emit": 0, "decals": 0}
	_count(d, c)
	_cur = {"job": job, "dun": d, "c": c, "settle": 1.5}
	_t = 0.0
	_frames = 0
	_yaw = 0.0
	_worst = 0.0

func _process(dt: float) -> bool:
	if _cur.is_empty():
		if _jobs.is_empty():
			return _finish()
		_start(_jobs.pop_front())
		return false
	var d: DungeonHD = _cur["dun"]
	var lamp: Vector3 = d.info["lamp"] + d.global_position
	_yaw += dt * 0.25
	var pitch := deg_to_rad(-48.0)
	var off := Vector3(sin(_yaw) * cos(pitch), -sin(pitch), cos(_yaw) * cos(pitch)) * 34.0
	_cam.global_position = lamp + off
	_cam.look_at(lamp + Vector3(0, 1.0, 0), Vector3.UP)
	if float(_cur["settle"]) > 0.0:
		_cur["settle"] = float(_cur["settle"]) - dt
		return false
	_t += dt
	_frames += 1
	_worst = maxf(_worst, dt)
	if _t >= _secs:
		var job: Array = _cur["job"]
		var c: Dictionary = _cur["c"]
		var line := "L28_FPS %-10s floor %2d  fps %6.1f  worst %5.1f ms  lights %2d (shadowed %d)  emitters %2d  decals %2d" % [
			job[0], job[1], float(_frames) / _t, _worst * 1000.0, c["lights"], c["shadow"], c["emit"], c["decals"]]
		print(line)
		_lines.append(line)
		_cur = {}
	return false

func _finish() -> bool:
	var f := FileAccess.open(ProjectSettings.globalize_path(OUT + "/fps_%s.txt" % _tag), FileAccess.WRITE)
	if f:
		f.store_string("\n".join(_lines) + "\n")
	print("L28_FPS done")
	return true
