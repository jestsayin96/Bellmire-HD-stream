extends SceneTree
## S16 (System 2, first half): the KayKit DUNGEON pack swords in a hero's hand, through the REAL
## path (Roster.weapon_mesh / weapon_look -> Gear.equip). Three knights, blade tiers 1-3, each holding
## a NAMED sword. Checks: (a) the mesh the roster picked is the dungeon-pack sword for that tier,
## (b) FIT - the hand point lies inside the held blade's bounds grown by 6 cm (grip in the fist),
## (c) the held node exists. 1080p shots, front + side + close, to renders/cycles/s16/.
## Prints S16_SWORD lines and S16_SWORD OK / FAIL. Run WINDOWED (headless gives a null image).
var _cam: Camera3D
var _f := 0
var _shots: Array = []
var _i := 0
var _stage: Node3D
var _r: Roster
var _out := "res://renders/cycles/s16/"
var _fails := 0
var _held := {}
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
    _swords()

const WANT := ["", "res://assets/gear/dungeon/sword_common.glb", "res://assets/gear/dungeon/sword_uncommon.glb", "res://assets/gear/dungeon/sword_rare.glb"]

func _swords() -> void:
    for t in [1, 2, 3]:
        var uid := "s16_%d" % t
        var h: Dictionary = _r.fresh(uid, "Sword%d" % t, "knight")
        h["weapon"] = t
        h["armour"] = t
        var picked := ""
        var all: Dictionary = Gear.equipment().get("weapons", {})
        var ids: Array = all.keys()
        ids.sort()
        for id in ids:
            var w: Dictionary = all[id]
            if int(w.get("tier", -1)) != t or String(w.get("family", "")) != "blade":
                continue
            h["wname"] = id
            if _r.weapon_mesh(h) == WANT[t]:
                picked = id
                break
        if picked == "":
            print("S16_SWORD FAIL tier %d: no named blade resolves to %s" % [t, WANT[t]])
            _fails += 1
            continue
        h["wname"] = picked
        _r.heroes[uid] = h
        var x := float(t - 2) * 1.6
        var held := _dress(h, Vector3(x, 0, 0))
        _fit(held, h, t)
        _held["s16_t%d_close" % t] = held
        _shots.append(["s16_t%d_close" % t, Vector3(x, 1.2, -1.6), Vector3(x, 0.9, 0)])
    _shots.push_front(["s16_side", Vector3(5.2, 1.2, 0), Vector3(0, 1.0, 0)])
    _shots.push_front(["s16_front", Vector3(0, 1.3, -5.6), Vector3(0, 1.1, 0)])

func _adv(f: String) -> String:
    return "" if f == "" else (f if f.begins_with("res://") else Gear.ADV + f)

func _dress(h: Dictionary, p: Vector3) -> Node3D:
    var ret: Node3D = null
    var host := Node3D.new()
    _stage.add_child(host)
    host.position = p
    host.rotation.y = PI
    var m: Node3D = (load("res://addons/kaykit_character_pack_adventures/Characters/gltf/" + String(Roster.CLASSES[h["class"]]["model"])) as PackedScene).instantiate()
    host.add_child(m)
    Gear.strip_props(m)
    var look := _r.weapon_look(h)
    var held := Gear.equip(m, _adv(_r.weapon_mesh(h)), "handslot.r", "weapon", float(look["scale"]), float(look["glow"]))
    ret = held
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
    return ret

## FIT, the measured half: the hand (the attachment the blade hangs off) must sit inside the blade's
## own bounds grown by 6 cm. Gear.equip puts the model ORIGIN at the hand, so this proves the pack's
## origin is in the grip (a pack with its origin at the tip or the pommel end fails it). It does NOT
## prove the blade angle reads right in the pose - the 1080p pictures are that half of the test.
func _fit(held: Node3D, h: Dictionary, t: int) -> void:
    if held == null:
        print("S16_SWORD FAIL tier %d: nothing held" % t)
        _fails += 1
        return
    var bb: AABB = Gear._local_aabb(held)
    var hand_local: Vector3 = held.transform.affine_inverse() * Vector3.ZERO
    var inside := bb.grow(0.06).has_point(hand_local)
    var len := bb.size.y * held.scale.y
    print("S16_SWORD tier %d | %s | %s | scale %.3f | blade %.2f m | hand-in-grip %s (hand %s, bounds %s)" % [t,
        _r.weapon_name(h), _r.weapon_mesh(h), held.scale.y, len, str(inside), str(hand_local.snapped(Vector3.ONE * 0.01)), str(bb)])
    if not inside:
        _fails += 1

func _process(_d: float) -> bool:
    _f += 1
    if _f < 40:
        return false
    if (_f - 40) % 12 == 0:
        if _i > 0:
            root.get_texture().get_image().save_png(ProjectSettings.globalize_path(_out + "%s.png" % _shots[_i - 1][0]))
        if _i >= _shots.size():
            print("S16_SWORD %s (%d shots, %d failures)" % ["OK" if _fails == 0 else "FAIL", _shots.size(), _fails])
            return true
        var s: Array = _shots[_i]
        _cam.fov = 34.0 if not String(s[0]).ends_with("_close") else 30.0
        _cam.global_position = s[1]
        if _held.has(s[0]) and is_instance_valid(_held[s[0]]):
            # close-up framed on the LIVE hand (bodies differ in size per tier, so a fixed point missed)
            var hp: Vector3 = (_held[s[0]] as Node3D).get_parent().global_position
            _cam.global_position = hp + Vector3(-0.55, 0.35, -1.5)
            _cam.look_at(hp + Vector3(0, 0.1, 0), Vector3.UP)
        elif String(s[0]).ends_with("_4top"):
            _cam.look_at(s[2], Vector3(0, 0, 1))
        else:
            _cam.look_at(s[2], Vector3.UP)
        _i += 1
    return false
