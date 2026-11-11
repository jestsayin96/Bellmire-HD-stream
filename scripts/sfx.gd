class_name Sfx
extends Node
## SOUND AND MUSIC. One node the town owns (made in town.gd's _ready). Anything
## can call the static helpers - Sfx.at("hit", pos), Sfx.play("horn"),
## Sfx.sting() - and they do nothing when no Sfx is live (bare test tools).
##  - sounds in the world are 3D (a pool of players): far fights are quiet;
##  - music: day / night / raid, crossfaded over 3 s, on its own bus at -14 dB
##    (a stream has a voice over it); a hero's death ducks it for a few seconds;
##  - a bell tolls three times at dawn and at dusk; a horn when a raid comes;
##  - a low wind under the town.
## Files: assets/audio (all CC0 or made here - see assets/audio/LICENSE.txt).

const DIR := "res://assets/audio/"
const SETS := {
    "hit": ["sfx/impactPlate_light_000.ogg", "sfx/impactPlate_light_001.ogg", "sfx/impactPlate_light_002.ogg",
            "sfx/impactPunch_medium_000.ogg", "sfx/impactPunch_medium_001.ogg", "sfx/impactPunch_medium_002.ogg"],
    "swing": ["sfx/knifeSlice.ogg", "sfx/knifeSlice2.ogg", "sfx/drawKnife1.ogg"],
    "spell": ["sfx/impactGlass_light_000.ogg", "sfx/impactGlass_light_001.ogg", "sfx/impactGlass_light_002.ogg"],
    "coin": ["sfx/handleCoins.ogg", "sfx/handleCoins2.ogg"],
    "bell": ["sfx/impactBell_heavy_000.ogg", "sfx/impactBell_heavy_001.ogg"],
    "splash": ["sfx/splash.ogg"],
    "horn": ["sfx/raid_horn.ogg"],
    "death": ["sfx/death_sting.ogg"],
    "ui": ["sfx/click1.ogg", "sfx/switch2.ogg"],
}
const MUSIC := {
    "day": ["music/day_old_tower_inn.ogg", "music/day_minstrel_dance.ogg"],
    "night": ["music/night_bards_tale.ogg", "music/night_exploration.ogg"],
    "raid": ["music/raid_battle.ogg"],
}
const AMBIENCE := "amb/town_wind.ogg"
const BUS_DB := {"Music": -14.0, "Sfx": -6.0, "Ambience": -20.0}
const FADE := 3.0
const SILENT := -60.0
const GAP := {"hit": 0.06, "swing": 0.06, "spell": 0.1, "coin": 0.15, "splash": 0.2}

static var _i: Sfx = null

var town: Node3D
var mood := ""                 # "day" / "night" / "raid" - what the music is playing
var plays := {}                # kind -> how many times it has sounded (tests)
var _streams := {}             # path -> AudioStream
var _pool: Array = []          # AudioStreamPlayer3D
var _next := 0
var _flat: Array = []          # AudioStreamPlayer (not in the world)
var _music: Array = []         # two AudioStreamPlayers, crossfaded
var _cur := 0
var _fade := 0.0
var _amb: AudioStreamPlayer
var _last := {}                # kind -> time it last sounded (msec)
var _check := 0.0
var _night := false
var _night_known := false
var _duck := 0.0

## ------------------------------------------------------------ static API
static func live() -> Sfx:
    return _i

## a sound at a place in the world
static func at(kind: String, pos: Vector3, db := 0.0) -> void:
    if _i and is_instance_valid(_i):
        _i._play3d(kind, pos, db)

## a sound everyone hears the same (horn, bell, coins, the death sting)
static func play(kind: String, db := 0.0) -> void:
    if _i and is_instance_valid(_i):
        _i._play2d(kind, db)

## a hero has died: the sting, the music ducks under it
static func sting() -> void:
    if _i and is_instance_valid(_i):
        _i._play2d("death", 0.0)
        _i._duck = 5.0

## ----------------------------------------------------------------- setup
func setup(t: Node3D) -> void:
    town = t
    _i = self
    _buses()
    for i in range(16):
        var p := AudioStreamPlayer3D.new()
        p.bus = "Sfx"
        p.unit_size = 9.0
        p.max_distance = 110.0
        p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
        add_child(p)
        _pool.append(p)
    for i in range(6):
        var q := AudioStreamPlayer.new()
        q.bus = "Sfx"
        add_child(q)
        _flat.append(q)
    for i in range(2):
        var m := AudioStreamPlayer.new()
        m.bus = "Music"
        m.volume_db = SILENT
        add_child(m)
        _music.append(m)
    _amb = AudioStreamPlayer.new()
    _amb.bus = "Ambience"
    _amb.stream = _load(AMBIENCE, true)
    add_child(_amb)
    if _amb.stream:
        _amb.play()

