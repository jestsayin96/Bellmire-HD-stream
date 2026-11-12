class_name Valley
extends Node3D
## D12: the valley beyond the walls. Bellmire's wall was the edge of the world -
## past it a sawmill, a mine, three farms and the Delvers' Road. Now the country
## around it is lived in, from what the original game already had:
##   - outlying steadings "where a highway leaves the wall" (the old town.gd: a
##     cottage and a well): Coalfoot Steading over the river, Bramble End by the
##     east road. Names are the lore's own surnames (town.gd LAST).
##   - the woods "belong OUTSIDE the wall" and the lumbermill stands "against the
##     treeline": the Ashwood, a stand of pine and oak south of the river with a
##     woodcutters' camp in it (the lore's Ashwood; the Ash-wood Circlet).
##   - the ford ("of the Ford", "Friend of the Ford"): a gravel bar across the
##     river west of the bridge, and the Ford Mill turning beside it.
##   - the Old Footing: a ring of broken stone on the north slope. Someone built
##     here first, and stopped all at once. Never says who (the scar's two
##     readings stay open).
##   - dirt roads linking them to the gates and the bridge; travellers and carts
##     walk them (navmesh routes, like the caravan); the director tours them.
## Everything is built once, BEFORE town._bake_nav: cottages, walls and stacks
## are carved out as footprints, trees as trunks, the ford left open.

const NATURE := "res://assets/nature/"
const PROPS := "res://assets/props/"
const MKPROPS := "res://assets/mkprops/"
const WATER_Y := -0.9              # mirrors town.WATER_Y (river surface)
const RIVER_W := 7.0               # mirrors town.RIVER_W (half-width of open water)
const LANE_W := 3.4
const MAX_TRAVELLERS := 4
## [from, to, with a cart, Chronicle line ("" = none)]
const TRIPS := [
    ["Coalfoot Steading", "the market", true, "A cart comes up the south road from Coalfoot Steading."],
    ["the Ashwood", "the sawmill", true, "A timber cart leaves the Ashwood for the sawmill."],
    ["Bramble End", "the market", false, ""],
    ["Coalfoot Steading", "the Ford Mill", true, "Grain goes down to the Ford Mill from Coalfoot."],
    ["the market", "the Old Footing", false, "Someone walks out to look at the Old Footing."],
    ["the Ford Mill", "Bramble End", false, ""],
    ["Bramble End", "the Ashwood", false, ""],
    ["the Ford Mill", "the market", true, "Flour comes in over the ford."],
]
const FOLK_MODELS := ["Rogue.glb", "Rogue_Hooded.glb", "Barbarian.glb"]

var town                        # town.gd (untyped: its fields are read by name)
var sites := {}                 # name -> {"pos": Vector3, "door": Vector3, "kind": String}
var ends := {}                  # trip end name -> Vector3 (walkable spot)
var tour: Array = []            # [pos, dist, pitch] - auto_director's slow tour
var travellers: Array = []      # {v, cart, a, b, phase, t, life}
var made := {"houses": 0, "trees": 0, "walls": 0, "stones": 0, "folk": 0, "roads": 0}
var trips_sent := 0
var trips_done := 0
var edge := 260.0               # the navmesh's half extent (town._bake_nav)
var _trip_t := 10.0
var _say_t := 0.0
var _rng := RandomNumberGenerator.new()
var _wood: StandardMaterial3D
var _moss: StandardMaterial3D
var _bark: StandardMaterial3D
var _soil: StandardMaterial3D
var _wheat: StandardMaterial3D
var _straw: StandardMaterial3D
var _hay: StandardMaterial3D
var _plank: StandardMaterial3D
var _d18b_fields: Array = []   # D18b: centres of the valley fields (for the test)

func setup(t) -> void:
    town = t
    name = "Valley"
    _rng.seed = 1212
    var sc: Vector3 = town._scar
    edge = maxf(260.0, Vector2(sc.x, sc.z).length() + 40.0)
    _mats()
    var bz: float = town._bridge_z
    # the west and east gates (the north gate has x > 0 too: pick by x)
    var gw := Vector3(-170.0, 0, 0)
    var ge := Vector3(170.0, 0, 0)
    for g in (town._wall_info as Dictionary).get("gates", []):
        var gv: Vector3 = g
        if gv.x < gw.x:
            gw = gv
        if gv.x > ge.x:
            ge = gv
    # sites first, then the roads between them, then the trees around the roads
    var ford := _ford()
    var coal := _hamlet("Coalfoot Steading", Vector3(-78.0, 0, bz + 62.0), Vector3(1, 0, 0), "green")
    var bram := _hamlet("Bramble End", Vector3(ge.x + 48.0, 0, ge.z - 42.0), Vector3(0, 0, 1), "red")
    var ash := _camp(Vector3(28.0, 0, bz + 104.0))
    var ruin := _ruins(Vector3(-88.0, 0, -178.0))
    # the South Road: off the bridge, a fork for Coalfoot, on into the Ashwood
    var s0 := Vector3(0, 0, bz + 18.0)
    var fork := Vector3(0, 0, bz + 46.0)
    _road([s0, fork, ash["entry"]])
    _road([fork, coal["east"]])
    # Coalfoot's west end down to the ford, over it, and up to the west road
    var rz: float = town.river_z_fast(town.ford_x)
    var fs := Vector3(town.ford_x, 0, rz + 16.0)
    var fn := Vector3(town.ford_x, 0, rz - 16.0)
    _road([coal["west"], coal["west"].lerp(fs, 0.5) + Vector3(0, 0, 6.0), fs])
    _road([fs, fn])
    _road([fn, Vector3(fn.x - 28.0, 0, 70.0), Vector3(fn.x - 45.0, 0, 30.0), Vector3(fn.x - 45.0, 0, gw.z + 3.0)])
    if ford.has("door"):
        _road([ford["door"], ford["door"].lerp(fs, 0.5) + Vector3(0, 0, 3.0), fs + Vector3(2.0, 0, 0)])
    # Bramble End's lane runs north onto the east road
    _road([bram["north"], Vector3(bram["north"].x, 0, ge.z - 4.0)])
    # the Old Footing: a track off the Delvers' Road
    _road([ruin["join"], ruin["gate"]])
    _forest(ash["pos"])
    _ruin_growth(ruin["pos"])
    _dress_valley(coal, bram, ash)
    # where travellers come and go
    ends["the market"] = town._market_pos + Vector3(3.0, 0, 3.0)
    var lm: Dictionary = town.landmarks
    if lm.has("lm_sawmill"):
        ends["the sawmill"] = lm["lm_sawmill"][0]
    for k in sites:
        ends[k] = sites[k]["door"]
    for k in ["Coalfoot Steading", "the Ashwood", "the Ford Mill", "the Old Footing", "Bramble End"]:
        if sites.has(k):
            var tp: Vector3 = sites[k]["pos"]
            tour.append([Vector3(tp.x, float(town.height_at(tp.x, tp.z)), tp.z), 46.0, -36.0])
    print("VALLEY sites ", sites.keys(), " made ", made)

