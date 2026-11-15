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
##  - D22a: LAYERED BEDS - looped, positional ambience laid by the town: the river
##    along its banks, the market's murmur, the forge's fire. Each fades by day /
##    night / raid on its own (market and forge sleep at night and shut for a raid);
##  - D22a: a 24-voice pool that hands out a FREE voice first and, when all are busy,
##    steals the quietest-ranked (farthest, lowest-priority) one - never round-robin
##    cuts a hit to start a footstep. Low-priority kinds (footfalls, animal and town
##    voices) are dropped outright when the pool is nearly full or a burst budget is
##    spent, so a raid's blows always find a voice.
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
    # D22a: delve.gd plays "roar" for a lord's rising - it had no set, so it was silent
    "roar": ["rpg/orc_roar_0.ogg", "rpg/troll_roar_0.ogg", "rpg/minotaur_bellow_0.ogg", "rpg/dragon_roar_0.ogg"],
    # ===== RPG sound library (generated from music-studio v3.5.2, CC0 - see rpg/LICENSE note in LICENSE.txt) =====
    # voices
    "female_attack_yell": ["rpg/female_attack_yell_0.ogg", "rpg/female_attack_yell_1.ogg"],
    "female_death": ["rpg/female_death_0.ogg", "rpg/female_death_1.ogg"],
    "female_effort": ["rpg/female_effort_0.ogg", "rpg/female_effort_1.ogg"],
    "female_gasp": ["rpg/female_gasp_0.ogg", "rpg/female_gasp_1.ogg"],
    "female_grunt": ["rpg/female_grunt_0.ogg", "rpg/female_grunt_1.ogg"],
    "female_hurt": ["rpg/female_hurt_0.ogg", "rpg/female_hurt_1.ogg"],
    "female_jump": ["rpg/female_jump_0.ogg", "rpg/female_jump_1.ogg"],
    "female_laugh": ["rpg/female_laugh_0.ogg", "rpg/female_laugh_1.ogg"],
    "male_attack_yell": ["rpg/male_attack_yell_0.ogg", "rpg/male_attack_yell_1.ogg"],
    "male_death": ["rpg/male_death_0.ogg", "rpg/male_death_1.ogg"],
    "male_effort": ["rpg/male_effort_0.ogg", "rpg/male_effort_1.ogg"],
    "male_gasp": ["rpg/male_gasp_0.ogg", "rpg/male_gasp_1.ogg"],
    "male_grunt": ["rpg/male_grunt_0.ogg", "rpg/male_grunt_1.ogg"],
    "male_hurt": ["rpg/male_hurt_0.ogg", "rpg/male_hurt_1.ogg"],
    "male_jump": ["rpg/male_jump_0.ogg", "rpg/male_jump_1.ogg"],
    "male_laugh": ["rpg/male_laugh_0.ogg", "rpg/male_laugh_1.ogg"],
    # monsters
    "demon_growl": ["rpg/demon_growl_0.ogg", "rpg/demon_growl_1.ogg"],
    "dragon_fire_breath": ["rpg/dragon_fire_breath_0.ogg", "rpg/dragon_fire_breath_1.ogg"],
    "dragon_roar": ["rpg/dragon_roar_0.ogg", "rpg/dragon_roar_1.ogg"],
    "ghost_wail": ["rpg/ghost_wail_0.ogg", "rpg/ghost_wail_1.ogg"],
    "giant_footstep": ["rpg/giant_footstep_0.ogg", "rpg/giant_footstep_1.ogg"],
    "goblin_cackle": ["rpg/goblin_cackle_0.ogg", "rpg/goblin_cackle_1.ogg"],
    "goblin_screech": ["rpg/goblin_screech_0.ogg", "rpg/goblin_screech_1.ogg"],
    "minotaur_bellow": ["rpg/minotaur_bellow_0.ogg", "rpg/minotaur_bellow_1.ogg"],
    "orc_roar": ["rpg/orc_roar_0.ogg", "rpg/orc_roar_1.ogg"],
    "skeleton_rattle": ["rpg/skeleton_rattle_0.ogg", "rpg/skeleton_rattle_1.ogg"],
    "slime_squish": ["rpg/slime_squish_0.ogg", "rpg/slime_squish_1.ogg"],
    "spider_skitter": ["rpg/spider_skitter_0.ogg", "rpg/spider_skitter_1.ogg"],
    "troll_roar": ["rpg/troll_roar_0.ogg", "rpg/troll_roar_1.ogg"],
    "wraith_whisper": ["rpg/wraith_whisper_0.ogg", "rpg/wraith_whisper_1.ogg"],
    "zombie_moan": ["rpg/zombie_moan_0.ogg", "rpg/zombie_moan_1.ogg"],
    # animals
    "bat_screech": ["rpg/bat_screech_0.ogg", "rpg/bat_screech_1.ogg"],
    "bear_roar": ["rpg/bear_roar_0.ogg", "rpg/bear_roar_1.ogg"],
    "bird_chirp": ["rpg/bird_chirp_0.ogg", "rpg/bird_chirp_1.ogg"],
    "boar_grunt": ["rpg/boar_grunt_0.ogg", "rpg/boar_grunt_1.ogg"],
    "cat_hiss": ["rpg/cat_hiss_0.ogg", "rpg/cat_hiss_1.ogg"],
    "cat_meow": ["rpg/cat_meow_0.ogg", "rpg/cat_meow_1.ogg"],
    "cricket_chirp": ["rpg/cricket_chirp_0.ogg", "rpg/cricket_chirp_1.ogg"],
    "crow_caw": ["rpg/crow_caw_0.ogg", "rpg/crow_caw_1.ogg"],
    "dog_bark": ["rpg/dog_bark_0.ogg", "rpg/dog_bark_1.ogg"],
    "dog_whine": ["rpg/dog_whine_0.ogg", "rpg/dog_whine_1.ogg"],
    "eagle_cry": ["rpg/eagle_cry_0.ogg", "rpg/eagle_cry_1.ogg"],
    "frog_ribbit": ["rpg/frog_ribbit_0.ogg", "rpg/frog_ribbit_1.ogg"],
    "horse_neigh": ["rpg/horse_neigh_0.ogg", "rpg/horse_neigh_1.ogg"],
    "horse_whinny": ["rpg/horse_whinny_0.ogg", "rpg/horse_whinny_1.ogg"],
    "insect_buzz": ["rpg/insect_buzz_0.ogg", "rpg/insect_buzz_1.ogg"],
    "lion_roar": ["rpg/lion_roar_0.ogg", "rpg/lion_roar_1.ogg"],
    "owl_hoot": ["rpg/owl_hoot_0.ogg", "rpg/owl_hoot_1.ogg"],
    "snake_hiss": ["rpg/snake_hiss_0.ogg", "rpg/snake_hiss_1.ogg"],
    "wolf_growl": ["rpg/wolf_growl_0.ogg", "rpg/wolf_growl_1.ogg"],
    "wolf_howl": ["rpg/wolf_howl_0.ogg", "rpg/wolf_howl_1.ogg"],
    # magic
    "buff": ["rpg/buff_0.ogg", "rpg/buff_1.ogg"],
    "curse": ["rpg/curse_0.ogg", "rpg/curse_1.ogg"],
    "debuff": ["rpg/debuff_0.ogg", "rpg/debuff_1.ogg"],
    "fireball": ["rpg/fireball_0.ogg", "rpg/fireball_1.ogg"],
    "heal": ["rpg/heal_0.ogg", "rpg/heal_1.ogg"],
    "ice_shard": ["rpg/ice_shard_0.ogg", "rpg/ice_shard_1.ogg"],
    "lightning": ["rpg/lightning_0.ogg", "rpg/lightning_1.ogg"],
    "mana_charge": ["rpg/mana_charge_0.ogg", "rpg/mana_charge_1.ogg"],
    "shield": ["rpg/shield_0.ogg", "rpg/shield_1.ogg"],
    "summon": ["rpg/summon_0.ogg", "rpg/summon_1.ogg"],
    "teleport": ["rpg/teleport_0.ogg", "rpg/teleport_1.ogg"],
    # combat
    "arrow_shot": ["rpg/arrow_shot_0.ogg", "rpg/arrow_shot_1.ogg"],
    "block": ["rpg/block_0.ogg", "rpg/block_1.ogg"],
    "bow_draw": ["rpg/bow_draw_0.ogg", "rpg/bow_draw_1.ogg"],
    "dagger_stab": ["rpg/dagger_stab_0.ogg", "rpg/dagger_stab_1.ogg"],
    "footstep_grass": ["rpg/footstep_grass_0.ogg", "rpg/footstep_grass_1.ogg"],
    "footstep_stone": ["rpg/footstep_stone_0.ogg", "rpg/footstep_stone_1.ogg"],
    "footstep_water": ["rpg/footstep_water_0.ogg", "rpg/footstep_water_1.ogg"],
    "footstep_wood": ["rpg/footstep_wood_0.ogg", "rpg/footstep_wood_1.ogg"],
    "hit_impact": ["rpg/hit_impact_0.ogg", "rpg/hit_impact_1.ogg"],
    "shield_bash": ["rpg/shield_bash_0.ogg", "rpg/shield_bash_1.ogg"],
    "sword_clash": ["rpg/sword_clash_0.ogg", "rpg/sword_clash_1.ogg"],
    "sword_swing": ["rpg/sword_swing_0.ogg", "rpg/sword_swing_1.ogg"],
    # ui / economy
    "chest_open": ["rpg/chest_open_0.ogg", "rpg/chest_open_1.ogg"],
    "coins_stack": ["rpg/coins_stack_0.ogg", "rpg/coins_stack_1.ogg"],
    "error": ["rpg/error_0.ogg", "rpg/error_1.ogg"],
    "inventory_open": ["rpg/inventory_open_0.ogg", "rpg/inventory_open_1.ogg"],
    "item_pickup": ["rpg/item_pickup_0.ogg", "rpg/item_pickup_1.ogg"],
    "level_up": ["rpg/level_up_0.ogg", "rpg/level_up_1.ogg"],
    "menu_back": ["rpg/menu_back_0.ogg", "rpg/menu_back_1.ogg"],
    "menu_select": ["rpg/menu_select_0.ogg", "rpg/menu_select_1.ogg"],
    "potion_drink": ["rpg/potion_drink_0.ogg", "rpg/potion_drink_1.ogg"],
    "quest_complete": ["rpg/quest_complete_0.ogg", "rpg/quest_complete_1.ogg"],
    "unlock": ["rpg/unlock_0.ogg", "rpg/unlock_1.ogg"],
}
const MUSIC := {
    "day": ["music/day_old_tower_inn.ogg", "music/day_minstrel_dance.ogg"],
    "night": ["music/night_bards_tale.ogg", "music/night_exploration.ogg"],
    "raid": ["music/raid_battle.ogg"],
}
const AMBIENCE := "amb/town_wind.ogg"
## D22a beds: kind -> [file, unit_size, max_distance, sleeps at night, shuts for a raid]
## (made for this game with numpy + ffmpeg, CC0 - see assets/audio/LICENSE.txt)
const BEDS := {
    "river": ["amb/river_flow.ogg", 10.0, 60.0, false, false],
    "market": ["amb/market_murmur.ogg", 11.0, 75.0, true, true],
    "forge": ["amb/forge_fire.ogg", 5.0, 40.0, true, true],
}
const BUS_DB := {"Music": -14.0, "Sfx": -6.0, "Ambience": -20.0, "Beds": -12.0}
const VOICES := 24             # D22a: the 3D pool (was 16; D15 peaked 16/16)
const LOW_BUSY := 18           # D22a: at or above this many busy voices, low-priority kinds are dropped
const BURST_WIN := 0.25        # D22a: a low-priority burst budget, per this many real seconds...
const BURST_MAX := 8           # ...at most this many low-priority starts
const LOW_FAR := 60.0          # D22a: low-priority sounds farther than this from the ear are skipped
## priority of a kind when the pool is full: higher keeps its voice. Unlisted = 2.
const PRIO := {"horn": 5, "death": 5, "bell": 5, "roar": 4, "level_up": 4,
    "hit": 3, "hit_impact": 3, "sword_clash": 3, "fireball": 3, "lightning": 3, "dragon_fire_breath": 3,
    "dragon_roar": 3, "orc_roar": 3, "troll_roar": 3}
