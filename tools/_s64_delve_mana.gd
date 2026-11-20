## S64: the mana gate on the LIVE delve path. Same party as _delve_test. Verdict:
## S64_DELVE_MANA OK when spells were PAID for (mana_casts > 0), the mage's pool went below
## full in a fight, and it refilled out of combat. NO VERDICT if the delve never fought.
extends SceneTree
var _d: Delve
var _r: Roster
var _f := 0
var _min := 1e9
var _dipped_then_rose := false
var _last_fight_low := -1.0
var _mage: Dictionary
func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)
	var V := [["1001", "JestFan", "knight"], ["1002", "MossyMage", "mage"], ["1003", "DawnCleric", "cleric"], ["1004", "BigAxe", "barbarian"]]
	var ids := []
	for v in V:
		var h: Dictionary = _r.fresh(v[0], v[1], v[2])
		h["weapon"] = 2
		h["armour"] = 2
		ids.append(v[0])
	_mage = _r.heroes["1002"]
	_d = Delve.new()
	_d.roster = _r
	_d.max_floors = 3
	root.add_child(_d)
	_d.start(ids)
func _process(_dt: float) -> bool:
	_f += 1
	var cur := float(_mage.get("mana", -1.0))
	var mx := float(_mage.get("mana_max", 0.0))
	if cur >= 0.0:
		_min = minf(_min, cur)
		if _d.state == "fight" and cur < mx:
			_last_fight_low = cur
		elif _d.state != "fight" and _last_fight_low >= 0.0 and cur > _last_fight_low + 1.0:
			_dipped_then_rose = true
	if _f % 900 == 0:
		print("T%ds floor=%d state=%s mage mana %.1f/%.0f paid=%d dry=%d" % [_f / 60, _d.floor_no, _d.state, cur, mx, _d.mana_casts, _d.mana_dry_swings])
	if _d.state == "home" or _f > 60 * 120:
		if _d.mana_casts == 0:
			print("S64_DELVE_MANA NO VERDICT: no spell was cast in %d frames" % _f)
			quit(2)
		else:
			var ok := _min < mx and _dipped_then_rose
			print("S64_DELVE_MANA %s paid_casts=%d dry_swings=%d mage_max=%.0f mage_low=%.1f refilled_out_of_combat=%s frames=%d" % [
				"OK" if ok else "FAIL", _d.mana_casts, _d.mana_dry_swings, mx, _min, _dipped_then_rose, _f])
			quit(0 if ok else 1)
		return true
	return false
