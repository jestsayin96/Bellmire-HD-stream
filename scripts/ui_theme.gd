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
	sb.bg_color = PARCHMENT
	sb.border_color = EDGE
	sb.set_border_width_all(border)
	sb.set_corner_radius_all(RADIUS)
	sb.content_margin_left = px(18)
	sb.content_margin_right = px(18)
	sb.content_margin_top = px(10)
	sb.content_margin_bottom = px(12)
	sb.shadow_color = SHADOW
	sb.shadow_size = SHADOW_SIZE
	return sb

## ---- L16: one theme for every panel - parchment and ink, the JestSayin teal as
## the one accent (title rules, the diamond before a title, focus, the timer).
## Text sizes: TITLE / BODY / SMALL, in 1080p pixels.
const PARCH := PARCHMENT
const INK := Color(0.16, 0.10, 0.06)
const INK_SOFT := Color(0.38, 0.28, 0.19)
const INK_RED := Color(0.48, 0.20, 0.12)
const EDGE := Color(0.45, 0.30, 0.16, 0.95)
const TEAL := Color(0.10, 0.62, 0.62)   # the accent fill (rules, gems)
const VIEWER := Color(0.47, 0.30, 0.02)      # a viewer's name on parchment (deep gold)
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

## ---- L65.1 TOKENS: the design system. Every value is named once, here; the HUD
## files read these and carry no literal colour, size or radius of their own.
## Sizes are 1080p pixels (run them through px()).
## TYPE SCALE (named roles). Floor: nothing a viewer must read is under T_CAPTION.
const T_WORDMARK := 46     # the Chronicle wordmark / a spotlight card title (Gloock)
const T_SECTION := 30      # a panel title
const T_BODY := 26         # body copy on a panel
const T_CHRONICLE := 21    # Chronicle body (Mr. E approved, L61)
const T_CAPTION := 17      # smallest legible string on stream (world-space chip text)
const T_NUMERAL := 28      # scores, counts, timers
## SPACING step (1080p px): gaps are multiples of this
const SP := 6
const SP_2 := 12
const SP_3 := 18
## SURFACES. PARCHMENT is the one light value; PLATE is the one dark value.
const PARCHMENT := Color(0.93, 0.86, 0.69, 0.93)
const PARCHMENT_SOLID := Color(0.93, 0.86, 0.69, 1.0)
const PLATE := Color(0.10, 0.07, 0.06, 0.94)
const PLATE_SOLID := Color(0.10, 0.07, 0.06, 1.0)
## INK pairs. ON PARCHMENT: INK / INK_SOFT / INK_RED / VIEWER / GOOD / BAD. ON DARK: ON_DARK*.
const ON_DARK := Color(0.93, 0.86, 0.69)        # parchment-coloured text on PLATE
const ON_DARK_SOFT := Color(0.74, 0.66, 0.50)
const ON_DARK_SHADOW := Color(0.0, 0.0, 0.0)
const GOOD := Color(0.10, 0.39, 0.16)
const BAD := Color(0.60, 0.14, 0.10)
## TEAL (the one accent) and GOLD, each with an on-parchment and an on-dark value.
const TEAL_ON_PARCH := Color(0.05, 0.38, 0.38)
const TEAL_ON_DARK := Color(0.30, 0.78, 0.76)
const GOLD_ON_PARCH := Color(0.47, 0.30, 0.02)
const GOLD_ON_DARK := Color(0.78, 0.62, 0.30)
## ---- U56: uncommon takes art's RARITY_HUE_PARCHMENT pewter (the interface variant; every other rung is canonical).
## ---- U55 (System 2, HUD half): the rarity hue ladder. SOURCE OF TRUTH is art's icons.RARITY_HUE
## (tools/art/icons.py:659) - never re-chosen here. EIGHT rungs, FIVE carry a hue; junk / starting /
## common are BARE on purpose and a piece with no stored rarity gets none (no cost-quartile guess).
const RARITY_HUE := {
	"uncommon": Color(0.62, 0.66, 0.72),    # cool pewter - art's RARITY_HUE_PARCHMENT (icons.py:691); pure white is paper on parchment
	"rare": Color(0.30, 0.55, 1.00),        # blue
	"very rare": Color(0.70, 0.35, 1.00),   # purple
	"legendary": Color(1.00, 0.55, 0.12),   # tangerine
	"artifact": Color(1.00, 0.13, 0.10),    # bright red
}
## the same four hued rungs darkened until a NAME reads on parchment (>= 4.5:1); uncommon stays ink
## and is carried by the pewter pip alone (pewter is too light to be text on cream)
const RARITY_INK := {
	"rare": Color(0.10, 0.28, 0.66),
	"very rare": Color(0.46, 0.14, 0.70),
	"legendary": Color(0.58, 0.24, 0.00),
	"artifact": Color(0.66, 0.07, 0.05),
}

