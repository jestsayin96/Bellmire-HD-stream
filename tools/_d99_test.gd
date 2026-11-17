extends SceneTree
## D99_TEST - the ladders go live (game build, 17 Nov). Headless.
##   A. stock_by_tier: every shop_adds / cargo_adds key reports the first tier the file lists it at
##      (counted off the file), and stock_open is false below that tier and true at/after it
##   B. the REAL shelf path (SnapshotPublisher._shelf_add): at every tier 1..12, no shop_stock good
##      lands on a shelf before its stock_by_tier tier; and goods DO land once opened
##   C. price_ladders: Economy.ladder_faults() over the file - every ladder key found, cost and tier
##      non-decreasing. Faults are printed by name.
##   D. classes.json healing: read from the file, mend_interval_s and the quaff threshold equal the
##      numbers in the file's own fields/sentence
## Run: <console> --headless --path . --script tools/_d99_test.gd
var _fails: Array = []
var _checks := 0

func _ok(c: bool, what: String) -> void:
	_checks += 1
	if not c:
		print("  FAIL ", what)
		_fails.append(what)

func _initialize() -> void:
	var it := Economy.items_data()
	var sbt: Array = (it.get("stock_by_tier", {}) as Dictionary).get("tiers", [])
	_ok(sbt.size() == 12, "A: stock_by_tier has 12 tiers (%d)" % sbt.size())
	var first := {"shop_adds": {}, "cargo_adds": {}}
	for row in sbt:
		for kind in ["shop_adds", "cargo_adds"]:
			for k in ((row as Dictionary).get(kind, []) as Array):
				if not (first[kind] as Dictionary).has(String(k)):
					first[kind][String(k)] = int((row as Dictionary)["tier"])
	var nshop: int = (first["shop_adds"] as Dictionary).size()
	var ncargo: int = (first["cargo_adds"] as Dictionary).size()
	_ok(nshop > 100, "A: shop_adds keys counted off the file (%d)" % nshop)
	_ok(ncargo > 50, "A: cargo_adds keys counted off the file (%d)" % ncargo)
	for kind in first:
		for k in (first[kind] as Dictionary):
			var t: int = first[kind][k]
			_ok(Economy.stock_first_tier(k, kind) == t, "A: %s %s first tier %d" % [kind, k, t])
			if t > 1:
				_ok(not Economy.stock_open(k, t - 1, kind), "A: %s %s shut at tier %d" % [kind, k, t - 1])
			_ok(Economy.stock_open(k, t, kind), "A: %s %s open at tier %d" % [kind, k, t])
	_ok(Economy.stock_open("no_such_key_d99", 1), "A: an unlisted key is not gated by stock_by_tier")

	var ss: Dictionary = it.get("shop_stock", {})
	var landed_total := 0
	var early := 0
	for tier in range(1, 13):
		for k in ss:
			if not (ss[k] is Dictionary):
				continue
			var goods: Array = []
			SnapshotPublisher._shelf_add(goods, ss[k], 1, tier, 12, String(k))
			if goods.size() > 0:
				landed_total += 1
				var ft := Economy.stock_first_tier(String(k))
				if ft > tier:
					early += 1
					_ok(false, "B: %s on a tier-%d shelf, stock_by_tier says %d" % [k, tier, ft])
	_ok(early == 0, "B: no good on a shelf before its stock_by_tier tier (%d early)" % early)
	_ok(landed_total > 500, "B: goods do land on shelves across 12 tiers (%d placements)" % landed_total)
	var g1: Array = []
	SnapshotPublisher._shelf_add(g1, ss.get("glass_goblets", {"tier": 12, "name": "x"}), 1, 1, 12, "glass_goblets")
	_ok(g1.is_empty(), "B: a crossing does not sell glass")

	_ok(Economy.never_stocked({"rarity": "artifact", "tier": 1, "name": "x"}), "E: an artifact is never stocked")
	var ga: Array = []
	SnapshotPublisher._shelf_add(ga, {"rarity": "artifact", "tier": 1, "name": "Scarforged test", "cost": 1}, 1, 12, 12, "d99_artifact")
	_ok(ga.is_empty(), "E: an artifact never reaches a shelf, even at tier 12")
	var arts := 0
	for src in ["shop_stock", "trader_cargo"]:
		for k in (it.get(src, {}) as Dictionary):
			var gv: Variant = (it.get(src, {}) as Dictionary)[k]
			if gv is Dictionary and String((gv as Dictionary).get("rarity", "")) == "artifact":
				arts += 1
	_ok(arts == 0, "E: the file stocks no artifact in shop_stock/trader_cargo (%d)" % arts)
	var _eq: Variant = it.get("equipment", {})
	var lf := Economy.ladder_faults()
	for f in lf:
		print("  LADDER FAULT ", f)
	var ladders: Dictionary = (it.get("price_ladders", {}) as Dictionary).get("ladders", {})
	_ok(ladders.size() >= 10, "C: price_ladders read (%d ladders)" % ladders.size())
	_ok(lf.is_empty(), "C: every ladder non-decreasing in cost and tier (%d faults)" % lf.size())

	var f := FileAccess.open("res://data/classes.json", FileAccess.READ)
	_ok(f != null, "D: classes.json opens")
	var hr: Dictionary = (JSON.parse_string(f.get_as_text()) as Dictionary).get("healing", {}) if f else {}
	var rules := Economy.healing_rules()
	_ok(bool(rules["from_file"]), "D: healing read from the file")
	_ok(is_equal_approx(float(rules["mend_interval_s"]), float(hr.get("mend_interval_s", -1))), "D: mend_interval_s %s == file %s" % [rules["mend_interval_s"], hr.get("mend_interval_s")])
	var re := RegEx.new()
	re.compile("below (\\d+)%")
	var m := re.search(String(hr.get("quaff", "")))
	_ok(m != null and is_equal_approx(float(rules["quaff_below"]), float(m.get_string(1)) / 100.0), "D: quaff threshold %s from the file's sentence" % rules["quaff_below"])

	_ok(String(rules.get("self_mend", "")) == "binds their own wounds", "D: self-mend voice read from the file ('%s')" % rules.get("self_mend", ""))

	if _checks < 200:
		_fails.append("too few checks (%d) - a gate with no floor is not a gate" % _checks)
	if _fails.is_empty():
		print("D99_TEST OK (%d checks)" % _checks)
	else:
		print("D99_TEST FAIL (%d of %d) first: %s" % [_fails.size(), _checks, _fails[0]])
	quit(0 if _fails.is_empty() else 1)
