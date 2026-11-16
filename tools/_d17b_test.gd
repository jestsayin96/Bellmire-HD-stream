extends SceneTree
## D17b: the foot-slide probe. The town for 60 s (a level-5 raid at 4 s, like
## _townwalk). Sampled at the END of every frame (a probe node that processes
## last - what is drawn), for every visible full-rate person (Townsfolk,
## heroes, guards, raiders; not the riders - cavalry.gd matches its horse):
##  SKATE  - the KayKit walks/runs are in place, so the feet grip the street
##           only when the body moves at the clip's own ground speed
##           (Rig.GAIT_MPS, tools/_d17b_clipspeed.gd) x playback speed x model
##           scale. SKATE = |that - the body's real speed| (0.1 s window), m/s,
##           over bodies moving > 0.3 m/s or playing a walk/run; a body gliding
##           along in an idle counts its whole speed.
##  SLIDE  - cross-check on the skeleton: the planted ankle (lower foot, within
##           2 cm of its lowest) speed over the ground. Even a perfect match
##           reads ~0.2 (walk x1) - 0.4 (walk x2) m/s here from the heel-toe
##           roll (tools/_d17b_ideal.gd), so it is reported, not gated.
##  MOONWALK - moving > 0.5 m/s in a walk/run, facing > 100 deg off the way.
## --fixed-fps 60; `-- --old` = before (Rig.gait off, the old 0.62 pace, no
## facing fix). PASS: skate median < 0.15 m/s and p90 < 0.50 m/s, moonwalk
## < 0.2% of moving samples.
var _t: Node3D
var _f := 0
var SECS := 60
var _probe: Node

class Probe extends Node:
    var host
    func _process(d: float) -> void:
        host.sample(d)

func _initialize() -> void:
    var a := OS.get_cmdline_user_args()
    if a.has("--short"):
        SECS = 20
    if a.has("--old"):
        Rig.gait = false
        Townsfolk.pace = 0.62
        Townsfolk.face_fix = false
        print("GAIT OFF (before)")
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _probe = Probe.new()
    _probe.host = self
    _probe.process_priority = 100000
    root.add_child(_probe)

func _loco(c: String) -> bool:
    return c.begins_with("Walking") or c.begins_with("Running")

func _people() -> Array:
    var out: Array = []
    var st: Array = [_t]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is Townsfolk and not (c is Cavalry):
            out.append(c)
        for g in c.get_children():
            st.append(g)
    return out

var _list: Array = []
var _hist := {}       # body -> Array of last positions (7 frames)
var _ank := {}        # body -> [lowest ankle height over body y seen, prev low foot, prev pos]
var _skate: Array = []
var _slide: Array = []
var _skate_clip := {}
var _slide_clip := {}
var _moving := 0
var _moon := 0
var _glide := 0
var _bodies := 0
var _onspot := 0
var _gwho := {}

