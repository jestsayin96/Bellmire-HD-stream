extends SceneTree
## S154: the 67th body `badger` (Forestall, art's CANON minibosses.py:25806) carries art's _fit_report.json
## ratio 0.99 in MB_FIT, sits in the mess row (art's field 5), and is NAMED in MB_NAME on the team lead's
## 09:58 row (art's fit ticked on his own look). Content's by_key.badger has NOT landed at S154, so the
## check is "named now; drawn exactly when fed" - the fanner precedent (S144).
var _n := 0
var _bad := 0
func _ok(c: bool, what: String) -> void:
	_n += 1
	if not c:
		_bad += 1
		print("S154 FAIL: " + what)
func _initialize() -> void:
	_ok(is_equal_approx(float(Delve.MB_FIT.get("badger", 0.0)), 0.99), "MB_FIT badger is art's 0.99")
	_ok((DungeonHD.THEME_MINIBOSS_MORE.get("mess", []) as Array).has("badger"), "badger is in the mess row")
	var model := Delve.miniboss_model("badger")
	print("S154 badger model: '%s'" % model)
	_ok(model != "", "badger.glb resolves")
	var fed := not Delve.miniboss_lines("badger", "arrive").is_empty()
	print("S154 badger fed: %s" % fed)
	_ok(Delve.MB_NAME.size() == 67, "MB_NAME is 67 (got %d)" % Delve.MB_NAME.size())
	_ok(Delve.MB_NAME.get("badger", "") == "Forestall", "MB_NAME badger is Forestall (got '%s')" % Delve.MB_NAME.get("badger", ""))
	_ok(Delve.miniboss_name("badger") == "Forestall", "nameplate reads Forestall, not Badger")
	_ok(Delve.MB_NAME.get("thatcher", "") == "Lastcourse", "thatcher still Lastcourse")
	var uniq := {}
	for k in Delve.MB_NAME:
		uniq[String(Delve.MB_NAME[k])] = true
	_ok(uniq.size() == Delve.MB_NAME.size(), "every MB_NAME value is unique (%d of %d)" % [uniq.size(), Delve.MB_NAME.size()])
	var drawn := {}
	for n in 4000:
		drawn[DungeonHD.miniboss_for("mess", n)] = true
	print("S154 mess draw: %s" % [drawn.keys()])
	_ok(drawn.has("badger") == fed, "badger is drawn exactly when fed (fed=%s drawn=%s)" % [fed, drawn.has("badger")])
	for k in ["loader", "hooper", "iceman", "mealman"]:
		_ok(drawn.has(k), "red-proof: %s IS still drawn by the same sweep" % k)
	var seen := {}
	var dup := 0
	for t in DungeonHD.THEME_MINIBOSS_MORE:
		for k in DungeonHD.THEME_MINIBOSS_MORE[t]:
			if seen.has(k): dup += 1
			seen[k] = true
	_ok(dup == 0, "no body sits in two theme rows (%d dupes)" % dup)
	if _n < 14:
		print("S154_BADGER FAILED - only %d checks ran" % _n)
	elif _bad == 0:
		print("S154_BADGER OK (%d checks)" % _n)
	else:
		print("S154_BADGER FAILED (%d of %d)" % [_bad, _n])
	quit()
