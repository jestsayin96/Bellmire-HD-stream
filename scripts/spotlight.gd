extends CanvasLayer
class_name Spotlight
## L17 (Mr. E, Nov 11): the spotlight split-screen. Viewers who support the stream
## get a timed pane on their own hero - in town or down in the scar.
##
## FIXED LANES, each with its own queue and frame colour:
##   top-left     the director (always - the main view)
##   top-right    BITS        gold    any cheer 15 s, 50+ bits 20 s, 100+ bits 30 s
##   bottom-left  SUBSCRIBERS purple  new sub / resub / gift 30 s (a gift bomb: each gifter 30 s)
##   bottom-right POINTS      teal    a channel-points redeem 15 s; a free !look 10 s when it is empty
## L32a (Mr. E, Nov 12): the 2x2 grid is the stream's RESTING state, up 24/7 - it
## never collapses to a single full-screen view or a side-by-side. An idle lane shows
## AMBIENT LIFE: a rotating shot of random heroes, townsfolk, animals or the dungeon
## (a new subject every 20-30 s, preferring something happening - a fight, a catch).
## A paid moment takes its lane for the seconds bought, queued in order; when it ends
## and the queue is empty the lane returns to ambient, never to blank.
##
## API: Spotlight.spotlight(town, uid, lane, seconds, reason) -> the line for the
## Chronicle. (The desktop's town.gd can wrap it as town.spotlight(...); T1's
## EventSub hands bits / subs / points here.) F10 hides the pane labels.
##
## Each pane is a SubViewport at half resolution with its own Camera3D following the
## hero; while the grid is up the main view stops drawing 3D (the director pane
## copies its camera), so the cost is roughly one full view, not five.

const LANES := ["bits", "subs", "points"]
const COL := {"bits": Color(0.95, 0.72, 0.18), "subs": Color(0.62, 0.36, 0.92), "points": Color(0.20, 0.72, 0.70), "director": Color(0.16, 0.10, 0.06), "wide": Color(0.38, 0.28, 0.19)}
const LOOK_S := 10.0
const POINTS_S := 15.0
const SUB_S := 30.0
const QUEUE_MAX := 24
const AMB_MIN := 20.0          # L32a: an ambient shot holds 20-30 s, then rotates
const AMB_MAX := 30.0

var town: Node3D
var labels_shown := true
## lane -> {cur: {uid, seconds, left, reason}, q: [...]}
var lanes := {}
var _panes := {}           # director / bits / subs / points / wide -> {box, vp, cam, frame, label, bar}
var _layout := ""
var _amb := {}             # L32a: lane -> {node, t} - the ambient subject while the lane is idle
var _amb_rng := RandomNumberGenerator.new()

## bits -> seconds in the bits lane
static func bits_seconds(n: int) -> float:
	return 30.0 if n >= 100 else (20.0 if n >= 50 else 15.0)

## the town's spotlight node (made on first use)
static func of(t: Node) -> Spotlight:
	if t == null:
		return null
	for c in t.get_children():
		if c is Spotlight:
			return c
	var s := Spotlight.new()
	s.name = "Spotlight"
	t.add_child(s)
	s.setup(t)
	return s

## the API: put a hero in a lane for some seconds (queued if the lane is busy)
static func spotlight(t: Node, uid: String, lane: String, seconds: float, reason: String) -> String:
	var s := of(t)
	return s.put(uid, lane, seconds, reason) if s else ""

func setup(t: Node3D) -> void:
	town = t
	layer = -1                 # over the world, under every panel (Chronicle, frames, chat)
	_amb_rng.randomize()
	for l in LANES:
		lanes[l] = {"cur": {}, "q": []}
		_amb[l] = {}
	for k in ["director", "bits", "subs", "points", "wide"]:
		_panes[k] = _make_pane(k)
	var ch = t.get("chat")
	if ch is ChatCmd:
		(ch as ChatCmd).spot = func(uid: String, lane: String, secs: float, why: String) -> String: return put(uid, lane, secs, why)
	UiTheme.watch(self)
	_relayout(true)

func restyle() -> void:
	for k in _panes:
		var p: Dictionary = _panes[k]
		(p["label"] as Label).add_theme_font_size_override("font_size", UiTheme.px(24))
		(p["frame"] as Panel).add_theme_stylebox_override("panel", _frame_box(k))
	_relayout(true)

## ---------------------------------------------------------------- the queues

