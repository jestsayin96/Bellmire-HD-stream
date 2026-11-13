extends SceneTree
## L45 (Mr. E's call): BOSSES SCALE WITH DEPTH. A lord met deep must be meaningfully harder than
## the same lord met shallow - hp, damage, mechanics, adds. Before this, boss_def() never saw the
## floor at all: only WHICH lord you met changed with depth, never how hard it hit.
## DONE in the plan is "a measured curve of boss difficulty by floor; a deep lord can wipe an
## unprepared party", so this prints the curve and then actually runs the wipe.
## Headless: this is bestiary/delve arithmetic, not HUD. Prints L45_TEST OK / FAIL.
##
## NOTE ON THE FLOORS USED HERE: the test walks lord-floors by STEP (the 1st, 2nd, 4th... lord
## floor), never asserting how many exist. No floor count is stated or implied - canon rule.
var _fails: Array = []
var _checks := 0

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _initialize() -> void:
	var r := Roster.new()
	root.add_child(r)

	# ---- 1. THE CURVE, measured on ONE fixed lord so only depth varies
	var b: Dictionary = (Bestiary.BOSS_DEFS["hollow_king"] as Dictionary).duplicate()
	b["id"] = "hollow_king"
	var rows: Array = []
	var floors := [5, 10, 20, 35, 50]
	for f in floors:
		var d := Bestiary.boss_def(b, f)
		rows.append({"floor": f, "step": int(d["depth_step"]),
					 "hp": float(d["boss_hp"]), "atk": float(d["boss_atk"])})
	print("L45 curve (the Hollow King, same lord, by depth):")
	for row in rows:
		print("   step %-2d  hp %7.1f  atk %6.2f" % [row["step"], row["hp"], row["atk"]])

	var shallow: Dictionary = rows[0]
	var deep: Dictionary = rows[rows.size() - 1]
	_ok(float(deep["hp"]) > float(shallow["hp"]) * 1.5,
		"the deep lord has meaningfully more hp (%.0f vs %.0f)" % [deep["hp"], shallow["hp"]])
	_ok(float(deep["atk"]) > float(shallow["atk"]) * 1.4,
		"the deep lord hits meaningfully harder (%.2f vs %.2f)" % [deep["atk"], shallow["atk"]])
	# monotonic: never easier the deeper you go
	var mono := true
	for i in range(1, rows.size()):
		if float(rows[i]["hp"]) < float(rows[i - 1]["hp"]) or float(rows[i]["atk"]) < float(rows[i - 1]["atk"]):
			mono = false
	_ok(mono, "the curve never dips - deeper is never easier")
	# the shallowest lord floor keeps the canon numbers, so nothing is retuned by accident
	_ok(is_equal_approx(float(shallow["hp"]), float(b["hp"])) and is_equal_approx(float(shallow["atk"]), float(b["atk"])),
		"the first lord floor is unchanged canon (hp %.0f atk %.2f)" % [shallow["hp"], shallow["atk"]])

	# ---- 2. MECHANICS scale too, not just the two numbers
	var sm: Dictionary = (Bestiary.BOSS_DEFS["ossuary_lord"] as Dictionary).duplicate()
	sm["id"] = "ossuary_lord"
	var w_near: Dictionary = Bestiary.boss_def(sm, 5)["ways"]
	var w_far: Dictionary = Bestiary.boss_def(sm, 50)["ways"]
	var near_most := int((w_near["summon"] as Dictionary)["most"])
	var far_most := int((w_far["summon"] as Dictionary)["most"])
	var near_every := float((w_near["summon"] as Dictionary)["every"])
	var far_every := float((w_far["summon"] as Dictionary)["every"])
	print("L45 mechanics: summon most %d -> %d, every %.1fs -> %.1fs, ward %.2f -> %.2f"
		% [near_most, far_most, near_every, far_every, float(w_near.get("ward", 0.0)), float(w_far.get("ward", 0.0))])
	_ok(far_most > near_most, "deeper: MORE adds crawl out of it (%d -> %d)" % [near_most, far_most])
	_ok(far_every < near_every, "deeper: they come FASTER (%.1fs -> %.1fs)" % [near_every, far_every])
	_ok(float(w_far.get("ward", 0.0)) > float(w_near.get("ward", 0.0)), "deeper: it shields harder")
	# the canon table itself must never be mutated - scale_ways works on a duplicate
	_ok(int(((Bestiary.LORD_WAYS["ossuary_lord"] as Dictionary)["summon"] as Dictionary)["most"]) == 2,
		"the canon LORD_WAYS table was not written to (still most=2)")

	# ---- 3. A DEEP LORD CAN WIPE AN UNPREPARED PARTY (the plan's own wording).
	# "Unprepared" = a fresh level-1 party with starting kit. Damage is applied the way delve
	# does it - boss_atk per landed blow - so this measures the real number, not a guess.
	var party_hp := 0.0
	for i in 4:
		var h: Dictionary = r.fresh("45%02d" % i, "Probe%d" % i, ["knight", "mage", "cleric", "barbarian"][i])
		party_hp += float(h.get("hp", 30))
	var deep_atk := float(Bestiary.boss_def(b, 50)["boss_atk"])
	var shallow_atk := float(Bestiary.boss_def(b, 5)["boss_atk"])
	# blows to chew through the whole unprepared party, ignoring armour and healing
	var deep_blows := party_hp / maxf(0.01, deep_atk)
	var shallow_blows := party_hp / maxf(0.01, shallow_atk)
	print("L45 wipe: unprepared party has %.0f hp total; deep lord needs %.1f landed blows, shallow %.1f"
		% [party_hp, deep_blows, shallow_blows])
	_ok(deep_blows < shallow_blows * 0.75,
		"a deep lord kills an unprepared party far quicker than a shallow one (%.1f vs %.1f blows)"
		% [deep_blows, shallow_blows])
	_ok(deep_blows < 30.0, "a deep lord can realistically wipe an unprepared party (%.1f blows)" % deep_blows)

	print("CHECKS ", _checks, " FAILS ", _fails.size())
	for f in _fails:
		print("  - ", f)
	print("L45_TEST ", "OK" if _fails.is_empty() else "FAIL")
	quit()
