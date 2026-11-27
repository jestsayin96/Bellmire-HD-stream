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
# S143b: the freeze frame. He walks 1.1 m/s and graves sit up to ~5.5 m apart; an uncapped
# window runs 150-180 fps, so 880 frames was ~5 s and could end before his first stoop.
const FZ := 1500
var _shot := ""
var _saved: Array = []
var _gap := 0.0
var _parented := true
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
        if _f < FZ:   # count only his own round, never the gate's forced poses
            _clips[c] = int(_clips.get(c, 0)) + 1
        if _f % 100 == 0 and _f < FZ:
            var sp: Array = _k.get("spots")
            var tg: Vector3 = sp[int(_k.get("_i"))]
            print("S143_TRACE f=%d fps=%d clip=%s pos=%s tgt=%s d=%.2f wait=%.2f" % [_f, Engine.get_frames_per_second(), c, str(_k.position), str(tg), Vector2(tg.x - _k.position.x, tg.z - _k.position.z).length(), float(_k.get("_wait"))])
        if _f == FZ:
            # S143b: freeze him in the walking/idle hold and shoot front, side, back,
            # then one frame tending - the lantern must hang from the RIGHT FIST.
            _k.set_process(false)
            _hide_hud(root)
            _k.call("_play", "idle")
            _k.call("_pose", 0.5)
            _cam = Camera3D.new()
            root.add_child(_cam)
            _cam.fov = 40
            _cam.current = true
        if _f >= (FZ + 2) and _f <= (FZ + 19) and _cam:
            var kp := _k.global_position
            var fw := _k.global_basis.z.normalized()
            var rt := fw.cross(Vector3.UP).normalized()
            var views := {(FZ + 2): ["front", fw], (FZ + 6): ["side", -rt], (FZ + 10): ["back", -fw], (FZ + 14): ["tend", (fw - rt).normalized()]}
            if views.has(_f):
                if _f == (FZ + 14):
                    _k.call("_play", "interact-right")
                    _k.call("_pose", 0.6)
                var v: Array = views[_f]
                _cam.look_at_from_position(kp + (v[1] as Vector3) * 3.6 + Vector3(0, 2.4, 0), kp + Vector3(0, 0.8, 0))
                _shot = String(v[0])
            if _shot != "" and (_f in [(FZ + 5), (FZ + 9), (FZ + 13), (FZ + 17)]):
                var img := root.get_viewport().get_texture().get_image()
                if img:
                    img.save_png("res://renders/cycles/s143/keeper_%s.png" % _shot)
                    _saved.append(_shot)
                var lan: Node3D = _k.get("lantern")
                var hand: Node3D = _k.get("_hand")
                if lan and hand:
                    var top := lan.global_position + Vector3(0, 0.36 * 1.3, 0)
                    _gap = maxf(_gap, top.distance_to(hand.global_position))
                    _parented = _parented and lan.get_parent() == _k
                _shot = ""
    if _f >= (FZ + 19):
        var graves := (_t.get("_grave_spots") as Array).size()
        var h := float(_k.get("height_m"))
        var has_l: bool = _k.get("lantern") != null
        var ok := graves >= 2 and h > 1.5 and h < 2.2 and _maxd > 1.5 and _clips.has("walk") and _clips.has("interact-right") and has_l and _gap < 0.02 and _saved.size() == 4
        print("S143_KEEPER %s graves=%d height_m=%.2f max_travel=%.2f lantern=%s hand_gap_m=%.4f shots=%s census=%s clips=%s" % ["OK" if ok else "FAIL", graves, h, _maxd, str(has_l), _gap, str(_saved), str(_t.get("_grave_census")), str(_clips)])
        quit()
    return false

func _hide_hud(n: Node) -> void:
    if n is CanvasLayer:
        (n as CanvasLayer).visible = false
    for c in n.get_children():
        _hide_hud(c)
