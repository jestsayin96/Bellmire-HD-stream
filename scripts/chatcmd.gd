## PORTED VERBATIM from the old game (trial-and-error, read only). Pure data + rules, no Twitch connection.
class_name ChatCmd
extends Node

# Parses viewer chat into actions on the Roster.
#
# NOTE ON REPLIES: anonymous IRC is read-only. Without a token the game cannot
# post back into Twitch chat, so every response here is returned as a line for
# the ON-SCREEN event feed. That is the right place for a stream overlay
# anyway - viewers are watching the stream, not the chat scrollback.
#
# Verbs deliberately avoid fightoverlay's (!join !shop !buy !points
# !leaderboard !avatar !duel !give !slots !boss !royale) so both can run on the
# same channel without every command firing twice.

signal say(line: String, colour: Color)
signal wants_delve(user_id: String)
signal wants_fish(user_id: String)
signal wants_shop(user_id: String, kind: String)
## T1 contract (supervisor, Nov 12): every answer a viewer's command produces, PLAIN - no "@name ",
## no rate limit, no sending. The desktop's twitch_eventsub.gd connects here and owns the queue,
## the rate limit, the prefix and the API call. Not emitted for Mr. E's local keyboard (local_*).
## Do not change this signature without telling the desktop.
signal twitch_reply(user_login: String, text: String)

const COOLDOWN := 1.5          # seconds per viewer, anti-spam
const QUEUE_MAX := 6

const C_OK := Color(0.72, 0.95, 0.76)
const C_INFO := Color(0.80, 0.88, 1.00)
const C_WARN := Color(1.00, 0.72, 0.42)
const C_DEAD := Color(1.00, 0.45, 0.38)

var roster: Roster
var delve_queue: Array = []
## where a hero is while the town has them on the scar road or below it; an
## errand command is refused rather than dragging them off (set by the town)
var away := {}
## the town hands chat the fishing log: name -> [{name, rarity, value}]
var catches_of: Callable
## L17: the spotlight hands chat its put(uid, lane, seconds, reason) -> line (set by Spotlight.setup)
var spot: Callable
## T1: the eventsub hands chat its _do_bits_tier(uid, bits) so !testbits fires town-wide effects
var bits_tier_fn: Callable
## L18: when each viewer last used a command (Time ticks, ms) - the director favours
## the freshest chatters and their name glows for a few seconds (HeroBody.glow)
static var last_cmd := {}

## seconds since this viewer's last command (INF if never)
static func since_cmd(uid: String) -> float:
    if not last_cmd.has(uid):
        return INF
    return float(Time.get_ticks_msec() - int(last_cmd[uid])) / 1000.0

## what a hero has on them: steel, armour, potions, oil, gold, and the fish
func inventory(user_id: String) -> String:
    var h := roster.get_hero(user_id)
    if h.is_empty():
        return "No hero yet - type !enlist to join the valley."
    var armour := String(Roster.ARMOUR[int(h["armour"])]["name"])
    var worn := roster.worn_line(h)
    var title := roster.title_of(h)
    var line := "%s%s carries %s and wears %s%s  |  %s, %d oil, %d gold" % [
        h["name"], (", " + title) if title != "" else "", roster.weapon_name(h), armour, (" + " + worn) if worn != "" else "", roster.brews_line(h), int(h.get("oil", 0)), int(h.get("gold", 0))]
    if catches_of.is_valid():
        var cs: Array = catches_of.call(String(h["name"]))
        if not cs.is_empty():
            var best: Dictionary = cs[0]
            var order := ["junk", "common", "uncommon", "rare", "epic", "legendary"]
            for x in cs:
                if order.find(String(x.get("rarity", ""))) > order.find(String(best.get("rarity", ""))):
                    best = x
            line += "  |  %d catch%s, best: %s (%s)" % [cs.size(), "" if cs.size() == 1 else "es", best.get("name"), best.get("rarity")]
    return line
var _last := {}                # user_id -> msec of last accepted command
var _seen_names := {}

func _init(r: Roster = null) -> void:
    roster = r

