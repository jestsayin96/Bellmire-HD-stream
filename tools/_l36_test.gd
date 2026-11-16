extends SceneTree
## L36 test (WINDOWED 1080p, --script). The local chat box and the Chronicle must share ZERO
## pixels: chat box up (Mr. E typing) AND the Chronicle running, at UI scale 100/125/150, in the
## 2x2 grid AND at full screen (grid suspended). Pass: Chronicle panel rect and every showing
## Chronicle line do not intersect the chat box rect. Args after `--`: tag.
var _t: Node3D
var _eye: RtsCamera
var _hud: FeedHUD
var _f := 0
var _t0 := -1.0
var _out := ""
var _tag := "after"
var _step := 0
var _fed := 0
var _bad := 0
var _shot := false
const LINES := [
	"A trade caravan is sighted on the west road.",
	"Viewer1001 swings a sword at a raider - hit! 7 damage.",
	"Viewer1002 gathers wood.", "Viewer1003 sips ale at the tavern.",
	"The granary is down to 12 days of food - hunger looms.",
	"Viewer1004 hauls a sack of grain.", "Viewer1005 mends the wall.",
	"Viewer1006 has fallen to a raider's axe at the palisade.",
	"Viewer1007 shoots a raider - hit! 6 damage.", "Viewer1008 fetches water.",
]
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_tag = a[0]
	_out = ProjectSettings.globalize_path("res://renders/cycles/l36/")
	DirAccess.make_dir_recursive_absolute(_out)
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
func _process(_d: float) -> bool:
	_f += 1
	if _f == 20:
		_eye = RtsCamera.new()
		_t.add_child(_eye)
		_eye.setup(_t)
		for c in _t.get_children():
			if c is FeedHUD:
				_hud = c
	if _f < 60 or _hud == null:
		return false
	if _t0 < 0.0:
		_t0 = Time.get_ticks_msec() / 1000.0
	var now := Time.get_ticks_msec() / 1000.0 - _t0
	var n_cfg := UiTheme.STEPS.size() * 2
	var base := float(_step) * 6.0
	if now < base:
		return false
	var t := now - base
	var sc: float = UiTheme.STEPS[_step / 2]
	var full := (_step % 2) == 1
	if t < 0.1 and not _shot and _fed == 0:
		UiTheme.scale = sc
		_hud.restyle()
		var sp := Spotlight.of(_t)
		if sp != null:
			sp.suspend(full)
		var ch: LineEdit = _eye._chat
		ch.visible = true
		ch.text = "!hero what is my hero doing right now"
	if t < 3.0:
		var want := int(t / 3.0 * 24.0)
		while _fed < want:
			_hud.source.append(LINES[_fed % LINES.size()] + (" (" + str(_fed) + ")" if _fed >= LINES.size() else ""))
			_fed += 1
	if t >= 5.0 and not _shot:
		_shot = true
		_audit(int(sc * 100.0), full)
		root.get_texture().get_image().save_png(_out + "l36_%s_%s_%d.png" % [_tag, "full" if full else "grid", int(sc * 100.0)])
		_step += 1
		_fed = 0
		_shot = false
		if _step >= n_cfg:
			print("L36_TEST ", "OK" if _bad == 0 else "FAIL")
			return true
	return false
func _audit(pct: int, full: bool) -> void:
	var cr: Rect2 = (_eye._chat as Control).get_global_rect()
	var tag := "%d%% %s" % [pct, "full" if full else "grid"]
	var panel: Control = null
	for n in get_nodes_in_group("hud_chronicle"):
		if is_instance_valid(n) and n is Control and (n as Control).is_visible_in_tree():
			panel = n
	if panel == null:
		print("FAIL no Chronicle panel @", tag); _bad += 1
		return
	var pr: Rect2 = panel.get_global_rect()
	print("  [", tag, "] chat=", cr, " chronicle=", pr)
	if pr.intersects(cr):
		print("FAIL chronicle panel shares pixels with chat @", tag); _bad += 1
	for lb in _hud._box.get_children():
		var l := lb as Label
		if l.visible and l.get_global_rect().intersects(cr):
			print("FAIL line overlaps chat @", tag, ": ", l.text); _bad += 1
