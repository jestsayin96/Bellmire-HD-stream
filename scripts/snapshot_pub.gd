class_name SnapshotPublisher
extends Node
## W1a: the viewer hub's data. Every EVERY s (15) ONE row of the Supabase table public.snapshot
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
const EVERY := 15.0                 # S168: 60 -> 15 s (team lead 23:58 row) - the hub's 15-30 s promise
const FIRST := 20.0                 # first beat after start: the roster and town are up
const TIMEOUT := 20.0
const USER_AGENT := "BellmireHD/1.0"
const ROLL_MAX := 50
const FALLEN_MAX := 50
## the Chronicle for the hub: the last CHRON_MAX lines of town.feed, newest first, each
## {t, s, at}. town.feed is append-only plain text, so the publisher keeps its own
## stamps: a line's "at" is when the publisher first saw it (scanned every second;
## lines already in the feed at start share the start time).
const CHRON_MAX := 50
const WHO_MAX := 4                  # D60: heroes named on one Chronicle row
const LINE_MAX := 200
const CHRON_TYPES := ["death", "raid", "loot", "delve", "town", "lore", "fight"]
## D57 - THE SATCHEL (hub H11). What the counter would pay a viewer for what their
## hero carries. The price curve is the counter's own, NOT a second opinion: the
## on-stream sell sheet (leaderboard_panel.gd Satchel.SELL_BACK) pays 0.4 of an
## item's buy cost, so the hub quotes the same number and the two can never disagree.
## `sell` is PER UNIT - the hub multiplies by qty itself.
const SELL_BACK := 0.4
## D59: v4 = the H20 sheet fields (initiative, speed, gear by slot, status, per-hero
## last_seen + events). Additive over v3. The hub's KNOWN_V took "4" in H23 (c19608c), so
## v4 ships. NEVER bump this past what web/app.js KNOWN_V accepts - the hub refuses an
## unknown number outright ("the page needs an update" instead of a town).
## H29.6: v5 = the shelves (shops[].stock), the caravan and the open orders, read from
## data/items.json (trade_stock / shop_stock / stock_retirement / caravan_manifests /
## trader_cargo). The hub's KNOWN_V took "5" in H29, so v5 ships. Additive over v4.
const PAYLOAD_V := 5
const SHELF_MAX := 60               # goods per shelf (the hub stops reading at 80)
const ORDERS_MAX := 40
const SATCHEL_MAX := 40             # the hub stops reading rows at 40
const NAME_MAX := 25                # W1a: every published name is capped here
## kind -> the hub's icon map (web/app.js SATCHEL_ICON). Only these words are sent;
## the kind SELECTS a whitelisted glyph on the hub and is never written into its DOM.
const SATCHEL_KINDS := ["weapon", "armour", "potion", "oil", "gold", "trinket", "loot", "gem"]

## first match wins, in this order (a delve's homecoming counts its gold and a trap's
## damage is the delve's, so those come before "loot" / "fight"; plain floor news after)
const CHRON_RULES := [
    ["death", ["is killed", "killed by", "cut down", "falls on floor", "keeps them all", "no one comes home",
               "slain", "laid to rest", "is buried", "burial", "!reroll", "perishes", "the fallen"]],
    ["raid", ["raider", "bandit", "raid", "boil out of", "the gates hold", "is burning", "mounted watch",
              "rides out", "torch", "rebuilt", "rebuild", "breach", "the attack"]],
    ["town", ["town level", "bellmire grows", "grows into", "falls back to", "souls live", "begins  ", "begins -",
              " begins", "settles", "sworn into", "takes the oath", "rises as", "reaches level", "joins the guild",
              "guild place", "market hall", "stables", "bathhouse", "mage tower", "the wall"]],
    ["delve", ["come home", "comes home", "descend", "sets out for", "the dungeon mouth", "trap", "steps on",
               "perception", "wild magic", "scar answers", "hands back", "lamp"]],
    ["loot", ["gold", "forge", "loot", "hoard", "treasury", "coffer", "wages", "caravan", "buys", "sells",
              "finds a", "salvaged", "turns up", "commissions", "brew", "drinks", "armour", "a vial"]],
    ["fight", ["rolls a 20", "falls to", "damage", "save", "goes down", "claws back", "enraged", "reels",
               "is gone", "comes round", "senseless", "stands back up", "initiative", "strikes", "hits ",
               "misses", "swings", "wounds", "fight", "kills"]],
    ["delve", ["floor", "the dungeon", "the dark below", " oil", "flask", "the party"]],
    ["lore", ["somewhere", "something", "the scar", "sings", "preach", "chapel", "tavern", "hammer", "the bell", "a bell",
              "remember", "the valley", "legend", "whisper", "they say", "song", "story", "old ", "dark"]],
]

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
var _chron: Array = []              # {t, s, at}, OLDEST first (the payload reverses it)
var _feed_seen := -1                # how many lines of town.feed are already stamped
var _scan_t := 0.0
static var _strip_re: RegEx = null