func _mats() -> void:
    _wood = (town._mat.get("MI_WoodTrim") as StandardMaterial3D).duplicate()
    _wood.uv1_triplanar = true
    _wood.uv1_scale = Vector3(0.35, 0.35, 0.35)
    _wood.albedo_color = Color(0.56, 0.43, 0.31)
    _moss = (town._stone() as StandardMaterial3D).duplicate()
    _moss.albedo_color = Color(0.60, 0.63, 0.55)
    _bark = StandardMaterial3D.new()
    _bark.albedo_color = Color(0.38, 0.27, 0.18)
    _soil = (town._mat.get("MI_Grass") as StandardMaterial3D).duplicate()
    _soil.albedo_color = Color(0.52, 0.40, 0.29)
    _soil.cull_mode = BaseMaterial3D.CULL_DISABLED
    _wheat = StandardMaterial3D.new()
    _wheat.albedo_color = Color(0.84, 0.69, 0.33)
    _wheat.roughness = 0.9
    _wheat.cull_mode = BaseMaterial3D.CULL_DISABLED
    _straw = StandardMaterial3D.new()
    _straw.albedo_color = Color(0.82, 0.68, 0.34)
    _straw.roughness = 1.0
    _hay = StandardMaterial3D.new()
    _hay.albedo_color = Color(0.85, 0.70, 0.36)
    _hay.roughness = 1.0
    _plank = _wood.duplicate()
    _plank.albedo_color = Color(0.48, 0.37, 0.26)

## ---------------------------------------------------------------- placing
## nearest spot to `want` with r metres of clear, gentle ground (no road, plot,
## field, river, wall or other structure) inside the navmesh
func _find(want: Vector3, r: float) -> Vector3:
    for ring in range(0, 8):
        var n := 1 if ring == 0 else 10
        for k in range(n):
            var a := TAU * float(k) / float(n) + float(ring) * 0.4
            var q := want + Vector3(cos(a), 0, sin(a)) * float(ring) * 7.0
            if _ok(q, r):
                return q
    push_warning("valley: no clear ground near %s" % want)
    return want

func _ok(q: Vector3, r: float) -> bool:
    if absf(q.x) > edge - r - 4.0 or absf(q.z) > edge - r - 4.0:
        return false
    if not bool(town.is_clear(q, r)) or bool(town._in_field(q, r)):
        return false
    var lo := 1e9
    var hi := -1e9
    for i in range(-1, 2):
        for j in range(-1, 2):
            var h: float = town.height_at(q.x + float(i) * r, q.z + float(j) * r)
            lo = minf(lo, h)
            hi = maxf(hi, h)
    return hi - lo < r * 0.45

func _road(pts: Array) -> void:
    var a: Array[Vector3] = []
    for p in pts:
        var v: Vector3 = p
        a.append(Vector3(v.x, 0, v.z))
    town._road_strip(a, LANE_W, true)
    made["roads"] += 1

## footprint for the navmesh and solid_at: centre, yaw, half extents
func _solid(c: Vector3, yaw: float, he: Vector2) -> void:
    town._solid_rects.append([Vector2(c.x, c.z), Vector2(cos(yaw), -sin(yaw)), Vector2(sin(yaw), cos(yaw)), he])

## lowest ground under a footprint, so nothing floats on the slope
func _low(c: Vector3, r: float) -> float:
    var lo: float = town.height_at(c.x, c.z)
    for k in range(8):
        var a := TAU * float(k) / 8.0
        lo = minf(lo, float(town.height_at(c.x + cos(a) * r, c.z + sin(a) * r)))
    return lo

## a cottage facing `face`; returns its door step
func _cottage(shape: String, at: Vector3, face: Vector3, livery: String, k := 0.92) -> Vector3:
    var path := "res://assets/buildings/mk_house_%s.glb" % shape
    var dep: float = town._depth_of(shape)
    if not ResourceLoader.exists(path):
        return at + face * (dep * 0.5 + 1.4)
    var h: Node3D = (load(path) as PackedScene).instantiate()
    h.position = Vector3(at.x, _low(at, dep * 0.45) - 0.1, at.z)
    h.rotation.y = atan2(face.x, face.z)
    h.scale = Vector3.ONE * k
    town.add_child(h)
    town._dress(h, livery)
    town._solid_of(h)
    town._objs.append([at, dep * 0.6])
    made["houses"] += 1
    return at + face * (dep * 0.5 * k + 1.4)

## someone who lives there, at the door, doing the day's small jobs
func _resident(at: Vector3, face: Vector3, role: String, model: String, tint: Color) -> void:
    var v := Townsfolk.new()
    v.role = role
    v.model = model
    v.tint = tint
    v.person_name = town.npc_name()
    v.town = town
    v.stay = true
    v.face_yaw = atan2(face.x, face.z)
    v.rotation.y = v.face_yaw
    v.position = Vector3(at.x, town.height_at(at.x, at.z), at.z)
    add_child(v)
    made["folk"] += 1

