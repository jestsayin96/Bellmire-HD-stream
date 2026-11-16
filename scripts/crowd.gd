class_name Crowd
extends RefCounted
## D91 stage 1: the D16a LOCAL AVOIDANCE, lifted out of town.gd so the town and
## the dungeon run ONE copy of it (two copies drift, then there are two bugs).
## The town's numbers and maths are unchanged - town.crowd_push now fills a
## Crowd once a physics frame and asks it; tools/_d91_crowd.gd holds the old
## town code verbatim and checks the two agree on every sample.
##
## A coarse 2 m grid of every body, rebuilt by its owner once a physics frame;
## push(v, dir) is the shove away from whoever stands closer than CROWD_R.
## The shove is a velocity (m/s). Soft out to CROWD_R, hard inside two bodies'
## width (faster than anyone walks, so nobody is ever walked through). Given
## the walker's heading it also YIELDS: someone in the way within CROWD_LOOK m
## ahead is passed on the side away from them (dead ahead: the walker's right)
## - the one coming the other way does the same, so two folk meeting in a gate
## step aside and pass instead of walking into each other. Someone ahead going
## the same way more slowly is followed, not shoved.
##
## A body may carry `body_r` (centre to shoulder, default 0.28) and `move_dir`
## (this step's heading) - push reads both.

const CROWD_R := 0.75
const CROWD_LOOK := 2.2
const CROWD_SOFT := 1.4        # m/s at the middle of the soft ring (the old shove)
const CROWD_HARD := 5.0        # m/s at full overlap
const CROWD_YIELD := 2.2       # m/s sidestep for someone dead ahead and close
const BODY_R := 0.28

var frame := -1                # the physics frame the grid was last filled on
var _cells: Dictionary = {}

## how wide someone is (centre to shoulder): folk, children, riders, animals,
## delvers, monsters
static func body_r(o: Node3D) -> float:
    var r = o.get("body_r")
    return float(r) if r != null else BODY_R

## true when the grid is already filled for this physics frame; otherwise
## empties it and marks it filled, so the caller adds this frame's bodies
func fresh() -> bool:
    var f := Engine.get_physics_frames()
    if f == frame:
        return true
    frame = f
    _cells.clear()
    return false

## D91: empty the grid for an owner that keeps its own frame clock (the Delve runs on process
## frames, not physics frames)
func reset() -> void:
    _cells.clear()

func add(o: Node3D) -> void:
    var op: Vector3 = o.global_position
    var key := Vector2i(floori(op.x * 0.5), floori(op.z * 0.5))
    if not _cells.has(key):
        _cells[key] = []
    (_cells[key] as Array).append(o)

func push(v: Node3D, dir := Vector3.ZERO) -> Vector3:
    var p := v.global_position
    var rv := body_r(v)
    var kx := floori(p.x * 0.5)
    var kz := floori(p.z * 0.5)
    var out := Vector3.ZERO
    var side := Vector3(-dir.z, 0.0, dir.x)       # the walker's right
    var yield_best := 0.0
    var yield_dir := Vector3.ZERO
    var reach := 2 if dir != Vector3.ZERO else 1
    for dx in range(-reach, reach + 1):
        for dz in range(-reach, reach + 1):
            var cell = _cells.get(Vector2i(kx + dx, kz + dz))
            if cell == null:
                continue
            for o in cell:
                if o == v:
                    continue
                var op: Vector3 = (o as Node3D).global_position
                if absf(op.y - p.y) > 3.0:
                    continue                    # a delver far below, not a neighbour
                var d := Vector3(p.x - op.x, 0.0, p.z - op.z)
                var L := d.length()
                var contact := rv + body_r(o)
                var ring := maxf(CROWD_R, contact + 0.15)
                if L < ring:
                    if L < 0.01:
                        d = Vector3(cos(float(v.get_instance_id() % 628) * 0.01), 0.0, sin(float(v.get_instance_id() % 628) * 0.01))
                        L = 0.01
                    var n := d / L
                    out += n * CROWD_SOFT * 2.0 * (ring - L) / ring
                    if L < contact:
                        out += n * CROWD_HARD * (contact - L) / contact
                if dir == Vector3.ZERO:
                    continue
                # yield: who is in the way ahead
                var rel := -d                      # me -> them
                var ahead := rel.dot(dir)
                if ahead <= 0.05 or ahead > CROWD_LOOK:
                    continue
                var lat := rel.dot(side)
                var clear := contact + 0.2
                if absf(lat) >= clear:
                    continue
                # going my way and not slower: no need to pass them
                var ov = o.get("move_dir")
                var odir: Vector3 = ov if ov is Vector3 else Vector3.ZERO
                if odir.dot(dir) > 0.6:
                    continue
                var w := (1.0 - ahead / CROWD_LOOK) * (1.0 - absf(lat) / clear)
                if w > yield_best:
                    yield_best = w
                    # pass on the side away from them; dead ahead keep right
                    yield_dir = -side if lat > 0.08 else side
    if yield_best > 0.0:
        out += yield_dir * CROWD_YIELD * yield_best
    return out

## the worst overlap among the bodies in the grid: [pairs closer than the sum
## of their body_r, the deepest overlap in m] - the D91 done-test's counter
func overlaps() -> Array:
    var n := 0
    var worst := 0.0
    for key in _cells:
        var k: Vector2i = key
        for dx in range(0, 2):
            for dz in range(-1, 2):
                if dx == 0 and dz < 0:
                    continue
                var other = _cells.get(Vector2i(k.x + dx, k.y + dz))
                if other == null:
                    continue
                var mine: Array = _cells[key]
                for i in range(mine.size()):
                    var a: Node3D = mine[i]
                    var j0 := i + 1 if (dx == 0 and dz == 0) else 0
                    for j in range(j0, (other as Array).size()):
                        var b: Node3D = other[j]
                        if absf(a.global_position.y - b.global_position.y) > 3.0:
                            continue
                        var L := Vector2(a.global_position.x - b.global_position.x, a.global_position.z - b.global_position.z).length()
                        var o := body_r(a) + body_r(b) - L
                        if o > 0.0:
                            n += 1
                            worst = maxf(worst, o)
    return [n, worst]
