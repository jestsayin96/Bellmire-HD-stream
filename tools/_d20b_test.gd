extends SceneTree
## D20b: CROWD REACTIONS probe. Boots the town, lets it settle, then:
##   1) forces a raid -> the eligible townsfolk flee indoors, so the STREETS
##      CLEAR (street-civilian count falls well below the baseline; Townsfolk.fled>0)
##   2) clears the raiders -> folk come back out over time (info, not gated)
##   3) forces a festival -> idle folk GATHER near the square (near-square count
##      climbs above baseline; Townsfolk.gathered>0)
## PASS = streets cleared on the raid + a crowd gathered at the festival.
var _t: Node3D
var _f := 0
var base_street := 0        # eligible civilians out on the street, pre-raid (max)
var raid_street := 99999    # min eligible civilians out during the raid window
var base_square := 0        # eligible civilians near the square, pre-festival (max)
var fest_square := 0        # max eligible civilians near the square during festival
var pre_fest_square := 0    # square count just before the festival is forced
var post_raid_out := 0      # eligible civilians back out after the all-clear (max)
var phase := "warm"
var _raid_at := 0
var _clear_at := 0
var _fest_at := 0

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _elig(v) -> bool:
    return is_instance_valid(v) and v is Townsfolk and v.rank < 0 and not v.stay \
        and v.leader == null and v.cart == null \
        and v.role != "guard" and v.role != "chief" and v.role != "bandit" \
        and String(v.gear_role) != "lookout"

func _street_count() -> int:
    var n := 0
    for v in _t.get("people"):
        if _elig(v) and v.visible and not v.inside:
            n += 1
    return n

func _square_count() -> int:
    var mk = _t.get("_market_pos")
    if not (mk is Vector3) or mk == Vector3.ZERO:
        return 0
    var c: Vector3 = mk
    var n := 0
    for v in _t.get("people"):
        if _elig(v) and v.visible and not v.inside:
            var p: Vector3 = v.global_position
            if Vector2(p.x - c.x, p.z - c.z).length() < 14.0:
                n += 1
    return n

func _process(_d: float) -> bool:
    _f += 1
    # --- warm-up: let people spawn, nav bake, folk start walking (~6 s)
    if _f < 360:
        if _f % 30 == 0:
            base_street = max(base_street, _street_count())
            base_square = max(base_square, _square_count())
        return false
    # --- phase 1: force the raid
    if phase == "warm":
        var rd = _t.get("raids")
        if rd == null:
            print("D20B_TEST FAIL (no raids node)")
            return true
        rd.force_level = 5
        rd.call("raid", "west")
        _raid_at = _f
        phase = "raid"
        print("RAID forced raiders=", (rd.get("raiders") as Array).size(), " base_street=", base_street, " base_square=", base_square)
        return false
    if phase == "raid":
        # give them ~8 s to run for cover
        if _f % 15 == 0 and _f - _raid_at > 120:
            raid_street = min(raid_street, _street_count())
        if _f - _raid_at >= 1500:
            # clear the raiders -> the attack is driven off
            var rd = _t.get("raids")
            for r in (rd.get("raiders") as Array).duplicate():
                rd.call("_raider_falls", r, "test")
            _clear_at = _f
            phase = "cooldown"
            print("RAID cleared  raid_street(min)=", raid_street, " Townsfolk.fled=", Townsfolk.fled)
        return false
    if phase == "cooldown":
        if _f % 30 == 0:
            post_raid_out = max(post_raid_out, _street_count())
        if _f - _clear_at >= 600:
            # force a festival
            pre_fest_square = _square_count()
            _t.set("festival", true)
            _t.set("festival_at", _t.get("_market_pos"))
            _t.set("_fest_left", 300.0)
            _fest_at = _f
            phase = "festival"
            var eco = _t.get("economy")
            print("FESTIVAL forced  post_raid_out(max)=", post_raid_out,
                  " pre_fest_square=", pre_fest_square, " hour=%.1f" % (eco.hour() if eco else -1.0))
        return false
    if phase == "festival":
        if _f % 15 == 0 and _f - _fest_at > 120:
            fest_square = max(fest_square, _square_count())
        if _f - _fest_at >= 1500:
            phase = "done"
        return false
    # --- verdict
    var streets_cleared: bool = raid_street <= max(1, int(base_street * 0.5)) and Townsfolk.fled > 0
    var crowd_gathered: bool = Townsfolk.gathered > 0 and fest_square >= 10 and fest_square >= pre_fest_square + 4
    print("D20B base_street=", base_street, " raid_street_min=", raid_street,
          "  base_square=", base_square, " pre_fest_square=", pre_fest_square, " fest_square_max=", fest_square,
          "  fled=", Townsfolk.fled, " gathered=", Townsfolk.gathered,
          " post_raid_out=", post_raid_out, " fests=", _t.get("fests"))
    var miss: Array = []
    if not streets_cleared:
        miss.append("streets_cleared")
    if not crowd_gathered:
        miss.append("crowd_gathered")
    print("D20B_TEST %s missing=%s" % ["PASS" if miss.is_empty() else "FAIL", str(miss)])
    return true
