class_name AutoDirector
extends Node
## Stream mode: the camera directs itself so Bellmire can run unattended.
## Every second it scores what is happening and cuts to the best shot:
##   a floor's lord fighting (100)  >  raid on the town  >  a fight below  >  a catch being landed  >  a party
##   walking a floor   >  a viewer's hero out in town  >  a slow tour of the town.
## A shot is held at least HOLD_MIN s; anything 20+ points hotter cuts in early;
## after HOLD_MAX s a quiet shot moves on to something else.
##   V    director on / off          F10   hide / show the whole interface
## Touching the camera yourself pauses the director for 20 s, then it resumes.

const HOLD_MIN := 8.0
const HOLD_MAX := 22.0
const MANUAL_PAUSE := 20.0

var eye: RtsCamera
var town: Node3D
var on := false
var _cur := {}                  # the shot on screen: {key, pri, node|pos, dist, pitch}
var _held := 0.0
var _tick := 0.0
var _paused_for := 0.0
var _tour_i := 0
var _rng := RandomNumberGenerator.new()

func setup(e: RtsCamera, t: Node3D) -> void:
    eye = e
    town = t
    _rng.randomize()

func _unhandled_input(ev: InputEvent) -> void:
    if ev is InputEventKey and ev.pressed and not ev.echo:
        if ev.keycode == KEY_V:
            _set_on(not on)
            get_viewport().set_input_as_handled()
            return
        if ev.keycode == KEY_F10:
            if eye and eye._layer:
                eye._layer.visible = not eye._layer.visible
            for c in town.get_children():
                if c is FeedHUD or c is LeaderboardPanel:
                    (c as CanvasLayer).visible = not (c as CanvasLayer).visible
            get_viewport().set_input_as_handled()
            return
    # any hands-on camera input: step aside for a while
    if on and (ev is InputEventMouseButton or (ev is InputEventKey and ev.pressed)):
        _paused_for = MANUAL_PAUSE
        eye.quiet = false

func _set_on(v: bool) -> void:
    on = v
    _cur = {}
    _held = 0.0
    _paused_for = 0.0
    if eye:
        eye.quiet = on
        eye._say_local("Director %s (V)" % ("ON - the camera runs itself" if on else "off"))
        if not on:
            eye._following = false

func _process(delta: float) -> void:
    if not on or eye == null or town == null:
        return
    var real := delta / maxf(Engine.time_scale, 0.001)
    if _paused_for > 0.0:
        _paused_for -= real
        if _paused_for <= 0.0:
            eye.quiet = true
            _cur = {}
        return
    _held += real
    if _cur.get("tour", false):
        eye.yaw += 0.06 * real                  # idle shots drift slowly round
    _tick -= real
    if _tick > 0.0:
        return
    _tick = 1.0
    var best := _best()
    if best.is_empty():
        return
    var cur_pri := float(_cur.get("pri", -1.0))
    var cur_alive := _shot_alive(_cur)
    var cut := false
    if _cur.is_empty() or not cur_alive:
        cut = true
    elif best["key"] == _cur["key"]:
        _cur["pri"] = best["pri"]               # same story, keep watching
    elif String(best["key"]).begins_with("lord_") and not String(_cur["key"]).begins_with("lord_"):
        cut = true                              # a lord has risen: go now
    elif float(best["pri"]) >= cur_pri + 20.0 and _held >= 2.0:
        cut = true                              # something much hotter
    elif _held >= HOLD_MIN and float(best["pri"]) > cur_pri:
        cut = true
    elif _held >= HOLD_MAX:
        cut = true                              # quiet too long: move on
    if cut:
        if _held >= HOLD_MAX and best["key"] == _cur.get("key", ""):
            best = _best(String(_cur.get("key", "")))      # something different
            if best.is_empty():
                return
        _cut(best)

func _cut(s: Dictionary) -> void:
    print("DIRECTOR cut ", s["key"], " pri ", s["pri"])
    _cur = s
    _held = 0.0
    eye.pitch = deg_to_rad(float(s.get("pitch", -45.0)))
    if s.has("node") and is_instance_valid(s["node"]):
        eye._delve_i = -1
        eye._select(s["node"])
        eye._following = true
        eye.focus = (s["node"] as Node3D).global_position
        eye.dist = float(s.get("dist", 22.0))
    else:
        eye._select(null)
        eye._jump(s["pos"], float(s.get("dist", 34.0)))