## ---------------------------------------------------------------- steadings
## "a cottage and a well where a highway leaves the wall" - three cottages on a
## lane, a well, barrels at the doors, two of the family about.
func _hamlet(nm: String, want: Vector3, lane: Vector3, livery: String) -> Dictionary:
    var c := _find(want, 22.0)
    var side := Vector3(-lane.z, 0, lane.x)
    _road([c - lane * 24.0, c + lane * 24.0])
    var plan := [["b", 1.0, -8.5], ["c", 1.0, 8.5], ["a", -1.0, 2.0]]
    var doors: Array = []
    for row in plan:
        var shape: String = row[0]
        var sgn: float = row[1]
        var dep: float = town._depth_of(shape)
        var at: Vector3 = c + lane * float(row[2]) + side * sgn * (dep * 0.5 + LANE_W * 0.5 + 2.6)
        var door := _cottage(shape, at, side * -sgn, livery)
        doors.append([door, side * -sgn])
        # a barrel and a crate by the door, on the house's own side of the step
        town._yard("Barrel", door, lane, side * -sgn, 2.0, -0.9)
        town._yard("FarmCrate_Carrot" if made["houses"] % 2 == 0 else "Crate_Wooden", door, lane, side * -sgn, -2.2, -0.9)
    var wp: Vector3 = c - lane * 13.0 - side * 4.6
    town._build_well(wp)
    _solid(wp, 0.0, Vector2(1.75, 1.75))
    town._objs.append([wp, 2.0])
    town._signpost(c + lane * 21.0 + side * 3.0, lane, nm.to_upper(), _wood, Color(0.95, 0.88, 0.70))
    _resident(doors[0][0], doors[0][1], "farmer", "Rogue.glb", Color(0.90, 0.88, 0.58))
    _resident(doors[2][0] + lane * 1.5, doors[2][1], "farmer", "Rogue_Hooded.glb", Color(0.78, 0.86, 0.62))
    sites[nm] = {"pos": c, "door": c + lane * 3.0, "kind": "steading"}
    return {"pos": c, "east": c + lane * 24.0, "west": c - lane * 24.0,
            "north": c + lane * 24.0 if lane.z > 0.0 else c - lane * 24.0}

## ---------------------------------------------------------------- the ford
## the gravel bar (town.height_at raises it, town._bake_nav leaves it open),
## stepping stones along it, and the Ford Mill on the south bank downstream
func _ford() -> Dictionary:
    var x: float = town.ford_x
    var rz: float = town.river_z_fast(x)
    var out := {}
    var z := rz - 8.0
    while z <= rz + 8.0:
        for sx in [-1.25, 1.25]:
            var p := Vector3(x + float(sx) + _rng.randf_range(-0.25, 0.25), 0, z + _rng.randf_range(-0.3, 0.3))
            var st: Node3D = town._spawn_raw(NATURE, "RockPath_Round_Wide",
                Vector3(p.x, float(town.height_at(p.x, p.z)) + 0.02, p.z), _rng.randf() * TAU, 1.15)
            if st:
                made["stones"] += 1
        z += 1.9
    var mill := Vector3.ZERO
    for dx in [22.0, 30.0, 16.0]:
        mill = town._watermill_at(x + float(dx))
        if mill != Vector3.ZERO:
            break
    var spot := Vector3(x, 0, rz)
    if mill != Vector3.ZERO:
        var dep: float = town._depth_of("lm_watermill")
        out["door"] = mill + Vector3(0, 0, dep * 0.5 + 1.6)
        sites["the Ford Mill"] = {"pos": mill, "door": out["door"], "kind": "mill"}
        spot = (spot + mill) * 0.5
    town._signpost(Vector3(x + 3.2, 0, rz + 18.0), Vector3(0, 0, -1), "THE FORD", _wood, Color(0.95, 0.88, 0.70))
    sites["the ford"] = {"pos": spot, "door": Vector3(x, 0, rz + 17.0), "kind": "ford"}
    return out

