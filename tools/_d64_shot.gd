extends SceneTree
## D64a LOOK: the smithy's rack at a level 1 smithy (pegs 2-4 draped, each saying its rarity and
## the smithy level it needs) and after a viewer raise to level 3. Windowed, 1920x1080.
## Writes renders/cycles/d64/d64_rack_{lv1,lv3}.png
var _t: Node3D
var _cam: Camera3D
var _f := 0
func _initialize() -> void:
    root.size = Vector2i(1920, 1080)
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _process(_d: float) -> bool:
    _f += 1
    var eco = _t.get("economy")
    if _f == 15:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        _cam.fov = 42.0
        var fr: Array = (_t.get("_shop_frame") as Dictionary).get("blacksmith", [])
        var y: Vector3 = fr[0]
        var side: Vector3 = fr[1]
        var f: Vector3 = fr[2]
        var rp := y + side * -1.8 + f * 1.4
        rp.y = float(_t.call("height_at", rp.x, rp.z))
        _cam.global_position = rp + f * 3.6 + Vector3(0, 1.8, 0)
        _cam.look_at(rp + Vector3(0, 1.0, 0), Vector3.UP)
        eco.shop_raised["smithy"] = 0
        eco.shop_grown["smithy"] = 1
        eco._apply_shop_caps()
        print("D64SHOT smithy level ", eco.shop_level(), " ceiling ", Roster.town_tier)
    if _f == 60:
        root.get_texture().get_image().save_png("res://renders/cycles/d64/d64_rack_lv1.png")
        eco.raise_shop("smithy", 2, "MrE")
        print("D64SHOT raised: ", (_t.get("feed") as Array).back())
    if _f == 90:
        root.get_texture().get_image().save_png("res://renders/cycles/d64/d64_rack_lv3.png")
        print("D64SHOT saved")
        return true
    return false
