extends SceneTree
## The armourer's rack at founding (tier 4 under a cloth) and after the town grows.
var _t: Node3D
var _cam: Camera3D
var _f := 0
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _process(_d: float) -> bool:
    _f += 1
    if _f == 15:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        _cam.fov = 50.0
        var fr: Array = (_t.get("_shop_frame") as Dictionary).get("blacksmith", [])
        var y: Vector3 = fr[0]
        var side: Vector3 = fr[1]
        var f: Vector3 = fr[2]
        var rp := y + side * -1.8 + f * 1.4
        rp.y = float(_t.call("height_at", rp.x, rp.z))
        _cam.global_position = rp + f * 4.2 + Vector3(0, 2.1, 0)
        _cam.look_at(rp + Vector3(0, 1.2, 0), Vector3.UP)
        print("TIER ", Roster.town_tier, " level ", _t.get("economy").town_level)
    if _f == 40:
        root.get_texture().get_image().save_png("user://rack_before.png")
        _t.call("show_tiers", 4)
    if _f == 50:
        root.get_texture().get_image().save_png("user://rack_after.png")
        print("SAVED racks")
        return true
    return false
