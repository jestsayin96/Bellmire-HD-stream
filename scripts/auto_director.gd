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

const HOLD_MIN := 8.0           # fallback when a shot names no type
const HOLD_MAX := 22.0
## L64.2 SHOT LANGUAGE: a named shot carries its own hold window (seconds, before the pace factor)
const SHOTS := {
    "establishing": {"min": 12.0, "max": 30.0},    # the town / valley wide
    "push": {"min": 10.0, "max": 24.0},            # slow push-in on a quiet beat
    "follow": {"min": 8.0, "max": 18.0},           # tail a hero
    "shoulder": {"min": 6.0, "max": 16.0},         # over-the-shoulder on a fight, a lord, a raid
    "hard_cut": {"min": 4.0, "max": 7.0},          # a death: cut, hold, go
    "breath": {"min": 4.0, "max": 7.0},            # L73: the quiet after a death or a beat that resolved
}
## L73 SHOT LANGUAGE (sits on _pace - no second knob): establish -> tighten -> hold -> breathe
const ESTABLISH_K := 1.7        # a delve's first look opens this much wider than its follow distance ...
const ESTABLISH_PITCH := -44.0  # ... and lower, then settles in (ease, T seconds)
const ESTABLISH_T := 6.0
const ESTABLISH_BONUS := 10.0   # a delve that has just set out is worth showing
const TIGHTEN_MAX := 0.38       # a fight at death's door sits this fraction closer than a fresh one
const DEATH_FROM := 16.0        # the death hold creeps in slowly from here ...
const DEATH_TO := 12.0
const BREATH_FROM := 14.0       # ... and the beat of quiet after it eases back out from the same spot
const BREATH_TO := 30.0
## L64.3: no subject comes back inside this window (stories at or above STORY_PRI are exempt - a
## raid or a lord rising is never withheld from the viewer)
const REPEAT_WINDOW := 90.0
const STORY_PRI := 90.0
const SAME_SHOT_PENALTY := 6.0
const DEATH_TTL := 7.0
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
var _tour_seen := {}            # L64.3: tour stop key -> director clock of its last cut (oldest is shown next)
var _rng := RandomNumberGenerator.new()
var _clock := 0.0               # real seconds the director has been on
var _pace := 1.0                # L64.3: 0.6 in a raid (faster cuts), 1.4 in a quiet stretch (calmer holds)
var _mem: Array = []            # L64.3 anti-repetition: [{key, shot, t}] of recent cuts
var _last_shot := ""
var _raid_i := 0
var _alive_n: Dictionary = {}   # delve id -> delvers alive last tick (a drop is a death)
var _last_pos: Dictionary = {}
var _deaths: Array = []         # [{key, pos, t}] fresh deaths the director may cut to
var _cands: Array = []          # L64.1: every scored candidate of the last _best() pass
## L72: a lord is framed by its MEASURED mesh bounds (height AND width), and the camera eases out to
## that frame as the lord rises - a move, not a cut. No table of names: the next lord frames itself.
const FIT_MARGIN := 1.18        # every bound point sits inside the frame shrunk by this factor
const FIT_TOP := 0.7            # the subject keeps out of the very top of the frame (the boss bar sits there); 0.5 framed the lords too small to read
const FIT_D_MIN := 8.0
const FIT_D_MAX := 90.0
const FIT_PITCHES := [-55.0, -62.0, -69.0, -76.0]    # steeper only when the room cannot hold the camera
const ROOM_SLACK := 3          # cells (4 m each) the camera may stand out from the nearest open cell, high over the walls
const REVEAL_T := 4.5           # s the pull-back takes
const REVEAL_START := 0.42      # the reveal opens this fraction of the full distance (a close, low look)
const REVEAL_PITCH := -36.0     # ... and tilts up to the fitted pitch as it goes
var _fit_want := 0.0
var _fit_cur := 0.0
var _fit_pitch := -55.0
var _fit_clock := 0.0
var _reveal_t := 0.0
var _reveal_from := 0.0
var _arc_t := 0.0               # L73: seconds into the current shot's ease
var _cur_pos := Vector3.ZERO    # where the shot on screen is looking (a breath opens from here)
var _cur_listed := true         # was the shot on screen still a candidate at the last full scoring pass
var _delve_seen := {}           # delve id -> true once the director has shown it setting out
var log_path := "user://director.log"
var log_lines: Array = []       # the same lines, kept in memory for tests

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
    _clock += real
    if _paused_for > 0.0:
        _paused_for -= real
        if _paused_for <= 0.0:
            eye.quiet = true
            _cur = {}
        return
    _held += real
    if _cur.get("tour", false):
        eye.yaw += 0.06 * real                  # idle shots drift slowly round
    if _cur.get("fit", false):
        _fit_tick(real)
    if _cur.has("node") and is_instance_valid(_cur["node"]):
        _cur_pos = (_cur["node"] as Node3D).global_position
    elif _cur.has("pos"):
        _cur_pos = _cur["pos"]
    _arc_tick(real)
    if String(_cur.get("shot", "")) == "push":
        # L64.2: a slow push - it closes ~25% of its starting distance over its max hold
        eye.dist = maxf(eye.dist - float(_cur.get("dist", 34.0)) * 0.25 / _hold_max(_cur) * real, 6.0)
    _tick -= real
    if _tick > 0.0:
        return
    _tick = 1.0
    _scan_deaths()
    var best := _best()
    _cur_listed = false
    for cc in _cands:
        if String(cc["key"]) == String(_cur.get("key", "")):
            _cur_listed = true
            break
    if best.is_empty():
        # L34(a): no candidate scored this tick. The old code returned here, which left
        # the eye parked on whatever it was already following - and if THAT subject had
        # just died, rerolled or vanished, the top-left pane froze on a dead body: the
        # death check below never ran. So if the shot on screen is no longer alive, cut
        # to a live fallback instead of holding a stale frame.
        if not _shot_alive(_cur):
            var fb := _fallback_shot()
            if not fb.is_empty():
                _cut(fb)
        return
    var cur_pri := float(_cur.get("pri", -1.0))
    var cur_alive := _shot_alive(_cur)
    var cut := false
    var why := ""
    if _cur.is_empty() or not cur_alive:
        cut = true
    elif _lane_owns(_cur) and best["key"] != _cur["key"]:
        cut = true                              # L24: a lane holds this hero now - the split would show it twice
        why = "lane_owns"
    elif best["key"] == _cur["key"]:
        _cur["pri"] = best["pri"]               # same story, keep watching
        _cur["hurt"] = best.get("hurt", 0.0)    # L73: a fight that is turning draws the camera in
        if _held >= _hold_max(_cur):
            cut = true
            why = "max_hold"
    elif String(best["key"]).begins_with("lord_") and not String(_cur["key"]).begins_with("lord_"):
        cut = true                              # a lord has risen: go now
        why = "lord_rises"
    elif String(best.get("shot", "")) == "hard_cut" and String(_cur.get("shot", "")) != "hard_cut":
        cut = true                              # L64.2: a death is a hard cut, at once
        why = "death"
    elif String(_cur.get("shot", "")) in ["hard_cut", "breath"] and _held < _hold_min(_cur):
        pass                                    # L73: hold on a death; let the quiet after it be quiet
    elif _beat_open(_cur) and _held < _hold_max(_cur):
        pass                                    # L64.3: never cut inside a beat that has not resolved
    elif float(best["pri"]) >= cur_pri + 20.0 and _held >= minf(2.0, _hold_min(_cur)):
        cut = true                              # something much hotter
        why = "hotter"
    elif _held >= _hold_min(_cur) and float(best["pri"]) > cur_pri:
        cut = true
        why = "better_after_min"
    elif _held >= _hold_max(_cur):
        cut = true                              # quiet too long: move on
        why = "max_hold"
    if cut:
        if _cur.is_empty() or not cur_alive:
            why = "start" if _cur.is_empty() else "shot_gone"
        if _held >= _hold_max(_cur) and best["key"] == _cur.get("key", ""):
            var alt := _best(String(_cur.get("key", "")))      # something different
            if alt.is_empty():
                alt = _fallback_shot(String(_cur.get("key", "")))
            if not alt.is_empty():          # L34: nothing else to show - re-cut, never return
                best = alt
        if _beat_ended() and float(best["pri"]) < STORY_PRI:
            best = _breath_shot()               # L73: a beat of quiet after a death or a resolved fight/lord
            why = "breath"
        _cut(best, why)

