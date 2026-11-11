extends SceneTree
## Director test: real town, RtsCamera + director on at 4x speed, a viewer delve
## and the town band running. Logs every cut and saves a frame at the first few.
var _t: Node3D
var _eye: RtsCamera
var _f := 0
var _shots := 0
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _process(_d: float) -> bool:
    _f += 1
    if _f == 20:
        _eye = RtsCamera.new()
        _t.add_child(_eye)
        _eye.setup(_t)
        var board := LeaderboardPanel.new()
        _t.add_child(board)
        board.setup(_t.roster)
        for u in ["1001", "1002", "1003"]:
            _t.chat_line(u, "Viewer" + u, "!enlist knight")
        for u in ["1001", "1002", "1003"]:
            _t.chat_line(u, "Viewer" + u, "!delve")
    if _f == 40:
        _eye.director._set_on(true)
        Engine.time_scale = 4.0
    if _f > 40 and _f % 240 == 0 and _shots < 6:
        root.get_texture().get_image().save_png("user://dir_%d.png" % _shots)
        print("SHOT dir_%d cur=%s" % [_shots, _eye.director._cur.get("key", "-")])
        _shots += 1
    if _f >= 1300:
        print("DIRECTOR_TEST done")
        return true
    return false
