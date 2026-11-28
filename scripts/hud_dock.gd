extends Node
class_name HudDock
## L21 (Mr. E, Nov 11): the interface over the spotlight panes. While more than one view is on
## screen, NO HUD element may cross a pane seam or float over a pane it does not belong to.
## Every element is either docked INSIDE one pane (scaled to it) or sits in the reserved
## CHROME bar across the bottom that no pane covers. Full screen (no lanes) is untouched.
##
##   centre strip the STRIP across the middle of the 2x2, at the cross of the four panes:
##                the on-stream Chronicle lives here (L32b, Mr. E's original ask), full
##                width, one line an entry at the L15 size, calm pacing
##   chrome bar   the slim bottom CHROME no pane covers: the clock / the local chat box
##                at its right end
##   a pane       the boss card at its top edge, a party's frames at its bottom-left, the
##                director's unit frame at its bottom-right - each in the pane SHOWING it
##
## And the world's 3D text, which every pane camera draws: it is sorted onto render layers
## as it enters the tree, and each pane camera's cull mask picks what that pane shows -
##   FLOAT   floating combat text, bubbles below, states: never in a pane under half the screen
##   HTAG    heroes' names (laid out on the director's screen by HeroBody)
##   MTAG    monsters' names        FTAG  townsfolk names and their bubbles
##   LANE_*  a lane's own name tag over its spotlit hero (Spotlight makes them)
## tools/_l21_test.gd checks all of it.

const CHROME := 0.06           # L32b: slim - the Chronicle left it for the centre strip
## L39 (Mr. E, Nov 13): the Chronicle is a compact BOX at the cross of the 2x2, NOT a band.
## He rejected the full-width bar, and then the tiny box over-corrected from it: the real
## problem was the TEXT, so feed_hud shrank the font first (28 -> 18 px) and the box is
## sized to the smaller text. CENTRE_W is well under half the screen, so the box can only
## ever cover the inner CORNERS of the panes it touches.
## L39b (Mr. E, Nov 13, from his annotated 1x screenshot): the width was close but the box
## was too SHORT. His red box is ~0.37 wide x ~0.27 tall (about 715x295 at 1080p, ~3x the
## old height). The font STAYS 18 px - the extra height buys MORE LINES on screen at once
## (feed_hud._chrome_lines), so a viewer can read back what just happened.
const STRIP := 0.273           # L39b: the box's height - ~0.27 of the screen (~295 px at 1080p)
const CENTRE_W := 0.40         # L39b: the box's width - ~0.37, a touch wider, still under half
const L_WORLD := 1
const L_FLOAT := 1 << 10
const L_HTAG := 1 << 11
const L_MTAG := 1 << 12
const L_FTAG := 1 << 13
const L_LANE := {"bits": 1 << 14, "subs": 1 << 15, "points": 1 << 16}
const ALL := 0xFFFFF
const LANES_MASK := (1 << 14) | (1 << 15) | (1 << 16)
const TEXT_MASK := L_FLOAT | L_HTAG | L_MTAG | L_FTAG | LANES_MASK

## how wide the chrome bar's right end is held for the clock / the chat box (px)
static var reserve_right := 0.0
## L40: the town, remembered so the static put() can ask where the Chronicle box is
static var _town: Node = null
static var _installed: SceneTree = null

## ---------------------------------------------------------------- 3D text layers

static func install(tree: SceneTree, town: Node) -> void:
	if _installed != tree:
		_installed = tree
		tree.node_added.connect(_on_added)
	for n in town.find_children("*", "Label3D", true, false):
		sort(n as Label3D)
	# U126 (Mr. E 21 Nov 10:17 directive): NO floating "Now fighting" banner and NO floating mana
	# strip on the game view. The boss name is the nameplate over its head (game lane S88); mana
	# lives on the hub character sheet. FightBanner / ManaStrip classes stay below, never added.

static func _on_added(n: Node) -> void:
	if n is Label3D:
		sort(n as Label3D)
	elif n is VisualInstance3D and n.get_parent() is Label3D:
		(n as VisualInstance3D).layers = (n.get_parent() as Label3D).layers     # a bubble's plate

## which layer a Label3D belongs on (a lane's own tag is set by Spotlight and left alone)
static func kind(lb: Label3D) -> int:
	if lb.has_meta("lane_tag"):
		return lb.layers
	if lb.name == "name_tag":
		return L_MTAG
	var p := lb.get_parent()
	while p:
		if p is HeroBody:
			return L_HTAG
		if p is Townsfolk:
			return L_FTAG
		if p is Monster:
			return L_FLOAT          # its damage numbers (its name_tag is caught above)
		if p is Delve or p is DungeonHD:
			return L_FLOAT
		p = p.get_parent()
	# the delve's numbers, states and barks live on the floor's own root
	return L_FLOAT if lb.top_level and lb.no_depth_test else L_WORLD

static func sort(lb: Label3D) -> void:
	lb.layers = kind(lb)
	for c in lb.get_children():
		if c is VisualInstance3D:
			(c as VisualInstance3D).layers = lb.layers

## ---------------------------------------------------------------- the screen

## the town's spotlight node, never made here
static func spot(t: Node) -> Spotlight:
	if t == null:
		return null
	for c in t.get_children():
		if c is Spotlight:
			return c
	return null

## "off" (full screen), "pair" (side by side) or "grid" (2x2)
static func mode(t: Node) -> String:
	var s := spot(t)
	return s.mode_now() if s else "off"

static func split(t: Node) -> bool:
	return mode(t) != "off"

static func screen() -> Vector2:
	var ml := Engine.get_main_loop()
	if ml is SceneTree and (ml as SceneTree).root:
		return Vector2((ml as SceneTree).root.size)
	return Vector2(1920, 1080)