## ---- L64.2/.3 helpers
func _pm(s: Dictionary) -> Dictionary:
    return SHOTS.get(String(s.get("shot", "")), {"min": HOLD_MIN, "max": HOLD_MAX})

func _hold_min(s: Dictionary) -> float:
    return float(_pm(s)["min"]) * _pace

func _hold_max(s: Dictionary) -> float:
    return float(_pm(s)["max"]) * _pace

## a beat is open while its subject is still alive: a raid in progress, a lord on its floor,
## a fight below. The director rides it out (up to the shot's max) instead of cutting for a
## marginally better candidate.
func _beat_open(s: Dictionary) -> bool:
    if s.is_empty():
        return false
    var k := String(s.get("key", ""))
    if k == "raid" or k.begins_with("lord_") or k.begins_with("fight_"):
        return _shot_alive(s)
    return false

## a delve whose live-delver count drops has had a death: remember where, for a hard cut
func _scan_deaths() -> void:
    for d in town.get_children():
        if not (d is Delve) or (d as Delve).dun == null or not is_instance_valid((d as Delve).dun):
            continue
        var id := d.get_instance_id()
        var alive: Array = (d as Delve)._alive()
        var n := alive.size()
        if _alive_n.has(id) and n < int(_alive_n[id]) and _last_pos.has(id):
            _deaths.append({"key": "death_%d_%d" % [id, int(_clock)], "pos": _last_pos[id], "t": _clock})
        _alive_n[id] = n
        if n > 0 and is_instance_valid(alive[0]["body"]):
            _last_pos[id] = (alive[0]["body"] as Node3D).global_position
    var keep: Array = []
    for e in _deaths:
        if _clock - float(e["t"]) < DEATH_TTL:
            keep.append(e)
    _deaths = keep

