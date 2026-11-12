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
var fallen := false         # this body died; a re-rolled hero gets a new one

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
    if is_inside_tree():
        HeroBody._layout_names(get_tree(), get_viewport().get_camera_3d())
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
    var h := roster.get_hero(user_id) if roster else {}
    if fallen or (not h.is_empty() and not bool(h.get("alive", true))):
        # the fallen keep no name tag - the next hero they raise gets it
        for c in get_children():
            if c is Label3D:
                (c as Label3D).visible = false
        remove_from_group("viewer_heroes")
        return
    for c in get_children():
        if c is Label3D and c != _shout:
            var lb: Label3D = c
            lb.position.y = 2.3 if _compact else (2.6 if npc else 2.7)
            lb.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
            lb.no_depth_test = true          # a name is never lost behind a wall
            lb.render_priority = 11
            if not _compact:
                lb.font_size = (48 if crowded else 60) if npc else (56 if crowded else 72)
            # a crowd, or underground: the name alone, one line each
            var want := person_name if (crowded or _compact or h.is_empty()) else "%s\n%s" % [person_name, String(h["class"]).capitalize()]
            if lb.text != want:
                lb.text = want
    _crowded = crowded

func _name_label() -> Label3D:
    for c in get_children():
        if c is Label3D and c != _shout:
            return c
    return null

static var _laid_frame := -1

## HD: every hero's name laid out ON SCREEN in one pass: lowest on screen
## first, each lifted just enough to clear the names already placed. Done per
## frame for all heroes together so neighbours never disagree.
static func _layout_names(tree: SceneTree, cam: Camera3D) -> void:
    var fr := Engine.get_process_frames()
    if fr == _laid_frame or cam == null:
        return
    _laid_frame = fr
    var items: Array = []
    for o in tree.get_nodes_in_group("viewer_heroes"):
        var hb := o as HeroBody
        if hb == null or not hb.visible or not hb.is_inside_tree():
            continue
        var lb := hb._name_label()
        if lb == null or not lb.visible:
            continue
        var anchor := hb.global_position + Vector3(0, lb.position.y, 0)
        # HD: up close a name grew to fill the screen; shrink it with nearness
        # (down to 40% when the camera is on top of it). L15 (laptop, stream
        # readability): and grow it with distance past 16 m, up to 3x, so a
        # name stays readable on a phone from the high stream camera.
        if not lb.has_meta("px0"):
            lb.set_meta("px0", lb.pixel_size)
        var cd := cam.global_position.distance_to(anchor)
        # L17: while the spotlight panes carry the view (root 3D off) the lane cameras sit ~11 m off -
        # every name (in front of the director or not) keeps the size a close camera gives it,
        # and the main camera's on-screen declutter means nothing in the panes
        var grid := cam.get_viewport() != null and cam.get_viewport().disable_3d
        lb.pixel_size = float(lb.get_meta("px0")) * (0.55 if grid else clampf(cd / 16.0, 0.4, 3.0))
        if grid or cam.is_position_behind(anchor):
            lb.offset.y = 0.0
            continue
        var sp := cam.unproject_position(anchor)
        var line_w := float(lb.font_size) * lb.pixel_size * 1.15
        var up := cam.unproject_position(anchor + cam.global_transform.basis.y * line_w)
        var lh := maxf(absf(sp.y - up.y), 4.0)
        var lines := lb.text.count("\n") + 1
        var longest := 0
        for part in lb.text.split("\n"):
            longest = maxi(longest, part.length())
        items.append([sp, lh, float(longest) * lh * 0.56 + lh * 0.4, float(lines) * lh, lb])
    items.sort_custom(func(a, b) -> bool: return (a[0] as Vector2).y > (b[0] as Vector2).y)
    var placed: Array = []          # [x centre, half w, top y, bottom y]
    for it in items:
        var sp: Vector2 = it[0]
        var lh: float = it[1]
        var hw: float = float(it[2]) * 0.5
        var bh: float = it[3]
        var lift := 0.0
        var tries := 0
        while tries < 40:
            var bot := sp.y - lift
            var top := bot - bh
            var hit := -1.0
            for q in placed:
                if absf(float(q[0]) - sp.x) < hw + float(q[1]) and top < float(q[3]) and bot > float(q[2]):
                    hit = maxf(hit, bot - float(q[2]))      # how far to rise to clear it
            if hit < 0.0:
                break
            lift += hit + lh * 0.12
            tries += 1
        placed.append([sp.x, hw, sp.y - lift - bh, sp.y - lift])
        var lbl: Label3D = it[4]
        lbl.offset.y = lift / lh * float(lbl.font_size) * 1.15
