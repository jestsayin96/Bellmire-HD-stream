extends SceneTree
## D53: TOWED WAGONS STAY ATTACHED TO THEIR HAULER. Mr. E clip 14-31-18 saw a
## cart "moving on its own ... supposed to be attached to this guy, but it wasn't."
## The follow was a 4 m/s crawl placed after the LOD throttle, so a big jump (a
## door exit, a respawn, a raid reset, a far-LOD chunk) left the wagon gliding
## across open ground untethered. Fix: close a large gap AT ONCE, roll otherwise.
## Boots the real Town, finds every hauler with a .cart, records the worst
## carter<->cart gap over ordinary travel/parking, then TELEPORTS one hauler 25 m
## and confirms the wagon reattaches within a beat. Gated on PHYSICS frames (the
## cart follow runs in _physics_process, 60 Hz; _process spins far faster in
## headless). Prints D53_TEST.
var _t: Node3D
var _phase := "boot"
var _carters: Array = []
var _travel_max := 0.0
var _travel_samp := 0
var _pf0 := 0
var _pf_tp := 0
var _tp_who: Townsfolk = null
var _tp_gapN := 0.0
var _fails: Array = []

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _haulers() -> Array:
    var out: Array = []
    for p in _t.get("people"):
        if p is Townsfolk and is_instance_valid(p) and p.cart != null and is_instance_valid(p.cart):
            out.append(p)
    return out

func _gap(v: Townsfolk) -> float:
    var a := v.global_position
    var b: Vector3 = v.cart.global_position
    return Vector2(a.x - b.x, a.z - b.z).length()

func _process(_d: float) -> bool:
    var pf := Engine.get_physics_frames()
    var ec = _t.get("economy")
    if ec != null:
        ec.clock = 12.3 / 24.0
    var rd = _t.get("raids")
    if rd != null:
        rd.set("_raid_t", 99999.0)
    if _phase == "boot":
        _carters = _haulers()
        var nav = _t.get("nav")
        var ready: bool = nav != null and bool(nav.get("ready_ok"))
        if _carters.is_empty() or not ready:
            if pf > 1200:
                print("D53 haulers=%d nav_ready=%s" % [_carters.size(), str(ready)])
                print("D53_TEST FAIL - no hauler with a cart (or nav never ready)")
                return true
            return false
        print("D53 haulers with a cart: %d (nav ready)" % _carters.size())
        _pf0 = pf
        _phase = "travel"
        return false
    if _phase == "travel":
        for v in _carters:
            if is_instance_valid(v) and v.cart != null and is_instance_valid(v.cart):
                _travel_max = maxf(_travel_max, _gap(v))
                _travel_samp += 1
        if pf - _pf0 >= 600:
            for v in _carters:
                if is_instance_valid(v) and v.cart != null and is_instance_valid(v.cart) and v.visible and not v.inside:
                    _tp_who = v
                    break
            if _tp_who == null:
                print("D53_TEST FAIL - haulers lost their carts mid-soak")
                return true
            var p := _tp_who.global_position + Vector3(25.0, 0.0, 0.0)
            p = _t.call("keep_walkable", p)
            p.y = float(_t.call("height_at", p.x, p.z))
            _tp_who.global_position = p
            print("D53 teleported %s +25m; cart gap right after = %.1f m" % [String(_tp_who.person_name), _gap(_tp_who)])
            _pf_tp = pf
            _phase = "recover"
        return false
    if _phase == "recover":
        if pf - _pf_tp >= 120:
            _tp_gapN = _gap(_tp_who) if (is_instance_valid(_tp_who) and _tp_who.cart != null) else 999.0
            if _travel_max >= 6.0:
                _fails.append("travel gap stayed attached (<6 m): was %.1f m" % _travel_max)
            if _tp_gapN >= 6.0:
                _fails.append("wagon reattached after teleport (<6 m): was %.1f m" % _tp_gapN)
            print("D53 travel_max=%.2f m over %d samples; post-teleport recovered gap=%.2f m" % [_travel_max, _travel_samp, _tp_gapN])
            if _fails.is_empty():
                print("D53_TEST OK")
            else:
                for fl in _fails:
                    print("  FAIL ", fl)
                print("D53_TEST FAIL")
            return true
        return false
    return false