func _recent(key: String) -> bool:
    for m in _mem:
        if String(m["key"]) == key and _clock - float(m["t"]) < REPEAT_WINDOW:
            return true
    return false

## L64.1: one readable line per cut - what was chosen, why, and what it beat
func _log_cut(s: Dictionary, why: String) -> void:
    var parts: Array = []
    var sorted := _cands.duplicate()
    sorted.sort_custom(func(a, b): return float(a["pri"]) > float(b["pri"]))
    for c in sorted.slice(0, 5):
        parts.append("%s/%s=%.1f%s" % [c["key"], c.get("shot", "?"), float(c["pri"]), "" if not c.has("note") else "(" + String(c["note"]) + ")"])
    var line := "t=%.1f CUT %s shot=%s pri=%.1f why=%s held_prev=%.1f pace=%.1f | %s" % [_clock, s["key"], s.get("shot", "?"), float(s["pri"]), why, _held, _pace, ", ".join(parts)]
    log_lines.append(line)
    print("DIRECTOR ", line)
    var f := FileAccess.open(log_path, FileAccess.READ_WRITE if FileAccess.file_exists(log_path) else FileAccess.WRITE)
    if f:
        f.seek_end()
        f.store_line(line)
        f.close()

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

func _cut(s: Dictionary, why: String = "") -> void:
    _log_cut(s, why)
    if s.has("delve_id"):
        _delve_seen[s["delve_id"]] = true
    _mem.append({"key": String(s["key"]), "shot": String(s.get("shot", "")), "t": _clock})
    var m2: Array = []
    for m in _mem:
        if _clock - float(m["t"]) < REPEAT_WINDOW:
            m2.append(m)
    _mem = m2
    if s.get("tour", false):
        _tour_seen[String(s["key"])] = _clock
    _last_shot = String(s.get("shot", ""))
    _cur = s
    _held = 0.0
    eye.pitch = deg_to_rad(float(s.get("pitch", -45.0)))
    if s.has("node") and is_instance_valid(s["node"]):
        eye._delve_i = -1
        eye._select(s["node"])
        eye._following = true
        eye.focus = (s["node"] as Node3D).global_position
        eye.dist = float(s.get("dist", 22.0))
        if s.get("fit", false):
            _begin_reveal(s["node"] as Node3D)
    else:
        eye._select(null)
        eye._jump(s["pos"], float(s.get("dist", 34.0)))
    _arc_t = 0.0
    if s.has("from_d"):
        eye.dist = float(s["from_d"])           # L73: the shot opens off its resting frame and eases into it
    if s.has("from_pitch"):
        eye.pitch = deg_to_rad(float(s["from_pitch"]))

