extends SceneTree
## Wait for real catches on the docks and photograph them: the cast/wait,
## the catch in the air, and the catch held up with its name.
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _shots := {}
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _aim(a: Node3D) -> void:
    var p: Vector3 = a.get_parent().global_position
    var fw: Vector3 = a.get_parent().global_transform.basis.z
    var sd := Vector3(-fw.z, 0, fw.x)
    _cam.global_position = p + fw * 2.5 + sd * 7.0 + Vector3(0, 2.4, 0)
    _cam.look_at(p + fw * 2.5 + Vector3(0, 2.0, 0), Vector3.UP)
func _snap(nm: String) -> void:
    root.get_texture().get_image().save_png("user://fish_%s.png" % nm)
    _shots[nm] = true
    print("SAVED ", nm)
func _process(_d: float) -> bool:
    _f += 1
    if _f == 20:
        _cam = Camera3D.new()
        _cam.fov = 55.0
        _t.add_child(_cam)
        _cam.make_current()
        Engine.time_scale = 3.0
    if _f < 25:
        return false
    var anglers: Array = _t.get("anglers")
    if anglers.is_empty():
        print("NO ANGLERS")
        return true
    for a in anglers:
        var st: int = a.state
        if st == 2 and not _shots.has("wait"):
            Engine.time_scale = 1.0
            _aim(a)
            if a._t > 0.3:
                _snap("wait")
                Engine.time_scale = 3.0
            return false
        if st == 4 and a._t > a._dur * 0.45 and not _shots.has("reel"):
            Engine.time_scale = 1.0
            _aim(a)
            _snap("reel")
            return false
        if st == 5 and a._t > 0.4 and not a.has_meta("shot"):
            Engine.time_scale = 1.0
            _aim(a)
            a.set_meta("shot", true)
            _snap("show_%d" % _shots.size())
            print("CATCH ", a.creel.back()["name"], " ", a.creel.back()["rarity"])
            return false
        if st != 5 and a.has_meta("shot"):
            a.remove_meta("shot")
            Engine.time_scale = 3.0
    if _f > 14000 or _shots.size() >= 4:
        print("LOG ", _t.get("fishing_log").size(), " ", _t.get("fishing_log"))
        return true
    return false
