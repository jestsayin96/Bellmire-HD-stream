extends SceneTree
## S171 gate for scripts/town_tiers.gd (the bellmire-town/2 reader). Pure data, quits itself.
##   <godot> --headless --path . --script res://tools/_s171_tiers.gd
## Prints ONE verdict line: S171_TIERS OK|FAIL <detail>. Red arms are real: a missing pool,
## a tier-1 crier, a level that steps backwards, or a hall with no words all FAIL.
const TT := preload("res://scripts/town_tiers.gd")

func _init() -> void:
    var tt = TT.new()
    var fails: Array = []
    if not tt.setup():
        print("S171_TIERS FAIL setup: town_buildings or bellmire.json did not load")
        quit(1)
        return
    if tt.tier_levels != [1, 5, 9]:
        print("S171_TIERS note: tier_levels now ", tt.tier_levels)
    var hall := {}
    for e in tt.layout.get("buildings", []):
        if String(e.get("landmark", "")) == "lm_hall":
            hall = e
    if hall.is_empty():
        fails.append("no lm_hall in layout")
    else:
        for t in [1, 2, 3]:
            if String(tt.tier_words(hall, t).get("name", "")) == "":
                fails.append("hall tier %d has no name" % t)
    var total := 0
    var cried := 0
    for L in range(1, 12):
        var ch: Array = tt.changes(L, L + 1)
        total += ch.size()
        for c in ch:
            if int(c["tier"]) <= 1 and String(c["crier"]) != "" and c["kind"] in ["building", "site"]:
                fails.append("tier-1 crier on %s" % c["id"])
            if String(c["crier"]) != "":
                cried += 1
        if tt.changes(L + 1, L).size() != 0:
            fails.append("changes(%d,%d) not empty going down" % [L + 1, L])
    var house := {"id": "x", "shape": "a", "district": "homes_s", "level": 7}
    if tt.tier_of(house, 6) != 0 or tt.tier_of(house, 7) != 2 or tt.tier_of(house, 9) != 3:
        fails.append("level-7 house clock wrong")
    var early := {"id": "y", "shape": "a", "district": "market", "level": 1, "tier_at": [null, 3, 6]}
    if tt.tier_of(early, 3) != 2 or tt.tier_of(early, 6) != 3:
        fails.append("tier_at override wrong")
    if tt.mesh_for(hall, 3) == "" and FileAccess.file_exists("res://assets/buildings/town_hall_t1.glb.import"):
        fails.append("town_hall_t* present but mesh_for found none")
    # S172: town.gd's crier puts landmarks first by the row's `landmark` field - it must be there
    var hall_row := false
    for c in tt.changes(4, 5):
        if c["kind"] == "building" and String(c.get("landmark", "")) == "lm_hall":
            hall_row = true
    if not hall_row:
        fails.append("changes(4,5) has no building row carrying landmark lm_hall")
    if total == 0:
        fails.append("no changes at all across levels 1..12")
    if fails.is_empty():
        print("S171_TIERS OK changes=%d cried=%d hall_mesh=%s" % [total, cried, tt.mesh_for(hall, 3)])
    else:
        print("S171_TIERS FAIL ", "; ".join(fails))
    quit(0 if fails.is_empty() else 1)
