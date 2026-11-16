extends SceneTree
## D94d proof: the cloak SHADE STEP mirrored from tools/art/icons.py. Every cloak that shares a
## (dye, cut) with another now sits a value step apart inside its dye, exactly as its hub icon does.
##   * every cloak's cloth (linear, before _lin) matches renders/cycles/d94d/expected_cloaks.json
##     (written by icons.register_cloaks + cloth_tone) to 1e-4, and its dye/variant/shade agree
##   * no two cloaks share (dye, variant, shade) - 49 distinct out of 49
## Renders the colliding groups front and back on real bodies -> renders/cycles/d94d/.
## Prints D94D OK / FAIL.
var _cam: Camera3D
var _f := 0
var _shots: Array = []
var _i := 0
var _stage: Node3D
var _r: Roster
var _out := "res://renders/cycles/d94d/"
var _fails := 0
var _paladins: Array = []

const ROWS := [
    ["woad_mantles", "knight", "acc", "cloak", ["barracks_cloak", "commander_mantle", "constable_cloak", "sparewall_cloak", "wall_cloak", "watch_mantle"], true],
    ["green_furs", "knight", "acc", "cloak", ["bucketline_cloak", "orchard_cloak", "woodward_cloak"], true],
    ["pairs_a", "knight", "acc", "cloak", ["backstair_cloak", "feast_cloak", "butcher_cloak", "mire_cloak", "crane_cloak", "raftsman_cloak"], true],
    ["pairs_b", "knight", "acc", "cloak", ["gravewyrm_cloak", "sexton_cloak", "harl_cloak", "raid_cloak", "hedgeward_cloak", "tiler_cloak"], true],
    ["pairs_c", "knight", "acc", "cloak", ["lamp_cloak", "thatcher_cloak", "lockkeep_cloak", "turbary_cloak"], true],
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
    var f := FileAccess.open("res://renders/cycles/d94d/expected_cloaks.json", FileAccess.READ)
    if f == null:
        print("D94D_FAIL no expected_cloaks.json")
        _fails += 1
        return
    var art: Dictionary = JSON.parse_string(f.get_as_text())
    var all: Dictionary = _r.items().get("accessories", {})
    var seen := {}
    var n := 0
    var shaded := 0
    for k in all:
        var e = all[k]
        if not (e is Dictionary) or String(e.get("slot", "")) != "cloak":
            continue
        n += 1
        var c := Gear.acc_ctx(String(k))
        var nm := String(e.get("name", ""))
        var di := Gear.cloak_dye_i(String(k), nm)
        var si := Gear.cloak_shade_i(String(k))
        if si > 0:
            shaded += 1
        var sig := "%d|%d|%d" % [di, int(c["variant"]), si]
        if seen.has(sig):
            print("D94D_DUP %s = %s (%s)" % [k, seen[sig], sig])
            _fails += 1
        seen[sig] = k
        if not art.has(k):
            print("D94D_FAIL %s missing from the art lane's table" % k)
            _fails += 1
            continue
        var x: Dictionary = art[k]
        var xc: Array = x["cloth"]
        var want := Gear._lin(Color(float(xc[0]), float(xc[1]), float(xc[2])))
        var got: Color = c["cloth"]
        var bad := int(x["dye"]) != di or int(x["variant"]) != int(c["variant"]) or int(x["shade"]) != si \
            or absf(want.r - got.r) > 1e-4 or absf(want.g - got.g) > 1e-4 or absf(want.b - got.b) > 1e-4
        if bad:
            print("D94D_MISMATCH %s game dye=%d var=%d shade=%d %s | art %s" % [k, di, int(c["variant"]), si, got, x])
            _fails += 1
    print("D94D cloaks %d, %d shaded, %d distinct (dye, cut, shade), %d vs art table" % [n, shaded, seen.size(), art.size()])
    if seen.size() != n or art.size() != n:
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
            print("D94D_ROW %s %d %s" % [row[0], j, what])
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
            print("D94D %s (%d shots, %d failures)" % ["OK" if _fails == 0 else "FAIL", _shots.size(), _fails])
            return true
        var s: Array = _shots[_i]
        _cam.fov = 40.0
        _cam.global_position = s[1]
        _cam.look_at(s[2], Vector3.UP)
        _i += 1
    return false
