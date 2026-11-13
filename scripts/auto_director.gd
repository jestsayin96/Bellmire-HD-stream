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
const CHAT_FRESH_S := 120.0     # L18: a command in the last 2 min makes a hero the director's pick

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
    UiTheme.watch(self)          # L18: the banner follows F11

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
                # L17: the spotlight panes' name / reason chips go with the rest of the UI
                if c is Spotlight:
                    (c as Spotlight).set_labels(not (c as Spotlight).labels_shown)
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

## ---- L18: "Now watching: <name> the <people> <calling>" - top centre, on the house chip,
## while the director holds on a viewer's hero (in town or below). Lives on the eye's UI
## layer, so F10 hides it with the rest; hidden while the spotlight grid carries the view.
var _banner: Label

func banner_text(n: Node) -> String:
    if not (n is HeroBody) or (n as HeroBody).npc or (n as HeroBody).roster == null:
        return ""
    var h := (n as HeroBody).roster.get_hero((n as HeroBody).user_id)
    if h.is_empty():
        return ""
    return "Now watching: %s the %s %s" % [h.get("name", "?"), String(h.get("species", "")).capitalize(), String(h.get("class", "")).capitalize()]

func _banner_tick() -> void:
    if eye == null or eye._layer == null:
        return
    if _banner == null:
        _banner = Label.new()
        _banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _banner.anchor_left = 0.5
        _banner.anchor_right = 0.5
        _banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
        _banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        HudDock.mark(_banner, "none")        # L21: hides while the spotlight panes are up
        eye._layer.add_child(_banner)
        restyle()
    var t := ""
    if on and _paused_for <= 0.0 and _cur.has("node") and is_instance_valid(_cur["node"]) and not get_viewport().disable_3d:
        t = banner_text(_cur["node"])
    _banner.visible = t != ""
    if t != "" and _banner.text != t:
        _banner.text = t
        _banner.reset_size()

func restyle() -> void:
    if _banner == null:
        return
    _banner.add_theme_stylebox_override("normal", UiTheme.chip())
    _banner.add_theme_font_size_override("font_size", UiTheme.px(28))
    _banner.add_theme_color_override("font_color", UiTheme.INK)
    _banner.offset_top = UiTheme.px(16)
    _banner.reset_size()

func _process(delta: float) -> void:
    _banner_tick()
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
        best = _fallback_shot()             # L34: never leave the eye parked
    if best.is_empty():
        return
    var cur_pri := float(_cur.get("pri", -1.0))
    var cur_alive := _shot_alive(_cur)
    var cut := false
    if _cur.is_empty() or not cur_alive:
        cut = true
    elif _lane_owns(_cur) and best["key"] != _cur["key"]:
        cut = true                              # L24: a lane holds this hero now - the split would show it twice
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
            var alt := _best(String(_cur.get("key", "")))      # something different
            if alt.is_empty():
                alt = _fallback_shot(String(_cur.get("key", "")))
            if not alt.is_empty():          # L34: nothing else to show - re-cut, never return
                best = alt
        _cut(best)

## ---- L24 (Mr. E, Nov 11): while a spotlight lane holds a hero, the director never follows
## that same hero - the split would show one thing twice. It cuts away (to the story, through
## another delver, or to the next best thing). A lord or a raid is followed by its own node,
## never a hero, so it is never given up for this.
var _held_now: Array = []

func lane_held() -> Array:
    var out: Array = []
    var s := HudDock.spot(town)
    if s == null or s.mode_now() == "off":
        return out
    for l in Spotlight.LANES:
        # L32a: only a PAID moment holds its hero against the director; the always-on
        # grid's ambient shots avoid the director themselves (Spotlight._amb_pick), so
        # they never starve it of subjects
        var b := s.paid_target(l)
        if b:
            out.append(b)
    return out

func _lane_owns(s: Dictionary) -> bool:
    if s.is_empty() or not s.has("node"):
        return false
    var k := String(s.get("key", ""))
    if k.begins_with("lord_") or k == "raid":
        return false
    return lane_held().has(s["node"])

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

## the town tour's shots: the market (the town wide), the scar's mouth, the whole valley
## (L20: the clearance test cuts to these through the director's own _cut)
func tour_stops() -> Array:
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
    var out: Array = []
    for i in tour.size():
        out.append({"key": "tour_%d" % i, "pri": 10.0, "pos": tour[i][0], "dist": tour[i][1], "pitch": tour[i][2], "tour": true})
    return out

## L34 (Mr. E's recordings: "the top left screen goes black or stays stuck when someone dies"):
## when the subject dies, rerolls or despawns, _best() can come back EMPTY for a tick. The old
## code returned, which left the eye parked exactly where it was - and the director pane, which
## copies the eye, showed a frozen frame (or a black void, the camera left inside geometry).
## So there is always a shot: step the town tour on and take the next stop.
func _fallback_shot(avoid: String = "") -> Dictionary:
    var tour := tour_stops()
    if tour.is_empty():
        return {}
    _tour_i += 1
    var s: Dictionary = tour[_tour_i % tour.size()]
    if avoid != "" and String(s.get("key", "")) == avoid and tour.size() > 1:
        _tour_i += 1
        s = tour[_tour_i % tour.size()]
    return s

## every shot worth showing right now, best first; `avoid` skips one story
func _best(avoid: String = "") -> Dictionary:
    _held_now = lane_held()
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
        # L24: the fight seen through a delver no spotlight lane already holds
        var body: Node3D = alive[0]["body"]
        for m in alive:
            if not _held_now.has(m["body"]):
                body = m["body"]
                break
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
    # 5. viewers' heroes about town - L18: the freshest chatter first (36-50: ahead of a
    # random hero, behind raids, lords and fights), then anyone at random
    var hs: Dictionary = town.get("heroes")
    var fresh := ""
    var fresh_ago := CHAT_FRESH_S
    for uid in hs:
        var ago := ChatCmd.since_cmd(String(uid))
        if ago < fresh_ago and is_instance_valid(hs[uid]) and (hs[uid] as Node3D).is_visible_in_tree() and not _held_now.has(hs[uid]):
            fresh = String(uid)
            fresh_ago = ago
    if fresh != "":
        c.append({"key": "chat_%s" % fresh, "pri": 36.0 + 14.0 * (1.0 - fresh_ago / CHAT_FRESH_S),
                  "node": hs[fresh], "dist": 14.0, "pitch": -30.0})
    var ks := hs.keys()
    ks.shuffle()
    for uid in ks:
        var hb = hs[uid]
        if is_instance_valid(hb) and (hb as Node3D).is_visible_in_tree() and not _held_now.has(hb):
            c.append({"key": "hero_%s" % uid, "pri": 30.0 + _rng.randf() * 5.0,
                      "node": hb, "dist": 14.0, "pitch": -30.0})
            break
    # 6. the town itself: a slow tour of its best views
    var tour := tour_stops()
    c.append(tour[_tour_i % tour.size()])
    if _cur.get("tour", false) and _held >= HOLD_MAX:
        _tour_i += 1
    var best := {}
    for s in c:
        if String(s["key"]) == avoid:
            continue
        if _lane_owns(s):
            continue                            # L24: never the hero a lane already shows
        if best.is_empty() or float(s["pri"]) > float(best["pri"]):
            best = s
    return best
