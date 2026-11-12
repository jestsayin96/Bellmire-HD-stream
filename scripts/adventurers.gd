extends Node
class_name Adventurers
## The town's own adventurers - ported from the old town._make_adventurer /
## _apply_hero / _send_party / _kit_up / _check_pending and the adventurer
## branches of _settlers and _chief_spends. They are Roster heroes like any
## viewer's (same classes, same rules) on the town's own roll (npcs), live at
## the tavern, and go down the scar through the same Delve.
##  - founding: a band of eight, one guaranteed sage;
##  - every 20-36 s the idle ones (over 55% hp) muster, up to PARTY_MAX 10, at
##    most DUNGEON_MAX 100 underground; each kits up from their OWN purse
##    (armour/weapon alternately, up to 4 buys), oil to three (two issued by the
##    guild to anyone who cannot pay), rank stores on top, a potion with spare
##    change; the party draws half a set of gear each from the town rack (+2);
##  - they gather at the mouth (11 m); after 45 s they go with whoever is there
##    if at least three; a party under two is stood down;
##  - settlers: with renown >= 3 and fewer than six, 55% of the time a new
##    adventurer arrives at the tavern instead of a tradesman (renown -1);
##  - the chief posts a bounty (240 g) when fewer than three remain, hiring a
##    sage if the band has no healer.

const PARTY_MAX := 10
const DUNGEON_MAX := 100
const GATHER := 11.0
const PATIENCE := 45.0
var town: Node3D
var npcs: Roster
var bodies := {}                 # uid -> HeroBody
var _n := 0
var _party_t := 7.0
var _pending: Array = []         # {uids, t}
var _delving := {}               # uid -> true while underground
var _lanes := 0

func setup(t: Node3D) -> void:
    town = t
    npcs = Roster.new()
    add_child(npcs)
    if npcs.has_signal("announced"):
        npcs.announced.connect(func(l: String, _c: Color) -> void: _say(l))

func _say(line: String) -> void:
    (town.get("feed") as Array).append(line)

func _tavern() -> Vector3:
    var fr: Array = (town.get("_shop_frame") as Dictionary).get("tavern", [])
    if fr.is_empty():
        return town.get("_market_pos")
    return fr[0]

func found() -> void:
    make("sage")
    for i in range(7):
        make()

## a new adventurer at the tavern (or walking in from the west gate)
func make(cls := "", from_gate := false) -> HeroBody:
    _n += 1
    var id := "npc:%d" % _n
    var nm: String = town.call("npc_name")
    var h := npcs.fresh(id, nm, cls)
    h["name"] = nm
    var b := HeroBody.new()
    b.npc = true
    b.setup(npcs, id)
    b.role = "adventurer"
    b.town = town
    var tav := _tavern()
    # D16c: never a spot inside the tavern yard's tables and stools
    b.home = town.call("keep_walkable", tav + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3)))
    b.work = town.call("keep_walkable", tav + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4)))
    var at := b.work
    if from_gate:
        var gw: Vector3 = town.call("_gate", -1.0)
        at = gw + Vector3(gw.x, 0, gw.z).normalized() * 30.0
    at.y = float(town.call("height_at", at.x, at.z))
    b.position = at
    town.add_child(b)
    (town.get("people") as Array).append(b)
    bodies[id] = b
    if from_gate:
        b._route = town.call("route", at, b.work)
    return b

func count() -> int:
    var n := 0
    for id in bodies:
        if is_instance_valid(bodies[id]) and npcs.is_alive(String(id)):
            n += 1
    return n

func has_healer() -> bool:
    for id in bodies:
        var h := npcs.get_hero(String(id))
        if not h.is_empty() and npcs.is_alive(String(id)) and String(h["class"]) in ["sage", "cleric"]:
            return true
    return false

func _idle() -> Array:
    var out: Array = []
    var busy := {}
    for s in _pending:
        for u in s["uids"]:
            busy[u] = true
    for id in bodies:
        var b = bodies[id]
        if not is_instance_valid(b) or not npcs.is_alive(String(id)) or busy.has(id) or _delving.has(id):
            continue
        out.append(String(id))
    return out

func _process(delta: float) -> void:
    if town == null:
        return
    _party_t -= delta
    if _party_t <= 0.0:
        _party_t = randf_range(20.0, 36.0)
        _send_party()
    _check_pending(delta)

func _send_party() -> void:
    var pool := _idle()
    if pool.size() < 1:
        return
    var party: Array = pool.slice(0, PARTY_MAX)
    if _delving.size() + party.size() > DUNGEON_MAX:
        return
    var sc: Dictionary = town.get("_scar_info")
    if not sc.has("mouth"):
        return
    var mouth: Vector3 = sc["mouth"]
    var fw: Vector3 = sc["fwd"]
    var who: Array = []
    for i in party.size():
        var uid: String = party[i]
        _kit_up(uid)
        var b: HeroBody = bodies[uid]
        var side := Vector3(-fw.z, 0, fw.x) * (float(i % 4) - 1.5) * 1.6
        b.go(mouth + fw * (6.0 + float(i / 4) * 2.0) + side, "delve")
        who.append(b.person_name)
    _say("%s set out for the dungeon." % ", ".join(who))
    var eco: Economy = town.get("economy")
    var kit := 0.0
    if eco.take("gear", float(party.size()) * 0.5):
        kit = 2.0
        town.call("_stock_piles")
    else:
        eco.want("gear", float(party.size()) * 0.5)
    _pending.append({"uids": party, "t": 0.0, "kit": kit})

