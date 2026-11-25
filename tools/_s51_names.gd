extends SceneTree
## S51: Mr. E's miniboss rename (supervisor doc sup-nov19-2150). Every one of the 36 trade keys
## in the directive's table maps to its new name; the names are unique, carry no "The" and no
## trade word; every body on disk still resolves and every key with feed lines still reads them
## (the key did not move). Prints S51_NAMES OK <n> / S51_NAMES FAIL <n>.
## S52: TABLE is a second copy of MB_NAME and can only agree with it - it shipped `drizzler`, a key
## that exists nowhere in this game, and passed. The KEY-SET checks below read three INDEPENDENT
## sources instead: content's miniboss_feed.by_key, MB_FIT's base keys, and the .glb stems under
## MB_DIR. A self red-proof plants `drizzler` in a copy of the map and must see it caught.
const TABLE := {"drillmaster": "Karvok", "scrapwright": "Ironhyde", "gaoler": "Shacklemaw", "snuffer": "Duskhollow",
	"sexton": "Gravrik", "porter": "Drudgewall", "tallyman": "Velmok", "cook": "Blisterhand", "sluicekeeper": "Rothenwell",
	"sower": "Thorncast", "snarer": "Griplash", "stoker": "Cindrak", "bellman": "Tolburn", "boiler": "Scaldmere",
	"jointer": "Halvrek", "quartermaster": "Wardgrim", "loader": "Millstone", "hurdleman": "Bramblejaw", "tanner": "Flenscar",
	"reeve": "Lockwarden", "tapster": "Dregsallow", "pressman": "Crushwright", "strickler": "Murkspit", "dyer": "Venomshade",
	"greener": "Corrodan", "moulder": "Ashform", "ratcatcher": "Skivven", "drover": "Yokebane", "paviser": "Shieldmaw",
	"fenman": "Bogwarden", "comfitmaker": "Brindle", "leech": "Gulworth", "beadle": "Ordrik", "rammer": "Breachar",
	"fuller": "Wrynn", "stackman": "Huskpile",
	"dauber": "Wetwall",   # S65: the 37th, content's C-142 name
	"sealer": "Leadbite",   # S66: the 38th, content's C-143 name
	"hooper": "Hoopfast",   # S67: the 39th, content's C-144 name
	"relief": "Watchturn",   # S68: the 40th, content's C-145 name
	"scraper": "Scourstone",   # S70: the 41st, content's C-147 name
	"ferryman": "Slackwater"}   # S72: the 42nd, content's C-149 name
var _fails := 0
var _checks := 0
func _ok(c: bool, what: String) -> void:
	_checks += 1
	if not c:
		_fails += 1
		print("FAIL " + what)
func _live_keys() -> Dictionary:
	var feed := {}
	var mf: Dictionary = Delve.lore().get("miniboss_feed", {})
	for k: String in mf.get("by_key", {}):
		feed[k] = true
	var fit := {}
	for k: String in Delve.MB_FIT:
		fit[k.trim_suffix("_chibi")] = true
	var glb := {}
	for f: String in DirAccess.get_files_at(Delve.MB_DIR):
		if f.ends_with(".glb"):
			glb[f.get_basename().trim_suffix("_chibi")] = true
	return {"feed": feed, "fit": fit, "glb": glb}

## every MB_NAME key must be a live key in all three sources; every key that has BOTH feed lines
## and a body (i.e. can reach a floor) must carry a name. Returns the faults as text.
func _keyset_faults(names: Dictionary, live: Dictionary) -> Array:
	var out := []
	for k: String in names:
		for src: String in ["feed", "fit", "glb"]:
			if not (live[src] as Dictionary).has(k):
				out.append("MB_NAME key %s is not in %s" % [k, src])
	for k: String in live["feed"]:
		if (live["glb"] as Dictionary).has(k) and not names.has(k):
			out.append("drawable key %s has no MB_NAME entry" % k)
	return out

