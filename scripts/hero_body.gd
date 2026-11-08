class_name HeroBody
extends Townsfolk
## A viewer's hero walking Bellmire. Same KayKit body as the old game for the
## class (Roster.CLASSES model), gear at the bought tier (Gear.dress_hero with
## the old FAMILIES mesh + size/glow), guild rank worn as a sash
## (Lore.standing -> rank_of), name tag in the rank's colour. Walks errands set
## by chat: the forge/armoury, the docks, or the Delvers' Road to the scar.

var user_id := ""
var roster: Roster
var errand := ""
var _route_done: Callable

func setup(r: Roster, uid: String) -> void:
    roster = r
    user_id = uid
    var h := r.get_hero(uid)
    var cls: Dictionary = Roster.CLASSES[h["class"]]
    model = String(cls["model"])
    person_name = String(h["name"])
    role = "hero"
    tint = Color(1, 1, 1)
    speed = float(cls["spd"])

func refresh() -> void:
    if _mdl == null or roster == null:
        return
    var h := roster.get_hero(user_id)
    var look := roster.weapon_look(h)
    Gear.equip(_mdl, _adv(roster.weapon_mesh(h)), "handslot.r", "weapon", float(look["scale"]), float(look["glow"]))
    Gear.equip(_mdl, _adv(roster.offhand_mesh(h)), roster.offhand_bone(h), "offhand")
    # the roster's own RANKS table (same guild roll as data/ranks.json)
    Gear.rank_trim(_mdl, Roster.RANKS.find(roster.rank_row(h)))

func _adv(f: String) -> String:
    if f == "":
        return ""
    return f if f.begins_with("res://") else Gear.ADV + f

var npc := false            # a town adventurer, not a viewer's hero

func _ready() -> void:
    super._ready()
    if _mdl:
        Gear.strip_props(_mdl)
        refresh()
    add_to_group("viewer_heroes")
    # the town's own adventurers: a silver name (viewers' heroes are gold), no ring
    if npc:
        for c in get_children():
            if c is Label3D and c != _shout:
                var lb: Label3D = c
                lb.visibility_range_end = 0.0
                lb.visible = true
                lb.modulate = Color(0.84, 0.86, 0.92)
                lb.font_size = 60
                lb.pixel_size = 0.010
                lb.position.y = 2.6
                var hh := roster.get_hero(user_id)
                lb.text = "%s\n%s" % [person_name, String(hh.get("class", "")).capitalize()]
        return
    # viewers' heroes are what the stream watches: a gold name always shown,
    # their class under it, and a soft ring of light at their feet
    for c in get_children():
        if c is Label3D:
            var lb: Label3D = c
            lb.visibility_range_end = 0.0
            lb.visible = true
            lb.modulate = Color(1.0, 0.84, 0.35)
            lb.font_size = 72
            lb.pixel_size = 0.011
            lb.position.y = 2.7
            var h := roster.get_hero(user_id)
            lb.text = "%s\n%s" % [person_name, String(h["class"]).capitalize()]
    var ring := MeshInstance3D.new()
    var tm := TorusMesh.new()
    tm.inner_radius = 0.55
    tm.outer_radius = 0.68
    ring.mesh = tm
    var m := StandardMaterial3D.new()
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.albedo_color = Color(1.0, 0.82, 0.3)
    m.emission_enabled = true
    m.emission = Color(1.0, 0.75, 0.25)
    m.emission_energy_multiplier = 2.0
    ring.material_override = m
    ring.position = Vector3(0, 0.05, 0)
    ring.scale = Vector3(1, 0.3, 1)
    add_child(ring)

## walk somewhere along the streets; call `then` on arrival
func go(dest: Vector3, why: String, then: Callable = Callable()) -> void:
    errand = why
    stay = false
    stops = []
    _route = town.call("route", global_position, dest)
    _enter_at = Vector3.ZERO
    _wait = 99999.0
    _route_done = then

func _physics_process(delta: float) -> void:
    var had := not _route.is_empty()
    super._physics_process(delta)
    if had and _route.is_empty() and (not npc or errand != ""):
        stay = true
        errand = ""
        if _route_done.is_valid():
            var cb := _route_done
            _route_done = Callable()
            cb.call()

## underground the camera sits close and a party packs into corridors:
## one small line per hero so the fight stays readable. Off again in town.
func compact(on: bool) -> void:
    _compact = on
    var hh := roster.get_hero(user_id) if roster else {}
    for c in get_children():
        if c is Label3D:
            var lb: Label3D = c
            lb.font_size = 40 if on else 72
            lb.outline_size = 10 if on else lb.outline_size
            lb.position.y = 2.3 if on else 2.7
            lb.text = person_name if on or hh.is_empty() else "%s\n%s" % [person_name, String(hh["class"]).capitalize()]

## ---- crowding: when a party bunches up the Name/Class pairs piled into one
## unreadable block. In a crowd each hero shows just their name, lifted by
## their place in the group, so every name stays legible.
var _crowd_t := randf() * 0.25
var _crowded := false
var _compact := false

func _process(delta: float) -> void:
    if not visible:
        return
    _crowd_t -= delta
    if _crowd_t > 0.0:
        return
    _crowd_t = 0.25
    var near: Array = []
    for o in get_tree().get_nodes_in_group("viewer_heroes"):
        if o == self or not (o as Node3D).visible:
            continue
        var d := Vector2(global_position.x - (o as Node3D).global_position.x, global_position.z - (o as Node3D).global_position.z).length()
        if d < 3.5:
            near.append(o)
    var crowded := not near.is_empty()
    # my place along the group (side by side on the ground); neighbours then
    # step through three rows, so adjacent names never collide
    var group: Array = near.duplicate()
    group.append(self)
    group.sort_custom(func(a, b) -> bool:
        var ka := (a as Node3D).global_position.x + (a as Node3D).global_position.z * 0.37
        var kb := (b as Node3D).global_position.x + (b as Node3D).global_position.z * 0.37
        return ka < kb if not is_equal_approx(ka, kb) else (a as Node).get_instance_id() < (b as Node).get_instance_id())
    var rank := group.find(self)
    for c in get_children():
        if c is Label3D and c != _shout:
            var lb: Label3D = c
            var base_y := 2.3 if _compact else (2.6 if npc else 2.7)
            lb.position.y = base_y + (float(rank % 3) * 0.5 if crowded else 0.0)
            if not _compact:
                lb.font_size = (48 if crowded else 60) if npc else (56 if crowded else 72)
            if crowded != _crowded:
                var h := roster.get_hero(user_id) if roster else {}
                if crowded or _compact or h.is_empty():
                    lb.text = person_name
                else:
                    lb.text = "%s\n%s" % [person_name, String(h["class"]).capitalize()]
    _crowded = crowded
