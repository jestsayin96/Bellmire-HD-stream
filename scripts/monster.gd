class_name Monster
extends Node3D
## A creature of the dungeon, built from a Bestiary def. Loads the body,
## normalises its size, maps its animations, arms it (Gear), tints it for its
## strain (with a glow when the strain has one), and - for the eight lords -
## adds the boss trappings: a ground aura that breathes, a crown of light, a
## title over its head. States: IDLE, PATROL (wanders an area), ATTACK (faces a
## target; casters throw Spells, the rest swing/bite), DEAD.

enum S { IDLE, PATROL, ATTACK, DEAD }
var def: Dictionary = {}
var state: int = S.PATROL
var home := Vector3.ZERO
var roam := 6.0
var target: Node3D = null
var ground_fn: Callable            # (x, z) -> y; flat 0 when unset
var _ap: AnimationPlayer
var _body: Node3D
var _goal := Vector3.ZERO
var _t := 0.0
var _swing := 1.0
var _rng := RandomNumberGenerator.new()
var _aura: MeshInstance3D

func _ready() -> void:
    _rng.randomize()
    home = global_position if home == Vector3.ZERO else home
    var ps: PackedScene = load(String(def.get("path", "")))
    if ps == null:
        return
    _body = ps.instantiate()
    add_child(_body)
    # scale to a real height from the body's own bounds, measured in body space
    var hb := _local_bounds(_body)
    if def.has("h") and hb.size.y > 0.01:
        _body.scale = Vector3.ONE * (float(def["h"]) / hb.size.y)
    elif def.has("scale"):
        _body.scale = Vector3.ONE * float(def["scale"])
    if bool((def.get("anims", {}) as Dictionary).get("ual", false)):
        _graft_ual()
    var st: Array = [_body]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is AnimationPlayer and _ap == null:
            _ap = c
        for g in c.get_children():
            st.append(g)
    if _ap:
        Rig.prep(_ap)
        for a in _ap.get_animation_list():
            var s := String(a)
            if s.contains("Idle") or s.contains("Walk") or s.contains("Run") or s.contains("Flying"):
                _ap.get_animation(a).loop_mode = Animation.LOOP_LINEAR
        # a creature's own idle / walk always loops (an aiming bowman, a sentinel behind its shield)
        for k in ["idle", "walk", "run"]:
            var nm := String((def.get("anims", {}) as Dictionary).get(k, ""))
            if nm != "" and _ap.has_animation(nm):
                _ap.get_animation(nm).loop_mode = Animation.LOOP_LINEAR
        _play("idle")
        _ap.seek(_rng.randf() * 1.5, true)
    if String(def.get("path", "")).contains("kaykit"):
        Gear.strip_props(_body)
    var tint: Color = def.get("tint", Color(1, 1, 1))
    var glow: Color = def.get("glow", Color(0, 0, 0))
    if tint != Color(1, 1, 1) or glow != Color(0, 0, 0):
        _tint(_body, tint, glow)
    if String(def.get("hand", "")) != "":
        Gear.equip(_body, String(def["hand"]), "handslot.r", "weapon", float(def.get("wscale", 1.0)), float(def.get("wglow", 0.0)))
    if String(def.get("off", "")) != "":
        Gear.equip(_body, String(def["off"]), "handslot.l", "offhand", float(def.get("wscale", 1.0)), float(def.get("wglow", 0.0)))
    max_hp = float(def.get("boss_hp", float(def.get("hp", 1.0)) * 30.0))
    hp = max_hp
    if bool(def.get("boss", false)):
        _trappings()
    _label()
    Monster.voice(self, false)            # S2: it makes itself known (one voice a beat, the biggest / nearest)

static var _ual: Array = []

## bounds of every visible mesh, in the space of `top` (node transforms only;
## does not depend on the tree having resolved globals yet)
func _local_bounds(top: Node3D) -> AABB:
    var box := AABB()
    var first := true
    var st: Array = [[top, Transform3D.IDENTITY]]
    while not st.is_empty():
        var e: Array = st.pop_back()
        var c: Node = e[0]
        var xf: Transform3D = e[1]
        if c is MeshInstance3D and (c as MeshInstance3D).visible and (c as MeshInstance3D).mesh:
            var ab: AABB = xf * (c as MeshInstance3D).get_aabb()
            box = ab if first else box.merge(ab)
            first = false
        for g in c.get_children():
            if g is HealthBar3D:
                continue      # the bar sits above the height: measuring it made it climb every frame
            var gx := xf * (g as Node3D).transform if g is Node3D else xf
            st.append([g, gx])
    return box

