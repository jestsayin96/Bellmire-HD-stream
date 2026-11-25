extends SceneTree
## Boss test (cycle 54): real town + RtsCamera, a party of four started straight
## onto floor 5 (a lord floor). Checks: the lord stands LORD_SCALE taller than
## its canon height; the Chronicle shows its name card; once it has risen and
## fights, the boss bar is up with its name and the director's best shot is the
## lord at 100+; when the lord is down the bar goes. Saves frames to
## renders/cycles/20261111_boss.
var _t: Node3D
var _eye: RtsCamera
var _d: Delve
var _f := 0
var _seen_at := -1
var _shots := 0
var _fails: Array = []
var _checks := 0
var _seen_ms := 0
var _dir_ms := -1
const OUT := "res://renders/cycles/20261111_boss"

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _check(ok: bool, what: String) -> void:
    _checks += 1
    print("BOSS_TEST %s %s" % ["pass" if ok else "FAIL", what])
    if not ok:
        _fails.append(what)

func _hud() -> FeedHUD:
    for c in _t.get_children():
        if c is FeedHUD:
            return c
    return null

func _process(_dt: float) -> bool:
    _f += 1
    if _f == 20:
        _eye = RtsCamera.new()
        _t.add_child(_eye)
        _eye.setup(_t)
        _check(_eye.boss_bar == null and get_nodes_in_group("hud_boss").is_empty(), "S89: the eye builds no floating boss card")
        var r: Roster = _t.get("roster")
        var ids := []
        for v in [["2001", "JestFan", "knight"], ["2002", "MossyMage", "mage"], ["2003", "DawnCleric", "cleric"], ["2004", "BigAxe", "barbarian"]]:
            var h: Dictionary = r.get_hero(v[0])
            if h.is_empty():
                h = r.fresh(v[0], v[1], v[2])
            h["alive"] = true
            h["weapon"] = 3
            h["armour"] = 3
            h["oil"] = 4
            ids.append(v[0])
        _d = Delve.new()
        _d.town = _t
        _d.roster = r
        _d.start_floor = 5
        _d.max_floors = 5
        _t.add_child(_d)
        _d.start(ids)
        _eye.director._set_on(true)
    if _f == 30:
        var l: Monster = _d.dun.lord if _d and _d.dun else null
        _check(l != null, "floor 5 has a lord")
        if l:
            var canon: float = float((Bestiary.BOSS_DEFS[String(_find_id(l))] as Dictionary)["h"])
            _check(absf(float(l.def["h"]) - canon * Bestiary.LORD_SCALE) < 0.01, "lord is %.1f m (canon %.1f x %.1f)" % [float(l.def["h"]), canon, Bestiary.LORD_SCALE])
        var hud := _hud()
        # S89 INVERTED: Mr. E's 10:17 directive item 3 took the boss card out of the Chronicle (HUD U126,
        # feed_hud.gd:284-287). A lord has risen here, so a card would show if one still existed.
        _check(hud != null and not hud.card_showing(), "S89: no boss card in the Chronicle as the lord rises (title '%s')" % (hud._card_title.text if hud else "-"))
        root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "/card.png"))
    if _f > 30 and _seen_at < 0 and _d.lord_fighting() != null:
        _seen_at = _f
        _seen_ms = Time.get_ticks_msec()
        print("BOSS_TEST lord fighting at frame %d" % _f)
    # the director thinks once a real second: it must be on the lord within 3 s
    if _seen_at > 0 and _dir_ms < 0 and String(_eye.director._cur.get("key", "")).begins_with("lord_"):
        _dir_ms = Time.get_ticks_msec() - _seen_ms
        _check(_dir_ms <= 3000, "director cut to the lord %d ms after it rose" % _dir_ms)
    if _seen_at > 0 and _f - _seen_at == 150:
        var l: Monster = _d.lord_fighting()
        # S89: no floating card while the lord fights; its name and hp live on the lord itself (S88)
        _check(get_nodes_in_group("hud_boss").is_empty() and root.find_children("BossCard", "", true, false).is_empty(), "S89: no floating boss card while the lord fights")
        var tg: Label3D = l.get_node_or_null("name_tag") as Label3D if l else null
        _check(tg != null and tg.text == String(l.def.get("name", "")), "lord's own name plate reads '%s'" % (tg.text if tg else "-"))
        var best: Dictionary = _eye.director._best()
        _check(String(best.get("key", "")).begins_with("lord_") and float(best.get("pri", 0.0)) >= 100.0, "director best %s pri %s" % [best.get("key", ""), best.get("pri", 0)])
    if _seen_at > 0 and (_f - _seen_at) in [152, 300]:
        root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "/fight_%d.png" % _shots))
        _shots += 1
    if _seen_at > 0 and _f - _seen_at == 320:
        var l: Monster = _d.dun.lord
        if l and is_instance_valid(l):
            l.state = Monster.S.DEAD
        _check(get_nodes_in_group("hud_boss").is_empty(), "S89: still no floating boss card once the lord is down")
    if (_seen_at > 0 and _f - _seen_at > 330) or _f > 6000:
        if _seen_at < 0:
            _fails.append("the lord never fought")
        if _dir_ms < 0:
            _fails.append("the director never cut to the lord")
        print("BOSS_TEST %d checks, %d failed" % [_checks, _fails.size()])
        print("BOSS_TEST %s" % ("OK" if _fails.is_empty() else "FAIL " + str(_fails)))
        return true
    return false

func _find_id(l: Monster) -> String:
    for k in Bestiary.BOSS_DEFS:
        if String(Bestiary.BOSS_DEFS[k]["title"]) == String(l.def.get("name", "")):
            return k
    return ""
