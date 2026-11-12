class_name DungeonParts
extends RefCounted
## Dungeon pieces the kits do not have, built in code. Each returns a Node3D
## rooted at floor level, ready to drop into a room. Moving parts animate
## themselves (they carry a small script via set_script-free tweens/_process
## in a Driver node). Kit pieces live in addons/kaykit_dungeon_remastered and
## assets/dungeon; see DungeonParts.KIT for the catalogue names.

const KAY := "res://addons/kaykit_dungeon_remastered/Assets/gltf/"
const QD := "res://assets/dungeon/"

static func _m(col: Color, metal := 0.0, rough := 0.8) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = col
    m.metallic = metal
    m.roughness = rough
    return m

static func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var b := BoxMesh.new()
    b.size = size
    mi.mesh = b
    mi.material_override = mat
    mi.position = pos
    parent.add_child(mi)
    return mi

static func _cyl(parent: Node3D, r: float, h: float, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var c := CylinderMesh.new()
    c.top_radius = r
    c.bottom_radius = r
    c.height = h
    c.radial_segments = 8
    mi.mesh = c
    mi.material_override = mat
    mi.position = pos
    mi.rotation = rot
    parent.add_child(mi)
    return mi

static func kit(name: String) -> Node3D:
    for p in [KAY + name + ".gltf", KAY + name + ".gltf.glb", KAY + name + ".glb", QD + name + ".glb"]:
        if ResourceLoader.exists(p):
            return (load(p) as PackedScene).instantiate()
    return Node3D.new()

static func embers(col: Color, amount: int, radius: float, life := 2.5) -> GPUParticles3D:
    var gp := GPUParticles3D.new()
    gp.amount = amount
    gp.lifetime = life
    var pm := ParticleProcessMaterial.new()
    pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    pm.emission_box_extents = Vector3(radius, 0.05, radius)
    pm.direction = Vector3(0, 1, 0)
    pm.spread = 20.0
    pm.initial_velocity_min = 0.4
    pm.initial_velocity_max = 1.6
    pm.gravity = Vector3(0, 0.3, 0)
    pm.scale_min = 0.5
    pm.scale_max = 1.2
    pm.color = col
    var ramp := Gradient.new()
    ramp.set_color(0, Color(1, 1, 1, 1))
    ramp.set_color(1, Color(1, 1, 1, 0))
    var gt := GradientTexture1D.new()
    gt.gradient = ramp
    pm.color_ramp = gt
    gp.process_material = pm
    var s := SphereMesh.new()
    s.radius = 0.04
    s.height = 0.08
    s.radial_segments = 6
    s.rings = 3
    var sm := StandardMaterial3D.new()
    sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    sm.vertex_color_use_as_albedo = true
    sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    sm.emission_enabled = true
    sm.emission = col
    sm.emission_energy_multiplier = 3.0
    s.material = sm
    gp.draw_pass_1 = s
    gp.visibility_aabb = AABB(Vector3(-radius - 1, -1, -radius - 1), Vector3(radius * 2 + 2, 8, radius * 2 + 2))
    return gp

## LAVA POOL: a sunken channel of moving melt with a rock lip, embers, glow
static func lava_pool(w: float, d: float) -> Node3D:
    var n := Node3D.new()
    n.name = "LavaPool"
    var pl := MeshInstance3D.new()
    var pm := PlaneMesh.new()
    pm.size = Vector2(w, d)
    pm.subdivide_width = int(w * 2)
    pm.subdivide_depth = int(d * 2)
    pl.mesh = pm
    var sh := ShaderMaterial.new()
    sh.shader = load("res://assets/shaders/lava.gdshader")
    pl.material_override = sh
    pl.position = Vector3(0, 0.12, 0)
    n.add_child(pl)
    var rock := _m(Color(0.16, 0.13, 0.12), 0.0, 1.0)
    for s in [-1.0, 1.0]:
        _box(n, Vector3(w + 0.8, 0.45, 0.4), Vector3(0, 0.12, (d * 0.5 + 0.2) * s), rock)
        _box(n, Vector3(0.4, 0.45, d), Vector3((w * 0.5 + 0.2) * s, 0.12, 0), rock)
    var e := embers(Color(1.0, 0.55, 0.15), int(w * d * 3.0), maxf(w, d) * 0.45)
    e.position = Vector3(0, 0.15, 0)
    n.add_child(e)
    var l := OmniLight3D.new()
    l.light_color = Color(1.0, 0.45, 0.12)
    l.light_energy = 3.0
    l.omni_range = maxf(w, d) * 1.4
    l.position = Vector3(0, 1.2, 0)
    n.add_child(l)
    return n

## SPIKE TRAP: a plate whose spikes punch up, hold, and sink again
static func spike_trap() -> Node3D:
    var n := Node3D.new()
    n.name = "SpikeTrap"
    var iron := _m(Color(0.30, 0.30, 0.32), 0.8, 0.4)
    _box(n, Vector3(2.0, 0.08, 2.0), Vector3(0, 0.04, 0), _m(Color(0.22, 0.2, 0.2), 0.3, 0.7))
    var spikes := Node3D.new()
    spikes.name = "spikes"
    n.add_child(spikes)
    for i in range(4):
        for j in range(4):
            var sp := MeshInstance3D.new()
            var cm := CylinderMesh.new()
            cm.top_radius = 0.0
            cm.bottom_radius = 0.08
            cm.height = 0.7
            cm.radial_segments = 6
            sp.mesh = cm
            sp.material_override = iron
            sp.position = Vector3(-0.72 + float(i) * 0.48, 0.35, -0.72 + float(j) * 0.48)
            spikes.add_child(sp)
    spikes.position.y = -0.72
    # L11: armed until something steps on it
    n.set_meta("fire", func() -> void:
        var t := spikes.create_tween()
        t.tween_property(spikes, "position:y", 0.0, 0.08)
        t.tween_interval(1.1)
        t.tween_property(spikes, "position:y", -0.72, 0.6))
    return n

## PRESSURE PLATE: a stone that sinks when stepped on (here: on a loop)
static func pressure_plate() -> Node3D:
    var n := Node3D.new()
    n.name = "PressurePlate"
    _box(n, Vector3(1.2, 0.06, 1.2), Vector3(0, 0.02, 0), _m(Color(0.15, 0.14, 0.14)))
    var plate := _box(n, Vector3(1.0, 0.12, 1.0), Vector3(0, 0.08, 0), _m(Color(0.42, 0.40, 0.38), 0.0, 0.9))
    var rune := _box(n, Vector3(0.4, 0.01, 0.4), Vector3(0, 0.145, 0), _m(Color(0.9, 0.3, 0.2)))
    (rune.material_override as StandardMaterial3D).emission_enabled = true
    (rune.material_override as StandardMaterial3D).emission = Color(1.0, 0.3, 0.15)
    n.set_meta("fire", func() -> void:
        var t := plate.create_tween()
        t.tween_property(plate, "position:y", 0.02, 0.08)
        t.tween_interval(1.6)
        t.tween_property(plate, "position:y", 0.08, 0.4))
    return n

## FIRE JET: a floor grate that roars flame upward in bursts
static func fire_trap() -> Node3D:
    var n := Node3D.new()
    n.name = "FireTrap"
    _box(n, Vector3(1.4, 0.08, 1.4), Vector3(0, 0.04, 0), _m(Color(0.12, 0.11, 0.11), 0.6, 0.5))
    var grate := _m(Color(0.05, 0.04, 0.04), 0.7, 0.5)
    for i in range(5):
        _box(n, Vector3(1.2, 0.04, 0.06), Vector3(0, 0.09, -0.5 + float(i) * 0.25), grate)
    var f := GPUParticles3D.new()
    f.amount = 220
    f.lifetime = 0.9
    var pm := ParticleProcessMaterial.new()
    pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    pm.emission_box_extents = Vector3(0.45, 0.05, 0.45)
    pm.direction = Vector3(0, 1, 0)
    pm.spread = 8.0
    pm.initial_velocity_min = 4.0
    pm.initial_velocity_max = 6.5
    pm.gravity = Vector3(0, 0.5, 0)
    pm.scale_min = 0.6
    pm.scale_max = 1.4
    var g := Gradient.new()
    g.set_color(0, Color(1.0, 0.85, 0.35, 1))
    g.add_point(0.35, Color(1.0, 0.40, 0.06, 0.95))
    g.set_color(g.get_point_count() - 1, Color(0.35, 0.06, 0.02, 0))
    var gt := GradientTexture1D.new()
    gt.gradient = g
    pm.color_ramp = gt
    f.process_material = pm
    var s := SphereMesh.new()
    s.radius = 0.08
    s.height = 0.16
    var sm := StandardMaterial3D.new()
    sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    sm.vertex_color_use_as_albedo = true
    sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    sm.albedo_color = Color(1.0, 0.5, 0.12)
    sm.emission_enabled = true
    sm.emission = Color(1.0, 0.38, 0.06)
    sm.emission_energy_multiplier = 4.0
    s.material = sm
    f.draw_pass_1 = s
    f.position = Vector3(0, 0.1, 0)
    f.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 8, 4))
    n.add_child(f)
    var l := OmniLight3D.new()
    l.light_color = Color(1.0, 0.5, 0.15)
    l.omni_range = 7.0
    l.position = Vector3(0, 1.5, 0)
    n.add_child(l)
    f.emitting = false
    l.light_energy = 0.3
    n.set_meta("fire", func() -> void:
        f.emitting = true
        l.light_energy = 4.0
        var t := f.create_tween()
        t.tween_interval(1.4)
        t.tween_callback(func() -> void:
            f.emitting = false
            l.light_energy = 0.3))
    return n

