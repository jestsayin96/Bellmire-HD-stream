extends SceneTree
## Spell gallery: each spell cast on the square, then the same four cast inside
## the scar (each misfires into the next). Photographs mid-effect.
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _casters: Array = []
var _targets: Array = []
var _plan := []
var _i := 0
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _body(model: String, p: Vector3, yaw: float, role: String) -> Node3D:
    var v := Townsfolk.new()
    v.model = model
    v.role = role
    v.stay = true
    v.face_yaw = yaw
    v.person_name = role
    v.position = p
    _t.add_child(v)
    return v
func _process(_d: float) -> bool:
    _f += 1
    if _f == 20:
        _cam = Camera3D.new()
        _cam.fov = 55.0
        _t.add_child(_cam)
        _cam.make_current()
        var sc: Dictionary = _t.call("stats").get("scar", {})
        # open meadow past the bridge for the clean casts; the scar's road
        # (crystals stand off it) for the misfires
        var m := Vector3(-14, 0, 175)
        var s: Vector3 = sc.get("pos", Vector3.ZERO)
        var sf: Vector3 = sc.get("fwd", Vector3(0, 0, 1))
        s = s + sf * 6.0
        for spot in [[m, false], [s, true]]:
            var c: Vector3 = spot[0]
            c.y = float(_t.call("height_at", c.x, c.z))
            for k in range(4):
                var kind: String = Spells.ORDER[k]
                _plan.append([kind, c, bool(spot[1])])
    if _f < 30:
        return false
    # one shot every 40 frames: set up, cast at +4, photograph at +22
    var step := (_f - 30) % 40
    var idx := (_f - 30) / 40
    if idx >= _plan.size():
        return true
    var pl: Array = _plan[idx]
    var c: Vector3 = pl[1]
    if step == 0:
        for n in _casters + _targets:
            n.queue_free()
        _casters.clear()
        _targets.clear()
        var model := "Mage.glb"
        var a := c + Vector3(-3, 0, 0)
        var b := c + Vector3(3, 0, 0)
        a.y = float(_t.call("height_at", a.x, a.z))
        b.y = float(_t.call("height_at", b.x, b.z))
        _casters.append(_body(model, a, PI * 0.5, "mage"))
        _targets.append(_body("Knight.glb", b, -PI * 0.5, "guard"))
        _cam.global_position = c + Vector3(0, 4.0, 6.5)
        _cam.look_at(c + Vector3(0, 1.0, 0), Vector3.UP)
    if step == 4:
        var tgt: Vector3 = _targets[0].global_position
        if pl[0] == "bolt":
            tgt = c + Vector3(3, 0, 0)
        var actual := Spells.cast(String(pl[0]), _casters[0], tgt, bool(pl[2]))
        print("CAST ", pl[0], " scar=", pl[2], " -> ", actual)
    if step == (9 if pl[0] == "bolt" else 18):
        var nm := "spell_%s%s" % [pl[0], "_scar" if pl[2] else ""]
        root.get_texture().get_image().save_png("user://%s.png" % nm)
        print("SAVED ", nm)
    return false