const FADE := 3.0
const SILENT := -60.0
const GAP := {"hit": 0.06, "swing": 0.06, "spell": 0.1, "coin": 0.15, "splash": 0.2,
    # S1 town casts + S2 dungeon/chat - merged union so a floor of blows (or a spam of commands) cannot machine-gun a sound
    "sword_swing": 0.07, "dagger_stab": 0.07, "sword_clash": 0.08, "hit_impact": 0.06, "bow_draw": 0.1, "arrow_shot": 0.08,
    "block": 0.1, "shield_bash": 0.15, "mana_charge": 0.12, "menu_select": 0.25, "error": 0.4, "coins_stack": 0.2,
    # D42: footfalls finally have a caller (Townsfolk._gait_step). A town-wide floor so a crowd near the camera patters, not machine-guns.
    "footstep_grass": 0.05, "footstep_stone": 0.05, "footstep_wood": 0.06, "footstep_water": 0.08,
    # D22a: animal and townsfolk voices - one bark is a dog, a bark every frame is a glitch
    "dog_bark": 0.35, "dog_whine": 0.5, "cat_meow": 0.6, "horse_neigh": 0.5, "horse_whinny": 0.5,
    "boar_grunt": 0.4, "bird_chirp": 0.3, "crow_caw": 0.6, "owl_hoot": 1.0, "cricket_chirp": 0.3,
    "wolf_howl": 1.0, "wolf_growl": 0.4, "eagle_cry": 1.0,
    "male_laugh": 0.3, "female_laugh": 0.3, "male_grunt": 0.12, "female_grunt": 0.12,
    "male_effort": 0.1, "female_effort": 0.1, "male_hurt": 0.12, "female_hurt": 0.12}

