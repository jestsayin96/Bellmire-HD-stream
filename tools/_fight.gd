extends SceneTree
## Staged fight: a knight and a mage against a skeleton pack, numbers flying,
## two die; then a lord rises. Photographed along the way.
var _cam: Camera3D
var _f := 0
var _stage: Node3D
var _pack: Array = []
var _knight: Node3D
var _lord: Monster
func _initialize() -> void:
    _stage = Node3D.new()
    root.add_child(_stage)
    var we := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color(0.05, 0.04, 0.07)
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(0.35, 0.32, 0.42)
    e.ambient_light_energy = 0.8
    e.glow_enabled = true
    e.tonemap_mode = Environment.TONE_MAPPER_AGX
    we.environment = e
    _stage.add_child(we)
    var sun := DirectionalLight3D.new()
    sun.rotation = Vector3(deg_to_rad(-55), deg_to_rad(25), 0)
    sun.light_energy = 0.9
    sun.shadow_enabled = true
    _stage.add_child(sun)
    var fl := MeshInstance3D.new()
    var pm := PlaneMesh.new()
    pm.size = Vector2(80, 80)
    fl.mesh = pm
    fl.material_override = load("res://assets/kit/materials/MI_Cobble.tres")
    _stage.add_child(fl)
    _cam = Camera3D.new()
    _stage.add_child(_cam)
    _cam.make_current()
    _cam.fov = 58.0
    _cam.global_position = Vector3(-7, 4.2, 7)
    _cam.look_at(Vector3(0, 1.0, -1), Vector3.UP)
    var v := Townsfolk.new()
    v.model = "Knight.glb"
    v.role = "guard"
    v.stay = true
    v.face_yaw = PI
    v.person_name = "Sir Bran"
    v.position = Vector3(-1.5, 0, 3)
    _stage.add_child(v)
    _knight = v
    var mg := Townsfolk.new()
    mg.model = "Mage.glb"
    mg.role = "healer"
    mg.stay = true
    mg.face_yaw = PI
    mg.person_name = "Edda Rivers"
    mg.position = Vector3(1.8, 0, 4)
    _stage.add_child(mg)
    var kinds := ["minion", "warrior", "minion", "cutpurse", "warlock"]
    for i in range(kinds.size()):
        var m := Monster.new()
        m.def = Bestiary.make(kinds[i], "plain" if i != 3 else "emberbound")
        m.state = Monster.S.IDLE
        m.position = Vector3(-4.0 + float(i) * 2.0, 0, -3.0 - float(i % 2) * 1.5)
        _stage.add_child(m)
        _pack.append(m)
func _process(_d: float) -> bool:
    _f += 1
    if _f == 30:
        for m in _pack:
            m.target = _knight
            m.state = Monster.S.ATTACK
    if _f in [40, 48, 56, 64, 72]:
        var i := (_f - 40) / 8
        var m: Monster = _pack[i]
        m.hurt(randf_range(6.0, 14.0), i == 2)
        Spells.cast("bolt", _stage.get_child(_stage.get_child_count() - 6) if false else _knight, m.global_position + Vector3(0, 0.0, 0))
    if _f == 60:
        _pack[0].hurt(999.0, true)
        _pack[2].hurt(999.0)
    if _f == 76:
        _snap("fight_hits")
    if _f == 150:
        _snap("fight_deaths")
        for m in _pack:
            if is_instance_valid(m):
                m.queue_free()
        var b: Dictionary = (Bestiary.BOSS_DEFS["ossuary_lord"] as Dictionary).duplicate()
        b["id"] = "ossuary_lord"
        _lord = Monster.new()
        _lord.def = Bestiary.boss_def(b)
        _lord.state = Monster.S.IDLE
        _lord.position = Vector3(0, 0, -8)
        _lord.rotation.y = 0.0
        _stage.add_child(_lord)
        _cam.global_position = Vector3(-9, 4.0, 10)
        _cam.look_at(Vector3(0, 3.0, -7), Vector3.UP)
    if _f == 152:
        _lord.entrance()
    if _f == 185:
        _snap("lord_rising")
    if _f == 300:
        _snap("lord_risen")
        return true
    return false
func _snap(nm: String) -> void:
    root.get_texture().get_image().save_png("user://%s.png" % nm)
    print("SAVED ", nm)
