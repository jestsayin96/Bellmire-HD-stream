extends SceneTree
## S120: the weigher (56th, Trueweight, art's tag treasury - field 5) gets its MB_FIT (1.04, art's
## _fit_report.json pairs.weigher.ratio) and a treasury row, and NOTHING ELSE: content's
## by_key.weigher has not landed, so NO MB_NAME row and miniboss_for must HOLD IT OUT. This gate
## asserts the body loads (so the only thing holding it out is the missing lines), the lines are
## absent, and a 400-draw treasury sweep never yields weigher while it DOES yield changer (red-proof:
## a sweep that draws nothing cannot pass). When content's lines land, flip the last arm.
## Prints S120_WEIGHER OK <checks> / S120_WEIGHER FAIL <n> (<checks>).
var _fails := 0
var _checks := 0
func _ok(c: bool, what: String) -> void:
	_checks += 1
	if not c:
		_fails += 1
		print("FAIL " + what)
func _initialize() -> void:
	_ok("weigher" in DungeonHD.THEME_MINIBOSS_MORE["treasury"], "weigher is in the treasury row")
	_ok(is_equal_approx(float(Delve.MB_FIT.get("weigher", -1.0)), 1.04), "MB_FIT weigher 1.04")
	_ok(not Delve.MB_NAME.has("weigher"), "no MB_NAME weigher until by_key.weigher lands")
	var mp := Delve.miniboss_model("weigher")
	_ok(mp != "", "miniboss_model(weigher) resolves (got '%s')" % mp)
	var ps: PackedScene = load(mp) if mp != "" else null
	_ok(ps != null, "weigher.glb LOADS as a PackedScene")
	if ps != null:
		var n := ps.instantiate()
		_ok(n != null, "weigher instantiates")
		if n != null:
			n.free()
	_ok(Delve.miniboss_lines("weigher", "arrive").is_empty(), "content's weigher arrive lines are absent (flip when they land)")
	var seen := {}
	for i in 400:
		seen[DungeonHD.miniboss_for("treasury", i)] = true
	_ok(not seen.has("weigher"), "treasury sweep never draws weigher while it has no lines")
	_ok(seen.has("changer"), "treasury sweep DOES draw changer (sweep is live)")
	print("S120 treasury draw set: %s" % [seen.keys()])
	if _fails == 0:
		print("S120_WEIGHER OK %d" % _checks)
	else:
		print("S120_WEIGHER FAIL %d (%d)" % [_fails, _checks])
	quit(0 if _fails == 0 else 1)
