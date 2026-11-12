extends SceneTree
## S1: the town's sound wiring (desktop). Headless, real town.
##  1. STATIC: every kind the town side can ask for is a registered Sfx kind -
##     the Sfx.at/Sfx.play literals in townsfolk/spells/raids/town/daylight, the
##     spell sound table, the raiders' cries, the pens and the valley's air, and
##     every townsfolk voice for both sexes.
##  2. LIVE: ~80 real seconds of the town at 4x with a raid, every spell cast
##     once and a level-up: each wired event sounded, nothing played that is not
##     in Sfx.SETS, and the voices stay sampled (never a crowd grunting).
var _t: Node3D
var _f := 0
var _t0 := 0
var _fails: Array = []
var _raided := false
var _lv0 := 0
const RUN_MS := 80000
const FILES := ["townsfolk.gd", "spells.gd", "raids.gd", "town.gd", "daylight.gd", "notables.gd"]

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _check(ok: bool, what: String) -> void:
    print("S1_TEST %s %s" % ["pass" if ok else "FAIL", what])
    if not ok:
        _fails.append(what)

func _reg(k: String) -> bool:
    return Sfx.SETS.has(k)

func _static() -> void:
    var bad: Array = []
    # literals in the desktop files
    var re := RegEx.new()
    re.compile("Sfx\\.(at|play)\\(\"([a-z_0-9]+)\"")
    var lits := 0
    for f in FILES:
        var txt := FileAccess.get_file_as_string("res://scripts/" + f)
        for m in re.search_all(txt):
            lits += 1
            if not _reg(m.get_string(2)):
                bad.append(f + ":" + m.get_string(2))
    # the tables
    for k in Spells.SOUND.values():
        if not _reg(String(k)):
            bad.append("Spells.SOUND:" + String(k))
    for k in Daylight.PEN_VOICE.values() + Daylight.DAY_AIR + Daylight.NIGHT_AIR:
        if not _reg(String(k)):
            bad.append("Daylight:" + String(k))
    for s in ["male", "female"]:
        for v in ["_laugh", "_grunt", "_effort", "_attack_yell"]:
            if not _reg(s + v):
                bad.append("voice:" + s + v)
    var cries := {}
    for id in ["warrior", "cutpurse", "minion"]:
        var d: Dictionary = Bestiary.make(id)
        cries[String(d.get("name", id))] = Raids.cry_of({"name": d.get("name", id), "kind": "monster"})
    cries["a bandit"] = Raids.cry_of({"name": "a bandit", "kind": "bandit"})
    for nm in ["a goblin", "an orc brute", "the hill troll"]:
        cries[nm] = Raids.cry_of({"name": nm, "kind": "monster"})
    print("S1_TEST cries ", cries)
    for k in cries.values():
        if not _reg(String(k)):
            bad.append("cry:" + String(k))
    _check(cries["a goblin"] == "goblin_screech" and cries["an orc brute"] == "orc_roar" and cries["the hill troll"] == "troll_roar",
           "goblin/orc/troll raiders cry by kind")
    for k in ["level_up", "quest_complete", "sword_clash", "hit_impact", "mana_charge", "curse"]:
        if not _reg(k):
            bad.append("fixed:" + k)
    print("S1_TEST literals ", lits, " unregistered ", bad)
    _check(lits >= 8 and bad.is_empty(), "every wired kind is registered in Sfx.SETS")

func _process(_d: float) -> bool:
    _f += 1
    if _f == 3:
        _t.get("raids").set("_raid_t", 99999.0)
    if _f == 20:
        _static()
        Engine.time_scale = 4.0
        _t0 = Time.get_ticks_msec()
        # every spell once, from a townsperson
        var who: Node3D = null
        for p in _t.get("people"):
            if is_instance_valid(p) and p is Townsfolk and not (p as Townsfolk).inside:
                who = p
                break
        if who:
            for k in Spells.ORDER:
                Sfx.live()._last.clear()
                Spells.cast(k, who, who.global_position + Vector3(0, 0, 5), false)
            Spells.cast("bolt", who, who.global_position + Vector3(0, 0, 5), true)
        # a level-up
        _lv0 = int(_t.get("_sound_level"))
        _t.call("show_level", mini(_lv0 + 1, 6) if _lv0 < 6 else 6, false)
        if _lv0 >= 6:
            _t.set("_sound_level", 5)
            _t.call("show_level", 6, false)
        return false
    if _f < 20:
        return false
    var el := Time.get_ticks_msec() - _t0
    if not _raided and el > 15000:
        _raided = true
        var r: Node = _t.get("raids")
        r.set("force_level", 4)
        r.call("raid", "scar")
        r.call("raid", "road")
    if el < RUN_MS:
        return false
    var plays: Dictionary = Sfx.live().plays
    var unreg: Array = []
    for k in plays:
        if not _reg(String(k)):
            unreg.append(k)
    print("S1_TEST plays ", plays)
    print("S1_TEST voices ", Townsfolk.voices)
    var amb: Dictionary = _t.get("daylight").ambient_plays
    print("S1_TEST ambient ", amb)
    print("S1_TEST cries at raids ", _t.get("raids").arrival_cries)
    _check(unreg.is_empty(), "nothing played that is not registered (%s)" % str(unreg))
    for k in ["lightning", "fireball", "ice_shard", "heal", "buff", "shield", "summon", "mana_charge", "curse"]:
        _check(int(plays.get(k, 0)) >= 1, "spell sound " + k)
    _check(int(plays.get("level_up", 0)) >= 1 and int(plays.get("quest_complete", 0)) >= 1, "level_up + quest_complete on a new level")
    var cried := 0
    for k in ["skeleton_rattle", "male_attack_yell", "goblin_screech", "orc_roar", "troll_roar"]:
        cried += int(plays.get(k, 0))
    _check(cried >= 2, "raiders cry when they arrive (%d)" % cried)
    _check(int(plays.get("sword_clash", 0)) + int(plays.get("hit_impact", 0)) >= 1, "blows in the raid sound")
    var males := 0
    var females := 0
    var total := 0
    for k in Townsfolk.voices:
        var n := int(Townsfolk.voices[k])
        total += n
        if String(k).begins_with("male_"):
            males += n
        else:
            females += n
    var mins := float(RUN_MS) / 60000.0
    print("S1_TEST voices total %d (%.1f / min) male %d female %d" % [total, float(total) / mins, males, females])
    _check(total >= 3, "townsfolk speak now and then")
    _check(males >= 1 and females >= 1, "both men's and women's voices")
    _check(float(total) / mins <= 18.0, "voices sampled: at most one every 3.5 s")
    var asum := 0
    for k in amb:
        asum += int(amb[k])
    _check(asum >= 4 and float(asum) / mins <= 13.0, "valley ambience: quiet and occasional (%d)" % asum)
    print("S1_TEST OK" if _fails.is_empty() else "S1_TEST FAIL %s" % str(_fails))
    return true
