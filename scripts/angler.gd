class_name Angler
extends Node3D
## Fishing, made visible. Child of a Townsfolk standing at the end of a dock.
## IDLE -> CAST (bobber arcs out) -> WAIT (bobs; Fishing.bite_wait) -> BITE
## (bobber yanked under, splash ring; open for Fishing.bite_window) -> REEL
## (the catch flies out of the river to the fisher) -> SHOW (held up, name in
## its rarity colour) -> IDLE. Rules live in Fishing; this only draws them.

signal caught(item: Dictionary, who: String)

enum S { IDLE, CAST, WAIT, BITE, REEL, SHOW, MISS }
var state: int = S.IDLE
var target := Vector3.ZERO          # where the bobber lands (world)
var water_y := -0.9
var luck := 0
var lure := 0
var skill := 0.85                   # chance an NPC reacts inside the bite window
var who := ""
var demo := false                   # first bite comes fast (render probe)
var creel: Array = []               # everything landed, newest last
var forced: Dictionary = {}         # next catch, when chat already rolled it

var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _dur := 0.0
var _rod_tip: Node3D
var _bobber: Node3D
var _line: MeshInstance3D
var _imm: ImmediateMesh
var _ring: MeshInstance3D
var _catch: Node3D
var _label: Label3D
var _item: Dictionary = {}
var _from := Vector3.ZERO
var _anim: AnimationPlayer

func _ready() -> void:
    _rng.randomize()
    _build_rod()
    _build_bobber()
    _line = MeshInstance3D.new()
    _imm = ImmediateMesh.new()
    _line.mesh = _imm
    var lm := StandardMaterial3D.new()
    lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    lm.albedo_color = Color(0.92, 0.92, 0.88)
    _line.material_override = lm
    _line.top_level = true
    add_child(_line)
    _ring = MeshInstance3D.new()
    var tm := TorusMesh.new()
    tm.inner_radius = 0.30
    tm.outer_radius = 0.38
    _ring.mesh = tm
    var rm := StandardMaterial3D.new()
    rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    rm.albedo_color = Color(0.85, 0.93, 1.0, 0.0)
    rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    _ring.material_override = rm
    _ring.top_level = true
    add_child(_ring)
    _label = Label3D.new()
    _label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    _label.font_size = 56
    _label.pixel_size = 0.009
    _label.outline_size = 18
    _label.outline_modulate = Color(0, 0, 0, 0.9)
    _label.position = Vector3(0, 4.3, 0)       # clear of the fisher's own name tag
    _label.visible = false
    add_child(_label)
    _go(S.IDLE, 0.5 if demo else _rng.randf_range(1.0, 4.0))
    call_deferred("_find_anim")

func _find_anim() -> void:
    var p := get_parent()
    if p and "_anim" in p:
        _anim = p.get("_anim")

func _build_rod() -> void:
    var wood := StandardMaterial3D.new()
    wood.albedo_color = Color(0.45, 0.32, 0.20)
    var pivot := Node3D.new()
    pivot.position = Vector3(0.28, 1.05, 0.30)
    # rotating +Y about X by +a swings the tip toward +Z = out over the water
    pivot.rotation.x = deg_to_rad(52.0)
    add_child(pivot)
    var rod := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = 0.012
    cm.bottom_radius = 0.035
    cm.height = 2.8
    rod.mesh = cm
    rod.material_override = wood
    rod.position = Vector3(0, 1.4, 0)
    pivot.add_child(rod)
    _rod_tip = Node3D.new()
    _rod_tip.position = Vector3(0, 2.8, 0)
    pivot.add_child(_rod_tip)
    var reel := MeshInstance3D.new()
    var rlm := CylinderMesh.new()
    rlm.top_radius = 0.07
    rlm.bottom_radius = 0.07
    rlm.height = 0.05
    reel.mesh = rlm
    var iron := StandardMaterial3D.new()
    iron.albedo_color = Color(0.3, 0.3, 0.32)
    iron.metallic = 0.7
    reel.material_override = iron
    reel.rotation.z = PI * 0.5
    reel.position = Vector3(0.06, 0.35, 0)
    pivot.add_child(reel)