## the bar along the bottom no pane covers (px); empty at full screen
static func chrome(t: Node) -> Rect2:
	if not split(t):
		return Rect2()
	var s := screen()
	var top := floorf(s.y * (1.0 - CHROME))
	return Rect2(0, top, s.x, s.y - top)

## L39: the Chronicle's compact box at the cross of the 2x2 (px); empty at full screen.
## Was Rect2(0, top, s.x, ...) - the full-width band Mr. E rejected.
static func centre(t: Node) -> Rect2:
	if not split(t):
		return Rect2()
	var s := screen()
	var top := floorf(s.y * (1.0 - CHROME - STRIP) * 0.5)
	var w := floorf(s.x * CENTRE_W)
	return Rect2(floorf((s.x - w) * 0.5), top, w, ceilf(s.y * STRIP))

## L36: the local chat box's rect on screen (px) while it is showing, else empty. The box is the
## eye's (rts_camera.gd); this only READS it so the Chronicle can keep clear of it. Nothing may
## draw over chat and chat may not draw over the Chronicle - they must share ZERO pixels.
static func chat_rect(t: Node) -> Rect2:
	if t == null:
		return Rect2()
	for c in t.get_children():
		if c is RtsCamera:
			var ch = (c as Node).get("_chat")
			if ch is Control and (ch as Control).is_visible_in_tree():
				return (ch as Control).get_global_rect()
	return Rect2()

## a pane's rect on screen (px), or an empty rect if it is not up
static func pane(t: Node, k: String) -> Rect2:
	var s := spot(t)
	return s.pane_rect(k) if s else Rect2()

## how big a pane's overlays are drawn: smaller in a quarter, a little in the side by side
static func pane_k(t: Node, k: String) -> float:
	var r := pane(t, k)
	if r.size.y <= 0.0:
		return 1.0
	return 0.85 if r.size.y < screen().y * 0.6 else 0.95

## the pane showing this delve: the director when its camera is down there, else the lane
## following one of its party; "" when no pane shows it
static func pane_for_delve(t: Node, d: Delve) -> String:
	var s := spot(t)
	if s == null or d == null:
		return ""
	var eye := s._eye()
	if eye and eye.cam and _cam_in(eye.cam.global_position, d):
		return "director"
	for l in Spotlight.LANES:
		if s.pane_rect(l).size.x <= 0.0:
			continue
		var b := s._target(l)
		if b == null:
			continue
		for m: Dictionary in d.party:
			if m.get("body") == b:
				return l
	return ""

static func _cam_in(p: Vector3, d: Delve) -> bool:
	if d.dun == null or not is_instance_valid(d.dun):
		return false
	var q := d.dun.global_position
	return p.y < Delve.DELVE_Y * 0.5 and Vector2(p.x, p.z).distance_to(Vector2(q.x, q.z)) < 120.0

## put a control inside a rect at a corner / edge ("tl", "tc", "tr", "bl", "bc", "br"),
## scaled by k; top_pad pushes it down (under a pane's own label chip)
static func put(c: Control, r: Rect2, k: float, at: String, top_pad := 0.0) -> void:
	var m := float(UiTheme.px(12))
	c.set_anchors_preset(Control.PRESET_TOP_LEFT)
	c.scale = Vector2(k, k)
	var s := c.get_combined_minimum_size()
	c.size = s
	var w := s * k
	var x := r.position.x + m
	if at[1] == "r":
		x = r.end.x - m - w.x
	elif at[1] == "c":
		x = r.position.x + (r.size.x - w.x) * 0.5
	var y := r.position.y + m + top_pad if at[0] == "t" else r.end.y - m - w.y
	# L40: the Chronicle box owns the centre cross - nothing docked in a pane may cross it.
	# Enforced HERE, at the one chokepoint every pane-docked element goes through, so a
	# boss card or a party's frames clears the Chronicle without their own files changing.
	var box := centre(_town)
	if box.size.x > 0.0 and region_of(c) != "centre" and Rect2(Vector2(x, y), w).intersects(box):
		if y + w.y * 0.5 <= box.position.y + box.size.y * 0.5:
			y = box.position.y - m - w.y        # it sits above the box: keep it above
		else:
			y = box.end.y + m                   # below: keep it below
		y = clampf(y, r.position.y + m, maxf(r.position.y + m, r.end.y - m - w.y))
	c.position = Vector2(roundf(x), roundf(y))

## undo put(): anchors are set again by the owner's own full-screen placement
static func unput(c: Control) -> void:
	c.scale = Vector2.ONE

## ---------------------------------------------------------------- default-deny
## Every HUD control states where it lives while the panes are up: a pane's name, "chrome",
## or "none" (it hides while split). A control inherits its nearest marked ancestor's home.
## Anything NOT marked - a panel added later by either machine - is hidden by guard() while
## the panes are up (and shown again after), and tools/_l21_test.gd fails on it. So a new
## panel can never silently float over a pane: it has to be given a home first.
const META := "hud_dock"

static func mark(c: Node, region: String) -> void:
	if c:
		c.set_meta(META, region)

## the home a control was given ("" = none given - denied)
static func region_of(n: Node) -> String:
	while n and not (n is CanvasLayer) and not (n is Viewport):
		if n.has_meta(META):
			return String(n.get_meta(META))
		n = n.get_parent()
	return ""

static var _denied := {}           # instance id -> the control guard() hid
static var _warned := {}

