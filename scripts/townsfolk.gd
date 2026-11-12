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
## D16a: room a body takes (centre to shoulder, m) and the way it is walking
## this step (ZERO standing) - town.crowd_push reads both to make room and yield
var body_r := 0.28
var move_dir := Vector3.ZERO

var _anim: AnimationPlayer
var _mdl: Node3D
## D16d: a route asked for before the navmesh is in the server's map comes
## from the old road-hex fallback - 1.8 m right of the hex centres and, for any
## goal past the wall, out through the nearest gate and back in: at the start of
## every stream the first trips crowded the gates two ways for nothing. Such a
## route is marked (the setter) and walked again from the navmesh once it syncs.
var _route: Array = []:
    set(value):
        _route = value
        _route_presync = not value.is_empty() and _nav_unsynced()
var _route_presync := false
static var funnel_fix := true        # false only for the before figure (tools/_d16d_test.gd)
static var presync_reroutes := 0
var _enter_at := Vector3.ZERO
var _wait := 0.0
var _to_work := true
var _wobble := 0.0
## D7: far-away LOD, set by town._lod_pass from the camera's distance. 0 = every
## physics tick; 1 = every 2nd; 2 = every 4th, the step taken with the summed
## time so nobody walks slower. Past 0 the rig is advanced by hand on the same
## beat (a 15 fps pose a hundred metres off reads the same on stream).
var lod := 0
static var steps := 0          # walker steps taken, all townsfolk (tools/_d7_test.gd)
var _lod_n := 0
var _lod_acc := 0.0

func set_lod(l: int) -> void:
    if l == lod:
        return
    lod = l
    _lod_n = 0
    _lod_acc = 0.0
    if _anim:
        _anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL if l > 0 \
                else AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE

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
            body_r *= size_k
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
        UiTheme.style_bubble(_shout)       # laptop L16 phone test (Mr. E): ink on a parchment plate, ~28 px at 1080p
    _shout.text = "\"" + String(shout_lines[randi() % shout_lines.size()]) + "\""
    _shout.visible = true
    UiTheme.fit_plate(_shout)
    Rig.play(_anim, "Cheer")
    var now := Time.get_ticks_msec()
    if randf() < 0.5 and now - _voice_last >= VOICE_GAP:   # S1: every other cry is shouted out loud (same town-wide gap)
        _voice_last = now
        var k := voice_sex() + "_attack_yell"
        voices[k] = int(voices.get(k, 0)) + 1
        Sfx.at(k, global_position + Vector3(0, 1.7, 0), -5.0)
    var st := create_tween()                 # D8: bound to this walker, dies with it
    st.tween_interval(5.0)
    st.tween_callback(func() -> void:
        if is_instance_valid(_shout):
            _shout.visible = false
            Rig.play(_anim, "Idle"))

## S1: VOICES. Now and then a person of Bellmire grunts, puffs or laughs - by
## their sex (the lore's first names; else the body: KayKit's Rogue bodies are
## women). SAMPLED, never a crowd: each person speaks every 45-120 s at most,
## only near the camera (LOD 0), out in the street, and the whole town gives at
## most one voice every VOICE_GAP ms (real time - at 4x the town is no louder).
## The crier's shout is a yell, under the same gap.
const FEMALE := ["Edda", "Mira", "Hilda", "Ysolde", "Petra", "Nessa", "Wren", "Sable", "Tove", "Ingrid", "Maela"]
const MALE := ["Bran", "Rolf", "Talen", "Osric", "Cort", "Garm", "Aldric", "Dunn", "Harl", "Rask", "Corvin"]
const VOICE_GAP := 3500
const QUIET := ["bandit"]                  # raiders cry in raids.gd, not here
static var _voice_last := -100000
static var voices := {}                    # kind -> count (tests)
var sex := ""                              # "male" / "female"; "" = worked out once
var _voice_t := randf_range(25.0, 120.0)

func voice_sex() -> String:
    if sex != "":
        return sex
    var first := person_name.get_slice(" ", 0)
    if FEMALE.has(first):
        sex = "female"
    elif MALE.has(first):
        sex = "male"
    else:
        sex = "female" if model.begins_with("Rogue") else "male"
    return sex