## low priority: dropped first when the pool is crowded (PRIO 1)
static func _low(kind: String) -> bool:
    return kind.begins_with("footstep_") or GAP.get(kind, 0.0) >= 0.3 or kind.ends_with("_laugh") \
        or kind.ends_with("_grunt") or kind.ends_with("_effort")

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
## D22a: measured for the audio soak
var busy_peak := 0             # most 3D voices playing at once
var steals := 0                # a busy voice was taken for a higher-priority sound
var dropped := {}              # kind -> starts dropped (pool crowded / burst spent)
var far_skips := 0             # low-priority starts skipped as out of earshot
var missing := {}              # kind -> plays of a kind with no set (a silent caller)
var beds: Array = []           # [{kind, player, base_db}]
var min_gap := {}              # kind -> shortest msec between two starts (the GAP check)
var _prio_of: Array = []       # pool index -> priority of what it is playing
var _burst_t := 0.0
var _burst_n := 0

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
    for i in range(VOICES):
        var p := AudioStreamPlayer3D.new()
        p.bus = "Sfx"
        p.unit_size = 9.0
        p.max_distance = 110.0
        p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
        add_child(p)
        _pool.append(p)
        _prio_of.append(0)
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
        missing[kind] = int(missing.get(kind, 0)) + 1
        return null
    return _load(String(lst[randi() % lst.size()]))

