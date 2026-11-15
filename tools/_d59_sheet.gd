extends SceneTree
## D59 - the H20 character sheet in the snapshot (v=4). Offline, no key file, no network:
## build_payload() on a fake town and check what the hub's hero sheet reads.
##  - v is PAYLOAD_V (3 until web/app.js KNOWN_V takes "4"); every v=3 field (Satchel) and v=2 field still there
##  - EVERY hero, a freshly rolled one included: stats (6), max_hp, xp_next, ac, hp, to_hit,
##    prof, saves, initiative (the delve's d20 + DEX bonus), speed (Roster.speed)
##  - gear keyed main_hand/body/hands/feet/cloak/neck/ring/head with ONLY real slots: no
##    empty strings, no off_hand (the game names none), bare hands = no main_hand
##  - status "in town" off-delve; last_seen + newest-first events when a hero changes;
##    heroes present at the first scan are seeded silently (no invented past)
##  - every string W1a clean, names <= 25; event lines <= 90; no Twitch ids
##  - 202 heroes with full event rings: size stated, under the W1a 400 KB bar
## Prints D59_SHEET OK.

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

func _find(p: Dictionary, nm: String) -> Dictionary:
    for s: Dictionary in p["heroes"]:
        if String(s["name"]) == nm:
            return s
    return {}

