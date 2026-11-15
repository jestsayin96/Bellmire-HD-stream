extends SceneTree
## D91 stage 1/5/6 test.
##  A. EQUIVALENCE: Crowd.push (crowd.gd) against the OLD town.crowd_push maths,
##     kept here verbatim, over 4000 random bodies/headings. Must be identical.
##  B. TOWN: the town built, run 90 s; every 0.5 s every body pair is checked
##     (centres closer than the sum of body_r) and every body against the
##     solid footprints. Animal radii printed per kind (stage 6). Scatter-prop
##     registration audited per kind (stage 5).
const OLD_R := 0.75
const OLD_LOOK := 2.2
const OLD_SOFT := 1.4
const OLD_HARD := 5.0
const OLD_YIELD := 2.2
var _old: Dictionary = {}
var _t: Node3D
var _f := 0
var _fail := 0
var _samples := 0
var _pairs := 0
var _worst := 0.0
var _in_solid := 0
var _body_checks := 0
var _in_by: Dictionary = {}

static func _br(o: Node3D) -> float:
    var r = o.get("body_r")
    return float(r) if r != null else 0.28

func _old_push(v: Node3D, dir := Vector3.ZERO) -> Vector3:
    var p := v.global_position
    var rv := _br(v)
    var kx := floori(p.x * 0.5)
    var kz := floori(p.z * 0.5)
    var push := Vector3.ZERO
    var side := Vector3(-dir.z, 0.0, dir.x)
    var yield_best := 0.0
    var yield_dir := Vector3.ZERO
    var reach := 2 if dir != Vector3.ZERO else 1
    for dx in range(-reach, reach + 1):
        for dz in range(-reach, reach + 1):
            var cell = _old.get(Vector2i(kx + dx, kz + dz))
            if cell == null:
                continue
            for o in cell:
                if o == v:
                    continue
                var op: Vector3 = (o as Node3D).global_position
                if absf(op.y - p.y) > 3.0:
                    continue
                var d := Vector3(p.x - op.x, 0.0, p.z - op.z)
                var L := d.length()
                var contact := rv + _br(o)
                var ring := maxf(OLD_R, contact + 0.15)
                if L < ring:
                    if L < 0.01:
                        d = Vector3(cos(float(v.get_instance_id() % 628) * 0.01), 0.0, sin(float(v.get_instance_id() % 628) * 0.01))
                        L = 0.01
                    var n := d / L
                    push += n * OLD_SOFT * 2.0 * (ring - L) / ring
                    if L < contact:
                        push += n * OLD_HARD * (contact - L) / contact
                if dir == Vector3.ZERO:
                    continue
                var rel := -d
                var ahead := rel.dot(dir)
                if ahead <= 0.05 or ahead > OLD_LOOK:
                    continue
                var lat := rel.dot(side)
                var clear := contact + 0.2
                if absf(lat) >= clear:
                    continue
                var ov = o.get("move_dir")
                var odir: Vector3 = ov if ov is Vector3 else Vector3.ZERO
                if odir.dot(dir) > 0.6:
                    continue
                var w := (1.0 - ahead / OLD_LOOK) * (1.0 - absf(lat) / clear)
                if w > yield_best:
                    yield_best = w
                    yield_dir = -side if lat > 0.08 else side
    if yield_best > 0.0:
        push += yield_dir * OLD_YIELD * yield_best
    return push

