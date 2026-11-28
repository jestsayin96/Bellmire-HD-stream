extends RefCounted
## S171: the READER for format "bellmire-town/2" (data/town/README.md) and content's
## lore_lines.json `town_buildings` pool (C-248/C-249/C-250). Pure data: no nodes, no meshes
## loaded here - it answers "which tier, which mesh path, which words" and "what changed between
## town level A and B", so town.gd/growth.gd can swap meshes and the crier can speak.
## No class_name on purpose (S171 was written while Godot could not run): use it as
##     const TownTiers := preload("res://scripts/town_tiers.gd")
##     var tt = TownTiers.new(); tt.setup()
## Every /2 field is optional; a /1 file reads exactly as /1 (tier 1 forever on the /1 mesh
## whenever no tiered family mesh exists).

const LORE := "res://data/lore_lines.json"
const LAYOUT := "res://data/town/bellmire.json"
const BUILDINGS := "res://assets/buildings/"
const TIERS := 3

var tb: Dictionary = {}               # lore_lines.json town_buildings
var layout: Dictionary = {}           # bellmire.json
var tier_levels := [1, 5, 9]          # fallback only; the data's tier_levels wins
var _mesh_ok: Dictionary = {}         # path -> bool (exists AND has an .import sibling)

func setup(lore_path: String = LORE, layout_path: String = LAYOUT) -> bool:
    var d = _read_json(lore_path)
    if d is Dictionary and (d as Dictionary).get("town_buildings") is Dictionary:
        tb = d["town_buildings"]
    var l = _read_json(layout_path)
    if l is Dictionary:
        layout = l
    var tl = tb.get("tier_levels", {})
    if tl is Dictionary:
        for t in range(1, TIERS + 1):
            if tl.has(str(t)):
                tier_levels[t - 1] = int(tl[str(t)])
    return not tb.is_empty() and not layout.is_empty()

static func _read_json(path: String):
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        return null
    return JSON.parse_string(f.get_as_text())

## ---- the tier clock ----
## The entry's tier at town level L: 0 if it does not stand yet, else 1..3.
func tier_of(e: Dictionary, lvl: int) -> int:
    var stands := int(e.get("level", 1))
    var clock: Array = tier_levels.duplicate()
    var ta = e.get("tier_at", null)
    if ta is Array:
        for i in range(mini((ta as Array).size(), TIERS)):
            if ta[i] != null:
                clock[i] = int(ta[i])
        if (ta as Array).size() >= 1 and ta[0] != null:
            stands = maxi(stands, int(ta[0]))
    if lvl < stands:
        return 0
    var t := 1                          # never below 1 once it stands (a level-7 house rises at 2)
    for i in range(1, TIERS):
        if lvl >= int(clock[i]):
            t = i + 1
    return t

## ---- families and meshes ----
func family_of(e: Dictionary, kind: String = "building") -> String:
    if String(e.get("family", "")) != "":
        return String(e["family"])
    var lm := String(e.get("landmark", ""))
    if lm != "":
        return lm.trim_prefix("lm_")
    if kind == "building":
        return "house_" + String(e.get("shape", "a"))
    return ""

func _has_mesh(path: String) -> bool:
    if not _mesh_ok.has(path):
        _mesh_ok[path] = FileAccess.file_exists(path + ".import") and ResourceLoader.exists(path)
    return bool(_mesh_ok[path])

## The mesh for this entry at tier t, with the README's fallback: highest existing tier <= t,
## else "" (the caller keeps the /1 mesh for `shape` at the /1 `off`).
func mesh_for(e: Dictionary, t: int, kind: String = "building") -> String:
    var fam := family_of(e, kind)
    if fam == "" or t <= 0:
        return ""
    for k in range(mini(t, TIERS), 0, -1):
        var p := BUILDINGS + "town_%s_t%d.glb" % [fam, k]
        if _has_mesh(p):
            return p
    return ""

## ---- words ----
func _node_at(path: String):
    var n = tb
    for part in path.split("."):
        if n is Dictionary and (n as Dictionary).has(part):
            n = n[part]
        else:
            return null
    return n

