extends SceneTree
## D94 probe: where the KayKit bones a worn piece hangs from actually are (rest pose), in the
## model's own space, with each bone's axes - so a piece is placed by measurement, not by eye.
var _f := 0
var _m: Node3D
func _initialize() -> void:
    var r := Roster.new()
    root.add_child(r)
    var cls := OS.get_environment("D94_CLASS") if OS.get_environment("D94_CLASS") != "" else "knight"
    _m = (load("res://addons/kaykit_character_pack_adventures/Characters/gltf/" + String(Roster.CLASSES[cls]["model"])) as PackedScene).instantiate()
    root.add_child(_m)
    var ap := Rig.find(_m)
    if ap and OS.get_environment("D94_IDLE") != "":
        Rig.prep(ap)
        Rig.play(ap, "Idle")
func _process(_d: float) -> bool:
    _f += 1
    if _f < (40 if OS.get_environment("D94_IDLE") != "" else 5):
        return false
    var sk := Gear.skeleton(_m)
    print("D94_BONES skeleton global scale ", sk.global_transform.basis.get_scale())
    for b in ["hips", "spine", "chest", "neck", "head", "upperarm.l", "lowerarm.l", "hand.l", "handslot.l", "hand.r", "upperleg.l", "lowerleg.l", "foot.l", "toes.l"]:
        var i := sk.find_bone(b)
        if i < 0:
            print("D94_BONES %s missing" % b)
            continue
        var t := sk.global_transform * sk.get_bone_global_pose(i)
        var bs := t.basis.orthonormalized()
        print("D94_BONES %-11s pos %s  x %s  y %s  z %s  len-scale %s" % [b, t.origin.snapped(Vector3.ONE * 0.01), bs.x.snapped(Vector3.ONE * 0.01), bs.y.snapped(Vector3.ONE * 0.01), bs.z.snapped(Vector3.ONE * 0.01), t.basis.get_scale().snapped(Vector3.ONE * 0.01)])
    for c in _m.find_children("*", "MeshInstance3D", true, false):
        var mi: MeshInstance3D = c
        var ab := mi.global_transform * mi.get_aabb()
        print("D94_MESH %-22s min %s max %s" % [mi.name, ab.position.snapped(Vector3.ONE * 0.01), ab.end.snapped(Vector3.ONE * 0.01)])
    return true
