extends SceneTree
## Lists every animation of the bodies given in ANIM_PATHS (comma list), or a default set.
func _initialize() -> void:
    var env := OS.get_environment("ANIM_PATHS")
    var paths: Array = env.split(",") if env != "" else [
        "res://addons/kaykit_character_pack_skeletons/Characters/gltf/Skeleton_Minion.glb",
        "res://addons/quaternius_monsters/Dragon.glb",
        "res://addons/kaykit_character_pack_adventures/Characters/gltf/Knight.glb"]
    for p in paths:
        var n: Node = (load(p) as PackedScene).instantiate()
        var st: Array = [n]
        while not st.is_empty():
            var c: Node = st.pop_back()
            if c is AnimationPlayer:
                print(p.get_file(), ": ", ", ".join((c as AnimationPlayer).get_animation_list()))
                break
            for g in c.get_children():
                st.append(g)
        n.free()
    quit()
