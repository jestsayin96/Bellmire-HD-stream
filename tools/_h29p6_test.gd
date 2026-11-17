extends SceneTree
## H29.6 - the publisher's shelves, caravan and orders (snapshot_pub.gd v5). Offline, no
## sockets. Real Economy, real Roster, real items.json. Asserts: payload v5 and KNOWN_V carries
## it; every shop open at a tier has a stock array; the smithy keeps its D64 level/sells_to and
## its shelf never lists a tier above its cap; a crossing (tier 1) has General Goods and the
## Smithy and nothing that opens later; tier 12 opens all five trades; retired goods leave;
## the caravan block reads a manifest; orders list only walking heroes; a hostile name is
## cleaned. Prints H29P6_TEST OK/FAIL.

class FakeBody extends Node3D:
	var errand := ""

class FakeTown extends Node3D:
	var feed: Array = []
	var roster: Roster
	var economy: Economy
	var _caravans: Array = []
	var shop_orders := {}
	var heroes := {}

var _checks := 0
## S12: measured 22 checks. Fewer is a FAIL by floor, never OK.
const MIN_CHECKS := 22
var _fails: Array = []

func _ok(c: bool, what: String) -> void:
	_checks += 1
	if not c:
		_fails.append(what)
	print("  %s %s" % ["ok  " if c else "FAIL", what])

func _names(shop: Dictionary) -> Array:
	var n: Array = []
	for g in (shop.get("stock", []) as Array):
		n.append(String(g["name"]))
	return n

func _initialize() -> void:
	print("H29P6_TEST start")
	var t := FakeTown.new()
	root.add_child(t)
	t.roster = Roster.new()
	t.add_child(t.roster)
	t.economy = Economy.new()
	t.economy.town = t
	var pub := SnapshotPublisher.new()
	pub.town = t
	var e := t.economy
	var app := FileAccess.get_file_as_string("res://web/app.js")
	_ok(SnapshotPublisher.PAYLOAD_V == 5 and app.contains('"5"'), "payload v5 and the hub's KNOWN_V carries \"5\"")

	# tier 1 - a crossing
	e.town_level = 1
	e.shop_grown["smithy"] = 1
	var sh: Array = pub._shelves(e)
	var names: Array = []
	for s in sh:
		names.append(String(s["name"]))
		_ok(s.has("stock") and s["stock"] is Array and s.has("level"), "tier 1: %s has level %s and a stock array (%d)" % [s["name"], str(s["level"]), (s["stock"] as Array).size()])
	print("    tier 1 shops: ", names)
	_ok(names.has("General Goods") and names.has("Smithy") and not names.has("Apothecary") and not names.has("Stables") and not names.has("Guild Counter"), "tier 1: General Goods + Smithy only")
	var smith: Dictionary = sh[names.find("Smithy")]
	print("    tier 1 smithy: ", _names(smith))
	_ok(int(smith["level"]) == 1 and String(smith["sells_to"]) == "common", "smithy keeps D64 level 1 / sells common")
	var only_common := true
	for g in smith["stock"]:
		if g.has("rarity") and String(g["rarity"]) != "common":
			only_common = false
	_ok(only_common and _names(smith).has("Plain steel") and _names(smith).has("Leather armour"), "a level 1 smithy shelves only common gear")
	var gen: Dictionary = sh[names.find("General Goods")]
	_ok(_names(gen).has("Bread") or _names(gen).size() > 5, "General Goods has a crossing's shelf (%d goods)" % _names(gen).size())
	_ok(not _names(gen).has("Sack of Grain"), "grain (tier 2) is not on a crossing's shelf")

	# tier 12 - everything open, retirements applied, smithy raised
	e.town_level = 12
	e.raise_shop("smithy", 3, "")
	sh = pub._shelves(e)
	names.clear()
	for s in sh:
		names.append(String(s["name"]))
	print("    tier 12 shops: ", names)
	_ok(names.size() == 5, "tier 12 opens all five trades")
	smith = sh[names.find("Smithy")]
	_ok(int(smith["level"]) == 4 and String(smith["sells_to"]) == "very rare" and _names(smith).has("Dragontooth steel"), "raised smithy: level 4, very rare, dragontooth on the shelf")
	var it := Economy.items_data()
	var cup := String(it["shop_stock"]["clay_cups"]["name"])
	var all12: Array = []
	for s in sh:
		all12 += _names(s)
		_ok((s["stock"] as Array).size() <= SnapshotPublisher.SHELF_MAX + 8, "%s shelf capped (%d)" % [s["name"], (s["stock"] as Array).size()])
	_ok(not all12.has(cup), "retired '%s' (last tier 6) is off every tier-12 shelf" % cup)

	# caravan
	_ok(not bool(pub._caravan_block()["present"]), "no caravan -> present false")
	var mid := String(it["caravan_manifests"]["caravans"][0]["id"])
	t._caravans.append({"phase": "trade", "t": 16.0, "manifest": mid})
	var cv: Dictionary = pub._caravan_block()
	print("    caravan: ", JSON.stringify(cv))
	_ok(bool(cv["present"]) and (cv["cargo"] as Array).size() > 0 and int(cv["leaves_in"]) == 1 and String(cv.get("name", "")) != "", "trading caravan -> present, named, cargo from its manifest, leaves in 1 min")
	t._caravans[0]["phase"] = "out"
	_ok(not bool(pub._caravan_block()["present"]), "a caravan on its way out is not 'in town'")

	# orders
	var h := t.roster.fresh("u9", "Aldric", "knight")
	var b := FakeBody.new()
	t.add_child(b)
	t.heroes["u9"] = b
	t.shop_orders["u9"] = {"item": "<img src=x onerror=alert(1)>", "shop": "Smithy"}
	_ok(pub._orders().is_empty(), "an order whose hero is not walking is not listed")
	b.errand = "blacksmith"
	var od: Array = pub._orders()
	print("    orders: ", JSON.stringify(od))
	_ok(od.size() == 1 and String(od[0]["who"]) == "Aldric" and String(od[0]["walker"]) == "Aldric" and not String(od[0]["item"]).contains("<"), "a walking order is listed, hostile item name cleaned")

	var blob := JSON.stringify({"shops": sh, "caravan": cv, "orders": od})
	print("    shelf blob bytes at tier 12: ", blob.length())
	_ok(blob.length() < 60000, "payload addition stays small (%d bytes)" % blob.length())

	# a mixed-level snapshot for the hub render: tier 5, smithy level 2, a caravan trading, one order
	e.town_level = 5
	e.shop_raised["smithy"] = 1
	t._caravans[0]["phase"] = "trade"
	var dump := {"v": SnapshotPublisher.PAYLOAD_V, "game": "Bellmire HD",
		"generated_at": Time.get_datetime_string_from_system(true) + "Z",
		"town": {"name": "a market-day town", "level": 5, "day": 3, "souls": 40, "treasury": 300, "renown": 20},
		"heroes": [], "guild_roll": [], "fallen": [], "parties": [], "chronicle": [], "rolls": [],
		"shops": pub._shelves(e), "caravan": pub._caravan_block(), "orders": pub._orders()}
	var f := FileAccess.open("res://renders/cycles/h29p6/payload.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(dump))
		f.close()
	if _checks < MIN_CHECKS:
		_fails.append("check floor: %d checks is under %d" % [_checks, MIN_CHECKS])
	print("H29P6_TEST %s %d checks%s" % ["OK" if _fails.is_empty() else "FAIL", _checks, "" if _fails.is_empty() else " " + str(_fails)])
	quit(0 if _fails.is_empty() else 1)
