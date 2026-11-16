extends SceneTree
## D17d: the POP probe. The town for 60 s (a level-5 west raid at 4 s, an east
## one at 30 s). Every frame, up to 90 visible bodies at full rate (LOD 0) have
## ~10 bones' local rotations read; a POP is a one-frame jump - a bone turning
## > POP_DEG in one 60 fps frame AND > 3x both neighbouring frames (a blend or
## a fast swing spreads over many frames; a snap is one). Each pop is put down
## to the clip change seen in the 3 frames before it ("Walking_A>Death_A") or
## to the clip itself ("in:Idle" - a loop seam). Also: TURN snaps (the body's
## yaw > 35 deg in a frame with no teleport) and RISEN corpses (a body that
## fell - a Death_* clip - later standing in any non-death clip while still in
## the tree). Sampled at the END of each frame (a probe node that processes
## last). SHAKE = a bone going and straight back > 25 deg each frame.
## Run with --fixed-fps 60; `-- --old` = before (Rig.smooth off).
var _t: Node3D
var _f := 0
var SECS := 60
const POP_DEG := 14.0
const TURN_DEG := 35.0
const MAXB := 90
var _trk := {}          # ap id -> {ap, sk, bones, q, d1, d2, cur hist, owner, yaw, pos, ok_from}
var pops := 0
var turns := 0
var risen := 0
var frames := 0
var _why := {}
var _twhy := {}
var _rwhy := {}
var _dead := {}
var _trans := 0
var falls := 0
var hist := {}          # per-frame max bone turn, 1-deg bins
var SELF := false       # --selftest: snap 12 bodies into a cheer with no blend
var _self_n := 0
var jitter := 0         # a bone turning > JIT_DEG in two frames running (shaking)
const JIT_DEG := 25.0
var _jwhy := {}
var killed := 0
var DBG := false
var _dbg_n := 0
var _bwhy := {}

func _initialize() -> void:
    var a := OS.get_cmdline_user_args()
    if a.has("--short"):
        SECS = 15
    if a.has("--dbg"):
        DBG = true
    if a.has("--selftest"):
        SELF = true
    if a.has("--old"):
        Rig.smooth = false
        print("RIG SMOOTH OFF (before)")
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    var pr := Probe.new()
    pr.host = self
    pr.process_priority = 10        # after every body and its AnimationPlayer: what is drawn
    root.add_child(pr)

class Probe extends Node:
    var host
    func _process(_d: float) -> void:
        host.tick()

func _is_body(ap: AnimationPlayer) -> bool:
    for nm in ap.get_animation_list():
        var s := String(nm)
        if s.begins_with("Idle") or s.ends_with("_Idle") or s.begins_with("Walk") or s.ends_with("_Flying"):
            return true
    return false

func _owner(ap: Node) -> Node3D:
    var n: Node = ap
    while n != null and n != _t:
        if n.get_script() != null and n is Node3D and (n.get_script() as Script).get_global_name() != "":
            return n
        n = n.get_parent()
    return null

func _tag(o: Node3D) -> String:
    if o == null:
        return "?"
    if o is Townsfolk:
        return "%s:%s" % [(o.get_script() as Script).get_global_name(), String(o.get("role"))]
    return String((o.get_script() as Script).get_global_name())

func _vis(n: Node) -> bool:
    while n != null and n != _t:
        if n is Node3D and not (n as Node3D).visible:
            return false
        n = n.get_parent()
    return true

const NAMES := ["hips", "spine", "chest", "head", "upperarm.l", "upperarm.r", "lowerarm.l",
    "lowerarm.r", "upperleg.l", "upperleg.r", "lowerleg.l", "lowerleg.r"]

func _bones(sk: Skeleton3D) -> Array:
    var out: Array = []
    for nm in NAMES:
        var b := sk.find_bone(nm)
        if b >= 0:
            out.append(b)
    if out.size() < 4:
        out.clear()
        var n := sk.get_bone_count()
        var step := maxi(1, n / 10)
        for b in range(0, n, step):
            out.append(b)
    return out

func _collect() -> void:
    var st: Array = [_t]
    var all: Array = []
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is AnimationPlayer and _is_body(c):
            all.append(c)
        for g in c.get_children():
            st.append(g)
    # drop the gone
    for k in _trk.keys():
        if not is_instance_valid(_trk[k]["ap"]) or not (_trk[k]["ap"] as Node).is_inside_tree():
            _trk.erase(k)
    all.shuffle()
    # raid folk first (they fight, fall), then the rest
    all.sort_custom(func(x, y): return _prio(x) > _prio(y))
    for ap in all:
        if _trk.size() >= MAXB:
            break
        var id: int = ap.get_instance_id()
        if _trk.has(id):
            continue
        var rootn: Node = (ap as AnimationPlayer).get_node_or_null((ap as AnimationPlayer).root_node)
        var sk := Rig.skeleton(rootn if rootn else ap.get_parent())
        if sk == null:
            continue
        _trk[id] = {"ap": ap, "sk": sk, "bones": _bones(sk), "q": [], "d": [0.0, 0.0],
            "cur": ["", "", "", ""], "o": _owner(ap), "yaw": INF, "pos": Vector3.INF, "skip": 3}

