extends SceneTree
## S166 gate (tools/_solo42_test.gd): System 42c !solo engine half in town.gd (DIRECTIVE sup-nov27-1844).
## Loads the real Town, enlists three heroes, sends one SOLO and one through the open muster, and
## checks the solo never touches the queue, runs in its own lane beside the open delve, and is
## refused twice. Prints SOLO_TEST OK n of n / FAIL (or NO VERDICT if the town never opened the scar).
var _t: Node
var _f := 0
var _fails := []
var _n := 0
var _phase := 0
func _ok(c: bool, what: String) -> void:
    _n += 1
    if not c:
        _fails.append(what)
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _done() -> void:
    if _fails.is_empty():
        print("SOLO_TEST OK %d of %d" % [_n, _n])
    else:
        print("SOLO_TEST FAIL %d of %d: %s" % [_n - _fails.size(), _n, str(_fails)])
    quit()
func _process(_d: float) -> bool:
    _f += 1
    if _phase == 0 and _f == 120:
        if not (_t.get("_scar_info") as Dictionary).has("post"):
            print("SOLO_TEST NO VERDICT: scar never opened by frame 120")
            quit(2)
            return true
        for v in [["s1", "Lonewolf"], ["s2", "Crowd"], ["s3", "Nobody"]]:
            _t.call("chat_line", v[0], v[1], "!enlist knight")
        var chat = _t.get("chat")
        _ok(String(_t.call("_on_solo", "zz")).contains("no hero"), "no hero refused")
        _ok(String(_t.call("_on_solo", "s1")) == "", "s1 sets off solo")
        _ok(not chat.delve_queue.has("s1") and not (_t.get("_at_mouth") as Array).has("s1"), "solo not in queue or mouth")
        _ok(String(chat.away.get("s1", "")) != "on the road to the scar", "solo away is not the muster's road string")
        _ok(String(_t.call("_on_solo", "s1")).contains("already"), "second solo refused")
        # straight to the town's own !delve entry (chat's per-user cooldown would eat a second line this frame)
        _t.call("_on_delve", "s2")
        _ok(chat.delve_queue.has("s2"), "s2 queued through open muster")
        _ok(String(_t.call("_on_solo", "s2")).contains("muster"), "queued hero cannot also solo")
        # skip both walks: the solo enters, and the open muster fires with s2 at the mouth
        _t.call("_solo_enter", "s1")
        var sd: Dictionary = _t.get("solo_delves")
        _ok(sd.has("s1"), "solo delve live")
        _ok(_t.get("delve") == null, "solo did not take town.delve")
        var d1 = sd.get("s1")
        _ok(d1 != null and int(d1.lane) < 0, "solo lane negative")
        _ok(d1 != null and d1.party.size() == 1, "party of one")
        (_t.get("_at_mouth") as Array).append("s2")
        _t.call("_begin_delve")
        _ok(_t.get("delve") != null, "open delve begins while solo is below")
        _ok(_t.get("delve") != null and _t.get("delve").party.size() == 1 and String(_t.get("delve").party[0]["uid"]) == "s2", "open party is s2 only")
        _ok(int(_t.get("delve").lane) == 0, "open delve on lane 0")
        _ok(String(_t.call("_on_solo", "s2")).contains("muster") or String(_t.call("_on_solo", "s2")).contains("below"), "hero below cannot solo")
        _phase = 1
    elif _phase == 1 and _f == 900:
        var sd: Dictionary = _t.get("solo_delves")
        _ok(sd.has("s1") and sd["s1"].floor_no >= 1, "solo reached a floor")
        _done()
        return true
    if _f > 3000:
        print("SOLO_TEST NO VERDICT: capped")
        quit(2)
        return true
    return false
