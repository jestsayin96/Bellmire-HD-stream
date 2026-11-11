extends SceneTree
## L5 (work plan 2): species. !enlist <class> <species> either way round, bonuses,
## traits, the look, saves without a species, reroll and respec. Prints L5_TEST OK.
var _fail := 0
func _ok(c: bool, what: String) -> void:
	print(("  ok  " if c else "  FAIL ") + what)
	if not c:
		_fail += 1
func _initialize() -> void:
	var r := Roster.new()
	root.add_child(r)
	var cc := ChatCmd.new(r)
	var out := cc.handle("a1", "Borin", "!enlist knight dwarf")
	var h := r.get_hero("a1")
	_ok(String(h.get("species", "")) == "dwarf" and String(h["class"]) == "knight", "!enlist knight dwarf: %s" % out)
	out = cc.handle("a2", "Elowen", "!enlist elf ranger")
	_ok(String(r.get_hero("a2").get("species", "")) == "elf" and String(r.get_hero("a2")["class"]) == "ranger", "!enlist elf ranger: %s" % out)
	out = cc.handle("a3", "Nob", "!enlist mage goblin")
	_ok(r.get_hero("a3").is_empty() and out.contains("No such people"), "unknown people refused: %s" % out)
	out = cc.handle("a4", "Rand", "!enlist bard")
	_ok(Roster.SPECIES.has(String(r.get_hero("a4").get("species", ""))), "no species given: one is drawn (%s)" % r.get_hero("a4").get("species"))
	var seen := {}
	for i in range(600):
		seen[r._any_species()] = true
	_ok(seen.size() == Roster.SPECIES.size(), "every people turns up in a draw (%s)" % [seen.keys()])
	# bonuses: the same seed with and without a species
	r.rng.seed = 77
	var base := r.roll_stats("knight")
	r.rng.seed = 77
	var dw := r._with_species(r.roll_stats("knight"), "dwarf")
	_ok(int(dw["con"]) == mini(20, int(base["con"]) + 2) and int(dw["wis"]) == mini(20, int(base["wis"]) + 1) and int(dw["str"]) == int(base["str"]), "dwarf +2 CON +1 WIS")
	var hu := r._with_species(base.duplicate(), "human")
	var all_up := true
	for s in Roster.STATS:
		if int(hu[s]) != mini(20, int(base[s]) + 1):
			all_up = false
	_ok(all_up, "human +1 to every ability")
	_ok(Roster.has_trait(h, "darkvision") and not Roster.has_trait(r.fresh("a5", "Pip", "rogue", "halfling"), "darkvision") and Roster.has_trait(r.get_hero("a5"), "lucky"), "dwarves see in the dark, halflings are lucky")
	var old := {"name": "Old", "class": "knight", "stats": base}
	_ok(Roster.species_of(old) == "human" and not Roster.has_trait(old, "darkvision"), "a save from before species reads as human")
	_ok(r.describe("a1").contains("dwarf knight"), "the sheet says it: %s" % r.describe("a1").substr(0, 60))
	h["gold"] = 1000
	r.reroll("a1")
	_ok(String(h["species"]) == "dwarf", "a reroll keeps the people")
	h["wkind"] = "spear"
	r.respec("a1", "barbarian")
	_ok(not h.has("wkind"), "a respec drops a weapon kind of the old family")
	print("look")
	for sp in Roster.SPECIES:
		var body: Node3D = (load("res://addons/kaykit_character_pack_adventures/Characters/gltf/Rogue.glb") as PackedScene).instantiate()
		root.add_child(body)
		Gear._dressing = {"class": "rogue", "species": sp, "armour": 0}
		Gear.rank_trim(body, 0)
		var want: Vector3 = Roster.SPECIES[sp].get("scale", Vector3.ONE)
		var parts: Array = Roster.SPECIES[sp].get("parts", [])
		var att := Gear.skeleton(body).get_node_or_null("eq_species")
		_ok(body.scale.is_equal_approx(want) and (att != null) == (not parts.is_empty()), "%s: scale %s, parts %s" % [sp, body.scale, parts])
		Gear._dressing = {"class": "rogue", "species": sp, "armour": 0}
		Gear.rank_trim(body, 0)
		_ok(body.scale.is_equal_approx(want), "%s: dressing twice does not compound" % sp)
		body.free()
	print("L5_TEST OK" if _fail == 0 else "L5_TEST FAIL %d" % _fail)
	quit()
