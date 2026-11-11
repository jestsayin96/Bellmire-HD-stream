extends MeshInstance3D
class_name HealthBar3D
## A health bar over a head (NEW - no old interface). One camera-facing quad,
## one shared shader. Shown while its owner is fighting, or whenever they are
## below full health; hidden otherwise.

static var _mat: ShaderMaterial
static var _all: Array = []      # every live bar, for staggering tight crowds
const STACK_R := 0.9             # owners closer than this (flat) share a column
const STACK_STEP := 0.21         # each bar above the next in a tight party
var engaged_until := 0.0
var _frac := 1.0
var base_h := 2.05
var lift := 0.0
var _stack_t := 0.0

static func on(owner_node: Node3D, height: float, hostile := false) -> HealthBar3D:
    var hb: HealthBar3D = owner_node.get_node_or_null("hpbar")
    if hb == null:
        hb = HealthBar3D.new()
        hb.name = "hpbar"
        var q := QuadMesh.new()
        q.size = Vector2(1.15, 0.17) if not hostile or height < 2.6 else Vector2(1.9, 0.24)
        hb.mesh = q
        if _mat == null:
            _mat = ShaderMaterial.new()
            _mat.shader = load("res://assets/shaders/healthbar.gdshader")
            _mat.render_priority = 10
        hb.material_override = _mat
        hb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        owner_node.add_child(hb)
        hb.set_instance_shader_parameter("hostile", 1.0 if hostile else 0.0)
        hb.visible = false
    # never higher than the first height asked for: an owner whose height is
    # measured from its meshes counts this bar too - asking for height + 0.25
    # every frame walked the bar (and anything aimed at it) up into the sky
    hb.base_h = minf(hb.base_h, height) if hb.has_meta("hb_set") else height
    hb.set_meta("hb_set", true)
    hb.position = Vector3(0, hb.base_h + hb.lift, 0)
    return hb

func _exit_tree() -> void:
    _all.erase(self)

func _enter_tree() -> void:
    if not _all.has(self):
        _all.append(self)

## tight parties: bars whose owners stand within STACK_R of each other step
## up one above the next (lower instance id lowest), so none hides another
func _restack() -> void:
    var me := get_parent() as Node3D
    if me == null:
        return
    var p := me.global_position
    var k := 0
    var my_id := get_instance_id()
    for o in _all:
        if o == self or not is_instance_valid(o) or not (o as HealthBar3D).visible:
            continue
        if (o as HealthBar3D).get_instance_id() > my_id:
            continue
        var op := ((o as Node).get_parent() as Node3D)
        if op == null:
            continue
        var q := op.global_position
        if absf(q.y - p.y) < 3.0 and Vector2(q.x - p.x, q.z - p.z).length() < STACK_R:
            k += 1
    lift = minf(float(k), 4.0) * STACK_STEP
    position = Vector3(0, base_h + lift, 0)

## hp / max now; `fighting` keeps the bar up for a few seconds after a blow
func set_hp(hp: float, mx: float, fighting := false) -> void:
    var now := Time.get_ticks_msec() / 1000.0
    if fighting:
        engaged_until = now + 4.0
    var f := clampf(hp / maxf(mx, 0.001), 0.0, 1.0)
    if not is_equal_approx(f, _frac):
        _frac = f
        set_instance_shader_parameter("fill", f)
    visible = hp > 0.0 and (f < 0.999 or now < engaged_until)
    if visible and now >= _stack_t:
        _stack_t = now + 0.25
        _restack()