func put(uid: String, lane: String, seconds: float, reason: String) -> String:
	var h: Dictionary = _hero(uid)
	if h.is_empty():
		return "No hero yet - type !enlist to join the valley."
	var nm := String(h.get("name", uid))
	if lane == "look":
		# free chat: only into the channel-points lane, only when nobody is in it or waiting
		var pl: Dictionary = lanes["points"]
		if not (pl["cur"] as Dictionary).is_empty() or not (pl["q"] as Array).is_empty():
			return "The spotlight is busy - %s's look waits for a quiet moment (or redeem one)." % nm
		lane = "points"
		seconds = LOOK_S
		reason = "took a look"
	if not lanes.has(lane):
		return ""
	var L: Dictionary = lanes[lane]
	var e := {"uid": uid, "seconds": seconds, "left": seconds, "reason": reason}
	if (L["cur"] as Dictionary).is_empty():
		L["cur"] = e
		_relayout()
		return "Spotlight on %s - %s." % [nm, reason]
	if (L["q"] as Array).size() >= QUEUE_MAX:
		return "The %s spotlight queue is full." % lane
	(L["q"] as Array).append(e)
	return "%s is in the %s spotlight queue (#%d) - %s." % [nm, lane, (L["q"] as Array).size(), reason]

func busy() -> Array:
	return LANES.filter(func(l): return not (lanes[l]["cur"] as Dictionary).is_empty())

func _hero(uid: String) -> Dictionary:
	var r = town.get("roster") if town else null
	if r is Roster:
		return (r as Roster).get_hero(uid)
	return {}

## where the hero stands now: their body below in a delve, else in town
func body_of(uid: String) -> Node3D:
	if town == null:
		return null
	for c in town.get_children():
		if c is Delve:
			for m: Dictionary in (c as Delve).party:
				var b = m.get("body")
				if String((m.get("h", {}) as Dictionary).get("id", "")) == uid and is_instance_valid(b) and (b as Node3D).is_inside_tree():
					return b
	var hs = town.get("heroes")
	if hs is Dictionary and (hs as Dictionary).has(uid) and is_instance_valid(hs[uid]):
		return hs[uid]
	return null

func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.001)
	var changed := false
	for l in LANES:
		var L: Dictionary = lanes[l]
		var cur: Dictionary = L["cur"]
		if cur.is_empty():
			continue
		cur["left"] = float(cur["left"]) - real
		if float(cur["left"]) <= 0.0 or not _hero_ok(String(cur["uid"])):
			L["cur"] = (L["q"] as Array).pop_front() if not (L["q"] as Array).is_empty() else {}
			changed = true
	if changed:
		_relayout()
	_amb_tick(real)
	if _layout != "off" and _layout != "":
		_follow(real)
		_cheap(real)

## L32a: each idle lane holds its ambient subject 20-30 s, then rotates to another
func _amb_tick(real: float) -> void:
	for l in LANES:
		if not (lanes[l]["cur"] as Dictionary).is_empty():
			continue
		var A: Dictionary = _amb[l]
		A["t"] = float(A.get("t", 0.0)) - real
		var n = A.get("node")
		if n == null or not is_instance_valid(n) or not (n as Node3D).is_inside_tree() or float(A["t"]) <= 0.0:
			_amb_pick(l)

