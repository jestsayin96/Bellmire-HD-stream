extends SceneTree
## S143 / System 14 gate: the graveyard keeper exists, stands at a sane height,
## walks between the chapel's graves and stoops at them. Renders one frame.
var _t: Node3D
var _f := 0
var _k: Node3D = null
var _start := Vector3.ZERO
var _maxd := 0.0
var _clips := {}
var _cam: Camera3D = null
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _process(_d: float) -> bool:
    _f += 1
    if _f == 30:
        _k = _t.get("grave_keeper")
        if _k == null:
            print("S143_KEEPER FAIL no keeper (graves=%d)" % (_t.get("_grave_spots") as Array).size())
            quit()
            return true
        _start = _k.position
    if _k and _f > 30:
        _maxd = maxf(_maxd, Vector2(_k.position.x - _start.x, _k.position.z - _start.z).length())
        var c := String(_k.get("_clip"))
        _clips[c] = int(_clips.get(c, 0)) + 1
        if _f == 400:
            _cam = Camera3D.new()
            root.add_child(_cam)
            var kp := _k.global_position
            var cp := kp + Vector3(4.5, 2.6, 4.5)
            _cam.look_at_from_position(cp, kp + Vector3(0, 1.0, 0))
            _cam.fov = 50
            _cam.current = true
        if _f == 420:
            var img := root.get_viewport().get_texture().get_image()
            if img:
                img.save_png("res://renders/cycles/s143/keeper.png")
    if _f >= 900:
        var graves := (_t.get("_grave_spots") as Array).size()
        var h := float(_k.get("height_m"))
        var ok := graves >= 2 and h > 1.5 and h < 2.2 and _maxd > 1.5 and _clips.has("walk") and _clips.has("interact-right")
        print("S143_KEEPER %s graves=%d height_m=%.2f max_travel=%.2f clips=%s" % ["OK" if ok else "FAIL", graves, h, _maxd, str(_clips)])
        quit()
    return false
