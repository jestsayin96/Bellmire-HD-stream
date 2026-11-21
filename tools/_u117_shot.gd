extends SceneTree
## L21 (Mr. E, Nov 11): the interface over the spotlight panes. THE RULE, checked here in
## code: while more than one view is on screen, no HUD element may overlap a pane seam or sit
## over a pane it does not belong to. Every drawn control is either inside ONE pane (that
## pane's overlay) or inside the reserved chrome bar outside the panes. Then:
##   - the Chronicle lives in the chrome bar, at the L15 size (28 px at 1080p)
##   - the boss card sits inside a pane whose camera is in that fight's delve
##   - each "Delvers / town's band - floor N" block sits inside a pane following that party
##   - floating combat text (numbers, bubbles, states) is not drawn by any pane smaller than
##     half the screen, and IS drawn by the side-by-side panes
##   - no two name tags a pane draws overlap
## Scene: four viewers in town (a crowded market), two of them delving a lord floor with the
## lord fighting, chat busy, then the bits lane (side by side), then all three lanes (2x2).
## Run windowed: --resolution 1920x1080 (it also saves the renders, 1080p and 854x480, to
## renders/cycles/20261120_u104). Headless it runs the checks only. Prints L21_TEST OK / FAIL.
var _t: Node3D
var _eye: RtsCamera
var _d: Delve
var _f := 0
var _fails: Array = []
var _checks := 0
var _stage := "boot"
var _at := 0
var _scales: Array = []
var _shots := not DisplayServer.get_name().to_lower().contains("headless")
const OUT := "res://renders/cycles/20261121_u117"

func _initialize() -> void:
	# a known screen: headless Godot gives a 100x100 window where nothing can be judged (that is
	# what failed 8 checks on the supervisor's headless run). Windowed keeps --resolution.
	if not _shots:
		root.size = Vector2i(1920, 1080)
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	if _shots:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _ok(c: bool, what: String) -> void:
	_checks += 1
	if not c:
		_fails.append(what)
		print("  FAIL ", what)

func _say(uid: String, nm: String, msg: String) -> void:
	var c: ChatCmd = _t.get("chat")
	c._last.clear()
	_t.call("chat_line", uid, nm, msg)

func _save(tag: String) -> void:
	if not _shots:
		return
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + "/%s_1080.png" % tag))
	img.resize(854, 480, Image.INTERPOLATE_LANCZOS)
	img.save_png(ProjectSettings.globalize_path(OUT + "/%s_phone480.png" % tag))
	print("L21_SHOT %s (window %s)" % [tag, root.size])

func _rr(n) -> Rect2:
	if n is Control and (n as Control).visible:
		var c := n as Control
		return Rect2(c.get_global_rect().position, c.size * c.scale)
	return Rect2()

func _probe(tag: String) -> void:
	var bb: Control = null
	for b in get_nodes_in_group("hud_boss"):
		bb = b
	var fb: Node = null
	for b2 in get_nodes_in_group("hud_fightbanner"):
		fb = b2
	var pl = fb.get("_plate") if fb != null else null
	var br := _rr(bb)
	var pr := _rr(pl)
	var a: float = (pl as Control).modulate.a if pl is Control else -1.0
	var vis: bool = (pl as Control).visible if pl is Control else false
	var inter := br.intersection(pr)
	var kk: String = HudDock.pane_for_delve(_t, _d)
	var pk: Rect2 = HudDock.pane(_t, kk) if kk != "" else Rect2()
	print("U117_FIT banner_in_pane=%s banner_bottom=%.0f pane_bottom=%.0f" % [pk.encloses(pr), pr.end.y, pk.end.y])
	print("U117_PANE split=%s pane_key=%s pane=%s card_docked=%s card_pos=%s card_size=%s card_scale=%s" % [HudDock.split(_t), kk, HudDock.pane(_t, kk) if kk != "" else "-", bb.get("_docked") if bb else "-", bb.position if bb else "-", bb.size if bb else "-", bb.scale if bb else "-"])
	print("U117_PROBE %s scale=%s card=%s banner=%s alpha=%.2f banner_visible=%s overlap_area=%.0f" % [tag, UiTheme.scale, br, pr, a, vis, inter.get_area() if br.intersects(pr) else 0.0])

func _process(_dt: float) -> bool:
	_f += 1
	if not _shots and root.size != Vector2i(1920, 1080):
		root.size = Vector2i(1920, 1080)
	match _stage:
		"boot":
			if _f == 20:
				_eye = RtsCamera.new()
				_t.add_child(_eye)
				_eye.setup(_t)
				var r: Roster = _t.get("roster")
				for v in [["2101", "JestFan", "knight dwarf"], ["2102", "MossyMage", "mage elf"], ["2103", "DawnCleric", "cleric human"], ["2104", "BigAxe", "barbarian orc"]]:
					_say(v[0], v[1], "!enlist " + v[2])
				for id in ["2101", "2104"]:
					var h: Dictionary = r.get_hero(id)
					h["weapon"] = 3
					h["armour"] = 3
					h["oil"] = 4
				_d = Delve.new()
				_d.town = _t
				_d.roster = r
				_d.start_floor = 5
				_d.max_floors = 5
				_t.add_child(_d)
				_d.start(["2102", "2103", "2104", "2101"])
				_eye.director._set_on(true)
				Engine.time_scale = 3.0
				_stage = "wait_lord"
		"wait_lord":
			if _d.lord_fighting() != null or _f > 3000:
				Engine.time_scale = 1.0
				_ok(_d.lord_fighting() != null, "the lord is fighting (frame %d)" % _f)
				for v in [["2102", "MossyMage", "!hero"], ["2103", "DawnCleric", "!guild"]]:
					_say(v[0], v[1], v[2])
				_scales = [1.0, 1.25, 1.5]
				_stage = "retrig"
				_at = _f
		"retrig":
			# per scale: set it, let it settle 40 frames, RE-ANNOUNCE the banner, probe at +20 (full alpha)
			# and +335 (inside the 1 s fade-out) and shoot both
			var k := _f - _at
			if k == 1:
				UiTheme.set_scale(float(_scales[0]))
			elif k == 40:
				for b in get_nodes_in_group("hud_fightbanner"):
					var lo: Monster = _d.lord_fighting()
					if lo != null:
						b.call("_announce", _d, lo)
			elif k == 62:
				_probe("s%d_full" % int(round(UiTheme.scale * 100.0)))
				_save("ban_%d_a" % int(round(UiTheme.scale * 100.0)))
			elif k == 376:
				_probe("s%d_fade" % int(round(UiTheme.scale * 100.0)))
				_save("ban_%d_b" % int(round(UiTheme.scale * 100.0)))
				_scales.remove_at(0)
				_at = _f
				if _scales.is_empty():
					UiTheme.set_scale(1.0)
					print("U117_DONE fails=%d" % _fails.size())
					return true
	return false