## the kind this person would voice now (a laugh, a grunt, an effort on the move)
func voice_kind() -> String:
    var s := voice_sex()
    if role in ["child", "drunk", "bard"]:
        return s + "_laugh"
    if not _route.is_empty():
        return s + ("_effort" if randf() < 0.6 else "_grunt")
    var r := randf()
    return s + ("_laugh" if r < 0.35 else ("_grunt" if r < 0.8 else "_effort"))

func _voice(delta: float) -> void:
    _voice_t -= delta
    if _voice_t > 0.0:
        return
    _voice_t = randf_range(45.0, 120.0)
    # heroes (rank >= 0) are the laptop's (S2: their voices ride their blows)
    if inside or not visible or lod > 0 or rank >= 0 or QUIET.has(role) or not shout_lines.is_empty():
        return
    var now := Time.get_ticks_msec()
    if now - _voice_last < VOICE_GAP:
        return
    _voice_last = now
    var k := voice_kind()
    voices[k] = int(voices.get(k, 0)) + 1
    Sfx.at(k, global_position + Vector3(0, 1.6 * size_k, 0), -9.0)

func _follow(delta: float) -> void:
    if not is_instance_valid(leader):
        return
    var side: Vector3 = leader.global_transform.basis.x * 1.3
    var tgt: Vector3 = leader.global_position + side - leader.global_transform.basis.z * 0.4
    var to := tgt - global_position
    to.y = 0.0
    if to.length() > 0.35:
        var p := global_position + to.normalized() * minf(to.length(), speed * pace * 1.15 * delta)
        p += (town.call("crowd_push", self, to.normalized()) as Vector3) * delta
        move_dir = to.normalized()
        global_position = town.call("keep_walkable", p)
        rotation.y = leader.rotation.y
        Rig.play(_anim, "Walking_A")
    else:
        move_dir = Vector3.ZERO
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
# D14: progress toward the waypoint (not just "did the feet move") and the
# side a walker slides round a prop by - kept so it does not dither
var _best_d := INF
var _best_tgt := Vector3.INF
var _prog_t := 0.0
var _slide_side := 0.0
var _rerouted := 0
var slides := 0
var reroutes := 0
# D16b: the unstick watchdog - where the feet stood WD_WINDOW s ago, how
# long since, and how many tries in a row came to nothing
static var watchdog := true    # off only for the D16b before/after test
const WD_WINDOW := 2.0
const WD_MIN := 0.2
var _wd_at := Vector3.INF
var _wd_t := 0.0
var _wd_n := 0
var wd_fires := 0
var wd_close := 0
var wd_repaths := 0
var wd_nudges := 0
var wd_giveups := 0
# D16c: when the wagons were last checked against the next leg, and how often
# a walker went round one
var _wag_t := randf() * 0.5
var wag_detours := 0
var _park: Array = []           # D16c: where the wagon is drawn up while stood still

