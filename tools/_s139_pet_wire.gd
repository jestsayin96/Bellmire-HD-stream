extends SceneTree
## S139 / System 13 step 2 (wiring only, look untouched): does a hero's pet (HeroPet, dressed by
## Gear.dress_cosmetics off h.cos.pet) survive a real Delve? Four heroes; A and B carry pet_corgi (shipped), C/D carry none
## (so B's death does not trip the party's retreat).
##  (a) FLOOR: every _next_floor teleports the body to the new entry; 45 frames later the pet must
##      be within 3 m (flat) of its hero, same parent, one pet per body.
##  (b) REVIVE: hero A goes to 0 hp through the REAL Delve._hero_hit with the rng seeded to a
##      natural 20 - the death-save stand-up path. Pet must still be the same node, at heel.
##  (c) DEATH: hero B goes to 0 hp with its save spent - the real Death_A / fallen / roster.kill
##      path. The pet must not error, must stay with the corpse (not wander), and the party goes on.
## Run WITH a window (one shot at floor 2 + 45f). Prints S139_PET_WIRE OK/FAIL with its checks.
var _d: Delve
var _r: Roster
var _f := 0
var _cam: Camera3D
var _last_floor := -1
var _since := -1
var _fails := []
var _checks := 0
var _pet0 := {}
var _shot := false
var _revived := false
var _killed := false
var _post := -1

func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)
	var ids := []
	for v in [["9001", "PetProbeA", "knight"], ["9002", "PetProbeB", "barbarian"], ["9003", "PetProbeC", "cleric"], ["9004", "PetProbeD", "mage"]]:
		var h: Dictionary = _r.fresh(v[0], v[1], v[2])
		h["weapon"] = 2
		h["armour"] = 2
		h["oil"] = 4
		if v[0] in ["9001", "9002"]:
			h["cos"] = {"pet": "pet_corgi"}
		ids.append(v[0])
	_d = Delve.new()
	_d.roster = _r
	_d.max_floors = 3
	root.add_child(_d)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	root.add_child(sun)
	_cam = Camera3D.new()
	_cam.fov = 45.0
	root.add_child(_cam)
	_cam.make_current()
	_d.start(ids)

func _pets(b: Node) -> Array:
	var out := []
	for c in b.get_children():
		if c is HeroPet:
			out.append(c)
	return out

func _ck(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(what)
		print("S139 FAIL ", what)

func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

func _process(_dt: float) -> bool:
	_f += 1
	var a: Dictionary = _d.party[0]
	var bA: HeroBody = a["body"]
	if is_instance_valid(bA):
		_cam.global_position = bA.global_position + Vector3(0.5, 10.0, -3.5)
		_cam.look_at(bA.global_position + Vector3(0, 0.6, 0), Vector3.UP)
	if _f == 30:
		for m in _d.party.slice(0, 2):
			var ps := _pets(m["body"])
			_ck(ps.size() == 1, "%s has %d pets at spawn" % [m["h"]["name"], ps.size()])
			if ps.size() == 1:
				_pet0[m["uid"]] = ps[0]
				_ck((ps[0] as HeroPet).owner_body == m["body"], "%s pet owner_body" % m["h"]["name"])
				_ck((ps[0] as HeroPet)._ap != null, "%s pet has no AnimationPlayer (model failed)" % m["h"]["name"])
	if _d.floor_no != _last_floor and _d.dun:
		_last_floor = _d.floor_no
		_since = 0
	elif _since >= 0:
		_since += 1
	if _since == 45 and _f > 30:
		for m in _d._alive():
			if not _pet0.has(m["uid"]):
				continue
			var ps := _pets(m["body"])
			_ck(ps.size() == 1 and ps[0] == _pet0.get(m["uid"]), "floor %d %s pet count %d / same node" % [_d.floor_no, m["h"]["name"], ps.size()])
			if ps.size() == 1:
				var dd := _flat((ps[0] as Node3D).global_position, (m["body"] as Node3D).global_position)
				var dy := absf((ps[0] as Node3D).global_position.y - (m["body"] as Node3D).global_position.y)
				print("S139 floor %d %s pet %.2f m flat, %.2f m dy, visible=%s" % [_d.floor_no, m["h"]["name"], dd, dy, (ps[0] as Node3D).visible])
				_ck(dd < 3.0 and dy < 0.5, "floor %d %s pet left behind (%.2f m, dy %.2f)" % [_d.floor_no, m["h"]["name"], dd, dy])
		if _d.floor_no == _d.start_floor + 1 and not _shot:
			_shot = true
			print("S139 shot rc=", root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://renders/cycles/s139/floor2_pet.png")))
		if _d.floor_no == _d.start_floor + 1 and not _revived:
			_revived = true
			# (b) revive: the real death-save path, rng seeded to a natural 20
			var k := 0
			while k < 5000:
				_d._rng.seed = k
				var st := _d._rng.state
				if _d._rng.randi_range(1, 20) == 20:
					_d._rng.state = st
					break
				k += 1
			a["saved"] = false
			a["hp"] = 0.0
			_d._hero_hit(a)
			_ck(float(a["hp"]) > 0.0 and not bA.fallen, "revive: A did not stand (hp %.1f)" % float(a["hp"]))
			var b: Dictionary = _d.party[1]
			b["saved"] = true
			b["hp"] = 0.0
			_d._hero_hit(b)
			_killed = true
			_post = 0
			_ck((b["body"] as HeroBody).fallen, "death: B not fallen")
	if _post >= 0:
		_post += 1
	if _post == 75:
		var ps := _pets(bA)
		_ck(ps.size() == 1 and ps[0] == _pet0.get(a["uid"]), "after revive A pet same node")
		if ps.size() == 1:
			_ck(_flat((ps[0] as Node3D).global_position, bA.global_position) < 3.0, "after revive A pet at heel")
		var bB: HeroBody = _d.party[1]["body"]
		var pB := _pets(bB)
		_ck(pB.size() == 1 and is_instance_valid(pB[0]), "after death B pet gone/duplicated (%d)" % pB.size())
		if pB.size() == 1:
			var dd := _flat((pB[0] as Node3D).global_position, bB.global_position)
			print("S139 corpse pet %.2f m from fallen B, visible=%s" % [dd, (pB[0] as Node3D).visible])
			_ck(dd < 3.0, "death: B's pet wandered %.2f m" % dd)
	if _d.state == "home" or _f > 60 * 400:
		_ck(_d.floor_no >= _d.start_floor + 1, "delve never left floor %d" % _d.floor_no)
		_ck(_revived and _killed and _post >= 75, "revive/death arms never ran to their after-check (post %d)" % _post)
		_ck(_shot, "floor-2 shot never taken")
		if _fails.is_empty():
			print("S139_PET_WIRE OK checks=%d fails=0 floors=%d state=%s frames=%d" % [_checks, _d.floor_no, _d.state, _f])
		else:
			print("S139_PET_WIRE FAIL checks=%d fails=%d %s" % [_checks, _fails.size(), _fails])
		quit(0)
		return true
	return false
