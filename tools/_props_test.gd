extends SceneTree
## Cycle 53: the Fantasy Props MegaKit placements. Counts them in the town
## (tavern chairs, chapel stand + candles, landmark banners) and on themed
## dungeon floors (registered as obstacles), and photographs each.
## Prints PROPS_TEST OK when every placement is present.
const OUT := "res://renders/cycles/20261111_props/"
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _fail := 0
var _shots: Array = []      # [name, cam pos, look at]
var _dun: Array = []

func _initialize() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _count(n: Node, nm: String) -> int:
    var c := 0
    for k in n.find_children("*", "Node3D", true, false):
        if String(k.scene_file_path).ends_with("/" + nm + ".gltf"):
            c += 1
    return c

func _check(label: String, got: int, want: int) -> void:
    var ok := got >= want
    if not ok:
        _fail += 1
    print("%s %s: %d (want >= %d)" % ["PASS" if ok else "FAIL", label, got, want])

func _snap(nm: String) -> void:
    root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + nm + ".png"))
    print("SAVED ", nm)

func _process(_d: float) -> bool:
    _f += 1
    if _f == 5:
        _check("tavern Chair_1", _count(_t, "Chair_1"), 2)
        _check("chapel BookStand", _count(_t, "BookStand"), 1)
        _check("chapel CandleStick_Stand", _count(_t, "CandleStick_Stand"), 2)
        _check("chapel Candle_1", _count(_t, "Candle_1"), 1)
        _check("landmark Banner_1/2", _count(_t, "Banner_1") + _count(_t, "Banner_2"), 6)
        _check("door Lantern_Wall", _count(_t, "Lantern_Wall"), 10)
        _cam = Camera3D.new()
        _cam.fov = 50.0
        root.add_child(_cam)
        var lm: Dictionary = _t.get("landmarks")
        var sf: Dictionary = _t.get("_shop_frame")
        if lm.has("lm_chapel"):
            var p: Vector3 = lm["lm_chapel"][0]
            var fw: Vector3 = lm["lm_chapel"][1]
            var fr: Vector3 = p + fw * 11.5
            _shots.append(["town_chapel", fr + fw * 9.0 + Vector3(2.5, 5.0, 0), fr + Vector3(0, 1.2, 0)])
        if sf.has("tavern"):
            var y: Vector3 = sf["tavern"][0]
            var fw2: Vector3 = sf["tavern"][2]
            var sd: Vector3 = sf["tavern"][1]
            _shots.append(["town_tavern", y + fw2 * 8.0 + sd * 2.0 + Vector3(0, 5.5, 0), y + Vector3(0, 0.6, 0)])
        if lm.has("lm_hall"):
            var p3: Vector3 = lm["lm_hall"][0]
            var fw3: Vector3 = lm["lm_hall"][1]
            _shots.append(["town_hall_banners", p3 + fw3 * 24.0 + Vector3(0, 6.0, 0), p3 + fw3 * 8.0 + Vector3(0, 2.0, 0)])
    # town shots, one every 20 frames
    if _f >= 40 and _f < 40 + _shots.size() * 20:
        var i := (_f - 40) / 20
        var s: Array = _shots[i]
        _cam.make_current()
        _cam.global_position = s[1]
        _cam.look_at(s[2] + Vector3(0, (_t.call("height_at", (s[2] as Vector3).x, (s[2] as Vector3).z) as float), 0), Vector3.UP)
        if (_f - 40) % 20 == 19:
            _snap(String(s[0]))
    var town_end := 40 + _shots.size() * 20
    if _f == town_end + 1:
        _t.queue_free()
        var we := WorldEnvironment.new()
        var e := Environment.new()
        e.background_mode = Environment.BG_COLOR
        e.background_color = Color(0.02, 0.02, 0.03)
        e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
        e.ambient_light_color = Color(0.5, 0.48, 0.55)
        e.ambient_light_energy = 0.8
        e.tonemap_mode = Environment.TONE_MAPPER_AGX
        we.environment = e
        root.add_child(we)
        var want := {"prison": "Chain_Coil", "crypt": "CandleStick_Stand", "shrine": "BookStand", "keep": "Bookcase_2", "mess": "Bookcase_2", "workshop": "Bookcase_2"}
        var seen := {}
        for n in range(1, 60):
            var th := FloorGen.theme_for(n)
            if want.has(th) and not seen.has(th):
                seen[th] = n
        var x := 0.0
        for th in seen:
            var d := DungeonHD.new()
            d.position = Vector3(x, 0, 0)
            x += 400.0
            root.add_child(d)
            d.build(int(seen[th]))
            _dun.append([th, d, String(want[th])])
    if _f == town_end + 4:
        for row in _dun:
            var d: DungeonHD = row[1]
            var nm: String = row[2]
            var c := _count(d, nm)
            # each placed piece must sit on a registered obstacle
            var reg := 0
            for k in d.find_children("*", "Node3D", true, false):
                if String(k.scene_file_path).begins_with("res://assets/props/"):
                    var lp: Vector3 = (k as Node3D).position
                    for o in d.info.get("obstacles", []):
                        if Vector2(lp.x - (o[0] as Vector3).x, lp.z - (o[0] as Vector3).z).length() < 0.05:
                            reg += 1
                            break
            _check("floor %d (%s) %s" % [d.floor_no, row[0], nm], c, 1)
            var tot := 0
            for k in d.find_children("*", "Node3D", true, false):
                if String(k.scene_file_path).begins_with("res://assets/props/"):
                    tot += 1
            _check("floor %d props registered as obstacles" % d.floor_no, reg, tot - _count(d, "Bucket_Wooden_1"))
    var dstart := town_end + 10
    if _f >= dstart and _f < dstart + _dun.size() * 20:
        var i := (_f - dstart) / 20
        var d: DungeonHD = _dun[i][1]
        var target: Node3D = null
        for k in d.find_children("*", "Node3D", true, false):
            if String(k.scene_file_path).ends_with("/" + String(_dun[i][2]) + ".gltf"):
                target = k
                break
        if target:
            var tp := target.global_position
            _cam.make_current()
            _cam.global_position = tp + Vector3(3.5, 4.0, 4.5)
            _cam.look_at(tp + Vector3(0, 0.8, 0), Vector3.UP)
        if (_f - dstart) % 20 == 19:
            _snap("floor_%s" % _dun[i][0])
    if _f == dstart + _dun.size() * 20 + 2:
        print("PROPS_TEST OK" if _fail == 0 else "PROPS_TEST FAIL %d" % _fail)
        return true
    return _f > 3000
