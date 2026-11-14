class_name Townsfolk
extends Node3D

## A person of Bellmire. Same KayKit bodies and tints as the old game's
## villagers (Mr. E: keep the characters looking the same for now) - only the
## town around them changed. This is the WALKING half of villager.gd: home ->
## work -> home along the streets. Fighting, delving and the hero sheet come
## across when the dungeon does.

const ADV := "res://addons/kaykit_character_pack_adventures/Characters/gltf/"
## the old game's pace multiplier: flat 4-6 m/s read as skating
## (D17b: 0.62 put a stroll at 2.6 m/s - a sprint for these short KayKit legs,
## whose walk covers 0.8 m/s. 0.40 is a brisk walk the gait can match.)
static var pace := 0.40
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
## D54: a watched NPC goes invisible behind solid walls while indoors. The old
## daytime dwell ran 18-45 s (a probe saw 59 s) - long enough that a pane loses
## them ("I can't find them", Mr. E clip 14-29-22). Cap the DAYTIME indoor stay
## so one always re-emerges within this, like the flee duck brings folk back.
const INDOOR_MIN := 7.0
const INDOOR_MAX := 14.0
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

## D17b: the gait follows how fast the body really moves this frame (its own
## steps, the crowd's push, a raid's _step - whoever moved it), smoothed; and a
## body walking faces the way it goes, so it never walks backwards in a walk
var _gp := Vector3.INF
var _vs := 0.0
## D42: footstep sounds - one step per stride of real travel, surface-aware.
static var foot_sfx := true
var _stride := 0.0
static var face_fix := true

func _process(delta: float) -> void:
    _gait_step(delta)

func _gait_step(delta: float) -> void:
    if _anim == null or delta <= 0.0 or not Rig.gait:
        return
    if inside or not visible:
        _gp = Vector3.INF
        _vs = 0.0
        _yaw_shown = INF
        return
    var p := global_position
    var vel := Vector2.ZERO
    var jump := false
    if _gp != Vector3.INF:
        vel = Vector2(p.x - _gp.x, p.z - _gp.z) / delta
        var v := vel.length()
        if v > 15.0:            # a teleport (out of a door, a raid reset)
            v = _vs
            jump = true
        _vs = lerpf(_vs, v, minf(delta * 7.0, 1.0))
    _gp = p
    # moved along in an idle (a wagon's shove, a pair's shoulder spot, a raid
    # walking them home) - take the steps, the gait stands them again after
    if _vs > 0.6 * size_k and not bool(_anim.get_meta("rig_move", false)) \
            and String(_anim.current_animation) == Rig.idle_of(_anim):
        Rig.play(_anim, "Walking_A")
    Rig.drive(_anim, _vs, size_k, delta)
    # D50: the LOD throttle in _physics_process (nav logic every 2nd/4th frame)
    # also advanced the animation in chunks - the stutter Mr. E saw on mid-distance
    # folk. Advance the clip every frame for the clearly-visible lod-1 band (60-120 m)
    # so it animates smoothly; lod 2 (tiny, past 120 m) stays chunked for the budget.
    if lod == 1 and _anim and visible:
        _anim.advance(delta)
    # D42: FOOTFALLS. The town read as silent because nothing ever played the
    # footstep sounds Sfx defines. A step per stride of real travel, near the
    # camera only (far steps are inaudible and only spend voices), the surface
    # taken from the ground under the foot. A town-wide gap in Sfx (0.05 s) keeps
    # a crowd a patter rather than a machine-gun.
    if foot_sfx and lod == 0 and town and town.has_method("surface_at"):
        if _vs > 0.5 * size_k:
            _stride += _vs * delta
            if _stride >= 0.62 * size_k:
                _stride = 0.0
                Sfx.at("footstep_" + String(town.call("surface_at", global_position)), global_position, -13.0)
        else:
            _stride = 0.0
    if face_fix and _vs > 0.35 and vel.length() > 0.25 and Rig.is_gait(String(_anim.current_animation)):
        # (D17d: from the yaw on screen, not one steering just snapped to)
        var from := _face if _face_ok else (_yaw_shown if Rig.smooth and _yaw_shown != INF and not jump else rotation.y)
        _face = lerp_angle(from, atan2(vel.x, vel.y), minf(delta * 9.0, 1.0))
        _face_ok = true
        rotation.y = _face
    else:
        _face_ok = false
    # a walker already turns smoothly with the way it goes (face_fix)
    _ease_turn(delta, jump or _face_ok)

