extends SceneTree
## S33_DRAW - every art miniboss body is in its theme's draw. Headless:
## <console> --headless --path . --script tools/_s33_draw.gd
## For every key in DungeonHD.THEME_MINIBOSS_MORE:
##   - its theme is ART'S OWN TAG (field 5 of the tuple in tools/art/minibosses.py), read here;
##   - Delve.miniboss_model answers a loadable body;
##   - Delve.MB_FIT carries art's measured ratio (pairs.<key>.ratio in _fit_report.json or the
##     key's _fit_<key>_register.json), equal to 0.005;
##   - with arrive lines it is DRAWN on at least one of floors 1..400; without lines it is drawn on NONE.
## Also: every art body on disk (non-_chibi, non-_tall, not a Bestiary key) is in THEME_MINIBOSS or THEME_MINIBOSS_MORE.
## S91: CANON titles no longer all begin "The " (tither = "Tenthpart"), so the tag regex takes any title.
## S33_RED=1 injects a key with no body and no ratio - the gate must print FAIL.
## Prints S33_DRAW OK <n> checks | S33_DRAW FAIL ...
var _fails: Array = []
var _checks := 0

func _ok(c: bool, what: String) -> void:
	_checks += 1
	if not c:
		print("  FAIL ", what)
		_fails.append(what)

func _json(p: String) -> Dictionary:
	if not FileAccess.file_exists(p):
		return {}
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
	return v if v is Dictionary else {}

func _art_ratio(key: String) -> float:
	for p: String in ["res://renders/art/minibosses/_fit_%s_register.json" % key, "res://renders/art/minibosses/_fit_report.json"]:
		var d := _json(p)
		var pr: Dictionary = d.get("pairs", {})
		if pr.has(key):
			return float((pr[key] as Dictionary).get("ratio", -1.0))
	return -1.0

func _init() -> void:
	var src := FileAccess.get_file_as_string("res://tools/art/minibosses.py")
	_ok(src.length() > 1000, "tools/art/minibosses.py read (%d chars)" % src.length())
	var re := RegEx.new()
	re.compile("(?m)^\\s+\"([a-z_]+)\":\\s*\\(\"[^\"]+\",\\s*[0-9.]+,\\s*\\([^)]*\\),\\s*\\([^)]*\\),\\s*\"([a-z]+)\"")
	var tag := {}
	for m in re.search_all(src):
		tag[m.get_string(1)] = m.get_string(2)
	_ok(tag.size() >= 30, "art theme tags parsed (%d)" % tag.size())
	var more: Dictionary = DungeonHD.THEME_MINIBOSS_MORE.duplicate(true)
	if OS.get_environment("S33_RED") == "1":
		more["crypt"] = (more.get("crypt", []) as Array) + ["nobody_redproof"]
		print("  S33_RED: injected nobody_redproof into crypt")
	var drawn := 0
	var held := 0
	for theme: String in more:
		_ok(DungeonHD.THEME_MINIBOSS.has(theme), "theme %s has a base key" % theme)
		for k in more[theme]:
			var key := String(k)
			_ok(String(tag.get(key, "")) == theme, "%s: art tags it %s, table says %s" % [key, tag.get(key, "?"), theme])
			_ok(Delve.miniboss_model(key) != "", "%s: loadable body" % key)
			var want := _art_ratio(key)
			var have := float(Delve.MB_FIT.get(key, -9.0))
			_ok(want > 0.0 and absf(want - have) <= 0.005, "%s: MB_FIT %.2f vs art %.2f" % [key, have, want])
			var has_lines := not Delve.miniboss_lines(key, "arrive").is_empty()
			var hits := 0
			for n in range(1, 401):
				# the live function reads the live table; for injected keys the gate above already fails
				if DungeonHD.miniboss_for(theme, n) == key:
					hits += 1
			if has_lines:
				_ok(hits > 0, "%s: has lines and is drawn (%d of 400 %s floors)" % [key, hits, theme])
				drawn += 1
			else:
				_ok(hits == 0, "%s: no arrive lines and never drawn (%d)" % [key, hits])
				held += 1
			print("  %-14s %-10s ratio %.2f lines %s drawn %d/400" % [key, theme, have, has_lines, hits])
	# every body on disk is in some draw
	var listed := {}
	for t in DungeonHD.THEME_MINIBOSS:
		listed[String(DungeonHD.THEME_MINIBOSS[t])] = true
	for t in more:
		for k in more[t]:
			listed[String(k)] = true
	var d := DirAccess.open("res://assets/monsters/minibosses/")
	var bodies := 0
	if d:
		for f in d.get_files():
			if not f.ends_with(".glb"):
				continue
			var b := f.get_basename()
			if b.ends_with("_chibi") or b.ends_with("_tall"):
				continue
			# S91: a bestiary pack-variant body (S54 broodglut, lastcuff) lives in this folder but is
			# placed by Bestiary (homes [], called by name), not by the theme draw - exempt it here.
			if not listed.has(b) and Bestiary.all_keys().has(b):
				print("  bestiary body %s: placed by Bestiary, not a theme draw" % b)
				continue
			bodies += 1
			_ok(listed.has(b), "body %s is in a draw" % b)
	_ok(bodies >= 30, "bodies on disk counted (%d)" % bodies)
	print("  bodies %d, drawn-with-lines %d, held-for-lines %d" % [bodies, drawn, held])
	if _fails.is_empty() and _checks > 0:
		print("S33_DRAW OK %d checks" % _checks)
	else:
		print("S33_DRAW FAIL %d of %d: %s" % [_fails.size(), _checks, _fails])
	quit(0 if _fails.is_empty() else 1)