func _equivalence() -> void:
    var gs := GDScript.new()
    gs.source_code = "extends Node3D\nvar body_r := 0.28\nvar move_dir := Vector3.ZERO\n"
    gs.reload()
    var rng := RandomNumberGenerator.new()
    rng.seed = 91
    var holder := Node3D.new()
    root.add_child(holder)
    var bodies: Array = []
    for i in range(400):
        var b := Node3D.new()
        b.set_script(gs)
        holder.add_child(b)
        b.global_position = Vector3(rng.randf_range(-12, 12), rng.randf_range(0, 0.4) if i % 9 else 5.0, rng.randf_range(-12, 12))
        if i % 7 == 0:
            b.global_position = (bodies[i - 1] as Node3D).global_position if i > 0 else Vector3.ZERO
        b.set("body_r", rng.randf_range(0.12, 0.6))
        var a := rng.randf() * TAU
        b.set("move_dir", Vector3(cos(a), 0, sin(a)) if rng.randf() < 0.7 else Vector3.ZERO)
        bodies.append(b)
    var c := Crowd.new()
    c.fresh()
    _old.clear()
    for b in bodies:
        c.add(b)
        var op: Vector3 = (b as Node3D).global_position
        var key := Vector2i(floori(op.x * 0.5), floori(op.z * 0.5))
        if not _old.has(key):
            _old[key] = []
        (_old[key] as Array).append(b)
    var n := 0
    for rep in range(10):
        for b in bodies:
            var dir := Vector3.ZERO
            if rng.randf() < 0.8:
                var a := rng.randf() * TAU
                dir = Vector3(cos(a), 0, sin(a))
            var o := _old_push(b, dir)
            var m := c.push(b, dir)
            n += 1
            if o != m:
                _fail += 1
                if _fail < 5:
                    print("D91_EQ MISMATCH ", o, " vs ", m)
    print("D91_EQ samples=%d mismatches=%d" % [n, _fail])
    holder.queue_free()

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _audit_props() -> void:
    var reg := {}
    for ch in _t.get_children():
        if not (ch is Node3D):
            continue
        var sp := String(ch.scene_file_path)
        if not sp.begins_with("res://assets/nature/") and not sp.begins_with("res://assets/props/") and not sp.begins_with("res://assets/mkprops/"):
            continue
        var kind := sp.get_file().get_basename()
        for k in range(1, 6):
            kind = kind.trim_suffix("_" + str(k))
        if not reg.has(kind):
            reg[kind] = [0, 0]
        var p: Vector3 = (ch as Node3D).global_position
        var hit: Array = _t.call("solid_at", p, 0.0)
        reg[kind][0 if not hit.is_empty() else 1] += 1
    var keys := reg.keys()
    keys.sort()
    for k in keys:
        if String(k).begins_with("Bush") or String(k).begins_with("Rock") or String(k).begins_with("Tree") or String(k).begins_with("Pine") or reg[k][1] > 0:
            print("D91_PROP %s registered=%d unregistered=%d" % [k, reg[k][0], reg[k][1]])

func _sample() -> void:
    var c := Crowd.new()
    c.fresh()
    var bodies: Array = []
    for o in _t.get("people"):
        if is_instance_valid(o) and (o as Node3D).visible and not bool(o.get("inside")):
            c.add(o)
            bodies.append(o)
    for a in _t.get("animals"):
        if is_instance_valid(a) and (a as Node3D).visible and float(a.get("float_y")) == INF:
            c.add(a)
            bodies.append(a)
    var ov: Array = c.overlaps()
    _samples += 1
    _pairs += int(ov[0])
    _worst = maxf(_worst, float(ov[1]))
    for b in bodies:
        _body_checks += 1
        if not (_t.call("solid_at", (b as Node3D).global_position, -0.05) as Array).is_empty():
            _in_solid += 1
            var k := String(b.get("kind")) if b.get("kind") != null else String(b.get_class())
            if k == "":
                k = String((b as Node).name).left(10)
            _in_by[k] = int(_in_by.get(k, 0)) + 1

func _process(_d: float) -> bool:
    _f += 1
    if _f == 2:
        _equivalence()      # in _process: the root is not in the tree in _initialize
    if _f == 5:
        var by := {}
        for a in _t.get("animals"):
            var k := String(a.get("kind"))
            if not by.has(k):
                by[k] = float(a.get("body_r"))
        for k in by:
            print("D91_ANIMAL %s body_r=%.2f" % [k, by[k]])
    if _f == 700:
        _audit_props()          # after the 600-frame solid-grid window, whatever it holds
    if _f > 60 and _f % 30 == 0:
        _sample()
    if _f >= 60 + 90 * 60:
        print("D91_TOWN samples=%d overlapping_pairs=%d (%.2f/sample) worst=%.2fm body_in_footprint=%d/%d" % [_samples, _pairs, float(_pairs) / maxf(1.0, float(_samples)), _worst, _in_solid, _body_checks])
        print("D91_IN_BY ", _in_by)
        print("D91_CROWD_TEST %s" % ("OK" if _fail == 0 else "FAIL"))
        return true
    return false
