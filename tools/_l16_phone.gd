extends SceneTree
## L16 phone test (Mr. E): the market square at 1920x1080 - heroes with cosmetic
## titles (one selected), the town crier calling - saved full size and shrunk to
## 854x480; then F9 (every title). Run with --resolution 1920x1080.
## renders/cycles/20261111_l16_phone.
var _t: Node3D
var _eye: RtsCamera
var _f := 0
const OUT := "res://renders/cycles/20261111_l16_phone"

func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _save(tag: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + "/%s_1080.png" % tag))
	img.resize(854, 480, Image.INTERPOLATE_LANCZOS)
	img.save_png(ProjectSettings.globalize_path(OUT + "/%s_phone480.png" % tag))
	print("PHONE_SHOT ", tag)

func _process(_dt: float) -> bool:
	_f += 1
	if _f == 20:
		_eye = RtsCamera.new()
		_t.add_child(_eye)
		_eye.setup(_t)
		var r: Roster = _t.get("roster")
		var who := [["8001", "JestFan", "knight dwarf", "keeper of the door"], ["8002", "MossyMage", "mage elf", "bell without"],
			["8003", "DawnCleric", "cleric human", "friend of the ford"], ["8004", "BigAxe", "barbarian orc", "scarwalker"]]
		for w in who:
			_t.call("chat_line", w[0], w[1], "!enlist " + String(w[2]))
			var h: Dictionary = r.get_hero(w[0])
			h["gold"] = 9999
			r.wear(w[0], String(w[3]))
	if _f == 60:
		# the square, from the stream's usual height
		var crier: Node3D = null
		for p in _t.get("people"):
			if is_instance_valid(p) and String((p as Townsfolk).role) == "crier":
				crier = p
		var hs: Dictionary = _t.get("heroes")
		var i := 0
		for uid in ["8001", "8002", "8003", "8004"]:
			var b: Node3D = hs.get(uid)
			if b and crier:
				b.global_position = crier.global_position + Vector3(-3.0 + float(i) * 1.6, 0, 2.5)
				(b as HeroBody).refresh()
			i += 1
		_eye._select(hs.get("8001"))
		if crier:
			_eye.focus = crier.global_position + Vector3(0, 0, 1.5)
			(crier as Townsfolk)._shout_t = 0.0
	if _f == 200:
		_save("square_selected")
		_eye.titles_all = true
		_eye._titles_t = 0.0
	if _f == 230:
		_save("square_all_titles")
		print("PHONE_SHOT done")
		return true
	return false
