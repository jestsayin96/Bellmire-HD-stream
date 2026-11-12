extends SceneTree
## SOAK (finish plan item 8) - FAKE CHAT FEED, nothing is posted anywhere.
## The real town in a real window, RtsCamera with the director on, 4x speed,
## six fake viewers enlisting, delving, fishing, forging and rerolling the dead,
## for SOAK_MIN wall minutes (default 30). One line a minute: FPS min/avg, the
## valley day, people, viewers alive, delves, the director's shot, nodes, memory.
## A frame every 10 minutes to renders/cycles/20261111_soak. Script errors are
## counted from the log by the runner (grep SCRIPT ERROR). Runs headless too
## (no frames then; proc_ms_max is the slowest frame's script time that minute).
var _t: Node3D
var _eye: RtsCamera
var _f := 0
var _t0 := 0
var _min_ms := 0
var _cmd_ms := 0
var _act_ms := 0
var _seen := 0
var _queue: Array = []
var _fps: Array = []
var _all_fps: Array = []
var _acc := 0.0
var _shots := 0
var _minutes := 30
var _proc_max := 0.0
var _stats := {"descend": 0, "home": 0, "wiped": 0, "viewer_dead": 0, "caught": 0, "rerolls": 0, "cmds": 0}
# D15 sound soak: audio snapshot state
var _aud_prev := 0
var _aud_prev_kinds := {}
var _aud_busiest := 0
var _aud_pool_max := 0
var _aud_flat_max := 0
var _cuts := {}
var _last_cut := ""
var V := [["1001", "JestFan", "knight"], ["1002", "MossyMage", "mage"], ["1003", "QuietArrow", "ranger"],
          ["1004", "BigAxe", "barbarian"], ["1005", "DawnCleric", "cleric"], ["1006", "Stabbity", "rogue"]]
var OUT := "res://renders/cycles/20261111_soak"

func _initialize() -> void:
    var m := OS.get_environment("SOAK_MIN")
    if m != "":
        _minutes = maxi(1, int(m))
    var o := OS.get_environment("SOAK_OUT")
    if o != "":
        OUT = o
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    # an early end with no "SOAK done" line: was the window closed by hand?
    root.close_requested.connect(func() -> void:
        print("SOAK window close requested at %d s" % ((Time.get_ticks_msec() - _t0) / 1000)))
    print("SOAK start minutes=%d" % _minutes)

func _finalize() -> void:
    print("SOAK finalize at %d s" % ((Time.get_ticks_msec() - _t0) / 1000))

func _say(i: int, msg: String) -> void:
    var v: Array = V[i]
    _t.call("chat_line", v[0], v[1], msg)
    _stats["cmds"] += 1

func _shot() -> void:
    if DisplayServer.get_name() == "headless":
        return
    root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "/soak_%02d.png" % _shots))
    print("SOAK shot soak_%02d cut=%s" % [_shots, _last_cut])
    _shots += 1

func _act() -> void:
    # every 60 wall seconds each viewer acts: the dead reroll, the idle pick an errand
    var r: Roster = _t.get("roster")
    var hs: Dictionary = _t.get("heroes")
    var eco: Economy = _t.get("economy")
    for i in V.size():
        var h: Dictionary = r.get_hero(V[i][0])
        if h.is_empty():
            _queue.append([i, "!enlist " + V[i][2]])
            continue
        if not bool(h.get("alive", false)):
            _queue.append([i, "!reroll"])
            _stats["rerolls"] += 1
            continue
        var b = hs.get(V[i][0])
        if b == null or not is_instance_valid(b) or not (b as HeroBody).visible or (b as HeroBody).errand != "" or not (b as HeroBody)._route.is_empty():
            continue
        var pick := (i + eco.day + _f / 997) % 4
        _queue.append([i, ["!delve", "!fish", "!delve", "!forge"][pick]])

func _audio() -> String:
    var sx = Sfx.live()
    if sx == null:
        return "audio=off"
    var pool: Array = sx._pool
    var flat: Array = sx._flat
    var pact := 0
    for pp in pool:
        if (pp as AudioStreamPlayer3D).playing:
            pact += 1
    var fact := 0
    for ff in flat:
        if (ff as AudioStreamPlayer).playing:
            fact += 1
    _aud_pool_max = maxi(_aud_pool_max, pact)
    _aud_flat_max = maxi(_aud_flat_max, fact)
    var plays: Dictionary = sx.plays
    var total := 0
    var busiest_kind := "-"
    var busiest_d := 0
    for k in plays:
        total += int(plays[k])
        var d := int(plays[k]) - int(_aud_prev_kinds.get(k, 0))
        if d > busiest_d:
            busiest_d = d
            busiest_kind = String(k)
    _aud_prev_kinds = plays.duplicate()
    var this_min := total - _aud_prev
    _aud_prev = total
    _aud_busiest = maxi(_aud_busiest, busiest_d)
    return "pool_active=%d/%d flat_active=%d/%d streams=%d plays_this_min=%d busiest=%s@%d/min" % [pact, pool.size(), fact, flat.size(), sx._streams.size(), this_min, busiest_kind, busiest_d]