## PORTCULLIS: an iron grid in a stone frame that winds up and drops
static func portcullis(w := 4.0, h := 4.0) -> Node3D:
    var n := Node3D.new()
    n.name = "Portcullis"
    var stone := _m(Color(0.38, 0.36, 0.34), 0.0, 0.95)
    var iron := _m(Color(0.20, 0.20, 0.22), 0.85, 0.45)
    for s in [-1.0, 1.0]:
        _box(n, Vector3(0.8, h + 0.8, 0.9), Vector3((w * 0.5 + 0.4) * s, (h + 0.8) * 0.5, 0), stone)
    _box(n, Vector3(w + 1.6, 0.8, 0.9), Vector3(0, h + 0.4, 0), stone)
    var grid := Node3D.new()
    grid.name = "grid"
    n.add_child(grid)
    var nx := int(w / 0.45)
    for i in range(nx + 1):
        var b := _box(grid, Vector3(0.09, h, 0.09), Vector3(-w * 0.5 + float(i) * w / float(nx), h * 0.5, 0), iron)
        var tip := MeshInstance3D.new()
        var cm := CylinderMesh.new()
        cm.top_radius = 0.0
        cm.bottom_radius = 0.07
        cm.height = 0.25
        tip.mesh = cm
        tip.material_override = iron
        tip.rotation.x = PI
        tip.position = Vector3(b.position.x, -0.1, 0)
        grid.add_child(tip)
    for j in range(5):
        _box(grid, Vector3(w, 0.08, 0.12), Vector3(0, 0.4 + float(j) * (h - 0.6) / 4.0, 0), iron)
    n.ready.connect(func() -> void:
        var t := grid.create_tween().set_loops()
        t.tween_interval(2.0)
        t.tween_property(grid, "position:y", h - 0.4, 2.4).set_trans(Tween.TRANS_SINE)
        t.tween_interval(1.5)
        t.tween_property(grid, "position:y", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN))
    return n

