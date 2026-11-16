extends SceneTree
## D17a: the T-pose probe. The town for 60 s (a level-5 raid at 4 s, like
## _townwalk); every 0.5 s every AnimationPlayer in the town is sampled. An
## EMPTY one (current_animation == "") is a body frozen in whatever pose its
## last clip left - or the bind T-pose if nothing ever played. Counts visible
## bodies (the gate) and all bodies (prop players - a chest lid - are not
## bodies and are left out), and names the worst offenders by owner and
## the clip they last had. Run with --fixed-fps 60; `-- --old` = the before
## figure (Rig fallbacks off).
var _t: Node3D
var _f := 0
var _aps: Array = []
var _samples := 0
var _empty_vis := 0
var _empty_all := 0
var _who := {}
var _hid := {}
var SECS := 60

func _initialize() -> void:
    if OS.get_cmdline_user_args().has("--short"):
        SECS = 12
    if OS.get_cmdline_user_args().has("--old"):
        Rig.fallback = false
        print("RIG FALLBACK OFF (before)")
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _collect() -> void:
    _aps.clear()
    var st: Array = [_t]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is AnimationPlayer and _is_body(c):
            _aps.append(c)
        for g in c.get_children():
            st.append(g)

## a body (person, beast) has an idle or a walk; a prop's player (a chest's
## lid) has neither and rests between uses by design
func _is_body(ap: AnimationPlayer) -> bool:
    for nm in ap.get_animation_list():
        var s := String(nm)
        if s.begins_with("Idle") or s.ends_with("_Idle") or s.begins_with("Walk") or s.ends_with("_Flying"):
            return true
    return false

func _owner_tag(ap: AnimationPlayer) -> String:
    var n: Node = ap
    while n != null and n != _t:
        if n is Townsfolk:
            return "Townsfolk:" + String(n.get("role"))
        if n.get_script() != null and n is Node3D and n.get_parent() != null and (n.get_script() as Script).get_global_name() != "":
            return String((n.get_script() as Script).get_global_name())
        n = n.get_parent()
    return "other:" + str(_t.get_path_to(ap))

func _vis(ap: AnimationPlayer) -> bool:
    var n: Node = ap.get_parent()
    while n != null and n != _t:
        if n is Node3D and not (n as Node3D).visible:
            return false
        n = n.get_parent()
    return true

func _process(_d: float) -> bool:
    _f += 1
    if _f == 240:
        var rd = _t.get("raids")
        if rd:
            rd.force_level = 5
            rd.call("raid", "west")
            print("RAID started")
    if _f % 300 == 30:
        _collect()
    if _f > 60 and _f % 30 == 0:
        for ap in _aps:
            if not is_instance_valid(ap) or not ap.is_inside_tree():
                continue
            _samples += 1
            if String(ap.current_animation) == "":
                _empty_all += 1
                var v := _vis(ap)
                if not v:
                    var kh := "hidden %s last=%s" % [_owner_tag(ap), String(ap.assigned_animation)]
                    _hid[kh] = int(_hid.get(kh, 0)) + 1
                if v:
                    _empty_vis += 1
                    var k := "%s last=%s" % [_owner_tag(ap), String(ap.assigned_animation)]
                    _who[k] = int(_who.get(k, 0)) + 1
    if _f % 1200 == 0:
        print("T=", _f / 60, "s players=", _aps.size(), " samples=", _samples, " empty_visible=", _empty_vis, " empty_all=", _empty_all)
    if _f >= SECS * 60:
        var ks: Array = _who.keys()
        ks.sort_custom(func(a, b): return int(_who[a]) > int(_who[b]))
        for k in ks.slice(0, 14):
            print("  EMPTY ", _who[k], "  ", k)
        for k in _hid.keys().slice(0, 10):
            print("  ", _hid[k], "  ", k)
        print("RIG misses=", Rig.misses, " fell_back=", Rig.fell_back, " chained=", Rig.chained)
        print("D17A_TEST players=%d samples=%d empty_visible=%d empty_all=%d %s" % [_aps.size(), _samples, _empty_vis, _empty_all, "PASS" if _empty_vis == 0 else "FAIL"])
        return true
    return false
