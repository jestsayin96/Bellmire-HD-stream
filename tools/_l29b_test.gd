extends SceneTree
## L29b: RARE UNIQUES - "NOT new lords - modified variants, bosses.json lesser/greater/draw/rule:
## rare spawn, visible modifier, better loot. DONE: a unique rolls + drops in a soak."
##
## MEASURED BEFORE BUILDING, as every item this session has needed, and it moved the item again:
## bestiary.gd ALREADY had a UNIQUES table - but those are the L2 FLOOR-uniques (Gnawbone, Mother
## Silk), brand new named things that hold an ORDINARY floor. They are not what L29b asks for.
## What did not exist is the thing the supervisor pointed at: the content writer has WRITTEN the
## lord variants in data/bosses.json and not one line of code read that file. So the data is now
## READ, not copied, and no parallel table was invented next to it.
##   A. THE DATA IS READ, NOT COPIED: every written variant loads, every one belongs to one of
##      the EIGHT canon lords, and none is orphaned by a name the code cannot match.
##   B. THE SPAWN RULE: rare - not never and not always; drawn only from the variants of the lord
##      that was actually drawn; never the same one twice running.
##   C. THE VISIBLE MODIFIER IS REAL: a unique differs from its own plain lord in name, in the
##      note that prints when it rises, in SIZE and in colour - measured, not asserted. And it is
##      still a LORD: same body, same mechanic, same depth curve.
##   D. BETTER LOOT, read out of the same function the Chronicle pays from.
##   E. THE SOAK the DONE line asks for: a real Delve, a real floor, a real fight - a unique
##      rises and gold is actually awarded for it.
## Prints L29B_TEST OK / FAIL.
var _fails: Array = []
var _checks := 0

func _ok(c: bool, what: String) -> void:
    _checks += 1
    print("  %s %s" % ["ok  " if c else "FAIL", what])
    if not c:
        _fails.append(what)

# The soak (E) runs on real frames, so the whole test lives in _process. L29a's lesson: a node
# added during _initialize NEVER enters the tree, so _ready never fires and the object looks
# broken when the harness is the thing at fault.
var _f := 0
var _phase := 0
var _d: Delve
var _r: Roster
var _saw_name := ""
var _saw_floor := 0

func _process(_dt: float) -> bool:
    _f += 1
    if _phase == 0:
        if _f < 20:
            return false
        _data_checks()
        _start_soak()
        _phase = 1
        return false
    # E: watch the soak for a unique rising, and for the gold it drops
    if _d.dun and _d.dun.lord and _saw_name == "":
        if bool(_d.dun.lord.def.get("lord_unique", false)):
            _saw_name = String(_d.dun.lord.def.get("name", ""))
            _saw_floor = _d.floor_no
            print("L29b soak: %s rose on floor %d" % [_saw_name, _saw_floor])
    if _d.state == "home" or _f > 60 * 240:
        _soak_checks()
        return true
    return false

func _raw(lord_id: String) -> Dictionary:
    var b: Dictionary = (Bestiary.BOSS_DEFS[lord_id] as Dictionary).duplicate(true)
    b["id"] = lord_id
    return b

## the same lord, on the same floor, with and without the written variant
func _lord_pair(lord_id: String, uq_name: String, floor_no: int) -> Array:
    Bestiary.only_lord_unique = ""
    var plain: Dictionary = Bestiary.boss_def(_raw(lord_id), floor_no)
    Bestiary.only_lord_unique = uq_name
    var raw := _raw(lord_id)
    var v := Bestiary.lord_unique_for(lord_id, 0.0)
    Bestiary.only_lord_unique = ""
    if v.is_empty():
        return [plain, plain]        # the pinned name was not found: C will fail loudly
    raw["uniq"] = v
    return [plain, Bestiary.boss_def(raw, floor_no)]

