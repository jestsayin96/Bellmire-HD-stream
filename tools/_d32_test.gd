extends SceneTree
## D32 TEST - the town levelling curve (economy.gd). The town was founding at
## level 3 of 6 and auto-climbing to 5 on settlers alone. This asserts the new
## 12-tier ladder: 12 strictly-rising thresholds, founding (~score 153) lands at
## a HAMLET not a market town, the pop-driven ceiling (~315) stalls below the top
## so the upper tiers are RENOWN-gated, and every tier cries the content writer's
## line (data/lore_lines.json "growth_tiers"). Headless unit, numbers + strings.
class StubTown extends Node3D:
	var feed: Array = []
	var people: Array = []

var _c := 0
var _fails: Array = []
func _ok(c: bool, what: String) -> void:
	_c += 1
	if not c: _fails.append(what)
	print("  %s %s" % ["ok  " if c else "FAIL", what])

func _initialize() -> void:
	print("D32_TEST start")
	var eco := Economy.new()
	var stub := StubTown.new()
	eco.town = stub

	var lv := Economy.TOWN_LEVELS
	_ok(lv.size() == 12, "12 tiers (%d)" % lv.size())
	var rising := true
	for i in range(1, lv.size()):
		if int(lv[i]["at"]) <= int(lv[i-1]["at"]): rising = false
	_ok(rising, "thresholds strictly rising")
	_ok(int(lv[0]["at"]) == 0, "tier 1 at score 0")

	# founding score measured live earlier = 153 (pop 51, renown 0)
	_ok(eco.level_for(153) == 2, "founding score 153 -> HAMLET (tier 2), was market-town/3")
	_ok(eco.level_for(0) == 1, "score 0 -> tier 1")
	_ok(eco.level_for(119) == 1 and eco.level_for(120) == 2, "tier-2 boundary at 120")
	_ok(eco.level_for(1140) == 12 and eco.level_for(5000) == 12, "top tier at 1140, clamps")
	# the pop-driven ceiling (~pop_cap 105 *3 = 315, renown 0) must NOT reach the top
	_ok(eco.level_for(315) <= 5, "pop-only ceiling (315) stalls at tier %d - upper tiers need renown" % eco.level_for(315))
	_ok(eco.level_for(315) < 12, "a town cannot become a CITY on settlers alone")

	# every tier has a crier line from the content file
	var all_crier := true
	for t in range(1, 13):
		if eco._crier_for(t) == "": all_crier = false
	_ok(all_crier, "all 12 tiers have a content crier line")

	# founding cries tier-1's line into the feed
	eco.check_town_level(true)
	_ok(stub.feed.size() > 0 and String(stub.feed.back()) == eco._crier_for(1), "founding cries tier-1 line")

	# a big renown jump crosses many tiers and cries each
	stub.feed.clear()
	eco.renown = 600                       # score = 0*3 + 600*2 = 1200 -> tier 12
	var moved := eco.check_town_level()
	_ok(eco.town_level == 12, "renown 600 -> tier 12 (%d)" % eco.town_level)
	_ok(moved == 11, "climbed 11 tiers (tier 1 -> 12) in one check (%d)" % moved)
	var cried := 0
	for line in stub.feed:
		if String(line).length() > 0: cried += 1
	_ok(cried >= 9, "cried a line for the tiers crossed (%d lines)" % cried)
	_ok(eco.town_name == String(lv[11]["name"]), "town_name is the tier-12 grammatical form")

	if _fails.is_empty():
		print("D32_TEST OK (%d checks, 0 failed)" % _c)
	else:
		print("D32_TEST FAIL (%d checks, %d failed): %s" % [_c, _fails.size(), str(_fails)])
	quit()