func setup(t: Node) -> void:
    town = t
    _commands = _load_commands()
    _load_key()
    if enabled:
        _load_mem()
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
    _scan_t -= delta
    if _scan_t <= 0.0:
        _scan_t = 1.0
        scan_feed()
    _hero_scan_t -= delta
    if _hero_scan_t <= 0.0:
        _hero_scan_t = 1.0
        scan_heroes()
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
        "v": PAYLOAD_V,         # see PAYLOAD_V (v4 the H20 sheet, v3 the Satchel, v2 `parties`)
        "game": "Bellmire HD",
        "generated_at": Time.get_datetime_string_from_system(true) + "Z",
        "town": _town_block(e),
        "guild_roll": [],
        "fallen": [],
        "heroes": [],
        "commands": _commands,
        "parties": _parties(),
        "chronicle": chronicle(),
        "rolls": _rolls(),
        "shops": [],
        "caravan": _caravan_block(),
        "orders": _orders(),
        "bags": [],
    }
    # H29.6: the hub reads p.shops at the TOP of the payload (web/app.js renderShops); the
    # town block's copy stays for anything that already reads it there.
    out["shops"] = (out["town"] as Dictionary).get("shops", [])
    if r:
        out["guild_roll"] = r.leaderboard("standing", ROLL_MAX)
        var dead: Array = []
        for f: Dictionary in r.fallen.slice(0, FALLEN_MAX):
            dead.append({"name": f.get("name", "?"), "class": f.get("class", ""),
                "level": int(f.get("level", 1)), "deepest": int(f.get("deepest", 0)),
                "kills": int(f.get("kills", 0)), "killed_by": String(f.get("killed_by", "")),
                "day": int(f.get("day", 0)), "epitaph": String(f.get("epitaph", ""))})
        out["fallen"] = dead
        out["bags"] = bags_block(r)
        var sheets: Array = []
        scan_heroes()
        var delv := _delvers()
        for id: String in r.heroes:
            var h: Dictionary = r.heroes[id]
            if bool(h.get("alive", false)):
                sheets.append(_sheet(r, h, id, delv))
        sheets.sort_custom(func(a, b): return int(a["standing"]) > int(b["standing"]))
        out["heroes"] = sheets
        out["rank_feed"] = r.rank_feed()   # S167 System 43: by_key ladder feed for hub + HUD
    last_build_ms = (Time.get_ticks_usec() - t0) / 1000.0
    return out

# ---------------------------------------------------------------- S162 the corpse-run bags

const BAGS_MAX := 40

## S162 (additive): System 33's skull markers - every corpse-run bag still on a floor, for the
## hub's dungeon map (RULING sup-nov27-0209). The owner's LOGIN is never published, only the
## hero's name. owner_left_s counts down the owner-only hour (0 once it is finders keepers);
## left_s counts down to the despawn. `open` is true once anyone may take it. Expired bags are
## left out (roster.take_bags sweeps them). An empty array until a hero falls below.
static func bags_block(r: Roster, now := -1) -> Array:
    var t := now if now >= 0 else int(Time.get_unix_time_from_system())
    var out: Array = []
    for bag: Dictionary in r.bags:
        var age := t - int(bag.get("t", t))
        if age >= Roster.BAG_LIFE_S:
            continue
        out.append({"name": clean_name(str(bag.get("name", "?"))), "floor": int(bag.get("floor", 0)),
            "gold": int(bag.get("gold", 0)), "potions": int(bag.get("potions", 0)), "oil": int(bag.get("oil", 0)),
            "owner_left_s": maxi(0, Roster.BAG_OWNER_S - age), "left_s": maxi(0, Roster.BAG_LIFE_S - age),
            "open": age >= Roster.BAG_OWNER_S})
        if out.size() >= BAGS_MAX:
            break
    return out

# ---------------------------------------------------------------- T5 the viewer's roll

const ROLLS_MAX := 20
const ROLL_RESULT_MAX := 400
const ROLL_TIERS := ["crit", "good", "mixed", "bad", "fumble"]

## T5: the town's d20 rolls for the hub's die and roll board (H9/H27), newest first, in the
## contract web/app.js normalizeRolls reads: n (1-20), by, what, result, cost, tier, at.
## ADDITIVE - an empty array until a viewer rolls, and the hub shows its honest empty state.
## by/what/result/cost are W1a-cleaned (control chars stripped, capped); tier is only ever
## one of the five words the hub's TIER_ALIAS whitelists.
func _rolls() -> Array:
    var out: Array = []
    var src = town.get("viewer_rolls") if town else null
    if typeof(src) != TYPE_ARRAY:
        return out
    for r in (src as Array).slice(0, ROLLS_MAX):
        if typeof(r) != TYPE_DICTIONARY:
            continue
        var d: Dictionary = r
        var row := {"n": clampi(int(d.get("n", 0)), 1, 20),
            "by": clean_name(str(d.get("by", ""))),
            "what": clean_line(str(d.get("what", ""))),
            "result": clean_line(str(d.get("result", "")), ROLL_RESULT_MAX),   # the hub reads 400 - never cut a verdict
            "cost": clean_name(str(d.get("cost", ""))),
            "at": str(d.get("at", ""))}
        var t := str(d.get("tier", ""))
        if ROLL_TIERS.has(t):
            row["tier"] = t
        out.append(row)
    return out

