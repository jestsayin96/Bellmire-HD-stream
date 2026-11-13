extends SceneTree
## D28 LIVE-RUN FEATURE CENSUS. Boots the real Town with the director on and six
## fake viewers enlisting/delving/fishing/forging/rerolling, runs an accelerated
## soak (Engine.time_scale), and COUNTS per feature so we learn which "DONE"
## features are BROKEN (count 0) vs merely TOO RARE (a handful in the window).
## Reads existing static counters (Sfx.plays, Rig.plays, Spells.cast_counts,
## Townsfolk.voices/acts, Monster.voiced, Dice.rolled) + Delve.trap_log + a feed
## scan + live-boss polling. Headless. Env: CENSUS_MIN (wall min, default 8),
## CENSUS_SCALE (time scale, default 8). Prints a CENSUS block at the end.
var _t: Node3D
var _eye
var _f := 0
var _t0 := 0
var _cmd_ms := 0
var _act_ms := 0
var _seen := 0
var _queue: Array = []
var _minutes := 8
var _scale := 8.0
var V := [["1001","JestFan","knight"],["1002","MossyMage","mage"],["1003","QuietArrow","ranger"],
          ["1004","BigAxe","barbarian"],["1005","DawnCleric","cleric"],["1006","Stabbity","rogue"]]
# feed buckets
var feedb := {"lord":0,"death":0,"loot_gold":0,"vial":0,"hoard":0,"forge":0,"buy_sell":0,"trap":0,"raid":0,"catch":0,"wear":0}
var _descends := 0
# trap accumulation across delve instances
var _trap_tot := {"spotted":0,"disarmed":0,"sprung":0,"saved":0,"damage":0.0}
var _trap_cur_id := 0
var _trap_cur := {"spotted":0,"disarmed":0,"sprung":0,"saved":0,"damage":0.0}
# boss polling
var bosses_seen := {}      # name -> times encountered
var bosses_killed := 0
var _cur_lord = null
var _cur_lord_name := ""

func _initialize() -> void:
    var m := OS.get_environment("CENSUS_MIN")
    if m != "": _minutes = maxi(1, int(m))
    var s := OS.get_environment("CENSUS_SCALE")
    if s != "": _scale = maxf(1.0, float(s))
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    print("CENSUS start minutes=%d scale=%.0f" % [_minutes, _scale])

func _say(i: int, msg: String) -> void:
    _t.call("chat_line", V[i][0], V[i][1], msg)

func _act() -> void:
    var r = _t.get("roster")
    var hs: Dictionary = _t.get("heroes")
    var eco = _t.get("economy")
    for i in V.size():
        var h: Dictionary = r.get_hero(V[i][0])
        if h.is_empty():
            _queue.append([i, "!enlist " + V[i][2]]); continue
        if not bool(h.get("alive", false)):
            _queue.append([i, "!reroll"]); continue
        var b = hs.get(V[i][0])
        if b == null or not is_instance_valid(b) or not (b as HeroBody).visible or (b as HeroBody).errand != "" or not (b as HeroBody)._route.is_empty():
            continue
        var pick: int = (i + int(eco.day) + _f / 997) % 5
        _queue.append([i, ["!delve","!fish","!delve","!forge","!delve"][pick]])

func _scan_feed() -> void:
    var feed: Array = _t.get("feed")
    while _seen < feed.size():
        var l := String(feed[_seen]).to_lower()
        if l.contains("descend into the scar") or l.contains("into the scar"): _descends += 1
        if l.contains(" rises.") or l.contains("is down here") or l.contains("lord of floor"): feedb["lord"] += 1
        if l.contains("is killed") or l.contains("cut down") or l.contains("falls on floor") or l.contains("falls to"): feedb["death"] += 1
        if l.contains("gold on floor") or l.contains("gold each") or l.contains("come home to bellmire"): feedb["loot_gold"] += 1
        if l.contains("vial of") or l.contains("flask"): feedb["vial"] += 1
        if l.contains("hoard"): feedb["hoard"] += 1
        if l.contains("forge") or l.contains("reforge"): feedb["forge"] += 1
        if l.contains("buys") or l.contains("sells"): feedb["buy_sell"] += 1
        if l.contains("trap") or l.contains("spikes") or l.contains("darts") or l.contains("blade") or l.contains("the floor drops"): feedb["trap"] += 1
        if l.contains("riding on the west road") or l.contains("boil out of the dungeon") or l.contains("driven off"): feedb["raid"] += 1
        if l.contains(" lands a "): feedb["catch"] += 1
        if l.contains(" wears ") or l.contains(" dons ") or l.contains(" dyes "): feedb["wear"] += 1
        _seen += 1

