extends SceneTree
## D94/D95 in-engine proof: real KayKit hero bodies dressed by the REAL code path (Roster ->
## Gear.equip / rank_trim -> dress_armour + dress_cosmetics), photographed so a fit fault cannot hide.
##   D95_MODE=ten   (default) ten heroes, one calling each, two per rarity tier (common..legendary),
##                  each a named weapon, a named armour piece and three accessories nobody else
##                  wears; FOUR views each (front, side, back, top) -> renders/cycles/d95/
##   D95_MODE=slots the D94 DONE shot: one row per slot, SIX different items of that slot on six
##                  real bodies at stream distance (ring, amulet, gloves, boots, cloak, weapon, armour)
## Prints D95_FIT lines (what each hero wears) and D95_FIT OK / FAIL (a piece that failed to attach).
var _cam: Camera3D
var _f := 0
var _shots: Array = []
var _i := 0
var _stage: Node3D
var _r: Roster
var _out := "res://renders/cycles/d95/"
var _fails := 0
const CALLINGS := ["knight", "rogue", "barbarian", "mage", "ranger", "cleric", "warden", "druid", "paladin", "monk"]
const RARITY := ["common", "uncommon", "rare", "very rare", "legendary"]
const SLOTS := ["ring", "amulet", "gloves", "boots", "cloak"]

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
    if OS.get_environment("D95_MODE") == "slots":
        _slots()
    else:
        _ten()

func _pieces(kind: String, pred: Callable) -> Array:
    var out: Array = []
    var all: Dictionary = Gear.equipment().get(kind, {})
    for k in all:
        if pred.call(all[k]):
            out.append(k)
    out.sort()
    return out

func _accs(rarity: String, slot: String) -> Array:
    var out: Array = []
    var all: Dictionary = _r.items().get("accessories", {})
    for k in all:
        var a = all[k]
        if a is Dictionary and String(a.get("slot", "")) == slot and String(a.get("rarity", "")) == rarity:
            out.append(k)
    out.sort()
    return out

func _ten() -> void:
    var used := {}
    for i in range(CALLINGS.size()):
        var cls: String = CALLINGS[i]
        var tier := i / 2
        var uid := "d95_%d" % i
        var h: Dictionary = _r.fresh(uid, "%s%d" % [cls.capitalize().substr(0, 4), i], cls)
        var fam := String(Roster.CLASSES[cls]["family"])
        h["weapon"] = tier
        h["armour"] = tier
        var ws := _pieces("weapons", func(w): return int(w["tier"]) == tier and String(w["family"]) == fam)
        if tier > 0 and not ws.is_empty():
            h["wname"] = ws[(i % 2) % ws.size()]
        var cut := String(Gear.D94_CUT.get(cls, "light"))
        var ars := _pieces("armour", func(a): return int(a["tier"]) == tier and String(a["cut"]) == cut)
        if ars.is_empty():
            ars = _pieces("armour", func(a): return int(a["tier"]) == tier)
        if tier > 0 and not ars.is_empty():
            h["aname"] = ars[(i % 2) % ars.size()]
        # three accessories of this hero's rarity, three different slots, worn by nobody else
        h["acc"] = {}
        for s in range(3):
            var slot: String = SLOTS[(i + s * 2) % SLOTS.size()]
            var cands: Array = _accs(RARITY[tier], slot) + _accs(RARITY[mini(4, tier + 1)], slot)
            for rr in [3, 2, 1, 0]:
                cands.append_array(_accs(RARITY[rr], slot))
            for k in cands:
                if not used.has(k):
                    used[k] = true
                    h["acc"][slot] = k
                    break
        _r.heroes[uid] = h
        var x := float(i) * 30.0
        var m := _dress(h, Vector3(x, 0, 0))
        print("D95_FIT %d %s tier %d | %s | %s | %s" % [i, cls, tier, _r.weapon_name(h), _r.armour_name(h),
            ", ".join((h["acc"] as Dictionary).values().map(func(k): return "%s=%s" % [k, _r.item(k).get("name", "?")]))])
        _check(m, h)
        var n := "%02d_%s" % [i, cls]
        _shots.append([n + "_1front", Vector3(x, 1.25, -6.2), Vector3(x, 1.25, 0)])
        _shots.append([n + "_2side", Vector3(x + 6.2, 1.25, 0), Vector3(x, 1.25, 0)])
        _shots.append([n + "_3back", Vector3(x, 1.25, 6.2), Vector3(x, 1.25, 0)])
        _shots.append([n + "_4top", Vector3(x, 7.2, -0.01), Vector3(x, 0.9, 0)])

