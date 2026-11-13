extends SceneTree
## D25 shot sheet: town overview, the 5 road-intrusion spots, and the farm/valley.
## Run WINDOWED. `-- before/after`. -> renders/cycles/20261112_d25/<tag>_*.png
var _t: Node3D
var _cam: Camera3D
var _dl
var _f := 0
var _out := ""
var _tag := "run"
var _shots: Array = []
var _i := 0
var _armed := -1
var _hold := 0
var ROADS := [Vector3(120,0,-17), Vector3(0,0,-54), Vector3(-62,0,-18), Vector3(-120,0,18), Vector3(-83,0,-83)]

func _initialize() -> void:
	var ua := OS.get_cmdline_user_args()
	if ua.size() > 0: _tag = String(ua[0])
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	_out = ProjectSettings.globalize_path("res://renders/cycles/20261112_d25")
	DirAccess.make_dir_recursive_absolute(_out)

func _process(_d: float) -> bool:
	_f += 1
	if _f == 90:
		_dl = _t.get("daylight")
		var r = _t.get("raids")
		if r: r.set("_raid_t", 999999.0)
		_cam = Camera3D.new(); _cam.fov = 55.0; _cam.far = 1400.0
		_t.add_child(_cam)
		var m: Vector3 = _t.get("_market_pos")
		_shots.append(["overview", 12.0, m + Vector3(0, 78.0, 100.0), m])
		for i in range(ROADS.size()):
			var c: Vector3 = ROADS[i]
			var g := float(_t.call("height_at", c.x, c.z))
			_shots.append(["road%d" % i, 12.0, Vector3(c.x + 11, g + 13, c.z + 15), Vector3(c.x, g + 2.0, c.z)])
		# farm: first valley site
		var valley = _t.get("valley")
		if valley:
			var sites: Dictionary = valley.get("sites")
			for k in ["Coalfoot Steading", "Bramble End"]:
				if sites.has(k):
					var sp: Vector3 = sites[k]["pos"]
					var g2 := float(_t.call("height_at", sp.x, sp.z))
					_shots.append(["farm_%s" % k.split(" ")[0], 12.0, Vector3(sp.x + 18, g2 + 26, sp.z + 34), Vector3(sp.x, g2 + 2.0, sp.z)])
	if _cam == null: return false
	if _cam != root.get_viewport().get_camera_3d(): _cam.make_current()
	if _i < _shots.size():
		var sh: Array = _shots[_i]
		if _armed != _i:
			if _dl:
				_dl.override_hour = float(sh[1]); _dl.set_weather("clear", true)
			_cam.global_position = sh[2] as Vector3
			_cam.look_at(sh[3] as Vector3, Vector3.UP)
			_armed = _i; _hold = 0
			return false
		_hold += 1
		if _hold >= 50:
			root.get_texture().get_image().save_png(_out + "/%s_%s.png" % [_tag, sh[0]])
			print("SAVED ", _tag, "_", sh[0]); _i += 1
		return false
	return true