## PRISON CELL: three barred sides and a barred door, a pallet, a bucket, chains
static func cell(w := 3.0, d := 3.0, h := 2.8, open := false) -> Node3D:
    var n := Node3D.new()
    n.name = "Cell"
    var iron := _m(Color(0.18, 0.18, 0.19), 0.85, 0.45)
    var sides := [[Vector3(-w * 0.5, 0, 0), Vector3(0, 0, 1), d], [Vector3(w * 0.5, 0, 0), Vector3(0, 0, 1), d], [Vector3(0, 0, -d * 0.5), Vector3(1, 0, 0), w]]
    for sdef in sides:
        var c: Vector3 = sdef[0]
        var ax: Vector3 = sdef[1]
        var L: float = sdef[2]
        var k := int(L / 0.32)
        for i in range(k + 1):
            var p: Vector3 = c + ax * (-L * 0.5 + float(i) * L / float(k))
            _cyl(n, 0.035, h, p + Vector3(0, h * 0.5, 0), iron)
        for yy in [0.15, h - 0.1]:
            var rail := _box(n, Vector3(L if ax.x > 0.5 else 0.08, 0.08, L if ax.z > 0.5 else 0.08), c + Vector3(0, yy, 0), iron)
    # the front: bars either side of a hinged door
    var door := Node3D.new()
    door.name = "door"
    door.position = Vector3(-0.5, 0, d * 0.5)
    n.add_child(door)
    for i in range(4):
        _cyl(door, 0.035, h - 0.2, Vector3(0.12 + float(i) * 0.26, (h - 0.2) * 0.5, 0), iron)
    for yy in [0.2, h * 0.5, h - 0.3]:
        _box(door, Vector3(1.0, 0.07, 0.07), Vector3(0.5, yy, 0), iron)
    _box(door, Vector3(0.14, 0.2, 0.12), Vector3(0.9, h * 0.5, 0.06), _m(Color(0.5, 0.4, 0.2), 0.8, 0.4))
    for side in [-1.0, 1.0]:
        var x0 := -w * 0.5 if side < 0.0 else 0.5
        var x1 := -0.5 if side < 0.0 else w * 0.5
        var k2 := int((x1 - x0) / 0.32)
        for i in range(k2 + 1):
            _cyl(n, 0.035, h, Vector3(x0 + float(i) * (x1 - x0) / float(maxi(k2, 1)), h * 0.5, d * 0.5), iron)
    _box(n, Vector3(w, 0.08, 0.08), Vector3(0, h - 0.1, d * 0.5), iron)
    if open:
        door.rotation.y = -1.9
    # inside: straw pallet, bucket, a chain on the back wall
    _box(n, Vector3(1.0, 0.12, 1.9), Vector3(w * 0.5 - 0.7, 0.06, -0.2), _m(Color(0.70, 0.58, 0.32)))
    var bk := kit("bucket_water") if false else (load("res://assets/props/Bucket_Wooden_1.gltf") as PackedScene).instantiate()
    bk.position = Vector3(-w * 0.5 + 0.5, 0, -d * 0.5 + 0.5)
    n.add_child(bk)
    for i in range(7):
        _cyl(n, 0.05, 0.14, Vector3(-0.4, h - 0.6 - float(i) * 0.12, -d * 0.5 + 0.08), iron, Vector3(0, 0, PI * 0.5 * float(i % 2)))
    return n