func _poll_delve() -> void:
    var d = _t.get("delve")
    if d == null: return
    # traps: accumulate across delve instances
    if "trap_log" in d:
        var id: int = d.get_instance_id()
        var tl: Dictionary = d.trap_log
        if id != _trap_cur_id:
            for k in _trap_tot: _trap_tot[k] += _trap_cur.get(k, 0)
            _trap_cur_id = id
        _trap_cur = tl.duplicate()
    # live boss
    var lord = null
    if "dun" in d and d.dun != null and "lord" in d.dun:
        lord = d.dun.lord
    if lord != null and is_instance_valid(lord):
        var nm := String((lord.def as Dictionary).get("name", "a lord")) if "def" in lord else "a lord"
        if lord != _cur_lord:
            if _cur_lord != null and (not is_instance_valid(_cur_lord) or float(_cur_lord.get("hp")) <= 0.0):
                bosses_killed += 1
            _cur_lord = lord
            _cur_lord_name = nm
            bosses_seen[nm] = int(bosses_seen.get(nm, 0)) + 1
    elif _cur_lord != null:
        if not is_instance_valid(_cur_lord) or (("hp" in _cur_lord) and float(_cur_lord.hp) <= 0.0):
            bosses_killed += 1
        _cur_lord = null

func _process(dt: float) -> bool:
    _f += 1
    if _f == 20:
        var RtsCam = load("res://scripts/rts_camera.gd")
        _eye = RtsCam.new(); _t.add_child(_eye); _eye.setup(_t)
        for i in V.size(): _queue.append([i, "!enlist " + V[i][2]])
        for i in V.size(): _queue.append([i, "!delve"])
    if _f == 40:
        if _eye and _eye.director: _eye.director._set_on(true)
        Engine.time_scale = _scale
        _t0 = Time.get_ticks_msec(); _act_ms = _t0
    if _f < 40: return false
    var now := Time.get_ticks_msec()
    if not _queue.is_empty() and now - _cmd_ms > 1500:
        var q: Array = _queue.pop_front(); _say(int(q[0]), String(q[1])); _cmd_ms = now
    if now - _act_ms > 60000:
        _act_ms = now; _act()
    _scan_feed()
    _poll_delve()
    if now - _t0 >= _minutes * 60000:
        _finish()
        return true
    return false

func _topn(d: Dictionary, n: int) -> String:
    var arr: Array = []
    for k in d: arr.append([String(k), int(d[k])])
    arr.sort_custom(func(a, b): return a[1] > b[1])
    var out: Array = []
    for i in range(min(n, arr.size())): out.append("%s=%d" % [arr[i][0], arr[i][1]])
    return ", ".join(out)

