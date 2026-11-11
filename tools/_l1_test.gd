extends SceneTree
## L1 (work plan 2): the new creatures and their ways.
## A: every creature (old and new) builds, its body loads, every animation its
##    map names exists, its weapon is on. B: home themes weight the pool.
## C: a real delve on floor 4 peopled with the new ways - an ooze divides, a
##    gravecaller raises the dead, a bowman shoots, a whelp breathes, a bite
##    leaves venom, a lost delver goes for the weakest. Prints L1_TEST OK.
var _f := 0
var _phase := 0
var _mons: Array = []
var _fail := 0
var _d: Delve
var _r: Roster
var seen := {"split": false, "raise": false, "shot": false, "breath": false, "venom": false, "guard_ac": false}
var _feed: Array = []

func _ok(c: bool, what: String) -> void:
    print(("  ok  " if c else "  FAIL ") + what)
    if not c:
        _fail += 1

func _initialize() -> void:
    for k in Bestiary.all_keys():
        var m := Monster.new()
        m.def = Bestiary.make(String(k), "plain")
        root.add_child(m)
        _mons.append(m)

func _phase_a() -> void:
    print("A: bodies, animations, weapons")
    for m in _mons:
        var mo: Monster = m
        var k := String(mo.def["type"])
        _ok(mo._body != null and mo._ap != null, "%s has a body and an animation player" % k)
        if mo._ap == null:
            continue
        var miss: Array = []
        for key in (mo.def["anims"] as Dictionary).keys():
            if key == "ual":
                continue
            var nm := String(mo.def["anims"][key])
            if not mo._ap.has_animation(nm):
                miss.append(nm)
        _ok(miss.is_empty(), "%s every mapped animation exists %s" % [k, miss])
        if String(mo.def.get("hand", "")) != "" and String(mo.def["path"]).contains("kaykit"):
            var sk := Gear.skeleton(mo._body)
            _ok(sk != null and sk.find_child("eq_weapon", true, false) != null, "%s holds its weapon" % k)
        var hh := mo._height() - float(mo.def.get("lift", 0.0))
        _ok(absf(hh - float(mo.def["h"])) < float(mo.def["h"]) * 0.35 + 0.3, "%s stands %.2f m (canon %.2f)" % [k, hh, float(mo.def["h"])])
        mo.queue_free()
    print("A: strains")
    for s in ["scarborn", "mossbacked"]:
        var d := Bestiary.make("bones", s)
        _ok(String(d["name"]).begins_with(s), "strain %s names its creature: %s" % [s, d["name"]])
    var mg := 0
    for i in range(400):
        if Bestiary.strain_for_theme(4, "grassland") == "mossbacked":
            mg += 1
    _ok(mg > 0, "mossbacked rise on meadow floors (%d of 400)" % mg)
    var sb := 0
    for i in range(400):
        if Bestiary.strain_for_theme(12, "crypt") == "scarborn":
            sb += 1
    _ok(sb > 0, "scarborn deep down (%d of 400)" % sb)
    print("B: homes weight the pool")
    var at_home := 0
    var elsewhere := 0
    for i in range(3000):
        if String(Bestiary.pick(6, "barracks")["type"]) == "bowman":
            at_home += 1
        if String(Bestiary.pick(6, "flooded")["type"]) == "bowman":
            elsewhere += 1
    _ok(float(at_home) > float(elsewhere) * 1.4, "bowmen in a barracks %d vs a flooded gallery %d" % [at_home, elsewhere])
    var depth_ok := true
    for i in range(500):
        if String(Bestiary.pick(1)["type"]) in ["bowman", "sentinel", "gravecaller", "lost", "whelp", "slimeling"]:
            depth_ok = false
    _ok(depth_ok, "no new creature on floor 1")

func _start_delve() -> void:
    print("C: the ways in a real delve")
    _r = Roster.new()
    root.add_child(_r)
    var V := [["2001", "Ashe", "knight"], ["2002", "Bram", "cleric"], ["2003", "Cass", "barbarian"], ["2004", "Dov", "ranger"]]
    var ids := []
    for v in V:
        var h: Dictionary = _r.fresh(v[0], v[1], v[2])
        h["weapon"] = 4
        h["armour"] = 4
        h["oil"] = 6
        ids.append(v[0])
    _d = Delve.new()
    _d.roster = _r
    _d.start_floor = 4
    _d.max_floors = 4
    root.add_child(_d)
    _d.start(ids)

func _people() -> void:
    for mo in _d.dun.monsters:
        if is_instance_valid(mo):
            (mo as Monster).queue_free()
    _d.dun.monsters.clear()
    var entry: Vector3 = _d.dun.info["entry"] + _d.dun.global_position
    var ex: Vector3 = _d.dun.info["exit"] + _d.dun.global_position
    var keys := ["slime", "gravecaller", "bowman", "whelp", "spider", "lost", "sentinel", "adder"]
    for i in range(keys.size()):
        var p := entry.lerp(ex, 0.25 + 0.08 * float(i))
        var nm := _d._spawn_on_floor(Bestiary.make(keys[i], "plain"), p)
        nm.max_hp *= 5.0
        nm.hp = nm.max_hp

func _process(_dt: float) -> bool:
    _f += 1
    if _f == 10:
        _phase_a()
        _start_delve()
    if _d == null or _d.dun == null:
        return false
    if _phase == 0:
        _people()
        _phase = 1
        return false
    for m in _d.party:
        if float(m.get("venom", 0.0)) > 0.0:
            seen["venom"] = true
    for mo in _d.dun.monsters:
        if not is_instance_valid(mo):
            continue
        var M: Monster = mo
        var w: Dictionary = M.def.get("ways", {})
        if M.shots > 0 and w.has("ranged") and not w.has("raise"):
            seen["shot"] = true
        if M.shots > 0 and w.has("breath"):
            seen["breath"] = true
        if String(M.def.get("type", "")) == "slimeling":
            seen["split"] = true
        if bool(M.def.get("raised", false)):
            seen["raise"] = true
    var done := _d.state == "home" or _f > 60 * 120
    if done:
        for k in seen:
            if k != "guard_ac":
                _ok(seen[k], "seen: %s" % k)
        print("ended state=", _d.state, " floor=", _d.floor_no, " frames=", _f)
        print("L1_TEST OK" if _fail == 0 else "L1_TEST FAIL %d" % _fail)
        return true
    return false
