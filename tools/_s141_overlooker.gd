extends SceneTree
## S141: the 63rd body `overlooker` (Velrick, art's tag workshop - field 5) is in MB_FIT at art's
## _fit_report.json ratio 0.98, in the workshop row of THEME_MINIBOSS_MORE, and - because content's
## C-216 by_key.overlooker is on main - named Velrick in MB_NAME in the same change. Floor of 10.
var _n := 0
var _bad := 0
func _ok(c: bool, what: String) -> void:
	_n += 1
	if not c:
		_bad += 1
		print("S141 FAIL: " + what)
func _initialize() -> void:
	_ok(Delve.MB_FIT.has("overlooker"), "MB_FIT has overlooker")
	_ok(is_equal_approx(float(Delve.MB_FIT.get("overlooker", 0.0)), 0.98), "MB_FIT overlooker is art's 0.98")
	_ok((DungeonHD.THEME_MINIBOSS_MORE.get("workshop", []) as Array).has("overlooker"), "overlooker is in the workshop row")
	var model := Delve.miniboss_model("overlooker")
	print("S141 overlooker model: '%s'" % model)
	_ok(model != "", "overlooker.glb resolves")
	var fed := not Delve.miniboss_lines("overlooker", "arrive").is_empty()
	print("S141 overlooker fed: %s" % fed)
	_ok(fed, "content's C-216 by_key.overlooker arrive lines are present")
	var drawn := {}
	for n in 4000:
		drawn[DungeonHD.miniboss_for("workshop", n)] = true
	print("S141 workshop draw: %s" % [drawn.keys()])
	_ok(drawn.has("overlooker") == fed, "overlooker is drawn exactly when fed (fed=%s drawn=%s)" % [fed, drawn.has("overlooker")])
	_ok(Delve.MB_NAME.get("overlooker", "") == "Velrick", "MB_NAME overlooker is Velrick (got '%s')" % Delve.MB_NAME.get("overlooker", ""))
	_ok(Delve.miniboss_name("overlooker") == "Velrick", "nameplate reads Velrick, not Overlooker")
	_ok(Delve.MB_NAME.size() == 65, "MB_NAME is 65 (S146 + mealman, S144 + fanner) (got %d)" % Delve.MB_NAME.size())
	for k in ["jointer", "dyer"]:
		_ok(drawn.has(k), "red-proof: %s IS drawn by the same sweep" % k)
	if _n < 10:
		print("S141_OVERLOOKER FAILED - only %d checks ran" % _n)
	elif _bad == 0:
		print("S141_OVERLOOKER OK (%d checks)" % _n)
	else:
		print("S141_OVERLOOKER FAILED (%d of %d)" % [_bad, _n])
	quit()