func _data_checks() -> void:
    # ---- A. the data is READ, and nothing in it is quietly dropped
    var by_lord := Bestiary.lord_uniques()
    var total := 0
    var lords_without: Array = []
    for k in Bestiary.BOSS_DEFS:
        var n: int = (by_lord.get(String(k), []) as Array).size()
        total += n
        if n == 0:
            lords_without.append(String(k))
    var orphans: Array = Bestiary.uniq_orphans()
    print("L29b: %d written variants loaded across %d lords; %d orphaned" % [total, by_lord.size(), orphans.size()])
    _ok(total > 0, "A: the written variants LOAD from data/bosses.json (%d)" % total)
    _ok(orphans.is_empty(), "A: no written variant is orphaned by a name the code cannot match (%s)" % str(orphans))
    _ok(lords_without.is_empty(), "A: EVERY canon lord has variants written for it (without: %s)" % str(lords_without))
    _ok(by_lord.size() == Bestiary.BOSS_DEFS.size(), "A: variants file under the EIGHT lords and nothing else (%d)" % by_lord.size())

    # ---- B. the spawn rule: rare, and it does happen
    var drew := 0
    var tries := 4000
    for i in tries:
        if not Bestiary.lord_unique_for("hollow_king", randf()).is_empty():
            drew += 1
    var rate := float(drew) / float(tries)
    print("L29b: drew a unique on %.1f%% of rolls (the chance is %.1f%%)" % [rate * 100.0, Bestiary.LORD_UNIQUE_CHANCE * 100.0])
    _ok(absf(rate - Bestiary.LORD_UNIQUE_CHANCE) < 0.03, "B: it is RARE and it does happen (%.3f vs %.3f)" % [rate, Bestiary.LORD_UNIQUE_CHANCE])
    _ok(Bestiary.lord_unique_for("hollow_king", 0.99).is_empty(), "B: a high roll draws nothing - a plain lord rises")

    # a variant drawn for a lord is always a variant OF THAT LORD
    var wrong: Array = []
    for k in Bestiary.BOSS_DEFS:
        var title := String((Bestiary.BOSS_DEFS[k] as Dictionary)["title"])
        for i in 60:
            var v := Bestiary.lord_unique_for(String(k), 0.0)
            if not v.is_empty() and not String(v.get("name", "")).begins_with(title):
                wrong.append("%s -> %s" % [k, v.get("name", "")])
    _ok(wrong.is_empty(), "B: a lord only ever draws a version of ITSELF, never another lord (%s)" % str(wrong))

    # never the same one twice running
    var repeats := 0
    var prev := ""
    for i in 400:
        var v2 := Bestiary.lord_unique_for("pale_duchess", 0.0)
        var nm := String(v2.get("name", ""))
        if nm != "" and nm == prev:
            repeats += 1
        prev = nm
    _ok(repeats == 0, "B: never the same rare one twice running (%d repeats in 400)" % repeats)

    # ---- C. the visible modifier, and that it is still a lord
    var fat_pair := _lord_pair("grubmother", "The Grubmother, Winter-Fat", 10)
    var plain: Dictionary = fat_pair[0]
    var fat: Dictionary = fat_pair[1]
    var lean_pair := _lord_pair("nightwing", "Nightwing, the Famished", 10)
    var lean_plain: Dictionary = lean_pair[0]
    var lean: Dictionary = lean_pair[1]
    print("L29b: Grubmother h %.2f -> %.2f (Winter-Fat); Nightwing h %.2f -> %.2f (Famished)"
        % [float(plain["h"]), float(fat["h"]), float(lean_plain["h"]), float(lean["h"])])
    _ok(String(fat["name"]) != String(plain["name"]), "C: it is NAMED as the version it is (%s)" % fat["name"])
    _ok(String(fat["note"]) != String(plain["note"]) and String(fat["note"]) != "",
        "C: the note that prints when it rises is the writer's own shape line")
    _ok(float(fat["h"]) > float(plain["h"]), "C: a swollen one is VISIBLY bigger (%.2f > %.2f)" % [float(fat["h"]), float(plain["h"])])
    _ok(float(lean["h"]) < float(lean_plain["h"]), "C: a famished one is VISIBLY leaner (%.2f < %.2f)" % [float(lean["h"]), float(lean_plain["h"])])
    _ok((fat["tint"] as Color) != (plain["tint"] as Color) and (fat["aura"] as Color) != (plain["aura"] as Color),
        "C: every rare one takes a scar-light no plain lord has")
    _ok(bool(fat.get("rare", false)), "C: it is flagged rare, which the boss bar ALREADY reads - no UI file touched")
    _ok(String(fat.get("path", "")) == String(plain.get("path", "")), "C: it keeps its lord's BODY - a variant, never a new lord")
    _ok((fat["ways"] as Dictionary) == (plain["ways"] as Dictionary), "C: it keeps its lord's MECHANIC unchanged")
    _ok(int(fat["depth_step"]) == int(plain["depth_step"]), "C: it still takes the L45 depth curve")
    _ok(float(fat["boss_hp"]) != float(plain["boss_hp"]),
        "C: the writer's stat skew is applied (%d hp vs %d)" % [int(fat["boss_hp"]), int(plain["boss_hp"])])
    _ok(float(lean.get("spd", 0.0)) > 0.0, "C: a speed skew reaches the def the mover reads (spd %.1f)" % float(lean.get("spd", 0.0)))

    # ---- D. better loot, out of the function the Chronicle pays from
    var m_none := Delve.boss_loot_mult(false, false, false)
    var m_floor := Delve.boss_loot_mult(true, true, false)
    var m_lord := Delve.boss_loot_mult(true, false, false)
    var m_rare := Delve.boss_loot_mult(true, false, true)
    print("L29b: loot multipliers - ordinary floor %.1f, floor-unique %.1f, lord %.1f, RARE LORD %.1f"
        % [m_none, m_floor, m_lord, m_rare])
    _ok(m_rare > m_lord, "D: a rare unique pays BETTER than the plain lord (%.1f > %.1f)" % [m_rare, m_lord])
    _ok(m_lord > m_floor and m_floor > m_none, "D: and the rest of the ladder still stands")

