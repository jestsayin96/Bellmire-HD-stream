extends SceneTree
## S164 gate: the corpse-run bag BODY on the floor and the WALK-OVER (RULING sup-nov27-0209, slice 3
## engine side). Prints S164_BAGS OK n / S164_BAGS FAIL. Windowed, it also writes a picture of the bag.
var _fails := []
var _n := 0
var _d: Delve
var _r: Roster
var _f := 0
var _phase := 0
func _ok(c: bool, what: String) -> void:
	_n += 1
	if not c:
		_fails.append(what)
		print("  FAIL ", what)
func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)
	var a: Dictionary = _r.fresh("9001", "Fallen", "knight")
	_r.fresh("9002", "Other", "mage")
	a["gold"] = 50; a["potions"] = 1
	_r.kill("9001", "a rat", 1, 0)
	_ok(_r.bags.size() == 1 and int(a["gold"]) == 0, "setup: one bag of 50g on floor 1")
	_r.bags.append({"owner": "9002", "name": "Other", "floor": 1, "gold": 30, "potions": 0, "oil": 0,
		"t": int(Time.get_unix_time_from_system())})
	_r.bags.append({"owner": "9002", "name": "Other", "floor": 1, "gold": 0, "potions": 0, "oil": 0,
		"t": int(Time.get_unix_time_from_system())})        # empty: no body
	_r.bags.append({"owner": "9002", "name": "Other", "floor": 2, "gold": 9, "potions": 0, "oil": 0,
		"t": int(Time.get_unix_time_from_system())})        # other floor: no body here
	_d = Delve.new()
	_d.roster = _r
	_d.max_floors = 1
	root.add_child(_d)
	_d.start(["9001"])
func _process(_dt: float) -> bool:
	_f += 1
	if _f == 5:
		_d.state = "hold"     # the test moves the body itself; nobody walks over a bag by accident
		_ok(_d.dun != null and _d.floor_no == 1, "on floor 1")
		_ok(_d.bag_nodes.size() == 2, "two bodies laid (own + other's), not the empty or floor-2 bag: %d" % _d.bag_nodes.size())
		for bn in _d.bag_nodes:
			var nd: Node3D = bn["node"]
			var loc := nd.global_position - _d.dun.global_position
			_ok(_d.dun._on_floor(loc) and _d.dun._in_reach(loc), "bag body on a reachable floor cell %s" % loc)
			_ok(absf(nd.global_position.y - _d.dun.global_position.y) < 0.01, "bag sits at floor height")
			_ok(nd.get_child_count() >= 1, "bag body has a model")
		var mine: Node3D = null
		var theirs: Node3D = null
		for bn in _d.bag_nodes:
			if String(bn["bag"]["owner"]) == "9001":
				mine = bn["node"]
			else:
				theirs = bn["node"]
		if DisplayServer.get_name() != "headless" and mine != null:
			var cam := Camera3D.new()
			_d.dun.add_child(cam)
			cam.global_position = mine.global_position + Vector3(2.2, 1.6, 2.2)
			cam.look_at(mine.global_position + Vector3(0, 0.3, 0))
			cam.current = true
			var lt := OmniLight3D.new()
			lt.omni_range = 8.0
			lt.light_energy = 3.0
			_d.dun.add_child(lt)
			lt.global_position = mine.global_position + Vector3(1, 2.5, 1)
		var body: Node3D = _d.party[0]["body"]
		# out of reach: nothing happens
		_d._bags_tick()
		_ok(_r.bags.size() == 4 or _flat_near(body, mine, theirs), "nothing taken from the entry unless standing on it")
		set_meta("mine", mine); set_meta("theirs", theirs)
	if _f == 40:
		var mine: Node3D = get_meta("mine")
		var theirs: Node3D = get_meta("theirs")
		if DisplayServer.get_name() != "headless":
			var img := root.get_viewport().get_texture().get_image()
			img.save_png("res://renders/cycles/s164/bag_on_floor.png")
			print("WROTE renders/cycles/s164/bag_on_floor.png")
		var body: Node3D = _d.party[0]["body"]
		# someone else's inside the hour: seen, not taken
		body.global_position = theirs.global_position
		_d._bags_tick()
		_ok(is_instance_valid(theirs) and _d.bag_nodes.size() == 2 and _d.bags_taken.is_empty(), "other's bag inside the hour stays")
		# own bag: walked over, taken back
		body.global_position = mine.global_position
		_d._bags_tick()
		var h: Dictionary = _r.get_hero("9001")
		_ok(int(h["gold"]) == 50 and int(h["potions"]) >= 1, "owner takes back 50g + potion, gold %d" % int(h["gold"]))
		_ok(_d.bag_nodes.size() == 1 and not _d.bags_taken.is_empty(), "own bag body gone after pickup: %d left" % _d.bag_nodes.size())
		# the other's after the hour: finders keepers
		for b in _r.bags:
			if String(b["owner"]) == "9002" and int(b["floor"]) == 1:
				b["t"] = int(b["t"]) - 3601
		body.global_position = theirs.global_position
		_d._bags_tick()
		_ok(int(h["gold"]) == 80 and _d.bag_nodes.is_empty(), "finders keepers after the hour: gold %d" % int(h["gold"]))
		_ok(_r.bags.size() == 1 and int(_r.bags[0]["floor"]) == 2, "floor-2 bag untouched, empty floor-1 bag swept with the take")
		# mid-floor drop: a body where they fell
		h["gold"] = 12
		_r.drop_bag("9001", 1)
		var nb := _d._bag_body(_r.bags.back(), body.global_position + Vector3(0.3, 0, 0))
		_ok(nb != null and _d.bag_nodes.size() == 1, "mid-floor drop lays a body")
		_ok(_d._bag_body({"gold": 0, "potions": 0, "oil": 0}, body.global_position) == null, "empty bag: no body")
		if _fails.is_empty():
			print("S164_BAGS OK %d checks" % _n)
		else:
			print("S164_BAGS FAIL %d of %d: %s" % [_fails.size(), _n, str(_fails)])
		quit(0 if _fails.is_empty() else 1)
		return true
	return false
func _flat_near(body: Node3D, a: Node3D, b: Node3D) -> bool:
	for n in [a, b]:
		if n != null and Vector2(body.global_position.x - n.global_position.x, body.global_position.z - n.global_position.z).length() <= Delve.BAG_REACH:
			return true
	return false
