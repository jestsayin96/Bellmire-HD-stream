extends VBoxContainer
class_name BossBar
## WoW-style boss bar: top centre, only while a floor's lord is up and fighting.
## The lord's name in its own colour, one wide HP bar, the floor beneath it.
## Lives in the RtsCamera's layer, so F10 hides it with the rest. With two
## delves below, a viewers' party's lord comes first.

const W := 780          # L15: at 1080p; UiTheme.px scales it

var town: Node3D
var lord: Monster = null
var delve: Delve = null
var _t := 0.0
var _title: Label
var _bar: ProgressBar
var _fill: StyleBoxFlat
var _num: Label
var _sub: Label

func setup(t: Node3D) -> void:
	town = t
	UiTheme.watch(self)
	# the bar keeps its 100% width at any UI scale (only its text grows): it must clear the side panels
	var w := int(round(float(W) * UiTheme.res_k()))
	anchor_left = 0.5
	anchor_right = 0.5
	offset_left = -w / 2
	offset_right = w / 2
	offset_top = UiTheme.px(140)          # under the key help (H), clear of it
	custom_minimum_size = Vector2(w, 0)
	add_theme_constant_override("separation", 2)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title = _label("", Color(1, 0.85, 0.5), 44)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title)
	var box := Control.new()
	box.custom_minimum_size = Vector2(w, UiTheme.px(36))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.04, 0.04, 0.88)
	bg.border_color = Color(0.78, 0.62, 0.30)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(4)
	_bar.add_theme_stylebox_override("background", bg)
	_fill = StyleBoxFlat.new()
	_fill.bg_color = Color(0.75, 0.15, 0.10)
	_fill.set_corner_radius_all(3)
	_fill.border_color = Color(0, 0, 0, 0)
	_fill.set_border_width_all(2)
	_bar.add_theme_stylebox_override("fill", _fill)
	box.add_child(_bar)
	_num = _label("", Color(1, 1, 1), 26)
	_num.set_anchors_preset(Control.PRESET_FULL_RECT)
	_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(_num)
	_sub = _label("", Color(0.93, 0.86, 0.69), 26)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_sub)
	refresh()

## L15: F11 changed the UI scale - build again
func restyle() -> void:
	for c in get_children():
		c.free()
	setup(town)

func _label(text: String, col: Color, size: int) -> Label:
	var lb := Label.new()
	lb.text = text
	lb.add_theme_font_size_override("font_size", UiTheme.px(size))
	lb.add_theme_color_override("font_color", col)
	lb.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lb.add_theme_constant_override("outline_size", UiTheme.px(7))
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lb

func _process(delta: float) -> void:
	_t -= delta / maxf(Engine.time_scale, 0.001)     # real time, like the camera
	if _t <= 0.0:
		_t = 0.15
		refresh()

## the lord to show: a viewers' party's first, then the town's band's
func find_lord() -> Array:
	if town == null:
		return []
	var best: Array = []
	for c in town.get_children():
		if not (c is Delve):
			continue
		var l: Monster = (c as Delve).lord_fighting()
		if l == null:
			continue
		if best.is_empty() or (bool((best[0] as Delve).npc_party) and not (c as Delve).npc_party):
			best = [c, l]
	return best

func refresh() -> void:
	var f := find_lord()
	visible = not f.is_empty()
	if f.is_empty():
		lord = null
		delve = null
		return
	delve = f[0]
	lord = f[1]
	var col: Color = lord.def.get("aura", Color(1, 0.8, 0.4))
	_title.text = String(lord.def.get("name", "A lord"))
	_title.add_theme_color_override("font_color", col.lightened(0.35))
	_fill.bg_color = Color(0.72, 0.12, 0.08).lerp(col, 0.18)     # blood red, a hint of its own colour
	_fill.border_color = col.darkened(0.2)
	_bar.max_value = maxf(1.0, lord.max_hp)
	_bar.value = clampf(lord.hp, 0.0, lord.max_hp)
	_num.text = "%d / %d" % [int(ceil(maxf(lord.hp, 0.0))), int(lord.max_hp)]
	var who := "the town's band" if delve.npc_party else "the delvers"
	var rare := bool(lord.def.get("unique", false)) or bool(lord.def.get("rare", false)) or String(lord.def.get("kind", "")) == "unique"
	var what := "A rare one, met on floor %d" % delve.floor_no if rare else "Lord of floor %d" % delve.floor_no
	_sub.text = "%s  ·  against %s (%d standing)" % [what, who, delve._alive().size()]
