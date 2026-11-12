extends SceneTree
## L12 render: a lord floor with states showing - frightened at the rise, blinded by the swoop, potions drunk.
## by a chosen lord or unique (L2_WHO, default the Hollow King; a UNIQUES key
## makes it a unique on floor 7). Saves the name card, then four frames once the
## party is on it (the director follows the lord), to renders/cycles/20261111_l2.
var _t: Node3D
var _eye: RtsCamera
var _d: Delve
var _f := 0
var _close_at := -1
var _n := 0
var _who := ""
const OUT := "res://renders/cycles/20261111_l12"

func _initialize() -> void:
	_who = OS.get_environment("L2_WHO") if OS.get_environment("L2_WHO") != "" else "hollow_king"
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _process(_dt: float) -> bool:
	_f += 1
	if _f == 20:
		_eye = RtsCamera.new()
		_t.add_child(_eye)
		_eye.setup(_t)
		var r: Roster = _t.get("roster")
		var ids := []
		for v in [["2001", "JestFan", "knight"], ["2002", "MossyMage", "mage"], ["2003", "DawnCleric", "cleric"], ["2004", "BigAxe", "barbarian"]]:
			var h: Dictionary = r.get_hero(v[0])
			if h.is_empty():
				h = r.fresh(v[0], v[1], v[2])
			h["alive"] = true
			h["weapon"] = 3
			h["armour"] = 3
			h["oil"] = 4
			h["potions"] = 2
			h["brews"] = {"ogre": 1, "bravecup": 1, "antidote": 1}
			ids.append(v[0])
		var fl := 7
		if Bestiary.BOSS_DEFS.has(_who):
			var bag: Array = Bestiary.LESSER if Bestiary.LESSER.has(_who) else Bestiary.GREATER
			fl = 5 if Bestiary.LESSER.has(_who) else 10
			Bestiary._spent = bag.duplicate()
			Bestiary._spent.erase(_who)
		else:
			DungeonHD.force_unique = 0.0
			Bestiary.only_unique = _who
			if _who == "kept":
				r.fallen.push_front({"name": "Wren", "class": "ranger", "killed_by": "the dark below", "level": 3, "deepest": 6, "kills": 9, "day": 2})
		_d = Delve.new()
		_d.town = _t
		_d.roster = r
		_d.start_floor = fl
		_d.max_floors = fl
		_t.add_child(_d)
		_d.start(ids)
		_eye.director._set_on(true)
	if _f == 40:
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "/%s_card.png" % _who))
	if _d and _d.dun and _d.dun.lord and is_instance_valid(_d.dun.lord) and _close_at < 0:
		for m in _d.party:
			if _d._flat((m["body"] as Node3D).global_position, _d.dun.lord.global_position) < 14.0:
				_close_at = _f
	if _close_at > 0 and (_f - _close_at) % 110 == 100 and _n < 4:
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "/%s_fight_%d.png" % [_who, _n]))
		_n += 1
	if _n >= 4 or _f > 7000:
		DungeonHD.force_unique = -1.0
		Bestiary.only_unique = ""
		print("L2_SHOT done ", _who, " frames ", _n)
		return true
	return false