## a new ambient subject for the lane: something happening first (a fight below, a catch
## being landed), then viewers' heroes, townsfolk at large, the animals - never a body
## another pane or the director already shows, never the same subject twice running
func _amb_pick(l: String) -> void:
	var A: Dictionary = _amb[l]
	var last = A.get("node")
	var used: Array = []
	for k in LANES:
		var pb := paid_target(k)
		if pb:
			used.append(pb)
		if k != l:
			var an = (_amb[k] as Dictionary).get("node")
			if an != null and is_instance_valid(an):
				used.append(an)
	var eye := _eye()
	if eye and eye.get("selected") != null and is_instance_valid(eye.get("selected")):
		used.append(eye.get("selected"))
	var c: Array = []            # [weight, node]
	for d in town.get_children():
		if d is Delve and (d as Delve).dun != null and is_instance_valid((d as Delve).dun):
			var w := 6.0 if String((d as Delve).state) == "fight" else 3.0
			for m in (d as Delve)._alive():
				var b = m.get("body")
				if is_instance_valid(b) and (b as Node3D).is_inside_tree():
					c.append([w, b])
	var ang = town.get("anglers")
	if ang is Array:
		for a in ang:
			if is_instance_valid(a) and a.get_parent() is Node3D \
					and (a.state == Angler.S.REEL or a.state == Angler.S.SHOW or a.state == Angler.S.BITE):
				c.append([5.0, a.get_parent()])
	var hs = town.get("heroes")
	if hs is Dictionary:
		for uid in hs:
			if is_instance_valid(hs[uid]) and (hs[uid] as Node3D).is_visible_in_tree():
				c.append([2.0, hs[uid]])
	var folk := town.find_children("*", "Townsfolk", false, false)
	folk.shuffle()
	for f in folk.slice(0, 12):
		if (f as Node3D).is_visible_in_tree():
			c.append([1.5, f])
	var am = town.get("animals")
	if am is Array:
		for a2 in am:
			if a2 is Node3D and is_instance_valid(a2) and (a2 as Node3D).is_visible_in_tree():
				c.append([1.0, a2])
	var total := 0.0
	var pool: Array = []
	for e in c:
		if used.has(e[1]) or e[1] == last:
			continue
		pool.append(e)
		total += float(e[0])
	var pick: Node3D = null
	if not pool.is_empty():
		var r := _amb_rng.randf() * total
		for e in pool:
			r -= float(e[0])
			if r <= 0.0:
				pick = e[1]
				break
		if pick == null:
			pick = pool[pool.size() - 1][1]
	elif last != null and is_instance_valid(last) and (last as Node3D).is_inside_tree():
		pick = last                      # nobody else about: keep the shot rather than go blank
	A["node"] = pick
	A["t"] = _amb_rng.randf_range(AMB_MIN, AMB_MAX)
	if (_panes[l]["box"] as Control).visible:
		_snap(l)                         # a rotation is a cut, not a swoop across the town

## FPS (the desktop is chasing stutter): the lane panes take turns, one a frame,
## so each lane runs at a third of the game rate and the cost is about two views;
## they see the town's sky, fog and daylight but no SSAO (re-copied 2x a second).
var _env_t := 9.0
var _lane_env: Environment
var _frame := 0

func _cheap(real: float) -> void:
	_frame += 1
	var i := 0
	for l in LANES:
		var p: Dictionary = _panes[l]
		if (p["box"] as Control).visible:
			(p["vp"] as SubViewport).render_target_update_mode = SubViewport.UPDATE_ONCE if (_frame + i) % 3 == 0 else SubViewport.UPDATE_DISABLED
			i += 1
	_env_t += real
	if _env_t < 0.5:
		return
	_env_t = 0.0
	var src: Environment = null
	for c in town.get_children():
		if c is WorldEnvironment:
			src = (c as WorldEnvironment).environment
			break
	if src == null:
		return
	_lane_env = src.duplicate(false)
	_lane_env.ssao_enabled = false
	_lane_env.ssil_enabled = false
	_lane_env.ssr_enabled = false
	_lane_env.sdfgi_enabled = false
	_lane_env.volumetric_fog_enabled = false
	for k in ["bits", "subs", "points", "wide"]:
		# L28b: a lane looking into a delve sees that floor's own air (cheap: no SSAO)
		var lc: Camera3D = _panes[k]["cam"]
		var fe := DungeonHD.env_at(get_tree(), lc.global_position, true) if lc.is_inside_tree() else null
		lc.environment = fe if fe != null else _lane_env

## while the grid is up the panes carry the view (feed_hud / hero_body read this)
static func grid_up(t: Node) -> bool:
	if t == null:
		return false
	for c in t.get_children():
		if c is Spotlight:
			return (c as Spotlight)._layout != "off"
	return false

func _hero_ok(uid: String) -> bool:
	return not _hero(uid).is_empty()

## ---------------------------------------------------------------- the panes

