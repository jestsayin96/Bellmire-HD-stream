extends SceneTree
## D17b: how fast does each KayKit locomotion clip walk? The clips are in place,
## so a planted foot slides back under the hips at the ground speed the clip
## was authored for. For each foot, the frames it is down (within `tol` of its
## lowest) are taken; its travel over them / their time = the clip's m/s
## (model scale 1). Rig.GAIT_MPS comes from this. --headless --script.
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
    for c in ["Walking_A", "Walking_B", "Walking_C", "Running_A", "Running_B"]:
        var L := ap.get_animation(c).length
        var N := 480
        ap.play(c)
        var data := {}
        for fb in ["foot.l", "foot.r"]:
            var bi := sk.find_bone(fb)
            var ps: Array = []
            for k in range(N):
                ap.seek(L * float(k) / float(N), true)
                ps.append((sk.global_transform * sk.get_bone_global_pose(bi)).origin)
            data[fb] = ps
        var line := "GAIT %s len=%.3f" % [c, L]
        var zr := 0.0
        for tol in [0.02, 0.04, 0.07]:
            var tot := 0.0
            var tt := 0.0
            for fb in data.keys():
                var ps: Array = data[fb]
                var mn := INF
                var zmin := INF
                var zmax := -INF
                for p in ps:
                    mn = minf(mn, (p as Vector3).y)
                    zmin = minf(zmin, (p as Vector3).z)
                    zmax = maxf(zmax, (p as Vector3).z)
                zr = zmax - zmin
                for k in range(N):
                    var k2 := (k + 1) % N
                    if (ps[k] as Vector3).y < mn + tol and (ps[k2] as Vector3).y < mn + tol:
                        var dv: Vector3 = ps[k2] - ps[k]
                        tot += Vector2(dv.x, dv.z).length()
                        tt += L / float(N)
            line += "  tol%.2f: %.3f m/s (down %.2f)" % [tol, tot / maxf(tt, 0.001), tt / (2.0 * L)]
        line += "  foot z range %.2f -> stride/cycle %.2f m/s if half-cycle stance" % [zr, 2.0 * zr / L]
        print(line)
    n.free()
    return true
