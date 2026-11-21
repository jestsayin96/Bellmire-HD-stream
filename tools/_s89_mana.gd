extends SceneTree
## S89 - Mr. E's 10:17 directive, item 1, option A: mana left the game view and must ARRIVE on the
## hub's character sheet. web/app.js manaBar(h) reads h.mana / h.mana_max and draws nothing unless
## mana_max > 0. Offline, no key file, no network: build_payload() on a fake town.
##  - a caster publishes mana_max > 0 = Roster.mana_max, and a never-cast hero publishes a FULL pool
##  - a spent pool publishes what is left (clamped), not the max
##  - a non-caster publishes 0 / 0 (the hub's documented "no bar")
##  - the publisher does NOT write mana keys into a hero that never had them (read, never store)
## Prints S89_MANA OK or S89_MANA FAIL n.

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
    r.fresh("8901", "S89Mage", "mage", "elf")
    r.fresh("8902", "S89Spent", "cleric", "human")
    r.fresh("8903", "S89Knight", "knight", "dwarf")
    var spent: Dictionary = r.heroes["8902"]
    var smx := r.mana_max(spent)
    spent["mana"] = smx * 0.4
    var mage: Dictionary = r.heroes["8901"]
    var had_key := mage.has("mana")

    var pub := SnapshotPublisher.new()
    pub.key_file = "user://_s89_no_such_file.json"
    pub.mem_file = "user://_s89_mem.json"
    root.add_child(pub)
    pub.setup(town)
    _check("0 off without a key file (no network in this test)", not pub.enabled)
    var p := pub.build_payload()
    var m := _find(p, "S89Mage")
    var c := _find(p, "S89Spent")
    var k := _find(p, "S89Knight")
    print("mage ", m.get("mana"), "/", m.get("mana_max"), "  cleric ", c.get("mana"), "/", c.get("mana_max"), "  knight ", k.get("mana"), "/", k.get("mana_max"))
    _check("1 every row carries mana and mana_max", m.has_all(["mana", "mana_max"]) and c.has_all(["mana", "mana_max"]) and k.has_all(["mana", "mana_max"]))
    _check("2 caster mana_max > 0 and = Roster.mana_max", int(m["mana_max"]) > 0 and int(m["mana_max"]) == int(round(r.mana_max(mage))))
    _check("3 never-cast caster publishes a full pool", int(m["mana"]) == int(m["mana_max"]))
    _check("4 spent pool publishes what is left, below the max", int(c["mana"]) == int(floor(smx * 0.4)) and int(c["mana"]) < int(c["mana_max"]))
    _check("5 non-caster publishes 0 / 0 (hub draws no bar)", int(k["mana"]) == 0 and int(k["mana_max"]) == 0)
    _check("6 publisher stored nothing into the hero dict", mage.has("mana") == had_key)
    print("S89_MANA OK" if _fails == 0 else "S89_MANA FAIL %d" % _fails)
    quit()
