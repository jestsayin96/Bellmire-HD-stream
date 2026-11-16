extends SceneTree
## L56 DELVE-HEAVY SOAK. The D28 census could not trust its boss or trap counts:
## raids kept pulling parties back to town and only ~1 sustained descent happened,
## so the dungeon-side counters undercounted. This harness removes ONLY that
## interruption and reads Delve.trap_log directly.
##
## RUN 2 - THE INSTRUMENT WAS THE FAULT, NOT L45/L46. Run 1 polled town.get("delve"),
## which is ONLY the viewer party's delve (town.gd:5353, nulled at 5413).
## adventurers.gd:248 gives every NPC band its OWN Delve.new(), and trap_log is
## per-instance (delve.gd:2545) - so run 1 was blind to every trap and boss an NPC
## party met, and printed zeros while the feed showed a fire grate spotted.
## Both kinds are add_child'd to town, so run 2 ENUMERATES every live Delve child
## and keeps the LATEST trap_log per instance_id. trap_log only ever climbs, so the
## sum of the final per-instance readings is the true total, and an instance that
## ends keeps the last reading taken before it was freed.
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
# traps, per Delve instance_id -> latest trap_log reading (cumulative, so the
# final reading per instance is that instance's total). Survives the instance.
var _trap_by_id := {}
var _kind_by_id := {}            # instance_id -> "viewer" | "npc"
var _ids_seen := {}              # instance_id -> frames polled
var TRAP_KEYS := ["spotted","disarmed","sprung","saved","damage","venomed","swarms"]
# depth + bosses
var _deepest := 0
var _floor_hits := {}            # floor_no -> frames seen (descent sustain), any party
var _floor_hits_by_id := {}      # instance_id -> {floor_no: frames} (sustain per party)
var bosses_seen := {}
var bosses_killed := 0
var _lord_by_id := {}            # instance_id -> last lord seen (for the kill edge)
var _lord_names_by_id := {}      # instance_id -> {name: true}

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

func _delves() -> Array:
    ## EVERY live Delve, the viewer's and every NPC band's. Both are add_child'd
    ## to town, so the children are the whole population.
    var out: Array = []
    for c in _t.get_children():
        if c is Delve:
            out.append(c)
    return out

func _poll_delve() -> void:
    for d in _delves():
        var id: int = d.get_instance_id()
        _ids_seen[id] = int(_ids_seen.get(id, 0)) + 1
        if not _kind_by_id.has(id):
            _kind_by_id[id] = "npc" if bool(d.npc_party) else "viewer"
        # trap_log only climbs, so the latest reading IS this instance's total
        if "trap_log" in d:
            _trap_by_id[id] = (d.trap_log as Dictionary).duplicate()
        if "floor_no" in d:
            var fl := int(d.floor_no)
            if fl > 0:
                _deepest = maxi(_deepest, fl)
                _floor_hits[fl] = int(_floor_hits.get(fl, 0)) + 1
                if not _floor_hits_by_id.has(id):
                    _floor_hits_by_id[id] = {}
                var fh: Dictionary = _floor_hits_by_id[id]
                fh[fl] = int(fh.get(fl, 0)) + 1
        _poll_lord(d, id)

func _poll_lord(d, id: int) -> void:
    var lord = null
    if "dun" in d and d.dun != null and "lord" in d.dun:
        lord = d.dun.lord
    var prev = _lord_by_id.get(id)
    if lord != null and is_instance_valid(lord):
        var nm := "a lord"
        if "def" in lord:
            nm = String((lord.def as Dictionary).get("name", "a lord"))
        if lord != prev:
            _credit_kill(prev)
            _lord_by_id[id] = lord
            if not _lord_names_by_id.has(id):
                _lord_names_by_id[id] = {}
            # count a lord MET once per party, not once per frame
            if not (_lord_names_by_id[id] as Dictionary).has(nm):
                (_lord_names_by_id[id] as Dictionary)[nm] = true
                bosses_seen[nm] = int(bosses_seen.get(nm, 0)) + 1
    elif prev != null:
        _credit_kill(prev)
        _lord_by_id[id] = null

func _credit_kill(prev) -> void:
    if prev == null:
        return
    if not is_instance_valid(prev):
        bosses_killed += 1
        return
    if ("hp" in prev) and float(prev.hp) <= 0.0:
        bosses_killed += 1

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
    ## how many distinct floors were actually held, not just touched
    var n := 0
    for k in _floor_hits:
        if int(_floor_hits[k]) >= 30: n += 1
    return n