func _slots() -> void:
    var rows := ["ring", "amulet", "gloves", "boots", "cloak", "weapon", "armour"]
    for ri in range(rows.size()):
        var slot: String = rows[ri]
        var z := float(ri) * 30.0
        for j in range(6):
            var uid := "d94_%d_%d" % [ri, j]
            var cls: String = "knight" if slot != "weapon" else ["knight", "rogue", "barbarian", "ranger", "mage", "monk"][j]
            var h: Dictionary = _r.fresh(uid, "S%d" % j, cls)
            h["acc"] = {}
            if slot in SLOTS:
                var pool: Array = []
                for rar in RARITY:
                    pool.append_array(_accs(rar, slot))
                h["acc"][slot] = pool[(j * pool.size()) / 6]
                h["armour"] = 0
            elif slot == "weapon":
                h["weapon"] = 1 + (j % 4)
                h["armour"] = 0
            else:
                var ars := _pieces("armour", func(a): return int(a["tier"]) >= 1)
                var pick: String = ars[(j * ars.size()) / 6]
                h["armour"] = int(Gear.armour_piece(pick)["tier"])
                h["aname"] = pick
            _r.heroes[uid] = h
            var m := _dress(h, Vector3(float(j) * 1.7 - 4.25, 0, z))
            _check(m, h)
            var what := _r.weapon_name(h) if slot == "weapon" else (_r.armour_name(h) if slot == "armour" else String(_r.item(String(h["acc"][slot])).get("name", "")))
            print("D94_ROW %s %d %s" % [slot, j, what])
        _shots.append(["d94_row_%d_%s" % [ri, slot], Vector3(0, 2.2, z - 7.0), Vector3(0, 1.0, z)])
        _shots.append(["d94_row_%d_%s_close" % [ri, slot], Vector3(-2.6, 1.6, z - 3.0), Vector3(-2.6, 1.0, z)])

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
    lb.text = "%s\n%s" % [_r.weapon_name(h), _r.armour_name(h)]
    lb.font_size = 26
    lb.pixel_size = 0.004
    lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    lb.outline_size = 10
    lb.position = p + Vector3(0, 2.95, 0)
    _stage.add_child(lb)
    return m

## every accessory the hero wears must have produced its node on the skeleton
func _check(m: Node3D, h: Dictionary) -> void:
    var sk := Gear.skeleton(m)
    var want := {"ring": "eq_ring", "amulet": "eq_amulet", "gloves": "eq_glove_l", "cloak": "eq_cloak"}
    for slot in (h.get("acc", {}) as Dictionary):
        var node := String(want.get(slot, ""))
        if slot == "boots":
            node = "eq_cboot_l" if sk.get_node_or_null("eq_boot_l") == null else "eq_boot_l"
        if node != "" and sk.get_node_or_null(NodePath(node)) == null:
            print("D95_FAIL %s: %s did not attach" % [h["name"], slot])
            _fails += 1

func _process(_d: float) -> bool:
    _f += 1
    if _f < 40:
        return false
    if (_f - 40) % 12 == 0:
        if _i > 0:
            root.get_texture().get_image().save_png(ProjectSettings.globalize_path(_out + "%s.png" % _shots[_i - 1][0]))
        if _i >= _shots.size():
            print("D95_FIT %s (%d shots, %d attach failures)" % ["OK" if _fails == 0 else "FAIL", _shots.size(), _fails])
            return true
        var s: Array = _shots[_i]
        _cam.fov = 34.0
        _cam.global_position = s[1]
        if String(s[0]).ends_with("_4top"):
            _cam.look_at(s[2], Vector3(0, 0, 1))
        else:
            _cam.look_at(s[2], Vector3.UP)
        _i += 1
    return false
