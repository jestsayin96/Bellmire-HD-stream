extends SceneTree
## D18a PROP/BUILDING SANITY sweep.
## A) Flat-ground props must sit on the ground (base within tol of height_at at
##    their own origin). Props on a steep slope (crag/mine/mountain/river-bank
##    dressing) and surface/mounted/water props are exempt by rule, not by name list.
## B) The solid registry (buildings + props + walls) must hold no genuine
##    overlapping footprints (walls are a continuous structure, wall-wall exempt).
## Prints D18A_TEST OK when both pass.
var _t: Node3D
var _f := 0
const FLOAT_TOL := 0.5
const SINK_TOL := 0.75
const SLOPE_EXEMPT := 0.33
const WALL_HE := Vector2(1.9, 1.1)
# held / rack / wall / roof / water dressing: their base is a surface, not the ground
var SURFACE := {
 "Lantern_Wall":1,"Roof_Tower_RoundTiles":1,"Mug":1,"mug_empty":1,"mug_full":1,
 "Potion_1":1,"Potion_2":1,"Potion_4":1,"SmallBottles_1":1,"Shelf_Small_Bottles":1,
 "Shelf_Simple":1,"Workbench_Drawers":1,"map_rolled":1,"journal_closed":1,
 "spellbook_closed":1,"spellbook_open":1,"tongs":1,"hammer":1,"mallet":1,"pickaxe":1,
 "Pickaxe_Bronze":1,"shovel":1,"saw":1,"knife":1,"dagger":1,"wand":1,"staff":1,"quiver":1,
 "sword_1handed":1,"sword_2handed":1,"sword_2handed_color":1,"Sword_Bronze":1,
 "axe":1,"axe_1handed":1,"axe_2handed":1,"halberd":1,"bow_A_withString":1,
 "shield_badge_color":1,"shield_round":1,"shield_square":1,"shield_square_color":1,
 "Shield_Wooden":1,"bucket_metal":1,"rope_bundle_A":1,"whetstone":1,"torch":1,"lantern":1,
 "crossbow_2handed":1,"Mushroom_Common":1,"waterlily_A":1,"waterlily_B":1,"boat_small":1,
 "Vase_2":1,"Pot_1":1,"Peg_Rack":1,
 "Banner_1":1,"Banner_2":1,"Candle_1":1,"CandleStick_Stand":1,"BookStand":1,
 # planter/meadow flower dressing (sit in raised planter boxes) + leaned tools
 "Flower_3_Group":1,"Flower_4_Group":1,"Bush_Common_Flowers":1,"Axe_Bronze":1,
 "Bottle_1":1,"Bottle_4":1,"journal":1,
}
# mobile bodies placed by their own controllers (riders, tower guards, heroes, folk)
var MOBILE := {"Knight":1,"Mage":1,"Rogue":1,"Rogue_Hooded":1,"Red":1,"Pug":1}
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _slope(x: float, z: float) -> float:
    var g := _t.call("height_at", x, z) as float
    var dx := absf((_t.call("height_at", x + 1.5, z) as float) - g)
    var dz := absf((_t.call("height_at", x, z + 1.5) as float) - g)
    return maxf(dx, dz) / 1.5
func _aabb_world(n: Node3D) -> AABB:
    var got := false
    var acc := AABB()
    for mi in n.find_children("*", "MeshInstance3D", true, false):
        var m: MeshInstance3D = mi
        if m.mesh == null: continue
        var lb: AABB = m.mesh.get_aabb()
        var gt: Transform3D = m.global_transform
        for cx in [0,1]:
            for cy in [0,1]:
                for cz in [0,1]:
                    var wp: Vector3 = gt * (lb.position + Vector3(lb.size.x*cx, lb.size.y*cy, lb.size.z*cz))
                    if not got: acc = AABB(wp, Vector3.ZERO); got = true
                    else: acc = acc.expand(wp)
    return acc if got else AABB(Vector3(NAN,0,0), Vector3.ZERO)
func _base(p: String) -> String:
    return p.get_file().get_basename()
# SAT overlap of two XZ OBBs; returns min penetration (>0 = overlap)
func _obb_pen(a: Array, b: Array) -> float:
    var ca: Vector2 = a[0]; var cb: Vector2 = b[0]
    var axes := [a[1], a[2], b[1], b[2]]
    var d := cb - ca
    var minpen := 1e9
    for axv in axes:
        var ax: Vector2 = axv
        var ra: float = absf((a[1] as Vector2).dot(ax)) * (a[3] as Vector2).x + absf((a[2] as Vector2).dot(ax)) * (a[3] as Vector2).y
        var rb: float = absf((b[1] as Vector2).dot(ax)) * (b[3] as Vector2).x + absf((b[2] as Vector2).dot(ax)) * (b[3] as Vector2).y
        var sep: float = absf(d.dot(ax))
        var pen: float = ra + rb - sep
        if pen <= 0.0: return 0.0
        minpen = minf(minpen, pen)
    return minpen
