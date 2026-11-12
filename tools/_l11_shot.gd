extends SceneTree
## L11 render: in the real town's light, a floor below; three delvers each stand
## on a trap (blade, fire, darts, then spikes, pit, plate); the fight is paused;
## the traps are set off and frames taken mid-trigger, with the floating numbers.
## Saves to renders/cycles/20261111_l11.
var _t: Node3D
var _d: Delve
var _f := 0
var _cam: Camera3D
var _set := 0
var _fire_at := -1
const OUT := "res://renders/cycles/20261111_l11"
const SETS := [["BladeTrap", "FireTrap", "DartTrap"], ["SpikeTrap", "PitTrap", "PressurePlate"]]
var _traps: Array = []

func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _place_set() -> void:
	for tr in _traps:
		if is_instance_valid(tr["node"]):
			(tr["node"] as Node3D).queue_free()
	_traps.clear()
	var made := {"SpikeTrap": DungeonParts.spike_trap, "PressurePlate": DungeonParts.pressure_plate, "FireTrap": DungeonParts.fire_trap,
		"DartTrap": DungeonParts.dart_trap, "BladeTrap": DungeonParts.blade_trap, "PitTrap": DungeonParts.pit_trap}
	# three open cells in a row, near the floor's middle
	var cells: Array = _d.dun._open_cells()
	var mid: Vector3 = _d.dun.info["root"].global_position
	cells.sort_custom(func(a, b) -> bool: return _d.dun._cell_pos(a).length() < _d.dun._cell_pos(b).length())
	var picked: Array = []
	for c in cells:
		var p: Vector3 = _d.dun._cell_pos(c) + mid
		var ok := true
		for q in picked:
			if (q as Vector3).distance_to(p) < 2.6:
				ok = false
		if ok:
			picked.append(p)
		if picked.size() == 3:
			break
	for i in 3:
		var n: Node3D = (made[SETS[_set][i]] as Callable).call()
		(_d.dun.info["root"] as Node3D).add_child(n)
		n.global_position = picked[i]
		_traps.append({"node": n, "kind": SETS[_set][i]})
		var b: Node3D = _d.party[i]["body"]
		b.global_position = picked[i] + Vector3(0, 0.05, 0)
		b.rotation.y = 0.0
		_d.party[i]["hp"] = 9999.0
		_d.party[i]["max"] = 9999.0
	var c0: Vector3 = (picked[0] + picked[1] + picked[2]) / 3.0
	_cam.global_position = c0 + Vector3(0, 5.5, 8.0)
	_cam.look_at(c0 + Vector3(0, 0.8, 0), Vector3.UP)
	_cam.make_current()

func _process(_dt: float) -> bool:
	_f += 1
	if _f == 20:
		var r: Roster = _t.get("roster")
		var ids := []
		for v in [["2201", "BigAxe", "barbarian"], ["2202", "MossyMage", "mage"], ["2203", "JestFan", "knight"]]:
			r.fresh(v[0], v[1], v[2], "human")
			ids.append(v[0])
		_d = Delve.new()
		_d.town = _t
		_d.roster = r
		_d.start_floor = 3
		_d.max_floors = 3
		_t.add_child(_d)
		_d.start(ids)
		_cam = Camera3D.new()
		_cam.fov = 50.0
		_t.add_child(_cam)
	if _f == 40:
		_d.set_process(false)
		for mo in _d.dun.monsters:
			(mo as Node3D).visible = false
			(mo as Node3D).set_process(false)
		if _d.dun.lord:
			_d.dun.lord.visible = false
		_place_set()
		_fire_at = _f + 30
	if _fire_at > 0 and _f == _fire_at:
		for i in 3:
			_d._meet_trap(_d.party[i], _traps[i], 0)
	for k in [6, 16, 30]:
		if _fire_at > 0 and _f == _fire_at + k:
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "/set%d_%02d.png" % [_set, k]))
	if _fire_at > 0 and _f == _fire_at + 40:
		_set += 1
		if _set >= SETS.size():
			print("L11_SHOT done")
			return true
		_place_set()
		_fire_at = _f + 30
	return false
