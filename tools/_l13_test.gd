extends SceneTree
## L13: accessories and cosmetics. Prints L13_TEST OK.
var _fail := 0

func _ok(c: bool, what: String) -> void:
	print(("  ok  " if c else "  FAIL ") + what)
	if not c:
		_fail += 1

func _initialize() -> void:
	var it := Roster.items()
	_ok((it["accessories"] as Dictionary).size() == 10 and (it["cosmetics"] as Dictionary).size() == 18 and (it["dyes"] as Dictionary).size() == 10, "data/items.json: 10 accessories, 18 cosmetics, 10 dyes")
	var r := Roster.new()
	root.add_child(r)
	var cc := ChatCmd.new(r)
	var h: Dictionary = r.fresh("w1", "Wren", "knight", "human")
	h["gold"] = 9000
	print("A: accessories in the numbers")
	var ac0 := r.armour_class(h)
	var out := cc.handle("w1", "Wren", "!wear night watch")
	_ok(r.armour_class(h) == ac0 + 1 and (h["owned"] as Array).has("nightwatch_ring"), "!wear night watch: AC %d -> %d: %s" % [ac0, r.armour_class(h), out])
	cc._last.clear()
	var sv0 := r.save_bonus(h, "dex")
	out = cc.handle("w1", "Wren", "!wear ferryman's ring")
	_ok(r.armour_class(h) == ac0 and r.save_bonus(h, "dex") == sv0 + 1, "a second ring takes the ring slot: AC back, saves +1: %s" % out)
	cc._last.clear()
	var g0 := int(h["gold"])
	out = cc.handle("w1", "Wren", "!wear night watch")
	_ok(int(h["gold"]) == g0 and r.armour_class(h) == ac0 + 1, "an item owned is worn again for nothing: %s" % out)
	var hp0 := r.max_hp(h)
	r.wear("w1", "hearthstone")
	_ok(r.max_hp(h) == hp0 + 12.0, "Hearthstone Amulet +12 hp")
	var sp0 := r.speed(h)
	r.wear("w1", "west road")
	_ok(absf(r.speed(h) - sp0 - 0.6) < 0.001, "Boots of the West Road +0.6 speed")
	var hit0 := r.attack_bonus(h)
	r.wear("w1", "fletcher")
	_ok(r.attack_bonus(h) == hit0 + 1, "Fletcher's Gloves +1 to hit")
	var d := Delve.new()
	d.roster = r
	d._rng.randomize()
	var m0 := 0.0
	for i in 4000:
		m0 += d._hero_damage(h, false)
	r.wear("w1", "smith")
	var m1 := 0.0
	for i in 4000:
		m1 += d._hero_damage(h, false)
	_ok(absf((m1 - m0) / 4000.0 - 2.0) < 0.3, "Smith's Gauntlets +2 damage (%.2f)" % ((m1 - m0) / 4000.0))
	d.free()
	print("B: cosmetics and dye")
	cc._last.clear()
	out = cc.handle("w1", "Wren", "!wear corgi")
	_ok(String(h["cos"]["pet"]) == "pet_corgi", "!wear corgi: %s" % out)
	cc._last.clear()
	out = cc.handle("w1", "Wren", "!wear keeper of the door")
	_ok(r.title_of(h) == "Keeper of the Door", "a title: %s" % out)
	cc._last.clear()
	out = cc.handle("w1", "Wren", "!dye teal")
	_ok(String(h["cos"]["dye"]) == "teal", "!dye teal: %s" % out)
	cc._last.clear()
	out = cc.handle("w1", "Wren", "!dye plaid")
	_ok(out.contains("The dyer has"), "an unknown colour lists the dyes: %s" % out)
	cc._last.clear()
	out = cc.handle("w1", "Wren", "!wear crown of thorns")
	_ok(out.contains("No such thing"), "an unknown item: %s" % out)
	r.wear("w1", "off pet")
	_ok(not (h["cos"] as Dictionary).has("pet"), "!wear off pet")
	var poor: Dictionary = r.fresh("w2", "Pip", "rogue", "halfling")
	poor["gold"] = 5
	out = r.wear("w2", "corgi")
	_ok(not poor.has("owned") and out.contains("needs"), "no gold, no corgi: %s" % out)
	cc._last.clear()
	out = cc.handle("w1", "Wren", "!inventory")
	_ok(out.contains("Keeper of the Door") and out.contains("Smith's Gauntlets") and out.contains("dyed teal"), "!inventory shows it: %s" % out)
	print("C: worn")
	r.wear("w1", "corgi")
	r.wear("w1", "wide-brimmed")
	r.wear("w1", "market banner")
	var host := Node3D.new()
	root.add_child(host)
	var body: Node3D = (load("res://addons/kaykit_character_pack_adventures/Characters/gltf/" + String(Roster.CLASSES["knight"]["model"])) as PackedScene).instantiate()
	host.add_child(body)
	Gear.strip_props(body)
	h["armour"] = 3
	r.offhand_bone(h)
	Gear.rank_trim(body, 0)
	var sk := Gear.skeleton(body)
	for slot in ["eq_ring", "eq_amulet", "eq_glove_l", "eq_hat", "eq_banner"]:
		_ok(sk.get_node_or_null(NodePath(slot)) != null, "%s is on the body" % slot)
	_ok(body.get_node_or_null("eq_title") != null, "the title floats under the name")
	var pets := 0
	for c in host.get_children():
		if c is HeroPet:
			pets += 1
	_ok(pets == 1, "one pet at heel")
	r.offhand_bone(h)
	Gear.rank_trim(body, 0)
	await process_frame
	pets = 0
	for c in host.get_children():
		if c is HeroPet and not c.is_queued_for_deletion():
			pets += 1
	_ok(pets == 1, "re-dressing does not add a second pet")
	print("L13_TEST OK" if _fail == 0 else "L13_TEST FAIL %d" % _fail)
	quit()
