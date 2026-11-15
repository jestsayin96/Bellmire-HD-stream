extends SceneTree
## D21b.3: guards form a line between the market and the incoming raiders -
## not every guard charges a different mark. Smoke-tests the three new helpers,
## then runs a short scar raid and checks guards actually move from their
## initial posts toward the raider centroid while the fight is still on.

var _t: Node3D
var _rd: Raids
var _f := 0
var _fails: Array = []
var _starts := {}
var _raid_f := -1
var _sampled := false

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _check(ok: bool, what: String) -> void:
    print("D21B3 %s %s" % ["pass" if ok else "FAIL", what])
    if not ok:
        _fails.append(what)

func _guards() -> Array:
    var out: Array = []
    for p in _t.get("people"):
        if is_instance_valid(p) and p is Townsfolk and String((p as Townsfolk).role) == "guard" \
                and not (p is Cavalry) and String((p as Townsfolk).notable_title) == "":
            out.append(p)
    return out

func _flat(a: Vector3, b: Vector3) -> float:
    return Vector2(a.x - b.x, a.z - b.z).length()

func _process(_d: float) -> bool:
    _f += 1
    if _f == 60:
        _rd = _t.get("raids") as Raids
        _check(_rd != null, "raids node present")
        _check(_rd.has_method("_raider_centroid"), "Raids._raider_centroid present")
        _check(_rd.has_method("_musters"),         "Raids._musters present")
        _check(_rd.has_method("_line_up"),         "Raids._line_up present")
        if _rd:
            _rd.force_level = 3
            _rd.set("_raid_t", 99999.0)
            var eco = _t.get("economy")
            if eco:
                eco.day = 20             # D21b.3: a busy day yields a 6-8 raider horde
    if _f == 180 and _raid_f < 0:
        var gs := _guards()
        for g in gs:
            _starts[g] = (g as Node3D).global_position
        _check(gs.size() >= 3, "at least 3 muster-eligible guards (got %d)" % gs.size())
        seed(2131)
        if _rd:
            _rd.raid("scar")
        _raid_f = _f
    # sample while the raid is still on, at raid_f+180 (3 s game time)
    if _raid_f > 0 and not _sampled and _f >= _raid_f + 180:
        _sampled = true
        var cent := _rd._raider_centroid()
        var centre: Vector3 = _t.get("_market_pos")
        var raiders_live: int = (_rd.raiders as Array).size()
        var moved := 0
        var toward := 0
        var on_line := 0
        var fwd := Vector3.ZERO
        var side := Vector3.ZERO
        if cent != Vector3.ZERO:
            var v := Vector3(cent.x - centre.x, 0, cent.z - centre.z)
            if v.length() > 0.01:
                fwd = v.normalized()
                side = Vector3(-fwd.z, 0, fwd.x)
        for g in _starts.keys():
            if not is_instance_valid(g):
                continue
            var p0: Vector3 = _starts[g]
            var p1: Vector3 = (g as Node3D).global_position
            if _flat(p0, p1) > 0.5:
                moved += 1
            if cent != Vector3.ZERO:
                var v0 := _flat(p0, cent)
                var v1 := _flat(p1, cent)
                if v1 < v0 - 0.4:
                    toward += 1
                # within 3 m of the muster line
                var rel := p1 - centre
                var along := rel.dot(fwd)
                var lat  := rel.dot(side)
                if absf(along - 11.0) < 3.5 and absf(lat) < 12.0 and _flat(p1, centre) > 4.0:
                    on_line += 1
        print("D21B3 raiders_live=%d moved=%d toward=%d on_line=%d guards=%d cent_from_centre=%.1f" \
              % [raiders_live, moved, toward, on_line, _starts.size(), _flat(cent, centre)])
        _check(raiders_live >= 2, "the raid is still going when sampled (%d raiders left)" % raiders_live)
        _check(moved >= 2,  "at least 2 guards left their posts (moved=%d)" % moved)
        _check(toward >= 1, "at least 1 guard closed toward the raider centre (toward=%d)" % toward)
        var bad := _fails.size()
        print("D21B3 %s fails=%d %s" % ["OK" if bad == 0 else "FAIL", bad, _fails])
        quit(0 if bad == 0 else 1)
        return true
    if _f > 3000:
        print("D21B3 TIMEOUT fails=", _fails)
        quit(1)
        return true
    return false
