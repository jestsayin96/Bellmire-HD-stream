extends SceneTree
## S101: the stopper (48th, crypt) and the roper (49th, grassland) sit in THEME_MINIBOSS_MORE with
## MB_FIT rows, but each is missing one half of miniboss_for's gate: the stopper has feed lines and
## NO .glb on any branch; the roper has a .glb and NO feed lines. Neither may be drawn. Red-proof:
## a key that has BOTH halves (pitman, crypt) must be drawn in the same sweep, so an instrument that
## never draws anything cannot pass. Prints S101_GATE OK <checks> / S101_GATE FAIL <n> (<checks>).
var _fails := 0
var _checks := 0
func _ok(c: bool, what: String) -> void:
	_checks += 1
	if not c:
		_fails += 1
		print("FAIL " + what)
func _initialize() -> void:
	_ok("stopper" in DungeonHD.THEME_MINIBOSS_MORE["crypt"], "stopper is in the crypt row")
	_ok("roper" in DungeonHD.THEME_MINIBOSS_MORE["grassland"], "roper is in the grassland row")
	_ok(is_equal_approx(float(Delve.MB_FIT.get("stopper", -1.0)), 0.97), "MB_FIT stopper 0.97")
	_ok(is_equal_approx(float(Delve.MB_FIT.get("roper", -1.0)), 1.0), "MB_FIT roper 1.0")
	## S103: stopper.glb is tracked on main 41f71825, so the three stopper-held arms below were true at
	## S101 and false now; inverted in the same commit as the Chokewell row (tools/_s102_gate.gd holds the full stopper check).
	_ok(Delve.miniboss_model("stopper") != "", "S103: stopper mesh resolves")
	_ok(not Delve.miniboss_lines("stopper", "arrive").is_empty(), "stopper has arrive lines (C-176)")
	_ok(Delve.miniboss_model("roper") != "", "roper mesh resolves")
	## S102: content's C-177 landed the roper's feed and MB_NAME now carries "Drawtight", so the two
	## roper-held asserts moved to tools/_s102_gate.gd, which asserts the roper IS drawn. Stopper half unchanged.
	_ok(Delve.MB_NAME.has("stopper"), "S103: stopper carries its MB_NAME row")
	var drawn := {}
	for th: String in ["crypt", "grassland"]:
		for n in 4000:
			var k := DungeonHD.miniboss_for(th, n)
			drawn[k] = int(drawn.get(k, 0)) + 1
	print("S101 draws over 8000 picks: ", drawn)
	_ok(drawn.has("stopper"), "S103: stopper IS drawn in crypt")
	_ok(drawn.has("pitman"), "red-proof: pitman (both halves) IS drawn by the same sweep")
	if _fails == 0:
		print("S101_GATE OK %d" % _checks)
	else:
		print("S101_GATE FAIL %d (%d)" % [_fails, _checks])
	quit()
