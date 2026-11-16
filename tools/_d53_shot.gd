extends SceneTree
## D53 LOOK (WINDOWED): a hauler with its wagon right behind it after it has had
## to tow the wagon along. Clock pinned to midday, raids suppressed.
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _dir := ""
var _who: Townsfolk = null

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _dir = ProjectSettings.globalize_path("res://renders/cycles/d53/")
    DirAccess.make_dir_recursive_absolute(_dir)

func _eye(at: Vector3, frm: Vector3) -> void:
    frm.y = maxf(frm.y, float(_t.call("height_at", frm.x, frm.z)) + 1.0)
    _cam.global_position = frm
    _cam.look_at(at, Vector3.UP)

func _hauler() -> Townsfolk:
    for p in _t.get("people"):
        if p is Townsfolk and is_instance_valid(p) and p.cart != null and is_instance_valid(p.cart):
            return p
    return null

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
        _cam.fov = 50.0
    if _f < 420:
        return false
    if _who == null or not is_instance_valid(_who):
        _who = _hauler()
    if _who == null:
        if _f > 520:
            print("D53_SHOT no hauler found")
            return true
        return false
    var c: Vector3 = _who.global_position
    var w: Vector3 = _who.cart.global_position
    var mid := (c + w) * 0.5
    _eye(mid, mid + Vector3(6.0, 3.0, 6.0))
    if _f >= 470:
        root.get_texture().get_image().save_png(_dir + "hauler_cart.png")
        print("SAVED hauler_cart  carter<->cart = %.1f m" % Vector2(c.x - w.x, c.z - w.z).length())
        return true
    return false
