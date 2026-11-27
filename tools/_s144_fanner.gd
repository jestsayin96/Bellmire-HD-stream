extends SceneTree
## S144: the 64th body `fanner` is named Blastmere in MB_NAME (art's CANON title, minibosses.py:24245),
## carries art's _fit_report.json ratio 0.95 in MB_FIT, and sits in the firepit row (art's field 5).
## Content's by_key.fanner (C-222) has NOT landed, so the body must be HELD: miniboss_for must not draw
## it until it is fed, and must draw it once it is. The check is "drawn == fed", so it stays true either side.
var _n := 0
var _bad := 0
func _ok(c: bool, what: String) -> void:
	_n += 1
	if not c:
		_bad += 1
		print("S144 FAIL: " + what)
func _initialize() -> void:
	_ok(Delve.MB_NAME.get("fanner", "") == "Blastmere", "MB_NAME fanner is Blastmere (got '%s')" % Delve.MB_NAME.get("fanner", ""))
	_ok(Delve.miniboss_name("fanner") == "Blastmere", "nameplate reads Blastmere, not Fanner")
	_ok(Delve.MB_NAME.size() == 67, "MB_NAME is 67 (S154 + badger, S148 + thatcher, S146 + mealman) (got %d)" % Delve.MB_NAME.size())
	_ok(is_equal_approx(float(Delve.MB_FIT.get("fanner", 0.0)), 0.95), "MB_FIT fanner is art's 0.95")
	_ok((DungeonHD.THEME_MINIBOSS_MORE.get("firepit", []) as Array).has("fanner"), "fanner is in the firepit row")
	var model := Delve.miniboss_model("fanner")
	print("S144 fanner model: '%s'" % model)
	_ok(model != "", "fanner.glb resolves")
	var fed := not Delve.miniboss_lines("fanner", "arrive").is_empty()
	print("S144 fanner fed: %s" % fed)
	var drawn := {}
	for n in 4000:
		drawn[DungeonHD.miniboss_for("firepit", n)] = true
	print("S144 firepit draw: %s" % [drawn.keys()])
	_ok(drawn.has("fanner") == fed, "fanner is drawn exactly when fed (fed=%s drawn=%s)" % [fed, drawn.has("fanner")])
	for k in ["moulder", "tapster"]:
		_ok(drawn.has(k), "red-proof: %s IS drawn by the same sweep" % k)
	var names := {}
	for k in Delve.MB_NAME:
		names[String(Delve.MB_NAME[k])] = true
	_ok(names.size() == Delve.MB_NAME.size(), "every MB_NAME value is unique (%d of %d)" % [names.size(), Delve.MB_NAME.size()])
	if _n < 10:
		print("S144_FANNER FAILED - only %d checks ran" % _n)
	elif _bad == 0:
		print("S144_FANNER OK (%d checks)" % _n)
	else:
		print("S144_FANNER FAILED (%d of %d)" % [_bad, _n])
	quit()