func _graft_ual() -> void:
    if _ual.is_empty():
        for p in ["res://assets/monsters/UAL1.glb", "res://assets/monsters/UAL2.glb"]:
            if not ResourceLoader.exists(p):
                continue
            var n: Node = (load(p) as PackedScene).instantiate()
            var st: Array = [n]
            while not st.is_empty():
                var c: Node = st.pop_back()
                if c is AnimationPlayer:
                    for ln in (c as AnimationPlayer).get_animation_library_list():
                        _ual.append((c as AnimationPlayer).get_animation_library(ln))
                for g in c.get_children():
                    st.append(g)
            n.free()
    var ap := AnimationPlayer.new()
    _body.add_child(ap)
    ap.root_node = NodePath("..")
    for i in range(_ual.size()):
        ap.add_animation_library("ual%d" % i if i > 0 else "", _ual[i])
    _ap = ap

func _tint(n: Node, col: Color, glow: Color) -> void:
    if n is MeshInstance3D and not String(n.name).begins_with("eq_"):
        var mi: MeshInstance3D = n
        if mi.mesh:
            for i in range(mi.mesh.get_surface_count()):
                var src: Material = mi.get_active_material(i)
                var d: StandardMaterial3D = (src as StandardMaterial3D).duplicate() if src is StandardMaterial3D else StandardMaterial3D.new()
                d.albedo_color = d.albedo_color * col
                if glow != Color(0, 0, 0):
                    d.emission_enabled = true
                    d.emission = glow
                    d.emission_energy_multiplier = 0.18
                mi.set_surface_override_material(i, d)
    for c in n.get_children():
        if not String(c.name).begins_with("eq_"):
            _tint(c, col, glow)

func _height() -> float:
    if _body:
        var lb := _local_bounds(self)
        if lb.size.y > 0.01:
            return lb.end.y
    var box := AABB()
    var first := true
    var st: Array = [_body]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is MeshInstance3D and (c as MeshInstance3D).visible:
            var ab: AABB = (c as MeshInstance3D).global_transform * (c as MeshInstance3D).get_aabb()
            box = ab if first else box.merge(ab)
            first = false
        for g in c.get_children():
            if not g is HealthBar3D:
                st.append(g)
    return box.end.y - global_position.y if not first else 2.0

func _label() -> void:
    var boss := bool(def.get("boss", false))
    var lb := Label3D.new()
    lb.text = String(def.get("name", "?"))
    if boss and String(def.get("note", "")) != "":
        lb.text += "\n" + String(def["note"])
    lb.font_size = 72 if boss else 40
    lb.pixel_size = 0.009 if boss else 0.005
    lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    lb.outline_size = 18
    lb.outline_modulate = Color(0, 0, 0, 0.9)
    lb.modulate = (def.get("aura", Color(1, 0.8, 0.4)) as Color).lightened(0.3) if boss else Color(1.0, 0.55, 0.45)
    lb.visibility_range_end = 90.0 if boss else 60.0
    lb.name = "name_tag"
    add_child(lb)
    lb.position = Vector3(0, _height() + 0.5, 0)

