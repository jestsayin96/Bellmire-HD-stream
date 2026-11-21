extends SceneTree
## S80 (System 8 row (b), shield variety; cloned from _s22_shield.gd). Armour tiers 4-5 carry the Quaternius Medieval
## Weapons shields (assets/gear/shields/) on the REAL path (Roster.offhand_mesh -> Gear.equip at Gear.offhand_scale).
## Five bearers, Idle: knight a3 (the pack's rare shield - the SIZE REFERENCE), knight a4 (heater_2), knight a5
## (celtic gold), cleric a4 (round_2), cleric a5 (celtic gold). SIZE is MEASURED in the world off the held meshes'
## own AABBs. Gate: S80_SHIELD OK only if all 5 are held, a4/a5 hold a shields/ file and a3 the pack's, and every
## new shield's largest world dimension is within 0.75-1.35x the reference. S80_RED=1 forces scale x3 (must FAIL).
## Run WINDOWED (headless gives a null image).
var _cam: Camera3D
var _f := 0
var _shots: Array = []
var _i := 0
var _stage: Node3D
var _r: Roster
var _out := "res://renders/cycles/s80/"
var _fails := 0
var _offs: Array = []   # [label, held node, kind ("kit"|"pack")]
var _faces := 0
const D := "res://assets/gear/dungeon/"
const BEARERS := [["knight", 3], ["knight", 4], ["knight", 5], ["cleric", 4], ["cleric", 5]]
var _ref := 0.0
var _sizes: Array = []

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
    var i := 0
    for b in BEARERS:
        var cls: String = b[0]
        var a: int = b[1]
        var uid := "s80_%s%d" % [cls, a]
        var h: Dictionary = _r.fresh(uid, "shield%s%d" % [cls, a], cls, "human")
        h["armour"] = a
        h["weapon"] = maxi(a, 1)
        _r.heroes[uid] = h
        var x := (i - 2) * 1.5
        _dress(h, Vector3(x, 0, 0), "%s a%d" % [cls, a], a)
        i += 1
    _shots = [["s80_front_all", Vector3(0, 1.5, -9.5), Vector3(0, 1.0, 0)],
        ["s80_side_all", Vector3(10.0, 1.4, 0), Vector3(0, 1.0, 0)],
        ["s80_front_3q", Vector3(-5.0, 1.8, -8.0), Vector3(0, 1.0, 0)]]
    for k in range(_offs.size()):
        _shots.append(["s80_close_%d" % k, Vector3.ZERO, Vector3.ZERO, k])

func _adv(f: String) -> String:
    return "" if f == "" else (f if f.begins_with("res://") else Gear.ADV + f)

func _dress(h: Dictionary, p: Vector3, label: String, a: int) -> void:
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
    if held:
        Gear.tint_piece(held, look.get("piece", {}))
        Gear.deco_piece(held, look.get("piece", {}))
    var offp := _adv(_r.offhand_mesh(h))
    var sc := Gear.offhand_scale(offp) * (3.0 if OS.get_environment("S80_RED") == "1" and offp.begins_with(Gear.SHD) else 1.0)
    var offn := Gear.equip(m, offp, _r.offhand_bone(h), "offhand", sc)
    var kind := "pack" if offp.begins_with(D + "shield_") else ("s80" if offp.begins_with(Gear.SHD) else "kit")
    var want := "pack" if a <= 3 else "s80"
    print("S80_SHIELD BEARER %s | %s | x%.2f | held %s | %s" % [label, offp.get_file(), sc, str(offn != null), kind])
    if offn == null or kind != want or not offp.get_file().begins_with("shield"):
        print("S80_SHIELD FAIL %s: off hand %s (%s), want a %s shield" % [label, offp, kind, want])
        _fails += 1
    else:
        _offs.append([label, offn, kind])
    Gear.rank_trim(m, 0)
    var ap := Rig.find(m)
    if ap:
        Rig.prep(ap)
        Rig.play(ap, "Idle")
    var lb := Label3D.new()
    lb.text = "%s\n%s %s" % [label, kind, offp.get_file().get_basename()]
    lb.font_size = 24
    lb.pixel_size = 0.004
    lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    lb.outline_size = 10
    lb.position = p + Vector3(0, 2.95, 0)
    _stage.add_child(lb)

func _wsize(n: Node3D) -> float:
    var bb := AABB()
    var first := true
    for mi in n.find_children("*", "MeshInstance3D", true, false) + ([n] if n is MeshInstance3D else []):
        var w: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
        bb = w if first else bb.merge(w)
        first = false
    return maxf(bb.size.x, maxf(bb.size.y, bb.size.z))

func _face(n: Node3D) -> Array:
    var bb: AABB = Gear._local_aabb(n)
    var s := bb.size
    var ax := 0
    if s.y < s[ax]:
        ax = 1
    if s.z < s[ax]:
        ax = 2
    var b := n.global_transform.basis
    var nrm: Vector3 = [b.x, b.y, b.z][ax].normalized()
    return [ax, nrm, s]

func _process(_d: float) -> bool:
    _f += 1
    if _f < 40:
        return false
    if (_f - 40) % 12 == 0:
        if _i > 0:
            root.get_texture().get_image().save_png(ProjectSettings.globalize_path(_out + "%s.png" % _shots[_i - 1][0]))
        if _i == 1:   # sizes read once, in Idle, after the first shot settled the pose
            for o in _offs:
                if not is_instance_valid(o[1]):
                    continue
                var mx := _wsize(o[1])
                _faces += 1
                if o[2] == "pack":
                    _ref = mx
                _sizes.append([o[0], o[2], mx])
                var fr := _face(o[1])
                print("S80_SHIELD AXES %s (%s): thin axis %s of local size %s -> world normal %s" % [o[0], o[2], "XYZ"[int(fr[0])],
                    str((fr[2] as Vector3).snapped(Vector3.ONE * 0.01)), str((fr[1] as Vector3).snapped(Vector3.ONE * 0.01))])
            for z in _sizes:
                var r := (float(z[2]) / _ref) if _ref > 0.0 else 0.0
                print("S80_SHIELD SIZE %s (%s): largest world dim %.3f m, %.2fx the rare pack shield" % [z[0], z[1], z[2], r])
                if z[1] == "s80" and (r < 0.75 or r > 1.35):
                    print("S80_SHIELD FAIL %s: %.2fx the reference, want 0.75-1.35" % [z[0], r])
                    _fails += 1
            if _ref <= 0.0:
                print("S80_SHIELD FLOOR UNMET: no reference size")
                _fails += 1
        if _i >= _shots.size():
            if _offs.size() < 5:
                print("S80_SHIELD FLOOR UNMET: %d shields held, need 5" % _offs.size())
                _fails += 1
            if _faces < 5:
                print("S80_SHIELD FLOOR UNMET: %d faces measured, need 5" % _faces)
                _fails += 1
            print("S80_SHIELD %s (%d shields, %d sized, %d shots, %d failures)" % ["OK" if _fails == 0 else "FAIL", _offs.size(), _faces, _shots.size(), _fails])
            quit()
            return true
        var s: Array = _shots[_i]
        _cam.fov = 34.0
        if s.size() > 3:
            var o: Array = _offs[int(s[3])]
            var hp: Vector3 = (o[1] as Node3D).get_parent().global_position
            _cam.fov = 30.0
            _cam.global_position = hp + Vector3(0.0, 0.3, -1.8)
            _cam.look_at(hp, Vector3.UP)
        else:
            _cam.global_position = s[1]
            _cam.look_at(s[2], Vector3.UP)
        _i += 1
    return false