## `login` is the viewer's Twitch login for twitch_reply; left out, the display name lowercased
## stands in (the same for every plain-letters name - pass the login for the rest)
func handle(user_id: String, display: String, msg: String, login := "") -> String:
    if roster == null:
        return ""
    msg = msg.strip_edges()
    if not msg.begins_with("!"):
        return ""
    var now := Time.get_ticks_msec()
    if now - int(_last.get(user_id, -99999)) < int(COOLDOWN * 1000.0):
        return ""
    var parts := msg.substr(1).split(" ", false)
    if parts.is_empty():
        return ""
    var verb := canonical(String(parts[0]).to_lower())
    var arg := String(parts[1]).to_lower() if parts.size() > 1 else ""
    var arg2 := String(parts[2]).to_lower() if parts.size() > 2 else ""
    var rest := " ".join(parts.slice(1)).to_lower()

    # viewers rename themselves; keep the display name current
    var h := roster.get_hero(user_id)
    if not h.is_empty() and display != "" and h["name"] != display:
        h["name"] = display

    var out := ""
    var gold0 := int(h.get("gold", 0)) if not h.is_empty() else -1      # S3: money that moves chinks
    if verb in ["fish", "forge", "armoury", "armory", "brew", "wear", "dye"] and away.has(user_id) and not h.is_empty():
        _last[user_id] = now
        last_cmd[user_id] = now
        return _reply(user_id, display, login, "%s is %s." % [h["name"], away[user_id]])
    match verb:
        "enlist":   out = _enlist(user_id, display, arg, arg2)
        "hero":     out = _needs(user_id, func(): return roster.describe(user_id))
        "inventory", "inv", "bag", "items":
                    out = _needs(user_id, func(): return inventory(user_id))
        "delve":    out = _delve(user_id)
        "fish":     out = _needs(user_id, func():
                        wants_fish.emit(user_id)
                        return "%s heads for the docks with a rod." % roster.get_hero(user_id)["name"])
        "forge":    out = _needs(user_id, func():
                        if arg in ["list", "kinds", "?", "menu"]:
                            return roster.forge_menu(user_id)
                        wants_shop.emit(user_id, "blacksmith")
                        return roster.buy_weapon(user_id, arg))
        "armoury", "armory":
                    out = _needs(user_id, func():
                        wants_shop.emit(user_id, "armorer")
                        return roster.buy_armour(user_id))
        "brew":     out = _brew(user_id, arg, arg2)
        "wear":     out = _needs(user_id, func(): return roster.wear(user_id, rest))
        "dye":      out = _needs(user_id, func(): return roster.dye(user_id, arg))
        "oil", "lamp", "torch":
                    out = _oil(user_id, arg)
        "reroll":   out = _reroll(user_id, display)
        "respec":   out = _needs(user_id, func(): return roster.respec(user_id, arg))
        "memorial": out = _memorial()
        "deepest":  out = _board("deepest")
        "richest":  out = _board("gold")
        "guild", "ranks":
                    out = _board("standing")
        "deadliest": out = _board("kills")
        "patrons", "benefactors":
                    out = _patrons()
        "help":     out = help_line(arg)
        "look":     out = _needs(user_id, func(): return _spot(user_id, "look", 0.0, ""))
        "testbits", "testsub", "testpoints":
                    # L17 test-only: the local chat box (Mr. E's keyboard) fakes a cheer / sub / redeem.
                    # Twitch users never reach these (their ids are not local_*); T1's EventSub calls the API.
                    if not user_id.begins_with("local_"):
                        return ""
                    out = _test_spot(user_id, verb, arg, arg2)
        _:
            # L14: a near miss of a real command gets a nudge, anything else is left alone (other bots)
            var guess := _closest(verb)
            if guess == "":
                return ""
            out = "No !%s here - did you mean !%s? (!help lists them all)" % [verb, guess]

    _last[user_id] = now
    last_cmd[user_id] = now
    if out != "":
        say.emit(out, _tone(out))
        _ui_snd(verb, out, _gold_moved(user_id, gold0))
    return _reply(user_id, display, login, out)

## T1: hand a command's answer to Twitch chat (via the desktop's twitch_eventsub.gd)
func _reply(user_id: String, display: String, login: String, out: String) -> String:
    if out != "" and not user_id.begins_with("local_"):
        twitch_reply.emit(login if login != "" else display.to_lower(), out)
    return out

# a command that requires a living hero
func _needs(user_id: String, fn: Callable) -> String:
    if roster.get_hero(user_id).is_empty():
        return "No hero yet - type !enlist to join the valley."
    if not roster.is_alive(user_id):
        return "%s is dead. !reroll to raise a new hero." % roster.get_hero(user_id)["name"]
    return String(fn.call())