func _ok_now(kind: String) -> bool:
    var now := Time.get_ticks_msec()
    var gap := int(float(GAP.get(kind, 0.0)) * 1000.0)
    var prev := int(_last.get(kind, -100000))
    if gap > 0 and now - prev < gap:
        return false
    if prev > -100000:
        min_gap[kind] = mini(int(min_gap.get(kind, 1 << 30)), now - prev)
    _last[kind] = now
    plays[kind] = int(plays.get(kind, 0)) + 1
    return true

func _busy() -> int:
    var n := 0
    for p in _pool:
        if (p as AudioStreamPlayer3D).playing:
            n += 1
    return n

func _drop(kind: String) -> void:
    dropped[kind] = int(dropped.get(kind, 0)) + 1

func _ear() -> Vector3:
    var vp := get_viewport()
    var cam: Camera3D = vp.get_camera_3d() if vp else null
    return cam.global_position if cam else Vector3.ZERO

## a voice for a new sound: the first free one after _next; else the busy voice
## with the lowest priority (farthest from the ear breaks a tie), if it ranks
## below the newcomer; else -1 (the newcomer is the least of them and is dropped)
func _voice_for(prio: int) -> int:
    var n := _pool.size()
    for k in range(n):
        var i := (_next + k) % n
        if not (_pool[i] as AudioStreamPlayer3D).playing:
            _next = (i + 1) % n
            return i
    var ear := _ear()
    var best := -1
    var best_p := prio
    var best_d := -1.0
    for i in range(n):
        var pr := int(_prio_of[i])
        var d := (_pool[i] as AudioStreamPlayer3D).global_position.distance_to(ear)
        if pr < best_p or (pr == best_p and best >= 0 and d > best_d):
            best = i
            best_p = pr
            best_d = d
    if best >= 0:
        steals += 1
    return best

