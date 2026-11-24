extends SceneTree
## S108 renders: System 11 UAA animals - Bull, Donkey, Alpaca in the paddock; Husky, Shiba
## on the square; Fox, Deer, Stag, Wolf at the woods edge. Prints S108_SHOTS OK|FAIL n/m.
## Windowed. -> renders/cycles/20261124_s108/
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _steps: Array = []
var _dir := ""

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _dir = ProjectSettings.globalize_path("res://renders/cycles/20261124_s108/")
    DirAccess.make_dir_recursive_absolute(_dir)

func _eye(at: Vector3, from: Vector3) -> void:
    # never under the hill: keep the eye above the ground it stands over
    from.y = maxf(from.y, float(_t.call("height_at", from.x, from.z)) + 1.2)
    _cam.global_position = from
    _cam.look_at(at, Vector3.UP)

func _first(kind: String, nth := 0) -> Animal:
    var n := 0
    for a in _t.get("animals"):
        if (a as Animal).kind == kind:
            if n == nth:
                return a
            n += 1
    return null

func _near(a: Animal, dist: float, up: float, ang: float, look_up := 0.3) -> void:
    if a == null:
        return
    var p := a.global_position
    _eye(p + Vector3(0, look_up, 0), p + Vector3(cos(ang) * dist, up, sin(ang) * dist))