# ---------------------------------------------------------------- the bands below (D46)

const PARTY_MAX := 8
const MEMBER_MAX := 8

## Every delving party right now, for the hub's "Bands below": its name, the floor it is on and
## each member {name, class, hp, max_hp, status}. Read-only and plain data - the hub renders every
## string as text. status is "fallen" at 0 hp, else the first running state's word, else "ok".
func _parties() -> Array:
    var out: Array = []
    if town == null:
        return out
    for c in town.get_children():
        if out.size() >= PARTY_MAX:
            break
        if not (c is Delve):
            continue
        var d: Delve = c
        if d.party.is_empty() or d.dun == null or not is_instance_valid(d.dun):
            continue
        var members: Array = []
        var lead := ""
        for m: Dictionary in d.party:
            if members.size() >= MEMBER_MAX:
                break
            var h: Dictionary = m.get("h", {})
            var hp := maxf(0.0, float(m.get("hp", 0.0)))
            var mx := maxf(1.0, float(m.get("max", 1.0)))
            var status := "ok"
            if hp <= 0.0:
                status = "fallen"
            else:
                var sts: Array = d.statuses(m)
                if not sts.is_empty():
                    status = String(sts[0][0]).to_lower().strip_edges().left(20)
            var nm := String(h.get("name", "?")).left(40)
            if lead == "" and hp > 0.0:
                lead = nm
            members.append({"name": nm, "class": String(h.get("class", "")).left(24),
                "hp": int(ceil(hp)), "max_hp": int(ceil(mx)), "status": status})
        var band := "The town's band" if d.npc_party else ("%s's band" % lead if lead != "" else "Delvers")
        out.append({"name": band, "floor": int(d.floor_no), "members": members})
    return out

# ---------------------------------------------------------------- the Chronicle

## stamp the feed lines not seen yet (town.feed only ever grows)
func scan_feed() -> void:
    var feed = town.get("feed") if town else null
    if typeof(feed) != TYPE_ARRAY:
        return
    var n: int = (feed as Array).size()
    if _feed_seen < 0 or n < _feed_seen:
        _feed_seen = maxi(0, n - CHRON_MAX)
    if n == _feed_seen:
        return
    var at := Time.get_datetime_string_from_system(true) + "Z"
    var tags = town.get("feed_tags")
    var e: Economy = town.get("economy")
    for i in range(maxi(_feed_seen, n - CHRON_MAX), n):
        var raw := str(feed[i])
        var line := clean_line(raw)
        if line != "":
            var row := {"t": kind_of(line), "s": line, "at": at}
            _annotate(row, tags.get(raw, {}) if typeof(tags) == TYPE_DICTIONARY else {}, e)
            _chron.append(row)
    _feed_seen = n
    if _chron.size() > CHRON_MAX:
        _chron = _chron.slice(_chron.size() - CHRON_MAX)

## D60: a Chronicle row's `day`, `kind` and `who`, all ADDITIVE (a hub that does not know them
## renders the row exactly as before). `day` is the town's own day (economy.day): the day the
## raiser stamped when it tagged the line, else the day the publisher first saw it (scanned
## once a second, so the same day bar a line raised in the last second before midnight).
## `kind` and `who` come ONLY from a raiser's tag (town.tag_feed) - a line nobody tagged has
## neither, so the hub keeps its honest fallback (`t` and its name match). `who` is the hero
## names the hub shows, W1a-cleaned and capped like every other published name.
func _annotate(row: Dictionary, tag: Dictionary, e: Economy) -> void:
    if tag.has("day"):
        row["day"] = int(tag["day"])
    elif e != null:
        row["day"] = int(e.day)
    var k := String(tag.get("kind", "")).to_lower().strip_edges()
    if k != "" and k.length() <= 16 and k.is_valid_ascii_identifier():
        row["kind"] = k
    var who: Array = []
    for w in (tag.get("who", []) as Array):
        var nm := clean_name(str(w))
        if nm != "" and not who.has(nm) and who.size() < WHO_MAX:
            who.append(nm)
    if not who.is_empty():
        row["who"] = who

## the payload's chronicle: newest first, copies (the hub never edits ours)
func chronicle() -> Array:
    scan_feed()
    var out: Array = []
    for i in range(_chron.size() - 1, -1, -1):
        out.append((_chron[i] as Dictionary).duplicate())
    return out

## plain text for the hub: no control chars, no BBCode or angle brackets (it is not
## HTML), no long digit runs (a Twitch user id is 7+ digits; days, gold, floors are
## shorter), one line, at most LINE_MAX characters
static func clean_line(raw: String, cap := LINE_MAX) -> String:
    if _strip_re == null:
        _strip_re = RegEx.new()
        _strip_re.compile("[\\x00-\\x1F\\x7F]+")
    var s := _strip_re.sub(raw, " ", true)
    var bb := RegEx.new()
    bb.compile("\\[/?[a-zA-Z_]+(=[^\\]]*)?\\]")
    s = bb.sub(s, "", true)
    s = s.replace("<", "").replace(">", "")
    var ids := RegEx.new()
    ids.compile("\\d{7,}")
    s = ids.sub(s, "#", true)
    while s.contains("   "):
        s = s.replace("   ", "  ")
    s = s.strip_edges()
    if s.length() > cap:
        s = s.left(cap - 1).strip_edges() + "\u2026"
    return s