func _physics_process(delta: float) -> void:
    # D16c: a wagon is not in the navmesh - one rolling into someone (walking
    # or stood still) shoves them aside; never a foot inside a wagon. Every
    # frame, before the LOD skip: a far body must not lag inside one either.
    if town != null and not inside and visible and town.has_method("off_wagons"):
        var wq: Vector3 = town.call("off_wagons", global_position, self)
        if wq != global_position:
            global_position = town.call("keep_walkable", wq)
    if lod > 0:
        _lod_acc += delta
        _lod_n += 1
        if _lod_n < (2 if lod == 1 else 4):
            return
        _lod_n = 0
        delta = _lod_acc
        _lod_acc = 0.0
        if _anim and visible:
            _anim.advance(delta)
    steps += 1
    if town != null:
        _try_cast(delta)
        _cry(delta)
        _voice(delta)
    if cart and is_instance_valid(cart):
        var back := global_position - global_transform.basis.z * 2.6
        back.y = float(town.call("height_at", back.x, back.z))
        var cy := rotation.y + PI * 0.5
        # D16c: stood still (a stop, a camp) the wagon is drawn up on open
        # ground beside them, never left across a lane between two props
        if _route.is_empty() and town.has_method("wagon_park"):
            if _park.is_empty():
                _park = town.call("wagon_park", self)
                if _park.is_empty():
                    _park = [back, cy]
            back = _park[0]
            cy = _park[1]
        else:
            _park = []
        # (D16c: no faster than a wagon rolls, so nobody is swept up by one)
        var cstep: Vector3 = (back - cart.global_position) * minf(delta * 4.0, 1.0)
        cart.global_position += cstep.limit_length(4.0 * delta)
        cart.rotation.y = lerp_angle(cart.rotation.y, cy, delta * 3.0)
    if town != null and not inside and visible and town.has_method("off_wagons"):
        # on a route, twice a second: a waypoint under a parked wagon is moved
        # beside it, a leg across one goes round its corner (the navmesh does
        # not know the wagons). Not the door leg - that is a step indoors.
        _wag_t -= delta
        if _wag_t <= 0.0 and not _route.is_empty() and not (_route.size() == 1 and _enter_at != Vector3.ZERO):
            _wag_t = 0.5
            var ww: Array = town.call("wagon_way", global_position, _route[0], self)
            if not ww.is_empty():
                wag_detours += 1
                if ww[0] == "under":
                    _route[0] = ww[1]
                elif _route.size() < 400:
                    _route.insert(0, ww[1])
    if _route_presync and funnel_fix and town != null:
        _resync_route()
    if leader != null and town != null:
        _follow(delta)
        return
    if town == null:
        return
    if stay:
        _posted(delta)
        return
    if _route.is_empty():
        move_dir = Vector3.ZERO
        _wd_at = Vector3.INF
        _wd_n = 0
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
        _best_d = INF
        _prog_t = 0.0
        _rerouted = 0
        _route.remove_at(0)
        if lod > 0 and not _route.is_empty():
            _lod_acc += delta       # D7: no step was taken - the far walker keeps the time
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
    if door_leg or (_ghost_last != Vector3.INF and _route.has(_ghost_last)):
        # (D14: brushing out of a pocket between props - see _escape_route)
        p.y = float(town.call("height_at", p.x, p.z))
    else:
        _ghost_last = Vector3.INF
        # room for each other, and never a foot inside anything solid
        # (D16a: crowd_push is a velocity - separation plus a sidestep to
        # pass whoever is in the way ahead)
        p += (town.call("crowd_push", self, dir) as Vector3) * delta
        var want := p
        p = town.call("keep_walkable", p)
        if Vector2(p.x - want.x, p.z - want.z).length() > 0.005:
            # D14: pressed against a prop (a crate, a bench, a fence end) the
            # push-out only hands the foot back - step round it instead
            p = _slide_round(was, dir, speed * pace * delta, p)
    global_position = p
    move_dir = dir
    rotation.y = atan2(dir.x, dir.z)
    Rig.play(_anim, "Walking_A")
    # D16b: on a route but the feet went under WD_MIN in WD_WINDOW s (pinned
    # in a crowd, wedged on a prop, or the skip / re-route below going round
    # in a circle): close enough is there, else re-path, else step aside
    if not watchdog:
        pass
    elif _wd_at == Vector3.INF:
        _wd_at = p
        _wd_t = 0.0
    else:
        _wd_t += delta
        if _wd_t >= WD_WINDOW:
            var moved := Vector2(p.x - _wd_at.x, p.z - _wd_at.z).length()
            _wd_t = 0.0
            _wd_at = p
            if moved < WD_MIN:
                wd_fires += 1
                if _unstick(dir):
                    return
            else:
                _wd_n = 0
    # a waypoint that cannot be reached (off the ground, behind a crowd):
    # after a moment give it up and take the next
    if Vector2(p.x - was.x, p.z - was.z).length() < speed * pace * delta * 0.3:
        _stuck_t += delta
        # a corner the walls will not let a foot onto: close enough is there
        if to.length() < 1.2 and _route.size() > 1:
            _stuck_t = 0.0
            _route.remove_at(0)
        elif _stuck_t > 1.2:
            # D14: not just skip the waypoint (the next one lies past the same
            # prop) - hand it to the re-route below
            _stuck_t = 0.0
            _prog_t = 3.0
    else:
        _stuck_t = maxf(_stuck_t - delta, 0.0)
    # D14: feet that move but get no nearer (a prop's push-out and the step
    # cancelling each other) are stuck too: re-route once, then skip it
    var d_now := Vector2(tgt.x - p.x, tgt.z - p.z).length()
    if tgt != _best_tgt:
        _best_tgt = tgt
        _best_d = d_now
        _prog_t = 0.0
    elif d_now < _best_d - 0.2:
        _best_d = d_now
        _prog_t = 0.0
        _slide_side = 0.0
    else:
        _prog_t += delta
        if _prog_t > 2.5 and not _route.is_empty():
            _prog_t = 0.0
            _best_d = INF
            _slide_side = -_slide_side if _slide_side != 0.0 else 1.0
            if _rerouted < 1 and _enter_at == Vector3.ZERO:
                _rerouted += 1
                reroutes += 1
                var goal: Vector3 = _route.back()
                var nr: Array = _escape_route(goal)
                if nr.is_empty():
                    nr = town.call("route", global_position, goal)
                if not nr.is_empty():
                    _route = nr
                    return
            _rerouted = 0
            _route.remove_at(0)

