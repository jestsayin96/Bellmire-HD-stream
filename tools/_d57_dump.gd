extends SceneTree
## D57 helper: write one real build_payload() to user://_d57_payload.json so the hub
## page can be rendered against exactly what the publisher sends. Offline, no key.

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
    r.fresh("7101", "Brannoc", "knight", "dwarf")
    r.fresh("7102", "Isolde", "mage", "elf")
    var h: Dictionary = r.heroes["7101"]
    h["potions"] = 2
    h["brews"] = {"greater": 3}
    h["oil"] = 5
    h["owned"] = ["nightwatch_ring", "hearth_amulet"]
    h["acc"] = {"ring": "nightwatch_ring"}
    h["weapon"] = 2
    h["armour"] = 2
    h["gold"] = 143
    var pub := SnapshotPublisher.new()
    pub.key_file = "user://_d57_no_such_file.json"
    root.add_child(pub)
    pub.setup(town)
    var f := FileAccess.open("user://_d57_payload.json", FileAccess.WRITE)
    f.store_string(JSON.stringify(pub.build_payload()))
    f.close()
    print("D57_DUMP OK -> ", ProjectSettings.globalize_path("user://_d57_payload.json"))
    quit(0)
