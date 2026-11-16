extends SceneTree
## D90 probe: where the Prop_Wagon mesh actually sits in its own node space
## (its AABB per mesh, local), so the hitch can be put at the SHAFT TIPS.
func _initialize() -> void:
    var path := "res://assets/mkprops/Prop_Wagon.gltf"
    if not ResourceLoader.exists(path):
        path = "res://assets/mkprops/Prop_Wagon.glb"
    var n: Node3D = (load(path) as PackedScene).instantiate()
    root.add_child(n)
    var inv := n.global_transform.affine_inverse()
    var st: Array = [n]
    var all := AABB()
    var first := true
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is MeshInstance3D:
            var mi: MeshInstance3D = c
            var ab: AABB = (inv * mi.global_transform) * mi.get_aabb()
            print("MESH %s pos=%s size=%s" % [mi.name, str(ab.position), str(ab.size)])
            all = ab if first else all.merge(ab)
            first = false
            var m := mi.mesh
            for si in m.get_surface_count():
                var arr := m.surface_get_arrays(si)
                var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
                # vertex extremes along each axis, in node space
                var xf := inv * mi.global_transform
                var mnx := Vector3.INF
                var mxx := -Vector3.INF
                var bins := {}
                for v in vs:
                    var p: Vector3 = xf * v
                    var bx := int(floor(p.x * 4.0))
                    if not bins.has(bx):
                        bins[bx] = [INF, -INF, INF, -INF, 0]
                    var b: Array = bins[bx]
                    b[0] = minf(b[0], p.z); b[1] = maxf(b[1], p.z); b[2] = minf(b[2], p.y); b[3] = maxf(b[3], p.y); b[4] = int(b[4]) + 1
                var ks := bins.keys()
                ks.sort()
                for k in ks:
                    var b2: Array = bins[k]
                    print("  x=[%.2f,%.2f) z=[%.2f,%.2f] y=[%.2f,%.2f] n=%d" % [k / 4.0, (k + 1) / 4.0, b2[0], b2[1], b2[2], b2[3], b2[4]])
    print("ALL pos=%s size=%s centre=%s" % [str(all.position), str(all.size), str(all.get_center())])
    quit()
