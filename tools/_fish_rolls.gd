extends SceneTree
func _initialize() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 42
    for luck in [0, 3]:
        var cats := {}
        var rar := {}
        var scar := 0
        var gold := 0
        for i in range(20000):
            var it: Dictionary = Fishing.roll(rng, luck)
            cats[it["cat"]] = int(cats.get(it["cat"], 0)) + 1
            rar[it["rarity"]] = int(rar.get(it["rarity"], 0)) + 1
            if it.has("scar"):
                scar += 1
            gold += int(it["value"])
        print("LUCK ", luck, " cats=", cats, " rarity=", rar, " scar=", scar, " avg_gold=", float(gold) / 20000.0)
    var waits := 0.0
    for i in range(1000):
        waits += Fishing.bite_wait(rng, 0)
    print("WAIT avg=", waits / 1000.0, " lure3=", Fishing.bite_wait(rng, 3))
    var b: Dictionary = {}
    while not b.has("note"):
        b = Fishing.roll(rng, 5)
    print("BOTTLE ", b["name"], ": ", b["note"])
    quit()
