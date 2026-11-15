extends SceneTree
## D59 helper: one real build_payload() with a kitted veteran who has DONE things (events,
## last_seen, worn accessories, a hat) and a freshly rolled hero, written to
## user://_d59_payload.json so the hub page can be rendered against exactly what the
## publisher sends. Offline, no key, no network, the game's own files untouched.

class FakeTown extends Node3D:
    var people: Array = []
    var roster: Roster
    var economy: Economy
    var feed: Array = []

func _initialize() -> void:
    _run.call_deferred()

func _run() -> void:
    var town := FakeTown.new()
    root.add_child(town)
    town.roster = Roster.new()
    town.economy = Economy.new()
    town.economy.town = town
    var r := town.roster
    r.fresh("7201", "Brannoc", "knight", "dwarf")
    var h: Dictionary = r.heroes["7201"]
    h["weapon"] = 2
    h["armour"] = 2
    h["level"] = 5
    h["xp"] = 900
    h["potions"] = 2
    h["owned"] = ["nightwatch_ring", "hearth_amulet"]
    h["acc"] = {"ring": "nightwatch_ring", "amulet": "hearth_amulet"}
    var pub := SnapshotPublisher.new()
    pub.key_file = "user://_d59_no_such_file.json"
    pub.mem_file = "user://_d59_dump_mem.json"
    root.add_child(pub)
    pub.setup(town)
    pub.build_payload()                 # first scan: Brannoc seeded silently
    r.fresh("7202", "Isolde", "mage", "elf")
    h["level"] = 6
    h["deepest"] = 4
    h["delves"] = 3
    h["kills"] = 11
    h["armour"] = 3
    var p := pub.build_payload()
    var f := FileAccess.open("user://_d59_payload.json", FileAccess.WRITE)
    f.store_string(JSON.stringify(p))
    f.close()
    print("D59_DUMP ", ProjectSettings.globalize_path("user://_d59_payload.json"), " ", JSON.stringify(p).length(), " bytes")
    quit(0)
