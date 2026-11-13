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
## problem was the TEXT, so feed_hud shrank the font first and the box is sized to the
## smaller text. CENTRE_W is well under half the screen, so the box can only ever cover the
## inner CORNERS of the panes it touches.
const STRIP := 0.12            # the box's height, as a share of the screen
const CENTRE_W := 0.34         # the box's width - well under half the screen (L39)
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
