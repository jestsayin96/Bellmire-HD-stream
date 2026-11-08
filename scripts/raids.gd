extends Node
class_name Raids
## PERILS - ported from the old town._raid / _peril_pass / _combat_pass /
## _wreck_a_building / _rebuild_pass and villager.gd's FIGHT state. The
## read-only original is the rulebook:
##  - no raids until Bellmire is a market town (RAIDS_FROM_LEVEL 3) - "a hamlet
##    has nothing to defend itself with and nothing to lose";
##  - every 110-190 s; 62% boil out of the scar (skeleton warriors, rogues and
##    minions), otherwise bandits ride in on the west road; n = min(8,
##    2 + 0..2 + day/3 + renown/12); raiders hp 30, atk 5.5, speed 4;
##  - guards (hp 64, atk 11), the chief (hp 40, atk 6) and heroes fight; a
##    defender takes the nearest raider within 70 m, a raider the nearest
##    defender within 26 m, else it makes for the middle of town; anyone who
##    cannot fight runs 16 m away from a raider within 13 m;
##  - d20 + to-hit vs AC: a 1 always misses, a 20 lands double; swing 1.1 s,
##    reach 2.2 m, chase at 1.15x speed;
##  - while raiders are inside the walls a building is wrecked every 7-13 s
##    ("A building is burning!"); townsfolk raise the first ruin again every
##    22 s for 12 wood + 8 stone;
##  - "The attack is driven off. The gates hold." when the last one falls.

const RAIDS_FROM_LEVEL := 3
const SKELETONS := ["warrior", "cutpurse", "minion"]
var town: Node3D
var economy: Economy
var raids := 0
var _raid_t := randf_range(110.0, 190.0)
var _breach := 0.0
var _rebuild_t := 22.0
var _live := false
var raiders: Array = []          # {node, hp, max, atk, ac, to_hit, speed, name, target, swing, kind}
var _fighters := {}              # defender node -> {hp, max, atk, ac, to_hit, speed, target, swing, post, yaw, stay}
var ruins: Array = []            # {node, pos, debris}
var _slow := 0.0
var force_level := -1            # test hook

func _level() -> int:
    return force_level if force_level > 0 else economy.town_level

func _say(line: String) -> void:
    (town.get("feed") as Array).append(line)
    print("FEED ", line)

## ------------------------------------------------------------------ raid
func raid(source := "") -> void:
    if _level() < RAIDS_FROM_LEVEL:
        return
    raids += 1
    var from_dungeon := randf() < 0.62 if source == "" else source == "scar"
    var day := economy.day
    var n: int = min(8, 2 + randi() % 3 + int(day / 3) + int(economy.renown / 12))
    var spawn: Vector3
    var sc: Dictionary = town.get("_scar_info")
    if from_dungeon and sc.has("mouth"):
        spawn = sc["mouth"] + (sc["fwd"] as Vector3) * 6.0
    else:
        from_dungeon = false
        var gw: Vector3 = town.call("_gate", -1.0)
        spawn = gw + Vector3(gw.x, 0, gw.z).normalized() * 40.0
    for i in range(n):
        var at := spawn + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
        at.y = float(town.call("height_at", at.x, at.z))
        var node: Node3D
        var nm := "Raider"
        if from_dungeon:
            var m := Monster.new()
            m.def = Bestiary.make(SKELETONS[randi() % SKELETONS.size()])
            m.state = Monster.S.IDLE
            m.ground_fn = Callable(town, "height_at")
            m.max_hp = 30.0
            m.hp = 30.0
            node = m
            nm = String(m.def.get("name", "raider"))
        else:
            var b := Townsfolk.new()
            b.role = "bandit"
            b.model = "Rogue_Hooded.glb"
            b.tint = Color(0.45, 0.36, 0.40)
            b.person_name = "Bandit"
            b.town = town
            b.stay = true
            node = b
            nm = "a bandit"
        node.position = at
        town.add_child(node)
        raiders.append({"node": node, "hp": 30.0, "max": 30.0, "atk": 5.5, "ac": 10, "to_hit": 2,
                        "speed": 4.0, "name": nm, "target": null, "swing": randf() * 1.1,
                        "kind": "monster" if from_dungeon else "bandit"})
    if from_dungeon:
        _say("%d creatures boil out of the dungeon!" % n)
    else:
        _say("%d bandits are riding on the west road!" % n)