func _build_bobber() -> void:
    _bobber = Node3D.new()
    _bobber.top_level = true
    add_child(_bobber)
    var red := StandardMaterial3D.new()
    red.albedo_color = Color(0.85, 0.12, 0.10)
    var white := StandardMaterial3D.new()
    white.albedo_color = Color(0.95, 0.95, 0.92)
    var top := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = 0.09
    sm.height = 0.18
    top.mesh = sm
    top.material_override = red
    top.position = Vector3(0, 0.05, 0)
    _bobber.add_child(top)
    var bot := MeshInstance3D.new()
    var sm2 := SphereMesh.new()
    sm2.radius = 0.085
    sm2.height = 0.14
    bot.mesh = sm2
    bot.material_override = white
    bot.position = Vector3(0, -0.03, 0)
    _bobber.add_child(bot)
    _bobber.visible = false

func _go(s: int, dur: float) -> void:
    state = s
    _t = 0.0
    _dur = dur

func _play(nm: String) -> void:
    if _anim:
        Rig.play(_anim, nm)

func _process(delta: float) -> void:
    if target == Vector3.ZERO:
        return
    _t += delta
    var tip := _rod_tip.global_position
    match state:
        S.IDLE:
            _bobber.visible = false
            if _t >= _dur:
                _play("Throw")
                _go(S.CAST, 0.7)
        S.CAST:
            _bobber.visible = true
            var k := clampf(_t / _dur, 0.0, 1.0)
            var p := tip.lerp(target, k)
            p.y = lerpf(tip.y, water_y, k) + sin(k * PI) * 2.2
            _bobber.global_position = p
            if k >= 1.0:
                _play("Idle")
                _splash(0.6)
                var w := Fishing.bite_wait(_rng, lure)
                if demo:
                    w = 0.4
                    demo = false
                _go(S.WAIT, w)
        S.WAIT:
            _bobber.global_position = target + Vector3(0, water_y - target.y + sin(_t * 2.6) * 0.03, 0)
            if _t >= _dur:
                _splash(1.0)
                _go(S.BITE, Fishing.bite_window())
        S.BITE:
            # yanked under, twitching
            _bobber.global_position = target + Vector3(sin(_t * 40.0) * 0.04, water_y - target.y - 0.22, 0)
            if _t >= _dur * 0.35:
                if not forced.is_empty() or _rng.randf() < skill:
                    _item = forced if not forced.is_empty() else Fishing.roll(_rng, luck)
                    forced = {}
                    _spawn_catch()
                    _play("Interact")
                    _go(S.REEL, 0.9)
                else:
                    _show_text("It got away...", Color(0.75, 0.75, 0.75))
                    _go(S.MISS, 1.6)
        S.REEL:
            var k := clampf(_t / _dur, 0.0, 1.0)
            var dest := global_position + Vector3(0, 1.9, 0) + global_transform.basis.z * 0.6
            var p := _from.lerp(dest, k)
            p.y += sin(k * PI) * 2.6
            _bobber.global_position = p
            if _catch:
                _catch.global_position = p + Vector3(0, -0.15, 0)
                _catch.rotation.y += delta * 9.0
            if k >= 1.0:
                var rar := String(_item.get("rarity", "common"))
                _show_text("%s\n%s" % [rar.to_upper(), String(_item.get("name", "?"))], Fishing.colour(_item))
                if rar == "rare" or rar == "epic" or rar == "legendary":
                    _play("Cheer")
                creel.append(_item)
                caught.emit(_item, who)
                _go(S.SHOW, 2.6)
        S.SHOW:
            _bobber.visible = false
            if _catch:
                # held up OVER the head, so it is seen from any side of the dock
                _catch.global_position = global_position + Vector3(0, 3.1 + sin(_t * 3.0) * 0.06, 0)
                _catch.rotation.y += delta * 1.5
            if _t >= _dur:
                if _catch:
                    _catch.queue_free()
                    _catch = null
                _label.visible = false
                _play("Idle")
                _go(S.IDLE, _rng.randf_range(2.0, 6.0))
        S.MISS:
            _bobber.visible = false
            if _t >= _dur:
                _label.visible = false
                _go(S.IDLE, _rng.randf_range(1.0, 3.0))
    _draw_line(tip)
    _tick_ring(delta)

