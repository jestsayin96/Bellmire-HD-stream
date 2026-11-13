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
const CENTRE_W := 0.372        # L39b: the box's width - ~0.37, a touch wider, still under half
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
	const CREAM := Color(0.960, 0.910, 0.770)
	const TAN := Color(0.865, 0.760, 0.555)
	const TAN_DK := Color(0.660, 0.520, 0.330)
	const WOOD_LT := Color(0.560, 0.405, 0.235)
	const WOOD_DK := Color(0.250, 0.160, 0.085)
	const BRASS := Color(0.780, 0.635, 0.340)
	const BRASS_DK := Color(0.360, 0.275, 0.130)
	const GOLD := Color(0.840, 0.670, 0.310)
	const TEAL := Color(0.10, 0.62, 0.62)
	const BURN := Color(0.190, 0.110, 0.065)

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

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
		var inx := _p(9.0)
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
			draw_circle(c, rr, Color(0.55, 0.40, 0.22, 0.05))
			draw_circle(c, rr * 0.6, Color(0.48, 0.34, 0.18, 0.05))

	## the paper visibly furls under each rod: a strong dark gradient band hugging the rods
	func _curl(ov: Rect2, cap: float) -> void:
		var n := 7
		var hh := (cap * 1.55) / float(n)
		for i in n:
			var k := 1.0 - float(i) / float(n)
			var col := Color(0.22, 0.14, 0.07, 0.5 * k)
			draw_rect(Rect2(ov.position.x, ov.position.y + float(i) * hh, ov.size.x, hh + 1.0), col)
			draw_rect(Rect2(ov.position.x, ov.end.y - float(i + 1) * hh, ov.size.x, hh + 1.0), col)
		# a faint central highlight so the sheet reads as a gently curved surface, not flat card
		var midh := ov.size.y * 0.3
		draw_rect(Rect2(ov.position.x, ov.position.y + (ov.size.y - midh) * 0.5, ov.size.x, midh), Color(1, 1, 1, 0.04))

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
		draw_circle(c - Vector2(r * 0.26, r * 0.30), r * 0.15, Color(0.97, 0.90, 0.64, 0.75))

	func _dowel(cy: float, cap: float) -> void:
		var s := size
		var x0 := _p(1.0)
		var x1 := s.x - _p(1.0)
		var wdt := x1 - x0
		_vgrad(Rect2(x0, cy - cap, wdt, cap), WOOD_DK, WOOD_LT, 4)
		_vgrad(Rect2(x0, cy, wdt, cap), WOOD_LT, WOOD_DK, 4)
		draw_rect(Rect2(x0, cy - cap * 0.5, wdt, maxf(1.0, cap * 0.20)), Color(0.68, 0.52, 0.31, 0.55))
		draw_line(Vector2(x0, cy - cap), Vector2(x1, cy - cap), Color(0.16, 0.10, 0.05, 0.85), 1.0)
		draw_line(Vector2(x0, cy + cap), Vector2(x1, cy + cap), Color(0.16, 0.10, 0.05, 0.85), 1.0)
		_finial(Vector2(x0 + cap, cy), cap)
		_finial(Vector2(x1 - cap, cy), cap)

	func _header(g: Dictionary) -> void:
		var s := size
		var cap: float = g.cap
		var top_cy: float = g.top_cy
		var font := ThemeDB.fallback_font
		var fs := maxi(10, UiTheme.px(15))
		var word := "CHRONICLE"
		var wsz := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var wx := (s.x - wsz.x) * 0.5
		var wy := top_cy + wsz.y * 0.32
		draw_string(font, Vector2(wx + 1.0, wy + 1.0), word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.70, 0.55, 0.32, 0.8))
		draw_string(font, Vector2(wx, wy), word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, BURN)
		# a teal wax-seal medallion with a gold jester diamond, on the top rod at the left
		var sx: float = g.sx0 + cap * 0.6
		var sy := top_cy
		var sr := cap * 0.92
		draw_circle(Vector2(sx, sy), sr, Color(0.06, 0.40, 0.40))
		draw_circle(Vector2(sx, sy), sr * 0.82, TEAL)
		var dd := sr * 0.52
		draw_colored_polygon(PackedVector2Array([Vector2(sx, sy - dd), Vector2(sx + dd, sy), Vector2(sx, sy + dd), Vector2(sx - dd, sy)]), GOLD)
		draw_circle(Vector2(sx, sy - dd), sr * 0.13, Color(0.97, 0.85, 0.48))
		draw_circle(Vector2(sx, sy + dd), sr * 0.13, Color(0.97, 0.85, 0.48))

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
		draw_colored_polygon(_sheet_poly(g, _p(3.0), _p(4.0)), Color(0, 0, 0, 0.30))
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
		_dowel(g.top_cy, cap)
		_dowel(g.bot_cy, cap)
		_header(g)