## ---------------------------------------------------------------- the Ashwood
## the woodcutters' camp in its clearing; the trees go in after the roads
func _camp(want: Vector3) -> Dictionary:
    var c := _find(want, 14.0)
    var bz: float = town._bridge_z
    var to_road := (Vector3(0, 0, bz + 46.0) - c)
    to_road.y = 0.0
    to_road = to_road.normalized()
    var side := Vector3(-to_road.z, 0, to_road.x)
    # the woodcutters' hut at the back of the clearing, door to the camp
    var hut := c - to_road * 9.0 + side * 3.0
    var door := _cottage("b", hut, to_road, "green", 0.8)
    # stacks of felled logs, stumps, the chopping block
    for k in range(3):
        var sp := c - side * 8.0 + to_road * (-3.0 + float(k) * 3.4)
        var yaw := atan2(to_road.x, to_road.z)
        town._timber_stack(sp, yaw, _wood)
        # a stack is 3.6 m of log across, 2 m deep: solid
        _solid(sp, yaw, Vector2(1.9, 1.2))
    for k in range(7):
        var a := _rng.randf() * TAU
        var sp := c + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(8.5, 12.5)
        if not bool(town.is_clear(sp, 0.8)):
            continue
        var st := MeshInstance3D.new()
        var cm := CylinderMesh.new()
        cm.top_radius = _rng.randf_range(0.32, 0.5)
        cm.bottom_radius = cm.top_radius + 0.1
        cm.height = 0.55
        st.mesh = cm
        st.material_override = _bark
        st.position = Vector3(sp.x, float(town.height_at(sp.x, sp.z)) + 0.25, sp.z)
        add_child(st)
        town._objs.append([sp, 0.8])
    town._yard("Axe_Bronze", c + side * 4.5, side, to_road, 0.0, 0.0, 0.6)
    # the camp fire: a ring of stones, a low flame, a little light
    var fp := c + side * 2.0 + to_road * 4.5
    var g: float = town.height_at(fp.x, fp.z)
    for k in range(7):
        var a := TAU * float(k) / 7.0
        town._spawn_raw(NATURE, "Pebble_Round_3", Vector3(fp.x + cos(a) * 0.9, g, fp.z + sin(a) * 0.9), a, 1.6)
    var flame := MeshInstance3D.new()
    var fm := CylinderMesh.new()
    fm.top_radius = 0.02
    fm.bottom_radius = 0.45
    fm.height = 0.9
    flame.mesh = fm
    var fmat := StandardMaterial3D.new()
    fmat.albedo_color = Color(1.0, 0.55, 0.15)
    fmat.emission_enabled = true
    fmat.emission = Color(1.0, 0.45, 0.10)
    fmat.emission_energy_multiplier = 3.0
    flame.material_override = fmat
    flame.position = Vector3(fp.x, g + 0.45, fp.z)
    add_child(flame)
    var lt := OmniLight3D.new()
    lt.light_color = Color(1.0, 0.62, 0.30)
    lt.light_energy = 1.4
    lt.omni_range = 7.0
    lt.position = Vector3(fp.x, g + 1.2, fp.z)
    add_child(lt)
    town._objs.append([fp, 1.2])
    _solid(fp, 0.0, Vector2(1.0, 1.0))
    # three woodcutters at their work
    var spots := [[c - side * 4.0 + to_road * 2.2, -side], [c - side * 3.6 - to_road * 1.6, -side],
                  [c + side * 4.5 + to_road * 1.6, -to_road]]
    for s in spots:
        _resident(s[0], s[1], "lumberjack", "Barbarian.glb", Color(0.78, 0.60, 0.40))
    town._signpost(c + to_road * 15.0 + side * 2.6, to_road, "THE ASHWOOD", _wood, Color(0.95, 0.88, 0.70))
    sites["the Ashwood"] = {"pos": c, "door": c + to_road * 4.0, "kind": "camp"}
    return {"pos": c, "entry": c + to_road * 6.0, "door": door}

## a stand of pine and oak round the clearing, every trunk solid on the navmesh,
## never on a road
func _forest(c: Vector3) -> void:
    var tries := 0
    var n := 0
    while n < 150 and tries < 1600:
        tries += 1
        var a := _rng.randf() * TAU
        var r := _rng.randf_range(15.0, 64.0)
        var tp := c + Vector3(cos(a), 0, sin(a)) * r
        if not bool(town.is_clear(tp, 1.5)) or bool(town._in_field(tp, 2.0)):
            continue
        var pine := _rng.randf() < 0.6
        var nm: String = ("Pine_%d" % (1 + _rng.randi() % 5)) if pine else ("CommonTree_%d" % (1 + _rng.randi() % 5))
        var nd: Node3D = town._spawn_raw(NATURE, nm, Vector3(tp.x, float(town.height_at(tp.x, tp.z)) - 0.05, tp.z),
            _rng.randf() * TAU, _rng.randf_range(1.0, 1.7))
        if nd == null:
            continue
        town._objs.append([tp, 1.2])
        n += 1
        if _rng.randf() < 0.35:
            var fp := tp + Vector3(_rng.randf_range(-2.5, 2.5), 0, _rng.randf_range(-2.5, 2.5))
            town._spawn_raw(NATURE, ["Fern_1", "Mushroom_Common", "Bush_Common"][_rng.randi() % 3],
                Vector3(fp.x, float(town.height_at(fp.x, fp.z)), fp.z), _rng.randf() * TAU, 1.0)
    made["trees"] += n

