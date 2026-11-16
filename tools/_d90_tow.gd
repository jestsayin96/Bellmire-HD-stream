extends SceneTree
## D90 DONE TEST - THE TOW IS RIGID. Boots the real Town and soaks it (default
## 1200 s of sim time = Mr. E's 20 minutes; `-- --secs=N` to change), raids and
## the day left running, a caravan (the green-hooded caravan master) forced in
## at the start and kept coming. EVERY FRAME, after every body has posed (a
## sampler node at the end of the process order), for each hauler with a cart:
##   - distance hauler<->SHAFT TIPS vs the hitch (0.1 m: at his hips) outside a park
##   - relative yaw (cart heading vs hauler facing) vs the clamped lag outside a park
##   - "sideways while moving": hauler moving > 0.3 m/s with the cart > 45 deg off
##     (counted in EVERY state, a park included)
##   - "crossed": the cart's BED ahead of the hauler while the cart MOVES
##     (towed, drawing up, re-hitching - a cart stood parked is not crossing)
## Mid-soak one hauler is teleported 25 m: its cart must be behind it next frame.
## Run headless with --fixed-fps 60 (frames = sim time). Prints D90_TOW OK/FAIL.
var _t: Node3D
var _secs := 1200.0
var _f := 0
var _sim := 0.0
var _last: Dictionary = {}       # hauler id -> Vector3 last position
var _seen: Dictionary = {}       # hauler id -> name
var _dev_max := 0.0
var _yaw_max := 0.0
var _side := 0
var _cross := 0
var _samp_towed := 0
var _samp_all := 0
var _parks := 0
var _unparks := 0
var _state_last: Dictionary = {}
var _caravan_seen := 0
var _tp_done := false
var _tp_ok := true
var _tp_who: Townsfolk = null
var _tp_f := 0
var _worst: String = ""
var _side_ex: Array = []
var _cross_ex: Array = []
const LAG := 0.35
const TOW := 0.1     # Townsfolk.HITCH_BACK: shaft tips this far behind his centre

func _initialize() -> void:
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--secs="):
            _secs = float(a.substr(7))
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    var gs := GDScript.new()
    gs.source_code = "extends Node\nvar cb: Callable\nfunc _process(d: float) -> void:\n\tcb.call(d)\n"
    gs.reload()
    var n := Node.new()
    n.set_script(gs)
    n.process_priority = 100000
    n.set("cb", _sample)
    root.add_child.call_deferred(n)
    print("D90 soak %.0f s sim" % _secs)

func _haulers() -> Array:
    var out: Array = []
    for p in _t.get("people"):
        if p is Townsfolk and is_instance_valid(p) and p.cart != null and is_instance_valid(p.cart):
            out.append(p)
    var cv = _t.get("_caravans")
    if cv is Array:
        for c in cv:
            var v = (c as Dictionary).get("v")
            if v is Townsfolk and is_instance_valid(v) and v.cart != null and is_instance_valid(v.cart) and not out.has(v):
                out.append(v)
    var vl = _t.get("valley")
    if vl != null:
        for tr in vl.get("travellers"):
            var v = tr.get("v")
            if v is Townsfolk and is_instance_valid(v) and v.cart != null and is_instance_valid(v.cart) and not out.has(v):
                out.append(v)
    return out