## hide every visible top-level HUD control with no home (or homed "none") while split;
## show them again at full screen. Returns the paths it hid this pass.
static func guard(t: Node) -> Array:
	_town = t                      # L40: put() needs it to find the Chronicle box
	var hid: Array = []
	if not split(t):
		for id in _denied:
			var c = instance_from_id(id)
			if c != null and is_instance_valid(c):
				(c as Control).visible = true
		_denied.clear()
		return hid
	var ml := Engine.get_main_loop()
	if not (ml is SceneTree):
		return hid
	# the HUD's layers, looked up again every 2 s (a native search; the guard itself is cheap)
	var now := Time.get_ticks_msec()
	if now - _layers_at > 2000:
		_layers_at = now
		_layers = (ml as SceneTree).root.find_children("*", "CanvasLayer", true, false)
	for cl in _layers:
		if not is_instance_valid(cl):
			continue
		for k in (cl as Node).get_children():
			if k is Control and (k as Control).visible:
				var r := region_of(k)
				if r == "" or r == "none":
					(k as Control).visible = false
					if r == "":
						_denied[k.get_instance_id()] = true     # a stranger: shown again at full screen
					# ("none": its owner hides / shows it itself)
					hid.append(str(k.get_path()))
					if r == "" and not _warned.has(str(k.get_path())):
						_warned[str(k.get_path())] = true
						push_warning("HudDock: %s has no home (HudDock.mark) - hidden while the spotlight panes are up" % k.get_path())
	return hid

static var _layers: Array = []
static var _layers_at := -100000