## L32a: an ambient (idle) lane wears the thin muted frame, so a paid moment's
## gold / purple / teal visibly takes the pane
func _frame_box(k: String, amb := false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	var w := UiTheme.px(6) if k in LANES and not amb else UiTheme.px(2)
	sb.border_width_left = w
	sb.border_width_right = w
	sb.border_width_top = w
	sb.border_width_bottom = w
	sb.border_color = COL["wide"] if amb else COL[k]
	return sb

func _make_pane(k: String) -> Dictionary:
	var box := Control.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.name = "Pane_" + k
	HudDock.mark(box, k)                 # L21: a pane and everything on it lives in that pane
	box.visible = false
	add_child(box)
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.stretch_shrink = 1 if k == "director" else 2       # the panes at half resolution
	svc.set_anchors_preset(Control.PRESET_FULL_RECT)
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(svc)
	var vp := SubViewport.new()
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	vp.msaa_3d = Viewport.MSAA_DISABLED
	if k != "director":
		# FPS (the desktop is chasing stutter): the small panes skip omni/spot shadows,
		# take coarser LODs and see 150 m, not the whole valley
		vp.positional_shadow_atlas_size = 0
		vp.mesh_lod_threshold = 4.0
	svc.add_child(vp)
	var cam := Camera3D.new()
	cam.fov = 50.0
	cam.far = 1500.0 if k in ["director", "wide"] else 150.0
	vp.add_child(cam)
	cam.current = true
	var frame := Panel.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _frame_box(k))
	box.add_child(frame)
	# the viewer, their hero and why they are here - across the top, on a chip of the lane colour
	var lb := Label.new()
	lb.add_theme_font_size_override("font_size", UiTheme.px(24))
	lb.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	lb.add_theme_color_override("font_outline_color", UiTheme.INK)
	lb.add_theme_constant_override("outline_size", UiTheme.px(6))
	var chip := StyleBoxFlat.new()
	chip.bg_color = Color(COL[k].r * 0.55, COL[k].g * 0.55, COL[k].b * 0.55, 0.85)
	chip.content_margin_left = UiTheme.px(12)
	chip.content_margin_right = UiTheme.px(12)
	chip.content_margin_top = UiTheme.px(4)
	chip.content_margin_bottom = UiTheme.px(4)
	lb.add_theme_stylebox_override("normal", chip)
	lb.position = Vector2(UiTheme.px(10), UiTheme.px(10))
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lb.visible = k in LANES
	box.add_child(lb)
	# a thin timer bar along the bottom edge
	var bar := ColorRect.new()
	bar.color = COL[k]
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.visible = k in LANES
	box.add_child(bar)
	return {"box": box, "vp": vp, "cam": cam, "frame": frame, "label": lb, "bar": bar, "svc": svc}

func set_labels(v: bool) -> void:
	labels_shown = v
	_relayout(true)

## L32a: the 2x2 is the resting state - the layout is ALWAYS the grid. The key still
## names the busy lanes, so a lane turning paid or ambient re-lays (frames, labels, cuts).
func _relayout(force := false) -> void:
	var b := busy()
	var lay := "grid_" + "_".join(b)
	# L21: the slim bottom chrome (clock / chat) is no pane's. L39: the two pane rows MEET at
	# the cross - L32b's full-width Chronicle band that parted them is gone (Mr. E rejected it);
	# the Chronicle is now a compact box over the cross, covering only the panes' corners.
	var h := (1.0 - HudDock.CHROME) * 0.5
	var y2 := h
	var rects := {"director": Rect2(0, 0, 0.5, h), "bits": Rect2(0.5, 0, 0.5, h),
			"subs": Rect2(0, y2, 0.5, h), "points": Rect2(0.5, y2, 0.5, h)}
	_rects = rects
	if lay == _layout and not force:
		_labels()
		return
	_layout = lay
	visible = true
	# the main view never draws 3D - the panes carry it (the director pane copies its camera)
	var root_vp := get_viewport()
	if root_vp:
		root_vp.disable_3d = true
	for k in _panes:
		var p: Dictionary = _panes[k]
		var box: Control = p["box"]
		var on := rects.has(k)
		box.visible = on
		(p["vp"] as SubViewport).render_target_update_mode = SubViewport.UPDATE_ALWAYS if on else SubViewport.UPDATE_DISABLED
		if on:
			var r: Rect2 = rects[k]
			box.anchor_left = r.position.x
			box.anchor_top = r.position.y
			box.anchor_right = r.end.x
			box.anchor_bottom = r.end.y
			box.offset_left = 0
			box.offset_top = 0
			box.offset_right = 0
			box.offset_bottom = 0
			if k != "director":
				_snap(k)
	_rects = rects
	mode = "grid"
	_masks()
	_labels()

## ---------------------------------------------------------------- L21: the panes' own rules

static var mode := "off"           # "off" / "pair" / "grid" (HeroBody's name layout reads it)
var _rects := {}                    # pane -> Rect2 in 0..1 of the screen