## W1a for a short published name: the same control-char strip as clean_line, no
## angle brackets or BBCode, one line, at most NAME_MAX characters. Item and potion
## names are lore text written by the content writer, so they are cleaned like any
## other string that leaves the game.
static func clean_name(raw: String) -> String:
    var s := clean_line(raw)
    if s.length() > NAME_MAX:
        s = s.left(NAME_MAX - 1).strip_edges() + "\u2026"
    return s

## one type per line, by keyword (CHRON_RULES, first match); unsure = "town"
static func kind_of(line: String) -> String:
    var l := line.to_lower()
    for rule in CHRON_RULES:
        for k in (rule[1] as Array):
            if l.contains(String(k)):
                return String(rule[0])
    return "town"

func _town_block(e: Economy) -> Dictionary:
    if e == null:
        return {}
    var out := {"name": e.town_name, "level": e.town_level, "souls": e.population(),
        "day": e.day, "treasury": e.treasury, "renown": e.renown,
        "next_level_at": e.next_level_at(), "score": e.town_score()}
    # D19b additions, all additive (payload v stays 1; the hub ignores what it
    # does not know): the hub only gets a number that is real.
    var rd = town.get("raids") if town else null
    if rd != null and rd.get("raids_turned") != null:
        out["raids_turned"] = int(rd.raids_turned)
    var dl = town.get("daylight") if town else null
    if dl != null and dl.has_method("day_phase"):
        out["day_phase"] = String(dl.day_phase())
        out["weather"] = String(dl.weather)
    # D64: each shop's level and the best rarity it may sell (additive; v unchanged)
    if e.has_method("shop_level"):
        out["shops"] = _shelves(e)
    return out

## H29.6: every shop open at the town's growth tier, with what is on its shelf RIGHT NOW.
## The shelf rule is the content writer's, verbatim from items.json trade_stock._note: a
## trade exists from its opens_tier; a good is on its shelf when max(good.tier, opens_tier)
## <= tier and the tier is not past the good's last_tier (stock_retirement / own last_tier).
## The smithy is the one shop with a LEVEL of its own (D64, viewers raise it): its card keeps
## that level and sells_to, and its shelf leads with the steel and armour the counter will
## actually sell at that level - so the smithy is listed even before its goods open at tier 3.
## Every other trade's shelf is governed by the town's growth tier, so that is its level.
func _shelves(e: Economy) -> Array:
    var tier := clampi(int(e.town_level), 1, 12)
    var it := Economy.items_data()
    var ss: Dictionary = it.get("shop_stock", {})
    var ret: Dictionary = (it.get("stock_retirement", {}) as Dictionary).get("shop_goods", {})
    var trades: Dictionary = (it.get("trade_stock", {}) as Dictionary).get("trades", {})
    var out: Array = []
    var have_smith := false
    for tk: String in trades:
        var t: Dictionary = trades[tk]
        var opens := int(t.get("opens_tier", 1))
        var smith := tk == "smith"
        if opens > tier and not smith:
            continue
        var goods: Array = []
        if opens <= tier:
            for key in (t.get("carries", []) as Array):
                var g: Variant = ss.get(String(key))
                if g is Dictionary:
                    var last := int((ret.get(String(key), {}) as Dictionary).get("last_tier", 12))
                    _shelf_add(goods, g, opens, tier, last, String(key))
            var own: Dictionary = t.get("own_goods", {})
            for key in own:
                var g2: Variant = own[key]
                if g2 is Dictionary:
                    _shelf_add(goods, g2, opens, tier, int((g2 as Dictionary).get("last_tier", 12)), String(key))
        # the newest goods first (what the town just grew into), then the cap
        goods.sort_custom(func(a, b): return int(a["_t"]) > int(b["_t"]) or (int(a["_t"]) == int(b["_t"]) and int(a["cost"]) < int(b["cost"])))
        goods = goods.slice(0, SHELF_MAX)
        for g3 in goods:
            (g3 as Dictionary).erase("_t")
        var row := {"name": clean_name(String(t.get("name", tk))), "level": tier, "stock": goods}
        if smith:
            have_smith = true
            row["level"] = e.shop_level("smithy")
            row["sells_to"] = e.shop_sells_to("smithy")
            row["stock"] = _smith_gear(e) + goods
        out.append(row)
    if not have_smith:
        out.push_front({"name": "Smithy", "level": e.shop_level("smithy"),
            "sells_to": e.shop_sells_to("smithy"), "stock": _smith_gear(e)})
    return out

