extends SceneTree
## D17b render: a walker side-on, camera tracking at its pace, 4 frames 0.1 s
## apart - planted feet should stay put on the street (new) instead of the
## legs paddling at a third of the body's speed (old). Also one shot of a
## running raider / child. Windowed, --fixed-fps 60, [-- --old]
## -> renders/cycles/20261112_d17b.
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _tag := "new"
var _out := ""
var _who: Townsfolk = null
var _shots := 0
var _side := Vector3.ZERO
var _kind := "walk"

func _initialize() -> void:
    if OS.get_cmdline_user_args().has("--old"):
        Rig.gait = false
        Townsfolk.pace = 0.62
        Townsfolk.face_fix = false
        _tag = "old"
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _out = ProjectSettings.globalize_path("res://renders/cycles/20261112_d17b")
    DirAccess.make_dir_recursive_absolute(_out)

func _pick(want: String) -> Townsfolk:
    var best: Townsfolk = null
    for v in _t.get("people"):
        if not is_instance_valid(v) or v.inside or not v.visible or v._anim == null or v is Cavalry:
            continue
        if String(v._anim.current_animation) != want or v._route.size() < 4 or v._vs < 0.3 and _tag == "new":
            continue
        if want == "Walking_A" and v.size_k != 1.0:
            continue
        best = v
        break
    return best

func _process(_d: float) -> bool:
    _f += 1
    if _f == 60:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.fov = 32.0
    if _cam and _f > 60 and _cam != root.get_viewport().get_camera_3d():
        _cam.make_current()
    if _f > 900 and _who == null and _f % 10 == 0:
        _who = _pick("Walking_A")
        if _who:
            print("WALKER ", _who.role, " ", _who.person_name, " speed_scale=", _who._anim.speed_scale)
    if _who and is_instance_valid(_who):
        var p := _who.global_position
        var fw := _who.global_basis.z
        if _side == Vector3.ZERO:
            _side = fw.cross(Vector3.UP).normalized()
        _cam.global_position = p + _side * 3.4 + Vector3(0, 0.9, 0)
        _cam.look_at(p + Vector3(0, 0.55, 0), Vector3.UP)
        if _f % 6 == 0 and _shots < 4:
            await_shot()
    return _f >= 60 * 50 or _shots >= 4

func await_shot() -> void:
    _shots += 1
    root.get_texture().get_image().save_png(_out + "/walk_%s_%d.png" % [_tag, _shots])
    print("SAVED walk_%s_%d clip=%s ss=%.2f" % [_tag, _shots, _who._anim.current_animation, _who._anim.speed_scale])
