extends SceneTree
## D17c render: the town-day shot sheet - folk at their work (smith, farmer /
## woodcutter / miner out in the yard, a stall's keeper, an angler), a grazing
## beast, someone sat on a bench of an evening and at the tavern's table, a
## mug at the tavern, and a raid (a blow landing, a parry, a fall, beasts
## running). Each named with the clip it is in. Windowed, --fixed-fps 60
## -> renders/cycles/20261112_d17c.
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _out := ""
var _q: Array = []          # [frame, name, label]
var _done := {}
var _forced: Townsfolk = null
var _forced2: Townsfolk = null

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _out = ProjectSettings.globalize_path("res://renders/cycles/20261112_d17c")
    DirAccess.make_dir_recursive_absolute(_out)

func _aim(n: Node3D, dist := 3.4, h := 1.7, side := 0.8, look_h := 0.7) -> void:
    var p: Vector3 = n.global_position
    var fw: Vector3 = n.global_transform.basis.z
    fw.y = 0.0
    fw = fw.normalized()
    var rt := Vector3(fw.z, 0, -fw.x)
    _cam.global_position = p + fw * dist + rt * side + Vector3(0, h, 0)
    _cam.look_at(p + Vector3(0, look_h, 0), Vector3.UP)

func _shot(k: String, n: Node3D, label: String, dist := 3.4, h := 1.7, side := 0.8, look_h := 0.7) -> void:
    if _done.has(k):
        return
    # one shot at a time: the camera is framed for it until it is saved
    for v in _done.values():
        if v is Array:
            return
    _aim(n, dist, h, side, look_h)
    _done[k] = [n, _f + 3, label, dist, h, side, look_h]

func _walker(roles: Array) -> Townsfolk:
    for v in _t.get("people"):
        if is_instance_valid(v) and not v.inside and v.visible and v._anim != null and not v.stay \
                and v.rank < 0 and v.leader == null and v.cart == null and String(v.role) in roles:
            return v
    return null

func _sit_now(v: Townsfolk, kind: String) -> bool:
    var seats: Array = _t.get("seats")
    for i in seats.size():
        var s: Dictionary = seats[i]
        if String(s["kind"]) != kind or int(s["by"]) != 0:
            continue
        var sp: Vector3 = s["p"]
        v.global_position = sp + (s["f"] as Vector3) * 0.7
        s["by"] = v.get_instance_id()
        v._seat_i = i
        v._seat_for = 200.0
        v._enter_at = Vector3.ZERO
        v._route = [sp]
        return true
    return false

