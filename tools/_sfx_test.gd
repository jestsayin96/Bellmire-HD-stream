extends SceneTree
## Sound test: real town. The Sfx node is live, the buses are set (music at
## -14 dB), day music plays; night brings the night music and the bell; a raid
## brings the horn and the raid music; hits, spells, coins, splashes and the
## death sting all sound. Saves a frame to renders/cycles/20261111_sfx.
var _t: Node3D
var _f := 0
var _step := 0
var _at := 0
var _fails: Array = []
const OUT := "res://renders/cycles/20261111_sfx"

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _ms() -> int:
    return Time.get_ticks_msec()

func _check(ok: bool, what: String) -> void:
    print("SFX_TEST %s %s" % ["pass" if ok else "FAIL", what])
    if not ok:
        _fails.append(what)

func _process(_d: float) -> bool:
    _f += 1
    var s := Sfx.live()
    if _f == 20:
        _check(s != null, "Sfx node live")
        if s == null:
            print("SFX_TEST FAIL")
            return true
        var mi := AudioServer.get_bus_index("Music")
        _check(mi >= 0 and is_equal_approx(AudioServer.get_bus_volume_db(mi), -14.0), "Music bus at -14 dB")
        _check(AudioServer.get_bus_index("Sfx") >= 0 and AudioServer.get_bus_index("Ambience") >= 0, "Sfx and Ambience buses")
        var eye := RtsCamera.new()
        _t.add_child(eye)
        eye.setup(_t)
        _at = _ms()
        _step = 1
    if s == null:
        return _f > 600
    if _step == 1 and _ms() - _at > 1500:
        _check(s.mood == "day", "day music at 07:12 (mood=%s)" % s.mood)
        var playing := 0
        for c in s.get_children():
            if c is AudioStreamPlayer and (c as AudioStreamPlayer).playing:
                playing += 1
        _check(playing >= 2, "music + ambience playing (%d players)" % playing)
        if not _t.get("economy"):
            _check(false, "economy")
        _t.economy.clock = 0.80          # 19:12 - night
        _at = _ms()
        _step = 2
    if _step == 2 and _ms() - _at > 4500:
        _check(s.mood == "night", "night music after dusk (mood=%s)" % s.mood)
        _check(int(s.plays.get("bell", 0)) >= 3, "bell tolled at dusk (%d)" % int(s.plays.get("bell", 0)))
        _t.raids.force_level = 3
        _t.raids.raid("scar")
        _at = _ms()
        _step = 3
    if _step == 3 and _ms() - _at > 1500:
        _check(not (_t.raids.raiders as Array).is_empty(), "a raid is on")
        _check(s.mood == "raid", "raid music (mood=%s)" % s.mood)
        _check(int(s.plays.get("horn", 0)) == 1, "raid horn once (%d)" % int(s.plays.get("horn", 0)))
        var r0: Node3D = (_t.raids.raiders[0] as Dictionary)["node"]
        var before := int(s.plays.get("hit", 0))
        if r0 is Monster:
            (r0 as Monster).hurt(1.0)
        else:
            Sfx.at("hit", r0.global_position)
        _check(int(s.plays.get("hit", 0)) > before, "a hit sounds")
        Spells.cast("bolt", r0, r0.global_position + Vector3(4, 0, 0))
        _check(int(s.plays.get("spell", 0)) >= 1, "a spell sounds")
        Sfx.play("coin")
        Sfx.at("splash", r0.global_position)
        Sfx.sting()
        for k in ["coin", "splash", "death"]:
            _check(int(s.plays.get(k, 0)) >= 1, "%s sounds" % k)
        _at = _ms()
        _step = 4
    if _step == 4 and _ms() - _at > 600:
        root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "/town_raid.png"))
        print("SFX_TEST plays %s" % str(s.plays))
        print("SFX_TEST %s" % ("OK" if _fails.is_empty() else "FAIL " + ", ".join(_fails)))
        return true
    return _f > 20000
