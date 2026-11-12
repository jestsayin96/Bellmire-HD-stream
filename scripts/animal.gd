class_name Animal
extends Node3D
## A grazing / wandering animal. Wanders between random points inside its
## area (a rect: centre, forward, side, half-width, half-depth), pauses to
## idle, never leaves. Ducks float at a fixed height and paddle slowly.
## Animation names differ per file (Walk, Walk_001, clip...), so they are found
## by prefix. "proc:hen" / "proc:cat" are built from simple shapes here and
## animated by hand (no CC0 hen or cat model in the packs we use).
## Targets inside a building's footprint (town.solid_at) are never picked, so
## nothing wanders through a house or ends up on top of one.

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
var kind := ""
var edge := false             # a sheepdog: walks the edge of its flock's pen
var _proc := ""
var _parts := {}
var _moving := false
var _tt := 0.0
var _peck := 0.0
var _ap: AnimationPlayer
var _walk := ""
var _idle := ""
var _target := Vector3.ZERO
var _wait := 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
    _rng.randomize()
    if model.begins_with("proc:"):
        _proc = model.substr(5)
        var pm := _build_hen() if _proc == "hen" else _build_cat()
        pm.scale = Vector3.ONE * scale_f
        add_child(pm)
        _walk = "walk"
        _idle = "idle"
        _tt = _rng.randf() * 10.0
        _wait = _rng.randf_range(0.0, 6.0)
        return
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
    _moving = a == _walk
    if _ap and a != "" and _ap.current_animation != a:
        _ap.play(a, 0.25)

func _pick() -> Vector3:
    for i in range(10):
        var p := centre + side * _rng.randf_range(-hw, hw) + fwd * _rng.randf_range(-hd, hd)
        if edge:
            var u := _rng.randf_range(-1.0, 1.0)
            var sg := 1.0 if _rng.randf() < 0.5 else -1.0
            if _rng.randf() < 0.5:
                p = centre + side * (hw * u) + fwd * (hd * sg)
            else:
                p = centre + side * (hw * sg) + fwd * (hd * u)
        if _open(p):
            return p
    return Vector3.ZERO

func _blocked(p: Vector3) -> bool:
    return town.has_method("solid_at") and not (town.call("solid_at", p, 0.15) as Array).is_empty()

## true when p and the straight walk to it stay out of every building
func _open(p: Vector3) -> bool:
    if float_y != INF or town == null or not town.has_method("solid_at"):
        return true
    var a := global_position
    for f in [1.0, 0.75, 0.5, 0.25]:
        var q := a.lerp(p, float(f))
        if not (town.call("solid_at", q, 0.35) as Array).is_empty():
            return false
    return true

func _ground(p: Vector3) -> float:
    if float_y != INF:
        return float_y + sin(Time.get_ticks_msec() * 0.002 + p.x) * 0.03
    return float(town.call("height_at", p.x, p.z))

func _physics_process(delta: float) -> void:
    if _proc != "":
        _anim(delta)
    if town == null:
        return
    if _target == Vector3.ZERO:
        _wait -= delta
        if _wait <= 0.0:
            _target = _pick()
            if _target == Vector3.ZERO:
                _wait = _rng.randf_range(1.0, 3.0)
        else:
            _play(_idle)
        return
    var to := _target - global_position
    to.y = 0.0
    if to.length() < 0.4:
        _target = Vector3.ZERO
        _wait = _rng.randf_range(3.0, 12.0)
        if _proc == "cat":
            _wait = _rng.randf_range(8.0, 30.0)     # cats nap
        _play(_idle)
        return
    var d := to.normalized()
    var p := global_position + d * speed * delta
    if float_y == INF and _blocked(p) and not _blocked(global_position):
        _target = Vector3.ZERO                  # a stall or a wall in the way: stop, pick again
        _wait = _rng.randf_range(0.5, 2.0)
        _play(_idle)
        return
    p.y = _ground(p)
    global_position = p
    rotation.y = lerp_angle(rotation.y, atan2(d.x, d.z), delta * 4.0)
    _play(_walk)