func _sample(d: float) -> void:
    if _t == null or _f < 60:
        return
    _sim += d
    for v in _haulers():
        var h: Townsfolk = v
        var id := h.get_instance_id()
        if not _seen.has(id):
            _seen[id] = "%s(%s)" % [String(h.person_name), String(h.role)]
            if String(h.role) == "caravan":
                _caravan_seen += 1
        var hp := h.global_position
        var sp := 0.0
        if _last.has(id) and d > 0.0:
            var lp: Vector3 = _last[id]
            sp = Vector2(hp.x - lp.x, hp.z - lp.z).length() / d
            if sp > 15.0:
                sp = 0.0      # a teleport (a door, a respawn), not a walk
        _last[id] = hp
        var st: int = h.tow_state
        var ls: int = _state_last.get(id, st)
        if ls != st:
            if st == Townsfolk.TOW_PARKING:
                _parks += 1
            elif st == Townsfolk.TOW_UNPARKING:
                _unparks += 1
        _state_last[id] = st
        if h.inside or not h.visible:
            continue
        _samp_all += 1
        var tp: Vector3 = h.cart_tip()
        var bd: Vector3 = h.cart_body()
        var dist := Vector2(hp.x - tp.x, hp.z - tp.z).length()
        var rel := absf(angle_difference(h.rotation.y, float(h.cart.rotation.y)))
        var fwd := Vector2(sin(h.rotation.y), cos(h.rotation.y))
        var ahead := Vector2(bd.x - hp.x, bd.z - hp.z).dot(fwd)
        if sp > 0.3 and rel > PI * 0.25 and rel < PI * 0.75:
            _side += 1
            if _side_ex.size() < 6:
                _side_ex.append("t=%.1f %s st=%d sp=%.2f rel=%.0fdeg" % [_sim, _seen[id], st, sp, rad_to_deg(rel)])
        if ahead > 0.2 and st != Townsfolk.TOW_PARKED:
            _cross += 1
            if _cross_ex.size() < 6:
                _cross_ex.append("t=%.1f %s st=%d ahead=%.2f" % [_sim, _seen[id], st, ahead])
        if st == Townsfolk.TOW_TOWED:
            _samp_towed += 1
            var dv := absf(dist - TOW)
            if dv > _dev_max:
                _dev_max = dv
                _worst = "t=%.1f %s dist=%.3f" % [_sim, _seen[id], dist]
            _yaw_max = maxf(_yaw_max, rel)

func _process(_d: float) -> bool:
    _f += 1
    if _f == 90:
        _t.call("_caravan")
    var ct = _t.get("_caravans")
    if ct is Array and (ct as Array).is_empty() and float(_t.get("_caravan_t")) > 20.0:
        _t.set("_caravan_t", 20.0)
    if not _tp_done and _sim > _secs * 0.5:
        for v in _haulers():
            var h: Townsfolk = v
            if h.visible and not h.inside and h.tow_state == Townsfolk.TOW_TOWED:
                var p: Vector3 = _t.call("keep_walkable", h.global_position + Vector3(25.0, 0.0, 0.0))
                p.y = float(_t.call("height_at", p.x, p.z))
                h.global_position = p
                _last.erase(h.get_instance_id())
                _tp_done = true
                _tp_who = h
                _tp_f = _f
                break
    if _tp_who != null and _f == _tp_f + 3:
        var h2 := _tp_who
        _tp_who = null
        if is_instance_valid(h2) and h2.cart != null:
            var tq: Vector3 = h2.cart_tip()
            var g := Vector2(h2.global_position.x - tq.x, h2.global_position.z - tq.z).length()
            _tp_ok = absf(g - TOW) < 0.15 or h2.tow_state != Townsfolk.TOW_TOWED
            print("D90 teleported %s +25 m; gap 3 frames later %.2f m (state %d)" % [String(h2.person_name), g, h2.tow_state])
    if _f % 3600 == 0:
        print("D90 t=%.0f s haulers=%d dev_max=%.3f yaw_max=%.0fdeg side=%d cross=%d parks=%d unparks=%d" % [_sim, _seen.size(), _dev_max, rad_to_deg(_yaw_max), _side, _cross, _parks, _unparks])
    if _sim < _secs:
        return false
    var fails: Array = []
    if _seen.is_empty():
        fails.append("no hauler with a cart")
    if _caravan_seen == 0:
        fails.append("no caravan master seen")
    if _dev_max > 0.15:
        fails.append("tow distance deviated %.3f m (> 0.15) %s" % [_dev_max, _worst])
    if _yaw_max > LAG + 0.02:
        fails.append("relative yaw %.1f deg > lag %.1f" % [rad_to_deg(_yaw_max), rad_to_deg(LAG)])
    if _side > 0:
        fails.append("%d frames sideways while moving %s" % [_side, str(_side_ex)])
    if _cross > 0:
        fails.append("%d frames cart ahead of hauler %s" % [_cross, str(_cross_ex)])
    if not _tp_ok:
        fails.append("cart not re-hitched after a teleport")
    print("D90 haulers=%d caravans=%d samples towed=%d all=%d dev_max=%.3f m yaw_max=%.1f deg side=%d cross=%d parks=%d unparks=%d tp=%s" % [_seen.size(), _caravan_seen, _samp_towed, _samp_all, _dev_max, rad_to_deg(_yaw_max), _side, _cross, _parks, _unparks, str(_tp_ok)])
    print("D90 haulers seen: ", _seen.values())
    if fails.is_empty():
        print("D90_TOW OK")
    else:
        for fl in fails:
            print("  FAIL ", fl)
        print("D90_TOW FAIL")
    return true
