extends SceneTree
## D18b DRESS-THE-VALLEY invariants. Builds the town, finds the Valley, and
## checks the new country dressing is there and sane:
##   - fields/crops/fences were made (counts),
##   - every registered field sits on gentle ground, off the roads, inside the
##     navmesh, and no two fields overlap,
##   - the ford jetty footprint exists over the water,
##   - grazing stock was added.
## Prints D18B_TEST OK when all pass, else D18B_TEST FAIL ...
var _t: Node3D
var _f := 0

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _process(_d: float) -> bool:
    _f += 1
    if _f < 10:
        return false
    var fail := 0
    var val: Node = _t.find_child("Valley", true, false)
    if val == null:
        print("D18B_TEST FAIL no Valley node")
        return true
    var made: Dictionary = val.get("made")
    var nfields := int(made.get("fields", 0))
    var ncrops := int(made.get("crops", 0))
    var nfences := int(made.get("fences", 0))
    print("D18B made fields=%d crops=%d fences=%d trees=%d roads=%d" % [nfields, ncrops, nfences, int(made.get("trees",0)), int(made.get("roads",0))])
    if nfields < 2:
        fail += 1; print("FLAG fields < 2 (%d)" % nfields)
    if ncrops < 200:
        fail += 1; print("FLAG crops < 200 (%d)" % ncrops)
    if nfences < 12:
        fail += 1; print("FLAG fences < 12 (%d)" % nfences)

    # every field: gentle ground, off roads, inside the navmesh; none overlapping
    var fields: Array = val.get("_d18b_fields")
    var edge: float = float(val.get("edge"))
    var road_bad := 0
    var slope_bad := 0
    var edge_bad := 0
    for f in fields:
        var c: Vector3 = f
        if float(_t.call("road_dist", c)) < 1.0:
            road_bad += 1
        if absf(c.x) > edge or absf(c.z) > edge:
            edge_bad += 1
        var lo := 1e9
        var hi := -1e9
        for i in range(-1, 2):
            for j in range(-1, 2):
                var h: float = _t.call("height_at", c.x + float(i) * 4.0, c.z + float(j) * 4.0)
                lo = minf(lo, h); hi = maxf(hi, h)
        if hi - lo > 5.0:
            slope_bad += 1
    if road_bad > 0:
        fail += 1; print("FLAG %d field centres on a road" % road_bad)
    if slope_bad > 0:
        fail += 1; print("FLAG %d field centres on steep ground" % slope_bad)
    if edge_bad > 0:
        fail += 1; print("FLAG %d field centres outside the navmesh" % edge_bad)
    var overlap := 0
    for i in range(fields.size()):
        for j in range(i + 1, fields.size()):
            if (fields[i] as Vector3).distance_to(fields[j] as Vector3) < 4.0:
                overlap += 1
    if overlap > 0:
        fail += 1; print("FLAG %d overlapping field pairs" % overlap)

    # the jetty footprint: a solid rect over the ford's water, upstream of the crossing
    var fx: float = float(_t.get("ford_x")) - 22.0
    var rz: float = float(_t.call("river_z_fast", fx))
    var solids: Array = _t.get("_solid_rects")
    var jetty := false
    for r in solids:
        var cc: Vector2 = r[0]
        if absf(cc.x - fx) < 3.0 and absf(cc.y - (rz + RIVER_MID())) < 8.0:
            jetty = true
    if not jetty:
        fail += 1; print("FLAG no jetty footprint near the ford")

    # grazing stock present
    var animals: Array = _t.get("animals")
    if animals.size() < 3:
        fail += 1; print("FLAG too few animals (%d)" % animals.size())

    if fail == 0:
        print("D18B_TEST OK  fields=%d crops=%d fences=%d animals=%d" % [nfields, ncrops, nfences, animals.size()])
    else:
        print("D18B_TEST FAIL (%d flags)" % fail)
    return true

func RIVER_MID() -> float:
    return 8.0 + 1.2 + 0.0  # (RIVER_W+1 + tip) mid offset ~ matches _jetty midz - rz