## D17d: TURNS EASE. Steering sets rotation.y outright - a raid's step faces
## the foe, a new leg of a route, a seat, a post - up to an about-face in one
## frame. The body now swings round toward whatever was set at TURN_RATE; a
## teleport (out of a door) still snaps, and a walker's heading is face_fix's.
const TURN_RATE := 9.5          # rad/s, ~540 deg/s: an about-face in a third of a second
var _yaw_shown := INF
var _yaw_goal := 0.0
var _yaw_set := 0.0             # what was last written here; anything else is a new heading

func _ease_turn(delta: float, jump: bool) -> void:
    if not Rig.smooth:
        return
    var r := rotation.y
    if _yaw_shown == INF or jump:
        _yaw_shown = r
        _yaw_goal = r
        _yaw_set = r
        return
    if absf(angle_difference(r, _yaw_set)) > 0.0005:
        _yaw_goal = r
    _yaw_shown = rotate_toward(_yaw_shown, _yaw_goal, TURN_RATE * delta)
    rotation.y = _yaw_shown
    _yaw_set = _yaw_shown

var _face := 0.0
var _face_ok := false

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
        # D17b: at the shoulder and keeping up is still walking (stepping
        # between Idle and Walking_A every other frame read as a glide);
        # the gait stands him once the pair has stopped
        if not (Rig.gait and leader is Townsfolk and (leader as Townsfolk)._vs > 0.3):
            Rig.play(_anim, "Idle")

## D20b: who takes cover when raiders are in the valley - ordinary folk, not
## the watch, the chief, a tower lookout, a posted stallholder, or a raider.
func _flee_ok() -> bool:
    return rank < 0 and not stay and leader == null and cart == null \
        and role != "guard" and role != "chief" and role != "bandit" \
        and gear_role != "lookout"

## D20b: while a raid is live an ordinary body drops what it is doing and runs
## for the nearest cover (its home, else any house), then cowers indoors until
## the all-clear. Returns true when it fully owns this frame (held indoors).
func _civic_flee() -> bool:
    if town == null or not town.has_method("is_raid_on"):
        return false
    if not bool(town.call("is_raid_on")):
        if _fleeing:
            _fleeing = false
            _flee_k = 1.0
            _wait = randf_range(1.0, 6.0)   # ease out after the all-clear, staggered
        return false
    if not _flee_ok():
        return false
    if inside:
        _route.clear()
        _fleeing = true
        _flee_k = 1.0
        _wait = 4.0
        return true
    # at the doorway with no interior point to step into (a homeless body's
    # refuge, or a home with no inside point): duck inside at the threshold so
    # the street truly clears, rather than mill about the door
    if _fleeing and _enter_at == Vector3.ZERO and _door_out != Vector3.ZERO \
            and Vector2(_door_out.x - global_position.x, _door_out.z - global_position.z).length() < 2.5:
        inside = true
        visible = false
        _route.clear()
        _wait = 4.0
        return true
    if _fleeing and not _route.is_empty():
        return false                         # already running for cover
    var dest := home
    var inpt := home_in
    if dest == Vector3.ZERO:
        var rf: Array = town.call("flee_refuge", global_position)
        if rf.size() == 2:
            dest = rf[0]
            inpt = rf[1]
    if dest == Vector3.ZERO:
        return false
    if _sat:
        _sat = false
        _release_seat()
    _seat_i = -1
    var r: Array = town.call("route", global_position, dest)
    if r.is_empty():
        return false
    _enter_at = inpt
    _door_out = dest
    var end: Vector3 = r.back()
    if inpt != Vector3.ZERO and Vector2(end.x - dest.x, end.z - dest.z).length() <= 1.0:
        r.append(inpt)
    else:
        _enter_at = Vector3.ZERO     # no interior leg; the doorway tuck takes over
    _route = r
    _fleeing = true
    _at_fest = false
    _flee_k = 1.7
    _linger = 999.0
    _wd_at = Vector3.INF
    _wd_n = 0
    _best_d = INF
    _prog_t = 0.0
    _wait = 0.0
    fled += 1
    return false

