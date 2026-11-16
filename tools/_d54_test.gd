extends SceneTree
## D54: NPCs VANISH AFTER ENTERING A BUILDING (Mr. E clip 14-29-22). An ordinary
## body indoors is invisible behind solid walls; the daytime dwell ran 18-45 s
## (a probe saw 59 s), so a pane following one lost it. The fix caps the DAYTIME
## indoor stay (INDOOR_MAX). This boots the real Town at pinned midday, soaks, and
## asserts: folk DO enter, every enterer re-emerges (none stuck indoors), and the
## worst daytime indoor dwell is bounded. Gated on physics frames. Prints D54_TEST.
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
            _trk[id] = {"enters":0,"exits":0,"in":ins,"since":pf,"maxrun":0}
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
    if (pf - _pf0) % 20 == 0:
        _sample(pf)
    if pf - _pf0 >= 3900:
        _report(pf)
        return true
    return false
func _report(pf: int) -> void:
    var entered := 0
    var tot_exits := 0
    var maxrun := 0
    var stuck := 0
    for id in _trk:
        var r: Dictionary = _trk[id]
        tot_exits += int(r["exits"])
        if int(r["enters"]) > 0:
            entered += 1
        var run := int(r["maxrun"])
        # only count bodies we actually saw ENTER (enters>0); a body that
        # STARTED inside is the _keep_indoors street-cap population, off-street
        # by design, not a watched NPC that vanished.
        if int(r["enters"]) > 0:
            if bool(r["in"]):
                run = maxi(run, pf - int(r["since"]))
            maxrun = maxi(maxrun, run)
        if bool(r["in"]) and int(r["enters"]) > 0 and (pf - int(r["since"])) > 1800:
            stuck += 1
    var maxs := float(maxrun) / 60.0
    print("D54 entered=%d exits=%d max_indoor=%.1fs stuck_over_30s=%d" % [entered, tot_exits, maxs, stuck])
    var fails: Array = []
    if entered < 5:
        fails.append("too few NPCs entered to test (entered=%d)" % entered)
    if stuck > 0:
        fails.append("%d NPC(s) entered and never re-emerged within 30 s" % stuck)
    if maxs >= 18.0:
        fails.append("worst daytime indoor dwell %.1fs >= 18 s cap" % maxs)
    if tot_exits < 1:
        fails.append("no NPC re-emerged at all")
    if fails.is_empty():
        print("D54_TEST OK")
    else:
        for f in fails:
            print("  FAIL ", f)
        print("D54_TEST FAIL")