## the art hue for a stored rarity, or a clear Color when the rung is bare / unknown
static func rarity_hue(rarity: String) -> Color:
	return RARITY_HUE.get(rarity.to_lower(), Color(0, 0, 0, 0))

## the parchment-safe text colour for a name of this rarity (INK when bare)
static func rarity_ink(rarity: String, fallback := INK) -> Color:
	return RARITY_INK.get(rarity.to_lower(), fallback)

## a round gem in the icon's own hue with a dark rim so white reads on cream; null when bare
static func rarity_pip(rarity: String, d := 14.0) -> Control:
	var hue := rarity_hue(rarity)
	if hue.a <= 0.0:
		return null
	var pip := Panel.new()
	pip.custom_minimum_size = Vector2(px(d), px(d))
	pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = hue
	sb.border_color = INK
	sb.set_border_width_all(maxi(1, px(2)))
	sb.set_corner_radius_all(px(d))
	pip.add_theme_stylebox_override("panel", sb)
	return pip

## BORDER and CORNER constants
const BORDER := 2
const BORDER_PANEL := 3
const RADIUS := 6
const EDGE_ON_DARK := Color(0.78, 0.62, 0.30)
## ELEVATION: one shadow
const SHADOW := Color(0, 0, 0, 0.4)
const SHADOW_SIZE := 6
## LEGIBILITY FLOOR (L65.4): min size and min contrast ratio vs the real backdrop
const FLOOR_PX := 17
const FLOOR_CONTRAST := 4.5

## SCROLL palette (the Chronicle's vellum, wood and brass) and effect inks
const SCROLL_CREAM := Color(0.960, 0.910, 0.770)
const SCROLL_TAN := Color(0.865, 0.760, 0.555)
const SCROLL_TAN_DK := Color(0.660, 0.520, 0.330)
const SCROLL_WOOD_LT := Color(0.560, 0.405, 0.235)
const SCROLL_WOOD_DK := Color(0.250, 0.160, 0.085)
const SCROLL_BRASS := Color(0.780, 0.635, 0.340)
const SCROLL_BRASS_DK := Color(0.360, 0.275, 0.130)
const SCROLL_GOLD := Color(0.840, 0.670, 0.310)
const SCROLL_BURN := Color(0.190, 0.110, 0.065)
const SCROLL_GRAIN := Color(0.68, 0.52, 0.31, 0.55)
const SCROLL_GRAIN_HI := Color(1, 1, 1, 0.04)
const SCROLL_GRAIN_OFF := 0.75   # U61: rod grain stripe sits this many caps BELOW the rod centre (was -0.5 = through the wordmark at the px(8) cap floor; clears the wordmark ink, measured in tools/_u61_stripe.gd)
const SCROLL_STAIN := Color(0.55, 0.40, 0.22, 0.05)
const SCROLL_STAIN_2 := Color(0.48, 0.34, 0.18, 0.05)
const SCROLL_RULE := Color(0.16, 0.10, 0.05, 0.85)
const SCROLL_EDGE_SHADE := Color(0.22, 0.14, 0.07, 0.34)   # L65.4: was 0.5 - it dragged the first and last Chronicle line under 4.5:1
const SCROLL_SHEET_SHADOW := Color(0, 0, 0, 0.30)
const SCROLL_GLINT := Color(0.97, 0.90, 0.64, 0.75)
const SCROLL_SEAL := Color(0.06, 0.40, 0.40)
const SCROLL_SEAL_PIP := Color(0.97, 0.85, 0.48)
const WORD_HI := Color(1.0, 0.96, 0.80)   # U60: was (0.97,0.88,0.62) = 3.87:1 on the rod's lightest wood (SCROLL_WOOD_LT); this is 4.58:1
const WORD_SHADOW := Color(0.08, 0.04, 0.02, 0.95)
const AURA_DEFAULT := Color(1, 0.8, 0.4)
const WHITE := Color(1, 1, 1)
const ON_KIND := Color(1, 0.98, 0.92)
const TAG_GOLD := Color(1.0, 0.86, 0.40)
const TAG_OUTLINE := Color(0, 0, 0, 0.95)
const CHIP_RADIUS := 3
## spotlight / director subject colours, one per kind
const KIND := {"bits": Color(0.95, 0.72, 0.18), "subs": Color(0.62, 0.36, 0.92), "points": Color(0.20, 0.72, 0.70), "director": Color(0.16, 0.10, 0.06), "wide": Color(0.38, 0.28, 0.19)}

