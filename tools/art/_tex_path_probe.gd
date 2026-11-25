extends SceneTree
# tools/art/_tex_path_probe.gd - ART LANE, tools/art/ only.
# THE DECISIVE MEASUREMENT, and it reverses what a file listing suggests.
# ResourceLoader.exists("res://...png") answers TRUE for a PNG that is NOT on
# disk, because the .import sidecar registers the resource against a cached
# .ctex. So "the source PNG is missing" does NOT mean "the sidecar is dead".
# This asks the only question that settles it: WHERE does each body's albedo
# texture actually come from - an external res:// path, or inside the .glb.
func _init():
    for n in ["lastcuff", "broodglut", "pledgeman"]:
        var p: String = "res://assets/monsters/minibosses/%s.glb" % n
        var ps = load(p)
        if ps == null:
            print("TEXPATH FAIL %s load null" % n); continue
        var inst = ps.instantiate()
        var stack: Array = [inst]
        var i := 0
        while stack.size() > 0:
            var node = stack.pop_back()
            if node is MeshInstance3D and node.mesh != null:
                var m: Mesh = node.mesh
                for s in range(m.get_surface_count()):
                    var mat = node.get_active_material(s)
                    i += 1
                    if mat == null:
                        print("TEXPATH %s slot%d mat=null" % [n, i]); continue
                    var ap := "<none>"
                    var nm := "<none>"
                    if mat is BaseMaterial3D:
                        var t = mat.albedo_texture
                        if t != null:
                            ap = t.resource_path
                            if ap == "":
                                ap = "<EMBEDDED, no resource_path> %dx%d" % [t.get_width(), t.get_height()]
                        var nt = mat.normal_texture
                        if nt != null:
                            nm = nt.resource_path
                            if nm == "":
                                nm = "<EMBEDDED>"
                    print("TEXPATH %s slot%d mat=%s albedo=%s normal=%s" % [n, i, mat.resource_name, ap, nm])
            for c in node.get_children():
                stack.append(c)
        inst.free()
    print("TEXPATH_DONE")
    quit(0)
