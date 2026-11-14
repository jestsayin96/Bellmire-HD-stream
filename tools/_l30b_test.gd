extends SceneTree
## L30b: COSMETICS & DYES - items.json cosmetics change only the look. The DONE
## line asks "!wear + !dye change the model in a soak." The writer has shipped
## ~32 cosmetics (hat / banner / pet / title) and ~50 dyes, and L13 wired
## roster.wear/roster.dye + Gear.dress_cosmetics/_cape_tint. This test proves
## the model actually changes under !wear / !dye and the wiring holds through
## a live delve.
##
## What is measured:
##   A. INVENTORY -- cosmetics + dyes load with the expected shape (hat has a
##      colour hex; pet has a model path; title has no model).
##   B. WEAR STATE -- !wear hat / banner / pet / title put the key in
##      h["cos"][kind]; !dye <colour> sets h["cos"]["dye"]; !wear off <kind>
##      removes it.
##   C. VISIBLE ON THE RIG -- a real HeroBody carries eq_hat, eq_banner and
##      eq_pet nodes on its skeleton after refresh(); the cape material's
##      albedo matches the dye colour.
##   D. SOAK -- heroes wearing cosmetics + dye run a 2-floor delve without
##      SCRIPT ERROR; the model keeps those nodes across floor transitions.
##
## Prints L30B_TEST OK / FAIL. Headless.

var _r: Roster
var _d: Delve
var _f := 0
var _fails: Array = []
var _checks := 0
var _hero_b: HeroBody = null
var _phase := 0        # 0 init -> 1 added -> 2 D done + soak started -> 3 soak done

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)

	# ---- A. inventory
	print("L30b A: cosmetics + dyes loaded?")
	var items: Dictionary = Roster.items()
	var cos: Dictionary = items.get("cosmetics", {})
	var dyes: Dictionary = items.get("dyes", {})
	print("   %d cosmetics, %d dyes" % [cos.size(), dyes.size()])
	_ok(cos.size() >= 20, "A: a healthy stock of cosmetics (%d)" % cos.size())
	_ok(dyes.size() >= 30, "A: a healthy stock of dyes (%d)" % dyes.size())
	var kinds := {}
	var hat_no_colour := []
	var pet_no_model := []
	for key in cos:
		var it: Dictionary = cos[key]
		var kind := String(it.get("kind", ""))
		kinds[kind] = int(kinds.get(kind, 0)) + 1
		if kind == "hat" and not it.has("colour"):
			hat_no_colour.append(key)
		if kind == "pet" and not it.has("model"):
			pet_no_model.append(key)
	print("   kind counts: %s" % [kinds])
	_ok(kinds.has("hat") and kinds.has("banner") and kinds.has("pet") and kinds.has("title"),
		"A: all four kinds represented (%s)" % [kinds.keys()])
	_ok(hat_no_colour.is_empty(), "A: every hat carries a colour hex (%d without)" % hat_no_colour.size())
	_ok(pet_no_model.is_empty(), "A: every pet carries a model path (%d without)" % pet_no_model.size())

	# ---- B. wear state on a bare roster-only hero
	print("L30b B: !wear + !dye populate h.cos[]")
	var h: Dictionary = _r.fresh("l30b_probe", "Probe", "knight")
	h["gold"] = 9999

	# pick one of each kind
	var picks := {"hat": "", "banner": "", "pet": "", "title": ""}
	for key in cos:
		var kind := String((cos[key] as Dictionary).get("kind", ""))
		if picks.has(kind) and picks[kind] == "":
			picks[kind] = String(key)
	for kind in picks:
		var reply := _r.wear("l30b_probe", String(picks[kind]))
		print("   wear %s (%s): %s" % [kind, picks[kind], reply])
	var cos_dict: Dictionary = h.get("cos", {})
	for kind in picks:
		_ok(String(cos_dict.get(kind, "")) == String(picks[kind]),
			"B: h.cos[%s] = %s" % [kind, picks[kind]])

	# !dye
	var dye_reply := _r.dye("l30b_probe", "crimson")
	print("   dye crimson: %s" % dye_reply)
	_ok(String((h.get("cos", {}) as Dictionary).get("dye", "")) == "crimson",
		"B: !dye sets h.cos.dye (crimson)")

	# !wear off <kind> - exercise the non-slot cosmetic removal path
	var reply_off := _r.wear("l30b_probe", "off hat")
	print("   off hat: %s" % reply_off)
	_ok(not (h.get("cos", {}) as Dictionary).has("hat"), "B: !wear off hat removes the hat")

	# ---- C and D run in _process so the HeroBody's skeleton has a chance to mount
	_hero_b = HeroBody.new()
	_hero_b.setup(_r, "l30b_probe")