## DEBRIS: rubble, a broken column drum, scattered bricks and bones
static func debris(seed_i := 1, r := 1.6) -> Node3D:
    var n := Node3D.new()
    n.name = "Debris"
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_i
    var stone := _m(Color(0.42, 0.40, 0.38), 0.0, 0.95)
    var rb := kit("rubble_large")
    rb.scale = Vector3.ONE * 0.35
    n.add_child(rb)
    var rh := kit("rubble_half")
    rh.scale = Vector3.ONE * 0.35
    rh.position = Vector3(r * 0.7, 0, r * 0.3)
    rh.rotation.y = 1.2
    n.add_child(rh)
    for i in range(10):
        var b := _box(n, Vector3(rng.randf_range(0.2, 0.45), rng.randf_range(0.12, 0.25), rng.randf_range(0.15, 0.3)),
                      Vector3(rng.randf_range(-r, r), 0.1, rng.randf_range(-r, r)), stone)
        b.rotation = Vector3(rng.randf_range(-0.4, 0.4), rng.randf() * TAU, rng.randf_range(-0.4, 0.4))
    var drum := _cyl(n, 0.4, 0.6, Vector3(-r * 0.6, 0.4, -r * 0.4), stone, Vector3(PI * 0.5, 0.3, 0))
    var sk := kit("Skull")
    sk.position = Vector3(r * 0.2, 0.05, -r * 0.6)
    sk.scale = Vector3.ONE * 0.6
    n.add_child(sk)
    return n

## SCAR-GLASS: crystals breaking up through a scar floor, out-of-step glow
static func scar_glass(seed_i := 1, count := 7) -> Node3D:
    var n := Node3D.new()
    n.name = "ScarGlass"
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_i
    var cols := [Color(0.62, 0.32, 1.0), Color(0.30, 0.85, 1.0), Color(1.0, 0.35, 0.75)]
    for i in range(count):
        var c: Color = cols[rng.randi() % cols.size()]
        var cr := MeshInstance3D.new()
        var pm := PrismMesh.new()
        var hgt := rng.randf_range(0.6, 2.2)
        pm.size = Vector3(rng.randf_range(0.25, 0.5), hgt, rng.randf_range(0.25, 0.5))
        cr.mesh = pm
        var m := StandardMaterial3D.new()
        m.albedo_color = c.darkened(0.3)
        m.emission_enabled = true
        m.emission = c
        m.emission_energy_multiplier = rng.randf_range(1.0, 2.6)
        m.roughness = 0.15
        cr.material_override = m
        cr.position = Vector3(rng.randf_range(-0.9, 0.9), hgt * 0.45, rng.randf_range(-0.9, 0.9))
        cr.rotation = Vector3(rng.randf_range(-0.5, 0.5), rng.randf() * TAU, rng.randf_range(-0.5, 0.5))
        n.add_child(cr)
    var l := OmniLight3D.new()
    l.light_color = cols[0]
    l.light_energy = 1.5
    l.omni_range = 5.0
    l.position = Vector3(0, 1.0, 0)
    n.add_child(l)
    n.ready.connect(func() -> void:
        var t := l.create_tween().set_loops()
        t.tween_property(l, "light_energy", 0.4, rng.randf_range(0.5, 1.2))
        t.tween_property(l, "light_energy", 2.0, rng.randf_range(0.3, 0.9)))
    return n

