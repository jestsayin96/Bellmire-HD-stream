extends SceneTree
## S126: the 60th body `crimp` (Oneshort, art's tag barracks - field 5) is in MB_FIT at art's
## _fit_report.json ratio 0.99 and in the barracks row of THEME_MINIBOSS_MORE. Content's C-202
## by_key.crimp has NOT landed, so the gate must hold it OUT of the draw and MB_NAME must not
## carry it yet (a name with no feed row is chatcmd.gd's MINIBOSS GHOST). Floor of 9 checks.
var _n := 0
var _bad := 0
func _ok(c: bool, what: String) -> void:
	_n += 1
	if not c:
		_bad += 1
		print("S126 FAIL: " + what)
func _initialize() -> void:
	_ok(Delve.MB_FIT.has("crimp"), "MB_FIT has crimp")
	_ok(is_equal_approx(float(Delve.MB_FIT.get("crimp", 0.0)), 0.99), "MB_FIT crimp is art's 0.99")
	_ok((DungeonHD.THEME_MINIBOSS_MORE.get("barracks", []) as Array).has("crimp"), "crimp is in the barracks row")
	var model := Delve.miniboss_model("crimp")
	print("S126 crimp model: '%s'" % model)
	_ok(model != "", "crimp.glb resolves")
	var fed := not Delve.miniboss_lines("crimp", "arrive").is_empty()
	print("S126 crimp fed: %s" % fed)
	if fed:
		print("S126 NOTE: content's by_key.crimp has landed - the MB_NAME row (Oneshort) is now owed")
	var drawn := {}
	for n in 4000:
		drawn[DungeonHD.miniboss_for("barracks", n)] = true
	print("S126 barracks draw: %s" % [drawn.keys()])
	_ok(drawn.has("crimp") == fed, "crimp is drawn exactly when fed (fed=%s drawn=%s)" % [fed, drawn.has("crimp")])
	_ok(not Delve.MB_NAME.has("crimp") or fed, "MB_NAME carries no crimp row while the feed is absent")
	_ok(Delve.MB_NAME.size() == 59, "MB_NAME is 59 (got %d)" % Delve.MB_NAME.size())
	for k in ["quartermaster", "relief"]:
		_ok(drawn.has(k), "red-proof: %s IS drawn by the same sweep" % k)
	if _n < 9:
		print("S126_CRIMP FAILED - only %d checks ran" % _n)
	elif _bad == 0:
		print("S126_CRIMP OK (%d checks)" % _n)
	else:
		print("S126_CRIMP FAILED (%d of %d)" % [_bad, _n])
	quit()
