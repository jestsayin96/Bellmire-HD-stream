class_name Townsfolk
extends Node3D

## A person of Bellmire. Same KayKit bodies and tints as the old game's
## villagers (Mr. E: keep the characters looking the same for now) - only the
## town around them changed. This is the WALKING half of villager.gd: home ->
## work -> home along the streets. Fighting, delving and the hero sheet come
## across when the dungeon does.

const ADV := "res://addons/kaykit_character_pack_adventures/Characters/gltf/"
## the old game's pace multiplier: flat 4-6 m/s read as skating
static var pace := 0.62
## On stream the names that matter are the viewers' heroes (HeroBody turns its
## own back on). Townsfolk names are off unless this is set.
static var show_names := false

var role := "peasant"
var person_name := "Villager"
var model := "Rogue.glb"
var tint := Color(1, 1, 1)
var speed := 4.2
var town: Node3D
var home := Vector3.ZERO
var work := Vector3.ZERO
## just inside the door. ZERO = nowhere to go in (a yard, a stall, a post)
var home_in := Vector3.ZERO
var work_in := Vector3.ZERO
var inside := false
var stay := false              # guards and stallholders keep their post
var face_yaw := 0.0
var gear_role := ""             # overrides role for kit (gate guard, lookout)
var gear_seed := 0
var livery := Color(0.5, 0.4, 0.3)   # district banner colour
var rank := -1                       # guild rank (heroes); -1 = townsfolk
## A DAY: a loop of stops, each [outside point, inside point or ZERO, linger s].
## When set it replaces the plain home<->work shuttle.
var stops: Array = []
var _stop_i := 0
var leader: Node3D = null            # watch pairs: the second man walks at the first's shoulder
var shout_lines: Array = []          # town crier
var _shout_t := 4.0
var _shout: Label3D
var cart: Node3D = null              # carters pull a wagon
var size_k := 1.0                    # children are smaller
## D6: Bellmire's named people (Notables): a title under the name, the tag shown
## up close even with names off, and how far they weave as they walk (the drunk)
var notable_title := ""
var sway := 0.04
var _tag: Label3D

var _anim: AnimationPlayer
var _mdl: Node3D
var _route: Array = []
var _enter_at := Vector3.ZERO
var _wait := 0.0
var _to_work := true
var _wobble := 0.0

func _ready() -> void:
    var sc: PackedScene = load(ADV + model)
    if sc:
        _mdl = sc.instantiate()
        add_child(_mdl)
        if tint != Color(1, 1, 1):
            Rig.tint(_mdl, tint)
        _anim = Rig.find(_mdl)
        Rig.prep(_anim)
        Rig.play(_anim, "Idle")
        if _anim:
            _anim.seek(randf() * 2.0, true)
        if size_k != 1.0:
            _mdl.scale = Vector3.ONE * size_k
        Gear.strip_props(_mdl)
        Gear.dress_role(_mdl, gear_role if gear_role != "" else role, gear_seed)
        Gear.clothe(_mdl, gear_role if gear_role != "" else role, livery, rank)
    var tag := Label3D.new()
    tag.text = person_name if notable_title == "" else "%s\n%s" % [person_name, notable_title]
    tag.font_size = 64
    tag.pixel_size = 0.008
    ## names only up close - forty labels at once was a wall of text
    ## with 130+ people, names only for whoever is right in front of the camera
    tag.visibility_range_end = 9.0
    tag.visible = show_names or notable_title != ""
    tag.visibility_range_end_margin = 2.0
    tag.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
    tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    tag.outline_size = 16
    tag.outline_modulate = Color(0, 0, 0, 0.85)
    tag.position = Vector3(0, 2.45, 0)
    if notable_title != "":
        tag.modulate = Color(1.0, 0.88, 0.55)
        tag.visibility_range_end = 14.0
    add_child(tag)
    _tag = tag
    _wobble = randf() * TAU
    _wait = randf_range(0.0, 5.0)
    if stay:
        rotation.y = face_yaw

