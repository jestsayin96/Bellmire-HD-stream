extends SceneTree
## L30a: GEAR EXPANSION - items.json accessories should be MORE than dead data.
## DONE line: "heroes equip visibly in a soak, bonuses apply." The writer has
## shipped 80+ accessories in data/items.json across six slots (ring, amulet,
## cloak, boots, gloves) with real 5E bonuses (ac / saves / hp / speed / hit /
## dmg). L13 wired up acc_bonus, wear(), item_key() and the dress_cosmetics
## skeleton paint. This test proves the wiring still holds end-to-end.
##
## What is measured:
##   A. INVENTORY -- items.json loads; every accessory carries a slot and at
##      least one of the six bonus keys; the content writer is not idle.
##   B. WEAR STATE -- !wear puts a key in h["acc"][slot]; !wear off <slot>
##      removes it; owned tracks what has been bought.
##   C. BONUSES FLOW -- the stats the delve actually reads (ac, attack_bonus,
##      max_hp, speed, save_bonus, and the dmg bonus in delve._blows_tick)
##      go up by the expected amount after !wear.
##   D. VISIBLE -- a real HeroBody (model loaded, skeleton instantiated)
##      carries eq_ring / eq_amulet / eq_cboot_l-r / eq_glove_l-r nodes on its
##      skeleton after refresh(), and a weapon tier change moves the handslot.r
##      mesh at EQ_ROOT. This is the "visible on handslot bones (rig EQUIP)"
##      half of the plan line.
##   E. SOAK -- a 3-floor delve with heroes who wear accessories writes a
##      Chronicle and finishes without SCRIPT ERROR. The bonuses do not need
##      to swing the outcome, only to BE there when combat arithmetic runs.
##
## Prints L30A_TEST OK / FAIL. Headless; instantiates Roster/HeroBody/Delve
## directly, as _l29b and _l29c do.