## ------------------------------------------------------------- defenders
func _defenders() -> Array:
    var out: Array = []
    for p in town.get("people"):
        if not is_instance_valid(p) or not (p as Node3D).visible:
            continue
        var is_hero: bool = p is HeroBody
        var role := String((p as Townsfolk).role)
        if not is_hero and role != "guard" and role != "chief":
            continue
        if String((p as Townsfolk).gear_role) == "lookout":
            continue          # the tower lookouts keep their towers
        if not _fighters.has(p):
            var st := {"target": null, "swing": 0.0, "post": (p as Node3D).global_position,
                       "yaw": (p as Node3D).rotation.y, "stay": (p as Townsfolk).stay}
            if is_hero:
                var r: Roster = (p as HeroBody).roster      # viewers' roll or the town's own
                var h: Dictionary = r.get_hero((p as HeroBody).user_id)
                st.merge({"hp": r.max_hp(h), "max": r.max_hp(h), "atk": r.attack(h), "ac": r.armour_class(h),
                          "to_hit": r.attack_bonus(h), "speed": r.speed(h)})
            elif role == "guard":
                st.merge({"hp": 64.0, "max": 64.0, "atk": 11.0, "ac": 10, "to_hit": 2, "speed": 4.4})
            else:
                st.merge({"hp": 40.0, "max": 40.0, "atk": 6.0, "ac": 10, "to_hit": 2, "speed": 3.4})
            _fighters[p] = st
        out.append(p)
    return out

func _d20() -> int:
    return randi() % 20 + 1

## one swing, by the sheet
func _strike(atk: float, to_hit: int, ac: int) -> float:
    var d := _d20()
    if d == 1:
        return 0.0
    if d == 20:
        return atk * 2.0
    return 0.0 if d + to_hit < ac else atk

func _flat(a: Vector3, b: Vector3) -> float:
    return Vector2(a.x - b.x, a.z - b.z).length()

func _step(n: Node3D, to: Vector3, spd: float, delta: float) -> void:
    var d := Vector3(to.x - n.global_position.x, 0, to.z - n.global_position.z)
    if d.length() < 0.05:
        return
    var p := n.global_position + d.normalized() * minf(spd * delta, d.length())
    p.y = float(town.call("height_at", p.x, p.z))
    n.global_position = p
    n.rotation.y = atan2(d.x, d.z)

func _anim(n: Node3D, key: String) -> void:
    if n is Monster:
        (n as Monster)._play({"walk": "walk", "run": "walk", "attack": "attack", "idle": "idle", "die": "die"}[key])
    elif n is Townsfolk:
        var ap: AnimationPlayer = (n as Townsfolk)._anim
        Rig.play(ap, {"walk": "Walking_A", "run": "Running_A", "attack": "1H_Melee_Attack_Chop", "idle": "Idle", "die": "Death_A"}[key])

