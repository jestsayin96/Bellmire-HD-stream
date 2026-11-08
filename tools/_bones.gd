extends SceneTree
func _initialize() -> void:
    for b in ["Knight", "Barbarian", "Mage", "Rogue", "Rogue_Hooded"]:
        var n: Node3D = (load("res://addons/kaykit_character_pack_adventures/Characters/gltf/%s.glb" % b) as PackedScene).instantiate()
        root.add_child(n)
        var meshes := []
        var st: Array = [n]
        while not st.is_empty():
            var c: Node = st.pop_back()
            if c is MeshInstance3D:
                meshes.append(String(c.name) + ("" if (c as MeshInstance3D).visible else "(hidden)"))
            for g in c.get_children():
                st.append(g)
        print("MESHES ", b, " ", meshes)
        n.free()
    quit()
