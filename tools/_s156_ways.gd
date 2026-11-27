extends SceneTree
## S156: SYSTEM 40's REMAINDER - the paths' bespoke ways in delve.gd. Headless. Prints
## S156_WAYS OK / FAIL. S156_RED=1 strips every hero's path first, and the gate must go red.
var _d: Delve
var _r: Roster
var _fails: Array = []
var _checks := 0
var _red := OS.get_environment("S156_RED") == "1"

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _mem(name: String, cls: String, spec: String, at: Vector3) -> Dictionary:
	var b := Node3D.new()
	b.position = at
	root.add_child(b)
	var h := {"name": name, "class": cls, "spec": "" if _red else spec, "level": 12, "alive": true}
	return {"uid": name, "h": h, "body": b, "hp": 50.0, "max": 100.0, "saved": true, "swing": 0.0}

func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)
	_d = Delve.new()
	_d.roster = _r
	root.add_child(_d)
	await process_frame            # bodies must be inside the tree before global_position reads
	# every way named in SPEC_WAYS is a real path of a real calling
	var bad: Array = []
	for k in Roster.SPEC_WAYS:
		var found := false
		for c in Roster.SPECS:
			if (Roster.SPECS[c] as Dictionary).has(k):
				found = true
		if not found:
			bad.append(k)
	_ok(bad.is_empty(), "every SPEC_WAYS key is a real path %s" % [bad])

	# taunt: the creature at the origin goes for the Guardian 6 away, not the mage 1 away
	var mage := _mem("Ilsa", "mage", "evoker", Vector3(1, 0, 0))
	var guard := _mem("Bram", "knight", "guardian", Vector3(6, 0, 0))
	var far_g := _mem("Odo", "knight", "guardian", Vector3(30, 0, 0))
	_d.party = [mage, guard, far_g]
	_ok(absf(_d._flat((mage["body"] as Node3D).global_position, Vector3.ZERO) - 1.0) < 0.01, "taunt: the mage really is nearer (1 m vs 6 m)")
	var t := _d._taunter(Vector3.ZERO, _d.party)
	_ok(not t.is_empty() and is_same(t, guard), "taunt: the near Guardian draws the blow off the nearer mage")
	var t2 := _d._taunter(Vector3(60, 0, 0), _d.party)
	_ok(t2.is_empty() or _red, "taunt: no Guardian within TAUNT_R, nobody is drawn")

	# aura
	_ok(is_equal_approx(_d._aura_mult(), 1.0), "aura: no Chieftain, blows land as they were")
	var chief := _mem("Hild", "barbarian", "chieftain", Vector3(2, 0, 0))
	_d.party.append(chief)
	_ok(is_equal_approx(_d._aura_mult(), Delve.AURA_MULT), "aura: a Chieftain standing, x%.2f" % _d._aura_mult())
	chief["hp"] = 0.0
	_ok(is_equal_approx(_d._aura_mult(), 1.0), "aura: the Chieftain down, the aura goes with them")

	# trapsense once a floor
	var trk := _mem("Wynn", "rogue", "tracker", Vector3(3, 0, 0))
	_d.party.append(trk)
	_d.floor_no = 4
	_ok(_d._trapsense() == "Wynn", "trapsense: the Tracker reads the first trap of floor 4")
	_ok(_d._trapsense() == "", "trapsense: and only the first")
	_d.floor_no = 5
	_ok(_d._trapsense() == "Wynn", "trapsense: fresh again on floor 5")

	# mend_party once a floor, every living delver gains a fifth
	var heal := _mem("Aud", "sage", "healer", Vector3(4, 0, 0))
	_d.party.append(heal)
	mage["hp"] = 20.0
	guard["hp"] = 40.0
	var did := _d._mend_party()
	_ok(did and is_equal_approx(float(mage["hp"]), 40.0) and is_equal_approx(float(guard["hp"]), 60.0),
		"mend_party: mage 20->%d, guardian 40->%d" % [int(mage["hp"]), int(guard["hp"])])
	_ok(is_equal_approx(float(chief["hp"]), 0.0), "mend_party: the fallen are not mended")
	_ok(not _d._mend_party(), "mend_party: once a floor")

	# death ward: a second death save that holds, once
	var still := _mem("Tam", "monk", "stillwater", Vector3(5, 0, 0))
	still["hp"] = 0.0
	_ok(_d._death_ward(still) and is_equal_approx(float(still["hp"]), 1.0), "death_ward: Stillwater stands at 1 hp")
	still["hp"] = 0.0
	_ok(not _d._death_ward(still), "death_ward: once a delve")
	var plain := _mem("Pip", "mage", "evoker", Vector3(5, 0, 0))
	plain["hp"] = 0.0
	_ok(not _d._death_ward(plain), "death_ward: a path without the ward gets none")

	print("S156 spec_log %s" % [_d.spec_log])
	if _fails.is_empty():
		print("S156_WAYS OK %d checks" % _checks)
	else:
		print("S156_WAYS FAIL %d of %d" % [_fails.size(), _checks])
	quit()
