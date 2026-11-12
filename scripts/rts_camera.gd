extends Node3D
class_name RtsCamera
## The player's eye on the valley - a NEW RTS-style camera (nothing from the
## old game's interface). It orbits a point on the ground:
##   WASD / arrows   pan (Shift = fast)        mouse wheel   zoom
##   right-drag      rotate + tilt             Q / E         rotate
##   R / T           tilt                      middle-drag   pan
##   left-click      select anyone (unit frame at the bottom)
##   F               follow the selected one (or your own hero if none)
##   Esc             clear selection / stop following      N   all names on/off
##   1 square  2 scar mouth  3 west gate  4 tavern  5 smithy  6 armourer  7 apothecary
##   Tab             cycle through delves running below (and back to town)
##   Space           pause / resume            [ / ]         slower / faster (1x 2x 4x 8x)
##   Enter           type a chat command as yourself (no Twitch: local only)
##   V               director: the camera runs itself (stream mode)
##   F10             hide / show the whole interface
##   H               show / hide this help
var town: Node3D
var cam: Camera3D
var focus := Vector3.ZERO
var yaw := deg_to_rad(35.0)
var pitch := deg_to_rad(-48.0)
var dist := 34.0
var _drag_r := false
var _drag_m := false
var _speeds := [1.0, 2.0, 4.0, 8.0]
var _speed_i := 0
var _paused := false
var _delve_i := -1
var _help: Label
var _speed_lb: Label
var _chat: LineEdit
var _layer: CanvasLayer
var party_frames: PartyFrames
var boss_bar: BossBar

func setup(t: Node3D) -> void:
	town = t
	cam = Camera3D.new()
	cam.fov = 55.0
	cam.far = 2000.0
	add_child(cam)
	cam.make_current()
	focus = t.get("_market_pos")
	UiTheme.watch(self)
	_layer = CanvasLayer.new()
	_layer.layer = 30
	add_child(_layer)
	_help = Label.new()
	_help.text = "WASD pan · wheel zoom · right-drag rotate · Q/E turn · R/T tilt\nclick: select · F follow (your hero if none selected) · Esc clear · N names\n1 square · 2 scar · 3 gate · 4 tavern · 5 smithy · 6 armourer · 7 apothecary\nTab: jump into a delve · Space pause · [ ] speed · Enter chat · H hide\nF9 all titles · F10 hide UI + spotlight labels · F11 UI scale"
	_help.add_theme_font_size_override("font_size", UiTheme.px(19))
	_help.add_theme_color_override("font_color", Color(1, 0.95, 0.85))
	_help.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_help.add_theme_constant_override("outline_size", 6)
	_help.position = Vector2(16, 12)
	_help.visible = false            # L16 phone test: dev furniture, not stream furniture - H shows it
	_skin_chips()
	_layer.add_child(_help)
	_speed_lb = Label.new()
	_speed_lb.add_theme_font_size_override("font_size", UiTheme.px(24))
	_speed_lb.add_theme_color_override("font_color", Color(1, 0.86, 0.45))
	_speed_lb.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_speed_lb.add_theme_constant_override("outline_size", 6)
	_speed_lb.anchor_left = 1.0
	_speed_lb.anchor_right = 1.0
	_speed_lb.offset_left = -260
	_speed_lb.offset_top = 12
	_layer.add_child(_speed_lb)
	_chat = LineEdit.new()
	_chat.placeholder_text = "chat as MrE, e.g. !enlist knight   (Enter to send, Esc to close)"
	# L16: bottom-right, clear of the Chronicle
	_chat.anchor_left = 1.0
	_chat.anchor_right = 1.0
	_chat.anchor_top = 1.0
	_chat.anchor_bottom = 1.0
	_chat.offset_left = -UiTheme.px(760)
	_chat.offset_right = -UiTheme.px(18)
	_chat.offset_top = -UiTheme.px(70)
	_chat.offset_bottom = -UiTheme.px(18)
	_skin_chat()
	_chat.visible = false
	_chat.text_submitted.connect(_send_chat)
	_layer.add_child(_chat)
	_update_speed_label()
	# party frames: a compact column, left edge, while any delve runs
	party_frames = PartyFrames.new()
	_layer.add_child(party_frames)
	party_frames.setup(t)
	# the lord's bar: top centre, only while a floor lord fights
	boss_bar = BossBar.new()
	_layer.add_child(boss_bar)
	boss_bar.setup(t)

	director = AutoDirector.new()
	add_child(director)
	director.setup(self, t)
	# L17: the spotlight split-screen (bits / subs / points lanes); chat's !look goes through it
	spotlight = Spotlight.of(t)

func _ground(p: Vector3) -> float:
	if p.y < Delve.DELVE_Y * 0.5:
		return Delve.DELVE_Y
	return float(town.call("height_at", p.x, p.z))

