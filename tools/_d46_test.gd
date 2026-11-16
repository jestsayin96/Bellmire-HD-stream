extends SceneTree
## D46: the delving parties ride in the snapshot (v2) and the band board is off the stream.
## Real town, three viewer knights enlist and delve; then build_payload() must carry a parties
## array the hub can read, and PartyFrames must stay hidden and empty.
var _t: Node3D
var _eye: RtsCamera
var _f := 0
var _seen_at := -1
var _fails := 0
var _checks := 0
func _check(label: String, ok: bool) -> void:
    _checks += 1
    if not ok:
        _fails += 1
    print("D46 %s %s" % ["ok  " if ok else "FAIL", label])
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
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
        Engine.time_scale = 8.0
    if _f > 20 and _seen_at < 0 and _eye.party_frames.delves().size() > 0:
        _seen_at = _f
        Engine.time_scale = 1.0
    if _seen_at > 0 and _f - _seen_at == 60:
        var sp := SnapshotPublisher.new()
        sp.town = _t
        var p: Dictionary = sp.build_payload()
        _check("payload version is 2", int(p.get("v", 0)) == 2)
        _check("payload has a parties array", p.has("parties") and p["parties"] is Array)
        var parties: Array = p.get("parties", [])
        _check("at least one band below", parties.size() >= 1)
        var shape := true
        var names_ok := true
        var total := 0
        for b in parties:
            if not (b is Dictionary) or not b.has("name") or not b.has("floor") or not b.has("members"):
                shape = false
                continue
            if String(b["name"]) == "" or int(b["floor"]) < 1:
                shape = false
            for m in b["members"]:
                total += 1
                if not (m is Dictionary) or m.keys().size() != 5:
                    shape = false
                    continue
                if String(m["name"]) == "" or int(m["max_hp"]) < 1 or int(m["hp"]) < 0 or int(m["hp"]) > int(m["max_hp"]):
                    shape = false
                if String(m["status"]) == "" or String(m["name"]).contains("<"):
                    names_ok = false
        _check("every band {name, floor>=1, members[]} and every member {name, class, hp, max_hp, status} sane", shape)
        _check("no member name or status is empty or carries markup", names_ok)
        _check("the three viewers are in the party (members >= 3)", total >= 3)
        _check("capped: <= 8 bands", parties.size() <= SnapshotPublisher.PARTY_MAX)
        _check("payload serialises to JSON", JSON.stringify(p).length() > 100 and JSON.parse_string(JSON.stringify(p)) != null)
        print("D46 sample: %s" % JSON.stringify(parties).left(420))
        var pf := _eye.party_frames
        pf.refresh()
        _check("band board stays hidden on stream", not pf.visible)
        _check("band board holds no children", pf.get_child_count() == 0)
        _check("the delve is still tracked (delves() > 0)", pf.delves().size() > 0)
        print("D46_TEST %s (%d checks, %d failed)" % ["OK" if _fails == 0 else "FAIL", _checks, _fails])
        return true
    if _f > 9000:
        print("D46_TEST FAIL no delve ever started")
        return true
    return false
