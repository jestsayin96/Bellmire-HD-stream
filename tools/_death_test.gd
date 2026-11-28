extends SceneTree
## S161 gate: RULING sup-nov27-0209 death model, roster half. Prints DEATH_TEST OK n / FAIL.
var _fails := []
var _n := 0
func _ok(c: bool, what: String) -> void:
    _n += 1
    if not c:
        _fails.append(what)
func _initialize() -> void:
    var r := Roster.new()
    root.add_child(r)
    var h: Dictionary = r.fresh("9001", "Fallen", "knight")
    var o: Dictionary = r.fresh("9002", "Finder", "mage")
    h["weapon"] = 2; h["armour"] = 2; h["gold"] = 100; h["potions"] = 2; h["oil"] = 3
    h["delves_completed"] = 3
    var atk_full := r.attack(h)
    var ac_full := r.armour_class(h)
    var line := r.kill("9001", "the Gaoler", 4, 0)
    _ok(r.is_alive("9001"), "hero alive after fall")
    _ok(r.heroes.has("9001"), "hero kept in heroes")
    _ok(int(h["deaths"]) == 1, "deaths counter 1")
    _ok(int(h["dur_weapon"]) == 100 - 8 - 3 * 4, "weapon durability 80 got %s" % h.get("dur_weapon"))
    _ok(int(h["dur_armour"]) == 80, "armour durability 80")
    _ok(int(h["weapon"]) == 2 and int(h["armour"]) == 2, "gear stays equipped")
    _ok(int(h["gold"]) == 0 and int(h["potions"]) == 0 and int(h["oil"]) == 0, "carried dropped")
    _ok(r.bags.size() == 1 and int(r.bags[0]["gold"]) == 100, "one bag of 100g")
    _ok(r.fallen.size() == 1 and bool(r.fallen[0]["rose"]), "memorial row recorded")
    _ok(not line.contains("!reroll") and line.contains("wakes"), "line says wakes, no reroll: " + line)
    _ok(is_equal_approx(r.attack(h), atk_full), "80%% is full power")
    var b: Dictionary = r.bags[0]
    var t0 := int(b["t"])
    _ok(r.bag_state(b, "9002", t0 + 10) == "locked", "other locked inside hour")
    _ok(r.bag_state(b, "9001", t0 + 10) == "owner", "owner inside hour")
    var g0: Dictionary = r.take_bags("9002", 4, t0 + 10)
    _ok(int(g0["bags"]) == 0 and r.bags.size() == 1, "finder cannot take inside hour")
    _ok(int(r.take_bags("9002", 3, t0 + 4000)["bags"]) == 0, "wrong floor takes nothing")
    var g1: Dictionary = r.take_bags("9002", 4, t0 + 3601)
    _ok(int(g1["gold"]) == 100 and int(o["gold"]) == 140 and r.bags.size() == 0, "finders keepers after hour")
    # owner corpse run
    h["gold"] = 50
    r.kill("9001", "a rat", 1, 0)
    var g2: Dictionary = r.take_bags("9001", 1, int(r.bags[0]["t"]) + 5)
    _ok(int(g2["gold"]) == 50 and int(h["gold"]) == 50, "owner retrieves own bag")
    # expiry
    h["gold"] = 7
    r.kill("9001", "a rat", 2, 0)
    _ok(int(r.take_bags("9002", 2, int(r.bags[0]["t"]) + 7200)["bags"]) == 0 and r.bags.is_empty(), "bag gone at 2h")
    # threshold
    h["dur_weapon"] = 20; h["dur_armour"] = 20
    _ok(r.attack(h) < atk_full and r.armour_class(h) < ac_full, "degraded below 25")
    h["dur_weapon"] = 0
    _ok(r.weapon_dice(h) == [1, 4], "broken weapon = fist dice")
    # grace
    var n: Dictionary = r.fresh("9003", "Newbie", "cleric")
    r.kill("9003", "a rat", 9, 0)
    _ok(int(n.get("dur_weapon", 100)) == 100, "grace: no wear in first 3 delves")
    r.note_delve_done("9003")
    _ok(int(n["delves_completed"]) == 1, "delve counter")
    # leaderboard: no duplicate row for a risen hero
    var names := []
    for row in r.leaderboard("standing", 50):
        names.append(row["name"])
    _ok(names.count("Fallen") == 1, "leaderboard one row per risen hero, got %d" % names.count("Fallen"))
    # S162: the smithy's repair (economy.gd) - base * rarity_mult * (1 - dur/100)
    _ok(Economy.repair_list_cost({"weapon": 5, "dur_weapon": 0}, "weapon") == 600, "broken legendary lists 600")
    _ok(Economy.repair_list_cost({"weapon": 1, "dur_weapon": 50}, "weapon") == 20, "half-worn common lists 20")
    _ok(Economy.repair_list_cost({"weapon": 0, "dur_weapon": 0}, "weapon") == 0, "bare hands: nothing to mend")
    _ok(Economy.repair_list_cost({"armour": 3}, "armour") == 0, "missing durability = new, nothing to mend")
    var q: Dictionary = Economy.repair_quote(r, h)
    _ok(int(q["total"]) == r.cost_for(h, 80) + r.cost_for(h, 64), "quote is weapon 80 + armour 64 at guild rate, got %s" % str(q))
    h["gold"] = 0
    var rp0: Dictionary = Economy.repair(r, "9001")
    _ok(not bool(rp0["ok"]) and int(h["dur_weapon"]) == 0 and int(h["gold"]) == 0, "cannot pay: nothing taken, nothing mended")
    h["gold"] = 1000
    var rp1: Dictionary = Economy.repair(r, "9001")
    _ok(bool(rp1["ok"]) and int(h["dur_weapon"]) == 100 and int(h["dur_armour"]) == 100 and int(h["gold"]) == 1000 - int(q["total"]), "repair pays and restores 100: " + str(rp1))
    _ok(r.weapon_dice(h) != [1, 4] and is_equal_approx(r.attack(h), atk_full), "mended weapon back to full power")
    _ok(int(Economy.repair(r, "9001")["cost"]) == 0, "whole gear: second repair costs 0")
    # S162: the hub's skull markers (snapshot_pub.gd bags_block)
    r.bags.clear()          # the grace hero's floor-9 bag above is not this check's
    h["gold"] = 33
    r.kill("9001", "a rat", 3, 0)
    var bt := int(r.bags[0]["t"])
    var bb: Array = SnapshotPublisher.bags_block(r, bt + 10)
    _ok(bb.size() == 1 and int(bb[0]["floor"]) == 3 and int(bb[0]["gold"]) == 33 and not bool(bb[0]["open"]) and int(bb[0]["owner_left_s"]) == 3590, "bag marker inside hour: " + str(bb))
    _ok(not str(bb).contains("9001"), "marker never publishes the owner login")
    var bo: Array = SnapshotPublisher.bags_block(r, bt + 3700)
    _ok(bo.size() == 1 and bool(bo[0]["open"]) and int(bo[0]["owner_left_s"]) == 0, "marker open after hour")
    _ok(SnapshotPublisher.bags_block(r, bt + 7300).is_empty(), "marker gone after 2h")
    if _fails.is_empty():
        print("DEATH_TEST OK %d of %d" % [_n, _n])
    else:
        print("DEATH_TEST FAIL %d of %d: %s" % [_n - _fails.size(), _n, str(_fails)])
    quit()
