extends SceneTree
## Party frames test: real town, the RtsCamera, three viewer knights enlist and
## delve. Waits for the delve to start, checks the frames show one row per
## delver with the party's oil, and saves frames to renders/cycles/20261111_party.
var _t: Node3D
var _eye: RtsCamera
var _f := 0
var _seen_at := -1
var _shots := 0
var _ok := false
const OUT := "res://renders/cycles/20261111_party"
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
func _process(_d: float) -> bool:
    _f += 1
    if _f == 20:
        _eye = RtsCamera.new()
        _t.add_child(_eye)
        _eye.setup(_t)
        if _eye.party_frames.visible:
            print("PARTY_TEST FAIL visible with no delve")
        for u in ["1001", "1002", "1003"]:
            _t.chat_line(u, "Viewer" + u, "!enlist knight")
        for u in ["1001", "1002", "1003"]:
            _t.chat_line(u, "Viewer" + u, "!delve")
        Engine.time_scale = 8.0
    if _f > 20 and _seen_at < 0 and _eye.party_frames.delves().size() > 0:
        _seen_at = _f
        Engine.time_scale = 1.0
        _eye._cycle_delve()
        print("PARTY_TEST delve seen at frame %d" % _f)
    if _seen_at > 0 and (_f - _seen_at) in [30, 200, 400]:
        var pf := _eye.party_frames
        pf.refresh()
        var d: Delve = pf.delves()[0] if not pf.delves().is_empty() else null
        var rows := 0
        if pf.get_child_count() > 0:
            rows = (pf.get_child(0).get_child(0) as VBoxContainer).get_child_count() - 1
        print("PARTY_TEST shot %d visible=%s blocks=%d rows=%d party=%d oil=%.1f floor=%d" % [_shots, pf.visible, pf.get_child_count(), rows, d.party.size() if d else -1, d.oil if d else -1.0, d.floor_no if d else -1])
        if d and pf.visible and rows == d.party.size():
            _ok = true
        _shots += 1
    if _seen_at > 0 and (_f - _seen_at) in [32, 202, 402]:
        root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "/party_%d.png" % (_shots - 1)))
    if (_seen_at > 0 and _f - _seen_at > 420) or _f > 9000:
        print("PARTY_TEST %s" % ("OK" if _ok else "FAIL"))
        return true
    return false
