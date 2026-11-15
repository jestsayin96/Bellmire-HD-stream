extends SceneTree
## D23 ATTRIBUTION (D23_SET=engine: the engine-side toggles instead) - FAKE CHAT, nothing posted. The same resting stream state as
## _d23_soak.gd (eye + director + L32 grid + leaderboard + dry publisher), then
## 20 s phases A/B'd against each other: normal, every script's _process /
## _physics_process timed by calling it by hand, sun shadows off, grid folded,
## SSAO+glow off, townsfolk hidden. One D23AB line per phase; D23CPU lines rank
## the scripts. Per-viewport render CPU/GPU ms from RenderingServer.
var _t: Node3D
var _eye: RtsCamera
var _pub: SnapshotPublisher
var _f := 0
var _t0 := 0
var _phase := -1
var _ph_t0 := 0
var _samp: Array = []
var _proc: Array = []
var _phys: Array = []
var _prof: Array = []        # [node, path, has_p, has_pp]
var _cost := {}              # path -> [usec, calls, nodes]
var _vps: Array = []
var _gpu := {}
var _cmd_ms := 0
var _rng := RandomNumberGenerator.new()
var _queue: Array = []
var _hidden: Array = []
var V := [["1001", "JestFan", "knight"], ["1002", "MossyMage", "mage"], ["1003", "QuietArrow", "ranger"],
          ["1004", "BigAxe", "barbarian"], ["1005", "DawnCleric", "cleric"], ["1006", "Stabbity", "rogue"]]
const PH_A := ["normal", "unseen_off", "normal", "unseen_off", "profiled", "no_sun_shadow", "normal", "folk_hidden"]
const PH_B := ["normal", "anims_frozen", "normal", "hud_hidden", "normal", "label3d_hidden", "physics_off", "particles_off", "normal", "lights_off"]
const PH_C := ["normal", "sun_2split", "normal", "sun_2split", "normal", "sun_2split", "normal", "sun_2split"]
var PH: Array = PH_A
var _saved: Array = []
const PH_S := 20
const ROSTER := "user://roster.json"
const ROSTER_BAK := "user://roster.json.d23abbak"
var _bak := false

func _initialize() -> void:
    _rng.seed = 77
    if OS.get_environment("D23_SET") == "engine":
        PH = PH_B
    if OS.get_environment("D23_SET") == "sun":
        PH = PH_C
    if FileAccess.file_exists(ROSTER):
        _bak = DirAccess.copy_absolute(ProjectSettings.globalize_path(ROSTER), ProjectSettings.globalize_path(ROSTER_BAK)) == OK
    DisplayServer.window_set_size(Vector2i(1920, 1080))
    DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
    Engine.max_fps = 0
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _sun() -> DirectionalLight3D:
    for c in _t.get_children():
        if c is DirectionalLight3D:
            return c
    return null

func _env() -> Environment:
    for c in _t.get_children():
        if c is WorldEnvironment:
            return (c as WorldEnvironment).environment
    return null

