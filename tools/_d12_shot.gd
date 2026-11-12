extends SceneTree
## D12 renders: each place beyond the wall, the ford, and the valley from above,
## with travellers on the roads. Windowed. -> renders/cycles/20261112_d12/
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _dir := ""
var _shots: Array = []
var _i := 0

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _dir = ProjectSettings.globalize_path("res://renders/cycles/20261112_d12/")
    DirAccess.make_dir_recursive_absolute(_dir)

func _process(_d: float) -> bool:
    _f += 1
    if _f == 2:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        _cam.fov = 60.0
        _cam.far = 3000.0
        _t.get("raids").set("_raid_t", 99999.0)
        (_t.get("economy") as Economy).clock = 10.5 / 24.0
    if _f == 40:
        var v = _t.get("valley")
        for k in ["Coalfoot Steading", "the Ashwood", "the ford", "the Old Footing", "Bramble End"]:
            if v.sites.has(k):
                _shots.append([k.replace(" ", "_").to_lower(), v.sites[k]["pos"]])
        # put travellers on the road for the pictures
        for tr in v.TRIPS:
            v.send(tr)
        Engine.time_scale = 6.0
    if _f == 700:
        Engine.time_scale = 1.0
    if _f >= 720 and (_f - 720) % 30 == 0:
        var n := (_f - 720) / 30
        if n > 0:
            var nm: String = _shots[n - 1][0] if n - 1 < _shots.size() else ("overview_%d" % (n - 1 - _shots.size()))
            root.get_texture().get_image().save_png(_dir + nm + ".png")
            print("SAVED ", nm)
        if n < _shots.size():
            var p: Vector3 = _shots[n][1]
            p.y = float(_t.call("height_at", p.x, p.z))
            var d := Vector3(-p.x, 0, -p.z).normalized()
            _cam.global_position = p + d * 34.0 + Vector3(0, 22.0, 0) + Vector3(-d.z, 0, d.x) * 10.0
            _cam.look_at(p + Vector3(0, 1.5, 0), Vector3.UP)
        elif n == _shots.size():
            _cam.global_position = Vector3(-60, 230, 360)
            _cam.look_at(Vector3(-20, 0, 40), Vector3.UP)
        elif n == _shots.size() + 1:
            _cam.global_position = Vector3(160, 210, -330)
            _cam.look_at(Vector3(0, 0, -40), Vector3.UP)
        else:
            print("D12_SHOTS DONE")
            return true
    return false
