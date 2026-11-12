class_name SnapshotPublisher
extends Node
## W1a: the viewer hub's data. Every 60 s ONE row of the Supabase table public.snapshot
## (id = 1) is overwritten with a jsonb blob: the town, the guild roll, the fallen, every
## hero's sheet / inventory / gear and the command list (data/commands.json). One row,
## upserted - the table never grows and nothing has to be cleaned up.
##  - The SERVICE ROLE key lives in user://supabase.json  {"url": ..., "service_key": ...}
##    beside the Twitch tokens, NEVER in the repo. No file (or no key) = publish is off,
##    quietly; the game runs the same without it.
##  - Fire and forget: HTTPRequest on its own thread (use_threads), one request in flight
##    at most, the answer read from a signal. A frame never waits on the network, and a
##    failure only waits for the next beat.
##  - Supabase refuses a secret key from anything that looks like a browser ("Forbidden
##    use of secret API key in browser"), so the request carries User-Agent: BellmireHD/1.0.
## Starts in play only (town.gd), like TwitchEventSub. Tests drive build_payload() / publish().

signal published(code: int)

const KEY_FILE := "user://supabase.json"
const TABLE_PATH := "/rest/v1/snapshot?on_conflict=id"
const EVERY := 60.0
const FIRST := 20.0                 # first beat after start: the roster and town are up
const TIMEOUT := 20.0
const USER_AGENT := "BellmireHD/1.0"
const ROLL_MAX := 50
const FALLEN_MAX := 50

var town: Node                      # roster, economy
var key_file := KEY_FILE            # tests point this elsewhere
var enabled := false
var url := ""
var _key := ""
var _commands: Dictionary = {}
var _t := FIRST
var _busy := false
var _http: HTTPRequest = null
var last_code := 0
var last_note := ""
var sent := 0
var failed := 0
var last_bytes := 0
var last_build_ms := 0.0
var _warned := {}

func setup(t: Node) -> void:
    town = t
    _commands = _load_commands()
    _load_key()
    if not enabled:
        print("SNAPSHOT off: no service key in %s - the hub will not update" % key_file)
        return
    _http = HTTPRequest.new()
    _http.name = "SnapshotHTTP"
    _http.use_threads = true
    _http.timeout = TIMEOUT
    add_child(_http)
    _http.request_completed.connect(_on_done)
    print("SNAPSHOT on: %s every %d s" % [url, int(EVERY)])

func _load_key() -> void:
    enabled = false
    if not FileAccess.file_exists(key_file):
        return
    var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(key_file))
    if typeof(j) != TYPE_DICTIONARY:
        return
    url = String(j.get("url", "")).strip_edges().trim_suffix("/")
    _key = String(j.get("service_key", "")).strip_edges()
    enabled = url.begins_with("https://") and _key != ""

func _load_commands() -> Dictionary:
    var f := FileAccess.open("res://data/commands.json", FileAccess.READ)
    if f == null:
        return {}
    var j: Variant = JSON.parse_string(f.get_as_text())
    if typeof(j) != TYPE_DICTIONARY:
        return {}
    return {"order": j.get("order", []), "commands": j.get("commands", {})}

func _process(delta: float) -> void:
    if not enabled:
        return
    _t -= delta
    if _t <= 0.0:
        _t = EVERY
        publish()

# ---------------------------------------------------------------- the blob

## Everything the hub shows. Plain JSON types only. Twitch user ids are left out:
## the hub needs names, not ids.
func build_payload() -> Dictionary:
    var t0 := Time.get_ticks_usec()
    var r: Roster = town.get("roster") if town else null
    var e: Economy = town.get("economy") if town else null
    var out := {
        "v": 1,
        "game": "Bellmire HD",
        "generated_at": Time.get_datetime_string_from_system(true) + "Z",
        "town": _town_block(e),
        "guild_roll": [],
        "fallen": [],
        "heroes": [],
        "commands": _commands,
    }
    if r:
        out["guild_roll"] = r.leaderboard("standing", ROLL_MAX)
        var dead: Array = []
        for f: Dictionary in r.fallen.slice(0, FALLEN_MAX):
            dead.append({"name": f.get("name", "?"), "class": f.get("class", ""),
                "level": int(f.get("level", 1)), "deepest": int(f.get("deepest", 0)),
                "kills": int(f.get("kills", 0)), "killed_by": String(f.get("killed_by", "")),
                "day": int(f.get("day", 0)), "epitaph": String(f.get("epitaph", ""))})
        out["fallen"] = dead
        var sheets: Array = []
        for id: String in r.heroes:
            var h: Dictionary = r.heroes[id]
            if bool(h.get("alive", false)):
                sheets.append(_sheet(r, h))
        sheets.sort_custom(func(a, b): return int(a["standing"]) > int(b["standing"]))
        out["heroes"] = sheets
    last_build_ms = (Time.get_ticks_usec() - t0) / 1000.0
    return out

