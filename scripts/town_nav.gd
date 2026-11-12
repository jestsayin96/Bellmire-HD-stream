class_name TownNav
extends NavigationRegion3D
## HD: the town's walkable ground as a Godot navigation mesh.
##
## People used to walk the hex street graph and then a straight line from the
## nearest street to wherever they were going - through the house in front of
## a back-rank door, through market tables, through the wall. This bakes one
## navmesh over the whole valley with every solid thing CARVED out of it:
## house footprints, stalls, tables, benches, wells, lamp posts, trees, the
## town wall (gates left open) and the river (the bridge left open). route()
## then asks the NavigationServer for the path, so nobody can be routed
## through anything solid.

var town: Node3D
var ready_ok := false
var bake_ms := 0
var n_obstructions := 0

const AGENT_R := 0.5
const CELL := 0.5

func setup(t: Node3D, extent: float, solids: Array, rects: Array, wall: Array,
           river_band: Array) -> void:
    town = t
    var nm := NavigationMesh.new()
    nm.cell_size = CELL
    nm.cell_height = 0.25
    nm.agent_radius = AGENT_R
    nm.agent_height = 2.0
    nm.agent_max_climb = 0.5
    nm.agent_max_slope = 60.0
    nm.region_min_size = 4.0
    # 1.6 let the simplified outline cut up to a metre and a half into a
    # house corner; keep the edges close to the carved footprints
    nm.edge_max_error = 0.4
    nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_MESH_INSTANCES
    nm.filter_baking_aabb = AABB(Vector3(-extent, -5.0, -extent), Vector3(extent * 2.0, 10.0, extent * 2.0))
    var src := NavigationMeshSourceGeometryData3D.new()
    # one flat walkable sheet; heights come from the town's own ground later
    var e := extent
    src.add_faces(PackedVector3Array([
        Vector3(-e, 0, -e), Vector3(e, 0, -e), Vector3(e, 0, e),
        Vector3(-e, 0, -e), Vector3(e, 0, e), Vector3(-e, 0, e)]), Transform3D.IDENTITY)
    for s in solids:              # [Vector3 centre, radius]
        _circle(src, s[0], float(s[1]))
    for r in rects:               # [Vector2 centre, Vector2 ax, Vector2 az, Vector2 half]
        _rect(src, r)
    for w in wall:                # [Vector3 p, Vector3 tangent]
        var p: Vector3 = w[0]
        var tg: Vector3 = w[1]
        var nrm := Vector3(-tg.z, 0, tg.x)
        _rect(src, [Vector2(p.x, p.z), Vector2(tg.x, tg.z), Vector2(nrm.x, nrm.z), Vector2(1.9, 1.1)])
    for b in river_band:          # [Vector3 a, Vector3 b, half width]
        var a: Vector3 = b[0]
        var c: Vector3 = b[1]
        var d := (c - a)
        d.y = 0
        var L := d.length()
        if L < 0.01:
            continue
        d /= L
        var n := Vector3(-d.z, 0, d.x)
        var m := (a + c) * 0.5
        _rect(src, [Vector2(m.x, m.z), Vector2(d.x, d.z), Vector2(n.x, n.z), Vector2(L * 0.5 + 0.3, float(b[2]))])
    var t0 := Time.get_ticks_msec()
    NavigationServer3D.bake_from_source_geometry_data(nm, src)
    bake_ms = Time.get_ticks_msec() - t0
    navigation_mesh = nm
    ready_ok = nm.get_polygon_count() > 0

func _circle(src: NavigationMeshSourceGeometryData3D, c: Vector3, r: float) -> void:
    if r <= 0.05:
        return
    var pts := PackedVector3Array()
    for i in range(8):
        var a := TAU * float(i) / 8.0
        pts.append(Vector3(c.x + cos(a) * r, 0.0, c.z + sin(a) * r))
    # D1: carve=false. A CARVED obstruction skips the agent-radius margin, so
    # paths ran along the very walls and the cell rounding put feet inside
    src.add_projected_obstruction(pts, -2.0, 8.0, false)
    n_obstructions += 1

func _rect(src: NavigationMeshSourceGeometryData3D, r: Array) -> void:
    var c: Vector2 = r[0]
    var ax: Vector2 = r[1]
    var az: Vector2 = r[2]
    # a fence or bench thinner than a cell slipped between the cell centres
    var he: Vector2 = (r[3] as Vector2).max(Vector2(0.3, 0.3))
    var pts := PackedVector3Array()
    for k in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
        var q: Vector2 = c + ax * he.x * k.x + az * he.y * k.y
        pts.append(Vector3(q.x, 0.0, q.y))
    # D1: carve=false. A CARVED obstruction skips the agent-radius margin, so
    # paths ran along the very walls and the cell rounding put feet inside
    src.add_projected_obstruction(pts, -2.0, 8.0, false)
    n_obstructions += 1

## a walkable path from a to b (flat; y is filled in by the walker), or [] if
## the map is not ready. The last point is the reachable point nearest b.
func path(a: Vector3, b: Vector3) -> PackedVector3Array:
    if not ready_ok:
        return PackedVector3Array()
    if not synced():
        return PackedVector3Array()
    var map := get_navigation_map()
    return NavigationServer3D.map_get_path(map, Vector3(a.x, 0, a.z), Vector3(b.x, 0, b.z), true)

## D6b: true once the server's map really holds this region's polygons. The
## map's iteration id goes above 0 a while before the region is in it, and until
## then map_get_closest_point answers (0,0,0) for everything - which stacked the
## square's people and the watch's beats on the origin. The probe: one of our
## own mesh vertices must snap back onto itself.
var _synced := false
var _probe := Vector3.INF

func synced() -> bool:
    if _synced:
        return true
    if not ready_ok or not is_inside_tree():
        return false
    var map := get_navigation_map()
    if not map.is_valid() or NavigationServer3D.map_get_iteration_id(map) == 0:
        return false
    if not NavigationServer3D.map_get_regions(map).has(get_rid()):
        return false
    if _probe == Vector3.INF:
        var nm := navigation_mesh
        var verts := nm.get_vertices()
        if nm.get_polygon_count() == 0 or verts.is_empty():
            return false
        # a vertex well away from the origin, so a (0,0,0) answer cannot pass
        var best := 0
        for i in range(verts.size()):
            if Vector2(verts[i].x, verts[i].z).length() > Vector2(verts[best].x, verts[best].z).length():
                best = i
            if Vector2(verts[best].x, verts[best].z).length() > 20.0:
                break
        _probe = verts[best] * global_transform.basis.get_scale() + global_position
    var q := NavigationServer3D.map_get_closest_point(map, _probe)
    _synced = Vector2(q.x - _probe.x, q.z - _probe.z).length() < 1.0
    return _synced

## the nearest walkable point to p; before the first sync, p itself (flat) -
## never the origin
func closest(p: Vector3) -> Vector3:
    if not synced():
        return Vector3(p.x, 0, p.z)       # not synced yet: no opinion
    return NavigationServer3D.map_get_closest_point(get_navigation_map(), Vector3(p.x, 0, p.z))