func _process(_d: float) -> bool:
    _f += 1
    if _f == 60:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.fov = 42.0
    if _cam and _f > 60 and _cam != root.get_viewport().get_camera_3d():
        _cam.make_current()
    var eco = _t.get("economy")
    if _f < 1500 and eco:
        eco.clock = 0.45                      # a bright working day
    # ---- day: work and grazing
    if _f > 400 and _f < 1500 and _f % 15 == 0:
        for v in _t.get("people"):
            if not is_instance_valid(v) or v.inside or not v.visible or v._anim == null:
                continue
            var ca := String(v._anim.current_animation)
            var r := String(v.role)
            if r in ["blacksmith", "smith"] and ca.begins_with("1H_Melee"):
                _shot("job_smith", v, "%s %s: %s" % [r, v.person_name, ca])
            elif r in ["farmer", "lumberjack", "miner"] and v._at_job and (ca.begins_with("2H_") or ca == "PickUp"):
                _shot("job_" + r, v, "%s %s at the yard: %s" % [r, v.person_name, ca])
            elif r in ["merchant", "trader", "store"] and ca in ["Interact", "Cheer", "Use_Item", "PickUp"]:
                _shot("job_vendor", v, "%s %s: %s" % [r, v.person_name, ca])
            elif r == "fisher" and ca in ["Interact", "Cheer"]:
                _shot("job_angler", v, "fisher %s: %s" % [v.person_name, ca], 4.0, 1.8, 1.2)
        for a in _t.get("animals"):
            if is_instance_valid(a) and a._graze != null and a.grazing() and a._graze.amount > 0.95:
                _shot("graze", a, "%s grazing (neck bent %.2f)" % [a.model.get_file(), a._graze.amount], 1.0, 1.3, 5.5, 0.3)
                break
    # ---- evening: benches, the tavern
    if _f == 1500 and eco:
        eco.clock = 0.80
    if _f >= 1500 and _f < 2700 and eco:
        eco.clock = 0.80
    if _f == 1520:
        _forced = _walker(["peasant", "baker", "washer", "farmer", "miller", "fletcher", "healer"])
        if _forced and not _sit_now(_forced, "bench"):
            _forced = null
        _forced2 = null
        for v in _t.get("people"):
            if is_instance_valid(v) and v != _forced and not v.inside and v.visible and not v.stay and v.rank < 0 \
                    and v.leader == null and v.cart == null and String(v.role) in ["peasant", "miner", "lumberjack", "smith", "trader"]:
                _forced2 = v
                break
        if _forced2 and not _sit_now(_forced2, "tavern"):
            _forced2 = null
    if _f == 1800 and _forced and _forced._sat:
        _shot("sit_bench", _forced, "%s on a bench of an evening: %s" % [_forced.person_name, _forced._anim.current_animation], 3.0, 1.4, 0.9, 0.5)
    if _f == 1900 and _forced2 and _forced2._sat:
        _shot("sit_tavern", _forced2, "%s at the tavern table: %s" % [_forced2.person_name, _forced2._anim.current_animation], 3.0, 1.5, 1.2, 0.5)
    if _f == 2000:
        var tv = _t.get("tavern_at")
        var v := _walker(["peasant", "baker", "washer", "miller", "fletcher"])
        if v and tv is Vector3 and tv != Vector3.INF:
            v._route = []
            v._enter_at = Vector3.ZERO
            v.global_position = _t.call("keep_walkable", tv + Vector3(1.5, 0, 1.5))
            v._wait = 30.0
            v._act_t = 0.0
            _forced = v
    if _f > 2010 and _f < 2400 and _forced and is_instance_valid(_forced) and String(_forced._anim.current_animation) == "Use_Item" \
            and _forced._anim.current_animation_position > 0.6:
        _shot("eat_tavern", _forced, "%s with a mug at the tavern: Use_Item" % _forced.person_name, 3.0, 1.6, 0.8, 0.9)
    # ---- a raid by day
    if _f == 2700 and eco:
        eco.clock = 0.45
        var rd = _t.get("raids")
        rd.force_level = 5
        rd.call("raid", "west")
    if _f == 3300:
        var rd3 = _t.get("raids")
        for a in _t.get("animals"):
            if is_instance_valid(a) and a._graze != null and String(a.kind) == "Sheep":
                for r in rd3.raiders:
                    var n = r.get("node")
                    if n != null and is_instance_valid(n):
                        var q: Vector3 = a.global_position + Vector3(6, 0, 0)
                        q.y = float(_t.call("height_at", q.x, q.z))
                        (n as Node3D).global_position = q
                        break
                break
    if _f > 2760 and _f % 6 == 0:
        for v in _t.get("people"):
            if not is_instance_valid(v) or not v.visible or v._anim == null or v is Cavalry:
                continue
            var ca := String(v._anim.current_animation)
            if ca.begins_with("Hit_") or ca == "Block_Hit":
                _shot("raid_hurt", v, "%s %s takes a blow: %s" % [v.role, v.person_name, ca], 4.5, 2.6, 1.5, 0.8)
            elif ca == "Block":
                _shot("raid_parry", v, "%s %s parries: Block" % [v.role, v.person_name], 4.5, 2.6, 1.5, 0.8)
        var rd2 = _t.get("raids")
        for r in rd2.raiders:
            var n = r.get("node")
            if n is Townsfolk and is_instance_valid(n):
                var ca2 := String((n as Townsfolk)._anim.current_animation)
                if ca2.begins_with("Hit_"):
                    _shot("raid_hurt_bandit", n, "bandit takes a blow: %s" % ca2, 4.5, 2.6, 1.5, 0.8)
                elif ca2.begins_with("1H_Melee") or ca2.begins_with("2H_Melee"):
                    _shot("raid_swing", n, "bandit swings: %s" % ca2, 4.5, 2.6, 1.5, 0.8)
        for v in _t.get_children():
            if v is Townsfolk and is_instance_valid(v) and v._anim and String(v._anim.current_animation).begins_with("Death_"):
                _shot("raid_fall", v, "%s falls: %s" % [v.role, v._anim.current_animation], 3.6, 2.2, 1.0, 0.2)
        for a in _t.get("animals"):
            if is_instance_valid(a) and a.fleeing() and a._moving:
                _shot("flee", a, "%s runs from a raider" % a.model.get_file(), -6.0, 2.6, 5.0, 0.4)
                break
    for k in _done.keys():
        if not (_done[k] is Array):
            continue
        var d: Array = _done[k]
        if d.size() == 7 and _f == int(d[1]):
            if is_instance_valid(d[0]):
                _aim(d[0], d[3], d[4], d[5], d[6])
            d[1] = _f + 1
            d.append(true)
        elif d.size() == 8 and _f == int(d[1]):
            root.get_texture().get_image().save_png(_out + "/%s.png" % k)
            print("SAVED ", k, "  ", d[2])
            _done[k] = true
    if _f >= 60 * 95:
        print("D17C_SHOT done ", _done.keys())
        return true
    return false