## D20b: when a festival is on, an idle ordinary body wanders to the square to
## join the crowd (and cheers there via _idle_acts). Returns true when it set a
## route (the caller stops this frame), like _maybe_errand.
func _maybe_gather() -> bool:
    if town == null or not town.has_method("is_festival") or not bool(town.call("is_festival")):
        _at_fest = false
        return false
    if not _flee_ok() or _fleeing or _seat_i >= 0 or _sat:
        return false
    var fp = town.get("festival_at")
    if not (fp is Vector3) or (fp as Vector3) == Vector3.ZERO:
        return false
    var centre: Vector3 = fp
    if Vector2(centre.x - global_position.x, centre.z - global_position.z).length() < 12.0:
        _at_fest = true                       # already here - mill about and cheer
        return false
    if _at_fest:
        return false
    if inside:
        if _door_out == Vector3.ZERO:
            return false
        inside = false
        visible = true
        global_position = Vector3(_door_out.x, float(town.call("height_at", _door_out.x, _door_out.z)), _door_out.z)
    var a := randf() * TAU
    var spot: Vector3 = town.call("keep_walkable", centre + Vector3(cos(a), 0.0, sin(a)) * randf_range(4.0, 11.0))
    var r: Array = town.call("route", global_position, spot)
    if r.is_empty():
        return false
    _route = r
    _enter_at = Vector3.ZERO
    _door_out = Vector3.ZERO
    _linger = randf_range(25.0, 50.0)
    _wait = 0.0
    _wd_at = Vector3.INF
    _wd_n = 0
    _best_d = INF
    _prog_t = 0.0
    _at_fest = true
    gathered += 1
    acts["festival"] = int(acts.get("festival", 0)) + 1
    return true

## D20a: RICHER ROUTINES. An ordinary shuttle-walker (empty stops, no leader,
## no cart) breaks off ONCE a day around midday to shop the market, and once of
## an evening for the tavern yard - so the day reads work -> market -> tavern ->
## home rather than a bare work<->home shuttle. Each body has its own hour for
## each (staggered, so the square fills over a few seconds, not all at once).
## The right anim plays on arrival via _idle_acts (buy/haggle at the market, a
## mug/bite at the tavern). Interrupts the linger (not the trip clock) so a long
## job stint never swallows the short midday window. Returns true when it set a
## new route (the caller stops this frame).
func _maybe_errand() -> bool:
    if market_off:
        return false
    if stay or rank >= 0 or leader != null or cart != null or not stops.is_empty():
        return false
    if _seat_i >= 0 or _sat or town == null:
        return false
    if inside and _door_out == Vector3.ZERO:
        return false
    var er = get("errand")
    if er != null and String(er) != "":
        return false
    var eco = town.get("economy")
    if eco == null or not town.has_method("keep_walkable"):
        return false
    var h: float = eco.hour()
    var dest_key := ""
    if not _mkt_done and not eco.is_night() and h >= _mkt_at and h < 15.0:
        dest_key = "market"
    elif not _tav_done and h >= _tav_at and h < 20.0:
        dest_key = "tavern"
    if dest_key == "":
        return false
    var centre: Vector3
    if dest_key == "market":
        var mk = town.get("_market_pos")
        if not (mk is Vector3) or (mk as Vector3) == Vector3.ZERO:
            return false
        centre = mk
    else:
        var tv = town.get("tavern_at")
        if not (tv is Vector3) or (tv as Vector3) == Vector3.INF or (tv as Vector3) == Vector3.ZERO:
            return false
        # folk knock off at dusk and some head to the tavern yard for a mug
        # before home (the single tavern is across town, so this is the one
        # errand that may land them there after dark - better than the aimless
        # walk home the compressed night already gives everyone)
        centre = tv
    # indoors at work or home: step out through the door, then make for it
    if inside:
        inside = false
        visible = true
        global_position = Vector3(_door_out.x, float(town.call("height_at", _door_out.x, _door_out.z)), _door_out.z)
    # already there (work or home by the square/tavern): count it done, no trip
    if Vector2(centre.x - global_position.x, centre.z - global_position.z).length() < 8.0:
        if dest_key == "market":
            _mkt_done = true
        else:
            _tav_done = true
        return false
    var a := randf() * TAU
    var spot: Vector3 = town.call("keep_walkable", centre + Vector3(cos(a), 0.0, sin(a)) * randf_range(3.0, 9.0))
    var r: Array = town.call("route", global_position, spot)
    if r.is_empty():
        return false
    _route = r
    _enter_at = Vector3.ZERO
    _door_out = Vector3.ZERO
    _linger = randf_range(14.0, 26.0)
    _wait = 0.0
    _wd_at = Vector3.INF
    _wd_n = 0
    _best_d = INF
    _prog_t = 0.0
    if dest_key == "market":
        _market_errand = true
        _mkt_done = true
        acts["market"] = int(acts.get("market", 0)) + 1
    else:
        _eve_drink = true
        _tav_done = true
        acts["tavern_errand"] = int(acts.get("tavern_errand", 0)) + 1
    return true