## L17: a spotlight pane on a hero (the Spotlight sets `spot`; without it, nothing)
func _spot(uid: String, lane: String, secs: float, why: String) -> String:
    if not spot.is_valid():
        return "The spotlight is not lit yet."
    return String(spot.call(uid, lane, secs, why))

## !testbits <n> [name] / !testsub [name] / !testpoints [name]: the named hero (or your own)
func _test_spot(user_id: String, verb: String, arg: String, arg2: String) -> String:
    var who := arg2 if verb == "testbits" else arg
    var uid := user_id
    if who != "":
        uid = ""
        for k in roster.heroes:
            if String(roster.heroes[k].get("name", "")).to_lower() == who:
                uid = k
                break
        if uid == "":
            return "No hero named %s." % who
    match verb:
        "testbits":
            var n := maxi(1, int(arg)) if arg.is_valid_int() else 100
            if bits_tier_fn.is_valid():
                bits_tier_fn.call(uid, n)
            return _spot(uid, "bits", Spotlight.bits_seconds(n), "cheered %d bits" % n)
        "testsub":
            return _spot(uid, "subs", Spotlight.SUB_S, "subscribed")
        _:
            return _spot(uid, "points", Spotlight.POINTS_S, "redeemed Spotlight")

func _enlist(user_id: String, display: String, cls: String, species := "") -> String:
    # L5: !enlist <class> <species>, either way round ("!enlist dwarf knight" too)
    if Roster.SPECIES.has(cls) and (species == "" or Roster.CLASSES.has(species)):
        var t := cls
        cls = species
        species = t
    if species != "" and not Roster.SPECIES.has(species):
        return "No such people in the valley. Try: %s." % ", ".join(Roster.SPECIES.keys())
    var h := roster.get_hero(user_id)
    if not h.is_empty() and roster.is_alive(user_id):
        return roster.describe(user_id)
    if not h.is_empty():
        return "%s lies in the memorial. !reroll to raise a new hero." % h["name"]
    if display == "":
        display = "Stranger"
    var nh := roster.fresh(user_id, display, cls, species)
    var sp := Roster.species_of(nh)
    return "%s takes the oath as %s %s %s (%s). %s" % [nh["name"], "an" if sp in ["elf", "orc"] else "a", sp,
        nh["class"], Roster.SPECIES[sp]["blurb"], Roster.CLASSES[nh["class"]]["blurb"]]

func _delve(user_id: String) -> String:
    var gate := _needs(user_id, func(): return "ok")
    if gate != "ok":
        return gate
    if user_id in delve_queue:
        return "%s is already waiting at the dungeon mouth." % roster.get_hero(user_id)["name"]
    if delve_queue.size() >= QUEUE_MAX:
        return "The muster is full - %s waits for the next party." \
            % roster.get_hero(user_id)["name"]
    delve_queue.append(user_id)
    wants_delve.emit(user_id)
    return "%s sets out for the dungeon mouth. (%d in the party)" \
        % [roster.get_hero(user_id)["name"], delve_queue.size()]

# Oil is the cheapest thing on the board and the one most worth buying. A
# viewer who keeps three flasks in the satchel will out-live a better-armed
# hero who descends with none.
func _oil(user_id: String, arg: String) -> String:
    var n := 1
    if arg != "" and arg.is_valid_int():
        n = clampi(int(arg), 1, 10)
    return _needs(user_id, func(): return roster.buy_oil(user_id, n))

func _brew(user_id: String, arg: String, arg2 := "") -> String:
    # L12: !brew [n] buys Mending as before; !brew <potion> [n] any brew the apothecary makes
    var n := 1
    var key := "mending"
    if arg != "" and arg.is_valid_int():
        n = clampi(int(arg), 1, 10)
    elif arg != "":
        key = Roster.potion_key(arg)
        if arg2 != "" and arg2.is_valid_int():
            n = clampi(int(arg2), 1, 10)
        if key == "":
            return _needs(user_id, func(): return roster.buy_brew(user_id, arg, n))
    if key == "mending":
        return _needs(user_id, func(): return roster.buy_potion(user_id, n))
    return _needs(user_id, func(): return roster.buy_brew(user_id, key, n))