## D99: stock_by_tier gates it too - a key the content writer listed at a later growth tier is
## not on the shelf yet, whatever its own tier says ("a crossing must not sell glass").
static func _shelf_add(goods: Array, g: Dictionary, opens: int, tier: int, last: int, key := "") -> void:
    if Economy.never_stocked(g):
        return
    var first := maxi(maxi(int(g.get("tier", 1)), opens), Economy.stock_first_tier(key))
    if first > tier or tier > last:
        return
    goods.append({"name": clean_name(String(g.get("name", "?"))), "cost": maxi(0, int(g.get("cost", 0))), "_t": first})

## what the counter will forge at the smithy's level, at list price (a hero's haggle can
## only lower it). Found-only tiers are never on a shelf.
func _smith_gear(e: Economy) -> Array:
    var rows: Array = []
    var cap := e.shop_cap("smithy")
    for pair in [[Roster.WEAPONS, "steel"], [Roster.ARMOUR, "armour"]]:
        var table: Array = pair[0]
        for i in range(1, mini(cap, table.size() - 1) + 1):
            var w: Dictionary = table[i]
            if bool(w.get("found", false)):
                continue
            var nm := String(w["name"]) + (" steel" if String(pair[1]) == "steel" and not String(w["name"]).ends_with("steel") else (" armour" if String(pair[1]) == "armour" else ""))
            rows.append({"name": clean_name(nm.left(1).to_upper() + nm.substr(1)),
                "cost": int(w["cost"]), "rarity": Economy.rarity_of(i)})
    return rows

## H29.6: the caravan in town, if one is - {present, leaves_in?, name?, cargo[]}. Cargo is the
## content writer's manifest (items.json caravan_manifests -> trader_cargo) picked when the
## wagon was spawned; leaves_in is whole minutes, given only while it stands trading.
func _caravan_block() -> Dictionary:
    var cs: Variant = town.get("_caravans") if town else null
    if not (cs is Array):
        return {"present": false, "cargo": []}
    for c in (cs as Array):
        if not (c is Dictionary) or String(c.get("phase", "")) == "out":
            continue
        var out := {"present": true, "cargo": []}
        if String(c.get("phase", "")) == "trade":
            out["leaves_in"] = maxi(1, ceili(float(c.get("t", 0.0)) / 60.0))
        var it := Economy.items_data()
        var tc: Dictionary = it.get("trader_cargo", {})
        var ctier := clampi(int(town.economy.town_level), 1, 12) if town and town.get("economy") else 12
        for m in ((it.get("caravan_manifests", {}) as Dictionary).get("caravans", []) as Array):
            if m is Dictionary and String(m.get("id", "")) == String(c.get("manifest", "")) and String(c.get("manifest", "")) != "":
                out["name"] = clean_name(String(m.get("name", "")))
                for line in (m.get("cargo", []) as Array):
                    var gk := String((line as Dictionary).get("good", ""))
                    var g: Variant = tc.get(gk)
                    # D99: stock_by_tier cargo_adds - a wagon does not carry what the town has not grown into
                    if g is Dictionary and Economy.stock_open(gk, ctier, "cargo_adds") and not Economy.never_stocked(g):
                        out["cargo"].append({"name": clean_name(String(g.get("name", "?"))),
                            "cost": maxi(0, int(g.get("cost", 0))), "qty": maxi(1, int(line.get("qty", 1)))})
                break
        return out
    return {"present": false, "cargo": []}

## H29.6: open orders - a purchase made at the counter whose hero is still walking to the
## yard to collect it (town.gd shop_orders). `who` is the hero's name, which is the viewer's
## display name; the hub marks the rows whose `who` is the signed-in login as "yours".
func _orders() -> Array:
    var out: Array = []
    var so: Variant = town.get("shop_orders") if town else null
    var hs: Variant = town.get("heroes") if town else null
    if not (so is Dictionary) or not (hs is Dictionary):
        return out
    var r: Roster = town.get("roster")
    for uid in (so as Dictionary):
        var b = (hs as Dictionary).get(uid)
        if b == null or not is_instance_valid(b) or String(b.get("errand")) == "":
            continue
        var o: Dictionary = so[uid]
        var nm := clean_name(String(r.get_hero(uid).get("name", ""))) if r else ""
        out.append({"who": nm, "item": clean_name(String(o.get("item", ""))),
            "shop": clean_name(String(o.get("shop", "Smithy"))), "walker": nm, "status": "walking"})
        if out.size() >= ORDERS_MAX:
            break
    return out

