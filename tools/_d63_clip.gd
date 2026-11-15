extends SceneTree
## D63 CLIP: one festival start to finish, then a viewer-bought one at dusk - for
## the DONE's "short clip". Run WINDOWED with the movie writer, e.g.
##   <console> --path . --write-movie <tmp>/d63.avi --fixed-fps 30 --script res://tools/_d63_clip.gd
## then ffmpeg it to renders/cycles/d63/d63_festival_clip.mp4. Env D63_LORE (optional)
## = a lore_lines.json carrying C6 "festivals", to show the words before content merges.
## Timeline at 30 fps: boot/enlist (~8 s), market festival ~40 s (ends on its own),
## struck square ~5 s, dusk, a 500-bit Festival of Plenty ~22 s.
var _t: Node3D
var _cam: Camera3D
var _f := 0
var phase := "warm"
var _mark := 0
var _clock := 0.50
var _ang := 0.0

func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)

func _aim(delta: float) -> void:
	var mk = _t.get("_market_pos")
	var c: Vector3 = mk if mk is Vector3 and mk != Vector3.ZERO else Vector3.ZERO
	_ang += delta * 0.06                        # a slow orbit, so it reads as footage, not a still
	var r := 22.0
	_cam.global_position = c + Vector3(cos(_ang) * r, 12.0, sin(_ang) * r)
	_cam.look_at(Vector3(c.x, 2.0, c.z), Vector3.UP)

func _lore() -> void:
	var p := OS.get_environment("D63_LORE")
	if p == "":
		return
	var f := FileAccess.open(p, FileAccess.READ)
	if f:
		var d = JSON.parse_string(f.get_as_text())
		if d is Dictionary and (d as Dictionary).get("festivals") is Dictionary:
			_t.set("_fest_lore", d["festivals"])
			_t.set("_fest_lore_ok", true)
			print("CLIP lore from ", p)

func _process(delta: float) -> bool:
	_f += 1
	var eco = _t.get("economy")
	if _f == 20:
		_cam = Camera3D.new(); _t.add_child(_cam); _cam.fov = 55.0
		root.get_window().size = Vector2i(1920, 1080)
		_lore()
	if _cam and _cam != root.get_viewport().get_camera_3d():
		_cam.make_current()
	if eco and _f >= 20:
		eco.clock = _clock
		eco._dis_cool = 1e9
	var rd = _t.get("raids")
	if rd and _f > 10:
		rd.set("_raid_t", 9999.0)
	if _cam:
		_aim(delta)
	match phase:
		"warm":
			if _f == 60:
				_t.call("chat_line", "d63a", "D63Alda", "!enlist")
				_t.call("chat_line", "d63b", "D63Bram", "!enlist")
				_t.set("_fest_t", 9999.0)
			if _f >= 240:
				_t.set("_fest_gap", 999.0)
				_t.call("start_festival", "market")
				_t.set("_fest_left", 40.0)
				print("CLIP fest open: ", (_t.get("feed") as Array).back())
				phase = "fest"; _mark = _f
		"fest":
			if not bool(_t.get("festival")):
				print("CLIP fest close: ", (_t.get("feed") as Array).back())
				phase = "after"; _mark = _f
		"after":
			if _f - _mark >= 150:
				_clock = 0.80
				var es := TwitchEventSub.new()
				es.set("town", _t)
				root.add_child(es)
				es.call("_do_bits_tier", "d63a", 500, "MrEsBestViewer")
				print("CLIP gift open: ", (_t.get("feed") as Array).back())
				phase = "gift"; _mark = _f
		"gift":
			if _f - _mark >= 660:
				print("CLIP done f=", _f, " barks=", _t.get("fest_barks"), " news=", _t.get("fest_news"))
				return true
	if _f > 4000:
		return true
	return false
