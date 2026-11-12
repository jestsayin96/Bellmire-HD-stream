extends SceneTree
## L14 render: the real town; !help, !help forge and a typo typed as a viewer;
## frame of how the replies read on stream. renders/cycles/20261111_l14.
var _t: Node3D
var _f := 0
func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
func _process(_d: float) -> bool:
	_f += 1
	if _f == 20:
		var eye := RtsCamera.new()
		_t.add_child(eye)
		eye.setup(_t)
		_t.call("chat_line", "7001", "MrE", "!enlist bard halfling")
	if _f == 60:
		_t.call("chat_line", "7001", "MrE", "!help")
	if _f == 160:
		_t.call("chat_line", "7001", "MrE", "!help forge")
	if _f == 260:
		_t.call("chat_line", "7001", "MrE", "!forg")
	if _f == 300:
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://renders/cycles/20261111_l14/help_replies.png"))
		print("L14_SHOT done")
		return true
	return false
