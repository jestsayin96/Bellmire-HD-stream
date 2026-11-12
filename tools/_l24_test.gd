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
		_ok(_cur_node() == _ash(), "before: the director takes the freshest chatter, Ash (%s)" % _dir._cur.get("key"))
	if _f == 60:
		Spotlight.of(_t).put("2401", "bits", 60.0, "cheered 500 bits")
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
		var dv := Delve.new()
		dv.town = _t
		dv.roster = _t.get("roster")
		dv.start_floor = 2
		dv.max_floors = 2
		_t.add_child(dv)
		dv.start(["2401", "2402"])
	if _f == _spot_f + 1200:
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