func _finish() -> void:
    # roll the last open delve's traps into the total
    for k in _trap_tot: _trap_tot[k] += _trap_cur.get(k, 0)
    var sx = Sfx.live()
    var plays: Dictionary = sx.plays if sx else {}
    var sets: Dictionary = Sfx.SETS
    var total_sfx := 0
    var zero_kinds: Array = []
    var counted := 0
    for k in sets:
        var c := int(plays.get(k, 0))
        total_sfx += c
        if c == 0: zero_kinds.append(String(k))
        else: counted += 1
    var orphan: Array = []   # played but NOT in SETS -> counted yet silent (the _ok_now overcount)
    for k in plays:
        if not sets.has(k): orphan.append("%s=%d" % [String(k), int(plays[k])])
    var rig_plays: Dictionary = Rig.plays
    var anim_total := 0
    for k in rig_plays: anim_total += int(rig_plays[k])
    var spells: Dictionary = Spells.cast_counts
    var eco = _t.get("economy")
    var raids_n := int((_t.get("raids") as Raids).raids)
    # cosmetics worn: inspect roster heroes
    var r = _t.get("roster")
    var cos_worn := 0
    var acc_worn := 0
    var tiers := []
    for v in V:
        var h: Dictionary = r.get_hero(v[0])
        if h.is_empty(): continue
        var cos: Dictionary = h.get("cos", {})
        var acc: Dictionary = h.get("acc", {})
        cos_worn += cos.size()
        acc_worn += acc.size()
        tiers.append("%s w%d/a%d k%d" % [String(h.get("name","?")), int(h.get("weapon",0)), int(h.get("armour",0)), int(h.get("kills",0))])
    print("==================== D28 CENSUS ====================")
    print("CENSUS runtime: %d wall-min at %.0fx  (game day=%d hour=%.1f)  descends=%d raids=%d" % [_minutes, _scale, eco.day if eco else -1, eco.hour() if eco else -1.0, _descends, raids_n])
    print("CENSUS SFX: total_plays=%d  distinct_kinds_fired=%d/%d  SETS_never_fired=%d" % [total_sfx, counted, sets.size(), zero_kinds.size()])
    print("CENSUS SFX top: %s" % _topn(plays, 18))
    print("CENSUS SFX never-fired kinds (%d): %s" % [zero_kinds.size(), ", ".join(zero_kinds)])
    print("CENSUS SFX played-but-not-in-SETS (silent, counted): %s" % ("none" if orphan.is_empty() else ", ".join(orphan)))
    print("CENSUS ANIM: total_starts=%d distinct_clips=%d  misses(distinct)=%d fell_back=%d" % [anim_total, rig_plays.size(), int(Rig.misses), int(Rig.fell_back)])
    print("CENSUS ANIM top: %s" % _topn(rig_plays, 20))
    print("CENSUS ANIM missing clips: %s" % str(Rig._missed.keys()))
    print("CENSUS SPELLS by name (%d distinct): %s" % [spells.size(), _topn(spells, 20)])
    print("CENSUS BOSSES: encountered_distinct=%d killed=%d  seen=%s" % [bosses_seen.size(), bosses_killed, str(bosses_seen)])
    print("CENSUS TRAPS: spotted=%d disarmed=%d sprung=%d saved=%d damage_applied=%.0f" % [int(_trap_tot["spotted"]), int(_trap_tot["disarmed"]), int(_trap_tot["sprung"]), int(_trap_tot["saved"]), float(_trap_tot["damage"])])
    print("CENSUS LOOT/forge (feed): gold_lines=%d vials=%d hoards=%d forge=%d buy_sell=%d chest_open_sfx=%d" % [feedb["loot_gold"], feedb["vial"], feedb["hoard"], feedb["forge"], feedb["buy_sell"], int(plays.get("chest_open",0))])
    print("CENSUS COSMETICS: cos_worn=%d acc_worn=%d (viewer-driven via !wear/!dye; feed wear lines=%d)" % [cos_worn, acc_worn, feedb["wear"]])
    print("CENSUS GEAR tiers: %s" % ", ".join(tiers))
    print("CENSUS VOICES town=%d dungeon_monster=%d  acts=%s  dice_rolled=%d" % [_sum(Townsfolk.voices), _sum(Monster.voiced), _topn(Townsfolk.acts, 10), int(Dice.rolled)])
    print("CENSUS FEED buckets: %s" % str(feedb))
    print("==================== END CENSUS ====================")

func _sum(d: Dictionary) -> int:
    var s := 0
    for k in d: s += int(d[k])
    return s
