extends SceneTree
## S115: the 54th body `iceman` (Hoarback, art's tag mess) is in MB_FIT and in the mess row, and
## miniboss_for HOLDS IT OUT until content's by_key.iceman arrive lines land. The red-proof is the
## sweep itself drawing loader and hooper from the same row. When C-lines land, flip the hold-out
## arm (iceman IS drawn) along with the MB_NAME row. Prints S115_ICEMAN OK <n> / FAIL.
var _fails := 0
var _checks := 0
func _ok(c: bool, what: String) -> void:
	_checks += 1
	if not c:
		_fails += 1
		print("FAIL " + what)
func _initialize() -> void:
	_ok(Delve.MB_FIT.has("iceman"), "MB_FIT has iceman")
	_ok(is_equal_approx(float(Delve.MB_FIT.get("iceman", 0.0)), 1.27), "MB_FIT iceman is art's 1.27")
	_ok((DungeonHD.THEME_MINIBOSS_MORE.get("mess", []) as Array).has("iceman"), "iceman is in the mess row")
	var model := Delve.miniboss_model("iceman")
	print("S115 iceman model: '%s'" % model)
	_ok(model != "", "iceman.glb resolves")
	var fed := not Delve.miniboss_lines("iceman", "arrive").is_empty()
	print("S115 iceman arrive lines present: %s" % fed)
	var drawn := {}
	for n in 4000:
		drawn[DungeonHD.miniboss_for("mess", n)] = true
	print("S115 mess draws over 4000 picks: ", drawn.keys())
	_ok(drawn.has("loader") and drawn.has("hooper"), "red-proof: loader and hooper ARE drawn by the same sweep")
	_ok(drawn.has("iceman") == fed, "iceman drawn exactly when its arrive lines exist (fed=%s)" % fed)
	_ok(Delve.MB_NAME.has("iceman") == false or fed, "no MB_NAME row ahead of the feed")
	if _fails == 0:
		print("S115_ICEMAN OK %d" % _checks)
	else:
		print("S115_ICEMAN FAIL %d of %d" % [_fails, _checks])
	quit(0 if _fails == 0 else 1)