func _nav_unsynced() -> bool:
    if town == null:
        return false
    var n = town.get("nav")
    return n != null and not bool(n.call("synced"))

## D16d: the navmesh is in the map now - walk the same trip on it instead of the
## pre-sync road-hex route (a door trip keeps its last step indoors)
func _resync_route() -> void:
    if _nav_unsynced():
        return
    _route_presync = false
    if _route.is_empty():
        return
    var door := _enter_at != Vector3.ZERO and _door_out != Vector3.ZERO
    var goal: Vector3 = _door_out if door else _route.back()
    var nr: Array = town.call("route", global_position, goal)
    if nr.is_empty():
        return
    if door:
        var end: Vector3 = nr.back()
        if Vector2(end.x - goal.x, end.z - goal.z).length() > 1.0:
            return
        nr.append(_enter_at)
    _route = nr
    presync_reroutes += 1
    _best_tgt = Vector3.INF
    _prog_t = 0.0
    _stuck_t = 0.0

## D16b: what the watchdog does with a walker that has not moved in
## WD_WINDOW s. True when the route changed (the caller stops this step).
func _unstick(dir: Vector3) -> bool:
    _wd_n += 1
    var here := global_position
    var door := _enter_at != Vector3.ZERO
    var goal: Vector3 = _route.back()
    var end_at: Vector3 = _door_out if door and _door_out != Vector3.ZERO else goal
    var to_end := Vector2(end_at.x - here.x, end_at.z - here.z).length()
    _best_tgt = Vector3.INF
    _prog_t = 0.0
    _stuck_t = 0.0
    # someone is standing on the very spot: near enough is there
    if to_end < (1.5 if door else 2.5):
        wd_close += 1
        if door:
            _route = [_enter_at]
            return true
        _route.clear()
        Rig.play(_anim, "Idle")
        _door_retry = 0
        _wait = _linger if _linger > 0.0 else randf_range(5.0, 14.0)
        return true
    if _wd_n == 2:
        # step aside (a body's width off the line, either hand, or back the
        # way it came) onto free walkable ground, then on along the route
        var side := Vector3(-dir.z, 0.0, dir.x)
        if _slide_side < 0.0:
            side = -side
        # (either hand first, then round the clock; a body's width, then half)
        for k in 16:
            var ang: float = [PI * 0.5, -PI * 0.5, PI * 0.75, -PI * 0.75, PI * 0.25, -PI * 0.25, PI, 0.0][k % 8]
            var c: Vector3 = here + side.rotated(Vector3.UP, ang - PI * 0.5) * (0.8 if k < 8 else 0.45)
            var kw: Vector3 = town.call("keep_walkable", c)
            if Vector2(kw.x - c.x, kw.z - c.z).length() > 0.05:
                continue
            if not (town.call("solid_at", c, 0.17) as Array).is_empty():
                continue
            c.y = float(town.call("height_at", c.x, c.z))
            wd_nudges += 1
            _route.push_front(c)
            return true
        # nowhere free to step: brush out past the props' edges to the mesh
        if not door:
            var gr := _flood_out(end_at, 0.02)
            if not gr.is_empty():
                _ghost_last = gr[_ghost_n_of]
                wd_nudges += 1
                _route = gr
                return true
    if _wd_n >= 3 and rank < 0 and role != "caravan":
        # three tries and still pinned: let this trip go, try another later
        # (a hero on an errand and a caravan, whose trip IS the errand, keep on)
        wd_giveups += 1
        _route.clear()
        _enter_at = Vector3.ZERO
        _door_out = Vector3.ZERO
        _door_retry = 0
        Rig.play(_anim, "Idle")
        _wait = randf_range(2.0, 5.0)
        return true
    # a fresh path from where the feet are (out of a prop pocket first)
    var nr: Array = []
    if not door:
        nr = _escape_route(end_at)
    if nr.is_empty():
        nr = town.call("route", here, end_at)
    if nr.is_empty():
        return false
    if door:
        nr.append(_enter_at)
    wd_repaths += 1
    if _wd_n >= 3:
        _wd_n = 1           # a hero on an errand keeps trying
    _route = nr
    return true

