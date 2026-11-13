extends SceneTree
## D20b LOOK: the market square + nearby streets. BUSY (midday) -> a RAID clears
## the streets (folk fled indoors) -> a FESTIVAL gathers a crowd. Windowed,
## --fixed-fps 60 -> renders/cycles/20261113_d20b.
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _out := ""
var phase := "warm"
var _mark := 0

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _out = ProjectSettings.globalize_path("res://renders/cycles/20261113_d20b")
    DirAccess.make_dir_recursive_absolute(_out)

func _aim() -> void:
    var mk = _t.get("_market_pos")
    var c: Vector3 = mk if mk is Vector3 and mk != Vector3.ZERO else Vector3.ZERO
    _cam.global_position = c + Vector3(26, 30, 26)
    _cam.look_at(Vector3(c.x, 1.0, c.z), Vector3.UP)

func _save(k: String) -> void:
    root.get_texture().get_image().save_png(_out + "/%s.png" % k)
    print("SAVED ", k)

func _process(_d: float) -> bool:
    _f += 1
    var eco = _t.get("economy")
    if _f == 60:
        _cam = Camera3D.new(); _t.add_child(_cam); _cam.fov = 55.0
    if _cam and _f > 60 and _cam != root.get_viewport().get_camera_3d():
        _cam.make_current()
    if eco and _f >= 60 and phase != "night":
        eco.clock = 0.50     # hold midday, bright
    if _cam:
        _aim()
    if phase == "warm" and _f >= 600:
        _save("1_busy_midday")
        var rd = _t.get("raids")
        rd.force_level = 5
        rd.call("raid", "west")
        phase = "raid"; _mark = _f
    elif phase == "raid" and _f - _mark >= 1200:
        _save("2_raid_streets_cleared")
        var rd = _t.get("raids")
        for r in (rd.get("raiders") as Array).duplicate():
            rd.call("_raider_falls", r, "shot")
        phase = "cool"; _mark = _f
    elif phase == "cool" and _f - _mark >= 480:
        _t.set("festival", true)
        _t.set("festival_at", _t.get("_market_pos"))
        _t.set("_fest_left", 300.0)
        phase = "fest"; _mark = _f
    elif phase == "fest" and _f - _mark >= 1500:
        _save("3_festival_crowd")
        return true
    return false
