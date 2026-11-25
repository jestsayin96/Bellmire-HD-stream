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
				# S132: DISTINCT seeds (40, 38, 36 ...), not a uniform 30 - a render where every
				# row reads 30s cannot show that the number belongs to the state
				var secs := 40.0 - 2.0 * i
				if k == "poisoned":
					m["venom"] = secs
				elif k == "slowed":
					m["slow"] = secs
				else:
					m["st"][k] = secs
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
		# S132 countdown arm: the qualifier the 18:58 tick left open - the render proved the
		# duration is DRAWN, not that it COUNTS DOWN. Tick the engine's own m["st"] clock
		# (Delve._status_tick, the call _fight_body makes every frame) by TICK seconds, rebuild
		# the real PartyFrames._row, and require every m["st"] chip to read its seconds minus
		# TICK. venom/slow are their own fields ticked inline in _fight_body, so they are
		# counted separately and only required to be drawn. L31_REDPROOF=1 ticks by zero.
		const TICK := 7.0
		var dt := 0.0 if OS.get_environment("L31_REDPROOF") == "1" else TICK
		var before := {}
		for m in d.party:
			for s in d.statuses(m):
				before[String(m["uid"]) + ":" + String(s[2])] = float(s[4])
		for m in d.party:
			d._status_tick(m, dt)
		var counted := 0
		var stale := 0
		var undrawn := 0
		var distinct := {}
		for m in d.party:
			var row: Control = _eye.party_frames._row(m, false, d)
			var texts: Array = []
			if row.get_child_count() > 1:
				for chip in row.get_child(1).get_children():
					texts.append(String((chip.get_child(1) as Label).text))
			for s in d.statuses(m):
				var k := String(s[2])
				var was := float(before.get(String(m["uid"]) + ":" + k, -1.0))
				var want_txt := "%s %ds" % [String(s[0]), int(ceil(float(s[4])))]
				if not texts.has(want_txt):
					undrawn += 1
				distinct[want_txt.get_slice(" ", want_txt.get_slice_count(" ") - 1)] = true
				if k == "poisoned" or k == "slowed":
					continue
				if absf((was - float(s[4])) - TICK) < 0.001:
					counted += 1
				else:
					stale += 1
			row.free()
		print("L31_COUNTDOWN tick=%.1f counted=%d stale=%d undrawn=%d distinct_secs=%d" % [dt, counted, stale, undrawn, distinct.size()])
		var ok := want > 0 and keyed == want and over == 0 and counted > 0 and stale == 0 and undrawn == 0 and distinct.size() > 1
		print("L31_ICONS %s %d" % ["OK" if ok else "FAIL", keyed])
		return true
	if _f > 9000:
		print("L31_ICONS FAIL timeout")
		return true
	return false