# !reroll does double duty: raise a new hero if dead, reroll stats if alive
func _reroll(user_id: String, display: String) -> String:
    var h := roster.get_hero(user_id)
    if h.is_empty():
        return "No hero yet - type !enlist to join the valley."
    if not roster.is_alive(user_id):
        roster.heroes.erase(user_id)
        var nh := roster.fresh(user_id, display if display != "" else String(h["name"]))
        return "%s rises as a %s. The valley remembers the last one." \
            % [nh["name"], nh["class"]]
    return roster.reroll(user_id)

func _memorial() -> String:
    if roster.fallen.is_empty():
        return "Nobody has died yet. Give it time."
    var bits := []
    for f: Dictionary in roster.fallen.slice(0, 5):
        bits.append("%s (lv%d, floor %d)" % [f["name"], int(f["level"]), int(f["deepest"])])
    var ep := String((roster.fallen[0] as Dictionary).get("epitaph", ""))
    return "The fallen: " + "  -  ".join(bits) + ("  |  %s: %s" % [roster.fallen[0]["name"], ep] if ep != "" else "")

# A thank-you board, deliberately separate from the achievement boards.
func _patrons() -> String:
    var rows := roster.patron_board(5)
    if rows.is_empty():
        return "Nobody has given to the valley yet."
    var bits := []
    var i := 0
    for row: Dictionary in rows:
        i += 1
        bits.append("%d. %s" % [i, row["name"]])
    return "Bellmire thanks:  " + "   ".join(bits)

func _board(kind: String) -> String:
    var rows := roster.leaderboard(kind, 5)
    if rows.is_empty():
        return "Nobody has enlisted yet."
    var bits := []
    var i := 0
    for row: Dictionary in rows:
        i += 1
        # The roll reads as a roll: rank first, then whatever was asked for.
        # A dagger marks the dead, who keep their place on it.
        var v: int = int(row.get(kind, row.get("standing", 0)))
        bits.append("%d. %s the %s (%d)%s"
            % [i, row["name"], String(row.get("rank", "Unproven")), v,
               "" if bool(row["alive"]) else " +"])
    var heads := {"deepest": "Deepest delvers", "gold": "Richest",
                  "kills": "Deadliest", "level": "Highest level",
                  "standing": "The guild roll"}
    var head: String = String(heads.get(kind, "The guild roll"))
    return head + ": " + "   ".join(bits)

func _tone(line: String) -> Color:
    var l := line.to_lower()
    if l.contains("dead") or l.contains("falls") or l.contains("memorial") or l.contains("fallen"):
        return C_DEAD
    if l.contains("needs") or l.contains("no hero") or l.contains("full") or l.contains("unkind"):
        return C_WARN
    if l.contains("takes") or l.contains("rises") or l.contains("fitted") or l.contains("sets out"):
        return C_OK
    return C_INFO

## ---- L14: the command list, from data/commands.json (the one source)
static var _cmds: Dictionary = {}
static func commands() -> Dictionary:
    if _cmds.is_empty():
        var f := FileAccess.open("res://data/commands.json", FileAccess.READ)
        if f:
            _cmds = JSON.parse_string(f.get_as_text())
    return _cmds

## an alias -> its command ("inv" -> "inventory"); anything else unchanged
static func canonical(word: String) -> String:
    var cs: Dictionary = commands().get("commands", {})
    if cs.has(word):
        return word
    for k in cs:
        if (cs[k].get("aliases", []) as Array).has(word):
            return k
    return word

## !help: the short list; !help <command>: that one in detail
static func help_line(arg := "") -> String:
    var cs: Dictionary = commands().get("commands", {})
    if arg != "":
        var k := canonical(arg.trim_prefix("!").to_lower())
        if not cs.has(k):
            return "No !%s. !help lists them all." % arg.trim_prefix("!")
        var c: Dictionary = cs[k]
        var al := ""
        if not (c.get("aliases", []) as Array).is_empty():
            al = " (also !" + " !".join(c["aliases"]) + ")"
        # on stream it goes in the Chronicle: the first sentence, the cost, an example (all of it in docs/COMMANDS.md)
        var first := String(c.get("short", String(c["what"]).split(". ")[0].trim_suffix(".") + "."))
        return "!%s %s%s - %s %s. e.g. %s" % [k, c.get("args", ""), al, first, c.get("cost", "free"), c.get("example", "!" + k)]
    var bits: Array = []
    for k in commands().get("order", cs.keys()):
        bits.append("!" + String(k))
    return "Commands: %s  |  !help <command> for more." % " ".join(bits)