## D57: one hero's sell sheet for the hub's Satchel (H11). Plain data, no new fetch,
## nothing invented - a row only exists for something the hero actually carries, and a
## price only for something the counter actually buys back. Mirrors the on-stream sheet:
## mending, brews, oil, then gear owned but not worn; the stated total is the purse the
## counter would hand over for the lot, worn pieces included.
## Returns {"rows": [{name, kind, qty, sell}], "total": int, "sellable": [{kind, qty}],
## "prices": [int]} - `sellable`/`prices` are the parallel-array form of the same rows.
func _satchel(h: Dictionary) -> Dictionary:
    var rows: Array = []
    var add := func(nm: String, kind: String, qty: int, sell: int) -> void:
        if qty <= 0 or rows.size() >= SATCHEL_MAX:
            return
        var k := kind if SATCHEL_KINDS.has(kind) else "loot"
        rows.append({"name": clean_name(nm), "kind": k, "qty": qty, "sell": maxi(0, sell)})

    # draughts and light: the counter pays the same 0.4 on these as on gear
    add.call("Mending draught", "potion", int(h.get("potions", 0)),
        int(floorf(float(Roster.POTION_COST) * SELL_BACK)))
    for bk: String in (h.get("brews", {}) as Dictionary):
        var pot := Roster.potion(bk)
        add.call(String(pot.get("name", bk)), "potion", int(h["brews"][bk]),
            int(floorf(float(pot.get("cost", 0)) * SELL_BACK)))
    add.call("Flask of lamp oil", "oil", int(h.get("oil", 0)),
        int(floorf(float(Roster.OIL_COST) * SELL_BACK)))

    # what is worn stays out of the spare list (it is in the stated total instead)
    var worn: Dictionary = {}
    for slot in (h.get("acc", {}) as Dictionary):
        worn[String(h["acc"][slot])] = true
    for kind in (h.get("cos", {}) as Dictionary):
        if String(kind) != "dye":
            worn[String(h["cos"][kind])] = true

    var purse := 0                      # every owned piece, worn included
    for key in (h.get("owned", []) as Array):
        var it := Roster.item(String(key))
        var v := int(floorf(float(it.get("cost", 0)) * SELL_BACK))
        purse += v
        if worn.has(String(key)):
            continue
        add.call(String(it.get("name", key)), "trinket", 1, v)

    # the stated total is everything the counter would take: the rows above plus the
    # worn pieces that never got a row of their own.
    var total := purse
    for row: Dictionary in rows:
        if String(row["kind"]) != "trinket":
            total += int(row["sell"]) * int(row["qty"])

    var sellable: Array = []
    var prices: Array = []
    for row: Dictionary in rows:
        sellable.append({"kind": String(row["kind"]), "qty": int(row["qty"])})
        prices.append(int(row["sell"]))
    return {"rows": rows, "total": total, "sellable": sellable, "prices": prices}

func _sheet(r: Roster, h: Dictionary, id := "", delv: Dictionary = {}) -> Dictionary:
    var stats := {}
    for k: String in Roster.STATS:
        stats[k] = int((h.get("stats", {}) as Dictionary).get(k, 10))
    var arm := int(h.get("armour", 0))
    var wt := clampi(int(h.get("weapon", 0)), 0, Roster.WEAPONS.size() - 1)
    var at := clampi(arm, 0, Roster.ARMOUR.size() - 1)
    var sat := _satchel(h)
    # the counter's price for what they are wearing. Omitted (not zeroed) at tier 0:
    # the hub only lists a worn piece once it has a price, so bare hands and rags
    # stay out of the sell sheet instead of quoting "0 gold".
    var wsell := int(floorf(float(Roster.WEAPONS[wt].get("cost", 0)) * SELL_BACK))
    var asell := int(floorf(float(Roster.ARMOUR[at].get("cost", 0)) * SELL_BACK))
    var wblock := {"name": r.weapon_name(h), "dice": r.dice_str(h), "tier": int(h.get("weapon", 0))}
    if wsell > 0:
        wblock["sell"] = wsell
        sat["total"] = int(sat["total"]) + wsell
    var ablock := {"name": r.armour_name(h), "tier": arm}
    if asell > 0:
        ablock["sell"] = asell
        sat["total"] = int(sat["total"]) + asell
    var row := {
        "name": String(h.get("name", "?")), "class": String(h.get("class", "")),
        "species": Roster.species_of(h), "level": int(h.get("level", 1)), "xp": int(h.get("xp", 0)),
        # S157 (additive): System 40's hub half. `spec` is the path STEM ("guardian"), "" until the
        # hero specializes; `spec_name` is its display name ("Guardian"), "" until then. Both come
        # straight off Roster.spec_of / spec_row - one source, so an invalid stored spec reads "".
        "spec": Roster.spec_of(h), "spec_name": String(Roster.spec_row(h).get("name", "")),
        "rank": r.rank_of(h), "standing": r.standing(h), "title": r.title_of(h),
        # S167 (additive): System 43's S-F letter beside the guild-roll title above.
        "letter": r.letter_rank(h), "letter_score": r.letter_score(h),
        "ac": r.armour_class(h), "hp": int(r.max_hp(h)), "max_hp": int(r.max_hp(h)),
        "xp_next": int(r._xp_needed(int(h.get("level", 1)))), "prof": r.prof(h),
        "to_hit": r.attack_bonus(h), "stats": stats, "saves": r.save_line(h),
        "weapon": wblock, "armour": ablock,
        "potions": int(h.get("potions", 0)), "brews": r.brews_line(h), "oil": int(h.get("oil", 0)),
        "gold": int(h.get("gold", 0)), "worn": r.worn_line(h),
        "kills": int(h.get("kills", 0)), "deepest": int(h.get("deepest", 0)), "delves": int(h.get("delves", 0)),
        # S162 (additive): the death model's hero-card half (RULING sup-nov27-0209). dur_* are
        # 0-100 (missing = 100, new), `deaths` is the fall counter - "Fell 47 times. Still here."
        # repair is the smithy's price to mend both, after the guild's rate; 0 = nothing to mend.
        "dur_weapon": r.durability(h, "weapon"), "dur_armour": r.durability(h, "armour"),
        "deaths": int(h.get("deaths", 0)), "repair": int(Economy.repair_quote(r, h)["total"]),
        # D57 (v3, additive): the Satchel. `satchel` is what the hub renders; `sellable`
        # and `sell_prices` are the same rows as parallel arrays for any other client.
        # An older hub ignores all three and draws the sheet exactly as before.
        "satchel": sat["rows"], "satchel_total": int(sat["total"]),
        "sellable": sat["sellable"], "sell_prices": sat["prices"],
    }
    # S89 (additive): mana for the hub's character sheet (web/app.js manaBar reads h.mana /
    # h.mana_max) - Mr. E's 10:17 directive, option A, took the floating strip off the game view.
    # Roster computes it (mana_max / the stored pool); non-casters publish 0 and the hub
    # draws nothing, which is its documented behaviour.
    # Read without writing: mana_of() stores into the hero dict, and a publisher must not.
    var mmx := r.mana_max(h)
    row["mana"] = int(floor(clampf(float(h.get("mana", mmx)), 0.0, mmx)))
    row["mana_max"] = int(round(mmx))
    # D59 (v4, additive): the rest of H20's sheet, only what the game computes.
    # initiative = the bonus delve.gd/raids.gd add to their d20 (DEX mod);
    # speed = the hero's own move speed in the game (m/s, Roster.speed).
    row["initiative"] = r.mod(h, "dex")
    row["speed"] = snappedf(r.speed(h), 0.1)
    row["gear"] = _gear(r, h)
    row["status"] = _status(id, delv)
    if delv.has(id):        # below, the sheet's HP is the party's live HP
        row["hp"] = int(delv[id]["hp"])
        row["max_hp"] = int(delv[id]["max"])
    var m: Dictionary = _mem.get(id, {})
    if String(m.get("seen", "")) != "":
        row["last_seen"] = String(m["seen"])
    var ev: Array = []
    for e: Dictionary in (m.get("ev", []) as Array):
        ev.append(e.duplicate())
    row["events"] = ev
    return row

