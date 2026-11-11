class_name Spells
extends RefCounted
## MAGIC, made visible. The first four spells the classes cast - BOLT (mage: a
## bolt of force), HEAL (healer/cleric: green motes rise round the target),
## WARD (cleric/chief: a shimmering shell), MEND (sage: golden threads close a
## wound) - and the battle spells of the arcane callings (D2): CHAIN (a bolt
## that leaps on to the next foe and the next), FIRE (an ember that bursts and
## scorches everything round its mark), FROST (a cold shard; the struck one
## goes slow), SMITE (a shaft of light drops on the scar's dead), RENEW (a
## mending that keeps on working, motes clinging to the one it was laid on).
## Then the wild-magic rule from canon: "Inside a scar, every spell misfires
## IN TURN." A misfire is not random: the cast comes out as the NEXT spell in
## the order, in the wrong colour, with a crackle of scar-violet. Every FX node
## frees itself.
##
## AIM (D2): a spell leaves the caster's HANDS (shoulder height, a little in
## front, toward the mark) and flies a FLAT arc at the foe's CHEST. A target
## may be a body (Node3D - its chest is measured from its own meshes, never
## its health bar) or a point. A point on the ground is lifted to a man's
## chest; a point above that is kept, but no spell is ever aimed higher than
## AIM_TOP over the caster's feet - the "4th of July" bolts (aimed at a
## health bar that climbed every frame) are gone.

const ORDER := ["bolt", "heal", "ward", "mend", "chain", "fire", "frost", "smite", "renew"]
const COL := {"bolt": Color(0.45, 0.65, 1.0), "heal": Color(0.35, 1.0, 0.45),
              "ward": Color(0.95, 0.85, 0.45), "mend": Color(1.0, 0.70, 0.30),
              "chain": Color(0.72, 0.80, 1.0), "fire": Color(1.0, 0.45, 0.12),
              "frost": Color(0.62, 0.92, 1.0), "smite": Color(1.0, 0.93, 0.62),
              "renew": Color(0.55, 1.0, 0.72)}
const SCAR := Color(0.62, 0.30, 1.0)
const CAST_ANIM := {"bolt": "Spellcast_Shoot", "heal": "Spellcast_Raise", "ward": "Spellcast_Long", "mend": "Spellcasting",
                    "chain": "Spellcast_Shoot", "fire": "Spellcast_Shoot", "frost": "Spellcast_Shoot",
                    "smite": "Spellcast_Raise", "renew": "Spellcast_Long"}
## spells that land on (or round) a body rather than fly at it
const ON_BODY := ["heal", "ward", "smite", "renew"]
## spells that hurt (the rest mend or shield)
const HARM := ["bolt", "chain", "fire", "frost", "smite"]
const SPEED := 16.0              # m/s, every thrown spell
const AIM_TOP := 2.4             # never aim higher than this over the caster's feet
const CHAIN_HOP := 0.12          # s between the chain's leaps
static var last := {}            # the last cast: kind, hand, aim, caster feet (tests)

## how tall a body stands (its own meshes; health bars and labels left out),
## measured once and kept on the body
static func body_height(n: Node3D) -> float:
    if n.has_meta("spell_h"):
        return float(n.get_meta("spell_h"))
    var top := -1.0
    var st: Array = [[n, Transform3D.IDENTITY]]
    while not st.is_empty():
        var e: Array = st.pop_back()
        var c: Node = e[0]
        var xf: Transform3D = e[1]
        if c is HealthBar3D or c is GPUParticles3D:
            continue
        if c is MeshInstance3D and (c as MeshInstance3D).visible and (c as MeshInstance3D).mesh:
            var ab: AABB = xf * (c as MeshInstance3D).get_aabb()
            top = maxf(top, ab.end.y)
        for g in c.get_children():
            if g is Node3D:
                st.append([g, xf * (g as Node3D).transform])
    if top > 0.3:
        top *= n.global_transform.basis.get_scale().y
        n.set_meta("spell_h", top)
        return top
    return 1.8

