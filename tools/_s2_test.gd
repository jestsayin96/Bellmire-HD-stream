extends SceneTree
## S2: the laptop's sound wiring uses only REGISTERED kinds (Sfx.SETS), and the events sound.
##  1. static: every kind named in the wired files (Sfx.at / Sfx.play / _snd string literals),
##     every table (Bestiary.VOICES / FAMILY_VOICE, Spells.SOUND, Delve.AMB_KINDS, the hero
##     voices, ChatCmd.ui_kinds' answers) and every creature's resolved voice - each ordinary
##     creature, every lord, every unique - is a key of Sfx.SETS. No creature is voiceless.
##  2. live: a real town (Sfx running) and a real delve on a lord floor with a knight, a ranger,
##     a rogue and a cleric. After the fight: everything Sfx actually played is registered, and
##     the swing, a hit, the bow, a creature's voice, the lord's arrival roar, a delver's voice
##     and a spell were all heard. Chat: !inventory opens the pack, a typo errors, a buy chinks.
## Prints S2_TEST OK / FAIL.
var _t: Node3D
var _d: Delve
var _f := 0
var _fails: Array = []
var _checks := 0
var _lord_v := ""
const FILES := ["res://scripts/monster.gd", "res://scripts/bestiary.gd", "res://scripts/delve.gd", "res://scripts/chatcmd.gd", "res://scripts/roster.gd"]
const IDS := ["2901", "2902", "2903", "2904"]

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _reg(k: String) -> bool:
	return Sfx.SETS.has(k)

func _initialize() -> void:
	_static()
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)

## ---------------------------------------------------------------- 1. static
func _static() -> void:
	var bad: Array = []
	var named := 0
	var rx := RegEx.new()
	rx.compile("(?:Sfx\\.(?:at|play)|_snd)\\(\"([a-z_]+)\"")
	for p in FILES:
		var src := FileAccess.get_file_as_string(p)
		for m in rx.search_all(src):
			named += 1
			if not _reg(m.get_string(1)):
				bad.append("%s: %s" % [p.get_file(), m.get_string(1)])
	_ok(named >= 10 and bad.is_empty(), "every literal Sfx kind in the wired files is registered (%d named, bad: %s)" % [named, bad])
	var tables: Array = []
	for pair in Bestiary.VOICES:
		tables.append(String(pair[1]))
	tables.append_array(Bestiary.FAMILY_VOICE.values())
	tables.append_array(Spells.SOUND.values())
	tables.append_array(Delve.AMB_KINDS)
	for v in ["male", "female"]:
		for w in ["hurt", "death", "effort"]:
			tables.append("%s_%s" % [v, w])
	for c in [["inventory", "x"], ["brew", "ok"], ["forge", "ok"], ["oil", "ok"], ["hero", "ok"], ["forge", "Ash needs 60 gold - you have 3."], ["zz", "No !zz here - did you mean !hero?"]]:
		tables.append_array(ChatCmd.ui_kinds(c[0], c[1]))
	tables.append_array(["dragon_fire_breath", "level_up", "chest_open", "potion_drink", "arrow_shot", "hit_impact", "block", "shield_bash"])
	var tb: Array = tables.filter(func(k): return not _reg(String(k)))
	_ok(tb.is_empty(), "every kind in the sound tables is registered (%d, bad: %s)" % [tables.size(), tb])
	# every creature has a registered voice
	var mute: Array = []
	var who := {}
	for k in Bestiary.TYPES:
		who["type " + k] = Bestiary.make(k)
	for k in Bestiary.NEW_TYPES:
		who["new " + k] = Bestiary.make(k)
	for k in Bestiary.BOSS_DEFS:
		var b: Dictionary = (Bestiary.BOSS_DEFS[k] as Dictionary).duplicate()
		b["id"] = k
		who["lord " + k] = Bestiary.boss_def(b)
	for k in Bestiary.UNIQUES:
		var u: Dictionary = (Bestiary.UNIQUES[k] as Dictionary).duplicate(true)
		u["id"] = k
		who["unique " + k] = Bestiary.unique_def(u, 6)
	var seen := {}
	for n in who:
		var v := Bestiary.voice_of(who[n])
		seen[n] = v
		if v == "" or not _reg(v):
			mute.append("%s -> '%s'" % [n, v])
	_ok(mute.is_empty(), "every creature (%d: types, lords, uniques) has a registered voice (bad: %s)" % [who.size(), mute])
	_ok(seen.get("type slime") == "slime_squish" and seen.get("type bat") == "bat_screech" and seen.get("type spider") == "spider_skitter" and seen.get("type warrior") == "skeleton_rattle" and seen.get("lord gravewyrm") == "dragon_roar" and seen.get("type imp") == "demon_growl" and seen.get("type rat") != "giant_footstep",
		"the brief's mapping holds (slime, bat, spider, skeleton, dragon, demon; a giant RAT is not a giant): %s" % [seen])

