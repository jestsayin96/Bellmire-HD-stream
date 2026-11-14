extends SceneTree
## D51: prove the angler's rod is parented to the body's right-hand bone, not
## floating at a fixed body offset. Inspect the node tree + report the hand
## bone's rest orientation so the grip rotation can be judged.
var _t: Node3D
var _f := 0
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _process(_d: float) -> bool:
    _f += 1
    if _f < 60:
        return false
    var anglers: Array = _t.get("anglers")
    if anglers.is_empty():
        print("D51_TEST FAIL: no anglers")
        return true
    var ok_all := true
    var n := 0
    for a in anglers:
        n += 1
        var holder: Node = a.get_parent()
        var sk: Skeleton3D = Rig.skeleton(holder)
        if sk == null:
            print("D51 angler %d: FAIL no skeleton" % n); ok_all=false; continue
        var hb := -1
        var hbn := ""
        for bn in ["handslot.r","handslot.l","Hand.R","hand.r","hand_r"]:
            if sk.find_bone(bn) >= 0:
                hb = sk.find_bone(bn); hbn = bn; break
        var mount = a._rod_mount
        var pivot = a._rod_pivot
        var tip = a._rod_tip
        # is tip a descendant of the skeleton? (=> hand-parented)
        var under_sk := false
        var p: Node = tip
        while p != null:
            if p == sk:
                under_sk = true; break
            p = p.get_parent()
        var mount_ok := (mount != null) and (mount is BoneAttachment3D)
        if n == 1:
            print("D51 hand bone=", hbn, " idx=", hb)
            if hb >= 0:
                var rest: Transform3D = sk.get_bone_global_rest(hb)
                print("D51 hand rest basis x=", rest.basis.x, " y=", rest.basis.y, " z=", rest.basis.z)
            print("D51 mount=", mount, " bone=", (mount.bone_name if mount_ok else "-"),
                  " pivot=", pivot, " tip_under_skeleton=", under_sk)
        if not (mount_ok and under_sk and hb >= 0):
            ok_all = false
            print("D51 angler %d FAIL: mount_ok=%s under_sk=%s hb=%d" % [n, str(mount_ok), str(under_sk), hb])
    print("D51_TEST ", ("OK" if ok_all else "FAIL"), " (", anglers.size(), " anglers)")
    return true
