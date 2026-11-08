class_name Fishing
extends RefCounted
## Fishing rules, Minecraft-style, with no scene dependency so it can be
## driven by chat, an NPC, or a headless test.
##
## A cast waits a random time for a bite (shorter with LURE), the bite is open
## for a short window, and a landed catch rolls a CATEGORY first - fish, junk
## or treasure - then an item by weight inside it. LUCK moves weight out of
## junk and into treasure. A small share of fish come up scar-touched: one
## rarity higher, worth triple, glowing (lore: the river runs past the scar).

const RARITY_COLOR := {"common": Color(0.92, 0.92, 0.90), "uncommon": Color(0.45, 0.95, 0.45),
    "rare": Color(0.40, 0.65, 1.00), "epic": Color(0.80, 0.45, 1.00), "legendary": Color(1.00, 0.66, 0.20)}

static var _t: Dictionary = {}

static func table() -> Dictionary:
    if _t.is_empty():
        var f := FileAccess.open("res://data/fishing.json", FileAccess.READ)
        if f:
            var parsed: Variant = JSON.parse_string(f.get_as_text())
            if parsed is Dictionary:
                _t = parsed
    return _t

static func bite_wait(rng: RandomNumberGenerator, lure: int = 0) -> float:
    var b: Array = table().get("bite_seconds", [5.0, 30.0])
    var per: float = float(table().get("lure_seconds_per_level", 5.0))
    return maxf(rng.randf_range(float(b[0]), float(b[1])) - per * float(lure), 1.5)

static func bite_window() -> float:
    return float(table().get("bite_window", 1.1))

static func category_weights(luck: int) -> Dictionary:
    var c: Dictionary = (table().get("categories", {}) as Dictionary).duplicate()
    var per: Dictionary = table().get("luck_per_level", {})
    for k in per:
        c[k] = maxf(float(c.get(k, 0.0)) + float(per[k]) * float(luck), 0.5)
    return c

static func _pick(rng: RandomNumberGenerator, weights: Dictionary) -> String:
    var total := 0.0
    for k in weights:
        total += float(weights[k])
    var r := rng.randf() * total
    for k in weights:
        r -= float(weights[k])
        if r <= 0.0:
            return String(k)
    return String(weights.keys()[0])

## One landed catch. Returns a copy of the item, plus "note" for bottles and
## "scar" for scar-touched fish.
static func roll(rng: RandomNumberGenerator, luck: int = 0) -> Dictionary:
    var cat := _pick(rng, category_weights(luck))
    var w := {}
    var by_id := {}
    for item in table().get("items", []):
        var d: Dictionary = item
        if String(d["cat"]) == cat:
            w[d["id"]] = float(d["weight"])
            by_id[d["id"]] = d
    var got: Dictionary = (by_id[_pick(rng, w)] as Dictionary).duplicate(true)
    if cat == "fish" and rng.randf() < float(table().get("scar_touched_chance", 0.03)):
        var tiers: Array = table().get("rarities", [])
        var i := tiers.find(got["rarity"])
        got["rarity"] = tiers[mini(i + 1, tiers.size() - 1)]
        got["name"] = "Scar-touched " + String(got["name"])
        got["value"] = int(got["value"]) * 3
        got["glow"] = true
        got["scar"] = true
    if String(got["id"]) == "sealed_bottle":
        var notes: Array = table().get("bottle_notes", [])
        if not notes.is_empty():
            got["note"] = notes[rng.randi() % notes.size()]
    return got

static func colour(item: Dictionary) -> Color:
    return RARITY_COLOR.get(item.get("rarity", "common"), Color.WHITE)

## A whole cast resolved at once, for chat (!fish) or offline ticks: did the
## fisher react inside the bite window, and what came up.
static func cast_result(rng: RandomNumberGenerator, luck: int = 0, lure: int = 0, skill: float = 0.8) -> Dictionary:
    var wait := bite_wait(rng, lure)
    if rng.randf() > skill:
        return {"wait": wait, "caught": false}
    return {"wait": wait, "caught": true, "item": roll(rng, luck)}
