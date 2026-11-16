extends SceneTree
## D94e proof: SIX DIFFERENT GLOVES on real knight bodies through the REAL dress path, front,
## side, back and a close front at the hands (Mr. E's acceptance test, 04:43), plus PARITY: the
## key dials Gear.d94_dials makes must equal showcase.sig()'s, so the worn piece in game is the
## object the ART lane's icon and proof sheet draw. Renders -> renders/cycles/d94e/. D94E OK / FAIL.
var _cam: Camera3D
var _f := 0
var _shots: Array = []
var _i := 0
var _stage: Node3D
var _r: Roster
var _out := "res://renders/cycles/d94e/"
var _fails := 0

const GLOVES := ["smith_gloves", "mason_mitts", "bowyer_wraps", "rattling_gauntlets", "raidbreaker_gloves", "fletcher_tabs"]
## showcase.sig(key, name).d[0..3], computed by python off tools/art/icons.py
const PY_DIALS := {
    "smith_gloves": [29554758, 1942829575, 2121926452, 1314855261],
    "mason_mitts": [1380124364, 6569237, 1216911402, 1526842907],
    "bowyer_wraps": [646157000, 1265540961, 951032454, 763219783],
    "rattling_gauntlets": [1292453052, 88849477, 1996119962, 2094518475],
    "raidbreaker_gloves": [1062498660, 1222176717, 586989698, 1322369939],
    "fletcher_tabs": [906152578, 2070939027, 1394039248, 1160695241]}

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
    _build()

func _build() -> void:
    var n := GLOVES.size()
    for j in range(n):
        var k := String(GLOVES[j])
        var nm := String(_r.item(k).get("name", k))
        var d := Gear.d94_dials(k, nm)
        var py: Array = PY_DIALS[k]
        for q in range(4):
            if int(d[q]) != int(py[q]):
                print("D94E_PARITY_FAIL %s dial %d gd=%d py=%d" % [k, q, int(d[q]), int(py[q])])
                _fails += 1
        var c := Gear.acc_ctx(k)
        var F := Gear.glove_form(int(c["variant"]), float(c["orn"]), d)
        print("D94E_FORM %s v=%d orn=%.2f cuff=%.3f flare=%.3f knuck=%.3f shell=%.3f plates=%d lip=%s form=%d" % [k, int(F["variant"]), float(c["orn"]), float(F["cuff"]), float(F["flare"]), float(F["knuck"]), float(F["shell"]), int(F["plates"]), F["lip"], int(c["form"])])
        var uid := "d94e_%d" % j
        var h: Dictionary = _r.fresh(uid, "P%d" % j, "knight")
        h["acc"] = {"gloves": k}
        h["armour"] = 0
        _r.heroes[uid] = h
        var m := _dress(h, Vector3((float(j) - (n - 1) * 0.5) * 1.8, 0, 0))
        var sk := Gear.skeleton(m)
        if sk.get_node_or_null("eq_glove_l") == null or sk.get_node_or_null("eq_glove_r") == null:
            print("D94E_MISSING %s" % k)
            _fails += 1
    var w := (n - 1) * 0.9
    _shots.append(["gloves_front", Vector3(0, 1.5, -3.2 - w), Vector3(0, 0.9, 0)])
    _shots.append(["gloves_side", Vector3(-3.6 - w, 1.3, -1.2), Vector3(0, 0.9, 0)])
    _shots.append(["gloves_back", Vector3(0, 1.5, 3.2 + w), Vector3(0, 0.9, 0)])
    _shots.append(["gloves_close_l", Vector3(-2.7, 1.1, -2.6), Vector3(-2.7, 0.75, 0)])
    _shots.append(["gloves_close_r", Vector3(2.7, 1.1, -2.6), Vector3(2.7, 0.75, 0)])

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
            print("D94E %s (%d shots, %d failures)" % ["OK" if _fails == 0 else "FAIL", _shots.size(), _fails])
            return true
        var s: Array = _shots[_i]
        _cam.fov = 40.0
        _cam.global_position = s[1]
        _cam.look_at(s[2], Vector3.UP)
        _i += 1
    return false
