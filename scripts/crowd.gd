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

## ---- D91 THE SETTLE, shared by the dungeon and the town (one copy - it began in delve.gd).
## Run LATE in the frame, after every walker has taken its step: parts any pair of bodies still
## closer than the sum of their body_r (the done test's line), the smaller body giving way, and
## only ever to a spot ok(p, r) accepts - the dungeon's "on a floor cell, clear of the wall and
## every obstacle", the town's "outside every solid footprint". A pinned body (instance id in
## `pinned` - a townsman sat on a bench, at his post at a stall) is never moved; the other one
## steps out of it. Pinned against stone on both sides, a pair slides sideways along it.
## D91c: one side's half-step fits but its full step does not (a body with stone at its back):
## it slides along the stone instead of giving up - the one 1.9 cm frame the 20-minute dungeon
## re-soak of D91b's loop found in 165k. Four passes, not three, for a pack of sixteen; up to
## ten for a street crowd (the festival puts a hundred folk on the green in one frame, and four
## rounds of half-steps do not untangle that). A pass that finds nobody truly inside anybody ends
## it, so a quiet frame costs one pass.
## Up to SETTLE_SMALL bodies every pair is checked (the dungeon);
## more than that (the town's streets) are bucketed on a 2 m grid, rebuilt every pass.
## Returns the deepest overlap the last pass found.
const SETTLE_PASSES := 4
const SETTLE_PASSES_BIG := 10     # a street crowd: the whole town poured onto the green at once
const SETTLE_PAD := 0.02
const SETTLE_SMALL := 48
static var passes_run := 0        # D91c: how many passes the settles have taken (perf probe)

static func settle(bodies: Array, ok: Callable, pinned := {}) -> float:
    var n := bodies.size()
    if n < 2:
        return 0.0
    var worst := 0.0
    var rs: Array[float] = []
    for _pass in range(SETTLE_PASSES if n <= SETTLE_SMALL else SETTLE_PASSES_BIG):
        passes_run += 1
        var moved := false
        worst = 0.0
        if n <= SETTLE_SMALL:
            for i in range(n):
                for j in range(i + 1, n):
                    var r := _settle_pair(bodies[i], bodies[j], ok, pinned)
                    worst = maxf(worst, r[0])
                    moved = moved or r[1]
        else:
            # (the pair test is inlined as a cheap distance check first - only a pair that
            # actually overlaps pays for _settle_pair; it returns nothing for the rest anyway)
            var grid := {}
            var ps: Array[Vector3] = []
            ps.resize(n)
            for i in range(n):
                var p: Vector3 = (bodies[i] as Node3D).global_position
                ps[i] = p
                var k := Vector2i(floori(p.x * 0.5), floori(p.z * 0.5))
                if not grid.has(k):
                    grid[k] = []
                (grid[k] as Array).append(i)
            if rs.is_empty():
                rs.resize(n)
                for i in range(n):
                    rs[i] = body_r(bodies[i])
            for i in range(n):
                var p: Vector3 = ps[i]
                var ri: float = rs[i]
                var k := Vector2i(floori(p.x * 0.5), floori(p.z * 0.5))
                for dx in range(-1, 2):
                    for dz in range(-1, 2):
                        var cell = grid.get(Vector2i(k.x + dx, k.y + dz))
                        if cell == null:
                            continue
                        for j in cell:
                            if int(j) <= i:
                                continue
                            var q: Vector3 = ps[j]
                            var reach: float = ri + rs[j] + SETTLE_PAD
                            if (p.x - q.x) * (p.x - q.x) + (p.z - q.z) * (p.z - q.z) >= reach * reach:
                                continue
                            var r := _settle_pair(bodies[i], bodies[j], ok, pinned)
                            worst = maxf(worst, r[0])
                            if r[1]:
                                moved = true
                                ps[i] = (bodies[i] as Node3D).global_position
                                ps[j] = (bodies[j] as Node3D).global_position
                                p = ps[i]
        if not moved:
            break
        # a street crowd: a pass that found nobody truly inside anybody (only the 2 cm pad) has
        # done the job - walkers held at arm's length by crowd_push sit on that pad all day, and
        # nudging them round it ten times a frame cost 3 ms (6.3 passes a run, D91c perf probe)
        if n > SETTLE_SMALL and worst <= 0.0:
            break
    return worst