## where a spell strikes a body: its chest
static func chest(n: Node3D) -> float:
    return clampf(body_height(n) * 0.62, 0.5, AIM_TOP)

## the point a thrown spell flies at
static func aim_at(caster: Node3D, target) -> Vector3:
    var feet := caster.global_position.y
    if target is Node3D:
        var t := target as Node3D
        var p := t.global_position + Vector3(0, chest(t), 0)
        p.y = minf(p.y, maxf(feet, t.global_position.y) + AIM_TOP)
        return p
    var q: Vector3 = target
    if q.y < feet + 0.45:
        q.y += 1.1               # a point on the ground: a man's chest above it
    q.y = clampf(q.y, feet + 0.5, feet + AIM_TOP)
    return q

## the ground under a target
static func ground_of(target) -> Vector3:
    return (target as Node3D).global_position if target is Node3D else (target as Vector3)

## the caster's hands: shoulder height, a little in front, toward the aim
static func hand_of(caster: Node3D, aim: Vector3) -> Vector3:
    var feet := caster.global_position
    var to := Vector3(aim.x - feet.x, 0, aim.z - feet.z)
    var fw := to.normalized() if to.length() > 0.05 else caster.global_transform.basis.z.normalized()
    return feet + Vector3(0, clampf(body_height(caster) * 0.5, 0.9, 3.0), 0) + fw * 0.45

## seconds from the cast until the spell lands on `target` (thrown spells fly,
## smite drops after its light gathers, the rest are instant)
static func flight(kind: String, caster: Node3D, target) -> float:
    if kind == "smite":
        return 0.3
    if ON_BODY.has(kind):
        return 0.0
    var aim := aim_at(caster, target)
    return maxf(hand_of(caster, aim).distance_to(aim) / SPEED, 0.15)

## caster: the casting body (Node3D); target: a body or a world point (a body's
## feet for heal/ward/renew). more: the chain's further leaps (bodies or
## points). Returns what actually went off.
static func cast(kind: String, caster: Node3D, target, in_scar := false, more: Array = []) -> String:
    var actual := kind
    var col: Color = COL.get(kind, Color.WHITE)
    if in_scar:
        actual = ORDER[(ORDER.find(kind) + 1) % ORDER.size()]
        col = SCAR.lerp(COL.get(actual, Color.WHITE), 0.35)
    var root := caster.get_tree().current_scene if caster.get_tree().current_scene else caster.get_parent()
    var aim := aim_at(caster, target)
    var ground := ground_of(target)
    var hand := hand_of(caster, aim)
    last = {"kind": actual, "hand": hand, "aim": aim, "feet": caster.global_position}
    _flash(root, hand, col, 0.4)
    Sfx.at("spell", hand)
    match actual:
        "bolt": _bolt(root, hand, aim, col)
        "heal": _heal(root, ground, col)
        "ward": _ward(root, ground, col)
        "mend": _mend(root, hand, aim, col)
        "chain":
            var hops: Array = [aim]
            for m in more:
                hops.append(aim_at(caster, m))
            _chain(root, hand, hops, col)
        "fire": _fire(root, hand, aim, ground, col)
        "frost": _frost(root, hand, aim, ground, col)
        "smite": _smite(root, ground, col)
        "renew": _renew(root, target, col)
    if in_scar:
        _crackle(root, hand)
    return actual

