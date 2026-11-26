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

## B104: THE COUNTER SET - every command that puts a viewer in front of a shopkeeper. A hero on
## the scar road or below it is refused with where they are instead of being dragged back to a
## till. This was a bare list inside handle() and it was MISSING `oil`: every other haggled
## purchase refused while a hero was away, and the chandler sold flasks to a hero standing in
## the dark. `fish` is here too and is not a purchase - it walks a hero to the docks, which is
## the same thing being refused. The COUNTER AWAY guard below reads scripts/roster.gd and holds
## this list to the engine's own haggle() sites, so a new shop cannot be added to the game
## without this gate hearing about it.
## `armory` is the one ALIAS kept as a literal here, exactly as the old list had it. handle()
## canonicalises before this gate, so the alias would normally arrive as `armoury` and the
## literal is redundant - but canonical() reads data/commands.json, and if that file ever fails
## to parse the alias arrives verbatim and the till is reached ungated. Keeping it costs one
## string and removes that path. The guard below only asks that every counter KEY is present, so
## an alias sitting in this list is not a fault.
const AWAY_COUNTERS := ["fish", "forge", "armoury", "armory", "brew", "oil", "wear", "dye"]

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
## L70: the Chronicle, newest first, rows of {t, s, at, day, kind?, who?} - the snapshot
## publisher's chronicle() (snapshot_pub.gd, D60 gave the rows their day, kind and who).
## Set this to hand chat another source (the tests do); left unset, chat asks the publisher
## standing beside it in the town, and says plainly that there is nothing yet if neither is there.
var chron_of: Callable
## B69: the town's own standing - {name, level, day, souls, treasury, score, next_at,
## built, specials}. Set this to hand chat another source (the tests do); left unset, chat
## reads the economy and the growth standing beside it (Roster is a child of town in live
## play, town.gd:_start_guild), and says plainly that nothing is standing yet if neither is.
var town_of: Callable
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

## the ladder word for a stored rarity. C-55 retired "epic" in favour of "very rare";
## data/fishing.json still carries the old word on three catches and is not this lane's file,
## so the retired word keeps its old step here instead of falling off the ladder (find() -> -1,
## which would have ranked an epic catch below junk and printed a word nothing else uses).
static func _band(r: String) -> String:
    return "very rare" if r == "epic" else r

## what a hero has on them: steel, armour, potions, oil, gold, and the fish
func inventory(user_id: String) -> String:
    var h := roster.get_hero(user_id)
    if h.is_empty():
        return "No hero yet - type !enlist to join the valley."
    var armour := roster.armour_name(h)
    var worn := roster.worn_line(h)
    var title := roster.title_of(h)
    var line := "%s%s carries %s and wears %s%s  |  %s, %d oil, %d gold" % [
        h["name"], (", " + title) if title != "" else "", roster.weapon_name(h), armour, (" + " + worn) if worn != "" else "", roster.brews_line(h), int(h.get("oil", 0)), int(h.get("gold", 0))]
    if catches_of.is_valid():
        var cs: Array = catches_of.call(String(h["name"]))
        if not cs.is_empty():
            var best: Dictionary = cs[0]
            # C-55 retired "epic" from the ladder - items.json bands the step as "very rare".
            # data/fishing.json is the GAME BUILD's and still says "epic" in its ladder and on
            # three catches, so _band() ranks and PRINTS the retired word as the step it was,
            # and chat never says a word the rest of the game has stopped using.
            var order := ["junk", "common", "uncommon", "rare", "very rare", "legendary"]
            for x in cs:
                if order.find(_band(String(x.get("rarity", "")))) > order.find(_band(String(best.get("rarity", "")))):
                    best = x
            line += "  |  %d catch%s, best: %s (%s)" % [cs.size(), "" if cs.size() == 1 else "es", best.get("name"), _band(String(best.get("rarity", "")))]
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
        # L69: no "!" at all - the bot still answers what chat plainly asks
        return _ask_line(user_id, display, login, msg)
    var now := Time.get_ticks_msec()
    if now - int(_last.get(user_id, -99999)) < int(cooldown() * 1000.0):
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
    if verb in AWAY_COUNTERS and away.has(user_id) and not h.is_empty():
        _last[user_id] = now
        last_cmd[user_id] = now
        return _reply(user_id, display, login, "%s is %s." % [h["name"], away[user_id]])
    ## B157 GUARD NOTE - READ THIS BEFORE YOU ADD A DICTIONARY LITERAL IN THIS FUNCTION.
    ## tools/_l14_test.gd harvests the verbs ChatCmd answers by matching lines at EXACTLY eight
    ## spaces of indent that look like `"word":` or `"a", "b":`. It pattern-matches, it does not
    ## parse, and it cannot tell a match label from a dictionary key. So a dict literal written at
    ## this depth with a lowercase string key - `        "gold": 140,` - is harvested as a command
    ## verb named `gold`, and the gate then goes RED demanding an entry in data/commands.json for a
    ## command that does not exist. THE GATE IS NOT BROKEN AND THE CHANGE IS NOT WRONG: the
    ## instrument is reading a shape it was never told about. Nest the literal one level deeper, or
    ## build it outside this match block, and the red goes away. Do not add an entry to
    ## data/commands.json to silence it - that would publish a verb no viewer can call.
    ## Measured at B156 against synthetic lines; no entry in commands.json today is of this origin.
    match verb:
        "enlist":   out = _enlist(user_id, display, arg, arg2)
        "hero":     out = _needs(user_id, func(): return roster.describe(user_id) + _hub_tail())
        "inventory", "inv", "bag", "items":
                    out = _needs(user_id, func(): return inventory(user_id))
        "weapon":   out = _needs(user_id, func(): return _weapon_line(user_id))
        "armour":   out = _needs(user_id, func(): return _armour_line(user_id))
        "delve":    out = _delve(user_id)
        "muster", "party", "mustered":
                    out = _muster(user_id)
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
        "hub", "site", "guildhall":
                    out = _hub()
        "satchel", "sell", "prices":
                    out = _satchel_line()
        "caravan", "trader", "cargo":
                    out = _caravan_line()
        "festival", "feast":
                    out = _festival_line()
        "town", "bellmire":
                    out = _town_line()
        "bestiary", "beasts", "monsters":
                    out = _bestiary_line()
        "miniboss", "elite", "elites":
                    out = _miniboss_line(rest)
        "catchup", "mystory", "since":
                    out = _catchup(user_id)
        "look":     out = _needs(user_id, func(): return _spot(user_id, "look", 0.0, ""))
        "testbits", "testsub", "testpoints":
                    # L17 test-only: the local chat box (Mr. E's keyboard) fakes a cheer / sub / redeem.
                    # Twitch users never reach these (their ids are not local_*); T1's EventSub calls the API.
                    if not user_id.begins_with("local_"):
                        return ""
                    out = _test_spot(user_id, verb, arg, arg2)
        _:
            # L69: "!how do i join" is a question with a ! on it - the ask table before silence
            var topic := ask_topic(msg.substr(1))
            if topic != "":
                return _ask_line(user_id, display, login, msg.substr(1))
            # L14: a near miss of a real command gets a nudge, anything else is left alone (other bots)
            var guess := _closest(verb)
            if guess == "":
                return ""
            # D70.4: this is the one answer that quotes a viewer's own word - declaw and cap it,
            # and if nothing of it survives, stay silent instead of printing "No ! here"
            var shown := safe_word(verb)
            if shown == "":
                return ""
            out = "No !%s here - did you mean !%s? (!help lists them all)" % [shown, guess]

    _last[user_id] = now
    last_cmd[user_id] = now
    out = safe_line(out)              # D70.4: the feed is published too, and _reply is idempotent
    if out != "":
        say.emit(out, _tone(out))
        _ui_snd(verb, out, _gold_moved(user_id, gold0))
    return _reply(user_id, display, login, out)

## ---- D70.4: THE ECHO RULE. The bot must NEVER echo attacker-controlled text back into chat.
## The hub defends itself with el()/textContent; chat has no such protection, and a line the bot
## repeats is a line Mr. E's channel published. So every answer leaves through _reply and _reply
## is THE ONE DOOR: control characters and the invisible marks are declawed, the whole line is
## capped, and it can never OPEN with a character Twitch itself reads as a command (a leading
## / or .). Where a viewer's own word has to be quoted at all - a typo nudge, !help <word> - it
## goes through safe_word first, which caps it short so their four hundred characters cannot
## crowd ours out inside the line cap. Echo only what the GAME made or what Twitch gave us.
const REPLY_MAX := 440          # characters leaving for chat. Twitch's own cap is 500 and the
                                # desktop's twitch_eventsub.gd puts its prefix in front of this.
const VIEWER_MAX := 24          # of a viewer's OWN word, where one must be quoted at all

## C0 and C1 controls, DEL, and the invisible marks that can hide text or turn a line round
static func _is_bad(o: int) -> bool:
    return o < 32 or o == 127 or (o >= 0x80 and o <= 0x9f) \
        or (o >= 0x200b and o <= 0x200f) or (o >= 0x202a and o <= 0x202e) \
        or (o >= 0x2066 and o <= 0x2069) or o == 0x2028 or o == 0x2029 or o == 0xfeff

## every one of them becomes a single space, so an injected newline joins the line
## instead of starting a second one
static func _declaw(s: String) -> String:
    var out := ""
    for c in s:
        out += " " if _is_bad(c.unicode_at(0)) else c
    return out

## a viewer's word, fit to be quoted inside one of our lines: declawed, the whitespace
## collapsed, nothing left that reads as a command or a mention, and capped short.
## "" means nothing survived - and then the bot says nothing at all rather than half a line.
static func safe_word(s: String, cap := VIEWER_MAX) -> String:
    var out := " ".join(_declaw(s).split(" ", false))
    while out != "" and (out.begins_with("/") or out.begins_with(".") or out.begins_with("!") or out.begins_with("@")):
        out = out.substr(1).strip_edges()
    return _cut(out, cap).strip_edges()

## the whole line as it will leave for chat. Spacing is left as the answer wrote it -
## "  |  " and "  -  " are how these lines read - so this only declaws, caps and un-commands.
static func safe_line(s: String) -> String:
    var out := _declaw(s)
    while out.strip_edges().begins_with("/") or out.strip_edges().begins_with("."):
        out = out.strip_edges().substr(1)
    out = out.strip_edges()
    return _cut(out, REPLY_MAX) if out.length() > REPLY_MAX else out

## T1: hand a command's answer to Twitch chat (via the desktop's twitch_eventsub.gd)
func _reply(user_id: String, display: String, login: String, out: String) -> String:
    # D70.4: the last thing that happens to any answer, whatever path built it
    var line := safe_line(out)
    if line != "" and not user_id.begins_with("local_"):
        twitch_reply.emit(safe_word(login if login != "" else display.to_lower(), 40), line)
    return line

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
            return "No hero named %s." % safe_word(who)      # D70.4
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
    # B17: THE UNION IS OUT OF THE GUARD TOO, AND THE GUARD STILL HOLDS. B11 kept
    # `or away.has(user_id)` for one honest reason: on `main` town._on_delve set `away`
    # WITHOUT queueing, so the queue alone let a point-redeemed errand hero !delve her way
    # into a SECOND slot. D41 moved the append to the source and it reached main - town.gd
    # _on_delve now appends to chat.delve_queue BEFORE it writes the away-state - so every
    # away-state is now carried by a name that is already in the queue:
    #   `away` has exactly THREE writers (on the road 5452, at the mouth 5468, below 5491),
    #   all downstream of the one append at 5450, and ONE eraser at delve.ended which erases
    #   the queue entry in the same breath. `delve_queue` has exactly ONE other eraser and it
    #   is that same line. So away is a SUBSET of the queue, and `or away.has()` can no longer
    #   catch a hero the queue does not already hold.
    # THE DROP IS MEMBERSHIP ONLY. `away` is still read here to WORD the refusal - a hero on
    # the road or below is told where she actually is instead of being told she waits at the
    # mouth. That is the same shape as the muster's exclusion: it narrows an answer, it is
    # never a second source of membership. The subset premise is an ASSERTION in
    # tools/_b11_muster.gd, not a belief: plant an away-only uid and !delve must still refuse
    # to send her out, so if a future writer ever sets `away` without queueing, the gate says
    # so rather than the guard going quietly blind.
    if user_id in delve_queue:
        var qn := String(roster.get_hero(user_id)["name"])
        if away.has(user_id):
            return "%s is %s." % [qn, away[user_id]]
        return "%s is already waiting at the dungeon mouth." % qn
    if delve_queue.size() >= QUEUE_MAX:
        return "The muster is full - %s waits for the next party." \
            % roster.get_hero(user_id)["name"]
    delve_queue.append(user_id)
    wants_delve.emit(user_id)
    return "%s sets out for the dungeon mouth. (%d in the party)" \
        % [roster.get_hero(user_id)["name"], delve_queue.size()]

## THE QUEUE READ - ONE LIST, AND THE UNION IS OUT (B12). D41's source-queueing reached main
## at 16:58 (town.gd: _on_delve appends to chat.delve_queue before it sets away), so a
## channel-point errand and a !delve now land in the SAME list, in the order they happened.
## !muster reads that list and takes no name from anywhere else. The gate proved the premise
## before the union came out: B11_SOURCE_QUEUEING read YES.
##
## WHAT IS NOT OUT, AND WHY - the town erases the queue when the DELVE ENDS, not when the
## party goes below (town.gd: delve.ended -> delve_queue.erase). So for the whole descent the
## names are still in the queue, and a plain read would stand heroes who are underground at
## the dungeon mouth and count them in the muster. The away-state is read here for ONE thing:
## to LEAVE OUT a hero already below. That is an exclusion, not a second source of membership
## - no name enters the muster from away, so there is nothing left to reconcile.
## Needs no hero of its own: a bystander may ask who is going down.
const LINE_WORDS := ["first", "second", "third", "fourth", "fifth", "sixth"]

## is this away-state a hero already underground, rather than one waiting to go down?
static func _below(state: String) -> bool:
    return state.to_lower().contains("below")

func _muster(user_id: String) -> String:
    var uids: Array = []
    for uid in delve_queue:
        var u := String(uid)
        if away.has(u) and _below(String(away[u])):
            continue
        uids.append(u)
    if uids.is_empty():
        return "Nobody at the dungeon mouth. !delve puts your name in."
    var names: Array = []
    var mine := -1
    for i in uids.size():
        var h := roster.get_hero(String(uids[i]))
        var nm := String(h.get("name", ""))
        names.append(nm if nm != "" else "someone")
        if String(uids[i]) == user_id:
            mine = i
    var out := "At the dungeon mouth (%d): %s." % [uids.size(), ", ".join(names)]
    if mine >= 0 and mine < LINE_WORDS.size():
        out += " You are %s in line." % LINE_WORDS[mine]
    elif mine >= 0:
        out += " Your name is in."
    elif delve_queue.size() >= QUEUE_MAX:
        out += " The muster is full - the next party takes you."
    else:
        out += " !delve to go with them."
    return out

# Oil is the cheapest thing on the board and the one most worth buying. A
# viewer who keeps three flasks in the satchel will out-live a better-armed
# hero who descends with none.
func _oil(user_id: String, arg: String) -> String:
    var n := 1
    if arg != "" and arg.is_valid_int():
        n = clampi(int(arg), 1, 10)
    return _needs(user_id, func(): return roster.buy_oil(user_id, n))

## B38: the no-name default was the bare literal "mending" inside _brew, and BOTH `brew`.short
## and `brew`.what publish it as a promise. A promise with no constant behind it cannot be
## checked, so it is a constant now and the BREW guard below reads it.
const BREW_DEFAULT := "mending"

func _brew(user_id: String, arg: String, arg2 := "") -> String:
    # L12: !brew [n] buys Mending as before; !brew <potion> [n] any brew the apothecary makes
    var n := 1
    var key := BREW_DEFAULT
    if arg != "" and arg.is_valid_int():
        n = clampi(int(arg), 1, 10)
    elif arg != "":
        key = Roster.potion_key(arg)
        if arg2 != "" and arg2.is_valid_int():
            n = clampi(int(arg2), 1, 10)
        if key == "":
            return _needs(user_id, func(): return roster.buy_brew(user_id, arg, n))
    if key == BREW_DEFAULT:
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

## ---- L68: what the game has become. The hub is the one place a viewer can read
## the whole of it, so every one of these ends by pointing there. The URL lives in
## data/commands.json ("hub_url") so chat, !help and the hub's Commands tab cannot
## disagree about it.
static func hub_url() -> String:
    return String(commands().get("hub_url", ""))

## a short pointer onto the end of an answer, or nothing if no URL is set
static func _hub_tail() -> String:
    var u := hub_url()
    return "" if u == "" else "  |  Full sheet: " + u

func _hub() -> String:
    var u := hub_url()
    if u == "":
        return "The page is not up yet."
    return "Bellmire's own page: %s - your hero's full sheet, the Chronicle of every day, the Satchel, crests, the Hall of the Fallen, the Bestiary and the Night Watch. Search it by name." % u

## D57: the counter pays SELL_BACK (0.4) of shop cost, per item. Said in words here so
## chat and the hub quote the same number; the rows themselves are the hub's.
## B67 (supervisor 19:28, item 1 of three): the named steel a hero carries and its step on
## the rarity ladder. data/items.json is the CONTENT writer's file - it is read through Gear
## and never edited here. A hero with no named piece (tier 0, bare hands) is said plainly.
func _weapon_line(user_id: String) -> String:
    var h := roster.get_hero(user_id)
    var wp := Gear.weapon_piece(roster.weapon_piece_id(h))
    if wp.is_empty() or int(h.get("weapon", 0)) <= 0:
        return "%s fights with bare hands. The smith sells steel - !forge." % h["name"]
    return "%s carries %s  |  %s, %s (tier %d)  |  %s" % [
        h["name"], wp["name"], _band(String(wp.get("rarity", "common"))),
        wp.get("tier_name", "steel"), int(wp.get("tier", h.get("weapon", 0))), roster.dice_str(h)]

## B67: the mail a hero wears, its step on the ladder, and the AC it leaves them. A kit with
## no named piece falls back to the tier name the sheet already prints, and still gives the AC.
func _armour_line(user_id: String) -> String:
    var h := roster.get_hero(user_id)
    var ap := Gear.armour_piece(Gear.armour_id(h))
    if ap.is_empty():
        return "%s wears %s  |  AC %d" % [h["name"], roster.armour_name(h), roster.armour_class(h)]
    return "%s wears %s  |  %s, %s (tier %d)  |  AC %d" % [
        h["name"], ap["name"], _band(String(ap.get("rarity", "common"))),
        ap.get("tier_name", "cloth"), int(ap.get("tier", h.get("armour", 0))), roster.armour_class(h)]

func _satchel_line() -> String:
    return "The counter pays two fifths of shop cost for anything you own and are not wearing." + _hub_tail()

## B100: the caravan. town.gd brings a master up the west road with a wagon every 70-120 s, holds
## him at the market, settles the trade against the economy's own prices (sells the town a good
## priced over 1.12x base while the treasury is over 80, buys back anything over 90 in store) and
## walks him out. A festival shortens the wait. !festival already named the caravan and nothing
## answered when a viewer asked after it. READ-ONLY: this command trades nothing and calls nothing.
func _caravan_line() -> String:
    return "A caravan comes up the west road with a wagon and stands at the market. It sells the town what the town is short of, buys up the surplus, and takes the road back out. A festival brings one sooner." + _hub_tail()

## D63: a festival is an event with a reason. A paid one is named for whoever paid.
func _festival_line() -> String:
    return "A festival fills the market square - music, stalls, a crowd. A caravan is likelier while it runs. The town levels, or a viewer pays and it carries their name." + _hub_tail()

## B69: what Bellmire is, on one line a viewer reads in a second. The level name IS what has
## been built - TOWN_LEVELS goes "a hamlet" -> "a walled town" - so the named buildings are the
## specials growth.stats() reports OPEN, not every plot. READ-ONLY: this command levels nothing,
## pays nothing and builds nothing; it only reports.
const TOWN_BUILT := {"market_hall": "the market hall", "stables": "the stables",
                     "guild": "the guild hall", "bathhouse": "the bathhouse",
                     "mage_tower": "the mage tower"}

## the town's standing, or {} when nothing is standing. An override wins; otherwise the
## economy and the growth the Roster's own parent holds.
func _town_state() -> Dictionary:
    if town_of.is_valid():
        var o = town_of.call()
        return o if o is Dictionary else {}
    if roster == null:
        return {}
    var t := roster.get_parent()
    if t == null:
        return {}
    var e = t.get("economy")
    if e == null:
        return {}
    var out := {"name": String(e.town_name), "level": int(e.town_level), "day": int(e.day),
                "treasury": int(e.treasury), "souls": int(e.population()),
                "score": int(e.town_score()), "next_at": int(e.next_level_at())}
    var g = t.get("growth")
    if g != null and g.has_method("stats"):
        var st: Dictionary = g.stats()
        out["built"] = int(st.get("built", 0))
        out["specials"] = (st.get("specials", []) as Array)
    return out

func _town_line() -> String:
    var s := _town_state()
    if s.is_empty():
        return "Bellmire is not standing yet. Nothing has been founded."
    var bits: Array[String] = []
    bits.append("Bellmire stands as %s  |  level %d, day %d" % [
        String(s.get("name", "a crossing")), int(s.get("level", 1)), int(s.get("day", 1))])
    bits.append("%d souls, %d gold" % [int(s.get("souls", 0)), int(s.get("treasury", 0))])
    var houses := int(s.get("built", 0))
    var named: Array[String] = []
    for k in (s.get("specials", []) as Array):
        var nm := String(TOWN_BUILT.get(String(k), ""))
        if nm != "":
            named.append(nm)
    if houses > 0 or not named.is_empty():
        var b := "no houses yet"
        if houses > 0:
            b = "%d houses" % houses
        if not named.is_empty():
            b += ", " + ", ".join(named)
        bits.append(b)
    # the climb is only worth printing while there is one left to make
    var nxt := int(s.get("next_at", 0))
    if nxt > 0:
        bits.append("next at %d, score %d" % [nxt, int(s.get("score", 0))])
    else:
        bits.append("nothing left to grow into")
    return "  |  ".join(bits)

func _bestiary_line() -> String:
    return "What haunts the dark, depth by depth: each beast's size, its habits in a fight, and the eight lords that hold the deep." + _hub_tail()

## ---- B70: !miniboss - THE THIRD OF THE SUPERVISOR'S THREE (19:28, item 3): "what's on your
## floor, what you've fought". THE ONE THING THIS COMMAND MUST NOT DO IS CARRY ITS OWN COPY OF
## THE NAMES. The 19 Nov rename (supervisor sup-nov19-2150) gave every elite a proper name and
## KEPT THE TRADE AS THE KEY - art's .glb stem, MB_FIT's key, content's miniboss_feed.by_key key.
## The team lead's 22:58 row charged the game build with shipping a name table whose own gate was
## a SECOND COPY of that table: tools/_s51_names.gd asserts the map against the map, so it can
## only ever agree with the thing it is checking. I am answering with the same names, one hour
## later, in a different file - so the copy was the obvious thing to write and is the one thing
## that would make this answer rot on its own.
## SO THERE IS NO TABLE HERE. The key set is content's by_key - the bodies that actually draw a
## line - and every name comes from Delve.miniboss_name(), the accessor the nameplate itself
## calls. One authority, read twice, never copied: when the game build corrects a name this
## answer corrects with it and I change nothing. The same walk is the guard further down, which
## is why that guard can see a fault neither lane's own gate could.
## READ-ONLY, no hero needed, nothing owed by the game build: it reports what stands in the deep.
const MB_ASK := "Ask by name, or by the trade: "

## trade key -> the name a viewer reads, for every elite that content has a feed row for.
## Empty when either side is missing - the answer says so plainly rather than printing nothing.
static func miniboss_names() -> Dictionary:
    var out := {}
    var mf: Dictionary = (Delve.lore().get("miniboss_feed", {}) as Dictionary)
    for k in (mf.get("by_key", {}) as Dictionary).keys():
        out[String(k)] = Delve.miniboss_name(String(k))
    return out

## the look of the thing: content's first `arrive` line for it. Lines carrying {name} belong to
## a delver who is not standing here, so they are passed over rather than filled in with a hole.
static func _miniboss_look(key: String) -> String:
    for l in Delve.miniboss_lines(key, "arrive"):
        var s := String(l)
        if s != "" and not s.contains("{"):
            return s
    return ""

## a viewer's word -> the trade key, or "". Exact on the key or the name first, then one
## unambiguous prefix ("murk" -> murkspit); two matches is no match and the answer asks again.
static func _miniboss_find(q: String) -> String:
    var want := q.strip_edges().to_lower()
    if want == "":
        return ""
    var names := miniboss_names()
    for k: String in names:
        if want == k or want == String(names[k]).to_lower():
            return k
    var hit := ""
    for k: String in names:
        if k.begins_with(want) or String(names[k]).to_lower().begins_with(want):
            if hit != "" and hit != k:
                return ""
            hit = k
    return hit

func _miniboss_line(q: String) -> String:
    var names := miniboss_names()
    if names.is_empty():
        return "Nothing is written down about what holds the chambers." + _hub_tail()
    var keys := names.keys()
    keys.sort()
    if q.strip_edges() == "":
        # the count is the live one, not a word of mine - chat cannot drift from the data here
        return "%d hold a chamber alone, one to a chamber. %s!miniboss %s" \
            % [names.size(), MB_ASK, String(names[keys[0]])] + _hub_tail()
    var key := _miniboss_find(q)
    if key == "":
        return "No such one holds a chamber. %s!miniboss %s" % [MB_ASK, String(names[keys[0]])]
    var nm := String(names[key])
    var trade := key.replace("_", " ")
    # a body the rename has not reached answers to its trade word - said once, not twice
    var head := nm if nm.to_lower() == trade else "%s, once the %s" % [nm, trade]
    var look := _miniboss_look(key)
    if look == "":
        return "%s holds a chamber alone." % head + _hub_tail()
    return "%s. %s" % [head, look] + _hub_tail()

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

## ---- L70: WHAT HAPPENED WHILE I WAS AWAY. One line, two at the outside: what the hero
## did, how it went, where they stand now, and the hub for the rest of it. A SUMMARY, NOT A
## SAGA - CATCHUP_MAX is a hard cap on the whole answer, the pointer included, and a row that
## will not fit whole is left out rather than cut off in the middle of a sentence.
const CATCHUP_MAX := 320        # characters, the hub pointer included (Twitch's own cap is 500)
const CATCHUP_ROWS := 3         # Chronicle entries quoted at the very most
## which of a hero's lines is worth the one line chat gets: a death over a fight, a fight over
## loot, loot over the walk down. The town's own weather is last - it happened to everyone.
const CATCHUP_WEIGHT := {"death": 5, "fight": 4, "loot": 3, "delve": 2, "raid": 2, "town": 1, "lore": 0}

## the Chronicle rows, newest first, or [] - `chron_of` if the town set one, else the
## publisher beside us. Never an error: a bot with no Chronicle still answers.
func _chron_rows() -> Array:
    if chron_of.is_valid():
        var given: Variant = chron_of.call()
        if given is Array:
            return given as Array
        return []
    var p := get_parent()
    if p == null:
        return []
    var pub := p.get_node_or_null("SnapshotPublisher")
    if pub == null or not pub.has_method("chronicle"):
        return []
    var rows: Variant = pub.call("chronicle")
    if rows is Array:
        return rows as Array
    return []

