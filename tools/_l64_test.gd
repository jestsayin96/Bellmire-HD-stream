extends SceneTree
## L64 director test (WINDOWED). Real town, director on, 3 viewer heroes delving, a raid mid-run,
## a synthetic death if none happens naturally. Audits the director's own decision log:
## no non-story subject inside REPEAT_WINDOW, no hold past its stated max, every cut has a why.
var _t: Node3D
var _eye: RtsCamera
var _f := 0
var _raid_at := -1.0
var _death_at := -1.0
var _shots := 0
var _natural_death := false
var RUN_S := 300.0
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _shot(tag: String) -> void:
    root.get_texture().get_image().save_png("user://l64_%s.png" % tag)
    print("SHOT l64_%s cur=%s" % [tag, _eye.director._cur.get("key", "-")])
func _process(_d: float) -> bool:
    _f += 1
    if _f == 20:
        _eye = RtsCamera.new()
        _t.add_child(_eye)
        _eye.setup(_t)
        for u in ["1001", "1002", "1003"]:
            _t.chat_line(u, "Viewer" + u, "!enlist knight")
        for u in ["1001", "1002", "1003"]:
            _t.chat_line(u, "Viewer" + u, "!delve")
    if _f == 40:
        _eye.director._set_on(true)
        Engine.time_scale = 4.0
    if _f < 40:
        return false
    var d: AutoDirector = _eye.director
    if _raid_at < 0.0 and d._clock > 100.0:
        _raid_at = d._clock
        _t.raids.force_level = 3
        _t.raids.raid("scar")
        print("RAID started at ", d._clock)
    if _raid_at > 0.0 and d._clock > _raid_at + 6.0 and _shots == 0:
        _shot("raid"); _shots = 1
    if _death_at < 0.0 and d._clock > 190.0:
        _death_at = d._clock
        if d._deaths.is_empty():
            d._deaths.append({"key": "death_synthetic_%d" % int(d._clock), "pos": Vector3(0, 0, 0), "t": d._clock})
            print("SYNTHETIC death injected at ", d._clock)
        else:
            _natural_death = true
    if _death_at > 0.0 and d._clock > _death_at + 2.0 and _shots == 1:
        _shot("death"); _shots = 2
    if d._clock > 250.0 and _shots == 2:
        _shot("quiet"); _shots = 3
    if d._clock >= RUN_S:
        _audit(d)
        return true
    return false
func _audit(d: AutoDirector) -> void:
    var cuts: Array = []
    for l in d.log_lines:
        var m := RegEx.create_from_string("t=([0-9.]+) CUT (\\S+) shot=(\\S+) pri=([0-9.\\-]+) why=(\\S*)")
        var r := m.search(l)
        if r:
            cuts.append({"t": float(r.get_string(1)), "key": r.get_string(2), "shot": r.get_string(3), "why": r.get_string(5)})
    var bad := 0
    for i in cuts.size():
        var c: Dictionary = cuts[i]
        var story: bool = c["key"] == "raid" or String(c["key"]).begins_with("lord_") or String(c["key"]).begins_with("death_")
        if not story:
            for j in i:
                if cuts[j]["key"] == c["key"] and float(c["t"]) - float(cuts[j]["t"]) < AutoDirector.REPEAT_WINDOW:
                    print("FAIL repeat ", c["key"], " at ", c["t"], " prev ", cuts[j]["t"]); bad += 1
        if c["why"] == "":
            print("FAIL no why at ", c["t"]); bad += 1
        if i + 1 < cuts.size():
            var hold: float = float(cuts[i + 1]["t"]) - float(c["t"])
            var mx: float = float(AutoDirector.SHOTS.get(c["shot"], {"max": 22.0})["max"]) * 1.4 + 2.0
            if hold > mx and cuts[i + 1]["why"] != "shot_gone":
                print("FAIL hold ", c["key"], " ", hold, " > ", mx); bad += 1
    var shots := {}
    for c in cuts:
        shots[c["shot"]] = int(shots.get(c["shot"], 0)) + 1
    print("L64_TEST cuts=%d shots=%s natural_death=%s bad=%d" % [cuts.size(), shots, _natural_death, bad])
    print("L64_TEST ", "OK" if bad == 0 and cuts.size() >= 8 else "FAIL")