func _draw_line(tip: Vector3) -> void:
    _imm.clear_surfaces()
    if not _bobber.visible:
        return
    var b := _bobber.global_position
    _imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
    var sag := 0.0 if state == S.REEL or state == S.BITE else 0.6
    for i in range(13):
        var k := float(i) / 12.0
        var p := tip.lerp(b, k)
        p.y -= sin(k * PI) * sag
        _imm.surface_add_vertex(p)
    _imm.surface_end()

func _splash(strength: float) -> void:
    _ring.global_position = Vector3(target.x, water_y + 0.02, target.z)
    _ring.scale = Vector3.ONE * 0.4
    _ring.set_meta("life", 0.9 * strength)
    _ring.set_meta("max", 0.9 * strength)

func _tick_ring(delta: float) -> void:
    var life: float = float(_ring.get_meta("life", 0.0))
    var mx: float = float(_ring.get_meta("max", 1.0))
    var m := _ring.material_override as StandardMaterial3D
    if life <= 0.0:
        m.albedo_color.a = 0.0
        return
    life -= delta
    _ring.set_meta("life", life)
    var k := 1.0 - life / mx
    _ring.scale = Vector3(0.4 + k * 3.0, 1.0, 0.4 + k * 3.0)
    m.albedo_color.a = (1.0 - k) * 0.8

func _show_text(t: String, c: Color) -> void:
    _label.text = t
    _label.modulate = c
    _label.visible = true

func _spawn_catch() -> void:
    _from = _bobber.global_position
    _catch = Node3D.new()
    _catch.top_level = true
    add_child(_catch)
    var path := String(_item.get("model", ""))
    var body: Node3D = null
    if path != "" and ResourceLoader.exists(path):
        body = (load(path) as PackedScene).instantiate()
    else:
        body = _boot()
    ## display size: a key or a perch is a few pixels at stream distance, so
    ## every catch is shown at a readable size, the real ones relative to each other
    body.scale = Vector3.ONE * float(_item.get("scale", 1.0)) * 1.8
    _catch.add_child(body)
    var tint: Array = _item.get("tint", [])
    var glow := bool(_item.get("glow", false))
    if tint.size() == 3 or glow:
        var col := Color(float(tint[0]), float(tint[1]), float(tint[2])) if tint.size() == 3 else Color(1, 1, 1)
        _recolour(body, col, tint.size() == 3, glow)
    if glow:
        var l := OmniLight3D.new()
        l.light_color = Fishing.colour(_item)
        l.light_energy = 1.2
        l.omni_range = 3.0
        _catch.add_child(l)

func _recolour(n: Node, col: Color, tint: bool, glow: bool) -> void:
    if n is MeshInstance3D:
        var mi: MeshInstance3D = n
        if mi.mesh:
            for i in range(mi.mesh.get_surface_count()):
                var src: Material = mi.get_active_material(i)
                var d: StandardMaterial3D = (src as StandardMaterial3D).duplicate() if src is StandardMaterial3D else StandardMaterial3D.new()
                if tint:
                    d.albedo_color = col
                if glow:
                    d.emission_enabled = true
                    d.emission = Fishing.colour(_item) if not tint else col
                    d.emission_energy_multiplier = 1.2
                mi.set_surface_override_material(i, d)
    for c in n.get_children():
        _recolour(c, col, tint, glow)

## No boot in the kits, so a boot is built: a shaft and a foot.
func _boot() -> Node3D:
    var n := Node3D.new()
    var leather := StandardMaterial3D.new()
    leather.albedo_color = Color(0.26, 0.18, 0.12)
    leather.roughness = 0.8
    var shaft := MeshInstance3D.new()
    var sm := CylinderMesh.new()
    sm.top_radius = 0.09
    sm.bottom_radius = 0.1
    sm.height = 0.34
    shaft.mesh = sm
    shaft.material_override = leather
    shaft.position = Vector3(0, 0.17, 0)
    n.add_child(shaft)
    var foot := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = Vector3(0.18, 0.11, 0.32)
    foot.mesh = bm
    foot.material_override = leather
    foot.position = Vector3(0, 0.05, 0.09)
    n.add_child(foot)
    return n