func _run() -> void:
    var town := FakeTown.new()
    root.add_child(town)
    town.roster = Roster.new()
    town.economy = Economy.new()
    town.economy.town = town
    var r := town.roster
    r.fresh("8101", "D59Veteran", "knight", "dwarf")
    var v: Dictionary = r.heroes["8101"]
    v["weapon"] = 3
    v["armour"] = 2
    v["level"] = 6
    v["owned"] = ["nightwatch_ring", "hearth_amulet"]
    v["acc"] = {"ring": "nightwatch_ring", "amulet": "hearth_amulet"}

    var pub := SnapshotPublisher.new()
    pub.key_file = "user://_d59_no_such_file.json"
    pub.mem_file = "user://_d59_mem.json"
    root.add_child(pub)
    pub.setup(town)
    _check("0 off without a key file (no network in this test)", not pub.enabled)

    var p := pub.build_payload()
    _check("1 payload v = PAYLOAD_V (3 until the hub KNOWN_V takes 4), never below 3", int(p["v"]) == SnapshotPublisher.PAYLOAD_V and int(p["v"]) >= 3)
    var vet := _find(p, "D59Veteran")
    var keys := ["stats", "max_hp", "xp_next", "ac", "hp", "to_hit", "prof", "saves", "initiative", "speed", "gear", "status", "events"]
    _check("2 veteran carries every v4 sheet field", vet.has_all(keys))
    _check("3 veteran seeded silently: no events, no last_seen yet", (vet["events"] as Array).is_empty() and not vet.has("last_seen"))
    var g: Dictionary = vet["gear"]
    print("veteran gear: ", g, "  init ", vet["initiative"], "  speed ", vet["speed"], "  status ", vet["status"])
    _check("4 veteran gear: main_hand, body, ring, neck real; no off_hand; no empty string",
        g.has_all(["main_hand", "body", "ring", "neck"]) and not g.has("off_hand") and not g.has("hands")
        and not g.values().has("") and String(g["ring"]) == "Ring of the Night Watch")
    _check("5 initiative = the delve's DEX bonus", int(vet["initiative"]) == r.mod(v, "dex"))
    _check("6 speed = Roster.speed", absf(float(vet["speed"]) - r.speed(v)) < 0.06)
    _check("7 status in town", String(vet["status"]) == "in town")

    # a freshly rolled hero AFTER the first scan: full sheet, an enlist event, last_seen
    r.fresh("8102", "D59Fresh", "mage", "elf")
    var p2 := pub.build_payload()
    var fr := _find(p2, "D59Fresh")
    print("fresh: stats ", fr.get("stats"), " gear ", fr.get("gear"), " events ", fr.get("events"))
    _check("8 fresh hero carries every v4 sheet field", fr.has_all(keys) and (fr["stats"] as Dictionary).size() == 6)
    _check("9 fresh hero: bare hands = no main_hand; body = rags", not (fr["gear"] as Dictionary).has("main_hand") and String(fr["gear"]["body"]) == "rags")
    _check("10 fresh hero: enlist event + last_seen", (fr["events"] as Array).size() == 1 and String(fr["events"][0]["t"]) == "enlist" and fr.has("last_seen"))

    # the veteran does things: level, deepest, a delve home, new armour, a find
    v["level"] = 7
    v["deepest"] = 5
    v["delves"] = 1
    v["kills"] = 4
    v["armour"] = 3
    v["owned"].append("ferryman_ring")
    var p3 := pub.build_payload()
    var vet3 := _find(p3, "D59Veteran")
    var ev: Array = vet3["events"]
    for e in ev:
        print("   event ", e)
    var kinds := ev.map(func(e): return String(e["t"]))
    _check("11 veteran: level, depth, delve, gear, find events", kinds.has("level") and kinds.has("depth") and kinds.has("delve") and kinds.has("gear") and kinds.has("find"))
    _check("12 veteran last_seen set (ISO)", vet3.has("last_seen") and String(vet3["last_seen"]).ends_with("Z"))
    # cap: many changes -> at most EVENT_MAX, newest first
    for i in 10:
        v["level"] = 8 + i
        pub.build_payload()
    var ev4: Array = _find(pub.build_payload(), "D59Veteran")["events"]
    _check("13 events capped at %d, newest first" % SnapshotPublisher.EVENT_MAX,
        ev4.size() == SnapshotPublisher.EVENT_MAX and String(ev4[0]["s"]) == "Reached level 17.")

    # W1a on everything new: a hostile item name
    var ctl := RegEx.new()
    ctl.compile("[\\x00-\\x1F\\x7F<>]")
    var clean := true
    var px := pub.build_payload()
    for s: Dictionary in px["heroes"]:
        for gv in (s["gear"] as Dictionary).values():
            if ctl.search(String(gv)) != null or String(gv).length() > SnapshotPublisher.NAME_MAX:
                clean = false
        for e: Dictionary in s["events"]:
            if ctl.search(String(e["s"])) != null or String(e["s"]).length() > SnapshotPublisher.EVENT_LINE or e.keys().size() != 3:
                clean = false
    _check("14 gear names and event lines W1a clean and capped", clean)

    # additive: v3 Satchel + v2 sheet still there
    _check("15 v3 Satchel fields still there", vet3.has_all(["satchel", "satchel_total", "sellable", "sell_prices"]))
    _check("16 v2 sheet + blocks untouched", vet3.has_all(["name", "class", "level", "weapon", "armour", "potions", "brews", "oil", "gold", "worn", "rank", "standing", "title"])
        and p3.has_all(["town", "guild_roll", "fallen", "heroes", "commands", "parties", "chronicle"]))

    # memory survives a restart: save, a new publisher loads it, last_seen + events carried
    pub.save_mem()
    var pub2 := SnapshotPublisher.new()
    pub2.key_file = "user://_d59_no_such_file.json"
    pub2.mem_file = "user://_d59_mem.json"
    root.add_child(pub2)
    pub2.setup(town)
    pub2._load_mem()            # setup only loads with a key; the test loads by hand
    var vr := _find(pub2.build_payload(), "D59Veteran")
    _check("17 restart keeps last_seen and events, no spurious new ones", vr.has("last_seen") and (vr["events"] as Array).size() == SnapshotPublisher.EVENT_MAX
        and String(vr["events"][0]["s"]) == "Reached level 17.")

    # size: 202 heroes, every one with a full ring
    for i in 200:
        r.fresh("x%d" % i, "Bulk%d" % i)
    pub.build_payload()
    for k in 7:
        for i in 200:
            r.heroes["x%d" % i]["level"] = 2 + k
        pub.build_payload()
    var big := JSON.stringify(pub.build_payload())
    print("D59 size 202 heroes, full event rings: %d bytes (%.1f KB), build %.2f ms" % [big.length(), big.length() / 1024.0, pub.last_build_ms])
    _check("18 202 heroes under the W1a 400 KB bar", big.length() < 400000)
    _check("19 no Twitch ids, no id key", big.find("8101") < 0 and big.find("8102") < 0 and big.find("\"id\"") < 0)
    var small := JSON.stringify(p3)
    print("D59 size 2 heroes: %d bytes" % small.length())
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://_d59_mem.json"))

    if _fails == 0:
        print("D59_SHEET OK")
    else:
        print("D59_SHEET FAILED (%d)" % _fails)
    quit(0 if _fails == 0 else 1)