func words_of(e: Dictionary, kind: String = "building") -> Dictionary:
    var path := String(e.get("words", ""))
    if path == "":
        if kind == "site":
            path = "sites." + String(e.get("landmark", "")).trim_prefix("lm_")
        elif String(e.get("landmark", "")) != "":
            path = "landmarks." + family_of(e, kind)
        else:
            path = "districts." + String(e.get("district", ""))
    var n = _node_at(path)
    return n if n is Dictionary else {}

## {name, crier, plaque, see} for tier t, or {} if content has none.
func tier_words(e: Dictionary, t: int, kind: String = "building") -> Dictionary:
    var tiers = words_of(e, kind).get("tiers", [])
    if t >= 1 and tiers is Array and (tiers as Array).size() >= t and tiers[t - 1] is Dictionary:
        return tiers[t - 1]
    return {}

## ---- the square and the market: their own staged clocks ----
func stage_of(pool: String, lvl: int) -> Dictionary:
    var st = (tb.get(pool, {}) as Dictionary).get("stages", []) if tb.get(pool) is Dictionary else []
    var best: Dictionary = {}
    if st is Array:
        for s in st:
            if s is Dictionary and int(s.get("level", 1)) <= lvl:
                best = s
    return best

func stage_index(pool: String, lvl: int) -> int:
    var st = (tb.get(pool, {}) as Dictionary).get("stages", []) if tb.get(pool) is Dictionary else []
    var i := 0
    if st is Array:
        for s in st:
            if s is Dictionary and int(s.get("level", 1)) <= lvl:
                i += 1
    return i

## ---- what changed between two town levels ----
## Every entry (building, site, road network, centrepiece, market) whose tier or stage rose
## going from level a to level b. Each row: {kind, id, tier, name, crier, mesh} (+ landmark on
## building/site rows, "" for a plain house).
## A founding (tier 0 -> 1) is listed with crier "" - the README says tier 1 is never cried.
func changes(a: int, b: int) -> Array:
    var out: Array = []
    for kind in ["building", "site"]:
        var arr = layout.get(kind + "s", [])
        if not (arr is Array):
            continue
        for e in arr:
            if not (e is Dictionary):
                continue
            var ta := tier_of(e, a)
            var tbb := tier_of(e, b)
            if tbb > ta:
                var w := tier_words(e, tbb, kind)
                out.append({"kind": kind, "id": String(e.get("id", "")), "tier": tbb,
                    "landmark": String(e.get("landmark", "")),
                    "name": String(w.get("name", "")),
                    "crier": String(w.get("crier", "")) if ta >= 1 else "",
                    "mesh": mesh_for(e, tbb, kind)})
    # roads step town-wide on the clock unless a road carries tier_at
    var rt := _clock_tier(a)
    var rb := _clock_tier(b)
    if rb > rt and tb.get("roads") is Dictionary:
        var rw = (tb["roads"] as Dictionary).get("tiers", [])
        if rw is Array and (rw as Array).size() >= rb and rw[rb - 1] is Dictionary:
            out.append({"kind": "roads", "id": "roads", "tier": rb, "name": String(rw[rb - 1].get("name", "")),
                "crier": String(rw[rb - 1].get("crier", "")), "mesh": ""})
    for pool in ["well_to_fountain", "market_growth"]:
        var ia := stage_index(pool, a)
        var ib := stage_index(pool, b)
        if ib > ia and ia >= 1:
            var s := stage_of(pool, b)
            var mesh := ""
            if pool == "well_to_fountain":
                for k in range(ib, 0, -1):
                    if _has_mesh(BUILDINGS + "town_well_t%d.glb" % k):
                        mesh = BUILDINGS + "town_well_t%d.glb" % k
                        break
            out.append({"kind": pool, "id": pool, "tier": ib, "name": String(s.get("name", "")),
                "crier": String(s.get("crier", "")), "mesh": mesh})
    return out

func _clock_tier(lvl: int) -> int:
    var t := 0
    for i in range(TIERS):
        if lvl >= int(tier_levels[i]):
            t = i + 1
    return t
