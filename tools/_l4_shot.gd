extends SceneTree
## L4 render: the six new callings in their cloaks, with their weapons, dressed as HeroBody.refresh does.
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
    _r = Roster.new()
    _stage.add_child(_r)
    var line := [["Oathsworn", "paladin", 2, 3, ""], ["Gravereader", "necromancer", 2, 1, ""], ["Stillhand", "monk", 2, 0, ""],
        ["Mossheart", "druid", 2, 1, ""], ["Bargainer", "warlock", 2, 1, ""], ["Songbird", "bard", 2, 1, ""]]
    for i in range(line.size()):
        var v: Array = line[i]
        var h: Dictionary = _r.fresh("x%d" % i, v[0], v[1])
        h["weapon"] = v[2]
        h["armour"] = v[3]
        if String(v[4]) != "":
            h["wkind"] = v[4]
        _dress(h, Vector3(float(i) * 1.6 - 5.6, 0, 0))
    _shots = [["callings_front", Vector3(0, 2.0, -7.5), Vector3(0, 0.9, 0)],
              ["callings_close", Vector3(-3.0, 1.6, -3.2), Vector3(-2.2, 0.9, 0)],
              ["callings_close_b", Vector3(3.0, 1.6, -3.2), Vector3(2.4, 0.9, 0)],
              ["callings_back", Vector3(-1.5, 2.2, 6.5), Vector3(-1.5, 0.9, 0)]]
var _r: Roster
func _adv(f: String) -> String:
    return "" if f == "" else (f if f.begins_with("res://") else Gear.ADV + f)
func _dress(h: Dictionary, p: Vector3) -> void:
    var m: Node3D = (load("res://addons/kaykit_character_pack_adventures/Characters/gltf/" + String(Roster.CLASSES[h["class"]]["model"])) as PackedScene).instantiate()
    _stage.add_child(m)
    m.position = p
    m.rotation.y = PI
    Gear.strip_props(m)
    var look := _r.weapon_look(h)
    Gear.equip(m, _adv(_r.weapon_mesh(h)), "handslot.r", "weapon", float(look["scale"]), float(look["glow"]))
    Gear.equip(m, _adv(_r.offhand_mesh(h)), _r.offhand_bone(h), "offhand")
    Gear.rank_trim(m, 0)
    var ap := Rig.find(m)
    if ap:
        Rig.prep(ap)
        Rig.play(ap, "Idle")
    var lb := Label3D.new()
    lb.text = "%s\n%s\n%s" % [h["name"], _r.weapon_name(h), Roster.ARMOUR[int(h["armour"])]["name"]]
    lb.font_size = 28
    lb.pixel_size = 0.005
    lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    lb.outline_size = 10
    lb.position = p + Vector3(0, 2.5, 0)
    _stage.add_child(lb)
func _process(_d: float) -> bool:
    _f += 1
    if _f < 40:
        return false
    if (_f - 40) % 20 == 0:
        if _i > 0:
            root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://renders/cycles/20261111_l4/%s.png" % _shots[_i - 1][0]))
        if _i >= _shots.size():
            return true
        var s: Array = _shots[_i]
        _cam.fov = 50.0
        _cam.global_position = s[1]
        _cam.look_at(s[2], Vector3.UP)
        _i += 1
    return false
