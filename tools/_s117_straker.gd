extends SceneTree
## S117: the 55th body `straker` (Everyhand, art's tag wood) is in MB_FIT and in the wood row, and
## miniboss_for HOLDS IT OUT until content's by_key.straker arrive lines land. The red-proof is the
## sweep itself drawing drover and winder from the same row. When C-195 lands, flip the hold-out
## arm (straker IS drawn) along with the MB_NAME row. Prints S117_STRAKER OK <n> / FAIL.
var _fails := 0
var _checks := 0
func _ok(c: bool, what: String) -> void:
	_checks += 1
	if not c:
		_fails += 1
		print("FAIL " + what)
func _initialize() -> void:
	_ok(Delve.MB_FIT.has("straker"), "MB_FIT has straker")
	_ok(is_equal_approx(float(Delve.MB_FIT.get("straker", 0.0)), 0.98), "MB_FIT straker is art's 0.98")
	_ok((DungeonHD.THEME_MINIBOSS_MORE.get("wood", []) as Array).has("straker"), "straker is in the wood row")
	var model := Delve.miniboss_model("straker")
	print("S117 straker model: '%s'" % model)
	_ok(model != "", "straker.glb resolves")
	var fed := not Delve.miniboss_lines("straker", "arrive").is_empty()
	print("S117 straker arrive lines present: %s" % fed)
	var drawn := {}
	for n in 4000:
		drawn[DungeonHD.miniboss_for("wood", n)] = true
	print("S117 wood draws over 4000 picks: ", drawn.keys())
	_ok(drawn.has("drover") and drawn.has("winder"), "red-proof: drover and winder ARE drawn by the same sweep")
	_ok(drawn.has("straker") == fed, "straker drawn exactly when its arrive lines exist (fed=%s)" % fed)
	_ok(Delve.MB_NAME.has("straker") == false or fed, "no MB_NAME row ahead of the feed")
	# S118: C-195 landed - the hold-out arm is flipped to HARD arms: fed, drawn in wood, named Everyhand.
	_ok(fed, "S118: straker is fed (content's by_key.straker arrive lines)")
	_ok(drawn.has("straker"), "S118: straker IS drawn by the wood sweep")
	_ok(Delve.MB_NAME.get("straker", "") == "Everyhand", "S118: MB_NAME straker is Everyhand (got '%s')" % Delve.MB_NAME.get("straker", ""))
	_ok(Delve.MB_NAME.size() == 66, "MB_NAME is 66 (S148 + thatcher, S146 + mealman, S144 + fanner, S141 + overlooker); S118/S121/S122/S123/S124/S126/S127/S129 (got %d) - S121 + weigher, S122 + dredger, S123 + harrowman, S124 + pledgeman" % Delve.MB_NAME.size())
	if _fails == 0:
		print("S117_STRAKER OK %d" % _checks)
	else:
		print("S117_STRAKER FAIL %d of %d" % [_fails, _checks])
	quit(0 if _fails == 0 else 1)
