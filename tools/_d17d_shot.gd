extends SceneTree
## D17d render: a townsfolk walking in view falls (town.bury - the same fall a
## raid gives) and is watched for 10 s: frames at 0, 0.3, 1, 2, 5 and 10 s
## after. Before (`-- --old`), the gait picked the body straight back up out of
## its held Death pose into an idle; now it stays down. Windowed,
## --fixed-fps 60 -> renders/cycles/20261112_d17d/fall_<tag>_<n>.png
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _tag := "new"
var _out := ""
var _v: Townsfolk = null
var _at := 0
const SHOTS := [0, 18, 60, 120, 300, 600]
var _n := 0

func _initialize() -> void:
    if OS.get_cmdline_user_args().has("--old"):
        Rig.smooth = false
        _tag = "old"
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _out = ProjectSettings.globalize_path("res://renders/cycles/20261112_d17d")
    DirAccess.make_dir_recursive_absolute(_out)

func _process(_d: float) -> bool:
    _f += 1
    if _f == 60:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.fov = 45.0
    if _cam and _f > 60 and _cam != root.get_viewport().get_camera_3d():
        _cam.make_current()
    if _v == null and _f > 900 and _f % 10 == 0:
        for v in _t.get("people"):
            if not is_instance_valid(v) or v.inside or not v.visible or v._anim == null or v is HeroBody:
                continue
            if String(v.role) in ["peasant", "farmer", "baker", "washer", "trader"] and String(v._anim.current_animation) == "Walking_A":
                _v = v
                break
        if _v:
            var p: Vector3 = _v.global_position
            var fw: Vector3 = _v.global_transform.basis.z
            var side: Vector3 = _v.global_transform.basis.x
            _cam.global_position = p + fw * 3.0 + side * 2.2 + Vector3(0, 2.4, 0)
            _cam.look_at(p + fw * 0.6 + Vector3(0, 0.4, 0), Vector3.UP)
            _t.call("bury", _v, "D17D render")
            _at = _f
            print("FALL ", _v.person_name, " role=", _v.role)
    if _v != null and _n < SHOTS.size() and _f == _at + 2 + int(SHOTS[_n]):
        var cur := String(_v._anim.current_animation) if is_instance_valid(_v) else "?"
        root.get_texture().get_image().save_png(_out + "/fall_%s_%d.png" % [_tag, _n])
        print("SAVED fall_%s_%d t=%.1fs cur=%s" % [_tag, _n, SHOTS[_n] / 60.0, cur])
        _n += 1
    return _n >= SHOTS.size() or _f > 60 * 90
