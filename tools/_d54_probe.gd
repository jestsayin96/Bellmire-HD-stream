extends SceneTree
## D54 PROBE: how long do ordinary townsfolk stay invisible after entering a
## building, and does anyone enter and NEVER come back out? Clock pinned to
## midday (the daytime complaint; no night-sleep). Gated on physics frames.
var _t: Node3D
var _pf0 := 0
var _trk := {}
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _ordinary(p) -> bool:
    return p is Townsfolk and is_instance_valid(p) and p.rank < 0 and not p.stay and p.leader == null and p.cart == null
func _sample(pf: int) -> void:
    for p in _t.get("people"):
        if not _ordinary(p):
            continue
        var id: int = p.get_instance_id()
        var ins: bool = bool(p.inside) or not bool(p.visible)
        if not _trk.has(id):
            _trk[id] = {"enters":0,"exits":0,"in":ins,"since":pf,"maxrun":0,"name":String(p.person_name),"role":String(p.role)}
        var r: Dictionary = _trk[id]
        if ins and not bool(r["in"]):
            r["in"] = true
            r["since"] = pf
            r["enters"] += 1
        elif (not ins) and bool(r["in"]):
            r["in"] = false
            r["exits"] += 1
            r["maxrun"] = maxi(int(r["maxrun"]), pf - int(r["since"]))
func _process(_d: float) -> bool:
    var pf := Engine.get_physics_frames()
    var ec = _t.get("economy")
    if ec != null:
        ec.clock = 12.3 / 24.0
    var rd = _t.get("raids")
    if rd != null:
        rd.set("_raid_t", 99999.0)
    if _pf0 == 0:
        if _t.get("people") != null and (_t.get("people") as Array).size() > 0:
            _pf0 = pf
        return false
    if (pf - _pf0) % 30 == 0:
        _sample(pf)
    if pf - _pf0 >= 3600:
        _report(pf)
        return true
    return false
func _report(pf: int) -> void:
    var n := _trk.size()
    var entered := 0
    var never_out := 0
    var tot_enters := 0
    var tot_exits := 0
    var maxrun := 0
    var stuck: Array = []
    for id in _trk:
        var r: Dictionary = _trk[id]
        tot_enters += int(r["enters"])
        tot_exits += int(r["exits"])
        if int(r["enters"]) > 0:
            entered += 1
        # still inside at the end: count the open run too
        var run := int(r["maxrun"])
        if bool(r["in"]):
            run = maxi(run, pf - int(r["since"]))
        maxrun = maxi(maxrun, run)
        if bool(r["in"]) and int(r["enters"]) > 0 and (pf - int(r["since"])) > 1800:
            never_out += 1
            if stuck.size() < 12:
                stuck.append("%s/%s in %.1fs enters=%d exits=%d" % [r["name"], r["role"], float(pf - int(r["since"]))/60.0, int(r["enters"]), int(r["exits"])])
    print("D54_PROBE ordinary=%d entered=%d  enters=%d exits=%d  max_indoor=%.1fs  stuck_over_30s=%d" % [n, entered, tot_enters, tot_exits, float(maxrun)/60.0, never_out])
    for s in stuck:
        print("  STUCK ", s)