## is this hero named on this Chronicle row? D60 puts tagged heroes in `who`; an untagged
## line still carries the name in its own text, so both are read. Word boundaries only -
## "Ash" must not be found inside "Ashen".
static func _row_names(row: Dictionary, name: String) -> bool:
    for w in (row.get("who", []) as Array):
        if _flat(String(w)) == _flat(name):
            return true
    return _has_word(_flat(String(row.get("s", ""))), _flat(name))

static func _has_word(flat: String, word: String) -> bool:
    if word == "":
        return false
    return (" " + flat + " ").contains(" " + word + " ")

## B46: the words inside the parenthesis that follows `head` in `wear`.what, cut at the first
## " - " (the accessory parenthesis carries a gloss after a dash), lower case, "a "/"the " gone.
## The published lists are PROSE, so this reads them the way a viewer does rather than asking
## the data file to carry a machine copy of a sentence.
static func _wear_list(what: String, head: String) -> Array[String]:
    var at := what.to_lower().find(head)
    if at < 0:
        return []
    var rest := what.to_lower().substr(at + head.length())
    var close := rest.find(")")
    if close < 0:
        return []
    var inner := rest.substr(0, close)
    var dash := inner.find(" - ")
    if dash >= 0:
        inner = inner.substr(0, dash)
    var out: Array[String] = []
    for part in inner.replace(" and ", ",").split(",", false):
        var w := String(part).strip_edges().trim_prefix("a ").trim_prefix("the ").strip_edges()
        if w != "" and not out.has(w):
            out.append(w)
    return out

## B46: a published plural matched to the one slot or kind it names ("rings" -> "ring",
## "boots" -> "boots", "a pet" -> "pet"): the word itself, or the word with one trailing "s"
## taken off. "" when nothing in the table answers to it, which is the GHOST finding.
static func _wear_one(word: String, real: Array[String]) -> String:
    if real.has(word):
        return word
    var cut := word.trim_suffix("s")
    return cut if real.has(cut) else ""

## B46: how many rows the shop sells above a published top price. Used only to say HOW BAD a
## wrong span is in the error line; the finding itself is the top price, not this count.
static func _wear_over(acc: Dictionary, cos: Dictionary, top: int) -> int:
    var n := 0
    for tab in [acc, cos]:
        for k in (tab as Dictionary):
            var row: Dictionary = (tab as Dictionary)[k] as Dictionary
            if row.has("cost") and int(row["cost"]) > top:
                n += 1
    return n

static func _weight(row: Variant) -> int:
    return int(CATCHUP_WEIGHT.get(String((row as Dictionary).get("kind", "")), 1))

## cut to n characters on a word, never mid-word and never trailing a comma or a dash
static func _cut(s: String, n: int) -> String:
    if n <= 0:
        return ""
    if s.length() <= n:
        return s
    var head := s.substr(0, n)
    var sp := head.rfind(" ")
    if sp > int(n / 2):
        head = head.substr(0, sp)
    return head.strip_edges().trim_suffix(",").trim_suffix("-").strip_edges()

## the deeds half: the heaviest CATCHUP_ROWS of this hero's lines, back in the order they
## happened, inside `budget` characters. Nothing on them yet is worth saying plainly.
static func _catchup_deeds(name: String, mine: Array, budget: int) -> String:
    if mine.is_empty():
        return "The Chronicle has nothing on %s yet - !delve and it will." % name
    var idx: Array = []
    for i in range(mine.size()):
        idx.append(i)
    idx.sort_custom(func(a, b): return _weight(mine[a]) > _weight(mine[b]))
    # The budget is spent in WEIGHT order, so a death is never the line that got cut for a
    # walk down the stair; the kept rows are only then put back in the order they happened.
    var head := "%s: " % name
    # the oldest line the Chronicle still holds on them - how far back "since" reaches
    var day := int((mine[mine.size() - 1] as Dictionary).get("day", 0))
    if day >= 1:
        head = "%s, since day %d: " % [name, day]
    var keep: Array = []
    var used := head.length()
    for i in idx:
        if keep.size() >= CATCHUP_ROWS:
            break
        var s := _catchup_text(mine[int(i)] as Dictionary, name)
        if s == "":
            continue
        if used + s.length() + 5 > budget and not keep.is_empty():
            continue
        keep.append(i)
        used += mini(s.length(), budget) + 5
    if keep.is_empty():
        return ""
    keep.sort()
    keep.reverse()                      # the rows come newest first, so this is oldest first
    var bits: Array = []
    var left := budget - head.length()
    for i in keep:
        var s := _catchup_text(mine[int(i)] as Dictionary, name)
        if s.length() + 5 > left:
            s = _cut(s, maxi(40, left - 5))
        if s == "":
            continue
        bits.append(s)
        left -= s.length() + 5
    if bits.is_empty():
        return ""
    return head + "  -  ".join(bits)

## a row as chat reads it: the Chronicle's own words, with the hero's name off the front
## where the line opens with it - the answer has already said whose story this is.
static func _catchup_text(row: Dictionary, name: String) -> String:
    var s := String(row.get("s", "")).strip_edges()
    if name != "" and s.to_lower().begins_with(name.to_lower() + " "):
        s = s.substr(name.length() + 1).strip_edges()
    return s

## where the hero stands now, in one clause
func _catchup_now(user_id: String, h: Dictionary) -> String:
    if not roster.is_alive(user_id):
        return "Dead now; the memorial keeps the name. !reroll raises another."
    var deepest := int(h.get("deepest", 0))
    var where := "deepest floor %d" % deepest if deepest > 0 else "not been down yet"
    return "Stands level %d, %d gold, %s." % [int(h.get("level", 1)), int(h.get("gold", 0)), where]

## !catchup / !mystory / !since
func _catchup(user_id: String) -> String:
    var h := roster.get_hero(user_id)
    if h.is_empty():
        return "No hero yet - type !enlist and there will be something to tell."
    var name := String(h["name"])
    var mine: Array = []
    for row in _chron_rows():
        if row is Dictionary and _row_names(row as Dictionary, name):
            mine.append(row)
    var tail := _hub_tail()
    var now_bit := _catchup_now(user_id, h)
    var body := CATCHUP_MAX - tail.length()
    var deeds := _catchup_deeds(name, mine, body - now_bit.length() - 5)
    var out := deeds + ("  |  " if deeds != "" else "") + now_bit
    return _cut(out, body) + tail

## ---- L14: the command list, from data/commands.json (the one source)
static var _cmds: Dictionary = {}
## B18: THIS LOADER WAS THE QUIETEST INSTRUMENT IN THE LANE AND IT IS THE ONE EVERY GATE READS.
## It used to return {} on a missing file, and `null` on malformed JSON, WITHOUT A WORD. Every
## downstream check then measured an empty dictionary: `!help` names nothing, the doc generator
## writes a header and prints "wrote 0 commands", and a reader skimming a battery sees a count
## rather than a failure. That is COORDINATION 15's fault at its source - a pass nothing earned.
## It now says so out loud, three ways, so a battery turns RED instead of going blind.
## B48: THE COUNTED ARM, AND WHY A LOUD GUARD STILL NEEDED ONE. The ten `wear` sites below
## report through push_error + printerr. tools/_l14_test.gd moves its _fail ONLY in the
## checked() helper at :11, so a push_error moves NEITHER the exit code NOR the printed
## verdict: B47 fired all ten off mutated data and the gate still printed "L14_TEST OK" on
## eight of them - on the exact live defect B46 found, a published price span 100 gold under
## what the counter charges. push_error CANNOT set an exit status. A COUNT a harness can read
## can. So every wear site now REGISTERS ITS TAG here as well as going loud, and any gate can
## ask ChatCmd.guard_faults() and fail on a non-empty answer. The loudness is unchanged and no
## published word, price or list is restated on this side - only the tag of the arm that fired.
## B49: THE REST OF THE COUNT. B48 covered TEN `wear` SITES WITH SEVEN ARMS and left SIXTY-SEVEN loud but
## uncounted, and that is worse than none of them being counted: guard_faults() is the reading
## a gate trusts, so an empty array read as "clean" while any of the other sixty-seven arms was
## firing. A harness asking the count would have passed the live defect class B46 found - a
## published price a hundred gold under what the counter charges - as long as the drift was in
## any command but `wear`. Every COMMANDS_DATA arm in this loader now registers its tag, so the
## count and the loudness say the same thing. The tag is the arm's own tag out of its message,
## unchanged; where an arm sits in a loop (the enlist pair, the three flat prices) the same tag
## can appear more than once, and the loud line beside it names which row fired. Nothing here
## restates a published word, price or list - only the tag.
static var _guard_faults: Array[String] = []
## The tags of every guard arm that fired on the last load of data/commands.json, in the order
## they fired. Empty is the healthy reading, the same convention as a battery grepping for zero
## COMMANDS_DATA lines.
static func guard_faults() -> Array[String]:
    return _guard_faults.duplicate()