func _trappings() -> void:
    var col: Color = def.get("aura", Color(1, 0.8, 0.4))
    var sc := float(def.get("scale", 1.0))
    var r := clampf(_height() * 0.5, 1.6, 6.0)
    _aura = MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = r
    cm.bottom_radius = r
    cm.height = 0.02
    _aura.mesh = cm
    var m := StandardMaterial3D.new()
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.albedo_color = Color(col.r, col.g, col.b, 0.35)
    _aura.material_override = m
    _aura.position = Vector3(0, 0.04, 0)
    add_child(_aura)
    var ring := MeshInstance3D.new()
    var tm := TorusMesh.new()
    tm.inner_radius = r * 0.96
    tm.outer_radius = r * 1.04
    ring.mesh = tm
    var rm := StandardMaterial3D.new()
    rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    rm.albedo_color = col
    rm.emission_enabled = true
    rm.emission = col
    rm.emission_energy_multiplier = 2.5
    ring.material_override = rm
    ring.position = Vector3(0, 0.06, 0)
    add_child(ring)
    # a crown of light: points of flame circling the head
    var crown := Node3D.new()
    crown.name = "crown"
    crown.position = Vector3(0, _height() + 0.15, 0)        # _height already includes lift
    add_child(crown)
    for i in range(7):
        var a := TAU * float(i) / 7.0
        var spike := MeshInstance3D.new()
        var pm := PrismMesh.new()
        pm.size = Vector3(0.22, 0.45, 0.1)
        spike.mesh = pm
        spike.material_override = rm
        spike.position = Vector3(cos(a) * 0.55, 0, sin(a) * 0.55) * clampf(sc * 0.35, 0.8, 2.0)
        spike.rotation.y = -a
        crown.add_child(spike)
    var l := OmniLight3D.new()
    l.light_color = col
    l.light_energy = 2.5
    l.omni_range = r * 3.0
    l.position = Vector3(0, _height() * 0.6, 0)
    add_child(l)
    var motes := GPUParticles3D.new()
    motes.amount = 60
    motes.lifetime = 3.0
    var pmat := ParticleProcessMaterial.new()
    pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
    pmat.emission_ring_radius = r
    pmat.emission_ring_inner_radius = r * 0.8
    pmat.emission_ring_height = 0.1
    pmat.emission_ring_axis = Vector3(0, 1, 0)
    pmat.direction = Vector3(0, 1, 0)
    pmat.spread = 10.0
    pmat.initial_velocity_min = 0.6
    pmat.initial_velocity_max = 1.6
    pmat.gravity = Vector3.ZERO
    pmat.scale_min = 0.6
    pmat.scale_max = 1.2
    pmat.color = col
    motes.process_material = pmat
    var sm := SphereMesh.new()
    sm.radius = 0.06
    sm.height = 0.12
    sm.material = rm
    motes.draw_pass_1 = sm
    add_child(motes)

## Anything outside (Delve, raids) drives the body through _play. The body's
## own idle (state IDLE) waits until nobody has driven it for a moment - it used
## to replay "idle" every frame, so every walk and every swing a fight asked for
## was undone the next frame and creatures glided frozen across the floor.
## A one-shot (attack, cast, hit, summon, rise) owns the body until it ends; only
## death cuts it short.
const ONE_SHOTS := ["attack", "attack2", "cast", "hit", "summon", "rise"]
var _ext_t := -99.0
var _hold_until := -1.0
func _play(key: String) -> void:
    _ext_t = _t
    _play_now(key)

## mid one-shot (a swing, a rise, a hit): Delve does not walk it meanwhile
func busy() -> bool:
    return _t < _hold_until

func _play_now(key: String) -> void:
    if _ap == null:
        if key == "hit":
            _flinch()
        return
    var an: Dictionary = def.get("anims", {})
    # L26a: a second swing where the body has one (bat, wyrm), now and then
    if key == "attack" and an.has("attack2") and _rng.randf() < 0.4:
        key = "attack2"
    var nm := clip_for(key)
    if nm == "":
        if key == "hit":
            _flinch()          # no reaction clip: the body itself recoils
        return
    if key != "die" and _t < _hold_until and not ONE_SHOTS.has(key):
        return
    if ONE_SHOTS.has(key):
        _ap.play(nm, 0.12)
        _ap.seek(0.0, true)
        var ln := _ap.get_animation(nm).length
        _hold_until = _t + clampf(ln * 0.9, 0.3, 2.0)
        if key in ["attack", "attack2", "cast"]:
            _swing_len = ln
    elif _ap.current_animation != nm:
        _ap.play(nm, 0.2)

## ---- L26a: no creature stands frozen for want of a clip
## when the body lacks the asked-for clip, the nearest one it does have. A missing walk
## falls to run then idle (never nothing - that is the glide); a missing hit has no
## stand-in clip, Monster flinches procedurally instead.
const FALLBACK := {"run": ["walk"], "walk": ["run", "idle"], "idle": ["walk"], "cast": ["attack"],
    "summon": ["cast", "attack"], "rise": ["idle"], "attack": ["cast"], "attack2": ["attack"],
    "hit": [], "die": []}
func clip_for(key: String) -> String:
    if _ap == null:
        return ""
    var an: Dictionary = def.get("anims", {})
    var keys: Array = [key]
    keys.append_array(FALLBACK.get(key, []))
    for k in keys:
        var nm := String(an.get(k, ""))
        if nm != "" and _ap.has_animation(nm):
            return nm
    return ""

