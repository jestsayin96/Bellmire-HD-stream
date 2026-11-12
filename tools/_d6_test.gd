extends SceneTree
## D6: Bellmire's named people. Headless.
## Twelve named folk with fixed names nobody else in town shares, each with their
## own look; over two town days each keeps a day (goes where the slot says),
## the drunk is abroad at night and indoors by day, the crier reads the Chronicle,
## named lines reach the Chronicle, and none of them steps inside a building.
var _t: Node3D
var _n: Notables
var _f := 0
var _bad: Array = []
var _game_t := 0.0
var _samples := 0
var _solid := 0
var _drunk_day := [0, 0]
var _drunk_night := [0, 0]
var _crier_news := 0
var _feed0 := 0

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

## the same test as tools/_townwalk.gd (D1's in_solid): inside a house box by
## 0.6 m, or inside any other solid by 0.15 m
var _houses: Array = []

func _inside_rect(p: Vector3, r: Array, shrink: float) -> bool:
    var d := Vector2(p.x, p.z) - (r[0] as Vector2)
    var he: Vector2 = r[3]
    return absf(d.dot(r[1])) < he.x - shrink and absf(d.dot(r[2])) < he.y - shrink

func _house_rects() -> Array:
    var out: Array = []
    var hb: Dictionary = _t.get("_house_box")
    for plot in _t.get("plots"):
        var sh: String = String(plot.get("shape", "a"))
        if not hb.has(sh):
            continue
        var yaw: float = float(plot["yaw"])
        var ax := Vector2(cos(yaw), -sin(yaw))
        var az := Vector2(sin(yaw), cos(yaw))
        var pp: Vector3 = plot["pos"]
        var off: Vector2 = hb[sh][1]
        out.append([Vector2(pp.x, pp.z) + ax * off.x + az * off.y, ax, az, hb[sh][0]])
    return out

func _in_solid(p: Vector3) -> bool:
    if _houses.is_empty():
        _houses = _house_rects()
    for r in _houses:
        if _inside_rect(p, r, 0.6):
            return true
    for r in _t.get("_solid_rects"):
        if _inside_rect(p, r, 0.15):
            return true
    return false

func _check(ok: bool, what: String) -> void:
    if not ok:
        _bad.append(what)
        print("FAIL ", what)

func _process(d: float) -> bool:
    _f += 1
    if _f == 3:
        _t.get("raids").set("_raid_t", 99999.0)
    if _f < 20:
        return false
    if _f == 20:
        _n = _t.get("notables")
        _check(_n != null, "the town has its notables")
        if _n == null:
            print("D6_TEST FAIL")
            return true
        var names := {}
        var looks := {}
        for c in _n.cast:
            var who: Townsfolk = c["who"]
            print("NOTABLE %-20s %-22s role=%-10s model=%-18s size=%.2f home=%s" % [who.person_name, who.notable_title, who.role, who.model, who.size_k, str(who.home.snapped(Vector3.ONE))])
            names[who.person_name] = true
            looks["%s|%s|%.2f" % [who.model, who.tint.to_html(), who.size_k]] = true
            _check(who.notable_title != "" and who._tag != null and who._tag.visible, "%s wears a visible title tag" % who.person_name)
        _check(_n.cast.size() >= 12, "twelve named people (%d)" % _n.cast.size())
        _check(names.size() == _n.cast.size(), "every name different")
        _check(looks.size() == _n.cast.size(), "every look different (%d of %d)" % [looks.size(), _n.cast.size()])
        var clash := 0
        for p in _t.get("people"):
            if p is Townsfolk and not (p is HeroBody) and (p as Townsfolk).notable_title == "" and names.has((p as Townsfolk).person_name):
                clash += 1
        _check(clash == 0, "no other townsfolk shares a named person's name (%d)" % clash)
        for k in ["chief", "smith", "healer", "innkeeper", "priest", "crier"]:
            var w := _n.by_key(k)
            _check(w != null and w.role == k, "the lore's %s is promoted, not doubled" % k)
        _feed0 = (_t.get("feed") as Array).size()
        Engine.time_scale = 4.0
        return false
    _game_t += d
    var eco: Economy = _t.get("economy")
    if _f % 10 == 0:
        var h := eco.hour()
        for c in _n.cast:
            var who: Townsfolk = c["who"]
            if who.inside or not who.visible:
                continue
            if who._route.size() == 1 and who._enter_at != Vector3.ZERO:
                continue       # the door leg, door -> just inside
            _samples += 1
            if _in_solid(who.global_position):
                _solid += 1
                if _solid <= 8:
                    print("SOLID ", who.person_name, " at ", who.global_position, " h=", snappedf(h, 0.1))
        var dr := _n.by_key("drunk")
        var out := 1 if (dr.visible and not dr.inside) else 0
        # (from the second morning: on the first he is still walking to his bed)
        if h >= 8.0 and h < 14.0 and _game_t > 0.6 * Economy.DAY_SECONDS:
            _drunk_day[0] += out
            _drunk_day[1] += 1
        elif h >= 2.0 and h < 5.5:
            _drunk_night[0] += out
            _drunk_night[1] += 1
        var cr := _n.by_key("crier")
        for l in cr.shout_lines:
            if String(l).begins_with("Hear ye!"):
                _crier_news += 1
                break
    if _game_t >= 2.2 * Economy.DAY_SECONDS or _f > 60000:
        Engine.time_scale = 1.0
        var feed: Array = _t.get("feed")
        var named := 0
        for i in range(_feed0, feed.size()):
            for c in _n.cast:
                if String(feed[i]).begins_with((c["who"] as Townsfolk).person_name):
                    named += 1
                    break
        var ratio := float(_n.reached) / maxf(float(_n.visits), 1.0)
        print("GAME_T %.0f s  frames %d" % [_game_t, _f])
        print("SLOTS visited %d reached %d (%.0f%%)" % [_n.visits, _n.reached, ratio * 100.0])
        print("CHRONICLE named lines %d (lines_said %d)" % [named, _n.lines_said])
        print("CRIER news samples %d, last shouts %s" % [_crier_news, str(_n.by_key("crier").shout_lines.slice(0, 2))])
        print("DRUNK out by day %d/%d, out at night %d/%d" % [_drunk_day[0], _drunk_day[1], _drunk_night[0], _drunk_night[1]])
        print("SAMPLES %d in_solid %d" % [_samples, _solid])
        _check(_n.visits >= _n.cast.size() * 4, "everyone moves through their day (%d slot changes)" % _n.visits)
        _check(ratio >= 0.75, "they get where their day says (%.2f)" % ratio)
        _check(named >= 3, "named lines in the Chronicle (%d)" % named)
        _check(_crier_news > 0, "the crier reads the Chronicle aloud")
        _check(_drunk_night[1] > 0 and float(_drunk_night[0]) / float(_drunk_night[1]) >= 0.4, "the drunk is out at night")
        _check(_drunk_day[1] > 0 and float(_drunk_day[0]) / float(_drunk_day[1]) <= 0.15, "the drunk sleeps it off by day")
        _check(_solid == 0, "no named person inside a building (%d)" % _solid)
        if _bad.is_empty():
            print("D6_TEST OK")
        else:
            print("D6_TEST FAIL ", _bad.size())
        return true
    return false
