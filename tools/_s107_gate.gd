extends SceneTree
## S107: the almoner (50th, Dolehand, art's tag shrine - field 5) is wired whole in ONE change:
## almoner.glb.import committed, MB_FIT 1.03 (art's _fit_report.json pairs.almoner.ratio),
## MB_NAME "Dolehand", and a shrine row in THEME_MINIBOSS_MORE. Content's C-182 by_key.almoner
## is on main. This gate asserts every half of miniboss_for's gate AND that the body is DRAWN and
## its mesh actually LOADS (an absent .import passes ResourceLoader.exists checks only by loading
## nothing - the S103 lesson). Red-proof: a sweep that draws nothing cannot pass, because the
## shrine draw must also yield leech. Prints S107_GATE OK <checks> / S107_GATE FAIL <n> (<checks>).
var _fails := 0
var _checks := 0
func _ok(c: bool, what: String) -> void:
	_checks += 1
	if not c:
		_fails += 1
		print("FAIL " + what)
func _initialize() -> void:
	_ok("almoner" in DungeonHD.THEME_MINIBOSS_MORE["shrine"], "almoner is in the shrine row")
	_ok(is_equal_approx(float(Delve.MB_FIT.get("almoner", -1.0)), 1.03), "MB_FIT almoner 1.03")
	_ok(String(Delve.MB_NAME.get("almoner", "")) == "Dolehand", "MB_NAME almoner Dolehand")
	_ok(Delve.miniboss_name("almoner") == "Dolehand", "miniboss_name reads Dolehand")
	var p := Delve.miniboss_model("almoner")
	_ok(p != "", "almoner mesh path resolves")
	var ps: PackedScene = load(p) if p != "" else null
	_ok(ps != null, "almoner.glb LOADS as a PackedScene")
	if ps != null:
		var n := ps.instantiate()
		_ok(n != null, "almoner instantiates")
		if n != null:
			n.free()
	_ok(not Delve.miniboss_lines("almoner", "arrive").is_empty(), "almoner has arrive lines (C-182)")
	_ok(not Delve.miniboss_lines("almoner", "fall").is_empty(), "almoner has fall lines (C-182)")
	var drawn := {}
	for n2 in 4000:
		var k := DungeonHD.miniboss_for("shrine", n2)
		drawn[k] = int(drawn.get(k, 0)) + 1
	print("S107 shrine draws over 4000 picks: ", drawn)
	_ok(drawn.has("almoner"), "almoner IS drawn in shrine")
	_ok(drawn.has("leech"), "red-proof: leech IS drawn by the same sweep")
	var mbn := Delve.MB_NAME.size()
	print("S107 MB_NAME size: ", mbn)
	# S107 asserted 50 (almoner, the 50th). S114: + panner (S111) + stiltman (S112) + nightman (S113) = 53. S116: + iceman (Hoarback, 54th) = 54. S118: + straker (Everyhand, 55th) = 55. S121: + weigher (Trueweight, 56th) = 56. S122: + dredger (Finepass, 57th) = 57. S123: + harrowman (Overturn, 58th) = 58. S124: + pledgeman (Heldfast, 59th) = 59. S126b: + crimp (Oneshort) = 60. S127: + timberman (Deadfall, 61st) = 61. S129: + collier (Halfblow, 62nd) = 62. S141: + overlooker (Velrick, 63rd) = 63. S144: + fanner (Blastmere, 64th) = 64. S146: + mealman (Whitedamp, 65th) = 65.
	# This arm went red-by-staleness at the 51st; it is the sibling of _s51_names.gd:64 and moves with it.
	_ok(mbn == 65, "MB_NAME holds 65 (S146 + mealman, S144 + fanner) (got %d)" % mbn)
	if _fails == 0:
		print("S107_GATE OK %d" % _checks)
	else:
		print("S107_GATE FAIL %d (%d)" % [_fails, _checks])
	quit()
