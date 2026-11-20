extends SceneTree
## S51: Mr. E's miniboss rename (supervisor doc sup-nov19-2150). Every one of the 36 trade keys
## in the directive's table maps to its new name; the names are unique, carry no "The" and no
## trade word; every body on disk still resolves and every key with feed lines still reads them
## (the key did not move). Prints S51_NAMES OK <n> / S51_NAMES FAIL <n>.
const TABLE := {"drillmaster": "Karvok", "scrapwright": "Ironhyde", "gaoler": "Shacklemaw", "snuffer": "Duskhollow",
	"sexton": "Gravrik", "porter": "Drudgewall", "tallyman": "Velmok", "cook": "Blisterhand", "sluicekeeper": "Rothenwell",
	"sower": "Thorncast", "snarer": "Griplash", "stoker": "Cindrak", "bellman": "Tolburn", "boiler": "Scaldmere",
	"jointer": "Halvrek", "quartermaster": "Wardgrim", "loader": "Millstone", "hurdleman": "Bramblejaw", "tanner": "Flenscar",
	"reeve": "Lockwarden", "tapster": "Dregsallow", "pressman": "Crushwright", "drizzler": "Murkspit", "dyer": "Venomshade",
	"greener": "Corrodan", "moulder": "Ashform", "ratcatcher": "Skivven", "drover": "Yokebane", "paviser": "Shieldmaw",
	"fenman": "Bogwarden", "comfitmaker": "Brindle", "leech": "Gulworth", "beadle": "Ordrik", "rammer": "Breachar",
	"fuller": "Wrynn", "stackman": "Huskpile"}
var _fails := 0
var _checks := 0
func _ok(c: bool, what: String) -> void:
	_checks += 1
	if not c:
		_fails += 1
		print("FAIL " + what)
func _initialize() -> void:
	_ok(TABLE.size() == 36, "directive table is 36")
	_ok(Delve.MB_NAME.size() == 36, "MB_NAME is 36 (got %d)" % Delve.MB_NAME.size())
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
	_ok(Delve.miniboss_name("strickler") == "Strickler", "an unnamed key falls back to its capitalised word")
	print("S51 bodies on disk resolving by trade key: %d ; keys with arrive lines: %d" % [bodies, fed])
	_ok(bodies >= 35, "bodies still resolve (%d)" % bodies)
	_ok(fed >= 30, "feed still reads by trade key (%d)" % fed)
	if _fails == 0:
		print("S51_NAMES OK %d checks" % _checks)
	else:
		print("S51_NAMES FAIL %d of %d" % [_fails, _checks])
	quit(0 if _fails == 0 else 1)
