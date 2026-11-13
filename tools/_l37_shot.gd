extends SceneTree
## L37: THE SCAR-VEINS, photographed on their own so they can be judged as veins rather than
## glimpsed in a room shot. Mr. E (19:27 recording): they read as "bright purple/cyan neon
## spaghetti looping across the floor rather than cracks in stone".
## Run windowed: --path . --resolution 1920x1080 --script tools/_l37_shot.gd
## L37_TAG=before|after names the files, so the same tool shoots both sides of the change.
## Veins only appear on deeper floors, so deep floors are what this shoots. It frames them from
## high and square-on, which is the view that makes continuous piping obvious if it is there -
## a flattering angle would be no evidence at all.
## Also PRINTS the count and the closest gap between any two veins, so "cut coverage" and "break
## up the curves" are numbers in the log and not just my opinion of a picture.
const OUT := "res://renders/cycles/20261113_l37"
var _host: Node3D
var _cam: Camera3D
var _we: WorldEnvironment
var _jobs: Array = []
var _f := 0
var _tag := "after"
var _pending := -1

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_tag = OS.get_environment("L37_TAG") if OS.get_environment("L37_TAG") != "" else "after"
	_we = WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.02, 0.02, 0.03)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.50, 0.50, 0.58)
	e.ambient_light_energy = 0.55
	e.tonemap_mode = Environment.TONE_MAPPER_AGX
	_we.environment = e
	root.add_child(_we)
	_cam = Camera3D.new()
	_cam.fov = 60.0
	root.add_child(_cam)
	_cam.make_current()
	# deep floors, where veins actually appear
	_jobs = [8, 11, 14]

func _process(_dt: float) -> bool:
	_f += 1
	if _f % 30 != 0:
		return false
	if _pending >= 0:
		var img := root.get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path("%s/f%d_%s.png" % [OUT, _pending, _tag]))
		print("L37_SHOT f%d_%s" % [_pending, _tag])
		_pending = -1
		return false
	if _jobs.is_empty():
		print("L37_SHOT done (%s)" % _tag)
		return true
	var fl: int = _jobs.pop_front()
	if _host:
		_host.free()
	_host = Node3D.new()
	root.add_child(_host)
	var d := DungeonHD.new()
	d.floor_no = fl
	_host.add_child(d)
	for m in d.monsters:
		(m as Node).queue_free()          # the veins, not the residents
	if d.lord:
		d.lord.queue_free()

	# count the veins and measure how close any two of them sit
	var pts: Array = []
	var st: Array = [d]
	while not st.is_empty():
		var n: Node = st.pop_back()
		# Count by a property, NOT by node name. Godot renames duplicate siblings, so only the
		# FIRST Decal_veins keeps that name and the rest become @Decal@NNN - a name match finds
		# exactly 1 every time no matter how many there are, which is what it did on my first
		# attempt and very nearly got reported as proof of a coverage cut.
		# texture_emission is set by the veins branch and by nothing else.
		if n is Decal and (n as Decal).texture_emission != null:
			pts.append((n as Decal).global_position)
		for c in n.get_children():
			st.append(c)
	var closest := 999.0
	for i in pts.size():
		for j in range(i + 1, pts.size()):
			closest = minf(closest, (pts[i] as Vector3).distance_to(pts[j] as Vector3))
	print("L37 floor %d [%s]: %d veins, closest pair %.1f m" % [fl, _tag, pts.size(), closest])

	# high and square-on: the view that would show continuous piping if it were there
	var lamp: Vector3 = d.info["lamp"]
	_cam.global_position = lamp + Vector3(0, 22, 14)
	_cam.look_at(lamp, Vector3.UP)
	# shoot on a LATER tick, not with an await inside _process - awaiting here silently ended
	# the loop after the first floor on the first attempt
	_pending = fl
	return false