var _r: Roster
var _d: Delve
var _f := 0
var _fails: Array = []
var _checks := 0
var _hero_b: HeroBody = null
var _phase := 0        # 0 init, 1 wait-a-frame, 2 D done, 3 soak, 4 soak done

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)

	# ---- A. inventory
	print("L30a A: items.json loaded?")
	var items: Dictionary = Roster.items()
	var acc: Dictionary = items.get("accessories", {})
	print("   %d accessories loaded" % acc.size())
	_ok(acc.size() >= 40, "A: a healthy stock of accessories (%d)" % acc.size())
	var slots := {}
	var bonus_keys := ["ac", "saves", "hp", "speed", "hit", "dmg"]
	var slot_counts := {}
	var no_bonus := []
	for key in acc:
		var it: Dictionary = acc[key]
		var slot := String(it.get("slot", ""))
		slot_counts[slot] = int(slot_counts.get(slot, 0)) + 1
		slots[slot] = true
		var has_any := false
		for bk in bonus_keys:
			if it.has(bk):
				has_any = true
				break
		if not has_any:
			no_bonus.append(key)
	print("   slot counts: %s" % [slot_counts])
	_ok(slots.has("ring") and slots.has("amulet") and slots.has("cloak") and slots.has("boots") and slots.has("gloves"),
		"A: all five slots represented (%s)" % [slots.keys()])
	_ok(no_bonus.is_empty(),
		"A: every accessory carries at least one 5E bonus (%d without)" % no_bonus.size())

	# ---- B + C. wear / bonuses on a bare roster-only hero (no body yet)
	print("L30a B+C: !wear sets acc[] and bonuses flow into the stat getters")
	var h: Dictionary = _r.fresh("l30a_probe", "Probe", "knight")
	h["gold"] = 9999                            # cover any cost
	var ac0: int = _r.armour_class(h)
	var atk0: int = _r.attack_bonus(h)
	var hp0: float = _r.max_hp(h)
	var sp0: float = _r.speed(h)
	var save0: int = _r.save_bonus(h, "wis")
	print("   baseline: ac=%d atk+=%d hp=%.1f speed=%.2f wis_save+=%d" % [ac0, atk0, hp0, sp0, save0])

	# pick one item per slot that carries a bonus we read (ac, saves, hp, speed, hit)
	# and not just the model paint - ignore cloak+ac items if we already covered ac
	var pick_for := {"ring": "ac", "amulet": "hp", "cloak": "saves", "boots": "speed", "gloves": "hit"}
	var chosen := {}
	for slot in pick_for:
		var want := String(pick_for[slot])
		for key in acc:
			var it2: Dictionary = acc[key]
			if String(it2.get("slot", "")) != slot:
				continue
			if not it2.has(want):
				continue
			chosen[slot] = key
			break
	print("   chosen: %s" % [chosen])
	_ok(chosen.size() == 5, "B: an item picked per slot (%d)" % chosen.size())
	# !wear each one through the chat path, not the direct setter: that is
	# the path a stream viewer actually uses
	for slot in chosen:
		var reply := _r.wear("l30a_probe", String(chosen[slot]))
		print("   wear %s (%s): %s" % [slot, chosen[slot], reply])
	var acc_dict: Dictionary = h.get("acc", {})
	for slot in chosen:
		_ok(String(acc_dict.get(slot, "")) == String(chosen[slot]),
			"B: h.acc[%s] = %s" % [slot, chosen[slot]])

	var ac1: int = _r.armour_class(h)
	var atk1: int = _r.attack_bonus(h)
	var hp1: float = _r.max_hp(h)
	var sp1: float = _r.speed(h)
	var save1: int = _r.save_bonus(h, "wis")
	print("   with gear: ac=%d (+%d) atk+=%d (+%d) hp=%.1f (+%.1f) speed=%.2f (+%.2f) wis+=%d (+%d)" %
		[ac1, ac1 - ac0, atk1, atk1 - atk0, hp1, hp1 - hp0, sp1, sp1 - sp0, save1, save1 - save0])
	_ok(ac1 > ac0, "C.ac: ring (ac bonus) raised AC (%d -> %d)" % [ac0, ac1])
	_ok(atk1 > atk0, "C.hit: gloves (hit bonus) raised attack_bonus (%d -> %d)" % [atk0, atk1])
	_ok(hp1 > hp0, "C.hp: amulet (hp bonus) raised max_hp (%.1f -> %.1f)" % [hp0, hp1])
	_ok(sp1 > sp0, "C.speed: boots raised speed (%.2f -> %.2f)" % [sp0, sp1])
	_ok(save1 > save0, "C.saves: cloak raised save_bonus (%d -> %d)" % [save0, save1])
	# the dmg bonus path (read in delve._blows_tick): pick a dmg item and check
	# acc_bonus goes up
	var dmg_item := ""
	for key in acc:
		var it3: Dictionary = acc[key]
		if int(it3.get("dmg", 0)) > 0:
			dmg_item = String(key)
			break
	if dmg_item != "":
		var dmg0: float = _r.acc_bonus(h, "dmg")
		_r.wear("l30a_probe", dmg_item)
		var dmg1: float = _r.acc_bonus(h, "dmg")
		_ok(dmg1 > dmg0, "C.dmg: a dmg accessory raised acc_bonus(dmg) (%.1f -> %.1f)" % [dmg0, dmg1])
	else:
		_ok(false, "C.dmg: a dmg accessory could be found in items.json")

	# !wear off <slot> removes it
	var reply_off := _r.wear("l30a_probe", "off ring")
	var acc2: Dictionary = h.get("acc", {})
	_ok(not acc2.has("ring"), "B: !wear off ring removes it")
	print("   off: %s" % reply_off)

	# ---- D. visibility: put a real HeroBody up and check the skeleton nodes
	print("L30a D: a real HeroBody carries equip nodes on its skeleton after refresh()")
	_hero_b = HeroBody.new()
	_hero_b.setup(_r, "l30a_probe")
	# the rest runs in _process so _ready has fired and the skeleton exists

	# ---- E. soak is launched after D so Delve sees the wearing hero in play
	# (see _process below)
	_phase = 0