## ---------------------------------------------------------------- the Old Footing
## a ring of broken wall, a tower's stump, columns standing and fallen. The
## doorway faces the Delvers' Road; two more falls let the weather in.
func _ruins(want: Vector3) -> Dictionary:
    var c := _find(want, 16.0)
    var a_from: Vector3 = town._north_from
    var a_to: Vector3 = town._scar
    var j := _closest_on(c, a_from, a_to)
    var to_j := Vector3(j.x - c.x, 0, j.z - c.z).normalized()
    var a0 := atan2(to_j.z, to_j.x)
    var R := 10.5
    var seg_l := 2.0 * R * sin(PI / 12.0) + 0.35
    for i in range(12):
        if i == 0 or i == 5 or i == 8:
            continue                        # the doorway and two falls
        var a := a0 + TAU * float(i) / 12.0
        var p := c + Vector3(cos(a), 0, sin(a)) * R
        var d := Vector3(-sin(a), 0, cos(a))
        var yaw := atan2(-d.z, d.x)
        var hgt := _rng.randf_range(0.9, 3.8)
        var g := _low(p, seg_l * 0.5)
        town._box(Vector3(seg_l, hgt + 0.7, 1.1), Vector3(p.x, g + (hgt + 0.7) * 0.5 - 0.7, p.z), _moss, yaw)
        if _rng.randf() < 0.6:
            # a jagged top: one end stands higher than the other
            var off := d * seg_l * (0.25 if _rng.randf() < 0.5 else -0.25)
            var th := _rng.randf_range(0.4, 1.3)
            town._box(Vector3(seg_l * 0.45, th, 1.0), Vector3(p.x + off.x, g + hgt + th * 0.5 - 0.05, p.z + off.z), _moss, yaw)
        _solid(p, yaw, Vector2(seg_l * 0.5 + 0.05, 0.6))
        made["walls"] += 1
    # the tower's stump, where the ring turns away from the road
    var ta := a0 + PI
    var tc := c + Vector3(cos(ta), 0, sin(ta)) * (R + 1.0)
    var tg := _low(tc, 3.0)
    for part in [[3.1, 5.4, 0.0], [2.4, 1.8, 0.6]]:
        var cy := MeshInstance3D.new()
        var cm := CylinderMesh.new()
        cm.top_radius = float(part[0])
        cm.bottom_radius = float(part[0]) + 0.15
        cm.height = float(part[1])
        cy.mesh = cm
        cy.material_override = _moss
        var off := Vector3(cos(ta + 1.2), 0, sin(ta + 1.2)) * float(part[2])
        cy.position = Vector3(tc.x + off.x, tg + float(part[1]) * 0.5 - 0.4 + (5.0 if float(part[2]) > 0.0 else 0.0), tc.z + off.z)
        add_child(cy)
    _solid(tc, 0.0, Vector2(3.2, 3.2))
    town._objs.append([tc, 3.4])
    # columns: two still standing inside the ring, two fallen in the long fall
    for k in range(2):
        var a := a0 + PI * 0.5 + float(k) * PI
        var cp := c + Vector3(cos(a), 0, sin(a)) * 4.2
        var col := MeshInstance3D.new()
        var cm := CylinderMesh.new()
        cm.top_radius = 0.5
        cm.bottom_radius = 0.62
        cm.height = 3.4 - float(k) * 1.6
        col.mesh = cm
        col.material_override = _moss
        col.position = Vector3(cp.x, float(town.height_at(cp.x, cp.z)) + cm.height * 0.5 - 0.1, cp.z)
        add_child(col)
        _solid(cp, 0.0, Vector2(0.7, 0.7))
    for k in range(2):
        var a := a0 + TAU * 5.0 / 12.0 + float(k) * 0.25
        var fp := c + Vector3(cos(a), 0, sin(a)) * (R + 2.5 + float(k) * 1.5)
        var col := MeshInstance3D.new()
        var cm := CylinderMesh.new()
        cm.top_radius = 0.52
        cm.bottom_radius = 0.52
        cm.height = 2.6
        col.mesh = cm
        col.material_override = _moss
        col.rotation = Vector3(0, a + 0.4, PI * 0.5)
        col.position = Vector3(fp.x, float(town.height_at(fp.x, fp.z)) + 0.35, fp.z)
        add_child(col)
        # lying along (cos(a+0.4), -sin(a+0.4)) in xz after the roll
        _solid(fp, a + 0.4, Vector2(1.35, 0.6))
    # worn flagstones on the floor inside
    for k in range(12):
        var a := _rng.randf() * TAU
        var fp := c + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(0.0, 7.5)
        town._spawn_raw(NATURE, "RockPath_Square_Wide", Vector3(fp.x, float(town.height_at(fp.x, fp.z)) + 0.02, fp.z), _rng.randf() * TAU, 1.3)
    town._objs.append([c, R + 2.0])
    var gate := c + to_j * (R + 3.0)
    town._signpost(c + to_j * (R + 7.0) + Vector3(-to_j.z, 0, to_j.x) * 2.8, to_j, "THE OLD FOOTING", _wood, Color(0.86, 0.84, 0.78))
    sites["the Old Footing"] = {"pos": c, "door": c + to_j * (R + 1.5), "kind": "ruin"}
    return {"pos": c, "gate": gate, "join": j + (c - j).normalized() * 3.0}

## rubble and old trees round the Footing, after the track is down
func _ruin_growth(c: Vector3) -> void:
    for k in range(10):
        var a := _rng.randf() * TAU
        var rp := c + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(12.5, 20.0)
        if not bool(town.is_clear(rp, 1.0)):
            continue
        town._spawn_raw(NATURE, "Rock_Medium_%d" % (1 + _rng.randi() % 3), Vector3(rp.x, float(town.height_at(rp.x, rp.z)) - 0.1, rp.z), _rng.randf() * TAU, _rng.randf_range(1.0, 1.8))
        town._objs.append([rp, 1.1])
    for k in range(6):
        var a := _rng.randf() * TAU
        var tp := c + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(15.0, 26.0)
        if not bool(town.is_clear(tp, 1.6)):
            continue
        var nm := ("TwistedTree_%d" % (1 + _rng.randi() % 5)) if k % 2 == 0 else ("DeadTree_%d" % (1 + _rng.randi() % 5))
        if town._spawn_raw(NATURE, nm, Vector3(tp.x, float(town.height_at(tp.x, tp.z)) - 0.05, tp.z), _rng.randf() * TAU, _rng.randf_range(1.0, 1.4)):
            town._objs.append([tp, 1.2])
            made["trees"] += 1

