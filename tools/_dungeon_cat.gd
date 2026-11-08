extends SceneTree
## Dungeon kit catalogue: every piece type laid out in a dark hall, torch-lit.
var _cam: Camera3D
var _f := 0
var _st: Node3D
var _shots: Array = []
var _i := 0
const K := "res://addons/kaykit_dungeon_remastered/Assets/gltf/"
func _put(n: Node3D, p: Vector3, yaw := 0.0) -> Node3D:
    n.position = p
    n.rotation.y = yaw
    _st.add_child(n)
    return n
func _k(nm: String, p: Vector3, yaw := 0.0) -> Node3D:
    return _put(DungeonParts.kit(nm), p, yaw)
func _initialize() -> void:
    _st = Node3D.new()
    root.add_child(_st)
    var we := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color(0.02, 0.02, 0.03)
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(0.32, 0.30, 0.40)
    e.ambient_light_energy = 0.55
    e.glow_enabled = true
    e.glow_intensity = 0.9
    e.tonemap_mode = Environment.TONE_MAPPER_AGX
    e.ssao_enabled = true
    we.environment = e
    _st.add_child(we)
    # floor: KayKit 4 m tiles across the hall
    for x in range(-6, 7):
        for z in range(-3, 6):
            var fp := Vector3(float(x) * 4.0, 0, float(z) * 4.0)
            if absf(fp.x + 12.0) < 4.5 and absf(fp.z - 14.0) < 3.0:
                continue        # the lava pool's pit
            _k("floor_tile_large", fp)
    # back wall run with every wall type
    var walls := ["wall", "wall_arched", "wall_doorway", "wall_gated", "wall_window_open", "wall_archedwindow_gated", "wall_broken",
                  "wall_cracked", "wall_shelves", "wall_pillar", "wall_scaffold", "wall_half"]
    for i in range(walls.size()):
        _k(walls[i], Vector3(-22.0 + float(i) * 4.0, 0, -14.0))
        if i % 2 == 0:
            _put(DungeonParts.torch_lit(), Vector3(-22.0 + float(i) * 4.0, 1.4, -13.4))
    # row A: pillars, columns, stairs, arches
    var row_a := ["pillar", "pillar_decorated", "column", "stairs", "stairs_wide", "stairs_wood", "Arch", "Arch_bars", "Arch_Door", "Statue_Horse", "Pedestal"]
    for i in range(row_a.size()):
        _k(row_a[i], Vector3(-20.0 + float(i) * 4.0, 0, -8.0))
    # row B: furniture + loot
    var row_b := ["table_long_decorated_A", "chair", "bed_decorated", "shelf_large", "barrel_large", "crates_stacked", "chest", "chest_gold",
                  "coin_stack_large", "keg_decorated", "banner_patternA_red", "Woodfire", "trunk_large_A"]
    for i in range(row_b.size()):
        _k(row_b[i], Vector3(-22.0 + float(i) * 3.6, 0, -2.0))
    # row C: traps, gates, cells, lava, debris, scar
    _put(DungeonParts.spike_trap(), Vector3(-20, 0, 6))
    _put(DungeonParts.pressure_plate(), Vector3(-16.5, 0, 6))
    _put(DungeonParts.fire_trap(), Vector3(-13, 0, 6))
    _k("floor_tile_big_spikes", Vector3(-9, 0, 6))
    _k("Trapdoor_open", Vector3(-5.5, 0, 6))
    _put(DungeonParts.portcullis(), Vector3(0, 0, 4))
    _put(DungeonParts.cell(), Vector3(7, 0, 5))
    _put(DungeonParts.cell(3.0, 3.0, 2.8, true), Vector3(11, 0, 5))
    _put(DungeonParts.lava_pool(8.0, 5.0), Vector3(-12, 0, 14))
    _put(DungeonParts.debris(3), Vector3(-2, 0, 13))
    _put(DungeonParts.debris(7), Vector3(2, 0, 15))
    _put(DungeonParts.scar_glass(4), Vector3(8, 0, 13))
    _put(DungeonParts.scar_glass(9, 10), Vector3(11, 0, 15))
    _k("Cobweb", Vector3(14, 0.0, 12))
    for x in [-22.0, -8.0, 6.0, 18.0]:
        _put(DungeonParts.torch_lit(), Vector3(float(x), 1.4, 10.0))
    _cam = Camera3D.new()
    _st.add_child(_cam)
    _shots = [["dng_overview", Vector3(0, 22, 26), Vector3(0, 0, -2), 60.0],
              ["dng_walls", Vector3(-14, 3.0, -10.5), Vector3(-14, 2.0, -14), 75.0], ["dng_walls2", Vector3(10, 3.0, -10.5), Vector3(10, 2.0, -14), 75.0],
              ["dng_structures", Vector3(-6, 4, 0), Vector3(0, 1.5, -8), 62.0],
              ["dng_furniture", Vector3(-6, 3.5, 5), Vector3(-2, 0.8, -2), 62.0],
              ["dng_traps", Vector3(-12, 4.5, 12), Vector3(-12, 0.5, 6), 60.0],
              ["dng_gates_cells", Vector3(4, 4.5, 13), Vector3(6, 1.5, 4.5), 62.0],
              ["dng_lava", Vector3(-4, 5, 22), Vector3(-10, 0, 14), 60.0],
              ["dng_scar_debris", Vector3(6, 4, 22), Vector3(5, 0.8, 14), 60.0]]
func _process(_d: float) -> bool:
    _f += 1
    if _f < 40:
        return false
    if (_f - 40) % 14 == 0:
        if _i > 0:
            root.get_texture().get_image().save_png("user://%s.png" % _shots[_i - 1][0])
        if _i >= _shots.size():
            return true
        var s: Array = _shots[_i]
        _cam.make_current()
        _cam.fov = float(s[3])
        _cam.global_position = s[1]
        _cam.look_at(s[2], Vector3.UP)
        _i += 1
    return false