func _exit_tree() -> void:
    if _i == self:
        _i = null
    # stop and let go of every stream, so nothing is still held at exit
    for c in get_children():
        if c is AudioStreamPlayer:
            (c as AudioStreamPlayer).stop()
            (c as AudioStreamPlayer).stream = null
        elif c is AudioStreamPlayer3D:
            (c as AudioStreamPlayer3D).stop()
            (c as AudioStreamPlayer3D).stream = null
    _streams.clear()

func _buses() -> void:
    for b in BUS_DB:
        var idx := AudioServer.get_bus_index(b)
        if idx < 0:
            AudioServer.add_bus()
            idx = AudioServer.bus_count - 1
            AudioServer.set_bus_name(idx, b)
            AudioServer.set_bus_send(idx, "Master")
        AudioServer.set_bus_volume_db(idx, float(BUS_DB[b]))

func _load(rel: String, loop := false) -> AudioStream:
    if _streams.has(rel):
        return _streams[rel]
    var s: AudioStream = null
    if ResourceLoader.exists(DIR + rel):
        s = load(DIR + rel) as AudioStream
    if s is AudioStreamOggVorbis:
        (s as AudioStreamOggVorbis).loop = loop
    _streams[rel] = s
    return s

func _pick(kind: String) -> AudioStream:
    var lst: Array = SETS.get(kind, [])
    if lst.is_empty():
        return null
    return _load(String(lst[randi() % lst.size()]))

func _ok_now(kind: String) -> bool:
    var now := Time.get_ticks_msec()
    var gap := int(float(GAP.get(kind, 0.0)) * 1000.0)
    if gap > 0 and now - int(_last.get(kind, -100000)) < gap:
        return false
    _last[kind] = now
    plays[kind] = int(plays.get(kind, 0)) + 1
    return true

func _play3d(kind: String, pos: Vector3, db: float) -> void:
    if not _ok_now(kind):
        return
    var s := _pick(kind)
    if s == null or _pool.is_empty():
        return
    var p: AudioStreamPlayer3D = _pool[_next]
    _next = (_next + 1) % _pool.size()
    p.stream = s
    p.volume_db = db
    p.pitch_scale = randf_range(0.92, 1.08)
    p.global_position = pos
    p.play()

func _play2d(kind: String, db: float) -> void:
    if not _ok_now(kind):
        return
    var s := _pick(kind)
    if s == null:
        return
    var q: AudioStreamPlayer = null
    for f in _flat:
        if not (f as AudioStreamPlayer).playing:
            q = f
            break
    if q == null:
        q = _flat[0]
    q.stream = s
    q.volume_db = db
    q.pitch_scale = 1.0 if kind in ["death", "horn"] else randf_range(0.95, 1.05)
    q.play()

## ------------------------------------------------------------ music mood
func want_mood() -> String:
    var r = town.get("raids") if town else null
    if r and not (r.raiders as Array).is_empty():
        return "raid"
    var eco = town.get("economy") if town else null
    if eco and eco.is_night():
        return "night"
    return "day"

func _process(delta: float) -> void:
    if town == null:
        return
    var real := delta / maxf(Engine.time_scale, 0.001)   # fades in real seconds, at any game speed
    _check -= real
    if _check <= 0.0:
        _check = 0.5
        var w := want_mood()
        if w != mood:
            _switch(w)
        var eco = town.get("economy")
        if eco:
            var n: bool = eco.is_night()
            if _night_known and n != _night:
                _toll(3)
            _night = n
            _night_known = true
    _duck = maxf(0.0, _duck - real)
    if _fade > 0.0:
        _fade = maxf(0.0, _fade - real)
    var k := 1.0 - _fade / FADE
    var duck_db := -10.0 if _duck > 0.0 else 0.0
    var a: AudioStreamPlayer = _music[_cur]
    var b: AudioStreamPlayer = _music[1 - _cur]
    a.volume_db = lerpf(SILENT, 0.0, sqrt(k)) + duck_db
    b.volume_db = lerpf(0.0, SILENT, sqrt(k)) + duck_db
    if _fade <= 0.0 and b.playing:
        b.stop()
    # the wind drops under a raid's music
    if _amb:
        _amb.volume_db = -8.0 if mood == "raid" else 0.0

func _switch(w: String) -> void:
    var list: Array = MUSIC.get(w, [])
    if list.is_empty():
        return
    if w == "raid" and mood != "raid":
        _play2d("horn", 0.0)
    mood = w
    var s := _load(String(list[randi() % list.size()]), true)
    if s == null:
        return
    _cur = 1 - _cur
    var m: AudioStreamPlayer = _music[_cur]
    m.stream = s
    m.volume_db = SILENT
    m.play()
    _fade = FADE

## the town bell: n strokes, 1.4 s apart (dawn and dusk)
func _toll(n: int) -> void:
    for i in range(n):
        get_tree().create_timer(0.05 + 1.4 * float(i), true, false, true).timeout.connect(func() -> void:
            _last.erase("bell")
            _play2d("bell", -2.0))
