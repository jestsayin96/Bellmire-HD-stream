extends SceneTree
## L31 LOOK (U26): the "NOW FIGHTING" banner when a lord rises, full screen and on the 2x2 grid.
## WINDOWED 1920x1080, no --headless. renders/cycles/20261115_u26. Prints U26_SHOT lines.
var _t: Node3D
var _eye: RtsCamera
var _d: Delve
var _f := 0
var _stage := "boot"
var _at := 0
const OUT := "res://renders/cycles/20261115_u26"

func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _say(uid: String, nm: String, msg: String) -> void:
	var c: ChatCmd = _t.get("chat")
	c._last.clear()
	_t.call("chat_line", uid, nm, msg)

func _banner():
	return _t.get_node_or_null("FightBanner")

func _save(tag: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + "/%s_1080.png" % tag))
	var fb = _banner()
	var pl: Control = fb._plate if fb else null
	var cb := HudDock.centre(_t)
	if pl:
		var r := Rect2(pl.global_position, pl.size * pl.scale)
		print("U26_SHOT %s banner vis=%s rect=%s a=%.2f chronicle=%s overlap=%s window=%s" % [tag, pl.visible, r, pl.modulate.a, cb, r.intersects(cb) if cb.size.x > 0 else false, root.size])
		if pl.visible:
			var box := Rect2i(Vector2i(r.position) - Vector2i(30, 30), Vector2i(r.size) + Vector2i(60, 60)).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
			img.get_region(box).save_png(ProjectSettings.globalize_path(OUT + "/%s_crop.png" % tag))
	else:
		print("U26_SHOT %s NO BANNER NODE" % tag)

func _rearm() -> void:
	var fb = _banner()
	if fb:
		fb._t = fb.HOLD

func _process(_dt: float) -> bool:
	_f += 1
	match _stage:
		"boot":
			if _f == 20:
				_eye = RtsCamera.new()
				_t.add_child(_eye)
				_eye.setup(_t)
				var r: Roster = _t.get("roster")
				for v in [["2101", "JestFan", "knight dwarf"], ["2102", "MossyMage", "mage elf"], ["2103", "DawnCleric", "cleric human"], ["2104", "BigAxe", "barbarian orc"]]:
					_say(v[0], v[1], "!enlist " + v[2])
				for id in ["2101", "2104"]:
					var h: Dictionary = r.get_hero(id)
					h["weapon"] = 3
					h["armour"] = 3
					h["oil"] = 4
				_d = Delve.new()
				_d.town = _t
				_d.roster = r
				_d.start_floor = 5
				_d.max_floors = 5
				_t.add_child(_d)
				_d.start(["2104", "2101"])
				_eye.director._set_on(true)
				Engine.time_scale = 3.0
				_stage = "wait_lord"
		"wait_lord":
			if _d.lord_fighting() != null or _f > 3500:
				Engine.time_scale = 1.0
				print("U26_SHOT lord fighting=", _d.lord_fighting() != null, " frame ", _f)
				_stage = "full"
				_at = _f
		"full":
			if _f - _at == 25:
				_rearm()
				_save("1_full")
				_say("local_mre", "MrE", "!testbits 500 bigaxe")
				_say("local_mre", "MrE", "!testsub mossymage")
				_say("local_mre", "MrE", "!testpoints dawncleric")
				_stage = "grid"
				_at = _f
		"grid":
			if _f - _at == 100:
				_rearm()
			if _f - _at == 110:
				_save("2_grid")
				print("U26_SHOT done")
				return true
	if _f > 5000:
		print("U26_SHOT timed out in ", _stage)
		return true
	return false