## ---------------------------------------------------------------- L61 the Chronicle scroll
## The on-stream Chronicle reads as an UNFURLED SCROLL (Mr. E, Nov 13): the stream's
## signature piece. ONE cheap procedural draw layer - a wavy parchment POLYGON (deckled
## sides, a slight sag), stepped-rect gradients, curl shadows and relief rects, a thin
## vector filigree frame; NO texture import. The two spindles OVERHANG the sheet so their
## ornamented finials cap the rods (not a framed box), and the paper visibly furls under
## them. "An elder scroll, our own design": ornate, illuminated-manuscript feel in OUR
## brand (parchment + ink + the JestSayin teal with a gold illumination), ORIGINAL filigree
## - it copies no existing game's art, font, logo, blank-scroll motif or UI. feed_hud docks
## the lines (and a lord's card) inside sheet_rect() so ink always sits on open vellum.
## It redraws only on resize (a static HUD skin), so the stepped gradients cost nothing.
class ChronicleScroll extends Control:
	const CREAM := UiTheme.SCROLL_CREAM
	const TAN := UiTheme.SCROLL_TAN
	const TAN_DK := UiTheme.SCROLL_TAN_DK
	const WOOD_LT := UiTheme.SCROLL_WOOD_LT
	const WOOD_DK := UiTheme.SCROLL_WOOD_DK
	const BRASS := UiTheme.SCROLL_BRASS
	const BRASS_DK := UiTheme.SCROLL_BRASS_DK
	const GOLD := UiTheme.SCROLL_GOLD
	const TEAL := UiTheme.TEAL
	const BURN := UiTheme.SCROLL_BURN

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	## U217: the TOWN BAND - Bellmire's level and its movement toward the next tier, on the Chronicle's own
	## vellum (COORDINATION 13 item 2, so no seventh overlay). {} = nothing to show, no band, no height.
	var town := {}

	func set_town(d: Dictionary) -> void:
		if d.hash() != town.hash():
			town = d
			queue_redraw()

	## the band's height in px (0 with no town data): feed_hud takes this off the lines' area
	func band_h() -> float:
		return 0.0 if town.is_empty() else float(UiTheme.px(40.0))

	## the band's rect on the open vellum, one source for _draw and any gate
	func band_rect() -> Rect2:
		var sr := sheet_rect()
		var h := band_h()
		if h <= 0.0:
			return Rect2()
		return Rect2(sr.position.x, sr.position.y + _p(9.0), sr.size.x, h - _p(11.0))

	func _town_band() -> void:
		var r := band_rect()
		if r.size.x <= 0.0 or r.size.y <= 0.0:
			return
		var font := _wordmark_font()
		var fs := maxi(14, UiTheme.px(21))
		var lv := int(town.get("level", 1))
		var tiers := int(town.get("tiers", 12))
		# the level plate: ink block, gilt numeral
		var tag := "LV %d" % lv
		var tsz := font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var plate := Rect2(r.position, Vector2(tsz.x + _p(14.0), r.size.y))
		draw_rect(plate, UiTheme.INK)
		draw_rect(plate, Color(GOLD.r, GOLD.g, GOLD.b, 0.9), false, maxf(1.0, _p(1.0)))
		var base := r.position.y + (r.size.y + tsz.y * 0.62) * 0.5
		draw_string(font, Vector2(plate.position.x + _p(7.0), base), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiTheme.WORD_HI)
		# the right end: the 12-tier bar, then what is still needed
		var bar_w := clampf(r.size.x * 0.34, _p(120.0), _p(300.0))
		var bar := Rect2(r.end.x - bar_w, r.position.y + r.size.y * 0.18, bar_w, r.size.y * 0.64)
		var note := "TOWN FULL" if bool(town.get("maxed", false)) else "%d to go" % int(town.get("to_next", 0))
		var nfs := maxi(13, UiTheme.px(18))
		var nsz := font.get_string_size(note, HORIZONTAL_ALIGNMENT_LEFT, -1, nfs)
		# U224: at 150% the full tier name ("A MARKET-DAY TOWN") was elided to "A MARKET..." - give the name its
		# room first by narrowing the tier bar, down to a floor, before the name is ever trimmed
		var nw := font.get_string_size(String(town.get("name", "")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var bar_cap := r.end.x - nsz.x - _p(20.0) - (plate.end.x + _p(10.0)) - nw
		bar.size.x = clampf(bar_cap, _p(84.0), bar_w)
		bar.position.x = r.end.x - bar.size.x
		bar.position.x -= nsz.x + _p(10.0)
		draw_string(font, Vector2(r.end.x - nsz.x, base), note, HORIZONTAL_ALIGNMENT_LEFT, -1, nfs, UiTheme.TEAL_ON_PARCH)
		# the town's name between plate and bar, trimmed to fit
		var nm := String(town.get("name", "")).to_upper()
		var nx := plate.end.x + _p(10.0)
		var room := bar.position.x - _p(10.0) - nx
		while nm.length() > 3 and font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > room:
			nm = nm.substr(0, nm.length() - 2).rstrip(" '-") + "…"
		draw_string(font, Vector2(nx, base), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiTheme.INK)
		# twelve tier cells: earned ones filled, the current one filled by its fraction
		var gap := maxf(1.0, _p(2.0))
		var cw := (bar.size.x - gap * float(tiers - 1)) / float(tiers)
		var frac := float(town.get("frac", 0.0))
		for i in tiers:
			var cr := Rect2(bar.position.x + float(i) * (cw + gap), bar.position.y, cw, bar.size.y)
			draw_rect(cr, Color(UiTheme.INK.r, UiTheme.INK.g, UiTheme.INK.b, 0.22))
			if i < lv - 1:
				draw_rect(cr, TEAL)
			elif i == lv - 1:
				draw_rect(Rect2(cr.position, Vector2(cr.size.x * (1.0 if bool(town.get("maxed", false)) else frac), cr.size.y)), GOLD)
			draw_rect(cr, UiTheme.INK, false, maxf(1.0, _p(1.0)))
		# a rule under the band so the lines start clearly below it
		draw_line(Vector2(r.position.x, r.end.y + _p(3.0)), Vector2(r.end.x, r.end.y + _p(3.0)), Color(TEAL.r, TEAL.g, TEAL.b, 0.7), maxf(1.0, _p(1.0)))

	func _p(n: float) -> float:
		return float(UiTheme.px(n))

	## one source of geometry, shared by _draw and sheet_rect so they never drift
	func _geo() -> Dictionary:
		var s := size
		var cap := maxf(_p(8.0), s.y * 0.050)
		var mx := maxf(_p(18.0), cap * 2.4)      # the rods overhang the sheet by ~this much
		var amp := _p(3.0)
		var sag := _p(5.0)
		var top_cy := cap * 1.25 + _p(1.0)
		var bot_cy := s.y - cap * 1.25 - _p(1.0)
		return {"cap": cap, "mx": mx, "amp": amp, "sag": sag, "top_cy": top_cy, "bot_cy": bot_cy,
			"sx0": mx, "sx1": s.x - mx}

	## the overlay rect: safely inside the wavy sheet silhouette
	func _ov(g: Dictionary) -> Rect2:
		var pad: float = g.amp + _p(2.0)
		return Rect2(g.sx0 + pad, g.top_cy, (g.sx1 - g.sx0) - 2.0 * pad, g.bot_cy - g.top_cy)

	## the writable vellum for feed_hud: inside the filigree frame
	func sheet_rect() -> Rect2:
		var g := _geo()
		var ov := _ov(g)
		var inx := _p(15.0)
		var iny := _p(10.0)
		return Rect2(ov.position.x + inx, ov.position.y + iny,
			maxf(0.0, ov.size.x - 2.0 * inx), maxf(0.0, ov.size.y - 2.0 * iny))

	func _sheet_poly(g: Dictionary, dx: float, dy: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		var n := 10
		var x0: float = g.sx0
		var x1: float = g.sx1
		var y0: float = g.top_cy
		var y1: float = g.bot_cy
		var amp: float = g.amp
		var sag: float = g.sag
		pts.append(Vector2(x0 + dx, y0 + dy))
		pts.append(Vector2(x1 + dx, y0 + dy))
		for i in range(1, n):
			var t := float(i) / float(n)
			pts.append(Vector2(x1 + amp * sin(t * PI * 3.0) + dx, lerp(y0, y1, t) + dy))
		for i in range(0, n + 1):
			var u := float(i) / float(n)
			pts.append(Vector2(lerp(x1, x0, u) + dx, y1 + sag * sin(u * PI) + dy))
		for i in range(1, n):
			var t2 := float(i) / float(n)
			pts.append(Vector2(x0 - amp * sin(t2 * PI * 3.0) + dx, lerp(y1, y0, t2) + dy))
		return pts

	func _vgrad(r: Rect2, top: Color, bot: Color, steps: int) -> void:
		steps = maxi(1, steps)
		var h := r.size.y / float(steps)
		for i in steps:
			var k := (float(i) + 0.5) / float(steps)
			draw_rect(Rect2(r.position.x, r.position.y + float(i) * h, r.size.x, h + 1.0), top.lerp(bot, k))

	func _side_shade(ov: Rect2, band: float) -> void:
		var n := 8
		var w := band / float(n)
		for i in n:
			var k := 1.0 - float(i) / float(n)
			var col := Color(TAN_DK.r, TAN_DK.g, TAN_DK.b, 0.26 * k)
			draw_rect(Rect2(ov.position.x + float(i) * w, ov.position.y, w + 1.0, ov.size.y), col)
			draw_rect(Rect2(ov.end.x - float(i + 1) * w, ov.position.y, w + 1.0, ov.size.y), col)

	func _fibre(ov: Rect2) -> void:
		var step := _p(16.0)
		var x := ov.position.x + step * 0.5
		var i := 0
		while x < ov.end.x:
			var col := CREAM if (i % 3 == 0) else TAN_DK
			var a := 0.05 if (i % 2 == 0) else 0.035
			draw_line(Vector2(x, ov.position.y + _p(3.0)), Vector2(x, ov.end.y - _p(3.0)), Color(col.r, col.g, col.b, a), 1.0)
			x += step
			i += 1

	func _foxing(ov: Rect2) -> void:
		for sp in [Vector2(0.20, 0.34), Vector2(0.72, 0.24), Vector2(0.55, 0.76), Vector2(0.88, 0.64)]:
			var c := ov.position + Vector2(ov.size.x * sp.x, ov.size.y * sp.y)
			var rr := _p(7.0)
			draw_circle(c, rr, UiTheme.SCROLL_STAIN)
			draw_circle(c, rr * 0.6, UiTheme.SCROLL_STAIN_2)

	## the paper visibly furls under each rod: a strong dark gradient band hugging the rods
	func _curl(ov: Rect2, cap: float) -> void:
		var n := 7
		var hh := (cap * 1.55) / float(n)
		for i in n:
			var k := 1.0 - float(i) / float(n)
			var col := Color(UiTheme.SCROLL_EDGE_SHADE, UiTheme.SCROLL_EDGE_SHADE.a * k)
			draw_rect(Rect2(ov.position.x, ov.position.y + float(i) * hh, ov.size.x, hh + 1.0), col)
			draw_rect(Rect2(ov.position.x, ov.end.y - float(i + 1) * hh, ov.size.x, hh + 1.0), col)
		# a faint central highlight so the sheet reads as a gently curved surface, not flat card
		var midh := ov.size.y * 0.3
		draw_rect(Rect2(ov.position.x, ov.position.y + (ov.size.y - midh) * 0.5, ov.size.x, midh), UiTheme.SCROLL_GRAIN_HI)

	func _frame(ov: Rect2) -> void:
		var bi := _p(6.0)
		var fr := Rect2(ov.position + Vector2(bi, bi), ov.size - Vector2(bi, bi) * 2.0)
		if fr.size.x <= 0.0 or fr.size.y <= 0.0:
			return
		var tw := maxf(1.0, _p(1.4))
		draw_rect(fr, Color(TEAL.r, TEAL.g, TEAL.b, 0.9), false, tw)
		var inset := _p(3.0)
		var fr2 := Rect2(fr.position + Vector2(inset, inset), fr.size - Vector2(inset, inset) * 2.0)
		if fr2.size.x > 0.0 and fr2.size.y > 0.0:
			draw_rect(fr2, Color(GOLD.r, GOLD.g, GOLD.b, 0.8), false, maxf(1.0, _p(1.0)))
		var fl := _p(12.0)
		for cdef in [[fr.position, Vector2(1, 1)], [Vector2(fr.end.x, fr.position.y), Vector2(-1, 1)], [Vector2(fr.position.x, fr.end.y), Vector2(1, -1)], [fr.end, Vector2(-1, -1)]]:
			var p0: Vector2 = cdef[0]
			var d: Vector2 = cdef[1]
			draw_line(p0, p0 + Vector2(fl * d.x, 0.0), Color(GOLD.r, GOLD.g, GOLD.b, 0.95), tw)
			draw_line(p0, p0 + Vector2(0.0, fl * d.y), Color(GOLD.r, GOLD.g, GOLD.b, 0.95), tw)
			draw_line(p0 + Vector2(fl * 0.6 * d.x, 0.0), p0 + Vector2(fl * 0.2 * d.x, fl * 0.6 * d.y), Color(TEAL.r, TEAL.g, TEAL.b, 0.85), maxf(1.0, _p(1.0)))

	func _finial(c: Vector2, cap: float) -> void:
		var r := cap * 1.22
		draw_circle(c, r, BRASS_DK)
		draw_circle(c, r * 0.80, BRASS)
		draw_arc(c, r * 0.54, 0.0, TAU, 22, Color(TEAL.r, TEAL.g, TEAL.b, 0.95), maxf(1.0, _p(1.7)))
		draw_circle(c, r * 0.30, BRASS_DK)
		draw_circle(c - Vector2(r * 0.26, r * 0.30), r * 0.15, UiTheme.SCROLL_GLINT)

	## U62: where the CHRONICLE baseline (the glyph ink bottom - capitals, no descenders) sits on the top rod.
	## One definition, used by the wordmark AND the grain stripe, so the stripe can never be placed
	## by a ratio that font-size rounding breaks (at 150% the ratio 0.75*cap fell 1 px short).
	func _wm_baseline(top_cy: float) -> float:
		var fs := maxi(10, UiTheme.px(17))
		return top_cy + _wordmark_font().get_string_size("CHRONICLE", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).y * 0.32

	## U63: the grain stripe's [top, height] on a rod. ONE definition, read by _dowel's draw AND by
	## tools/_u58_contrast.gd's gate, so the gate asserts what the draw does and not a constant that was
	## only ever true at 100% (the old hard-coded 17.0 floor).
	func _grain_span(cy: float, cap: float, ink_bot: float = -1.0) -> Vector2:
		var gy := cy + cap * UiTheme.SCROLL_GRAIN_OFF
		var gh := maxf(1.0, cap * 0.20)
		if ink_bot >= 0.0:
			gy = maxf(gy, ink_bot)
			gh = clampf(cy + cap - gy, 0.0, gh)
		return Vector2(gy, gh)

	## U64: which rod carries the wordmark. [top, bottom]. The draw reads it at its two _dowel calls and the
	## gate reads it too, so flipping it for the top rod is a red gate, not a silent overlap.
	const ROD_WORDMARK := [true, false]

	## U64: the stripe span of a rod AS DRAWN - resolves the wordmark baseline itself, so there is no
	## ink_bot argument at a call site to forget. _dowel draws from this; tools/_u58_contrast.gd gates it.
	func _dowel_grain(cy: float, cap: float, has_wordmark: bool) -> Vector2:
		return _grain_span(cy, cap, _wm_baseline(cy) if has_wordmark else -1.0)

	func _dowel(cy: float, cap: float, has_wordmark: bool = false) -> void:
		var s := size
		var x0 := _p(1.0)
		var x1 := s.x - _p(1.0)
		var wdt := x1 - x0
		_vgrad(Rect2(x0, cy - cap, wdt, cap), WOOD_DK, WOOD_LT, 4)
		_vgrad(Rect2(x0, cy, wdt, cap), WOOD_LT, WOOD_DK, 4)
		var gs := _dowel_grain(cy, cap, has_wordmark)
		draw_rect(Rect2(x0, gs.x, wdt, gs.y), UiTheme.SCROLL_GRAIN)
		draw_line(Vector2(x0, cy - cap), Vector2(x1, cy - cap), UiTheme.SCROLL_RULE, 1.0)
		draw_line(Vector2(x0, cy + cap), Vector2(x1, cy + cap), UiTheme.SCROLL_RULE, 1.0)
		_finial(Vector2(x0 + cap, cy), cap)
		_finial(Vector2(x1 - cap, cy), cap)

	## L61: the wordmark is set in Gloock (SIL OFL, same face as the hub; assets/fonts has the
	## licence). Loaded once from bytes so no editor import is needed; falls back to the engine
	## font if the file is missing.
	static var _gloock: Font = null
	static func _wordmark_font() -> Font:
		if _gloock == null:
			var path := "res://assets/fonts/gloock-latin-400.woff2"
			if FileAccess.file_exists(path):
				var ff := FontFile.new()
				ff.data = FileAccess.get_file_as_bytes(path)
				_gloock = ff
			else:
				_gloock = ThemeDB.fallback_font
		return _gloock

	func _header(g: Dictionary) -> void:
		var s := size
		var cap: float = g.cap
		var top_cy: float = g.top_cy
		var font: Font = _wordmark_font()
		var fs := maxi(10, UiTheme.px(17))
		var word := "CHRONICLE"
		var wsz := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var wx := (s.x - wsz.x) * 0.5
		var wy := _wm_baseline(top_cy)
		# L61: gilt on the dark wood (the burn-brown wordmark vanished into the spindle at 1080p)
		draw_string(font, Vector2(wx + 1.0, wy + 1.5), word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiTheme.WORD_SHADOW)
		draw_string(font, Vector2(wx, wy), word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiTheme.WORD_HI)
		# a teal wax-seal medallion with a gold jester diamond, on the top rod at the left
		var sx: float = g.sx0 + cap * 0.6
		var sy := top_cy
		var sr := cap * 0.92
		draw_circle(Vector2(sx, sy), sr, UiTheme.SCROLL_SEAL)
		draw_circle(Vector2(sx, sy), sr * 0.82, TEAL)
		var dd := sr * 0.52
		draw_colored_polygon(PackedVector2Array([Vector2(sx, sy - dd), Vector2(sx + dd, sy), Vector2(sx, sy + dd), Vector2(sx - dd, sy)]), GOLD)
		draw_circle(Vector2(sx, sy - dd), sr * 0.13, UiTheme.SCROLL_SEAL_PIP)
		draw_circle(Vector2(sx, sy + dd), sr * 0.13, UiTheme.SCROLL_SEAL_PIP)

	func _draw() -> void:
		var s := size
		if s.x < 16.0 or s.y < 16.0:
			return
		var g := _geo()
		var cap: float = g.cap
		var ov := _ov(g)
		if ov.size.x <= 0.0 or ov.size.y <= 0.0:
			return
		# soft drop shadow (the whole sheet lifts off the panes)
		draw_colored_polygon(_sheet_poly(g, _p(3.0), _p(4.0)), UiTheme.SCROLL_SHEET_SHADOW)
		# the parchment silhouette: a wavy, deckled, slightly sagging polygon - NOT a rectangle
		draw_colored_polygon(_sheet_poly(g, 0.0, 0.0), CREAM)
		_side_shade(ov, _p(34.0))
		_fibre(ov)
		_foxing(ov)
		_curl(ov, cap)
		_frame(ov)
		# a soft inked edge along the deckled sides so they read as free paper edges
		var edge := _sheet_poly(g, 0.0, 0.0)
		draw_polyline(edge, Color(TAN_DK.r, TAN_DK.g, TAN_DK.b, 0.6), maxf(1.0, _p(1.2)))
		# the two spindles overhang the sheet; their finials cap the rod ends
		_dowel(g.top_cy, cap, ROD_WORDMARK[0])
		_dowel(g.bot_cy, cap, ROD_WORDMARK[1])
		_header(g)
		_town_band()

## ---------------------------------------------------------------- U104 the mana strip
## One blue bar per hero who draws on a pool (Roster S64: h["mana"] / h["mana_max"]). A hero who
## publishes mana_max 0 gets NO row - never an empty bar - and a party with no caster gets no
## strip. Lives bottom-right of the pane showing the delve (full screen: bottom-right above the
## chrome), clear of the party frames' bottom-left. Blue is Mr. E's potion colour key for mana.
class ManaStrip extends CanvasLayer:
	const MANA_FILL := Color(0.22, 0.44, 0.92)
	const MANA_BG := Color(0.08, 0.12, 0.30, 0.92)
	const W := 300.0
	var town: Node
	var _plates := {}           # pane key -> PanelContainer
	var _poll := 0.0

	func _ready() -> void:
		name = "ManaStrip"
		layer = 20
		UiTheme.watch(self)

	func restyle() -> void:
		_poll = 0.0
		_drop()

	func _drop() -> void:
		for k in _plates:
			if is_instance_valid(_plates[k]):
				(_plates[k] as Node).queue_free()
		_plates.clear()

	## the casters of one delve: [[name, mana, mana_max], ...] in party order
	static func casters(d: Delve) -> Array:
		var out: Array = []
		for m: Dictionary in d.party:
			var h: Dictionary = m.get("h", {})
			var mx := float(h.get("mana_max", 0.0))
			if mx <= 0.0 or float(m.get("hp", 0.0)) <= 0.0:
				continue
			out.append([String(h.get("name", "?")), float(h.get("mana", mx)), mx])
		return out

	func _row(c: Array) -> Control:
		var box := Control.new()
		box.custom_minimum_size = Vector2(UiTheme.px(W), UiTheme.px(26))
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var b := UiTheme.bar(c[1], c[2], 26)
		var bg := (b.get_theme_stylebox("background") as StyleBoxFlat).duplicate()
		bg.bg_color = MANA_BG
		var fg := (b.get_theme_stylebox("fill") as StyleBoxFlat).duplicate()
		fg.bg_color = MANA_FILL if c[1] >= Roster.MANA_COST else MANA_FILL.darkened(0.45)
		b.add_theme_stylebox_override("background", bg)
		b.add_theme_stylebox_override("fill", fg)
		b.set_anchors_preset(Control.PRESET_FULL_RECT)
		box.add_child(b)
		var nm := UiTheme.label(String(c[0]), 20, Color(0.86, 0.92, 1.0))
		nm.add_theme_color_override("font_outline_color", UiTheme.INK)
		nm.add_theme_constant_override("outline_size", UiTheme.px(5))
		nm.clip_text = true
		nm.set_anchors_preset(Control.PRESET_FULL_RECT)
		nm.offset_left = UiTheme.px(8)
		nm.offset_right = -UiTheme.px(70)
		nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		box.add_child(nm)
		var num := UiTheme.label("%d/%d" % [int(floor(c[1])), int(c[2])], UiTheme.SMALL, Color(1, 1, 1))
		num.add_theme_color_override("font_outline_color", UiTheme.INK)
		num.add_theme_constant_override("outline_size", UiTheme.px(4))
		num.set_anchors_preset(Control.PRESET_FULL_RECT)
		num.offset_right = -UiTheme.px(8)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		box.add_child(num)
		return box

	func _build(rows: Array) -> PanelContainer:
		var p := PanelContainer.new()
		var sb := UiTheme.parchment(4)
		sb.set_content_margin_all(UiTheme.px(8))
		p.add_theme_stylebox_override("panel", sb)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", UiTheme.px(3))
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(v)
		v.add_child(UiTheme.label("Mana", UiTheme.SMALL, UiTheme.INK_SOFT))
		for c in rows:
			v.add_child(_row(c))
		return p

	func _process(delta: float) -> void:
		if town == null:
			return
		_poll -= delta / maxf(Engine.time_scale, 0.001)
		if _poll > 0.0:
			return
		_poll = 0.25
		var groups := {}              # pane key ("full" when not split) -> rows
		var sp := HudDock.split(town)
		for c in town.get_children():
			if not (c is Delve) or (c as Delve).party.is_empty() or (c as Delve).dun == null or not is_instance_valid((c as Delve).dun):
				continue
			var k := HudDock.pane_for_delve(town, c) if sp else "full"
			if k == "":
				continue
			var rows := casters(c)
			if rows.is_empty():
				continue
			if not groups.has(k):
				groups[k] = []
			(groups[k] as Array).append_array(rows)
		for k in _plates.keys():
			if not groups.has(k):
				if is_instance_valid(_plates[k]):
					(_plates[k] as Node).queue_free()
				_plates.erase(k)
		for k in groups:
			if _plates.has(k) and is_instance_valid(_plates[k]):
				(_plates[k] as Node).queue_free()
			var p := _build((groups[k] as Array).slice(0, 6))
			add_child(p)
			_plates[k] = p
			_place(p, k, sp)

	func _place(p: PanelContainer, k: String, sp: bool) -> void:
		p.size = p.get_combined_minimum_size()
		if sp:
			HudDock.mark(p, k)
			HudDock.put(p, HudDock.pane(town, k), HudDock.pane_k(town, k), "br")
			_clear_of_boss(p, HudDock.pane(town, k))
		else:
			HudDock.mark(p, "full")
			p.scale = Vector2.ONE
			var sc := HudDock.screen()
			p.position = Vector2(roundf(sc.x - p.size.x - float(UiTheme.px(12))), roundf(sc.y - p.size.y - float(UiTheme.px(12))))

	## U106: at 150% the boss card (810x200, not my file) covers the plate that put() docked
	## "br" - the plate was MEASURED on screen but drawn UNDER the card. Slide it to the first
	## spot in the pane that touches neither the boss card nor the Chronicle box.
	func _clear_of_boss(p: PanelContainer, r: Rect2) -> void:
		## U108: blockers are the boss card AND the NOW FIGHTING banner (group hud_fightbanner,
		## both read-only), every visible one, not just the last boss plate seen.
		var blk: Array[Rect2] = []
		for g in ["hud_boss", "hud_fightbanner"]:
			for b in get_tree().get_nodes_in_group(g):
				var pl = b.get("_plate")
				if pl is Control and (pl as Control).is_visible_in_tree():
					var xf := (pl as Control).get_global_transform()
					blk.append(Rect2(xf.origin, (pl as Control).size * xf.get_scale()))
		if blk.is_empty():
			return
		var m := float(UiTheme.px(12))
		var sz := p.size * p.scale
		var hit := false
		for bb in blk:
			if Rect2(p.position, sz).intersects(bb):
				hit = true
		if not hit:
			return
		var box := HudDock.centre(town)
		var ys := [r.end.y - m - sz.y]
		for bb in blk:
			ys.append(bb.end.y + m)
		var xs := [r.end.x - m - sz.x, r.position.x + m]
		for y: float in ys:
			for x: float in xs:
				var q := Rect2(Vector2(x, y), sz)
				if y + sz.y > r.end.y or y < r.position.y:
					continue
				var bad := false
				for bb in blk:
					if q.intersects(bb):
						bad = true
				if bad:
					continue
				if box.size.x > 0.0 and q.intersects(box):
					continue
				p.position = Vector2(roundf(x), roundf(y))
				return

## ---------------------------------------------------------------- L31 the fight banner
## "NOW FIGHTING / <the lord>": a parchment banner that announces a lord the moment it rises
## and holds a few seconds, in the lord's own colour. It lives where the boss card lives -
## docked in the pane showing the fight, directly UNDER the boss card, never across a seam or
## the Chronicle (HudDock.put keeps it clear of both) - and at full screen below the boss bar.
class FightBanner extends CanvasLayer:
	const HOLD := 6.0           # real seconds on screen
	const FADE := 1.0
	var town: Node
	var _plate: PanelContainer
	var _sb: StyleBoxFlat
	var _kick: Label
	var _nm: Label
	var _sub: Label
	var _lord_id := 0
	var _t := 0.0               # seconds left; 0 = hidden
	var _poll := 0.0

	func _ready() -> void:
		name = "FightBanner"
		layer = 21
		add_to_group("hud_fightbanner")
		UiTheme.watch(self)
		_build()

	func restyle() -> void:
		if _plate:
			var keep := [_kick.text, _nm.text, _sub.text, _nm.get_theme_color("font_color"), _sb.border_color]
			remove_child(_plate)
			_plate.queue_free()
			_build()
			_kick.text = keep[0]; _nm.text = keep[1]; _sub.text = keep[2]
			_nm.add_theme_color_override("font_color", keep[3]); _sb.border_color = keep[4]

	func _lab(size: int, col: Color) -> Label:
		var lb := Label.new()
		lb.add_theme_font_size_override("font_size", UiTheme.px(size))
		lb.add_theme_color_override("font_color", col)
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return lb

	func _build() -> void:
		_plate = PanelContainer.new()
		_sb = UiTheme.parchment(4)
		_sb.set_content_margin_all(UiTheme.px(10))
		_plate.add_theme_stylebox_override("panel", _sb)
		_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_plate.visible = false
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", UiTheme.px(0))
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_plate.add_child(v)
		_kick = _lab(20, UiTheme.INK_RED)
		_nm = _lab(40, UiTheme.INK)
		_sub = _lab(20, UiTheme.INK_SOFT)
		for l in [_kick, _nm, _sub]:
			v.add_child(l)
		add_child(_plate)

	## the lord to announce: a viewers' party's first, then the town's band's
	func _find() -> Array:
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

	func _process(delta: float) -> void:
		if town == null or _plate == null:
			return
		var rd := delta / maxf(Engine.time_scale, 0.001)
		_poll -= rd
		if _poll <= 0.0:
			_poll = 0.2
			var f := _find()
			if f.is_empty():
				_lord_id = 0
			else:
				var l: Monster = f[1]
				if l.get_instance_id() != _lord_id:
					_lord_id = l.get_instance_id()
					_announce(f[0], l)
		if _t > 0.0:
			_t = maxf(0.0, _t - rd)
		_plate.visible = _t > 0.0
		if not _plate.visible:
			HudDock.mark(_plate, "none")
			return
		_plate.modulate.a = clampf(minf(_t / FADE, (HOLD - _t) / 0.3), 0.0, 1.0)
		_place()

	var _delve: Delve = null
	func _announce(d: Delve, l: Monster) -> void:
		_delve = d
		var col: Color = l.def.get("aura", UiTheme.AURA_DEFAULT)
		_kick.text = "NOW FIGHTING"
		_nm.text = String(l.def.get("name", "A lord"))
		_nm.add_theme_color_override("font_color", col.darkened(0.55))
		_sb.border_color = col.darkened(0.15)
		var rare := bool(l.def.get("unique", false)) or bool(l.def.get("rare", false))
		_sub.text = ("A rare one" if rare else "Lord of the deep") + "  -  " + ("the town's band" if d.npc_party else "the delvers")
		_t = HOLD

	func _over_card() -> bool:
		var pr := Rect2(_plate.position, _plate.size * _plate.scale)
		for b in _plate.get_tree().get_nodes_in_group("hud_boss"):
			if b is Control and (b as Control).visible and pr.intersects(Rect2((b as Control).position, (b as Control).size * (b as Control).scale)):
				return true
		return false

	## under the boss card, in the pane showing this fight; full screen: below the boss bar
	func _place() -> void:
		var s := _plate.get_combined_minimum_size()
		_plate.size = s
		if HudDock.split(town):
			var k := HudDock.pane_for_delve(town, _delve) if _delve and is_instance_valid(_delve) else ""
			if k == "":
				_plate.visible = false
				HudDock.mark(_plate, "none")
				return
			HudDock.mark(_plate, k)
			var r := HudDock.pane(town, k)
			var pad := float(UiTheme.px(54))
			for b in _plate.get_tree().get_nodes_in_group("hud_boss"):
				## U117: a card wider than its pane docks at a NEGATIVE x (card -20,140 in a 960 pane at 150%), so the old
				## has_point(position) test missed it and the banner sat under the card. Test the card's drawn rect.
				if b is Control and (b as Control).visible and r.intersects(Rect2((b as Control).position, (b as Control).size * (b as Control).scale)):
					pad = maxf(pad, (b as Control).position.y + (b as Control).size.y * (b as Control).scale.y - r.position.y + float(UiTheme.px(8)))
			HudDock.put(_plate, r, HudDock.pane_k(town, k), "tc", pad)
			## U117: put() keeps it clear of the Chronicle box, and at 150% in a 2x2 pane there is no room for
			## card + banner above that box, so it lands UNDER the card (73k px2 overlap, the "ghost"). The card
			## already names the lord and its hp: the banner yields for the fight rather than draw behind it.
			if _over_card():
				_plate.visible = false
				HudDock.mark(_plate, "none")
		else:
			HudDock.mark(_plate, "full")
			_plate.scale = Vector2.ONE
			var y := float(UiTheme.px(140))
			for b in _plate.get_tree().get_nodes_in_group("hud_boss"):
				if b is Control and (b as Control).visible:
					y = maxf(y, (b as Control).position.y + (b as Control).size.y * (b as Control).scale.y + float(UiTheme.px(8)))
			_plate.position = Vector2(roundf((HudDock.screen().x - s.x) * 0.5), roundf(y))
