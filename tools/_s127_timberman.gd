extends SceneTree
## S127: the 61st body `timberman` (Deadfall, art's tag crypt - field 5) is in MB_FIT at art's
## _fit_report.json ratio 1.24, in the crypt row of THEME_MINIBOSS_MORE, and - because content's
## C-203 by_key.timberman is on main - named Deadfall in MB_NAME in the same change. Floor of 10.
var _n := 0
var _bad := 0
func _ok(c: bool, what: String) -> void:
	_n += 1
	if not c:
		_bad += 1
		print("S127 FAIL: " + what)
func _initialize() -> void:
	_ok(Delve.MB_FIT.has("timberman"), "MB_FIT has timberman")
	_ok(is_equal_approx(float(Delve.MB_FIT.get("timberman", 0.0)), 1.24), "MB_FIT timberman is art's 1.24")
	_ok((DungeonHD.THEME_MINIBOSS_MORE.get("crypt", []) as Array).has("timberman"), "timberman is in the crypt row")
	var model := Delve.miniboss_model("timberman")
	print("S127 timberman model: '%s'" % model)
	_ok(model != "", "timberman.glb resolves")
	var fed := not Delve.miniboss_lines("timberman", "arrive").is_empty()
	print("S127 timberman fed: %s" % fed)
	_ok(fed, "content's C-203 by_key.timberman arrive lines are present")
	var drawn := {}
	for n in 4000:
		drawn[DungeonHD.miniboss_for("crypt", n)] = true
	print("S127 crypt draw: %s" % [drawn.keys()])
	_ok(drawn.has("timberman") == fed, "timberman is drawn exactly when fed (fed=%s drawn=%s)" % [fed, drawn.has("timberman")])
	_ok(Delve.MB_NAME.get("timberman", "") == "Deadfall", "MB_NAME timberman is Deadfall (got '%s')" % Delve.MB_NAME.get("timberman", ""))
	_ok(Delve.miniboss_name("timberman") == "Deadfall", "nameplate reads Deadfall, not Timberman")
	_ok(Delve.MB_NAME.size() == 66, "MB_NAME is 66 (S148 + thatcher, S146 + mealman, S144 + fanner, S141 + overlooker) (S129 + collier) (got %d)" % Delve.MB_NAME.size())
	for k in ["ratcatcher", "stopper"]:
		_ok(drawn.has(k), "red-proof: %s IS drawn by the same sweep" % k)
	if _n < 10:
		print("S127_TIMBERMAN FAILED - only %d checks ran" % _n)
	elif _bad == 0:
		print("S127_TIMBERMAN OK (%d checks)" % _n)
	else:
		print("S127_TIMBERMAN FAILED (%d of %d)" % [_bad, _n])
	quit()
