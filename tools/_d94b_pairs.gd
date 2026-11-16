extends SceneTree
## D94b proof: the duplicates the proof sheet caught, side by side on real bodies through the REAL
## dress path, plus the numbers that say no two items can be one object any more.
##   * every accessory's full signature (slot, variant, metal, stat, cloth, FORM) is unique
##   * every named weapon differs from every sibling of its tier/family/kind in mesh OR form
##   * Parish Iron Mace is a mace, bought boots show over armour boots
## Renders -> renders/cycles/d94b/. Prints D94B OK / FAIL.
var _cam: Camera3D
var _f := 0
var _shots: Array = []
var _i := 0
var _stage: Node3D
var _r: Roster
var _out := "res://renders/cycles/d94b/"
var _fails := 0
var _paladins: Array = []

const ROWS := [
    ["amulet_art_pair", "knight", "acc", "amulet", ["gate_whistle", "brewster_amulet"], false],
    ["amulet_game_trio", "knight", "acc", "amulet", ["barracks_key", "hearth_amulet", "millwright_amulet"], false],
    ["cloak_pair", "knight", "acc", "cloak", ["hurdler_cloak", "osier_cloak"], true],
    ["gloves_pairs", "knight", "acc", "gloves", ["baker_mitts", "mill_mitts", "chainsmith_gloves", "rivet_mitts"], false],
    ["boots_pair", "knight", "acc", "boots", ["drover_boots", "miller_clogs"], false],
    ["bows_t5", "ranger", "weapon", "5", ["w_ranged_scarbow", "w_ranged_seamstring"], false],
    ["mace_greatbow", "", "weapon", "", ["cleric:0:w_kit_cleric", "ranger:4:w_ranged_ashbolt_great"], false],
    ["paladin_boots", "paladin", "boots", "", ["longcount_boots", ""], false],
]

func _initialize() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
    _stage = Node3D.new()
    root.add_child(_stage)
    var we := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color(0.30, 0.31, 0.34)
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(0.75, 0.75, 0.80)
    e.ambient_light_energy = 0.7
    e.tonemap_mode = Environment.TONE_MAPPER_AGX
    we.environment = e
    _stage.add_child(we)
    var sun := DirectionalLight3D.new()
    sun.rotation = Vector3(deg_to_rad(-50), deg_to_rad(150), 0)
    sun.light_energy = 1.3
    sun.shadow_enabled = true
    _stage.add_child(sun)
    var fill := DirectionalLight3D.new()
    fill.rotation = Vector3(deg_to_rad(-30), deg_to_rad(-30), 0)
    fill.light_energy = 0.5
    _stage.add_child(fill)
    var floor := MeshInstance3D.new()
    var pm := PlaneMesh.new()
    pm.size = Vector2(600, 600)
    floor.mesh = pm
    var fm := StandardMaterial3D.new()
    fm.albedo_color = Color(0.42, 0.40, 0.37)
    floor.material_override = fm
    _stage.add_child(floor)
    _cam = Camera3D.new()
    _stage.add_child(_cam)
    _r = Roster.new()
    _stage.add_child(_r)
    _numbers()
    _build()

func _numbers() -> void:
    # 1. accessories: no two share the full signature
    var all: Dictionary = _r.items().get("accessories", {})
    var seen := {}
    var dup := 0
    var forms := 0
    for k in all:
        var c := Gear.acc_ctx(String(k))
        if c.is_empty():
            continue
        var ci := int(c["cloth_i"]) if Gear.D94_CLOTH_SLOTS.has(String(c["slot"])) else -1
        var sig := "%s|%d|%d|%s|%d|%d" % [c["slot"], int(c["variant"]), int(c["metal_i"]), c["stat"], ci, int(c["form"])]
        if int(c["form"]) > 0:
            forms += 1
        if seen.has(sig):
            print("D94B_DUP accessory %s = %s (%s)" % [k, seen[sig], sig])
            dup += 1
        seen[sig] = k
    print("D94B accessories %d, %d given a form > 0, %d duplicates" % [all.size(), forms, dup])
    _fails += dup
    # 2. weapons: siblings differ in mesh or form
    var ws: Dictionary = Gear.equipment().get("weapons", {})
    var wseen := {}
    var wdup := 0
    for id in ws:
        var w: Dictionary = ws[id]
        var fam := String(w.get("family", ""))
        var ks := Gear.kinds_of(fam)
        if ks.is_empty():
            continue
        var lk := Gear.weapon_piece_look(String(id), fam, int(w.get("tier", 0)), String(ks[0]))
        var sig := "%s|%d|%s|%s|%d" % [fam, int(w.get("tier", 0)), lk["kind"], lk["path"], int(lk["form"])]
        if wseen.has(sig):
            print("D94B_DUP weapon %s = %s (%s)" % [id, wseen[sig], sig])
            wdup += 1
        wseen[sig] = id
    print("D94B weapons %d, %d duplicates" % [ws.size(), wdup])
    _fails += wdup
    var k0 := Gear.piece_kind("w_kit_cleric", "arcane")
    print("D94B Parish Iron Mace kind = %s" % k0)
    if k0 != "sceptre":
        _fails += 1

