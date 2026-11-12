extends SceneTree
## D8 test - the two things the 30-minute soak broke:
## 1) a chain bolt's later hops landing after its floor was freed (SCRIPT ERROR
##    add_child on null in Spells._arc_line / _burst), and renew motes whose host
##    went first ("Lambda capture freed");
## 2) a viewer's hero caught by a raid on the way to the docks: after the raid the
##    errand's arrival fired where they stood. Now they walk on and fish.
var _t: Node3D
var _f := 0
var _rd: Raids
var _floor: Node3D
var _uid := "2001"
var _raid_f := -1
var _over_f := -1
var _had_dest := false
var _fail := 0
var _ms0 := 0
var _fish_ms := 0
var _left := -1

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _angler(b: Node) -> bool:
    for c in b.get_children():
        if c is Angler:
            return true
    return false

func _process(_d: float) -> bool:
    _f += 1
    if _f == 10:
        _rd = _t.get("raids")
        _rd.force_level = 3
        _rd.set("_raid_t", 99999.0)
        _t.call("chat_line", _uid, "Fisher", "!enlist knight")
        _ms0 = Time.get_ticks_msec()
        # 1) a stand-in floor with a 3-hop chain bolt and a renew on a body, freed at once
        _floor = Node3D.new()
        root.add_child(_floor)
        var host := Node3D.new()
        _floor.add_child(host)
        Spells._chain(_floor, Vector3(0, 1, 0), [Vector3(2, 1, 0), Vector3(4, 1, 0), Vector3(6, 1, 0), Vector3(8, 1, 0)], Color(0.6, 0.8, 1.0))
        Spells._renew(_floor, host, Color(0.4, 1.0, 0.5))
    if _f == 40:
        _floor.queue_free()      # mid-flight: the hops and the motes outlive their floor
        print("D8 floor freed under a chain bolt and a renew")
    # the per-viewer cooldown is wall time
    if _fish_ms == 0 and _ms0 > 0 and Time.get_ticks_msec() - _ms0 > 4000:
        print("D8 fish: ", _t.call("chat_line", _uid, "Fisher", "!fish"))
        _fish_ms = _f
    if _fish_ms > 0 and _f == _fish_ms + 30 and _raid_f < 0:
        var b: HeroBody = (_t.get("heroes") as Dictionary).get(_uid)
        print("D8 hero errand=%s route=%d before the raid" % [b.errand, b._route.size()])
        if b.errand != "fish" or b._route.is_empty():
            print("D8 FAIL the hero is not on the way to the docks")
            _fail += 1
        Engine.time_scale = 4.0
        seed(11)
        _rd.raid()
        _raid_f = _f
    if _raid_f > 0 and _over_f < 0:
        var b2: HeroBody = (_t.get("heroes") as Dictionary).get(_uid)
        if _rd._fighters.has(b2) and (_rd._fighters[b2] as Dictionary).has("dest"):
            _had_dest = true
        if _f > _raid_f + 120 and _rd.raiders.is_empty():
            _over_f = _f
            print("D8 raid over after %d frames, hero errand=%s route=%d kept_dest=%s" % [_f - _raid_f, b2.errand, b2._route.size(), _had_dest])
    if _over_f > 0 and _f == _over_f + 60 * 60:
        var left: Array = []
        for k in _rd._fighters.keys():
            if is_instance_valid(k):
                var st: Dictionary = _rd._fighters[k]
                left.append("%s %.1f m from post" % [(k as Townsfolk).person_name, _rd._flat((k as Node3D).global_position, st["post"])])
        print("D8 60 s after the raid, still standing down: %d %s" % [left.size(), left])
        _left = left.size()
    if _over_f > 0:
        var b3: HeroBody = (_t.get("heroes") as Dictionary).get(_uid)
        if b3 != null and is_instance_valid(b3) and _angler(b3) and _left >= 0:
            print("D8 the hero walked on and is fishing %d frames after the raid" % (_f - _over_f))
            if not _had_dest:
                print("D8 FAIL the raid did not keep the errand's destination")
                _fail += 1
            if _left > 0:
                print("D8 FAIL defenders still walking to their posts a minute after the raid")
                _fail += 1
            print("D8_TEST OK" if _fail == 0 else "D8_TEST FAIL %d" % _fail)
            return true
        if _f - _over_f > 60 * 180:
            var where := "gone"
            if b3 != null and is_instance_valid(b3):
                where = "errand=%s route=%d" % [b3.errand, b3._route.size()]
            print("D8 FAIL no rod 120 s after the raid: ", where)
            print("D8_TEST FAIL")
            return true
    if _f > 60 * 600:
        print("D8 FAIL timeout (raid never ended?) raiders=%d fighters=%d" % [_rd.raiders.size(), _rd._fighters.size()])
        print("D8_TEST FAIL")
        return true
    return false