## L73: the shot's own ease - establish (wide and low, settling), the death creep, the breath's
## pull-out - and the fight's tighten, which follows how hurt the party is
func _arc_tick(real: float) -> void:
    var arc := String(_cur.get("arc", ""))
    if arc == "":
        return
    if arc == "tighten":
        if _cur.has("from_pitch"):              # a delve's first look is a fight: it opens wide and low, then closes
            _arc_t += real
            var kp := clampf(_arc_t / ESTABLISH_T, 0.0, 1.0)
            kp = kp * kp * (3.0 - 2.0 * kp)
            eye.pitch = lerpf(deg_to_rad(float(_cur["from_pitch"])), deg_to_rad(float(_cur.get("pitch", -60.0))), kp)
        var want := float(_cur.get("dist", 20.0)) * (1.0 - TIGHTEN_MAX * clampf(float(_cur.get("hurt", 0.0)), 0.0, 1.0))
        eye.dist = lerpf(eye.dist, want, clampf(real * (0.5 if not _cur.has("from_d") else 0.35), 0.0, 1.0))
        return
    _arc_t += real
    var k := clampf(_arc_t / maxf(float(_cur.get("T", 6.0)), 0.1), 0.0, 1.0)
    k = k * k * (3.0 - 2.0 * k)
    eye.dist = lerpf(float(_cur.get("from_d", _cur.get("dist", 22.0))), float(_cur.get("to", _cur.get("dist", 22.0))), k)
    if _cur.has("from_pitch"):
        eye.pitch = lerpf(deg_to_rad(float(_cur["from_pitch"])), deg_to_rad(float(_cur.get("pitch", -55.0))), k)

## the shot on screen was a beat that has now resolved: a death held out, a fight or a lord that is over
func _beat_ended() -> bool:
    if _cur.is_empty():
        return false
    var pk := String(_cur.get("key", ""))
    if String(_cur.get("shot", "")) == "hard_cut":
        return true
    return (pk.begins_with("lord_") or pk.begins_with("fight_")) and (not _shot_alive(_cur) or not _cur_listed)

## the quiet after: ease back out from where the beat ended, then the director goes on
func _breath_shot() -> Dictionary:
    return {"key": "breath_%d" % int(_clock), "shot": "breath", "pri": 20.0, "pos": _cur_pos, "dist": BREATH_FROM, "pitch": -52.0,
            "note": "breath", "arc": "ease", "from_d": BREATH_FROM, "to": BREATH_TO, "T": _hold_max({"shot": "breath"})}

## L72: the floor's lord while it is still climbing out of the ground (lord_fighting() is null until it is up)
func _lord_rising(d: Delve) -> Monster:
    if d.state != "fight" or d.dun == null or not is_instance_valid(d.dun) or d._alive().is_empty():
        return null
    var l = d.dun.lord
    if l == null or not is_instance_valid(l) or not (l is Monster):
        return null
    var m := l as Monster
    if m.state == Monster.S.DEAD or m._body == null or not m._entering() or not m.is_visible_in_tree():
        return null
    return m