## who casts in town, and what (healers mend the neighbourhood, the chief
## wards the hall, apothecaries test their brews on the air)
const CASTERS := {"healer": "heal", "chief": "ward", "apothecary": "mend"}
var _cast_t := randf_range(6.0, 20.0)

func _try_cast(delta: float) -> void:
    if not CASTERS.has(role) or inside:
        return
    _cast_t -= delta
    if _cast_t > 0.0:
        return
    _cast_t = randf_range(14.0, 30.0)
    var kind: String = CASTERS[role]
    var tgt := global_position + global_transform.basis.z * 3.0
    var best := 9.0
    for v in town.get("people"):
        if not is_instance_valid(v):
            continue
        var d: float = (v as Node3D).global_position.distance_to(global_position)
        if v != self and d < best and not v.inside:
            best = d
            tgt = (v as Node3D).global_position
    var in_scar: bool = town.call("in_scar", global_position)
    Spells.cast(kind, self, tgt, in_scar)
    Rig.play(_anim, Spells.CAST_ANIM.get(kind, "Spellcasting"))

func _cry(delta: float) -> void:
    if shout_lines.is_empty():
        return
    _shout_t -= delta
    if _shout_t > 0.0:
        return
    _shout_t = randf_range(9.0, 16.0)
    if _shout == null:
        _shout = Label3D.new()
        _shout.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        _shout.font_size = 48
        _shout.pixel_size = 0.009
        _shout.width = 560.0
        _shout.autowrap_mode = TextServer.AUTOWRAP_WORD
        _shout.outline_size = 14
        _shout.modulate = Color(1.0, 0.92, 0.6)
        # D6: above a named person's two-line tag, not over it
        _shout.position = Vector3(0, 3.1 if notable_title == "" else 3.75, 0)
        add_child(_shout)
    _shout.text = "\"" + String(shout_lines[randi() % shout_lines.size()]) + "\""
    _shout.visible = true
    Rig.play(_anim, "Cheer")
    get_tree().create_timer(5.0).timeout.connect(func() -> void:
        if is_instance_valid(_shout):
            _shout.visible = false
            Rig.play(_anim, "Idle"))

func _follow(delta: float) -> void:
    if not is_instance_valid(leader):
        return
    var side: Vector3 = leader.global_transform.basis.x * 1.3
    var tgt: Vector3 = leader.global_position + side - leader.global_transform.basis.z * 0.4
    var to := tgt - global_position
    to.y = 0.0
    if to.length() > 0.35:
        var p := global_position + to.normalized() * minf(to.length(), speed * pace * 1.15 * delta)
        global_position = town.call("keep_walkable", p)
        rotation.y = leader.rotation.y
        Rig.play(_anim, "Walking_A")
    else:
        rotation.y = leader.rotation.y
        Rig.play(_anim, "Idle")

func _next_trip() -> Vector3:
    # old villager: at night the WORK state ends and they go home to REST until
    # morning (the old clock: night before 6:00 and after 18:30)
    var eco = town.get("economy") if town else null
    var on_errand: bool = String(get("errand")) != "" if get("errand") != null else false
    if stops.is_empty() and eco and eco.is_night() and home != Vector3.ZERO and not on_errand:
        _enter_at = home_in
        _to_work = true                     # in the morning, off to work
        var h: float = eco.hour()
        var left: float = (6.0 - h if h < 6.0 else 30.0 - h) / 24.0 * float(eco.DAY_SECONDS)
        _linger = maxf(left, 2.0)
        return home
    if stops.is_empty():
        var dest: Vector3 = work if _to_work else home
        _enter_at = work_in if _to_work else home_in
        _to_work = not _to_work
        _linger = -1.0
        return dest
    var s: Array = stops[_stop_i % stops.size()]
    _stop_i += 1
    _enter_at = s[1]
    _linger = float(s[2])
    return s[0]

var _linger := -1.0
var _door_out := Vector3.ZERO
var _stuck_t := 0.0
var _door_retry := 0