## D14: a walker caught in a pocket between props (a yard's fence and its
## tables) is off the navmesh, and a path from there starts at the nearest
## walkable point - often across the fence. Find the nearest walkable point
## a straight step can reach, and go from there.
func _escape_route(goal: Vector3) -> Array:
    # first a foot's width clear of every solid; failing that (wedged between
    # a fence and a stool) brush past the props' edges for that short stretch
    var r := _flood_out(goal, 0.17)
    if r.is_empty():
        r = _flood_out(goal, 0.02)
        if not r.is_empty():
            _ghost_last = r[_ghost_n_of]
    return r

var _ghost_last := Vector3.INF
var _ghost_n_of := 0

func _flood_out(goal: Vector3, margin: float) -> Array:
    var nav = town.get("nav")
    if nav == null or not nav.ready_ok:
        return []
    var here := global_position
    var c0: Vector3 = nav.closest(here)
    if Vector2(c0.x - here.x, c0.z - here.z).length() < 0.4 and bool(town.call("_clear_line", here, c0)):
        return []
    # a small flood over free ground (a foot's width clear of every solid),
    # 0.35 m steps, out to the first cell that is on the walkable mesh
    const STEP := 0.35
    var start := Vector2i(0, 0)
    var prev := {start: start}
    var q: Array[Vector2i] = [start]
    var found := Vector2i(9999, 9999)
    var head := 0
    while head < q.size() and head < 2500:
        var c: Vector2i = q[head]
        head += 1
        var w := here + Vector3(c.x * STEP, 0.0, c.y * STEP)
        if c != start:
            var nc: Vector3 = nav.closest(w)
            if Vector2(nc.x - w.x, nc.z - w.z).length() < 0.2:
                found = c
                break
        for n in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
            var nn: Vector2i = c + n
            if prev.has(nn) or absi(nn.x) > 30 or absi(nn.y) > 30:
                continue
            var wp := here + Vector3(nn.x * STEP, 0.0, nn.y * STEP)
            if not (town.call("solid_at", wp, margin) as Array).is_empty():
                continue
            prev[nn] = c
            q.append(nn)
    if found.x == 9999:
        return []
    var chain: Array = []
    var cur := found
    while cur != start:
        var wp2 := here + Vector3(cur.x * STEP, 0.0, cur.y * STEP)
        wp2.y = float(town.call("height_at", wp2.x, wp2.z))
        chain.push_front(wp2)
        cur = prev[cur]
    var r: Array = town.call("route", chain.back(), goal)
    if r.is_empty():
        return []
    _ghost_n_of = chain.size() - 1
    return chain + r

## D14: the first free step round whatever the foot met, turning a little
## more each try, on the side chosen last time (toward the target first)
func _slide_round(was: Vector3, dir: Vector3, step: float, fallback: Vector3) -> Vector3:
    step = maxf(step, 0.02)
    if _slide_side == 0.0:
        var r: Array = town.call("solid_at", fallback, 0.6)
        var side := 1.0
        if not r.is_empty():
            var c: Vector2 = r[0]
            var off := Vector2(was.x - c.x, was.z - c.y)
            # turn away from the prop's middle
            side = 1.0 if (dir.x * off.y - dir.z * off.x) < 0.0 else -1.0
        _slide_side = side
    slides += 1
    for a in [0.6, 1.0, 1.4, 1.8, 2.3]:
        for sgn in [_slide_side, -_slide_side]:
            var c2: Vector3 = was + dir.rotated(Vector3.UP, a * sgn) * step
            if (town.call("solid_at", c2, 0.155) as Array).is_empty():
                if sgn != _slide_side:
                    _slide_side = sgn
                c2.y = float(town.call("height_at", c2.x, c2.z))
                return c2
    return fallback

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