func _shot_alive(s: Dictionary) -> bool:
    if s.is_empty():
        return false
    if s.has("node"):
        var n = s["node"]
        return is_instance_valid(n) and (n as Node3D).is_visible_in_tree()
    return true

## every shot worth showing right now, best first; `avoid` skips one story
func _best(avoid: String = "") -> Dictionary:
    var c: Array = []
    # 1. a raid on Bellmire
    var rd = town.get("raids")
    if rd and bool(rd.get("_live")):
        for r in rd.get("raiders"):
            var n = r.get("node") if r is Dictionary else null
            if n and is_instance_valid(n):
                c.append({"key": "raid", "pri": 95.0, "node": n, "dist": 30.0, "pitch": -40.0})
                break
    # 2-3. delves below: fights first, then the walk between them
    for d in town.get_children():
        if not (d is Delve) or (d as Delve).dun == null or not is_instance_valid((d as Delve).dun):
            continue
        var alive: Array = (d as Delve)._alive()
        if alive.is_empty():
            continue
        var body: Node3D = alive[0]["body"]
        var hurt := 0.0
        for m in alive:
            hurt = maxf(hurt, 1.0 - float(m["hp"]) / maxf(float(m["max"]), 1.0))
        var st := String((d as Delve).state)
        if st == "home":
            continue
        var viewers := 0.0 if (d as Delve).npc_party else 10.0
        var lord: Monster = (d as Delve).lord_fighting()
        if lord:
            # a lord on its floor is the event of the night: nothing outranks it
            var lh := float(lord.def.get("h", 5.0))
            c.append({"key": "lord_%d" % d.get_instance_id(), "pri": 100.0 + viewers * 0.1,
                      "node": lord, "dist": clampf(12.0 + lh * 2.2, 20.0, 42.0), "pitch": -55.0})
        if st == "fight":
            c.append({"key": "fight_%d" % d.get_instance_id(), "pri": 75.0 + viewers + hurt * 10.0,
                      "node": body, "dist": 20.0, "pitch": -60.0})
        else:
            c.append({"key": "delve_%d" % d.get_instance_id(), "pri": 45.0 + viewers,
                      "node": body, "dist": 22.0, "pitch": -62.0})
    # 4. a catch coming in on the docks
    for a in town.get("anglers"):
        if is_instance_valid(a) and (a.state == Angler.S.REEL or a.state == Angler.S.SHOW or a.state == Angler.S.BITE):
            c.append({"key": "fish_%d" % a.get_instance_id(), "pri": 60.0,
                      "node": a.get_parent(), "dist": 12.0, "pitch": -28.0})
    # 5. viewers' heroes about town
    var hs: Dictionary = town.get("heroes")
    var ks := hs.keys()
    ks.shuffle()
    for uid in ks:
        var hb = hs[uid]
        if is_instance_valid(hb) and (hb as Node3D).is_visible_in_tree():
            c.append({"key": "hero_%s" % uid, "pri": 30.0 + _rng.randf() * 5.0,
                      "node": hb, "dist": 14.0, "pitch": -30.0})
            break
    # 6. the town itself: a slow tour of its best views
    var tour: Array = [[town.get("_market_pos"), 38.0, -42.0]]
    var si: Dictionary = town.get("_scar_info")
    if si.has("mouth"):
        tour.append([si["mouth"], 45.0, -35.0])
    tour.append([Vector3.ZERO, 120.0, -50.0])
    # D12: the valley beyond the wall - steadings, the Ashwood, the ford, the Old Footing
    var vl = town.get("valley")
    if vl != null:
        for vt in vl.tour:
            tour.append(vt)
    var stp: Array = tour[_tour_i % tour.size()]
    c.append({"key": "tour_%d" % (_tour_i % tour.size()), "pri": 10.0, "pos": stp[0],
              "dist": stp[1], "pitch": stp[2], "tour": true})
    if _cur.get("tour", false) and _held >= HOLD_MAX:
        _tour_i += 1
    var best := {}
    for s in c:
        if String(s["key"]) == avoid:
            continue
        if best.is_empty() or float(s["pri"]) > float(best["pri"]):
            best = s
    return best