func _next_trip() -> Vector3:
    _at_job = false
    _eve_drink = false
    _market_errand = false
    # old villager: at night the WORK state ends and they go home to REST until
    # morning (the old clock: night before 6:00 and after 18:30)
    var eco = town.get("economy") if town else null
    var on_errand: bool = String(get("errand")) != "" if get("errand") != null else false
    if stops.is_empty() and eco and eco.is_night() and home != Vector3.ZERO and not on_errand:
        _enter_at = home_in
        _to_work = true                     # in the morning, off to work
        _mkt_done = false                   # D20a: a fresh day - shop + drink again
        _tav_done = false
        _mkt_at = randf_range(10.5, 14.5)
        _tav_at = randf_range(15.0, 17.0)
        var h: float = eco.hour()
        var left: float = (6.0 - h if h < 6.0 else 30.0 - h) / 24.0 * float(eco.DAY_SECONDS)
        _linger = maxf(left, 2.0)
        return home
    if stops.is_empty():
        var dest: Vector3 = work if _to_work else home
        _enter_at = work_in if _to_work else home_in
        _linger = -1.0
        # D17c: a worker works the job out of doors a while (a yard with no
        # door always; one with a door half the time) - seen at it, not gone in
        if _to_work and job_out > 0.0 and JOB_ANIMS.has(role) and rank < 0 \
                and (work_in == Vector3.ZERO or randf() < job_out):
            _enter_at = Vector3.ZERO
            _at_job = true
            _linger = randf_range(25.0, 50.0)
        _to_work = not _to_work
        return dest
    # D17c: an evening's drink - now and then of an evening a body breaks off
    # its round for the tavern's yard (a stool at the tables, or a mug stood
    # up), then takes the round up again where it left it
    if job_out > 0.0 and eco and (eco.hour() >= 17.0 or eco.hour() < 0.5) and rank < 0 \
            and leader == null and cart == null and randf() < 0.3 and town.has_method("_shop_door"):
        var td: Array = town.call("_shop_door", "tavern")
        if not td.is_empty():
            var dv: Vector3 = td[0]
            if Vector2(dv.x - global_position.x, dv.z - global_position.z).length() > 8.0:
                _enter_at = Vector3.ZERO
                _linger = randf_range(20.0, 35.0)
                _eve_drink = true
                acts["tavern_eve"] = int(acts.get("tavern_eve", 0)) + 1
                return dv
    var s: Array = stops[_stop_i % stops.size()]
    _stop_i += 1
    _enter_at = s[1]
    _linger = float(s[2])
    # D17c: of an evening the tavern stop is often out in its yard - a seat at
    # the tables, or a mug stood up - rather than gone indoors
    var tv = town.get("tavern_at") if town else null
    var sp: Vector3 = s[0]
    if job_out > 0.0 and _enter_at != Vector3.ZERO and tv is Vector3 and tv != Vector3.INF \
            and Vector2(sp.x - tv.x, sp.z - tv.z).length() < 12.0 and eco and (eco.hour() >= 17.0 or eco.hour() < 1.0) \
            and randf() < 0.6:
        _enter_at = Vector3.ZERO
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
const WAGON_SNAP := 5.0         # D53: gap (m) past which a towed wagon snaps to its hauler, not crawls

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
        if lod >= 2 and _anim and visible:
            _anim.advance(delta)
    steps += 1
    if town != null:
        _try_cast(delta)
        _cry(delta)
        _voice(delta)
    if cart and is_instance_valid(cart):
        if inside or not visible:
            # D53: the hauler is indoors or culled - leave the wagon parked where it
            # stands; when they re-emerge the owner-gap snap below reattaches it, so it
            # is never seen chasing a body that is not there.
            _park = []
        else:
            var tow := global_position - global_transform.basis.z * 2.6
            tow.y = float(town.call("height_at", tow.x, tow.z))
            var tyaw := rotation.y + PI * 0.5
            # D53: a towed wagon is ATTACHED to its hauler, not a free body. If the
            # HAULER itself has got far from the wagon - it stepped out of a door,
            # respawned, a raid reset it, its stop moved, or a far-LOD body jumped a
            # chunk - the wagon is reattached AT ONCE behind them and re-parks when it
            # settles, so a cart is never seen gliding across open ground with no one
            # on it (Mr. E clip 14-31-18: "the cart is moving on its own ... supposed
            # to be attached to this guy, but it wasn't"). Keyed off the owner-to-cart
            # distance, not the (possibly stale) park target, so a jump can never hide.
            var owner_gap := Vector2(global_position.x - cart.global_position.x, global_position.z - cart.global_position.z).length()
            if owner_gap > WAGON_SNAP:
                cart.global_position = tow
                cart.rotation.y = tyaw
                _park = []
            else:
                var back := tow
                var cy := tyaw
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
                # (D16c: rolls no faster than a wagon should, so nobody is swept up by
                # one; but never slower than the hauler, so it cannot be left behind)
                var cap: float = maxf(_vs + 1.5, 4.0)
                cart.global_position += (back - cart.global_position).limit_length(cap * delta)
                cart.rotation.y = lerp_angle(cart.rotation.y, cy, minf(delta * 6.0, 1.0))
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
    if _civic_flee():
        return
    if stay:
        _posted(delta)
        return
    if _route.is_empty():
        move_dir = Vector3.ZERO
        _wd_at = Vector3.INF
        _wd_n = 0
        if not inside and visible:
            if _seated(delta):
                return
            _idle_acts(delta)
        if _maybe_gather():
            return
        if _maybe_errand():
            return
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
            # D44b: a generated stop point can sit inside a footprint in the
            # dense south-market overlap (the (52,-88.6) hotspot) - route to the
            # walkable point beside it so a body does not stand embedded on
            # arrival (what the walk audit counts). No-op when dest is already
            # clear; the door/interior leg still runs from here via _enter_at.
            if not (town.call("solid_at", dest, 0.0) as Array).is_empty():
                dest = town.call("keep_walkable", dest)
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
    if _sat:
        # D17c: called away while sitting (a raid's flight): up and off
        _sat = false
        _release_seat()
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
            if _seat_i >= 0:
                _sit()
                return
            if _enter_at != Vector3.ZERO:
                # through the door and gone: a while indoors
                inside = true
                visible = false
                var dwell: float = _linger if _linger > 0.0 else randf_range(18.0, 45.0)
                # D54: cap the DAYTIME stay so a pane following them does not lose
                # them for good; the night sleep (a long _linger set in _next_trip)
                # is left alone - the town is meant to be abed then.
                var eco2 = town.get("economy") if town else null
                var night: bool = eco2 != null and eco2.has_method("is_night") and bool(eco2.call("is_night"))
                if not night:
                    dwell = minf(dwell, randf_range(INDOOR_MIN, INDOOR_MAX))
                _wait = dwell
            else:
                _wait = _linger if _linger > 0.0 else randf_range(5.0, 14.0)
                if not _at_job:
                    _maybe_sit()
        return
    var dir: Vector3 = to.normalized()
    _wobble += delta * 1.7
    dir = (dir + Vector3(sin(_wobble), 0.0, cos(_wobble * 0.8)) * sway).normalized()
    var was := global_position
    var p: Vector3 = global_position + dir * speed * pace * _flee_k * delta
    # (D17c: the last step onto a seat is off the walkable ground too)
    var seat_leg: bool = _route.size() == 1 and _seat_i >= 0
    var ghost_leg: bool = _ghost_last != Vector3.INF and _route.has(_ghost_last)
    if door_leg or seat_leg or ghost_leg:
        # (D14: brushing out of a pocket between props - see _escape_route)
        p.y = float(town.call("height_at", p.x, p.z))
        _dbg_leg = 1 if door_leg else (2 if seat_leg else 3)
    else:
        _ghost_last = Vector3.INF
        _dbg_leg = 0
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
    # D44b: never COMMIT a foot the walk audit (_solid_footprints: props +
    # houses) would read as inside one. keep_walkable + _slide_round can fail to
    # clear the dense south-market overlap, and a ghost brush or crowd nudge can
    # cut a footprint corner; carrying that inside foot frame-to-frame via `was`
    # is what left a stray 1/17k. Snap instead to the navmesh - it is baked by
    # carving the SAME footprints, so its nearest point is walkable by
    # construction. The door/seat legs legitimately end inside a house/at a seat
    # (the audit skips them by endpoint), so exclude those; hold at the last
    # spot only if the nav map is not ready yet.
    if not door_leg and not seat_leg and not (town.call("solid_at", p, 0.0) as Array).is_empty():
        var nav2 = town.get("nav")
        if nav2 != null and nav2.ready_ok:
            var q2: Vector3 = nav2.closest(p)
            p = q2 if (town.call("solid_at", q2, 0.0) as Array).is_empty() else was
        else:
            p = was
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

