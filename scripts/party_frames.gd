extends VBoxContainer
class_name PartyFrames
## WoW-style party frames for the delves running below: a compact column on the
## left edge, above the Chronicle. One block per delve - the floor they are on
## and the party's oil - then each delver: name, HP bar. Viewers' heroes gold,
## the town's own band silver, the fallen greyed with a cross. Lives in the
## RtsCamera's layer, so F10 hides it with the rest of the interface.

const W := 250
const GOLD := Color(1.0, 0.84, 0.36)
const SILVER := Color(0.82, 0.84, 0.88)
const DEAD := Color(0.55, 0.52, 0.50)
const MAX_ROWS := 8          # per delve; more than that folds into "+N more"

var town: Node3D
var _t := 0.0

func setup(t: Node3D) -> void:
	town = t
	anchor_left = 0.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = 18
	offset_bottom = -300
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	custom_minimum_size = Vector2(W, 0)
	add_theme_constant_override("separation", 6)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	refresh()

func _process(delta: float) -> void:
	_t -= delta / maxf(Engine.time_scale, 0.001)     # real time, like the camera
	if _t <= 0.0:
		_t = 0.4
		refresh()

func delves() -> Array:
	var out: Array = []
	if town == null:
		return out
	for c in town.get_children():
		if c is Delve and not (c as Delve).party.is_empty() and (c as Delve).dun != null and is_instance_valid((c as Delve).dun):
			out.append(c)
	return out

func refresh() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var ds := delves()
	visible = not ds.is_empty()
	for d: Delve in ds:
		add_child(_block(d))

func _style(col: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	return sb

func _label(text: String, col: Color, size: int) -> Label:
	var lb := Label.new()
	lb.text = text
	lb.clip_text = true
	lb.add_theme_font_size_override("font_size", size)
	lb.add_theme_color_override("font_color", col)
	lb.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lb.add_theme_constant_override("outline_size", 4)
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lb

func _block(d: Delve) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := _style(Color(0.06, 0.06, 0.08, 0.80), Color(0.78, 0.62, 0.30))
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 5
	sb.content_margin_bottom = 7
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	p.add_child(v)
	# header: which floor, and the oil they carry (it is their light)
	var head := HBoxContainer.new()
	v.add_child(head)
	var who := "The town's band" if d.npc_party else "Delvers"
	var t := _label("%s · floor %d" % [who, d.floor_no], Color(0.95, 0.80, 0.50), 14)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var oil_col := Color(1.0, 0.45, 0.30) if d.dark or d.oil < 1.0 else (Color(1.0, 0.75, 0.35) if d.oil <= float(d._alive().size()) else Color(0.95, 0.88, 0.60))
	var oil := _label(("oil %.1f" % d.oil) if d.oil > 0.0 else "no oil - dark", oil_col, 14)
	oil.clip_text = false
	head.add_child(oil)
	var shown := 0
	for m: Dictionary in d.party:
		if shown >= MAX_ROWS:
			break
		v.add_child(_row(m, d.npc_party, d))
		shown += 1
	if d.party.size() > MAX_ROWS:
		v.add_child(_label("+%d more" % (d.party.size() - MAX_ROWS), SILVER, 12))
	return p

func _row(m: Dictionary, npc: bool, d: Delve = null) -> Control:
	var h: Dictionary = m.get("h", {})
	var hp := maxf(0.0, float(m.get("hp", 0.0)))
	var mx := maxf(1.0, float(m.get("max", 1.0)))
	var alive := hp > 0.0
	var box := Control.new()
	box.custom_minimum_size = Vector2(W - 16, 20)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar.max_value = mx
	bar.value = hp
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var k := hp / mx
	var fill := Color(0.20, 0.72, 0.25) if k > 0.5 else (Color(0.85, 0.65, 0.15) if k > 0.25 else Color(0.85, 0.18, 0.12))
	bar.add_theme_stylebox_override("background", _style(Color(0.18, 0.05, 0.05, 0.9), Color(0, 0, 0, 0.8)))
	bar.add_theme_stylebox_override("fill", _style(fill, Color(0, 0, 0, 0.0)))
	box.add_child(bar)
	var name_col := (SILVER if npc else GOLD) if alive else DEAD
	var nm := _label(("%s" if alive else "+ %s") % String(h.get("name", "?")), name_col, 13)
	nm.set_anchors_preset(Control.PRESET_FULL_RECT)
	nm.offset_left = 5
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(nm)
	var num := _label("%d/%d" % [int(ceil(hp)), int(mx)] if alive else "fallen", Color(0.95, 0.95, 0.95) if alive else DEAD, 12)
	num.set_anchors_preset(Control.PRESET_FULL_RECT)
	num.offset_right = -5
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(num)
	# L12: the delver's states, coloured, under the bar
	var sts: Array = d.statuses(m) if d and alive else []
	if sts.is_empty():
		return box
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(box)
	var tags := HBoxContainer.new()
	tags.add_theme_constant_override("separation", 6)
	tags.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for s in sts:
		var tl := _label(String(s[0]), s[1], 12)
		tl.clip_text = false
		tags.add_child(tl)
	col.add_child(tags)
	return col
