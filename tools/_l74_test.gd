extends SceneTree
## L74 test (WINDOWED 1080p, --script). A raid floods the Chronicle: 36 lines in ~3 s, at UI scale
## 100/125/150, feed running LIVE (pacing, merge, drop). Pass: no ellipsis, stack fits the vellum,
## protected (town/crit) lines never dropped, a shot per scale. Args after `--`: tag.
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
const RAID := [
	"Warband of raiders sighted at the east gate - the Scar is on the march!",
	"Viewer1001 swings a sword at a raider - hit! 7 damage.",
	"Viewer1002 picks up a plank.", "Viewer1003 gathers wood.", "Viewer1004 chops a log.",
	"Viewer1005 sips ale at the tavern.", "Viewer1006 hauls a sack of grain.",
	"Viewer1007 shoots a raider - hit! 6 damage (Longbow, DEX 14 vs AC 12).",
	"E3PO the Commander raises his halberd: 'Hold the line at the east gate!'",
	"Viewer1008 has fallen to a raider's axe at the palisade.",
	"The gate is besieged - the east palisade is ablaze!",
	"Viewer1009 mends the wall.", "Viewer1010 fetches water.", "Viewer1011 sweeps the square.",
	"Viewer1012 casts a bolt of fire - the raider is slain!",
	"The granary is down to 12 days of food - hunger looms.",
]
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_tag = a[0]
	_out = ProjectSettings.globalize_path("res://renders/cycles/l74/")
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
	var sc: float = UiTheme.STEPS[_step]
	var base := float(_step) * 9.0
	if now < base:
		return false
	if now - base < 0.1 and UiTheme.scale != sc:
		UiTheme.scale = sc
		_hud.restyle()
		_fed = 0
		_shot = false
	var t := now - base
	if t < 3.0:
		var want := int(t / 3.0 * 36.0)
		while _fed < want:
			_hud.source.append(RAID[_fed % RAID.size()] + (" (" + str(_fed) + ")" if _fed >= RAID.size() else ""))
			_fed += 1
	if t >= 7.0 and not _shot:
		_shot = true
		_audit(int(sc * 100.0))
		root.get_texture().get_image().save_png(_out + "l74_%s_%d.png" % [_tag, int(sc * 100.0)])
		print("SHOT l74_%s_%d  stats=%s" % [_tag, int(sc * 100.0), str(_hud.stats)])
		_step += 1
		if _step >= UiTheme.STEPS.size():
			var f := FileAccess.open(_out + "l74_feed_log_%s.txt" % _tag, FileAccess.WRITE)
			f.store_string(_hud.log_text())
			print("L74_TEST ", "OK" if _bad == 0 else "FAIL")
			return true
	return false
func _audit(pct: int) -> void:
	for lb in _hud._box.get_children():
		var l := lb as Label
		if "..." in l.text or "…" in l.text:
			print("FAIL ellipsis @", pct, " ", l.text); _bad += 1
		print("  [", pct, "] ", l.get_line_count(), "L: ", l.text)
	var sr: Rect2 = (_hud._panel as HudDock.ChronicleScroll).sheet_rect()
	print("  [", pct, "] box h=", _hud._box.size.y, " sheet h=", sr.size.y)
	if _hud._box.size.y > sr.size.y + 2.0:
		print("FAIL overflow @", pct); _bad += 1
	if int(_hud.stats.get("dropped_protected", 0)) > 0:
		print("FAIL protected line dropped @", pct); _bad += 1
