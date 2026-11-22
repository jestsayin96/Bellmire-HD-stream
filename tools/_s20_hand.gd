extends SceneTree
## S20 (System 2 engine half: crossbow roll + greataxe kind; cloned from _s19_hand.gd). Was: S19 (cloned from _s17_heft.gd): the KayKit DUNGEON pack DAGGERS
## (a rogue) in a hero's hand, through the REAL
## path (Roster.weapon_mesh / weapon_look -> Gear.equip). Three knights, blade tiers 1-3, each holding
## a NAMED sword. Checks: (a) the mesh the roster picked is the dungeon-pack sword for that tier,
## (b) FIT - the hand point lies inside the held blade's bounds grown by 6 cm (grip in the fist),
## (c) the held node exists. 1080p shots, front + side + close, to renders/cycles/s20/.
## Prints S20_HEFT lines and S20_HEFT OK / FAIL. Run WINDOWED (headless gives a null image).
var _cam: Camera3D
var _f := 0
var _shots: Array = []
var _i := 0
var _stage: Node3D
var _r: Roster
var _out := "res://renders/cycles/s20/"
var _xbow: Array = []
var _shields := 0
var _fails := 0
var _held := {}
var _probe: Array = []
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

const D := "res://assets/gear/dungeon/"
## S19: staff (mages) and crossbow (rangers) tiers 1-3, the two S18 left unwired
## S20: crossbow (rangers, now rolled level by held_rot) and the new GREATAXE kind (barbarians, axeDouble_*)
const ROWS := [["crossbow", "crossbow", 0.0, "ranged", "ranger"], ["greataxe", "axeDouble", 3.0, "axe", "barbarian"], ["greataxe", "axeDouble", -3.0, "axe", "warden"]]

func _swords() -> void:
    for row in ROWS:
        for t in [1, 2, 3]:
            var want: String = D + "%s_%s.glb" % [row[1], ["", "common", "uncommon", "rare"][t]]
            var uid := "s20_%s_%s%d" % [row[4], row[0], t]
            var h: Dictionary = _r.fresh(uid, "%s%d" % [row[0], t], String(row[4]))
            h["weapon"] = t
            h["armour"] = t
            h["wkind"] = String(row[0])   # the chosen-kind path (!forge <kind>)
            var picked := ""
            var all: Dictionary = Gear.equipment().get("weapons", {})
            var ids: Array = all.keys()
            ids.sort()
            for id in ids:
                var w: Dictionary = all[id]
                if int(w.get("tier", -1)) != t or String(w.get("family", "")) != String(row[3]):
                    continue
                h["wname"] = id
                if _r.weapon_mesh(h) == want:
                    picked = id
                    break
            if picked == "":
                # NAMED: items.json has no tier-1/2 axe-family piece without an axe word, so no NAMED piece
                # reaches the mace mesh at those tiers. The map itself is still checked; it fails if wrong.
                var mapped := Gear.kind_path(row[0], t) == want
                print("S20_HEFT NOTE %s tier %d: no named piece reaches %s (map kind_path ok=%s)" % [row[0], t, want, str(mapped)])
                if not mapped:
                    _fails += 1
                    continue
                # S19: the UNNAMED !forge <kind> path is the real way such a hero reaches the mesh - dress THAT
                h.erase("wname")
                if _r.weapon_mesh(h) != want:
                    print("S20_HEFT FAIL %s tier %d: unnamed !forge path gives %s, want %s" % [row[0], t, _r.weapon_mesh(h), want])
                    _fails += 1
                    continue
                print("S20_HEFT NOTE %s tier %d: dressed through the unnamed !forge %s path" % [row[0], t, row[0]])
            else:
                h["wname"] = picked
            _r.heroes[uid] = h
            var x := float(t - 2) * 2.0 + 0.0
            var held := _dress(h, Vector3(x, 0, float(row[2])))
            _fit(held, h, t)
            var nm := "s20_%s_%s_t%d_close" % [row[4], row[0], t]
            _held[nm] = held
            _shots.append([nm, Vector3(x, 1.2, -1.6), Vector3(x, 0.9, 0)])
    _shots.push_front(["s20_side", Vector3(9.0, 1.4, 0), Vector3(0, 1.0, 0)])
    _shots.push_front(["s20_front", Vector3(0.45, 1.5, -10.0), Vector3(0.45, 1.0, 0)])

func _adv(f: String) -> String:
    return "" if f == "" else (f if f.begins_with("res://") else Gear.ADV + f)