func _play3d(kind: String, pos: Vector3, db: float) -> void:
    var low := _low(kind)
    var prio: int = 1 if low else int(PRIO.get(kind, 2))
    if low:
        # GAP throttle on top of the per-kind gap: a crowded pool or a spent burst drops footfalls & chatter
        var now := Time.get_ticks_msec() * 0.001
        if now - _burst_t > BURST_WIN:
            _burst_t = now
            _burst_n = 0
        # a footfall or a bark past LOW_FAR is all but inaudible (-13 dB under a 9 m unit
        # size): it never takes a voice, so the burst budget goes to the near ones
        if pos.distance_to(_ear()) > LOW_FAR:
            far_skips += 1
            return
        if _burst_n >= BURST_MAX or _busy() >= LOW_BUSY:
            _drop(kind)
            return
    if not _ok_now(kind):
        return
    var s := _pick(kind)
    if s == null or _pool.is_empty():
        return
    var vi := _voice_for(prio)
    if vi < 0:
        _drop(kind)
        return
    if low:
        _burst_n += 1
    var p: AudioStreamPlayer3D = _pool[vi]
    _prio_of[vi] = prio
    p.stop()
    p.stream = s
    p.volume_db = db
    p.pitch_scale = randf_range(0.92, 1.08)
    p.global_position = pos
    p.play()
    busy_peak = maxi(busy_peak, _busy())

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

## ----------------------------------------------------------- D22a beds
## lay one looped ambience bed at a place (the town calls this once it is built).
## db is the bed's own level on the Beds bus; it then fades with day/night/raid.
func bed(kind: String, pos: Vector3, db := 0.0) -> AudioStreamPlayer3D:
    var spec: Array = BEDS.get(kind, [])
    if spec.is_empty():
        missing["bed:" + kind] = 1
        return null
    var s := _load(String(spec[0]), true)
    if s == null:
        missing["bed:" + kind] = 1
        return null
    var p := AudioStreamPlayer3D.new()
    p.name = "Bed_" + kind + str(beds.size())
    p.bus = "Beds"
    p.stream = s
    p.unit_size = float(spec[1])
    p.max_distance = float(spec[2])
    p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
    p.volume_db = SILENT
    add_child(p)
    p.global_position = pos
    # start each bed of a kind somewhere different in the loop, so three river
    # emitters do not comb-filter into one phasey voice
    p.play(randf() * 25.0)
    beds.append({"kind": kind, "player": p, "base_db": db})
    return p

## what a bed's level should be now
func bed_target(kind: String) -> float:
    var spec: Array = BEDS.get(kind, [])
    if spec.is_empty():
        return SILENT
    var eco = town.get("economy") if town else null
    var night: bool = eco != null and eco.is_night()
    var raid := mood == "raid"
    if (night and bool(spec[3])) or (raid and bool(spec[4])):
        return SILENT
    return -6.0 if raid else 0.0       # the river runs on under a raid, a little lower

func _beds(real: float) -> void:
    var step := real * 20.0             # dB per real second: a 3 s fade, about
    for b in beds:
        var p: AudioStreamPlayer3D = b["player"]
        if not is_instance_valid(p):
            continue
        var want := bed_target(String(b["kind"]))
        var tgt := SILENT if want <= SILENT else want + float(b["base_db"])
        p.volume_db = move_toward(p.volume_db, tgt, step)

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
    _beds(real)
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