## ---- L72: frame a big subject by what it measures
## every corner of every visible mesh under the subject's body, in world space, plus the floor it
## stands on (so "the whole lord and the ground under it" is what the frame must hold)
func subject_points(n: Node3D) -> PackedVector3Array:
    var out := PackedVector3Array()
    var top: Node = n.get("_body") if n is Monster else n
    if top == null:
        top = n
    var st: Array = [top]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is MeshInstance3D and (c as MeshInstance3D).visible and (c as MeshInstance3D).mesh and (c as MeshInstance3D).is_inside_tree():
            var mi := c as MeshInstance3D
            var ab := mi.get_aabb()
            for i in 8:
                out.append(mi.global_transform * ab.get_endpoint(i))
        for g in c.get_children():
            if not g is HealthBar3D:
                st.append(g)
    var gy := eye._ground(n.global_position)
    if out.is_empty():
        var h := float(n.get("def").get("h", 2.0)) if n.get("def") is Dictionary else 2.0
        for dx in [-1.0, 1.0]:
            for dz in [-1.0, 1.0]:
                out.append(n.global_position + Vector3(dx * h * 0.5, 0, dz * h * 0.5))
                out.append(n.global_position + Vector3(dx * h * 0.5, h, dz * h * 0.5))
    for i in out.size():
        var q: Vector3 = out[i]
        q.y = maxf(q.y, gy)
        out[i] = q                              # a lord still climbing out of the floor is framed from the floor up
    var lo := out[0]
    var hi := out[0]
    for p in out:
        lo = Vector3(minf(lo.x, p.x), minf(lo.y, p.y), minf(lo.z, p.z))
        hi = Vector3(maxf(hi.x, p.x), maxf(hi.y, p.y), maxf(hi.z, p.z))
    for x in [lo.x, hi.x]:
        for z in [lo.z, hi.z]:
            out.append(Vector3(x, gy, z))
    return out

## the extent of the subject, metres: x width, y height above the floor, z depth
func subject_size(n: Node3D) -> Vector3:
    var pts := subject_points(n)
    var lo := pts[0]
    var hi := pts[0]
    for p in pts:
        lo = Vector3(minf(lo.x, p.x), minf(lo.y, p.y), minf(lo.z, p.z))
        hi = Vector3(maxf(hi.x, p.x), maxf(hi.y, p.y), maxf(hi.z, p.z))
    return hi - lo

func _cam_off(yaw: float, pitch: float, d: float) -> Vector3:
    return Vector3(sin(yaw) * cos(pitch), -sin(pitch), cos(yaw) * cos(pitch)) * d

## do all points sit inside the frame (shrunk by FIT_MARGIN) of a camera `d` out on (yaw, pitch)?
func _fits(pts: PackedVector3Array, pivot: Vector3, yaw: float, pitch: float, d: float, th: float, tw: float) -> bool:
    var cp := pivot + _cam_off(yaw, pitch, d)
    var fwd := (pivot - cp).normalized()
    var right := fwd.cross(Vector3.UP).normalized()
    var up := right.cross(fwd)
    for p in pts:
        var v := p - cp
        var z := v.dot(fwd)
        if z < 1.0:
            return false
        var vy := v.dot(up)
        if absf(v.dot(right)) > z * tw / FIT_MARGIN or vy < -z * th / FIT_MARGIN or vy > z * th * FIT_TOP / FIT_MARGIN:
            return false
    return true

## the nearest distance at which the whole subject fits, on this pitch
func _fit_dist(pts: PackedVector3Array, pivot: Vector3, yaw: float, pitch: float, th: float, tw: float) -> float:
    var lo := FIT_D_MIN
    var hi := FIT_D_MAX
    if _fits(pts, pivot, yaw, pitch, lo, th, tw):
        return lo
    for i in 26:
        var mid := (lo + hi) * 0.5
        if _fits(pts, pivot, yaw, pitch, mid, th, tw):
            hi = mid
        else:
            lo = mid
    return hi

