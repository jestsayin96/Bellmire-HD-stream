extends SceneTree
## S86: the three numbers the chat bot's wording guards describe are now named engine
## constants. This proves (a) they hold the values the published lines promise, and
## (b) the floor's oil burn and the rework price are byte-for-byte what the old bare
## literals computed, for every party size and every weapon tier. Prints S86_CONSTS OK/FAIL.

var _fails := 0
var _checks := 0

func _check(name: String, ok: bool) -> void:
	_checks += 1
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		_fails += 1

func _initialize() -> void:
	_check("REWORK_DIVISOR is 4 (a quarter)", Roster.REWORK_DIVISOR == 4)
	_check("OIL_PER_HEAD is 0.5 (a flask per two)", is_equal_approx(Delve.OIL_PER_HEAD, 0.5))
	_check("OIL_FLOOR_MIN is 1", Delve.OIL_FLOOR_MIN == 1)
	for n in range(0, 9):
		var old_burn := maxi(1, int(ceil(float(n) * 0.5)))
		var new_burn := maxi(Delve.OIL_FLOOR_MIN, int(ceil(float(n) * Delve.OIL_PER_HEAD)))
		_check("burn %d heads old=%d new=%d" % [n, old_burn, new_burn], old_burn == new_burn)
	for i in range(Roster.WEAPONS.size()):
		var c := int(Roster.WEAPONS[i]["cost"])
		_check("rework tier %d cost %d -> %d" % [i, c, int(c / Roster.REWORK_DIVISOR)], int(c / 4) == int(c / Roster.REWORK_DIVISOR))
	print("CHECKS %d FAILS %d" % [_checks, _fails])
	print("S86_CONSTS OK" if _fails == 0 else "S86_CONSTS FAIL")
	quit(0 if _fails == 0 else 1)
