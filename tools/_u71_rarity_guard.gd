extends SceneTree
## U71 - ONE-TABLE GUARD for the rarity hue ladder. HEADLESS is fine: no UI is drawn.
## SOURCE OF TRUTH is art's tools/art/icons.py RARITY_HUE (+ RARITY_HUE_PARCHMENT["uncommon"]).
## UiTheme.RARITY_HUE must equal it digit-for-digit on rare / very rare / legendary / artifact,
## junk / starting / common must stay BARE on both sides, uncommon must be art's sanctioned
## parchment value (not a re-choice), and the ink ladder must not grow a rung the hue ladder lacks.
## U74b (18 Nov, TAKE THIS NEXT 07:04 row 3) adds the THIRD table: scripts/fishing.gd RARITY_COLOR.
## Art ruled it a SANCTIONED LAMP VARIANT: rare / very rare / legendary = canonical +0.10 per channel
## (clamped), uncommon = white (the ladder's claim, not the MMO green), common / junk / starting BARE.
## Run: <console> --headless --path W2 --script res://tools/_u71_rarity_guard.gd
const PY := "res://tools/art/icons.py"
const CANON4 := ["rare", "very rare", "legendary", "artifact"]
const BARE := ["junk", "starting", "common"]
const FISH_GD := "res://scripts/fishing.gd"
const LAMP_RUNGS := ["rare", "very rare", "legendary"]

## the RARITY_HUE block of icons.py as {rung: Color or null}
static func parse_py(txt: String) -> Dictionary:
	var out := {}
	var a := txt.find("\nRARITY_HUE = {")
	if a < 0:
		return out
	var b := txt.find("\n}", a)
	var re := RegEx.new()
	re.compile("\"([a-z ]+)\":\\s*(None|\\(\\s*([0-9.]+),\\s*([0-9.]+),\\s*([0-9.]+)\\s*\\))")
	for m in re.search_all(txt.substr(a, b - a)):
		if m.get_string(2) == "None":
			out[m.get_string(1)] = null
		else:
			out[m.get_string(1)] = Color(float(m.get_string(3)), float(m.get_string(4)), float(m.get_string(5)))
	return out

static func parse_parch_uncommon(txt: String):
	var re := RegEx.new()
	re.compile("RARITY_HUE_PARCHMENT\\[\"uncommon\"\\]\\s*=\\s*\\(\\s*([0-9.]+),\\s*([0-9.]+),\\s*([0-9.]+)\\s*\\)")
	var m := re.search(txt)
	if m == null:
		return null
	return Color(float(m.get_string(1)), float(m.get_string(2)), float(m.get_string(3)))

