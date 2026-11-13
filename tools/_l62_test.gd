extends SceneTree
## L61 / L62 / L63 (Mr. E, Nov 13): verify the three HUD items in one windowed pass.
##   L62: each pane carries a readable KIND title (DIRECTOR / BITS / SUBSCRIBER /
##        CHANNEL POINTS, with "(ambient)" on an idle paid lane) above the "Now watching"
##        line, on the pane's outer-top side so it clears the Chronicle box.
##   L61: the centre Chronicle box wears the house parchment / ink / teal / gold aesthetic -
##        the "Chronicle" wordmark, a teal accent rule, two gold diamond pips, deeper edges.
##        Line size (18 px) and 8-9 line capacity kept.
##   L63: leaderboard_panel.gd draws nothing on stream (the Satchel moved to the hub).
## Judged WINDOWED (COORDINATION 4). 1080p shots in renders/cycles/20261113_l62.
var _t: Node3D
var _eye: RtsCamera
var _f := 0
var _stage := "boot"
var _fails: Array = []
var _checks := 0
var _shots := not DisplayServer.get_name().to_lower().contains("headless")
const OUT := "res://renders/cycles/20261113_l62"
var _crew := {"7101": ["Ashvein", "knight"], "7102": ["Brelda", "mage"], "7103": ["Corin", "rogue"], "7104": ["Dax", "ranger"]}

func _initialize() -> void:
	if _shots:
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

func _sp() -> Spotlight:
	return Spotlight.of(_t)

func _grab(tag: String) -> void:
	if not _shots:
		return
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "/%s.png" % tag))

func _kind(k: String) -> Label:
	return (_sp()._panes[k] as Dictionary).get("kind") as Label

func _process(_dt: float) -> bool:
	_f += 1
	if _f == 20:
		_eye = RtsCamera.new()
		_t.add_child(_eye)
		_eye.setup(_t)
		(_t.get("raids") as Raids).set("_raid_t", 99999.0)
		for uid in _crew:
			_say(uid, _crew[uid][0], "!enlist " + _crew[uid][1])
		return false
	if _f < 80:
		return false

	match _stage:
		"boot":
			var sp := _sp()
			sp.put("7101", "bits", 90.0, "cheered 100 bits")
			sp.put("7102", "subs", 90.0, "subscribed")
			sp.put("7103", "points", 90.0, "redeemed a look")
			_eye.director._set_on(true)
			_say("7104", _crew["7104"][0], "!hero")
			# L63: the chronicle gets a few lines so the styled centre box shows them
			var fe: Array = _t.get("feed") as Array
			if fe != null:
				for i in 7:
					fe.append("A line in the chronicle, number %d." % (i + 1))
			_stage = "settle"
			_f = 80
		"settle":
			if _f < 180:
				return false
			var sp := _sp()
			# L62 checks: every pane carries a visible KIND label with the right text
			for k in ["director", "bits", "subs", "points"]:
				var kl := _kind(k)
				_ok(kl != null and kl.visible, "%s pane has a visible kind title" % k)
				if kl:
					_ok(kl.text.find(Spotlight.KIND[k]) == 0, "%s kind title reads %s (got %s)" % [k, Spotlight.KIND[k], kl.text])
			_grab("l62_paid_all_four_1080")
			# ambient check: clear one paid lane, see "(ambient)"
			var L: Dictionary = sp.lanes["bits"]
			L["cur"] = {}
			L["q"] = []
			sp._relayout(true)
			_stage = "ambient"
			_f = 180
		"ambient":
			if _f < 240:
				return false
			var kb := _kind("bits")
			_ok(kb != null and kb.text.find("ambient") >= 0, "bits kind title reads ambient when idle (got %s)" % (kb.text if kb else "<none>"))
			_grab("l62_bits_ambient_1080")
			# L63: no satchel node in the leaderboard panel
			var lbp: Node = null
			for c in _t.get_children():
				if c is LeaderboardPanel:
					lbp = c
					break
			_ok(lbp != null, "LeaderboardPanel still exists as a CanvasLayer")
			if lbp:
				var kids := lbp.get_children()
				_ok(kids.is_empty(), "leaderboard_panel draws nothing on stream (children=%d)" % kids.size())
			_grab("l61_chronicle_styled_1080")
			_stage = "done"
			_f = 240
		"done":
			print("L61/L62/L63 test: %d checks, %d FAIL" % [_checks, _fails.size()])
			for f in _fails:
				print("  FAIL: " + f)
			quit(0 if _fails.is_empty() else 1)
	return false
