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

## ---- L16: one theme for every panel - parchment and ink, the JestSayin teal as
## the one accent (title rules, the diamond before a title, focus, the timer).
## Text sizes: TITLE / BODY / SMALL, in 1080p pixels.
const PARCH := Color(0.93, 0.86, 0.69, 0.93)
const INK := Color(0.16, 0.10, 0.06)
const INK_SOFT := Color(0.38, 0.28, 0.19)
const INK_RED := Color(0.48, 0.20, 0.12)
const EDGE := Color(0.45, 0.30, 0.16, 0.95)
const TEAL := Color(0.10, 0.62, 0.62)
const VIEWER := Color(0.55, 0.35, 0.02)      # a viewer's name on parchment (deep gold)
const BAND := Color(0.24, 0.27, 0.34)        # the town's own band (slate)
const TITLE := 30
const BODY := 26
const SMALL := 22

static func label(text: String, size: float, col := INK) -> Label:
	var lb := Label.new()
	lb.text = text
	lb.add_theme_font_size_override("font_size", px(size))
	lb.add_theme_color_override("font_color", col)
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lb

## a panel title: a small teal diamond, the words in red-brown ink, a teal rule under
static func title(text: String, size := TITLE) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", px(2))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", px(8))
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var d := Control.new()
	d.custom_minimum_size = Vector2(px(size * 0.42), px(size * 0.9))
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gem := ColorRect.new()
	gem.color = TEAL
	gem.size = Vector2(px(size * 0.3), px(size * 0.3))
	gem.position = Vector2(px(size * 0.06), px(size * 0.32))
	gem.pivot_offset = gem.size * 0.5
	gem.rotation = PI * 0.25
	gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.add_child(gem)
	h.add_child(d)
	var lb := label(text, size, INK_RED)
	lb.name = "text"
	h.add_child(lb)
	v.add_child(h)
	var rule := ColorRect.new()
	rule.color = Color(TEAL.r, TEAL.g, TEAL.b, 0.85)
	rule.custom_minimum_size = Vector2(0, maxi(2, px(2)))
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(rule)
	return v

## an HP bar in the house style: ink-edged, filled green / amber / red by how full
static func bar(value: float, maxv: float, h := 30.0) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.max_value = maxf(1.0, maxv)
	b.value = clampf(value, 0.0, b.max_value)
	b.custom_minimum_size = Vector2(0, px(h))
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.30, 0.12, 0.09, 0.92)
	bg.border_color = INK
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(3)
	var k := b.value / b.max_value
	var fg := StyleBoxFlat.new()
	fg.bg_color = Color(0.22, 0.62, 0.24) if k > 0.5 else (Color(0.82, 0.60, 0.14) if k > 0.25 else Color(0.80, 0.18, 0.12))
	fg.set_corner_radius_all(2)
	fg.border_color = Color(0, 0, 0, 0)
	fg.set_border_width_all(2)
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	return b

## a small parchment chip (the key help, the speed, the chat box)
static func chip() -> StyleBoxFlat:
	var sb := parchment(2)
	sb.content_margin_left = px(12)
	sb.content_margin_right = px(12)
	sb.content_margin_top = px(6)
	sb.content_margin_bottom = px(6)
	sb.shadow_size = 3
	return sb
