extends SceneTree
## D7 FPS (windowed): the real town filled past 210 people, a fixed stream-height
## camera over the market, LOD off / on / off / on in 40 s blocks; FPS per block
## and a frame of each to renders/cycles/20261112_d7.
var _t: Node3D
var _f := 0
var _cam: Camera3D
var _b0 := 0
var _blk := -1
var _fps: Array = []
var _res := {"on": [], "off": []}
const OUT := "res://renders/cycles/20261112_d7"
const BLOCK_MS := 40000

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _process(_d: float) -> bool:
    _f += 1
    if _f == 30:
        var n := 0
        while (_t.get("people") as Array).size() < 215 and n < 120:
            _t.call("arrive", ["farmer", "trader", "smith", "miner"][n % 4], "%s settles (D7 fps).")
            n += 1
        _cam = Camera3D.new()
        _t.add_child(_cam)
        var m: Vector3 = _t.get("_market_pos")
        _cam.global_position = m + Vector3(0, 38, 46)
        _cam.look_at(m + Vector3(0, 0, -10))
        _cam.make_current()
        print("D7FPS people=%d indoor=%d" % [(_t.get("people") as Array).size(), int(_t.get("indoor_souls"))])
        _b0 = Time.get_ticks_msec() + 15000
    if _f < 31 or Time.get_ticks_msec() < _b0:
        return false
    var b := (Time.get_ticks_msec() - _b0) / BLOCK_MS
    if b != _blk:
        if _blk >= 0:
            var k := "off" if _blk % 2 == 0 else "on"
            var sm := 0.0
            for x in _fps:
                sm += float(x)
            var avg := sm / maxf(1.0, float(_fps.size()))
            (_res[k] as Array).append(avg)
            root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "/d7_fps_%d_%s.png" % [_blk, k]))
            print("D7FPS block %d lod %s fps_avg=%.1f fps_min=%d lod_counts=%s" % [_blk, k, avg, int(_fps.min()) if not _fps.is_empty() else 0, str(_t.get("lod_counts"))])
        _blk = b
        if _blk >= 4:
            var on := 0.0
            var off := 0.0
            for x in _res["on"]:
                on += x
            for x in _res["off"]:
                off += x
            on /= 2.0
            off /= 2.0
            print("D7FPS done people=%d lod on %.1f fps, off %.1f fps (%+.0f%%)" % [(_t.get("people") as Array).size(), on, off, 100.0 * (on / maxf(1.0, off) - 1.0)])
            return true
        _t.set("lod_on", _blk % 2 == 1)
        _t.call("_lod_pass")
        _fps.clear()
    if _f % 10 == 0 and Time.get_ticks_msec() - _b0 - _blk * BLOCK_MS > 3000:
        _fps.append(Engine.get_frames_per_second())
    return false