## ---------------------------------------------------------------- tick
func _process(delta: float) -> void:
    if town == null or economy == null:
        return
    _raid_t -= delta
    if _raid_t <= 0.0:
        _raid_t = randf_range(110.0, 190.0)
        raid()
    _rebuild_t -= delta
    if _rebuild_t <= 0.0:
        _rebuild_t = 22.0
        _rebuild_pass()
    _tick_ruin_fires(delta)
    if raiders.is_empty():
        if _live:
            _live = false
            _breach = 0.0
            _say("The attack is driven off. The gates hold.")
        _stand_down(delta)
        return
    _live = true
    var defs := _defenders()
    var centre: Vector3 = town.get("_market_pos")
    # breach: raiders inside the walls wreck the town
    var inside := 0
    for r in raiders:
        if _inside_walls((r["node"] as Node3D).global_position):
            inside += 1
    if inside > 0:
        _breach -= delta
        if _breach <= 0.0:
            _breach = randf_range(7.0, 13.0)
            _wreck_a_building()
    # targeting (the old _combat_pass, twice a second)
    _slow -= delta
    if _slow <= 0.0:
        _slow = 0.5
        _targets(defs)
        _flee()
    # health bars on everyone in the fight
    for rr in raiders:
        var rn: Node3D = rr["node"]
        HealthBar3D.on(rn, (rn as Monster)._height() + 0.25 if rn is Monster else 2.05, true).set_hp(float(rr["hp"]), float(rr["max"]), rr["target"] != null)
    for dd in defs:
        var st0: Dictionary = _fighters[dd]
        HealthBar3D.on(dd, 2.05, false).set_hp(float(st0["hp"]), float(st0["max"]), st0["target"] != null)
    # defenders
    for d in defs:
        var st: Dictionary = _fighters[d]
        var tg = st["target"]
        if tg == null or not raiders.has(tg):
            st["target"] = null
            continue
        (d as Townsfolk).stay = true
        _engage(d, st, tg, delta, true)
    # raiders
    for r in raiders.duplicate():
        var n: Node3D = r["node"]
        var tg = r["target"]
        if tg != null and (not is_instance_valid(tg) or not _fighters.has(tg) or float(_fighters[tg]["hp"]) <= 0.0):
            r["target"] = null
            tg = null
        if tg == null:
            if _flat(n.global_position, centre) > 3.0:
                _step(n, centre, float(r["speed"]), delta)
                _anim(n, "walk")
            continue
        _engage(n, r, tg, delta, false)

func _targets(defs: Array) -> void:
    for d in defs:
        var st: Dictionary = _fighters[d]
        if st["target"] == null or not raiders.has(st["target"]):
            # The old 70 m reached every guard in the little hex town (they
            # mustered at one barracks). Bellmire HD posts its guards at gates
            # ~350 m apart, so the horn turns the WHOLE garrison out - the same
            # outcome: every guard in the valley answers the raid.
            var best = null
            var bd := 1e9
            for r in raiders:
                var rp: Vector3 = (r["node"] as Node3D).global_position
                var dist := _flat(rp, (d as Node3D).global_position)
                if dist < bd:
                    bd = dist
                    best = r
            st["target"] = best
    for r in raiders:
        if r["target"] == null:
            var best2 = null
            var bd2 := 26.0
            for d in defs:
                var dist2 := _flat((d as Node3D).global_position, (r["node"] as Node3D).global_position)
                if dist2 < bd2:
                    bd2 = dist2
                    best2 = d
            r["target"] = best2

## a fight between `me` (stats `st`) and `tg` - a raider dict (for a defender)
## or a defender node (for a raider)
func _engage(me: Node3D, st: Dictionary, tg, delta: float, defending: bool) -> void:
    var tn: Node3D = (tg["node"] as Node3D) if defending else (tg as Node3D)
    st["swing"] = float(st["swing"]) - delta
    if _flat(me.global_position, tn.global_position) > 2.2:
        _step(me, tn.global_position, float(st["speed"]) * 1.15, delta)
        _anim(me, "run")
        return
    var to := tn.global_position - me.global_position
    me.rotation.y = atan2(to.x, to.z)
    if float(st["swing"]) > 0.0:
        return
    st["swing"] = 1.1
    _anim(me, "attack")
    var ts: Dictionary = tg if defending else _fighters[tg]
    var dmg := _strike(float(st["atk"]), int(st["to_hit"]), int(ts["ac"]))
    if dmg <= 0.0:
        return
    ts["hp"] = float(ts["hp"]) - dmg
    if tn is Monster:
        (tn as Monster).hp = float(ts["hp"])
        (tn as Monster)._number(dmg, dmg > float(st["atk"]))
        (tn as Monster)._flash()
    var killer := _name_of(me, st)
    if float(ts["hp"]) <= 0.0:
        if defending:
            _raider_falls(tg, killer)
        else:
            _defender_falls(tn, ts, killer)

