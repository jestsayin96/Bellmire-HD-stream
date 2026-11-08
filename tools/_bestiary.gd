extends SceneTree
## Bestiary gallery: every creature, every strain, every lord, lined up on open
## ground and photographed. Builds its own flat stage (no town) so nothing is
## in the way: grass plane, sky, sun.
var _cam: Camera3D
var _f := 0
var _shots: Array = []
var _i := 0
var _stage: Node3D
func _initialize() -> void:
    _stage = Node3D.new()
    root.add_child(_stage)
    var we := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sm := ProceduralSkyMaterial.new()
    sm.sky_top_color = Color(0.20, 0.22, 0.32)
    sm.sky_horizon_color = Color(0.45, 0.40, 0.50)
    sm.ground_bottom_color = Color(0.1, 0.1, 0.1)
    sky.sky_material = sm
    e.sky = sky
    e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    e.ambient_light_energy = 0.8
    e.tonemap_mode = Environment.TONE_MAPPER_AGX
    e.glow_enabled = true
    we.environment = e
    _stage.add_child(we)
    var sun := DirectionalLight3D.new()
    sun.rotation = Vector3(deg_to_rad(-50), deg_to_rad(30), 0)
    sun.light_energy = 1.2
    sun.shadow_enabled = true
    _stage.add_child(sun)
    var floor := MeshInstance3D.new()
    var pm := PlaneMesh.new()
    pm.size = Vector2(400, 400)
    floor.mesh = pm
    var fm: StandardMaterial3D = load("res://assets/kit/materials/MI_Cobble.tres")
    floor.material_override = fm
    _stage.add_child(floor)
    _cam = Camera3D.new()
    _stage.add_child(_cam)
    _cam.make_current()
    # row 1-2: every creature, plain
    var keys: Array = Bestiary.TYPES.keys()
    for i in range(keys.size()):
        var x := float(i % 8) * 4.0 - 14.0
        var z := 0.0 if i < 8 else 8.0
        _spawn(Bestiary.make(String(keys[i]), "plain"), Vector3(x, 0, z))
    # row 3: the six strains on a skeleton warrior
    var sk: Array = Bestiary.STRAINS.keys()
    for i in range(sk.size()):
        _spawn(Bestiary.make("warrior", String(sk[i])), Vector3(-10.0 + float(i) * 4.0, 0, 20.0))
    # rows 4-5: the eight lords, well spaced
    var bk: Array = Bestiary.BOSS_DEFS.keys()
    for i in range(bk.size()):
        var b: Dictionary = (Bestiary.BOSS_DEFS[bk[i]] as Dictionary).duplicate()
        b["id"] = bk[i]
        var x := float(i % 4) * 22.0 - 33.0
        var z := 50.0 if i < 4 else 90.0
        _spawn(Bestiary.boss_def(b), Vector3(x, 0, z))
        # a 1.8 m knight beside each lord, for scale
        var ref := Bestiary.make("warrior", "plain")
        ref["name"] = "(1.8 m)"
        _spawn(ref, Vector3(x + 5.0, 0, z - 2.0))
    _shots = [["creatures_a", Vector3(-0.5, 4.0, -12), Vector3(-0.5, 0.6, 1)],
              ["creatures_b", Vector3(-0.5, 4.0, -4), Vector3(-0.5, 0.5, 9)],
              ["strains", Vector3(0, 3.5, 9), Vector3(0, 1.0, 21)],
              ["lords_a", Vector3(0, 12, 18), Vector3(0, 4, 50)],
              ["lords_b", Vector3(0, 14, 56), Vector3(0, 5, 90)]]
    for i in range(bk.size()):
        var x := float(i % 4) * 22.0 - 33.0
        var z := 50.0 if i < 4 else 90.0
        var bh := float((Bestiary.BOSS_DEFS[bk[i]] as Dictionary)["h"])
        _shots.append(["lord_" + String(bk[i]), Vector3(x + bh * 0.6, bh * 0.7, z - bh * 1.9 - 3.0), Vector3(x, bh * 0.5, z)])
func _spawn(d: Dictionary, p: Vector3) -> void:
    var m := Monster.new()
    m.def = d
    m.state = Monster.S.IDLE
    m.position = p
    m.rotation.y = PI          # bodies face +Z; the cameras look from -Z
    _stage.add_child(m)
    print("SPAWN ", d.get("name"), " scale=", snappedf(float(d.get("scale", 1.0)), 0.01))
func _process(_d: float) -> bool:
    _f += 1
    if _f < 40:
        return false
    if (_f - 40) % 10 == 0:
        if _i > 0:
            root.get_texture().get_image().save_png("user://best_%s.png" % _shots[_i - 1][0])
        if _i >= _shots.size():
            return true
        var s: Array = _shots[_i]
        _cam.fov = 60.0
        _cam.global_position = s[1]
        _cam.look_at(s[2], Vector3.UP)
        _i += 1
    return false