## when a swing lands: the contact point of the clip just started (about 0.42 of a
## melee swing - the blade comes down there), so Delve applies the blow then, not on the
## swing's first frame
const IMPACT_FRAC := 0.42
var _swing_len := 0.8
func impact() -> float:
    return clampf(_swing_len * IMPACT_FRAC / maxf(0.1, _ap.speed_scale if _ap else 1.0), 0.12, 0.6)

## the body recoils (no hit clip): tipped back and squashed for a beat, then home
var _flinch_tw: Tween
var _base_scale := Vector3.ZERO
var flinches := 0
func _flinch() -> void:
    if _body == null or not is_inside_tree():
        return
    flinches += 1
    # the rest size is read fresh unless a flinch is mid-way (enrage swells the body)
    if _flinch_tw and _flinch_tw.is_valid() and _flinch_tw.is_running():
        _flinch_tw.kill()
    else:
        _base_scale = _body.scale
    _body.scale = _base_scale
    _body.rotation.x = 0.0
    _flinch_tw = create_tween()
    _flinch_tw.tween_property(_body, "rotation:x", -0.22, 0.07).set_ease(Tween.EASE_OUT)
    _flinch_tw.parallel().tween_property(_body, "scale", _base_scale * Vector3(1.08, 0.86, 1.08), 0.07)
    _flinch_tw.tween_property(_body, "rotation:x", 0.0, 0.22).set_trans(Tween.TRANS_BACK)
    _flinch_tw.parallel().tween_property(_body, "scale", _base_scale, 0.22).set_trans(Tween.TRANS_BACK)

func _entering() -> bool:
    return _body.position.y < -0.05

func _gy(x: float, z: float) -> float:
    return float(ground_fn.call(x, z)) if ground_fn.is_valid() else 0.0

func _process(delta: float) -> void:
    _t += delta
    _tick_flash(delta)
    Monster._voice_flush()
    if _body == null or state == S.DEAD:
        return
    _tick_wild()
    _tick_tag(delta)
    var lift := float(def.get("lift", 0.0))
    if _body.position.y < lift - 0.05 and get_tree() and _entering():
        return
    # unrigged bodies (imp, puglin) and every flyer get a bob
    var bob := 0.0
    if lift > 0.0:
        bob = sin(_t * 2.2) * 0.25
    if not _entering():
        _body.position.y = lift + bob

    var crown := get_node_or_null("crown")
    if crown:
        crown.rotation.y += delta * 0.8
    if _aura:
        var k := 0.85 + sin(_t * 1.6) * 0.15
        _aura.scale = Vector3(k, 1, k)
    match state:
        S.IDLE:
            if _t - _ext_t > 0.3:
                _play_now("idle")
        S.PATROL:
            if _goal == Vector3.ZERO or global_position.distance_to(_goal) < 0.8:
                _goal = home + Vector3(_rng.randf_range(-roam, roam), 0, _rng.randf_range(-roam, roam))
            var to := _goal - global_position
            to.y = 0.0
            var d := to.normalized()
            var p := global_position + d * float(def.get("spd", 3.0)) * 0.35 * delta
            p.y = _gy(p.x, p.z)
            global_position = p
            rotation.y = lerp_angle(rotation.y, atan2(d.x, d.z), delta * 5.0)
            _play_now("walk")
        S.ATTACK:
            if target == null or not is_instance_valid(target):
                state = S.PATROL
                return
            var to2 := target.global_position - global_position
            to2.y = 0.0
            rotation.y = lerp_angle(rotation.y, atan2(to2.x, to2.z), delta * 6.0)
            _swing -= delta
            if _swing <= 0.0:
                _swing = 1.6
                if bool(def.get("casts", false)):
                    Spells.cast("bolt", self, target.global_position, false)
                    _play("cast")
                else:
                    _play("attack")
                    if _ap:
                        _ap.queue(String((def.get("anims", {}) as Dictionary).get("idle", "")))

