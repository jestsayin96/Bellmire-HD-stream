extends SceneTree
## S167 SYSTEM 43 engine half: the S-F ladder. Unit checks on Roster, then a real !solo delve in
## Town.tscn that must raise solo_deepest, then the snapshot's rank_feed. Prints RANK_TEST OK|FAIL.
var _t: Node3D
var _f := 0
var _bad: Array = []
func _chk(ok: bool, what: String) -> void:
    if not ok:
        _bad.append(what)
func _initialize() -> void:
    var r := Roster.new()
    root.add_child(r)
    var h: Dictionary = r.fresh("u1", "Alpha", "knight")
    _chk(r.letter_rank(h) == "F", "new hero not F (%s)" % r.letter_rank(h))
    _chk(r.letter_band(h) == ["F", "E"], "F band %s" % str(r.letter_band(h)))
    h["solo_deepest"] = 10; h["lords"] = 2; h["minibosses"] = 6; h["weapon"] = 3; h["armour"] = 3
    var sc := r.letter_score(h)
    _chk(sc == 120 + 120 + 90 + 60, "score %d" % sc)
    _chk(r.letter_rank(h) == "C", "390 should be C, got %s" % r.letter_rank(h))
    _chk(r.letter_band(h) == ["D", "C", "B"], "C band %s" % str(r.letter_band(h)))
    _chk(int(r.letter_next(h).get("need", -1)) == 130, "need %s" % str(r.letter_next(h)))
    r._letter_check("u1", h)
    _chk(String(h.get("letter", "")) == "C", "letter not stored")
    h["weapon"] = 0; h["armour"] = 0; h["minibosses"] = 0     # gear lost to a death: rank must FALL
    r._letter_check("u1", h)
    _chk(String(h["letter"]) == "D", "rank did not fall: %s" % h["letter"])
    var g: Dictionary = r.fresh("u2", "Beta", "mage")
    _chk(not r.letters_match(h, g), "D and F matched")
    g["solo_deepest"] = 4                                    # 48 -> E
    _chk(r.letter_rank(g) == "E" and r.letters_match(h, g), "D and E did not match")
    r.note_lord("u2"); r.note_miniboss("u2")
    _chk(int(g["lords"]) == 1 and int(g["minibosses"]) == 1, "note_* did not count")
    var top: Dictionary = r.fresh("u3", "Gamma", "knight")
    top["solo_deepest"] = 200
    _chk(r.letter_rank(top) == "S" and r.letter_next(top).is_empty() and r.letter_band(top) == ["A", "S"], "S row")
    var feed := r.rank_feed()
    _chk((feed["by_key"] as Dictionary).size() == 3 and (feed["ladder"] as Array).size() == 7, "feed size")
    _chk(String(feed["by_key"]["Alpha"]["letter"]) == "D", "feed letter")
    print("RANK_UNIT ", "OK" if _bad.is_empty() else "FAIL " + str(_bad))
    r.queue_free()
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _process(_d: float) -> bool:
    _f += 1
    if _f == 120:
        _t.get("raids").set("_raid_t", 99999.0)
        _t.call("chat_line", "s1", "Lonewolf", "!enlist knight")
        _t.call("_solo_enter", "s1")
    if _f == 400:
        var ro = _t.get("roster")
        var h: Dictionary = ro.get_hero("s1")
        var d = (_t.get("solo_delves") as Dictionary).get("s1")
        var fl: int = int(d.floor_no) if d else -1
        print("RANK_SOLO floor=", fl, " solo=", d.solo if d else null, " solo_deepest=", int(h.get("solo_deepest", 0)))
        _chk(d != null and bool(d.solo), "solo delve not flagged")
        _chk(int(h.get("solo_deepest", 0)) >= 1 and int(h.get("solo_deepest", 0)) == fl, "solo_deepest not fed")
        var sp := SnapshotPublisher.new()   # NOT added to the tree and NOT setup(): it never posts
        sp.town = _t
        if sp != null:
            var p: Dictionary = sp.call("build_payload")
            _chk(p.has("rank_feed") and (p["rank_feed"]["by_key"] as Dictionary).has("Lonewolf"), "payload rank_feed missing Lonewolf")
            var sheets: Array = p.get("heroes", [])
            _chk(not sheets.is_empty() and sheets[0].has("letter"), "sheet has no letter")
            print("RANK_FEED ", JSON.stringify(p.get("rank_feed", {}).get("by_key", {}).get("Lonewolf", {})))
        else:
            _bad.append("no snapshot publisher found")
        sp.free()
        print("RANK_TEST ", "OK" if _bad.is_empty() else "FAIL " + str(_bad))
        quit()
    return false
