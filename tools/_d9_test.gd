extends SceneTree
## D9: the town's roll audit. Headless.
## A - Dice: a fair d20, 2d6 averages 7, a +2 check vs DC 10 lands ~65%.
## B - raid blows by the sheet: a watchman (+2, 2d6+4) vs AC 10 hits ~65% for ~11,
##     a 20 rolls the dice twice; a raider vs a rider's AC 13 hits ~50%.
## C - spells: the fire burst is a DEX save vs 8 + to-hit (a save halves it);
##     bolt / chain / frost / smite are spell attacks.
## D - a beat of work averages the old measure (1.0); fishing's hook is a DEX
##     check (a dock fisher ~80%, an untrained hero ~55%), a 20 marks the catch.
## E - a real raid in the real town: initiative in the Chronicle, the torch and
##     the CON saves rolled, the raid driven off, no SCRIPT ERROR.
var _t: Node3D
var _f := 0
var _bad: Array = []
var _raid_f := 0
var _feed0 := 0
var _phase := 0
var _rolled0 := 0

func _check(ok: bool, what: String) -> void:
    print(("ok   " if ok else "FAIL ") + what)
    if not ok:
        _bad.append(what)

func _near(x: float, want: float, tol: float) -> bool:
    return absf(x - want) <= tol

func _initialize() -> void:
    seed(9)

## the unit checks run on the first frame, once the root is in the tree
func _unit() -> void:
    # ---- A
    var faces := {}
    for i in range(20000):
        var d := Dice.d20()
        faces[d] = int(faces.get(d, 0)) + 1
    var fair := faces.size() == 20
    for k in faces:
        fair = fair and _near(float(faces[k]) / 20000.0, 0.05, 0.008)
    _check(fair, "d20 is fair (20 faces, each ~5%)")
    var s := 0
    for i in range(20000):
        s += Dice.roll(2, 6)
    _check(_near(float(s) / 20000.0, 7.0, 0.1), "2d6 averages 7 (%.2f)" % (float(s) / 20000.0))
    var ok := 0
    for i in range(20000):
        if Dice.check(2, 10)["ok"]:
            ok += 1
    _check(_near(float(ok) / 20000.0, 0.65, 0.02), "+2 vs DC 10 succeeds ~65%% (%.3f)" % (float(ok) / 20000.0))
    # ---- B
    var rd := Raids.new()
    root.add_child(rd)
    var guard := {"to_hit": 2, "dice": [2, 6], "dmod": 4}
    var hits := 0
    var sum := 0.0
    var crit_sum := 0.0
    var crits := 0
    for i in range(20000):
        var dmg: float = rd._strike(guard, 10)
        if dmg > 0.0:
            hits += 1
            if rd.last_nat == 20:
                crits += 1
                crit_sum += dmg
            else:
                sum += dmg
    _check(_near(float(hits) / 20000.0, 0.65, 0.02), "a watchman hits AC 10 ~65%% (%.3f)" % (float(hits) / 20000.0))
    _check(_near(sum / float(hits - crits), 11.0, 0.3), "a watchman's blow 2d6+4 ~11 (%.2f)" % (sum / float(hits - crits)))
    _check(_near(crit_sum / float(crits), 18.0, 0.8), "a 20 rolls the dice twice ~18 (%.2f)" % (crit_sum / float(crits)))
    var rh := 0
    for i in range(20000):
        if rd._strike({"to_hit": 2, "dice": [1, 6], "dmod": 2}, 13) > 0.0:
            rh += 1
    _check(_near(float(rh) / 20000.0, 0.50, 0.02), "a raider hits a rider (AC 13) ~50%% (%.3f)" % (float(rh) / 20000.0))
    # ---- C: ten raiders round a mark, a caster with +5 to hit (DC 13), raiders DEX +1
    var marks: Array = []
    for i in range(10):
        var n := Node3D.new()
        root.add_child(n)
        n.position = Vector3(float(i % 3) * 0.5, 0, float(i / 3) * 0.5)
        var r := {"node": n, "hp": 100000.0, "max": 100000.0, "ac": 12, "dex": 1, "name": "dummy", "kind": "bandit"}
        rd.raiders.append(r)
        marks.append(r)
    var caster := {"to_hit": 5, "dmod": 3, "flat": 0.0}
    for i in range(300):
        rd._spell_lands("fire", [marks[0]], Vector3.ZERO, caster, "Test")
    var fs: Array = rd.fire_saves
    var sv := float(fs[0]) / float(fs[0] + fs[1])
    _check(fs[0] + fs[1] == 3000, "every raider in the burst saves (%d)" % (fs[0] + fs[1]))
    _check(_near(sv, 0.45, 0.04), "DEX +1 vs DC 13 saves ~45%% (%.3f)" % sv)
    var hp0 := float(marks[0]["hp"])
    var bolt_hits := 0
    for i in range(2000):
        var before := float(marks[0]["hp"])
        rd._spell_lands("bolt", [marks[0]], Vector3.ZERO, caster, "Test")
        if float(marks[0]["hp"]) < before:
            bolt_hits += 1
    _check(_near(float(bolt_hits) / 2000.0, 0.70, 0.04), "a bolt (+5 vs AC 12) hits ~70%% (%.3f)" % (float(bolt_hits) / 2000.0))
    var dealt := hp0 - float(marks[0]["hp"])
    _check(_near(dealt / float(bolt_hits), 8.5 * 1.04, 0.8), "a bolt deals 1d10+3 (%.2f a hit)" % (dealt / float(bolt_hits)))
    # the tower crossbows: +3, 1d10+3, rolled when the bolt lands
    var bh0 := int(rd.arrows_hit)
    for i in range(2000):
        rd._bolt_lands(marks[1], "Test")
    _check(_near(float(int(rd.arrows_hit) - bh0) / 2000.0, 0.60, 0.04), "a tower bolt (+3 vs AC 12) hits ~60%% (%.3f)" % (float(int(rd.arrows_hit) - bh0) / 2000.0))
    rd.raiders.clear()
    # ---- D
    var ec := Economy.new()
    var ksum := 0.0
    for i in range(40000):
        ksum += ec.work_roll()
    var wr: Array = ec.work_rolls
    _check(_near(ksum / 40000.0, 1.0, 0.02), "a beat of work averages the old measure (%.3f)" % (ksum / 40000.0))
    _check(int(wr[0]) > 0 and int(wr[3]) > 0, "work rolls 1s and 20s (%s)" % str(wr))
    ec.free()
    var rng := RandomNumberGenerator.new()
    rng.seed = 9
    var c5 := 0
    var c0 := 0
    var strikes20 := 0
    for i in range(10000):
        var a := Fishing.cast_result(rng, 0, 0, Fishing.DOCK_HAND)
        if a["caught"]:
            c5 += 1
            if int(a["item"].get("strike", 0)) == 20:
                strikes20 += 1
        if Fishing.cast_result(rng, 0, 0, 0)["caught"]:
            c0 += 1
    _check(_near(float(c5) / 10000.0, 0.80, 0.02), "a dock fisher (+5) strikes ~80%% (%.3f)" % (float(c5) / 10000.0))
    _check(_near(float(c0) / 10000.0, 0.55, 0.02), "an untrained hero (+0) strikes ~55%% (%.3f)" % (float(c0) / 10000.0))
    _check(_near(float(strikes20) / 10000.0, 0.05, 0.01), "a 20 on the strike is marked (%d)" % strikes20)
    for m in marks:
        (m["node"] as Node).queue_free()

