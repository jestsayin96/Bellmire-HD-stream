extends SceneTree
## D20c: ANIMAL-BEHAVIOUR probe. Boots the town, warms up, then soaks ~45 s and
## checks the three things Mr. E asked for:
##   HERDS DRIFT   - each herd has a shared centre that ambles the pen, and its
##                   beasts stay clustered around it (cohesion), not scattered.
##                   PASS: a herd's centre moved, and herds stay in a tight group.
##   DOGS FOLLOW   - the town dogs trot after the nearest townsperson; at least
##                   one gets right up on someone during the run (Animal.follows>0).
##   BIRDS FLOCK   - birds wheel as a knot AND the flock migrates across the sky.
##                   PASS: every flock's centre moved, and its birds stay bunched.
var _t: Node3D
var _f := 0
var WARM := 360
var SECS := 45
# herds
var herd_moved_max := 0.0
var herd_spread_sum := 0.0
var herd_spread_n := 0
# dogs
var dog_near_frac_num := 0
var dog_near_frac_den := 0
var dog_min := 1e9
# birds
var flock_moved_min := 1e9
var flock_spread_bad := 0      # flocks seen scattered (spread > 2.2*r) at any sample

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _sample() -> void:
    var animals: Array = _t.get("animals")
    var people: Array = _t.get("people")
    var herds: Array = _t.get("_herds")
    var flocks: Array = _t.get("_flocks")
    var birds: Array = _t.get("_birds")
    # --- herds: cluster tightness of each herd's members around their centroid
    for hm in herds:
        var mem: Array = []
        for a in animals:
            if is_instance_valid(a) and a.herd == hm and not a.orbit:
                mem.append((a as Node3D).global_position)
        if mem.size() < 2:
            continue
        var cen := Vector3.ZERO
        for q in mem:
            cen += q
        cen /= float(mem.size())
        var mx := 0.0
        for q in mem:
            mx = maxf(mx, Vector2(q.x - cen.x, q.z - cen.z).length())
        herd_spread_sum += mx
        herd_spread_n += 1
    # --- dogs: nearest outdoor person to each follow-dog
    for a in animals:
        if not (is_instance_valid(a) and a.follow):
            continue
        var best := 1e9
        for v in people:
            if not is_instance_valid(v) or not v.visible or v.inside:
                continue
            best = minf(best, (a as Node3D).global_position.distance_to((v as Node3D).global_position))
        if best < 1e8:
            dog_near_frac_den += 1
            dog_min = minf(dog_min, best)
            if best < 6.0:
                dog_near_frac_num += 1
    # --- birds: each flock's members stay in a knot
    for fl in flocks:
        var r: float = float(fl["r"])
        var pts: Array = []
        for b in birds:
            if b[1] == fl:
                pts.append((b[0] as Node3D).global_position)
        var mx := 0.0
        for i in range(pts.size()):
            for j in range(i + 1, pts.size()):
                var pa: Vector3 = pts[i]
                var pb: Vector3 = pts[j]
                mx = maxf(mx, Vector2(pa.x - pb.x, pa.z - pb.z).length())
        if pts.size() >= 2 and mx > 2.2 * r:
            flock_spread_bad += 1

func _process(_d: float) -> bool:
    _f += 1
    if _f < WARM:
        return false
    if _f % 15 == 0:
        _sample()
    if _f % 600 == 0:
        var herds: Array = _t.get("_herds")
        var flocks: Array = _t.get("_flocks")
        for hm in herds:
            herd_moved_max = maxf(herd_moved_max, float(hm.moved))
        for fl in flocks:
            flock_moved_min = minf(flock_moved_min, float(fl["moved"]))
        print("T=", _f / 60, "s herds=", herds.size(), " herd_moved_max=%.1f" % herd_moved_max,
              " flocks=", flocks.size(), " flock_moved_min=%.1f" % flock_moved_min,
              " dog_near=%d/%d" % [dog_near_frac_num, dog_near_frac_den], " dog_min=%.1f" % dog_min,
              " follows=", Animal.follows)
    if _f >= WARM + SECS * 60:
        var herds: Array = _t.get("_herds")
        var flocks: Array = _t.get("_flocks")
        for hm in herds:
            herd_moved_max = maxf(herd_moved_max, float(hm.moved))
        for fl in flocks:
            flock_moved_min = minf(flock_moved_min, float(fl["moved"]))
        var herd_spread := herd_spread_sum / maxf(1.0, float(herd_spread_n))
        var dog_frac := float(dog_near_frac_num) / maxf(1.0, float(dog_near_frac_den))
        print("--- D20c results ---")
        print("  herds=", herds.size(), " herd_moved_max=%.1f (drift)" % herd_moved_max,
              " mean_cluster_radius=%.1f (cohesion)" % herd_spread)
        print("  dogs follows=", Animal.follows, " near_frac=%.2f" % dog_frac, " min_dist=%.1f" % dog_min)
        print("  flocks=", flocks.size(), " flock_moved_min=%.1f (migration)" % flock_moved_min,
              " scattered_samples=", flock_spread_bad)
        var checks := {
            "herds_drift": herd_moved_max > 3.0,
            "herds_cohere": herd_spread_n > 0 and herd_spread < 8.0,
            "dogs_follow": Animal.follows > 0 and dog_min < 5.5,
            "birds_migrate": flocks.size() > 0 and flock_moved_min > 2.0,
            "birds_cohere": flock_spread_bad == 0,
        }
        var miss: Array = []
        for k in checks:
            if not bool(checks[k]):
                miss.append(k)
        print("D20C_TEST %s missing=%s" % ["PASS" if miss.is_empty() else "FAIL", str(miss)])
        return true
    return false
