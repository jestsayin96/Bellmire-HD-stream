extends SceneTree
## D4: more guards and the mounted watch. Headless.
## Every gate post manned, two crossbowmen per watchtower, watch beats that
## grow with the level, riders from the Town Stables at 4+ who ride the roads
## (never inside anything solid), ride out at a raid, and archers who shoot.
var _t: Node3D
var _f := 0
var _bad: Array = []
var _phase := 0
var _ride_f := 0
var _solid := 0
var _samples := 0
var _start := {}
var _stops_seen := {}
var _engaged := {}
var _raid_f := 0

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _check(ok: bool, what: String) -> void:
    if not ok:
        _bad.append(what)
        print("FAIL ", what)

func _count(pred: Callable) -> int:
    var n := 0
    for p in _t.get("people"):
        if is_instance_valid(p) and pred.call(p):
            n += 1
    return n

func _finish() -> bool:
    Engine.time_scale = 1.0
    if _bad.is_empty():
        print("D4_TEST OK")
    else:
        print("D4_TEST FAIL ", _bad.size())
    return true

func _process(_d: float) -> bool:
    _f += 1
    if _f == 3:
        _t.get("raids").set("_raid_t", 99999.0)
    if _f < 20:
        return false
    var raids = _t.get("raids")
    var cav: Array = _t.get("cavalry")
    if _phase == 0:
        _phase = 1
        _t.call("show_level", 1, true)
        var posts: Array = _t.call("_guard_posts")
        var gg := _count(func(p) -> bool: return String(p.gear_role) == "gateguard" and p.visible)
        var lk := _count(func(p) -> bool: return String(p.gear_role) == "lookout" and p.visible)
        var towers: Array = _t.get("towers")
        print("GATE POSTS ", posts.size(), " gate guards ", gg, " | towers ", towers.size(), " lookouts ", lk)
        _check(gg == posts.size(), "every gate post manned (%d/%d)" % [gg, posts.size()])
        _check(lk == towers.size() * 2, "two crossbowmen per tower (%d)" % lk)
        var feed: Array = _t.get("feed")
        var feed0 := feed.size()
        var watch := {}
        var riders := {}
        for lv in range(1, 7):
            _t.call("show_level", lv)
            watch[lv] = _count(func(p) -> bool: return String(p.role) == "watch" and p.visible)
            riders[lv] = _count(func(p) -> bool: return p is Cavalry and p.visible)
            print("LEVEL ", lv, " watch ", watch[lv], " riders ", riders[lv])
        _check(int(riders[1]) == 0 and int(riders[3]) == 0, "no riders before the stables")
        _check(int(riders[4]) == 2 and int(riders[5]) == 3 and int(riders[6]) == 4, "riders 2/3/4 at 4/5/6")
        _check(int(watch[6]) > int(watch[3]) and int(watch[3]) > int(watch[1]) and int(watch[1]) >= 12, "the watch grows")
        var sworn := 0
        var rode := 0
        for i in range(feed0, feed.size()):
            if String(feed[i]).contains("sworn into the watch"):
                sworn += 1
                print("NEWS ", feed[i])
            if String(feed[i]).contains("mounted watch"):
                rode += 1
                print("NEWS ", feed[i])
        _check(sworn >= 2 and rode >= 1, "news of the garrison (%d sworn, %d rides)" % [sworn, rode])
        _t.call("show_level", 3, true)
        _check(_count(func(p) -> bool: return p is Cavalry and p.visible) == 0, "riders go back when the town falls")
        _t.call("show_level", 6, true)
        for c in cav:
            var cv: Cavalry = c
            _check(cv._horse != null and cv.seat_h > 0.7 and cv.seat_h < 2.2, "rider seated on a horse (seat %.2f)" % cv.seat_h)
            print("RIDER ", cv.person_name, " seat ", snappedf(cv.seat_h, 0.01), " stops ", cv.stops.size())
            _start[cv] = cv.ridden
        Engine.time_scale = 4.0
        return false
    if _phase == 1:
        _ride_f += 1
        if _ride_f % 20 == 0:
            for c in cav:
                var cv: Cavalry = c
                _samples += 1
                var sr: Array = _t.call("solid_at", cv.global_position, -0.15)
                if not sr.is_empty():
                    _solid += 1
                    if _solid <= 12:
                        print("SOLID ", cv.person_name, " at ", cv.global_position, " route ", cv._route.size(),
                              " next ", cv._route[0] if not cv._route.is_empty() else "-", " rect ", sr[0], " he ", sr[3])
                _stops_seen[str(cv.get_instance_id()) + ":" + str(cv._stop_i)] = true
        if _ride_f >= 3000:
            var tot := 0.0
            for c in cav:
                var m: float = (c as Cavalry).ridden - float(_start[c])
                tot += m
                print("RODE ", (c as Cavalry).person_name, " ", snappedf(m, 0.1), " m, gait ", (c as Cavalry)._gait)
                _check(m > 60.0, "rider %s rides the roads (%.0f m)" % [(c as Cavalry).person_name, m])
            print("RIDE in_solid ", _solid, "/", _samples, " stops seen ", _stops_seen.size())
            _check(float(_solid) <= float(_samples) * 0.01, "riders never inside a building (%d/%d)" % [_solid, _samples])
            _check(_stops_seen.size() >= cav.size() * 3, "riders pass their stops")
            # a raid on the west road; one raider is sent under a watchtower
            raids.set("force_level", 5)
            raids.call("raid", "west")
            var rs: Array = raids.get("raiders")
            var towers: Array = _t.get("towers")
            if not rs.is_empty() and not towers.is_empty():
                var tv: Vector3 = towers[0]
                var at: Vector3 = _t.call("_snap", tv + Vector3(14.0, 0, 6.0))
                at.y = _t.call("height_at", at.x, at.z)
                (rs[0]["node"] as Node3D).global_position = at
            _phase = 2
        return false
    if _phase == 2:
        _raid_f += 1
        var fighters: Dictionary = raids.get("_fighters")
        for c in cav:
            if fighters.has(c) and fighters[c]["target"] != null:
                _engaged[c] = true
        var rs2: Array = raids.get("raiders")
        if rs2.is_empty() or _raid_f > 6000:
            print("RAID over after ", _raid_f, " frames, raiders left ", rs2.size(), " riders engaged ", _engaged.size(),
                  " bolts ", raids.get("arrows_loosed"), " hits ", raids.get("arrows_hit"))
            _check(rs2.is_empty(), "the raid is driven off")
            _check(_engaged.size() >= 2, "the mounted watch rides out (%d)" % _engaged.size())
            _check(int(raids.get("arrows_loosed")) > 0, "tower archers shoot")
            var feed: Array = _t.get("feed")
            for l in feed.slice(maxi(0, feed.size() - 14)):
                print("FEED> ", l)
            return _finish()
    return false
