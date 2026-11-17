extends SceneTree
## L71 test (WINDOWED 1080p, --script). Longest line of each kind the game writes, at UI scale
## 100/125/150. Pass: no ellipsis in any Chronicle label, the stack fits the vellum, shots saved.
## Args after `--`: tag (default "after").
var _t: Node3D
var _eye: RtsCamera
var _hud: FeedHUD
var _f := 0
var _t0 := -1.0
var _out := ""
var _tag := "after"
var _step := 0
var _phase := 0
var _bad := 0
var _audited := 0   # labels actually inspected: a gate that audited nothing must not say OK
const LINES := [
	"Hobwick the Knight (Lv 3, STR 16 DEX 12 CON 15 INT 9 WIS 11 CHA 10) - 24 HP, AC 17, wielding a longsword; carries 41 gold.",
	"Viewer1001 steps on a pressure plate - fire! DEX 12 vs DC 13, 9 damage (halved).",
	"Viewer1002 spots a swarm grate (Perception 20 vs DC 13) and disarms it with thieves' tools (17).",
	"Viewer1003 searches the chest - Successfully found loot!! 38 gold (Investigation 14 vs DC 12).",
	"E3PO the Commander raises his halberd: 'Hold the line at the east gate! The Scar will not take Bellmire tonight!'",
]
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_tag = a[0]
	_out = ProjectSettings.globalize_path("res://renders/cycles/l71/")
	DirAccess.make_dir_recursive_absolute(_out)
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
func _process(d: float) -> bool:
	_f += 1
	if _f == 20:
		_eye = RtsCamera.new()
		_t.add_child(_eye)
		_eye.setup(_t)
		for c in _t.get_children():
			if c is FeedHUD and _tag != "break_nohud":   # break_nohud: prove a missing HUD gives NO VERDICT
				_hud = c
	if _f > 1800 and _hud == null:
		print("L71_TEST NO VERDICT - FeedHUD never found in 1800 frames"); quit(2); return true
	if _f > 40000:
		print("L71_TEST NO VERDICT - frame cap hit at step ", _step); quit(2); return true
	if _f < 60 or _hud == null:
		return false
	if _t0 < 0.0:
		_t0 = Time.get_ticks_msec() / 1000.0
	var now := Time.get_ticks_msec() / 1000.0 - _t0
	var sc: float = UiTheme.STEPS[_step]
	var base := float(_step) * 12.0
	if now >= base and UiTheme.scale != sc:
		_phase = 0
		UiTheme.scale = sc
		_hud.restyle()
		_hud.set_process(false)           # freeze the live feed so the five test lines stay put
		_hud._panel.modulate.a = 1.0
	if now >= base + 3.0 and _step < UiTheme.STEPS.size():
		# phase 0-4: each long line ALONE; phase 5: all five stacked (worst case) + shot
		if _phase > 0:
			_audit(int(sc * 100.0))
		if _phase < LINES.size():
			_hud._shown = [{"text": LINES[_phase], "n": 1, "key": str(_phase), "t": 0.0, "at": 0.0, "pri": 2}]
		elif _phase == LINES.size():
			_hud._shown = []
			for i in LINES.size():
				_hud._shown.append({"text": LINES[i], "n": 1, "key": str(i), "t": 0.0, "at": 0.0, "pri": 2})
		if _phase <= LINES.size():
			_hud._rebuild()
			_phase += 1
			return false
		root.get_texture().get_image().save_png(_out + "l71_%s_%d.png" % [_tag, int(sc * 100.0)])
		print("SHOT l71_%s_%d" % [_tag, int(sc * 100.0)])
		_phase = 0
		_step += 1
		if _step >= UiTheme.STEPS.size():
			if _audited < 15:
				print("L71_TEST NO VERDICT - only ", _audited, " labels audited (floor 15)"); quit(2); return true
			print("L71_TEST ", "OK" if _bad == 0 else "FAIL", " audited=", _audited)
			if _bad > 0: quit(1)
			return true
	return false
func _audit(pct: int) -> void:
	for lb in ([] if _tag == "break_empty" else _hud._box.get_children()):   # break_empty: prove an empty box is not OK
		var l := lb as Label
		_audited += 1
		if "..." in l.text or "…" in l.text or l.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING:
			print("FAIL ellipsis @", pct, " ", l.text); _bad += 1
		print("  [", pct, "] ", l.get_line_count(), "L: ", l.text)
	var sr: Rect2 = (_hud._panel as HudDock.ChronicleScroll).sheet_rect()
	print("  [", pct, "] box h=", _hud._box.size.y, " sheet h=", sr.size.y)
	if _hud._box.size.y > sr.size.y + 2.0:
		print("FAIL overflow @", pct); _bad += 1
