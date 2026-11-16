extends SceneTree
## D37: prove E3PO exists, is immortal (out of the defender roster), has his
## lore wired, and that saying a line reaches the Chronicle + his shout.
var _t: Node3D
var _f := 0
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _process(_d: float) -> bool:
    _f += 1
    if _f < 120:
        return false
    var nb = _t.get("notables")
    if nb == null:
        print("D37_TEST FAIL: no notables"); return true
    var e = nb.by_key("e3po")
    var ok := true
    if e == null or not is_instance_valid(e):
        print("D37 FAIL: E3PO not spawned"); print("D37_TEST FAIL"); return true
    var title := String(e.notable_title)
    var in_people := (_t.get("people") as Array).has(e)
    var lore_n := (nb._e3po_lore as Dictionary).size()
    # immortality: he must NOT be in the raid defender roster
    var raids = _t.get("raids")
    var defs: Array = raids.call("_defenders")
    var in_defenders := defs.has(e)
    # picker over a few categories (incl a sub-keyed one)
    var picks := {
        "intro": nb._e3po_pick("intro"),
        "raid": nb._e3po_pick("raid"),
        "night_watch": nb._e3po_pick("night_watch"),
        "roll_crit": nb._e3po_pick("viewer_roll", "crit"),
    }
    var pick_ok := true
    for k in picks:
        if String(picks[k]) == "": pick_ok = false
    # say an event line -> Chronicle feed grows + his shout is set
    var feed: Array = _t.get("feed")
    var before := feed.size()
    nb.call("_e3po_say", "festival")
    var feed_grew := feed.size() > before
    var shouted := not (e.shout_lines as Array).is_empty()
    print("D37 title=", title, " in_people=", in_people, " lore_cats=", lore_n,
          " in_defenders=", in_defenders)
    print("D37 picks: intro=", picks["intro"].substr(0,40))
    print("D37 picks: roll_crit=", picks["roll_crit"].substr(0,40))
    print("D37 pick_ok=", pick_ok, " feed_grew=", feed_grew, " shouted=", shouted,
          " e3po_pos=", e.global_position)
    ok = (title == "Commander of the Guards") and in_people and lore_n >= 20 \
         and not in_defenders and pick_ok and feed_grew and shouted
    print("D37_TEST ", ("OK" if ok else "FAIL"))
    return true