static func commands() -> Dictionary:
    if _cmds.is_empty():
        _guard_faults.clear()
        var f := FileAccess.open("res://data/commands.json", FileAccess.READ)
        if f == null:
            _guard_faults.append("MISSING")
            push_error("COMMANDS_DATA MISSING: res://data/commands.json would not open (err %d)" % FileAccess.get_open_error())
            printerr("COMMANDS_DATA MISSING - res://data/commands.json would not open")
            return {}
        var parsed: Variant = JSON.parse_string(f.get_as_text())
        if typeof(parsed) != TYPE_DICTIONARY:
            _guard_faults.append("UNPARSABLE")
            push_error("COMMANDS_DATA UNPARSABLE: data/commands.json is not a JSON object")
            printerr("COMMANDS_DATA UNPARSABLE - data/commands.json is not a JSON object")
            return {}
        if not (parsed as Dictionary).has("commands") or (parsed["commands"] as Dictionary).is_empty():
            _guard_faults.append("EMPTY")
            push_error("COMMANDS_DATA EMPTY: data/commands.json carries no `commands`")
            printerr("COMMANDS_DATA EMPTY - data/commands.json carries no `commands`")
            return {}
        # B19: `commands` was the only key this loader vouched for, and two SHIPPED features
        # read siblings of it with a silent `.get(key, {})`. An `ask` that goes missing makes
        # the bot answer a plain question with nothing - and the comment above ask() in this
        # same file already says silence reads as a broken bot. A `foreign` that goes missing
        # is worse than quiet: foreign() then returns false for every word, so Bellmire starts
        # nudging another app's commands through the one door D70.4 built. NEITHER IS FATAL and
        # neither returns {} - the commands themselves still answer, and killing the bot over a
        # dead sibling would be a bigger fault than the one being reported. So they say it out
        # loud and carry on. A battery greps COMMANDS_DATA; no line is the healthy reading.
        var ask_d: Variant = (parsed as Dictionary).get("ask", {})
        if typeof(ask_d) != TYPE_DICTIONARY or (ask_d as Dictionary).is_empty():
            _guard_faults.append("NO ASK")
            push_error("COMMANDS_DATA NO ASK: data/commands.json carries no usable `ask` - a plain question gets no answer")
            printerr("COMMANDS_DATA NO ASK - data/commands.json carries no usable `ask`")
        var for_d: Variant = (parsed as Dictionary).get("foreign", {})
        if typeof(for_d) != TYPE_DICTIONARY or (for_d as Dictionary).is_empty():
            _guard_faults.append("NO FOREIGN")
            push_error("COMMANDS_DATA NO FOREIGN: data/commands.json carries no usable `foreign` - another app's commands would be answered")
            printerr("COMMANDS_DATA NO FOREIGN - data/commands.json carries no usable `foreign`")
        # B22 (B21 Fault 2): `order` is the key the doc generator actually walks, and this loader
        # never vouched for it. A MISSING `order` is safe - the generator falls back to the command
        # keys - but a PRESENT-BUT-SHORT one writes a truncated docs/COMMANDS.md while the count
        # still reads full: a doc that quietly drops commands a viewer can type. Not fatal - the
        # commands answer either way - so it says it out loud and carries on, the same shape as
        # `ask` and `foreign` above.
        var ord_v: Variant = (parsed as Dictionary).get("order", [])
        var cmd_d: Dictionary = parsed["commands"] as Dictionary
        if typeof(ord_v) != TYPE_ARRAY:
            _guard_faults.append("ORDER UNUSABLE")
            push_error("COMMANDS_DATA ORDER UNUSABLE: data/commands.json `order` is not an array")
            printerr("COMMANDS_DATA ORDER UNUSABLE - `order` is not an array")
        elif not (ord_v as Array).is_empty():
            var ord_a: Array = ord_v as Array
            var miss: Array = []
            for k in cmd_d:
                if not ord_a.has(k):
                    miss.append(k)
            var ghost: Array = []
            for k in ord_a:
                if not cmd_d.has(k):
                    ghost.append(k)
            if not miss.is_empty():
                _guard_faults.append("ORDER SHORT")
                push_error("COMMANDS_DATA ORDER SHORT: %d command(s) absent from `order` would be dropped from docs/COMMANDS.md: %s" % [miss.size(), miss])
                printerr("COMMANDS_DATA ORDER SHORT - %d command(s) absent from `order`: %s" % [miss.size(), miss])
            if not ghost.is_empty():
                _guard_faults.append("ORDER GHOST")
                push_error("COMMANDS_DATA ORDER GHOST: `order` names %d key(s) no command answers: %s" % [ghost.size(), ghost])
                printerr("COMMANDS_DATA ORDER GHOST - `order` names %d dead key(s): %s" % [ghost.size(), ghost])
        # B108: THE ALIAS COLUMN HAS BEEN PUBLISHED SINCE L14 AND NO ARM HAS EVER READ IT.
        # I grepped my own file for an ALIAS tag before writing this - rc=1, no arm - and
        # tools/_l14_test.gd:97-100 asks only whether an alias collides with ANOTHER APP's
        # words, never whether it routes HERE. canonical() (:2996) is the only router: it
        # returns `word` when `commands` already has it, otherwise the first key whose
        # `aliases` list holds it. docs/COMMANDS.md publishes every alias as a route a viewer
        # can type, so an alias that does not route is a published lie, and all four shapes
        # below are silent in every gate today. Not fatal - the command still answers under
        # its own name - so each says it out loud and carries on, the shape `order` uses above.
        var al_bad: Array = []          # `aliases` is not an array: canonical() would call
                                        # .has() on Nil and EVERY command stops routing
        var al_shadow: Array = []       # the alias is also a command key, so cs.has(word)
                                        # wins first and the alias never reaches this command
        var al_clash: Array = []        # the same alias on two commands: whichever key the
                                        # dictionary walks first wins, silently
        var al_dead: Array = []         # handle() lowercases and splits on whitespace before
                                        # canonical(), so upper case/blank/padded never arrives
        var al_seen: Dictionary = {}
        for k in cmd_d:
            var av: Variant = (cmd_d[k] as Dictionary).get("aliases", [])
            if typeof(av) != TYPE_ARRAY:
                al_bad.append(String(k))
                continue
            for a in (av as Array):
                if typeof(a) != TYPE_STRING:
                    al_dead.append("%s:<%s>" % [k, type_string(typeof(a))])
                    continue
                var al_s := String(a)
                if al_s.is_empty() or al_s != al_s.to_lower() or al_s.strip_edges() != al_s or al_s.contains(" "):
                    al_dead.append("%s:%s" % [k, al_s])
                if cmd_d.has(al_s):
                    al_shadow.append("%s:%s" % [k, al_s])
                if al_seen.has(al_s):
                    al_clash.append("%s:%s (already %s)" % [k, al_s, al_seen[al_s]])
                else:
                    al_seen[al_s] = k
        if not al_bad.is_empty():
            _guard_faults.append("ALIAS UNUSABLE")
            push_error("COMMANDS_DATA ALIAS UNUSABLE: `aliases` is not an array on %d command(s) - canonical() cannot route at all: %s" % [al_bad.size(), al_bad])
            printerr("COMMANDS_DATA ALIAS UNUSABLE - `aliases` not an array on %d command(s): %s" % [al_bad.size(), al_bad])
        if not al_shadow.is_empty():
            _guard_faults.append("ALIAS SHADOW")
            push_error("COMMANDS_DATA ALIAS SHADOW: %d alias(es) are also command keys, so they answer that command and never this one: %s" % [al_shadow.size(), al_shadow])
            printerr("COMMANDS_DATA ALIAS SHADOW - %d alias(es) shadowed by a command key: %s" % [al_shadow.size(), al_shadow])
        if not al_clash.is_empty():
            _guard_faults.append("ALIAS CLASH")
            push_error("COMMANDS_DATA ALIAS CLASH: %d alias(es) are declared on two commands and route by dictionary order: %s" % [al_clash.size(), al_clash])
            printerr("COMMANDS_DATA ALIAS CLASH - %d alias(es) declared twice: %s" % [al_clash.size(), al_clash])
        if not al_dead.is_empty():
            _guard_faults.append("ALIAS DEAD")
            push_error("COMMANDS_DATA ALIAS DEAD: %d published alias(es) can never reach canonical() as written: %s" % [al_dead.size(), al_dead])
            printerr("COMMANDS_DATA ALIAS DEAD - %d published alias(es) unreachable: %s" % [al_dead.size(), al_dead])
        # B23: the earnability pass run over my own files. Every guard above stops at the key
        # it names, and five live reads sit one level below them. `ask` being a non-empty
        # dictionary says nothing about `topics`, and `ask.order` is the same instrument as
        # `order` above with a worse failure: a topic absent from `ask.order` is UNREACHABLE,
        # because ask_topic() walks `order` and never the topic keys. A topic that matches and
        # carries neither `cmd` nor `reply` is worse still - the line is recognised and the bot
        # then says nothing, which is the one failure L69 was built to end. And help_line()
        # reads `c["what"]` as the default of a .get(), so GDScript evaluates it even when
        # `short` is there: one command with no `what` breaks !help for that command. None of
        # the five is fatal, so all five say it out loud and carry on, as `ask`/`foreign`/`order`
        # do. A battery greps COMMANDS_DATA; no line is the healthy reading.
        if typeof(ask_d) == TYPE_DICTIONARY and not (ask_d as Dictionary).is_empty():
            var ask_k: Dictionary = ask_d as Dictionary
            var tps_v: Variant = ask_k.get("topics", {})
            if typeof(tps_v) != TYPE_DICTIONARY or (tps_v as Dictionary).is_empty():
                _guard_faults.append("ASK NO TOPICS")
                push_error("COMMANDS_DATA ASK NO TOPICS: `ask` carries no usable `topics` - every plain question gets silence")
                printerr("COMMANDS_DATA ASK NO TOPICS - `ask` carries no usable `topics`")
            else:
                var tps: Dictionary = tps_v as Dictionary
                var ao_v: Variant = ask_k.get("order", [])
                if typeof(ao_v) != TYPE_ARRAY:
                    _guard_faults.append("ASK ORDER UNUSABLE")
                    push_error("COMMANDS_DATA ASK ORDER UNUSABLE: `ask.order` is not an array")
                    printerr("COMMANDS_DATA ASK ORDER UNUSABLE - `ask.order` is not an array")
                elif not (ao_v as Array).is_empty():
                    var ao: Array = ao_v as Array
                    var t_miss: Array = []
                    for k in tps:
                        if not ao.has(k):
                            t_miss.append(k)
                    var t_ghost: Array = []
                    for k in ao:
                        if not tps.has(k):
                            t_ghost.append(k)
                    if not t_miss.is_empty():
                        _guard_faults.append("ASK ORDER SHORT")
                        push_error("COMMANDS_DATA ASK ORDER SHORT: %d topic(s) absent from `ask.order` can never be matched: %s" % [t_miss.size(), t_miss])
                        printerr("COMMANDS_DATA ASK ORDER SHORT - %d topic(s) unreachable: %s" % [t_miss.size(), t_miss])
                    if not t_ghost.is_empty():
                        _guard_faults.append("ASK ORDER GHOST")
                        push_error("COMMANDS_DATA ASK ORDER GHOST: `ask.order` names %d topic(s) that do not exist: %s" % [t_ghost.size(), t_ghost])
                        printerr("COMMANDS_DATA ASK ORDER GHOST - `ask.order` names %d dead topic(s): %s" % [t_ghost.size(), t_ghost])
                var mute: Array = []
                var nophr: Array = []
                for k in tps:
                    var t: Dictionary = tps[k] as Dictionary if tps[k] is Dictionary else {}
                    if (t.get("phrases", []) as Array).is_empty():
                        nophr.append(k)
                    if String(t.get("cmd", "")) == "" and String(t.get("reply", "")) == "":
                        mute.append(k)
                if not nophr.is_empty():
                    _guard_faults.append("ASK TOPIC NO PHRASES")
                    push_error("COMMANDS_DATA ASK TOPIC NO PHRASES: %d topic(s) nothing can match: %s" % [nophr.size(), nophr])
                    printerr("COMMANDS_DATA ASK TOPIC NO PHRASES - %d topic(s) nothing can match: %s" % [nophr.size(), nophr])
                if not mute.is_empty():
                    _guard_faults.append("ASK TOPIC MUTE")
                    push_error("COMMANDS_DATA ASK TOPIC MUTE: %d topic(s) match a question and answer with nothing: %s" % [mute.size(), mute])
                    printerr("COMMANDS_DATA ASK TOPIC MUTE - %d topic(s) answer with nothing: %s" % [mute.size(), mute])
        var no_what: Array = []
        for k in cmd_d:
            if not (cmd_d[k] is Dictionary) or String((cmd_d[k] as Dictionary).get("what", "")) == "":
                no_what.append(k)
        if not no_what.is_empty():
            _guard_faults.append("NO WHAT")
            push_error("COMMANDS_DATA NO WHAT: %d command(s) carry no `what` - !help <command> breaks on them: %s" % [no_what.size(), no_what])
            printerr("COMMANDS_DATA NO WHAT - %d command(s) carry no `what`: %s" % [no_what.size(), no_what])
        if typeof(for_d) == TYPE_DICTIONARY:
            var dead_app: Array = []
            for app in (for_d as Dictionary):
                if String(app).begins_with("_"):
                    continue          # `_why` and friends are comments in the data, not apps
                var fa: Dictionary = (for_d as Dictionary)[app] as Dictionary if (for_d as Dictionary)[app] is Dictionary else {}
                if (fa.get("prefixes", []) as Array).is_empty() and (fa.get("exact", []) as Array).is_empty():
                    dead_app.append(app)
            if not dead_app.is_empty():
                _guard_faults.append("FOREIGN APP EMPTY")
                push_error("COMMANDS_DATA FOREIGN APP EMPTY: %d app(s) in `foreign` name nothing, so their commands are answered: %s" % [dead_app.size(), dead_app])
                printerr("COMMANDS_DATA FOREIGN APP EMPTY - %d app(s) name nothing: %s" % [dead_app.size(), dead_app])
        # B29 (B28 residual 2, closed): the two COOLDOWN keys are the only published numbers in
        # this file that NOTHING vouches for. `cooldown_s` is read by cooldown() below with a
        # silent fallback to COOLDOWN; `twitch_cooldown_s` is read by the game build's
        # twitch_chat.gd with a silent fallback to its own constant. Delete either key and every
        # gate in the house stays green while the bot quietly enforces a DIFFERENT number from
        # the one docs/COMMANDS.md promises a viewer - the exact drift L14 was built to refuse,
        # one key over. A wrong TYPE is the same fault: a string "1.5" reads as 0.0 and falls
        # back. Neither is fatal, so both say it out loud and carry on, the shape every guard
        # above uses. A battery greps COMMANDS_DATA; no line is the healthy reading.
        for ck in ["cooldown_s", "twitch_cooldown_s"]:
            if not (parsed as Dictionary).has(ck):
                _guard_faults.append("COOLDOWN MISSING")
                push_error("COMMANDS_DATA COOLDOWN MISSING: data/commands.json carries no `%s` - the enforced wait silently falls back and docs/COMMANDS.md still promises the old number" % ck)
                printerr("COMMANDS_DATA COOLDOWN MISSING - no `%s`; the published wait and the enforced wait can now differ" % ck)
                continue
            var cv: Variant = (parsed as Dictionary)[ck]
            if not (typeof(cv) == TYPE_FLOAT or typeof(cv) == TYPE_INT) or float(cv) <= 0.0:
                _guard_faults.append("COOLDOWN UNUSABLE")
                push_error("COMMANDS_DATA COOLDOWN UNUSABLE: data/commands.json `%s` is not a positive number (%s) - the read falls back and the published wait lies" % [ck, str(cv)])
                printerr("COMMANDS_DATA COOLDOWN UNUSABLE - `%s` is not a positive number (%s)" % [ck, str(cv)])
        # B42: THE TWO NUMBERS IN MY OWN DATA FILE NOTHING VOUCHED FOR. The B29 comment above
        # says the COOLDOWN keys are the only PUBLISHED numbers nothing vouched for, and that is
        # still true - but `ask.gap_s` and `ask.max_len` are numbers nothing vouched for either,
        # and they are read with the same silent fallback to a literal in this file:
        # ask_topic() uses `int(float(ask().get("gap_s", 45.0)) * 1000.0)` for the shared-answer
        # gap and `int(a.get("max_len", 140))` for the length a question may reach. Delete either
        # key, or give it a wrong type, and every gate in the house stays green while the bot
        # enforces a DIFFERENT number a viewer feels: a question one character over the cap gets
        # SILENCE, which is the one failure L69 exists to end, and a wrong gap either repeats a
        # shared answer on stream or swallows it. Neither is published, so there is no doc to
        # drift - the fault is the silent fallback itself, which is why these two were missed when
        # the published pair were guarded.
        # THE TYPE ARM IS WRITTEN FOR GODOT'S JSON, NOT AGAINST IT: the parser hands back a
        # FLOAT for a plain `140`, so TYPE_FLOAT is CORRECT here and an int-only check would be
        # the defect. A STRING "140" is the fault - it reads as 0 through int() and the cap
        # becomes "every question is too long".
        # max_len gets one arm the gap does not: a cap must be a WHOLE number of characters.
        # 140.9 silently enforces 140 through int(), the same shape as LOOK FRACTION below.
        if typeof(ask_d) == TYPE_DICTIONARY:
            for ak: Array in [["gap_s", "the shared-answer gap"], ["max_len", "the length a question may reach"]]:
                var akey := String(ak[0])
                var awhat := String(ak[1])
                if not (ask_d as Dictionary).has(akey):
                    _guard_faults.append("ASK NUMBER MISSING")
                    push_error("COMMANDS_DATA ASK NUMBER MISSING: `ask` carries no `%s` - %s silently falls back to the literal inside chatcmd.gd and nothing in the house says the data stopped deciding it" % [akey, awhat])
                    printerr("COMMANDS_DATA ASK NUMBER MISSING - no `ask.%s`; %s is on the fallback literal" % [akey, awhat])
                    continue
                var av: Variant = (ask_d as Dictionary)[akey]
                if not (typeof(av) == TYPE_FLOAT or typeof(av) == TYPE_INT) or float(av) <= 0.0:
                    # the TYPE is named beside the value on purpose: str("140") and str(140) read
                    # the same in a log, and a lane reading this line has to be able to tell a
                    # wrong type from a wrong number without opening the data file.
                    _guard_faults.append("ASK NUMBER UNUSABLE")
                    push_error("COMMANDS_DATA ASK NUMBER UNUSABLE: `ask.%s` is not a positive number (%s, type %s) - the read falls back and %s is not what the data says" % [akey, str(av), type_string(typeof(av)), awhat])
                    printerr("COMMANDS_DATA ASK NUMBER UNUSABLE - `ask.%s` is not a positive number (%s, type %s)" % [akey, str(av), type_string(typeof(av))])
                elif akey == "max_len" and float(av) != float(int(float(av))):
                    _guard_faults.append("ASK MAX_LEN FRACTION")
                    push_error("COMMANDS_DATA ASK MAX_LEN FRACTION: `ask.max_len` is %s, and a cap on a question is a whole number of characters - the read truncates it to %d, so the enforced cap is not the one the data states" % [str(av), int(float(av))])
                    printerr("COMMANDS_DATA ASK MAX_LEN FRACTION - max_len %s enforced as %d" % [str(av), int(float(av))])
        # B33: THE FORGE KIND LIST WAS RECITED, NOT ENUMERATED. `forge`.what names the kinds a
        # viewer may ask the smith for, and NOTHING compared that sentence to Gear.KINDS, which is
        # what roster.gd actually accepts (it refuses on `Gear.KINDS.has(kind)` and lists
        # `Gear.kinds_of(fam)`). So a kind added in the GAME BUILD's file made docs/COMMANDS.md
        # wrong in silence, and the doc generator could not notice: it copies this string through.
        # It had already happened twice - `sceptre` (D94b, arcane) and `greataxe` (S20, axe) were
        # both ACCEPTED COMMANDS the doc did not mention. The list is still written by hand, on
        # purpose - it carries the family grouping and the slashes a viewer reads - but an UNLISTED
        # kind is now a FAIL rather than a silence, in both directions. Not fatal: the commands
        # answer either way, and killing the bot over a doc line would be the bigger fault.
        # A battery greps COMMANDS_DATA; no line is the healthy reading.
        var fw: String = String(((cmd_d.get("forge", {}) as Dictionary)).get("what", ""))
        var kparts: PackedStringArray = fw.split("kinds: ", false)
        if kparts.size() < 2:
            _guard_faults.append("FORGE ANCHOR")
            push_error("COMMANDS_DATA FORGE ANCHOR: `forge`.what no longer carries \"kinds: \" - the published kind list can no longer be checked against Gear.KINDS")
            printerr("COMMANDS_DATA FORGE ANCHOR - `forge`.what lost its \"kinds: \" anchor; the kind list is now unchecked")
        else:
            var said: Array = []
            for grp in kparts[1].split(".", false)[0].split("/", false):
                for w in grp.split(",", false):
                    var t := w.strip_edges()
                    if t != "":
                        said.append(t)
            var real: Array = Gear.KINDS.keys()
            var unsaid: Array = real.filter(func(k): return not said.has(k))
            var ghost_k: Array = said.filter(func(k): return not real.has(k))
            if not unsaid.is_empty():
                _guard_faults.append("FORGE DRIFT")
                push_error("COMMANDS_DATA FORGE DRIFT: %d forge kind(s) Gear.KINDS accepts are absent from `forge`.what, so docs/COMMANDS.md does not tell a viewer they can type them: %s" % [unsaid.size(), unsaid])
                printerr("COMMANDS_DATA FORGE DRIFT - %d accepted kind(s) unpublished: %s" % [unsaid.size(), unsaid])
            if not ghost_k.is_empty():
                _guard_faults.append("FORGE GHOST")
                push_error("COMMANDS_DATA FORGE GHOST: `forge`.what names %d kind(s) Gear.KINDS does not accept, so the doc invites a refusal: %s" % [ghost_k.size(), ghost_k])
                printerr("COMMANDS_DATA FORGE GHOST - %d published kind(s) the smith refuses: %s" % [ghost_k.size(), ghost_k])
        # B34: THE FORGE KIND LIST WAS THE FIRST RECITED FIELD ANYONE CHECKED, NOT THE ONLY ONE.
        # The row this hour asked how many other `what` strings make a claim a viewer can check
        # against code, and how many of those already have a guard. I walked all 27 - the count,
        # the authority for each and the reason the unguarded ones stay unguarded are written out
        # in PROGRESS.md B34. THREE more have an authority that is an ENUMERATION or a single
        # NUMBER I can compare exactly, so they are guarded here in the forge's shape:
        #   `enlist`.what recites Roster.CLASSES (15 callings) and Roster.SPECIES (6 peoples) -
        #   the two longest hand-written lists in this file. A calling added to roster.gd tomorrow
        #   is EXACTLY how `greataxe` (S20) and `sceptre` (D94b) reached the smithy unpublished.
        #   `muster`.what publishes "takes six from chat", and QUEUE_MAX above is what actually
        #   turns the seventh viewer away. Change either and nothing else in the house notices.
        # ALL THREE READ CORRECT TODAY - 15/15, 6/6, six vs 6 - and that is the point: they agree
        # by coincidence, not by construction, and this is what makes them stay agreed. Not fatal,
        # the shape every guard above uses: a battery greps COMMANDS_DATA; no line is healthy.
        var ew: String = String(((cmd_d.get("enlist", {}) as Dictionary)).get("what", ""))
        for pair in [["Callings: ", Roster.CLASSES.keys(), "CALLING", "the valley refuses"],
                     ["Peoples: ", Roster.SPECIES.keys(), "PEOPLE", "no such people"]]:
            var e_anchor: String = String(pair[0])
            var e_real: Array = pair[1] as Array
            var e_tag: String = String(pair[2])
            var e_parts: PackedStringArray = ew.split(e_anchor, false)
            if e_parts.size() < 2:
                _guard_faults.append("ENLIST ANCHOR")
                push_error("COMMANDS_DATA ENLIST ANCHOR: `enlist`.what no longer carries \"%s\" - the published %s list can no longer be checked against the code that accepts it" % [e_anchor, e_tag.to_lower()])
                printerr("COMMANDS_DATA ENLIST ANCHOR - `enlist`.what lost its \"%s\" anchor; that list is now unchecked" % e_anchor)
                continue
            var e_said: Array = []
            for w in e_parts[1].split(".", false)[0].split(",", false):
                var t := String(w).strip_edges()
                if t != "":
                    e_said.append(t)
            var e_unsaid: Array = e_real.filter(func(k): return not e_said.has(String(k)))
            var e_ghost: Array = e_said.filter(func(k): return not e_real.has(k))
            if not e_unsaid.is_empty():
                _guard_faults.append("ENLIST %s DRIFT" % e_tag)
                push_error("COMMANDS_DATA ENLIST %s DRIFT: %d %s(s) !enlist accepts are absent from `enlist`.what, so docs/COMMANDS.md does not tell a viewer they can type them: %s" % [e_tag, e_unsaid.size(), e_tag.to_lower(), e_unsaid])
                printerr("COMMANDS_DATA ENLIST %s DRIFT - %d accepted %s(s) unpublished: %s" % [e_tag, e_unsaid.size(), e_tag.to_lower(), e_unsaid])
            if not e_ghost.is_empty():
                _guard_faults.append("ENLIST %s GHOST" % e_tag)
                push_error("COMMANDS_DATA ENLIST %s GHOST: `enlist`.what names %d %s(s) that do not exist, so the doc invites a refusal (%s): %s" % [e_tag, e_ghost.size(), e_tag.to_lower(), String(pair[3]), e_ghost])
                printerr("COMMANDS_DATA ENLIST %s GHOST - %d published %s(s) nothing accepts: %s" % [e_tag, e_ghost.size(), e_tag.to_lower(), e_ghost])
        var mw: String = String(((cmd_d.get("muster", {}) as Dictionary)).get("what", ""))
        var m_words: Dictionary = {"one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
                                   "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10}
        var m_said: int = -1
        for w in m_words:
            if mw.contains("takes %s from chat" % w):
                m_said = int(m_words[w])
                break
        if m_said < 0:
            _guard_faults.append("MUSTER ANCHOR")
            push_error("COMMANDS_DATA MUSTER ANCHOR: `muster`.what no longer says \"takes <number> from chat\" - the published size of the chat queue can no longer be checked against QUEUE_MAX (%d)" % QUEUE_MAX)
            printerr("COMMANDS_DATA MUSTER ANCHOR - `muster`.what lost its \"takes <number> from chat\" phrase; the queue size is now unchecked")
        elif m_said != QUEUE_MAX:
            _guard_faults.append("MUSTER COUNT")
            push_error("COMMANDS_DATA MUSTER COUNT: `muster`.what publishes a chat queue of %d and QUEUE_MAX turns the viewer away at %d - docs/COMMANDS.md promises a place the muster does not have" % [m_said, QUEUE_MAX])
            printerr("COMMANDS_DATA MUSTER COUNT - published %d, enforced %d" % [m_said, QUEUE_MAX])
        # B35: THE SMALLEST CLAIM LEFT WHOSE AUTHORITY IS A NUMBER LIVING IN CODE.
        # B34 named fifteen unguarded `what` claims. Four of them carry a number rather than a
        # list; of those four this is the SMALLEST by measurement, not by feel:
        #   `look`.what "a 10-second pane"  -> Spotlight.LOOK_S, ONE declaration (spotlight.gd:33)
        #     with ONE use site (line 120), a LITERAL DIGIT in the sentence, and the constant is
        #     ALREADY referenced twice in this file (SUB_S, POINTS_S at lines 290-292) - so the
        #     guard adds no dependency and needs no word-to-number table.
        #   `satchel`.what "two fifths"      -> SELL_BACK 0.4, declared TWICE (leaderboard_panel.gd
        #     Satchel:65 and snapshot_pub.gd:40) with ~10 use sites, and a fraction in WORDS.
        #     Bigger on every count: two authorities that can disagree with each OTHER before
        #     either disagrees with me. It is the obvious next one and it is NOT done here.
        #   `bestiary`.what "eight lords"    -> a COUNT over bosses.json, a data file, not a const.
        #   `oil`.what "two delvers"         -> a burn RATE in delve.gd, no constant to read.
        # WHY IT IS WORTH A GUARD AT ALL: a viewer reads "10-second" in docs/COMMANDS.md and the
        # pane is whatever LOOK_S says. Nothing in the house compares them. The free `look` is the
        # one pane a viewer gets WITHOUT paying, so its length is the promise most likely to be
        # quietly tuned - POINTS_S and SUB_S sit on the two lines above it in spotlight.gd.
        # THREE PATHS, the muster shape plus one: the published number differs from the enforced
        # one; the sentence is reworded so no number can be found (ANCHOR, which is what stops the
        # guard going blind); and LOOK_S becomes FRACTIONAL, where a whole-second sentence cannot
        # state it truthfully and an int compare would pass 10.5 as 10. Not fatal - a battery greps
        # COMMANDS_DATA; no line is the healthy reading.
        var lw: String = String(((cmd_d.get("look", {}) as Dictionary)).get("what", ""))
        var l_anchor := "-second pane"
        var l_at: int = lw.find(l_anchor)
        var l_said: int = -1
        if l_at > 0:
            var l_i: int = l_at
            while l_i > 0 and "0123456789".contains(lw.substr(l_i - 1, 1)):
                l_i -= 1
            if l_i < l_at:
                l_said = int(lw.substr(l_i, l_at - l_i))
        var l_real: float = float(Spotlight.LOOK_S)
        if l_said < 0:
            _guard_faults.append("LOOK ANCHOR")
            push_error("COMMANDS_DATA LOOK ANCHOR: `look`.what no longer says \"<number>-second pane\" - the published length of the free look can no longer be checked against Spotlight.LOOK_S (%s)" % str(l_real))
            printerr("COMMANDS_DATA LOOK ANCHOR - `look`.what lost its \"<number>-second pane\" phrase; the pane length is now unchecked")
        elif l_real != floorf(l_real):
            _guard_faults.append("LOOK FRACTION")
            push_error("COMMANDS_DATA LOOK FRACTION: Spotlight.LOOK_S is %s, which no whole-second sentence can state - `look`.what publishes %d-second and the pane is neither" % [str(l_real), l_said])
            printerr("COMMANDS_DATA LOOK FRACTION - LOOK_S %s is not whole seconds; published %d" % [str(l_real), l_said])
        elif float(l_said) != l_real:
            _guard_faults.append("LOOK SECONDS")
            push_error("COMMANDS_DATA LOOK SECONDS: `look`.what publishes a %d-second pane and Spotlight.LOOK_S holds it for %s - docs/COMMANDS.md promises a look the spotlight does not give" % [l_said, str(l_real)])
            printerr("COMMANDS_DATA LOOK SECONDS - published %d, enforced %s" % [l_said, str(l_real)])
        # B36: THE NEXT NUMERIC CLAIM, AND THE FIRST ONE WITH TWO AUTHORITIES.
        # B35 took `look` because it had ONE declaration and named `satchel` as the obvious next
        # one BECAUSE IT HAS TWO: SELL_BACK is declared in leaderboard_panel.gd (class Satchel,
        # line 65) AND in snapshot_pub.gd (line 40), both 0.4 today, with ~10 use sites between
        # them - the sell sheet on stream and the hub's published sell prices. So those two can
        # disagree with EACH OTHER before either disagrees with my sentence, and the viewer then
        # reads one number on the hub and is paid the other at the counter. THAT is the piece
        # worth more than checking my own string, so it is the FIRST path here, not an afterthought:
        # if the two authorities differ there IS no published rate to check against and the guard
        # says so instead of silently believing one of them.
        # `satchel`.what says "two fifths" IN WORDS, not as a digit, so this needs the word table
        # `muster` needed, widened to fractions. The table is the guard's vocabulary, and a rate
        # it cannot say is reported as such in the RATE line rather than hidden - a 0.37 cannot be
        # fixed by rewording the sentence, it needs a different sentence shape, and the reader of
        # the error should be told which of those two they are looking at.
        # THREE PATHS. SPLIT and ANCHOR are the two that stop this going quietly wrong; RATE is
        # the mismatch itself. Not fatal, the shape every guard above uses: push_error + printerr,
        # the commands still answer, and a battery greps COMMANDS_DATA. No line is healthy output.
        var sw: String = String(((cmd_d.get("satchel", {}) as Dictionary)).get("what", ""))
        var s_tail := " of its shop cost"
        var s_words := {"a tenth": 0.1, "one tenth": 0.1, "a fifth": 0.2, "one fifth": 0.2,
                        "a quarter": 0.25, "one quarter": 0.25, "three tenths": 0.3,
                        "a third": 1.0 / 3.0, "one third": 1.0 / 3.0, "two fifths": 0.4,
                        "a half": 0.5, "one half": 0.5, "three fifths": 0.6,
                        "two thirds": 2.0 / 3.0, "seven tenths": 0.7, "three quarters": 0.75,
                        "four fifths": 0.8, "nine tenths": 0.9}
        var s_said: float = -1.0
        var s_phrase := ""
        var s_at: int = sw.find(s_tail)
        if s_at > 0:
            var s_head: String = sw.substr(0, s_at).to_lower()
            for w in s_words:
                var ws := String(w)
                if s_head.ends_with(ws) and ws.length() > s_phrase.length():
                    s_phrase = ws
                    s_said = float(s_words[w])
        var s_panel: float = float(LeaderboardPanel.Satchel.SELL_BACK)
        var s_pub: float = float(SnapshotPublisher.SELL_BACK)
        if absf(s_panel - s_pub) > 0.0005:
            _guard_faults.append("SATCHEL SPLIT")
            push_error("COMMANDS_DATA SATCHEL SPLIT: the sell-back rate is declared TWICE and the two no longer agree - leaderboard_panel.gd Satchel.SELL_BACK is %s and snapshot_pub.gd SELL_BACK is %s, so the counter on stream and the sell prices on the hub pay different money and `satchel`.what cannot be true of both" % [str(s_panel), str(s_pub)])
            printerr("COMMANDS_DATA SATCHEL SPLIT - Satchel.SELL_BACK %s vs SnapshotPublisher.SELL_BACK %s; no single published rate exists" % [str(s_panel), str(s_pub)])
        elif s_said < 0.0:
            _guard_faults.append("SATCHEL ANCHOR")
            push_error("COMMANDS_DATA SATCHEL ANCHOR: `satchel`.what no longer says \"<fraction> of its shop cost\" in words this guard knows - the published sell-back rate can no longer be checked against SELL_BACK (%s)" % str(s_panel))
            printerr("COMMANDS_DATA SATCHEL ANCHOR - `satchel`.what lost its \"<fraction> of its shop cost\" phrase; the sell-back rate is now unchecked")
        elif absf(s_said - s_panel) > 0.0005:
            var s_can := ""
            for w in s_words:
                if absf(float(s_words[w]) - s_panel) <= 0.0005:
                    s_can = String(w)
                    break
            var s_tip: String = "say \"%s\"" % s_can if s_can != "" else "NO fraction phrase this guard knows can state %s - the sentence needs a different shape, not a different word" % str(s_panel)
            _guard_faults.append("SATCHEL RATE")
            push_error("COMMANDS_DATA SATCHEL RATE: `satchel`.what publishes \"%s\" (%s) of shop cost and SELL_BACK pays %s - docs/COMMANDS.md prices a viewer's satchel at money the counter does not pay; %s" % [s_phrase, str(s_said), str(s_panel), s_tip])
            printerr("COMMANDS_DATA SATCHEL RATE - published \"%s\" (%s), enforced %s" % [s_phrase, str(s_said), str(s_panel)])
        # B96: THE SAME NUMBER, SAID IN THREE PLACES, AND THE GUARD ABOVE READS ONE OF THEM.
        # The three paths above check `satchel`.what and nothing else. `satchel`.what is the ONLY
        # one of the three that reaches docs/COMMANDS.md, and that is exactly why it is the only
        # one that was ever checked - the drift arms are built around what the generator
        # publishes. But the sell-back rate is stated to a viewer in THREE places in my own file:
        #   `satchel`.what    "two fifths of its shop cost"  -> published, GATED above.
        #   `satchel`.short   "two fifths of shop cost"      -> chat only. `help_line()` sends it
        #                       verbatim on `!help satchel`; the generator does not publish
        #                       `short` AT ALL (B95's finding), so no drift arm can see it.
        #   `ask.gold`.reply  "pays two fifths of shop cost"  -> answered to a plain question in
        #                       chat by the `ask` tree. The ASK arms above check that topics have
        #                       phrases and are not mute; NOTHING reads what an answer SAYS.
        # SO THE FAILURE IS CONCRETE, not theoretical: change SELL_BACK to 0.3 and the RATE arm
        # goes red on `.what` alone. A lane fixes `.what`, the gate goes green, and `!help satchel`
        # and every plain "how do I get gold" answer keep paying a viewer two fifths at a counter
        # that pays three tenths. A GREEN GATE BESIDE A WRONG SENTENCE IS THE FAULT CLASS THE LEAD
        # NAMED AT 23:58 - it is the one the art lane fixed this hour and the one B95 found in this
        # very file. Here it is a THIRD time, and twice over in one value.
        # THE ARM: sweep every viewer-facing string my file owns - `short` and `what` on all 31
        # commands, and every `ask` topic `reply` - for a known fraction phrase in front of
        # "of shop cost" or "of its shop cost", and require EVERY site to state SELL_BACK. The
        # vocabulary is `s_words`, already built above; this adds no second table to drift.
        # It does NOT fire when SPLIT fired: with two disagreeing authorities there is no rate to
        # check any site against, and saying so once is the honest reading.
        if absf(s_panel - s_pub) <= 0.0005:
            var se_tails: Array[String] = [" of its shop cost", " of shop cost"]
            var se_sites: Array = []
            for se_k in cmd_d:
                var se_row: Dictionary = cmd_d[se_k] as Dictionary
                for se_f in ["short", "what"]:
                    if se_row.has(se_f):
                        se_sites.append(["`%s`.%s" % [String(se_k), se_f], String(se_row[se_f])])
            var se_ask: Dictionary = (ask_d if ask_d is Dictionary else {}) as Dictionary
            var se_top: Dictionary = se_ask.get("topics", {}) as Dictionary
            for se_t in se_top:
                var se_tr: Dictionary = se_top[se_t] as Dictionary
                if se_tr.has("reply"):
                    se_sites.append(["`ask.%s`.reply" % String(se_t), String(se_tr["reply"])])
            var se_bad: Array = []
            var se_seen: int = 0
            for se_pair in se_sites:
                var se_name: String = String((se_pair as Array)[0])
                var se_text: String = String((se_pair as Array)[1]).to_lower()
                for se_tail in se_tails:
                    var se_from: int = 0
                    while true:
                        var se_at: int = se_text.find(se_tail, se_from)
                        if se_at < 0:
                            break
                        se_from = se_at + 1
                        # " of shop cost" is a suffix of " of its shop cost"; count the longer
                        # tail only, or every `.what` is reported twice for one sentence.
                        if se_tail == " of shop cost" and se_text.substr(0, se_at).ends_with(" of its"):
                            continue
                        var se_head: String = se_text.substr(0, se_at)
                        var se_ph := ""
                        var se_val: float = -1.0
                        for se_w in s_words:
                            var se_ws := String(se_w)
                            if se_head.ends_with(se_ws) and se_ws.length() > se_ph.length():
                                se_ph = se_ws
                                se_val = float(s_words[se_w])
                        if se_val < 0.0:
                            continue   # no phrase this guard knows; ANCHOR is the arm for that
                        se_seen += 1
                        if absf(se_val - s_panel) > 0.0005:
                            se_bad.append("%s says \"%s\" (%s)" % [se_name, se_ph, str(se_val)])
            if not se_bad.is_empty():
                _guard_faults.append("SATCHEL ECHO")
                push_error("COMMANDS_DATA SATCHEL ECHO: %d viewer-facing site(s) state a sell-back rate that is not SELL_BACK (%s) - a viewer reads one number and is paid another, and only `satchel`.what is covered by the RATE arm above: %s" % [se_bad.size(), str(s_panel), ", ".join(PackedStringArray(se_bad))])
                printerr("COMMANDS_DATA SATCHEL ECHO - %d site(s) off SELL_BACK %s: %s" % [se_bad.size(), str(s_panel), ", ".join(PackedStringArray(se_bad))])
        # B37: THE ARMOURY - CHOSEN ON SHAPE, AND THE ONLY CLAIM LEFT WHERE *MY OWN FILE*
        # DECLARES THE SAME LADDER TWICE. The row let me pick on shape over size. This one wins
        # on all three of the shapes the row named, which is why it beat the two smaller ones:
        #   TWO DECLARATIONS, BOTH MINE - `armoury`.short AND `armoury`.what each recite
        #   "leather, chainmail, plate, warded plate". Those two can disagree with EACH OTHER
        #   before either disagrees with the game, and then !armoury's one-line reply promises one
        #   ladder and docs/COMMANDS.md's long line promises another. That is B36's SPLIT shape
        #   turning up INSIDE my own three files instead of across two of another lane's, so SPLIT
        #   is the first path again and for the same reason: if the two disagree there is no
        #   published ladder to check, and the guard says so rather than believing one of them.
        #   A DERIVED NUMBER LIST - `armoury`.cost publishes "50 / 150 / 400 / 1000 gold by tier".
        #   Four numbers whose authority is the `cost` field of the very same Gear.ARMOUR rows, and
        #   nothing in the house compared them. So one guard covers the NAMES and THE MONEY.
        #   AN AUTHORITY IN A FILE I DO NOT OWN - scripts/gear.gd is the GAME BUILD's, and it holds
        #   TWO tables, not one: Gear.ARMOUR (names, costs, the found-only flag) and
        ##  B103 CORRECTS THE LINE BELOW AND THE THREE ARMS THAT TRUSTED IT: Gear.ARMOUR is NOT
        ##  the authority for the ladder, the prices or the found-only flag, because NO SHOP READS
        ##  IT. `Roster.buy_armour` charges `Roster.ARMOUR` (roster.gd:183). The ladder, COST and
        ##  FOUND arms below now read Roster.ARMOUR; only ARMOUR_LOOK is still Gear's, and that
        ##  one is correct - it has no second copy. See the B103 block at the end of this guard.
        #   Gear.ARMOUR_LOOK (which pieces actually show, per tier). A tier added there is exactly
        #   how `greataxe` (S20) and `sceptre` (D94b) reached the smithy unpublished.
        # AND IT CORRECTS MY OWN LANE'S RECORD. B36's leftovers list said this claim's authority
        # was "what gear.gd:257-258 only says in a comment". THAT WAS WRONG, and it is why the
        # claim looked smaller than it is. The comment restates the code; the AUTHORITY is
        # Gear.ARMOUR_LOOK, which carries real `boots` / `pauldrons` / `helm` booleans per tier.
        # It is exactly checkable, and it is checked below - read as "every key whose value is a
        # true bool", NOT as a hand-written list of three, so a piece the game build adds
        # tomorrow goes red here instead of silently making my sentence short.
        # SIX PATHS. ANCHOR and SPLIT are the two that stop this going quietly wrong; LADDER, COST,
        # PIECES and FOUND are the four mismatches themselves, and they are INDEPENDENT - the
        # names can be right while the money is wrong, so they do not share an elif. Not fatal,
        # the shape every guard above uses: push_error + printerr, the commands still answer, and
        # a battery greps COMMANDS_DATA. No line is the healthy reading.
        var a_d: Dictionary = (cmd_d.get("armoury", {}) as Dictionary)
        var a_what: String = String(a_d.get("what", ""))
        var a_anchor := "armour tier: "
        # the published ladder, read the same way out of BOTH declarations: everything between the
        # anchor and the first full stop, split on commas. Order is kept - a ladder's order is
        # itself a claim, so leather before plate is checked, not just membership.
        var a_ladders: Array = []
        for a_src in [a_what, String(a_d.get("short", ""))]:
            var a_s := String(a_src)
            var a_out: Array = []
            var a_at: int = a_s.find(a_anchor)
            if a_at >= 0:
                var a_tail: String = a_s.substr(a_at + a_anchor.length())
                var a_stop: int = a_tail.find(".")
                if a_stop >= 0:
                    a_tail = a_tail.substr(0, a_stop)
                for a_w in a_tail.split(",", false):
                    var a_tok := String(a_w).strip_edges().to_lower()
                    if a_tok != "":
                        a_out.append(a_tok)
            a_ladders.append(a_out)
        var a_said: Array = a_ladders[0]
        var a_said_short: Array = a_ladders[1]
        # what the game actually sells, and what it only ever drops. `rags` is neither: cost 0 and
        # no `found`, because it is the state a hero starts in, not a tier anyone buys.
        var a_real: Array = []
        var a_real_cost: Array = []
        var a_found: Array = []
        for a_row in Roster.ARMOUR:
            var a_r: Dictionary = a_row
            var a_nm := String(a_r.get("name", "")).to_lower()
            if a_nm == "":
                continue
            if bool(a_r.get("found", false)):
                a_found.append(a_nm)
            elif float(a_r.get("cost", 0)) > 0.0:
                a_real.append(a_nm)
                a_real_cost.append(int(a_r.get("cost", 0)))
        # the published price ladder, leading digits of each slash-separated piece
        var a_said_cost: Array = []
        for a_w2 in String(a_d.get("cost", "")).split("/", false):
            var a_dig := ""
            var a_piece := String(a_w2).strip_edges()
            for a_i in a_piece.length():
                var a_ch := a_piece[a_i]
                if a_ch >= "0" and a_ch <= "9":
                    a_dig += a_ch
                elif a_dig != "":
                    break
            if a_dig != "":
                a_said_cost.append(int(a_dig))
        # the published pieces, and the pieces ARMOUR_LOOK really turns on across the buyable tiers
        var a_said_pc: Array = []
        var a_pat: int = a_what.find("It shows: ")
        if a_pat >= 0:
            var a_ptail: String = a_what.substr(a_pat + 10)
            var a_pstop: int = a_ptail.find(".")
            if a_pstop >= 0:
                a_ptail = a_ptail.substr(0, a_pstop)
            for a_w3 in a_ptail.split(",", false):
                var a_pc := String(a_w3).strip_edges().to_lower()
                for a_lead in ["a ", "an ", "the "]:
                    if a_pc.begins_with(a_lead):
                        a_pc = a_pc.substr(String(a_lead).length())
                if a_pc != "":
                    a_said_pc.append(a_pc)
        var a_real_pc: Array = []
        for a_i2 in range(1, mini(a_real.size() + 1, Gear.ARMOUR_LOOK.size())):
            var a_lk: Dictionary = Gear.ARMOUR_LOOK[a_i2]
            for a_k in a_lk:
                if typeof(a_lk[a_k]) == TYPE_BOOL and bool(a_lk[a_k]) and not a_real_pc.has(String(a_k)):
                    a_real_pc.append(String(a_k))
        if a_said.is_empty():
            _guard_faults.append("ARMOURY ANCHOR")
            push_error("COMMANDS_DATA ARMOURY ANCHOR: `armoury`.what no longer carries \"%s\" - the published armour ladder can no longer be checked against Roster.ARMOUR (%s), and neither can the prices" % [a_anchor, a_real])
            printerr("COMMANDS_DATA ARMOURY ANCHOR - `armoury`.what lost its \"%s\" anchor; the ladder and the prices are now unchecked" % a_anchor)
        else:
            if a_said_short != a_said:
                var a_sp_tip: String = "`armoury`.short no longer carries the ladder at all" if a_said_short.is_empty() else "short says %s" % str(a_said_short)
                _guard_faults.append("ARMOURY SPLIT")
                push_error("COMMANDS_DATA ARMOURY SPLIT: the armour ladder is declared TWICE in data/commands.json and the two no longer agree - `armoury`.what says %s and %s, so !armoury's reply and docs/COMMANDS.md promise different tiers and no single published ladder exists to check against Roster.ARMOUR" % [str(a_said), a_sp_tip])
                printerr("COMMANDS_DATA ARMOURY SPLIT - what %s vs short %s; no single published ladder" % [str(a_said), str(a_said_short)])
            if a_said != a_real:
                var a_unsaid: Array = a_real.filter(func(n): return not a_said.has(n))
                var a_ghost2: Array = a_said.filter(func(n): return not a_real.has(n))
                var a_tip: String = "same names, WRONG ORDER - a ladder's order is the claim" if (a_unsaid.is_empty() and a_ghost2.is_empty()) else "unpublished: %s; invented: %s" % [str(a_unsaid), str(a_ghost2)]
                _guard_faults.append("ARMOURY LADDER")
                push_error("COMMANDS_DATA ARMOURY LADDER: `armoury`.what publishes %s and Roster.ARMOUR sells %s - docs/COMMANDS.md does not describe the armour a viewer can actually buy; %s" % [str(a_said), str(a_real), a_tip])
                printerr("COMMANDS_DATA ARMOURY LADDER - published %s, sold %s; %s" % [str(a_said), str(a_real), a_tip])
            if a_said_cost != a_real_cost:
                var a_ctip: String = "`armoury`.cost no longer states a slash-separated price ladder" if a_said_cost.is_empty() else "published %d price(s) against %d tier(s)" % [a_said_cost.size(), a_real_cost.size()]
                _guard_faults.append("ARMOURY COST")
                push_error("COMMANDS_DATA ARMOURY COST: `armoury`.cost publishes %s gold by tier and Roster.ARMOUR charges %s - a viewer is quoted a price the shop does not take; %s" % [str(a_said_cost), str(a_real_cost), a_ctip])
                printerr("COMMANDS_DATA ARMOURY COST - published %s, charged %s" % [str(a_said_cost), str(a_real_cost)])
            if a_said_pc != a_real_pc:
                var a_ptip: String = "`armoury`.what no longer carries \"It shows: \"" if a_said_pc.is_empty() else "published %s" % str(a_said_pc)
                _guard_faults.append("ARMOURY PIECES")
                push_error("COMMANDS_DATA ARMOURY PIECES: `armoury`.what says the armour shows %s and Gear.ARMOUR_LOOK turns on %s across the buyable tiers - the doc tells a viewer what they will see on the body and the body shows something else; %s" % [str(a_said_pc), str(a_real_pc), a_ptip])
                printerr("COMMANDS_DATA ARMOURY PIECES - published %s, dressed %s" % [str(a_said_pc), str(a_real_pc)])
            var a_sold_found: Array = a_found.filter(func(n): return a_said.has(n))
            var a_mute_found: Array = a_found.filter(func(n): return not a_what.to_lower().contains(String(n)))
            if not a_sold_found.is_empty() or not a_mute_found.is_empty():
                var a_ftip: String = "named in the buy ladder though it cannot be bought: %s" % str(a_sold_found) if not a_sold_found.is_empty() else "found-only armour `armoury`.what never mentions: %s" % str(a_mute_found)
                _guard_faults.append("ARMOURY FOUND")
                push_error("COMMANDS_DATA ARMOURY FOUND: Roster.ARMOUR marks %s as found-only (cost 0, `found` true) and `armoury`.what does not tell that truth - %s" % [str(a_found), a_ftip])
                printerr("COMMANDS_DATA ARMOURY FOUND - found-only %s; %s" % [str(a_found), a_ftip])
        # B38: THE BREW - CHOSEN ON SHAPE AGAIN, AND ITS AUTHORITIES SIT IN TWO FILES I DO NOT
        # OWN. The row let me choose on shape over size; `brew` beat the three small ones that
        # were left in my own file on four counts:
        #   TWO DECLARATIONS, BOTH MINE - `brew`.short and `brew`.what EACH publish the no-name
        #   default. They can disagree with each other before either disagrees with the game, and
        #   then !brew's reply and docs/COMMANDS.md promise different brews. That is B36's SPLIT
        #   shape inside my own file, so SPLIT is the first path again and for the same reason:
        #   if the two disagree there is no published default to check, and the guard says so
        #   rather than believing one of them. They are NOT compared as strings - "Draughts of
        #   Mending" and "Mending" are the same promise - each is RESOLVED to a brew key and the
        #   keys are compared.
        #   THE DEFAULT WAS A BARE STRING INTO ANOTHER LANE'S DATA - data/potions.json is the
        #   CONTENT writer's, it holds 232 brews and it grows most hours. Rename or drop the row
        #   both my sentences name and !brew with no name stops buying what they promise. The
        #   literal is BREW_DEFAULT now, so there is something to check against.
        #   A NAME OWNED BY CONTENT - the row's own `name` is the display name a viewer is shown.
        #   The guard SINGULARISES word by word, so the sentence may pluralise, which the English
        #   wants, while a real rename still fires.
        #   A PRICE DECLARED TWICE AND ONE OF THE TWO IS DEAD - `brew`.cost publishes a number for
        #   the default; Roster.POTION_COST is what the no-name path actually CHARGES (buy_potion,
        #   not buy_brew); and the potions.json row ALSO carries a cost that buy_potion never
        #   reads. The two agree by coincidence today, not by construction.
        #   NOT CHECKED, DELIBERATELY: the twelve names `what` lists against the 232 brews the
        #   apothecary makes. Which brews a one-second chat line should name is a CONTENT call and
        #   not a drift. B34, B35, B36 and B37 each named it and left it; so does this.
        var b_d: Dictionary = (cmd_d.get("brew", {}) as Dictionary)
        var b_what: String = String(b_d.get("what", ""))
        var b_anchor := "no name buys "
        # the published default, read the same way out of BOTH declarations: the words between the
        # anchor and the first full stop, singularised, then resolved to a brew key
        var b_said: Array = []
        for b_src in [b_what, String(b_d.get("short", ""))]:
            var b_s := String(b_src).to_lower()
            var b_at: int = b_s.find(b_anchor)
            var b_phrase := ""
            if b_at >= 0:
                b_phrase = b_s.substr(b_at + b_anchor.length())
                var b_stop: int = b_phrase.find(".")
                if b_stop >= 0:
                    b_phrase = b_phrase.substr(0, b_stop)
                var b_words: Array = []
                for b_w in b_phrase.strip_edges().split(" ", false):
                    var b_t := String(b_w).strip_edges()
                    if b_t.length() > 3 and b_t.ends_with("s"):
                        b_t = b_t.substr(0, b_t.length() - 1)
                    if b_t != "":
                        b_words.append(b_t)
                b_phrase = " ".join(b_words)
            b_said.append(b_phrase)
        var b_ph_what := String(b_said[0])
        var b_ph_short := String(b_said[1])
        var b_key_what := Roster.potion_key(b_ph_what) if b_ph_what != "" else ""
        var b_key_short := Roster.potion_key(b_ph_short) if b_ph_short != "" else ""
        var b_rows: Dictionary = (Roster.potions().get("potions", {}) as Dictionary)
        var b_row: Dictionary = (b_rows.get(BREW_DEFAULT, {}) as Dictionary)
        # the twelve names the sentence lists, kept to the GHOST direction only
        var b_ghost: Array = []
        var b_nat: int = b_what.find("Names: ")
        if b_nat >= 0:
            var b_ntail: String = b_what.substr(b_nat + 7)
            var b_nstop: int = b_ntail.find(".")
            if b_nstop >= 0:
                b_ntail = b_ntail.substr(0, b_nstop)
            for b_n in b_ntail.split(",", false):
                var b_name := String(b_n).strip_edges().to_lower()
                var b_par: int = b_name.find("(")
                if b_par >= 0:
                    b_name = b_name.substr(0, b_par).strip_edges()
                if b_name != "" and Roster.potion_key(b_name) == "":
                    b_ghost.append(b_name)
        # the published price of the default, and the two numbers behind it
        var b_cost_s: String = String(b_d.get("cost", "")).to_lower()
        var b_said_cost := -1
        var b_cat: int = b_cost_s.find(BREW_DEFAULT)
        if b_cat >= 0:
            var b_dig := ""
            for b_i in range(b_cat, b_cost_s.length()):
                var b_ch := b_cost_s[b_i]
                if b_ch >= "0" and b_ch <= "9":
                    b_dig += b_ch
                elif b_dig != "":
                    break
            if b_dig != "":
                b_said_cost = int(b_dig)
        if b_ph_what == "":
            _guard_faults.append("BREW ANCHOR")
            push_error("COMMANDS_DATA BREW ANCHOR: `brew`.what no longer says \"%s<brew>.\" - the published no-name default can no longer be checked against BREW_DEFAULT (%s)" % [b_anchor, BREW_DEFAULT])
            printerr("COMMANDS_DATA BREW ANCHOR - `brew`.what lost its \"%s\" phrase; the default is now unchecked" % b_anchor)
        else:
            if b_key_what != b_key_short:
                var b_sp_tip: String = "`brew`.short no longer publishes the default at all" if b_ph_short == "" else "short says \"%s\" (%s)" % [b_ph_short, "no such brew" if b_key_short == "" else b_key_short]
                _guard_faults.append("BREW SPLIT")
                push_error("COMMANDS_DATA BREW SPLIT: the no-name default is declared TWICE in data/commands.json and the two no longer name the same brew - `brew`.what says \"%s\" (%s) and %s, so !brew's reply and docs/COMMANDS.md promise different brews and no single published default exists to check against BREW_DEFAULT (%s)" % [b_ph_what, "no such brew" if b_key_what == "" else b_key_what, b_sp_tip, BREW_DEFAULT])
                printerr("COMMANDS_DATA BREW SPLIT - what \"%s\" vs short \"%s\"; no single published default" % [b_ph_what, b_ph_short])
            if b_key_what == "":
                _guard_faults.append("BREW DEFAULT")
                push_error("COMMANDS_DATA BREW DEFAULT: `brew`.what publishes \"%s\" as the no-name buy and the apothecary makes no such brew - data/potions.json has no row the sentence can resolve to, so docs/COMMANDS.md names a brew a viewer cannot get" % b_ph_what)
                printerr("COMMANDS_DATA BREW DEFAULT - published \"%s\" resolves to no brew" % b_ph_what)
            elif b_key_what != BREW_DEFAULT:
                ## B82: THIS ARM USED TO BE TAGGED "BREW DEFAULT" TOO, THE SAME AS THE ARM ABOVE.
                ## Two different faults under one name: the arm above means the published default
                ## resolves to NO brew, this one means it resolves to a brew that is not the one
                ## !brew actually buys. push_error told them apart; guard_faults() could not, and
                ## guard_faults() is the reading a harness gates on (B48). Measured on the shipped
                ## file: both arms reported ["BREW DEFAULT"]. One tag, so the count can name which.
                _guard_faults.append("BREW DEFAULT MISMATCH")
                push_error("COMMANDS_DATA BREW DEFAULT MISMATCH: `brew`.what publishes \"%s\", which is the brew `%s`, and !brew with no name buys `%s` - the doc promises one brew and the command buys another" % [b_ph_what, b_key_what, BREW_DEFAULT])
                printerr("COMMANDS_DATA BREW DEFAULT MISMATCH - published `%s`, bought `%s`" % [b_key_what, BREW_DEFAULT])
        if b_row.is_empty():
            _guard_faults.append("BREW KEY")
            push_error("COMMANDS_DATA BREW KEY: BREW_DEFAULT is `%s` and data/potions.json carries no such row - !brew with no name charges and counts a brew the apothecary no longer makes, and the name both of my sentences publish has no authority left" % BREW_DEFAULT)
            printerr("COMMANDS_DATA BREW KEY - potions.json has no `%s` row" % BREW_DEFAULT)
        else:
            # the display name content owns, singularised the same way the sentence was
            var b_rn_words: Array = []
            for b_w2 in String(b_row.get("name", "")).to_lower().split(" ", false):
                var b_t2 := String(b_w2).strip_edges()
                if b_t2.length() > 3 and b_t2.ends_with("s"):
                    b_t2 = b_t2.substr(0, b_t2.length() - 1)
                if b_t2 != "":
                    b_rn_words.append(b_t2)
            var b_real_name := " ".join(b_rn_words)
            if b_ph_what != "" and b_real_name != "" and not b_ph_what.contains(b_real_name):
                _guard_faults.append("BREW NAME")
                push_error("COMMANDS_DATA BREW NAME: `brew`.what calls the no-name buy \"%s\" and data/potions.json calls that row \"%s\" - docs/COMMANDS.md and !brew's own reply publish a name the apothecary does not use (plurals allowed, this is a rename)" % [b_ph_what, String(b_row.get("name", ""))])
                printerr("COMMANDS_DATA BREW NAME - published \"%s\", row is \"%s\"" % [b_ph_what, String(b_row.get("name", ""))])
            var b_row_cost := int(b_row.get("cost", -1))
            if b_row_cost >= 0 and b_row_cost != Roster.POTION_COST:
                _guard_faults.append("BREW PRICE SPLIT")
                push_error("COMMANDS_DATA BREW PRICE SPLIT: the default brew's price is declared TWICE and the two no longer agree - Roster.POTION_COST is %d and is what the no-name path CHARGES (buy_potion), and the potions.json `%s` row says %d, which buy_potion never reads. A viewer pays %d whatever the data says" % [Roster.POTION_COST, BREW_DEFAULT, b_row_cost, Roster.POTION_COST])
                printerr("COMMANDS_DATA BREW PRICE SPLIT - POTION_COST %d charged, potions.json row %d dead" % [Roster.POTION_COST, b_row_cost])
        if b_said_cost < 0:
            _guard_faults.append("BREW COST ANCHOR")
            push_error("COMMANDS_DATA BREW COST ANCHOR: `brew`.cost no longer carries a number beside \"%s\" - the published price of the no-name buy can no longer be checked against Roster.POTION_COST (%d)" % [BREW_DEFAULT, Roster.POTION_COST])
            printerr("COMMANDS_DATA BREW COST ANCHOR - `brew`.cost lost its %s number" % BREW_DEFAULT)
        elif b_said_cost != Roster.POTION_COST:
            _guard_faults.append("BREW COST")
            push_error("COMMANDS_DATA BREW COST: `brew`.cost publishes %d gold for the no-name buy and Roster.POTION_COST charges %d - docs/COMMANDS.md prices a brew at money the apothecary does not take" % [b_said_cost, Roster.POTION_COST])
            printerr("COMMANDS_DATA BREW COST - published %d, charged %d" % [b_said_cost, Roster.POTION_COST])
        if not b_ghost.is_empty():
            _guard_faults.append("BREW GHOST")
            push_error("COMMANDS_DATA BREW GHOST: `brew`.what names %d brew(s) the apothecary does not accept, so the doc invites a refusal: %s" % [b_ghost.size(), b_ghost])
            printerr("COMMANDS_DATA BREW GHOST - %d unaccepted name(s): %s" % [b_ghost.size(), b_ghost])
        # B40: THE THREE FLAT PRICES BESIDE THE ONE B39 GUARDED.
        # B39 closed the brew's price: `brew`.cost publishes a number and Roster.POTION_COST is
        # what buy_potion actually CHARGES, and the two agreed by coincidence until the guard
        # made them agree by construction. POTION_COST is roster.gd:210. Lines 214, 215 and 216
        # of the same file are OIL_COST, REROLL_COST and RESPEC_COST - three more flat prices,
        # each PUBLISHED BY ME in data/commands.json and each charged from a single constant,
        # and not one of them was checked. I found them by measurement, not by feel: I walked
        # every number any `what` or `cost` string in my own file states and asked what reads it.
        # These three are the only ones left whose authority is ONE exact integer in code.
        # WHY IT MATTERS AND WHY IT IS SILENT: a viewer reads "200 gold" in docs/COMMANDS.md,
        # types !respec, and is charged RESPEC_COST whatever my doc says. Nothing in the house
        # compares the two. The cost strings are MINE, so the lie would be mine to publish, and
        # the number that gets taken off a hero is the one a viewer can count in their purse.
        # `dye` WAS NAMED HERE AND IS NOW GUARDED BELOW (B41): its authority is a DATA key in
        # items.json plus a roster.gd fallback, not one constant, which is why it waited an hour.
        # WHAT I AM STILL NOT CLAIMING: `wear`.cost publishes a RANGE
        # (30-420) and `forge`/`armoury` publish tier LISTS that already carry their own guards.
        ## B83: THE SENTENCE ABOVE IS STALE AND IT COST ME A MEASUREMENT, SO IT IS CORRECTED HERE
        ## RATHER THAN REWRITTEN. `wear`.cost no longer publishes 30-420; it publishes 30-520, and
        ## the range IS claimed now - WEAR SPAN LOW and WEAR SPAN HIGH below read the cheapest and
        ## dearest accessory/cosmetic row out of data/items.json and check both ends. A seat that
        ## reads B40's words alone goes looking for an unguarded number that was guarded hours ago.
        ## B40's own walk still holds at 31 commands: I re-walked every digit published in every
        ## `what`, `short`, `cost`, `args` and `example` across all 31 (the set was 26 when B40
        ## wrote the line) - forge 60/160/420/1100, armoury 50/150/400/1000, brew 35 and 40-480,
        ## oil 12, wear 30-520, dye 25, reroll 120, respec 200, look 10, miniboss 36 - and every
        ## one of them already sits under an arm. No published number in this file is unwatched.
        for pr in [["oil", Roster.OIL_COST, "Roster.OIL_COST", "a flask of lamp oil (buy_oil)"],
                   ["reroll", Roster.REROLL_COST, "Roster.REROLL_COST", "a living hero's re-throw (reroll)"],
                   ["respec", Roster.RESPEC_COST, "Roster.RESPEC_COST", "a change of calling (respec)"]]:
            var p_key: String = String(pr[0])
            var p_real: int = int(pr[1])
            var p_name: String = String(pr[2])
            var p_what: String = String(pr[3])
            var p_cost: String = String(((cmd_d.get(p_key, {}) as Dictionary)).get("cost", ""))
            # the number this file PUBLISHES: the digits that stand immediately before "gold".
            # `reroll` prices two cases in one string ("free when dead; 120 gold alive") and the
            # guarded one is the paid case, which is the one carrying the number.
            var p_said: int = -1
            var p_dig := ""
            for p_i in p_cost.length():
                var p_c := p_cost[p_i]
                if p_c >= "0" and p_c <= "9":
                    p_dig += p_c
                else:
                    if p_dig != "" and p_cost.substr(p_i).begins_with(" gold"):
                        p_said = int(p_dig)
                        break
                    p_dig = ""
            if p_said < 0:
                _guard_faults.append("PRICE ANCHOR")
                push_error("COMMANDS_DATA PRICE ANCHOR: `%s`.cost no longer carries a number before \"gold\" - the published price of %s can no longer be checked against %s (%d)" % [p_key, p_what, p_name, p_real])
                printerr("COMMANDS_DATA PRICE ANCHOR - `%s`.cost lost its gold number; that price is now unchecked" % p_key)
            elif p_said != p_real:
                _guard_faults.append("PRICE")
                push_error("COMMANDS_DATA PRICE: `%s`.cost publishes %d gold for %s and %s charges %d - docs/COMMANDS.md prices it at money the town does not take, and the viewer finds out by paying" % [p_key, p_said, p_what, p_name, p_real])
                printerr("COMMANDS_DATA PRICE - `%s` published %d, charged %d" % [p_key, p_said, p_real])
        # B41: THE `dye` PRICE - THE ONE B40 NAMED AND REFUSED TO CLAIM.
        # B40 guarded three flat prices whose authority was ONE integer constant in roster.gd and
        # said plainly that `dye` was a different shape: `dye`.cost publishes 25 and the dyer
        # charges `int(items().get("dye_cost", 25))` at roster.gd:1258. So the number a viewer
        # actually pays comes out of data/items.json, which is the CONTENT lane's file, and if
        # that key is ever absent the dyer falls back to a literal written inside roster.gd, which
        # is the GAME BUILD lane's file. ONE PRICE DECLARED IN THREE LANES' FILES, all three
        # reading 25 today by coincidence, and nothing in the house compared any pair of them.
        # HOW I READ THE CHARGED NUMBER: through `Roster.items()`, the same static accessor the
        # dyer itself calls, so the guard compares against the authority actually in play instead
        # of against a copy of it. I DO NOT RESTATE THE 25 FALLBACK ON MY SIDE - a fourth copy of
        # a price would be the defect, not the guard. When the key is gone there is no number to
        # compare and the dead key IS the finding, so that arm reports the key, not a mismatch.
        var dy_cost: String = String(((cmd_d.get("dye", {}) as Dictionary)).get("cost", ""))
        # the number this file PUBLISHES: the digits standing immediately before "gold", read the
        # same way B40 read its three, so one published-price reader is used for every flat price.
        var dy_said: int = -1
        var dy_dig := ""
        for dy_i in dy_cost.length():
            var dy_c := dy_cost[dy_i]
            if dy_c >= "0" and dy_c <= "9":
                dy_dig += dy_c
            else:
                if dy_dig != "" and dy_cost.substr(dy_i).begins_with(" gold"):
                    dy_said = int(dy_dig)
                    break
                dy_dig = ""
        var dy_items: Dictionary = Roster.items()
        if dy_said < 0:
            _guard_faults.append("DYE ANCHOR")
            push_error("COMMANDS_DATA DYE ANCHOR: `dye`.cost no longer carries a number before \"gold\" - the published price of a dyeing can no longer be checked against data/items.json `dye_cost`, which is the number the dyer charges")
            printerr("COMMANDS_DATA DYE ANCHOR - `dye`.cost lost its gold number; the dyer's price is now unchecked")
        # RED-PROVED AT B45 under the supervisor's 03:16 cross-lane scratch-and-restore
        # exception: `dye_cost` lifted out of data/items.json, this arm fired, items.json restored
        # byte-identical (md5 4f2e8b57...) and L14_TEST green on the restored bytes. It was written
        # at B41 and shipped unproven for two cycles because the file is the CONTENT lane's.
        elif not dy_items.has("dye_cost"):
            _guard_faults.append("DYE AUTHORITY")
            push_error("COMMANDS_DATA DYE AUTHORITY: data/items.json carries no `dye_cost` key, so the dyer is charging the fallback literal inside roster.gd's `items().get(\"dye_cost\", ...)` and the data key that is supposed to own this price is DEAD - the dyer can no longer be re-priced from the data file at all, and `dye`.cost publishes %d gold against nothing" % dy_said)
            printerr("COMMANDS_DATA DYE AUTHORITY - items.json lost `dye_cost`; the dyer is on roster.gd's fallback and my published %d is unanchored" % dy_said)
        else:
            var dy_raw: Variant = dy_items.get("dye_cost")
            var dy_real: int = int(dy_raw)
            if dy_real != dy_said:
                _guard_faults.append("DYE COST")
                push_error("COMMANDS_DATA DYE COST: `dye`.cost publishes %d gold for a dyeing and the dyer charges %d, read from data/items.json `dye_cost` (raw value `%s`) - docs/COMMANDS.md prices the dyer at money the town does not take, and a viewer finds out by paying" % [dy_said, dy_real, str(dy_raw)])
                printerr("COMMANDS_DATA DYE COST - published %d, charged %d (items.json `dye_cost` = %s)" % [dy_said, dy_real, str(dy_raw)])

        # ---- B43: THE PUBLISHED DYE COLOURS. A LIST, NOT A NUMBER. ----------------------
        # The team lead's row asked for the NEXT CLASS of thing on my surface that nothing
        # vouches for - "a NAME, a LIST or a STATE your commands publish and nothing compares to
        # what the game does". B40, B41 and B42 took the numbers; this is the first LIST.
        # `dye`.what publishes TEN colour names and the viewer types one of them straight back at
        # the bot. The dyer's authority is `items().get("dyes", {})` at roster.gd:1252 - and C-71
        # put TWO HUNDRED AND EIGHTY-ONE dyes in that table. Nothing in the house has ever
        # compared my ten names against it. All ten are accepted TODAY, which is exactly why this
        # is worth guarding and not worth celebrating: content owns items.json, has three swap
        # sets pending on it right now, and a rename of one key turns one of my published names
        # into a refusal with nothing anywhere going red.
        # THE ASYMMETRY IS THE WHOLE POINT, AND IT IS WHY THIS GUARD HAS NO DRIFT ARM.
        # A colour I PUBLISH that the dyer REFUSES is a defect: the doc invites a viewer to spend
        # a command on a name that cannot work. A colour the dyer ACCEPTS that I DO NOT PUBLISH
        # is BY DESIGN - roster.gd's own comment records that the full list ran ~2800 chars and
        # chat cut it at 480 mid-word, so naming a handful is the deliberate shape. A drift arm
        # here would go red on 271 names on the first run and would be deleted by the next seat.
        # I ALSO CHECK `dye`.example. It is not decoration - it is the one string a viewer copies
        # verbatim, so a dead name there is a refusal handed out pre-typed.
        # I DO NOT RESTATE THE TEN NAMES ON MY SIDE. They are read out of the sentence that
        # publishes them; a second copy inside the guard would be the defect, not the guard.
        # A battery greps COMMANDS_DATA; no line is the healthy reading.
        var dy_what: String = String(((cmd_d.get("dye", {}) as Dictionary)).get("what", ""))
        var dy_ex: String = String(((cmd_d.get("dye", {}) as Dictionary)).get("example", ""))
        var dy_col_anchor := " cloak: "
        var dy_said_cols: Array[String] = []
        var dy_ci := dy_what.find(dy_col_anchor)
        if dy_ci >= 0:
            var dy_tail := dy_what.substr(dy_ci + dy_col_anchor.length()).strip_edges()
            if dy_tail.ends_with("."):
                dy_tail = dy_tail.substr(0, dy_tail.length() - 1)
            for dy_part in dy_tail.split(","):
                var dy_n := String(dy_part).strip_edges().to_lower()
                if dy_n != "" and not dy_said_cols.has(dy_n):
                    dy_said_cols.append(dy_n)
        # the example's argument is a published name too: "!dye teal" -> "teal"
        var dy_ex_col := ""
        var dy_ex_parts := dy_ex.strip_edges().split(" ", false)
        if dy_ex_parts.size() >= 2 and String(dy_ex_parts[0]).to_lower().begins_with("!dye"):
            dy_ex_col = String(dy_ex_parts[1]).strip_edges().to_lower()
        var dy_dyes_raw: Variant = dy_items.get("dyes", null)
        if dy_said_cols.is_empty():
            _guard_faults.append("DYE COLOURS ANCHOR")
            push_error("COMMANDS_DATA DYE COLOURS ANCHOR: `dye`.what no longer carries its \"%s\" colour list in words this guard can read - the colour names docs/COMMANDS.md invites a viewer to type can no longer be checked against the dyer's table, so a dead name would reach chat silently" % dy_col_anchor.strip_edges())
            printerr("COMMANDS_DATA DYE COLOURS ANCHOR - `dye`.what lost its \"%s\" colour list; the published names are now unchecked" % dy_col_anchor.strip_edges())
        # RED-PROVED AT B45 under the same 03:16 exception: `dyes` lifted out of data/items.json,
        # this arm fired naming all 10 published colours, file restored byte-identical and proved
        # by md5. Written at B43, unproven until then.
        elif not (dy_dyes_raw is Dictionary) or (dy_dyes_raw as Dictionary).is_empty():
            _guard_faults.append("DYE COLOURS AUTHORITY")
            push_error("COMMANDS_DATA DYE COLOURS AUTHORITY: data/items.json carries no usable `dyes` table (raw `%s`), so Roster.dye refuses EVERY name and answers with a count of nothing - all %d colours `dye`.what publishes are unanchored at once, and the command is dead rather than mispriced" % [str(dy_dyes_raw), dy_said_cols.size()])
            printerr("COMMANDS_DATA DYE COLOURS AUTHORITY - items.json has no usable `dyes`; all %d published colours are dead" % dy_said_cols.size())
        else:
            var dy_dyes: Dictionary = dy_dyes_raw as Dictionary
            var dy_ghost: Array[String] = []
            for dy_n in dy_said_cols:
                if not dy_dyes.has(dy_n):
                    dy_ghost.append(dy_n)
            if not dy_ghost.is_empty():
                _guard_faults.append("DYE COLOURS GHOST")
                push_error("COMMANDS_DATA DYE COLOURS GHOST: `dye`.what publishes %d colour(s) the dyer does not accept, so docs/COMMANDS.md invites a refusal a viewer pays a command to discover - the dyer's `dyes` table holds %d name(s) and none of these is among them: %s" % [dy_ghost.size(), dy_dyes.size(), dy_ghost])
                printerr("COMMANDS_DATA DYE COLOURS GHOST - %d published colour(s) the dyer refuses: %s" % [dy_ghost.size(), dy_ghost])
            if dy_ex_col != "" and not dy_dyes.has(dy_ex_col):
                _guard_faults.append("DYE EXAMPLE GHOST")
                push_error("COMMANDS_DATA DYE EXAMPLE GHOST: `dye`.example is \"%s\" and the dyer does not accept `%s` - the example is the one string a viewer copies verbatim out of docs/COMMANDS.md, so this hands out a pre-typed refusal" % [dy_ex, dy_ex_col])
                printerr("COMMANDS_DATA DYE EXAMPLE GHOST - example colour `%s` is not in the dyer's table" % dy_ex_col)
        # ---- B44: THE FIRST STATE GUARDED. WHERE THE FREE LOOK GOES AND HOW IT RANKS. ------
        # The row asked for a STATE: a condition or mode my commands publish as true of the game
        # that nothing compares against what the game actually does. B40-B42 took the numbers,
        # B43 took the first list. `look`.what is the densest state sentence on my surface - it
        # publishes FOUR separate claims about the free look and B35 guarded only the first:
        #   1. "a 10-second pane"              -> Spotlight.LOOK_S. GUARDED ALREADY (B35 above).
        #   2. "in the channel-points lane"    -> the pane a viewer actually sees it in, whose
        #      title in words is Spotlight.KIND - the pane's OWN label (spotlight.gd:32, L62,
        #      Mr. E's own ask that every pane say what it is FOR). UNGUARDED until now.
        #   3. "(teal)"                        -> that lane's colour, Spotlight.COL, which IS
        #      UiTheme.KIND - the table the frame is drawn from. UNGUARDED until now.
        #   4. "Cheers, subs and redeems get their own longer panes" -> a COMPARATIVE state:
        #      every paid pane outlasts the free one. UNGUARDED until now, and the one most
        #      likely to go quietly false, because LOOK_S, POINTS_S and SUB_S sit on three
        #      CONSECUTIVE LINES (spotlight.gd:33-35) and a re-tune touches one of them.
        #      The smallest cheer is the test, not the biggest: bits_seconds(1) is the floor a
        #      viewer gets for the cheapest cheer there is, so that is what must still beat free.
        # I READ THE LANE THROUGH ITS TITLE AND THE COLOUR THROUGH THE KEY THE TITLE RESOLVED TO.
        # There is no lane name and no colour restated on my side - if I wrote "points" in here
        # the guard would be vouching for its own copy, which is the defect B43 was about.
        # ONE CLAUSE IN THAT SENTENCE I CANNOT CHECK AND I WILL NOT PRETEND TO: "only when nobody
        # has redeemed it or is waiting". That gate is BEHAVIOUR - spotlight.gd:115-118 turns the
        # free look away when the points lane has a current pane OR a non-empty queue - and no
        # constant states it. Proving it needs a behavioural harness under tools/, which is not
        # my file. It is named here so the next seat finds it as a known gap, not a discovery.
        # THE COLOUR ARM IS A JUDGEMENT AND IS DECLARED AS ONE. Every other arm I have shipped
        # compares a published token against a stored token. "teal" is a WORD FOR A HUE, so this
        # arm asks of the real Color only what the word cannot be wrong about: red is the
        # smallest channel, green and blue are both strong, and they are close to each other.
        # That catches the swap that matters (the lane re-coloured orange, purple or grey while
        # docs/COMMANDS.md still says teal) and it will NOT catch a teal drifting to a cyan.
        # A battery greps COMMANDS_DATA; no line is the healthy reading.
        var lk_what: String = String(((cmd_d.get("look", {}) as Dictionary)).get("what", ""))
        var lk_lane_said := ""
        var lk_col_said := ""
        var lk_mark := " lane ("
        var lk_at := lk_what.find(lk_mark)
        if lk_at > 0:
            var lk_head := lk_what.substr(0, lk_at)
            var lk_the := lk_head.rfind("the ")
            if lk_the >= 0:
                lk_lane_said = lk_head.substr(lk_the + 4).strip_edges().to_lower().replace("-", " ")
            var lk_rest := lk_what.substr(lk_at + lk_mark.length())
            var lk_close := lk_rest.find(")")
            if lk_close > 0:
                lk_col_said = lk_rest.substr(0, lk_close).strip_edges().to_lower()
        var lk_key := ""
        var lk_titles: Array[String] = []
        for lk_l in Spotlight.LANES:
            var lk_t := String(Spotlight.KIND.get(lk_l, "")).strip_edges().to_lower().replace("-", " ")
            lk_titles.append("%s=\"%s\"" % [String(lk_l), lk_t])
            if lk_t != "" and lk_t == lk_lane_said and lk_key == "":
                lk_key = String(lk_l)
        if lk_lane_said == "" or lk_col_said == "":
            _guard_faults.append("LOOK LANE ANCHOR")
            push_error("COMMANDS_DATA LOOK LANE ANCHOR: `look`.what no longer says \"in the <lane> lane (<colour>)\" - the pane the free look lands in, and the colour a viewer is told to watch for, can no longer be checked against Spotlight.KIND and Spotlight.COL")
            printerr("COMMANDS_DATA LOOK LANE ANCHOR - `look`.what lost its \"<lane> lane (<colour>)\" phrase; the lane and its colour are now unchecked")
        elif lk_key == "":
            _guard_faults.append("LOOK LANE GHOST")
            push_error("COMMANDS_DATA LOOK LANE GHOST: `look`.what sends a viewer to the \"%s\" lane and no spotlight lane carries that title - the pane titles are %s, so docs/COMMANDS.md points at a pane that is not on screen" % [lk_lane_said, lk_titles])
            printerr("COMMANDS_DATA LOOK LANE GHOST - published lane \"%s\" matches no pane title: %s" % [lk_lane_said, lk_titles])
        else:
            var lk_c_raw: Variant = Spotlight.COL.get(lk_key, null)
            if not (lk_c_raw is Color):
                _guard_faults.append("LOOK COLOUR AUTHORITY")
                push_error("COMMANDS_DATA LOOK COLOUR AUTHORITY: the `%s` lane has no colour in Spotlight.COL (raw `%s`), so the frame a viewer is told is %s is drawn from nothing" % [lk_key, str(lk_c_raw), lk_col_said])
                printerr("COMMANDS_DATA LOOK COLOUR AUTHORITY - lane `%s` has no Color; published \"%s\"" % [lk_key, lk_col_said])
            elif lk_col_said != "teal":
                _guard_faults.append("LOOK COLOUR WORD")
                push_error("COMMANDS_DATA LOOK COLOUR WORD: `look`.what publishes the colour \"%s\" and this guard knows only \"teal\" - the `%s` lane is drawn %s and nothing here can say whether that word is true of it" % [lk_col_said, lk_key, str(Spotlight.COL.get(lk_key))])
                printerr("COMMANDS_DATA LOOK COLOUR WORD - published \"%s\" is outside this guard's vocabulary" % lk_col_said)
            else:
                var lk_c: Color = lk_c_raw as Color
                var lk_teal: bool = lk_c.r < lk_c.g and lk_c.r < lk_c.b and lk_c.g >= 0.4 and lk_c.b >= 0.4 and absf(lk_c.g - lk_c.b) <= 0.2
                if not lk_teal:
                    _guard_faults.append("LOOK COLOUR")
                    push_error("COMMANDS_DATA LOOK COLOUR: `look`.what tells a viewer to watch the %s pane for a teal frame and the `%s` lane is drawn (%.2f, %.2f, %.2f) - a viewer looking for teal is looking at the wrong pane" % [lk_lane_said, lk_key, lk_c.r, lk_c.g, lk_c.b])
                    printerr("COMMANDS_DATA LOOK COLOUR - lane `%s` is (%.2f, %.2f, %.2f), which is not teal" % [lk_key, lk_c.r, lk_c.g, lk_c.b])
        var lk_low := lk_what.to_lower()
        var lk_free: float = float(Spotlight.LOOK_S)
        var lk_paid := {"the smallest cheer there is": float(Spotlight.bits_seconds(1)),
                        "a subscription": float(Spotlight.SUB_S),
                        "a point redeem": float(Spotlight.POINTS_S)}
        if not (lk_low.contains("longer pane") and lk_low.contains("cheer") and lk_low.contains("sub") and lk_low.contains("redeem")):
            _guard_faults.append("LOOK LONGER ANCHOR")
            push_error("COMMANDS_DATA LOOK LONGER ANCHOR: `look`.what no longer claims that cheers, subs and redeems get \"longer panes\" - the free look's rank against the three paid lanes (%s) is now unchecked, and the free pane could outlast a paid one with nothing going red" % str(lk_paid))
            printerr("COMMANDS_DATA LOOK LONGER ANCHOR - `look`.what lost its \"longer pane\" claim; the paid lanes are now unranked")
        else:
            var lk_short: Array[String] = []
            for lk_n in lk_paid:
                if float(lk_paid[lk_n]) <= lk_free:
                    lk_short.append("%s holds %ss" % [String(lk_n), str(float(lk_paid[lk_n]))])
            # RED-PROVED AT B45 under the same 03:16 exception: POINTS_S 15.0 -> 5.0 in
            # scripts/spotlight.gd (the GAME BUILD lane's file), this arm fired on the point
            # redeem, file restored byte-identical (md5 24c2ec76...) and proved. Written at B44.
            if not lk_short.is_empty():
                _guard_faults.append("LOOK LONGER")
                push_error("COMMANDS_DATA LOOK LONGER: `look`.what promises cheers, subs and redeems LONGER panes than the free look, and %d of them do not outlast it - the free look holds %ss and %s - so docs/COMMANDS.md tells a viewer that paying buys more screen time than asking, and it does not" % [lk_short.size(), str(lk_free), lk_short])
                printerr("COMMANDS_DATA LOOK LONGER - free look %ss, not outlasted by: %s" % [str(lk_free), lk_short])
        # B46: `wear` - THE PRICE SPAN B40 NAMED AND REFUSED TO CLAIM, AND THE TWO LISTS BESIDE IT.
        # B40 guarded three flat prices and wrote, in the comment above, "WHAT I AM STILL NOT
        # CLAIMING: `wear`.cost publishes a RANGE (30-420)". This is that row, and reading it
        # found a LIVE DEFECT rather than an unanchored claim: the dearest thing !wear sells
        # costs 520 gold (crater_ring), 28 rows sit above 420, and my own file published the
        # span as "30-420 gold". A viewer counted 420 into their purse for the best ring in
        # Bellmire and was 100 gold short at the counter. The low end was right. The top was
        # not. THE NUMBER IS CORRECTED IN data/commands.json IN THIS SAME COMMIT - the fix is
        # the delivery and the guard is what stops it drifting back, because content owns
        # items.json and every ring they add or re-price moves this span under my sentence.
        # THE AUTHORITY: `Roster.wear` charges `int(it["cost"])` for ANY key in
        # items.json `accessories` or `cosmetics` (haggle and rank move what is taken, the same
        # way they move every other price, so the published span is the LIST span - the same
        # convention `forge` and `armoury` publish under). I read it through Roster.items(), the
        # accessor the shop itself calls, so the guard compares against the table in play.
        # AND THE TWO LISTS: `wear`.what publishes FIVE accessory slots and FOUR cosmetic kinds,
        # and both are the COMPLETE set today - which is why these carry a MISSING arm as well as
        # a GHOST one, unlike the dye colours (ten names out of a 281-key table, where naming a
        # handful IS the design). A ghost slot hands a viewer a pre-typed refusal; a missing one
        # hides a whole slot of gear nobody is told they can buy.
        var we_d: Dictionary = cmd_d.get("wear", {}) as Dictionary
        var we_items: Dictionary = Roster.items()
        var we_acc: Dictionary = we_items.get("accessories", {}) as Dictionary
        var we_cos: Dictionary = we_items.get("cosmetics", {}) as Dictionary
        var we_min: int = -1
        var we_max: int = -1
        var we_slots: Array[String] = []
        var we_kinds: Array[String] = []
        for we_t in [we_acc, we_cos]:
            var we_tab: Dictionary = we_t as Dictionary
            for we_k in we_tab:
                var we_row: Dictionary = we_tab[we_k] as Dictionary
                if we_row.has("cost"):
                    var we_c: int = int(we_row["cost"])
                    if we_min < 0 or we_c < we_min:
                        we_min = we_c
                    if we_c > we_max:
                        we_max = we_c
                if we_row.has("slot") and not we_slots.has(String(we_row["slot"])):
                    we_slots.append(String(we_row["slot"]))
                if we_row.has("kind") and not we_kinds.has(String(we_row["kind"])):
                    we_kinds.append(String(we_row["kind"]))
        # the span this file PUBLISHES: "<low>-<high> gold". Read in one place, because a span
        # read two different ways is two numbers again.
        var we_cost: String = String(we_d.get("cost", ""))
        var we_low: int = -1
        var we_high: int = -1
        var we_gold: int = we_cost.find(" gold")
        if we_gold > 0:
            var we_pair: PackedStringArray = we_cost.substr(0, we_gold).split("-", false)
            if we_pair.size() == 2 and we_pair[0].strip_edges().is_valid_int() and we_pair[1].strip_edges().is_valid_int():
                we_low = int(we_pair[0].strip_edges())
                we_high = int(we_pair[1].strip_edges())
        if we_acc.is_empty() or we_cos.is_empty():
            # the dead key IS the finding, the same shape as the dye table: there is no span to
            # compare against, and a !wear that sells nothing is the bigger fault.
            _guard_faults.append("WEAR AUTHORITY")
            push_error("COMMANDS_DATA WEAR AUTHORITY: data/items.json carries %d accessory row(s) and %d cosmetic row(s), so the shop `wear` publishes a %s price span for sells nothing from one of its two tables" % [we_acc.size(), we_cos.size(), we_cost])
            printerr("COMMANDS_DATA WEAR AUTHORITY - accessories %d, cosmetics %d" % [we_acc.size(), we_cos.size()])
        elif we_low < 0:
            _guard_faults.append("WEAR SPAN ANCHOR")
            push_error("COMMANDS_DATA WEAR SPAN ANCHOR: `wear`.cost no longer carries a \"<low>-<high> gold\" span in words this guard can read - the cheapest and dearest thing the shop sells can no longer be checked against data/items.json, and the span is what a viewer budgets from")
            printerr("COMMANDS_DATA WEAR SPAN ANCHOR - `wear`.cost lost its \"<low>-<high> gold\" span; the published price range is now unchecked")
        else:
            if we_low != we_min:
                _guard_faults.append("WEAR SPAN LOW")
                push_error("COMMANDS_DATA WEAR SPAN LOW: `wear`.cost publishes %d gold as the cheapest thing the shop sells and the cheapest row in data/items.json costs %d - docs/COMMANDS.md tells a viewer the floor of the counter and it is the wrong floor" % [we_low, we_min])
                printerr("COMMANDS_DATA WEAR SPAN LOW - published %d, cheapest row %d" % [we_low, we_min])
            if we_high != we_max:
                _guard_faults.append("WEAR SPAN HIGH")
                push_error("COMMANDS_DATA WEAR SPAN HIGH: `wear`.cost publishes %d gold as the dearest thing the shop sells and %d row(s) in data/items.json cost more, up to %d - a viewer who saves the published top and walks to the counter is %d gold short" % [we_high, _wear_over(we_acc, we_cos, we_high), we_max, we_max - we_high])
                printerr("COMMANDS_DATA WEAR SPAN HIGH - published %d, dearest row %d" % [we_high, we_max])
        # THE SLOTS AND THE KINDS. Two lists, read out of the sentence, each checked BOTH ways.
        var we_what: String = String(we_d.get("what", ""))
        for we_pair2 in [["accessory (", we_slots, "SLOT", "accessory slot", "data/items.json `accessories`"],
                         ["cosmetic (", we_kinds, "KIND", "cosmetic kind", "data/items.json `cosmetics`"]]:
            var we_head: String = String(we_pair2[0])
            var we_real: Array[String] = []
            we_real.assign(we_pair2[1])
            var we_tag: String = String(we_pair2[2])
            var we_word: String = String(we_pair2[3])
            var we_src: String = String(we_pair2[4])
            var we_said: Array[String] = _wear_list(we_what, we_head)
            if we_said.is_empty():
                _guard_faults.append("WEAR %s ANCHOR" % we_tag)
                push_error("COMMANDS_DATA WEAR %s ANCHOR: `wear`.what no longer carries its \"%s...)\" list in words this guard can read - the %ss docs/COMMANDS.md invites a viewer to type can no longer be checked against %s, so a dead one would reach chat silently" % [we_tag, we_head, we_word, we_src])
                printerr("COMMANDS_DATA WEAR %s ANCHOR - `wear`.what lost its \"%s\" list; those names are now unchecked" % [we_tag, we_head])
                continue
            var we_ghost: Array[String] = []
            var we_hit: Array[String] = []
            for we_w in we_said:
                var we_m: String = _wear_one(String(we_w), we_real)
                if we_m == "":
                    we_ghost.append(we_w)
                elif not we_hit.has(we_m):
                    we_hit.append(we_m)
            var we_miss: Array[String] = []
            for we_r in we_real:
                if not we_hit.has(we_r):
                    we_miss.append(we_r)
            if not we_ghost.is_empty():
                _guard_faults.append("WEAR %s GHOST" % we_tag)
                push_error("COMMANDS_DATA WEAR %s GHOST: `wear`.what publishes %d %s(s) nothing in %s carries, so docs/COMMANDS.md invites a refusal a viewer pays a command to discover - the real ones are %s and none of these is among them: %s" % [we_tag, we_ghost.size(), we_word, we_src, we_real, we_ghost])
                printerr("COMMANDS_DATA WEAR %s GHOST - %d published %s(s) nothing answers to: %s" % [we_tag, we_ghost.size(), we_word, we_ghost])
            if not we_miss.is_empty():
                _guard_faults.append("WEAR %s MISSING" % we_tag)
                push_error("COMMANDS_DATA WEAR %s MISSING: %s carries %d %s(s) `wear`.what never names - %s - so a whole slot of gear is for sale and nothing tells a viewer it exists, and `!wear off <slot>` takes it off a word they were never given" % [we_tag, we_src, we_miss.size(), we_word, we_miss])
                printerr("COMMANDS_DATA WEAR %s MISSING - %d unpublished %s(s): %s" % [we_tag, we_miss.size(), we_word, we_miss])
        # ---- B50: "THE EIGHT LORDS" - THE THIRD OF THE FOUR NUMERIC CLAIMS MY OWN LANE NAMED.
        # B35 listed the four `what` claims whose authority is a number living in code and ranked
        # them. `look` (B35) and `satchel` (B36) are done; this is the third, and B35's own note
        # on it was INCOMPLETE rather than wrong. It called this "a COUNT over bosses.json, a
        # data file, not a const". THERE ARE TWO CONSTS, AND THE DATA FILE AS WELL:
        #   Bestiary.LESSER and Bestiary.GREATER (bestiary.gd:299-300) are the lords the game
        #   actually RISES - four and four.
        #   data/bosses.json `lesser` / `greater` are the CONTENT writer's rows for the same
        #   lords, read here through Bestiary.bosses_raw() - the accessor the bestiary itself
        #   uses, so the guard reads the authority in play instead of re-parsing a copy of it.
        # So this is B36's SPLIT shape again and now across TWO OTHER LANES' files: the game
        # build's consts and the content writer's rows can disagree with EACH OTHER before either
        # disagrees with my sentence, and a row the writer adds with no const beside it is a lord
        # the Bestiary will never rise. When they disagree there is no count to publish at all,
        # and the guard says so rather than believing one of them. A bosses.json that cannot be
        # read reads as ZERO rows here, which is a disagreement and is reported as the row count
        # it is - not hidden behind the consts.
        # AND THE CLAIM SITS IN MY OWN FILE TWICE. `bestiary`.what and `bestiary`.short both say
        # "the eight lords", so those two can disagree with each other the way the armoury ladder
        # could at B37 - !bestiary's one-line reply promising one number and docs/COMMANDS.md's
        # long line another. That is the FIELDS path.
        # IT IS A WORD, NOT A DIGIT, AND THAT IS WHY IT COULD DRIFT IN SILENCE. "eight" needs the
        # number table `muster` needed; the digit reader B40 wrote for the flat prices finds
        # nothing in this sentence and would report healthy on a ninth lord.
        # FOUR PATHS. SPLIT is INDEPENDENT of the rest and does not share their elif - the two
        # authorities disagreeing matters whatever my sentence says. ANCHOR stops the guard going
        # blind; FIELDS and LORDS are the mismatches. Not fatal, the shape every guard above uses:
        # push_error + printerr, the commands still answer, and a battery greps COMMANDS_DATA. No
        # line here is the healthy reading.
        var bl_d: Dictionary = (cmd_d.get("bestiary", {}) as Dictionary)
        var bl_words: Dictionary = {"one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
                                   "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
                                   "eleven": 11, "twelve": 12}
        var bl_anchor := " lords"
        var bl_fields: Array[String] = ["what", "short"]
        var bl_seen: Array[String] = []
        var bl_said: Array[int] = []
        for bl_f in bl_fields:
            var bl_s: String = String(bl_d.get(bl_f, "")).to_lower()
            if not bl_s.contains(bl_anchor):
                continue
            bl_seen.append(bl_f)
            var bl_n: int = -1
            for bl_w in bl_words:
                if bl_s.contains("%s%s" % [String(bl_w), bl_anchor]):
                    bl_n = int(bl_words[bl_w])
                    break
            bl_said.append(bl_n)
        var bl_code: int = Bestiary.LESSER.size() + Bestiary.GREATER.size()
        var bl_raw: Dictionary = Bestiary.bosses_raw()
        var bl_rows: int = (bl_raw.get("lesser", []) as Array).size() \
                        + (bl_raw.get("greater", []) as Array).size()
        if bl_code != bl_rows:
            _guard_faults.append("BESTIARY SPLIT")
            push_error("COMMANDS_DATA BESTIARY SPLIT: the lords are declared TWICE and the two no longer agree - Bestiary.LESSER + Bestiary.GREATER rise %d lords and data/bosses.json `lesser` + `greater` carry %d rows, so a row and a const disagree about how many lords the deep holds and `bestiary` cannot be true of both" % [bl_code, bl_rows])
            printerr("COMMANDS_DATA BESTIARY SPLIT - %d lords in code, %d rows in data/bosses.json; no single count exists to publish" % [bl_code, bl_rows])
        if bl_seen.is_empty() or bl_said.has(-1):
            _guard_faults.append("BESTIARY ANCHOR")
            push_error("COMMANDS_DATA BESTIARY ANCHOR: `bestiary` no longer says \"<number> lords\" in words this guard knows (fields carrying the phrase: %s) - the published count of the lords that hold the deep can no longer be checked against Bestiary.LESSER + Bestiary.GREATER (%d)" % [bl_seen, bl_code])
            printerr("COMMANDS_DATA BESTIARY ANCHOR - `bestiary` lost its \"<number> lords\" phrase; the lord count is now unchecked")
        elif bl_said.size() == 2 and bl_said[0] != bl_said[1]:
            _guard_faults.append("BESTIARY FIELDS")
            push_error("COMMANDS_DATA BESTIARY FIELDS: `bestiary`.what publishes %d lords and `bestiary`.short publishes %d - my own two declarations disagree, so !bestiary answers one number and docs/COMMANDS.md prints the other" % [bl_said[0], bl_said[1]])
            printerr("COMMANDS_DATA BESTIARY FIELDS - what %d, short %d" % [bl_said[0], bl_said[1]])
        elif bl_said[0] != bl_code:
            _guard_faults.append("BESTIARY LORDS")
            push_error("COMMANDS_DATA BESTIARY LORDS: `bestiary` publishes %d lords and the game rises %d, read from Bestiary.LESSER + Bestiary.GREATER - docs/COMMANDS.md counts the deep's lords wrong and a viewer finds out by reaching the one that is not there" % [bl_said[0], bl_code])
            printerr("COMMANDS_DATA BESTIARY LORDS - published %d, risen %d" % [bl_said[0], bl_code])
        # ---- B70: THE RENAME'S ONE JOIN, ASSERTED FROM A FILE THAT HOLDS NO COPY OF IT.
        # The team lead's 22:58 check found the same defect in two lanes with one question: for
        # each body key, does THAT key's own name appear under THAT key. Neither lane's gate could
        # see it, because each gate was a second copy of the thing it was checking. This guard is
        # the other shape: it walks content's miniboss_feed.by_key - the bodies that actually draw
        # a line - and reads Delve.MB_NAME, the table the nameplate draws from. It owns neither.
        # TWO WAYS THE JOIN BREAKS, AND THEY ARE NOT THE SAME FAULT:
        #   UNNAMED - a body content writes a feed for with no MB_NAME row. It still stands up
        #     (miniboss_name falls back to the capitalised trade), so nothing crashes and nothing
        #     looks wrong in a log - a viewer simply reads the trade word the directive exists to
        #     remove, and !miniboss answers it too.
        #   GHOST - an MB_NAME row keyed on a word that is not a body. Unreachable: the name can
        #     never be drawn, never be asked for here, and the map looks full while being short.
        # B71: THESE TWO ARE NOW FULL FAULTS, AND THE DEBT IS PAID IN THE SAME WORDS IT WAS TAKEN
        # IN. B70 held them at printerr-only with the reason written here: both had exactly ONE
        # live instance (`strickler` unnamed, `drizzler` ghost), they were the SAME single defect,
        # and the fix was already on branch `laptop` at a2d6ab2e and arriving at the next merge -
        # a guard that goes red on a fix in flight teaches a lane to ignore it. Main carries
        # a2d6ab2e as of the 23:58 merge. I did not take the merge's word for it: I brace-matched
        # MB_NAME off `scripts/delve.gd` in the merged worktree and walked it against content's
        # `miniboss_feed.by_key` - 36 rows, 36 names, UNNAMED empty, GHOST empty - so the promotion
        # lands green rather than landing on a live fault. They are push_error from here on, and
        # the warning window was one cycle wide exactly as declared.
        # COUNT / ANCHOR / FIELDS are full faults from the first run: those are MY sentence, and
        # "36" in data/commands.json is a number in prose with nothing under it until now.
        var mb_d: Dictionary = (cmd_d.get("miniboss", {}) as Dictionary)
        var mb_anchor := " elites"
        var mb_seen: Array[String] = []
        var mb_said: Array[int] = []
        for mb_f in ["what", "short"]:
            var mb_s: String = String(mb_d.get(mb_f, "")).to_lower()
            var mb_at: int = mb_s.find(mb_anchor)
            if mb_at < 0:
                continue
            mb_seen.append(String(mb_f))
            var mb_dig := ""
            var mb_i: int = mb_at - 1
            while mb_i >= 0 and "0123456789".contains(mb_s.substr(mb_i, 1)):
                mb_dig = mb_s.substr(mb_i, 1) + mb_dig
                mb_i -= 1
            mb_said.append(int(mb_dig) if mb_dig != "" else -1)
        var mb_live: Dictionary = miniboss_names()
        var mb_unnamed: Array[String] = []
        for mb_k: String in mb_live.keys():
            if not Delve.MB_NAME.has(mb_k):
                mb_unnamed.append(mb_k)
        var mb_ghost: Array[String] = []
        for mb_g in Delve.MB_NAME.keys():
            if not mb_live.has(String(mb_g)):
                mb_ghost.append(String(mb_g))
        if mb_live.is_empty():
            _guard_faults.append("MINIBOSS FEED")
            push_error("COMMANDS_DATA MINIBOSS FEED: data/lore_lines.json carries no `miniboss_feed`.by_key rows, so there is no key set to count or to name - `miniboss` publishes a number with nothing under it and !miniboss can only say nothing is written down")
            printerr("COMMANDS_DATA MINIBOSS FEED - no miniboss_feed.by_key rows; the published count is unchecked")
        elif mb_seen.is_empty() or mb_said.has(-1):
            _guard_faults.append("MINIBOSS ANCHOR")
            push_error("COMMANDS_DATA MINIBOSS ANCHOR: `miniboss` no longer says \"<number> elites\" (fields carrying the phrase: %s) - the published count of the ones that hold a chamber alone can no longer be checked against content's %d feed rows" % [mb_seen, mb_live.size()])
            printerr("COMMANDS_DATA MINIBOSS ANCHOR - `miniboss` lost its \"<number> elites\" phrase; the count is now unchecked")
        elif mb_said.size() == 2 and mb_said[0] != mb_said[1]:
            _guard_faults.append("MINIBOSS FIELDS")
            push_error("COMMANDS_DATA MINIBOSS FIELDS: `miniboss`.what publishes %d elites and `miniboss`.short publishes %d - my own two declarations disagree, so !miniboss answers one number and docs/COMMANDS.md prints the other" % [mb_said[0], mb_said[1]])
            printerr("COMMANDS_DATA MINIBOSS FIELDS - what %d, short %d" % [mb_said[0], mb_said[1]])
        elif mb_said[0] != mb_live.size():
            _guard_faults.append("MINIBOSS COUNT")
            push_error("COMMANDS_DATA MINIBOSS COUNT: `miniboss` publishes %d elites and content writes feed rows for %d - docs/COMMANDS.md counts the chambers wrong and a viewer finds out by asking for one that is not there" % [mb_said[0], mb_live.size()])
            printerr("COMMANDS_DATA MINIBOSS COUNT - published %d, feed rows %d" % [mb_said[0], mb_live.size()])
        if not mb_unnamed.is_empty():
            _guard_faults.append("MINIBOSS UNNAMED")
            push_error("COMMANDS_DATA MINIBOSS UNNAMED: %d body(s) content writes a feed for carry no `Delve.MB_NAME` row, so the nameplate falls back to the capitalised trade and !miniboss answers the trade word the rename exists to remove - nothing crashes and nothing reads wrong in a log, which is why this is a fault and not a warning: %s" % [mb_unnamed.size(), mb_unnamed])
            printerr("COMMANDS_DATA MINIBOSS UNNAMED - %d bodies draw a feed with no MB_NAME row and answer to their trade word instead of a name: %s" % [mb_unnamed.size(), mb_unnamed])
        if not mb_ghost.is_empty():
            _guard_faults.append("MINIBOSS GHOST")
            push_error("COMMANDS_DATA MINIBOSS GHOST: %d `Delve.MB_NAME` row(s) are keyed on a word no body carries, so the name can never be drawn on a nameplate nor asked for here - the map looks full while being short by that many names: %s" % [mb_ghost.size(), mb_ghost])
            printerr("COMMANDS_DATA MINIBOSS GHOST - %d MB_NAME rows keyed on a word no body carries, so the name can never be drawn or asked for: %s" % [mb_ghost.size(), mb_ghost])
        # ---- B51: THE `inventory` FIELD LIST - THE FIRST CLAIM IN THIS FILE GUARDED BY WHETHER
        # THE THING THAT DELIVERS IT STILL EXISTS, RATHER THAN BY WHAT A NUMBER SAYS.
        # B34 named fifteen unguarded `what` claims. FOUR carried a number and all four are now
        # closed: `look` (B35), `satchel` (B36), `bestiary` (B50) and `oil` - which is closed as
        # NOT GUARDABLE FROM THIS LANE, measured this cycle and written up in PROGRESS.md: the
        # authority for "two delvers" is an inline `* 0.5` at delve.gd:161 with no constant beside
        # it, and reading that file's TEXT at runtime would go blind in an exported build (Godot 4
        # ships .gd as binary tokens), so the guard would fire on export rather than on drift.
        # ELEVEN REMAIN AND THEY CARRY LISTS, NOT NUMBERS. This is one of them, and it is the one
        # whose line is built in THIS FILE - inventory() above, not another lane's printer. So the
        # sentence and the code that has to honour it are both mine, and the drift that could pass
        # in silence is not a wrong number but a FIELD THAT IS PROMISED AND NEVER PRINTED.
        # I SUSPECTED ONE TODAY AND MEASUREMENT OVERTURNED IT: `inventory`.what publishes `dye`
        # and inventory()'s format string has no dye in it. It is NOT a fault - roster.gd:1276-77
        # appends "dyed <colour>" inside worn_line(), so dye reaches the line through the same
        # call as accessories. Recorded so the next sweep does not re-raise it.
        # WHAT THIS GUARD IS BOUND TO. Each published field maps to the call in inventory() that
        # puts it on the line, and the guard asks the authority whether that call still EXISTS -
        # Roster's own script method list, read off the class without instancing it. That is not
        # circular: GHOST catches my sentence growing a field nothing delivers, and SOURCE catches
        # the roster lane renaming or dropping the call while my sentence still promises it. Two
        # directions, the drift check this lane runs on every edit, made into an engine arm.
        # THREE PATHS. ANCHOR stops the guard going blind if the sentence loses its "carries:"
        # lead-in; GHOST and SOURCE are the two mismatches and are INDEPENDENT of each other -
        # a sentence can grow a field and lose a printer in the same edit. Not fatal, the shape
        # every guard above uses: push_error + printerr, the commands still answer, and a battery
        # greps COMMANDS_DATA. No line here is the healthy reading.
        var iw: String = String(((cmd_d.get("inventory", {}) as Dictionary)).get("what", ""))
        var i_anchor := "carries: "
        var i_fields: Array[String] = []
        var i_at: int = iw.find(i_anchor)
        if i_at >= 0:
            var i_rest := iw.substr(i_at + i_anchor.length())
            var i_stop: int = i_rest.find(".")
            if i_stop > 0:
                i_rest = i_rest.substr(0, i_stop)
            for i_part in i_rest.split(","):
                var i_p := String(i_part).strip_edges()
                if i_p.begins_with("and "):
                    i_p = i_p.substr(4).strip_edges()
                if i_p != "":
                    i_fields.append(i_p)
        # every published field -> the Roster call in inventory() that puts it on the line
        var i_src := {
            "title": "title_of",
            "weapon": "weapon_name",
            "armour": "armour_name",
            "accessories": "worn_line",
            "dye": "worn_line",
            "brews": "brews_line",
        }
        # the three inventory() prints itself: two hero keys read in this file, and the fish block
        var i_own: Array[String] = ["oil", "gold", "the best fish caught"]
        var i_have := {}
        for i_m in (Roster as Script).get_script_method_list():
            i_have[String((i_m as Dictionary).get("name", ""))] = true
        if i_fields.is_empty():
            _guard_faults.append("INVENTORY ANCHOR")
            push_error("COMMANDS_DATA INVENTORY ANCHOR: `inventory`.what no longer says \"carries: <fields>\" - the fields !inventory promises can no longer be checked against the calls that print them, and a promised field could go missing in silence")
            printerr("COMMANDS_DATA INVENTORY ANCHOR - `inventory`.what lost its \"carries: \" lead-in; the published field list is now unchecked")
        else:
            var i_ghost: Array[String] = []
            var i_dead: Array[String] = []
            for i_f in i_fields:
                if i_src.has(i_f):
                    var i_fn := String(i_src[i_f])
                    if not i_have.has(i_fn):
                        i_dead.append("%s -> Roster.%s" % [i_f, i_fn])
                elif not i_own.has(i_f):
                    i_ghost.append(i_f)
            if not i_dead.is_empty():
                _guard_faults.append("INVENTORY SOURCE")
                push_error("COMMANDS_DATA INVENTORY SOURCE: `inventory`.what promises %d field(s) whose printer is gone from Roster - %s - so !inventory answers without them while docs/COMMANDS.md still says a viewer will see them" % [i_dead.size(), i_dead])
                printerr("COMMANDS_DATA INVENTORY SOURCE - %d published field(s) with no printer left: %s" % [i_dead.size(), i_dead])
            if not i_ghost.is_empty():
                _guard_faults.append("INVENTORY GHOST")
                push_error("COMMANDS_DATA INVENTORY GHOST: `inventory`.what publishes %d field(s) inventory() never puts on the line - %s - so docs/COMMANDS.md promises a viewer something !inventory does not answer with" % [i_ghost.size(), i_ghost])
                printerr("COMMANDS_DATA INVENTORY GHOST - %d published field(s) nothing prints: %s" % [i_ghost.size(), i_ghost])
        # ---- B53: THE PUBLISHED needs_hero FLAG. A BOOLEAN, NOT A NUMBER OR A LIST. -----
        # Every flat price I publish is guarded now (B39 brew, B40 oil/reroll/respec, B41 dye,
        # B46 the wear span) and so is every published LIST (forge and armoury tiers, dye
        # colours, bestiary fields, B51/B52's inventory fields). So I went looking for the next
        # CLASS of claim on my own surface rather than the next instance of one I had done, and
        # found one nothing in the house has ever checked: `needs_hero`, declared 27 times in
        # data/commands.json and PUBLISHED TO VIEWERS TWICE - tools/_commands_doc.gd writes
        # " (no hero needed)" into docs/COMMANDS.md when it is false, and the hub prints
        # "Needs a living hero." when it is true (web/app.js:2102, the HUB LANE'S FILE - I read
        # it, I did not touch it). A wrong flag is not a cosmetic slip: it tells a viewer whether
        # a command is worth typing at all.
        # THE AUTHORITY IS THE DISPATCH TABLE IN THIS FILE AND I READ IT RATHER THAN COPYING IT.
        # B41's lesson was that a second copy of the answer is the defect, not the guard, so this
        # arm PARSES the dispatch table out of my own source and asks, per command, whether its
        # route reaches the living-hero gate - either in the case body or inside the one handler
        # the case calls. That is the house's own method, not a new one: the HUD's
        # tools/_u71_rarity_guard.gd guards a table by walking GDScript source, and the team lead
        # read that parser at 10:5x.
        # AN UNREADABLE SOURCE IS NOT A FAULT. In an exported build res://scripts/*.gd need not be
        # present as text. No source means there is nothing to compare against, so the arm stays
        # silent - a guard that cries fault when its own instrument is missing is a lying
        # instrument, which is exactly what the HUD spent U76 proving about a half-read table.
        #
        # *** MY FIRST VERSION OF THIS ARM WAS WRONG TWICE AND A PYTHON EMULATION CAUGHT BOTH
        # *** BEFORE THE ENGINE DID. I am writing them down because the second one is funny and
        # *** the house keeps relearning it.
        # (1) It ended a handler's body at the next "\nfunc ", which does not match "static func",
        #     so the slice for _catchup ran 1,482 LINES past the end of _catchup. A half-read
        #     body is U76's fault in a different file. _func_body() below ends a body at the
        #     first non-blank line in column 0, so every top-level form closes it.
        # (2) The `_needs(` it then found was INSIDE THIS COMMENT BLOCK. My own prose about the
        #     guard scored as evidence for the guard, and the arm reported !catchup as a flag
        #     disagreement that does not exist. That is the team lead's `district_rules`-in-a-
        #     comment trap at 09:5x and U76's skip-the-strings lesson, arriving a third time.
        #     _code_only() below strips comments and string literals before anything is tested.
        # NOTHING IS GUARDED BY PROSE. The arm now reads code, and the corrected emulation puts
        # 26 of 27 flags in exact agreement with their route, with !reroll the one carve-out.
        #
        # THE ONE COMMAND THE FLAG CANNOT DESCRIBE, AND I AM NOT PAPERING OVER IT.
        # !reroll declares needs_hero true and does NOT gate on a living hero: _reroll admits a
        # DEAD hero on purpose, erases it and raises a new one. BOTH VALUES OF THE FLAG ARE FALSE
        # STATEMENTS ABOUT IT - `true` has the hub tell a dead viewer that the one command which
        # revives them needs a living hero, and `false` would have docs/COMMANDS.md say "no hero
        # needed" when a viewer with no hero at all is sent to !enlist. SO I DID NOT FLIP IT.
        # A boolean cannot carry three gate strengths, and inventing a third data key is work the
        # freeze forbids a lane to invent. It is carved out BY NAME with its reason, and THE
        # CARVE-OUT IS ITSELF GUARDED: if !reroll ever starts routing through the living-hero
        # gate, revival is broken for every dead viewer and the EXEMPT arm below says so.
        var nh_exempt := {"reroll": "admits a DEAD hero on purpose - it erases the fallen one and raises a new hero, so its gate is a hero EXISTING, not a hero living"}
        var nh_f := FileAccess.open("res://scripts/chatcmd.gd", FileAccess.READ)
        if nh_f != null:
            var nh_src: String = nh_f.get_as_text()
            var nh_lines: PackedStringArray = nh_src.split("\n")
            # THE DISPATCH TABLE IS THE ONE INSIDE handle(), NOT "the first `match verb:` in the
            # file". THERE ARE THREE IN HERE: handle() dispatches the commands, _test_spot()
            # matches the local test verbs, and ui_kinds() maps a verb to sound kinds. My first
            # instrument took the first one it met and was RIGHT BY COINCIDENCE, because handle()
            # happens to come first - and a coincidence standing in for a construction is the one
            # thing this lane exists to replace. So the anchor is handle() itself, the search
            # stops at the end of handle() body, and a missing handle() is the ANCHOR fault.
            var nh_start: int = -1
            var nh_hs: int = -1
            for nh_i in nh_lines.size():
                if nh_lines[nh_i].begins_with("func handle("):
                    nh_hs = nh_i
                    break
            if nh_hs >= 0:
                var nh_s2: int = nh_hs + 1
                while nh_s2 < nh_lines.size():
                    var nh_sl: String = nh_lines[nh_s2]
                    if nh_sl.strip_edges() != "" and not nh_sl.begins_with(" ") and not nh_sl.begins_with("\t"):
                        break
                    if nh_sl.strip_edges() == "match verb:":
                        nh_start = nh_s2
                        break
                    nh_s2 += 1
            if nh_start < 0:
                _guard_faults.append("NEEDS_HERO ANCHOR")
                push_error("COMMANDS_DATA NEEDS_HERO ANCHOR: the `match verb:` dispatch table inside handle() is gone from scripts/chatcmd.gd, so the sole authority for every published `needs_hero` flag can no longer be read - all %d flags go unchecked, and both docs/COMMANDS.md's \"(no hero needed)\" and the hub's \"Needs a living hero.\" badge are published against nothing" % cmd_d.size())
                printerr("COMMANDS_DATA NEEDS_HERO ANCHOR - no handle() dispatch table in source; every needs_hero flag is now unchecked")
            else:
                # which commands the dispatch table actually gates on a LIVING hero
                var nh_gate := {}
                var nh_j: int = nh_start + 1
                while nh_j < nh_lines.size():
                    var nh_ln: String = nh_lines[nh_j]
                    if nh_ln.strip_edges() == "":
                        nh_j += 1
                        continue
                    var nh_ind: int = nh_ln.length() - nh_ln.lstrip(" ").length()
                    if nh_ind <= 4:
                        break
                    if nh_ind != 8 or not nh_ln.lstrip(" ").begins_with("\""):
                        nh_j += 1
                        continue
                    # the case head: the quoted keys standing before the colon that closes it
                    var nh_h: String = nh_ln.lstrip(" ")
                    var nh_keys: Array[String] = []
                    var nh_body := ""
                    var nh_q := false
                    var nh_cur := ""
                    for nh_k in nh_h.length():
                        var nh_c: String = nh_h[nh_k]
                        if nh_q:
                            if nh_c == "\"":
                                nh_keys.append(nh_cur)
                                nh_cur = ""
                                nh_q = false
                            else:
                                nh_cur += nh_c
                        elif nh_c == "\"":
                            nh_q = true
                        elif nh_c == ":":
                            nh_body = nh_h.substr(nh_k + 1)
                            break
                    # the rest of the case: every following line indented past the case head
                    var nh_m: int = nh_j + 1
                    while nh_m < nh_lines.size():
                        var nh_l2: String = nh_lines[nh_m]
                        if nh_l2.strip_edges() == "":
                            nh_m += 1
                            continue
                        if nh_l2.length() - nh_l2.lstrip(" ").length() <= 8:
                            break
                        nh_body += "\n" + nh_l2
                        nh_m += 1
                    var nh_gated: bool = _code_only(nh_body).contains("_needs(")
                    if not nh_gated:
                        # the case hands off to one of this file's own handlers; does IT gate?
                        var nh_code: String = _code_only(nh_body)
                        var nh_hn := ""
                        var nh_oi: int = nh_code.find("out = ")
                        if nh_oi >= 0:
                            var nh_rest: String = nh_code.substr(nh_oi + 6)
                            var nh_pi: int = nh_rest.find("(")
                            if nh_pi > 0:
                                nh_hn = nh_rest.substr(0, nh_pi).strip_edges()
                        if nh_hn != "":
                            nh_gated = _code_only(_func_body(nh_src, nh_hn)).contains("_needs(")
                    for nh_key in nh_keys:
                        nh_gate[nh_key] = nh_gated
                    nh_j = nh_m
                # the published flag against the route it actually takes, command by command
                var nh_bad: Array[String] = []
                var nh_route: Array[String] = []
                var nh_broke: Array[String] = []
                for nh_key2 in cmd_d:
                    if not nh_gate.has(nh_key2):
                        nh_route.append(String(nh_key2))
                        continue
                    var nh_real: bool = bool(nh_gate[nh_key2])
                    if nh_exempt.has(nh_key2):
                        if nh_real:
                            nh_broke.append(String(nh_key2))
                        continue
                    var nh_said: bool = bool((cmd_d[nh_key2] as Dictionary).get("needs_hero", true))
                    if nh_said != nh_real:
                        nh_bad.append("%s publishes needs_hero %s and routes %s" % [String(nh_key2), str(nh_said), "through the living-hero gate" if nh_real else "with no hero gate"])
                if not nh_route.is_empty():
                    _guard_faults.append("NEEDS_HERO ROUTE")
                    push_error("COMMANDS_DATA NEEDS_HERO ROUTE: %d published command(s) have no case in the dispatch table - %s - so docs/COMMANDS.md and the hub list a command nothing dispatches, and a viewer who types it gets the near-miss nudge instead of an answer" % [nh_route.size(), nh_route])
                    printerr("COMMANDS_DATA NEEDS_HERO ROUTE - %d published command(s) nothing dispatches: %s" % [nh_route.size(), nh_route])
                if not nh_bad.is_empty():
                    _guard_faults.append("NEEDS_HERO")
                    push_error("COMMANDS_DATA NEEDS_HERO: %d published `needs_hero` flag(s) disagree with the dispatch table - %s - so the hub shows \"Needs a living hero.\" on a command that needs none, or docs/COMMANDS.md says \"(no hero needed)\" on one that turns a viewer away" % [nh_bad.size(), nh_bad])
                    printerr("COMMANDS_DATA NEEDS_HERO - %d flag(s) disagree with the route: %s" % [nh_bad.size(), nh_bad])
                if not nh_broke.is_empty():
                    _guard_faults.append("NEEDS_HERO EXEMPT")
                    push_error("COMMANDS_DATA NEEDS_HERO EXEMPT: %s now route(s) through the living-hero gate, and it was carved out of this guard precisely because it must not - a dead viewer can no longer raise a new hero, which is the one thing that command exists to do" % [nh_broke])
                    printerr("COMMANDS_DATA NEEDS_HERO EXEMPT - %s now gates on a LIVING hero; revival is broken for every dead viewer" % [nh_broke])
        # ---- B101: THE FIVE SPECIAL BUILDINGS !town NAMES. -------------------------------
        # A CLAIM ON MY OWN SURFACE THAT NOTHING HAS EVER CHECKED, AND IT IS A SECOND COPY OF
        # SOMEBODY ELSE'S TABLE SITTING IN MY OWN FILE. `_town_line()` turns the growth lane's
        # special-building KEYS into words through `TOWN_BUILT`, declared in this file - and the
        # lookup is `TOWN_BUILT.get(String(k), "")` with an EMPTY-STRING fallback that is then
        # skipped. So if the growth lane adds a sixth special, or renames one of the five keys,
        # the building is SILENTLY DROPPED OFF THE !town LINE: no crash, no log line, no wrong
        # word on screen - just a building a viewer built and the bot never mentions, while
        # `town`.what goes on naming all five to them. Same fault class as the MB_NAME map and
        # the satchel split, and it is the reason this arm exists.
        # THE AUTHORITY IS `UNLOCK` IN scripts/growth.gd, READ OFF THE SCRIPT, NOT COPIED.
        # growth.gd carries no `class_name`, so there is no global to reach it by; the constant
        # comes out of the script's own constant map, which is the lane's declaration itself. If
        # the growth lane ever renames UNLOCK the AUTHORITY arm fires, rather than this guard
        # scoring a green off an empty table - a guard that cannot read its authority must say so.
        var tb_unlock: Dictionary = {}
        if ResourceLoader.exists("res://scripts/growth.gd"):
            var tb_script: Variant = load("res://scripts/growth.gd")
            if tb_script is Object and (tb_script as Object).has_method("get_script_constant_map"):
                var tb_cm: Variant = (tb_script as Object).call("get_script_constant_map")
                if tb_cm is Dictionary:
                    var tb_raw: Variant = (tb_cm as Dictionary).get("UNLOCK", null)
                    if tb_raw is Dictionary:
                        tb_unlock = tb_raw as Dictionary
        # the names `town`.what publishes, read out of the sentence rather than assumed
        var tw: String = String(((cmd_d.get("town", {}) as Dictionary)).get("what", ""))
        var tb_lead := "which of "
        var tb_tail := " are open"
        var tb_said: Array[String] = []
        var tb_a: int = tw.find(tb_lead)
        var tb_b: int = tw.find(tb_tail)
        if tb_a >= 0 and tb_b > tb_a:
            var tb_list: String = tw.substr(tb_a + tb_lead.length(), tb_b - tb_a - tb_lead.length())
            for tb_part in tb_list.replace(" and ", ", ").split(","):
                var tb_p := String(tb_part).strip_edges()
                if tb_p.begins_with("the "):
                    tb_p = tb_p.substr(4).strip_edges()
                if tb_p != "":
                    tb_said.append(tb_p)
        # the words my own table would actually print, with the article stripped the same way
        var tb_mine: Array[String] = []
        for tb_k in TOWN_BUILT.keys():
            var tb_w := String(TOWN_BUILT[tb_k]).strip_edges()
            if tb_w.begins_with("the "):
                tb_w = tb_w.substr(4).strip_edges()
            if tb_w != "":
                tb_mine.append(tb_w)
        if tb_unlock.is_empty():
            _guard_faults.append("TOWN SPECIALS AUTHORITY")
            push_error("COMMANDS_DATA TOWN SPECIALS AUTHORITY: scripts/growth.gd carries no readable `UNLOCK` dictionary, so the specials the growth lane can open cannot be read at all - the %d name(s) in this file's own TOWN_BUILT table and the %d `town`.what publishes are both unanchored, and a sixth building would reach a viewer's town with nothing here to name it" % [tb_mine.size(), tb_said.size()])
            printerr("COMMANDS_DATA TOWN SPECIALS AUTHORITY - growth.gd has no readable UNLOCK; TOWN_BUILT (%d) and `town`.what (%d) are unchecked" % [tb_mine.size(), tb_said.size()])
        else:
            var tb_unnamed: Array[String] = []
            var tb_ghost: Array[String] = []
            for tb_u in tb_unlock.keys():
                if String(TOWN_BUILT.get(String(tb_u), "")) == "":
                    tb_unnamed.append(String(tb_u))
            for tb_m in TOWN_BUILT.keys():
                if not tb_unlock.has(String(tb_m)):
                    tb_ghost.append(String(tb_m))
            if not tb_unnamed.is_empty():
                _guard_faults.append("TOWN SPECIALS UNNAMED")
                push_error("COMMANDS_DATA TOWN SPECIALS UNNAMED: the growth lane can open %d special(s) this file's TOWN_BUILT table has no word for - %s - and `_town_line()` skips a key it cannot name, so a viewer builds it and !town never says it stands while `town`.what still promises it by name" % [tb_unnamed.size(), tb_unnamed])
                printerr("COMMANDS_DATA TOWN SPECIALS UNNAMED - %d unlockable special(s) TOWN_BUILT drops in silence: %s" % [tb_unnamed.size(), tb_unnamed])
            if not tb_ghost.is_empty():
                _guard_faults.append("TOWN SPECIALS GHOST")
                push_error("COMMANDS_DATA TOWN SPECIALS GHOST: TOWN_BUILT carries %d name(s) keyed on a special the growth lane never unlocks - %s - so that word can never print on the !town line, and the table looks complete while being short by that many live keys" % [tb_ghost.size(), tb_ghost])
                printerr("COMMANDS_DATA TOWN SPECIALS GHOST - %d TOWN_BUILT key(s) nothing can open: %s" % [tb_ghost.size(), tb_ghost])
            if tb_said.is_empty():
                _guard_faults.append("TOWN SPECIALS ANCHOR")
                push_error("COMMANDS_DATA TOWN SPECIALS ANCHOR: `town`.what no longer says \"which of <buildings> are open\" - the buildings docs/COMMANDS.md tells a viewer !town will name can no longer be checked against the words TOWN_BUILT prints, so a dropped building would go unpublished in silence")
                printerr("COMMANDS_DATA TOWN SPECIALS ANCHOR - `town`.what lost its \"which of ... are open\" list; the published buildings are now unchecked")
            else:
                var tb_said_ghost: Array[String] = []
                var tb_said_miss: Array[String] = []
                for tb_s in tb_said:
                    if not tb_mine.has(tb_s):
                        tb_said_ghost.append(tb_s)
                for tb_v in tb_mine:
                    if not tb_said.has(tb_v):
                        tb_said_miss.append(tb_v)
                if not tb_said_ghost.is_empty():
                    _guard_faults.append("TOWN SPECIALS SAID GHOST")
                    push_error("COMMANDS_DATA TOWN SPECIALS SAID GHOST: `town`.what names %d building(s) the !town line can never print - %s - the words it does print are %s, so docs/COMMANDS.md sends a viewer looking for a building that is not on the line" % [tb_said_ghost.size(), tb_said_ghost, tb_mine])
                    printerr("COMMANDS_DATA TOWN SPECIALS SAID GHOST - %d published building(s) nothing prints: %s" % [tb_said_ghost.size(), tb_said_ghost])
                if not tb_said_miss.is_empty():
                    _guard_faults.append("TOWN SPECIALS SAID SHORT")
                    push_error("COMMANDS_DATA TOWN SPECIALS SAID SHORT: the !town line can print %d building(s) `town`.what never names - %s - so a viewer reads docs/COMMANDS.md, learns which buildings the command reports, and is told about fewer than it reports" % [tb_said_miss.size(), tb_said_miss])
                    printerr("COMMANDS_DATA TOWN SPECIALS SAID SHORT - %d printable building(s) unpublished: %s" % [tb_said_miss.size(), tb_said_miss])
        # ---- B101: THE CARAVAN COUNT, AND IT IS SPELLED OUT IN WORDS. ---------------------
        # `caravan`.what states THREE things about the content writer's manifest list: how many
        # carts are written, that each carries a name / a road it came from / a load, and that
        # the town's growth decides which can turn up. The team lead verified all three BY HAND
        # at 04:58 - which is exactly why this arm is worth writing: a claim that needs a human
        # to re-count it every hour is an unguarded claim. The authority is data/items.json
        # `caravan_manifests.caravans`, the CONTENT lane's file, read through `Roster.items()` -
        # the same accessor the dye and wear arms use - and town.gd:6203 reads the same rows.
        # THE NUMBER IS A WORD, NOT A DIGIT: "Twenty-eight". No digit search in the house would
        # ever have found it, which is why the satchel arm's word table had to be joined by one
        # for whole numbers - `_word_int` below.
        # THE GROWTH CLAUSE IS THE SUBTLE ONE. town.gd:6207 tests
        # `int(m.get("first_tier", 99)) <= economy.town_level`, and the growth ladder tops out at
        # 6, so a row carrying no `first_tier` can NEVER turn up: it is written and unreachable.
        # My sentence counts it as written. A quiet half-truth, not a crash, so it gets its own
        # arm rather than a mention in a comment.
        var cv_rows: Array = []
        var cv_man: Variant = (Roster.items().get("caravan_manifests", {}) as Dictionary).get("caravans", [])
        if cv_man is Array:
            cv_rows = cv_man as Array
        var cw: String = String(((cmd_d.get("caravan", {}) as Dictionary)).get("what", ""))
        var cv_tail := " carts are written"
        var cv_said: int = -1
        var cv_phrase := ""
        var cv_at: int = cw.find(cv_tail)
        if cv_at > 0:
            var cv_head: String = cw.substr(0, cv_at)
            var cv_sp: int = cv_head.rfind(" ")
            cv_phrase = (cv_head.substr(cv_sp + 1) if cv_sp >= 0 else cv_head).strip_edges()
            cv_said = _word_int(cv_phrase)
        if cv_rows.is_empty():
            _guard_faults.append("CARAVAN AUTHORITY")
            push_error("COMMANDS_DATA CARAVAN AUTHORITY: data/items.json carries no `caravan_manifests.caravans` rows, so every cart that comes up the west road is an unnamed crossing (town.gd reads the same list) and `caravan`.what counts carts that are not written")
            printerr("COMMANDS_DATA CARAVAN AUTHORITY - items.json has no caravan_manifests.caravans rows; the published count is unanchored")
        elif cv_said < 0:
            _guard_faults.append("CARAVAN ANCHOR")
            push_error("COMMANDS_DATA CARAVAN ANCHOR: `caravan`.what no longer says \"<number> carts are written\" in words this guard can read (it reads \"%s\") - the number of manifests docs/COMMANDS.md publishes can no longer be checked against the %d row(s) in data/items.json" % [cv_phrase, cv_rows.size()])
            printerr("COMMANDS_DATA CARAVAN ANCHOR - `caravan`.what lost its \"<number> carts are written\" phrase (read \"%s\"); the count is now unchecked" % cv_phrase)
        else:
            if cv_said != cv_rows.size():
                _guard_faults.append("CARAVAN COUNT")
                push_error("COMMANDS_DATA CARAVAN COUNT: `caravan`.what publishes \"%s\" (%d) carts and data/items.json carries %d manifest row(s) - docs/COMMANDS.md counts the content writer's carts wrong, and the number is spelled out in words so no digit search would ever find it" % [cv_phrase, cv_said, cv_rows.size()])
                printerr("COMMANDS_DATA CARAVAN COUNT - published \"%s\" (%d), rows %d" % [cv_phrase, cv_said, cv_rows.size()])
            var cv_short: Array[String] = []
            var cv_notier: Array[String] = []
            for cv_i in cv_rows.size():
                var cv_r: Variant = cv_rows[cv_i]
                var cv_id := "row %d" % cv_i
                if not (cv_r is Dictionary):
                    cv_short.append("%s (not a row)" % cv_id)
                    continue
                var cv_d: Dictionary = cv_r as Dictionary
                cv_id = String(cv_d.get("id", cv_id))
                var cv_lack: Array[String] = []
                if String(cv_d.get("name", "")).strip_edges() == "":
                    cv_lack.append("name")
                if String(cv_d.get("origin", "")).strip_edges() == "":
                    cv_lack.append("origin")
                if not (cv_d.get("cargo", null) is Array) or (cv_d["cargo"] as Array).is_empty():
                    cv_lack.append("cargo")
                if not cv_lack.is_empty():
                    cv_short.append("%s: %s" % [cv_id, ", ".join(PackedStringArray(cv_lack))])
                if not cv_d.has("first_tier"):
                    cv_notier.append(cv_id)
            if not cv_short.is_empty():
                _guard_faults.append("CARAVAN FIELDS")
                push_error("COMMANDS_DATA CARAVAN FIELDS: `caravan`.what promises every cart carries a name, a road it came from and a load, and %d row(s) in data/items.json are missing one of the three - %s - so !caravan publishes a promise the manifest list does not keep" % [cv_short.size(), cv_short])
                printerr("COMMANDS_DATA CARAVAN FIELDS - %d row(s) short of name/origin/cargo: %s" % [cv_short.size(), cv_short])
            if not cv_notier.is_empty():
                _guard_faults.append("CARAVAN TIER")
                push_error("COMMANDS_DATA CARAVAN TIER: %d manifest row(s) carry no `first_tier` - %s - and town.gd:6207 reads a missing one as 99, above every growth level, so those carts are written and can NEVER turn up; `caravan`.what counts them among the %d it tells a viewer are waiting on the road" % [cv_notier.size(), cv_notier, cv_said])
                printerr("COMMANDS_DATA CARAVAN TIER - %d row(s) with no first_tier can never be drawn: %s" % [cv_notier.size(), cv_notier])
        # B102: THE LAST OF B34's FOUR NUMERIC CLAIMS, AND A HALF-TRUTH FOUND WHILE READING FOR IT.
        # B35 listed four `what` claims carrying a number. `look` (B35), `satchel` (B36, echoed
        # B96) and `bestiary`'s eight lords (BESTIARY LORDS above) are all gated. The fourth was
        # left with a reason written at line 1223: `oil`.what "two delvers" is a burn RATE in
        # delve.gd with NO CONSTANT TO READ. That reason still holds and I am not pretending
        # otherwise - see the ASK at the bottom of this block.
        # WHAT I DID READ, BY HAND, THIS RUN, off scripts/delve.gd on the merged tree:
        #   :161  `oil = maxf(0.0, oil - float(maxi(1, int(ceil(float(alive_now) * 0.5)))))`
        #         - one flask per two bodies a floor, AND A FLOOR NEVER COSTS LESS THAN ONE
        #           FLASK, however few go down. `maxi(1, ...)` is that minimum.
        #   :2453 `oil = maxf(0.0, oil - 0.5)` - half a flask more to search a room.
        #   :78-80 every hero's flasks are added to one party total and their own count is SET TO
        #         ZERO at the mouth; :80 then says in the game's own voice "They carry %d flasks of
        #         oil between them." delve.gd's own docstring (:26-27) says the same: "Each hero
        #         empties their own satchel into the party's at the mouth".
        # SO `oil`.what WAS RIGHT AND INCOMPLETE, and `delve`.what WAS WRONG. It said "Everyone
        # carries their own oil", which reads to a viewer as: my flasks light me, and a hero who
        # brought none goes dark alone. The engine pools them - a hero with no oil descends on the
        # party's pool, and a hero who brought three loses them to it. That is a quiet half-truth
        # in a published line, the fault class the lead named at 23:58, and it is MINE. Both
        # sentences are corrected in data/commands.json this cycle.
        # WHAT THIS ARM IS, SAID PLAINLY: a WORDING-REGRESSION guard, not an engine guard. It
        # holds the two corrected sentences in place - the pooling clause and the floor minimum -
        # and reads the delver count so a reword to "three delvers" goes red. It CANNOT catch the
        # game build retuning the 0.5, because there is nothing to read. If that number moves,
        # this arm and my sentence go stale together, and I would rather that be written here than
        # discovered later.
        # ASK TO THE GAME BUILD LANE (scripts/delve.gd is theirs, not mine): `class_name Delve` is
        # already declared, so one named const - say `const OIL_PER_HEAD := 0.5` and
        # `const OIL_FLOOR_MIN := 1` at :161 - turns this into a real two-authority arm like LOOK
        # and SATCHEL, and closes the last of B34's four. I am not editing their file to get it.
        var dvw: String = String(((cmd_d.get("delve", {}) as Dictionary)).get("what", ""))
        if not dvw.to_lower().contains("pooled at the mouth"):
            _guard_faults.append("DELVE POOL")
            push_error("COMMANDS_DATA DELVE POOL: `delve`.what no longer says the oil is \"pooled at the mouth\" (it reads \"%s\") - delve.gd:78-80 empties every hero's flasks into ONE party total and zeroes their own, and :80 says \"between them\" in the game's own voice, so a published line that leaves the pooling out tells a viewer their flasks light only them" % dvw)
            printerr("COMMANDS_DATA DELVE POOL - `delve`.what lost the pooling clause; the published line implies per-hero oil")
        var olw: String = String(((cmd_d.get("oil", {}) as Dictionary)).get("what", ""))
        var o_tail := " delvers"
        var o_said: int = -1
        var o_phrase := ""
        var o_at: int = olw.find(o_tail)
        if o_at > 0:
            var o_head: String = olw.substr(0, o_at)
            var o_sp: int = o_head.rfind(" ")
            o_phrase = (o_head.substr(o_sp + 1) if o_sp >= 0 else o_head).strip_edges()
            o_said = _word_int(o_phrase)
        if o_said < 0:
            _guard_faults.append("OIL DELVERS ANCHOR")
            push_error("COMMANDS_DATA OIL DELVERS ANCHOR: `oil`.what no longer says \"<number> delvers\" in words this guard can read (it reads \"%s\") - the burn rate docs/COMMANDS.md publishes can no longer be checked against `Delve.OIL_PER_HEAD` at all" % o_phrase)
            printerr("COMMANDS_DATA OIL DELVERS ANCHOR - `oil`.what lost its \"<number> delvers\" phrase (read \"%s\")" % o_phrase)
        # B106: THE OIL ARMS ARE TWO-AUTHORITY ARMS NOW, AND THIS IS THE ASK ABOVE BEING ANSWERED.
        # S86 (game build, 10:14 today) named `OIL_PER_HEAD := 0.5` and `OIL_FLOOR_MIN := 1` at
        # delve.gd:336-337 and READS them at :161 - I grepped the read, not just the declaration.
        # So these arms no longer carry a number of my own: they rebuild the engine's burn out of
        # the engine's own constants and ask whether the sentence I publish is true of it. THE 2
        # THAT USED TO LIVE IN THIS FILE IS GONE, and nothing here restates a figure delve.gd owns.
        # The ask block above is left standing exactly as written - it is the record of how this
        # arm got here, and a lane that answered an ask deserves the asking kept, not tidied away.
        # WHAT THE SENTENCE CLAIMS, READ STRICTLY: "one flask lights a floor for two delvers" is a
        # CEILING claim, so it is two-sided and BOTH sides are checked - N delvers must burn
        # exactly one flask, and N+1 must burn more. An arm that checked only the first half would
        # pass unchanged if the engine got cheaper and my sentence quietly understated the light,
        # which is the same half-truth class as B102's pooling fault and also mine to catch.
        # The floor is folded into both, because delve.gd:161 wraps the burn in `maxi()`: a raised
        # OIL_FLOOR_MIN makes "for two delvers" false without OIL_PER_HEAD moving at all.
        if o_said >= 0:
            var o_burn: int = maxi(Delve.OIL_FLOOR_MIN, int(ceil(float(o_said) * Delve.OIL_PER_HEAD)))
            var o_next: int = maxi(Delve.OIL_FLOOR_MIN, int(ceil(float(o_said + 1) * Delve.OIL_PER_HEAD)))
            if o_burn != 1:
                _guard_faults.append("OIL DELVERS")
                push_error("COMMANDS_DATA OIL DELVERS: `oil`.what publishes one flask per \"%s\" (%d) delvers and delve.gd:161 burns %d flask(s) for that many bodies - `maxi(OIL_FLOOR_MIN %d, ceil(alive * OIL_PER_HEAD %s))`. A viewer buying at the published rate goes dark on the floor they paid for" % [o_phrase, o_said, o_burn, Delve.OIL_FLOOR_MIN, str(Delve.OIL_PER_HEAD)])
                printerr("COMMANDS_DATA OIL DELVERS - published %d delvers a flask, delve.gd:161 burns %d for %d" % [o_said, o_burn, o_said])
            elif o_next <= 1:
                _guard_faults.append("OIL DELVERS CEILING")
                push_error("COMMANDS_DATA OIL DELVERS CEILING: `oil`.what publishes \"%s\" (%d) delvers to a flask, but delve.gd:161 still burns only %d flask(s) for %d bodies - the engine lights MORE delvers than the sentence promises, so the published rate is not the ceiling it reads as and a viewer overbuys light they already had. OIL_PER_HEAD is %s, OIL_FLOOR_MIN %d" % [o_phrase, o_said, o_next, o_said + 1, str(Delve.OIL_PER_HEAD), Delve.OIL_FLOOR_MIN])
                printerr("COMMANDS_DATA OIL DELVERS CEILING - published %d a flask, engine lights %d on the same one" % [o_said, o_said + 1])
        # THE FLOOR CLAUSE, NOW READ AS A NUMBER RATHER THAN AS A STRING. It used to be
        # `contains("a flask at least")`, a wording guard that could not tell a raised floor from a
        # kept promise. The quantity word in front of "flask" is parsed and compared to
        # `Delve.OIL_FLOOR_MIN`, so the engine doubling the floor goes red HERE instead of being
        # discovered by a solo delver paying twice what this file quoted them.
        var o_fl_said: int = -1
        var o_fl_word := ""
        var o_fl_at: int = olw.to_lower().find(" at least")
        if o_fl_at > 0:
            var o_fl_parts: PackedStringArray = olw.substr(0, o_fl_at).strip_edges().split(" ", false)
            if o_fl_parts.size() >= 2 and String(o_fl_parts[o_fl_parts.size() - 1]).to_lower().begins_with("flask"):
                o_fl_word = String(o_fl_parts[o_fl_parts.size() - 2]).strip_edges()
                var o_fl_low := o_fl_word.to_lower()
                o_fl_said = (1 if (o_fl_low == "a" or o_fl_low == "an") else _word_int(o_fl_word))
        if o_fl_said < 0:
            _guard_faults.append("OIL FLOOR ANCHOR")
            push_error("COMMANDS_DATA OIL FLOOR ANCHOR: `oil`.what no longer carries a readable \"<n> flask(s) at least\" clause (it reads \"%s\"; the quantity word this guard found was \"%s\") - delve.gd:161 wraps the burn in `maxi(OIL_FLOOR_MIN, ...)` and that floor is now published nowhere a guard can read, so a lone delver's cost goes unwatched" % [olw, o_fl_word])
            printerr("COMMANDS_DATA OIL FLOOR ANCHOR - `oil`.what lost its readable floor clause (quantity word \"%s\")" % o_fl_word)
        elif o_fl_said != Delve.OIL_FLOOR_MIN:
            _guard_faults.append("OIL FLOOR MIN")
            push_error("COMMANDS_DATA OIL FLOOR MIN: `oil`.what publishes a floor of \"%s\" (%d) flask(s) a floor and `Delve.OIL_FLOOR_MIN` is %d - delve.gd:161 charges the engine's figure, so a viewer sending one hero down is quoted %d and pays %d" % [o_fl_word, o_fl_said, Delve.OIL_FLOOR_MIN, o_fl_said, Delve.OIL_FLOOR_MIN])
            printerr("COMMANDS_DATA OIL FLOOR MIN - published floor %d, engine OIL_FLOOR_MIN %d" % [o_fl_said, Delve.OIL_FLOOR_MIN])
        # B103: THE ARMOURY'S PRICE GUARD WAS READING A TABLE NO SHOP CHARGES, AND THE FORGE'S
        # PRICE LADDER HAD NO ARM AT ALL. Both found by measurement, and the second one disproves
        # a sentence THIS FILE PUBLISHES ABOUT ITSELF.
        # WHAT B83 ASSERTS, ~1200 LINES ABOVE: "every one of them already sits under an arm. No
        # published number in this file is unwatched", listing "forge 60/160/420/1100" among the
        # numbers it had walked. THAT IS FALSE, AND IT WAS FALSE WHEN IT WAS WRITTEN. `forge`.cost
        # publishes four prices; the FORGE arms above check Gear.KINDS and nothing else - the KIND
        # LIST. Nothing in the house has ever compared the forge's money to the smith's. (The same
        # comment still says "miniboss 36"; the published count has been 44 since B94. Neither
        # line is rewritten - a lane's wrong sentence is the evidence of how the mistake happened,
        # and the correction belongs where the work is, which is here.)
        # WORSE, AND THE REASON THIS IS NOT MERELY A GAP: `grep -rn "Gear\.ARMOUR\b" scripts/`
        # over the whole game returns NOTHING OUTSIDE THIS FILE. Gear.ARMOUR (gear.gd:30) is read
        # by my own guard and by no shop, no till and no stall. `Roster.buy_armour` charges
        # `Roster.ARMOUR` (roster.gd:183), a SECOND six-row table carrying its own copy of every
        # price. So ARMOURY COST has been checking the price I publish against a table no viewer
        # ever pays, and its own error text said "Gear.ARMOUR charges" - a false statement about
        # the engine, written by me, inside the arm built to catch false statements about the
        # engine. The two copies agree row for row TODAY, which is exactly why it printed OK and
        # why no battery, mine or anyone's, could see it.
        # THE SAME SHAPE ON THE WEAPONS SIDE, with one difference that makes it worse rather than
        # better: `Roster.WEAPONS` (roster.gd:171) is what `buy_weapon` charges, and Gear.WEAPONS
        # IS read elsewhere - town.gd:4571 dresses the smithy's stall out of it. A drift between
        # those two copies does not just blind a guard: it puts one price on the goods a viewer
        # can SEE on the stall and a different one in the till.
        # WHAT I CHANGED, AND WHAT I REFUSED TO DO: the armoury arms now read the table that
        # CHARGES, and I did NOT copy a price into this file to compare against. B41's rule holds
        # - a fourth copy of a price would be the defect and not the guard. Instead the two engine
        # copies are now compared TO EACH OTHER, so the drift that would have hidden all of this
        # is the thing that goes red first.
        # FIVE NEW PATHS, all independent: FORGE COST ANCHOR and FORGE COST (two authorities, the
        # published ladder against the till), one AUTHORITY arm per ladder (till copy against
        # stall copy), and FORGE REWORK, which is WORDING ONLY and says so.
        var f_d: Dictionary = (cmd_d.get("forge", {}) as Dictionary)
        var f_cost: String = String(f_d.get("cost", ""))
        # the published ladder: leading digits of each slash-separated piece, the same reading
        # ARMOURY COST uses, so one published-ladder reader serves both shops.
        var f_said_cost: Array = []
        for f_pc in f_cost.split("/", false):
            var f_piece := String(f_pc).strip_edges()
            var f_dig := ""
            for f_i in f_piece.length():
                var f_ch := f_piece[f_i]
                if f_ch >= "0" and f_ch <= "9":
                    f_dig += f_ch
                elif f_dig != "":
                    break
            if f_dig != "":
                f_said_cost.append(int(f_dig))
        # what the smith actually charges. `bare hands` is neither bought nor found - it is the
        # state a hero starts in - and `scarforged` is found-only, so neither is a priced tier.
        var f_real_cost: Array = []
        var f_real_name: Array = []
        for f_row in Roster.WEAPONS:
            var f_r: Dictionary = f_row
            if bool(f_r.get("found", false)):
                continue
            if int(f_r.get("cost", 0)) > 0:
                f_real_cost.append(int(f_r.get("cost", 0)))
                f_real_name.append(String(f_r.get("name", "")))
        if f_said_cost.is_empty():
            _guard_faults.append("FORGE COST ANCHOR")
            push_error("COMMANDS_DATA FORGE COST ANCHOR: `forge`.cost no longer carries a slash-separated price ladder (it reads \"%s\") - the forge prices docs/COMMANDS.md publishes can no longer be checked against Roster.WEAPONS, which charges %s for %s" % [f_cost, str(f_real_cost), str(f_real_name)])
            printerr("COMMANDS_DATA FORGE COST ANCHOR - `forge`.cost lost its price ladder; the smith's money is now unchecked")
        elif f_said_cost != f_real_cost:
            var f_ctip: String = "published %d price(s) against %d forgeable tier(s)" % [f_said_cost.size(), f_real_cost.size()]
            if f_said_cost.size() == f_real_cost.size():
                f_ctip = "same count, wrong money - a price ladder's order is the claim"
            _guard_faults.append("FORGE COST")
            push_error("COMMANDS_DATA FORGE COST: `forge`.cost publishes %s gold by tier and `Roster.buy_weapon` charges %s for %s - a viewer is quoted a price the smith does not take, and finds out by paying; %s" % [str(f_said_cost), str(f_real_cost), str(f_real_name), f_ctip])
            printerr("COMMANDS_DATA FORGE COST - published %s, charged %s" % [str(f_said_cost), str(f_real_cost)])
        # THE TWO COPIES OF EACH LADDER. The till's table is the authority for what a viewer pays;
        # the other copy is what the rest of the game dresses itself from. They are compared on
        # the three fields my own arms read - name, cost and the found-only flag - and nothing is
        # restated here: both sides of every comparison are the engine's own.
        for f_auth in [["ARMOURY", "armour", Roster.ARMOUR, Gear.ARMOUR, "Roster.ARMOUR (roster.gd:183)", "Gear.ARMOUR (gear.gd:30)", "Roster.buy_armour", "nothing outside this guard reads the gear.gd copy, so a drift there is silent until a lane wires it up"],
                       ["FORGE", "weapon", Roster.WEAPONS, Gear.WEAPONS, "Roster.WEAPONS (roster.gd:171)", "Gear.WEAPONS (gear.gd:21)", "Roster.buy_weapon", "town.gd:4571 dresses the smithy's stall from the gear.gd copy, so a drift puts one price on the stall and another in the till"]]:
            var au_tag: String = String(f_auth[0])
            var au_word: String = String(f_auth[1])
            var au_till: Array = f_auth[2]
            var au_other: Array = f_auth[3]
            var au_tname: String = String(f_auth[4])
            var au_oname: String = String(f_auth[5])
            var au_buyer: String = String(f_auth[6])
            var au_why: String = String(f_auth[7])
            var au_diff: Array = []
            if au_till.size() != au_other.size():
                au_diff.append("%d rows in %s against %d in %s" % [au_till.size(), au_tname, au_other.size(), au_oname])
            for au_i in range(mini(au_till.size(), au_other.size())):
                var au_a: Dictionary = au_till[au_i]
                var au_b: Dictionary = au_other[au_i]
                for au_k in ["name", "cost", "found"]:
                    var au_va: String = str(au_a.get(au_k, null))
                    var au_vb: String = str(au_b.get(au_k, null))
                    if au_va != au_vb:
                        au_diff.append("row %d `%s`: %s vs %s" % [au_i, String(au_k), au_va, au_vb])
            if not au_diff.is_empty():
                _guard_faults.append("%s AUTHORITY" % au_tag)
                push_error("COMMANDS_DATA %s AUTHORITY: the %s ladder is declared TWICE IN THE ENGINE and the two no longer agree - %s is what %s charges, %s is the other copy, and they differ: %s. docs/COMMANDS.md can only be right about one of them, and %s" % [au_tag, au_word, au_tname, au_buyer, au_oname, str(au_diff), au_why])
                printerr("COMMANDS_DATA %s AUTHORITY - the two engine %s tables disagree: %s" % [au_tag, au_word, str(au_diff)])
        # THE REWORK CLAUSE, AND WHAT THIS ARM HONESTLY IS. `forge`.cost ends "(rework at the top:
        # a quarter)" - the promise that a hero already at the best forgeable tier pays a QUARTER
        # to have their steel remade in another kind. The engine site is roster.gd:510,
        # `int(int(WEAPONS[int(h["weapon"])]["cost"]) / 4)`. THE 4 IS A BARE LITERAL: there is no
        # named constant anywhere in scripts/ for it, so there is no second authority to compare
        # against and THIS ARM GUARDS MY OWN WORDING, NOT THE ENGINE - exactly the limit B102's
        # oil arms carry, and it is said here rather than left for a reader to work out. If the
        # GAME BUILD lane ever wants this to be a real two-authority arm, one const at that site
        # (`REWORK_DIVISOR := 4`) is all it needs and this arm will read it instead. Declining
        # that is free; the wording guard stands either way, because a clause silently deleted
        # from my own file is the failure this arm actually catches.
        # B106: AND THE REWORK CLAUSE IS A TWO-AUTHORITY ARM NOW TOO - the other half of the same
        # ask, answered by the same cycle. `Roster.REWORK_DIVISOR := 4` is declared at roster.gd:218
        # and READ at :514 (I grepped both ends; the ask block above still says :510 because that
        # is where the bare literal stood when the ask was written, and S86's edit moved the line).
        # The arm no longer asks whether the WORD "quarter" is present. It reads WHICH fraction word
        # the sentence publishes, turns it into the divisor that word means, and compares that to the
        # engine's constant. So re-pricing the rework to a third goes red with my sentence named, and
        # so does rewording my sentence to a third while the smith still charges a quarter. A wording
        # guard could catch neither: it only ever noticed the clause being deleted outright.
        var f_rw_words := {"half": 2, "third": 3, "quarter": 4, "fifth": 5, "sixth": 6,
                           "seventh": 7, "eighth": 8, "ninth": 9, "tenth": 10}
        var f_rw_low := f_cost.to_lower()
        var f_rw_word := ""
        var f_rw_said: int = -1
        for f_rw_k in f_rw_words:
            if f_rw_low.contains(String(f_rw_k)):
                f_rw_word = String(f_rw_k)
                f_rw_said = int(f_rw_words[f_rw_k])
                break
        if f_rw_said < 0:
            _guard_faults.append("FORGE REWORK")
            push_error("COMMANDS_DATA FORGE REWORK: `forge`.cost no longer carries a readable fraction word for the rework clause (it reads \"%s\") - roster.gd:514 charges `cost / REWORK_DIVISOR` (%d) to remake the top tier in another kind, and with the clause gone a viewer at the top of the ladder is told only that the forge sells nothing more" % [f_cost, Roster.REWORK_DIVISOR])
            printerr("COMMANDS_DATA FORGE REWORK - `forge`.cost lost its rework fraction word; the top-tier price is unpublished")
        elif f_rw_said != Roster.REWORK_DIVISOR:
            _guard_faults.append("FORGE REWORK RATE")
            push_error("COMMANDS_DATA FORGE REWORK RATE: `forge`.cost publishes the top-tier rework at \"a %s\" (1/%d) and `Roster.REWORK_DIVISOR` is %d, which roster.gd:514 charges - a hero at the top of the ladder is quoted one fraction of their steel's cost and billed another, and the gap is paid in gold before anybody reads a log" % [f_rw_word, f_rw_said, Roster.REWORK_DIVISOR])
            printerr("COMMANDS_DATA FORGE REWORK RATE - published 1/%d (\"a %s\"), engine REWORK_DIVISOR %d" % [f_rw_said, f_rw_word, Roster.REWORK_DIVISOR])
        # B104: THE COUNTER SET AGAINST THE ENGINE'S OWN TILLS - A TWO-AUTHORITY ARM, AND THE
        # DEFECT IT WAS WRITTEN FOR WAS MINE. handle() refuses a shop command while a hero is on
        # the scar road or below it. That list was a bare literal and `oil` was never in it, so
        # `!oil` charged gold, rolled the counter haggle and handed flasks to a hero standing in
        # the dark while every other till said "Tilda is below." Nothing published it and no arm
        # watched it: a gate is a promise kept in code, so a hole in one is silent by nature.
        # THE SECOND AUTHORITY IS roster.gd ITSELF. `haggle()` is the counter: it is called by
        # exactly the functions that stand a viewer in front of a shopkeeper, and the engine
        # decides that, not me. Every call site is collected from the source and held to
        # AWAY_COUNTERS. The one restated thing is the func -> command map, and it is restated
        # BECAUSE it is the join nothing else in the house writes down; a new till arrives as an
        # unmapped name and the UNKNOWN arm below says so rather than passing silently.
        # `kit_up_after_delve` mentions haggle() in a COMMENT and must not be collected - the
        # scan drops everything after a `#`, which is why it reads the code and not the prose.
        var ca_map := {"buy_weapon": "forge", "buy_armour": "armoury", "buy_potion": "brew",
                       "buy_brew": "brew", "buy_oil": "oil", "wear": "wear", "dye": "dye"}
        var ca_f := FileAccess.open("res://scripts/roster.gd", FileAccess.READ)
        if ca_f == null:
            _guard_faults.append("COUNTER AWAY ANCHOR")
            push_error("COMMANDS_DATA COUNTER AWAY ANCHOR: scripts/roster.gd cannot be opened, so the engine's own counter set (every caller of `haggle()`) cannot be read and the %d-command away gate in handle() is held to nothing - a shop added to the game would reach a hero who is below ground and no arm here would know" % AWAY_COUNTERS.size())
            printerr("COMMANDS_DATA COUNTER AWAY ANCHOR - roster.gd unreadable; the away gate is unchecked")
        else:
            var ca_lines: PackedStringArray = ca_f.get_as_text().split("\n")
            var ca_fn := ""
            var ca_tills: Array = []
            for ca_ln in ca_lines:
                var ca_raw: String = String(ca_ln)
                if ca_raw.begins_with("func "):
                    var ca_p: int = ca_raw.find("(")
                    ca_fn = ca_raw.substr(5, ca_p - 5).strip_edges() if ca_p > 5 else ""
                var ca_h: int = ca_raw.find("#")
                var ca_code: String = ca_raw.substr(0, ca_h) if ca_h >= 0 else ca_raw
                if ca_fn != "" and ca_fn != "haggle" and ca_code.contains("haggle(") and not ca_tills.has(ca_fn):
                    ca_tills.append(ca_fn)
            if ca_tills.is_empty():
                _guard_faults.append("COUNTER AWAY ANCHOR")
                push_error("COMMANDS_DATA COUNTER AWAY ANCHOR: not one call to `haggle()` survives in scripts/roster.gd, so the engine no longer names its own counters and the away gate in handle() has nothing left to be checked against - either the haggle has been renamed (this arm must follow it) or every shop now charges list price with no CHA check at the till, which `_source` publishes as the rule for every cost in docs/COMMANDS.md")
                printerr("COMMANDS_DATA COUNTER AWAY ANCHOR - no haggle() call sites in roster.gd; the counter set is unreadable")
            else:
                var ca_unknown: Array = []
                var ca_open: Array = []
                for ca_t in ca_tills:
                    var ca_name: String = String(ca_t)
                    if not ca_map.has(ca_name):
                        ca_unknown.append(ca_name)
                        continue
                    var ca_v: String = String(ca_map[ca_name])
                    if not AWAY_COUNTERS.has(ca_v):
                        ca_open.append("%s -> !%s" % [ca_name, ca_v])
                if not ca_unknown.is_empty():
                    _guard_faults.append("COUNTER UNKNOWN")
                    push_error("COMMANDS_DATA COUNTER UNKNOWN: scripts/roster.gd stands a viewer at a till in %s, and this guard's func -> command map has never heard of %s - a new shop has been added to the engine and the away gate in handle() cannot be checked for it, so a hero who is below ground may be able to buy from it. One line in the map beside the command that calls it closes this" % [str(ca_unknown), str(ca_unknown)])
                    printerr("COMMANDS_DATA COUNTER UNKNOWN - unmapped haggle site(s) in roster.gd: %s" % str(ca_unknown))
                if not ca_open.is_empty():
                    _guard_faults.append("COUNTER AWAY")
                    push_error("COMMANDS_DATA COUNTER AWAY: %s charge(s) a haggled price in scripts/roster.gd and the command is NOT in AWAY_COUNTERS - %s, so a hero on the scar road or below it is served at that counter while every other till refuses with where the hero is. The viewer pays gold and the bot describes a shop the hero is nowhere near" % [str(ca_open), str(ca_open)])
                    printerr("COMMANDS_DATA COUNTER AWAY - ungated counter(s): %s" % str(ca_open))
        # B114: THE SMITHY'S LEVEL IS THE CEILING, AND NOTHING PUBLISHED IT. D64a (game build,
        # scripts/economy.gd) gave the smithy a LEVEL and made that level alone the top rarity the
        # counter will ever stock - `shop_cap()` feeds `Roster.town_tier`, clamped to
        # SHOP_MAX_LEVEL. A hero with the gold for the top step is refused by the BUILDING, not by
        # their purse. `forge`.what said only "The best tiers need Bellmire to grow" - true and
        # unmeasurable - and `armoury`.what said NOTHING AT ALL, so a viewer saving 1000 gold for
        # warded plate had no published way to learn the counter would turn them away. Both now
        # state the ceiling in the ladder's own words and this arm holds those words to the engine.
        # THE AUTHORITY IS READ AS SOURCE TEXT, not through a class name: economy.gd is the GAME
        # BUILD's file and is NOT an autoload (project.godot registers only `Lore`), so the
        # COUNTER AWAY arm's habit of reading the file is the one that survives a rename. Comment
        # lines are dropped before the consts are read - that is the trap that read MB_NAME as 37.
        # NOT FATAL: the commands answer either way. A battery greps COMMANDS_DATA and no line is
        # the healthy reading; the tag is registered so guard_faults() counts it.
        var sc_f := FileAccess.open("res://scripts/economy.gd", FileAccess.READ)
        var sc_rar: Array = []
        var sc_max := -1
        if sc_f != null:
            for sc_ln in sc_f.get_as_text().split("\n"):
                var sc_raw: String = String(sc_ln)
                if sc_raw.strip_edges().begins_with("#"):
                    continue
                var sc_h: int = sc_raw.find("#")
                var sc_code: String = sc_raw.substr(0, sc_h) if sc_h >= 0 else sc_raw
                if sc_rar.is_empty() and sc_code.contains("const RARITY :="):
                    var sc_a: int = sc_code.find("[")
                    var sc_b: int = sc_code.rfind("]")
                    if sc_a >= 0 and sc_b > sc_a:
                        for sc_w in sc_code.substr(sc_a + 1, sc_b - sc_a - 1).split(",", false):
                            var sc_t: String = String(sc_w).strip_edges().trim_prefix("\"").trim_suffix("\"")
                            if sc_t != "":
                                sc_rar.append(sc_t)
                if sc_max < 0 and sc_code.contains("const SHOP_MAX_LEVEL :="):
                    var sc_n: String = sc_code.get_slice(":=", 1).strip_edges()
                    if sc_n.is_valid_int():
                        sc_max = int(sc_n)
        if sc_rar.is_empty() or sc_max < 1 or sc_max >= sc_rar.size():
            _guard_faults.append("SHOP CAP AUTHORITY")
            push_error("COMMANDS_DATA SHOP CAP AUTHORITY: scripts/economy.gd no longer yields a readable `const RARITY :=` ladder and `const SHOP_MAX_LEVEL :=` (read %s and %d), so the top tier a counter will ever stock cannot be checked and the ceiling `forge`.what and `armoury`.what publish to chat is unguarded" % [str(sc_rar), sc_max])
            printerr("COMMANDS_DATA SHOP CAP AUTHORITY - economy.gd RARITY/SHOP_MAX_LEVEL unreadable (%s, %d); the published shop ceiling is unchecked" % [str(sc_rar), sc_max])
        else:
            var sc_rx := RegEx.new()
            sc_rx.compile("level\\s+(\\d+)\\s+stocks\\s+([a-z][a-z ]*?)\\s*(?:,|\\.|;|$)")
            for sc_key in ["forge", "armoury"]:
                var sc_what: String = String(((cmd_d.get(sc_key, {}) as Dictionary)).get("what", "")).to_lower()
                var sc_pairs: Array = []
                for sc_m in sc_rx.search_all(sc_what):
                    sc_pairs.append([int(sc_m.get_string(1)), String(sc_m.get_string(2)).strip_edges()])
                if sc_pairs.size() < 2:
                    _guard_faults.append("SHOP CAP ANCHOR")
                    push_error("COMMANDS_DATA SHOP CAP ANCHOR: `%s`.what carries %d \"level <n> stocks <rarity>\" phrase(s) and this arm needs the floor and the ceiling - the smithy's level is what refuses a hero who has the gold (economy.gd shop_cap -> Roster.town_tier, top level %d = \"%s\"), and docs/COMMANDS.md no longer tells a viewer that before they save for it" % [sc_key, sc_pairs.size(), sc_max, String(sc_rar[sc_max])])
                    printerr("COMMANDS_DATA SHOP CAP ANCHOR - `%s`.what lost its \"level <n> stocks <rarity>\" phrases; the published ceiling is unchecked" % sc_key)
                    continue
                var sc_bad: Array = []
                var sc_top := -1
                for sc_p in sc_pairs:
                    var sc_lv: int = int(sc_p[0])
                    var sc_word: String = String(sc_p[1])
                    sc_top = maxi(sc_top, sc_lv)
                    if sc_lv < 1 or sc_lv > sc_max or String(sc_rar[sc_lv]) != sc_word:
                        sc_bad.append("level %d stocks \"%s\"" % [sc_lv, sc_word])
                if not sc_bad.is_empty():
                    _guard_faults.append("SHOP CAP DRIFT")
                    push_error("COMMANDS_DATA SHOP CAP DRIFT: `%s`.what publishes %s and economy.gd's ladder is %s capped at level %d - a viewer is told a level stocks a tier the counter will not put on it; %s" % [sc_key, str(sc_bad), str(sc_rar), sc_max, str(sc_pairs)])
                    printerr("COMMANDS_DATA SHOP CAP DRIFT - `%s`.what: %s against ladder %s cap %d" % [sc_key, str(sc_bad), str(sc_rar), sc_max])
                if sc_top != sc_max:
                    _guard_faults.append("SHOP CAP CEILING")
                    push_error("COMMANDS_DATA SHOP CAP CEILING: `%s`.what publishes level %d as the best a smithy reaches and economy.gd's SHOP_MAX_LEVEL is %d (\"%s\") - the doc either promises a tier no building can stock or hides one a grown town can, and D66's raise_shop() moves this number" % [sc_key, sc_top, sc_max, String(sc_rar[sc_max])])
                    printerr("COMMANDS_DATA SHOP CAP CEILING - `%s`.what tops out at level %d, SHOP_MAX_LEVEL is %d" % [sc_key, sc_top, sc_max])
        _cmds = parsed
        # ---- B138: THE ONE THING THIS FILE PUBLISHES THAT IT NEVER MEASURED - THE LENGTH OF ITS
        # OWN ANSWER. Every arm above checks whether a published WORD is true. None checks whether
        # the line carrying it ARRIVES. twitch_eventsub.gd (the game build's) pastes "@<login> "
        # on the front and, past CHAT_MAX_LEN, cuts the result and appends "...". That cut is the
        # one drop in that whole function with NO _say_log beside it - the queue-full drop, the
        # stale drop and the duplicate drop all log; truncation is silent. So a line of mine that
        # grows past the cap loses its tail on stream and says so nowhere, and what sits at the
        # tail of the longest line this file emits is the hub URL - the one thing a viewer needs
        # when the answer was too long to finish.
        # WHY IT IS A FAULT NOW AND WAS NOT BEFORE: help_line("") is built from `order`, so it
        # grows whenever ANY lane adds a command, not when I touch anything. It is the only reply
        # in this file whose length is decided by a list other lanes extend.
        # TWO NUMBERS BELOW ARE MIRRORS OF ANOTHER LANE'S FILE AND ARE LABELLED AS SUCH:
        # CHAT_MAX_LEN (480) and the 25-character ceiling Twitch puts on a login. I do not read
        # them from twitch_eventsub.gd on purpose - this file must not fall over when that script
        # is absent - so if the game build moves CHAT_MAX_LEN, this arm's number has to follow it,
        # and my summary says so in the same breath. 25 is Twitch's own limit, not that lane's.
        # MEASURED, NOT EMULATED: the lines come from help_line() itself, reading the cache set
        # one line above, so the arm cannot drift from the function it guards. A key carrying
        # neither `short` nor `what` is SKIPPED, not measured - help_line() would fault on it and
        # the NO WHAT arm above already names it; crashing the loader here would turn a reported
        # fault into a dead bot.
        var hl_cap := 480            # mirror of twitch_eventsub.gd CHAT_MAX_LEN
        var hl_pre := 1 + 25 + 1     # "@" + the longest login Twitch issues + " "
        var hl_budget: int = hl_cap - hl_pre
        var hl_over: Array[String] = []
        var hl_rows: Array = [["!help", help_line("")]]
        var hl_cs: Dictionary = (parsed as Dictionary).get("commands", {})
        for hl_k in hl_cs.keys():
            var hl_c: Variant = hl_cs[hl_k]
            if not (hl_c is Dictionary):
                continue
            var hl_d: Dictionary = hl_c as Dictionary
            if String(hl_d.get("short", "")) == "" and String(hl_d.get("what", "")) == "":
                continue
            hl_rows.append(["!help " + String(hl_k), help_line(String(hl_k))])
        for hl_r in hl_rows:
            var hl_len: int = String(hl_r[1]).length()
            if hl_len > hl_budget:
                hl_over.append("%s is %d chars, %d over" % [String(hl_r[0]), hl_len, hl_len - hl_budget])
        if not hl_over.is_empty():
            _guard_faults.append("HELP LINE CUT")
            push_error("COMMANDS_DATA HELP LINE CUT: %d reply(s) this file publishes are longer than the %d characters that survive a worst-case \"@<login> \" prefix under a %d-char cap, so chat cuts the tail and appends \"...\" with nothing logged anywhere - the hub URL is what sits at that tail: %s" % [hl_over.size(), hl_budget, hl_cap, hl_over])
            printerr("COMMANDS_DATA HELP LINE CUT - %d reply(s) over the %d-char budget and silently truncated on stream: %s" % [hl_over.size(), hl_budget, hl_over])
    return _cmds

## B101: a whole number written out in words, or -1 when this guard cannot read it. The satchel
## arm already had to carry a FRACTION table ("two fifths" -> 0.4) because the voice of this bot
## spells its numbers out; the caravan count is the first WHOLE number published the same way,
## and a digit search would have walked straight past it. Digits are accepted too, so the
## sentence can be rewritten either way without the arm going blind.
static func _word_int(w: String) -> int:
    var s := w.strip_edges().to_lower()
    if s.is_valid_int():
        return int(s)
    var units := {"zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6,
                  "seven": 7, "eight": 8, "nine": 9, "ten": 10, "eleven": 11, "twelve": 12,
                  "thirteen": 13, "fourteen": 14, "fifteen": 15, "sixteen": 16,
                  "seventeen": 17, "eighteen": 18, "nineteen": 19}
    var tens := {"twenty": 20, "thirty": 30, "forty": 40, "fifty": 50, "sixty": 60,
                 "seventy": 70, "eighty": 80, "ninety": 90}
    if units.has(s):
        return int(units[s])
    if tens.has(s):
        return int(tens[s])
    var parts: PackedStringArray = s.split("-")
    if parts.size() == 2 and tens.has(String(parts[0])) and units.has(String(parts[1])):
        var u: int = int(units[String(parts[1])])
        if u >= 1 and u <= 9:
            return int(tens[String(parts[0])]) + u
    return -1

## B53: THE GATE TEST READS CODE, NEVER PROSE. The first emulation of the needs_hero arm found
## the text `_needs(` inside the arm's OWN COMMENT BLOCK and scored it as a hero gate on
## !catchup - a disagreement that did not exist. The team lead hit the same trap at 09:5x on a
## `district_rules` mention in a comment, and U76 closed it for the HUD by skipping strings.
## So comments and string literals come out of a body before anything is tested against it.
static func _code_only(s: String) -> String:
    var out := ""
    for ln in s.split("\n"):
        var line: String = ln
        var q := false
        var keep := ""
        var i := 0
        while i < line.length():
            var c: String = line[i]
            if q and c == "\\":
                i += 2
                continue
            if c == "\"":
                q = not q
                i += 1
                continue
            if c == "#" and not q:
                break
            if not q:
                keep += c
            i += 1
        out += keep + "\n"
    return out

## B53: a function's body, ending where the next top-level form begins. The first version ended
## it at the next "\nfunc ", which does not match "static func" - the _catchup slice overran by
## 1,482 lines. Column 0 is the only honest boundary, because every top-level form starts there.
static func _func_body(src: String, fname: String) -> String:
    var lines: PackedStringArray = src.split("\n")
    var st: int = -1
    for i in lines.size():
        var l: String = lines[i]
        if l.begins_with("func %s(" % fname) or l.begins_with("static func %s(" % fname):
            st = i
            break
    if st < 0:
        return ""
    var out := ""
    var j: int = st + 1
    while j < lines.size():
        var l2: String = lines[j]
        if l2.strip_edges() != "" and not l2.begins_with(" ") and not l2.begins_with("\t"):
            break
        out += l2 + "\n"
        j += 1
    return out

## B18: the published cooldown is now the ENFORCED one. data/commands.json carries `cooldown_s`
## (1.5) and tools/_commands_doc.gd prints it into docs/COMMANDS.md as a promise to viewers -
## "one every 1.5 s" - while the gate actually used the constant below. The two agreed by
## coincidence, not by construction, so editing the data would have made my own doc lie. The
## key is READ now, which closes it the way D98 closes a pool. COOLDOWN stays as the fallback
## for a run with no data file, and is the only number a reader has to trust.
static func cooldown() -> float:
    var v: float = float(commands().get("cooldown_s", COOLDOWN))
    return v if v > 0.0 else COOLDOWN

## B169: READ THIS BEFORE YOU WRITE A PLURAL GUARD ARM - THERE IS NOTHING TO GUARD.
## The alias column has FOUR loader arms (ALIAS UNUSABLE / SHADOW / CLASH / DEAD, :1044-1060,
## B108) and `guard_faults()` is read by tools/_l14_test.gd:163, so any alias fault fails a
## gate. The PLURAL fallback below (L69) has no arm, and I went looking for the fault that
## would earn it. There is none, and this is a PROOF rather than a sample, which is why no arm
## is owed: the plural path is only reached for a word `commands` does not hold and no
## `aliases` list holds, and its FIRST cut is one character, so for any published word w the
## form w+"s" cuts back to w itself and resolves to w's OWN command before any other key is
## walked. A published word's plural therefore cannot land on another command. I measured it
## too, both directions over all 63 published words (32 keys + 31 aliases): plurals routing to
## the wrong command ZERO. The one shape the cuts CAN differ on is w+"es", whose cut-1 stem is
## w+"e" - that needs two published words one trailing "e" apart on different commands, which
## the namespace does not hold and which would be an ALIAS SHADOW the moment it did.
## NOT A DEFECT EITHER, recorded in the `max_len` precedent so nobody "fixes" it: 13 of the 32
## commands carry no `short` field. That is BY DESIGN - help_line() (:3205) falls back to the
## first sentence of `what`, and the fallback fires only on an ABSENT key, never an empty one
## (no command carries an empty `short`; checked). Do not backfill `short` to silence it.
## an alias -> its command ("inv" -> "inventory"); anything else unchanged
static func canonical(word: String) -> String:
    var cs: Dictionary = commands().get("commands", {})
    if cs.has(word):
        return word
    for k in cs:
        if (cs[k].get("aliases", []) as Array).has(word):
            return k
    # L69: a plural reaches the command - "!heroes", "!delves", "!dyes"
    for cut in [1, 2]:
        if not word.ends_with("s") or word.length() - cut < 3:
            continue
        var one := word.substr(0, word.length() - cut)
        if cs.has(one):
            return one
        for k in cs:
            if (cs[k].get("aliases", []) as Array).has(one):
                return k
    return word

## !help: the short list; !help <command>: that one in detail
static func help_line(arg := "") -> String:
    var cs: Dictionary = commands().get("commands", {})
    if arg != "":
        var k := canonical(arg.trim_prefix("!").to_lower())
        if not cs.has(k):
            # D70.4: the viewer's own word again - capped, and dropped entirely if nothing survives
            var shown := safe_word(arg.trim_prefix("!"))
            return "!help lists them all." if shown == "" else "No !%s. !help lists them all." % shown
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
    var tail := hub_url()
    return "Commands: %s  |  !help <command> for more.%s" % [" ".join(bits), "" if tail == "" else "  All of it: " + tail]

## ---- L69: THE BOT CARRIES THE CHAT. A viewer who does not know the commands still
## gets an answer: a line with no "!" is flattened to words and matched against the
## phrases in data/commands.json "ask". Silence reads as a broken bot. The answers
## themselves are DATA, so chat, the hub and this file cannot disagree - and nothing a
## viewer typed is ever echoed back, only a fixed line or what the game itself produced.
## A shared answer is said ONCE to the channel in gap_s seconds, however many ask it.
static var _said := {}          # topic -> msec it was last said to the channel
const ASK_FLAT := "abcdefghijklmnopqrstuvwxyz0123456789"

static func ask() -> Dictionary:
    return commands().get("ask", {})

## a chat line cut down to words: lower case, punctuation gone, single spaces
static func _flat(msg: String) -> String:
    var out := ""
    for c in msg.to_lower():
        out += c if ASK_FLAT.contains(c) else " "
    return " ".join(out.split(" ", false))

## does this line match one of a topic's phrases? "a+b" wants both words present,
## any other pattern is the phrase itself on a word boundary
static func _hits(flat: String, phrases: Array) -> bool:
    var words: Array = Array(flat.split(" ", false))
    for p in phrases:
        var pat := String(p)
        if pat.contains("+"):
            var all := true
            for w in pat.split("+", false):
                if not words.has(String(w)):
                    all = false
                    break
            if all:
                return true
        elif (" " + flat).contains(" " + pat):
            return true
    return false

## the topic a plain line asks about, or "" - the first one in "order" that matches
static func ask_topic(msg: String) -> String:
    var a := ask()
    if a.is_empty() or msg.length() > int(a.get("max_len", 140)):
        return ""
    var flat := _flat(msg)
    if flat == "":
        return ""
    var ts: Dictionary = a.get("topics", {})
    for k in a.get("order", ts.keys()):
        if ts.has(k) and _hits(flat, (ts[k] as Dictionary).get("phrases", [])):
            return String(k)
    return ""

## answer a plain question, or stay quiet. A topic with `cmd` runs that command for
## the asker (their own hero differs, so it is never held back); a topic with `reply`
## is a shared line and is said to the channel once, not once for every asker.
func _ask_line(user_id: String, display: String, login: String, msg: String) -> String:
    var topic := ask_topic(msg)
    if topic == "":
        return ""
    var t: Dictionary = (ask().get("topics", {}) as Dictionary).get(topic, {})
    var cmd := String(t.get("cmd", ""))
    if cmd != "":
        return handle(user_id, display, "!" + cmd, login)
    var out := String(t.get("reply", ""))
    if out == "":
        return ""
    var now := Time.get_ticks_msec()
    if now - int(_last.get(user_id, -99999)) < int(cooldown() * 1000.0):
        return ""
    if now - int(_said.get(topic, -999999999)) < int(float(ask().get("gap_s", 45.0)) * 1000.0):
        return ""                              # already said to the channel; saying it again is noise
    _said[topic] = now
    _last[user_id] = now
    last_cmd[user_id] = now
    out += _hub_tail()
    out = safe_line(out)              # D70.4
    say.emit(out, _tone(out))
    _ui_snd("menu_select", out)
    return _reply(user_id, display, login, out)

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
