extends SceneTree
## L24: while a spotlight lane holds a hero, the director never follows that same hero (the
## split would show one thing twice) - it cuts away. Three viewers in town, director on.
## 1. Ash is the freshest chatter, so the director takes Ash (chat_). Then Ash is spotlit in
##    the bits lane: within 2 s the director has cut away, and for 15 s it never comes back.
## 2. Ash and Bree delve; Ash is spotlit: the director's delve / fight shot goes through Bree.
## Prints L24_TEST OK / FAIL.
var _t: Node3D
var _eye: RtsCamera
var _dir: AutoDirector
var _f := 0
var _fails: Array = []
var _checks := 0
var _spot_f := -1
var _back := 0
var _cut_away_f := -1
## L44: made deterministic. A hold long enough that it cannot expire inside the test, and the
## final checks gated on a CONDITION - the delve's bodies being real and in the tree - instead
## of a frame count that meant different things at different frame rates.
const HOLD_S := 900.0
const WAIT_CAP := 1800          # frames to wait for the delve before calling it a failure
var _dv: Delve = null
var _dv_f := -1

func _initialize() -> void:
	root.size = Vector2i(1920, 1080)
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _say(uid: String, nm: String, msg: String) -> void:
	(_t.get("chat") as ChatCmd)._last.erase(uid)
	_t.call("chat_line", uid, nm, msg)

func _ash() -> Node3D:
	return Spotlight.of(_t).body_of("2401")

func _cur_node() -> Node:
	var n = _dir._cur.get("node")
	return n if n != null and is_instance_valid(n) else null

func _process(_dt: float) -> bool:
	_f += 1
	if _f == 20:
		_eye = RtsCamera.new()
		_t.add_child(_eye)
		_eye.setup(_t)
		_dir = _eye.director
		(_t.get("raids") as Raids).set("_raid_t", 99999.0)
		for v in [["2401", "Ash", "!enlist knight"], ["2402", "Bree", "!enlist mage"], ["2403", "Cole", "!enlist rogue"]]:
			_say(v[0], v[1], v[2])
		_dir._set_on(true)
	if _f == 40:
		_say("2401", "Ash", "!hero")              # Ash: the freshest chatter
		_dir._cut(_dir._best())
		# a catch being landed / a fight / a lord is HOTTER than chatter by design (60+ vs 50):
		# if one is live at this instant the director is right to be on it, not on Ash
		var k := String(_dir._cur.get("key", ""))
		var hotter := k.begins_with("fish_") or k.begins_with("fight_") or k.begins_with("lord_") or k == "raid"
		_ok(_cur_node() == _ash() or hotter, "before: the director takes the freshest chatter, Ash, unless a hotter story is live (%s)" % k)
	if _f == 60:
		# L44: the hold used to be 60 s while the test waited 1200 FRAMES for its last check.
		# Spotlight seconds are REAL seconds, so at the 14-20 fps this machine runs during a
		# delve those 1200 frames are around 60 s - the hold expired right as the final asserts
		# ran, and the test failed or passed on how fast the machine happened to be. The hold is
		# now far longer than the test can possibly take: this test is about whether the
		# director yields to a lane, not about when a lane expires.
		Spotlight.of(_t).put("2401", "bits", HOLD_S, "cheered 500 bits")
		_spot_f = _f
	if _spot_f > 0 and _f > _spot_f and _f <= _spot_f + 1020:
		if _f % 120 == 0:
			_say("2401", "Ash", "!hero")      # Ash keeps chatting (stays the freshest)
		var on_ash := _cur_node() == _ash()
		if not on_ash and _cut_away_f < 0:
			_cut_away_f = _f
		if _f > _spot_f + 120 and on_ash:
			_back += 1
	if _f == _spot_f + 1021:
		_ok(_cut_away_f > 0 and _cut_away_f - _spot_f <= 120, "a lane takes Ash: the director cuts away within 2 s (%d frames, now %s)" % [_cut_away_f - _spot_f, _dir._cur.get("key")])
		_ok(_back == 0, "for 15 s the director never follows Ash while the lane holds them (%d frames on Ash)" % _back)
		# 2. a delve with Ash spotlit: the delve's shot goes through Bree
		_dv = Delve.new()
		_dv.town = _t
		_dv.roster = _t.get("roster")
		_dv.start_floor = 2
		_dv.max_floors = 2
		_t.add_child(_dv)
		_dv.start(["2401", "2402"])
		_dv_f = _f

	# ---- L44: wait for the STATE the checks need, not for a number of frames.
	# body_of() resolves a delver through the Delve party first, so the lane only points at the
	# underground body once that body exists and is in the tree. Waiting a fixed 1200 frames
	# hoped that had happened; this waits until it HAS, and fails loudly if it never does.
	if _dv_f > 0 and _f > _dv_f:
		var ready := false
		if is_instance_valid(_dv) and _dv.party.size() >= 2:
			ready = true
			for m in _dv.party:
				var b = m.get("body")
				if not (is_instance_valid(b) and (b as Node3D).is_inside_tree()):
					ready = false
		if not ready and _f - _dv_f < WAIT_CAP:
			return false
		if not ready:
			_ok(false, "the delve never put both delvers underground within %d frames" % WAIT_CAP)
			print("L24_TEST %s (%d checks, %d failed)" % ["OK" if _fails.is_empty() else "FAIL", _checks, _fails.size()])
			return true
		# the bodies are real and underground: bind the lane to the body it must hold NOW,
		# rather than trusting that a hold placed before the delve survived the body swap
		Spotlight.of(_t).put("2401", "bits", HOLD_S, "cheered 500 bits")
		var best := _dir._best()
		var cands: Array = []
		for k in ["delve_", "fight_"]:
			if String(best.get("key", "")).begins_with(k):
				cands.append(best)
		var held := _dir.lane_held()
		_ok(not held.is_empty() and held.has(_ash()), "Ash's body below is the one the lane holds")
		_ok(not best.is_empty() and best.get("node") != _ash(), "below: the director's best shot (%s) is not on Ash" % best.get("key"))
		_ok(cands.is_empty() or (best.get("node") is HeroBody and (best["node"] as HeroBody).user_id == "2402"), "below: the delve shot goes through Bree (%s)" % [best.get("node")])
		print("L24_TEST %s (%d checks, %d failed)" % ["OK" if _fails.is_empty() else "FAIL", _checks, _fails.size()])
		return true
	return false
