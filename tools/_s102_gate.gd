extends SceneTree
## S102: the roper (49th, grassland, "Drawtight") now has BOTH halves of miniboss_for's gate - its
## .glb (S101) and content's C-177 feed - plus its MB_NAME row. It must be DRAWN in grassland and
## read "Drawtight" on its plate. The stopper (48th, crypt) is STILL HELD: stopper.glb is on no
## branch, so it must carry no MB_NAME row and never be drawn. Red-proof: the same sweep must draw
## pitman (crypt, both halves), so a sweep that draws nothing cannot pass the stopper half.
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
	_ok(Delve.miniboss_model("stopper") == "", "stopper still has no mesh")
	_ok(not Delve.MB_NAME.has("stopper"), "stopper still carries no MB_NAME row (held)")
	var drawn := {}
	for th: String in ["crypt", "grassland"]:
		for n in 4000:
			var k := DungeonHD.miniboss_for(th, n)
			drawn[k] = int(drawn.get(k, 0)) + 1
	print("S102 draws over 8000 picks: ", drawn)
	_ok(drawn.has("roper"), "roper IS drawn in grassland")
	_ok(not drawn.has("stopper"), "stopper never drawn")
	_ok(drawn.has("pitman"), "red-proof: pitman IS drawn by the same sweep")
	if _fails == 0:
		print("S102_GATE OK %d" % _checks)
	else:
		print("S102_GATE FAIL %d (%d)" % [_fails, _checks])
	quit()