func _dress(h: Dictionary, p: Vector3) -> Node3D:
    var ret: Node3D = null
    var host := Node3D.new()
    _stage.add_child(host)
    host.position = p
    host.rotation.y = PI
    var mp := String(Roster.CLASSES[h["class"]]["model"])
    if not mp.begins_with("res://"):
        mp = "res://addons/kaykit_character_pack_adventures/Characters/gltf/" + mp
    var m: Node3D = (load(mp) as PackedScene).instantiate()
    host.add_child(m)
    Gear.strip_props(m)
    var look := _r.weapon_look(h)
    var held := Gear.equip(m, _adv(_r.weapon_mesh(h)), "handslot.r", "weapon", float(look["scale"]), float(look["glow"]))
    ret = held
    Gear.tint_piece(held, look.get("piece", {}))
    Gear.deco_piece(held, look.get("piece", {}))
    var offp := _adv(_r.offhand_mesh(h))
    var offn := Gear.equip(m, offp, _r.offhand_bone(h), "offhand", Gear.offhand_scale(offp))
    if String(h["class"]) == "warden":   # S20: the shield row - the off hand must hold the tier's pack shield
        var wantoff := D + "shield_%s.glb" % ["common", "uncommon", "rare"][int(h["armour"]) - 1]
        print("S20_HEFT SHIELD tier %d | %s | held %s" % [int(h["armour"]), offp, str(offn != null)])
        if offp != wantoff or offn == null:
            print("S20_HEFT FAIL shield tier %d: got %s, want %s" % [int(h["armour"]), offp, wantoff])
            _fails += 1
        else:
            _shields += 1
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
        print("S20_HEFT FAIL tier %d: nothing held" % t)
        _fails += 1
        return
    var bb: AABB = Gear._local_aabb(held)
    var hand_local: Vector3 = held.transform.affine_inverse() * Vector3.ZERO
    var inside := bb.grow(0.06).has_point(hand_local)
    var len := bb.size.y * held.scale.y
    print("S20_HEFT tier %d | %s | %s | scale %.3f | blade %.2f m | hand-in-grip %s (hand %s, bounds %s)" % [t,
        _r.weapon_name(h), _r.weapon_mesh(h), held.scale.y, len, str(inside), str(hand_local.snapped(Vector3.ONE * 0.01)), str(bb)])
    if not inside:
        _fails += 1
    _probe.append(held)
    if String(_r.weapon_mesh(h)).contains("crossbow_"):
        _xbow.append(held)

func _process(_d: float) -> bool:
    _f += 1
    if _f < 40:
        return false
    if (_f - 40) % 12 == 0:
        if _i > 0:
            root.get_texture().get_image().save_png(ProjectSettings.globalize_path(_out + "%s.png" % _shots[_i - 1][0]))
        if _i >= _shots.size():
            for hn in _probe:   # S19: which way the held mesh's own +Y points in the WORLD, posed (staff wants UP)
                if is_instance_valid(hn):
                    var up: Vector3 = (hn as Node3D).global_transform.basis.y.normalized()
                    var px: Vector3 = (hn as Node3D).global_transform.basis.x.normalized()
                    var pz: Vector3 = (hn as Node3D).global_transform.basis.z.normalized()
                    print("S20_HEFT AXIS %s: mesh +X %s +Y %s +Z %s" % [hn.name, str(px.snapped(Vector3.ONE * 0.01)), str(up.snapped(Vector3.ONE * 0.01)), str(pz.snapped(Vector3.ONE * 0.01))])
                    # S95: INTENT CHANGED, ARM NOT WEAKENED. Was "prod LEVEL" (|+X.y| <= 0.35). Art's 35 deg roll (gear.gd
                    # held_rot) cants the prod out of the horizontal plane so it reads as a crossbow and not a lath, so the
                    # prod must now be CANTED 25-45 deg: |+X.y| in [sin 25, sin 45] = [0.42, 0.71]. A LEVEL prod (the old,
                    # unrolled carry) FAILS this arm, and so does one stood upright (the pre-S20 fault).
                    var cant := rad_to_deg(asin(clampf(absf(px.y), 0.0, 1.0)))
                    if _xbow.has(hn):
                        print("S20_HEFT CANT %s: prod +X.y %.2f = %.1f deg" % [hn.name, px.y, cant])
                    if _xbow.has(hn) and (absf(px.y) < 0.42 or absf(px.y) > 0.71):
                        print("S20_HEFT FAIL crossbow prod not canted 25-45 deg: +X.y %.2f (%.1f deg)" % [px.y, cant])
                        _fails += 1
                    if _xbow.has(hn) and pz.z > -0.6:   # S20: and the stock (+Z) must point the way the hero faces (-Z here)
                        print("S20_HEFT FAIL crossbow stock not forward: +Z %s" % str(pz.snapped(Vector3.ONE * 0.01)))
                        _fails += 1
            if _shields < 3:   # S20: the warden row must put three pack shields on the off hand
                print("S20_HEFT FLOOR UNMET: %d pack shields held, need 3" % _shields)
                _fails += 1
            if _held.size() < 6:   # floor (S19: two rows x three tiers): an empty or near-empty run must not read green
                print("S20_HEFT FLOOR UNMET: %d pieces held, need >= 6" % _held.size())
                _fails += 1
            print("S20_HEFT %s (%d shots, %d failures)" % ["OK" if _fails == 0 else "FAIL", _shots.size(), _fails])
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