var _dbg_leg := 0
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
    if JOB_ANIMS.has(role):
        # D17c: a keeper at the job works it - mostly the trade's own motions,
        # now and then a look along the street; seldom a pace
        _post_t = randf_range(1.2, 3.5)
        roll = 0.8 if roll < 0.75 else 0.5
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
    var gl: Array = JOB_ANIMS.get(role, POST_GESTURES)
    var g: String = gl[randi() % gl.size()]
    if _anim and _anim.has_animation(g):
        Rig.play(_anim, g)
        _gest_t = minf(_anim.get_animation(g).length, 3.5)
        if gl != POST_GESTURES:
            acts["job"] = int(acts.get("job", 0)) + 1

## D6: name this body as one of Bellmire's own (works before or after _ready)
func make_notable(nm: String, title: String) -> void:
    person_name = nm
    notable_title = title
    if _tag != null:
        _tag.text = "%s\n%s" % [nm, title]
        _tag.modulate = Color(1.0, 0.88, 0.55)
        _tag.visible = true
        _tag.visibility_range_end = 60.0 if show_names else 14.0

## ---- D17c: STATE COVERAGE. What a body does where it stands. A worker at
## the job (posted keepers, and walkers who work their yard out of doors) works
## it in the trade's own motions: the smith at the hammer, a farmer at the hoe
## and the baskets, woodcutters and miners swinging, the stall's keeper with
## the wares and the customers. Folk lingering on the square haggle; of an
## evening at the tavern they drink and eat (KayKit has no seated eating clip:
## a mug or a bite is Use_Item, stood at the tavern's tables). A free bench,
## stool or chair near where someone stopped is sat on - often of an evening,
## now and then by day - Sit_Chair_Down into Sit_Chair_Idle, up again with
## Sit_Chair_StandUp. `job_out = 0` / `sit_ok = false` give the old town.
const JOB_ANIMS := {
    "smith": ["1H_Melee_Attack_Chop", "1H_Melee_Attack_Chop", "Use_Item", "PickUp"],
    "blacksmith": ["1H_Melee_Attack_Chop", "1H_Melee_Attack_Chop", "Use_Item", "PickUp"],
    "armorer": ["1H_Melee_Attack_Chop", "Use_Item", "Interact"],
    "farmer": ["2H_Melee_Attack_Chop", "PickUp", "PickUp", "Use_Item"],
    "miller": ["PickUp", "Use_Item", "Interact"],
    "lumberjack": ["2H_Melee_Attack_Chop", "2H_Melee_Attack_Chop", "PickUp"],
    "miner": ["2H_Melee_Attack_Chop", "2H_Melee_Attack_Chop", "PickUp"],
    "fletcher": ["Use_Item", "1H_Ranged_Reload", "Interact"],
    "merchant": ["Interact", "Cheer", "Use_Item", "PickUp"],
    "trader": ["Interact", "Cheer", "Use_Item", "PickUp"],
    "store": ["Interact", "PickUp", "Use_Item"],
    "apothecary": ["Use_Item", "Interact", "PickUp"],
    "tavern": ["Use_Item", "Interact", "Cheer"],
    "innkeeper": ["Use_Item", "Interact", "Cheer"],
    "baker": ["Use_Item", "PickUp", "Interact"],
    "washer": ["PickUp", "Use_Item", "PickUp"],
}
const NO_SIT := ["caravan", "carter", "bandit", "guard", "watch", "crier", "priest"]
static var job_out := 0.5
static var market_off := false     # D20a: tools/_d20a_test.gd --old turns the errands off
static var sit_ok := true
static var acts := {}                 # kind -> count (tools/_d17c_test.gd)
var _at_job := false
## (a day here is 90 s: a walk across town is hours, so an evening's errand
## is remembered by why it was made, not by the clock on arrival)
var _eve_drink := false
var _market_errand := false     # D20a: on a midday errand to the market
var _mkt_done := false          # D20a: already shopped today (reset each night)
var _tav_done := false          # D20a: already took the evening tavern today
var _mkt_at := randf_range(10.5, 14.5)   # D20a: this body's own market hour
var _tav_at := randf_range(15.0, 17.0)   # D20a: this body's own tavern hour (after the shift)
var _seat_i := -1
var _sat := false
# D20b: a body fleeing a raid for cover, and a body gone to the festival. The
# flee runs (the D17b gait picks the run clip from the real speed via _flee_k).
var _fleeing := false
var _at_fest := false
var _flee_k := 1.0
static var fled := 0             # tools/_d20b_test.gd
static var gathered := 0
var _seat_for := 0.0
var _act_t := randf_range(2.0, 6.0)

