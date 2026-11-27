extends SceneTree
## S145: the 65th body `mealman` (Whitedamp, art's CANON minibosses.py:24699) carries art's _fit_report.json
## ratio 0.97 in MB_FIT and sits in the mess row (art's field 5). Content's by_key.mealman has NOT landed, so
## NO MB_NAME row is written and miniboss_for must hold it out until fed. The check is "drawn == fed".
var _n := 0
var _bad := 0
func _ok(c: bool, what: String) -> void:
	_n += 1
	if not c:
		_bad += 1
		print("S145 FAIL: " + what)
func _initialize() -> void:
	_ok(is_equal_approx(float(Delve.MB_FIT.get("mealman", 0.0)), 0.97), "MB_FIT mealman is art's 0.97")
	_ok((DungeonHD.THEME_MINIBOSS_MORE.get("mess", []) as Array).has("mealman"), "mealman is in the mess row")
	var model := Delve.miniboss_model("mealman")
	print("S145 mealman model: '%s'" % model)
	_ok(model != "", "mealman.glb resolves")
	var fed := not Delve.miniboss_lines("mealman", "arrive").is_empty()
	print("S145 mealman fed: %s" % fed)
	_ok(Delve.MB_NAME.has("mealman") == fed, "MB_NAME row exists exactly when fed (fed=%s named=%s)" % [fed, Delve.MB_NAME.has("mealman")])
	_ok(Delve.MB_NAME.size() == (66 if fed else 64), "MB_NAME is 66 once fed (S148 + thatcher, got %d)" % Delve.MB_NAME.size())
	# S146: content's C-225 landed, so the hold is spent and the name is written - art's CANON title.
	_ok(fed, "S146: by_key.mealman is on main (C-225)")
	_ok(Delve.MB_NAME.get("mealman", "") == "Whitedamp", "MB_NAME mealman is Whitedamp (got '%s')" % Delve.MB_NAME.get("mealman", ""))
	_ok(Delve.miniboss_name("mealman") == "Whitedamp", "nameplate reads Whitedamp, not Mealman")
	var uniq := {}
	for k in Delve.MB_NAME:
		uniq[String(Delve.MB_NAME[k])] = true
	_ok(uniq.size() == Delve.MB_NAME.size(), "every MB_NAME value is unique (%d of %d)" % [uniq.size(), Delve.MB_NAME.size()])
	var drawn := {}
	for n in 4000:
		drawn[DungeonHD.miniboss_for("mess", n)] = true
	print("S145 mess draw: %s" % [drawn.keys()])
	_ok(drawn.has("mealman") == fed, "mealman is drawn exactly when fed (fed=%s drawn=%s)" % [fed, drawn.has("mealman")])
	for k in ["loader", "hooper"]:
		_ok(drawn.has(k), "red-proof: %s IS drawn by the same sweep" % k)
	var seen := {}
	var dup := 0
	for t in DungeonHD.THEME_MINIBOSS_MORE:
		for k in DungeonHD.THEME_MINIBOSS_MORE[t]:
			if seen.has(k): dup += 1
			seen[k] = true
	_ok(dup == 0, "no body sits in two theme rows (%d dupes)" % dup)
	_ok(not seen.has("fanner") or (DungeonHD.THEME_MINIBOSS_MORE["firepit"] as Array).has("fanner"), "fanner still in firepit")
	if _n < 10:
		print("S145_MEALMAN FAILED - only %d checks ran" % _n)
	elif _bad == 0:
		print("S145_MEALMAN OK (%d checks)" % _n)
	else:
		print("S145_MEALMAN FAILED (%d of %d)" % [_bad, _n])
	quit()