# ---------------------------------------------------------------- D59: the character sheet (hub H20)

## v4, additive. What H20's sheet asks for that the game ALREADY knows, and nothing it
## does not: no off-hand (the class's shield / book / quiver is a model, not an item the
## game names), no background, alignment, skills, spells or hit dice (no such systems).
## acc slot -> the sheet's slot key; `hat` is the one cosmetic that sits in a body slot
const GEAR_SLOT := {"gloves": "hands", "boots": "feet", "cloak": "cloak", "amulet": "neck", "ring": "ring"}
const EVENT_MAX := 6                # per hero, newest first
const EVENT_LINE := 90
const MEM_FILE := "user://snapshot_heroes.json"
var mem_file := MEM_FILE            # tests point this elsewhere
var _mem: Dictionary = {}           # user_id -> {"sig": {...}, "seen": iso or "", "ev": [{t, s, at}]}
var _mem_seeded := false
var _hero_scan_t := 0.0

## what a hero is wearing, keyed the way H20 draws it. Only the slots that are real;
## an empty slot is OMITTED (the hub draws it empty, which is the truth).
func _gear(r: Roster, h: Dictionary) -> Dictionary:
    var g := {}
    if int(h.get("weapon", 0)) > 0:
        g["main_hand"] = clean_name(r.weapon_name(h))
    var at := clampi(int(h.get("armour", 0)), 0, Roster.ARMOUR.size() - 1)
    g["body"] = clean_name(r.armour_name(h))
    var acc: Dictionary = h.get("acc", {})
    for slot in acc:
        if GEAR_SLOT.has(String(slot)):
            var nm := String(Roster.item(String(acc[slot])).get("name", ""))
            if nm != "":
                g[GEAR_SLOT[String(slot)]] = clean_name(nm)
    var cos: Dictionary = h.get("cos", {})
    if cos.has("hat"):
        var hn := String(Roster.item(String(cos["hat"])).get("name", ""))
        if hn != "":
            g["head"] = clean_name(hn)
    return g

## every hero in a delving party right now: user_id -> {hp, max, status}
func _delvers() -> Dictionary:
    var out := {}
    if town == null:
        return out
    for c in town.get_children():
        if not (c is Delve):
            continue
        var d: Delve = c
        if d.party.is_empty():
            continue
        for m: Dictionary in d.party:
            var h: Dictionary = m.get("h", {})
            var id := String(h.get("id", ""))
            if id == "":
                continue
            var hp := maxf(0.0, float(m.get("hp", 0.0)))
            var mx := maxf(1.0, float(m.get("max", 1.0)))
            var st := "delving"
            if hp <= 0.0:
                st = "fallen"
            elif hp < mx:
                st = "wounded"
            out[id] = {"hp": int(ceil(hp)), "max": int(ceil(mx)), "status": st}
    return out

