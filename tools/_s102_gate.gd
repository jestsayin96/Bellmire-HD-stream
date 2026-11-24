extends SceneTree
## S102: the roper (49th, grassland, "Drawtight") now has BOTH halves of miniboss_for's gate - its
## .glb (S101) and content's C-177 feed - plus its MB_NAME row. It must be DRAWN in grassland and
## read "Drawtight" on its plate.
## S103: the stopper hold is LIFTED - stopper.glb is tracked on main 41f71825 and content's C-176
## feed landed - so the two arms that asserted "no mesh" / "no MB_NAME row" were true at S102 and
## false now. They are inverted here, in the same commit as the Chokewell row, so this gate never
## goes red on a tree with no defect. The stopper must now resolve, read "Chokewell" and be DRAWN
## in crypt. Red-proof: pitman (crypt) must still be drawn, so the stopper cannot crowd it out.
## Prints S102_GATE OK <checks> / S102_GATE FAIL <n> (<checks>).
var _fails := 0
var _checks := 0
func _ok(c: bool, what: String) -> void:
	_checks += 1
	if not c:
		_fails += 1
		print("FAIL " + what)
func _initialize() -> void:
	_ok(Delve.miniboss_model("roper") != "", "roper mesh resolves")
	_ok(not Delve.miniboss_lines("roper", "arrive").is_empty(), "roper has arrive lines (C-177)")
	_ok(Delve.miniboss_name("roper") == "Drawtight", "roper reads Drawtight")
	_ok(is_equal_approx(float(Delve.MB_FIT.get("roper", -1.0)), 1.0), "MB_FIT roper 1.0 (unchanged)")
	_ok(Delve.miniboss_model("stopper") != "", "S103: stopper mesh resolves (stopper.glb on main)")
	_ok(not Delve.miniboss_lines("stopper", "arrive").is_empty(), "S103: stopper has arrive lines (C-176)")
	_ok(Delve.miniboss_name("stopper") == "Chokewell", "S103: stopper reads Chokewell")
	_ok(is_equal_approx(float(Delve.MB_FIT.get("stopper", -1.0)), 0.97), "MB_FIT stopper 0.97 (unchanged)")
	var drawn := {}
	for th: String in ["crypt", "grassland"]:
		for n in 4000:
			var k := DungeonHD.miniboss_for(th, n)
			drawn[k] = int(drawn.get(k, 0)) + 1
	print("S102 draws over 8000 picks: ", drawn)
	_ok(drawn.has("roper"), "roper IS drawn in grassland")
	_ok(drawn.has("stopper"), "S103: stopper IS drawn in crypt")
	_ok(drawn.has("pitman"), "red-proof: pitman IS drawn by the same sweep")
	if _fails == 0:
		print("S102_GATE OK %d" % _checks)
	else:
		print("S102_GATE FAIL %d (%d)" % [_fails, _checks])
	quit()
