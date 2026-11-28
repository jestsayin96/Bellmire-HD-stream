extends VBoxContainer
class_name PartyFrames
const StatusIconScript := preload("res://scripts/status_icon.gd")
## WoW-style party frames for the delves running below: a compact column at the
## top-left under the key help. One parchment block per delve (L16: the house
## theme) - the floor they are on and the party's oil - then each delver: name,
## the numbers, an inked HP bar, their states. Viewers' heroes in deep gold, the
## town's own band in slate, the fallen greyed with a cross. Lives in the
## RtsCamera's layer, so F10 hides it with the rest of the interface.

const W := 400          # L15: at 1080p; UiTheme.px scales it
const DEAD := Color(0.45, 0.38, 0.32)
const ON_STREAM := false      # D46: the multi-member band board no longer draws on stream (hub: Bands below)
const MAX_ROWS := Roster.PARTY_CAP   # S168: per delve, read off the party cap (10) so the two never drift; more folds into "+N more"

var town: Node3D
var _t := 0.0

func setup(t: Node3D) -> void:
	town = t
	UiTheme.watch(self)
	_place()
	add_theme_constant_override("separation", UiTheme.px(8))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	refresh()

## L15: top-left, under the key help (the Chronicle owns the bottom-left)
func _place() -> void:
	HudDock.unput(self)
	anchor_left = 0.0
	anchor_right = 0.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = UiTheme.px(18)
	offset_top = UiTheme.px(150)
	offset_right = offset_left + UiTheme.px(W)
	offset_bottom = offset_top
	grow_vertical = Control.GROW_DIRECTION_END
	custom_minimum_size = Vector2(UiTheme.px(W), 0)

func restyle() -> void:
	_place()
	add_theme_constant_override("separation", UiTheme.px(8))
	refresh()

func _process(delta: float) -> void:
	_t -= delta / maxf(Engine.time_scale, 0.001)     # real time, like the camera
	var sp := HudDock.split(town)
	if _t <= 0.0 or sp != _split:
		_t = 0.4
		refresh()
	if sp and ON_STREAM:
		_dock()

## ---- L21: with the spotlight panes up, each party's block docks at the bottom-left INSIDE
## the pane following that party (the director when it is down there, else a lane on one of
## them), scaled to the pane. A party no pane shows is not drawn. A second pane's parties go
## in a second column (_extra), so nothing ever spans a seam.
var _split := false
var _groups := {}          # pane -> [Delve]
var _extra := {}           # pane -> VBoxContainer (the columns after the first)
var _first := ""           # the pane this column itself sits in

func _dock() -> void:
	HudDock.mark(self, _first if _first != "" else "none")
	for k in _extra:
		HudDock.mark(_extra[k], k)
	if _first != "":
		HudDock.put(self, HudDock.pane(town, _first), HudDock.pane_k(town, _first), "bl")
	for k in _extra:
		var col: VBoxContainer = _extra[k]
		if is_instance_valid(col):
			HudDock.put(col, HudDock.pane(town, k), HudDock.pane_k(town, k), "bl")

func _clear_extra() -> void:
	for k in _extra:
		if is_instance_valid(_extra[k]):
			(_extra[k] as Node).queue_free()
	_extra.clear()

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
	if not ON_STREAM:                  # D46: the band board is off the stream; the hub carries it now
		visible = false
		_clear_extra()
		return
	var ds := delves()
	var sp := HudDock.split(town)
	if sp != _split:
		_split = sp
		if not sp:
			_place()
	_clear_extra()
	_first = ""
	if sp:
		_groups.clear()
		for d: Delve in ds:
			var k := HudDock.pane_for_delve(town, d)
			if k != "":
				if not _groups.has(k):
					_groups[k] = []
				(_groups[k] as Array).append(d)
		for k in _groups:
			if _first == "":
				_first = k
				for d: Delve in _groups[k]:
					add_child(_block(d))
			else:
				var col := VBoxContainer.new()
				col.add_theme_constant_override("separation", UiTheme.px(8))
				col.mouse_filter = Control.MOUSE_FILTER_IGNORE
				col.custom_minimum_size = Vector2(UiTheme.px(W), 0)
				get_parent().add_child(col)
				for d: Delve in _groups[k]:
					col.add_child(_block(d))
				_extra[k] = col
		visible = _first != ""
		_dock()
		return
	visible = not ds.is_empty()
	for d: Delve in ds:
		add_child(_block(d))

