extends SceneTree
## L39 / L39b (Mr. E, Nov 13, from his annotated 1x screenshot): THE CHRONICLE IS A COMPACT
## CENTRE BOX, and it must be TALL enough to read back several lines - the width was close
## but the old box (652x130) was ~1/3 the height he drew (~715x295). L39b keeps the 18 px
## type (he rejected the "super huge" 28 px) and uses the extra height for MORE LINES, not
## bigger letters. Checked WINDOWED (--resolution 1920x1080; a HUD cannot be judged headless
## - COORDINATION 4):
##   1. the box is COMPACT in width (well under half the screen) and not a band
##   2. the box is TALL now (~0.27 of the screen), centred on the cross of the 2x2
##   3. the two pane rows MEET at that cross and the box overlaps only the pane CORNERS
##   4. the Chronicle sits inside the box, the type is SMALL (18 px, not 28), and the box
##      holds 8-9 lines so a flood fills it without any line spilling out
##   5. a lord's name card still fits inside the taller box
## Prints L39_TEST OK / FAIL and leaves 1080p shots in renders/cycles/20261113_l39b/.
var _t: Node3D
var _eye: RtsCamera
var _f := 0
var _fails: Array = []
var _checks := 0
var _stage := "boot"
var _shots := not DisplayServer.get_name().to_lower().contains("headless")
const OUT := "res://renders/cycles/20261113_l39b"

func _initialize() -> void:
	if not _shots:
		root.size = Vector2i(1920, 1080)
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	if _shots:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _say(uid: String, nm: String, msg: String) -> void:
	(_t.get("chat") as ChatCmd)._last.erase(uid)
	_t.call("chat_line", uid, nm, msg)

func _grab(tag: String) -> void:
	if not _shots:
		return
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + "/%s_1080.png" % tag))

func _chron() -> Control:
	for n in get_nodes_in_group("hud_chronicle"):
		if is_instance_valid(n) and n is Control:
			return n as Control
	return null

func _feed() -> FeedHUD:
	for c in _t.get_children():
		if c is FeedHUD:
			return c as FeedHUD
	return null

## every Label under the Chronicle that is actually showing a line
func _lines(p: Control) -> Array:
	var out: Array = []
	var stack: Array = [p]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
			if c is Label and (c as Label).visible and String((c as Label).text).strip_edges() != "":
				out.append(c)
	return out

