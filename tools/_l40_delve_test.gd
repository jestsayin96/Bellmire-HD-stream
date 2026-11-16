extends SceneTree
## L40 DELVE capture (WINDOWED 1080p, --script). The supervisor's 13:58 ask: party frames + boss card + chat open +
## Chronicle running in the SAME frame, at UI scale 100/125/150, grid AND full screen. MEASURE ONLY, no game file touched.
## Prints L40D_TEST OK/FAIL and every element rect; stills in renders/cycles/l40d/.
var _t: Node3D
var _eye: RtsCamera
var _hud: FeedHUD
var _d: Delve
var _f := 0
var _t0 := -1.0
var _out := ""
var _step := 0
var _fed := 0
var _bad := 0
var _stage := "boot"
const SC := [1.0, 1.25, 1.5]
const LINES := ["A trade caravan is sighted on the west road.", "Viewer1001 swings a sword at a raider - hit! 7 damage.",
	"Viewer1002 gathers wood.", "The granary is down to 12 days of food - hunger looms.", "Viewer1004 hauls a sack of grain."]
func _initialize() -> void:
	_out = ProjectSettings.globalize_path("res://renders/cycles/l40d/")
	DirAccess.make_dir_recursive_absolute(_out)
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
func _process(_dt: float) -> bool:
	_f += 1
	if _stage == "boot":
		if _f == 20:
			_eye = RtsCamera.new()
			_t.add_child(_eye)
			_eye.setup(_t)
			for c in _t.get_children():
				if c is FeedHUD:
					_hud = c
			var r: Roster = _t.get("roster")
			for v in [["2101", "JestFan", "knight dwarf"], ["2102", "MossyMage", "mage elf"], ["2103", "DawnCleric", "cleric human"], ["2104", "BigAxe", "barbarian orc"]]:
				var c: ChatCmd = _t.get("chat")
				c._last.clear()
				_t.call("chat_line", v[0], v[1], "!enlist " + v[2])
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
			_d.start(["2104", "2101"])
			_eye.director._set_on(true)
			Engine.time_scale = 3.0
			_stage = "wait_lord"
		return false
	if _stage == "wait_lord":
		if _d.lord_fighting() != null or _f > 3000:
			Engine.time_scale = 1.0
			print("L40D lord fighting: ", _d.lord_fighting() != null, " frame ", _f)
			_stage = "run"
		return false
	if _hud == null:
		return true
	if _t0 < 0.0:
		_t0 = Time.get_ticks_msec() / 1000.0
	var now := Time.get_ticks_msec() / 1000.0 - _t0
	var base := float(_step) * 6.0
	if now < base:
		return false
	var t := now - base
	var sc: float = SC[_step / 2]
	var full := (_step % 2) == 1
	if t < 0.1 and _fed == 0:
		UiTheme.scale = sc
		_hud.restyle()
		var sp := Spotlight.of(_t)
		if sp != null:
			sp.suspend(full)
		_eye._chat.visible = true
		_eye._chat.text = "!hero what is my hero doing right now"
	if t < 2.5:
		var want := int(t / 2.5 * 18.0)
		while _fed < want:
			_hud.source.append(LINES[_fed % LINES.size()] + " (" + str(_fed) + ")")
			_fed += 1
	if t >= 4.5:
		_audit(int(sc * 100.0), full)
		root.get_texture().get_image().save_png(_out + "l40d_%s_%d.png" % ["full" if full else "grid", int(sc * 100.0)])
		_step += 1
		_fed = 0
		if _step >= SC.size() * 2:
			print("L40D_TEST ", "OK" if _bad == 0 else "FAIL", " overlaps=", _bad)
			return true
	return false
func _audit(pct: int, full: bool) -> void:
	var tag := "%d%% %s" % [pct, "full" if full else "grid"]
	var scr := Vector2(root.size)
	var items: Array = []
	for cl in root.find_children("*", "CanvasLayer", true, false):
		for k in (cl as Node).get_children():
			if not (k is Control and (k as Control).is_visible_in_tree()):
				continue
			if str(k.name).begins_with("Pane_"):
				# a pane box is the container its own plate / boss card / frames live in:
				# audit what is drawn ON it, never the box against the Chronicle at the cross
				for pc in (k as Node).get_children():
					if pc is Control and (pc as Control).is_visible_in_tree():
						var pr := (pc as Control).get_global_rect()
						if pr.size.x >= 4.0 and pr.size.y >= 4.0 and pr.size.x * pr.size.y < 0.20 * scr.x * scr.y:
							items.append([str(k.name) + "/" + str(pc.name) + ":" + pc.get_class(), pr])
				continue
			var r := (k as Control).get_global_rect()
			if r.size.x < 4.0 or r.size.y < 4.0 or r.size.x * r.size.y >= 0.35 * scr.x * scr.y:
				continue
			items.append([str(k.name) + ":" + k.get_class(), r])
	print("  [", tag, "] ", items.size(), " elements")
	for it in items:
		print("     ", it[0], " ", it[1])
	for i in items.size():
		for j in range(i + 1, items.size()):
			if (items[i][1] as Rect2).intersects(items[j][1]):
				print("L40D FAIL overlap @", tag, ": ", items[i][0], " x ", items[j][0]); _bad += 1