func _name_of(n: Node3D, st: Dictionary) -> String:
    if st.has("name"):
        return String(st["name"])
    return String((n as Townsfolk).person_name)

func _raider_falls(r: Dictionary, _killer: String) -> void:
    raiders.erase(r)
    var n: Node3D = r["node"]
    if n is Monster:
        (n as Monster).die()
    else:
        _anim(n, "die")
        get_tree().create_timer(25.0).timeout.connect(func() -> void:
            if is_instance_valid(n):
                n.queue_free())

func _defender_falls(n: Node3D, st: Dictionary, killer: String) -> void:
    # heroes get one CON save, DC 10 (old take_damage)
    if n is HeroBody and not st.get("saved", false):
        st["saved"] = true
        var r: Roster = (n as HeroBody).roster
        var h := r.get_hero((n as HeroBody).user_id)
        var roll := randi() % 20 + 1 + r.save_bonus(h, "con")
        if roll >= 10:
            st["hp"] = 1.0
            _say("%s goes down and claws back up. (CON save %d)" % [(n as Townsfolk).person_name, roll])
            return
        _say("%s fails the save. (CON %d)" % [(n as Townsfolk).person_name, roll])
    _fighters.erase(n)
    _anim(n, "die")
    (town.get("people") as Array).erase(n)
    (n as Townsfolk).stay = true
    var who := (n as Townsfolk).person_name
    if n is HeroBody:
        (n as HeroBody).fallen = true
        var r2: Roster = (n as HeroBody).roster
        var line := r2.kill((n as HeroBody).user_id, killer, 0, 0)
        if line != "":
            _say(line)
        (town.get("heroes") as Dictionary).erase((n as HeroBody).user_id)
        var adv = town.get("adventurers")
        if adv:
            (adv.bodies as Dictionary).erase((n as HeroBody).user_id)
        get_tree().create_timer(25.0).timeout.connect(func() -> void:
            if is_instance_valid(n):
                n.queue_free())
    elif String((n as Townsfolk).role) == "chief":
        town.call("bury", n, "%s, the chief of Bellmire, is killed by %s." % [who, killer])
    else:
        town.call("bury", n, "%s is killed by %s." % [who, killer])

func _flee() -> void:
    for p in town.get("people"):
        if not is_instance_valid(p) or _fighters.has(p) or p is HeroBody:
            continue
        var f: Townsfolk = p
        if f.stay or String(f.role) in ["guard", "chief"]:
            continue
        for r in raiders:
            var hp: Vector3 = (r["node"] as Node3D).global_position
            if _flat(hp, f.global_position) < 13.0:
                var away := Vector3(f.global_position.x - hp.x, 0, f.global_position.z - hp.z).normalized()
                f._route = [f.global_position + away * 16.0]
                f._wait = 3.0
                break

## after the raid, defenders walk back to their posts and take them up again
func _stand_down(delta: float) -> void:
    for d in _fighters.keys():
        if not is_instance_valid(d):
            _fighters.erase(d)
            continue
        var st: Dictionary = _fighters[d]
        var post: Vector3 = st["post"]
        if _flat((d as Node3D).global_position, post) > 0.6:
            _step(d, post, float(st["speed"]), delta)
            _anim(d, "walk")
        else:
            (d as Node3D).rotation.y = float(st["yaw"])
            (d as Townsfolk).stay = bool(st["stay"])
            if not bool(st["stay"]):
                (d as Townsfolk)._route = []
            _anim(d, "idle")
            _fighters.erase(d)

func _inside_walls(p: Vector3) -> bool:
    var wi: Dictionary = town.get("_wall_info")
    var ax := float(wi.get("ax", 0.0))
    var az := float(wi.get("az", 0.0))
    if ax <= 0.0 or az <= 0.0:
        return _flat(p, town.get("_market_pos")) < 60.0
    return (p.x * p.x) / (ax * ax) + (p.z * p.z) / (az * az) < 1.0