func _enter(i: int) -> void:
    var n: String = PH[i]
    if n == "profiled":
        _prof.clear()
        _cost.clear()
        for nd in root.find_children("*", "", true, false):
            var s = nd.get_script()
            if s == null or nd == _t.get_parent():
                continue
            var hp: bool = nd.has_method("_process") and nd.is_processing()
            var hpp: bool = nd.has_method("_physics_process") and nd.is_physics_processing()
            if not hp and not hpp:
                continue
            var path := String((s as Script).resource_path).get_file()
            if path == "":
                path = "inner:" + String(nd.get_class())
            if hp:
                nd.set_process(false)
            if hpp:
                nd.set_physics_process(false)
            _prof.append([nd, path, hp, hpp])
            if not _cost.has(path):
                _cost[path] = [0, 0, 0]
            _cost[path][2] += 1
    elif n == "unseen_off":
        _t.set("lod_unseen", false)
    elif n == "sun_2split":
        var s2 := _sun()
        if s2:
            s2.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
            print("D23AB sun max_distance=%.0f" % s2.directional_shadow_max_distance)
    elif n == "anims_frozen":
        _saved.clear()
        for ap in root.find_children("*", "AnimationMixer", true, false):
            _saved.append([ap, (ap as AnimationMixer).active])
            (ap as AnimationMixer).active = false
        print("D23AB froze %d mixers" % _saved.size())
    elif n == "hud_hidden":
        _saved.clear()
        for cl in root.find_children("*", "CanvasLayer", true, false):
            if (cl as CanvasLayer).layer >= 0 and (cl as CanvasLayer).visible:
                _saved.append([cl, true])
                (cl as CanvasLayer).visible = false
        print("D23AB hid %d canvas layers" % _saved.size())
    elif n == "label3d_hidden":
        _saved.clear()
        for lb in root.find_children("*", "Label3D", true, false):
            if (lb as Label3D).visible:
                _saved.append([lb, true])
                (lb as Label3D).visible = false
        print("D23AB hid %d label3d" % _saved.size())
    elif n == "physics_off":
        PhysicsServer3D.set_active(false)
        var nb := 0
        for b in root.find_children("*", "CollisionObject3D", true, false):
            nb += 1
        print("D23AB physics server off; %d collision objects" % nb)
    elif n == "particles_off":
        _saved.clear()
        for gp in root.find_children("*", "GPUParticles3D", true, false):
            if (gp as GPUParticles3D).visible:
                _saved.append([gp, true])
                (gp as GPUParticles3D).visible = false
        print("D23AB hid %d particles" % _saved.size())
    elif n == "lights_off":
        _saved.clear()
        var sh := 0
        for lt in root.find_children("*", "OmniLight3D", true, false):
            if (lt as Light3D).visible:
                _saved.append([lt, true])
                if (lt as Light3D).shadow_enabled:
                    sh += 1
                (lt as Light3D).visible = false
        print("D23AB hid %d omni lights (%d shadowed)" % [_saved.size(), sh])
    elif n == "no_sun_shadow":
        var s := _sun()
        if s:
            s.shadow_enabled = false
    elif n == "grid_folded":
        var sp := Spotlight.of(_t)
        if sp:
            sp.suspend(true)
    elif n == "no_ssao_glow":
        var e := _env()
        if e:
            e.ssao_enabled = false
            e.glow_enabled = false
    elif n == "folk_hidden":
        _hidden.clear()
        for v in _t.get("people"):
            if is_instance_valid(v) and v.visible and not (v is HeroBody):
                v.visible = false
                _hidden.append(v)

func _leave(i: int) -> void:
    var n: String = PH[i]
    if n == "profiled":
        for e in _prof:
            if is_instance_valid(e[0]):
                if e[2]:
                    e[0].set_process(true)
                if e[3]:
                    e[0].set_physics_process(true)
        _prof.clear()
    elif n == "unseen_off":
        _t.set("lod_unseen", true)
    elif n == "sun_2split":
        var s2 := _sun()
        if s2:
            s2.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
    elif n == "anims_frozen":
        for e in _saved:
            if is_instance_valid(e[0]):
                (e[0] as AnimationMixer).active = e[1]
        _saved.clear()
    elif n in ["hud_hidden", "label3d_hidden", "particles_off", "lights_off"]:
        for e in _saved:
            if is_instance_valid(e[0]):
                e[0].visible = true
        _saved.clear()
    elif n == "physics_off":
        PhysicsServer3D.set_active(true)
    elif n == "no_sun_shadow":
        var s := _sun()
        if s:
            s.shadow_enabled = true
    elif n == "grid_folded":
        var sp := Spotlight.of(_t)
        if sp:
            sp.suspend(false)
    elif n == "no_ssao_glow":
        var e := _env()
        if e:
            e.ssao_enabled = true
            e.glow_enabled = true
    elif n == "folk_hidden":
        for v in _hidden:
            if is_instance_valid(v):
                v.visible = true
        _hidden.clear()

