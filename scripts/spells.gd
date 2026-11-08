class_name Spells
extends RefCounted
## MAGIC, made visible. Four spells the classes cast - BOLT (mage: a bolt of
## force), HEAL (healer/cleric: green motes rise round the target), WARD (cleric/
## chief: a shimmering shell), MEND (sage: golden threads close a wound) - and
## the wild-magic rule from canon: "Inside a scar, every spell misfires IN
## TURN." A misfire is not random: the cast comes out as the NEXT spell in the
## order, in the wrong colour, with a crackle of scar-violet. Every FX node frees
## itself.

const ORDER := ["bolt", "heal", "ward", "mend"]
const COL := {"bolt": Color(0.45, 0.65, 1.0), "heal": Color(0.35, 1.0, 0.45),
              "ward": Color(0.95, 0.85, 0.45), "mend": Color(1.0, 0.70, 0.30)}
const SCAR := Color(0.62, 0.30, 1.0)
const CAST_ANIM := {"bolt": "Spellcast_Shoot", "heal": "Spellcast_Raise", "ward": "Spellcast_Long", "mend": "Spellcasting"}

## caster: the casting body (Node3D); target: world point (another body's
## position for heal/ward/mend). Returns what actually went off.
static func cast(kind: String, caster: Node3D, target: Vector3, in_scar := false) -> String:
    var actual := kind
    var col: Color = COL.get(kind, Color.WHITE)
    if in_scar:
        actual = ORDER[(ORDER.find(kind) + 1) % ORDER.size()]
        col = SCAR.lerp(COL.get(actual, Color.WHITE), 0.35)
    var root := caster.get_tree().current_scene if caster.get_tree().current_scene else caster.get_parent()
    var hand := caster.global_position + Vector3(0, 1.35, 0) + caster.global_transform.basis.z * 0.6
    _flash(root, hand, col, 0.4)
    match actual:
        "bolt": _bolt(root, hand, target + Vector3(0, 1.0, 0), col)
        "heal": _heal(root, target, col)
        "ward": _ward(root, target, col)
        "mend": _mend(root, hand, target + Vector3(0, 1.0, 0), col)
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

static func _flash(root: Node, p: Vector3, col: Color, t: float) -> void:
    var l := OmniLight3D.new()
    l.light_color = col
    l.light_energy = 3.0
    l.omni_range = 4.0
    root.add_child(l)
    l.global_position = p
    var tw := l.create_tween()
    tw.tween_property(l, "light_energy", 0.0, t)
    _free_after(l, t + 0.05)

## a glowing orb that streaks to the target, trailing sparks, and bursts
static func _bolt(root: Node, from: Vector3, to: Vector3, col: Color) -> void:
    var orb := Node3D.new()
    root.add_child(orb)
    orb.global_position = from
    var core := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = 0.24
    sm.height = 0.48
    core.mesh = sm
    core.material_override = _mat(col.lightened(0.5), 9.0)
    orb.add_child(core)
    var halo := MeshInstance3D.new()
    var hm := SphereMesh.new()
    hm.radius = 0.55
    hm.height = 1.1
    halo.mesh = hm
    halo.material_override = _mat(col, 3.0, 0.45)
    orb.add_child(halo)
    var trail := _particles(col, 120, 0.6, 0.12, Vector2(0.1, 0.6), Vector3.ZERO, Vector2(0.7, 1.4))
    trail.one_shot = false
    trail.explosiveness = 0.0
    trail.local_coords = false
    orb.add_child(trail)
    var l := OmniLight3D.new()
    l.light_color = col
    l.light_energy = 2.0
    l.omni_range = 3.5
    orb.add_child(l)
    var dur := maxf(from.distance_to(to) / 18.0, 0.15)
    var tw := orb.create_tween()
    tw.tween_property(orb, "global_position", to, dur)
    tw.tween_callback(func() -> void:
        _burst(root, to, col)
        orb.queue_free())

static func _burst(root: Node, p: Vector3, col: Color) -> void:
    var b := _particles(col, 70, 0.7, 0.2, Vector2(2.0, 5.0), Vector3(0, -3, 0), Vector2(0.6, 1.4))
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
    tw.tween_property(ring, "scale", Vector3.ONE * 4.0, 0.45)
    tw.tween_property(ring.material_override, "albedo_color:a", 0.0, 0.45)
    _free_after(ring, 0.5)
    _flash(root, p, col, 0.5)

## green motes rising round the target, a ground ring that swells
static func _heal(root: Node, p: Vector3, col: Color) -> void:
    var up := _particles(col, 80, 1.6, 0.7, Vector2(0.6, 1.4), Vector3(0, 1.2, 0), Vector2(0.5, 1.1))
    root.add_child(up)
    up.global_position = p + Vector3(0, 0.3, 0)
    _free_after(up, 2.2)
    var disc := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = 1.0
    cm.bottom_radius = 1.0
    cm.height = 0.02
    disc.mesh = cm
    disc.material_override = _mat(col, 2.0, 0.55)
    root.add_child(disc)
    disc.global_position = p + Vector3(0, 0.05, 0)
    disc.scale = Vector3(0.2, 1, 0.2)
    var tw := disc.create_tween()
    tw.set_parallel(true)
    tw.tween_property(disc, "scale", Vector3(1.4, 1, 1.4), 0.6)
    tw.tween_property(disc.material_override, "albedo_color:a", 0.0, 1.4)
    _free_after(disc, 1.5)
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
        var mid := (from + to) * 0.5 + Vector3(randf_range(-1.0, 1.0), 1.0 + randf() * 0.8, randf_range(-1.0, 1.0))
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

## wild magic: violet sparks that jump the wrong way
static func _crackle(root: Node, p: Vector3) -> void:
    var c := _particles(SCAR, 50, 0.6, 0.3, Vector2(3.0, 7.0), Vector3(0, -6, 0), Vector2(0.4, 0.9))
    root.add_child(c)
    c.global_position = p
    _free_after(c, 1.0)
    _flash(root, p, SCAR, 0.6)