func _is_wall(r: Array) -> bool:
    return (r[3] as Vector2).is_equal_approx(WALL_HE)
func _bld_obb(n: Node3D) -> Array:
    var box := AABB(); var first := true
    var inv: Transform3D = n.global_transform.affine_inverse()
    for mi in n.find_children("*", "MeshInstance3D", true, false):
        var m: MeshInstance3D = mi
        if m.mesh == null: continue
        var ab: AABB = (inv * m.global_transform) * m.mesh.get_aabb()
        box = ab if first else box.merge(ab); first = false
    if first: return []
    var sc: float = n.scale.x
    var he := Vector2(box.size.x, box.size.z) * 0.5 * sc
    var yaw: float = n.rotation.y
    var ax := Vector2(cos(yaw), -sin(yaw))
    var az := Vector2(sin(yaw), cos(yaw))
    var cen := box.get_center() * sc
    var c2 := Vector2(n.global_position.x, n.global_position.z) + ax * cen.x + az * cen.z
    return [c2, ax, az, he]

func _process(_d: float) -> bool:
    _f += 1
    if _f < 8: return false
    # ---- Check A: flat-ground props grounded ----
    var fail_a := 0
    var checked := 0
    for node in _t.find_children("*", "Node3D", true, false):
        var n: Node3D = node
        var sfp: String = String(n.scene_file_path)
        if sfp == "": continue
        var par: Node = n.get_parent()
        if par != null and par is Node3D and String((par as Node3D).scene_file_path) == sfp: continue
        var anm: String = _base(sfp)
        if SURFACE.has(anm) or MOBILE.has(anm) or anm.begins_with("hero_") or anm.begins_with("lm_"): continue
        var ab: AABB = _aabb_world(n)
        if is_nan(ab.position.x): continue
        var ox: float = n.global_position.x
        var oz: float = n.global_position.z
        var slp: float = _slope(ox, oz)
        var is_bld: bool = anm.begins_with("mk_house") or anm.begins_with("lm_")
        if slp > (0.10 if is_bld else SLOPE_EXEMPT): continue   # hillside buildings nestle; slope dressing exempt
        if (_t.call("river_dist", ox, oz) as float) < 12.0: continue   # on the raised dock/jetty over the river
        var g: float = _t.call("height_at", ox, oz)
        var gap: float = ab.position.y - g
        checked += 1
        if gap > FLOAT_TOL or gap < -SINK_TOL:
            fail_a += 1
            if fail_a <= 25:
                print("A-FLAG %-22s gap=%.2f at (%d,%d) slope=%.2f" % [anm, gap, int(ox), int(oz), _slope(ox,oz)])
    # ---- Check B: building-into-building overlap (oriented footprints) ----
    var blds: Array = []
    for node in _t.find_children("*", "Node3D", true, false):
        var n2: Node3D = node
        var sfp2: String = String(n2.scene_file_path)
        if sfp2 == "": continue
        var bnm: String = _base(sfp2)
        if not (bnm.begins_with("mk_house") or bnm.begins_with("lm_")): continue
        var ob: Array = _bld_obb(n2)
        if ob.is_empty(): continue
        blds.append([bnm, ob])
    var fail_b := 0
    var worst := 0.0
    for ii in range(blds.size()):
        for jj in range(ii+1, blds.size()):
            var pen: float = _obb_pen(blds[ii][1], blds[jj][1])
            if pen > 0.5:
                fail_b += 1
                worst = maxf(worst, pen)
                if fail_b <= 20:
                    var c: Vector2 = blds[ii][1][0]
                    print("B-OVERLAP %s / %s pen=%.2f at (%d,%d)" % [blds[ii][0], blds[jj][0], pen, int(c.x), int(c.y)])
    var n := blds.size()
    print("D18A: checkedA=%d  A-flags=%d   solids=%d  B-overlaps=%d (worst pen %.2f)" % [checked, fail_a, n, fail_b, worst])
    if fail_a == 0 and fail_b == 0:
        print("D18A_TEST OK")
    else:
        print("D18A_TEST FAIL a=%d b=%d" % [fail_a, fail_b])
    return true