func _report(i: int) -> void:
    var sm := 0.0
    var mn := 1e9
    for x in _samp:
        sm += float(x)
        mn = minf(mn, float(x))
    var pr := 0.0
    for x in _proc:
        pr += float(x)
    var py := 0.0
    for x in _phys:
        py += float(x)
    var g := ""
    for k in _gpu:
        var a: Array = _gpu[k]
        if a[2] > 0:
            g += " %s=cpu%.2f/gpu%.2f" % [k, a[0] / a[2], a[1] / a[2]]
    print("D23AB phase=%d %s fps_avg=%.1f fps_min=%d proc_ms=%.2f phys_ms=%.2f n=%d lod=%s raid=%d%s" % [i, PH[i], sm / maxf(1.0, _samp.size()), int(mn),
        pr / maxf(1.0, _proc.size()), py / maxf(1.0, _phys.size()), _samp.size(), str(_t.get("lod_counts")),
        (_t.get("raids").get("raiders") as Array).size(), g])
    if PH[i] == "profiled":
        var frames := float(maxi(1, _proc.size()))
        var rows: Array = []
        for k in _cost:
            rows.append([k, _cost[k]])
        rows.sort_custom(func(a, b): return a[1][0] > b[1][0])
        var tot := 0.0
        for r in rows:
            tot += float(r[1][0])
        print("D23CPU total_scripts_ms_per_frame=%.2f over %d frames" % [tot / 1000.0 / frames, int(frames)])
        for r in rows.slice(0, 22):
            print("D23CPU %-28s %.3f ms/frame nodes=%d" % [r[0], float(r[1][0]) / 1000.0 / frames, int(r[1][2])])
    _samp.clear()
    _proc.clear()
    _phys.clear()
    _gpu.clear()

func _time_calls(phys: bool, dt: float) -> void:
    for e in _prof:
        var nd: Node = e[0]
        if not is_instance_valid(nd) or not nd.is_inside_tree():
            continue
        if phys and e[3]:
            var a := Time.get_ticks_usec()
            nd._physics_process(dt)
            _cost[e[1]][0] += Time.get_ticks_usec() - a
        elif not phys and e[2]:
            var a := Time.get_ticks_usec()
            nd._process(dt)
            _cost[e[1]][0] += Time.get_ticks_usec() - a

func _physics_process(dt: float) -> bool:
    if _phase >= 0 and PH[_phase] == "profiled":
        _time_calls(true, dt)
    return false

func _process(dt: float) -> bool:
    _f += 1
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
    if _f < 40:
        return false
    var now := Time.get_ticks_msec()
    if _queue.is_empty() and now - _cmd_ms > _rng.randi_range(4000, 9000):
        _queue.append([_rng.randi_range(0, 5), ["!delve", "!fish", "!look", "!stats"][_rng.randi_range(0, 3)]])
    if not _queue.is_empty() and now - _cmd_ms > 1700:
        var q: Array = _queue.pop_front()
        _t.call("chat_line", V[q[0]][0], V[q[0]][1], String(q[1]))
        _cmd_ms = now
    if _phase >= 0 and PH[_phase] == "profiled":
        _time_calls(false, dt)
    if _t0 == 0:
        _t0 = now
    if now - _t0 < 50000:
        return false
    if _phase < 0:
        _phase = 0
        _ph_t0 = now
        _vps = [root.get_viewport_rid()]
        RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
        for sv in root.find_children("*", "SubViewport", true, false):
            RenderingServer.viewport_set_measure_render_time((sv as SubViewport).get_viewport_rid(), true)
        _enter(0)
    _samp.append(Engine.get_frames_per_second())
    _proc.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
    _phys.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
    var k := 0
    for sv in [root] + root.find_children("*", "SubViewport", true, false):
        var rid: RID = (sv as Viewport).get_viewport_rid()
        var key := "root" if sv == root else "vp%d" % k
        if sv != root:
            k += 1
        if not _gpu.has(key):
            _gpu[key] = [0.0, 0.0, 0]
        _gpu[key][0] += RenderingServer.viewport_get_measured_render_time_cpu(rid)
        _gpu[key][1] += RenderingServer.viewport_get_measured_render_time_gpu(rid)
        _gpu[key][2] += 1
    if now - _ph_t0 >= PH_S * 1000:
        _leave(_phase)
        _report(_phase)
        _phase += 1
        _ph_t0 = now
        if _phase >= PH.size():
            if _bak:
                DirAccess.copy_absolute(ProjectSettings.globalize_path(ROSTER_BAK), ProjectSettings.globalize_path(ROSTER))
            print("D23AB done")
            return true
        _enter(_phase)
    return false
