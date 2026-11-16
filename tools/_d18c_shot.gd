extends SceneTree
## D18c shot sheet: the wet muddy shore where the valley ground slides under
## the river - before (wet band off) / after - and the smith's tier rack
## (ignite now baked into unique meshes; must look as before).
## Run WINDOWED for real materials. -> renders/cycles/20261112_d18c/*.png
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _out := ""
var _shots: Array = []   # [name, target, offset, water_y]
var _i := 0
var _armed := -1
var _gmat: ShaderMaterial

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _out = ProjectSettings.globalize_path("res://renders/cycles/20261112_d18c")
    DirAccess.make_dir_recursive_absolute(_out)

func _find_ground() -> void:
    for c in _t.get_children():
        if c is MeshInstance3D and (c as MeshInstance3D).material_override is ShaderMaterial:
            var sm := (c as MeshInstance3D).material_override as ShaderMaterial
            if sm.shader and String(sm.shader.resource_path).ends_with("ground.gdshader"):
                _gmat = sm
                return

func _plan() -> void:
    var fx: float = float(_t.get("ford_x"))
    var fz: float = float(_t.call("river_z_fast", fx))
    var bz: float = float(_t.call("river_z_fast", 30.0))
    _shots.append(["ford_shore_before", Vector3(fx, -0.9, fz), Vector3(9, 5, 16), -9999.0])
    _shots.append(["ford_shore_after", Vector3(fx, -0.9, fz), Vector3(9, 5, 16), -0.9])
    _shots.append(["bank_before", Vector3(30.0, -0.9, bz), Vector3(-10, 5, 14), -9999.0])
    _shots.append(["bank_after", Vector3(30.0, -0.9, bz), Vector3(-10, 5, 14), -0.9])
    var sf: Dictionary = _t.get("_shop_frame")
    if sf.has("blacksmith"):
        var y: Vector3 = (sf["blacksmith"] as Array)[0]
        _shots.append(["rack", Vector3(y.x, float(_t.call("height_at", y.x, y.z)) + 1.2, y.z), Vector3(4, 2.4, 7), -0.9])

func _process(_d: float) -> bool:
    _f += 1
    if _f == 90:
        _cam = Camera3D.new()
        _cam.fov = 50.0
        _cam.far = 900.0
        _t.add_child(_cam)
        _find_ground()
        _plan()
    if _cam == null:
        return false
    if _cam != root.get_viewport().get_camera_3d():
        _cam.make_current()
    if _i >= _shots.size():
        return _f > 120
    var sh: Array = _shots[_i]
    var target: Vector3 = sh[1]
    var off: Vector3 = sh[2]
    if _armed != _i:
        if _gmat != null:
            _gmat.set_shader_parameter("water_y", float(sh[3]))
        _cam.global_position = target + off
        _cam.look_at(target + Vector3(0, 1.0, 0), Vector3.UP)
        _armed = _i
        return false
    if _f % 8 == 0:
        root.get_texture().get_image().save_png(_out + "/%02d_%s.png" % [_i, sh[0]])
        print("SAVED %02d_%s" % [_i, sh[0]])
        if _gmat != null:
            _gmat.set_shader_parameter("water_y", -0.9)
        _i += 1
    return false
