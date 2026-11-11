extends SceneTree
## D3: the town level drives Bellmire's buildings (scripts/growth.gd).
## Headless. Walks levels 1..6 and back down, checks what stands at each.
var _t: Node3D
var _f := 0
var _bad: Array = []

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _check(ok: bool, what: String) -> void:
    if not ok:
        _bad.append(what)
        print("FAIL ", what)

func _process(_d: float) -> bool:
    _f += 1
    if _f == 3:
        _t.get("raids").set("_raid_t", 99999.0)
    if _f < 20:
        return false
    var g = _t.get("growth")
    _check(g != null, "growth exists")
    if g == null:
        print("D3_TEST FAIL")
        return true
    var last := -1
    var want := {1: [], 2: [], 3: ["market_hall"], 4: ["market_hall", "stables"],
        5: ["market_hall", "stables", "guild", "bathhouse"],
        6: ["market_hall", "stables", "guild", "bathhouse", "mage_tower"]}
    var feed: Array = _t.get("feed")
    var feed0 := feed.size()
    g.show_level(1, true)
    for lv in range(1, 7):
        g.show_level(lv)
        var s: Dictionary = g.stats()
        print("LEVEL ", lv, " built ", s["built"], "/", s["houses"], " specials ", s["specials"], " stone_wall ", s["stone_wall"])
        _check(int(s["built"]) > last, "more houses at level %d" % lv)
        last = int(s["built"])
        var sp: Array = s["specials"]
        sp.sort()
        var w: Array = (want[lv] as Array).duplicate()
        w.sort()
        _check(sp == w, "specials at level %d: %s" % [lv, str(sp)])
        # every house plot: visible exactly when built (special halls hide their house)
        for plot in g.houses:
            var h: Node3D = plot["node"]
            var shown: bool = h.visible
            var expect: bool = not plot.get("unbuilt", false)
            if plot.has("special") and String(plot["special"]) != "guild":
                expect = false
            _check(shown == expect, "house visibility %s at level %d" % [str(plot["pos"]), lv])
        # the wall: palisade below a walled town, stone from it
        var stone = _t.call("_stone")
        for wp in _t.get("wall_parts"):
            _check((wp.get("material_override") == stone) == (lv >= 4), "wall material at level %d" % lv)
            break
    _check(int(g.stats()["built"]) == int(g.stats()["houses"]), "all built at the top")
    _check(feed.size() > feed0 + 5, "news lines on growth (%d)" % (feed.size() - feed0))
    for i in range(feed0, feed.size()):
        print("NEWS ", feed[i])
    # and falling back
    g.show_level(2)
    var s2: Dictionary = g.stats()
    _check((s2["specials"] as Array).is_empty(), "halls close when the town falls back")
    _check(int(s2["built"]) < last, "lots return when the town falls back")
    # nobody housed on a lot at level 1 founding pass, raids skip lots
    g.show_level(1, true)
    var lots := 0
    for plot in _t.get("plots"):
        if plot.get("unbuilt", false):
            lots += 1
    print("LOTS at level 1: ", lots)
    _check(lots > 0, "lots at level 1")
    if _bad.is_empty():
        print("D3_TEST OK")
    else:
        print("D3_TEST FAIL ", _bad.size())
    return true
