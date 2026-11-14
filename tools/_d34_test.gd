extends SceneTree
## D34 TEST - natural disasters (desktop, economy.gd). The words are the content
## writer\'s (lore_lines.json "disasters"); this checks the MECHANIC: each of the
## 13 disasters charges its onset cost against the town\'s own stock/treasury/
## renown, raises the right active flags, cries a begin line, speaks while it
## lasts, passes with a pass line + its rebuild cost or windfall, and resets. Also
## that it is one-at-a-time and gated on town size. Headless: strings and numbers
## are asserted, not looked at. Prints D34_TEST OK/FAIL.
class StubTown extends Node3D:
	var feed: Array = []

var _checks := 0
var _fails: Array = []

func _ok(c: bool, what: String) -> void:
	_checks += 1
	if not c:
		_fails.append(what)
	print("  %s %s" % ["ok  " if c else "FAIL", what])

func _fresh(eco: Economy) -> void:
	eco.stock = {"food": 100.0, "wood": 100.0, "stone": 100.0, "ore": 100.0, "gear": 100.0, "potion": 100.0}
	eco.treasury = 400
	eco.renown = 5
	eco.dis_work_k = 1.0
	eco._dis_no_growth = false
	eco._dis_no_cast = false
	eco._dis_trade_frozen = false

func _initialize() -> void:
	print("D34_TEST start")
	var eco := Economy.new()
	var stub := StubTown.new()
	eco.town = stub
	var feed: Array = stub.feed

	var keys: Array = Economy.DIS_SPECS.keys()
	_ok(keys.size() == 13, "all 13 disasters present in DIS_SPECS (%d)" % keys.size())

	for key in keys:
		_fresh(eco)
		eco._dis_active = ""
		var spec: Dictionary = Economy.DIS_SPECS[key]
		var before := feed.size()
		var ok := eco.trigger_disaster(String(key))
		_ok(ok, "%s: triggers" % key)
		_ok(eco.disaster_active() == String(key), "%s: is the active disaster" % key)
		_ok(feed.size() > before and String(feed.back()) != "", "%s: cries a begin line" % key)
		# onset cost against stock
		for g in Economy.GOODS:
			if spec.has(g):
				_ok(float(eco.stock[g]) < 100.0, "%s: costs %s (%.1f)" % [key, g, float(eco.stock[g])])
		if spec.has("gold"):
			_ok(eco.treasury < 400, "%s: costs gold (%d)" % [key, eco.treasury])
		if spec.has("renown"):
			_ok(eco.renown < 5, "%s: costs renown (%d)" % [key, eco.renown])
		# active flags match the spec
		_ok(is_equal_approx(eco.dis_work_k, float(spec.get("workk", 1.0))), "%s: production damp set" % key)
		_ok(eco._dis_no_growth == bool(spec.get("no_growth", false)), "%s: no_growth flag" % key)
		_ok(eco.casting_blocked() == bool(spec.get("no_cast", false)), "%s: no_cast flag" % key)
		_ok(eco.trade_blocked() == bool(spec.get("trade_frozen", false)), "%s: trade_frozen flag" % key)
		# only one at a time
		_ok(eco.trigger_disaster("fire") == false, "%s: cannot start a second while active" % key)
		# speaks while it lasts
		var b2 := feed.size()
		eco._disaster_tick(Economy.DIS_DURING_GAP + 0.1)
		_ok(feed.size() > b2, "%s: speaks a during line" % key)
		# passes, applies rebuild cost / windfall, resets
		var tbefore := eco.treasury
		var og := int(spec.get("on_pass_gold", 0))
		eco._end_disaster()
		_ok(eco.disaster_active() == "", "%s: ends" % key)
		_ok(eco.treasury == max(0, tbefore + og), "%s: on_pass gold %d (%d->%d)" % [key, og, tbefore, eco.treasury])
		_ok(eco.dis_work_k == 1.0 and not eco._dis_no_growth and not eco._dis_no_cast and not eco._dis_trade_frozen, "%s: flags reset on pass" % key)

	_ok(eco.disasters_survived == 13, "survived counter counts every disaster (%d)" % eco.disasters_survived)

	# scheduler gating: nothing before the town is grown, something after
	var e2 := Economy.new()
	e2.town = StubTown.new()
	e2.town_level = 1
	e2.day = 1
	e2._dis_cool = 0.01
	e2._disaster_tick(1.0)
	_ok(e2.disaster_active() == "", "gated: no disaster in the first days of a tiny town")
	e2.town_level = 3
	e2.day = 20
	e2._dis_cool = 0.01
	e2._disaster_tick(1.0)
	_ok(e2.disaster_active() != "", "scheduler fires once the town is worth striking")

	if _fails.is_empty():
		print("D34_TEST OK (%d checks, 0 failed)" % _checks)
	else:
		print("D34_TEST FAIL (%d checks, %d failed): %s" % [_checks, _fails.size(), str(_fails)])
	quit()
