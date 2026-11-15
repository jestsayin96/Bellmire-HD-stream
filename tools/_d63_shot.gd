extends SceneTree
## D63 LOOK: the market square before a festival, a market-day festival in full swing
## (dressed, crowd acting, heroes in it), the square struck after, and a VIEWER-BOUGHT
## festival at dusk (gold dressing, lanterns lit). Windowed 1920x1080 ->
## renders/cycles/d63/*.png
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _out := ""
var phase := "warm"
var _mark := 0
var _clock := 0.50

func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	_out = ProjectSettings.globalize_path("res://renders/cycles/d63")
	DirAccess.make_dir_recursive_absolute(_out)

func _aim(close := false) -> void:
	var mk = _t.get("_market_pos")
	var c: Vector3 = mk if mk is Vector3 and mk != Vector3.ZERO else Vector3.ZERO
	if close:
		_cam.global_position = c + Vector3(17, 11, 17)
	else:
		_cam.global_position = c + Vector3(24, 20, 24)
	_cam.look_at(Vector3(c.x, 2.0, c.z), Vector3.UP)

func _save(k: String) -> void:
	root.get_texture().get_image().save_png(_out + "/%s.png" % k)
	print("SAVED ", k, " feed: ", (_t.get("feed") as Array).back())

func _process(_d: float) -> bool:
	_f += 1
	var eco = _t.get("economy")
	if _f == 60:
		_cam = Camera3D.new(); _t.add_child(_cam); _cam.fov = 55.0
		root.get_window().size = Vector2i(1920, 1080)
	if _cam and _f > 60 and _cam != root.get_viewport().get_camera_3d():
		_cam.make_current()
	if eco and _f >= 60:
		eco.clock = _clock
		eco._dis_cool = 1e9
	var rd = _t.get("raids")
	if rd and _f > 30:
		rd.set("_raid_t", 9999.0)
	if _cam:
		_aim(phase == "fest" or phase == "gift")
	if phase == "warm" and _f == 500:
		_t.call("chat_line", "d63a", "D63Alda", "!enlist")
		_t.call("chat_line", "d63b", "D63Bram", "!enlist")
	if phase == "warm" and _f >= 700:
		_t.set("_fest_t", 9999.0)
		_save("1_square_before")
		_t.call("start_festival", "market")
		_t.set("_fest_left", 999.0)
		phase = "fest"; _mark = _f
	elif phase == "fest" and _f - _mark >= 1500:
		_save("2_festival_day")
		_t.set("_fest_left", 0.0)
		phase = "after"; _mark = _f
	elif phase == "after" and _f - _mark >= 120:
		_save("3_square_struck")
		_clock = 0.80
		phase = "dusk"; _mark = _f
	elif phase == "dusk" and _f - _mark >= 300:
		var es := TwitchEventSub.new()
		es.set("town", _t)
		root.add_child(es)
		es.call("_do_bits_tier", "d63a", 500, "MrEsBestViewer")
		phase = "gift"; _mark = _f
	elif phase == "gift" and _f - _mark >= 1500:
		_save("4_viewer_festival_dusk")
		return true
	return false
