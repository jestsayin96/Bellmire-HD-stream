extends Node
class_name HudDock
## L21 (Mr. E, Nov 11): the interface over the spotlight panes. While more than one view is on
## screen, NO HUD element may cross a pane seam or float over a pane it does not belong to.
## Every element is either docked INSIDE one pane (scaled to it) or sits in the reserved
## CHROME bar across the bottom that no pane covers. Full screen (no lanes) is untouched.
##
##   chrome bar   the bottom CHROME of the screen in the side-by-side and the 2x2: the
##                Chronicle (full width, L15 size), the clock / the local chat box at its right
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

const CHROME := 0.15
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
	c.position = Vector2(roundf(x), roundf(y))

## undo put(): anchors are set again by the owner's own full-screen placement
static func unput(c: Control) -> void:
	c.scale = Vector2.ONE
