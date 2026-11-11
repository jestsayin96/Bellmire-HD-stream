extends SceneTree
## L1 gallery: the new creatures, the two new strains, a bowman shooting and a whelp breathing.
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
    var keys := ["bowman", "sentinel", "gravecaller", "lost", "lost", "whelp", "slimeling", "slime"]
    for i in range(keys.size()):
        _spawn(Bestiary.make(keys[i], "plain"), Vector3(float(i) * 3.0 - 10.5, 0, 0))
    var sk := ["minion", "bones", "spider", "rat", "frog", "warrior"]
    for i in range(sk.size()):
        _spawn(Bestiary.make(sk[i], "scarborn" if i % 2 == 0 else "mossbacked"), Vector3(float(i) * 3.0 - 7.5, 0, 10.0))
    _bow = Bestiary.make("bowman", "plain")
    _spawn(_bow, Vector3(-4, 0, 22))
    _spawn(Bestiary.make("whelp", "plain"), Vector3(4, 0, 22))
    _shots = [["new_creatures", Vector3(0, 4.0, -14.0), Vector3(0, 0.9, 0)],
              ["new_strains", Vector3(0, 3.0, 2.5), Vector3(0, 0.6, 10)],
              ["ways_shot_breath", Vector3(0, 4.5, 13.0), Vector3(0, 0.8, 24)]]
var _bow: Dictionary
func _spawn(d: Dictionary, p: Vector3) -> void:
    var m := Monster.new()
    m.def = d
    m.state = Monster.S.IDLE
    m.position = p
    m.rotation.y = PI
    _stage.add_child(m)
    _ms.append(m)
var _ms: Array = []
func _process(_d: float) -> bool:
    _f += 1
    if _f < 40:
        return false
    if _f % 25 == 0 and _i >= 2:
        for m in _ms:
            var mo: Monster = m
            if mo.position.z > 20.0:
                mo.rotation.y = 0.0
                var tgt := Vector3(mo.position.x * -0.2, 1.0, 30.0)
                if String(mo.def["type"]) == "whelp":
                    mo.breathe(tgt)
                else:
                    mo.shoot(tgt)
    if (_f - 40) % 30 == 12 and _i > 0:
        root.get_texture().get_image().save_png("user://l1_%s.png" % _shots[_i - 1][0])
    if (_f - 40) % 30 == 0:
        if _i >= _shots.size():
            return true
        var s: Array = _shots[_i]
        _cam.fov = 55.0
        _cam.global_position = s[1]
        _cam.look_at(s[2], Vector3.UP)
        _i += 1
    return false