static func same(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.0005 and absf(a.g - b.g) < 0.0005 and absf(a.b - b.b) < 0.0005

## every failure as a string; empty = the ladders agree
static func audit(ui_hue: Dictionary, ui_ink: Dictionary, py: Dictionary, parch) -> Array:
	var f := []
	if py.size() != 8:
		f.append("PY TABLE: read %d rungs from icons.py RARITY_HUE, expected 8 (parser or table changed)" % py.size())
	for r in CANON4:
		if not py.has(r) or py[r] == null:
			f.append("PY %s: art's table has no hue for a canonical rung" % r)
		elif not ui_hue.has(r):
			f.append("UI %s: UiTheme.RARITY_HUE lacks the rung art defines" % r)
		elif not same(ui_hue[r], py[r]):
			f.append("DRIFT %s: UiTheme %s vs art %s" % [r, ui_hue[r], py[r]])
	for r in BARE:
		if py.has(r) and py[r] != null:
			f.append("PY %s: art gave a bare rung a hue" % r)
		if ui_hue.has(r):
			f.append("UI %s: bare rung carries a hue in UiTheme (no hue is the claim)" % r)
	if parch == null:
		f.append("PARCHMENT: icons.py RARITY_HUE_PARCHMENT[\"uncommon\"] not found")
	elif not ui_hue.has("uncommon"):
		f.append("UI uncommon: missing")
	elif not same(ui_hue["uncommon"], parch):
		f.append("UNCOMMON: UiTheme %s is not art's parchment value %s" % [ui_hue["uncommon"], parch])
	for k in ui_hue.keys():
		if k != "uncommon" and not CANON4.has(k):
			f.append("UI %s: a rung art's ladder does not hue" % k)
	for k in ui_ink.keys():
		if not ui_hue.has(k):
			f.append("INK %s: ink rung with no hue rung" % k)
	return f

## the RARITY_COLOR block of fishing.gd as {rung: Color}
static func parse_fish(txt: String) -> Dictionary:
	var out := {}
	var a := txt.find("const RARITY_COLOR := {")
	if a < 0:
		return out
	var b := txt.find("}", a)
	var re := RegEx.new()
	re.compile("\"([a-z ]+)\":\\s*Color\\(\\s*([0-9.]+),\\s*([0-9.]+),\\s*([0-9.]+)\\s*\\)")
	for m in re.search_all(txt.substr(a, b - a)):
		out[m.get_string(1)] = Color(float(m.get_string(2)), float(m.get_string(3)), float(m.get_string(4)))
	return out

static func lamp(c: Color) -> Color:
	return Color(minf(c.r + 0.10, 1.0), minf(c.g + 0.10, 1.0), minf(c.b + 0.10, 1.0))

## the third table against art's canon: three lamp rungs, white uncommon, bare baseline
static func audit_fish(fish: Dictionary, py: Dictionary) -> Array:
	var f := []
	if fish.size() != 4:
		f.append("FISH TABLE: read %d rungs from fishing.gd RARITY_COLOR, expected 4 (parser or table changed)" % fish.size())
	for r in LAMP_RUNGS:
		if not py.has(r) or py[r] == null:
			f.append("FISH %s: art has no hue to lift" % r)
		elif not fish.has(r):
			f.append("FISH %s: fishing.gd lacks the lamp rung" % r)
		elif not same(fish[r], lamp(py[r])):
			f.append("FISH DRIFT %s: fishing %s vs art lamp %s" % [r, fish[r], lamp(py[r])])
	if not fish.has("uncommon"):
		f.append("FISH uncommon: missing")
	elif not same(fish["uncommon"], Color(1, 1, 1)):
		f.append("FISH UNCOMMON: %s is not the ladder's white (green is the MMO convention)" % fish["uncommon"])
	for r in BARE:
		if fish.has(r):
			f.append("FISH %s: bare rung carries a hue in fishing.gd (reads as the rung above it)" % r)
	for k in fish.keys():
		if k != "uncommon" and not LAMP_RUNGS.has(k):
			f.append("FISH %s: a rung the fishing ladder cannot reach or art does not lift" % k)
	return f

func _initialize() -> void:
	var ui = load("res://scripts/ui_theme.gd")
	var hue: Dictionary = ui.RARITY_HUE
	var ink: Dictionary = ui.RARITY_INK
	var fa := FileAccess.open(PY, FileAccess.READ)
	if fa == null:
		print("U71_GUARD FAIL cannot read ", PY)
		quit(1)
		return
	var txt := fa.get_as_text()
	var py := parse_py(txt)
	var parch = parse_parch_uncommon(txt)
	var real := audit(hue, ink, py, parch)
	for l in real:
		print("FAIL ", l)
	var ff := FileAccess.open(FISH_GD, FileAccess.READ)
	var ftxt := "" if ff == null else ff.get_as_text()
	var fish := parse_fish(ftxt)
	var real_fish := audit_fish(fish, py)
	for l in real_fish:
		print("FAIL ", l)
	var bad := real.size() + real_fish.size()
	## RED PROOFS: each mutation of the UI table MUST be caught; the clean table must not be.
	var muts := {
		"rare nudged": func(h, _i): h["rare"] = Color(0.30, 0.55, 0.99),
		"artifact lost": func(h, _i): h.erase("artifact"),
		"common painted": func(h, _i): h["common"] = Color(0.92, 0.92, 0.90),
		"uncommon re-chosen (white)": func(h, _i): h["uncommon"] = Color(1, 1, 1),
		"uncommon re-chosen (green)": func(h, _i): h["uncommon"] = Color(0.45, 0.95, 0.45),
		"junk painted": func(h, _i): h["junk"] = Color(0.5, 0.5, 0.5),
		"epic rung invented": func(h, _i): h["epic"] = Color(0.7, 0.35, 1.0),
		"ink without hue": func(h, _i): h.erase("rare"),
	}
	var proofs := 0
	for name in muts.keys():
		var h2: Dictionary = hue.duplicate(true)
		var i2: Dictionary = ink.duplicate(true)
		muts[name].call(h2, i2)
		var r2 := audit(h2, i2, py, parch)
		if r2.is_empty():
			print("FAIL REDPROOF '%s' was NOT caught" % name)
			bad += 1
		else:
			proofs += 1
	## and a parse-side mutation: art's table edited -> must be caught
	var edited := txt.replace("\"legendary\": (1.00, 0.55, 0.12)", "\"legendary\": (1.00, 0.60, 0.12)")
	if edited == txt:
		print("FAIL REDPROOF art-edit: legendary line not found to mutate")
		bad += 1
	elif audit(hue, ink, parse_py(edited), parch).is_empty():
		print("FAIL REDPROOF 'art edits legendary' NOT caught")
		bad += 1
	else:
		proofs += 1
	## THIRD-TABLE RED PROOFS: each shape of drift that shipped or could ship must be caught
	var fmuts := {
		"fish uncommon green (shipped)": func(h): h["uncommon"] = Color(0.45, 0.95, 0.45),
		"fish common painted (shipped)": func(h): h["common"] = Color(0.92, 0.92, 0.90),
		"fish junk painted": func(h): h["junk"] = Color(0.5, 0.5, 0.5),
		"fish legendary old (1.00,0.66,0.20)": func(h): h["legendary"] = Color(1.00, 0.66, 0.20),
		"fish rare nudged": func(h): h["rare"] = Color(0.40, 0.65, 0.99),
		"fish rare lost": func(h): h.erase("rare"),
		"fish uncommon lost": func(h): h.erase("uncommon"),
		"fish epic invented": func(h): h["epic"] = Color(0.8, 0.45, 1.0),
		"fish rare unlifted (canonical)": func(h): h["rare"] = Color(0.30, 0.55, 1.00),
	}
	var fproofs := 0
	for name in fmuts.keys():
		var h3: Dictionary = fish.duplicate(true)
		fmuts[name].call(h3)
		if audit_fish(h3, py).is_empty():
			print("FAIL REDPROOF '%s' was NOT caught" % name)
			bad += 1
		else:
			fproofs += 1
	## text-side: edit fishing.gd's own uncommon back to the old green -> parse must see it and fail
	var fedit := ftxt.replace("\"uncommon\": Color(1.00, 1.00, 1.00)", "\"uncommon\": Color(0.45, 0.95, 0.45)")
	if fedit == ftxt:
		print("FAIL REDPROOF fish text-edit: uncommon line not found to mutate")
		bad += 1
	elif audit_fish(parse_fish(fedit), py).is_empty():
		print("FAIL REDPROOF 'fishing.gd text reverted to green' NOT caught")
		bad += 1
	else:
		fproofs += 1
	## and art-side: art edits the lamp's source rung -> the lifted expectation moves, fishing must now fail
	var art2 := txt.replace("\"rare\":      (0.30, 0.55, 1.00)", "\"rare\":      (0.30, 0.50, 1.00)")
	if art2 == txt:
		print("FAIL REDPROOF art-edit rare: line not found to mutate")
		bad += 1
	elif audit_fish(fish, parse_py(art2)).is_empty():
		print("FAIL REDPROOF 'art edits rare, fishing silent' NOT caught")
		bad += 1
	else:
		fproofs += 1
	print("U71_FISH rungs_fish=", fish.size(), " redproofs_caught=", fproofs, "/", fmuts.size() + 2)
	print("U71_GUARD ", "OK" if bad == 0 else "FAIL", " rungs_py=", py.size(), " ui_rungs=", hue.size(), " redproofs_caught=", proofs, "/", muts.size() + 1, " fails=", bad)
	quit(0 if bad == 0 else 1)
