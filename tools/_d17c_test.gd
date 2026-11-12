extends SceneTree
## D17c: the STATE COVERAGE probe. The town for 110 s at --fixed-fps 60 (a
## whole 90 s day from dawn, the evening included, then a level-5 raid at 75 s);
## every 0.5 s every body's clip is sampled and sorted into what it shows:
## the trades at work (smith, farmer/woodcutter/miner/miller, the stalls and
## shops, the anglers), sitting, a mug/bite at the tavern, haggling, the raid
## (swing, cast, hurt/parry, fall) and the beasts (walk, idle, graze, flee).
## PASS = every state seen, and no visible body without a clip (the D17a gate).
## `-- --old` = before (no outdoor work, no seats, no grazing/flight, D17c's
## raid reactions still in - they are not switchable).
var _t: Node3D
var _f := 0
var SECS := 130
var _n := {}
var _samples := 0
var _empty := 0
var _old := false
var _min_ra := INF

func _initialize() -> void:
    _old = OS.get_cmdline_user_args().has("--old")
    if _old:
        Townsfolk.job_out = 0.0
        Townsfolk.sit_ok = false
        Animal.graze_on = false
        Animal.flee_on = false
        print("D17C OLD (before)")
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _c(k: String) -> void:
    _n[k] = int(_n.get(k, 0)) + 1

const JOB_SMITH := ["smith", "blacksmith", "armorer"]
const JOB_LAND := ["farmer", "lumberjack", "miner", "miller"]
const JOB_SHOP := ["merchant", "trader", "store", "tavern", "innkeeper", "apothecary", "baker"]

func _sample() -> void:
    for v in _t.get("people"):
        if not is_instance_valid(v) or not v.visible or v.inside or v._anim == null:
            continue
        var ca := String(v._anim.current_animation)
        _samples += 1
        if ca == "":
            _empty += 1
        var r := String(v.role)
        var jl: Array = Townsfolk.JOB_ANIMS.get(r, [])
        var in_job: bool = ca in jl and not Rig.loops(ca)
        if in_job and r in JOB_SMITH:
            _c("job_smith")
        elif in_job and r in JOB_LAND:
            _c("job_land")
            if v._at_job:
                _c("job_land_outdoors")
        elif in_job and r in JOB_SHOP:
            _c("job_shop")
        elif r == "fisher" and ca in ["Interact", "Cheer"]:
            _c("job_angler")
        if ca.begins_with("Sit_"):
            _c("sit")
        if ca.begins_with("Spellcast"):
            _c("cast")
    # raid bodies (fighters are in people; bandits are not)
    var rd = _t.get("raids")
    var bodies: Array = []
    for p in _t.get("people"):
        if is_instance_valid(p):
            bodies.append(p)
    if rd:
        for r in rd.raiders:
            var n = r.get("node")
            if n is Townsfolk and is_instance_valid(n):
                bodies.append(n)
    for c in _t.get_children():
        if c is Townsfolk and is_instance_valid(c) and String(c.role) == "bandit":
            bodies.append(c)
    for b in bodies:
        var ap: AnimationPlayer = b._anim
        if ap == null or not b.visible:
            continue
        var ca := String(ap.current_animation)
        var fighter: bool = rd != null and (rd._fighters.has(b) or String(b.role) == "bandit")
        if fighter and (ca.begins_with("1H_Melee") or ca.begins_with("2H_Melee") or ca.begins_with("Dualwield")):
            _c("attack")
        elif ca.begins_with("Hit_") or ca.begins_with("Block"):
            _c("hurt")
        elif ca.begins_with("Death_"):
            _c("death")
    if rd:
        for r in rd.raiders:
            var n = r.get("node")
            if n != null and is_instance_valid(n):
                for a2 in _t.get("animals"):
                    if is_instance_valid(a2):
                        var dd: float = Vector2((n as Node3D).global_position.x - a2.global_position.x, (n as Node3D).global_position.z - a2.global_position.z).length()
                        _min_ra = minf(_min_ra, dd)
    for a in _t.get("animals"):
        if not is_instance_valid(a) or not a.visible:
            continue
        if a.fleeing():
            _c("beast_flee")
        elif a.grazing():
            _c("beast_graze")
        elif a._moving:
            _c("beast_walk")
        else:
            _c("beast_idle")

func _process(_d: float) -> bool:
    _f += 1
    if _f == 75 * 60:
        var rd = _t.get("raids")
        if rd:
            rd.force_level = 5
            rd.call("raid", "west")
            print("RAID started")
    if _f == 80 * 60:
        # a raider strays out among the beasts (the raids come in by the west
        # road or the scar, 50+ m from any pen - this puts one in a field to
        # see the beasts bolt): the nearest pen beast gets a bandit 6 m off
        var rd = _t.get("raids")
        var tgt = null
        for a in _t.get("animals"):
            if is_instance_valid(a) and a._graze != null:
                tgt = a
                break
        if rd and tgt:
            for r in rd.raiders:
                var n = r.get("node")
                if n != null and is_instance_valid(n):
                    var q: Vector3 = tgt.global_position + Vector3(6, 0, 0)
                    q.y = float(_t.call("height_at", q.x, q.z))
                    (n as Node3D).global_position = q
                    print("STRAY raider put 6 m from a ", tgt.kind)
                    break
    if _f > 120 and _f % 30 == 0:
        _sample()
    if _f % 1200 == 0:
        var eco = _t.get("economy")
        print("T=", _f / 60, "s hour=%.1f " % (eco.hour() if eco else -1.0), _n)
    if _f >= SECS * 60:
        var acts: Dictionary = Townsfolk.acts
        var rd = _t.get("raids")
        print("ACTS ", acts, " swings=", rd.swings if rd else {}, " reels=", rd.reels if rd else 0, " parries=", rd.parries if rd else 0, " flees=", Animal.flees)
        var need := ["job_smith", "job_land", "job_shop", "job_angler", "sit", "attack", "cast", "hurt", "death",
                     "beast_walk", "beast_idle", "beast_graze", "beast_flee"]
        var miss: Array = []
        for k in need:
            if int(_n.get(k, 0)) == 0:
                miss.append(k)
        if int(acts.get("eat", 0)) == 0:
            miss.append("eat")
        print("closest raider-beast m=", _min_ra)
        print("SAMPLES ", _samples, " empty_visible=", _empty)
        for k in need:
            print("  %-18s %d" % [k, int(_n.get(k, 0))])
        print("  %-18s %d" % ["job_land_outdoors", int(_n.get("job_land_outdoors", 0))])
        print("  %-18s %d" % ["eat (acts)", int(acts.get("eat", 0))])
        print("  %-18s %d" % ["haggle (acts)", int(acts.get("haggle", 0))])
        var ok := miss.is_empty() and _empty == 0
        print("D17C_TEST %s missing=%s empty_visible=%d" % ["PASS" if ok else "FAIL", str(miss), _empty])
        return true
    return false
