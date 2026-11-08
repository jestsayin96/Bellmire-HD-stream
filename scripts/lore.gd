extends Node
## Autoload. Reads res://data/*.json ONCE at boot and exposes it.
## Game code must never re-parse these files.

var world: Dictionary = {}
var classes: Dictionary = {}
var bosses: Dictionary = {}
var strains: Dictionary = {}
var ranks: Dictionary = {}
var biomes: Dictionary = {}
var origins: Dictionary = {}

var _all: Dictionary = {}

func _ready() -> void:
    _load_all()

func _load_all() -> void:
    var dir := DirAccess.open("res://data")
    if dir == null:
        push_error("Lore: res://data missing")
        return
    for f in dir.get_files():
        if not f.ends_with(".json"):
            continue
        var txt := FileAccess.get_file_as_string("res://data/" + f)
        var parsed = JSON.parse_string(txt)
        if parsed == null:
            push_error("Lore: could not parse " + f)
            continue
        _all[f.get_basename()] = parsed
    world   = _all.get("world", {})
    classes = _all.get("classes", {})
    bosses  = _all.get("bosses", {})
    strains = _all.get("strains", {})
    ranks   = _all.get("ranks", {})
    biomes  = _all.get("biomes", {})
    origins = _all.get("origins", {})

func town_name() -> String:
    return world.get("town", {}).get("name", "Bellmire")

func districts() -> Array:
    return world.get("districts", [])

func rank_list() -> Array:
    return ranks.get("ranks", [])

## standing = deepest*6 + kills*2 + (level-1)*8. Gold is deliberately absent:
## gold buys gear, it does not buy rank.
func standing(deepest: int, kills: int, level: int) -> int:
    return deepest * 6 + kills * 2 + (level - 1) * 8

func rank_of(deepest: int, kills: int, level: int) -> String:
    var rl := rank_list()
    if rl.is_empty():
        return "Unproven"
    var s := standing(deepest, kills, level)
    var steps := [0, 12, 30, 60, 110, 180, 280]
    var idx := 0
    for i in range(min(steps.size(), rl.size())):
        if s >= int(steps[i]):
            idx = i
    return String(rl[idx])