func _start_soak() -> void:
    # E: a real delve, with the draw pinned so the soak cannot simply get unlucky
    Bestiary.force_lord_unique = 0.0
    _r = Roster.new()
    root.add_child(_r)
    var V := [["2001", "SoakKnight", "knight"], ["2002", "SoakMage", "mage"],
              ["2003", "SoakCleric", "cleric"], ["2004", "SoakAxe", "barbarian"]]
    var ids: Array = []
    for v in V:
        var h: Dictionary = _r.fresh(v[0], v[1], v[2])
        h["weapon"] = 4
        h["armour"] = 4
        h["oil"] = 12
        ids.append(v[0])
    _d = Delve.new()
    _d.roster = _r
    # straight to a lord floor. The first run of this test crawled from floor 1 and ran out of
    # frames at floor 3, so it reported "no unique rose" when the soak had simply never reached
    # one - a harness miss that reads exactly like a product bug, which is the L29a lesson again.
    _d.start_floor = 5
    _d.max_floors = 6
    root.add_child(_d)
    _d.start(ids)

func _soak_checks() -> void:
    Bestiary.force_lord_unique = -1.0
    print("L29b soak: ended at floor %d, state %s, gold %d" % [_d.floor_no, _d.state, _d._gold])
    _ok(_saw_name != "", "E: a rare unique ROLLED and rose in a real soak (%s)" % _saw_name)
    _ok(_d._gold > 0, "E: and it DROPPED - gold was actually awarded in the soak (%d)" % _d._gold)
    print("CHECKS ", _checks, " FAILS ", _fails.size())
    for x in _fails:
        print("  - ", x)
    print("L29B_TEST ", "OK" if _fails.is_empty() else "FAIL")
    quit()