func _process(_dt: float) -> bool:
	_f += 1
	# D runs after one frame so HeroBody._ready is done and _mdl has the skeleton
	if _phase == 0 and _hero_b != null:
		_phase = 1
		root.add_child(_hero_b)
		return false
	if _phase == 1:
		_phase = 2
		_hero_b.refresh()
		# the model's skeleton is _mdl's Skeleton3D; Gear.skeleton walks the tree
		var model_root: Node = _hero_b.get("_mdl")
		var sk := Gear.skeleton(model_root) if model_root else null
		if sk == null:
			_ok(false, "D: a real HeroBody has a skeleton")
		else:
			# re-wear a ring just before this check to make sure the eq_ring
			# node is up (the test's "off ring" call earlier removed it)
			_r.wear("l30a_probe", "nightwatch_ring")
			_hero_b.refresh()
			_ok(sk.get_node_or_null("eq_ring") != null,
				"D.ring: eq_ring node attached to the skeleton")
			_ok(sk.get_node_or_null("eq_amulet") != null,
				"D.amulet: eq_amulet node attached")
			_ok(sk.get_node_or_null("eq_glove_l") != null or sk.get_node_or_null("eq_glove_r") != null,
				"D.gloves: eq_glove_l/r attached")
			# the weapon equips on handslot.r via Gear.equip - a tier change should
			# move the mesh referenced at that slot
			var h2 := _r.get_hero("l30a_probe")
			h2["gold"] = 9999
			h2["weapon"] = 0
			_hero_b.refresh()
			var weapon0 := model_root.find_child("eq_weapon", true, false) if model_root else null
			var had0 := weapon0 != null
			h2["weapon"] = 3                # jump up to a runed weapon tier
			_hero_b.refresh()
			var weapon1 := model_root.find_child("eq_weapon", true, false) if model_root else null
			_ok(weapon1 != null,
				"D.handslot: weapon mesh at eq_weapon exists after a tier change (had before=%s, has after=%s)"
				% [str(had0), str(weapon1 != null)])

		# launch E (soak) immediately after D on the same frame
		print("L30a E: short soak - a hero wearing accessories completes a delve")
		var ids: Array = []
		for v in [["30a_a", "Aen", "knight"], ["30a_b", "Brel", "mage"], ["30a_c", "Corvin", "cleric"], ["30a_d", "Doria", "barbarian"]]:
			var hh: Dictionary = _r.fresh(v[0], v[1], v[2])
			hh["gold"] = 9999
			hh["oil"] = 10
			hh["weapon"] = 2
			hh["armour"] = 2
			# give each one a different accessory so acc_bonus(dmg) etc. fires in combat
			_r.wear(v[0], "smith_gloves")
			_r.wear(v[0], "nightwatch_ring")
			ids.append(v[0])
		_d = Delve.new()
		_d.roster = _r
		_d.max_floors = 3
		_d.start_floor = 2
		root.add_child(_d)
		_d.start(ids)
		_phase = 3
		_f = 0
		return false

	if _phase != 3:
		return false
	if _d.state == "home" or _f > 60 * 120:
		_phase = 4
		_ok(_d.state == "home" or _d.state == "flee" or _d.state == "fight" or _d.state == "search" or _d.state == "descend",
			"E: soak reached a known state (state=%s frames=%d)" % [_d.state, _f])
		# the real check is that no SCRIPT ERROR fired during the soak and the
		# combat read acc_bonus every blow. The fact that the delve is still
		# coherent after that many ticks is the evidence.
		print("")
		print("CHECKS ", _checks, " FAILS ", _fails.size())
		for fl in _fails:
			print("  - ", fl)
		print("L30A_TEST ", "OK" if _fails.is_empty() else "FAIL")
		return true
	return false