func _initialize() -> void:
	_ok(TABLE.size() == 42, "directive table is 42 (36 + S65 dauber + S66 sealer + S67 hooper + S68 relief + S70 scraper + S72 ferryman)")
	# S93: 45 = the 42-row directive table + S75 winder + S76 pitman + S89 tither (+ S94 blower = 46). This line read 42 since S72 and went
	# red at S75 with nobody re-reading it; the key-SET check below is the real guard, this is the count beside it.
	# S99: + changer (Evenhand, 47th, C-174) = 47. S102: + roper (Drawtight, 49th body, C-177) = 48. S103: + stopper (Chokewell, 48th body, C-176, .glb on main 41f71825) = 49. S107: + almoner (Dolehand, 50th body, C-182, .import committed) = 50.
	# S113: + panner (Onceround, S111) + stiltman (Downfast, S112) = 52 - S111 and S112 never moved this count, so this arm was red on main for two cycles; + nightman (Nightwork, 53rd, C-190) = 53. S116: + iceman (Hoarback, 54th, C-193) = 54. S118: + straker (Everyhand, 55th, C-195) = 55. S121: + weigher (Trueweight, 56th, C-198) = 56. S122: + dredger (Finepass, 57th, C-199) = 57. S123: + harrowman (Overturn, 58th, C-200) = 58. S124: + pledgeman (Heldfast, 59th, C-201) = 59.
	_ok(Delve.MB_NAME.size() == 62, "MB_NAME is 62 (got %d)" % Delve.MB_NAME.size())
	var seen := {}
	var bodies := 0
	var fed := 0
	for k: String in TABLE:
		var nm := Delve.miniboss_name(k)
		_ok(nm == String(TABLE[k]), "%s -> %s (want %s)" % [k, nm, TABLE[k]])
		_ok(not nm.begins_with("The "), "%s carries no The" % nm)
		_ok(not nm.to_lower().contains(k), "%s carries no trade word %s" % [nm, k])
		_ok(not seen.has(nm), "%s unique" % nm)
		seen[nm] = true
		if Delve.miniboss_model(k) != "":
			bodies += 1
		if not Delve.miniboss_lines(k, "arrive").is_empty():
			fed += 1
	_ok(Delve.miniboss_name("nosuchtrade") == "Nosuchtrade", "an unnamed key falls back to its capitalised word")
	_ok(Delve.miniboss_name("strickler") == "Murkspit", "strickler (directive row 23) is Murkspit")
	# ---- S52 key-set: MB_NAME's keys against what actually draws
	var live := _live_keys()
	print("S52 live key sources: by_key %d, MB_FIT base %d, glb stems %d" % [live["feed"].size(), live["fit"].size(), live["glb"].size()])
	var miss := _keyset_faults(Delve.MB_NAME, live)
	for f: String in miss:
		_ok(false, f)
	_ok(miss.is_empty(), "MB_NAME key set matches the live keys")
	# self red-proof: the exact S51 fault must be caught by the same function
	var bad: Dictionary = Delve.MB_NAME.duplicate()
	bad.erase("strickler")
	bad["drizzler"] = "Murkspit"
	var caught := _keyset_faults(bad, live)
	print("S52 red-proof (drizzler planted): %d faults: %s" % [caught.size(), ", ".join(caught)])
	_ok(caught.size() >= 2, "red-proof catches the planted drizzler both ways")
	print("S51 bodies on disk resolving by trade key: %d ; keys with arrive lines: %d" % [bodies, fed])
	_ok(bodies >= 35, "bodies still resolve (%d)" % bodies)
	_ok(fed >= 30, "feed still reads by trade key (%d)" % fed)
	if _fails == 0:
		print("S51_NAMES OK %d checks" % _checks)
	else:
		print("S51_NAMES FAIL %d of %d" % [_fails, _checks])
	quit(0 if _fails == 0 else 1)
