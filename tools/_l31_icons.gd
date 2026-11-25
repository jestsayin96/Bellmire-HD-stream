extends SceneTree
## L31 remainder test: a real delve's party frames with every state in
## potions.json `states` forced onto the delvers, rendered at 1080p.
## Verdict: L31_ICONS OK n when every state shown has a StatusIcon with a non-empty key.
var _t: Node3D
var _eye: RtsCamera
var _f := 0
var _seen_at := -1
var _holder: Node
const OUT := "res://renders/cycles/l31"
func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
func _force(d: Delve) -> void:
	var keys: Array = Roster.potions().get("states", {}).keys()
	var i := 0
	for m in d.party:
		m["hp"] = maxf(float(m["hp"]), 1.0)
		m["st"] = {}
		for j in 5:
			if i < keys.size():
				var k := String(keys[i])
				if k == "poisoned":
					m["venom"] = 30.0
				elif k == "slowed":
					m["slow"] = 30.0
				else:
					m["st"][k] = 30.0
				i += 1
func _count(n: Node, acc: Array) -> void:
	if n.get_script() == preload("res://scripts/status_icon.gd"):
		acc.append(n)
	for c in n.get_children():
		_count(c, acc)
func _process(_d: float) -> bool:
	_f += 1
	# S119: the chip-fits-the-row arm is POSITIONAL, so a capture under 1080p cannot see what it audits (U157's trap) - red, never a quiet pass.
	if root.get_visible_rect().size.x < 1919 or root.get_visible_rect().size.y < 1079:
		print("L31_ICONS NO VERDICT - capture %s is smaller than 1920x1080; run --resolution 1920x1080" % str(root.get_visible_rect().size)); quit(2); return true
	if _f == 20:
		_eye = RtsCamera.new()
		_t.add_child(_eye)
		_eye.setup(_t)
		for u in ["1001", "1002", "1003"]:
			_t.chat_line(u, "Viewer" + u, "!enlist knight")
		for u in ["1001", "1002", "1003"]:
			_t.chat_line(u, "Viewer" + u, "!delve")
		Engine.time_scale = 8.0
	if _f > 20 and _seen_at < 0 and _eye.party_frames.delves().size() > 0:
		_seen_at = _f
		Engine.time_scale = 0.05
		_eye._cycle_delve()
	if _seen_at > 0 and _f - _seen_at == 30:
		var d: Delve = _eye.party_frames.delves()[0]
		_force(d)
		# the director's four-up hides the frames, so the REAL PartyFrames._row for
		# each delver is mounted on its own layer at 1080p, parchment behind it
		var cl := CanvasLayer.new()
		cl.layer = 100
		root.add_child(cl)
		var pc := PanelContainer.new()
		pc.add_theme_stylebox_override("panel", UiTheme.parchment())
		pc.position = Vector2(40, 40)
		cl.add_child(pc)
		var v := VBoxContainer.new()
		pc.add_child(v)
		for m in d.party:
			v.add_child(_eye.party_frames._row(m, false, d))
		_holder = cl
	if _seen_at > 0 and _f - _seen_at == 34:
		var d: Delve = _eye.party_frames.delves()[0]
		var want := 0
		for m in d.party:
			want += d.statuses(m).size()
		var icons: Array = []
		_count(_holder, icons)
		var keyed := 0
		var over := 0
		for ic in icons:
			if String(ic.key) != "" and ic.size.x > 4.0:
				keyed += 1
		# L31c: every chip must END inside its own row's bar width (W-24 at 1080p).
		# Each row's first child is the bar box; any chip whose right edge passes the
		# box's right edge is a word cut off in the live frame.
		for row in _holder.get_child(0).get_child(0).get_children():
			var bar: Control = row.get_child(0)
			# the bar's DESIGNED width, not its laid-out one: a VBox widens the bar to
			# its widest child, so size.x would grow with the overflow and never read red
			var lim := bar.global_position.x + bar.custom_minimum_size.x + 0.5
			if row.get_child_count() > 1:
				for chip in row.get_child(1).get_children():
					if (chip as Control).global_position.x + (chip as Control).size.x > lim:
						over += 1
		print("L31_FIT chips_past_bar=%d" % over)
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "/l31_icons_1080.png"))
		print("L31_ICONS party=%d states_wanted=%d icons=%d keyed_and_sized=%d" % [d.party.size(), want, icons.size(), keyed])
		print("L31_ICONS %s %d" % ["OK" if want > 0 and keyed == want and over == 0 else "FAIL", keyed])
		return true
	if _f > 9000:
		print("L31_ICONS FAIL timeout")
		return true
	return false
