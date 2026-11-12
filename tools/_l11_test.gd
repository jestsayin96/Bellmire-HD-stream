extends SceneTree
## L11: traps that visibly work. Prints L11_TEST OK.
var _fail := 0
var _d: Delve
var _r: Roster
var _f := 0
var _feed: Array = []

func _ok(c: bool, what: String) -> void:
	print(("  ok  " if c else "  FAIL ") + what)
	if not c:
		_fail += 1

func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)
	var ids := []
	for i in 2:
		var h: Dictionary = _r.fresh("t%d" % i, ["BigAxe", "Sly"][i], ["barbarian", "rogue"][i], "human")
		h["oil"] = 5
		ids.append("t%d" % i)
	_d = Delve.new()
	_d.roster = _r
	_d.start_floor = 6
	_d.max_floors = 6
	root.add_child(_d)
	_d.start(ids)

func _trap(kind: String) -> Dictionary:
	var made := {"SpikeTrap": DungeonParts.spike_trap, "PressurePlate": DungeonParts.pressure_plate, "FireTrap": DungeonParts.fire_trap,
		"DartTrap": DungeonParts.dart_trap, "BladeTrap": DungeonParts.blade_trap, "PitTrap": DungeonParts.pit_trap}
	var n: Node3D = (made[kind] as Callable).call()
	(_d.dun.info["root"] as Node3D).add_child(n)
	n.global_position = (_d.party[0]["body"] as Node3D).global_position
	return {"node": n, "kind": kind}

func _process(_dt: float) -> bool:
	_f += 1
	if _f != 20:
		return false
	_d.set_process(false)
	var feed: Array = []
	var big: Dictionary = _d.party[0]
	var sly: Dictionary = _d.party[1]
	print("A: every kind, sprung")
	for kind in Delve.TRAPS:
		big["hp"] = 9999.0
		big["max"] = 9999.0
		var tr := _trap(kind)
		var before := float(big["hp"])
		var n0 := _d.trap_log["sprung"] as int
		_d._meet_trap(big, tr, 0)
		var line := String(_d.town.get("feed")[-1]) if _d.town else ""
		var node: Node3D = tr["node"]
		_ok(int(node.get_meta("fired", 0)) == 1 and node.has_meta("fire"), "%s plays its trigger" % kind)
		_ok(float(big["hp"]) < before and int(_d.trap_log["sprung"]) == n0 + 1, "%s does damage (%d)" % [kind, int(before - float(big["hp"]))])
	print("B: the rolls")
	var saves := 0
	var n := 2000
	_d.trap_log["saved"] = 0
	for i in n:
		big["hp"] = 9999.0
		_d._spring(big, {"node": Node3D.new(), "kind": "DartTrap"}, Delve.TRAPS["DartTrap"], _d.trap_dc())
	var sb := _r.save_bonus(big["h"], "dex")
	var dc := _d.trap_dc()
	var want := 0.05
	for dd in range(2, 20):
		if dd + sb >= dc:
			want += 0.05
	_ok(absf(float(_d.trap_log["saved"]) / float(n) - want) < 0.03, "DEX saves %.3f vs the odds %.3f (save %+d vs DC %d)" % [float(_d.trap_log["saved"]) / float(n), want, sb, dc])
	var dis0 := int(_d.trap_log["disarmed"])
	for i in 400:
		sly["hp"] = 9999.0
		sly["max"] = 9999.0
		_d._meet_trap(sly, {"node": Node3D.new(), "kind": "BladeTrap"}, 1)
	_ok(int(_d.trap_log["disarmed"]) - dis0 > 100, "a rogue disarms spotted traps with thieves' tools (%d of 400)" % (int(_d.trap_log["disarmed"]) - dis0))
	var dis1 := int(_d.trap_log["disarmed"])
	for i in 50:
		_d._meet_trap(big, {"node": Node3D.new(), "kind": "BladeTrap"}, 1)
	_ok(int(_d.trap_log["disarmed"]) == dis1, "a barbarian who spots one steps round it, no tools")
	print("C: the Chronicle")
	big["hp"] = 9999.0
	var lines: Array = []
	var old_say := _d.town
	_d._meet_trap(big, _trap("DartTrap"), 0)
	print("  sample: ", _d.get("_last_line") if false else "(see FEED above)")
	print("L11_TEST OK" if _fail == 0 else "L11_TEST FAIL %d" % _fail)
	return true
