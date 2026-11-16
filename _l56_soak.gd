extends SceneTree
## L56 DELVE-HEAVY SOAK. The D28 census could not trust its boss or trap counts:
## raids kept pulling parties back to town and only ~1 sustained descent happened,
## so the dungeon-side counters undercounted. This harness removes ONLY that
## interruption and reads Delve.trap_log directly.
##
## WHAT IT CHANGES, AND WHAT IT DELIBERATELY DOES NOT:
##   - raids are held off (raids._raid_t pushed out every frame). This is the
##     named cause in L56.
##   - a living hero idle in town is sent straight back down, every few seconds
##     instead of the census's 60 s tick.
##   - turn_back_at, oil, max_floors and every other delve dial are LEFT AT CANON.
##     Flattening them would manufacture the descent the run is meant to measure.
## Headless. Env: L56_MIN (wall minutes, default 3), L56_SCALE (time scale, default 8).
var _t: Node3D
var _eye
var _f := 0
var _t0 := 0
var _cmd_ms := 0
var _act_ms := 0
var _seen := 0
var _queue: Array = []
var _minutes := 3
var _scale := 8.0
var V := [["1001","JestFan","knight"],["1002","MossyMage","mage"],["1003","QuietArrow","ranger"],
          ["1004","BigAxe","barbarian"],["1005","DawnCleric","cleric"],["1006","Stabbity","rogue"]]
var _descends := 0
var _redelves := 0
var _raids_suppressed := 0
# traps accumulated across delve instances
var _trap_tot := {"spotted":0,"disarmed":0,"sprung":0,"saved":0,"damage":0.0,"venomed":0,"swarms":0}
var _trap_cur_id := 0
var _trap_cur := {}
# depth + bosses
var _deepest := 0
var _floor_hits := {}            # floor_no -> frames seen (descent sustain)
var bosses_seen := {}
var bosses_killed := 0
var minibosses_seen := {}
var _cur_lord = null

func _initialize() -> void:
    var m := OS.get_environment("L56_MIN")
    if m != "": _minutes = maxi(1, int(m))
    var s := OS.get_environment("L56_SCALE")
    if s != "": _scale = maxf(1.0, float(s))
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    print("L56 start minutes=%d scale=%.0f" % [_minutes, _scale])

func _say(i: int, msg: String) -> void:
    _t.call("chat_line", V[i][0], V[i][1], msg)

func _hold_raids() -> void:
    var rd = _t.get("raids")
    if rd == null: return
    if "_raid_t" in rd and float(rd._raid_t) < 600.0:
        rd._raid_t = 9999.0
        _raids_suppressed += 1

func _act() -> void:
    var r = _t.get("roster")
    var hs: Dictionary = _t.get("heroes")
    for i in V.size():
        var h: Dictionary = r.get_hero(V[i][0])
        if h.is_empty():
            _queue.append([i, "!enlist " + V[i][2]]); continue
        if not bool(h.get("alive", false)):
            _queue.append([i, "!reroll"]); continue
        var b = hs.get(V[i][0])
        if b == null or not is_instance_valid(b): continue
        # in town, idle, not on an errand -> straight back to the mouth
        if (b as HeroBody).visible and (b as HeroBody).errand == "" and (b as HeroBody)._route.is_empty():
            _queue.append([i, "!delve"]); _redelves += 1

func _scan_feed() -> void:
    var feed: Array = _t.get("feed")
    while _seen < feed.size():
        var l := String(feed[_seen]).to_lower()
        if l.contains("into the scar"): _descends += 1
        _seen += 1

