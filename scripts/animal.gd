class_name Animal
extends Node3D
## A grazing / wandering animal. Wanders between random points inside its
## area (a rect: centre, forward, side, half-width, half-depth), pauses to
## idle, never leaves. Ducks float at a fixed height and paddle slowly.
## Animation names differ per file (Walk, Walk_001, clip...), so they are found
## by prefix.

var model := ""
var scale_f := 1.0
var town: Node3D
var centre := Vector3.ZERO
var fwd := Vector3(0, 0, 1)
var side := Vector3(1, 0, 0)
var hw := 5.0
var hd := 5.0
var speed := 1.0
var float_y := INF            # set for ducks: ride the water surface
var yaw_off := 0.0            # models that face -Z get PI
var _ap: AnimationPlayer
var _walk := ""
var _idle := ""
var _target := Vector3.ZERO
var _wait := 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
    _rng.randomize()
    var ps: PackedScene = load(model)
    if ps == null:
        return
    var m: Node3D = ps.instantiate()
    m.scale = Vector3.ONE * scale_f
    m.rotation.y = yaw_off
    add_child(m)
    var st: Array = [m]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is AnimationPlayer:
            _ap = c
        for g in c.get_children():
            st.append(g)
    if _ap:
        for a in _ap.get_animation_list():
            var s := String(a)
            if s.begins_with("Walk") and not s.begins_with("WalkSlow") and _walk == "":
                _walk = s
            if s.begins_with("WalkSlow"):
                _walk = s                     # grazing pace reads better
            if s.begins_with("Idle"):
                _idle = s
            if s == "clip":
                _walk = s
                _idle = s
        for a in [_walk, _idle]:
            if a != "" and _ap.has_animation(a):
                _ap.get_animation(a).loop_mode = Animation.LOOP_LINEAR
        _play(_idle)
        _ap.seek(_rng.randf() * 1.5, true)
    _wait = _rng.randf_range(0.0, 6.0)

func _play(a: String) -> void:
    if _ap and a != "" and _ap.current_animation != a:
        _ap.play(a, 0.25)

func _pick() -> Vector3:
    return centre + side * _rng.randf_range(-hw, hw) + fwd * _rng.randf_range(-hd, hd)

func _ground(p: Vector3) -> float:
    if float_y != INF:
        return float_y + sin(Time.get_ticks_msec() * 0.002 + p.x) * 0.03
    return float(town.call("height_at", p.x, p.z))

func _physics_process(delta: float) -> void:
    if town == null:
        return
    if _target == Vector3.ZERO:
        _wait -= delta
        if _wait <= 0.0:
            _target = _pick()
        else:
            _play(_idle)
        return
    var to := _target - global_position
    to.y = 0.0
    if to.length() < 0.4:
        _target = Vector3.ZERO
        _wait = _rng.randf_range(3.0, 12.0)
        _play(_idle)
        return
    var d := to.normalized()
    var p := global_position + d * speed * delta
    p.y = _ground(p)
    global_position = p
    rotation.y = lerp_angle(rotation.y, atan2(d.x, d.z), delta * 4.0)
    _play(_walk)
