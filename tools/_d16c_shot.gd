extends SceneTree
## D16c render: the wagons that move. The camera rides over the pedlar's cart
## (drawn up beside her on open ground at the market) and over a carter's wagon
## on the street, and townsfolk step round them. The camera is made current
## EVERY frame (the town's RTS camera took the D16b shot back).
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _out := ""
const SHOTS := [[20, "pedlar"], [40, "carter"], [60, "pedlar"], [75, "carter"], [95, "pedlar"], [110, "carter"]]
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _out = ProjectSettings.globalize_path("res://renders/cycles/20261112_d16c")
    DirAccess.make_dir_recursive_absolute(_out)
    _cam = Camera3D.new()
    _cam.fov = 48.0
    _t.add_child(_cam)

func _wagon(role: String) -> Array:
    for e in _t.call("_wagons"):
        if String(e[1].role) == role:
            return e
    return []

func _process(_d: float) -> bool:
    _f += 1
    var which := "pedlar"
    for s in SHOTS:
        if _f <= int(s[0]) * 60:
            which = String(s[1])
            break
    var e := _wagon(which)
    if not e.is_empty():
        var c: Vector2 = e[2]
        var tgt := Vector3(c.x, float(e[6]) + 0.6, c.y)
        _cam.global_position = tgt + Vector3(7.0, 11.0, 9.0)
        _cam.look_at(tgt, Vector3.UP)
    _cam.make_current()
    for s in SHOTS:
        if _f == int(s[0]) * 60:
            var near := 0
            for v in _t.get("people"):
                if not e.is_empty() and not v.inside and Vector2(v.global_position.x, v.global_position.z).distance_to(e[2]) < 6.0:
                    near += 1
            root.get_texture().get_image().save_png(_out + "/%s_%03ds.png" % [s[1], s[0]])
            print("SAVED %s_%03ds near=%d" % [s[1], s[0], near])
    return _f >= 112 * 60
