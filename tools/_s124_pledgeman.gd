extends SceneTree
## S124: the 59th body `pledgeman` (Heldfast, art's tag treasury - field 5) is in MB_FIT at art's
## 1.05, in the treasury row, fed by content's C-201, drawn by the treasury sweep and named Heldfast.
## Red-proof: the same sweep must also draw the four older treasury bodies.
## Prints S124_PLEDGEMAN OK <n> / FAIL.
var _fails := 0
var _checks := 0
func _ok(c: bool, what: String) -> void:
	_checks += 1
	if not c:
		_fails += 1
		print("FAIL " + what)
func _initialize() -> void:
	_ok(Delve.MB_FIT.has("pledgeman"), "MB_FIT has pledgeman")
	_ok(is_equal_approx(float(Delve.MB_FIT.get("pledgeman", 0.0)), 1.05), "MB_FIT pledgeman is art's 1.05")
	_ok((DungeonHD.THEME_MINIBOSS_MORE.get("treasury", []) as Array).has("pledgeman"), "pledgeman is in the treasury row")
	var model := Delve.miniboss_model("pledgeman")
	print("S124 pledgeman model: '%s'" % model)
	_ok(model != "", "pledgeman.glb resolves")
	var fed := not Delve.miniboss_lines("pledgeman", "arrive").is_empty()
	_ok(fed, "pledgeman is fed (content's C-201 by_key.pledgeman arrive lines)")
	var drawn := {}
	for n in 4000:
		drawn[DungeonHD.miniboss_for("treasury", n)] = true
	print("S124 treasury draws over 4000 picks: ", drawn.keys())
	for k in ["strickler", "sealer", "changer", "weigher"]:
		_ok(drawn.has(k), "red-proof: %s IS drawn by the same sweep" % k)
	_ok(drawn.has("pledgeman"), "pledgeman IS drawn by the treasury sweep")
	_ok(Delve.MB_NAME.get("pledgeman", "") == "Heldfast", "MB_NAME pledgeman is Heldfast (got '%s')" % Delve.MB_NAME.get("pledgeman", ""))
	_ok(Delve.miniboss_name("pledgeman") == "Heldfast", "miniboss_name resolves Heldfast")
	_ok(Delve.MB_NAME.size() == 63, "MB_NAME is 63 (S141 + overlooker) (got %d) - S126 + crimp, S127 + timberman, S129 + collier" % Delve.MB_NAME.size())
	if _fails == 0:
		print("S124_PLEDGEMAN OK %d" % _checks)
	else:
		print("S124_PLEDGEMAN FAIL %d of %d" % [_fails, _checks])
	quit(0 if _fails == 0 else 1)
