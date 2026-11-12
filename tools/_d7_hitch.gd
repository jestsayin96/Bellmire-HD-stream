extends SceneTree
## D7 HITCH HUNT - FAKE CHAT FEED, nothing is posted anywhere. The real town,
## the director on, 4x speed, six fake viewers delving, for HITCH_MIN wall minutes
## (default 6). Every frame longer than 250 ms wall is printed with what changed
## that frame: process / physics ms, nodes added, the delve's state and floor,
## new Chronicle lines, the hour. One FPS line a minute. Then DungeonHD.build is
## timed alone for a few floors. Windowed (render cost counts) or headless.
var _t: Node3D
var _eye: RtsCamera
var _f := 0
var _t0 := 0
var _last := 0
var _min_ms := 0
var _cmd_ms := 0
var _queue: Array = []
var _minutes := 6
var _nodes := 0
var _seen := 0
var _hitches: Array = []
var _fps: Array = []
var _all: Array = []
var _acc := 0.0
var _dstate := "-"
var V := [["1001", "JestFan", "knight"], ["1002", "MossyMage", "mage"], ["1003", "QuietArrow", "ranger"],
          ["1004", "BigAxe", "barbarian"], ["1005", "DawnCleric", "cleric"], ["1006", "Stabbity", "rogue"]]

func _initialize() -> void:
    var m := OS.get_environment("HITCH_MIN")
    if m != "":
        _minutes = maxi(1, int(m))
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    print("HITCH start minutes=%d display=%s" % [_minutes, DisplayServer.get_name()])

func _delve_desc() -> String:
    var d = _t.get("delve")
    if d == null or not is_instance_valid(d):
        return "none"
    return "%s/f%s" % [String(d.get("state")), str(d.get("floor_no"))]

func _process(dt: float) -> bool:
    _f += 1
    var now_us := Time.get_ticks_usec()
    var wall_ms := float(now_us - _last) / 1000.0
    _last = now_us
    var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
    var dn := nodes - _nodes
    _nodes = nodes
    if _f == 20 and OS.get_environment("HITCH_BENCH") != "":
        _bench()
        return true
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
    if _f <= 41:
        return false
    var now := Time.get_ticks_msec()
    if not _queue.is_empty() and now - _cmd_ms > 1700:
        var q: Array = _queue.pop_front()
        _t.call("chat_line", V[q[0]][0], V[q[0]][1], String(q[1]))
        _cmd_ms = now
    var ds := _delve_desc()
    var feed: Array = _t.get("feed")
    var news := ""
    while _seen < feed.size():
        news = String(feed[_seen]).left(70)
        _seen += 1
    if wall_ms > 250.0:
        var eco: Economy = _t.get("economy")
        var h := "HITCH t=%.1fs wall_ms=%.0f proc_ms=%.1f phys_ms=%.1f nodes=%+d delve=%s (was %s) hour=%.2f people=%d cut=%s news=%s" % [
            (now - _t0) / 1000.0, wall_ms, Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
            Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, dn, ds, _dstate, eco.hour(),
            (_t.get("people") as Array).size(), String(_eye.director._cur.get("key", "-")), news]
        print(h)
        _hitches.append(wall_ms)
    _dstate = ds
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
        _all.append_array(_fps)
        print("HITCH min=%d fps_min=%d fps_avg=%.1f people=%d nodes=%d" % [(now - _t0) / 60000, int(mn), sm / maxf(1.0, _fps.size()), (_t.get("people") as Array).size(), nodes])
        _fps.clear()
    if now - _t0 >= _minutes * 60000:
        _bench()
        print("HITCH done minutes=%d hitches=%d worst_ms=%.0f" % [_minutes, _hitches.size(), (_hitches.max() if not _hitches.is_empty() else 0.0)])
        return true
    return false

func _bench() -> void:
    # the floor build alone, and its three parts (DungeonHD.build = FloorGen.build + _dress + _people)
    for n in [1, 2, 3, 5, 8]:
        var d := DungeonHD.new()
        d.info = {"skip": true}
        root.add_child(d)
        var a := Time.get_ticks_usec()
        d.floor_no = n
        d._rng.seed = hash("hd:%d" % n)
        d.info = FloorGen.build(d, n, Vector3.ZERO)
        var b := Time.get_ticks_usec()
        d._dress()
        var c := Time.get_ticks_usec()
        d._people()
        var e := Time.get_ticks_usec()
        var cnt := [0]
        var walk := func(nd: Node, me: Callable) -> void:
            cnt[0] += 1
            for ch in nd.get_children():
                me.call(ch, me)
        walk.call(d, walk)
        var g := Time.get_ticks_usec()
        d.free()
        var h := Time.get_ticks_usec()
        print("HITCH bench floor %d: floorgen %.0f ms, dress %.0f ms, people %.0f ms, total %.0f ms, %d nodes, free %.0f ms" % [
            n, (b - a) / 1000.0, (c - b) / 1000.0, (e - c) / 1000.0, (e - a) / 1000.0, cnt[0], (h - g) / 1000.0])
