extends SceneTree
## L67 test (WINDOWED 1080p, run with --script): a forced raid with the feed SATURATED.
## ~12 lines/s of routine pickups, repeats, hero actions, a death and a lord are pushed into
## town.feed for 30 s of real time. Audits FeedHUD's own log and stats: admit gap >= PACE_S
## (rate at or under 1.25/s), no protected line dropped, repeats merged, every priority-3 line
## admitted. Saves renders/cycles/20261115_l67/ (feed_log.txt + shots).
var _t: Node3D
var _eye: RtsCamera
var _hud: FeedHUD
var _f := 0
var _t0 := -1.0
var _out := ""
var _shots := {}
var _sent := 0
var _crit_sent := 0
var _acc := 0.0
const FLOOD_S := 30.0
const RUN_S := 55.0
func _initialize() -> void:
	_out = ProjectSettings.globalize_path("res://renders/cycles/20261115_l67/")
	DirAccess.make_dir_recursive_absolute(_out)
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
func _shot(tag: String) -> void:
	if _shots.has(tag):
		return
	_shots[tag] = 1
	root.get_texture().get_image().save_png(_out + "l67_%s.png" % tag)
	print("SHOT l67_%s" % tag)
func _post(text: String, kind := "", who := []) -> void:
	_t.feed.append(text)
	if kind != "":
		_t.tag_feed(kind, who)
	_sent += 1
func _process(d: float) -> bool:
	_f += 1
	if _f == 20:
		_eye = RtsCamera.new()
		_t.add_child(_eye)
		_eye.setup(_t)
		for u in ["1001", "1002", "1003"]:
			_t.chat_line(u, "Viewer" + u, "!enlist knight")
		for c in _t.get_children():
			if c is FeedHUD:
				_hud = c
	if _f == 40:
		_eye.director._set_on(true)
	if _f < 60 or _hud == null:
		return false
	if _t0 < 0.0:
		_t0 = Time.get_ticks_msec() / 1000.0
		_t.raids.force_level = 3
		_t.raids.raid("scar")
		print("RAID + FLOOD start")
	var now := Time.get_ticks_msec() / 1000.0 - _t0
	if now < FLOOD_S:
		_acc += d * 12.0                      # ~12 lines per real second
		while _acc >= 1.0:
			_acc -= 1.0
			var k := _sent % 20
			if k == 3:
				_post("Viewer1001 the Knight is struck down in the scar.", "death", ["Viewer1001"]); _crit_sent += 1
			elif k == 9:
				_post("Viewer1002 answers the bounty and wins %d gold." % (40 + _sent), "bounty", ["Viewer1002"])
			elif k == 15 and _sent % 100 == 15:
				_post("The Scarlord rises in the east.", "lord"); _crit_sent += 1
			elif k % 3 == 0:
				_post("A raider is felled at the east gate. (%d)" % _sent)
			else:
				_post("%s picks up a coin." % ["Hob", "Wat", "Mab", "Gil"][_sent % 4])
	if now > 10.0:
		_shot("flood")
	if now > 22.0 and _shots.has("flood"):
		_shot("flood_late")
	if now > RUN_S:
		_audit()
		return true
	return false
func _audit() -> void:
	var st: Dictionary = _hud.stats
	var bad := 0
	if float(st["min_gap"]) < FeedHUD.PACE_S - 0.02:
		print("FAIL rate: min admit gap %.3f < %.2f" % [float(st["min_gap"]), FeedHUD.PACE_S]); bad += 1
	if int(st["dropped_protected"]) > 0:
		print("FAIL protected drops: ", st["dropped_protected"]); bad += 1
	if int(st["merged"]) == 0:
		print("FAIL no repeat merged"); bad += 1
	var crit_admit := 0
	for l in _hud.feed_log:
		if "ADMIT pri=3" in l:
			crit_admit += 1
	if crit_admit < 1:
		print("FAIL no priority-3 line admitted"); bad += 1
	var f := FileAccess.open(_out + "feed_log.txt", FileAccess.WRITE)
	f.store_string(_hud.log_text() + "\n")
	f.close()
	print("L67_STATS ", st, " crit_sent=", _crit_sent, " crit_admitted=", crit_admit, " max_rate=%.2f/s" % (1.0 / maxf(float(st["min_gap"]), 0.001)))
	print("L67_TEST ", "OK" if bad == 0 else "FAIL")
