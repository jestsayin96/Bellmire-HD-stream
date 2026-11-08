extends SceneTree
func _initialize() -> void:
    var paths := ["res://addons/kaykit_character_pack_skeletons/Characters/gltf/Skeleton_Minion.glb",
        "res://addons/kaykit_character_pack_skeletons/Characters/gltf/Skeleton_Mage.glb",
        "res://addons/quaternius_monsters/Slime.glb", "res://addons/quaternius_monsters/Bat.glb",
        "res://addons/quaternius_monsters/Skeleton.glb", "res://addons/quaternius_monsters/Dragon.glb",
        "res://assets/monsters/Imp.glb", "res://assets/monsters/Puglin.glb", "res://assets/monsters/Frog.glb",
        "res://assets/monsters/Rat.glb", "res://assets/monsters/Snake.glb", "res://assets/monsters/Snake_Angry.glb",
        "res://assets/monsters/Spider.glb", "res://assets/monsters/Wasp.glb"]
    for p in paths:
        var n: Node3D = (load(p) as PackedScene).instantiate()
        root.add_child(n)
        var box := AABB()
        var first := true
        var ap: AnimationPlayer = null
        var meshes := []
        var st: Array = [n]
        while not st.is_empty():
            var c: Node = st.pop_back()
            if c is MeshInstance3D and (c as MeshInstance3D).visible:
                var ab: AABB = (c as MeshInstance3D).global_transform * (c as MeshInstance3D).get_aabb()
                box = ab if first else box.merge(ab)
                first = false
                meshes.append(String(c.name))
            if c is AnimationPlayer and ap == null:
                ap = c
            for g in c.get_children():
                st.append(g)
        var an := []
        if ap:
            for a in ap.get_animation_list():
                if not String(a).begins_with("_"):
                    an.append(String(a))
        print("MON ", p.get_file(), " size=", box.size, " meshes=", meshes.size(), " anims=", an)
        n.free()
    quit()