static func _mat(col: Color, e: float, alpha := 1.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.albedo_color = Color(col.r, col.g, col.b, alpha)
    m.emission_enabled = true
    m.emission = col
    m.emission_energy_multiplier = e
    if alpha < 1.0:
        m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.vertex_color_use_as_albedo = true
    return m

static func _particles(col: Color, amount: int, life: float, radius: float, vel: Vector2, grav: Vector3, size: Vector2) -> GPUParticles3D:
    var gp := GPUParticles3D.new()
    gp.amount = amount
    gp.lifetime = life
    gp.one_shot = true
    gp.explosiveness = 0.6
    var pm := ParticleProcessMaterial.new()
    pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
    pm.emission_sphere_radius = radius
    pm.direction = Vector3(0, 1, 0)
    pm.spread = 180.0
    pm.initial_velocity_min = vel.x
    pm.initial_velocity_max = vel.y
    pm.gravity = grav
    pm.scale_min = size.x
    pm.scale_max = size.y
    pm.color = col
    var ramp := Gradient.new()
    ramp.set_color(0, Color(1, 1, 1, 1))
    ramp.set_color(1, Color(1, 1, 1, 0))
    var gt := GradientTexture1D.new()
    gt.gradient = ramp
    pm.color_ramp = gt
    gp.process_material = pm
    var s := SphereMesh.new()
    s.radius = 0.06
    s.height = 0.12
    s.radial_segments = 6
    s.rings = 3
    s.material = _mat(col, 3.0)
    gp.draw_pass_1 = s
    gp.emitting = true
    return gp

static func _free_after(n: Node, t: float) -> void:
    n.get_tree().create_timer(t).timeout.connect(n.queue_free)

static func _flash(root: Node, p: Vector3, col: Color, t: float, energy := 3.0, rng := 4.0) -> void:
    var l := OmniLight3D.new()
    l.light_color = col
    l.light_energy = energy
    l.omni_range = rng
    root.add_child(l)
    l.global_position = p
    var tw := l.create_tween()
    tw.tween_property(l, "light_energy", 0.0, t)
    _free_after(l, t + 0.05)

## a glowing orb (core + halo + trailing sparks + its own light), not yet moving
static func _orb(root: Node, from: Vector3, col: Color, r: float) -> Node3D:
    var orb := Node3D.new()
    root.add_child(orb)
    orb.global_position = from
    var core := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = r
    sm.height = r * 2.0
    core.mesh = sm
    core.material_override = _mat(col.lightened(0.5), 9.0)
    orb.add_child(core)
    var halo := MeshInstance3D.new()
    var hm := SphereMesh.new()
    hm.radius = r * 2.3
    hm.height = r * 4.6
    halo.mesh = hm
    halo.material_override = _mat(col, 3.0, 0.45)
    orb.add_child(halo)
    var trail := _particles(col, 120, 0.6, r * 0.5, Vector2(0.1, 0.6), Vector3.ZERO, Vector2(0.7, 1.4))
    trail.one_shot = false
    trail.explosiveness = 0.0
    trail.local_coords = false
    orb.add_child(trail)
    var l := OmniLight3D.new()
    l.light_color = col
    l.light_energy = 2.0
    l.omni_range = 3.5
    orb.add_child(l)
    return orb

## fly a node from -> to along a FLAT arc (it rises a hand's breadth over a
## short throw, never more than 0.45 m), then call on_hit and free it
static func _fly(n: Node3D, from: Vector3, to: Vector3, on_hit: Callable) -> void:
    var dist := from.distance_to(to)
    var mid := (from + to) * 0.5 + Vector3(0, minf(0.45, dist * 0.04), 0)
    var dur := maxf(dist / SPEED, 0.15)
    var tw := n.create_tween()
    tw.tween_method(func(k: float) -> void:
        if is_instance_valid(n):
            n.global_position = from.lerp(mid, k).lerp(mid.lerp(to, k), k), 0.0, 1.0, dur)
    tw.tween_callback(func() -> void:
        on_hit.call()
        n.queue_free())

## a glowing orb that streaks to the target, trailing sparks, and bursts
static func _bolt(root: Node, from: Vector3, to: Vector3, col: Color) -> void:
    var orb := _orb(root, from, col, 0.22)
    _fly(orb, from, to, func() -> void: _burst(root, to, col))

static func _burst(root: Node, p: Vector3, col: Color, k := 1.0) -> void:
    var b := _particles(col, int(70 * k), 0.7, 0.2, Vector2(2.0, 5.0) * k, Vector3(0, -3, 0), Vector2(0.6, 1.4))
    root.add_child(b)
    b.global_position = p
    _free_after(b, 1.2)
    var ring := MeshInstance3D.new()
    var tm := TorusMesh.new()
    tm.inner_radius = 0.3
    tm.outer_radius = 0.42
    ring.mesh = tm
    ring.material_override = _mat(col, 3.0, 0.8)
    root.add_child(ring)
    ring.global_position = p
    ring.rotation.x = PI * 0.5
    var tw := ring.create_tween()
    tw.set_parallel(true)
    tw.tween_property(ring, "scale", Vector3.ONE * 4.0 * k, 0.45)
    tw.tween_property(ring.material_override, "albedo_color:a", 0.0, 0.45)
    _free_after(ring, 0.5)
    _flash(root, p, col, 0.5)

## a flat ring that swells out over the ground and fades
static func _ground_ring(root: Node, p: Vector3, col: Color, radius: float, t: float, alpha := 0.6) -> void:
    var disc := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = 1.0
    cm.bottom_radius = 1.0
    cm.height = 0.02
    disc.mesh = cm
    disc.material_override = _mat(col, 2.0, alpha)
    disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    root.add_child(disc)
    disc.global_position = p + Vector3(0, 0.05, 0)
    disc.scale = Vector3(0.2, 1, 0.2)
    var tw := disc.create_tween()
    tw.set_parallel(true)
    tw.tween_property(disc, "scale", Vector3(radius, 1, radius), t * 0.45)
    tw.tween_property(disc.material_override, "albedo_color:a", 0.0, t)
    _free_after(disc, t + 0.1)

## green motes rising round the target, a ground ring that swells
static func _heal(root: Node, p: Vector3, col: Color) -> void:
    var up := _particles(col, 80, 1.6, 0.7, Vector2(0.6, 1.4), Vector3(0, 1.2, 0), Vector2(0.5, 1.1))
    root.add_child(up)
    up.global_position = p + Vector3(0, 0.3, 0)
    _free_after(up, 2.2)
    _ground_ring(root, p, col, 1.4, 1.4, 0.55)
    _flash(root, p + Vector3(0, 1, 0), col, 1.0)

## a shimmering shell that pops up, holds, and fades
static func _ward(root: Node, p: Vector3, col: Color) -> void:
    var sh := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = 1.3
    sm.height = 2.6
    sh.mesh = sm
    var m := StandardMaterial3D.new()
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.albedo_color = Color(col.r, col.g, col.b, 0.22)
    m.rim_enabled = true
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    m.emission_enabled = true
    m.emission = col
    m.emission_energy_multiplier = 0.8
    sh.material_override = m
    root.add_child(sh)
    sh.global_position = p + Vector3(0, 1.0, 0)
    sh.scale = Vector3.ONE * 0.1
    var tw := sh.create_tween()
    tw.tween_property(sh, "scale", Vector3.ONE * 1.05, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tw.tween_property(sh, "scale", Vector3.ONE, 0.2)
    tw.tween_interval(1.6)
    tw.tween_property(m, "albedo_color:a", 0.0, 0.6)
    _free_after(sh, 2.8)
    var glint := _particles(col, 40, 1.2, 1.25, Vector2(0.0, 0.2), Vector3.ZERO, Vector2(0.4, 0.8))
    root.add_child(glint)
    glint.global_position = p + Vector3(0, 1.0, 0)
    _free_after(glint, 1.8)

## golden threads arcing from hand to target, a soft glow where they land
static func _mend(root: Node, from: Vector3, to: Vector3, col: Color) -> void:
    for i in range(5):
        var mote := MeshInstance3D.new()
        var sm := SphereMesh.new()
        sm.radius = 0.08
        sm.height = 0.16
        mote.mesh = sm
        mote.material_override = _mat(col, 4.0)
        root.add_child(mote)
        mote.global_position = from
        # threads fan out sideways, rising no more than a forearm
        var mid := (from + to) * 0.5 + Vector3(randf_range(-1.0, 1.0), 0.2 + randf() * 0.4, randf_range(-1.0, 1.0))
        var tw := mote.create_tween()
        tw.tween_interval(float(i) * 0.08)
        tw.tween_method(func(k: float) -> void:
            var a := from.lerp(mid, k)
            var b := mid.lerp(to, k)
            mote.global_position = a.lerp(b, k), 0.0, 1.0, 0.7)
        tw.tween_callback(mote.queue_free)
    var glow := _particles(col, 40, 1.0, 0.4, Vector2(0.2, 0.8), Vector3(0, 0.6, 0), Vector2(0.5, 1.0))
    root.add_child(glow)
    glow.global_position = to
    _free_after(glow, 1.8)

## a jagged crackle of light between two points, gone in a blink
static func _arc_line(root: Node, a: Vector3, b: Vector3, col: Color) -> void:
    var segs := 6
    var prev := a
    var m := _mat(col.lightened(0.4), 8.0, 0.95)
    for i in range(1, segs + 1):
        var k := float(i) / float(segs)
        var nxt := a.lerp(b, k)
        if i < segs:
            nxt += Vector3(randf_range(-0.25, 0.25), randf_range(-0.2, 0.2), randf_range(-0.25, 0.25))
        var sl := prev.distance_to(nxt)
        if sl > 0.01:
            var seg := MeshInstance3D.new()
            var bm := BoxMesh.new()
            bm.size = Vector3(0.06, 0.06, sl)
            seg.mesh = bm
            seg.material_override = m
            seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            root.add_child(seg)
            seg.global_position = (prev + nxt) * 0.5
            if absf((nxt - prev).normalized().dot(Vector3.UP)) < 0.99:
                seg.look_at(nxt, Vector3.UP)
            _free_after(seg, 0.22)
        prev = nxt
    _flash(root, b, col, 0.25, 2.0, 3.0)

## a bolt to the first foe, then the light leaps on to the next, and the next
static func _chain(root: Node, from: Vector3, hops: Array, col: Color) -> void:
    var first: Vector3 = hops[0]
    var orb := _orb(root, from, col, 0.16)
    _fly(orb, from, first, func() -> void:
        _burst(root, first, col, 0.7)
        for i in range(1, hops.size()):
            var a: Vector3 = hops[i - 1]
            var b: Vector3 = hops[i]
            root.get_tree().create_timer(CHAIN_HOP * float(i)).timeout.connect(func() -> void:
                _arc_line(root, a, b, col)
                _burst(root, b, col, 0.55)))

## an ember that flies, bursts in flame and scorches the ground round its mark
static func _fire(root: Node, from: Vector3, to: Vector3, ground: Vector3, col: Color) -> void:
    var orb := _orb(root, from, col, 0.26)
    _fly(orb, from, to, func() -> void:
        _burst(root, to, col, 1.3)
        var flame := _particles(Color(1.0, 0.6, 0.15), 110, 0.9, 1.1, Vector2(1.0, 3.0), Vector3(0, 2.5, 0), Vector2(0.9, 1.8))
        root.add_child(flame)
        flame.global_position = ground + Vector3(0, 0.3, 0)
        _free_after(flame, 1.4)
        _ground_ring(root, ground, col, 2.6, 0.9, 0.7)
        _ground_ring(root, ground, Color(0.08, 0.05, 0.03), 2.0, 4.0, 0.55)    # the scorch
        _flash(root, ground + Vector3(0, 1.0, 0), col, 0.8, 5.0, 7.0))

## a cold shard: rime on the ground round the struck one, snow drifting down
static func _frost(root: Node, from: Vector3, to: Vector3, ground: Vector3, col: Color) -> void:
    var shard := Node3D.new()
    root.add_child(shard)
    shard.global_position = from
    var mi := MeshInstance3D.new()
    var pm := PrismMesh.new()
    pm.size = Vector3(0.16, 0.6, 0.16)
    mi.mesh = pm
    mi.material_override = _mat(col.lightened(0.4), 6.0)
    mi.rotation.x = -PI * 0.5        # the prism's point leads (-Z after look_at)
    shard.add_child(mi)
    var trail := _particles(Color(0.9, 0.97, 1.0), 60, 0.5, 0.06, Vector2(0.0, 0.3), Vector3(0, -0.5, 0), Vector2(0.5, 0.9))
    trail.one_shot = false
    trail.explosiveness = 0.0
    trail.local_coords = false
    shard.add_child(trail)
    if absf((to - from).normalized().dot(Vector3.UP)) < 0.99:
        shard.look_at_from_position(from, to, Vector3.UP)
    _fly(shard, from, to, func() -> void:
        _burst(root, to, col, 0.8)
        var snow := _particles(Color(0.92, 0.97, 1.0), 60, 1.6, 1.0, Vector2(0.1, 0.4), Vector3(0, -0.8, 0), Vector2(0.5, 1.0))
        root.add_child(snow)
        snow.global_position = ground + Vector3(0, 2.0, 0)
        _free_after(snow, 2.2)
        _ground_ring(root, ground, col, 1.6, 2.5, 0.7))

## a shaft of light drops on the mark from above and is gone
static func _smite(root: Node, p: Vector3, col: Color) -> void:
    var beam := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = 0.5
    cm.bottom_radius = 0.5
    cm.height = 7.0
    beam.mesh = cm
    var m := _mat(col, 4.0, 0.7)
    beam.material_override = m
    beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    root.add_child(beam)
    beam.global_position = p + Vector3(0, 3.5, 0)
    beam.scale = Vector3(0.15, 1, 0.15)
    var tw := beam.create_tween()
    tw.tween_property(beam, "scale", Vector3(1, 1, 1), 0.3).set_ease(Tween.EASE_OUT)
    tw.tween_callback(func() -> void:
        _burst(root, p + Vector3(0, 0.6, 0), col, 1.1)
        _ground_ring(root, p, col, 1.8, 0.8, 0.7))
    tw.tween_property(m, "albedo_color:a", 0.0, 0.45)
    _free_after(beam, 0.85)
    _flash(root, p + Vector3(0, 2.0, 0), col, 0.8, 5.0, 6.0)

## RENEW: a mending that keeps working - motes cling to the one it was laid on
## for a few seconds (they follow a body), a slow green ring at their feet
const RENEW_T := 5.0
static func _renew(root: Node, target, col: Color) -> void:
    var host: Node = target if target is Node3D else root
    var at := ground_of(target)
    var motes := _particles(col, 50, 1.4, 0.5, Vector2(0.2, 0.6), Vector3(0, 0.9, 0), Vector2(0.4, 0.8))
    motes.one_shot = false
    motes.explosiveness = 0.0
    host.add_child(motes)
    motes.global_position = at + Vector3(0, 0.4, 0)
    motes.get_tree().create_timer(RENEW_T).timeout.connect(func() -> void:
        if is_instance_valid(motes):
            motes.emitting = false)
    _free_after(motes, RENEW_T + 1.6)
    _heal(root, at, col)

## wild magic: violet sparks that jump the wrong way
static func _crackle(root: Node, p: Vector3) -> void:
    var c := _particles(SCAR, 50, 0.6, 0.3, Vector2(3.0, 7.0), Vector3(0, -6, 0), Vector2(0.4, 0.9))
    root.add_child(c)
    c.global_position = p
    _free_after(c, 1.0)
    _flash(root, p, SCAR, 0.6)
