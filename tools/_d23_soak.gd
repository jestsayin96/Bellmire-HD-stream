extends SceneTree
## D23 SOAK - FAKE CHAT FEED, nothing is posted anywhere. The stream's REAL resting
## state per COORDINATION 8.5: the player's eye (director on, the L32 2x2 spotlight
## grid up), the leaderboard, a simulated chat feed at stream cadence, and the
## snapshot publisher's full per-minute work (scan_feed every 1 s, build_payload +
## JSON every 60 s) with its key pointed at a file that does not exist, so it can
## NEVER reach the live hub. 1x speed, 1920x1080 window, vsync off, uncapped.
## Raids come on their own timer (every 110-190 s). The on-disk roster is backed up
## first and put back at the end so the fake viewers do not stay in Mr. E's save.
##   D23_MIN=<minutes> (default 30)
## One D23S line per second (fps), one D23M line per minute (avg/min + what the
## frame is made of), every frame over 100 ms as D23H, then the verdict D23_SOAK.
var _t: Node3D
var _eye: RtsCamera
var _pub: SnapshotPublisher
var _f := 0
var _t0 := 0
var _last := 0
var _minutes := 30
var _cmd_ms := 0
var _queue: Array = []
var _rng := RandomNumberGenerator.new()
var _sec: Array = []          # every 1 s fps sample, whole run
var _min_s: Array = []        # this minute's samples
var _acc := 0.0
var _min_ms := 0
var _pub_ms := 0
var _scan_ms := 0
var _pub_cost: Array = []
var _hitch: Array = []
var _bak := false
var V := [["1001", "JestFan", "knight"], ["1002", "MossyMage", "mage"], ["1003", "QuietArrow", "ranger"],
          ["1004", "BigAxe", "barbarian"], ["1005", "DawnCleric", "cleric"], ["1006", "Stabbity", "rogue"]]
const ROSTER := "user://roster.json"
const ROSTER_BAK := "user://roster.json.d23bak"

func _initialize() -> void:
    _rng.seed = 2323
    var m := OS.get_environment("D23_MIN")
    if m != "":
        _minutes = maxi(1, int(m))
    if FileAccess.file_exists(ROSTER):
        _bak = DirAccess.copy_absolute(ProjectSettings.globalize_path(ROSTER), ProjectSettings.globalize_path(ROSTER_BAK)) == OK
    DisplayServer.window_set_size(Vector2i(1920, 1080))
    DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
    Engine.max_fps = 0
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    print("D23 start minutes=%d display=%s roster_backup=%s" % [_minutes, DisplayServer.get_name(), str(_bak)])

func _mon(k: int) -> float:
    return Performance.get_monitor(k)

