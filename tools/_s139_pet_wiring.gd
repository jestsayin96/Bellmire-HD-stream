extends SceneTree
## S139 / System 13 (pet companions) step 2, THE WIRING HALF ONLY. The look is routed up, not
## settled here. A KayKit Knight stands in a host Node3D exactly as delve's HeroBody holds its model
## (Gear.dress_cosmetics hangs the HeroPet on model_root.get_parent()). Through the REAL
## Gear.dress_cosmetics with cos.pet = pet_corgi (shipped), plus a UAA fox on HeroPet directly:
##   A heel      - host walks 4 m; pet ends near its heel spot
##   B floor     - host teleported the way delve._next_floor moves a body (lane*700, DELVE_Y=-400);
##                 pet must be at the new floor within 3 frames, same y as the host
##   C death     - host plays Death_A (delve: Rig.play Death_A, b.fallen = true, body stays):
##                 pet stays alive, beside the body, visible
##   D revive    - death save stands them back up; then a re-dress (dress_cosmetics again):
##                 exactly ONE pet on the host, not two
##   E re-roll   - the fallen body is freed: its pet goes with it (no orphan pet)
## Also prints a STYLE line per pet (tris, textured surfaces, mean albedo) - numbers for the
## look question, which is NOT decided here. Shot renders/cycles/s139/pet_wiring.png.
## Run WITH a window. Prints S139_PET_WIRING OK/FAIL.
const ADV := "res://addons/kaykit_character_pack_adventures/Characters/gltf/"
var _f := 0
var _host: Node3D
var _kn: Node3D
var _uhost: Node3D
var _upet: HeroPet
var _fails := []
var _cam: Camera3D

func _pets_on(h: Node) -> Array:
	var out := []
	for c in h.get_children():
		if c is HeroPet and not c.is_queued_for_deletion():
			out.append(c)
	return out

func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

func _initialize() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.62, 0.7)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.6, 0.6)
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	root.add_child(sun)
	for at in [Vector3.ZERO, Vector3(700, -400, 0)]:
		var fl := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(60, 60)
		fl.mesh = pm
		var fm := StandardMaterial3D.new()
		fm.albedo_color = Color(0.42, 0.5, 0.33)
		fl.material_override = fm
		fl.position = at
		root.add_child(fl)
	_host = Node3D.new()
	root.add_child(_host)
	_kn = (load(ADV + "Knight.glb") as PackedScene).instantiate()
	_host.add_child(_kn)
	Gear.dress_cosmetics(_kn, {"cos": {"pet": "pet_corgi"}})
	_uhost = Node3D.new()
	_uhost.position = Vector3(3, 0, 0)
	root.add_child(_uhost)
	var uk: Node3D = (load(ADV + "Knight.glb") as PackedScene).instantiate()
	_uhost.add_child(uk)
	_upet = HeroPet.new()
	_upet.owner_body = _uhost
	_upet.model = "res://assets/animals/uaa/Fox.gltf"
	_upet.scale_f = 0.15
	_uhost.add_child(_upet)
	_cam = Camera3D.new()
	_cam.fov = 40.0
	root.add_child(_cam)
	_aim(Vector3(1.5, 0, 0))

func _aim(c: Vector3) -> void:
	var eye := c + Vector3(0, 2.6, 8.5)
	_cam.transform = Transform3D(Basis.looking_at(c + Vector3(0, 0.6, 0) - eye, Vector3.UP), eye)
	_cam.make_current()

func _anim_of(n: Node) -> AnimationPlayer:
	var st: Array = [n]
	while not st.is_empty():
		var c: Node = st.pop_back()
		if c is AnimationPlayer:
			return c
		for g in c.get_children():
			st.append(g)
	return null