## ---------------------------------------------------------------- 2. live
func _process(_dt: float) -> bool:
	_f += 1
	if _f == 20:
		_ok(Sfx.live() != null, "the town's Sfx is running")
		var r: Roster = _t.get("roster")
		for v in [[IDS[0], "Ash", "knight"], [IDS[1], "Bree", "ranger"], [IDS[2], "Cole", "rogue"], [IDS[3], "Dawn", "cleric"]]:
			var h: Dictionary = r.get_hero(v[0])
			if h.is_empty():
				h = r.fresh(v[0], v[1], v[2])
			h["alive"] = true
			h["weapon"] = 3
			h["armour"] = 3
			h["oil"] = 4
			h["gold"] = 5000
		_ok(Roster.voice_of(r.get_hero(IDS[0])) == "male" and Roster.voice_of(r.get_hero(IDS[2])) == "female", "voices by body: the knight a man, the rogue a woman (%s / %s)" % [Roster.voice_of(r.get_hero(IDS[0])), Roster.voice_of(r.get_hero(IDS[2]))])
		var v2 := Roster.voice_of(r.get_hero(IDS[1]))
		_ok(v2 in ["male", "female"] and Roster.voice_of(r.get_hero(IDS[1])) == v2, "the ranger's voice is stable (%s)" % v2)
		# chat
		var c: ChatCmd = _t.get("chat")
		ChatCmd.ui_sounds.clear()
		for cmd in ["!inventory", "!hro", "!oil 1", "!brew"]:
			c._last.clear()
			ChatCmd._ui_last = -100000
			_t.call("chat_line", IDS[0], "Ash", cmd)
		_ok(ChatCmd.ui_sounds.has("inventory_open") and ChatCmd.ui_sounds.has("error") and ChatCmd.ui_sounds.has("coins_stack") and ChatCmd.ui_sounds.has("potion_drink"), "chat: the pack opens, a typo errors, buys chink, a brew is drunk (%s)" % [ChatCmd.ui_sounds])
		Monster.voiced.clear()
		_d = Delve.new()
		_d.town = _t
		_d.roster = r
		_d.start_floor = 5
		_d.max_floors = 5
		_t.add_child(_d)
		_d.start(IDS)
		Engine.time_scale = 3.0
	if _d and _lord_v == "" and _d.dun and _d.dun.lord and is_instance_valid(_d.dun.lord):
		_lord_v = Bestiary.voice_of(_d.dun.lord.def)
	if _f > 20 and (_f == 2400 or (_d and _f > 400 and _d.lord_fighting() == null and _d.dun and _d.dun.lord and not is_instance_valid(_d.dun.lord))):
		Engine.time_scale = 1.0
		_live_checks()
		print("S2_TEST %s (%d checks, %d failed)" % ["OK" if _fails.is_empty() else "FAIL", _checks, _fails.size()])
		return true
	return false

func _live_checks() -> void:
	var s := Sfx.live()
	var played: Dictionary = s.plays if s else {}
	var bad: Array = played.keys().filter(func(k): return not _reg(String(k)))
	_ok(not played.is_empty() and bad.is_empty(), "everything Sfx played is a registered kind (%d kinds, bad: %s)" % [played.size(), bad])
	var ds: Dictionary = _d.sounds
	var dbad: Array = ds.keys().filter(func(k): return not _reg(String(k)))
	_ok(dbad.is_empty(), "every sound the delve asked for is registered (bad: %s)" % [dbad])
	print("  delve sounds: ", ds)
	print("  creature voices: ", Monster.voiced)
	_ok(ds.has("sword_swing") and ds.has("dagger_stab") and ds.has("bow_draw"), "the swing has the weapon's sound: sword, dagger, bow")
	_ok(ds.has("hit_impact") or ds.has("sword_clash"), "a blow that lands is heard")
	_ok(ds.has("arrow_shot") or int(ds.get("bow_draw", 0)) > 0, "the ranger looses")
	var spells := 0
	for k in ["lightning", "fireball", "ice_shard", "heal", "shield", "buff", "summon"]:
		spells += int(played.get(k, 0))          # Spells.cast sounds them (S1); the delve no longer layers a copy (S3)
	_ok(spells > 0, "a spell is heard (%d)" % spells)
	var vox := 0
	for k in ds:
		if String(k).begins_with("male_") or String(k).begins_with("female_"):
			vox += int(ds[k])
	_ok(vox > 0, "the delvers cry out now and then (%d)" % vox)
	var swings := int(ds.get("sword_swing", 0)) + int(ds.get("dagger_stab", 0)) + int(ds.get("bow_draw", 0))
	_ok(vox * 2 < swings, "voices are sampled, not one per blow (%d voices, %d swings)" % [vox, swings])
	_ok(_lord_v != "" and int(Monster.voiced.get(_lord_v, 0)) > 0, "the lord roared as it rose (%s)" % _lord_v)
	_ok(not Monster.voiced.is_empty(), "creatures are heard (%s)" % [Monster.voiced])
	var bmv: Array = Monster.voiced.keys().filter(func(k): return not _reg(String(k)))
	_ok(bmv.is_empty(), "every creature voice heard is registered")
