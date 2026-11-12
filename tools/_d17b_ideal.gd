extends SceneTree
## D17b helper: the probe's slide figure for a PERFECT match - the clip played
## in place while the body moves at exactly its GAIT_MPS - so the probe has a
## floor to compare against (the ankle rolls heel-to-toe even on a planted foot).
const ADV := "res://addons/kaykit_character_pack_adventures/Characters/gltf/"
var _f := 0
func _process(_d: float) -> bool:
    _f += 1
    if _f < 2:
        return false
    var n: Node3D = (load(ADV + "Rogue.glb") as PackedScene).instantiate()
    root.add_child(n)
    var ap := Rig.find(n)
    var sk := Rig.skeleton(n)
    var il := sk.find_bone("foot.l")
    var ir := sk.find_bone("foot.r")
    for c in ["Walking_A", "Running_B", "Running_A"]:
        for s in [1.0, 2.0]:
            var L := ap.get_animation(c).length
            var nat: float = Rig.GAIT_MPS[c]
            var dt := 1.0 / 60.0
            var N := int(L / s / dt) * 3
            var a1: Array = []
            var a2: Array = []
            var prev := []
            var mn := INF
            for k in range(N):
                var t := fmod(float(k) * dt * s, L)
                ap.play(c)
                ap.seek(t, true)
                var off := Vector3(0, 0, nat * s * float(k) * dt)
                var pl: Vector3 = (sk.global_transform * sk.get_bone_global_pose(il)).origin + off
                var pr: Vector3 = (sk.global_transform * sk.get_bone_global_pose(ir)).origin + off
                mn = minf(mn, minf(pl.y, pr.y))
                var low := 0 if pl.y < pr.y else 1
                var lp := pl if low == 0 else pr
                var clear := absf(pl.y - pr.y) > 0.03
                if not prev.is_empty() and prev[0] == low and clear and prev[2]:
                    var fd := Vector2(lp.x - (prev[1] as Vector3).x, lp.z - (prev[1] as Vector3).z).length() / dt
                    a1.append(fd)
                    if lp.y < mn + 0.02:
                        a2.append(fd)
                prev = [low, lp, clear]
            a1.sort()
            a2.sort()
            print("IDEAL %s x%.1f clear3cm median=%.2f p90=%.2f | grounded2cm median=%.2f p90=%.2f n=%d" % [c, s, a1[a1.size() / 2], a1[int(a1.size() * 0.9)], a2[a2.size() / 2] if a2.size() > 0 else -1.0, a2[int(a2.size() * 0.9)] if a2.size() > 0 else -1.0, a2.size()])
    n.free()
    return true