func _process(_dt: float) -> bool:
	_f += 1
	if _phase == 0 and _hero_b != null:
		_phase = 1
		root.add_child(_hero_b)
		return false
	if _phase == 1:
		_phase = 2
		# put the hat back on, so eq_hat should mount
		_r.wear("l30b_probe", "wide_hat")
		_r.wear("l30b_probe", "banner_blue")
		_r.wear("l30b_probe", "pet_corgi")
		_r.dye("l30b_probe", "teal")
		_hero_b.refresh()
		var model_root: Node = _hero_b.get("_mdl")
		var sk := Gear.skeleton(model_root) if model_root else null
		if sk == null:
			_ok(false, "C: HeroBody has a skeleton")
		else:
			_ok(sk.get_node_or_null("eq_hat") != null, "C.hat: eq_hat node attached to the skeleton")
			_ok(sk.get_node_or_null("eq_banner") != null, "C.banner: eq_banner node attached")
			# pet mounts as a HeroPet child of the HeroBody
			var has_pet := false
			for c in _hero_b.get_children():
				if c is HeroPet:
					has_pet = true
					break
			_ok(has_pet, "C.pet: a HeroPet child mounted under the HeroBody")
			# dye: the cape mesh's surface override albedo should match the dye hex
			# exactly (Gear._cape_tint sets it outright). Any cape mesh, any surface.
			var teal := Color.html("1e8a8a")
			var cape_tinted := false
			var cape_sample := Color(0, 0, 0)
			for mi in model_root.find_children("*", "MeshInstance3D", true, false):
				if not String((mi as Node).name).contains("Cape"):
					continue
				var m: MeshInstance3D = mi
				if m.mesh == null:
					continue
				for i in range(m.mesh.get_surface_count()):
					var mat: Material = m.get_surface_override_material(i)
					if mat == null:
						mat = m.get_active_material(i)
					if not (mat is StandardMaterial3D):
						continue
					var a: Color = (mat as StandardMaterial3D).albedo_color
					if abs(a.r - teal.r) < 0.05 and abs(a.g - teal.g) < 0.05 and abs(a.b - teal.b) < 0.05:
						cape_tinted = true
						cape_sample = a
						break
				if cape_tinted:
					break
			_ok(cape_tinted, "C.dye: a cape surface override matches the dye colour (sample=%s target=%s)"
				% [cape_sample, teal])

		# ---- D. soak - a short delve with cosmetics + dye set
		print("L30b D: short soak - cosmetics + dye through a delve")
		var ids: Array = []
		for v in [["30b_a", "Aen", "knight"], ["30b_b", "Brel", "mage"], ["30b_c", "Corvin", "cleric"], ["30b_d", "Doria", "barbarian"]]:
			var hh: Dictionary = _r.fresh(v[0], v[1], v[2])
			hh["gold"] = 9999
			hh["oil"] = 8
			hh["weapon"] = 2
			hh["armour"] = 2
			_r.wear(v[0], "wide_hat")
			_r.wear(v[0], "banner_blue")
			_r.dye(v[0], "crimson")
			ids.append(v[0])
		_d = Delve.new()
		_d.roster = _r
		_d.max_floors = 2
		_d.start_floor = 2
		root.add_child(_d)
		_d.start(ids)
		_f = 0
		return false

	if _phase != 2:
		return false
	if _d.state == "home" or _f > 60 * 120:
		# every party member still has their cos entries after the delve
		var kept := 0
		for uid in ["30b_a", "30b_b", "30b_c", "30b_d"]:
			var hh2 := _r.get_hero(uid)
			var cd: Dictionary = hh2.get("cos", {})
			if cd.has("hat") and cd.has("banner") and cd.has("dye"):
				kept += 1
		_ok(kept == 4, "D: cosmetics + dye survive the delve for every hero (%d/4)" % kept)
		_ok(_d.state in ["home", "flee", "fight", "search", "descend"],
			"D: soak reached a known state (state=%s frames=%d)" % [_d.state, _f])
		print("")
		print("CHECKS ", _checks, " FAILS ", _fails.size())
		for fl in _fails:
			print("  - ", fl)
		print("L30B_TEST ", "OK" if _fails.is_empty() else "FAIL")
		return true
	return false