func _closest_on(p: Vector3, a: Vector3, b: Vector3) -> Vector3:
    var ab := Vector3(b.x - a.x, 0, b.z - a.z)
    var t := clampf(Vector3(p.x - a.x, 0, p.z - a.z).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
    return Vector3(a.x, 0, a.z) + ab * t

## ---------------------------------------------------------------- travellers
## Folk and carts on the valley roads: out from one place to another, a while
## there, then home again and gone (the caravan's pattern, town.gd _caravan).
func _process(delta: float) -> void:
    if town == null or town.get("nav") == null:
        return
    _say_t -= delta
    _trip_t -= delta
    if _trip_t <= 0.0:
        _trip_t = _rng.randf_range(16.0, 32.0)
        if travellers.size() < MAX_TRAVELLERS and (town.nav as TownNav).synced():
            send(TRIPS[_rng.randi() % TRIPS.size()])
    for tr in travellers.duplicate():
        if not is_instance_valid(tr["v"]):
            _drop(tr)
            continue
        var v: Townsfolk = tr["v"]
        tr["life"] = float(tr["life"]) + delta
        if float(tr["life"]) > 900.0:
            _drop(tr)               # never wander for ever
            continue
        if not v._route.is_empty():
            continue
        match String(tr["phase"]):
            "out":
                tr["phase"] = "there"
                tr["t"] = _rng.randf_range(6.0, 14.0)
            "there":
                tr["t"] = float(tr["t"]) - delta
                if float(tr["t"]) <= 0.0:
                    v._route = town.route(v.global_position, tr["a"])
                    tr["phase"] = "back"
                    if v._route.is_empty():
                        _drop(tr)
            "back":
                trips_done += 1
                _drop(tr)

## start one trip; returns the traveller (tests call it directly)
func send(trip: Array) -> Townsfolk:
    if not ends.has(trip[0]) or not ends.has(trip[1]):
        return null
    var a: Vector3 = ends[trip[0]]
    var b: Vector3 = ends[trip[1]]
    var cart: bool = trip[2]
    var v := Townsfolk.new()
    v.role = "carter" if cart else "traveller"
    v.model = "Rogue.glb" if cart else String(FOLK_MODELS[_rng.randi() % FOLK_MODELS.size()])
    v.tint = Color(_rng.randf_range(0.7, 0.95), _rng.randf_range(0.7, 0.92), _rng.randf_range(0.5, 0.8))
    v.person_name = town.npc_name()
    v.speed = 2.6 if cart else 3.1
    v.town = town
    v._linger = 99999.0
    v._wait = 99999.0
    v.position = Vector3(a.x, town.height_at(a.x, a.z), a.z)
    add_child(v)
    var w: Node3D = null
    if cart:
        w = town._spawn_raw(MKPROPS, "Prop_Wagon", v.position + Vector3(0, 0, 2.6), PI * 0.5, 0.8)
        v.cart = w
    v._route = town.route(a, b)
    if v._route.is_empty():
        if w:
            w.queue_free()
        v.queue_free()
        return null
    travellers.append({"v": v, "cart": w, "a": a, "b": b, "phase": "out", "t": 0.0, "life": 0.0, "trip": trip})
    trips_sent += 1
    var line := String(trip[3])
    if line != "" and _say_t <= 0.0:
        _say_t = 90.0
        (town.feed as Array).append(line)
    return v

func _drop(tr: Dictionary) -> void:
    travellers.erase(tr)
    if is_instance_valid(tr["cart"]):
        (tr["cart"] as Node).queue_free()
    if is_instance_valid(tr["v"]):
        (tr["v"] as Node).queue_free()

## ================================================================ D18b dress
## Make the country read as worked land: each steading gets ploughed, fenced,
## cropped fields with a scarecrow, a kitchen garden, a hayrick and grazing
## stock; the ford gets a fishing jetty; the lanes get wildflowers and tall
## grass along the verges, and a copse stands between the roads.
func _dress_valley(coal: Dictionary, bram: Dictionary, ash: Dictionary) -> void:
    _steading(coal, "Sheep", 3)
    _steading(bram, "Cow", 2)
    _jetty()
    _copse((coal["pos"] as Vector3).lerp(ash["pos"] as Vector3, 0.5) + Vector3(-20.0, 0, 6.0), 26)
    _verges()
    print("VALLEY dressed fields=%d crops=%d fences=%d" % [int(made.get("fields", 0)), int(made.get("crops", 0)), int(made.get("fences", 0))])

func _steading(res: Dictionary, beast: String, n_beast: int) -> void:
    var c: Vector3 = res["pos"]
    var dirs := [Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(0, 0, -1),
                 Vector3(1, 0, 1).normalized(), Vector3(-1, 0, 1).normalized(),
                 Vector3(1, 0, -1).normalized(), Vector3(-1, 0, -1).normalized()]
    var n := 0
    var wheat := true
    for d in dirs:
        if n >= 2:
            break
        var dv: Vector3 = d
        var spot := _field_spot(c + dv * 30.0, dv)
        if spot == Vector3.INF:
            continue
        _field(spot, dv, 9.0, 7.0, wheat, c)
        var to_c := (c - spot).normalized()
        var gate: Vector3 = spot + to_c * 11.0
        var path: Array[Vector3] = [Vector3(c.x, 0, c.z) + to_c * -9.0, Vector3(gate.x, 0, gate.z)]
        town._road_strip(path, 1.6, true)
        made["roads"] = int(made.get("roads", 0)) + 1
        n += 1
        wheat = not wheat
    _garden(c)
    _hayrick(c)
    _graze(c, beast, n_beast)

## nearest placeable field centre to `want`, laid along `fw`
func _field_spot(want: Vector3, fw: Vector3) -> Vector3:
    var sd := Vector3(-fw.z, 0, fw.x)
    for ring in range(0, 6):
        var cnt := 1 if ring == 0 else 6
        for k in range(cnt):
            var a := TAU * float(k) / float(cnt) + float(ring) * 0.3
            var q := want + Vector3(cos(a), 0, sin(a)) * float(ring) * 6.0
            if absf(q.x) > edge - 22.0 or absf(q.z) > edge - 22.0:
                continue
            if bool(town._field_ok(q, fw, sd, 9.0, 7.0)):
                return q
    return Vector3.INF

## a ploughed, fenced, cropped field; the gate gap faces `toward` (the steading)
func _field(c: Vector3, fw: Vector3, hw: float, hd: float, wheat: bool, toward: Vector3) -> void:
    var sd := Vector3(-fw.z, 0, fw.x)
    (town._fields as Array).append([c, fw, sd, hw, hd])
    _d18b_fields.append(c)
    town._ground_patch(c, fw, sd, hw, hd, _soil)
    var mesh: Mesh = town._mesh_of(NATURE + ("Grass_Wispy_Tall.gltf" if wheat else "Plant_1.gltf"))
    if mesh:
        var xs: Array[Transform3D] = []
        var row := -hd + 1.0
        while row < hd - 0.8:
            var col := -hw + 0.8
            while col < hw - 0.6:
                var q := c + sd * (col + _rng.randf_range(-0.12, 0.12)) + fw * row
                var s := _rng.randf_range(0.26, 0.34) if wheat else _rng.randf_range(0.30, 0.42)
                var b := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s * (1.25 if wheat else 1.0), s))
                xs.append(Transform3D(b, Vector3(q.x, float(town.height_at(q.x, q.z)) + 0.05, q.z)))
                col += 0.42 if wheat else 0.9
            row += 1.1
        var mm := MultiMesh.new()
        mm.transform_format = MultiMesh.TRANSFORM_3D
        mm.mesh = mesh
        mm.instance_count = xs.size()
        for i in range(xs.size()):
            mm.set_instance_transform(i, xs[i])
        var mmi := MultiMeshInstance3D.new()
        mmi.multimesh = mm
        if wheat:
            mmi.material_override = _wheat
        mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        mmi.visibility_range_end = 320.0
        add_child(mmi)
        made["crops"] = int(made.get("crops", 0)) + xs.size()
    _fence_ring(c, fw, sd, hw, hd, (toward - c).normalized())
    _scarecrow(c + sd * (hw * 0.25) + fw * (hd * 0.1))
    town._objs.append([c, sqrt(hw * hw + hd * hd)])
    made["fields"] = int(made.get("fields", 0)) + 1

