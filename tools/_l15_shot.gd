extends SceneTree
## L15 render: 1920x1080, the whole interface up - a lord fight below (boss bar,
## party frames), the Chronicle, the Guild Roll, a hero's unit frame - saved full
## size and shrunk to 854x480 (a phone watching the stream), at UI scale 100%
## and 150%. Run with --resolution 1920x1080. renders/cycles/20261111_l15.
var _t: Node3D
var _eye: RtsCamera
var _d: Delve
var _f := 0
var _n := 0
const OUT := "res://renders/cycles/20261111_l15"

func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _save(tag: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + "/%s_1080.png" % tag))
	img.resize(854, 480, Image.INTERPOLATE_LANCZOS)
	img.save_png(ProjectSettings.globalize_path(OUT + "/%s_phone480.png" % tag))
	print("L15_SHOT %s (window %s, scale %.2f)" % [tag, root.size, UiTheme.scale])

func _process(_dt: float) -> bool:
	_f += 1
	if _f == 20:
		_eye = RtsCamera.new()
		_t.add_child(_eye)
		_eye.setup(_t)
		var board := LeaderboardPanel.new()
		_t.add_child(board)
		board.setup(_t.get("roster"))
		var r: Roster = _t.get("roster")
		var ids := []
		for v in [["2301", "JestFan", "knight", "dwarf"], ["2302", "MossyMage", "mage", "elf"], ["2303", "DawnCleric", "cleric", "human"], ["2304", "BigAxe", "barbarian", "orc"]]:
			var h: Dictionary = r.fresh(v[0], v[1], v[2], v[3])
			h["weapon"] = 3
			h["armour"] = 3
			h["oil"] = 4
			h["brews"] = {"ogre": 1, "bravecup": 1}
			ids.append(v[0])
		Bestiary._spent = Bestiary.LESSER.duplicate()
		Bestiary._spent.erase("hollow_king")
		_d = Delve.new()
		_d.town = _t
		_d.roster = r
		_d.start_floor = 5
		_d.max_floors = 5
		_t.add_child(_d)
		_d.start(ids)
		_eye.director._set_on(true)
	if _d and _d.lord_fighting() != null and _n == 0 and _f > 400:
		_n = 1
		_eye.boss_bar.refresh()
		for c in _d.party:
			if (c["body"] as Node3D).is_inside_tree():
				_eye._select(c["body"])
				break
	if _n == 1:
		_n = 2
		_f = 10000
	if _f == 10020:
		_eye.director._set_on(false)
		for c in _t.get_children():
			if c is LeaderboardPanel:
				(c as LeaderboardPanel).visible = true
	if _f == 10030:
		_save("ui100")
		UiTheme.set_scale(1.5)
		_eye.boss_bar.refresh()
	if _f == 10070:
		_save("ui150")
		UiTheme.set_scale(1.0)
		print("L15_SHOT done")
		return true
	if _f > 9000 and _f < 10000:
		print("L15_SHOT no lord fight")
		return true
	return false