## ------------------------------------------------------- ruin and rebuild
const RUBBLE := "res://addons/kaykit_dungeon_remastered/Assets/gltf/"

func _wreck_a_building() -> void:
    var pool: Array = []
    for plot in town.get("plots"):
        if plot.get("ruined", false) or not plot.has("node") or plot.has("landmark"):
            continue
        if is_instance_valid(plot["node"]) and _inside_walls(plot["pos"]):
            pool.append(plot)
    if pool.is_empty():
        return
    # the raiders burn what they can reach: the nearest house to one of them
    var r: Dictionary = raiders[randi() % raiders.size()]
    var rp: Vector3 = (r["node"] as Node3D).global_position
    pool.sort_custom(func(a, b) -> bool: return _flat(a["pos"], rp) < _flat(b["pos"], rp))
    var plot: Dictionary = pool[0]
    plot["ruined"] = true
    plot["ruin"] = _ruin_at(plot)
    ruins.append(plot)
    _say("A building is burning!")

## The house is not swapped for a stock "destroyed" model (the old hex one
## would not match): it is the same house, burnt black, its frame sagged into
## its own footprint, with fallen stone at its feet.
var _char: StandardMaterial3D

func _ruin_at(plot: Dictionary) -> Node3D:
    var house: Node3D = plot["node"]
    if _char == null:
        _char = StandardMaterial3D.new()
        _char.albedo_color = Color(0.11, 0.09, 0.08)
        _char.roughness = 1.0
    plot["was"] = [house.position, house.rotation]
    var aabb := _bounds(house)
    for m in house.find_children("*", "MeshInstance3D", true, false):
        (m as MeshInstance3D).material_override = _char
    house.position.y -= aabb.size.y * 0.38
    house.rotation.z += 0.07
    house.rotation.x -= 0.04
    var holder := Node3D.new()
    holder.name = "ruin"
    town.add_child(holder)
    var c: Vector3 = plot["pos"]
    var yaw := float(plot.get("yaw", 0.0))
    var fw := Vector3(sin(yaw), 0, cos(yaw))
    var sd := Vector3(-fw.z, 0, fw.x)
    var hx := maxf(aabb.size.x, 6.0) * 0.5 + 0.6
    var hz := maxf(aabb.size.z, 6.0) * 0.5 + 0.6
    var pieces := [["rubble_half", hx, 0.0, 0.3], ["rubble_half", -hx, 1.0, 2.0], ["rubble_large", 0.8, hz, 0.9],
                   ["rubble_half", -1.5, -hz, 1.4], ["wall_broken", hx * 0.6, -hz, 0.0]]
    for pc in pieces:
        var path: String = RUBBLE + String(pc[0]) + ".gltf.glb"
        if not ResourceLoader.exists(path):
            continue
        var n: Node3D = (load(path) as PackedScene).instantiate()
        var q := c + sd * float(pc[1]) + fw * float(pc[2])
        n.position = Vector3(q.x, float(town.call("height_at", q.x, q.z)), q.z)
        n.rotation.y = yaw + float(pc[3])
        n.scale = Vector3.ONE * 0.9
        holder.add_child(n)
    var fire := _fire(c + Vector3(0, aabb.size.y * 0.25, 0), hx, hz)
    holder.add_child(fire)
    holder.set_meta("burn", 45.0)
    return holder

func _bounds(n: Node3D) -> AABB:
    var out := AABB()
    var first := true
    for m in n.find_children("*", "MeshInstance3D", true, false):
        var mi: MeshInstance3D = m
        var ab: AABB = mi.global_transform * mi.get_aabb()
        out = ab if first else out.merge(ab)
        first = false
    return out

var _soft: GradientTexture2D