## the nearest command to a typo (edit distance 2 or less), or ""
## another app's command (data/commands.json "foreign"): one of theirs, one of their
## prefixes (fightoverlay's "v"), or a near miss of one of theirs - Bellmire stays silent.
## near_too = false: exact or prefix only (a Bellmire name may sit NEAR theirs: stats ~ vstats)
static func foreign(word: String, near_too := true) -> bool:
    var near := 2 if word.length() <= 4 else 3
    var fs: Dictionary = commands().get("foreign", {})
    for app in fs:
        if not (fs[app] is Dictionary):
            continue
        for p in (fs[app] as Dictionary).get("prefixes", []):
            if word.begins_with(String(p)):
                return true
        for n in (fs[app] as Dictionary).get("exact", []):
            if word == String(n) or (near_too and _lev(word, String(n)) < near):
                return true
    return false

## the Bellmire command a typo meant, or "" - never for another app's word (foreign)
static func _closest(word: String) -> String:
    if foreign(word):
        return ""
    var best := ""
    var bd := 2 if word.length() <= 4 else 3
    var names: Array = []
    for k in commands().get("commands", {}):
        names.append(k)
        names.append_array(commands()["commands"][k].get("aliases", []))
    for n in names:
        var d := _lev(word, String(n))
        if d < bd:
            bd = d
            best = canonical(String(n))
    return best

static func _lev(a: String, b: String) -> int:
    var prev: Array = range(b.length() + 1)
    for i in range(1, a.length() + 1):
        var cur: Array = [i]
        for j in range(1, b.length() + 1):
            var cost := 0 if a[i - 1] == b[j - 1] else 1
            cur.append(mini(mini(int(cur[j - 1]) + 1, int(prev[j]) + 1), int(prev[j - 1]) + cost))
        prev = cur
    return int(prev[b.length()])

## ---- S2: what a command sounds like on the stream (flat - Sfx.play, not in the world).
## A typo nudge or a refusal: error. A buy that went through: coins, and the thing picked
## up (or the flask drunk); !inventory opens the pack; any other command: menu_select.
## At most one every UI_GAP s, so a busy chat is not a wall of clicks.
const UI_GAP := 0.35
## S3 (the sound review, measured against the music as heard): menu_select is the commonest
## UI sound and was +4.6 dB over the music at -6, potion_drink -6.8 under it - each kind its own
## level; the rest at UI_DB_BASE
const UI_DB_BASE := -6.0
const UI_DB := {"menu_select": -10.0, "potion_drink": -2.0, "level_up": -4.0}
static var _ui_last := -100000
static var ui_sounds := {}          # kind -> times (tests read it)

## S3: did this command move the hero's gold (a buy, a reroll or respec paid for, a find)?
func _gold_moved(user_id: String, gold0: int) -> bool:
    if gold0 < 0:
        return false
    var h := roster.get_hero(user_id)
    return not h.is_empty() and int(h.get("gold", 0)) != gold0

static func ui_kinds(verb: String, out: String) -> Array:
    var low := out.to_lower()
    if out.begins_with("No !") and out.contains("did you mean"):
        return ["error"]
    if out.contains(" - you have ") or low.begins_with("no hero") or low.contains("needs ") or low.contains("can't") or low.contains("cannot"):
        return ["error"]
    match verb:
        "inventory", "inv", "bag", "items":
            return ["inventory_open"]
        "brew":
            return ["coins_stack", "potion_drink"]
        "forge", "armoury", "armory", "wear":
            return ["coins_stack", "item_pickup"]
        "oil", "lamp", "torch", "dye":
            return ["coins_stack"]
    return ["menu_select"]

func _ui_snd(verb: String, out: String, paid := false) -> void:
    var now := Time.get_ticks_msec()
    if now - _ui_last < int(UI_GAP * 1000.0):
        return
    _ui_last = now
    var ks := ui_kinds(verb, out)
    # S3: whatever the command, gold that moved is heard (reroll / respec cost gold too)
    if paid and not ks.has("coins_stack") and not ks.has("error"):
        ks = ["coins_stack"] + (ks.filter(func(k): return k != "menu_select"))
    for k in ks:
        ui_sounds[k] = int(ui_sounds.get(k, 0)) + 1
        Sfx.play(String(k), float(UI_DB.get(k, UI_DB_BASE)))