func _style(tag: String, n: Node) -> void:
	var tris := 0
	var tex := 0
	var surf := 0
	var col := Color(0, 0, 0)
	var st: Array = [n]
	while not st.is_empty():
		var c: Node = st.pop_back()
		if c is MeshInstance3D and (c as MeshInstance3D).mesh:
			var m: Mesh = (c as MeshInstance3D).mesh
			for s in m.get_surface_count():
				surf += 1
				var a: Array = m.surface_get_arrays(s)
				var idx = a[Mesh.ARRAY_INDEX]
				tris += (idx.size() if idx != null else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
				var mat := (c as MeshInstance3D).get_active_material(s)
				if mat is BaseMaterial3D:
					col += (mat as BaseMaterial3D).albedo_color
					if (mat as BaseMaterial3D).albedo_texture != null:
						tex += 1
		for g in c.get_children():
			st.append(g)
	if surf > 0:
		col /= float(surf)
	print("S139_STYLE %s tris=%d surfaces=%d textured=%d mean_albedo=(%.2f,%.2f,%.2f) sat=%.2f" % [tag, tris, surf, tex, col.r, col.g, col.b, col.s])

func _check(ok: bool, what: String) -> void:
	print("S139_PET_WIRING %s %s" % ["pass" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)

func _process(_d: float) -> bool:
	_f += 1
	var pets := _pets_on(_host)
	var pet: HeroPet = pets[0] if pets.size() > 0 else null
	if _f == 5:
		_check(pets.size() == 1 and pet._ap != null, "dress: real Gear.dress_cosmetics hung 1 HeroPet (pet_corgi) with a rig")
		_style("knight(host)", _kn)
		if pet:
			_style("pet_corgi(shipped)", pet)
		_style("fox_uaa", _upet)
	if _f > 5 and _f <= 125:
		_host.position.x = -4.0 * float(_f - 5) / 120.0
		_uhost.position.x = 3.0 - 4.0 * float(_f - 5) / 120.0
	if _f == 200:
		_check(pet != null and _flat(pet.global_position, pet._spot()) < 0.6, "A heel: corgi %.2f m off its spot after a 4 m walk" % (_flat(pet.global_position, pet._spot()) if pet else -1.0))
		_check(_flat(_upet.global_position, _upet._spot()) < 0.6, "A heel: uaa fox %.2f m off its spot" % _flat(_upet.global_position, _upet._spot()))
		var out := ProjectSettings.globalize_path("res://renders/cycles/s139/heel.png")
		DirAccess.make_dir_recursive_absolute(out.get_base_dir())
		print("S139_PET_WIRING shot heel rc=", root.get_texture().get_image().save_png(out))
		# B: the floor change, as delve._next_floor moves a body
		_host.global_position = Vector3(700, -400, 0)
		_uhost.global_position = Vector3(702, -400, 0)
		_aim(Vector3(701, -400, 0))
	if _f == 203:
		_check(pet != null and _flat(pet.global_position, pet._spot()) < 0.6 and absf(pet.global_position.y - _host.global_position.y) < 0.01, "B floor: corgi at the new floor 3 frames after a 700 m / -400 m jump (%.2f m off, dy %.2f)" % [_flat(pet.global_position, pet._spot()), pet.global_position.y - _host.global_position.y])
		_check(_flat(_upet.global_position, _upet._spot()) < 0.6 and absf(_upet.global_position.y + 400.0) < 0.01, "B floor: uaa fox at the new floor")
		var ap := _anim_of(_kn)
		if ap and ap.has_animation("Death_A"):
			ap.play("Death_A")
		else:
			_check(false, "C death: Knight has no Death_A clip")
	if _f == 260:
		_check(pet != null and is_instance_valid(pet) and pet.is_visible_in_tree() and _flat(pet.global_position, pet._spot()) < 0.6, "C death: corgi stays, visible, beside the fallen body")
		var out := ProjectSettings.globalize_path("res://renders/cycles/s139/death.png")
		print("S139_PET_WIRING shot death rc=", root.get_texture().get_image().save_png(out))
		# D: the death save stands them up, and the body is re-dressed
		var ap := _anim_of(_kn)
		if ap and ap.has_animation("Idle"):
			ap.play("Idle")
		Gear.dress_cosmetics(_kn, {"cos": {"pet": "pet_corgi"}})
		Gear.dress_cosmetics(_kn, {"cos": {"pet": "pet_corgi"}})
	if _f == 264:
		_check(pets.size() == 1, "D revive: re-dressed twice, %d HeroPet on the host (want 1)" % pets.size())
		_check(pet != null and _flat(pet.global_position, pet._spot()) < 0.6, "D revive: the new pet starts at heel, not at the origin")
		_uhost.queue_free()      # E: a re-rolled hero's old body goes
	if _f == 268:
		_check(not is_instance_valid(_upet), "E re-roll: the freed body took its pet with it")
		if _fails.is_empty():
			print("S139_PET_WIRING OK heel, floor change, death, revive re-dress and re-roll all hold")
		else:
			print("S139_PET_WIRING FAIL ", _fails)
		return true
	return false