func _process(delta: float) -> void:
	if _chat == null:
		return                  # setup() has not run yet (the town is still building)
	if cam == null:
		return
	var real := delta / maxf(Engine.time_scale, 0.001)    # camera moves in real time
	_titles_tick(real)
	_titles_follow()
	if not _chat.visible:
		var mv := Vector2.ZERO
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): mv.y -= 1
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): mv.y += 1
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): mv.x -= 1
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): mv.x += 1
		if mv != Vector2.ZERO:
			var spd := (12.0 + dist * 1.1) * (3.0 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
			var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
			var right := Vector3(cos(yaw), 0, -sin(yaw))
			focus += (right * mv.x + fwd * -mv.y) * spd * real
		if Input.is_key_pressed(KEY_Q): yaw += 1.6 * real
		if Input.is_key_pressed(KEY_E): yaw -= 1.6 * real
		if Input.is_key_pressed(KEY_R): pitch = clampf(pitch - 1.0 * real, deg_to_rad(-85), deg_to_rad(-12))
		if Input.is_key_pressed(KEY_T): pitch = clampf(pitch + 1.0 * real, deg_to_rad(-85), deg_to_rad(-12))
		if mv != Vector2.ZERO:
			_following = false
	_track(real)
	focus.y = lerpf(focus.y, _ground(focus), clampf(real * 8.0, 0.0, 1.0))
	var off := Vector3(sin(yaw) * cos(pitch), -sin(pitch), cos(yaw) * cos(pitch)) * dist
	# L20: every shot keeps the lower frame clear - tilt up over a roof in the way
	if pull_in:
		_lift_t -= real
		if _lift_t <= 0.0:
			_lift_t = CLEAR_EVERY
			var piv := focus + Vector3(0, 1.0, 0)
			var mv := clear_shot(piv, focus + off, cam.fov, _aspect())
			# don't glide THROUGH a roof to get there: where we are is clear and halfway is not -> stay
			var cur := Vector2(_lift, _swing)
			if cur.distance_to(mv) > 0.05:
				var asp := _aspect()
				if frame_clear(piv, shifted(piv, focus + off, cur), cam.fov, asp) \
						and not frame_clear(piv, shifted(piv, focus + off, (cur + mv) * 0.5), cam.fov, asp):
					mv = cur
			_lift_want = mv.x
			_swing_want = mv.y
		_lift = lerpf(_lift, _lift_want, clampf(real * (8.0 if _lift_want > _lift else 1.2), 0.0, 1.0))
		# a swing glides round (never snaps), and drifts home slowly once the view is clear
		_swing = lerpf(_swing, _swing_want, clampf(real * (3.0 if absf(_swing_want) > absf(_swing) else 0.8), 0.0, 1.0))
	else:
		_lift = 0.0
		_swing = 0.0
	if _lift > 0.001 or absf(_swing) > 0.001:
		var ep := maxf(pitch - _lift, deg_to_rad(-CLEAR_MAX_DEG))
		var ey := yaw + _swing
		off = Vector3(sin(ey) * cos(ep), -sin(ep), cos(ey) * cos(ep)) * dist
	cam.global_position = focus + off
	# never under the ground
	var gy := _ground(cam.global_position) + 1.5
	if cam.global_position.y < gy:
		cam.global_position.y = gy
	# a followed one: never inside a wall or a house - pull in along the line to them. (L20: NOT for
	# wide / tour shots - their pivot is a spot on the ground, and pulling in toward it parked the
	# camera low in front of the nearest house; the tilt above keeps those clear instead.)
	if _following and selected != null and pull_in:
		_pull_in(real)
	else:
		_pull_d = 1.0e9
	_fill_light(real)
	cam.look_at(focus + Vector3(0, 1.0, 0), Vector3.UP)

func _unhandled_input(ev: InputEvent) -> void:
	if _chat == null:
		return                  # setup() has not run yet (the town is still building)
	if _chat.visible:
		if ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
			_chat.visible = false
			_chat.release_focus()
		return
	if ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			dist = clampf(dist * 0.88, 6.0, 260.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			dist = clampf(dist / 0.88, 6.0, 260.0)
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_pick(mb.position)
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			_drag_r = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			_drag_m = mb.pressed
	elif ev is InputEventMouseMotion:
		var mm: InputEventMouseMotion = ev
		if _drag_r:
			yaw -= mm.relative.x * 0.005
			pitch = clampf(pitch - mm.relative.y * 0.004, deg_to_rad(-85), deg_to_rad(-12))
		elif _drag_m:
			var k := dist * 0.0022
			var right := Vector3(cos(yaw), 0, -sin(yaw))
			var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
			focus += (-right * mm.relative.x + fwd * mm.relative.y) * k
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		match ev.keycode:
			KEY_1: _jump(town.get("_market_pos"), 34.0)
			KEY_2: _jump_scar()
			KEY_3: _jump(town.call("_gate", -1.0), 30.0)
			KEY_4: _jump_shop("tavern")
			KEY_5: _jump_shop("blacksmith")
			KEY_6: _jump_shop("armorer")
			KEY_7: _jump_shop("apothecary")
			KEY_TAB: _cycle_delve()
			KEY_SPACE:
				_paused = not _paused
				town.get_tree().paused = false
				Engine.time_scale = 0.0001 if _paused else float(_speeds[_speed_i])
				_update_speed_label()
			KEY_BRACKETLEFT:
				_speed_i = maxi(0, _speed_i - 1)
				_set_speed()
			KEY_BRACKETRIGHT:
				_speed_i = mini(_speeds.size() - 1, _speed_i + 1)
				_set_speed()
			KEY_H: _help.visible = not _help.visible
			KEY_F9:
				# L16 phone test: every hero's title, or only the one in view (selected / the director's focus)
				titles_all = not titles_all
				_titles_t = 0.0
			KEY_F11:
				# L15: the interface scale for the stream, 100 / 125 / 150%
				var s := UiTheme.cycle()
				_say_scale(s)
			KEY_F: _follow_key()
			KEY_ESCAPE:
				_following = false
				_select(null)
			KEY_N: _toggle_names()
			KEY_ENTER, KEY_KP_ENTER:
				_chat.visible = true
				_chat.text = "!"
				_chat.grab_focus()
				_chat.caret_column = 1

func _set_speed() -> void:
	_paused = false
	Engine.time_scale = float(_speeds[_speed_i])
	_update_speed_label()

func _update_speed_label() -> void:
	var eco = town.get("economy")
	var clock := ""
	if eco:
		var h: float = eco.hour()
		clock = "  Day %d  %02d:%02d" % [eco.day, int(h), int(fmod(h, 1.0) * 60.0)]
	_speed_lb.text = ("PAUSED" if _paused else "%dx" % int(_speeds[_speed_i])) + clock

func _physics_process(_d: float) -> void:
	if _chat == null:
		return
	if _speed_lb:
		_update_speed_label()

func _jump(p: Vector3, d: float) -> void:
	_delve_i = -1
	focus = p
	dist = d

func _jump_scar() -> void:
	var sc: Dictionary = town.get("_scar_info")
	if sc.has("mouth"):
		_jump(sc["mouth"] + (sc["fwd"] as Vector3) * 8.0, 30.0)

func _jump_shop(kind: String) -> void:
	var fr: Array = (town.get("_shop_frame") as Dictionary).get(kind, [])
	if not fr.is_empty():
		_jump(fr[0], 20.0)

## Tab: every delve under way, in turn, then back to the square
func _cycle_delve() -> void:
	var ds: Array = []
	for c in town.get_children():
		if c is Delve and (c as Delve).dun != null and is_instance_valid((c as Delve).dun):
			ds.append(c)
	if ds.is_empty() or _delve_i + 1 >= ds.size():
		_jump(town.get("_market_pos"), 34.0)
		return
	_delve_i += 1
	var d: Delve = ds[_delve_i]
	var alive: Array = d._alive()
	focus = (alive[0]["body"] as Node3D).global_position if not alive.is_empty() else d.dun.global_position
	dist = 22.0
	pitch = deg_to_rad(-62.0)

func _send_chat(text: String) -> void:
	_chat.visible = false
	_chat.release_focus()
	if text.strip_edges().length() > 1:
		var out: String = town.call("chat_line", "local_mre", "MrE", text.strip_edges())
		print("CHAT MrE: ", text, " -> ", out)

## ================================================= selection and following
## RTS-style: click anyone - a townsfolk, a hero, the band, a monster - and a
## ring marks them and a unit frame at the bottom tells you who they are.
var selected: Node3D = null
var _following := false
var _ring: MeshInstance3D
var _frame: PanelContainer
var _f_name: Label
var _f_sub: Label
var _f_hp: ProgressBar
var _f_hp_lb: Label
var _f_body: Label
var _frame_t := 0.0
var quiet := false          # stream mode: no selection ring, no unit frame
var director: AutoDirector
var spotlight: Spotlight

func _candidates() -> Array:
	var out: Array = []
	for n in town.find_children("*", "Townsfolk", true, false):
		out.append(n)
	for n in town.find_children("*", "Monster", true, false):
		out.append(n)
	return out

func _pick(at: Vector2) -> void:
	var best: Node3D = null
	var bd := 48.0
	for n in _candidates():
		var nd: Node3D = n
		if not nd.is_visible_in_tree():
			continue
		var p := nd.global_position + Vector3(0, 1.0, 0)
		if cam.is_position_behind(p):
			continue
		var sp := cam.unproject_position(p)
		var d := sp.distance_to(at)
		if d < bd:
			bd = d
			best = nd
	_following = false          # a new pick stops following the old one
	_select(best)

func _select(n: Node3D) -> void:
	selected = n
	if _ring == null:
		_ring = MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.7
		tm.outer_radius = 0.85
		_ring.mesh = tm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(0.35, 1.0, 0.45)
		m.emission_enabled = true
		m.emission = Color(0.3, 1.0, 0.4)
		_ring.material_override = m
		_ring.scale = Vector3(1, 0.25, 1)
		_ring.top_level = true
		add_child(_ring)
	if _frame == null:
		_build_frame()
	_ring.visible = n != null
	_frame.visible = n != null
	if n == null:
		_following = false
	_frame_t = 0.0

func _follow_key() -> void:
	if selected == null or not is_instance_valid(selected):
		var mine = _hero_body("local_mre", town.get("roster"))
		if mine == null:
			_say_local("No hero of yours yet - press Enter and type !enlist knight")
			return
		_select(mine)
	_following = not _following if selected != null else false
	if _following:
		dist = minf(dist, 26.0)

func _say_local(line: String) -> void:
	(town.get("feed") as Array).append(line)

## the body a hero has right now: their town body, or their body down a delve
func _hero_body(uid: String, roster: Roster) -> Node3D:
	for c in town.get_children():
		if c is Delve and (c as Delve).roster == roster:
			for m in (c as Delve).party:
				if String(m["uid"]) == uid and is_instance_valid(m["body"]) and float(m["hp"]) > 0.0 and (c as Delve).state != "home":
					return m["body"]
	var hs: Dictionary = town.get("heroes")
	if roster == town.get("roster") and hs.has(uid) and is_instance_valid(hs[uid]):
		return hs[uid]
	var adv = town.get("adventurers")
	if adv and (adv.bodies as Dictionary).has(uid) and is_instance_valid(adv.bodies[uid]):
		return adv.bodies[uid]
	return null

func _track(real: float) -> void:
	# a freed selection (a slain lord, a raider gone) compares equal to null, so
	# test validity, not null-ness, and drop the ring and frame with it
	if not is_instance_valid(selected):
		if _ring != null and _ring.visible:
			_select(null)
		selected = null
	# a followed hero who goes down the scar (or comes back up) changes bodies
	if selected is HeroBody and (not selected.is_visible_in_tree() or not selected.is_inside_tree()):
		var hb: HeroBody = selected
		var nb := _hero_body(hb.user_id, hb.roster)
		if nb != null and nb != selected:
			selected = nb
	if selected == null:
		return
	if _following:
		if focus.distance_to(selected.global_position) > 60.0:
			focus = selected.global_position        # into / out of the scar: cut, don't glide
			dist = minf(dist, 26.0)
		else:
			focus = focus.lerp(selected.global_position, clampf(real * 6.0, 0.0, 1.0))
	if _ring:
		_ring.global_position = selected.global_position + Vector3(0, 0.08, 0)
		_ring.visible = selected.is_visible_in_tree() and not quiet
	if _frame and quiet:
		_frame.visible = false
	_frame_t -= real
	if _frame_t <= 0.0:
		_frame_t = 0.2
		_fill_frame()

func _build_frame() -> void:
	_frame = PanelContainer.new()
	var sb := UiTheme.parchment()      # L16: the house parchment
	sb.content_margin_left = UiTheme.px(16)
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 10
	_frame.add_theme_stylebox_override("panel", sb)
	# L16 phone test: bottom-right, clear of the Chronicle (above the chat box line)
	_frame.anchor_left = 1.0
	_frame.anchor_right = 1.0
	_frame.anchor_top = 1.0
	_frame.anchor_bottom = 1.0
	_frame.offset_left = -UiTheme.px(618)
	_frame.offset_right = -UiTheme.px(18)
	_frame.offset_bottom = -UiTheme.px(86)
	_frame.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_layer.add_child(_frame)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	_frame.add_child(v)
	_f_name = Label.new()
	_f_name.add_theme_font_size_override("font_size", UiTheme.px(32))
	_f_name.add_theme_color_override("font_color", UiTheme.VIEWER)
	v.add_child(_f_name)
	_f_sub = Label.new()
	_f_sub.add_theme_font_size_override("font_size", UiTheme.px(24))
	_f_sub.add_theme_color_override("font_color", UiTheme.INK_SOFT)
	v.add_child(_f_sub)
	var hpbox := Control.new()
	hpbox.custom_minimum_size = Vector2(UiTheme.px(560), UiTheme.px(26))
	v.add_child(hpbox)
	_f_hp = ProgressBar.new()
	_f_hp.show_percentage = false
	_f_hp.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.2, 0.05, 0.05)
	var fg := StyleBoxFlat.new()
	fg.bg_color = Color(0.2, 0.75, 0.25)
	_f_hp.add_theme_stylebox_override("background", bg)
	_f_hp.add_theme_stylebox_override("fill", fg)
	hpbox.add_child(_f_hp)
	_f_hp_lb = Label.new()
	_f_hp_lb.set_anchors_preset(Control.PRESET_FULL_RECT)
	_f_hp_lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_f_hp_lb.add_theme_font_size_override("font_size", UiTheme.px(20))
	_f_hp_lb.add_theme_color_override("font_color", Color(1, 1, 1))
	_f_hp_lb.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_f_hp_lb.add_theme_constant_override("outline_size", UiTheme.px(5))
	hpbox.add_child(_f_hp_lb)
	_f_body = Label.new()
	_f_body.add_theme_font_size_override("font_size", UiTheme.px(24))
	_f_body.add_theme_color_override("font_color", UiTheme.INK)
	_f_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_f_body.custom_minimum_size = Vector2(UiTheme.px(560), 0)
	v.add_child(_f_body)

func _fill_frame() -> void:
	if _frame == null or selected == null:
		return
	var hp := 1.0
	var mx := 1.0
	var follow := "   [following]" if _following else "   (F to follow)"
	if selected is HeroBody:
		var hb: HeroBody = selected
		var r: Roster = hb.roster
		var h := r.get_hero(hb.user_id)
		mx = r.max_hp(h)
		hp = mx
		var where := "in Bellmire"
		for c in town.get_children():
			if c is Delve:
				for m in (c as Delve).party:
					if m["body"] == selected:
						hp = float(m["hp"])
						mx = float(m["max"])
						where = "below, floor %d" % (c as Delve).floor_no
		_f_name.text = String(h.get("name", hb.person_name)) + follow
		_f_sub.text = "%s %s, level %d  ·  %s  ·  %s" % ["Viewer's" if not hb.npc else "The town's", String(h.get("class", "")).capitalize(), int(h.get("level", 1)), r.rank_of(h), where]
		var cs: Array = []
		var chat = town.get("chat")
		if chat and chat.catches_of.is_valid():
			cs = chat.catches_of.call(String(h.get("name", "")))
		_f_body.text = "%s  ·  %s  ·  AC %d\n%d potions · %d oil · %d gold · %d kills · deepest floor %d%s" % [
			r.weapon_name(h), String(Roster.ARMOUR[int(h["armour"])]["name"]), r.armour_class(h),
			int(h.get("potions", 0)), int(h.get("oil", 0)), int(h.get("gold", 0)), int(h.get("kills", 0)), int(h.get("deepest", 0)),
			("  ·  %d catches" % cs.size()) if not cs.is_empty() else ""]
	elif selected is Monster:
		var mo: Monster = selected
		hp = mo.hp
		mx = mo.max_hp
		_f_name.text = String(mo.def.get("name", "creature")).capitalize() + follow
		_f_sub.text = ("Lord of the scar" if mo.def.get("boss", false) else String(mo.def.get("family", "creature")).capitalize())
		_f_body.text = String(mo.def.get("note", ""))
	elif selected is Townsfolk:
		var tf: Townsfolk = selected
		var role := String(tf.gear_role if tf.gear_role != "" else tf.role)
		hp = float(tf.get_meta("hp", 28.0))
		mx = {"guard": 64.0, "chief": 40.0}.get(String(tf.role), 28.0)
		_f_name.text = tf.person_name + follow
		_f_sub.text = role.capitalize() + " of Bellmire"
		var eco = town.get("economy")
		var doing := "at their post" if tf.stay else ("indoors" if tf.inside else ("on the way" if not tf._route.is_empty() else "about town"))
		_f_body.text = doing + ("  ·  night - heading home" if eco and eco.is_night() and not tf.stay else "")
	_f_hp.max_value = maxf(mx, 1.0)
	_f_hp.value = clampf(hp, 0.0, mx)
	_f_hp_lb.text = "%d / %d" % [int(maxf(hp, 0.0)), int(mx)]

## N: every name in the valley on or off (townsfolk names are off by default
## so the square does not drown in text)
func _toggle_names() -> void:
	Townsfolk.show_names = not Townsfolk.show_names
	for n in town.find_children("*", "Townsfolk", true, false):
		if n is HeroBody:
			continue
		for c in (n as Node).get_children():
			if c is Label3D and c != (n as Townsfolk)._shout:
				# D6: Bellmire's named people keep their tag up close
				var named: bool = (n as Townsfolk).notable_title != ""
				(c as Label3D).visible = Townsfolk.show_names or named
				(c as Label3D).visibility_range_end = 60.0 if Townsfolk.show_names else (14.0 if named else 9.0)
	_say_local("Names %s." % ("shown" if Townsfolk.show_names else "hidden"))

## ================================================= follow camera fixes
## No physics bodies in this game, so the "raycast" marches the line from the
## followed one's head out to the camera through what IS solid: house boxes in
## town (up to their roof), and anything off the floor cells below wall top in
## a dungeon. The first solid sample pulls the camera in front of it at once;
## when the view clears it eases back out.
const DUN_WALL_TOP := 4.6       # KayKit walls are one 4 m grid tall
var pull_in := true
const PULL_MIN := 6.0           # L20: the follow pull-in stops this far from the subject (town)
const PULL_MIN_BELOW := 4.0     # and below
var _pull_d := 1.0e9
var _houses: Array = []         # [centre xz, ax, az, half extents, top y, radius]
var _near: Array = []           # this frame's houses near the line
var _cam_delve: Delve = null

var _houses_key := ""

func _house_rects() -> Array:
	# L20: rebuilt when the town gains a house, a prop or a wall piece (a raid's rebuild)
	var sr: Array = town.get("_solid_rects") if town.get("_solid_rects") != null else []
	var ws: Array = town.get("_wall_solid") if town.get("_wall_solid") != null else []
	var tw: Array = town.get("towers") if town.get("towers") != null else []
	var key := "%d/%d/%d/%d" % [(town.get("plots") as Array).size(), sr.size(), ws.size(), tw.size()]
	if not _houses.is_empty() and key == _houses_key:
		return _houses
	_houses_key = key
	_houses = []
	_more_solids(sr, ws, tw)
	var hb: Dictionary = town.get("_house_box")
	for plot in town.get("plots"):
		var sh := String(plot.get("shape", "a"))
		if not hb.has(sh):
			continue
		var he: Vector2 = (hb[sh][0] as Vector2) * 1.04
		var off: Vector2 = hb[sh][1]
		var top: float = float(hb[sh][2]) * 1.1 if (hb[sh] as Array).size() > 2 else 9.0
		var yaw := float(plot["yaw"])
		var ax := Vector2(cos(yaw), -sin(yaw))
		var az := Vector2(sin(yaw), cos(yaw))
		var pp: Vector3 = plot["pos"]
		_houses.append([Vector2(pp.x, pp.z) + ax * off.x + az * off.y, ax, az, he, pp.y + top, he.length(), "house"])
	return _houses

## L20: the houses were the only solids the camera knew - a market stall's roof and a guard
## tower filled director frames in the L20 renders. Same records the town's nav carves
## (footprints only), with heights: towers 11 m + roof, the wall 5 m + merlons, a stall-size
## prop 4.5 m (a canopy roof). Benches, barrels and anything under 0.9 m across cannot fill a frame - skipped.
const TOWER_TOP := 15.5
const WALL_TOP := 6.6
const PROP_TOP := 4.5
func _more_solids(sr: Array, ws: Array, tw: Array) -> void:
	for t: Vector3 in tw:
		var g := float(town.call("height_at", t.x, t.z))
		_houses.append([Vector2(t.x, t.z), Vector2(1, 0), Vector2(0, 1), Vector2(4.2, 4.2), g + TOWER_TOP, 6.0, "tower"])
	for w: Array in ws:
		var wp: Vector3 = w[0]
		var tg: Vector3 = w[1]
		var g := float(town.call("height_at", wp.x, wp.z))
		_houses.append([Vector2(wp.x, wp.z), Vector2(tg.x, tg.z), Vector2(-tg.z, tg.x), Vector2(2.0, 1.3), g + WALL_TOP, 2.4, "wall"])
	for r: Array in sr:
		var he: Vector2 = r[3]
		if maxf(he.x, he.y) < 0.9:
			continue
		var c: Vector2 = r[0]
		var g := float(town.call("height_at", c.x, c.y))
		_houses.append([c, r[1], r[2], he, g + PROP_TOP, he.length(), "prop"])

func _delve_at(p: Vector3) -> Delve:
	var best: Delve = null
	var bd := 1.0e9
	for c in town.get_children():
		if c is Delve and (c as Delve).dun != null and is_instance_valid((c as Delve).dun):
			var d := Vector2(p.x, p.z).distance_to(Vector2((c as Delve).dun.global_position.x, (c as Delve).dun.global_position.z))
			if d < bd:
				bd = d
				best = c
	return best

func _solid_at(p: Vector3) -> bool:
	if _cam_delve != null:
		var dn: DungeonHD = _cam_delve.dun
		if p.y > dn.global_position.y + DUN_WALL_TOP:
			return false
		return not (dn.info["cells"] as Dictionary).has(_cam_delve._cell_of(p))
	var q := Vector2(p.x, p.z)
	for r in _near:
		if p.y > float(r[4]):
			continue
		var d := q - (r[0] as Vector2)
		var he: Vector2 = r[3]
		if absf(d.dot(r[1])) < he.x and absf(d.dot(r[2])) < he.y:
			return true
	return false

func _pull_in(real: float) -> void:
	var pivot := focus + Vector3(0, 1.0, 0)
	var seg := cam.global_position - pivot
	var L := seg.length()
	if L < 1.0:
		return
	var dir := seg / L
	_cam_delve = null
	_near.clear()
	if pivot.y < Delve.DELVE_Y * 0.5:
		_cam_delve = _delve_at(pivot)
		if _cam_delve == null:
			return
		# the followed hero stands on a cell the grid calls solid (a doorway, a prop's
		# square): the doorway rule below then parked the camera 4 m off their head,
		# inside the scenery (soak frame 02). Underground the camera sits high above
		# the walls anyway - leave it there.
		if _solid_at(pivot):
			_pull_d = 1.0e9
			return
	else:
		# only the houses whose footprint circle touches the line (xz)
		var a := Vector2(pivot.x, pivot.z)
		var b := Vector2(cam.global_position.x, cam.global_position.z)
		for r in _house_rects():
			var c: Vector2 = r[0]
			if Geometry2D.get_closest_point_to_segment(c, a, b).distance_to(c) < float(r[5]):
				_near.append(r)
	# standing in a doorway (inside a footprint): start where the line leaves it
	var s0 := 0.0
	while s0 < minf(L, 4.0) and _solid_at(pivot + dir * s0):
		s0 += 0.2
	if s0 >= L:
		return
	# L20: below, a hero with their back to a wall clipped it in the first metres of the line
	# and the camera snapped in ~1.3 m from their head, into the wall's corner (_l20_test,
	# 1 run in 3). The camera sits high above the walls there: a wall right by the hero is
	# scenery - only what stands between, further out, pulls it in (the tilt sees that first).
	if _cam_delve != null:
		s0 = maxf(s0, 3.0)
	var free_d := L
	var s := s0 + 0.6
	while s <= L:
		if _solid_at(pivot + dir * s):
			free_d = maxf(s - 0.7, s0 + 0.3)
			break
		s += 0.4
	# L20: never closer than this - a stall beside a hero (props are solids now) made the pull-in
	# park the camera in their face (the L20 hero render). Nearer blockers are the tilt / swing's job.
	free_d = maxf(free_d, minf(L, PULL_MIN_BELOW if _cam_delve != null else PULL_MIN))
	if free_d < _pull_d:
		_pull_d = free_d                                    # snap in
	else:
		_pull_d = minf(free_d, lerpf(_pull_d, free_d, clampf(real * 2.5, 0.0, 1.0)))   # ease out
	if _pull_d < L:
		cam.global_position = pivot + dir * _pull_d
		# L20: below, pulled in over a wall's corner the camera could land inside the wall
		# (1 frame in 455 in _l20_test) - lift it just over the wall top instead
		if _cam_delve != null and _solid_at(cam.global_position):
			cam.global_position.y = _cam_delve.dun.global_position.y + DUN_WALL_TOP + 0.6

## ================================================= L20: clearance for EVERY shot
## The pull-in above guards the one line from the subject to the camera. A roof beside
## that line can still fill the bottom of the picture (the director's wide and tour
## shots had no check at all). So: lines from the camera into the lower half of the
## frame, toward the ground; anything solid in their NEAR stretch (a roof or a wall by
## the camera - a house beside the subject is scenery, not a blocker) means tilt up.
## clear_lift() finds the least extra tilt (keeping the distance) that clears them all.
## The spotlight panes (spotlight.gd) call the same function for their own cameras.
const CLEAR_EVERY := 0.2                     # s between searches
const CLEAR_MAX_DEG := 80.0                  # never steeper than this
## what a cameraman would try, cheapest first: tilt up a little; swing round the subject a
## little; both; swing further; only then look steeply down. [extra tilt, swing] in degrees
const CLEAR_CANDS := [Vector2(0, 0), Vector2(6, 0), Vector2(12, 0), Vector2(18, 0),
	Vector2(0, 35), Vector2(0, -35), Vector2(12, 35), Vector2(12, -35), Vector2(24, 0),
	Vector2(0, 70), Vector2(0, -70), Vector2(18, 70), Vector2(18, -70),
	Vector2(31, 0), Vector2(24, 35), Vector2(24, -35), Vector2(38, 0), Vector2(46, 0)]
const CLEAR_PTS := [Vector2(0.10, 0.94), Vector2(0.5, 0.96), Vector2(0.90, 0.94),
	Vector2(0.15, 0.72), Vector2(0.85, 0.72), Vector2(0.5, 0.62)]      # where in the frame (u, v)
const CLEAR_NEAR := 0.8                      # how far along each lower-frame line (to the ground, or the subject) counts
const CLEAR_REACH := 40.0                    # past this from the camera nothing fills the frame
var _lift := 0.0                             # radians of extra tilt now
var _lift_want := 0.0
var _swing := 0.0                            # radians round the subject now
var _swing_want := 0.0
var _lift_t := 0.0

func _aspect() -> float:
	var s := get_viewport().get_visible_rect().size if get_viewport() else Vector2(16, 9)
	return s.x / maxf(1.0, s.y)

## the least move (x: extra tilt, y: swing round the subject, radians) that clears the frame
## of a camera at `pos` looking at `pivot`; nothing clears -> the steepest tilt tried
func clear_shot(pivot: Vector3, pos: Vector3, fov_deg: float, aspect: float) -> Vector2:
	if town == null:
		return Vector2.ZERO
	var L := (pos - pivot).length()
	if L < 2.0 or Vector2(pos.x - pivot.x, pos.z - pivot.z).length() < 0.05:
		return Vector2.ZERO
	_clear_near(pivot, L)
	var last := Vector2.ZERO
	for c: Vector2 in CLEAR_CANDS:
		var mv := Vector2(deg_to_rad(c.x), deg_to_rad(c.y))
		if frame_clear(pivot, shifted(pivot, pos, mv), fov_deg, aspect):
			return mv
		if c.y == 0.0:
			last = mv
	return last

## tilt only (kept for callers that cannot swing)
func clear_lift(pivot: Vector3, pos: Vector3, fov_deg: float, aspect: float) -> float:
	return clear_shot(pivot, pos, fov_deg, aspect).x

## the houses (town) or the delve (below) that a camera this far from pivot could meet
func _clear_near(pivot: Vector3, L: float) -> void:
	_near.clear()
	_cam_delve = null
	if pivot.y < Delve.DELVE_Y * 0.5:
		_cam_delve = _delve_at(pivot)
		return
	var a := Vector2(pivot.x, pivot.z)
	for r in _house_rects():
		if (r[0] as Vector2).distance_to(a) < L + float(r[5]) + 4.0:
			_near.append(r)

## is the near part of the lower frame free of roofs and walls? (call _clear_near first)
func frame_clear(pivot: Vector3, p: Vector3, fov_deg: float, aspect: float) -> bool:
	if _near.is_empty() and _cam_delve == null:
		return true
	if _solid_at(p):
		return false
	var fwd := (pivot - p).normalized()
	if fwd.cross(Vector3.UP).length() < 0.01:
		return true
	var subj := p.distance_to(pivot)
	# only the near half of every line counts: test only what stands within that reach of the
	# camera (props + walls + towers are hundreds - a valley shot must not test them all)
	var keep := _near
	var reach_n := subj * CLEAR_NEAR + 1.5
	var pc := Vector2(p.x, p.z)
	_near = keep.filter(func(r): return (r[0] as Vector2).distance_to(pc) < reach_n + float(r[5]))
	var ok := _frame_lines(pivot, p, fwd, subj, fov_deg, aspect)
	_near = keep
	return ok

func _frame_lines(pivot: Vector3, p: Vector3, fwd: Vector3, subj: float, fov_deg: float, aspect: float) -> bool:
	if _near.is_empty() and _cam_delve == null:
		return true
	var right := fwd.cross(Vector3.UP).normalized()
	var up := right.cross(fwd)
	var th := tan(deg_to_rad(fov_deg) * 0.5)
	var gy := pivot.y - 1.0
	# the line to the subject itself (short of the last 2.5 m, where a hero may stand in a doorway):
	# a wall or roof across it is a reason to tilt over it before the follow's pull-in has to step in
	var s0 := 1.0
	var lim0 := minf(subj - 2.5, CLEAR_REACH)
	while s0 < lim0:
		if _solid_at(p + fwd * s0):
			return false
		s0 += 0.8 + s0 * 0.03
	# below, the maze's walls in the lower frame ARE the floor - only the line to the hero counts
	if _cam_delve != null:
		return true
	for uv: Vector2 in CLEAR_PTS:
		var d := (fwd + right * (2.0 * uv.x - 1.0) * th * aspect + up * (1.0 - 2.0 * uv.y) * th).normalized()
		var reach := CLEAR_REACH / CLEAR_NEAR
		if d.y < -0.01:
			reach = minf(reach, (gy - p.y) / d.y)
		var s := 1.0
		var lim := minf(reach, subj) * CLEAR_NEAR
		while s < lim:
			if _solid_at(p + d * s):
				return false
			s += 0.8 + s * 0.03                       # finer close to the camera, where size counts
	return true

## a camera at `pos` on `pivot`, moved by mv (x: tilt up, y: swing round) radians, same distance
static func shifted(pivot: Vector3, pos: Vector3, mv: Vector2) -> Vector3:
	if absf(mv.x) <= 0.001 and absf(mv.y) <= 0.001:
		return pos
	var off := pos - pivot
	var h := Vector2(off.x, off.z)
	if h.length() < 0.05:
		return pos
	var e := minf(atan2(off.y, h.length()) + mv.x, deg_to_rad(CLEAR_MAX_DEG))
	var az := atan2(h.x, h.y) + mv.y
	return pivot + Vector3(sin(az) * cos(e), sin(e), cos(az) * cos(e)) * off.length()

## tilt only (kept for older callers)
static func lifted(pivot: Vector3, pos: Vector3, lift: float) -> Vector3:
	return shifted(pivot, pos, Vector2(lift, 0.0))

## camera_solid(): is the camera itself inside something solid right now (tests)
func camera_solid() -> bool:
	var keep := _near.duplicate()
	var kd := _cam_delve
	_near = _house_rects()
	_cam_delve = _delve_at(cam.global_position) if cam.global_position.y < Delve.DELVE_Y * 0.5 else null
	var hit := _solid_at(cam.global_position)
	_near = keep
	_cam_delve = kd
	return hit

## a soft fill light on the followed one at night, so a hero is not a
## silhouette in the dark (town only: a dungeon's dark is the lore's dark)
const FILL_ENERGY := 0.9
var fill: OmniLight3D

func _fill_light(real: float) -> void:
	var want := 0.0
	var eco = town.get("economy")
	if _following and selected != null and selected.is_visible_in_tree() \
			and selected.global_position.y > Delve.DELVE_Y * 0.5 and eco and eco.is_night():
		want = FILL_ENERGY
	if fill == null:
		if want <= 0.0:
			return
		fill = OmniLight3D.new()
		fill.name = "follow_fill"
		fill.top_level = true
		fill.light_color = Color(0.86, 0.88, 1.0)
		fill.light_energy = 0.0
		fill.light_specular = 0.15
		fill.omni_range = 7.0
		fill.omni_attenuation = 1.4
		fill.shadow_enabled = false
		add_child(fill)
	fill.light_energy = move_toward(fill.light_energy, want, real * 1.5)
	fill.visible = fill.light_energy > 0.01
	if fill.visible and selected != null:
		var to_cam := cam.global_position - selected.global_position
		to_cam.y = 0.0
		fill.global_position = selected.global_position + Vector3(0, 2.6, 0) + to_cam.normalized() * 1.8

## ---- L15: the stream's UI scale (F11). Panels elsewhere restyle themselves
## (UiTheme.watch); here the key help, the speed label and the unit frame.
func restyle() -> void:
	if _help:
		_help.add_theme_font_size_override("font_size", UiTheme.px(19))
	if _speed_lb:
		_speed_lb.add_theme_font_size_override("font_size", UiTheme.px(24))
	_skin_chips()
	_skin_chat()
	if _frame:
		var was := _frame.visible
		_frame.queue_free()
		_frame = null
		if was and selected:
			_build_frame()
			_fill_frame()

func _say_scale(s: float) -> void:
	if town and town.get("feed") != null:
		(town.get("feed") as Array).append("Interface at %d%% (F11)." % int(round(s * 100.0)))

## ---- L16: the key help, the speed and the chat box on parchment chips, ink text,
## the teal as the chat box's focus edge - the same house as every panel
func _skin_chips() -> void:
	for lb: Label in [_help, _speed_lb]:
		if lb == null:
			continue
		lb.add_theme_stylebox_override("normal", UiTheme.chip())
		lb.add_theme_color_override("font_color", UiTheme.INK)
		lb.add_theme_constant_override("outline_size", 0)

func _skin_chat() -> void:
	if _chat == null:
		return
	var n := UiTheme.chip()
	var f := UiTheme.chip()
	f.border_color = UiTheme.TEAL
	_chat.add_theme_stylebox_override("normal", n)
	_chat.add_theme_stylebox_override("focus", f)
	_chat.add_theme_color_override("font_color", UiTheme.INK)
	_chat.add_theme_color_override("font_placeholder_color", UiTheme.INK_SOFT)
	_chat.add_theme_color_override("caret_color", UiTheme.TEAL)
	_chat.add_theme_font_size_override("font_size", UiTheme.px(UiTheme.SMALL))

## ---- L16 phone test: cosmetic titles (Gear's "eq_title" under a hero's body)
## show on the selected hero - which is also the director's focus - and on all of
## them only with F9; a long title is shortened so it keeps to its hero's column.
var titles_all := false
var _titles_t := 0.0
var _shown_titles: Array = []
const TITLE_MAX := 22
func _titles_tick(real: float) -> void:
	_titles_t -= real
	if _titles_t > 0.0 or town == null:
		return
	_titles_t = 0.25
	_shown_titles.clear()
	for o in get_tree().get_nodes_in_group("viewer_heroes"):
		var hb := o as HeroBody
		if hb == null or hb._mdl == null:
			continue
		var lb := hb._mdl.get_node_or_null("eq_title") as Label3D
		if lb == null:
			continue
		if not lb.has_meta("full"):
			lb.set_meta("full", lb.text)
		var full := String(lb.get_meta("full"))
		lb.text = full if full.length() <= TITLE_MAX else full.substr(0, TITLE_MAX - 1) + "…"
		lb.visible = titles_all or hb == selected
		lb.top_level = true
		if lb.visible:
			_shown_titles.append(hb)

## every frame: a shown title rides one line under its hero's name label, at the
## name's own size and lift (the hero's label layout spreads the names apart)
func _titles_follow() -> void:
	for hb in _shown_titles:
		if not is_instance_valid(hb) or (hb as HeroBody)._mdl == null:
			continue
		var lb := (hb as HeroBody)._mdl.get_node_or_null("eq_title") as Label3D
		var nm := (hb as HeroBody)._name_label()
		if lb == null or nm == null or not nm.visible:
			if lb:
				lb.visible = false
			continue
		lb.global_position = nm.global_position
		lb.pixel_size = nm.pixel_size
		lb.font_size = int(nm.font_size * 0.62)
		lb.offset = Vector2(0, nm.offset.y - float(nm.font_size) * 0.95)
		lb.vertical_alignment = VERTICAL_ALIGNMENT_TOP