## ---------------------------------------------------------------- ways (L1)
## a shot at `to`: casters throw the Spells bolt, a bowman looses a bone bolt
## that flies flat from the bow to the mark
var shots := 0
func shoot(to: Vector3) -> void:
    shots += 1
    var ways: Dictionary = def.get("ways", {})
    _play("attack" if not bool(def.get("casts", false)) else "cast")
    if _ap:
        _ap.queue(String((def.get("anims", {}) as Dictionary).get("idle", "")))
    var from := global_position + Vector3(0, _height() * 0.62, 0) + global_transform.basis.z * 0.4
    if bool(def.get("casts", false)):
        Spells.cast("bolt", self, to, false)
        return
    var root := get_tree().current_scene if get_tree().current_scene else get_parent()
    var bolt := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = Vector3(0.05, 0.05, 0.75)
    bolt.mesh = bm
    var m := StandardMaterial3D.new()
    m.albedo_color = Color(0.92, 0.88, 0.78)
    m.emission_enabled = true
    m.emission = Color(0.9, 0.85, 0.6) if String(ways.get("shot", "")) == "bolt_bone" else Color(1, 1, 1)
    m.emission_energy_multiplier = 0.6
    bolt.material_override = m
    bolt.top_level = true
    root.add_child(bolt)
    bolt.global_position = from
    if from.distance_to(to) > 0.1:
        bolt.look_at_from_position(from, to, Vector3.UP)
    var tw := bolt.create_tween()
    tw.tween_property(bolt, "global_position", to, clampf(from.distance_to(to) / 26.0, 0.08, 0.45))
    tw.tween_callback(bolt.queue_free)

## a grave-whelp's breath: a short stream of pale grave-fire at the mark
func breathe(to: Vector3) -> void:
    shots += 1
    Sfx.at("dragon_fire_breath", global_position + Vector3(0, _height() * 0.5, 0), 3.0)    # S2
    _play("attack")
    if _ap:
        _ap.queue(String((def.get("anims", {}) as Dictionary).get("idle", "")))
    var root := get_tree().current_scene if get_tree().current_scene else get_parent()
    var from := global_position + Vector3(0, _height() * 0.55, 0) + global_transform.basis.z * (_height() * 0.45)
    var col := Color(0.55, 1.0, 0.6)
    for i in range(7):
        var s := MeshInstance3D.new()
        var sm := SphereMesh.new()
        sm.radius = 0.08 + 0.05 * float(i)
        sm.height = sm.radius * 2.0
        s.mesh = sm
        var mm := StandardMaterial3D.new()
        mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        mm.albedo_color = Color(col.r, col.g, col.b, 0.55)
        s.material_override = mm
        s.top_level = true
        root.add_child(s)
        s.global_position = from
        var tw := s.create_tween()
        tw.tween_interval(0.05 * float(i))
        tw.tween_property(s, "global_position", to + Vector3(randf_range(-0.6, 0.6), 0.3, randf_range(-0.6, 0.6)), 0.35)
        tw.parallel().tween_property(mm, "albedo_color:a", 0.0, 0.5)
        tw.tween_callback(s.queue_free)
    Spells._burst(root, to + Vector3(0, 0.3, 0), col)

## a raised dead: starts in the floor and climbs out (the KayKit awaken)
func rise() -> void:
    _play("rise")
    if _ap:
        _ap.queue(String((def.get("anims", {}) as Dictionary).get("idle", "")))
    var root := get_tree().current_scene if get_tree().current_scene else get_parent()
    Spells._burst(root, global_position + Vector3(0, 0.2, 0), Color(0.3, 0.9, 0.45))

## ---- L2 lord mechanics, the visible half (Delve does the numbers)
## a ring of the lord's own colour that rolls out to `r` along the floor
func nova(r: float) -> void:
    var col: Color = def.get("aura", Color(1, 0.8, 0.4))
    _play("cast" if (def.get("anims", {}) as Dictionary).has("cast") else "attack")
    if _ap:
        _ap.queue(String((def.get("anims", {}) as Dictionary).get("idle", "")))
    var root := get_tree().current_scene if get_tree().current_scene else get_parent()
    var ring := MeshInstance3D.new()
    var tm := TorusMesh.new()
    tm.inner_radius = 0.85
    tm.outer_radius = 1.0
    ring.mesh = tm
    var m := StandardMaterial3D.new()
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.albedo_color = Color(col.r, col.g, col.b, 0.85)
    m.emission_enabled = true
    m.emission = col
    m.emission_energy_multiplier = 3.0
    ring.material_override = m
    ring.top_level = true
    root.add_child(ring)
    ring.global_position = global_position + Vector3(0, 0.25, 0)
    ring.scale = Vector3(0.5, 1.0, 0.5)
    var tw := ring.create_tween()
    tw.set_parallel(true)
    tw.tween_property(ring, "scale", Vector3(r, 2.5, r), 0.6).set_ease(Tween.EASE_OUT)
    tw.tween_property(m, "albedo_color:a", 0.0, 0.7)
    tw.chain().tween_callback(ring.queue_free)
    Spells._burst(root, global_position + Vector3(0, 0.5, 0), col)
    nova_count += 1