func mode_now() -> String:
	return "off" if _layout == "" else "grid"      # L32a: once set up, always the grid

## a pane's rect on screen in px (empty when it is not up)
func pane_rect(k: String) -> Rect2:
	if not _rects.has(k):
		return Rect2()
	var r: Rect2 = _rects[k]
	var s := HudDock.screen()
	return Rect2(r.position * s, r.size * s)

## what each pane's camera draws of the world's text (HudDock's layers):
##   the director   everything, but in a quarter no floating text, no townsfolk or monster names
##                  (only the heroes' names, laid out by HeroBody on its screen)
##   a lane         only its own hero's tag; floating text too when it is half the screen
##   the wide view  no text at all
func _masks() -> void:
	var quarter := mode == "grid"
	for k in _panes:
		var cam: Camera3D = _panes[k]["cam"]
		var m := HudDock.ALL & ~HudDock.LANES_MASK
		if k == "director":
			if quarter:
				m &= ~(HudDock.L_FLOAT | HudDock.L_FTAG | HudDock.L_MTAG)
		elif k == "wide":
			m &= ~HudDock.TEXT_MASK
		else:
			m = (HudDock.ALL & ~HudDock.TEXT_MASK) | int(HudDock.L_LANE[k]) | (0 if quarter else HudDock.L_FLOAT)
			var tag = _panes[k].get("tag")
			if tag != null and is_instance_valid(tag) and not _rects.has(k):
				(tag as Label3D).visible = false
		cam.cull_mask = m

## a lane's own name over its hero: only that lane's camera draws it, at a size read on a phone
func _lane_tag(l: String, real: float) -> void:
	var p: Dictionary = _panes[l]
	var tag: Label3D = p.get("tag")
	if tag == null or not is_instance_valid(tag):
		tag = Label3D.new()
		tag.set_meta("lane_tag", true)
		tag.layers = HudDock.L_LANE[l]
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.fixed_size = true
		tag.no_depth_test = true
		tag.render_priority = 10
		tag.font_size = 48
		tag.outline_size = 14
		tag.outline_modulate = Color(0, 0, 0, 0.95)
		tag.modulate = Color(1.0, 0.86, 0.40)
		tag.top_level = true
		town.add_child(tag)
		p["tag"] = tag
	var t := paid_target(l)          # L32a: only a PAID hero gets the name tag, never an ambient subject
	var box: Control = p["box"]
	tag.visible = t != null and box.visible
	if not tag.visible:
		return
	var h := _hero(String(lanes[l]["cur"].get("uid", "")))
	tag.text = String(h.get("name", ""))
	tag.global_position = t.global_position + Vector3(0, 2.6, 0)
	# fixed size: glyphs ~26 px on the 1080p stream whatever the pane's height
	var ph := maxf(64.0, pane_rect(l).size.y)
	var cam: Camera3D = p["cam"]
	tag.pixel_size = float(UiTheme.px(26)) * 2.0 * tan(deg_to_rad(cam.fov) * 0.5) / (float(tag.font_size) * ph)

