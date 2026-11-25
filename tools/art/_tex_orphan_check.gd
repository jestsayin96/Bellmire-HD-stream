extends SceneTree
# tools/art/_tex_orphan_check.gd - ART LANE, tools/art/ only.
#
# WHY THIS EXISTS. Four TRACKED files in assets/monsters/minibosses/ are
# texture .import sidecars whose source_file PNG has never existed on any ref:
#   lastcuff_T_Imp_{BaseColor_3,Emissive,Normal,ORM}.png.import
# They are leftovers from a pass that extracted lastcuff's textures and was
# then turned off (lastcuff.glb.import carries materials/extract=0 and
# gltf/embedded_image_handling=1, so the body carries its own images).
#
# WHAT THIS ASKS, AND IT IS THE VIEWER'S QUESTION, NOT A FILE COUNT.
# Not "is the sidecar gone" - that is trivially true once you delete it.
# "Does the body still come in WITH ITS TEXTURES." So this counts, per body,
# the mesh surfaces and the material slots carrying a real albedo texture, and
# the same number is taken BEFORE and AFTER the removal. If removing a sidecar
# quietly cost lastcuff its skin, this number drops and the arm goes RED.
#
# RED ON EMPTY: a run that checks zero bodies, or finds zero textured slots on
# a body that should have them, is a FAIL and not a silent pass.
func _init():
    var subject := ["lastcuff"]              # the body whose sidecars are in question
    var control := ["broodglut", "pledgeman"] # untouched: one variant, one miniboss
    var fails := 0
    var checked := 0
    for group in [["SUBJECT", subject], ["CONTROL", control]]:
        for n in group[1]:
            var p: String = "res://assets/monsters/minibosses/%s.glb" % n
            checked += 1
            if not ResourceLoader.exists(p):
                print("TEXORPHAN FAIL %s %s - ResourceLoader.exists false" % [group[0], n])
                fails += 1
                continue
            var ps = load(p)
            if ps == null:
                print("TEXORPHAN FAIL %s %s - load() returned null" % [group[0], n])
                fails += 1
                continue
            var inst = ps.instantiate()
            if inst == null:
                print("TEXORPHAN FAIL %s %s - instantiate() null" % [group[0], n])
                fails += 1
                continue
            var meshes := 0
            var surfaces := 0
            var slots := 0
            var textured := 0
            var stack: Array = [inst]
            while stack.size() > 0:
                var node = stack.pop_back()
                if node is MeshInstance3D and node.mesh != null:
                    meshes += 1
                    var m: Mesh = node.mesh
                    surfaces += m.get_surface_count()
                    for s in range(m.get_surface_count()):
                        var mat = node.get_active_material(s)
                        if mat == null:
                            continue
                        slots += 1
                        if mat is BaseMaterial3D:
                            var t = mat.albedo_texture
                            if t != null and t.get_width() > 0 and t.get_height() > 0:
                                textured += 1
                for c in node.get_children():
                    stack.append(c)
            if meshes == 0:
                print("TEXORPHAN FAIL %s %s - loaded but ZERO meshes" % [group[0], n])
                fails += 1
            elif slots == 0:
                print("TEXORPHAN FAIL %s %s - ZERO material slots, nothing to measure" % [group[0], n])
                fails += 1
            else:
                print("TEXORPHAN OK %s %s meshes=%d surfaces=%d slots=%d textured=%d" % [group[0], n, meshes, surfaces, slots, textured])
            inst.free()
    # The sidecars themselves, named so the log says what the tree held at run time.
    for t in ["BaseColor_3", "Emissive", "Normal", "ORM"]:
        var sp: String = "res://assets/monsters/minibosses/lastcuff_T_Imp_%s.png" % t
        print("TEXORPHAN SIDECAR %s exists=%s" % [t, str(ResourceLoader.exists(sp))])
    if checked == 0:
        print("TEXORPHAN FAIL - checked NOTHING, this is a fail not a pass")
        fails += 1
    print("TEXORPHAN_DONE checked=%d fails=%d" % [checked, fails])
    quit(1 if fails > 0 else 0)