## a post-and-rail fence round a plot, with a gap for a gate on the `gate_dir` side
func _fence_ring(c: Vector3, fw: Vector3, sd: Vector3, hw: float, hd: float, gate_dir: Vector3) -> void:
    var corners := [[-1.0, -1.0, 1.0, -1.0], [1.0, -1.0, 1.0, 1.0], [1.0, 1.0, -1.0, 1.0], [-1.0, 1.0, -1.0, -1.0]]
    for cr in corners:
        var p0 := c + sd * (hw * float(cr[0])) + fw * (hd * float(cr[1]))
        var p1 := c + sd * (hw * float(cr[2])) + fw * (hd * float(cr[3]))
        var L := p0.distance_to(p1)
        if L < 0.1:
            continue
        var dirv := (p1 - p0) / L
        var outward := ((p0 + p1) * 0.5 - c).normalized()
        var gate_side := outward.dot(gate_dir) > 0.55
        var cnt := int(L / 2.0)
        for k in range(cnt):
            if gate_side and absf(float(k) - float(cnt) * 0.5) < 0.9:
                continue
            var q := p0 + dirv * (2.0 * (float(k) + 0.5))
            town._spawn_raw(MKPROPS, "Prop_WoodenFence_Single", Vector3(q.x, float(town.height_at(q.x, q.z)), q.z), atan2(dirv.x, dirv.z) - PI * 0.5, 1.0)
            made["fences"] = int(made.get("fences", 0)) + 1

## a straw figure on a cross of poles, over a tended field
func _scarecrow(p: Vector3) -> void:
    var g := float(town.height_at(p.x, p.z))
    town._box(Vector3(0.12, 2.0, 0.12), Vector3(p.x, g + 1.0, p.z), _wood, 0.0)
    town._box(Vector3(1.3, 0.1, 0.1), Vector3(p.x, g + 1.45, p.z), _wood, _rng.randf_range(-0.25, 0.25))
    var rag := StandardMaterial3D.new()
    rag.albedo_color = Color(0.55, 0.42, 0.40)
    rag.roughness = 1.0
    town._box(Vector3(0.6, 0.6, 0.2), Vector3(p.x, g + 1.15, p.z), rag, 0.0)
    var head := MeshInstance3D.new()
    var hm := SphereMesh.new()
    hm.radius = 0.16
    hm.height = 0.32
    head.mesh = hm
    head.material_override = _straw
    head.position = Vector3(p.x, g + 1.78, p.z)
    add_child(head)

## a small fenced kitchen garden by the steading: rows of greens, a crate, a bucket
func _garden(c: Vector3) -> void:
    var want := c + Vector3(_rng.randf_range(-1.0, 1.0), 0, _rng.randf_range(-1.0, 1.0)).normalized() * 17.0
    var g0 := _find_open(want, 4.5)
    if g0 == Vector3.INF:
        return
    for r in range(4):
        for cc in range(6):
            var q := g0 + Vector3(-2.5 + float(cc), 0, -1.5 + float(r))
            town._spawn_raw(NATURE, "Plant_1", Vector3(q.x, float(town.height_at(q.x, q.z)), q.z), _rng.randf() * TAU, _rng.randf_range(0.5, 0.8))
    var ce := g0 + Vector3(3.2, 0, 0.0)
    town._spawn_raw(PROPS, "FarmCrate_Carrot", Vector3(ce.x, float(town.height_at(ce.x, ce.z)), ce.z), _rng.randf() * TAU, 0.9)
    var be := g0 + Vector3(-3.0, 0, 1.6)
    town._spawn_raw(PROPS, "Bucket_Wooden_1", Vector3(be.x, float(town.height_at(be.x, be.z)), be.z), _rng.randf() * TAU, 1.0)
    _fence_ring(g0, Vector3(0, 0, 1), Vector3(1, 0, 0), 3.2, 2.4, (c - g0).normalized())
    town._objs.append([g0, 4.2])

## a hayrick (two thatched stacks) on open ground by the steading
func _hayrick(c: Vector3) -> void:
    var want := c + Vector3(_rng.randf_range(-1.0, 1.0), 0, _rng.randf_range(-1.0, 1.0)).normalized() * 20.0
    var h0 := _find_open(want, 3.5)
    if h0 == Vector3.INF:
        return
    for off in [Vector3(-1.6, 0, 0), Vector3(1.6, 0, 0.4)]:
        var sp: Vector3 = h0 + off
        var stack := MeshInstance3D.new()
        var cm := CylinderMesh.new()
        cm.top_radius = 0.3
        cm.bottom_radius = 1.4
        cm.height = 2.4
        stack.mesh = cm
        stack.material_override = _hay
        stack.position = Vector3(sp.x, float(town.height_at(sp.x, sp.z)) + 1.1, sp.z)
        add_child(stack)
    town._objs.append([h0, 3.2])

## a few beasts grazing loose on open ground near the steading
func _graze(c: Vector3, kind: String, n: int) -> void:
    var want := c + Vector3(_rng.randf_range(-1.0, 1.0), 0, _rng.randf_range(-1.0, 1.0)).normalized() * 26.0
    var center := _find_open(want, 8.0)
    if center == Vector3.INF:
        return
    var fw := Vector3(0, 0, 1)
    var sd := Vector3(1, 0, 0)
    for k in range(n):
        var at := center + sd * _rng.randf_range(-6.0, 6.0) + fw * _rng.randf_range(-5.0, 5.0)
        town._animal(kind, center, fw, sd, 7.0, 5.5, at)
    town._objs.append([center, 3.0])