func _process(_dt: float) -> bool:
	_f += 1
	if _f == 20:
		_eye = RtsCamera.new()
		_t.add_child(_eye)
		_eye.setup(_t)
		(_t.get("raids") as Raids).set("_raid_t", 99999.0)
		for v in [["3901", "Ashvein", "!enlist knight"], ["3902", "Brelda", "!enlist mage"]]:
			_say(v[0], v[1], v[2])
		return false
	if _f < 70:
		return false

	match _stage:
		"boot":
			var s := Vector2(root.size)
			var box := HudDock.centre(_t)
			var sp := Spotlight.of(_t)
			_ok(box.size.x > 0.0, "the centre box exists (%s)" % box)

			# 1. compact in width, not a band
			_ok(box.size.x < s.x * 0.5,
				"COMPACT width: well under half the screen (%d px of %d, %.0f%%)"
				% [int(box.size.x), int(s.x), 100.0 * box.size.x / s.x])
			_ok(box.size.x <= s.x * 0.42, "not a wide band (%.0f%% of the width)" % [100.0 * box.size.x / s.x])

			# 2. L39b: TALL now, and centred on the cross
			_ok(box.size.y >= s.y * 0.22,
				"TALL: the box is much taller than the old 0.12 band (%d px, %.0f%% of height)"
				% [int(box.size.y), 100.0 * box.size.y / s.y])
			_ok(box.size.y <= s.y * 0.34, "still not a full-height band (%.0f%% of height)" % [100.0 * box.size.y / s.y])
			var cross := Vector2(s.x * 0.5, s.y * (1.0 - HudDock.CHROME) * 0.5)
			_ok(absf(box.get_center().x - cross.x) <= 1.0, "centred across (%.1f vs %.1f)" % [box.get_center().x, cross.x])
			_ok(absf(box.get_center().y - cross.y) <= 1.0, "centred on the cross (%.1f vs %.1f)" % [box.get_center().y, cross.y])

			# 3. pane rows MEET at the cross; the box clips only the corners
			var dr := sp.pane_rect("director")
			var su := sp.pane_rect("subs")
			_ok(absf(dr.end.y - su.position.y) <= 1.0,
				"the pane rows meet at the cross (top ends %.1f, bottom starts %.1f)" % [dr.end.y, su.position.y])
			for k in ["director", "bits", "subs", "points"]:
				var r := sp.pane_rect(k)
				if r.size.x <= 0.0:
					continue
				var ov := r.intersection(box)
				var frac := (ov.size.x * ov.size.y) / maxf(1.0, r.size.x * r.size.y)
				_ok(frac < 0.16, "%s pane: the box covers only its corner (%.1f%% of the pane)" % [k, frac * 100.0])

			# 4a. the Chronicle is in the box
			var p := _chron()
			_ok(p != null, "the Chronicle panel exists")
			if p != null:
				_ok(HudDock.region_of(p) == "centre", "the Chronicle is docked to the centre region")
				var pr := p.get_global_rect()
				_ok(box.grow(2.0).encloses(pr), "the Chronicle panel sits inside the box (%s in %s)" % [pr, box])

			# 4b. L39b capacity: the taller box must hold 8-9 lines
			var fd := _feed()
			_ok(fd != null, "the FeedHUD node exists")
			if fd != null:
				var cap: int = fd._chrome_lines()
				_ok(cap >= 7, "the box holds many lines now (_chrome_lines = %d, was clamped to 4)" % cap)
			_grab("box_idle")

			# fill the Chronicle with real lines so the TALLER box's capacity shows on screen
			# (the pacing cursor reveals 1 line / 0.8 s - too slow to fill in a test window;
			# calm pacing itself is unchanged from L39/L32b and is covered by _l21_test)
			if fd != null:
				for L in [
					"A trade caravan is sighted on the west road.",
					"The forge sits cold - no ore.",
					"Ashvein the Knight descends into the scar.",
					"Floor 3 - the Rattling Host stirs in the dark.",
					"Brelda looses a bolt of frost at a skeleton.",
					"The granary is running low.",
					"A building is burning!",
					"The townsfolk raise the ruin again.",
					"The attack is driven off. The gates hold.",
				]:
					fd.source.append(L)
			if fd != null:
				fd._seen = fd.source.size()
				fd._rebuild()
			_stage = "fill"
			_f = 70
		"fill":
			# get_image() reads the last PRESENTED frame, a step behind a same-frame _rebuild,
			# so let the newly revealed labels lay out and paint before the capture
			var fd2 := _feed()
			if fd2 != null:
				fd2._seen = fd2.source.size()
			if _f < 78:
				return false
			var pn := _chron()
			if pn != null:
				var ls := _lines(pn)
				_ok(ls.size() >= 8, "the taller box fills with 8-9 lines (%d; the old box showed ~3)" % ls.size())
				var big := 0
				for l in ls:
					big = maxi(big, (l as Label).get_theme_font_size("font_size"))
				_ok(big <= UiTheme.px(20), "SMALL type, not the huge 28 px (%d px)" % big)
				_ok(big >= UiTheme.px(14), "type still readable (%d px)" % big)
				var box2 := HudDock.centre(_t)
				var spill := 0
				for l in ls:
					if not box2.grow(3.0).encloses((l as Label).get_global_rect()):
						spill += 1
				_ok(spill == 0, "no line spills out of the box (%d of %d)" % [spill, ls.size()])
			_grab("box_full")
			# 5. a lord's card must still fit
			FeedHUD.card_on(_t, "The Hollow Lord", "stirs in the deep", Color(0.7, 0.3, 0.9))
			_stage = "card"
			_f = 70
		"card":
			if _f < 82:
				return false
			var p := _chron()
			var box3 := HudDock.centre(_t)
			if p != null:
				var pr := p.get_global_rect()
				_ok(box3.grow(3.0).encloses(pr), "with a lord's card up the Chronicle still fits the box (%s in %s)" % [pr, box3])
			_grab("box_lord_card")
			print("CHECKS ", _checks, " FAILS ", _fails.size())
			for f in _fails:
				print("  - ", f)
			print("L39_TEST ", "OK" if _fails.is_empty() else "FAIL")
			return true
	return false