func _fire(at: Vector3, hx := 3.0, hz := 3.0) -> Node3D:
    if _soft == null:
        _soft = GradientTexture2D.new()
        _soft.fill = GradientTexture2D.FILL_RADIAL
        _soft.fill_from = Vector2(0.5, 0.5)
        _soft.fill_to = Vector2(0.5, 0.0)
        var g := Gradient.new()
        g.set_color(0, Color(1, 1, 1, 1))
        g.set_color(1, Color(1, 1, 1, 0))
        _soft.gradient = g
        _soft.width = 64
        _soft.height = 64
    var root := Node3D.new()
    root.position = at
    # [colour, rise speed, amount, life, size]
    for spec in [[Color(1.0, 0.55, 0.15, 0.9), 2.4, 160, 1.3, 1.3], [Color(1.0, 0.85, 0.35, 0.8), 3.0, 60, 0.8, 0.7],
                 [Color(0.16, 0.15, 0.15, 0.55), 3.2, 70, 6.0, 4.0]]:
        var p := GPUParticles3D.new()
        p.amount = int(spec[2])
        p.lifetime = float(spec[3])
        var pm := ParticleProcessMaterial.new()
        pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
        pm.emission_box_extents = Vector3(hx * 0.6, 0.5, hz * 0.6)
        pm.direction = Vector3(0, 1, 0)
        pm.spread = 10.0
        pm.initial_velocity_min = float(spec[1]) * 0.5
        pm.initial_velocity_max = float(spec[1])
        pm.gravity = Vector3(0.4, 0.3, 0)
        pm.scale_min = float(spec[4]) * 0.6
        pm.scale_max = float(spec[4])
        var fade := Curve.new()
        fade.add_point(Vector2(0, 0.4))
        fade.add_point(Vector2(0.3, 1.0))
        fade.add_point(Vector2(1, 0.0))
        var ct := CurveTexture.new()
        ct.curve = fade
        pm.scale_curve = ct
        p.process_material = pm
        var q := QuadMesh.new()
        q.size = Vector2(1, 1)
        var m := StandardMaterial3D.new()
        m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
        m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        m.albedo_color = spec[0]
        m.albedo_texture = _soft
        m.vertex_color_use_as_albedo = true
        if (spec[0] as Color).r > 0.9:
            m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
        q.material = m
        p.draw_pass_1 = q
        root.add_child(p)
    var l := OmniLight3D.new()
    l.light_color = Color(1.0, 0.5, 0.2)
    l.light_energy = 4.0
    l.omni_range = 14.0
    l.position.y = 1.5
    root.add_child(l)
    root.name = "fire"
    return root

func _tick_ruin_fires(delta: float) -> void:
    for plot in ruins:
        var h = plot.get("ruin")
        if h == null or not is_instance_valid(h) or not (h as Node).has_meta("burn"):
            continue
        var t := float((h as Node).get_meta("burn")) - delta
        (h as Node).set_meta("burn", t)
        if t <= 0.0:
            (h as Node).remove_meta("burn")
            var f := (h as Node).get_node_or_null("fire")
            if f:
                f.queue_free()

func _rebuild_pass() -> void:
    if ruins.is_empty():
        return
    var plot: Dictionary = ruins[0]
    if economy.stock.get("wood", 0.0) < 12.0 or economy.stock.get("stone", 0.0) < 8.0:
        economy.want("wood", 12.0)
        economy.want("stone", 8.0)
        return
    economy.take("wood", 12.0)
    economy.take("stone", 8.0)
    ruins.remove_at(0)
    plot["ruined"] = false
    if is_instance_valid(plot["node"]):
        var house: Node3D = plot["node"]
        for m in house.find_children("*", "MeshInstance3D", true, false):
            (m as MeshInstance3D).material_override = null
        if plot.has("was"):
            house.position = plot["was"][0]
            house.rotation = plot["was"][1]
            plot.erase("was")
    if plot.get("ruin") != null and is_instance_valid(plot["ruin"]):
        (plot["ruin"] as Node).queue_free()
    plot.erase("ruin")
    _say("The townsfolk raise the ruin again.")
