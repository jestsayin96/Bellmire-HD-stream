extends SceneTree
# S133 - System 12 (NPC variety) step S110c-1: measure the 20 staged Quaternius UACP bodies
# (CC0, quaternius.com/packs/ultimatedanimatedcharacter.html, read 25 Nov 10:1x CT) INSIDE GODOT
# against the KayKit Adventurers bodies townsfolk.gd already draws, WITHOUT adding anything to
# assets/ (they enter assets/ only in the commit that wires them, as S108's rule requires).
# Loads off-repo via GLTFDocument, so no import cache is touched.
# Verdict: UACP_PROBE OK / UACP_PROBE FAIL. `-- --redprove` adds a missing body and must FAIL.
const STAGE := "C:/hd adventure/_gb_s110_uacp/"
const ADV := "res://addons/kaykit_character_pack_adventures/Characters/gltf/"
const BODIES := ["BlueSoldier_Female", "BlueSoldier_Male", "Chef_Female", "Chef_Male", "Elf",
    "Goblin_Female", "Goblin_Male", "Knight_Golden_Female", "Knight_Golden_Male", "Knight_Male",
    "OldClassy_Female", "OldClassy_Male", "Soldier_Female", "Soldier_Male", "Viking_Female",
    "Viking_Male", "Witch", "Wizard", "Worker_Female", "Worker_Male"]
const NEED_CLIPS := ["Idle", "Walk"]

func _measure(n: Node) -> Array:
    var box := AABB()
    var first := true
    var ap: AnimationPlayer = null
    var meshes := 0
    var st: Array = [n]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is MeshInstance3D:
            var mi := c as MeshInstance3D
            # Accumulate local transforms up to `n`: in _initialize the nodes are not inside the
            # tree yet, so global_transform would return identity and log !is_inside_tree.
            var xf := Transform3D.IDENTITY
            var w: Node = mi
            while w != null and w != n.get_parent():
                if w is Node3D:
                    xf = (w as Node3D).transform * xf
                w = w.get_parent()
            var ab: AABB = xf * mi.get_aabb()
            box = ab if first else box.merge(ab)
            first = false
            meshes += 1
        if c is AnimationPlayer and ap == null:
            ap = c
        for g in c.get_children():
            st.append(g)
    return [box, ap, meshes]

func _initialize() -> void:
    var red := "--redprove" in OS.get_cmdline_user_args()
    var fails: Array = []
    var adv_h: Array = []
    for nm in ["Rogue", "Knight", "Barbarian", "Mage"]:
        var ps = load(ADV + nm + ".glb")
        if ps == null:
            continue
        var n: Node3D = (ps as PackedScene).instantiate()
        root.add_child(n)
        var m := _measure(n)
        adv_h.append((m[0] as AABB).size.y)
        print("S133 ADV ", nm, " h=%.3f" % (m[0] as AABB).size.y)
        n.free()
    if adv_h.is_empty():
        fails.append("no KayKit ADV body loaded")
    var adv_mean := 0.0
    for h in adv_h:
        adv_mean += h
    adv_mean = adv_mean / max(1, adv_h.size())
    var list: Array = BODIES.duplicate()
    if red:
        list.append("Nobody_Redprove")
    var ok_n := 0
    var prefixed := 0
    var hs: Array = []
    for nm in list:
        var path: String = STAGE + nm + ".glb"
        if not FileAccess.file_exists(path):
            fails.append(nm + ": missing")
            continue
        var doc := GLTFDocument.new()
        var stt := GLTFState.new()
        if doc.append_from_file(path, stt) != OK:
            fails.append(nm + ": gltf parse")
            continue
        var n: Node = doc.generate_scene(stt)
        if n == null:
            fails.append(nm + ": no scene")
            continue
        root.add_child(n)
        var m := _measure(n)
        var box: AABB = m[0]
        var ap: AnimationPlayer = m[1]
        var raw: Array = ap.get_animation_list() if ap else []
        # FINDING S133: the FBX->glb clips arrive as "CharacterArmature|CharacterArmature|Idle", so
        # Rig.play(anim, "Idle") would MISS them. The wiring must strip the armature prefix; this
        # gate judges the bare clip name after the last "|" and counts how many carry the prefix.
        var clips: Array = []
        for r in raw:
            var s: String = str(r)
            if "|" in s:
                prefixed += 1
            clips.append(s.get_slice("|", s.get_slice_count("|") - 1))
        var miss: Array = []
        for c in NEED_CLIPS:
            if not (c in clips):
                miss.append(c)
        if m[2] == 0 or box.size.y <= 0.0:
            fails.append(nm + ": no mesh")
        elif not miss.is_empty():
            fails.append(nm + ": missing clips " + str(miss))
        else:
            ok_n += 1
            hs.append(box.size.y)
        print("S133 UACP ", nm, " h=%.3f ymin=%.3f meshes=%d clips=%d %s" % [box.size.y, box.position.y, m[2], clips.size(), str(clips)])
        n.free()
    var mean := 0.0
    for h in hs:
        mean += h
    mean = mean / max(1, hs.size())
    var hmin: float = hs.min() if not hs.is_empty() else 0.0
    var hmax: float = hs.max() if not hs.is_empty() else 0.0
    print("S133 ADV mean h=%.3f  UACP mean h=%.3f min=%.3f max=%.3f  scale UACP->ADV = %.4f" % [adv_mean, mean, hmin, hmax, (adv_mean / mean) if mean > 0 else 0.0])
    if fails.is_empty() and ok_n == BODIES.size():
        print("UACP_PROBE OK %d bodies, all with Idle+Walk (bare names; %d clips carry the armature prefix), scale %.4f" % [ok_n, prefixed, adv_mean / mean])
    else:
        print("UACP_PROBE FAIL ok=%d/%d fails=%s" % [ok_n, list.size(), str(fails)])
    quit()