func _maybe_sit() -> void:
    if not sit_ok or rank >= 0 or role in NO_SIT or leader != null or cart != null \
            or not shout_lines.is_empty() or not town.has_method("free_seat"):
        return
    var eco = town.get("economy")
    var h: float = eco.hour() if eco != null else 12.0
    var eve := h >= 17.0 or h < 1.0 or _eve_drink
    if randf() > (0.55 if eve else 0.2):
        return
    var i: int = town.call("free_seat", global_position, 16.0 if eve else 9.0)
    if i < 0:
        return
    var s: Dictionary = (town.get("seats") as Array)[i]
    var sp: Vector3 = s["p"]
    var app: Vector3 = sp + (s["f"] as Vector3) * 0.75
    var r: Array = town.call("route", global_position, app)
    if r.is_empty():
        return
    var end: Vector3 = r.back()
    if Vector2(end.x - app.x, end.z - app.z).length() > 1.0:
        return
    s["by"] = get_instance_id()
    _seat_i = i
    _seat_for = maxf(_wait, randf_range(20.0, 45.0) if eve else randf_range(10.0, 22.0))
    r.append(sp)
    _route = r

func _sit() -> void:
    var seats: Array = town.get("seats")
    if _seat_i < 0 or _seat_i >= seats.size():
        _seat_i = -1
        return
    var s: Dictionary = seats[_seat_i]
    var sp: Vector3 = s["p"]
    if Vector2(sp.x - global_position.x, sp.z - global_position.z).length() > 1.3:
        _release_seat()           # sent somewhere else on the way (a flight)
        _wait = randf_range(2.0, 5.0)
        return
    var f: Vector3 = s["f"]
    # the KayKit sit puts the hips 0.35 m behind the feet: the root goes that
    # far forward of the seat so the hips land on the plank (tools/_d17c_fit.gd)
    global_position = sp + f * 0.35
    rotation.y = atan2(f.x, f.z)
    _sat = true
    _wait = _seat_for
    if _anim:
        _anim.set_meta("rig_move", false)
        _anim.set_meta("rig_loop", "Sit_Chair_Idle")
        Rig.play(_anim, "Sit_Chair_Down", 0.25)
    acts["sit"] = int(acts.get("sit", 0)) + 1

