class_name Cavalry
extends Townsfolk

## D4: the MOUNTED WATCH - Bellmire's town guards on horseback, and only them.
## A watchman (Knight body, garrison livery, sword and shield) sat on one of the
## Quaternius Farm Animals horses (CC0, the same horse that stands in the Town
## Stables). From the stables they ride a loop of the roads - every gate, the
## market, the bridge - and when a raid comes they ride out with the garrison
## (raids.gd treats them as guards, faster and harder to unhorse).
## The walking half is Townsfolk's own (navmesh routes, crowd room); this only
## seats the rider, keeps him seated, and picks the horse's gait from how fast
## the pair actually moves.

const HORSE := "res://assets/animals/Horse.glb"
const HORSE_SCALE := 0.27          # town.gd ANIMALS["Horse"], growth.gd HORSE_SCALE
const SEAT := "Sit_Chair_Idle"     # knees forward, hands low: reads as astride
const SEAT_K := 0.60               # saddle height as a share of the horse's full height
const SEAT_BACK := 0.06            # saddle sits a little behind the middle (share of length)

var _horse: Node3D
var _hap: AnimationPlayer
var _rap: AnimationPlayer           # the rider's own player (Townsfolk._anim is left null)
var _last := Vector3.INF
var _gait := ""
var _strike_t := 0.0
var _v := 0.0
var seat_h := 1.2
var ridden := 0.0                   # metres covered (tests)

func _ready() -> void:
    body_r = 0.6                    # D16a: a horse takes more room than a man
    super._ready()
    var ps: PackedScene = load(HORSE)
    if ps:
        _horse = ps.instantiate()
        _horse.name = "Mount"
        _horse.scale = Vector3.ONE * HORSE_SCALE
        add_child(_horse)
        _hap = Rig.find(_horse)
        if _hap:
            for a in ["Walk", "Run", "Idle", "WalkSlow"]:
                if _hap.has_animation(a):
                    _hap.get_animation(a).loop_mode = Animation.LOOP_LINEAR
        var bb := _bounds(_horse)
        if bb.size.y > 0.1:
            seat_h = bb.size.y * SEAT_K + bb.position.y
            if _mdl:
                _mdl.position.z = bb.get_center().z - bb.size.z * SEAT_BACK
    if _mdl:
        _mdl.position.y = seat_h
    _rap = _anim
    _anim = null                    # Townsfolk would play walking legs on a rider
    if _rap and _rap.has_animation(SEAT):
        _rap.get_animation(SEAT).loop_mode = Animation.LOOP_LINEAR
        Rig.play(_rap, SEAT)
    _gallop("Idle", 1.0)

## the horse's own size, in this node's space
func _bounds(n: Node3D) -> AABB:
    var out := AABB()
    var first := true
    var st: Array = [n]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is MeshInstance3D and (c as MeshInstance3D).mesh:
            var mi: MeshInstance3D = c
            var xf: Transform3D = global_transform.affine_inverse() * mi.global_transform if is_inside_tree() else _rel(mi)
            var b: AABB = xf * mi.get_aabb()
            out = b if first else out.merge(b)
            first = false
        for g in c.get_children():
            st.append(g)
    return out

func _rel(n: Node3D) -> Transform3D:
    var xf := Transform3D.IDENTITY
    var c: Node = n
    while c != null and c != self:
        if c is Node3D:
            xf = (c as Node3D).transform * xf
        c = c.get_parent()
    return xf

func _gallop(g: String, sc: float) -> void:
    if _hap == null:
        return
    _hap.speed_scale = sc
    if g == _gait or not _hap.has_animation(g):
        return
    _gait = g
    _hap.play(g, 0.3)

## raids.gd: what a fight asks of a rider. Only the swing shows; the rest of
## the time he stays in the saddle.
func mounted(key: String) -> void:
    if key == "attack" and _rap:
        Rig.play(_rap, "1H_Melee_Attack_Chop", 0.1)
        _strike_t = 0.85
    elif key == "die" and _rap:
        Rig.play(_rap, "Death_A")
        _strike_t = 99.0

func _process(delta: float) -> void:
    if delta <= 0.0:
        return
    var p := global_position
    if _last != Vector3.INF:
        var moved := Vector2(p.x - _last.x, p.z - _last.z).length()
        ridden += moved
        _v = lerpf(_v, moved / delta, minf(delta * 6.0, 1.0))
    _last = p
    if _v > 2.6:
        _gallop("Run", clampf(_v / 7.0, 0.6, 1.4))
    elif _v > 0.25:
        _gallop("Walk", clampf(_v / 1.6, 0.6, 1.6))
    else:
        _gallop("Idle", 1.0)
    if _strike_t > 0.0:
        _strike_t -= delta
        if _strike_t <= 0.0 and _rap:
            Rig.play(_rap, SEAT, 0.2)