## the camera must sit over the room: above the wall tops, and not out over the void. Else steepen.
func _room_ok(n: Node3D, focus: Vector3, yaw: float, pitch: float, d: float) -> bool:
    var cp := focus + _cam_off(yaw, pitch, d)
    if focus.y > Delve.DELVE_Y * 0.5:
        return true                                     # the valley: nothing to clamp to
    if cp.y - focus.y < RtsCamera.DUN_WALL_TOP + 1.0:
        return false
    var dl: Delve = eye._delve_at(focus)
    if dl == null or dl.dun == null:
        return true
    var cells: Dictionary = dl.dun.info["cells"]
    var c0: Vector2i = dl._cell_of(cp)
    for dx in range(-ROOM_SLACK, ROOM_SLACK + 1):
        for dz in range(-ROOM_SLACK, ROOM_SLACK + 1):
            if cells.has(c0 + Vector2i(dx, dz)):
                return true
    return false

## the frame for a subject: {dist, pitch (deg)}. Height and width both count (the Grubmother is
## 8.3 m wide and 4.5 m tall). Steepens the pitch when the room cannot hold the camera.
func fit_shot(n: Node3D, yaw: float) -> Dictionary:
    var pts := subject_points(n)
    var focus := Vector3(n.global_position.x, eye._ground(n.global_position), n.global_position.z)
    var pivot := focus + Vector3(0, 1.0, 0)
    var th := tan(deg_to_rad(eye.cam.fov) * 0.5)
    var tw := th * eye._aspect()
    var res := {}
    for pd in FIT_PITCHES:
        var d := _fit_dist(pts, pivot, yaw, deg_to_rad(float(pd)), th, tw)
        res = {"dist": d, "pitch": float(pd)}
        if _room_ok(n, focus, yaw, deg_to_rad(float(pd)), d):
            break
    return res

func _begin_reveal(n: Node3D) -> void:
    var f := fit_shot(n, eye.yaw)
    _fit_want = float(f["dist"])
    _fit_cur = _fit_want
    _fit_pitch = float(f["pitch"])
    _fit_clock = 0.5
    _reveal_t = 0.0
    _reveal_from = maxf(_fit_cur * REVEAL_START, 9.0)
    eye.dist = _reveal_from
    eye.pitch = deg_to_rad(REVEAL_PITCH)

## the pull-back: the camera eases from a close, low look at the lord out to the whole of it
func _fit_tick(real: float) -> void:
    if not (_cur.has("node") and is_instance_valid(_cur["node"])):
        return
    _fit_clock -= real
    if _fit_clock <= 0.0:
        _fit_clock = 0.25
        var f := fit_shot(_cur["node"] as Node3D, eye.yaw)       # the lord moves and breathes: keep it framed
        _fit_want = float(f["dist"])
        _fit_pitch = float(f["pitch"])
    _fit_cur = lerpf(_fit_cur, _fit_want, clampf(real * 1.2, 0.0, 1.0))
    _reveal_t = minf(_reveal_t + real, REVEAL_T)
    var k := _reveal_t / REVEAL_T
    k = k * k * (3.0 - 2.0 * k)                                  # smoothstep: eases out of the start AND into the frame
    eye.dist = lerpf(_reveal_from, _fit_cur, k)
    eye.pitch = lerpf(deg_to_rad(REVEAL_PITCH), deg_to_rad(_fit_pitch), k)

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
    var mp = town.get("_market_pos")
    var tour: Array = [[mp if mp != null else Vector3.ZERO, 38.0, -42.0]]
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
        out.append({"key": "tour_%d" % i, "pri": 10.0, "pos": tour[i][0], "dist": tour[i][1], "pitch": tour[i][2], "tour": true,
                    "shot": "establishing" if float(tour[i][1]) >= 100.0 else "push", "note": "quiet baseline"})
    return out