func _physics_process(delta: float) -> void:
    if town != null:
        _try_cast(delta)
        _cry(delta)
    if cart and is_instance_valid(cart):
        var back := global_position - global_transform.basis.z * 2.6
        cart.global_position = cart.global_position.lerp(Vector3(back.x, float(town.call("height_at", back.x, back.z)), back.z), minf(delta * 4.0, 1.0))
        cart.rotation.y = lerp_angle(cart.rotation.y, rotation.y + PI * 0.5, delta * 3.0)
    if leader != null and town != null:
        _follow(delta)
        return
    if town == null:
        return
    if stay:
        _posted(delta)
        return
    if _route.is_empty():
        _wait -= delta
        if _wait <= 0.0:
            if inside:
                # step back out through the door - FROM the door: the inside
                # point sits within the walls, and a path from there cut
                # straight through the house to the nearest open ground
                inside = false
                visible = true
                if _door_out != Vector3.ZERO:
                    global_position = Vector3(_door_out.x, float(town.call("height_at", _door_out.x, _door_out.z)), _door_out.z)
            var dest: Vector3 = _next_trip()
            _door_out = dest if _enter_at != Vector3.ZERO else Vector3.ZERO
            _route = town.call("route", global_position, dest)
            if _enter_at != Vector3.ZERO:
                # D1: in only through the door - if the street does not reach
                # it, wait outside rather than walk through the walls
                var end: Vector3 = _route.back() if not _route.is_empty() else global_position
                if Vector2(end.x - dest.x, end.z - dest.z).length() > 1.0:
                    _enter_at = Vector3.ZERO
                    _door_out = Vector3.ZERO
                else:
                    _route.append(_enter_at)
            if _route.is_empty():
                _wait = 3.0
        return
    var tgt: Vector3 = _route[0]
    var to: Vector3 = tgt - global_position
    to.y = 0.0
    # D1: the last leg, door -> just inside, is the only one off the walkable
    # ground; corners are taken tight (0.9 m cut through house corners)
    var door_leg: bool = _route.size() == 1 and _enter_at != Vector3.ZERO
    if door_leg and to.length() > 3.0:
        # D6b: a door leg is a step or two. Far from the door (the waypoints
        # before it were given up as stuck) walk the street back to the door
        # first - once; then leave the house be rather than cut through walls
        _route.clear()
        if _door_out != Vector3.ZERO and _door_retry < 1:
            _door_retry += 1
            _route = town.call("route", global_position, _door_out)
            var end: Vector3 = _route.back() if not _route.is_empty() else global_position
            if Vector2(end.x - _door_out.x, end.z - _door_out.z).length() <= 1.0:
                _route.append(_enter_at)
                return
            _route.clear()
        _enter_at = Vector3.ZERO
        _door_out = Vector3.ZERO
        _door_retry = 0
        _wait = randf_range(2.0, 5.0)
        return
    if to.length() < (0.9 if _route.size() == 1 else 0.45):
        _stuck_t = 0.0
        _route.remove_at(0)
        if _route.is_empty():
            Rig.play(_anim, "Idle")
            _door_retry = 0
            if _enter_at != Vector3.ZERO:
                # through the door and gone: a while indoors
                inside = true
                visible = false
                _wait = _linger if _linger > 0.0 else randf_range(18.0, 45.0)
            else:
                _wait = _linger if _linger > 0.0 else randf_range(5.0, 14.0)
        return
    var dir: Vector3 = to.normalized()
    _wobble += delta * 1.7
    dir = (dir + Vector3(sin(_wobble), 0.0, cos(_wobble * 0.8)) * sway).normalized()
    var was := global_position
    var p: Vector3 = global_position + dir * speed * pace * delta
    if door_leg:
        p.y = float(town.call("height_at", p.x, p.z))
    else:
        # room for each other, and never a foot inside anything solid
        p += (town.call("crowd_push", self) as Vector3) * 1.4 * delta
        p = town.call("keep_walkable", p)
    global_position = p
    rotation.y = atan2(dir.x, dir.z)
    Rig.play(_anim, "Walking_A")
    # a waypoint that cannot be reached (off the ground, behind a crowd):
    # after a moment give it up and take the next
    if Vector2(p.x - was.x, p.z - was.z).length() < speed * pace * delta * 0.3:
        _stuck_t += delta
        # a corner the walls will not let a foot onto: close enough is there
        if to.length() < 1.2 and _route.size() > 1:
            _stuck_t = 0.0
            _route.remove_at(0)
        elif _stuck_t > 1.2:
            _stuck_t = 0.0
            _route.remove_at(0)
    else:
        _stuck_t = maxf(_stuck_t - delta, 0.0)

