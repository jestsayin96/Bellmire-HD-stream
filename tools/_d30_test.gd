extends SceneTree
## D30 TEST (town side of the census's spell-legibility finding). The census
## proved nine distinct spells already fire - the gap is that a viewer cannot
## TELL them apart and the town never NAMED them (L52 did that for the dungeon).
## This checks the two halves of the fix, both in desktop-owned files:
##   A. every spell has a word and a colour, and no two words collide;
##   B. the thrown spells wear DISTINCT in-flight forms (bolt/chain/fire were one
##      round orb before; frost already flew as a shard) - checked by building
##      the real projectile and reading its core mesh, not by eye;
##   C. name_over floats a correctly-worded, correctly-coloured billboard;
##   D. every spell still actually casts without error.
## Headless: meshes and strings are asserted, not looked at. Prints D30_TEST OK/FAIL.
var _caster: Node3D
var _target: Node3D
var _f := 0
var _checks := 0
var _fails: Array = []

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _body(name_s: String, h: float) -> Node3D:
	var n := Node3D.new()
	n.name = name_s
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.5, h, 0.3)
	mi.mesh = bm
	n.add_child(mi)
	mi.position = Vector3(0, h * 0.5, 0)
	return n

func _find_label(n: Node, text_s: String):
	if n is Label3D and String((n as Label3D).text) == text_s:
		return n
	for c in n.get_children():
		var r = _find_label(c, text_s)
		if r != null:
			return r
	return null

func _initialize() -> void:
	_caster = _body("caster", 1.8)
	root.add_child(_caster)
	_caster.global_position = Vector3(0, 0, 0)
	_target = _body("target", 1.7)
	root.add_child(_target)
	_target.global_position = Vector3(5, 0, 0)
	print("D30_TEST start")

func _process(_dt: float) -> bool:
	_f += 1
	if _f < 2:
		return false
	# ---- A. words and colours for all nine, no duplicate words
	var missing_word: Array = []
	var missing_col: Array = []
	var seen := {}
	var dupes: Array = []
	for k in Spells.ORDER:
		if not Spells.WORD.has(k):
			missing_word.append(k)
		else:
			var w := String(Spells.WORD[k])
			if seen.has(w):
				dupes.append(w)
			seen[w] = true
		if not Spells.COL.has(k):
			missing_col.append(k)
	_ok(missing_word.is_empty(), "A: every spell has a town word (missing: %s)" % str(missing_word))
	_ok(missing_col.is_empty(), "A: every spell has a colour (missing: %s)" % str(missing_col))
	_ok(dupes.is_empty(), "A: no two spells share a word - they must be tellable apart (%s)" % str(dupes))
	# ---- B. distinct in-flight forms for the four thrown spells
	var forms := {}
	for k in ["bolt", "chain", "fire", "frost"]:
		forms[Spells.thrown_form(k)] = true
	print("D30 thrown forms: bolt=%s chain=%s fire=%s frost=%s"
		% [Spells.thrown_form("bolt"), Spells.thrown_form("chain"), Spells.thrown_form("fire"), Spells.thrown_form("frost")])
	_ok(forms.size() == 4, "B: the four thrown spells each fly as a DIFFERENT form (%d distinct)" % forms.size())
	_ok(Spells.thrown_form("bolt") != "orb", "B: bolt is no longer the plain round orb")
	# ---- B2. the form actually changes the projectile's core mesh (built, not guessed)
	var lance := Spells._orb(root, Vector3.ZERO, Color.RED, 0.22, "lance")
	var plain := Spells._orb(root, Vector3.ZERO, Color.RED, 0.22, "orb")
	_ok(lance.get_child(0) is MeshInstance3D and (lance.get_child(0) as MeshInstance3D).mesh is BoxMesh,
		"B: a lance builds a shaft (BoxMesh) core")
	_ok(plain.get_child(0) is MeshInstance3D and (plain.get_child(0) as MeshInstance3D).mesh is SphereMesh,
		"B: a plain orb still builds a round (SphereMesh) core")
	lance.queue_free()
	plain.queue_free()
	# ---- C. name_over floats the right word in the right colour
	Spells.name_over(_caster, "frost")
	var lbl = _find_label(root, "Frost")
	_ok(lbl != null, "C: casting Frost floats a 'Frost' label over the caster")
	if lbl != null:
		var col: Color = Spells.COL["frost"]
		var m: Color = (lbl as Label3D).modulate
		_ok(absf(m.r - col.r) < 0.02 and absf(m.g - col.g) < 0.02 and absf(m.b - col.b) < 0.02,
			"C: the label wears the spell's own colour")
	# ---- D. every spell still casts without error, and is counted
	Spells.cast_counts.clear()
	var cast_ok := true
	for k in Spells.ORDER:
		var got := Spells.cast(k, _caster, _target)
		if got == "":
			cast_ok = false
	_ok(cast_ok, "D: every spell returns a cast")
	_ok(Spells.cast_counts.size() == Spells.ORDER.size(),
		"D: all %d spells fired and were counted (%d)" % [Spells.ORDER.size(), Spells.cast_counts.size()])
	print("CHECKS ", _checks, " FAILS ", _fails.size())
	for f in _fails:
		print("  - ", f)
	print("D30_TEST ", "OK" if _fails.is_empty() else "FAIL")
	return true
