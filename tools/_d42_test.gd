extends SceneTree
## D42 TEST. Boots the real Town with a roaming director camera and soaks, then
## checks the two sounds the town was missing now FIRE: footsteps (Townsfolk,
## surface-aware) and animal voices (Animal, a horse among them). Headless -
## audio is counted, not heard: Sfx.live().plays + Animal.voices. Env D42_SECS
## (wall seconds of soak, default 60), D42_SCALE (time scale, default 8).
var _t: Node3D
var _eye
var _f := 0
var _t0 := 0
var _secs := 60.0
var _scale := 8.0

func _initialize() -> void:
	var s := OS.get_environment("D42_SECS")
	if s != "": _secs = maxf(5.0, float(s))
	var sc := OS.get_environment("D42_SCALE")
	if sc != "": _scale = maxf(1.0, float(sc))
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	print("D42_TEST start secs=%.0f scale=%.0f" % [_secs, _scale])

func _process(_dt: float) -> bool:
	_f += 1
	if _f == 20:
		var RtsCam = load("res://scripts/rts_camera.gd")
		_eye = RtsCam.new(); _t.add_child(_eye); _eye.setup(_t)
	if _f == 40:
		if _eye and _eye.director: _eye.director._set_on(true)
		Engine.time_scale = _scale
		_t0 = Time.get_ticks_msec()
	if _f < 40:
		return false
	if Time.get_ticks_msec() - _t0 < int(_secs * 1000.0):
		return false
	_report()
	return true

func _report() -> void:
	Engine.time_scale = 1.0
	var sfx = Sfx.live()
	var plays: Dictionary = sfx.plays if sfx else {}
	var foot := 0
	var by := {}
	for k in ["footstep_grass", "footstep_stone", "footstep_wood", "footstep_water"]:
		var n := int(plays.get(k, 0))
		by[k] = n
		foot += n
	var av: Dictionary = Animal.voices
	var horse := int(av.get("horse_neigh", 0)) + int(av.get("horse_whinny", 0))
	var dog := int(av.get("dog_bark", 0)) + int(av.get("dog_whine", 0))
	var anim_total := 0
	for k in av: anim_total += int(av[k])
	print("D42 footsteps total=%d  %s" % [foot, by])
	print("D42 animal voices total=%d  horse=%d dog=%d  %s" % [anim_total, horse, dog, av])
	var ok := foot > 0 and anim_total > 0 and horse > 0
	print("D42_TEST %s (footsteps>0:%s animals>0:%s horse>0:%s)" % ["OK" if ok else "FAIL", foot > 0, anim_total > 0, horse > 0])
