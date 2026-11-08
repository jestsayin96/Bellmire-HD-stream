extends SceneTree
func _initialize() -> void:
    for nm in ["Cow", "Horse", "Pig", "Sheep", "Pug", "Llama", "Duck", "Corgi", "Red"]:
        var n: Node3D = (load("res://assets/animals/%s.glb" % nm) as PackedScene).instantiate()
        root.add_child(n)
        var box := AABB()
        var first := true
        var ap: AnimationPlayer = null
        var st: Array = [n]
        while not st.is_empty():
            var c: Node = st.pop_back()
            if c is MeshInstance3D:
                var ab: AABB = (c as MeshInstance3D).global_transform * (c as MeshInstance3D).get_aabb()
                box = ab if first else box.merge(ab)
                first = false
            if c is AnimationPlayer:
                ap = c
            for g in c.get_children():
                st.append(g)
        print("ANIM ", nm, " size=", box.size, " anims=", ap.get_animation_list() if ap else [])
        n.free()
    quit()
