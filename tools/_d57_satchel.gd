extends SceneTree
## D57 - the hub's Satchel (H11) in the snapshot. Offline, no key file, no network:
## build_payload() on a fake town and check the sell sheet the hub reads.
##  - v is 3 (web/app.js KNOWN_V accepts "1","2","3")
##  - per hero: `satchel` rows {name, kind, qty, sell}, `satchel_total`, and the same
##    rows as the parallel arrays `sellable` / `sell_prices`
##  - `sell` is PER UNIT and is the counter's own price: floor(cost * 0.4), the same
##    SELL_BACK the on-stream sheet pays (leaderboard_panel.gd), so they cannot disagree
##  - worn gear gets no row but is still in the stated total; a 0-cost tier is omitted
##  - every name is W1a clean and at most 25 characters
##  - additive: the v2 sheet fields are all still there, and it all survives JSON
## Prints D57_SATCHEL OK.

class FakeTown extends Node3D:
    var people: Array = []
    var roster: Roster
    var economy: Economy
    var feed: Array = []

var _fails := 0

func _check(name: String, ok: bool) -> void:
    print(("PASS " if ok else "FAIL ") + name)
    if not ok:
        _fails += 1

func _initialize() -> void:
    _run.call_deferred()

func _run() -> void:
    var town := FakeTown.new()
    root.add_child(town)
    town.roster = Roster.new()
    town.economy = Economy.new()
    town.economy.town = town
    var r := town.roster
    r.fresh("7101", "D57Packrat", "knight", "dwarf")
    r.fresh("7102", "D57Pauper", "mage", "elf")
    var h: Dictionary = r.heroes["7101"]
    h["potions"] = 2
    h["brews"] = {"greater": 3}
    h["oil"] = 5
    h["owned"] = ["nightwatch_ring", "hearth_amulet"]
    h["acc"] = {"ring": "nightwatch_ring"}          # worn: no row, but in the total
    h["weapon"] = 0
    h["armour"] = 0
    var poor: Dictionary = r.heroes["7102"]
    poor["potions"] = 0
    poor["brews"] = {}
    poor["oil"] = 0
    poor["owned"] = []
    poor["weapon"] = 0
    poor["armour"] = 0

    var pub := SnapshotPublisher.new()
    pub.key_file = "user://_d57_no_such_file.json"
    root.add_child(pub)
    pub.setup(town)
    _check("0 off without a key file (no network in this test)", not pub.enabled)

    var p := pub.build_payload()
    _check("1 payload v is 3", int(p["v"]) == 3)

    var rich := {}
    var lean := {}
    for s: Dictionary in p["heroes"]:
        if String(s["name"]) == "D57Packrat":
            rich = s
        elif String(s["name"]) == "D57Pauper":
            lean = s
    _check("2 both heroes published", not rich.is_empty() and not lean.is_empty())
    _check("3 sheet carries the D57 fields", rich.has_all(["satchel", "satchel_total", "sellable", "sell_prices"]))

    var rows: Array = rich["satchel"]
    var by := {}
    for row: Dictionary in rows:
        by[String(row["name"])] = row
    _check("4 four rows: mending, brew, oil, the spare amulet", rows.size() == 4)
    _check("5 mending x2 at 14 each (35 * 0.4)",
        by.has("Mending draught") and int(by["Mending draught"]["qty"]) == 2
        and int(by["Mending draught"]["sell"]) == 14 and String(by["Mending draught"]["kind"]) == "potion")
    _check("6 Greater Mending x3 at 36 each (90 * 0.4)",
        by.has("Greater Mending") and int(by["Greater Mending"]["qty"]) == 3 and int(by["Greater Mending"]["sell"]) == 36)
    _check("7 oil x5 at 4 each (12 * 0.4)",
        by.has("Flask of lamp oil") and int(by["Flask of lamp oil"]["qty"]) == 5
        and int(by["Flask of lamp oil"]["sell"]) == 4 and String(by["Flask of lamp oil"]["kind"]) == "oil")
    _check("8 the spare amulet is listed at 144 (360 * 0.4)",
        by.has("Hearthstone Amulet") and int(by["Hearthstone Amulet"]["sell"]) == 144)
    _check("9 the WORN ring gets no row of its own", not by.has("Ring of the Night Watch"))

    # 2*14 + 3*36 + 5*4 = 156 carried, + 152 + 144 for both owned rings (worn included)
    _check("10 stated total is the whole purse, worn too (452)", int(rich["satchel_total"]) == 452)

    _check("11 sellable / sell_prices mirror the rows",
        (rich["sellable"] as Array).size() == rows.size() and (rich["sell_prices"] as Array).size() == rows.size()
        and int((rich["sell_prices"] as Array)[0]) == int(rows[0]["sell"])
        and String(((rich["sellable"] as Array)[0] as Dictionary)["kind"]) == String(rows[0]["kind"]))

    var kinds := ["weapon", "armour", "potion", "oil", "gold", "trinket", "loot", "gem"]
    var kinds_ok := true
    var names_ok := true
    for row: Dictionary in rows:
        if not kinds.has(String(row["kind"])):
            kinds_ok = false
        var nm := String(row["name"])
        if nm.length() > 25 or nm.contains("<") or nm.contains(">") or nm.strip_edges() != nm:
            names_ok = false
    _check("12 every kind is one the hub's icon map knows", kinds_ok)
    _check("13 every name is W1a clean and <= 25 chars", names_ok)

    _check("14 bare hands / rags quote no price at all",
        not (rich["weapon"] as Dictionary).has("sell") and not (rich["armour"] as Dictionary).has("sell"))

    # a hero carrying nothing: an empty sheet, never an invented row
    _check("15 the pauper's satchel is empty and totals 0",
        (lean["satchel"] as Array).is_empty() and int(lean["satchel_total"]) == 0
        and (lean["sellable"] as Array).is_empty())

    # worn gear with a price does show up, and lands in the total
    h["weapon"] = 2                                  # fine steel, 160 -> 64
    h["armour"] = 2                                  # chainmail, 150 -> 60
    var p2 := pub.build_payload()
    var rich2 := {}
    for s: Dictionary in p2["heroes"]:
        if String(s["name"]) == "D57Packrat":
            rich2 = s
    _check("16 worn weapon and armour quote the counter's price",
        int((rich2["weapon"] as Dictionary).get("sell", 0)) == 64
        and int((rich2["armour"] as Dictionary).get("sell", 0)) == 60)
    _check("17 and both are in the stated total (452 + 124)", int(rich2["satchel_total"]) == 576)

    # additive: nothing the v2 hub reads has gone away
    _check("18 the v2 sheet is untouched",
        rich2.has_all(["name", "class", "level", "stats", "saves", "ac", "hp", "max_hp", "to_hit",
            "weapon", "armour", "potions", "brews", "oil", "gold", "worn", "rank", "standing", "title"])
        and String((rich2["weapon"] as Dictionary)["name"]) != ""
        and String((rich2["armour"] as Dictionary)["name"]) != "")
    _check("19 payload still has every v2 block", p2.has_all(["town", "guild_roll", "fallen", "heroes", "commands", "parties", "chronicle"]))

    var txt := JSON.stringify(p2)
    var back: Variant = JSON.parse_string(txt)
    _check("20 plain JSON, round-trips", typeof(back) == TYPE_DICTIONARY)
    _check("21 no Twitch ids leaked", txt.find("7101") < 0 and txt.find("7102") < 0)
    print("payload bytes: %d   build ms: %.2f" % [txt.length(), pub.last_build_ms])
    _check("22 payload well under the size cap (1 MB)", txt.length() < 1000000)

    if _fails == 0:
        print("D57_SATCHEL OK")
    else:
        print("D57_SATCHEL FAILED (%d)" % _fails)
    quit(0 if _fails == 0 else 1)
