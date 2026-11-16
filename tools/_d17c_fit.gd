extends SceneTree
## D17c fit check: a body sat on a bench / stool and a cow grazing, side on.
var _f := 0
var _cam: Camera3D
var _out := ""
var _cow: Animal
func _initialize() -> void:
    _out = ProjectSettings.globalize_path("res://renders/cycles/20261112_d17c")
    var w := Node3D.new()
    root.add_child(w)
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color(0.6, 0.7, 0.8)
    env.environment.ambient_light_color = Color(0.7, 0.7, 0.7)
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    w.add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation = Vector3(-0.8, 0.6, 0)
    w.add_child(sun)
    var gm := MeshInstance3D.new()
    var pm := PlaneMesh.new()
    pm.size = Vector2(30, 30)
    gm.mesh = pm
    w.add_child(gm)
    var town_s = load("res://scripts/town.gd")
    var off := float(OS.get_environment("SIT_OFF")) if OS.get_environment("SIT_OFF") != "" else 0.0
    var lift := float(OS.get_environment("SIT_LIFT")) if OS.get_environment("SIT_LIFT") != "" else 0.0
    for pair in [["Bench", Vector3(0, 0, 0)], ["Stool", Vector3(3, 0, 0)]]:
        var b: Node3D = (load(town_s.PROPS + pair[0] + ".gltf") as PackedScene).instantiate()
        b.scale = Vector3.ONE * town_s.PROP_SCALE
        b.position = pair[1]
        w.add_child(b)
        var k: Node3D = (load("res://addons/kaykit_character_pack_adventures/Characters/gltf/Rogue.glb") as PackedScene).instantiate()
        k.position = pair[1] + Vector3(0, lift, off)
        w.add_child(k)
        var ap := Rig.find(k)
        Rig.prep(ap)
        ap.play("Sit_Chair_Idle")
    var cw := Animal.new()
    cw.model = "res://assets/animals/Cow.glb"
    cw.position = Vector3(-4, 0, 0)
    cw.rotation.y = PI * 0.5
    for kk in w.get_children():
        pass
    w.add_child(cw)
    _cow = cw
    _cam = Camera3D.new()
    w.add_child(_cam)
    _cam.position = Vector3(-0.5, 1.8, 8.0)
    _cam.fov = 60
func _process(_d: float) -> bool:
    _f += 1
    if _f == 3:
        _cam.look_at(Vector3(-0.5, 0.6, 0), Vector3.UP)
        _cam.make_current()
    if _cow and _cow._graze:
        _cow._graze.target = 1.0
        _cow._wait = 99.0
    if _f == 149:
        print("CAM ", _cam.global_transform, " cur=", root.get_viewport().get_camera_3d())
        for c in _cam.get_parent().get_children():
            if c is Node3D: print("N ", c.name, " ", (c as Node3D).global_position, " vis=", (c as Node3D).visible)
    if _f == 150:
        root.get_texture().get_image().save_png(_out + "/fit_%s.png" % OS.get_environment("SIT_TAG"))
        return true
    return false
