extends SceneTree
func _sk(n: Node) -> Skeleton3D:
    var st: Array = [n]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is Skeleton3D:
            return c
        for g in c.get_children():
            st.append(g)
    return null
func _ap(n: Node) -> AnimationPlayer:
    var st: Array = [n]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is AnimationPlayer:
            return c
        for g in c.get_children():
            st.append(g)
    return null
func _initialize() -> void:
    for p in ["res://assets/monsters/Imp.glb", "res://assets/monsters/UAL1.glb"]:
        var n: Node3D = (load(p) as PackedScene).instantiate()
        root.add_child(n)
        var sk := _sk(n)
        var b := []
        for i in range(mini(sk.get_bone_count(), 70)):
            b.append(sk.get_bone_name(i))
        var ap := _ap(n)
        print("SK ", p.get_file(), " path=", n.get_path_to(sk), " bones=", sk.get_bone_count(), " ", b.slice(0, 25))
        if ap:
            print("AP ", p.get_file(), " ", ap.get_animation_list().slice(0, 60), " root=", ap.root_node)
    for d in [["warlock", 2.0], ["bones", 3.2], ["cutpurse", 2.4], ["slime", 3.0], ["bat", 2.8]]:
        var td: Dictionary = Bestiary.TYPES[d[0]]
        var n2: Node3D = (load(td["path"]) as PackedScene).instantiate()
        root.add_child(n2)
        n2.scale = Vector3.ONE * float(td["scale"]) * float(d[1])
        var box := AABB()
        var first := true
        var st: Array = [n2]
        while not st.is_empty():
            var c: Node = st.pop_back()
            if c is MeshInstance3D and (c as MeshInstance3D).visible:
                var ab: AABB = (c as MeshInstance3D).global_transform * (c as MeshInstance3D).get_aabb()
                box = ab if first else box.merge(ab)
                first = false
            for g in c.get_children():
                st.append(g)
        print("H ", d[0], " boss_h=", box.size)
    quit()