func _town_block(e: Economy) -> Dictionary:
    if e == null:
        return {}
    return {"name": e.town_name, "level": e.town_level, "souls": e.population(),
        "day": e.day, "treasury": e.treasury, "renown": e.renown,
        "next_level_at": e.next_level_at(), "score": e.town_score()}

func _sheet(r: Roster, h: Dictionary) -> Dictionary:
    var stats := {}
    for k: String in Roster.STATS:
        stats[k] = int((h.get("stats", {}) as Dictionary).get(k, 10))
    var arm := int(h.get("armour", 0))
    return {
        "name": String(h.get("name", "?")), "class": String(h.get("class", "")),
        "species": Roster.species_of(h), "level": int(h.get("level", 1)), "xp": int(h.get("xp", 0)),
        "rank": r.rank_of(h), "standing": r.standing(h), "title": r.title_of(h),
        "ac": r.armour_class(h), "hp": int(r.max_hp(h)), "prof": r.prof(h),
        "to_hit": r.attack_bonus(h), "stats": stats, "saves": r.save_line(h),
        "weapon": {"name": r.weapon_name(h), "dice": r.dice_str(h), "tier": int(h.get("weapon", 0))},
        "armour": {"name": String(Roster.ARMOUR[clampi(arm, 0, Roster.ARMOUR.size() - 1)]["name"]), "tier": arm},
        "potions": int(h.get("potions", 0)), "brews": r.brews_line(h), "oil": int(h.get("oil", 0)),
        "gold": int(h.get("gold", 0)), "worn": r.worn_line(h),
        "kills": int(h.get("kills", 0)), "deepest": int(h.get("deepest", 0)), "delves": int(h.get("delves", 0)),
    }

# ---------------------------------------------------------------- the send

## One upsert, fire and forget. False when it could not even start (off, or one in flight).
func publish() -> bool:
    if not enabled or _http == null:
        return false
    if _busy:
        _note("busy", "SNAPSHOT: last publish still in flight - skipping this beat")
        return false
    var body := JSON.stringify([{"id": 1, "payload": build_payload(),
        "updated_at": Time.get_datetime_string_from_system(true) + "Z"}])
    last_bytes = body.length()
    var hd := PackedStringArray([
        "apikey: " + _key,
        "Authorization: Bearer " + _key,
        "Content-Type: application/json",
        "Prefer: resolution=merge-duplicates,return=minimal",
        "User-Agent: " + USER_AGENT,
    ])
    var err := _http.request(url + TABLE_PATH, hd, HTTPClient.METHOD_POST, body)
    if err != OK:
        failed += 1
        _note("start", "SNAPSHOT: request did not start (error %d)" % err)
        return false
    _busy = true
    return true

func _on_done(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    _busy = false
    last_code = code
    if result == HTTPRequest.RESULT_SUCCESS and code >= 200 and code < 300:
        sent += 1
        last_note = "ok"
        if sent == 1:
            print("SNAPSHOT: first publish ok (%d, %d bytes)" % [code, last_bytes])
    else:
        failed += 1
        var txt := body.get_string_from_utf8().left(300)
        last_note = "result %d code %d %s" % [result, code, txt]
        if code == 403 and txt.findn("browser") >= 0:
            _note("403b", "SNAPSHOT: 403 'secret key in browser' - the User-Agent is browser-like; it must stay " + USER_AGENT)
        else:
            _note("fail%d" % code, "SNAPSHOT: publish failed - " + last_note)
    published.emit(code)

## a warning printed once per kind, so a dead network does not flood the log
func _note(kind: String, text: String) -> void:
    if _warned.has(kind):
        return
    _warned[kind] = true
    push_warning(text)