func _process(_d: float) -> bool:
    _f += 1
    if _t == null:
        _unit()
        # ---- E
        _t = (load("res://Town.tscn") as PackedScene).instantiate()
        root.add_child(_t)
        _f = 0
        return false
    if _f == 3:
        _t.get("raids").set("_raid_t", 99999.0)
    if _f < 30:
        return false
    var raids = _t.get("raids")
    var feed: Array = _t.get("feed")
    if _phase == 0:
        _phase = 1
        _t.call("show_level", 5, true)
        Engine.time_scale = 4.0
        raids.set("force_level", 5)
        _feed0 = feed.size()
        _rolled0 = Dice.rolled
        raids.call("raid", "west")
        return false
    _raid_f += 1
    var rs: Array = raids.get("raiders")
    if not rs.is_empty() and _raid_f < 7000:
        return false
    Engine.time_scale = 1.0
    var lines: Array = []
    for i in range(_feed0, feed.size()):
        lines.append(String(feed[i]))
    var init := 0
    var saves := 0
    for l in lines:
        print("NEWS ", l)
        if l.begins_with("Initiative:"):
            init += 1
        if l.contains("save") or l.contains("comes round"):
            saves += 1
    var tc: Array = raids.get("torches")
    print("RAID over after ", _raid_f, " frames; raiders left ", rs.size(), "; torches ", tc, "; bolts ", raids.get("arrows_loosed"),
          " hits ", raids.get("arrows_hit"), "; d20s rolled ", Dice.rolled)
    _check(init == 1, "initiative is rolled and told")
    _check(rs.is_empty(), "the raid is driven off")
    _check(Dice.rolled > _rolled0, "the raid is fought by the dice (%d d20s)" % (Dice.rolled - _rolled0))
    if _bad.is_empty():
        print("D9_TEST OK")
    else:
        print("D9_TEST FAIL ", _bad.size())
    return true
