extends SceneTree
## D18b shot sheet: the dressed valley - each steading with its fields and
## fences, the ford jetty, a kitchen garden, the copse, and an aerial. Run
## windowed for real materials. -> renders/cycles/20261112_d18b/*.png
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _out := ""
var _shots: Array = []
var _i := 0
var _armed := -1

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _out = ProjectSettings.globalize_path("res://renders/cycles/20261112_d18b")
    DirAccess.make_dir_recursive_absolute(_out)

func _plan() -> void:
    var val: Node = _t.find_child("Valley", true, false)
    var sites: Dictionary = val.get("sites")
    var fx: float = float(_t.get("ford_x"))
    # [name, ground target, cam offset, pitch-look height]
    for nm in ["Coalfoot Steading", "Bramble End", "the Ashwood", "the Old Footing"]:
        if sites.has(nm):
            var p: Vector3 = sites[nm]["pos"]
            _shots.append([nm.replace(" ", "_"), _g(p), Vector3(6, 20, 32)])
    _shots.append(["the_jetty", _g(Vector3(fx - 22.0, 0, float(_t.call("river_z_fast", fx - 22.0)) + 6.0)), Vector3(10, 10, 20)])
    _shots.append(["ford", _g(sites["the ford"]["pos"] if sites.has("the ford") else Vector3(fx,0,0)), Vector3(8, 14, 26)])
    _shots.append(["aerial_south", _g(Vector3(0, 0, 80)), Vector3(0, 120, 70)])

func _g(p: Vector3) -> Vector3:
    return Vector3(p.x, float(_t.call("height_at", p.x, p.z)), p.z)

func _process(_d: float) -> bool:
    _f += 1
    if _f == 90:
        _cam = Camera3D.new()
        _cam.fov = 50.0
        _cam.far = 900.0
        _t.add_child(_cam)
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
        _cam.global_position = target + off
        _cam.look_at(target + Vector3(0, 2.0, 0), Vector3.UP)
        _armed = _i
        return false
    if _f % 6 == 0:
        root.get_texture().get_image().save_png(_out + "/%02d_%s.png" % [_i, sh[0]])
        print("SAVED %02d_%s at (%d,%d)" % [_i, sh[0], int(target.x), int(target.z)])
        _i += 1
    return false