func _process(dt: float) -> bool:
    _f += 1
    var now_us := Time.get_ticks_usec()
    var wall_ms := float(now_us - _last) / 1000.0
    _last = now_us
    if _f == 20:
        _eye = RtsCamera.new()
        _t.add_child(_eye)
        _eye.setup(_t)
        var board := LeaderboardPanel.new()
        _t.add_child(board)
        board.setup(_t.get("roster"))
        _pub = SnapshotPublisher.new()
        _pub.key_file = "user://__d23_no_key_never_publish.json"
        _t.add_child(_pub)
        _pub.setup(_t)
        for i in V.size():
            _queue.append([i, "!enlist " + V[i][2]])
        for i in V.size():
            _queue.append([i, "!delve"])
    if _f == 40:
        _eye.director._set_on(true)
    if _f < 240:          # settle: the first build, the grid, the first floor
        return false
    if _t0 == 0:
        _t0 = Time.get_ticks_msec()
        _min_ms = _t0
        _pub_ms = _t0
        _scan_ms = _t0
        print("D23 measuring from frame %d" % _f)
    var now := Time.get_ticks_msec()
    # chat at stream cadence: a command every 4-9 s from a random viewer
    if _queue.is_empty() and now - _cmd_ms > _rng.randi_range(4000, 9000):
        var i := _rng.randi_range(0, V.size() - 1)
        _queue.append([i, ["!delve", "!fish", "!look", "!delve", "!stats", "!fish"][_rng.randi_range(0, 5)]])
    if not _queue.is_empty() and now - _cmd_ms > 1700:
        var q: Array = _queue.pop_front()
        _t.call("chat_line", V[q[0]][0], V[q[0]][1], String(q[1]))
        _cmd_ms = now
    # the publisher's real work, never its network call
    if now - _scan_ms >= 1000:
        _scan_ms = now
        _pub.scan_feed()
    if now - _pub_ms >= 60000:
        _pub_ms = now
        var a := Time.get_ticks_usec()
        var body := JSON.stringify([{"id": 1, "payload": _pub.build_payload()}])
        _pub_cost.append((Time.get_ticks_usec() - a) / 1000.0)
        _pub.last_bytes = body.length()
    var rd = _t.get("raids")
    if wall_ms > 100.0:
        _hitch.append(wall_ms)
        print("D23H t=%.1fs wall_ms=%.0f proc_ms=%.1f phys_ms=%.1f nodes=%d" % [(now - _t0) / 1000.0, wall_ms,
            _mon(Performance.TIME_PROCESS) * 1000.0, _mon(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
            int(_mon(Performance.OBJECT_NODE_COUNT))])
    _acc += dt / maxf(0.01, Engine.time_scale)
    if _acc >= 1.0:
        _acc = 0.0
        var fps := Engine.get_frames_per_second()
        _sec.append(fps)
        _min_s.append(fps)
        print("D23S t=%d fps=%d" % [(now - _t0) / 1000, int(fps)])
    if now - _min_ms >= 60000:
        _min_ms = now
        var mn := 1e9
        var sm := 0.0
        for x in _min_s:
            mn = minf(mn, float(x))
            sm += float(x)
        var d = _t.get("delve")
        var ds := "none"
        if d != null and is_instance_valid(d):
            ds = "%s/f%s" % [String(d.get("state")), str(d.get("floor_no"))]
        print("D23M min=%d fps_avg=%.1f fps_min=%d proc_ms=%.2f phys_ms=%.2f draws=%d objs=%d prims=%dk nodes=%d people=%d delve=%s raid=%s cut=%s" % [
            (now - _t0) / 60000, sm / maxf(1.0, _min_s.size()), int(mn), _mon(Performance.TIME_PROCESS) * 1000.0,
            _mon(Performance.TIME_PHYSICS_PROCESS) * 1000.0, int(_mon(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
            int(_mon(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)), int(_mon(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000.0),
            int(_mon(Performance.OBJECT_NODE_COUNT)), (_t.get("people") as Array).size(), ds,
            ("%s/%d" % [str(rd.get("_live")), (rd.get("raiders") as Array).size()]) if rd else "-", String(_eye.director._cur.get("key", "-"))])
        _min_s.clear()
    if now - _t0 >= _minutes * 60000:
        _finish()
        return true
    return false

func _finish() -> void:
    var sm := 0.0
    var mn := 1e9
    var below := 0
    var run := 0
    var worst_run := 0
    for x in _sec:
        sm += float(x)
        mn = minf(mn, float(x))
        if float(x) < 100.0:
            below += 1
            run += 1
            worst_run = maxi(worst_run, run)
        else:
            run = 0
    var avg := sm / maxf(1.0, _sec.size())
    var pc := 0.0
    for c in _pub_cost:
        pc = maxf(pc, float(c))
    # "sustained dip" = 10+ consecutive seconds under 100
    var ok := avg >= 120.0 and worst_run < 10
    print("D23_SOAK %s minutes=%d fps_avg=%.1f fps_min=%d secs=%d below100=%d longest_below100_run=%ds hitches_over100ms=%d worst_ms=%.0f publish_build_ms_max=%.1f payload_bytes=%d" % [
        "OK" if ok else "FAIL", _minutes, avg, int(mn), _sec.size(), below, worst_run, _hitch.size(),
        (_hitch.max() if not _hitch.is_empty() else 0.0), pc, _pub.last_bytes if _pub else 0])
    if _bak:
        var e := DirAccess.copy_absolute(ProjectSettings.globalize_path(ROSTER_BAK), ProjectSettings.globalize_path(ROSTER))
        print("D23 roster restored=%s" % str(e == OK))
