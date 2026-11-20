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

## THE THIRD RARITY TABLE, closed 18 Nov (team lead TAKE THIS NEXT 07:04 row 1, art's ruling in
## tools/art/icons.py above RARITY_HUE_LAMP). Art's RARITY_HUE is canonical (U55). This table is
## its SANCTIONED LAMP VARIANT - every channel +0.10, clamped to 1.0 - because two of its three
## readers are a light_color and an emission, which want the lifted value or they tint the water.
## common, junk and starting are BARE: no entry here, so the baseline does not spend the rung
## above it. uncommon is WHITE (the ladder's claim), not the MMO green it carried before.
## artifact is absent on purpose: fishing.json `rarities` stops at legendary and the scar bump
## clamps there, so it is unreachable. tools/_fish_rarity.gd guards all of this.
const RARITY_COLOR := {"uncommon": Color(1.00, 1.00, 1.00), "rare": Color(0.40, 0.65, 1.00),
    "very rare": Color(0.80, 0.45, 1.00), "legendary": Color(1.00, 0.65, 0.22)}
## what a bare rung draws with: the label's own ink and an untinted light - no hue, not a guess
const BARE := Color(1, 1, 1)

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

## true when this catch has earned a hue. JUNK never has, whatever rarity its row carries
## (fishing.json gives 7 junk rows a rarity - before this a boot came up blue).
static func has_hue(item: Dictionary) -> bool:
    if String(item.get("cat", "")) == "junk":
        return false
    return RARITY_COLOR.has(String(item.get("rarity", "common")).to_lower())

static func colour(item: Dictionary) -> Color:
    if not has_hue(item):
        return BARE
    return RARITY_COLOR[String(item.get("rarity", "common")).to_lower()]

## D9 (the DnD RULE): striking a bite is a DEX check - d20 + the fisher's bonus
## (DEX, + proficiency for those who know the river) vs HOOK_DC. A 1 snaps the
## line; a 20 is a perfect strike: the catch rolls with NAT20_LUCK more luck.
const HOOK_DC := 10
const NAT20_LUCK := 3
const DOCK_HAND := 5              # a dock fisher: DEX +2, proficient +3

static func hook(rng: RandomNumberGenerator, bonus: int) -> Dictionary:
    var d := rng.randi_range(1, 20)
    return {"d": d, "total": d + bonus, "ok": d == 20 or (d != 1 and d + bonus >= HOOK_DC)}

## A whole cast resolved at once, for chat (!fish) or offline ticks: did the
## fisher strike inside the bite window (the hook check), and what came up.
static func cast_result(rng: RandomNumberGenerator, luck: int = 0, lure: int = 0, hook_bonus: int = DOCK_HAND) -> Dictionary:
    var wait := bite_wait(rng, lure)
    var hk := hook(rng, hook_bonus)
    if not hk["ok"]:
        return {"wait": wait, "caught": false, "hook": hk}
    var item := roll(rng, luck + (NAT20_LUCK if int(hk["d"]) == 20 else 0))
    item["strike"] = int(hk["d"])
    return {"wait": wait, "caught": true, "item": item, "hook": hk}
