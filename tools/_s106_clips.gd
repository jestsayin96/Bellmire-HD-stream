extends SceneTree
## S106: prove the two animal.gd clip-selection traps are fixed without moving
## any shipped animal. For every model under assets/animals/ the Animal picks
## its idle / walk / run; a pick containing "HitReact" or "Death" is a FAIL.
## Prints one verdict line: S106_CLIPS OK <n> / S106_CLIPS FAIL ...
## An EMPTY idle is also a FAIL - the first draft of this gate read the picks
## before _ready ran and passed 9 of 9 on nothing.
var _as: Array = []
var _f := 0

func _initialize() -> void:
	var paths: Array = []
	_walk_dir("res://assets/animals", paths)
	paths.sort()
	for p in paths:
		var a: Node3D = load("res://scripts/animal.gd").new()
		a.process_mode = Node.PROCESS_MODE_DISABLED
		a.set("model", p)
		root.add_child(a)
		_as.append([p, a])

func _process(_d: float) -> bool:
	_f += 1
	if _f < 3:
		return false
	var bad := 0
	var n := 0
	for pa in _as:
		var p: String = pa[0]
		var a: Node3D = pa[1]
		var idle: String = a.get("_idle")
		var walk: String = a.get("_walk")
		var run: String = a.get("_run")
		var flag := ""
		if idle == "":
			flag = "  <-- EMPTY IDLE"
		for c in [idle, walk, run]:
			if c.find("HitReact") >= 0 or c.find("Death") >= 0:
				flag = "  <-- BAD"
		if flag != "":
			bad += 1
		n += 1
		var idles: Array = []
		var ap: AnimationPlayer = a.get("_ap")
		if ap:
			for an in ap.get_animation_list():
				if String(an).begins_with("Idle"):
					idles.append(String(an))
		var was: String = idles[-1] if idles.size() > 0 else ""
		print("S106 ", p.get_file(), " idle=", idle, " walk=", walk, " run=", run,
				" | Idle-prefixed=", idles, " old-pick=", was, flag)
	if n == 0:
		print("S106_CLIPS FAIL no models found")
	elif bad > 0:
		print("S106_CLIPS FAIL ", bad, " of ", n)
	else:
		print("S106_CLIPS OK ", n, " models, 0 hit-react/death picks")
	quit()
	return true

func _walk_dir(d: String, out: Array) -> void:
	var da := DirAccess.open(d)
	if da == null:
		return
	for f in da.get_files():
		if f.ends_with(".glb") or f.ends_with(".gltf"):
			out.append(d + "/" + f)
	for sd in da.get_directories():
		_walk_dir(d + "/" + sd, out)