func _build() -> void:
    for ri in range(ROWS.size()):
        var row: Array = ROWS[ri]
        var z := float(ri) * 12.0
        var items: Array = row[4]
        var n := items.size()
        for j in range(n):
            var uid := "d94b_%d_%d" % [ri, j]
            var cls := String(row[1])
            var spec := String(items[j])
            if String(row[2]) == "weapon" and cls == "":
                cls = spec.split(":")[0]
            var h: Dictionary = _r.fresh(uid, "P%d" % j, cls)
            h["acc"] = {}
            h["armour"] = 0
            match String(row[2]):
                "acc":
                    h["acc"][String(row[3])] = spec
                "weapon":
                    if spec.contains(":"):
                        var parts := spec.split(":")
                        h["weapon"] = int(parts[1])
                        h["wname"] = parts[2]
                    else:
                        h["weapon"] = int(String(row[3]))
                        h["wname"] = spec
                "boots":
                    h["armour"] = 3
                    if spec != "":
                        h["acc"]["boots"] = spec
            _r.heroes[uid] = h
            var m := _dress(h, Vector3((float(j) - (n - 1) * 0.5) * 1.8, 0, z))
            if String(row[2]) == "boots":
                _paladins.append([m, spec])
            var what := spec
            if String(row[2]) == "weapon":
                what = _r.weapon_name(h)
            elif String(row[2]) == "acc":
                what = String(_r.item(spec).get("name", spec))
            print("D94B_ROW %s %d %s" % [row[0], j, what])
        var w := (n - 1) * 0.9
        _shots.append(["%d_%s_front" % [ri, row[0]], Vector3(0, 1.5, z - 3.2 - w), Vector3(0, 0.9, z)])
        if String(row[2]) == "weapon":
            _shots.append(["%d_%s_side" % [ri, row[0]], Vector3(-3.6 - w, 1.3, z - 1.2), Vector3(0, 0.9, z)])
        if bool(row[5]):
            _shots.append(["%d_%s_back" % [ri, row[0]], Vector3(0, 1.5, z + 3.2 + w), Vector3(0, 0.9, z)])
        if String(row[3]) in ["boots"] or String(row[2]) == "boots":
            _shots.append(["%d_%s_feet" % [ri, row[0]], Vector3(0.6, 0.7, z - 2.0 - w * 0.5), Vector3(0, 0.2, z)])
    # bought boots over armour boots
    for pr in _paladins:
        var sk := Gear.skeleton(pr[0])
        var want_c := String(pr[1]) != ""
        var has_c := sk.get_node_or_null("eq_cboot_l") != null
        var has_a := sk.get_node_or_null("eq_boot_l") != null
        print("D94B paladin boots=%s cboot=%s armour_boot=%s" % [pr[1], has_c, has_a])
        if want_c and (not has_c or has_a):
            _fails += 1
        if not want_c and not has_a:
            _fails += 1

func _adv(f: String) -> String:
    return "" if f == "" else (f if f.begins_with("res://") else Gear.ADV + f)

func _dress(h: Dictionary, p: Vector3) -> Node3D:
    var host := Node3D.new()
    _stage.add_child(host)
    host.position = p
    host.rotation.y = PI
    var m: Node3D = (load("res://addons/kaykit_character_pack_adventures/Characters/gltf/" + String(Roster.CLASSES[h["class"]]["model"])) as PackedScene).instantiate()
    host.add_child(m)
    Gear.strip_props(m)
    var look := _r.weapon_look(h)
    var held := Gear.equip(m, _adv(_r.weapon_mesh(h)), "handslot.r", "weapon", float(look["scale"]), float(look["glow"]))
    Gear.tint_piece(held, look.get("piece", {}))
    Gear.deco_piece(held, look.get("piece", {}))
    Gear.equip(m, _adv(_r.offhand_mesh(h)), _r.offhand_bone(h), "offhand")
    Gear.rank_trim(m, 0)
    var ap := Rig.find(m)
    if ap:
        Rig.prep(ap)
        Rig.play(ap, "Idle")
    var lb := Label3D.new()
    var acc: Dictionary = h.get("acc", {})
    var t := _r.weapon_name(h)
    for s in acc:
        t = String(_r.item(String(acc[s])).get("name", ""))
    lb.text = t
    lb.font_size = 22
    lb.pixel_size = 0.003
    lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    lb.outline_size = 8
    lb.position = p + Vector3(0, 2.6, 0)
    _stage.add_child(lb)
    return m

func _process(_d: float) -> bool:
    _f += 1
    if _f < 40:
        return false
    if (_f - 40) % 12 == 0:
        if _i > 0:
            root.get_texture().get_image().save_png(ProjectSettings.globalize_path(_out + "%s.png" % _shots[_i - 1][0]))
        if _i >= _shots.size():
            print("D94B %s (%d shots, %d failures)" % ["OK" if _fails == 0 else "FAIL", _shots.size(), _fails])
            return true
        var s: Array = _shots[_i]
        _cam.fov = 40.0
        _cam.global_position = s[1]
        _cam.look_at(s[2], Vector3.UP)
        _i += 1
    return false