func _poll_delve() -> void:
    var d = _t.get("delve")
    if d == null: return
    if "trap_log" in d:
        var id: int = d.get_instance_id()
        if id != _trap_cur_id:
            for k in _trap_cur: _trap_tot[k] = _trap_tot.get(k, 0) + _trap_cur[k]
            _trap_cur_id = id
        _trap_cur = (d.trap_log as Dictionary).duplicate()
    if "floor_no" in d:
        var fl := int(d.floor_no)
        if fl > 0:
            _deepest = maxi(_deepest, fl)
            _floor_hits[fl] = int(_floor_hits.get(fl, 0)) + 1
    var lord = null
    if "dun" in d and d.dun != null and "lord" in d.dun: lord = d.dun.lord
    if lord != null and is_instance_valid(lord):
        var nm := String((lord.def as Dictionary).get("name", "a lord")) if "def" in lord else "a lord"
        if lord != _cur_lord:
            if _cur_lord != null and (not is_instance_valid(_cur_lord) or float(_cur_lord.get("hp")) <= 0.0):
                bosses_killed += 1
            _cur_lord = lord
            bosses_seen[nm] = int(bosses_seen.get(nm, 0)) + 1
    elif _cur_lord != null:
        if not is_instance_valid(_cur_lord) or (("hp" in _cur_lord) and float(_cur_lord.hp) <= 0.0):
            bosses_killed += 1
        _cur_lord = null
    # minibosses, if the delve tracks them by name
    for key in ["mini", "miniboss"]:
        if key in d and d.get(key) != null:
            var mb = d.get(key)
            if is_instance_valid(mb) and "def" in mb:
                var mn := String((mb.def as Dictionary).get("name", "?"))
                minibosses_seen[mn] = int(minibosses_seen.get(mn, 0)) + 1

func _process(dt: float) -> bool:
    _f += 1
    if _f == 20:
        var RtsCam = load("res://scripts/rts_camera.gd")
        _eye = RtsCam.new(); _t.add_child(_eye); _eye.setup(_t)
        for i in V.size(): _queue.append([i, "!enlist " + V[i][2]])
        for i in V.size(): _queue.append([i, "!delve"])
    if _f == 40:
        Engine.time_scale = _scale
        _t0 = Time.get_ticks_msec(); _act_ms = _t0
    if _f < 40: return false
    _hold_raids()
    var now := Time.get_ticks_msec()
    if not _queue.is_empty() and now - _cmd_ms > 900:
        var q: Array = _queue.pop_front(); _say(int(q[0]), String(q[1])); _cmd_ms = now
    if now - _act_ms > 8000:
        _act_ms = now; _act()
    _scan_feed()
    _poll_delve()
    if now - _t0 >= _minutes * 60000:
        _finish()
        return true
    return false

func _sustained() -> int:
    ## how many distinct floors the party actually held, not just touched
    var n := 0
    for k in _floor_hits:
        if int(_floor_hits[k]) >= 30: n += 1
    return n

func _finish() -> void:
    for k in _trap_cur: _trap_tot[k] = _trap_tot.get(k, 0) + _trap_cur[k]
    var eco = _t.get("economy")
    var raids_n := int((_t.get("raids") as Raids).raids)
    var tl := _trap_tot
    var trap_events := int(tl["spotted"]) + int(tl["sprung"])
    print("==================== L56 DELVE SOAK ====================")
    print("L56 runtime: %d wall-min at %.0fx (game day=%d) descend_lines=%d redelve_cmds=%d" % [_minutes, _scale, eco.day if eco else -1, _descends, _redelves])
    print("L56 RAIDS: raids_fired=%d raid_timer_pushes=%d (0 fired is the point - raids were the census's interruption)" % [raids_n, _raids_suppressed])
    print("L56 DEPTH: deepest=%d floors_held=%d floor_frames=%s" % [_deepest, _sustained(), str(_floor_hits)])
    print("L56 TRAPS: spotted=%d disarmed=%d sprung=%d saved=%d damage=%.0f venomed=%d swarms=%d" % [int(tl["spotted"]), int(tl["disarmed"]), int(tl["sprung"]), int(tl["saved"]), float(tl["damage"]), int(tl.get("venomed",0)), int(tl.get("swarms",0))])
    print("L56 BOSSES: distinct=%d killed=%d seen=%s" % [bosses_seen.size(), bosses_killed, str(bosses_seen)])
    print("L56 MINIBOSSES: distinct=%d seen=%s" % [minibosses_seen.size(), str(minibosses_seen)])
    if trap_events == 0:
        print("L56 VERDICT: TRAPS STILL UNCOUNTED - 0 trap events in a sustained descent. L45/L46 are NOT cleared and NOT condemned; the harness must go longer before anyone touches them.")
    elif bosses_seen.is_empty():
        print("L56 VERDICT: traps count (%d events) but NO boss was met - boss side still untrusted." % trap_events)
    else:
        print("L56 VERDICT: COUNTERS LIVE - %d trap events and %d distinct boss(es) in one run. L45/L46 are measurable." % [trap_events, bosses_seen.size()])
    print("L56_SOAK OK")
    print("==================== END L56 ====================")