func _prio(ap: AnimationPlayer) -> int:
    var o := _owner(ap)
    if o == null:
        return 0
    var rd = _t.get("raids")
    if rd:
        if (rd.get("_fighters") as Dictionary).has(o):
            return 2
        for r in rd.get("raiders"):
            if r.get("node") == o:
                return 2
    return 1 if _vis(ap) else 0

func _process(_d: float) -> bool:
    _f += 1
    if _f == 240 or _f == 1800:
        var rd = _t.get("raids")
        if rd:
            rd.force_level = 5
            rd.call("raid", "west" if _f == 240 else "east")
            print("RAID started")
    if _f % 120 == 30:
        _collect()
    if _f == 1500:
        _kill()
    if SELF and _f % 300 == 150:
        for k in _trk.keys().slice(0, 12):
            var ap: AnimationPlayer = _trk[k]["ap"]
            if ap.has_animation("Cheer") and ap.current_animation != "Cheer":
                ap.play("Cheer", 0.0)
                _self_n += 1
    if _f % 1200 == 0:
        print("T=", _f / 60, "s tracked=", _trk.size(), " frames=", frames, " pops=", pops, " turns=", turns, " risen=", risen)
    if _f >= SECS * 60:
        _report()
        return true
    return false

func tick() -> void:
    if _f > 60:
        _sample()

func _sample() -> void:
    for k in _trk.keys():
        var e: Dictionary = _trk[k]
        if not is_instance_valid(e["ap"]):
            _trk.erase(k)
            continue
        var ap: AnimationPlayer = e["ap"]
        if not ap.is_inside_tree():
            _trk.erase(k)
            continue
        if e["o"] != null and not is_instance_valid(e["o"]):
            _trk.erase(k)
            continue
        var o: Node3D = e["o"]
        var lod := 0
        if o != null and o.get("lod") != null:
            lod = int(o.get("lod"))
        var cur := String(ap.current_animation)
        if cur == "":
            cur = "(" + String(ap.assigned_animation) + ")"
        var h: Array = e["cur"]
        h.push_back(cur)
        h.pop_front()
        # corpses: once fallen, any non-death clip after is a rise
        if cur.begins_with("Death_") or cur.begins_with("(Death_"):
            if not _dead.has(k):
                falls += 1
            _dead[k] = true
        elif _dead.has(k):
            # (a green hero's knock-out stands them up again for real)
            var up := o != null and o is HeroBody and not bool(o.get("fallen"))
            if not up:
                risen += 1
                var rk := "%s now %s" % [_tag(o), cur]
                _rwhy[rk] = int(_rwhy.get(rk, 0)) + 1
            _dead.erase(k)
        if lod != 0 or not _vis(ap) or ap.callback_mode_process != AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE:
            e["skip"] = 3
            e["q"] = []
            e["q0"] = []
            continue
        var sk: Skeleton3D = e["sk"]
        var qs: Array = []
        for b in e["bones"]:
            qs.append(sk.get_bone_pose_rotation(b))
        var dmax := 0.0
        var shake := false
        var imax := -1
        var q1: Array = e["q"]
        var q0: Array = e.get("q0", [])
        if q1.size() == qs.size():
            for i in range(qs.size()):
                var a: Quaternion = q1[i]
                var dd := rad_to_deg(a.angle_to(qs[i]))
                if dd > dmax:
                    dmax = dd
                    imax = i
                # SHAKE: a bone that goes and comes straight back (> JIT_DEG each
                # way) - fast motion keeps going one way, a fight between two
                # poses reverses every frame
                if q0.size() == qs.size() and dd > JIT_DEG:
                    var d0 := rad_to_deg((q0[i] as Quaternion).angle_to(a))
                    var span := rad_to_deg((q0[i] as Quaternion).angle_to(qs[i]))
                    if d0 > JIT_DEG and span < 0.4 * (d0 + dd):
                        shake = true
                        if DBG and _dbg_n < 6:
                            _dbg_n += 1
                            print("SHAKE %s cur=%s bone=%s d0=%.1f d1=%.1f span=%.1f ss=%.2f" % [_tag(o), cur, sk.get_bone_name(e["bones"][i]), d0, dd, span, ap.speed_scale])
        e["q0"] = q1
        e["q"] = qs
        # yaw snap of the whole body
        if o != null:
            var y := o.global_rotation.y
            var p := o.global_position
            if e["yaw"] != INF and e["skip"] <= 0:
                var dy := absf(rad_to_deg(angle_difference(float(e["yaw"]), y)))
                var mv := (p - (e["pos"] as Vector3)).length()
                if dy > TURN_DEG and mv < 1.0:
                    turns += 1
                    var tk := "%s in %s" % [_tag(o), cur]
                    _twhy[tk] = int(_twhy.get(tk, 0)) + 1
            e["yaw"] = y
            e["pos"] = p
        if int(e["skip"]) > 0:
            e["skip"] = int(e["skip"]) - 1
            e["d"] = [0.0, 0.0]
            continue
        frames += 1
        # d = [d(t-2), d(t-1)]; now dmax = d(t). Judge t-1.
        var d: Array = e["d"]
        var dp: float = d[1]
        if dp > POP_DEG and dp > 3.0 * maxf(float(d[0]), 1.5) and dp > 3.0 * maxf(dmax, 1.5):
            pops += 1
            var why := "in:" + String(h[2])
            for i in range(2, 0, -1):
                if String(h[i]) != String(h[i - 1]):
                    why = "%s>%s" % [h[i - 1], h[i]]
                    break
            var wk := "%s %s" % [_tag(o), why]
            _why[wk] = int(_why.get(wk, 0)) + 1
        e["d"] = [dp, dmax]
        if shake:
            jitter += 1
            var jk := "%s in:%s" % [_tag(o), cur]
            _jwhy[jk] = int(_jwhy.get(jk, 0)) + 1
        if dmax >= 40.0 and imax >= 0:
            var bk := "%s in:%s bone %s" % [_tag(o), cur, sk.get_bone_name(e["bones"][imax])]
            _bwhy[bk] = int(_bwhy.get(bk, 0)) + 1
        var bin := mini(int(dmax), 40)
        hist[bin] = int(hist.get(bin, 0)) + 1