func _release_seat() -> void:
    var seats: Array = town.get("seats") if town != null else []
    if _seat_i >= 0 and _seat_i < seats.size() and int(seats[_seat_i]["by"]) == get_instance_id():
        seats[_seat_i]["by"] = 0
    _seat_i = -1

## sitting: true while this frame is the getting-up (the next trip waits on it)
func _seated(delta: float) -> bool:
    if _seat_i >= 0 and not _sat:
        _release_seat()           # the walk there ended some other way
    if not _sat:
        return false
    if _wait > delta:
        return false
    _sat = false
    _release_seat()
    if _anim:
        _anim.set_meta("rig_loop", Rig.idle_of(_anim))
        Rig.play(_anim, "Sit_Chair_StandUp", 0.15)
    _wait = 1.6
    return true

## lingering out of doors: the job's motions, haggling at the market, a mug
## or a bite at the tavern of an evening
func _idle_acts(delta: float) -> void:
    if _sat or _seat_i >= 0 or rank >= 0 or leader != null or not shout_lines.is_empty() \
            or _anim == null or _wait < 1.0:
        return
    _act_t -= delta
    if _act_t > 0.0:
        return
    var cur := String(_anim.current_animation)
    if cur != "" and not Rig.loops(cur):
        _act_t = 0.5                  # a gesture still playing out
        return
    var list: Array = []
    var kind := ""
    if _at_job and JOB_ANIMS.has(role):
        list = JOB_ANIMS[role]
        kind = "job"
        _act_t = randf_range(1.0, 3.0)
    else:
        _act_t = randf_range(4.0, 9.0)
        var eco = town.get("economy")
        var h: float = eco.hour() if eco != null else 12.0
        var tv = town.get("tavern_at")
        var mk = town.get("_market_pos")
        var p := global_position
        if _at_fest and bool(town.get("festival")):
            list = ["Cheer", "Interact", "Cheer"]
            kind = "festival"
        elif (h >= 17.0 or h < 1.0 or _eve_drink) and tv is Vector3 and tv != Vector3.INF \
                and Vector2(p.x - tv.x, p.z - tv.z).length() < 16.0:
            list = ["Use_Item", "Use_Item", "Cheer"]
            kind = "eat"
        elif mk is Vector3 and mk != Vector3.ZERO and Vector2(p.x - mk.x, p.z - mk.z).length() < 20.0 \
                and (_market_errand or randf() < 0.6):
            list = ["Interact", "PickUp", "Interact"]
            kind = "haggle"
        else:
            # D50: a body idling away from the market/tavern/job used to stand in a
            # dead Idle pose - "all these people just hanging out not doing anything".
            # Give it an occasional calm gesture so a standing townsperson reads alive.
            list = POST_GESTURES
            kind = "idle"
            _act_t = randf_range(5.0, 11.0)
    var g: String = list[randi() % list.size()]
    Rig.play(_anim, g)
    acts[kind] = int(acts.get(kind, 0)) + 1
