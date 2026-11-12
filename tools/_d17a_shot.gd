extends SceneTree
## D17a render: close-ups of bodies just after a one-shot - a fallen raider (in
## his held Death _Pose), a smith or farmer after a PickUp, the crier after a
## Cheer, a fisher after an Interact - each named with the clip it is in.
## Windowed, --fixed-fps 60, [-- --old] -> renders/cycles/20261112_d17a.
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _tag := "new"
var _out := ""
var _done := {}

func _initialize() -> void:
    if OS.get_cmdline_user_args().has("--old"):
        Rig.fallback = false
        _tag = "old"
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _out = ProjectSettings.globalize_path("res://renders/cycles/20261112_d17a")
    DirAccess.make_dir_recursive_absolute(_out)

func _pick(roles: Array, pre: String, lead: String) -> Townsfolk:
    for v in _t.get("people"):
        if not is_instance_valid(v) or v.inside or not v.visible or v._anim == null:
            continue
        if not String(v.role) in roles:
            continue
        var ca := String(v._anim.current_animation)
        var aa := String(v._anim.assigned_animation)
        if (pre == "" and ca == "" and aa.begins_with(lead)) or (pre != "" and ca.begins_with(pre)):
            return v
    return null

func _process(_d: float) -> bool:
    _f += 1
    if _f == 60:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.fov = 40.0
    if _f == 240:
        var rd = _t.get("raids")
        if rd:
            rd.force_level = 5
            rd.call("raid", "west")
    if _cam and _f > 60 and _cam != root.get_viewport().get_camera_3d():
        _cam.make_current()
    if _f > 600 and _f % 20 == 0:
        var tests := {
            "fallen": [["bandit"], "Death_A_Pose" if _tag == "new" else "", "Death"],
            "worker": [["blacksmith", "farmer"], "Idle" if _tag == "new" else "", "PickUp"],
            "crier": [["crier"], "Idle" if _tag == "new" else "", "Cheer"],
        }
        for k in tests.keys():
            if _done.has(k):
                continue
            var a: Array = tests[k]
            var v := _pick(a[0], a[1], a[2])
            if v == null:
                continue
            var p: Vector3 = v.global_position
            var fw: Vector3 = v.global_transform.basis.z
            _cam.global_position = p + fw * 3.2 + Vector3(0.6, 1.9, 0)
            _cam.look_at(p + Vector3(0, 0.6, 0), Vector3.UP)
            _done[k] = [v, _f + 2, "%s_%s %s %s cur=%s last=%s" % [k, _tag, v.role, v.person_name, v._anim.current_animation, v._anim.assigned_animation]]
            break
    for k in _done.keys():
        if _done[k] is Array and _f == int(_done[k][1]):
            root.get_texture().get_image().save_png(_out + "/%s_%s.png" % [k, _tag])
            print("SAVED ", _done[k][2])
            _done[k] = true
    return _f >= 60 * 70 or (_done.size() == 3 and not (_done.values().any(func(x): return x is Array)))
