extends SceneTree
## L28 renders. Run windowed at 1920x1080:
##   godot --path . --resolution 1920x1080 --script tools/_l28_shot.gd
## L28_SET=a   (default) three themes, kit look OFF ("before") and ON ("after"), views room + close
## L28_SET=all every theme, after only (the per-biome sheet)
## L28_ENV=town (default) the light a delve is seen in today: the town's WorldEnvironment
##   (sky ambient, AGX, valley haze), which every delve camera copies
## L28_ENV=floor the floor's own environment, when DungeonHD provides one (L28b)
## Saves renders/cycles/20261112_l28/<set>_<theme>_<before|after>_<view>.png and a contact
## sheet <set>_sheet.png (one row per theme).
const OUT := "res://renders/cycles/20261112_l28"
const SET_A := ["crypt", "flooded", "treasury"]
var _cam: Camera3D
var _we: WorldEnvironment
var _town_env: Environment
var _host: Node3D
var _jobs: Array = []        # [theme, floor, look, view]
var _shots: Array = []       # [theme, file]
var _f := 0
var _cur := {}
var _set := "a"
var _envmode := "town"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_set = OS.get_environment("L28_SET") if OS.get_environment("L28_SET") != "" else "a"
	_envmode = OS.get_environment("L28_ENV") if OS.get_environment("L28_ENV") != "" else "town"
	_we = WorldEnvironment.new()
	_town_env = _town_like()
	_we.environment = _town_env
	root.add_child(_we)
	# the town's sun is above the lid; it lights nothing below but is part of the scene
	_cam = Camera3D.new()
	_cam.fov = 55.0
	root.add_child(_cam)
	_cam.make_current()
	var themes: Array = SET_A if _set == "a" else FloorGen.all_themes().keys()
	if _set in ["c", "d"]:
		themes = themes.duplicate()
		themes.append("boss")
	for th in themes:
		var fl := _floor_of(String(th))
		if fl < 0:
			print("L28_SHOT no floor for ", th)
			continue
		var views: Array = ["room", "close", "game"] if _set in ["c", "d"] else ["room", "close"]
		for look in ([false, true] if _set == "a" else [true]):
			for view in views:
				_jobs.append([th, fl, look, view])

## the town's environment as town.gd builds it (sky ambient 0.85, AGX, haze, SSAO)
func _town_like() -> Environment:
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.29, 0.46, 0.74)
	sm.sky_horizon_color = Color(0.72, 0.79, 0.86)
	sm.ground_bottom_color = Color(0.46, 0.52, 0.42)
	sm.ground_horizon_color = Color(0.70, 0.76, 0.80)
	sky.sky_material = sm
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.85
	e.ssao_enabled = true
	e.tonemap_mode = Environment.TONE_MAPPER_AGX
	e.fog_enabled = true
	e.fog_light_color = Color(0.70, 0.77, 0.84)
	e.fog_density = 0.0011
	e.fog_aerial_perspective = 0.6
	e.fog_sky_affect = 0.15
	return e

func _floor_of(theme: String) -> int:
	if theme == "boss":         # L28c: the first lord's floor, lord and all
		for f in range(2, 80):
			if Bestiary.is_boss_floor(f):
				return f
	for f in range(2, 80):
		if FloorGen.theme_for(f) == theme and not Bestiary.is_boss_floor(f):
			return f
	return -1

