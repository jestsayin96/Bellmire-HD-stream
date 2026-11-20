extends SceneTree
## S62_PROPS - System 47 batch 2 (on top of batch 1): thirty-six whole-pack dungeon props (assets/props + assets/dungeon) on
## the floor, each set on its own base by art's SIGNED base_dz_m. Windowed, quits itself:
##   <console> --path . --resolution 1920x1080 --script tools/_s62_props.gd
## Prints S62_PROPS OK n=<checks> | S62_PROPS FAIL <what> | S62_PROPS NO VERDICT.
## (1) every PROP_BATCH number == art's manifest row, read live; (2) every piece drawn in the engine has
## its lowest visible vertex on its holder's floor (|gap| < 2 cm) - that is the sign test, and it covers
## a sinker past 5 cm (Fence -0.9991) and the floater (Workbench_Drawers +0.8842); (3) floors 1..24 place
## batch pieces in every theme, every one on a floor cell, none resting off the floor.
## S62_RED=1 turns on the single-sign shift (lift by |dz|): the floater must leave the floor -> FAIL.
var _fails: Array = []
var _checks := 0
var _f := 0
var _red := false
var _cam: Camera3D
const OUT := "res://renders/cycles/s62/"
const NEW2 := ["res://assets/dungeon/Pedestal2.glb", "res://assets/props/Anvil_Log.gltf", "res://assets/props/Barrel_Apples.gltf",
	"res://assets/props/Barrel_Holder.gltf", "res://assets/props/Bed_Twin1.gltf", "res://assets/props/Bag.gltf", "res://assets/props/Chair_1.gltf",
	"res://assets/props/Nightstand_Shelf.gltf", "res://assets/props/Shelf_Small_Bottles.gltf", "res://assets/props/Whetstone.gltf",
	"res://assets/props/Workbench.gltf", "res://assets/props/Vase_2.gltf", "res://assets/props/Vase_4.gltf", "res://assets/props/FarmCrate_Carrot.gltf",
	"res://assets/props/Bucket_Metal.gltf", "res://assets/props/Pot_1_Lid.gltf"]
const MAN := "res://renders/art/worldfit/_manifest.json"

func _ok(c: bool, what: String) -> void:
	_checks += 1
	if not c:
		print("  FAIL %s" % what)
		_fails.append(what)
	else:
		print("  ok   %s" % what)

