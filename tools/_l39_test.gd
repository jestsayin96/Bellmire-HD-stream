extends SceneTree
## L39 (Mr. E, Nov 12, with a reference screenshot): THE CHRONICLE IS A COMPACT CENTRE BOX,
## NOT A BAR. This REPLACES L32b's full-width tan band, which he rejected. Checked windowed
## (--resolution 1920x1080; a HUD cannot be judged headless - COORDINATION 4):
##   1. the box is COMPACT - well under half the screen width, and not a band of any kind
##   2. it is CENTRED on the cross of the 2x2, within a pixel
##   3. the two pane rows MEET at that cross (L32b's parting band is gone) and the box
##      overlaps only the four pane CORNERS - every pane keeps most of itself clear
##   4. the Chronicle panel sits inside the box, shows at least 2 lines at the L15 size,
##      and L32b's calm pacing still holds (a flood does not scroll like crazy)
##   5. a lord's name card still fits inside the box
## Prints L39_TEST OK / FAIL and leaves 1080p shots in renders/cycles/20261112_l39/.
var _t: Node3D
var _eye: RtsCamera
var _f := 0
var _fails: Array = []
var _checks := 0
var _stage := "boot"
var _seen_max := 0
var _pace_n := 0
var _shots := not DisplayServer.get_name().to_lower().contains("headless")
const OUT := "res://renders/cycles/20261112_l39"

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

			# 1. compact, and not a band
			_ok(box.size.x < s.x * 0.5,
				"COMPACT: the box is well under half the screen width (%d px of %d, %.0f%%)"
				% [int(box.size.x), int(s.x), 100.0 * box.size.x / s.x])
			_ok(box.size.x <= s.x * 0.40, "the box is not a wide band (%.0f%% of the width)" % [100.0 * box.size.x / s.x])
			_ok(box.size.y >= s.y * 0.07, "the box is tall enough for its lines (%d px)" % int(box.size.y))

			# 2. centred on the cross
			var cross := Vector2(s.x * 0.5, s.y * (1.0 - HudDock.CHROME) * 0.5)
			_ok(absf(box.get_center().x - cross.x) <= 1.0, "the box is centred across (%.1f vs %.1f)" % [box.get_center().x, cross.x])
			_ok(absf(box.get_center().y - cross.y) <= 1.0, "the box is centred on the cross (%.1f vs %.1f)" % [box.get_center().y, cross.y])

			# 3. the pane rows MEET at the cross, and the box only clips their corners
			var dr := sp.pane_rect("director")
			var su := sp.pane_rect("subs")
			_ok(absf(dr.end.y - su.position.y) <= 1.0,
				"the pane rows meet at the cross - no parting band (top ends %.1f, bottom starts %.1f)" % [dr.end.y, su.position.y])
			for k in ["director", "bits", "subs", "points"]:
				var r := sp.pane_rect(k)
				if r.size.x <= 0.0:
					continue
				var ov := r.intersection(box)
				var frac := (ov.size.x * ov.size.y) / maxf(1.0, r.size.x * r.size.y)
				_ok(frac < 0.12, "%s pane: the box covers only its corner (%.1f%% of the pane)" % [k, frac * 100.0])

			# 4. the Chronicle is in the box
			var p := _chron()
			_ok(p != null, "the Chronicle panel exists")
			if p != null:
				_ok(HudDock.region_of(p) == "centre", "the Chronicle is docked to the centre region")
				var pr := p.get_global_rect()
				_ok(box.encloses(pr) or box.grow(2.0).encloses(pr), "the Chronicle panel sits inside the box (%s in %s)" % [pr, box])
			_grab("box_idle")
			# flood it: calm pacing must still hold
			for i in 30:
				_say("3901", "Ashvein", "!say a trade caravan is sighted on the west road %d" % i)
			_stage = "flood"
		"flood":
			var p := _chron()
			if p != null:
				_seen_max = maxi(_seen_max, _lines(p).size())
			_pace_n += 1
			if _pace_n < 150:
				return false
			var pn := _chron()
			if pn != null:
				var ls := _lines(pn)
				_ok(ls.size() >= 2, "the box shows at least 2 lines (%d)" % ls.size())
				var big := 0
				for l in ls:
					big = maxi(big, (l as Label).get_theme_font_size("font_size"))
				_ok(big >= UiTheme.px(28) - 1, "lines at the L15 size (%d px)" % big)
				var box2 := HudDock.centre(_t)
				var spill := 0
				for l in ls:
					if not box2.grow(2.0).encloses((l as Label).get_global_rect()):
						spill += 1
				_ok(spill == 0, "no line spills out of the box under a flood (%d of %d)" % [spill, ls.size()])
				_ok(_seen_max <= 4, "calm pacing: the box never stacked more than 4 lines (%d)" % _seen_max)
			_grab("box_flood")
			# 5. a lord's card must still fit
			FeedHUD.card_on(_t, "The Hollow Lord", "stirs in the deep", Color(0.7, 0.3, 0.9))
			_stage = "card"
		"card":
			_pace_n += 1
			if _pace_n < 180:
				return false
			var p := _chron()
			var box3 := HudDock.centre(_t)
			if p != null:
				var pr := p.get_global_rect()
				_ok(box3.grow(2.0).encloses(pr), "with a lord's card up the Chronicle still fits the box (%s in %s)" % [pr, box3])
			_grab("box_lord_card")
			print("CHECKS ", _checks, " FAILS ", _fails.size())
			for f in _fails:
				print("  - ", f)
			print("L39_TEST ", "OK" if _fails.is_empty() else "FAIL")
			return true
	return false
