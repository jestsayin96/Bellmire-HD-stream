extends SceneTree
## L3 (work plan 2): weapon kinds and tiers, worn armour, the forge, deep finds.
## Prints L3_TEST OK.
var _fail := 0

func _ok(c: bool, what: String) -> void:
	print(("  ok  " if c else "  FAIL ") + what)
	if not c:
		_fail += 1

func _initialize() -> void:
	print("A: every kind has a mesh at every tier, every class has kinds")
	for k in Gear.KINDS:
		if bool(Gear.KINDS[k].get("bare", false)):
			continue
		for t in range(1, 6):
			var p := Gear.kind_path(k, t)
			_ok(ResourceLoader.exists(p), "%s tier %d: %s" % [k, t, p.get_file()])
	for c in Roster.CLASSES:
		var fam := String(Roster.CLASSES[c]["family"])
		_ok(Gear.kinds_of(fam).size() >= 2, "%s (%s) chooses from %s" % [c, fam, Gear.kinds_of(fam)])
	_ok(Roster.WEAPONS.size() == Gear.WEAPONS.size() and Roster.ARMOUR.size() == Gear.ARMOUR.size(), "Roster and Gear tier tables agree")
	_ok(Roster.forged_max(Roster.WEAPONS) == 4 and Roster.forged_max(Roster.ARMOUR) == 4, "the forge's best is still tier 4")

	print("B: the forge")
	var r := Roster.new()
	root.add_child(r)
	Roster.town_tier = 4
	var k: Dictionary = r.fresh("u1", "Ashe", "knight")
	k["gold"] = 5000
	_ok(r.weapon_name(k) == "bare hands", "a fresh knight is bare-handed")
	var s := r.buy_weapon("u1", "spear")
	_ok(int(k["weapon"]) == 1 and String(k["wkind"]) == "spear", "!forge spear: %s" % s)
	_ok(r.weapon_name(k) == "plain steel spear", "named: %s" % r.weapon_name(k))
	_ok(r.weapon_mesh(k).ends_with("spear_A.gltf"), "spear mesh %s" % r.weapon_mesh(k).get_file())
	_ok(absf(float(r.weapon_look(k)["scale"]) - 0.62) < 0.01, "kit spear scaled for the hand (%.2f)" % float(r.weapon_look(k)["scale"]))
	s = r.buy_weapon("u1", "mace")
	_ok(int(k["weapon"]) == 1 and String(k["wkind"]) == "spear", "a knight cannot have a mace: %s" % s)
	s = r.buy_weapon("u1", "")
	_ok(int(k["weapon"]) == 2 and String(k["wkind"]) == "spear", "!forge keeps the kind: %s" % s)
	k["weapon"] = 4
	var g0 := int(k["gold"])
	s = r.buy_weapon("u1", "greatsword")
	_ok(int(k["weapon"]) == 4 and String(k["wkind"]) == "greatsword" and int(k["gold"]) < g0, "rework at the top: %s" % s)
	s = r.buy_weapon("u1", "")
	_ok(int(k["weapon"]) == 4, "scarforged is never sold: %s" % s)
	k["armour"] = 4
	s = r.buy_armour("u1")
	_ok(int(k["armour"]) == 4, "scarwoven is never sold: %s" % s)
	var poor: Dictionary = r.fresh("u2", "Bram", "warden")
	poor["gold"] = 0
	s = r.buy_weapon("u2", "mace")
	_ok(int(poor["weapon"]) == 0 and not poor.has("wkind"), "no gold, no mace, no free change: %s" % s)
	_ok(r.forge_menu("u2").contains("axe") and r.forge_menu("u2").contains("mace"), "!forge list: %s" % r.forge_menu("u2"))

	print("C: deep floors give up gear")
	var f: Dictionary = r.fresh("u3", "Cass", "barbarian")
	f["weapon"] = 2
	f["armour"] = 2
	_ok(r.find_gear("u3", 5, 0.0) == "", "nothing found above floor 6")
	_ok(r.find_gear("u3", 7, 0.99) == "", "a missed roll finds nothing")
	s = r.find_gear("u3", 7, 0.0)
	_ok(int(f["weapon"]) == 3 or int(f["armour"]) == 3, "floor 7: %s" % s)
	f["weapon"] = 4
	f["armour"] = 4
	_ok(r.find_gear("u3", 8, 0.0) == "", "nothing past the forge's best above floor 10")
	s = r.find_gear("u3", 12, 0.0)
	_ok(int(f["weapon"]) == 5 or int(f["armour"]) == 5, "floor 12: %s" % s)
	_ok(r.weapon_name(f).begins_with("scarforged") or String(Roster.ARMOUR[int(f["armour"])]["name"]) == "scarwoven mail", "the scar's own: %s / %s" % [r.weapon_name(f), Roster.ARMOUR[int(f["armour"])]["name"]])
	_ok(float(r.attack(f)) > 0.0 and float(r.max_hp(f)) > 0.0 and r.armour_class(f) > 0, "tier 5 works in the numbers (atk %.0f hp %.0f ac %d)" % [r.attack(f), r.max_hp(f), r.armour_class(f)])

	print("D: chat")
	var cc := ChatCmd.new(r)
	r.fresh("u4", "Dov", "ranger")
	r.get_hero("u4")["gold"] = 500
	var out := cc.handle("u4", "Dov", "!forge bow")
	_ok(String(r.get_hero("u4").get("wkind", "")) == "bow", "chat !forge bow: %s" % out)
	cc._last.clear()
	out = cc.handle("u4", "Dov", "!forge list")
	_ok(out.contains("crossbow") and out.contains("bow"), "chat !forge list: %s" % out)

	print("E: armour is worn")
	for mdl in ["Knight", "Barbarian", "Mage", "Rogue", "Rogue_Hooded"]:
		var bb: Node3D = (load("res://addons/kaykit_character_pack_adventures/Characters/gltf/%s.glb" % mdl) as PackedScene).instantiate()
		Gear.strip_props(bb)
		print("    ", mdl, " has headwear of its own: ", Gear._has_headwear(bb))
		bb.free()
	var body: Node3D = (load("res://addons/kaykit_character_pack_adventures/Characters/gltf/Barbarian.glb") as PackedScene).instantiate()
	root.add_child(body)
	Gear.strip_props(body)
	for t in range(0, 6):
		Gear.dress_armour(body, t)
		var sk := Gear.skeleton(body)
		var n := 0
		for slot in ["eq_boot_l", "eq_boot_r", "eq_pauldron_l", "eq_pauldron_r", "eq_helm"]:
			if sk.get_node_or_null(NodePath(slot)) != null:
				n += 1
		var want: int = [0, 2, 4, 5, 5, 5][t] - (1 if t >= 3 and Gear._has_headwear(body) else 0)
		_ok(n == want, "armour tier %d wears %d pieces (want %d)" % [t, n, want])
	Gear._dressing = k
	Gear.rank_trim(body, 0)
	_ok(Gear._dressing.is_empty() and Gear.skeleton(body).get_node_or_null("eq_boot_l") != null, "a hero being dressed gets armour through rank_trim")
	Gear.rank_trim(body, 0)
	print("L3_TEST OK" if _fail == 0 else "L3_TEST FAIL %d" % _fail)
	quit()
