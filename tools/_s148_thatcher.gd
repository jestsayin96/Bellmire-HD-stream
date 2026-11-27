extends SceneTree
## S148: the 66th body `thatcher` (Lastcourse, art's CANON minibosses.py:25131) carries art's _fit_report.json
## ratio 1.04 in MB_FIT, sits in the flooded row (art's field 5), and - content's C-227 by_key.thatcher having
## landed - is NAMED in MB_NAME in the same change. The check is "drawn == fed == named".
var _n := 0
var _bad := 0
func _ok(c: bool, what: String) -> void:
	_n += 1
	if not c:
		_bad += 1
		print("S148 FAIL: " + what)
func _initialize() -> void:
	_ok(is_equal_approx(float(Delve.MB_FIT.get("thatcher", 0.0)), 1.04), "MB_FIT thatcher is art's 1.04 (not the mealman's 0.97)")
	_ok((DungeonHD.THEME_MINIBOSS_MORE.get("flooded", []) as Array).has("thatcher"), "thatcher is in the flooded row")
	var model := Delve.miniboss_model("thatcher")
	print("S148 thatcher model: '%s'" % model)
	_ok(model != "", "thatcher.glb resolves")
	var fed := not Delve.miniboss_lines("thatcher", "arrive").is_empty()
	print("S148 thatcher fed: %s" % fed)
	_ok(fed, "by_key.thatcher is on main (C-227)")
	_ok(Delve.MB_NAME.has("thatcher") == fed, "MB_NAME row exists exactly when fed (fed=%s named=%s)" % [fed, Delve.MB_NAME.has("thatcher")])
	_ok(Delve.MB_NAME.size() == 67, "MB_NAME is 67 (S154 + badger) (got %d)" % Delve.MB_NAME.size())
	_ok(Delve.MB_NAME.get("thatcher", "") == "Lastcourse", "MB_NAME thatcher is Lastcourse (got '%s')" % Delve.MB_NAME.get("thatcher", ""))
	_ok(Delve.miniboss_name("thatcher") == "Lastcourse", "nameplate reads Lastcourse, not Thatcher")
	_ok(Delve.MB_NAME.get("mealman", "") == "Whitedamp", "mealman still Whitedamp")
	var uniq := {}
	for k in Delve.MB_NAME:
		uniq[String(Delve.MB_NAME[k])] = true
	_ok(uniq.size() == Delve.MB_NAME.size(), "every MB_NAME value is unique (%d of %d)" % [uniq.size(), Delve.MB_NAME.size()])
	var drawn := {}
	for n in 4000:
		drawn[DungeonHD.miniboss_for("flooded", n)] = true
	print("S148 flooded draw: %s" % [drawn.keys()])
	_ok(drawn.has("thatcher") == fed, "thatcher is drawn exactly when fed (fed=%s drawn=%s)" % [fed, drawn.has("thatcher")])
	for k in ["tanner", "rammer", "ferryman"]:
		_ok(drawn.has(k), "red-proof: %s IS still drawn by the same sweep" % k)
	var seen := {}
	var dup := 0
	for t in DungeonHD.THEME_MINIBOSS_MORE:
		for k in DungeonHD.THEME_MINIBOSS_MORE[t]:
			if seen.has(k): dup += 1
			seen[k] = true
	_ok(dup == 0, "no body sits in two theme rows (%d dupes)" % dup)
	if _n < 12:
		print("S148_THATCHER FAILED - only %d checks ran" % _n)
	elif _bad == 0:
		print("S148_THATCHER OK (%d checks)" % _n)
	else:
		print("S148_THATCHER FAILED (%d of %d)" % [_bad, _n])
	quit()