## L34(a): a shot that is ALWAYS available - the next stop on the town tour. The director
## falls back to this whenever scoring comes back empty (every candidate avoided, lane-held
## or dead), so it always has somewhere live to point. It rotates, so two empty ticks running
## do not re-pick the same view.
func _fallback_shot(avoid: String = "") -> Dictionary:
    return _tour_pick(avoid)

## L64.3: the tour is a set of PLACES, so the anti-repeat memory is a lap: always the stop that was
## shown longest ago (never one cut a moment ago), the current stop excluded.
func _tour_pick(avoid: String = "") -> Dictionary:
    var tour := tour_stops()
    if tour.is_empty():
        return {}
    var best := {}
    var best_t := INF
    for i in tour.size():
        var s: Dictionary = tour[(_tour_i + i) % tour.size()]
        if String(s["key"]) == avoid:
            continue
        var t := float(_tour_seen.get(String(s["key"]), -1.0e9))
        if t < best_t:
            best_t = t
            best = s
    if not best.is_empty():
        _tour_i = (_tour_i + 1) % tour.size()
    return best

## every shot worth showing right now, best first; `avoid` skips one story
func _best(avoid: String = "") -> Dictionary:
    _held_now = lane_held()
    var c: Array = []
    # 1. a raid on Bellmire
    var rd = town.get("raids")
    if rd and bool(rd.get("_live")):
        var rn: Array = []
        for r in rd.get("raiders"):
            var n = r.get("node") if r is Dictionary else null
            if n and is_instance_valid(n):
                rn.append(n)
        if not rn.is_empty():
            # a different raider each cut, so a raid is covered from more than one spot
            c.append({"key": "raid", "shot": "shoulder", "pri": 95.0, "node": rn[_raid_i % rn.size()], "dist": 30.0, "pitch": -40.0, "note": "raid live"})
    # 2-3. delves below: fights first, then the walk between them
    for d in town.get_children():
        if not (d is Delve) or (d as Delve).dun == null or not is_instance_valid((d as Delve).dun):
            continue
        var alive: Array = (d as Delve)._alive()
        if alive.is_empty():
            _delve_seen.erase(d.get_instance_id())
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
            _delve_seen.erase(d.get_instance_id())
            continue
        var viewers := 0.0 if (d as Delve).npc_party else 10.0
        var lord: Monster = (d as Delve).lord_fighting()
        if lord == null:
            lord = _lord_rising(d as Delve)         # L72: the camera is there as the lord RISES, not after
        if lord:
            # a lord on its floor is the event of the night: nothing outranks it
            var lh := float(lord.def.get("h", 5.0))
            c.append({"key": "lord_%d" % d.get_instance_id(), "pri": 100.0 + viewers * 0.1,
                      "node": lord, "dist": clampf(12.0 + lh * 2.2, 20.0, 42.0), "pitch": -55.0, "shot": "shoulder", "note": "lord", "fit": true})
        if st == "fight":
            var fc := {"key": "fight_%d" % d.get_instance_id(), "pri": 75.0 + viewers + hurt * 10.0,
                       "node": body, "dist": 20.0, "pitch": -60.0, "shot": "shoulder", "note": "hurt %.2f" % hurt,
                       "arc": "tighten", "hurt": hurt, "delve_id": d.get_instance_id()}
            if not _delve_seen.has(d.get_instance_id()):
                # L73: ESTABLISH - a delve's first look (it opens on a fight) is wide and low, then closes in
                fc["note"] = "delve start hurt %.2f" % hurt
                fc["from_d"] = 20.0 * ESTABLISH_K
                fc["from_pitch"] = ESTABLISH_PITCH
            c.append(fc)
        else:
            var fresh_out := not _delve_seen.has(d.get_instance_id())
            var dc := {"key": "delve_%d" % d.get_instance_id(), "pri": 45.0 + viewers + (ESTABLISH_BONUS if fresh_out else 0.0),
                       "node": body, "dist": 22.0, "pitch": -62.0, "shot": "follow", "note": "walking", "delve_id": d.get_instance_id()}
            if fresh_out:
                # L73: ESTABLISH - a delve setting out is shown wide and low first, then settles to its follow
                dc["note"] = "delve start"
                dc["arc"] = "ease"
                dc["from_d"] = 22.0 * ESTABLISH_K
                dc["to"] = 22.0
                dc["from_pitch"] = ESTABLISH_PITCH
                dc["T"] = ESTABLISH_T
            c.append(dc)
    # 4. a catch coming in on the docks
    for a in town.get("anglers"):
        if is_instance_valid(a) and (a.state == Angler.S.REEL or a.state == Angler.S.SHOW or a.state == Angler.S.BITE):
            c.append({"key": "fish_%d" % a.get_instance_id(), "pri": 60.0,
                      "node": a.get_parent(), "dist": 12.0, "pitch": -28.0, "shot": "follow", "note": "catch"})
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
                  "node": hs[fresh], "dist": 14.0, "pitch": -30.0, "shot": "follow", "note": "chat %ds ago" % int(fresh_ago)})
    var ks := hs.keys()
    ks.shuffle()
    for uid in ks:
        var hb = hs[uid]
        if is_instance_valid(hb) and (hb as Node3D).is_visible_in_tree() and not _held_now.has(hb):
            c.append({"key": "hero_%s" % uid, "pri": 30.0 + _rng.randf() * 5.0,
                      "node": hb, "dist": 14.0, "pitch": -30.0, "shot": "follow", "note": "town life"})
            break
    # 5b. L64.2: a delver just fell - hard cut to where it happened
    for e in _deaths:
        c.append({"key": String(e["key"]), "shot": "hard_cut", "pri": 90.0, "pos": e["pos"], "dist": DEATH_FROM, "pitch": -50.0, "note": "death",
                  "arc": "ease", "from_d": DEATH_FROM, "to": DEATH_TO, "T": _hold_min({"shot": "hard_cut"}) + 1.0})
    # 6. the town itself: a slow tour of its best views
    var tp := _tour_pick(String(_cur.get("key", "")) if _cur.get("tour", false) else "")
    if not tp.is_empty():
        c.append(tp)
    # L64.1/.3: score, with the reason for every adjustment kept in the note so the log explains it
    var hottest := 0.0
    for s in c:
        hottest = maxf(hottest, float(s["pri"]) if not s.get("tour", false) else 0.0)
    _pace = 0.6 if (rd and bool(rd.get("_live"))) else (1.4 if hottest < 45.0 else 1.0)
    _cands = []
    var best := {}
    for s in c:
        if String(s["key"]) == avoid:
            continue
        if _lane_owns(s):
            continue                            # L24: never the hero a lane already shows
        s = s.duplicate()
        var k := String(s["key"])
        var is_cur := String(_cur.get("key", "")) == k
        var estab := String(s.get("note", "")).begins_with("delve start")      # L73: a delve setting out is never withheld
        if not is_cur and not estab and float(s["pri"]) < STORY_PRI and _recent(k):
            s["note"] = String(s.get("note", "")) + " REPEAT-held-out"
            _cands.append(s)
            continue                            # no subject comes back inside the window
        if not is_cur and not estab and String(s.get("shot", "")) == _last_shot and float(s["pri"]) < STORY_PRI:
            s["pri"] = float(s["pri"]) - SAME_SHOT_PENALTY
            s["note"] = String(s.get("note", "")) + " same-shot-%.0f" % SAME_SHOT_PENALTY
        _cands.append(s)
        if best.is_empty() or float(s["pri"]) > float(best["pri"]):
            best = s
    if not best.is_empty() and best["key"] == "raid" and String(_cur.get("key", "")) != "raid":
        _raid_i += 1
    if best.is_empty():
        # L34(a): the avoid-filter or L24 lane-ownership removed every candidate. Never
        # hand back an empty shot - the caller would freeze on its current subject.
        best = _fallback_shot(avoid)
    return best