## the state the game already holds: in a delving party (delving / wounded / fallen),
## else walking the town ("in town"). Nothing else is claimed.
static func _status(id: String, delv: Dictionary) -> String:
    if delv.has(id):
        return String(delv[id]["status"])
    return "in town"

func _sig(r: Roster, h: Dictionary, st: String) -> Dictionary:
    return {"level": int(h.get("level", 1)), "xp": int(h.get("xp", 0)), "gold": int(h.get("gold", 0)),
        "kills": int(h.get("kills", 0)), "deepest": int(h.get("deepest", 0)), "delves": int(h.get("delves", 0)),
        "weapon": int(h.get("weapon", 0)), "armour": int(h.get("armour", 0)),
        "potions": int(h.get("potions", 0)), "oil": int(h.get("oil", 0)),
        "owned": (h.get("owned", []) as Array).duplicate(), "status": st}

func _event(m: Dictionary, kind: String, text: String, at: String) -> void:
    var s := clean_line(text)
    if s.length() > EVENT_LINE:
        s = s.left(EVENT_LINE - 1).strip_edges() + "…"
    var ev: Array = m.get("ev", [])
    ev.push_front({"t": kind, "s": s, "at": at})
    if ev.size() > EVENT_MAX:
        ev.resize(EVENT_MAX)
    m["ev"] = ev

## once a second: compare every living hero with what we saw last. A change of any
## tracked number stamps their last-seen; the changes that are news become their own
## events. Heroes present at the very first scan are seeded silently (no invented past).
func scan_heroes() -> void:
    var r: Roster = town.get("roster") if town else null
    if r == null:
        return
    var at := Time.get_datetime_string_from_system(true) + "Z"
    var delv := _delvers()
    var live := {}
    for id: String in r.heroes:
        var h: Dictionary = r.heroes[id]
        if not bool(h.get("alive", false)):
            continue
        live[id] = true
        var st := _status(id, delv)
        var now := _sig(r, h, st)
        if not _mem.has(id):
            _mem[id] = {"sig": now, "seen": "", "ev": []}
            if _mem_seeded:
                _mem[id]["seen"] = at
                _event(_mem[id], "enlist", "Enlisted: %s %s." % [Roster.species_of(h), String(h.get("class", ""))], at)
            continue
        var m: Dictionary = _mem[id]
        var was: Dictionary = m["sig"]
        if was == now:
            continue
        m["seen"] = at
        if int(now["level"]) > int(was.get("level", 1)):
            _event(m, "level", "Reached level %d." % int(now["level"]), at)
        if int(now["deepest"]) > int(was.get("deepest", 0)):
            _event(m, "depth", "New deepest: floor %d." % int(now["deepest"]), at)
        if int(now["delves"]) > int(was.get("delves", 0)):
            var k := int(now["kills"]) - int(was.get("kills", 0))
            _event(m, "delve", "Came home from a delve with %d kill%s." % [k, "" if k == 1 else "s"], at)
        if int(now["weapon"]) > int(was.get("weapon", 0)):
            _event(m, "gear", "Took up %s." % r.weapon_name(h), at)
        if int(now["armour"]) > int(was.get("armour", 0)):
            var an := r.armour_name(h)
            _event(m, "gear", "Now wears %s." % an, at)
        var had: Array = was.get("owned", [])
        for key in (now["owned"] as Array):
            if not had.has(key):
                _event(m, "find", "Got %s." % String(Roster.item(String(key)).get("name", key)), at)
        if String(now["status"]) != String(was.get("status", "")) and String(now["status"]) == "delving" \
                and String(was.get("status", "")) == "in town":
            _event(m, "delve", "Went down into the dungeon.", at)
        m["sig"] = now
    for id in _mem.keys():
        if not live.has(id):
            _mem.erase(id)          # fallen or gone: the fallen row carries their end
    _mem_seeded = true

func _load_mem() -> void:
    if not FileAccess.file_exists(mem_file):
        return
    var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(mem_file))
    if typeof(j) != TYPE_DICTIONARY or typeof(j.get("heroes")) != TYPE_DICTIONARY:
        return
    for id in j["heroes"]:
        var m: Variant = j["heroes"][id]
        if typeof(m) != TYPE_DICTIONARY or typeof(m.get("sig")) != TYPE_DICTIONARY:
            continue
        var sig: Dictionary = m["sig"]
        for k in sig:       # JSON brings numbers back as floats; the sig compares ints
            if typeof(sig[k]) == TYPE_FLOAT:
                sig[k] = int(sig[k])
        _mem[String(id)] = {"sig": sig, "seen": String(m.get("seen", "")),
            "ev": (m.get("ev", []) as Array).slice(0, EVENT_MAX)}
    _mem_seeded = true      # a remembered roster: heroes new since then are news

func save_mem() -> void:
    var f := FileAccess.open(mem_file, FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify({"v": 1, "heroes": _mem}))

# ---------------------------------------------------------------- the send

## One upsert, fire and forget. False when it could not even start (off, or one in flight).
func publish() -> bool:
    if not enabled or _http == null:
        return false
    if _busy:
        _note("busy", "SNAPSHOT: last publish still in flight - skipping this beat")
        return false
    save_mem()
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
