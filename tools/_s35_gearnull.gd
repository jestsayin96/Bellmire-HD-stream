extends SceneTree
## S35_GEARNULL - Gear.equip never instantiates a null. Headless:
## <console> --headless --path . --script tools/_s35_gearnull.gd
## A resource that EXISTS but is not a PackedScene (here a texture; in the wild an un-imported
## gltf whose load() returns null) must make equip() return null and leave NO eq_<slot> node.
## A real .gltf weapon must still attach. S35_RED=1 replays the pre-S35 unguarded cast, which must
## print FAIL (it records a null where a Node3D was required).
## Prints S35_GEARNULL OK <n> checks | S35_GEARNULL FAIL ...
var _fails: Array = []
var _checks := 0

func _ok(c: bool, what: String) -> void:
	_checks += 1
	if not c:
		print("  FAIL ", what)
		_fails.append(what)

func _rig() -> Node3D:
	var root := Node3D.new()
	var sk := Skeleton3D.new()
	sk.add_bone("handslot.r")
	root.add_child(sk)
	get_root().add_child(root)
	return root

func _init() -> void:
	var bad := "res://icon.svg"
	_ok(ResourceLoader.exists(bad), "the bad path exists (%s)" % bad)
	_ok(not (load(bad) is PackedScene), "the bad path is not a PackedScene")
	var r1 := _rig()
	if OS.get_environment("S35_RED") == "1":
		var ps := load(bad) as PackedScene
		_ok(ps != null, "RED: pre-S35 cast of a non-scene is non-null")
	else:
		var m: Node3D = Gear.equip(r1, bad)
		_ok(m == null, "equip(bad) returns null")
		_ok(Gear.skeleton(r1).get_node_or_null("eq_weapon") == null, "equip(bad) leaves no eq_weapon node")
		_ok(not Gear._cache.has(bad), "equip(bad) leaves no cached null")
	var good := ""
	if true:
		var d := DirAccess.open(Gear.KIT)
		if d:
			for f in d.get_files():
				if f.ends_with(".gltf") or f.ends_with(".glb"):
					if ResourceLoader.exists(Gear.KIT + f) and load(Gear.KIT + f) is PackedScene:
						good = Gear.KIT + f
						break
	_ok(good != "", "found a real weapon scene to attach")
	if good != "":
		var r2 := _rig()
		var g: Node3D = Gear.equip(r2, good)
		_ok(g != null, "equip(%s) attaches" % good)
		_ok(Gear.skeleton(r2).get_node_or_null("eq_weapon") != null, "real weapon leaves eq_weapon")
	if _fails.is_empty() and _checks >= 4:
		print("S35_GEARNULL OK %d checks" % _checks)
	else:
		print("S35_GEARNULL FAIL %d of %d" % [_fails.size(), _checks])
	quit(0 if _fails.is_empty() else 1)