## ---- HD: somebody at a post is not a statue. Guards shift their weight,
## look up and down the street and pace a step or two; stallholders reach for
## their wares and turn to passers-by. All of it stays on their own spot and
## off anything solid (the town's navmesh says where a step may land).
const POST_GESTURES := ["Interact", "Use_Item", "PickUp", "Idle_B", "Interact", "Cheer"]
var _post_at := Vector3.INF
var _post_t := randf_range(2.0, 9.0)
var _gest_t := 0.0
var _pace: Array = []
var _look := 0.0

func _posted(delta: float) -> void:
    if inside or not visible:
        return
    # a fisher on a dock stays put: a pace there walked them off the planks
    for c in get_children():
        if c is Angler:
            return
    # only in Bellmire itself: underground (and in raids) the fight owns the body
    if town.get("nav") == null or (town.get("raids") != null and bool(town.get("raids").get("_live"))):
        return
    if _post_at == Vector3.INF:
        _post_at = global_position
        _look = face_yaw
    if not _pace.is_empty():
        var tgt: Vector3 = _pace[0]
        var to := tgt - global_position
        to.y = 0.0
        if to.length() < 0.12:
            _pace.remove_at(0)
            if _pace.is_empty():
                Rig.play(_anim, "Idle")
            return
        var p := global_position + to.normalized() * minf(to.length(), speed * pace * 0.55 * delta)
        p.y = float(town.call("height_at", p.x, p.z))
        global_position = p
        rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), minf(delta * 8.0, 1.0))
        Rig.play(_anim, "Walking_A")
        return
    rotation.y = lerp_angle(rotation.y, _look, minf(delta * 2.5, 1.0))
    if _gest_t > 0.0:
        _gest_t -= delta
        if _gest_t <= 0.0:
            Rig.play(_anim, "Idle")
        return
    _post_t -= delta
    if _post_t > 0.0:
        return
    _post_t = randf_range(5.0, 13.0)
    var roll := randf()
    if roll < 0.35:
        # a step or two along the post and back
        var side := Vector3(cos(face_yaw), 0.0, -sin(face_yaw)) * randf_range(-1.6, 1.6)
        var tgt := _post_at + side
        var nv = town.get("nav")
        if nv == null or (nv.closest(tgt) as Vector3).distance_to(Vector3(tgt.x, 0, tgt.z)) < 0.25:
            _pace = [tgt, _post_at]
            _look = face_yaw
            return
    if roll < 0.7:
        # look along the street, or at whoever is passing
        _look = face_yaw + randf_range(-1.1, 1.1)
        return
    var g: String = POST_GESTURES[randi() % POST_GESTURES.size()]
    if _anim and _anim.has_animation(g):
        Rig.play(_anim, g)
        _gest_t = minf(_anim.get_animation(g).length, 3.5)

## D6: name this body as one of Bellmire's own (works before or after _ready)
func make_notable(nm: String, title: String) -> void:
    person_name = nm
    notable_title = title
    if _tag != null:
        _tag.text = "%s\n%s" % [nm, title]
        _tag.modulate = Color(1.0, 0.88, 0.55)
        _tag.visible = true
        _tag.visibility_range_end = 60.0 if show_names else 14.0
