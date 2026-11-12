extends SceneTree
## L17 render: every lane full - bits (gold), subs (purple), points (teal) - around the
## director, one hero down in the scar. Saves the side-by-side and the 2x2 at 1080p and
## shrunk to 854x480, and prints FPS with the panes off / on, alternating over the same
## stretch of play so the sim is the same (L17_FPS).
## Run windowed with --resolution 1920x1080. renders/cycles/20261111_l17.
var _t: Node3D
var _eye: RtsCamera
var _d: Delve
var _f := 0
var _sum := {"off": 0.0, "grid": 0.0}
var _n := {"off": 0, "grid": 0}
var _stash := {}
const OUT := "res://renders/cycles/20261111_l17"

func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _save(tag: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + "/%s_1080.png" % tag))
	img.resize(854, 480, Image.INTERPOLATE_LANCZOS)
	img.save_png(ProjectSettings.globalize_path(OUT + "/%s_phone480.png" % tag))
	print("L17_SHOT %s (window %s)" % [tag, root.size])

func _say(msg: String) -> void:
	var c: ChatCmd = _t.get("chat")
	c._last.clear()
	print("  ", msg, " -> ", _t.call("chat_line", "local_mre", "MrE", msg))

## the panes off (lanes kept aside) or back on
func _grid(on: bool) -> void:
	var s := Spotlight.of(_t)
	if not on:
		_stash = s.lanes.duplicate(true)
		for l in Spotlight.LANES:
			s.lanes[l] = {"cur": {}, "q": []}
	else:
		s.lanes = _stash.duplicate(true)
	s._relayout()

func _process(_dt: float) -> bool:
	_f += 1
	if _f == 20:
		_eye = RtsCamera.new()
		_t.add_child(_eye)
		_eye.setup(_t)
		var c: ChatCmd = _t.get("chat")
		for v in [["2301", "JestFan", "knight dwarf"], ["2302", "MossyMage", "mage elf"], ["2303", "DawnCleric", "cleric human"], ["2304", "BigAxe", "barbarian orc"]]:
			c._last.clear()
			_t.call("chat_line", v[0], v[1], "!enlist " + v[2])
		# BigAxe goes below, so one pane follows a hero into the scar
		_d = Delve.new()
		_d.town = _t
		_d.roster = _t.get("roster")
		_d.start_floor = 2
		_d.max_floors = 2
		_t.add_child(_d)
		_d.start(["2304"])
		_eye.director._set_on(true)
	if _f == 300:
		_say("!testbits 500 bigaxe")
	if _f == 320:
		_save("pair")
		_say("!testsub mossymage")
		_say("!testpoints dawncleric")
		_say("!testpoints jestfan")
	# frames 400-1199: 100-frame blocks, grid / off / grid / off ..., the first 20 of each skipped
	if _f >= 400 and _f < 1200:
		var blk := (_f - 400) / 100
		var k := "grid" if blk % 2 == 0 else "off"
		if (_f - 400) % 100 == 0 and _f > 400:
			_grid(k == "grid")
		if (_f - 400) % 100 >= 20:
			_sum[k] += Engine.get_frames_per_second()
			_n[k] += 1
	if _f == 1200:
		_grid(true)
	if _f == 1230:
		_save("grid")
		print("L17_FPS off %.1f  grid %.1f" % [_sum["off"] / maxi(1, _n["off"]), _sum["grid"] / maxi(1, _n["grid"])])
		Spotlight.of(_t).set_labels(false)
	if _f == 1240:
		_save("grid_nolabels")
		print("L17_SHOT done")
		return true
	return false