## L28c: a standing iron brazier - three legs, a bowl of glowing coals, a flame and a
## flickering light (unshadowed). Its embers come from the floor's shared flame emitter
## (FloorGen.flame_embers): the flame point is BRAZIER_FLAME above the node.
const BRAZIER_FLAME := Vector3(0, 1.25, 0)
static func brazier(col: Color, seed_i := 1) -> Node3D:
    var n := Node3D.new()
    n.name = "Brazier"
    var iron := _m(Color(0.09, 0.085, 0.08), 0.85, 0.45)
    for k in 3:
        var a := float(k) * TAU / 3.0
        _cyl(n, 0.045, 1.0, Vector3(cos(a) * 0.22, 0.48, sin(a) * 0.22), iron,
             Vector3(sin(a) * 0.22, 0, -cos(a) * 0.22))
    var bowl := MeshInstance3D.new()
    var bm := CylinderMesh.new()
    bm.top_radius = 0.5
    bm.bottom_radius = 0.22
    bm.height = 0.3
    bm.radial_segments = 12
    bowl.mesh = bm
    bowl.material_override = iron
    bowl.position = Vector3(0, 1.0, 0)
    n.add_child(bowl)
    var coal := _m(col.lerp(Color(1.0, 0.35, 0.08), 0.6), 0.0, 0.9)
    coal.emission_enabled = true
    coal.emission = col.lerp(Color(1.0, 0.35, 0.08), 0.6)
    coal.emission_energy_multiplier = 3.0
    _cyl(n, 0.44, 0.06, Vector3(0, 1.13, 0), coal)
    var flame := MeshInstance3D.new()
    var fm := SphereMesh.new()
    fm.radius = 0.26
    fm.height = 0.7
    fm.radial_segments = 10
    fm.rings = 6
    flame.mesh = fm
    var fmat := StandardMaterial3D.new()
    fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    fmat.albedo_color = col
    fmat.emission_enabled = true
    fmat.emission = col
    fmat.emission_energy_multiplier = 8.0
    fm.material = fmat
    flame.position = Vector3(0, 1.38, 0)
    n.add_child(flame)
    var l := OmniLight3D.new()
    l.light_color = col
    l.light_energy = 5.0
    l.omni_range = 11.0
    l.shadow_enabled = false
    l.position = Vector3(0, 1.7, 0)
    n.add_child(l)
    var r := RandomNumberGenerator.new()
    r.seed = seed_i
    n.ready.connect(func() -> void:
        var t := l.create_tween().set_loops()
        t.tween_property(l, "light_energy", 3.8, r.randf_range(0.08, 0.16))
        t.tween_property(l, "light_energy", 5.4, r.randf_range(0.10, 0.22))
        t.tween_property(l, "light_energy", 4.4, r.randf_range(0.07, 0.14))
        t.tween_property(l, "light_energy", 5.0, r.randf_range(0.12, 0.2))
        var ft := flame.create_tween().set_loops()
        ft.tween_property(flame, "scale", Vector3(1.0, 1.15, 1.0), r.randf_range(0.12, 0.2))
        ft.tween_property(flame, "scale", Vector3(0.92, 0.9, 0.92), r.randf_range(0.12, 0.2)), CONNECT_ONE_SHOT)
    return n

## a lit wall torch with a flickering light
static func torch_lit() -> Node3D:
    var n := kit("torch_mounted")
    var l := OmniLight3D.new()
    l.light_color = Color(1.0, 0.62, 0.3)
    l.light_energy = 1.8
    l.omni_range = 7.0
    l.position = Vector3(0, 1.1, 0.35)
    n.add_child(l)
    var e := embers(Color(1.0, 0.6, 0.2), 20, 0.05, 0.8)
    e.position = Vector3(0, 1.0, 0.3)
    n.add_child(e)
    n.ready.connect(func() -> void:
        var t := l.create_tween().set_loops()
        t.tween_property(l, "light_energy", 1.3, 0.13)
        t.tween_property(l, "light_energy", 2.0, 0.17))
    return n