## ------------------------------------------------ hand-built hen and cat
func _m(c: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = 0.9
    return m

func _part(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, scl := Vector3.ONE, rot := Vector3.ZERO) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    mi.material_override = mat
    mi.position = pos
    mi.scale = scl
    mi.rotation = rot
    parent.add_child(mi)
    return mi

func _pivot(parent: Node3D, key: String, pos: Vector3) -> Node3D:
    var n := Node3D.new()
    n.position = pos
    parent.add_child(n)
    _parts[key] = n
    return n

func _sphere(r: float) -> SphereMesh:
    var m := SphereMesh.new()
    m.radius = r
    m.height = r * 2.0
    m.radial_segments = 12
    m.rings = 6
    return m

func _cyl(top: float, bot: float, h: float) -> CylinderMesh:
    var m := CylinderMesh.new()
    m.top_radius = top
    m.bottom_radius = bot
    m.height = h
    m.radial_segments = 8
    return m

## a hen, about 0.45 m tall, facing +Z
func _build_hen() -> Node3D:
    var cols := [Color(0.92, 0.9, 0.84), Color(0.55, 0.32, 0.16), Color(0.16, 0.15, 0.14), Color(0.85, 0.64, 0.38)]
    var feather: Color = cols[_rng.randi_range(0, cols.size() - 1)]
    var fm := _m(feather)
    var dk := _m(feather.darkened(0.3))
    var red := _m(Color(0.78, 0.1, 0.08))
    var yel := _m(Color(0.93, 0.62, 0.15))
    var root := Node3D.new()
    var body := _pivot(root, "body", Vector3(0, 0, 0))
    _part(body, _sphere(0.15), fm, Vector3(0, 0.27, 0), Vector3(0.9, 0.85, 1.25))
    _part(body, BoxMesh.new(), dk, Vector3(0, 0.39, -0.17), Vector3(0.12, 0.17, 0.06), Vector3(-0.5, 0, 0))
    _part(body, _sphere(0.06), dk, Vector3(0.12, 0.28, -0.01), Vector3(0.4, 0.9, 1.6))
    _part(body, _sphere(0.06), dk, Vector3(-0.12, 0.28, -0.01), Vector3(0.4, 0.9, 1.6))
    var head := _pivot(body, "head", Vector3(0, 0.34, 0.13))
    _part(head, _sphere(0.065), fm, Vector3(0, 0.08, 0.04))
    _part(head, BoxMesh.new(), red, Vector3(0, 0.16, 0.04), Vector3(0.025, 0.06, 0.08))
    _part(head, _cyl(0.0, 0.022, 0.06), yel, Vector3(0, 0.075, 0.12), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
    _part(head, _sphere(0.018), red, Vector3(0, 0.035, 0.09))
    for sx in [-1.0, 1.0]:
        var leg := _pivot(root, "leg" + ("L" if sx < 0.0 else "R"), Vector3(0.05 * float(sx), 0.17, 0.0))
        _part(leg, _cyl(0.011, 0.011, 0.17), yel, Vector3(0, -0.085, 0))
        _part(leg, BoxMesh.new(), yel, Vector3(0, -0.168, 0.025), Vector3(0.04, 0.008, 0.07))
    return root

## a cat, about 0.32 m tall, facing +Z
func _build_cat() -> Node3D:
    var cols := [Color(0.85, 0.5, 0.2), Color(0.45, 0.45, 0.48), Color(0.08, 0.08, 0.09), Color(0.9, 0.85, 0.74), Color(0.5, 0.36, 0.24)]
    var fur: Color = cols[_rng.randi_range(0, cols.size() - 1)]
    var fm := _m(fur)
    var lt := _m(fur.lightened(0.35))
    var eye := _m(Color(0.55, 0.75, 0.2))
    var root := Node3D.new()
    var body := _pivot(root, "body", Vector3(0, 0, 0))
    var cap := CapsuleMesh.new()
    cap.radius = 0.075
    cap.height = 0.4
    _part(body, cap, fm, Vector3(0, 0.2, 0), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
    var head := _pivot(body, "head", Vector3(0, 0.27, 0.19))
    _part(head, _sphere(0.075), fm, Vector3(0, 0.0, 0.0), Vector3(1.1, 0.95, 1.0))
    _part(head, _sphere(0.035), lt, Vector3(0, -0.025, 0.06))
    for sx in [-1.0, 1.0]:
        _part(head, _cyl(0.0, 0.03, 0.065), fm, Vector3(0.045 * float(sx), 0.075, -0.005))
        _part(head, _sphere(0.012), eye, Vector3(0.032 * float(sx), 0.015, 0.068))
    var tail := _pivot(body, "tail", Vector3(0, 0.23, -0.19))
    tail.rotation.x = -0.55
    _part(tail, _cyl(0.012, 0.017, 0.3), fm, Vector3(0, 0.15, 0))
    var i := 0
    for lz in [0.13, -0.13]:
        for sx in [-1.0, 1.0]:
            var leg := _pivot(root, "leg%d" % i, Vector3(0.045 * float(sx), 0.15, float(lz)))
            _part(leg, _cyl(0.018, 0.018, 0.15), fm, Vector3(0, -0.075, 0))
            i += 1
    return root

func _anim(delta: float) -> void:
    _tt += delta
    var body: Node3D = _parts.get("body")
    var head: Node3D = _parts.get("head")
    if _proc == "hen":
        var w := sin(_tt * 15.0)
        if _moving:
            (_parts["legL"] as Node3D).rotation.x = w * 0.6
            (_parts["legR"] as Node3D).rotation.x = -w * 0.6
            body.position.y = absf(w) * 0.02
            head.position.z = 0.13 + w * 0.02
            head.rotation.x = 0.0
        else:
            (_parts["legL"] as Node3D).rotation.x = 0.0
            (_parts["legR"] as Node3D).rotation.x = 0.0
            body.position.y = 0.0
            # peck at the ground now and then
            _peck -= delta
            if _peck <= -0.45:
                _peck = _rng.randf_range(0.8, 4.0)
            head.rotation.x = 1.1 if _peck < 0.0 else 0.0
    else:
        var tail: Node3D = _parts["tail"]
        tail.rotation.z = sin(_tt * 1.4) * 0.45
        var w := sin(_tt * 11.0)
        for k in range(4):
            var leg: Node3D = _parts["leg%d" % k]
            var ph := 1.0 if k == 0 or k == 3 else -1.0
            leg.rotation.x = w * 0.5 * ph if _moving else 0.0
        # a resting cat settles low, head up
        body.position.y = 0.0 if _moving else -0.06
        head.rotation.x = 0.0 if _moving else -0.15
