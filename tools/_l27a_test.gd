extends SceneTree
## L27a (headless): the widened roster's wiring, before the live soak.
##   godot --headless --path . --script tools/_l27a_test.gd
## For each new creature: its def resolves, its body file and weapon files exist,
## a strain applies its stat mods, and it sits in the right depth bands (fodder in
## none). Prints L27A_TEST OK / FAIL. The live "appear at depth + animate" check is
## tools/_l26_anims.gd with L26_FLOORS=7,9,11.
const NEW := ["hewer", "cutthroat", "silkmother", "spiderling", "scarrat", "lurker", "pitwyrm", "ashwight", "gloombat"]
const FODDER := ["spiderling", "slimeling"]
var _fail := 0

func _ok(c: bool, what: String) -> void:
	print(("  ok  " if c else "  FAIL ") + what)
	if not c:
		_fail += 1

func _initialize() -> void:
	for k in NEW:
		var d := Bestiary.def_of(k)
		_ok(not d.is_empty() and d.has("name") and d.has("anims") and d.has("h"), "%s: def resolves (name/anims/height)" % k)
		_ok(ResourceLoader.exists(String(d.get("path", ""))), "%s: body file exists (%s)" % [k, String(d.get("path", "")).get_file()])
		for slot in ["hand", "off"]:
			var p := String(d.get(slot, ""))
			if p != "":
				_ok(ResourceLoader.exists(p), "%s: %s weapon exists (%s)" % [k, slot, p.get_file()])
		var plain := Bestiary.make(k, "plain")
		var ember := Bestiary.make(k, "emberbound")
		_ok(absf(float(ember["hp"]) - float(plain["hp"]) * 0.90) < 0.001, "%s: a strain's hp mod applies (%.2f -> %.2f)" % [k, plain["hp"], ember["hp"]])
		_ok(absf(float(ember["atk"]) - float(plain["atk"]) * 1.40) < 0.001, "%s: a strain's atk mod applies" % k)
	# the bands: each new creature haunts its depth; fodder is summoned, never rolled
	for pair in [["hewer", 6], ["scarrat", 6], ["lurker", 7], ["cutthroat", 8], ["ashwight", 9], ["gloombat", 8], ["silkmother", 9], ["pitwyrm", 10], ["hewer", 12], ["silkmother", 15]]:
		_ok(Bestiary.pool(int(pair[1])).has(String(pair[0])), "%s haunts floor %d" % [pair[0], pair[1]])
	for f in [1, 3, 5, 6, 8, 10]:
		for k in FODDER:
			_ok(not Bestiary.pool(f).has(k), "%s is never rolled on floor %d (summon/split fodder only)" % [k, f])
	# shallow floors stay innocent of the deep roster
	for k in ["pitwyrm", "silkmother", "ashwight", "cutthroat"]:
		_ok(not Bestiary.pool(2).has(k) and not Bestiary.pool(4).has(k), "%s stays out of the shallows" % k)
	print("L27A_TEST OK" if _fail == 0 else "L27A_TEST FAIL %d" % _fail)
	quit()
