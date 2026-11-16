extends SceneTree
## L27b (headless): strains.json is the live authority, every named strain has
## a clear tell, stat mods apply via Bestiary.make, the widened deep bands roll
## the new strains, and the shallows are unchanged.
##   godot --headless --path . --script tools/_l27b_test.gd
## Prints L27B_TEST OK / FAIL. The visual tell is judged from tools/_l27b_shot.gd.
const NEW := ["duskforged", "sporeblown", "veilstruck"]
var _fail := 0

func _ok(c: bool, what: String) -> void:
	print(("  ok  " if c else "  FAIL ") + what)
	if not c:
		_fail += 1

func _initialize() -> void:
	# 1) the json is the authority
	_ok(Bestiary.strains_from_json, "STRAINS loaded from data/strains.json (not the fallback)")
	var f := FileAccess.open("res://data/strains.json", FileAccess.READ)
	var parsed: Dictionary = JSON.parse_string(f.get_as_text())
	var json_ids := {}
	for e in (parsed["strains"] as Array):
		json_ids[String((e as Dictionary)["id"])] = e
	_ok(Bestiary.STRAINS.size() == json_ids.size(), "table size matches the json (%d)" % json_ids.size())
	for id in json_ids:
		_ok(Bestiary.STRAINS.has(id), "json strain '%s' is in the live table" % id)
	# a json number is the live number (authority, not a copy of the const)
	var jd: Dictionary = json_ids.get("duskforged", {})
	var ld: Dictionary = Bestiary.STRAINS.get("duskforged", {})
	_ok(not ld.is_empty() and absf(float(ld.get("hp", 0.0)) - float(jd.get("hp", -1.0))) < 0.001, "duskforged hp comes from the json (%.2f)" % float(ld.get("hp", 0.0)))
	# 2) numbers of every pre-L27b strain UNCHANGED (frozen - measured 83% vs 63%)
	var FROZEN := {
		"plain": [1.00, 1.00, 1.00, 1.00], "hollowed": [0.75, 0.95, 1.10, 0.92],
		"drowned": [1.35, 0.90, 0.80, 1.05], "emberbound": [0.90, 1.40, 1.15, 1.00],
		"gorged": [1.60, 1.10, 0.75, 1.35], "wraithtouched": [0.85, 1.25, 1.30, 0.98],
		"scarborn": [0.95, 1.20, 1.10, 1.02], "mossbacked": [1.30, 0.95, 0.85, 1.08],
	}
	for id in FROZEN:
		var st: Dictionary = Bestiary.STRAINS.get(id, {})
		var want: Array = FROZEN[id]
		var same := not st.is_empty() \
			and absf(float(st["hp"]) - float(want[0])) < 0.001 and absf(float(st["atk"]) - float(want[1])) < 0.001 \
			and absf(float(st["spd"]) - float(want[2])) < 0.001 and absf(float(st["scale"]) - float(want[3])) < 0.001
		_ok(same, "%s numbers frozen (hp/atk/spd/scale unchanged)" % id)
	# 3) every NAMED strain has a clear tell: glow, particle, or scale != 1
	for id in Bestiary.STRAINS:
		if id == "plain":
			continue
		var st: Dictionary = Bestiary.STRAINS[id]
		var tell := (st.get("glow", Color(0, 0, 0)) as Color) != Color(0, 0, 0) \
			or String(st.get("particle", "")) != "" or absf(float(st["scale"]) - 1.0) > 0.01
		_ok(tell, "%s has a tell (glow/particle/scale)" % id)
	# wild stays scarborn's (monster.gd _tick_wild)
	_ok(bool((Bestiary.STRAINS["scarborn"] as Dictionary).get("wild", false)), "scarborn keeps its wandering hue")
	# 4) stat mods + particle apply through Bestiary.make
	for id in NEW:
		var plain := Bestiary.make("warrior", "plain")
		var got := Bestiary.make("warrior", id)
		var st: Dictionary = Bestiary.STRAINS[id]
		_ok(absf(float(got["hp"]) - float(plain["hp"]) * float(st["hp"])) < 0.001, "%s hp mod applies via make" % id)
		_ok(absf(float(got["atk"]) - float(plain["atk"]) * float(st["atk"])) < 0.001, "%s atk mod applies" % id)
		_ok(absf(float(got["spd"]) - float(plain["spd"]) * float(st["spd"])) < 0.001, "%s spd mod applies" % id)
		_ok(absf(float(got["h"]) - float(plain["h"]) * float(st["scale"])) < 0.001, "%s scale applies to height" % id)
		_ok(String(got.get("particle", "")) == String(st.get("particle", "")), "%s particle tell rides the def" % id)
		_ok(String(got["name"]).begins_with(String(st["label"]) + " "), "%s names the creature" % id)
	# 5) the widened bands roll the new strains at depth; shallows unchanged
	var seen_mid := {}
	var seen_deep := {}
	var seen_shallow := {}
	var seen_low := {}
	for i in range(4000):
		seen_mid[Bestiary.strain_for(8)] = true
		seen_deep[Bestiary.strain_for(12)] = true
		seen_shallow[Bestiary.strain_for(1)] = true
		seen_low[Bestiary.strain_for(4)] = true
	for id in ["duskforged", "sporeblown"]:
		_ok(seen_mid.has(id), "%s rolls on floors 6-9" % id)
		_ok(seen_deep.has(id), "%s rolls on 10+" % id)
	_ok(seen_deep.has("veilstruck"), "veilstruck rolls on 10+")
	_ok(not seen_mid.has("veilstruck"), "veilstruck stays below floor 9")
	_ok(seen_mid.has("plain") and seen_deep.has("plain"), "plain still rolls at depth (30/15 share kept)")
	var sh_ok := true
	for id in seen_shallow:
		if id != "plain" and id != "hollowed":
			sh_ok = false
	_ok(sh_ok, "floors 1-2 unchanged (plain/hollowed only: %s)" % str(seen_shallow.keys()))
	var low_ok := true
	for id in seen_low:
		if not (id in ["plain", "hollowed", "drowned"]):
			low_ok = false
	_ok(low_ok, "floors 3-5 unchanged (plain/hollowed/drowned: %s)" % str(seen_low.keys()))
	print("L27B_TEST OK" if _fail == 0 else "L27B_TEST FAIL %d" % _fail)
	quit()
