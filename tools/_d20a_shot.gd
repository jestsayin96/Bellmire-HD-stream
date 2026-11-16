extends SceneTree
## D20a render: the daily arc. Midday the market square is busy (folk shopping,
## a shopper mid-Interact/PickUp); of an evening folk take a mug at the tavern.
## Windowed, --fixed-fps 60 -> renders/cycles/20261112_d20a.
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _out := ""
var _done := {}
var _tav_folk: Array = []

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _out = ProjectSettings.globalize_path("res://renders/cycles/20261112_d20a")
    DirAccess.make_dir_recursive_absolute(_out)

func _aim_point(p: Vector3, eye: Vector3, look_h := 1.2) -> void:
    _cam.global_position = p + eye
    _cam.look_at(Vector3(p.x, look_h, p.z), Vector3.UP)

func _aim_node(n: Node3D, dist := 3.4, h := 1.7, side := 0.9, look_h := 0.8) -> void:
    var p: Vector3 = n.global_position
    var fw: Vector3 = n.global_transform.basis.z; fw.y = 0.0; fw = fw.normalized()
    var rt := Vector3(fw.z, 0, -fw.x)
    _cam.global_position = p + fw * dist + rt * side + Vector3(0, h, 0)
    _cam.look_at(p + Vector3(0, look_h, 0), Vector3.UP)

func _save(k: String) -> void:
    root.get_texture().get_image().save_png(_out + "/%s.png" % k)
    print("SAVED ", k)
    _done[k] = true

func _market_shopper() -> Townsfolk:
    var mk = _t.get("_market_pos")
    for v in _t.get("people"):
        if not is_instance_valid(v) or v.inside or not v.visible or v._anim == null or v.stay: continue
        if v.rank >= 0 or v.leader != null or v.cart != null: continue
        var ca := String(v._anim.current_animation)
        if ca in ["Interact", "PickUp"] and mk is Vector3 \
                and Vector2(v.global_position.x - mk.x, v.global_position.z - mk.z).length() < 16.0:
            return v
    return null

func _process(_d: float) -> bool:
    _f += 1
    var eco = _t.get("economy")
    if _f == 60:
        _cam = Camera3D.new(); _t.add_child(_cam); _cam.fov = 50.0
    if _cam and _f > 60 and _cam != root.get_viewport().get_camera_3d():
        _cam.make_current()
    # hold midday for the market phase
    if _f >= 60 and _f < 2200 and eco:
        eco.clock = 0.50                          # ~hour 12, bright
    # a wide of the square at midday
    if _f == 900 and not _done.has("square_midday"):
        var mk = _t.get("_market_pos")
        _aim_point(mk, Vector3(20, 11, 20), 1.0)
        _done["square_midday_aim"] = _f + 3
    if _done.has("square_midday_aim") and _f == int(_done["square_midday_aim"]) and not _done.has("square_midday"):
        _save("square_midday")
    # eye-level across the market
    if _f == 1200 and not _done.has("market_eye"):
        var mk = _t.get("_market_pos")
        _aim_point(mk, Vector3(-11, 2.2, -4), 1.2)
        _done["market_eye_aim"] = _f + 3
    if _done.has("market_eye_aim") and _f == int(_done["market_eye_aim"]) and not _done.has("market_eye"):
        _save("market_eye")
    # a shopper mid-anim
    if _f > 1300 and _f < 2100 and _f % 10 == 0 and not _done.has("market_shopper"):
        var v := _market_shopper()
        if v:
            _aim_node(v, 3.2, 1.6, 0.9, 0.9)
            _done["_shopper"] = v
            _done["market_shopper_aim"] = _f + 3
    if _done.has("market_shopper_aim") and _f == int(_done["market_shopper_aim"]) and not _done.has("market_shopper"):
        if is_instance_valid(_done["_shopper"]):
            _aim_node(_done["_shopper"], 3.2, 1.6, 0.9, 0.9)
        _save("market_shopper")
    # ---- evening: the tavern yard
    if _f == 2200 and eco:
        eco.clock = 0.80                          # ~hour 19, dusk
        var tv = _t.get("tavern_at")
        var picked := 0
        for v in _t.get("people"):
            if picked >= 3: break
            if not is_instance_valid(v) or v.inside or not v.visible or v._anim == null or v.stay: continue
            if v.rank >= 0 or v.leader != null or v.cart != null or not (v.stops as Array).is_empty(): continue
            if tv is Vector3 and tv != Vector3.INF:
                v._route = []
                v._enter_at = Vector3.ZERO
                v._seat_i = -1
                v.global_position = _t.call("keep_walkable", tv + Vector3(1.6 + picked*1.2, 0, 1.4 - picked*0.9))
                v._wait = 40.0
                v._eve_drink = true
                v._act_t = 0.0
                _tav_folk.append(v)
                picked += 1
    if _f >= 2200 and _f < 2300 and eco:
        eco.clock = 0.80
    # let them roll a mug (Use_Item), then frame the tavern
    if _f == 2500 and not _done.has("tavern_dusk"):
        var tv = _t.get("tavern_at")
        _aim_point(tv, Vector3(7, 3.0, 7), 1.1)
        _done["tavern_dusk_aim"] = _f + 3
    if _done.has("tavern_dusk_aim") and _f == int(_done["tavern_dusk_aim"]) and not _done.has("tavern_dusk"):
        _save("tavern_dusk")
    # a close mug shot
    if _f > 2550 and _f < 2900 and _f % 8 == 0 and not _done.has("tavern_mug"):
        for v in _tav_folk:
            if is_instance_valid(v) and String(v._anim.current_animation) in ["Use_Item", "Cheer"]:
                _aim_node(v, 3.0, 1.6, 0.9, 0.9)
                _done["_mug"] = v
                _done["tavern_mug_aim"] = _f + 3
                break
    if _done.has("tavern_mug_aim") and _f == int(_done["tavern_mug_aim"]) and not _done.has("tavern_mug"):
        if is_instance_valid(_done["_mug"]):
            _aim_node(_done["_mug"], 3.0, 1.6, 0.9, 0.9)
        _save("tavern_mug")
    if _f >= 60 * 55:
        print("D20A_SHOT done ", _done.keys())
        return true
    return false
