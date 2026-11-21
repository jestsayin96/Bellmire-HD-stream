extends SceneTree
## S85 diagnostic (game build): L29C arm C soak stalls in state=fight on floor 3 after
## "The slime divides." Replays the same soak and dumps foes + party when stalled.
var _r: Roster
var _d: Delve
var _f := 0
var _last_state := ""
var _fight_since := 0

func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)
	var ids: Array = []
	for v in [["29c1", "Aen", "knight"], ["29c2", "Bram", "mage"], ["29c3", "Corvin", "cleric"], ["29c4", "Doria", "barbarian"]]:
		var hh: Dictionary = _r.fresh(v[0], v[1], v[2])
		hh["oil"] = 12
		ids.append(v[0])
	_d = Delve.new()
	_d.roster = _r
	_d.max_floors = 8
	_d.start_floor = 2
	root.add_child(_d)
	Delve.setpieces_fired.clear()
	_d.start(ids)

func _dump(tag: String) -> void:
	print("S85_DUMP %s frame=%d floor=%d state=%s back_to=%s" % [tag, _f, _d.floor_no, _d.state, _d._back_to])
	for mon in _d.dun.monsters:
		if not is_instance_valid(mon):
			print("   mon <freed>")
			continue
		var m: Monster = mon
		print("   mon %s state=%d hp=%.1f/%.1f pos=%s in_tree=%s cell=%s target=%s" % [
			String(m.def.get("name", "?")), m.state, m.hp, m.max_hp, m.global_position, m.is_inside_tree(),
			_d._cell_of(m.global_position), m.target])
	for p in _d.party:
		var b: Node3D = p["body"]
		print("   hero %s hp=%.1f pos=%s cell=%s" % [String(p["uid"]), float(p["hp"]), b.global_position, _d._cell_of(b.global_position)])

func _process(_dt: float) -> bool:
	_f += 1
	if _d.state != _last_state:
		print("S85 frame=%d floor=%d %s -> %s fired=%s" % [_f, _d.floor_no, _last_state, _d.state, Delve.setpieces_fired])
		_last_state = _d.state
		_fight_since = _f
	if _d.state == "fight" and _f - _fight_since in [5400, 10800]:
		_dump("stalled")
	if _d.state == "home" or _f > 60 * 420:
		_dump("end")
		print("S85 fired=%s" % [Delve.setpieces_fired])
		print("S85_DIAG DONE")
		return true
	return false