## one pair: [how deep they overlapped (0 if not), whether anyone was moved]
static func _settle_pair(a: Node3D, b: Node3D, ok: Callable, pinned: Dictionary) -> Array:
    var pa := a.global_position
    var pb := b.global_position
    if absf(pa.y - pb.y) > 3.0:
        return [0.0, false]
    var ra := body_r(a)
    var rb := body_r(b)
    var d := Vector3(pa.x - pb.x, 0.0, pa.z - pb.z)
    var L := d.length()
    var over := ra + rb + SETTLE_PAD - L
    if over <= 0.0:
        return [0.0, false]
    var deep := over - SETTLE_PAD
    if L < 0.01:
        var ang := float((a.get_instance_id() + b.get_instance_id()) % 628) * 0.01
        d = Vector3(cos(ang), 0.0, sin(ang))
        L = 1.0
    var nrm := d / L
    var pin_a := pinned.has(a.get_instance_id())
    var pin_b := pinned.has(b.get_instance_id())
    if pin_a and pin_b:
        return [deep, false]
    # the smaller body gives way: a lord is not shouldered aside by a halfling
    var ka := rb / (ra + rb)
    var kb := ra / (ra + rb)
    var na := pa + nrm * over * ka
    var nb := pb - nrm * over * kb
    var oka: bool = not pin_a and ok.call(na, ra, a)
    var okb: bool = not pin_b and ok.call(nb, rb, b)
    if oka and okb:
        a.global_position = na
        b.global_position = nb
    elif oka or (pin_b and not pin_a):
        na = pa + nrm * over
        if ok.call(na, ra, a):
            a.global_position = na
        else:
            var sa := _perp(nrm, L, ra + rb + SETTLE_PAD)
            if ok.call(pa + sa, ra, a):
                a.global_position = pa + sa
            elif ok.call(pa - sa, ra, a):
                a.global_position = pa - sa
            else:
                return [deep, false]
    elif okb or (pin_a and not pin_b):
        nb = pb - nrm * over
        if ok.call(nb, rb, b):
            b.global_position = nb
        else:
            var sb := _perp(nrm, L, ra + rb + SETTLE_PAD)
            if ok.call(pb - sb, rb, b):
                b.global_position = pb - sb
            elif ok.call(pb + sb, rb, b):
                b.global_position = pb + sb
            else:
                return [deep, false]
    else:
        # pinned between stone on both sides: slide sideways along the wall.
        # D91e: the slide must be the FULL perpendicular that clears the pair
        # (sqrt(need^2 - L^2)), not `over` - a sideways step of `over` only
        # grows the gap to sqrt(L^2 + over^2) and left a ~1 cm residual in
        # the north store's alcove. Try one body, then the other, then both
        # going opposite ways by half each.
        var side := _perp(nrm, L, ra + rb + SETTLE_PAD)
        if ok.call(pa + side, ra, a):
            a.global_position = pa + side
        elif ok.call(pb - side, rb, b):
            b.global_position = pb - side
        elif ok.call(pa - side, ra, a):
            a.global_position = pa - side
        elif ok.call(pb + side, rb, b):
            b.global_position = pb + side
        elif ok.call(pa + side * 0.5, ra, a) and ok.call(pb - side * 0.5, rb, b):
            a.global_position = pa + side * 0.5
            b.global_position = pb - side * 0.5
        elif ok.call(pa - side * 0.5, ra, a) and ok.call(pb + side * 0.5, rb, b):
            a.global_position = pa - side * 0.5
            b.global_position = pb + side * 0.5
        else:
            return [deep, false]
    return [deep, true]

## D91e: the sideways step that clears a pair at axis distance L, needing `need`
## between centres: sqrt(need^2 - L^2) along the perpendicular (plus a hair).
static func _perp(nrm: Vector3, L: float, need: float) -> Vector3:
    var s := sqrt(maxf(need * need - L * L, 0.0)) + 0.002
    return Vector3(-nrm.z, 0.0, nrm.x) * s

