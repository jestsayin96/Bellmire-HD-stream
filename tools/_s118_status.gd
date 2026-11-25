extends SceneTree
## S118: the L31 remainder, both open bits. (a) statuses() carries the seconds left as [4],
## which party_frames draws beside the word; (b) _give's `was` is read - a NEW state fires
## exactly one on-apply line, a refresh of a held state fires none. Red-proof arm: a state
## blocked by its ward (burning under resist_fire) fires no line and is not held.
## Prints S118_STATUS OK <n> / FAIL.
var _fails := 0
var _checks := 0
func _ok(c: bool, what: String) -> void:
	_checks += 1
	if not c:
		_fails += 1
		print("FAIL " + what)
func _initialize() -> void:
	var d = Delve.new()
	var m := {"hp": 20.0, "max": 20.0, "uid": "s118", "h": {"name": "S118"}}
	_ok(d.applied_lines == 0, "no line before any state")
	d._give(m, "burning", 12.0)
	_ok(d.applied_lines == 1, "new burning fires one on-apply line (got %d)" % d.applied_lines)
	d._give(m, "burning", 8.0)
	_ok(d.applied_lines == 1, "refresh of held burning fires none (got %d)" % d.applied_lines)
	d._give(m, "poisoned", 5.0)
	_ok(d.applied_lines == 2, "new poisoned (venom field) fires one (got %d)" % d.applied_lines)
	d._give(m, "slowed", 3.0)
	_ok(d.applied_lines == 3, "new slowed (slow field) fires one (got %d)" % d.applied_lines)
	_ok(is_equal_approx(d.st_secs(m, "burning"), 12.0), "burning keeps the longer 12 s (got %s)" % d.st_secs(m, "burning"))
	_ok(is_equal_approx(d.st_secs(m, "poisoned"), 5.0), "poisoned reads 5 s off venom")
	_ok(d.st_secs(m, "haste") == 0.0, "unheld haste reads 0")
	var sts: Array = d.statuses(m)
	print("S118 statuses: ", sts)
	var secs := {}
	for s in sts:
		_ok(s.size() == 5, "status tuple has 5 fields")
		secs[String(s[2])] = float(s[4])
	_ok(is_equal_approx(float(secs.get("burning", -1.0)), 12.0), "statuses()[burning][4] is 12")
	# red-proof: a ward blocks the state, so nothing is held and no line fires
	var w := {"hp": 20.0, "max": 20.0, "uid": "s118w", "h": {"name": "W"}, "st": {"resist_fire": 30.0}}
	var before: int = d.applied_lines
	d._give(w, "burning", 10.0)
	_ok(d.applied_lines == before and not d.has_st(w, "burning"), "red-proof: warded burning is not held and fires no line")
	# dead delver: no state, no line
	var dead := {"hp": 0.0, "max": 20.0, "uid": "s118d", "h": {"name": "D"}}
	d._give(dead, "frightened", 10.0)
	_ok(d.applied_lines == before, "a fallen delver gets no line")
	d.free()
	if _fails == 0:
		print("S118_STATUS OK %d" % _checks)
	else:
		print("S118_STATUS FAIL %d of %d" % [_fails, _checks])
	quit(0 if _fails == 0 else 1)