func _process(_dt: float) -> bool:
	_f += 1
	if _f % 14 != 1:
		return false
	if _cur.has("job"):
		var j: Array = _cur["job"]
		var file := "%s_%s_%s_%s.png" % [_set, j[0], "after" if j[2] else "before", j[3]]
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "/" + file))
		_shots.append([j[0], file])
	if _jobs.is_empty():
		_sheet()
		print("L28_SHOT done (%d shots)" % _shots.size())
		return true
	var job: Array = _jobs.pop_front()
	var key := "%s_%s" % [job[1], job[2]]
	if _cur.get("key", "") != key:
		if _host:
			_host.free()
		_host = Node3D.new()
		root.add_child(_host)
		FloorGen.kit_look = bool(job[2])
		var d := DungeonHD.new()
		d.floor_no = int(job[1])
		_host.add_child(d)
		for m in d.monsters:
			(m as Node).queue_free()          # the look, not the residents
		if d.lord and String(job[0]) != "boss":
			d.lord.queue_free()
		_cur = {"key": key, "info": d.info, "dun": d}
		var fe = d.env() if _envmode == "floor" else null
		_we.environment = fe if _envmode == "floor" and fe is Environment else _town_env
	_cur["job"] = job
	var info: Dictionary = _cur["info"]
	var lamp: Vector3 = info["lamp"]
	var en: Vector3 = info["entry"]
	match String(job[3]):
		"room":
			_cam.global_position = lamp + Vector3(9, 7, 11)
			_cam.look_at(lamp + Vector3(0, 0.8, 0), Vector3.UP)
		"close":
			# low and near, along the floor toward a wall: tiles, a wall face, props
			var dir := (lamp - en)
			dir.y = 0
			dir = dir.normalized() if dir.length() > 0.1 else Vector3(0, 0, 1)
			if _set in ["c", "d"]:
				dir = _open_dir(info, en)
			_cam.global_position = en + dir * 3.0 + Vector3(0, 1.7, 0)
			_cam.look_at(en + dir * 9.0 + Vector3(0, 0.6, 0), Vector3.UP)
		"game":
			# the director's camera as the game frames it: fov 55, 48 deg down, 34 m back,
			# on the lord (boss floor) or the lamp-stand
			var at := lamp
			var dn: DungeonHD = _cur["dun"]
			if dn.lord and is_instance_valid(dn.lord) and not dn.lord.is_queued_for_deletion():
				at = dn.lord.global_position
			var p := deg_to_rad(-48.0)
			var yaw := deg_to_rad(35.0)
			_cam.global_position = at + Vector3(sin(yaw) * cos(p), -sin(p), cos(yaw) * cos(p)) * 34.0
			_cam.look_at(at + Vector3(0, 1.0, 0), Vector3.UP)
	return false

## the way from the entry with the longest run of open floor (so "close" faces into the
## room, not a bare wall a cell away); lamp-ward wins ties
func _open_dir(info: Dictionary, en: Vector3) -> Vector3:
	var G: float = info["grid"]
	var hv: Vector2 = info["half"]
	var cells: Dictionary = info["cells"]
	var c0 := Vector2i(int(round((en.x + hv.x) / G)), int(round((en.z + hv.y) / G)))
	var best := Vector3(0, 0, -1)
	var bn := -1
	for d in [Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
		var n := 0
		var c: Vector2i = c0 + d
		while cells.has(c) and n < 8:
			n += 1
			c += d
		if n > bn:
			bn = n
			best = Vector3(d.x, 0, d.y).normalized()
	return best

## one row per theme, its shots left to right at quarter size
func _sheet() -> void:
	var rows := {}
	var order: Array = []
	for s in _shots:
		if not rows.has(s[0]):
			rows[s[0]] = []
			order.append(s[0])
		(rows[s[0]] as Array).append(s[1])
	var tw := 480
	var th := 270
	var cols := 0
	for k in order:
		cols = maxi(cols, (rows[k] as Array).size())
	var sheet := Image.create(tw * cols, th * order.size(), false, Image.FORMAT_RGB8)
	for r in order.size():
		var files: Array = rows[order[r]]
		for c in files.size():
			var im := Image.load_from_file(ProjectSettings.globalize_path(OUT + "/" + String(files[c])))
			if im == null:
				continue
			im.convert(Image.FORMAT_RGB8)
			im.resize(tw, th, Image.INTERPOLATE_BILINEAR)
			sheet.blit_rect(im, Rect2i(0, 0, tw, th), Vector2i(c * tw, r * th))
	sheet.save_png(ProjectSettings.globalize_path(OUT + "/%s_sheet.png" % _set))
