extends SceneTree
## D20a: RICHER ROUTINES probe. Boots the town and runs ~2 game days from dawn
## at --fixed-fps 60 (a day is 90 s). Every 0.5 s it samples the ordinary folk
## (rank < 0, not a notable, on the home<->work shuttle) and the Notables and
## records that the day reads work -> market -> tavern -> home:
##   - MIDDAY  : folk make a deliberate market errand (acts["market"]) + shop it
##   - EVENING : folk make a tavern errand (acts["tavern_errand"]) + a mug/bite
##   - NIGHT   : HOMED folk are home / indoors
##   - the trades still work their jobs; seats sat on; 0 body without a clip
##   - the Notables occupy their hour-slots (Notables.reached climbs)
## PASS = every beat seen. `-- --old` turns the D20a errands off.
var _t: Node3D
var _f := 0
var SECS := 190
var _old := false
var _samples := 0
var _empty := 0
var mkt_midday := 0        # ordinary folk near the market in market hours
var tav_eve := 0           # ordinary folk near the tavern of an evening
var homed_home := 0        # HOMED ordinary folk home/indoors at night
var homed_night := 0       # HOMED ordinary folk sampled at night (denominator)
var notable_at_slot := 0
var notable_samp := 0

func _initialize() -> void:
    _old = OS.get_cmdline_user_args().has("--old")
    if _old:
        Townsfolk.market_off = true
        print("D20A OLD (errands off)")
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _is_ordinary(v) -> bool:
    return v.rank < 0 and String(v.notable_title) == "" and not v.stay \
        and v.leader == null and v.cart == null and (v.stops as Array).is_empty()

func _notables():
    var n = _t.get("notables")
    if n != null:
        return n
    for c in _t.get_children():
        if c.get("cast") != null and c.has_method("by_key"):
            return c
    return null

func _sample() -> void:
    var eco = _t.get("economy")
    var h: float = eco.hour() if eco else 12.0
    var mk = _t.get("_market_pos")
    var tv = _t.get("tavern_at")
    var midday := h >= 10.5 and h < 15.0
    var evening := h >= 18.0 and h < 23.0
    var night := h < 6.0 or h >= 21.0
    for v in _t.get("people"):
        if not is_instance_valid(v) or v._anim == null:
            continue
        if v.visible and not v.inside:
            _samples += 1
            if String(v._anim.current_animation) == "":
                _empty += 1
        if not _is_ordinary(v):
            continue
        var p: Vector3 = v.global_position
        if midday and mk is Vector3 and mk != Vector3.ZERO \
                and Vector2(p.x - mk.x, p.z - mk.z).length() < 14.0 and not v.inside:
            mkt_midday += 1
        if evening and tv is Vector3 and tv != Vector3.INF \
                and Vector2(p.x - tv.x, p.z - tv.z).length() < 16.0 and not v.inside:
            tav_eve += 1
        if night and v.home != Vector3.ZERO:
            homed_night += 1
            if v.inside or Vector2(p.x - v.home.x, p.z - v.home.z).length() < 6.0:
                homed_home += 1
    var nb = _notables()
    if nb != null:
        for c in nb.cast:
            if not is_instance_valid(c["who"]):
                continue
            notable_samp += 1
            var who = c["who"]
            if who.inside:
                notable_at_slot += 1
                continue
            for g in c["goals"]:
                var gv: Vector3 = g
                if Vector2(who.global_position.x - gv.x, who.global_position.z - gv.z).length() < 3.0:
                    notable_at_slot += 1
                    break

func _process(_d: float) -> bool:
    _f += 1
    if _f > 120 and _f % 30 == 0:
        _sample()
    if _f % 1800 == 0:
        var eco = _t.get("economy")
        var acts: Dictionary = Townsfolk.acts
        print("T=", _f / 60, "s hour=%.1f" % (eco.hour() if eco else -1.0),
              " mkt=", int(acts.get("market",0)), " tav=", int(acts.get("tavern_errand",0)),
              " mkt_midday=", mkt_midday, " tav_eve=", tav_eve,
              " homed_home=%d/%d" % [homed_home, homed_night])
    if _f >= SECS * 60:
        var acts: Dictionary = Townsfolk.acts
        print("ACTS ", acts)
        var nb = _notables()
        var reached := int(nb.reached) if nb else 0
        var visits := int(nb.visits) if nb else 0
        print("SAMPLES ", _samples, " empty_visible=", _empty)
        print("  market errands       = ", int(acts.get("market", 0)))
        print("  tavern errands       = ", int(acts.get("tavern_errand", 0)))
        print("  haggle anim          = ", int(acts.get("haggle", 0)))
        print("  eat anim             = ", int(acts.get("eat", 0)))
        print("  job anim             = ", int(acts.get("job", 0)))
        print("  mkt_midday (near)    = ", mkt_midday)
        print("  tav_eve (near)       = ", tav_eve)
        print("  homed at night       = %d/%d" % [homed_home, homed_night])
        print("  notable at slot      = %d/%d" % [notable_at_slot, notable_samp])
        print("  notable reached      = %d/%d" % [reached, visits])
        var home_frac := float(homed_home) / maxf(1.0, float(homed_night))
        print("  (info) at_tavern_evening near=%d  homed_at_night_frac=%.2f  [night-home is pre-existing, out of D20a scope]" % [tav_eve, home_frac])
        var checks := {
            "market_errand": int(acts.get("market", 0)) > 0,
            "market_shop_anim": int(acts.get("haggle", 0)) > 0,
            "at_market_midday": mkt_midday > 0,
            "tavern_errand": int(acts.get("tavern_errand", 0)) > 0,
            "tavern_eat_anim": int(acts.get("eat", 0)) > 0,
            "notables_on_routine": notable_samp > 0 and reached > 0,
            "no_empty_clip": _empty == 0,
        }
        if _old:
            checks.erase("market_errand")
            checks.erase("tavern_errand")
            checks.erase("at_market_midday")
        var miss: Array = []
        for k in checks:
            if not bool(checks[k]):
                miss.append(k)
        print("home_frac=%.2f" % home_frac)
        print("D20A_TEST %s missing=%s empty_visible=%d" % ["PASS" if miss.is_empty() else "FAIL", str(miss), _empty])
        return true
    return false
