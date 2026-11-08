extends SceneTree
## STREAM SOAK - FAKE CHAT FEED, nothing is posted anywhere. The real town with
## six viewers playing alongside the town band, raids, caravans, settlers and
## the day clock, for 10 valley days. Logs one line per day.
var _t: Node3D
var _f := 0
var _seen := 0
var _t0 := 0
var _last_day := 0
var _cmd_ms := 0
var _queue: Array = []
var _stats := {"descend": 0, "home": 0, "wiped": 0, "viewer_dead": 0, "caught": 0, "bought": 0}
var V := [["1001", "JestFan", "knight"], ["1002", "MossyMage", "mage"], ["1003", "QuietArrow", "ranger"],
          ["1004", "BigAxe", "barbarian"], ["1005", "DawnCleric", "cleric"], ["1006", "Stabbity", "rogue"]]
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _t0 = Time.get_ticks_msec()
func _say(i: int, msg: String) -> void:
    var v: Array = V[i]
    var out: String = _t.call("chat_line", v[0], v[1], msg)
    if out.to_lower().contains("buy") or out.to_lower().contains("forge"):
        _stats["bought"] += 1
func _process(_d: float) -> bool:
    _f += 1
    if _f == 10:
        for i in V.size():
            _queue.append([i, "!enlist " + V[i][2]])
        Engine.time_scale = 8.0
    # one command every 1.7 s of WALL clock (the per-viewer cooldown is real time)
    if not _queue.is_empty() and Time.get_ticks_msec() - _cmd_ms > 1700:
        var q: Array = _queue.pop_front()
        _say(int(q[0]), String(q[1]))
        _cmd_ms = Time.get_ticks_msec()
    var eco: Economy = _t.get("economy")
    if eco == null:
        return false
    var feed: Array = _t.get("feed")
    while _seen < feed.size():
        var l := String(feed[_seen])
        if l.contains("descend into the scar"):
            _stats["descend"] += 1
        if l.contains("come home to Bellmire"):
            _stats["home"] += 1
        if l.contains("No one comes home"):
            _stats["wiped"] += 1
        if l.contains("!reroll"):
            _stats["viewer_dead"] += 1
        if l.contains(" lands a "):
            _stats["caught"] += 1
        if l.begins_with("Bellmire grows") or l.begins_with("Bellmire falls") or l.contains("chief of Bellmire"):
            print("  ", l)
        _seen += 1
    if eco.day != _last_day:
        _last_day = eco.day
        # each morning the viewers act: some fish, some shop, the rest delve
        var r: Roster = _t.get("roster")
        var hs: Dictionary = _t.get("heroes")
        for i in V.size():
            var h: Dictionary = r.get_hero(V[i][0])
            if h.is_empty():
                continue
            if not bool(h.get("alive", false)):
                _queue.append([i, "!reroll"])
                continue
            # only an idle hero takes a new errand (a viewer would not cancel their own walk)
            var b = hs.get(V[i][0])
            if b == null or not is_instance_valid(b) or not (b as HeroBody).visible or (b as HeroBody).errand != "" or not (b as HeroBody)._route.is_empty():
                continue
            var pick := (i + eco.day) % 3
            _queue.append([i, ["!fish", "!forge", "!delve"][pick]])
        var alive := 0
        for v in V:
            if r.is_alive(v[0]):
                alive += 1
        var adv: Adventurers = _t.get("adventurers")
        print("DAY %d souls=%d lvl=%d gold=%d food=%d gear=%d ore=%d | viewers alive=%d | band=%d | delves in=%d home=%d wiped=%d | raids=%d dead=%d | viewer deaths=%d catches=%d real_s=%d" % [
            eco.day, eco.population(), eco.town_level, eco.treasury, int(eco.stock["food"]), int(eco.stock["gear"]), int(eco.stock["ore"]),
            alive, adv.count(), _stats["descend"], _stats["home"], _stats["wiped"], (_t.get("raids") as Raids).raids, eco.dead,
            _stats["viewer_dead"], _stats["caught"], (Time.get_ticks_msec() - _t0) / 1000])
        if eco.day > 10:
            return true
    return (Time.get_ticks_msec() - _t0) > 340000
