extends SceneTree
# tools/art/_load_check.gd - ART LANE, tools/art/ only.
# Proves the 8 bodies whose .glb.import this lane just generated actually LOAD.
# Generating a sibling file is not proof that the resource resolves; this is.
# RED ON EMPTY: a run that checks zero bodies is a FAIL, not a silent pass.
func _init():
    var names := ["blower","ferryman","hooper","pitman","relief","scraper","tither","winder"]
    var control := ["beadle","drillmaster"]   # already had .import before this run
    var fails := 0
    var checked := 0
    for group in [["OWED", names], ["CONTROL", control]]:
        for n in group[1]:
            var p: String = "res://assets/monsters/minibosses/%s.glb" % n
            checked += 1
            if not ResourceLoader.exists(p):
                print("LOADCHECK FAIL %s %s - ResourceLoader.exists false" % [group[0], n])
                fails += 1
                continue
            var ps = load(p)
            if ps == null:
                print("LOADCHECK FAIL %s %s - load() returned null" % [group[0], n])
                fails += 1
                continue
            var inst = ps.instantiate()
            if inst == null:
                print("LOADCHECK FAIL %s %s - instantiate() null" % [group[0], n])
                fails += 1
                continue
            var meshes := 0
            var stack: Array = [inst]
            while stack.size() > 0:
                var node = stack.pop_back()
                if node is MeshInstance3D and node.mesh != null:
                    meshes += 1
                for c in node.get_children():
                    stack.append(c)
            if meshes == 0:
                print("LOADCHECK FAIL %s %s - loaded but ZERO meshes" % [group[0], n])
                fails += 1
            else:
                print("LOADCHECK OK %s %s meshes=%d" % [group[0], n, meshes])
            inst.free()
    if checked == 0:
        print("LOADCHECK FAIL - checked NOTHING, this is a fail not a pass")
        fails += 1
    print("LOADCHECK_DONE checked=%d fails=%d" % [checked, fails])
    quit(1 if fails > 0 else 0)