## old _kit_up: their own purse first, oil before potions, the guild dole
func _kit_up(uid: String) -> void:
    var h := npcs.get_hero(uid)
    if h.is_empty():
        return
    for _i in range(4):
        var w0 := int(h.get("weapon", 0))
        var a0 := int(h.get("armour", 0))
        var msg: String = npcs.buy_armour(uid) if a0 <= w0 else npcs.buy_weapon(uid)
        if int(h.get("weapon", 0)) == w0 and int(h.get("armour", 0)) == a0:
            break
        _say(msg)
    var want_oil := 3 - int(h.get("oil", 0))
    if want_oil > 0 and int(h.get("gold", 0)) >= Roster.OIL_COST * want_oil:
        npcs.buy_oil(uid, want_oil)
    elif want_oil > 0 and int(h.get("gold", 0)) >= Roster.OIL_COST:
        npcs.buy_oil(uid, 1)
    if int(h.get("oil", 0)) < 2:
        h["oil"] = 2
    var stores := int(npcs.rank_row(h).get("stores", 0))
    if stores > 0:
        h["oil"] = int(h.get("oil", 0)) + stores
        if stores >= 2:
            _say("%s draws %d flasks from the guild stores." % [h.get("name", uid), stores])
    if int(h.get("potions", 0)) < 2 and int(h.get("gold", 0)) > 80:
        npcs.buy_potion(uid, 1)
    if bodies.has(uid) and is_instance_valid(bodies[uid]):
        (bodies[uid] as HeroBody).refresh()

func _check_pending(dt: float) -> void:
    var sc: Dictionary = town.get("_scar_info")
    var mouth: Vector3 = sc.get("mouth", Vector3.ZERO)
    for slot in _pending.duplicate():
        var party: Array = []
        for u in slot["uids"]:
            if bodies.has(u) and is_instance_valid(bodies[u]) and npcs.is_alive(String(u)):
                party.append(u)
        slot["uids"] = party
        if party.size() < 2:
            for u in party:
                _release(String(u))
            _pending.erase(slot)
            continue
        var here: Array = []
        var fw: Vector3 = sc.get("fwd", Vector3(0, 0, 1))
        for i in party.size():
            var u = party[i]
            var b: HeroBody = bodies[u]
            var p: Vector3 = b.global_position
            if Vector2(p.x - mouth.x, p.z - mouth.z).length() <= GATHER:
                here.append(u)
            elif b._route.is_empty() and not b.stay:
                # stopped short (something else gave them a trip): send them on again
                var side := Vector3(-fw.z, 0, fw.x) * (float(i % 4) - 1.5) * 1.6
                b.go(mouth + fw * (6.0 + float(i / 4) * 2.0) + side, "delve")
        # The old 45 s patience was measured from the muster in a town where the
        # tavern was a short walk from the mine. Bellmire HD's tavern is ~300 m
        # from the scar, so the wait is counted from the first arrival at the door.
        if not here.is_empty():
            slot["t"] = float(slot["t"]) + dt
        slot["walk"] = float(slot.get("walk", 0.0)) + dt
        var go := here.size() == party.size()
        if not go and float(slot["t"]) >= PATIENCE:
            if here.size() >= 3:
                go = true
                for u in party:
                    if not here.has(u):
                        _release(String(u))
                party = here
            else:
                # "If only two ever turn up, they wait for the next muster."
                for u in party:
                    _release(String(u))
                _pending.erase(slot)
                continue
        elif not go and float(slot["walk"]) > 240.0:
            # nobody reached the door in four minutes: stand the muster down
            var ds := []
            for u in party:
                var p: Vector3 = (bodies[u] as Node3D).global_position
                ds.append(int(Vector2(p.x - mouth.x, p.z - mouth.z).length()))
            print("MUSTER timed out: dists=", ds, " vis=", (bodies[party[0]] as Node3D).visible, " stay=", (bodies[party[0]] as HeroBody).stay, " route=", (bodies[party[0]] as HeroBody)._route.size(), " inside=", (bodies[party[0]] as HeroBody).inside)
            for u in party:
                _release(String(u))
            _pending.erase(slot)
            continue
        if go:
            _pending.erase(slot)
            _delve(party, float(slot.get("kit", 0.0)))

func _release(uid: String) -> void:
    if bodies.has(uid) and is_instance_valid(bodies[uid]):
        var b: HeroBody = bodies[uid]
        b.stay = false
        b.errand = ""
        b._route = town.call("route", b.global_position, b.work)

func _delve(party: Array, kit: float) -> void:
    var d := Delve.new()
    d.town = town
    d.roster = npcs
    d.npc_party = true
    _lanes += 1
    d.lane = _lanes
    d.kit_bonus = kit
    town.add_child(d)
    for u in party:
        _delving[u] = true
        (bodies[u] as Node3D).visible = false
    d.start(party.duplicate())
    d.ended.connect(func(survivors: Array) -> void:
        var sc: Dictionary = town.get("_scar_info")
        var mo: Vector3 = sc.get("mouth", Vector3.ZERO)
        var fw: Vector3 = sc.get("fwd", Vector3(0, 0, 1))
        for u in party:
            _delving.erase(u)
            var b: HeroBody = bodies.get(u)
            if b == null or not is_instance_valid(b):
                continue
            if survivors.has(u):
                var k := survivors.find(u)
                var p := mo + fw * (2.5 + float(k / 2) * 1.6) + Vector3(-fw.z, 0, fw.x) * (float(k % 2) - 0.5) * 1.6
                p.y = float(town.call("height_at", p.x, p.z))
                b.global_position = p
                b.visible = true
                b.refresh()
                _release(String(u))
            else:
                (town.get("people") as Array).erase(b)
                bodies.erase(u)
                b.queue_free()
        d.queue_free())