func _labels() -> void:
	for l in LANES:
		var p: Dictionary = _panes[l]
		var cur: Dictionary = lanes[l]["cur"]
		var lb: Label = p["label"]
		lb.visible = labels_shown and not cur.is_empty()
		# L32a: the timer bar and the bright lane frame belong to a paid moment only
		(p["bar"] as ColorRect).visible = not cur.is_empty()
		(p["frame"] as Panel).add_theme_stylebox_override("panel", _frame_box(l, cur.is_empty()))
		if cur.is_empty():
			continue
		var h := _hero(String(cur["uid"]))
		lb.text = "%s the %s %s - %s" % [h.get("name", "?"), String(h.get("species", "")).capitalize(), String(h.get("class", "")).capitalize(), cur["reason"]]
		# L21: the chip never runs past its own pane (a long name is cut with an ellipsis)
		lb.clip_text = true
		lb.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		var fs := lb.get_theme_font_size("font_size")
		var want := lb.get_theme_font("font").get_string_size(lb.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + float(UiTheme.px(26))
		var room := pane_rect(l).size.x - float(UiTheme.px(20))
		lb.size = Vector2(minf(want, maxf(40.0, room)), lb.get_combined_minimum_size().y)

func _target(k: String) -> Node3D:
	if k in LANES:
		var cur: Dictionary = lanes[k]["cur"]
		if not cur.is_empty():
			return body_of(String(cur["uid"]))
		# L32a: the lane is idle - its camera follows the ambient subject
		var an = (_amb.get(k, {}) as Dictionary).get("node")
		if an != null and is_instance_valid(an) and (an as Node3D).is_inside_tree():
			return an
	return null

## the body a PAID moment holds in this lane (null while the lane is ambient) -
## the director's L24 "never the same hero twice" rule reads this, so ambient
## shots never starve the director of subjects
func paid_target(k: String) -> Node3D:
	if k in LANES and not (lanes[k]["cur"] as Dictionary).is_empty():
		return body_of(String(lanes[k]["cur"]["uid"]))
	return null

## put a pane's camera straight onto its hero (no swoop in from the last one)
func _snap(k: String) -> void:
	var t := _target(k)
	var cam: Camera3D = _panes[k]["cam"]
	if t:
		var at := t.global_position + Vector3(0, 1.0, 0)
		cam.global_position = _clear(_panes[k], at, at + _offset_lane(k, t), 999.0)
		cam.look_at(at, Vector3.UP)
	else:
		# L32a: no subject at all (the first frames of an empty town): the market wide,
		# never a blank pane
		var mp: Vector3 = town.get("_market_pos") if town and town.get("_market_pos") != null else Vector3.ZERO
		cam.global_position = mp + Vector3(0, 70, 85)
		cam.look_at(mp, Vector3.UP)

## L20: the pane's camera position after the eye's clearance rule (searched every 0.25 s per pane)
func _clear(p: Dictionary, at: Vector3, want: Vector3, real: float) -> Vector3:
	var eye := _eye()
	if eye == null:
		return want
	p["lift_t"] = float(p.get("lift_t", 0.0)) - real
	if float(p["lift_t"]) <= 0.0:
		p["lift_t"] = 0.25
		var sz: Vector2 = (p["box"] as Control).size
		p["lift"] = eye.clear_shot(at, want, (p["cam"] as Camera3D).fov, sz.x / maxf(1.0, sz.y))
		# L22: a lane spread round a group keeps its side - clearance may tilt it, never swing it
		# round into a neighbour's quarter (a 70 deg swing had put two lanes 24 deg apart)
		if bool(p.get("crowd", false)):
			p["lift"] = Vector2((p["lift"] as Vector2).x, 0.0)
	# eased like the eye's (tilt and swing glide, never snap; a cut - real 999 - goes straight there)
	p["mv"] = (p.get("mv", Vector2.ZERO) as Vector2).lerp(p.get("lift", Vector2.ZERO), clampf(real * 3.0, 0.0, 1.0))
	return RtsCamera.shifted(at, want, p["mv"])

## L34: the eye's shot rebuilt from its OWN numbers (same convention as RtsCamera's placement),
## for the tick where neither the main viewport's camera nor the eye's Camera3D can be read.
## The director pane then still moves with the eye instead of holding a dead frame.
func _eye_xform(eye: RtsCamera) -> Transform3D:
	var off := Vector3(sin(eye.yaw) * cos(eye.pitch), -sin(eye.pitch), cos(eye.yaw) * cos(eye.pitch)) * eye.dist
	var t := Transform3D(Basis(), eye.focus + off)
	return t.looking_at(eye.focus + Vector3(0, 1.0, 0), Vector3.UP)

var _eye_n: RtsCamera
func _eye() -> RtsCamera:
	if not is_instance_valid(_eye_n):
		_eye_n = null
		for c in town.get_children():
			if c is RtsCamera:
				_eye_n = c
				break
	return _eye_n

## a little higher and closer below ground, where walls crowd the view
func _offset_for(t: Node3D) -> Vector3:
	var deep := t.global_position.y < -20.0 or _in_delve(t)
	return Vector3(0, 9.0, 7.0) if deep else Vector3(0, 6.5, 9.5)

## ---- L22: two spotlit heroes standing together made two panes of one picture (every lane
## sat at the same offset behind its hero). When another pane's subject - another lane's hero,
## or the director's - is within CLOSE_M of a lane's hero, that lane takes its own side of the
## group and its own zoom - the four views a quarter-turn apart: bits 90 deg round from the director's
## side and close in, subs -90 deg at the usual distance, points straight opposite, further out. Measured from
## the director's camera, so no lane looks the director's way. Apart again (past APART_M,
## the gap stops it flickering): the usual view behind the hero. Each change is a cut.
const CLOSE_M := 6.0
const APART_M := 9.0
const SPREAD := {"bits": [90.0, 0.85], "subs": [-90.0, 1.05], "points": [180.0, 1.32]}

func _offset_lane(l: String, t: Node3D) -> Vector3:
	var o := _offset_for(t)
	if not l in LANES:
		return o
	var p: Dictionary = _panes[l]
	var was := bool(p.get("crowd", false))
	var near := 1.0e9
	var tp := t.global_position
	for k in LANES:
		if k == l or not (_panes[k]["box"] as Control).visible:
			continue
		var b := _target(k)
		if b:
			near = minf(near, tp.distance_to(b.global_position))
	var eye := _eye()
	if eye and (_panes["director"]["box"] as Control).visible:
		near = minf(near, tp.distance_to(eye.focus))
	var crowd := near < (APART_M if was else CLOSE_M)
	if crowd != was:
		p["crowd"] = crowd
		p["cut"] = true
	if not crowd:
		return o
	var main := get_viewport().get_camera_3d() if get_viewport() else null
	var base := 0.0
	if main:
		var d := main.global_position - tp
		if Vector2(d.x, d.z).length() > 0.5:
			base = atan2(d.x, d.z)
	var yaw := base + deg_to_rad(float(SPREAD[l][0]))
	var k := float(SPREAD[l][1])
	var h := Vector2(o.x, o.z).length() * k
	return Vector3(sin(yaw) * h, o.y * k, cos(yaw) * h)

func _in_delve(t: Node3D) -> bool:
	var p := t.get_parent()
	while p:
		if p is Delve:
			return true
		p = p.get_parent()
	return false

var _wide_t := 0.0

func _follow(real: float) -> void:
	var w: Dictionary = _panes["wide"]
	if (w["box"] as Control).visible:
		_wide_t += real
		if _wide_t >= 0.25:
			_wide_t = 0.0
			(w["vp"] as SubViewport).render_target_update_mode = SubViewport.UPDATE_ONCE
	var main := get_viewport().get_camera_3d() if get_viewport() else null
	var d: Dictionary = _panes["director"]
	if (d["box"] as Control).visible:
		# L34: the main viewport's camera can be null (L32a keeps disable_3d on, or the eye's
		# subject rerolled mid-frame). The old code just skipped the copy, so the pane SILENTLY
		# held its last transform - the frozen/black top-left pane Mr. E saw. Never hold stale:
		# drive the pane from the eye's own camera, and failing that from the eye's numbers.
		var dc: Camera3D = d["cam"]
		var src: Camera3D = main
		var eye := _eye()
		if (src == null or not is_instance_valid(src)) and eye != null and is_instance_valid(eye.cam):
			src = eye.cam
		if src != null and is_instance_valid(src):
			dc.global_transform = src.global_transform
			dc.fov = src.fov
			dc.far = src.far
		elif eye != null:
			dc.global_transform = _eye_xform(eye)
	for l in LANES:
		var p: Dictionary = _panes[l]
		_lane_tag(l, real)
		if not (p["box"] as Control).visible:
			continue
		var cur: Dictionary = lanes[l]["cur"]
		var t := _target(l)
		if t:
			var cam: Camera3D = p["cam"]
			var at := t.global_position + Vector3(0, 1.0, 0)
			# L20: the eye's clearance rule, not a copy - tilt up over a roof in the pane's lower frame
			var want := _clear(p, at, at + _offset_lane(l, t), real)
			if cam.global_position.distance_to(want) > 40.0 or bool(p.get("cut", false)):
				p["cut"] = false          # L22: a new side of the group is a cut, not a swoop through the heroes
				cam.global_position = want          # the hero went below (or came up): cut, don't fly
			else:
				cam.global_position = cam.global_position.lerp(want, clampf(real * 4.0, 0.0, 1.0))
			cam.look_at(at, Vector3.UP)
		var box: Control = p["box"]
		var bar: ColorRect = p["bar"]
		var f := clampf(float(cur.get("left", 0.0)) / maxf(0.01, float(cur.get("seconds", 1.0))), 0.0, 1.0)
		var bh := float(UiTheme.px(8))
		bar.position = Vector2(0, box.size.y - bh)
		bar.size = Vector2(box.size.x * f, bh)
