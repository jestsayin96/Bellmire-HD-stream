extends Node
class_name Daylight
## The old day clock made visible (economy.clock, 90 s days; old sim.is_night:
## night before 6:00 and after 18:30). The sun climbs from 6:00 and sets at
## 18:30; dawn and dusk run warm; at night a low blue moon, a dark sky, the
## street lamps and yard fires burn brighter and the windows glow.

var town: Node3D
var economy: Economy
var sun: DirectionalLight3D
var env: Environment
var sky: ProceduralSkyMaterial
var _lights: Array = []          # [OmniLight3D, base energy]
var _glass: Array = []           # window materials
var _sky_day := {}
var override_hour := -1.0        # test hook

const DAWN := 6.0
const DUSK := 18.5

func setup(t: Node3D) -> void:
    town = t
    economy = t.get("economy")
    for c in t.get_children():
        if c is DirectionalLight3D and sun == null:
            sun = c
        elif c is WorldEnvironment and env == null:
            env = (c as WorldEnvironment).environment
    if env and env.sky:
        sky = env.sky.sky_material as ProceduralSkyMaterial
        _sky_day = {"top": sky.sky_top_color, "hor": sky.sky_horizon_color,
                    "gb": sky.ground_bottom_color, "gh": sky.ground_horizon_color}
    # every town light that exists at founding: lamps, yard fires, beacons
    for n in t.find_children("*", "OmniLight3D", true, false):
        _lights.append([n, (n as OmniLight3D).light_energy])
    # window glass, wherever a building uses it
    var seen := {}
    for mi in t.find_children("*", "MeshInstance3D", true, false):
        var m: MeshInstance3D = mi
        if m.mesh == null:
            continue
        for s in m.mesh.get_surface_count():
            var mat := m.get_active_material(s)
            if mat is StandardMaterial3D and String(mat.resource_name).begins_with("MI_WindowGlass") and not seen.has(mat):
                seen[mat] = true
                _glass.append(mat)
    for g in _glass:
        (g as StandardMaterial3D).emission_enabled = true
        (g as StandardMaterial3D).emission = Color(1.0, 0.68, 0.32)

## S1: THE VALLEY'S VOICES - quiet and now and then. By day birds and a crow, at
## night an owl and the crickets; and when the camera is near the pens, one of
## the animals (a dog, a cat, a horse, a pig). One sound every 5-11 real seconds
## at most, low in the mix (-12 dB and under; Sfx.at fades the far ones), and
## none while a raid has the stage.
const PEN_VOICE := {"Pug": "dog_bark", "Corgi": "dog_bark", "Cat": "cat_meow", "Horse": "horse_neigh",
                    "Foal": "horse_whinny", "Pig": "boar_grunt"}
const DAY_AIR := ["bird_chirp", "bird_chirp", "crow_caw"]
const NIGHT_AIR := ["owl_hoot", "cricket_chirp", "cricket_chirp"]
const HEAR := 70.0
var ambient_plays := {}          # kind -> count (tests)
var _amb_t := 6.0

func _ambient(dt: float) -> void:
    _amb_t -= dt / maxf(Engine.time_scale, 0.001)
    if _amb_t > 0.0:
        return
    _amb_t = randf_range(5.0, 11.0)
    var r = town.get("raids")
    if r and not (r.raiders as Array).is_empty():
        return
    var ear: Vector3 = town.get("_market_pos")
    var cam: Camera3D = get_viewport().get_camera_3d() if get_viewport() else null
    if cam:
        ear = cam.global_position
    var night := nightness(hour()) > 0.5
    var kind := ""
    var at := Vector3.ZERO
    if randf() < 0.45:
        var near: Array = []
        for a in town.get("animals"):
            if is_instance_valid(a) and PEN_VOICE.has(String(a.kind)) and (a as Node3D).global_position.distance_to(ear) < HEAR:
                near.append(a)
        if not near.is_empty():
            var an: Node3D = near[randi() % near.size()]
            kind = String(PEN_VOICE[String(an.kind)])
            at = an.global_position + Vector3(0, 0.6, 0)
    if kind == "":
        kind = String((NIGHT_AIR if night else DAY_AIR)[randi() % 3])
        at = ear + Vector3(randf_range(-25.0, 25.0), 0.0, randf_range(-25.0, 25.0))
        at.y = float(town.call("height_at", at.x, at.z)) + (0.3 if kind == "cricket_chirp" else 9.0)
    ambient_plays[kind] = int(ambient_plays.get(kind, 0)) + 1
    Sfx.at(kind, at, -14.0 if kind in ["cricket_chirp", "bird_chirp"] else -12.0)