func _block(d: Delve) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := UiTheme.parchment()
	sb.content_margin_left = UiTheme.px(12)
	sb.content_margin_right = UiTheme.px(12)
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UiTheme.px(4))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	# header: which floor, and the oil they carry (it is their light)
	p.add_to_group("hud_party")          # L21: the test finds each party block by group + its delve
	p.set_meta("delve", d)
	var who := "The town's band" if d.npc_party else "Delvers"
	v.add_child(UiTheme.title("%s · floor %d" % [who, d.floor_no], 24))
	var oil_col := UiTheme.INK_RED if d.dark or d.oil < 1.0 else (Color(0.62, 0.38, 0.05) if d.oil <= float(d._alive().size()) else UiTheme.INK_SOFT)
	v.add_child(UiTheme.label(("oil %.1f flasks" % d.oil) if d.oil > 0.0 else "no oil - the dark", UiTheme.SMALL, oil_col))
	var shown := 0
	for m: Dictionary in d.party:
		if shown >= MAX_ROWS:
			break
		v.add_child(_row(m, d.npc_party, d))
		shown += 1
	if d.party.size() > MAX_ROWS:
		v.add_child(UiTheme.label("+%d more" % (d.party.size() - MAX_ROWS), UiTheme.SMALL, UiTheme.INK_SOFT))
	return p

func _row(m: Dictionary, npc: bool, d: Delve = null) -> Control:
	var h: Dictionary = m.get("h", {})
	var hp := maxf(0.0, float(m.get("hp", 0.0)))
	var mx := maxf(1.0, float(m.get("max", 1.0)))
	var alive := hp > 0.0
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UiTheme.px(1))
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# the name and the numbers ride on the inked bar itself: one compact row a delver
	var box := Control.new()
	box.custom_minimum_size = Vector2(UiTheme.px(W - 24), UiTheme.px(36))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var b := UiTheme.bar(hp if alive else 0.0, mx, 36)
	b.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.add_child(b)
	var name_col := (Color(0.80, 0.86, 1.0) if npc else Color(1.0, 0.86, 0.40)) if alive else Color(0.75, 0.70, 0.66)
	var nm := UiTheme.label(("%s" if alive else "+ %s") % String(h.get("name", "?")), 26, name_col)
	nm.add_theme_color_override("font_outline_color", UiTheme.INK)
	nm.add_theme_constant_override("outline_size", UiTheme.px(6))
	nm.clip_text = true
	nm.set_anchors_preset(Control.PRESET_FULL_RECT)
	nm.offset_left = UiTheme.px(8)
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(nm)
	var num := UiTheme.label("%d/%d" % [int(ceil(hp)), int(mx)] if alive else "fallen", UiTheme.SMALL, Color(1, 1, 1))
	num.add_theme_color_override("font_outline_color", UiTheme.INK)
	num.add_theme_constant_override("outline_size", UiTheme.px(5))
	num.set_anchors_preset(Control.PRESET_FULL_RECT)
	num.offset_right = -UiTheme.px(8)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(num)
	col.add_child(box)
	# L12: the delver's states, coloured, under the bar (at the largest UI scale the
	# states show under each hero only - room for the Chronicle)
	var sts: Array = d.statuses(m) if d and alive and UiTheme.scale < 1.4 else []
	if not sts.is_empty():
		# L31c: a FLOW, not a row - five states at ~690 px ran past the 400 px frame;
		# now they wrap inside the bar's own width and nothing is cut
		var tags := HFlowContainer.new()
		tags.add_theme_constant_override("h_separation", UiTheme.px(8))
		tags.add_theme_constant_override("v_separation", UiTheme.px(2))
		tags.custom_minimum_size.x = UiTheme.px(W - 24)
		tags.size_flags_horizontal = Control.SIZE_FILL
		tags.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for s in sts:
			# L31: the state's icon first (reads at stream distance), then its word.
			# The state colours are bright for the dark world; on parchment, darkened to read
			var chip := HBoxContainer.new()
			chip.add_theme_constant_override("separation", UiTheme.px(3))
			chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			chip.add_child(StatusIconScript.new().setup(String(s[2]) if s.size() > 2 else "", String(s[0]), s[1] as Color, bool(s[3]) if s.size() > 3 else false, UiTheme.px(22)))
			# S118 (L31 remainder a): the duration beside the word - m["st"] holds seconds
			var word := String(s[0])
			if s.size() > 4 and float(s[4]) > 0.0:
				word = "%s %ds" % [word, int(ceil(float(s[4])))]
			chip.add_child(UiTheme.label(word, UiTheme.SMALL, (s[1] as Color).darkened(0.45)))
			tags.add_child(chip)
		col.add_child(tags)
	return col
