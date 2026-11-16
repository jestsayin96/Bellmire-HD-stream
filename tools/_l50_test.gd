extends SceneTree
## L50: MONSTER DIVERSITY - "more variety in what appears, and at what depth", DONE being "a
## depth census showing a wide spread, not three repeats".
## MEASURED BEFORE CHANGING ANYTHING, because L46, L49, L52 and L55 all turned out to be
## something other than their reported symptom. The roster is already wide (L27a widened the
## deep bands), so if a floor still reads as three repeats the fault is in the DISTRIBUTION,
## not the number of monsters that exist.
## This reproduces dungeon_hd's own spawn loop exactly - pick per point, then pack expansion -
## so the census measures what a floor really gets rather than what the table could give.
##   A. THE CENSUS ITSELF (the DONE criterion): distinct types per floor, and what share of a
##      floor the single commonest type takes.
##   B. THE BAND is wide at every depth - the table is not the limit.
##   C. NO FLOOR IS THREE REPEATS: a typical floor shows several types and no one type owns it.
## Prints L50_TEST OK / FAIL.
var _fails: Array = []
var _checks := 0
var _rng := RandomNumberGenerator.new()

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

## dungeon_hd._populate in miniature: points are filled by picking a type, and a pack creature
## fills several of them at once from that ONE pick.
func _floor_census(floor_no: int, theme: String, count: int) -> Dictionary:
	var tally := {}
	var placed := 0
	var guard := 0
	while placed < count and guard < 500:
		guard += 1
		var d := Bestiary.pick(floor_no, theme)
		var t := String(d.get("type", "?"))
		var pack := int((d.get("ways", {}) as Dictionary).get("pack", 0))
		# mirrors dungeon_hd's pack cap - a pack cannot own more than ~a third of a floor
		var pack_cap := maxi(1, int(round(float(count) * 0.34)))
		var n := 1 + mini(mini(pack, pack_cap - 1), count - placed - 1)
		tally[t] = int(tally.get(t, 0)) + n
		placed += n
	return tally

func _top_share(tally: Dictionary, total: int) -> float:
	var top := 0
	for k in tally:
		top = maxi(top, int(tally[k]))
	return float(top) / maxf(1.0, float(total))

func _initialize() -> void:
	_rng.randomize()
	# the depths sampled, by BAND rather than by naming how deep the dungeon goes
	var depths := [1, 3, 5, 6, 8, 10, 14]
	var themes := ["", "crypt", "mire", "forge"]
	var per_floor := 10

	print("L50 DEPTH CENSUS - %d floors sampled per depth, %d creatures a floor" % [40, per_floor])
	print("   depth | band | mean distinct types a floor | commonest type's share | types ever seen")
	var worst_distinct := 99.0
	var worst_share := 0.0
	var narrow_band: Array = []

	for depth in depths:
		var band := Bestiary.pool(depth).size()
		var sum_distinct := 0.0
		var sum_share := 0.0
		var seen := {}
		var runs := 40
		for r in runs:
			var theme := String(themes[r % themes.size()])
			var tally := _floor_census(depth, theme, per_floor)
			sum_distinct += float(tally.size())
			sum_share += _top_share(tally, per_floor)
			for k in tally:
				seen[k] = true
		var mean_distinct := sum_distinct / float(runs)
		var mean_share := sum_share / float(runs)
		worst_distinct = minf(worst_distinct, mean_distinct)
		worst_share = maxf(worst_share, mean_share)
		if band < 5:
			narrow_band.append(depth)
		print("   %5d | %4d | %27.1f | %21.0f%% | %d"
			% [depth, band, mean_distinct, mean_share * 100.0, seen.size()])

	# ---- B. the table is wide at every depth
	_ok(narrow_band.is_empty(), "B: every depth band offers at least 5 kinds (narrow: %s)" % str(narrow_band))

	# ---- C. a floor is not three repeats
	print("L50: worst depth averages %.1f distinct types a floor; commonest type takes up to %.0f%%"
		% [worst_distinct, worst_share * 100.0])
	_ok(worst_distinct >= 4.0,
		"C: even the least varied depth averages 4+ distinct types a floor (%.1f) - not three repeats" % worst_distinct)
	_ok(worst_share <= 0.5,
		"C: no single type owns more than half a floor (worst %.0f%%)" % [worst_share * 100.0])

	# ---- A. depth actually CHANGES what appears, which is the other half of "and at what depth"
	var shallow := {}
	var deep := {}
	for r in 60:
		for k in _floor_census(1, "", per_floor):
			shallow[k] = true
		for k in _floor_census(14, "", per_floor):
			deep[k] = true
	var only_deep: Array = []
	for k in deep:
		if not shallow.has(k):
			only_deep.append(k)
	var only_shallow: Array = []
	for k in shallow:
		if not deep.has(k):
			only_shallow.append(k)
	print("L50 A: shallow shows %d kinds, deep shows %d; %d appear ONLY deep, %d only shallow"
		% [shallow.size(), deep.size(), only_deep.size(), only_shallow.size()])
	_ok(only_deep.size() >= 3, "A: depth brings things the shallows never show (%d: %s)" % [only_deep.size(), str(only_deep).substr(0, 90)])
	_ok(only_shallow.size() >= 1, "A: the shallows keep something of their own (%d)" % only_shallow.size())

	print("CHECKS ", _checks, " FAILS ", _fails.size())
	for x in _fails:
		print("  - ", x)
	print("L50_TEST ", "OK" if _fails.is_empty() else "FAIL")
	quit()
