extends SceneTree
## D64a TEST - a shop's level decides what it sells (economy.gd). Headless, asserted:
## the rarity ranks sit over the unchanged ladders, the smithy has a level that IS the
## counter's ceiling (Roster.town_tier), a level 1 smithy REFUSES a rarer tier while a
## richer hero stands at the counter and the Chronicle says so once, raise_shop (D66's
## entry point) lifts the ceiling and the same hero then buys, and growth still grants
## the smithy its level. Prints D64_TEST OK/FAIL.
class StubTown extends Node3D:
	var feed: Array = []
	var people: Array = []
	var roster: Roster
	var tiers_shown := -1
	var shop_shown := -1
	func show_tiers(t: int, lv := 0) -> void:
		tiers_shown = t
		shop_shown = lv

var _checks := 0
var _fails: Array = []

func _ok(c: bool, what: String) -> void:
	_checks += 1
	if not c:
		_fails.append(what)
	print("  %s %s" % ["ok  " if c else "FAIL", what])

func _initialize() -> void:
	print("D64_TEST start")
	var eco := Economy.new()
	var stub := StubTown.new()
	var r := Roster.new()
	stub.roster = r
	eco.town = stub
	var feed: Array = stub.feed

	# .1 the ladder is named and ranked; values untouched
	_ok(Economy.rarity_of(0) == "none" and Economy.rarity_of(1) == "common" and Economy.rarity_of(4) == "very rare", "ranks: none/common/../very rare")
	_ok(Economy.rarity_of(5) == "legendary" and bool(Roster.WEAPONS[5].get("found", false)) and bool(Roster.ARMOUR[5].get("found", false)), "legendary = the found-only tier on both ladders")
	_ok(int(Roster.WEAPONS[1]["cost"]) == 60 and int(Roster.WEAPONS[4]["atk"]) == 26 and int(Roster.ARMOUR[4]["ac"]) == 7, "ladder values unchanged")

	# .2 the smithy has a level, and it caps the counter
	eco.shop_grown["smithy"] = 1
	eco._apply_shop_caps()
	_ok(eco.shop_level() == 1 and Roster.town_tier == 1, "level 1 smithy -> counter ceiling 1 (town_tier %d)" % Roster.town_tier)
	_ok(stub.tiers_shown == 1 and stub.shop_shown == 1, "the rack is told the ceiling and the shop level")
	_ok(eco.shop_sells_to() == "common", "a level 1 smithy sells common")

	var h := r.fresh("u1", "Aldric", "knight")
	h["weapon"] = 1
	h["gold"] = 5000
	var before_gold := int(h["gold"])
	var said := r.buy_weapon("u1")
	print("    counter: ", said)
	_ok(int(h["weapon"]) == 1 and int(h["gold"]) == before_gold, "level 1 smithy REFUSES uncommon to a hero holding 5000 gold")
	eco._counter_watch()
	var line := String(feed.back()) if not feed.is_empty() else ""
	print("    chronicle: ", line)
	_ok(eco.counter_refusals == 1 and line.contains("level 1 smithy") and line.contains("Aldric"), "the Chronicle says so plainly")
	var n := feed.size()
	eco._counter_watch()
	_ok(feed.size() == n and eco.counter_refusals == 1, "said once per hero per shop level, not every day")

	# a poorer hero is not a 'refusal' - the cap is not what stops them
	var p := r.fresh("u2", "Brannoc", "knight")
	p["weapon"] = 1
	p["gold"] = 10
	eco._counter_watch()
	_ok(eco.counter_refusals == 1, "a hero without the gold is not counted as refused by the cap")

	# D66 entry point: viewers raise the ceiling
	var gained := eco.raise_shop("smithy", 1, "MrE")
	print("    raise: ", feed.back())
	_ok(gained == 1 and eco.shop_level() == 2 and Roster.town_tier == 2, "raise_shop lifts the smithy to 2 and the counter follows")
	_ok(String(feed.back()).contains("uncommon") and String(feed.back()).contains("MrE"), "the raise is cried, crediting who paid")
	said = r.buy_weapon("u1")
	print("    counter: ", said)
	_ok(int(h["weapon"]) == 2 and int(h["gold"]) < before_gold, "the same hero now buys uncommon")
	eco.raise_shop("smithy", 9, "MrE")
	_ok(eco.shop_level() == Economy.SHOP_MAX_LEVEL and Roster.town_tier == 4, "never past what a smith can make (very rare)")
	_ok(eco.raise_shop("smithy", 1, "MrE") == 0, "a raise at the top gains nothing")
	_ok(eco.raise_shop("nowhere", 1) == 0, "an unknown shop cannot be raised")

	# growth still grants the smithy its level (today's curve, unchanged)
	eco.shop_raised["smithy"] = 0
	eco.shop_grown["smithy"] = Roster.tier_for_town(3)
	eco._apply_shop_caps()
	_ok(eco.shop_level() == 3 and Roster.town_tier == 3, "growth: town level 3 grants a level 3 smithy")

	Roster.town_tier = 4
	r.free()
	stub.free()
	eco.free()
	print("D64_TEST %s (%d checks, %d fail)" % ["OK" if _fails.is_empty() else "FAIL", _checks, _fails.size()])
	for f in _fails:
		print("   FAILED: ", f)
	quit(0 if _fails.is_empty() else 1)