func _low(n: Node) -> float:
	var lo := INF
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var a: AABB = m.global_transform * m.get_aabb()
		lo = minf(lo, a.position.y)
	return lo

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_red = OS.get_environment("S62_RED") == "1"
	DungeonHD.batch_red_single_sign = _red
	if _red:
		print("  S62_RED: single-sign shift on")
	var man = JSON.parse_string(FileAccess.get_file_as_string(MAN))
	_ok(man is Dictionary, "art's manifest parses")
	var rows := {}
	if man is Dictionary:
		for dk in ["assets/props", "assets/dungeon"]:
			for r in man["dirs"][dk]["rows"]:
				rows["res://%s/%s" % [dk, r["file"]]] = r
	_ok(DungeonHD.PROP_BATCH.size() == 36, "batch size %d == 20 (batch 1) + 16 (batch 2)" % DungeonHD.PROP_BATCH.size())
	var miss2 := []
	for p in NEW2:
		if not DungeonHD.PROP_BATCH.has(p):
			miss2.append(p.get_file())
	_ok(miss2.is_empty(), "all 16 batch-2 pieces are in PROP_BATCH %s" % str(miss2))
	var copy_bad := []
	for p in DungeonHD.PROP_BATCH:
		var r: Dictionary = rows.get(p, {})
		var v: Array = DungeonHD.PROP_BATCH[p]
		if r.is_empty() or not is_equal_approx(float(v[0]), float(r["base_dz_m"])) or not is_equal_approx(float(v[1]), float(r["footprint_m"])) \
				or r["corridor"] != "CORRIDOR-SAFE" or r["lid"] != "UNDER-LID":
			copy_bad.append(p.get_file())
	_ok(copy_bad.is_empty(), "every base_dz_m / footprint_m copied == manifest, all CORRIDOR-SAFE + UNDER-LID %s" % str(copy_bad))
	var used := {}
	for t in DungeonHD.THEME_BATCH:
		for p in DungeonHD.THEME_BATCH[t]:
			used[p] = true
	_ok(used.size() == DungeonHD.PROP_BATCH.size(), "every batch piece is in a theme row (%d/%d)" % [used.size(), DungeonHD.PROP_BATCH.size()])
	# (2) line-up: each piece on its holder at y = 0, in the engine
	var stage := Node3D.new(); root.add_child(stage)
	var fl := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(90, 40); fl.mesh = pm
	var fm := StandardMaterial3D.new(); fm.albedo_color = Color(0.35, 0.3, 0.26); fl.material_override = fm
	stage.add_child(fl)
	var x := -33.0
	var x1 := -35.15
	var bad := []
	var keys: Array = DungeonHD.PROP_BATCH.keys()
	keys.sort()
	for p in keys:
		var h := DungeonHD.batch_piece(p)
		if h == null:
			bad.append(p.get_file() + " null")
			continue
		if p in NEW2:
			h.position = Vector3(x, 0, 0)
			x += 4.4
		else:
			h.position = Vector3(x1, 0, -12)
			x1 += 3.7
		stage.add_child(h)
		var gap := _low(h)
		var dz := float(DungeonHD.PROP_BATCH[p][0])
		var sg := "FLOATS" if dz > 0.05 else ("SINKS" if dz < -0.05 else "")
		if sg != "":
			print("  MEASURED %s dz %+.4f (%s) lowest vertex %+.4f m vs floor" % [p.get_file(), dz, sg, gap])
		if absf(gap) > 0.02:
			bad.append("%s gap %+.3f" % [p.get_file(), gap])
	_ok(bad.is_empty(), "all %d pieces rest on the floor within 2 cm %s" % [keys.size(), str(bad)])
	# (3) floors
	if not _red:
		var per := {}
		var offc := 0
		var offy := 0
		var total := 0
		for n in range(1, 25):
			var d := DungeonHD.new(); d.floor_no = n
			root.add_child(d)
			var th := String(d.info.get("theme", ""))
			var cells: Dictionary = d.info["cells"]
			var rt: Node3D = d.info["root"]
			for ch in rt.get_children():
				if not ch.has_meta("batch_path"):
					continue
				total += 1
				per[th] = int(per.get(th, 0)) + 1
				var lp: Vector3 = rt.to_local((ch as Node3D).global_position)
				var G: float = d.info["grid"]
				var hw := (float(d.info["w"]) - 1.0) * G * 0.5
				var hh := (float(d.info["h"]) - 1.0) * G * 0.5
				var cc := Vector2i(roundi((lp.x + hw) / G), roundi((lp.z + hh) / G))
				if not cells.has(cc):
					offc += 1
				if absf(_low(ch) - (ch as Node3D).global_position.y) > 0.02:
					offy += 1
			_ok(int(d.info.get("batch_props", -1)) >= 1, "f%d %s placed %d batch pieces" % [n, th, int(d.info.get("batch_props", -1))])
			root.remove_child(d); d.free()
		print("  batch pieces per theme over floors 1..24: %s (total %d)" % [str(per), total])
		_ok(per.size() == DungeonHD.THEME_BATCH.size() and DungeonHD.THEME_BATCH.size() == FloorGen.all_themes().size(), "every theme AND biome drew batch pieces (%d/%d rows, %d in FloorGen)" % [per.size(), DungeonHD.THEME_BATCH.size(), FloorGen.all_themes().size()])
		_ok(offc == 0, "no batch piece off the floor cells (%d)" % offc)
		_ok(offy == 0, "no batch piece resting off its base on a real floor (%d)" % offy)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-40, 25, 0); root.add_child(sun)
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.2, 0.22, 0.26)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color(0.7, 0.7, 0.75)
	root.add_child(env)
	_cam = Camera3D.new(); _cam.fov = 32.0; root.add_child(_cam)
	_cam.look_at_from_position(Vector3(0, 3.0, 66), Vector3(0, 0.6, -4))

func _process(_d: float) -> bool:
	_f += 1
	if _f == 2:
		_run()
	if _f == 40:
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + ("s62_red.png" if _red else "s62_props.png")))
		if _checks == 0:
			print("S62_PROPS NO VERDICT")
		elif _fails.is_empty():
			print("S62_PROPS OK n=%d" % _checks)
		else:
			print("S62_PROPS FAIL %s" % "; ".join(_fails))
		quit()
	return false
