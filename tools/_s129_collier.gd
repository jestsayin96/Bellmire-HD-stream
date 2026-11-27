extends SceneTree
## S129: the 62nd body `collier` (Halfblow, art's tag wood - field 5) is in MB_FIT at art's
## _fit_report.json ratio 0.86, in the wood row of THEME_MINIBOSS_MORE, and - because content's
## C-205 by_key.collier is on main - named Halfblow in MB_NAME in the same change. Floor of 10.
var _n := 0
var _bad := 0
func _ok(c: bool, what: String) -> void:
	_n += 1
	if not c:
		_bad += 1
		print("S129 FAIL: " + what)
func _initialize() -> void:
	_ok(Delve.MB_FIT.has("collier"), "MB_FIT has collier")
	_ok(is_equal_approx(float(Delve.MB_FIT.get("collier", 0.0)), 0.86), "MB_FIT collier is art's 0.86")
	_ok((DungeonHD.THEME_MINIBOSS_MORE.get("wood", []) as Array).has("collier"), "collier is in the wood row")
	var model := Delve.miniboss_model("collier")
	print("S129 collier model: '%s'" % model)
	_ok(model != "", "collier.glb resolves")
	var fed := not Delve.miniboss_lines("collier", "arrive").is_empty()
	print("S129 collier fed: %s" % fed)
	_ok(fed, "content's C-205 by_key.collier arrive lines are present")
	var drawn := {}
	for n in 4000:
		drawn[DungeonHD.miniboss_for("wood", n)] = true
	print("S129 wood draw: %s" % [drawn.keys()])
	_ok(drawn.has("collier") == fed, "collier is drawn exactly when fed (fed=%s drawn=%s)" % [fed, drawn.has("collier")])
	_ok(Delve.MB_NAME.get("collier", "") == "Halfblow", "MB_NAME collier is Halfblow (got '%s')" % Delve.MB_NAME.get("collier", ""))
	_ok(Delve.miniboss_name("collier") == "Halfblow", "nameplate reads Halfblow, not Collier")
	_ok(Delve.MB_NAME.size() == 67, "MB_NAME is 67 (S154 + badger, S148 + thatcher, S146 + mealman, S144 + fanner, S141 + overlooker) (got %d)" % Delve.MB_NAME.size())
	for k in ["drover", "straker"]:
		_ok(drawn.has(k), "red-proof: %s IS drawn by the same sweep" % k)
	if _n < 10:
		print("S129_COLLIER FAILED - only %d checks ran" % _n)
	elif _bad == 0:
		print("S129_COLLIER OK (%d checks)" % _n)
	else:
		print("S129_COLLIER FAILED (%d of %d)" % [_bad, _n])
	quit()