## a plank fishing jetty out over the ford's slow water, with a barrel, a crate,
## a bucket and a coil of rope at the landward end
func _jetty() -> void:
    var x := float(town.ford_x) - 22.0
    var rz := float(town.river_z_fast(x))
    var bank := rz + RIVER_W + 1.0        # the near (south) bank
    var tip := rz + 1.2                    # out over the water
    var length := bank - tip
    var midz := (bank + tip) * 0.5
    var dy := WATER_Y + 0.55
    town._box(Vector3(2.2, 0.14, length), Vector3(x, dy, midz), _plank, 0.0)
    for sx in [-0.9, 0.9]:
        for sz in [tip + 0.5, bank - 0.5]:
            town._box(Vector3(0.14, 1.5, 0.14), Vector3(x + float(sx), dy - 0.75, float(sz)), _plank, 0.0)
    var top := dy + 0.08
    town._spawn_raw(PROPS, "Barrel", Vector3(x - 0.7, top, bank - 0.7), _rng.randf() * TAU, 0.9)
    town._spawn_raw(PROPS, "Crate_Wooden", Vector3(x + 0.7, top, bank - 0.7), 0.4, 0.9)
    town._spawn_raw(PROPS, "Bucket_Wooden_1", Vector3(x - 0.5, top, tip + 1.0), 0.0, 1.0)
    town._spawn_raw(PROPS, "Rope_1", Vector3(x + 0.6, top, tip + 1.4), 0.0, 1.0)
    _solid(Vector3(x, 0, midz), 0.0, Vector2(1.3, length * 0.5 + 0.3))
    town._objs.append([Vector3(x, 0, midz), length * 0.5 + 2.0])
    town._signpost(Vector3(x + 2.6, 0, bank + 1.5), Vector3(0, 0, -1), "THE JETTY", _wood, Color(0.95, 0.88, 0.70))

## a small stand of common trees and undergrowth between the valley roads
func _copse(center: Vector3, count: int) -> void:
    var c := _find_open(center, 6.0)
    if c == Vector3.INF:
        return
    var tries := 0
    var n := 0
    while n < count and tries < count * 14:
        tries += 1
        var a := _rng.randf() * TAU
        var r := _rng.randf_range(4.0, 22.0)
        var tp := c + Vector3(cos(a), 0, sin(a)) * r
        if not bool(town.is_clear(tp, 1.4)) or bool(town._in_field(tp, 2.0)) or float(town.road_dist(tp)) < 3.0:
            continue
        var nm := ("CommonTree_%d" % (1 + _rng.randi() % 5)) if _rng.randf() < 0.7 else ("Pine_%d" % (1 + _rng.randi() % 5))
        var nd: Node3D = town._spawn_raw(NATURE, nm, Vector3(tp.x, float(town.height_at(tp.x, tp.z)) - 0.05, tp.z), _rng.randf() * TAU, _rng.randf_range(1.0, 1.6))
        if nd == null:
            continue
        town._objs.append([tp, 1.2])
        n += 1
        if _rng.randf() < 0.3:
            var fp := tp + Vector3(_rng.randf_range(-2.0, 2.0), 0, _rng.randf_range(-2.0, 2.0))
            town._spawn_raw(NATURE, ["Bush_Common", "Fern_1", "Flower_3_Group"][_rng.randi() % 3], Vector3(fp.x, float(town.height_at(fp.x, fp.z)), fp.z), _rng.randf() * TAU, 1.0)
    made["trees"] += n

## wildflowers, clover and tall grass along the valley lanes
func _verges() -> void:
    var placed := 0
    for sg in (town._road_segs as Array):
        var a: Vector3 = sg[0]
        var b: Vector3 = sg[1]
        var mid := (a + b) * 0.5
        if Vector2(mid.x, mid.z).length() < 120.0:
            continue                         # the town core, not the valley
        var dv := b - a
        dv.y = 0.0
        var L := dv.length()
        if L < 1.5:
            continue
        dv = dv / L
        var perp := Vector3(-dv.z, 0, dv.x)
        var steps := maxi(int(L / 5.0), 1)
        for k in range(steps):
            if _rng.randf() < 0.45:
                continue
            var t := (float(k) + 0.5) / float(steps)
            var base := a.lerp(b, t)
            var sgn := 1.0 if _rng.randf() < 0.5 else -1.0
            var q := base + perp * sgn * (float(sg[2]) * 0.5 + _rng.randf_range(1.2, 3.2))
            if not bool(town.is_clear(q, 0.6)) or bool(town._in_field(q, 1.0)):
                continue
            var nm: String = ["Grass_Common_Tall", "Grass_Wispy_Tall", "Clover_1", "Flower_3_Group", "Flower_4_Group", "Bush_Common_Flowers"][_rng.randi() % 6]
            if town._spawn_raw(NATURE, nm, Vector3(q.x, float(town.height_at(q.x, q.z)), q.z), _rng.randf() * TAU, _rng.randf_range(0.9, 1.5)):
                placed += 1
    print("VALLEY verges ", placed)

## nearest clear, gentle, road- and field-free open spot to `want`
func _find_open(want: Vector3, r: float) -> Vector3:
    for ring in range(0, 7):
        var cnt := 1 if ring == 0 else 8
        for k in range(cnt):
            var a := TAU * float(k) / float(cnt) + float(ring) * 0.2
            var q := want + Vector3(cos(a), 0, sin(a)) * float(ring) * 5.0
            if absf(q.x) > edge - r - 4.0 or absf(q.z) > edge - r - 4.0:
                continue
            if bool(town.is_clear(q, r)) and not bool(town._in_field(q, r)) \
                    and float(town.road_dist(q)) > r + 1.5 and float(town.river_dist(q.x, q.z)) > r + 6.0:
                return q
    return Vector3.INF
