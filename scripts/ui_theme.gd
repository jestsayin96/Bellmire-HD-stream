class_name UiTheme
extends RefCounted
## L15: one place for interface sizes, so the stream reads on a phone.
## Sizes are written for a 1920x1080 frame and follow the real window height
## (a 900p window gets 5/6 of them). F11 cycles a UI scale of 100/125/150% on
## top. Anything a viewer must read is at least ~28 px at 1080p at 100%.
## Panels call watch(self) and get restyle() called when the scale changes.

const STEPS := [1.0, 1.25, 1.5]
static var scale := 1.0
static var _watch: Array = []

## a size in 1080p pixels -> pixels on this window at this UI scale
static func px(n: float) -> int:
	return int(round(n * scale * res_k()))

static func res_k() -> float:
	var ml := Engine.get_main_loop()
	if ml is SceneTree and (ml as SceneTree).root:
		return clampf(float((ml as SceneTree).root.size.y) / 1080.0, 0.5, 2.0)
	return 1.0

static func watch(n: Object) -> void:
	if not _watch.has(n):
		_watch.append(n)

## F11: the next UI scale; every watched panel restyles
static func cycle() -> float:
	var i := STEPS.find(scale)
	set_scale(float(STEPS[(i + 1) % STEPS.size()]))
	return scale

static func set_scale(s: float) -> void:
	scale = s
	var live: Array = []
	for n in _watch:
		if is_instance_valid(n):
			live.append(n)
			if n.has_method("restyle"):
				n.restyle()
	_watch = live

## the parchment every panel shares (L16 builds the theme on this)
static func parchment(border := 3) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.93, 0.86, 0.69, 0.92)
	sb.border_color = Color(0.45, 0.30, 0.16, 0.95)
	sb.set_border_width_all(border)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = px(18)
	sb.content_margin_right = px(18)
	sb.content_margin_top = px(10)
	sb.content_margin_bottom = px(12)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 6
	return sb