func sample(_d: float) -> void:
    if _f <= 90:
        return
    var dt := 1.0 / 60.0
    var seen := {}
    for v in _list:
        if not is_instance_valid(v) or not v.is_inside_tree():
            continue
        var tf: Townsfolk = v
        if tf._anim == null or tf.inside or not tf.is_visible_in_tree() or tf.lod != 0:
            continue
        var sk := Rig.skeleton(tf._mdl)
        if sk == null:
            continue
        var il := sk.find_bone("foot.l")
        var ir := sk.find_bone("foot.r")
        if il < 0 or ir < 0:
            continue
        seen[tf] = true
        var bp := tf.global_position
        var h: Array = _hist.get(tf, [])
        h.append(bp)
        if h.size() > 7:
            h.pop_front()
        _hist[tf] = h
        var ap: AnimationPlayer = tf._anim
        var cur := String(ap.current_animation)
        var ks: float = tf._mdl.global_basis.get_scale().x
        # body speed over the window
        if h.size() == 7:
            var d0: Vector3 = h[0]
            var bv := Vector2(bp.x - d0.x, bp.z - d0.z) / (6.0 * dt)
            var spd := bv.length()
            var loco := _loco(cur)
            if spd < 15.0 and (spd > 0.3 or loco):
                var exp := 0.0
                if Rig.GAIT_MPS.has(cur):
                    exp = float(Rig.GAIT_MPS[cur]) * ap.speed_scale * ks
                elif loco:
                    exp = 0.8 * ap.speed_scale * ks
                var sk8 := absf(spd - exp)
                _skate.append(sk8)
                var key := cur if cur != "" else "(none)"
                if not _skate_clip.has(key):
                    _skate_clip[key] = []
                (_skate_clip[key] as Array).append(sk8)
                if loco and spd < 0.1:
                    _onspot += 1
                if spd > 0.5:
                    _moving += 1
                    if loco:
                        var fw := tf.global_basis.z
                        if absf(angle_difference(atan2(fw.x, fw.z), atan2(bv.x, bv.y))) > deg_to_rad(100.0):
                            _moon += 1
                    elif spd > 0.6:
                        _glide += 1
                        var gk := "%s %s %s par=%s" % [tf.role, tf.person_name, cur, tf.get_parent().name]
                        _gwho[gk] = int(_gwho.get(gk, 0)) + 1
                        if int(_gwho[gk]) == 30 and OS.get_cmdline_user_args().has("--why"):
                            print("WHY ", gk, " move=", ap.get_meta("rig_move", "-"), " gait=", ap.get_meta("rig_gait", "-"), " loop=", ap.get_meta("rig_loop", "-"), " vs=", tf._vs, " spd=", spd, " route=", tf._route.size(), " stay=", tf.stay, " leader=", tf.leader != null, " t=", _f / 60, " ss=", ap.speed_scale, " q=", ap.get_queue())
        # the planted ankle
        var pl: Vector3 = (sk.global_transform * sk.get_bone_global_pose(il)).origin
        var pr: Vector3 = (sk.global_transform * sk.get_bone_global_pose(ir)).origin
        var low := il if pl.y < pr.y else ir
        var lp := pl if low == il else pr
        var rel := lp.y - bp.y
        var an: Array = _ank.get(tf, [INF, -1, Vector3.ZERO])
        var mn := minf(float(an[0]), rel)
        if int(an[1]) == low and rel < mn + 0.02 * ks and (_loco(cur) or (h.size() > 1 and (h[h.size() - 2] as Vector3).distance_to(bp) > 0.005)):
            var pv: Vector3 = an[2]
            var fd := Vector2(lp.x - pv.x, lp.z - pv.z).length() / dt
            if fd < 20.0:
                _slide.append(fd)
                var key2 := cur if cur != "" else "(none)"
                if not _slide_clip.has(key2):
                    _slide_clip[key2] = []
                (_slide_clip[key2] as Array).append(fd)
        _ank[tf] = [mn, low, lp]
    for k in _hist.keys():
        if not seen.has(k):
            _hist.erase(k)
            _ank.erase(k)
    _bodies = maxi(_bodies, seen.size())

func _process(_d: float) -> bool:
    _f += 1
    if _f == 240:
        var rd = _t.get("raids")
        if rd:
            rd.force_level = 5
            rd.call("raid", "west")
            print("RAID started")
    if _f % 120 == 1:
        _list = _people()
    if _f % 1200 == 0:
        print("T=", _f / 60, "s skate_n=", _skate.size(), " moving=", _moving, " moon=", _moon, " glide=", _glide)
    if _f >= SECS * 60:
        for k in _skate_clip.keys():
            var arr: Array = _skate_clip[k]
            if arr.size() > 300:
                var sl: Array = _slide_clip.get(k, [])
                print("  CLIP %-20s n=%6d skate median=%.2f p90=%.2f | ankle slide median=%.2f p90=%.2f" % [k, arr.size(), _q(arr, 0.5), _q(arr, 0.9), _q(sl, 0.5), _q(sl, 0.9)])
        var gks: Array = _gwho.keys()
        gks.sort_custom(func(a, b): return int(_gwho[a]) > int(_gwho[b]))
        for k in gks.slice(0, 6):
            print("  GLIDE ", _gwho[k], "  ", k)
        var mfrac := float(_moon) / maxf(1.0, float(_moving))
        var med := _q(_skate, 0.5)
        var p90 := _q(_skate, 0.9)
        print("RIG gait_swaps=", Rig.gait_swaps, " pace=", Townsfolk.pace, " on_the_spot=", _onspot)
        var ok := med < 0.15 and p90 < 0.50 and mfrac < 0.002
        print("D17B_TEST bodies=%d samples=%d skate_median=%.3f skate_p90=%.3f ankle_slide_median=%.3f ankle_slide_p90=%.3f moving=%d moonwalk=%d (%.2f%%) glide=%d %s" % [_bodies, _skate.size(), med, p90, _q(_slide, 0.5), _q(_slide, 0.9), _moving, _moon, mfrac * 100.0, _glide, "PASS" if ok else "FAIL"])
        return true
    return false

func _q(a: Array, q: float) -> float:
    if a.is_empty():
        return 0.0
    var s := a.duplicate()
    s.sort()
    return float(s[clampi(int(q * s.size()), 0, s.size() - 1)])
