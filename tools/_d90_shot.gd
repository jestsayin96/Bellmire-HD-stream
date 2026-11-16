extends SceneTree
## D90 LOOK (WINDOWED, --fixed-fps 60): the green-hooded caravan master and his
## cart, MOVING (walking in from the gate) and STOPPING (drawn up at the market),
## plus a carter mid-turn. Clock pinned to midday, raids suppressed. Writes
## renders/cycles/d90/*.png and prints the hauler<->cart distance + relative yaw
## for each frame shot.
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _dir := ""
var _cv: Townsfolk = null
var _shots := {}
var _carter: Townsfolk = null
var _cf := 0

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _dir = ProjectSettings.globalize_path("res://renders/cycles/d90/")
    DirAccess.make_dir_recursive_absolute(_dir)

func _eye(at: Vector3, frm: Vector3) -> void:
    frm.y = maxf(frm.y, float(_t.call("height_at", frm.x, frm.z)) + 1.0)
    _cam.global_position = frm
    _cam.look_at(at + Vector3(0, 0.8, 0), Vector3.UP)

func _frame(who: Townsfolk) -> void:
    var c := who.global_position
    var w: Vector3 = who.cart_body()
    var mid := (c + w) * 0.5
    var side := Vector3(cos(who.rotation.y), 0, -sin(who.rotation.y))
    _eye(mid, mid + side * 7.0 + Vector3(0, 3.2, 0) + Vector3(sin(who.rotation.y), 0, cos(who.rotation.y)) * 2.5)

func _snap(tag: String, who: Townsfolk) -> void:
    root.get_texture().get_image().save_png(_dir + tag + ".png")
    var c := who.global_position
    var w: Vector3 = who.cart_body()
    var tp: Vector3 = who.cart_tip()
    print("SAVED %s  %s hauler<->shaft tips=%.2f m rel_yaw=%.0f deg state=%d" % [tag, String(who.person_name), Vector2(c.x - tp.x, c.z - tp.z).length(), rad_to_deg(absf(angle_difference(who.rotation.y, float(who.cart.rotation.y)))), who.tow_state])
    _shots[tag] = true

func _process(_d: float) -> bool:
    _f += 1
    var ec = _t.get("economy")
    if ec != null:
        ec.clock = 12.3 / 24.0
    var rd = _t.get("raids")
    if rd != null:
        rd.set("_raid_t", 99999.0)
    if _f == 12:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        _cam.fov = 45.0
    if _f == 60:
        _t.call("_caravan")
    if _f < 70:
        return false
    if _cv == null:
        for c in _t.get("_caravans"):
            _cv = (c as Dictionary)["v"]
    if _cv == null or not is_instance_valid(_cv) or _cv.cart == null:
        if _f > 600:
            print("D90_SHOT no caravan")
            return true
        return false
    if _cf > 0:
        _frame(_carter)
    else:
        _frame(_cv)
    var moving: bool = not _cv._route.is_empty() and _cv.tow_state == Townsfolk.TOW_TOWED
    if _cf > 0:
        moving = false
    if moving and _f > 400 and not _shots.has("a_caravan_moving"):
        _snap("a_caravan_moving", _cv)
    if moving and _f > 700 and not _shots.has("b_caravan_moving2"):
        _snap("b_caravan_moving2", _cv)
    if _cf <= 0 and _cv.tow_state == Townsfolk.TOW_PARKED and not _shots.has("c_caravan_stopped"):
        _snap("c_caravan_stopped", _cv)
    if _cf <= 0 and _cv.tow_state == Townsfolk.TOW_UNPARKING and _cv._tow_t > 0.5 and not _shots.has("d_caravan_rehitch"):
        _snap("d_caravan_rehitch", _cv)
    if _cf <= 0 and _shots.has("d_caravan_rehitch") and _cv.tow_state == Townsfolk.TOW_TOWED and not _cv._route.is_empty() and not _shots.has("e_caravan_leaving"):
        _snap("e_caravan_leaving", _cv)
    if _carter == null:
        for p in _t.get("people"):
            if p is Townsfolk and is_instance_valid(p) and String(p.role) == "carter" and p.cart != null:
                _carter = p
                break
    if _cf == 0 and _carter != null and is_instance_valid(_carter) and not _shots.has("f_carter_stopped") and _carter.tow_state == Townsfolk.TOW_PARKED:
        _cf = _f
    if _cf > 0:
        _frame(_carter)
        if _f >= _cf + 4:
            _snap("f_carter_stopped", _carter)
            _cf = -1
        return false
    if _shots.size() >= 6 or _f > 60 * 360:
        print("D90_SHOT done shots=%d" % _shots.size())
        return true
    return false
