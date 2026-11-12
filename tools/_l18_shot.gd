extends SceneTree
## L18 render: Bree types a command, the director cuts to her - "Now watching" up top,
## her name glowing. Saved at 1080p and shrunk to 854x480. Run windowed with
## --resolution 1920x1080. renders/cycles/20261111_l18.
var _t: Node3D
var _eye: RtsCamera
var _f := 0
const OUT := "res://renders/cycles/20261111_l18"

func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _save(tag: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + "/%s_1080.png" % tag))
	img.resize(854, 480, Image.INTERPOLATE_LANCZOS)
	img.save_png(ProjectSettings.globalize_path(OUT + "/%s_phone480.png" % tag))
	print("L18_SHOT %s" % tag)

func _say(uid: String, nm: String, msg: String) -> void:
	(_t.get("chat") as ChatCmd)._last.erase(uid)
	print("  ", nm, " ", msg, " -> ", _t.call("chat_line", uid, nm, msg))

func _process(_dt: float) -> bool:
	_f += 1
	if _f == 20:
		_eye = RtsCamera.new()
		_t.add_child(_eye)
		_eye.setup(_t)
		for v in [["9101", "Ash", "!enlist knight dwarf"], ["9102", "Bree", "!enlist mage elf"], ["9103", "Cole", "!enlist rogue halfling"]]:
			_say(v[0], v[1], v[2])
		_eye.director._set_on(true)
	if _f == 300:
		for u in ["9101", "9102", "9103"]:
			ChatCmd.last_cmd[u] = Time.get_ticks_msec() - 130000
		_say("9102", "Bree", "!hero")
		var d: AutoDirector = _eye.director
		d._cut(d._best())
	if _f == 400:
		_save("now_watching")
	if _f == 410:
		return true
	return false