## U217 (Mr. E / supervisor 27 Nov, TOWN FIRST): the town's level and its movement toward the next tier.
## PURE: takes Economy.TOWN_LEVELS ([{at,name}...]) and the town score, returns what the Chronicle's town
## band draws. level is 1-based; frac is 0..1 through the CURRENT tier (1.0 and maxed at the top tier);
## to_next is the score still needed (0 when maxed). No scene access, so a gate can call it with a table.
static func town_progress(levels: Array, score: int) -> Dictionary:
	var n := levels.size()
	if n == 0:
		return {}
	var lv := 1
	for i in n:
		if score >= int((levels[i] as Dictionary).get("at", 0)):
			lv = i + 1
	var at_cur := int((levels[lv - 1] as Dictionary).get("at", 0))
	var maxed := lv >= n
	var at_next := at_cur if maxed else int((levels[lv] as Dictionary).get("at", at_cur))
	var span := maxi(1, at_next - at_cur)
	var frac := 1.0 if maxed else clampf(float(score - at_cur) / float(span), 0.0, 1.0)
	return {"level": lv, "tiers": n, "name": String((levels[lv - 1] as Dictionary).get("name", "")), "score": score,
		"at_cur": at_cur, "at_next": at_next, "frac": frac, "maxed": maxed,
		"to_next": 0 if maxed else maxi(0, at_next - score)}

## L65.2 CHROME: the one panel frame. kind: "parch" (light) or "plate" (dark).
static func frame(kind := "parch", margin_h := SP_3, margin_v := SP_2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	var dark := kind == "plate"
	sb.bg_color = PLATE if dark else PARCHMENT
	sb.border_color = EDGE_ON_DARK if dark else EDGE
	sb.set_border_width_all(BORDER if dark else BORDER_PANEL)
	sb.set_corner_radius_all(RADIUS)
	sb.content_margin_left = px(margin_h)
	sb.content_margin_right = px(margin_h)
	sb.content_margin_top = px(margin_v * 0.8)
	sb.content_margin_bottom = px(margin_v)
	sb.shadow_color = SHADOW
	sb.shadow_size = SHADOW_SIZE
	return sb

## the header (diamond + title + teal rule) is title(); the divider and the empty state:
static func divider(col := INK_SOFT) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(col.r, col.g, col.b, 0.45)
	r.custom_minimum_size = Vector2(0, maxi(1, px(1)))
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

static func empty_state(text: String, col := INK_SOFT) -> Label:
	var lb := label(text, T_BODY * 0.85, col)
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lb

## WCAG contrast ratio of two opaque colours (used by the legibility audit, L65.4)
static func contrast(a: Color, b: Color) -> float:
	var la := _lum(a)
	var lb := _lum(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)

static func _lum(c: Color) -> float:
	var f := func(v: float) -> float:
		return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)

## L65.4: the fill behind light text on a kind-coloured chip. Darkens the kind colour until
## `fg` reads at `ratio`:1 against it, so a gold BITS chip can never wash its own label out.
static func chip_bg(col: Color, a := 0.95, fg := ON_KIND, ratio := 6.0) -> Color:
	var c := Color(col.r * 0.72, col.g * 0.72, col.b * 0.72, 1.0)
	var guard := 0
	while contrast(fg, c) < ratio and guard < 24:
		c = Color(c.r * 0.88, c.g * 0.88, c.b * 0.88, 1.0)
		guard += 1
	return Color(c.r, c.g, c.b, a)

## ---- L16 (phone test): speech in the world - a townsperson's bubble, the crier.
## Same house as the Chronicle: ink on parchment, a plate behind the words so they
## never sit on the ground, and a FIXED on-screen size (~28 px at 1080p at any
## distance). Call style_bubble once on the Label3D, fit_plate after each text.
const BUBBLE_PX := 0.00085        # Label3D.fixed_size pixel_size: ~28 px glyphs at 1080p
static func style_bubble(lb: Label3D) -> void:
	lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lb.fixed_size = true
	lb.no_depth_test = true
	lb.font_size = 32
	lb.pixel_size = BUBBLE_PX * scale
	lb.outline_size = 6
	lb.outline_modulate = Color(PARCH.r, PARCH.g, PARCH.b, 1.0)
	lb.modulate = INK
	lb.render_priority = 12
	lb.width = 520.0
	lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

static func fit_plate(lb: Label3D) -> void:
	var plate := lb.get_node_or_null("plate") as MeshInstance3D
	if plate == null:
		plate = MeshInstance3D.new()
		plate.name = "plate"
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.fixed_size = true
		m.no_depth_test = true
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(PARCH.r, PARCH.g, PARCH.b, 0.94)
		m.render_priority = 11
		plate.material_override = m
		plate.mesh = QuadMesh.new()
		lb.add_child(plate)
	var font: Font = lb.font if lb.font else ThemeDB.fallback_font
	var sz := font.get_multiline_string_size(lb.text, HORIZONTAL_ALIGNMENT_CENTER, lb.width, lb.font_size)
	var pad := Vector2(28, 16)
	(plate.mesh as QuadMesh).size = (sz + pad) * lb.pixel_size
	plate.visible = lb.visible and lb.text != ""
