extends SceneTree
## D5: more animals. Headless.
## Hens in a run by the farmhouses, a sheepdog with each flock, five horses and a
## foal in the paddock, cats about the streets, crows over the fields - and over
## 3000 frames nothing is inside a building, up on a roof, or out of its pen.
var _t: Node3D
var _f := 0
var _bad: Array = []
var _run := 0
var _samples := 0
var _solid := 0
var _high := 0
var _out := 0
var _start := {}
var _birds0 := 0

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _check(ok: bool, what: String) -> void:
    if not ok:
        _bad.append(what)
        print("FAIL ", what)

func _kinds() -> Dictionary:
    var n := {}
    for a in _t.get("animals"):
        var k := String((a as Animal).kind)
        n[k] = int(n.get(k, 0)) + 1
    return n

func _process(_d: float) -> bool:
    _f += 1
    if _f == 3:
        _t.get("raids").set("_raid_t", 99999.0)
    if _f < 20:
        return false
    var animals: Array = _t.get("animals")
    if _f == 20:
        var n := _kinds()
        print("ANIMALS ", animals.size(), " ", n)
        var flocks: Array = _t.get("_flock_pens")
        var dogs := 0
        for a in animals:
            if (a as Animal).edge:
                dogs += 1
        print("FLOCKS ", flocks.size(), " sheepdogs ", dogs, " birds ", (_t.get("_birds") as Array).size(), " fields ", (_t.get("_fields") as Array).size())
        _check(int(n.get("Hen", 0)) >= 10, "hens in the farm runs (%d)" % int(n.get("Hen", 0)))
        _check(int(n.get("Cat", 0)) >= 6, "cats in town (%d)" % int(n.get("Cat", 0)))
        _check(int(n.get("Horse", 0)) >= 5 and int(n.get("Foal", 0)) == 1, "five horses and a foal in the paddock")
        _check(flocks.size() >= 1 and dogs == flocks.size(), "a sheepdog with every flock")
        for k in ["Cow", "Sheep", "Pig", "Duck", "Pug", "Corgi"]:
            _check(int(n.get(k, 0)) >= 1, "some %s" % k)
        _check((_t.get("_birds") as Array).size() >= 15 + 3 * mini(5, (_t.get("_fields") as Array).size()), "crows over the fields")
        for a in animals:
            _start[a] = (a as Node3D).global_position
        Engine.time_scale = 4.0
        return false
    _run += 1
    if _run % 10 == 0:
        for a in animals:
            var an: Animal = a
            var p := an.global_position
            _samples += 1
            if not (_t.call("solid_at", p, -0.1) as Array).is_empty():
                _solid += 1
                if _solid <= 8:
                    print("SOLID ", an.kind, " at ", p)
            if an.float_y == INF and p.y - float(_t.call("height_at", p.x, p.z)) > 0.25:
                _high += 1
                if _high <= 8:
                    print("HIGH ", an.kind, " at ", p)
            var d := p - an.centre
            if absf(d.dot(an.side)) > an.hw + 0.8 or absf(d.dot(an.fwd)) > an.hd + 0.8:
                _out += 1
                if _out <= 8:
                    print("OUT ", an.kind, " at ", p)
    if _run >= 3000:
        var moved := {}
        for a in animals:
            var an: Animal = a
            if an.global_position.distance_to(_start[a]) > 0.5:
                moved[an.kind] = int(moved.get(an.kind, 0)) + 1
        print("MOVED ", moved)
        print("SAMPLES ", _samples, " in_solid ", _solid, " on_high ", _high, " out_of_pen ", _out)
        _check(int(moved.get("Hen", 0)) >= 5 and int(moved.get("Cat", 0)) >= 3, "hens and cats wander")
        _check(_solid == 0, "no animal inside a building (%d)" % _solid)
        _check(_high == 0, "no animal on a roof (%d)" % _high)
        _check(_out == 0, "every animal stays in its pen/area (%d)" % _out)
        Engine.time_scale = 1.0
        if _bad.is_empty():
            print("D5_TEST OK")
        else:
            print("D5_TEST FAIL ", _bad.size())
        return true
    return false
