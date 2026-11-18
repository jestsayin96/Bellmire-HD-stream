extends SceneTree
## Guard for the third rarity table (TAKE THIS NEXT 18 Nov 07:04 row 1). Reads art's canonical
## RARITY_HUE straight out of tools/art/icons.py, derives the +0.10 lamp, and checks
## Fishing.RARITY_COLOR against it rung by rung. Then proves it would go red on the three
## shapes of drift that were actually shipped (green uncommon, painted common, blue boot).
## Prints FISH_RARITY OK (n checks) or FISH_RARITY FAIL. No verdict line = red.
const FLOOR := 20
var checks := 0
var fails: Array = []

func _ok(c: bool, what: String) -> void:
	checks += 1
	if not c:
		fails.append(what)

func _canon() -> Dictionary:
	var f := FileAccess.open("res://tools/art/icons.py", FileAccess.READ)
	if f == null:
		return {}
	var out := {}
	var on := false
	for line in f.get_as_text().split("\n"):
		if line.begins_with("RARITY_HUE = {"):
			on = true
			continue
		if on and line.begins_with("}"):
			break
		if on:
			var re := RegEx.new()
			re.compile("\"([a-z ]+)\":\\s*(None|\\(([0-9.]+),\\s*([0-9.]+),\\s*([0-9.]+)\\))")
			var m := re.search(line)
			if m:
				out[m.get_string(1)] = null if m.get_string(2) == "None" else Color(float(m.get_string(3)), float(m.get_string(4)), float(m.get_string(5)))
	return out

func _lamp(c: Color) -> Color:
	return Color(minf(c.r + 0.10, 1.0), minf(c.g + 0.10, 1.0), minf(c.b + 0.10, 1.0))

## returns the list of faults for a candidate table against canon; [] = clean
func _audit(table: Dictionary, canon: Dictionary) -> Array:
	var bad := []
	for k in canon:
		if canon[k] == null:
			if table.has(k):
				bad.append("%s is bare in canon but painted here" % k)
		elif k != "artifact":
			if not table.has(k):
				bad.append("%s missing" % k)
			elif not (table[k] as Color).is_equal_approx(_lamp(canon[k])):
				bad.append("%s %s != lamp %s" % [k, table[k], _lamp(canon[k])])
	for k in table:
		if not canon.has(k):
			bad.append("%s is not a canonical rung" % k)
	return bad

func _initialize() -> void:
	var canon := _canon()
	_ok(canon.size() >= 8, "icons.py RARITY_HUE read (%d rungs)" % canon.size())
	var a := _audit(Fishing.RARITY_COLOR, canon)
	_ok(a.is_empty(), "live table: %s" % [a])
	for k in ["common", "junk", "starting"]:
		_ok(not Fishing.RARITY_COLOR.has(k), "%s must be bare" % k)
	# every row in the data, through the real reader
	var rows: Array = Fishing.table().get("items", [])
	_ok(rows.size() > 0, "fishing.json items read")
	var junk_seen := 0
	for r in rows:
		var it: Dictionary = r
		var rar := String(it.get("rarity", "common"))
		if String(it.get("cat", "")) == "junk":
			junk_seen += 1
			_ok(not Fishing.has_hue(it) and Fishing.colour(it) == Fishing.BARE, "junk %s (%s) must be bare" % [it.get("id"), rar])
		elif rar == "common":
			_ok(not Fishing.has_hue(it), "common %s must be bare" % it.get("id"))
		else:
			_ok(Fishing.colour(it).is_equal_approx(_lamp(canon[rar])), "%s %s colour" % [it.get("id"), rar])
	_ok(junk_seen >= 7, "junk rows seen %d" % junk_seen)
	# a scar-touched common fish bumps to uncommon and must glow WHITE, not green
	_ok(Fishing.colour({"cat": "fish", "rarity": "uncommon"}).is_equal_approx(Color(1, 1, 1)), "scar uncommon is white")
	# RED PROOFS: each shipped drift must be caught by _audit
	var t1: Dictionary = Fishing.RARITY_COLOR.duplicate(); t1["uncommon"] = Color(0.45, 0.95, 0.45)
	_ok(not _audit(t1, canon).is_empty(), "red proof: green uncommon not caught")
	var t2: Dictionary = Fishing.RARITY_COLOR.duplicate(); t2["common"] = Color(0.92, 0.92, 0.90)
	_ok(not _audit(t2, canon).is_empty(), "red proof: painted common not caught")
	var t3: Dictionary = Fishing.RARITY_COLOR.duplicate(); t3["legendary"] = Color(1.00, 0.66, 0.20)
	_ok(not _audit(t3, canon).is_empty(), "red proof: off-lamp legendary not caught")
	if fails.is_empty() and checks >= FLOOR:
		print("FISH_RARITY OK (%d checks, floor %d, 3/3 red proofs caught)" % [checks, FLOOR])
	else:
		print("FISH_RARITY FAIL (%d checks, floor %d): %s" % [checks, FLOOR, fails])
	quit()