func hour() -> float:
    return override_hour if override_hour >= 0.0 else economy.hour()

## 0 at full day, 1 at full night, smooth across an hour either side of dawn/dusk
func nightness(h: float) -> float:
    if h >= DAWN + 1.0 and h <= DUSK - 1.0:
        return 0.0
    if h < DAWN - 0.5 or h > DUSK + 0.5:
        return 1.0
    if h < 12.0:
        return clampf((DAWN + 1.0 - h) / 1.5, 0.0, 1.0)
    return clampf((h - (DUSK - 1.0)) / 1.5, 0.0, 1.0)

## warm light around the horizon crossings
func goldness(h: float) -> float:
    var d := minf(absf(h - DAWN), absf(h - DUSK))
    return clampf(1.0 - d / 1.6, 0.0, 1.0)

func _process(_dt: float) -> void:
    if economy == null or sun == null:
        return
    _ambient(_dt)
    var h := hour()
    var nt := nightness(h)
    var gd := goldness(h)
    # sun along its arc: up at dawn, highest at mid-day, down at dusk
    var day_t := clampf((h - DAWN) / (DUSK - DAWN), 0.0, 1.0)
    var elev := sin(day_t * PI) * 58.0
    var az := lerpf(-70.0, 110.0, day_t)
    if nt >= 1.0 or h < DAWN or h > DUSK:
        # the moon: low, cold, faint
        sun.rotation = Vector3(deg_to_rad(-34.0), deg_to_rad(150.0), 0.0)
        sun.light_color = Color(0.62, 0.70, 0.95)
        sun.light_energy = lerpf(0.0, 0.7, nt)       # HD: a moon you can see by - the stream was near black at night
    else:
        sun.rotation = Vector3(deg_to_rad(-maxf(elev, 4.0)), deg_to_rad(az), 0.0)
        sun.light_color = Color(1, 1, 1).lerp(Color(1.0, 0.62, 0.36), gd)
        sun.light_energy = lerpf(1.5, 0.7, gd) * (1.0 - nt)
    if env:
        # a stream must stay watchable at night: the night sky is near black,
        # so at night the ambient comes mostly from a cool moonlit colour
        env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
        env.ambient_light_color = Color(0.42, 0.50, 0.74)
        env.ambient_light_sky_contribution = lerpf(1.0, 0.3, nt)
        env.ambient_light_energy = lerpf(0.85, 0.8, nt)
        env.fog_light_color = Color(0.70, 0.77, 0.84).lerp(Color(0.86, 0.60, 0.45), gd * (1.0 - nt)).lerp(Color(0.10, 0.12, 0.20), nt)
    if sky and not _sky_day.is_empty():
        var night_top := Color(0.02, 0.03, 0.09)
        var night_hor := Color(0.07, 0.08, 0.16)
        var gold_hor := Color(0.98, 0.58, 0.32)
        sky.sky_top_color = (_sky_day["top"] as Color).lerp(Color(0.32, 0.30, 0.52), gd * 0.6).lerp(night_top, nt)
        sky.sky_horizon_color = (_sky_day["hor"] as Color).lerp(gold_hor, gd).lerp(night_hor, nt)
        sky.ground_horizon_color = (_sky_day["gh"] as Color).lerp(Color(0.5, 0.4, 0.35), gd).lerp(night_hor, nt)
        sky.ground_bottom_color = (_sky_day["gb"] as Color).lerp(Color(0.03, 0.03, 0.05), nt)
    # lamps burn low by day (they are lit, it is just bright out), full at night
    var k := lerpf(0.35, 1.6, maxf(nt, gd * 0.6))
    for l in _lights:
        if is_instance_valid(l[0]):
            (l[0] as OmniLight3D).light_energy = float(l[1]) * k
    for g in _glass:
        (g as StandardMaterial3D).emission_energy_multiplier = lerpf(0.0, 2.4, nt)
