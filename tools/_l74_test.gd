extends SceneTree
## L74 test (WINDOWED 1080p, --script). The Chronicle under load: a burst of mixed-priority lines
## (2/s for 24 s) then UI scale 125% and 150%. For every line, measures how long it was actually
## VISIBLE (inside the last _cap() of _shown) against how long it takes to read: chars / READ_CPS + SCAN_S.
## Reports lines taken off the scroll before they could be read, by priority. Args: tag (default "run").
## break_nolines: feed nothing -> must say NO VERDICT. A gate that measured no lines must not say OK.
const READ_CPS := 18.0     # ~215 wpm, a comfortable stream-viewer pace
const SCAN_S := 1.0        # eye finds the new line
var _t: Node3D
var _hud: FeedHUD
var _f := 0
var _t0 := -1.0
var _tag := "run"
var _out := ""
var _fed := 0
var _vis := {}   # key -> {first,last,len,pri,text}
var _shot := [false, false, false]
const POOL := [
	[0, "%s picks up a log."], [0, "%s sweeps the smithy floor."], [0, "%s fetches water from the well."],
	[1, "%s sells a basket of apples at the market stall."], [1, "%s trains with the militia near the east wall."],
	[2, "Viewer%d steps on a pressure plate - fire! DEX 12 vs DC 13, 9 damage (halved)."],
	[2, "The granary is at 40 percent - hunger will bite the town within the week."],
	[3, "Hobwick the Knight has fallen to the raiders at the east gate, and the Scar presses on toward the bridge!"],
	[3, "Lord Varrick raises the warband banner: a raid on Bellmire has begun at the palisade."],
]
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: _tag = a[0]
	_out = ProjectSettings.globalize_path("res://renders/cycles/l74/")
	DirAccess.make_dir_recursive_absolute(_out)
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
func _process(_d: float) -> bool:
	_f += 1
	if _f == 20:
		var eye := RtsCamera.new(); _t.add_child(eye); eye.setup(_t)
		for c in _t.get_children():
			if c is FeedHUD: _hud = c
	if _f > 1800 and _hud == null:
		print("L74_TEST NO VERDICT - FeedHUD never found"); quit(2); return true
	if _hud == null or _f < 60: return false
	if _t0 < 0.0: _t0 = Time.get_ticks_msec() / 1000.0
	var now := Time.get_ticks_msec() / 1000.0 - _t0
	# feed: 2 lines/s for 24 s, pool cycled with a prime stride so priorities interleave
	while _tag != "break_nolines" and now < 24.0 and float(_fed) < now * 2.0:
		var p: Array = POOL[(_fed * 7) % POOL.size()]
		var s: String = p[1]
		var line: String = (s % ("Viewer%d" % _fed)) if s.count("%s") > 0 else (s % _fed if s.count("%d") > 0 else s)
		_t.feed.append(line); _fed += 1
	var cap := _hud._cap()
	var sh: Array = _hud._shown.slice(maxi(0, _hud._shown.size() - cap))
	for e in sh:
		var k := str(e["key"]) + "|" + str(e["at"])
		if not _vis.has(k):
			_vis[k] = {"first": now, "len": String(e["text"]).length(), "pri": int(e["pri"]), "text": String(e["text"])}
		_vis[k]["last"] = now
	if now >= 26.0 and UiTheme.scale == 1.0:
		_save(0, 100); UiTheme.scale = 1.25; _hud.restyle()
	if now >= 32.0 and UiTheme.scale == 1.25 and not _shot[1]:
		_save(1, 125); UiTheme.scale = 1.5; _hud.restyle()
	if now >= 38.0 and UiTheme.scale == 1.5 and not _shot[2]:
		_save(2, 150)
		_report(now)
		return true
	return false
func _save(i: int, pct: int) -> void:
	_shot[i] = true
	root.get_texture().get_image().save_png(_out + "l74_%s_%d.png" % [_tag, pct])
	print("SHOT l74_%s_%d  shown=%d cap=%d pending=%d" % [_tag, pct, _hud._shown.size(), _hud._cap(), _hud._pending.size()])
func _report(now: float) -> void:
	var short := [0, 0, 0, 0]; var tot := [0, 0, 0, 0]; var n := 0
	for k in _vis:
		var v: Dictionary = _vis[k]
		if now - float(v["last"]) < 0.5: continue          # still on the scroll: not yet taken off
		var seen: float = float(v["last"]) - float(v["first"])
		var need: float = float(v["len"]) / READ_CPS + SCAN_S
		n += 1; tot[int(v["pri"])] += 1
		if seen < need:
			short[int(v["pri"])] += 1
			print("  SHORT pri=%d seen=%.1fs need=%.1fs len=%d '%s'" % [int(v["pri"]), seen, need, int(v["len"]), String(v["text"]).left(60)])
	var st: Dictionary = _hud.stats
	print("STATS ", st)
	print("L74 measured=", n, " fed=", _fed, " by_pri=", tot, " taken_off_unread=", short)
	if n < 10:
		print("L74_TEST NO VERDICT - only ", n, " lines measured (floor 10)"); quit(2); return
	var bad: int = short[2] + short[3] + int(st["dropped_protected"])
	print("L74_TEST ", "OK" if bad == 0 else "FAIL", " protected_unread=", short[2] + short[3], " dropped_protected=", st["dropped_protected"])
	quit(1 if bad > 0 else 0)
