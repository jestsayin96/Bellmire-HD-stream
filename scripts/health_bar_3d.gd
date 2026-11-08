extends MeshInstance3D
class_name HealthBar3D
## A health bar over a head (NEW - no old interface). One camera-facing quad,
## one shared shader. Shown while its owner is fighting, or whenever they are
## below full health; hidden otherwise.

static var _mat: ShaderMaterial
var engaged_until := 0.0
var _frac := 1.0

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
    hb.position = Vector3(0, height, 0)
    return hb

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