func _process(dt: float) -> bool:
    _f += 1
    if _f == 20:
        _eye = RtsCamera.new()
        _t.add_child(_eye)
        _eye.setup(_t)
        for i in V.size():
            _queue.append([i, "!enlist " + V[i][2]])
        for i in V.size():
            _queue.append([i, "!delve"])
    if _f == 40:
        _eye.director._set_on(true)
        Engine.time_scale = 4.0
        _t0 = Time.get_ticks_msec()
        _min_ms = _t0
        _act_ms = _t0
    if _f < 40:
        return false
    var now := Time.get_ticks_msec()
    if not _queue.is_empty() and now - _cmd_ms > 1700:
        var q: Array = _queue.pop_front()
        _say(int(q[0]), String(q[1]))
        _cmd_ms = now
    if now - _act_ms > 60000:
        _act_ms = now
        _act()
    var key := String(_eye.director._cur.get("key", "-"))
    if key != _last_cut:
        _last_cut = key
        var k := key.split("_")[0]
        _cuts[k] = int(_cuts.get(k, 0)) + 1
    var feed: Array = _t.get("feed")
    while _seen < feed.size():
        var l := String(feed[_seen])
        if l.contains("descend into the scar"):
            _stats["descend"] += 1
        if l.contains("come home to Bellmire"):
            _stats["home"] += 1
        if l.contains("No one comes home"):
            _stats["wiped"] += 1
        if l.contains("!reroll"):
            _stats["viewer_dead"] += 1
        if l.contains(" lands a "):
            _stats["caught"] += 1
        _seen += 1
    _proc_max = maxf(_proc_max, Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
    _acc += dt / maxf(0.01, Engine.time_scale)
    if _acc >= 1.0:
        _acc = 0.0
        _fps.append(Engine.get_frames_per_second())
    if now - _min_ms >= 60000:
        _min_ms = now
        var mn := 1e9
        var sm := 0.0
        for x in _fps:
            mn = minf(mn, float(x))
            sm += float(x)
        var avg := sm / maxf(1.0, float(_fps.size()))
        var _pm := _proc_max
        _all_fps.append_array(_fps)
        _fps.clear()
        var r: Roster = _t.get("roster")
        var alive := 0
        for v in V:
            if r.is_alive(v[0]):
                alive += 1
        var eco: Economy = _t.get("economy")
        _proc_max = 0.0
        print("SOAK min=%d fps_min=%d fps_avg=%.1f proc_ms_max=%.1f day=%d hour=%.1f people=%d viewers_alive=%d in=%d home=%d wiped=%d viewer_dead=%d rerolls=%d catches=%d raids=%d cut=%s nodes=%d mem_mb=%.0f" % [
            (now - _t0) / 60000, int(mn), avg, _pm, eco.day, eco.hour(), (_t.get("people") as Array).size(), alive,
            _stats["descend"], _stats["home"], _stats["wiped"], _stats["viewer_dead"], _stats["rerolls"], _stats["caught"],
            (_t.get("raids") as Raids).raids, _last_cut, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
            Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0])
        print("SOAK audio min=%d %s" % [(now - _t0) / 60000, _audio()])
        if ((now - _t0) / 60000) % 10 == 0:
            _shot()
    if _shots == 0 and now - _t0 > 20000:
        _shot()
    if now - _t0 >= _minutes * 60000:
        var mn2 := 1e9
        var sm2 := 0.0
        for x in _all_fps:
            mn2 = minf(mn2, float(x))
            sm2 += float(x)
        _shot()
        print("SOAK cuts=", _cuts)
        print("SOAK done minutes=%d fps_min=%d fps_avg=%.1f samples=%d cmds=%d" % [_minutes, int(mn2), sm2 / maxf(1.0, float(_all_fps.size())), _all_fps.size(), _stats["cmds"]])
        print("SOAK audio_summary pool_max_active=%d flat_max_active=%d busiest_kind_in_a_minute=%d streams_cached=%d" % [_aud_pool_max, _aud_flat_max, _aud_busiest, (Sfx.live()._streams.size() if Sfx.live() else 0)])
        return true
    return false