func _best_sustain() -> int:
    ## the deepest SINGLE party's held-floor count - run 1's "floors held 1-4"
    var best := 0
    for id in _floor_hits_by_id:
        var n := 0
        for k in (_floor_hits_by_id[id] as Dictionary):
            if int((_floor_hits_by_id[id] as Dictionary)[k]) >= 30: n += 1
        best = maxi(best, n)
    return best

func _trap_totals() -> Dictionary:
    var t := {}
    for k in TRAP_KEYS: t[k] = 0.0
    for id in _trap_by_id:
        var tl_i: Dictionary = _trap_by_id[id]
        for k in TRAP_KEYS:
            t[k] = float(t[k]) + float(tl_i.get(k, 0))
    return t

func _trap_totals_for(kind: String) -> Dictionary:
    var t := {}
    for k in TRAP_KEYS: t[k] = 0.0
    for id in _trap_by_id:
        if String(_kind_by_id.get(id, "?")) != kind: continue
        var tl_i: Dictionary = _trap_by_id[id]
        for k in TRAP_KEYS:
            t[k] = float(t[k]) + float(tl_i.get(k, 0))
    return t

func _events(t: Dictionary) -> int:
    return int(float(t["spotted"]) + float(t["sprung"]))

func _finish() -> void:
    var eco = _t.get("economy")
    var raids_n := int((_t.get("raids") as Raids).raids)
    var tl := _trap_totals()
    var tl_v := _trap_totals_for("viewer")
    var tl_n := _trap_totals_for("npc")
    var trap_events := _events(tl)
    var n_viewer := 0
    var n_npc := 0
    for id in _kind_by_id:
        if String(_kind_by_id[id]) == "viewer": n_viewer += 1
        else: n_npc += 1
    print("==================== L56 DELVE SOAK (RUN 2) ====================")
    print("L56 runtime: %d wall-min at %.0fx (game day=%d) descend_lines=%d redelve_cmds=%d" % [_minutes, _scale, eco.day if eco else -1, _descends, _redelves])
    print("L56 RAIDS: raids_fired=%d raid_timer_pushes=%d (0 fired is the point - raids were the census's interruption)" % [raids_n, _raids_suppressed])
    print("L56 DELVES SEEN: %d total = %d viewer + %d npc (run 1 could only see the viewer's one)" % [_kind_by_id.size(), n_viewer, n_npc])
    print("L56 DEPTH: deepest=%d floors_held_any=%d best_party_floors_held=%d floor_frames=%s" % [_deepest, _sustained(), _best_sustain(), str(_floor_hits)])
    print("L56 TRAPS (all delves): spotted=%d disarmed=%d sprung=%d saved=%d damage=%.0f venomed=%d swarms=%d" % [int(tl["spotted"]), int(tl["disarmed"]), int(tl["sprung"]), int(tl["saved"]), float(tl["damage"]), int(tl["venomed"]), int(tl["swarms"])])
    print("L56 TRAPS viewer-only: spotted=%d sprung=%d damage=%.0f  <- all run 1 could ever have counted" % [int(tl_v["spotted"]), int(tl_v["sprung"]), float(tl_v["damage"])])
    print("L56 TRAPS npc-parties: spotted=%d sprung=%d damage=%.0f  <- invisible to run 1" % [int(tl_n["spotted"]), int(tl_n["sprung"]), float(tl_n["damage"])])
    print("L56 BOSSES: distinct=%d killed=%d seen=%s" % [bosses_seen.size(), bosses_killed, str(bosses_seen)])
    print("L56 SETPIECES (static, all instances): %s" % str(Delve.setpieces_fired))
    if trap_events == 0:
        print("L56 VERDICT: TRAPS STILL UNCOUNTED - 0 trap events across %d delve instances in a sustained descent. L45/L46 are NOT cleared and NOT condemned; the harness must go longer before anyone touches them." % _kind_by_id.size())
    elif bosses_seen.is_empty():
        print("L56 VERDICT: TRAPS COUNT (%d events over %d delve instances) but NO lord was met - the trap side of L45/L46 is MEASURABLE, the boss side is not yet." % [trap_events, _kind_by_id.size()])
    else:
        print("L56 VERDICT: COUNTERS LIVE - %d trap events and %d distinct lord(s) over %d delve instances. L45/L46 are measurable." % [trap_events, bosses_seen.size(), _kind_by_id.size()])
    print("L56_SOAK OK")
    print("==================== END L56 ====================")