var nova_count := 0

## crosses the room in one beat onto `to` (Nightwing: too fast to see coming)
func swoop(to: Vector3, exact := false) -> void:
    var dest := to if exact else to + (global_position - to).normalized() * 1.4
    dest.y = global_position.y
    var tw := create_tween()
    tw.tween_property(self, "global_position", dest, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    _play("attack")
    var root := get_tree().current_scene if get_tree().current_scene else get_parent()
    Spells._burst(root, global_position + Vector3(0, 1.0, 0), def.get("aura", Color(0.5, 0.3, 0.9)))

## enraged: the aura and crown burn red and the body swells a little
var enraged := false
func enrage() -> void:
    if enraged:
        return
    enraged = true
    var red := Color(1.0, 0.18, 0.12)
    def["aura"] = red
    for c in get_children():
        if c is MeshInstance3D and (c as MeshInstance3D).material_override is StandardMaterial3D:
            var mm: StandardMaterial3D = (c as MeshInstance3D).material_override
            var a := mm.albedo_color.a
            mm.albedo_color = Color(red.r, red.g, red.b, a)
            if mm.emission_enabled:
                mm.emission = red
        if c is OmniLight3D:
            (c as OmniLight3D).light_color = red
    if _body:
        var tw := create_tween()
        tw.tween_property(_body, "scale", _body.scale * 1.1, 0.4)
    var root := get_tree().current_scene if get_tree().current_scene else get_parent()
    Spells._burst(root, global_position + Vector3(0, _height() * 0.5, 0), red)

## the scarborn glow never settles: it wanders the hue wheel like the scar's motes
var _wild_mats: Array = []
func _tick_wild() -> void:
    if not bool(def.get("wild", false)) or _flash_t > 0.0:
        return
    if _wild_mats.is_empty():
        var st: Array = [_body]
        while not st.is_empty():
            var c: Node = st.pop_back()
            if c is MeshInstance3D and not String(c.name).begins_with("eq_"):
                var mi: MeshInstance3D = c
                for i in range(mi.mesh.get_surface_count() if mi.mesh else 0):
                    var mat := mi.get_surface_override_material(i)
                    if mat is StandardMaterial3D:
                        _wild_mats.append(mat)
            for g in c.get_children():
                if not String(g.name).begins_with("eq_"):
                    st.append(g)
    var col := Color.from_hsv(fposmod(_t * 0.12 + float(get_instance_id() % 97) / 97.0, 1.0), 0.75, 1.0)
    for m in _wild_mats:
        (m as StandardMaterial3D).emission = col
        (m as StandardMaterial3D).emission_energy_multiplier = 0.35

## ---------------------------------------------------------------- combat polish
var hp := 10.0
var max_hp := 10.0
var _flash_t := 0.0
var _flash_mats: Array = []

## take a hit: white flash, hit animation, a number that floats up, death at 0
func hurt(amount: float, crit := false) -> void:
    if state == S.DEAD:
        return
    hp -= amount
    Sfx.at("hit", global_position, HIT_DB + (3.0 if crit else 0.0))     # S3: under the weapon's own clash / impact
    _number(amount, crit)
    _flash()
    if hp <= 0.0:
        die()
    else:
        _play("hit")
        if _ap:
            _ap.queue(String((def.get("anims", {}) as Dictionary).get("idle", "")))

func _number(amount: float, crit: bool) -> void:
    var lb := Label3D.new()
    lb.text = ("%d!" if crit else "%d") % int(round(amount))
    lb.font_size = 96 if crit else 64
    lb.pixel_size = 0.006 if Spotlight.mode != "off" else 0.01    # L21: smaller in a close side-by-side pane
    lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    lb.no_depth_test = true
    lb.outline_size = 20
    lb.outline_modulate = Color(0, 0, 0, 0.9)
    lb.modulate = Color(1.0, 0.85, 0.2) if crit else Color(1.0, 0.95, 0.9)
    lb.top_level = true
    add_child(lb)
    var p := global_position + Vector3(randf_range(-0.4, 0.4), _height() * 0.8 + 0.3, randf_range(-0.4, 0.4))
    lb.global_position = p
    var tw := lb.create_tween()
    tw.set_parallel(true)
    tw.tween_property(lb, "global_position", p + Vector3(0, 1.4, 0), 0.9).set_ease(Tween.EASE_OUT)
    tw.tween_property(lb, "modulate:a", 0.0, 0.9).set_delay(0.3)
    tw.chain().tween_callback(lb.queue_free)

func _flash() -> void:
    if _flash_mats.is_empty():
        var st: Array = [_body]
        while not st.is_empty():
            var c: Node = st.pop_back()
            if c is MeshInstance3D and (c as MeshInstance3D).visible and not String(c.name).begins_with("eq_"):
                var mi: MeshInstance3D = c
                for i in range(mi.mesh.get_surface_count()):
                    var src: Material = mi.get_active_material(i)
                    if src is StandardMaterial3D:
                        var d: StandardMaterial3D = src.duplicate()
                        mi.set_surface_override_material(i, d)
                        _flash_mats.append(d)
            for g in c.get_children():
                if not String(g.name).begins_with("eq_"):
                    st.append(g)
    for d in _flash_mats:
        var mm: StandardMaterial3D = d
        mm.emission_enabled = true
        mm.emission = Color(1, 1, 1)
        mm.emission_energy_multiplier = 1.6
    _flash_t = 0.12

func _tick_flash(delta: float) -> void:
    if _flash_t <= 0.0:
        return
    _flash_t -= delta
    if _flash_t <= 0.0:
        var glow: Color = def.get("glow", Color(0, 0, 0))
        for d in _flash_mats:
            var mm: StandardMaterial3D = d
            mm.emission = glow
            mm.emission_enabled = glow != Color(0, 0, 0)
            mm.emission_energy_multiplier = 0.18

## death: the death animation, then sink into the floor and go
func die() -> void:
    state = S.DEAD
    _play("die")
    Monster.voice(self, true)             # S2: its last sound
    if _aura:
        _aura.visible = false
    var tw := create_tween()
    tw.tween_interval(1.8)
    tw.tween_property(self, "position:y", position.y - _height() * 0.6 - 0.5, 1.4)
    tw.tween_callback(queue_free)

## A LORD RISES. Out of the ground in a burst of its own colour, its title and
## canon note spelled out over it, a shock ring when it is fully up.
func entrance() -> void:
    var col: Color = def.get("aura", Color(1, 0.8, 0.4))
    var h := _height()
    _body.position.y = -h - 0.5
    var lb := get_node_or_null("title")
    var tw := create_tween()
    tw.tween_property(_body, "position:y", float(def.get("lift", 0.0)), 2.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    var root := get_tree().current_scene if get_tree().current_scene else get_parent()
    var dust := GPUParticles3D.new()
    dust.amount = 160
    dust.lifetime = 1.8
    dust.one_shot = true
    dust.explosiveness = 0.3
    var pm := ParticleProcessMaterial.new()
    pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
    pm.emission_ring_radius = clampf(h * 0.5, 1.5, 6.0)
    pm.emission_ring_inner_radius = 0.2
    pm.emission_ring_height = 0.1
    pm.emission_ring_axis = Vector3(0, 1, 0)
    pm.direction = Vector3(0, 1, 0)
    pm.spread = 35.0
    pm.initial_velocity_min = 2.0
    pm.initial_velocity_max = 6.0
    pm.gravity = Vector3(0, -5, 0)
    pm.scale_min = 0.8
    pm.scale_max = 2.0
    pm.color = col
    dust.process_material = pm
    var sm := SphereMesh.new()
    sm.radius = 0.1
    sm.height = 0.2
    var mm := StandardMaterial3D.new()
    mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mm.albedo_color = col
    mm.emission_enabled = true
    mm.emission = col
    mm.emission_energy_multiplier = 3.0
    sm.material = mm
    dust.draw_pass_1 = sm
    dust.emitting = true
    add_child(dust)
    tw.tween_callback(func() -> void:
        Spells._burst(root, global_position + Vector3(0, 0.3, 0), col)
        dust.queue_free())
    _play("idle")

## L15: a creature's name stays readable from the stream camera - its label
## grows with distance past 16 m (as the heroes' names do), checked 4x a second
var _tag_t := 0.0
func _tick_tag(delta: float) -> void:
    _tag_t -= delta
    if _tag_t > 0.0:
        return
    _tag_t = 0.25
    var lb := get_node_or_null("name_tag") as Label3D
    var vp := get_viewport()
    var cam := vp.get_camera_3d() if vp else null
    if lb == null or cam == null:
        return
    if not lb.has_meta("px0"):
        lb.set_meta("px0", lb.pixel_size)
    var cd := cam.global_position.distance_to(lb.global_position)
    lb.pixel_size = float(lb.get_meta("px0")) * clampf(cd / 16.0, 0.6, 3.0)

## ---- S2: creatures' voices (Bestiary.voice_of -> an Sfx kind). A floor spawns a dozen at
## once and a fight kills several in a second, so voices are QUEUED and one plays a beat:
## the frame's loudest claim wins - the biggest, the nearest the camera, a death over a
## spawn - and then nobody speaks for VOICE_GAP, nor that same kind for KIND_GAP. A lord's
## arrival roar goes straight through (and holds the rest off for a moment).
## S3 (measured: file RMS against the music as heard, ~20 m off): the voices are not one
## loudness - the dragon roars 10 dB hotter than a skeleton rattles - so each is trimmed to sit
## near the music; a lord's roar is ROAR_DB over its own trimmed level
const VOICE_TRIM := {"dragon_roar": -6.0, "demon_growl": -3.0, "wolf_growl": -3.0, "skeleton_rattle": 4.0, "spider_skitter": 4.0, "insect_buzz": 2.0}
const ROAR_DB := 4.0
const DEATH_DB := 2.0
const HIT_DB := -4.0                 # the generic thud a blow lands with, under its weapon sound
const VOICE_GAP := 900               # ms between any two creature voices
const KIND_GAP := 3500               # ms before the same kind of voice again
static var _vq: Array = []           # [score, kind, pos, db] claims this frame
static var _vq_frame := -1
static var _v_any := -100000
static var _v_kind := {}
static var voiced := {}              # kind -> times heard (tests read it)

static func voice(m: Monster, dying: bool) -> void:
    if m == null or not m.is_inside_tree():
        return
    var kind := Bestiary.voice_of(m.def)
    if kind == "":
        return
    var cam := m.get_viewport().get_camera_3d() if m.get_viewport() else null
    var far := cam.global_position.distance_to(m.global_position) if cam else 30.0
    var score := m._height() * 2.0 - far * 0.08 + (3.0 if dying else 0.0) + (10.0 if bool(m.def.get("boss", false)) else 0.0)
    _vq.append([score, kind, m.global_position + Vector3(0, m._height() * 0.6, 0), float(VOICE_TRIM.get(kind, 0.0)) + (DEATH_DB if dying else 0.0)])

static func _voice_flush() -> void:
    var fr := Engine.get_process_frames()
    if fr == _vq_frame:
        return
    _vq_frame = fr
    if _vq.is_empty():
        return
    var best: Array = _vq[0]
    for c in _vq:
        if float(c[0]) > float(best[0]):
            best = c
    _vq.clear()
    var now := Time.get_ticks_msec()
    var kind := String(best[1])
    if now - _v_any < VOICE_GAP or now - int(_v_kind.get(kind, -100000)) < KIND_GAP:
        return
    _v_any = now
    _v_kind[kind] = now
    voiced[kind] = int(voiced.get(kind, 0)) + 1
    Sfx.at(kind, best[2], float(best[3]))

## a lord's arrival: its voice, loud, and the room falls quiet under it for a beat
static func roar(m: Monster) -> void:
    var kind := Bestiary.voice_of(m.def)
    if kind == "" or not m.is_inside_tree():
        return
    var now := Time.get_ticks_msec()
    _v_any = now + 1500
    _v_kind[kind] = now
    voiced[kind] = int(voiced.get(kind, 0)) + 1
    Sfx.at(kind, m.global_position + Vector3(0, m._height() * 0.6, 0), ROAR_DB + float(VOICE_TRIM.get(kind, 0.0)))