## ---- L11: more traps, all armed until something steps on them. Each carries
## meta "fire" (a Callable that plays the trap going off); Delve calls it.

## DART TRAP: a worn flagstone with two dart posts either side; darts fly across
static func dart_trap() -> Node3D:
    var n := Node3D.new()
    n.name = "DartTrap"
    _box(n, Vector3(1.4, 0.06, 1.4), Vector3(0, 0.03, 0), _m(Color(0.30, 0.28, 0.26), 0.0, 0.95))
    var post := _m(Color(0.25, 0.22, 0.20), 0.2, 0.8)
    for s in [-1.0, 1.0]:
        _box(n, Vector3(0.22, 1.1, 0.22), Vector3(1.0 * s, 0.55, 0), post)
        _box(n, Vector3(0.06, 0.06, 0.06), Vector3(0.88 * s, 0.9, 0), _m(Color(0.05, 0.05, 0.05)))
    n.set_meta("fire", func() -> void:
        var dm := _m(Color(0.75, 0.72, 0.65), 0.6, 0.4)
        for k in range(3):
            var dart := _box(n, Vector3(0.36, 0.035, 0.035), Vector3(-0.9, 0.9 - 0.12 * float(k), -0.15 + 0.15 * float(k)), dm)
            var t := dart.create_tween()
            t.tween_interval(0.05 * float(k))
            t.tween_property(dart, "position:x", 0.9, 0.16)
            t.tween_interval(0.4)
            t.tween_callback(dart.queue_free))
    return n

## BLADE TRAP: a slot in the floor; a scything blade sweeps up out of it and back
static func blade_trap() -> Node3D:
    var n := Node3D.new()
    n.name = "BladeTrap"
    _box(n, Vector3(1.8, 0.06, 1.8), Vector3(0, 0.03, 0), _m(Color(0.22, 0.20, 0.20), 0.3, 0.7))
    _box(n, Vector3(1.6, 0.07, 0.14), Vector3(0, 0.05, 0), _m(Color(0.02, 0.02, 0.02)))
    var pivot := Node3D.new()
    pivot.name = "blade"
    pivot.position = Vector3(0, -0.9, 0)
    n.add_child(pivot)
    var steel := _m(Color(0.70, 0.72, 0.76), 0.9, 0.25)
    var arm := _box(pivot, Vector3(0.08, 1.4, 0.06), Vector3(0, 0.7, 0), _m(Color(0.20, 0.18, 0.16), 0.6, 0.6))
    var edge := _box(pivot, Vector3(0.9, 0.22, 0.03), Vector3(0, 1.45, 0), steel)
    pivot.rotation.x = -PI * 0.5
    n.set_meta("fire", func() -> void:
        var t := pivot.create_tween()
        t.tween_property(pivot, "rotation:x", PI * 0.5, 0.28).set_trans(Tween.TRANS_SINE)
        t.tween_property(pivot, "rotation:x", -PI * 0.5, 0.5).set_delay(0.2))
    return n

## PIT TRAP: two boards over a dark shaft; they drop open and close again
static func pit_trap() -> Node3D:
    var n := Node3D.new()
    n.name = "PitTrap"
    _box(n, Vector3(1.8, 0.04, 1.8), Vector3(0, -0.9, 0), _m(Color(0.01, 0.01, 0.01)))
    for s in [-1.0, 1.0]:
        _box(n, Vector3(0.12, 0.9, 1.8), Vector3(0.9 * s, -0.45, 0), _m(Color(0.08, 0.07, 0.07)))
        _box(n, Vector3(1.8, 0.9, 0.12), Vector3(0, -0.45, 0.9 * s), _m(Color(0.08, 0.07, 0.07)))
    var wood := _m(Color(0.40, 0.30, 0.20), 0.0, 0.9)
    var doors: Array = []
    for s in [-1.0, 1.0]:
        var hinge := Node3D.new()
        hinge.position = Vector3(0.9 * s, 0.04, 0)
        n.add_child(hinge)
        _box(hinge, Vector3(0.9, 0.06, 1.8), Vector3(-0.45 * s, 0, 0), wood)
        doors.append([hinge, s])
    n.set_meta("fire", func() -> void:
        for d in doors:
            var hinge: Node3D = d[0]
            var t := hinge.create_tween()
            t.tween_property(hinge, "rotation:z", -1.45 * float(d[1]), 0.15)
            t.tween_interval(1.4)
            t.tween_property(hinge, "rotation:z", 0.0, 0.6))
    return n