func _report() -> void:
    for pr in [["POP", _why], ["TURN", _twhy], ["RISEN", _rwhy], ["SHAKE", _jwhy], ["FAST40", _bwhy]]:
        var m: Dictionary = pr[1]
        var ks: Array = m.keys()
        ks.sort_custom(func(a, b): return int(m[a]) > int(m[b]))
        for k in ks.slice(0, 16):
            print("  %s %d  %s" % [pr[0], m[k], k])
    var acc := 0
    var p99 := 0
    var p999 := 0
    for b in range(41):
        acc += int(hist.get(b, 0))
        if p99 == 0 and acc >= frames * 0.99:
            p99 = b + 1
        if p999 == 0 and acc >= frames * 0.999:
            p999 = b + 1
    print("bone turn per frame: p99 < %d deg, p99.9 < %d deg, max bin %d; falls seen %d; selftest snaps %d" % [p99, p999, hist.keys().max() if not hist.is_empty() else 0, falls, _self_n])
    var ok := pops <= maxi(3, frames / 20000) and risen == 0 and turns <= maxi(3, frames / 20000) \
        and jitter <= maxi(3, frames / 20000) and falls >= killed
    print("D17D_TEST frames=%d pops=%d turns=%d jitter=%d falls=%d (fixture %d) risen=%d %s" % [frames, pops, turns, jitter, falls, killed, risen, "PASS" if ok else "FAIL"])

## fixture: deaths are rare in a minute, so at 25 s four walking townsfolk in
## view are buried (town.bury - the fall a raid gives) and two raiders fall;
## all six are watched for 35 s - none may get up
func _kill() -> void:
    var n := 0
    for k in _trk.keys():
        var o: Node3D = _trk[k]["o"]
        if n < 4 and o != null and o is Townsfolk and not (o is HeroBody) \
                and (_t.get("people") as Array).has(o) and _vis(o) and Rig.is_gait(String((_trk[k]["ap"] as AnimationPlayer).current_animation)):
            _t.call("bury", o, "D17D fixture")
            n += 1
            killed += 1
    var rd = _t.get("raids")
    if rd:
        var rs: Array = (rd.get("raiders") as Array).duplicate()
        var m := 0
        for r in rs:
            if m < 2 and r.get("node") is Townsfolk:
                var id: int = ((r["node"] as Townsfolk)._anim).get_instance_id() if (r["node"] as Townsfolk)._anim else 0
                if _trk.has(id):
                    rd.call("_raider_falls", r, "test")
                    m += 1
                    killed += 1
    print("FIXTURE killed ", killed)
