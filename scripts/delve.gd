class_name Delve
extends Node3D
## A party's descent. Floors are built far below the valley (DELVE_Y) so the
## town keeps running above. Rules come from the ported Roster (5e to-hit:
## d20 + attack_bonus vs AC, damage from Roster.attack, max_hp, heal_power,
## one death save per delve, permadeath -> Roster.kill -> memorial) and the
## Bestiary (depth bands, strains, the lords on every fifth floor).
## Chronicle lines go to town.feed - canon word order (origin first, then the
## biome it was remade as) and never a floor count.

signal ended(survivors: Array)

const DELVE_Y := -400.0
const REACH := 1.9
var town: Node3D
var roster: Roster
var party: Array = []            # [{uid, h, body, hp, max, saved, swing}]
var floor_no := 0
var dun: DungeonHD
var state := "enter"
var _t := 0.0
var _kills := 0
var _gold := 0
var kit_bonus := 0.0      # gear drawn from the town rack at the muster
## ---- light (ported from the old expedition.gd). Burn is PER FLOOR, never per
## second: a floor is a floor on any machine. Each hero empties their own
## satchel into the party's at the mouth; one flask per two bodies a floor,
## half a flask to search one. Out of oil it goes dark: heroes swing at
## disadvantage, everything down there at advantage - and a party in the dark
## goes home after the floor it is on.
var oil := 0.0
var dark := false
var _warned_low := false
var haul := {"ore": 0.0, "stone": 0.0, "gear": 0.0, "potion": 0.0}
var _rng := RandomNumberGenerator.new()
var turn_back_at := 0.35         # mean hp fraction at which the party retreats

var start_floor := 1
var npc_party := false           # the town's own band: no viewer gold
var lane := 0                    # parallel delves sit side by side, 700 m apart
var solo := false                # S167 System 43: a !solo delve (town._solo_enter sets it) - its floors feed solo_deepest

## D37: E3PO voice hook. The town-held Notables carries _e3po_say. In a live
## delve `town` is the Town node; in a bare test rig it may be a stub without a
## notables ref, so this no-ops safely.
func _e3po(cat: String, sub := "") -> void:
	if town == null:
		return
	var n = town.get("notables") if town.get("notables") != null else null
	if n != null and n.has_method("_e3po_say"):
		n._e3po_say(cat, sub)

func start(uids: Array) -> void:
	_rng.randomize()
	_sense_floor = -1              # S156: the paths' once-a-floor ways start fresh each delve
	_mend_floor = -1
	for uid in uids:
		var h: Dictionary = roster.get_hero(uid)
		if h.is_empty() or not bool(h["alive"]):
			continue
		var b := HeroBody.new()
		b.npc = npc_party
		b.setup(roster, uid)
		b.town = self
		b.stay = true
		add_child(b)
		var mx := roster.max_hp(h)
		var mem := {"uid": uid, "h": h, "body": b, "hp": mx, "max": mx, "saved": false, "swing": _rng.randf()}
		party.append(mem)
		# Rally (bits/points reward): a pending rally seeds this delver's combat states
		var rs := float(h.get("rally_secs", 0.0))
		if rs > 0.0:
			_rally_states(mem, rs)
			h.erase("rally_secs")
			_say("%s descends rallied - strong, swift, and fearless." % String(h["name"]))
		if b.has_method("compact"):
			b.call_deferred("compact", true)
	_say(_fmt_line(_pick_line("descend", "%s %s into the scar."), [_names(), "descends" if party.size() == 1 else "descend"]))
	_e3po("delve_dispatch")         # D37: the Commander sees the party off
	for m in party:
		oil += float(int(m["h"].get("oil", 0)))
		m["h"]["oil"] = 0
	_say("They carry %d flask%s of oil between them." % [int(oil), "" if int(oil) == 1 else "s"])
	floor_no = start_floor - 1
	if is_inside_tree():
		_next_floor()
	else:
		call_deferred("_next_floor")

func _names_of(uids: Array) -> String:
	var n: Array = []
	for m in party:
		if uids.has(m["uid"]):
			n.append(String(m["h"]["name"]))
	return ", ".join(n) if n.size() < 3 else "%s and %d others" % [n[0], n.size() - 1]

func _names() -> String:
	var n: Array = []
	for m in party:
		n.append(String(m["h"]["name"]))
	return ", ".join(n) if n.size() < 3 else "%s and %d others" % [n[0], n.size() - 1]

func _say(line: String) -> void:
	if town:
		(town.get("feed") as Array).append(line)
	print("FEED ", line)

## height_at for the hero bodies: dungeon floors are flat
func height_at(_x: float, _z: float) -> float:
	return DELVE_Y + 0.05

func _alive() -> Array:
	var out: Array = []
	for m in party:
		if float(m["hp"]) > 0.0:
			out.append(m)
	return out

## L25c: forget the routes and the progress clocks (they are timed on _t, which restarts when a
## floor is cleared - a clock from the fight read as "no progress for ages" on the way down)
func _nav_reset() -> void:
	_paths.clear()
	_prog.clear()

func _next_floor() -> void:
	_nav_reset()
	_back_to = ""                  # D83: whatever pulled them back into a fight was on the last floor
	floor_no += 1
	if solo and roster and roster.has_method("note_solo_floor"):
		for m in party:
			roster.note_solo_floor(String(m["uid"]), floor_no)
	if dun:
		dun.queue_free()
	dun = DungeonHD.new()
	dun.floor_no = floor_no
	Bestiary.memorial = roster.fallen if roster else []
	dun.position = Vector3(float(lane) * 700.0, DELVE_Y, 0)
	add_child(dun)
	if dun.info.is_empty():
		dun.build(floor_no)
	# FloorGen's entry/exit are relative to the floor's own origin
	var entry: Vector3 = dun.info["entry"] + dun.global_position
	var i := 0
	for m in _alive():
		var b: HeroBody = m["body"]
		var at := entry + Vector3(float(i % 3) - 1.0, 0, float(i / 3)) * 1.4
		# a big party's back rows can land past the wall by the stairs: on the floor or at the entry
		if not (dun.info["cells"] as Dictionary).has(_cell_of(at)):
			at = entry + Vector3(float(i % 3) - 1.0, 0, 0) * 0.5
		if not (dun.info["cells"] as Dictionary).has(_cell_of(at)):
			at = entry
		b.global_position = at
		i += 1
	# monster numbers scale with depth (Bestiary multipliers on a floor base)
	for mon in dun.monsters:
		var M: Monster = mon
		M.max_hp = (14.0 + float(floor_no) * 6.0) * float(M.def.get("hp", 1.0))
		M.hp = M.max_hp
	if dun.lord:
		dun.lord.max_hp = float(dun.lord.def.get("boss_hp", 200.0))
		dun.lord.hp = dun.lord.max_hp
		# L29a: a lord crossing a phase threshold is a story beat - say it
		if not dun.lord.phase_changed.is_connected(_lord_phase):
			dun.lord.phase_changed.connect(_lord_phase)
	# a floor costs one flask per two bodies
	var alive_now := _alive().size()
	oil = maxf(0.0, oil - float(maxi(OIL_FLOOR_MIN, int(ceil(float(alive_now) * OIL_PER_HEAD)))))
	var origin_key := FloorGen.origin_for(floor_no)
	var of := String((FloorGen.ORIGINS.get(origin_key, {}) as Dictionary).get("of", "a ruin"))
	var biome := String(dun.info.get("theme_name", "the dark"))
	var line := "Floor %d - %s, remade as %s: %s." % [floor_no, of, biome, _census()]
	_say(line)
	# L19: the old budget - one tell a delve, on its first floor (the origin's own, or one of lore_lines)
	if floor_no == start_floor:
		var tells: Array = [String((FloorGen.ORIGINS.get(origin_key, {}) as Dictionary).get("tell", ""))]
		tells.append_array((lore().get("tells", {}) as Dictionary).get(origin_key, []))
		tells = tells.filter(func(s): return String(s) != "")
		if not tells.is_empty():
			_say(String(tells[_rng.randi() % tells.size()]))
		_bark_any("enter")
	if dun.lord:
		# NOT capitalize(): it title-cases every word (origins.json warns about this)
		var note := String(dun.lord.def.get("note", ""))
		if note != "":
			note = note.substr(0, 1).to_upper() + note.substr(1) + "."
		var uniq := bool(dun.lord.def.get("unique", false))
		_say(("%s is down here. %s" if uniq else "%s rises. %s") % [dun.lord.def.get("name", "A lord"), note])
		_e3po("lord_sighted")   # D37: a lord has risen - the Commander calls it out
		# L29b: the guild knows this lord. It does not know THIS one.
		if bool(dun.lord.def.get("lord_unique", false)):
			_say("The guild has put down %s before. Not this one." % String(dun.lord.def.get("lord_title", "its like")))
		var intro := intro_line(uniq, String(dun.lord.def.get("id", "")), _rng)
		if intro != "":
			_say(intro)
		_bark_any("lord")
		# L12: a lord rising - a WIS save (DC 10 + floor/2) or frightened a while
		if not uniq:
			for m in _alive():
				if _rng.randi_range(1, 20) + roster.save_bonus(m["h"], "wis") < mini(20, 10 + floor_no / 2):
					_give(m, "frightened", 6.0)
		Monster.roar(dun.lord)          # S2: the lord's voice as it rises (the card, the director and the spotlight cut to it)
		FeedHUD.card_on(town, String(dun.lord.def.get("name", "A lord")),
			(("A rare thing on floor %d. %s" if uniq else "Lord of floor %d. %s") % [floor_no, note]).strip_edges(), dun.lord.def.get("aura", Color(1, 0.8, 0.4)))
	if not dark and not _warned_low and oil > 0.0 and oil <= float(alive_now):
		_warned_low = true
		_say("The oil is running low.")
	_initiative()
	_lamp_lit = false
	_light_check()
	_lay_bags()                       # S164: corpse-run bags left on this floor lie by the way in
	state = "fight"

## ---------------------------------------------------------------- L29c: set pieces
## A floor's AMBUSH goes off here: as the party walks past a trigger point one short
## pack of theme-matched creatures peels out of the dark, named in the Chronicle so a
## viewer who looks up from chat knows what just dropped on them. One resolution per
## set piece per floor, and the ambush's own creatures are counted into the floor's
## foes so every other system (the fight loop, the lord's roar, boss_bar) picks them
## up for free. The data is laid by dungeon_hd._set_pieces; this is the ONLY code
## that resolves it, so the test can count resolutions straight off setpieces_fired.
static var setpieces_fired := {}            # kind -> count (tools/_l29c_test.gd)
## S38: the Beadle's holds are counted per held hero PER FRAME, so they live here and NOT in
## setpieces_fired - _l29c_test C sums that dict and could otherwise pass on holds alone.
static var order_held_frames := 0
static var rammer_struck := 0                # S38: delvers caught on the pile at the count
static var fuller_struck := 0                # S78: delvers under the stocks when the Fuller wrung
static var pitman_fell := 0                  # S79: delvers who went into one of the Pitman's pits
static var rammer_read := 0                  # S38: delvers on the pile who read the hold and stepped off
const _AMBUSH_LINE := [
	"Shadows peel off the walls - an ambush! %s surges in.",
	"A grate shifts, and %s is already upon them.",
	"%s was waiting in the dark, and now it isn't.",
]

func _setpieces_tick() -> void:
	if dun == null or not dun.info.has("set_pieces"):
		return
	var sps: Array = dun.info["set_pieces"]
	if sps.is_empty():
		return
	for sp_v in sps:
		var sp: Dictionary = sp_v
		if bool(sp.get("resolved", false)):
			continue
		var at: Vector3 = (sp["pos"] as Vector3) + dun.global_position
		var r: float = float(sp.get("r", 3.0))
		var triggered := false
		for m in _alive():
			if _flat((m["body"] as Node3D).global_position, at) <= r:
				triggered = true
				break
		if not triggered:
			continue
		sp["resolved"] = true
		var kind := String(sp.get("kind", ""))
		Delve.setpieces_fired[kind] = int(Delve.setpieces_fired.get(kind, 0)) + 1
		match kind:
			"ambush":
				_setpiece_ambush(sp, at)
			"prisoner":
				_setpiece_prisoner(sp, at)
			"shrine":
				_setpiece_shrine(sp, at)
			"miniboss":
				_setpiece_miniboss(sp, at)

func _setpiece_ambush(sp: Dictionary, at: Vector3) -> void:
	var names: Array = []
	var pack: Array = sp.get("pack", [])
	var i := 0
	for d_v in pack:
		var d: Dictionary = d_v
		var m := Monster.new()
		m.def = d
		m.state = Monster.S.PATROL
		m.roam = 2.5
		var off := Vector3(cos(float(i) * 2.1), 0.0, sin(float(i) * 2.1)) * 1.3 if i > 0 else Vector3.ZERO
		m.position = Vector3(at.x - dun.global_position.x + off.x, 0.0, at.z - dun.global_position.z + off.z)
		dun.add_child(m)
		_admit(m)
		# scale to this floor the same way _next_floor does for ordinary spawns
		m.max_hp = (14.0 + float(floor_no) * 6.0) * float(m.def.get("hp", 1.0))
		m.hp = m.max_hp
		names.append(String(d.get("name", "something")))
		i += 1
	# "2 ghouls and a skeleton" rather than "ghoul, ghoul, skeleton"
	var counts := {}
	for nm in names:
		counts[nm] = int(counts.get(nm, 0)) + 1
	var parts: Array = []
	for k in counts:
		var ks := String(k)
		var n: int = counts[k]
		parts.append("%d %s" % [n, ks if n == 1 or ks.ends_with("s") else ks + "s"])
	var who := ", ".join(parts) if not parts.is_empty() else "something"
	_say(_AMBUSH_LINE[_rng.randi() % _AMBUSH_LINE.size()] % who)
	# an ambush is a roar: Monster.roar would also fire when the pack enters
	# its FIGHT state, but a single tell lands harder than three in a row
	if not names.is_empty():
		Sfx.play("roar", -4.0)

## PRISONER: a captive was down here before the party was. A hero within reach
## cracks the chain off; the captive slips a purse into the party's hands before
## making for the stairs. Gold is split among the alive, same rule as a chest.
## argument order on every line: [finder_name, purse, alive.size()] - keep it
## uniform so a random pick never trips a String-format error at play
const _PRISONER_LINE := [
	"%s cracks the chain off a captive - %d gold passes to the party, split %d ways.",
	"%s finds a man in a cage still alive. He slips %d gold to them on the way out, %d ways to split it.",
	"%s gets a captive free. %d gold, %d ways - small thanks for a poor life.",
]

func _setpiece_prisoner(sp: Dictionary, at: Vector3) -> void:
	var alive := _alive()
	if alive.is_empty():
		return
	# the nearest alive hero does the freeing (the one who tripped the trigger)
	var finder: Dictionary = alive[0]
	var best := 1.0e9
	for m in alive:
		var d := _flat((m["body"] as Node3D).global_position, at)
		if d < best:
			best = d
			finder = m
	var purse := int(sp.get("purse", 50))
	var share := maxi(1, purse / alive.size())
	for m in alive:
		roster.award(String(m["uid"]), share, 0, 0, floor_no)
		_float_text(m, "+%d" % share, Color(1.0, 0.85, 0.35))
	var finder_name := String(finder["h"].get("name", "A delver"))
	_say(_PRISONER_LINE[_rng.randi() % _PRISONER_LINE.size()] % [finder_name, purse, alive.size()])
	Sfx.play("coin", -4.0)

## SHRINE: an altar older than the floor. A hero touches it; the die is already
## cast in the data (dungeon_hd.gd rolls boon/curse at build). A BOON fills
## everybody's hp; a CURSE takes a bite out of each - small and survivable, the
## point is the risk of the touch, not the hit.
const SHRINE_BOON_FRAC := 1.0           # a boon mends the party back to full
const SHRINE_CURSE_HP := 12.0           # a curse takes this many hp from each
## S86: the oil a floor burns - OIL_PER_HEAD flasks per living delver, rounded up,
## never under OIL_FLOOR_MIN. Named so the chat bot's `delve`/`oil` wording guards
## read the engine (two authorities) instead of only their own sentence.
const OIL_PER_HEAD := 0.5
const OIL_FLOOR_MIN := 1

func _setpiece_shrine(sp: Dictionary, at: Vector3) -> void:
	var alive := _alive()
	if alive.is_empty():
		return
	var toucher: Dictionary = alive[0]
	var best := 1.0e9
	for m in alive:
		var d := _flat((m["body"] as Node3D).global_position, at)
		if d < best:
			best = d
			toucher = m
	var who := String(toucher["h"].get("name", "A delver"))
	var is_boon := bool(sp.get("boon", true))
	if is_boon:
		for m in alive:
			m["hp"] = float(m["max"])       # the boon is a mend (max_hp of this delver)
			_float_text(m, "+boon", Color(0.5, 1.0, 0.7))
		_say("%s touches the altar - a boon. The light steadies; the party is mended." % who)
	else:
		for m in alive:
			m["hp"] = maxf(1.0, float(m["hp"]) - SHRINE_CURSE_HP)
			_float_text(m, "-%d" % int(SHRINE_CURSE_HP), Color(1.0, 0.45, 0.42))
			_hero_hit(m)
		_say("%s touches the altar - a curse. Something older than the floor takes a bite." % who)

## MINIBOSS: an elite theme creature standing alone in its own chamber - 2x hp
## and +20% atk on top of the floor's depth scaling, so it reads as a real
## fight and not another spawn. The Chronicle names it when the party crosses
## the trigger, and when it falls _on_kill drops the purse carried on its meta
## (set here) across the alive party - same split rule as a chest. Kept off
## floors 1-3 by the picker in dungeon_hd._set_pieces.
##
## Round 4 (RALLY): at half hp the elite "finds its second wind" - its atk
## climbs by MINIBOSS_RALLY_MULT and the Chronicle writes a tell so a viewer
## reading the panes or the Chronicle sees the beat land. One rally per
## miniboss; the meta flag below gates it so it never fires twice.
## D96: the miniboss bodies (assets/monsters/minibosses/, art lane). A _chibi variant is the
## art register conversion and is preferred when it is on disk. MB_FIT is art's MEASURED
## creature-to-hero height ratio per model (renders/art/minibosses/_fit_*_register.json and
## _fit_report.json, hero = the posed KayKit knight at 2.45) - copied, not re-derived.
## S13: quartermaster 0.96 from _fit_report.json pairs.quartermaster.ratio (art, 0f0caea).
const MB_DIR := "res://assets/monsters/minibosses/"
const MB_HERO_H := 2.45
const MB_FIT := {
	"drillmaster": 0.90, "drillmaster_chibi": 0.90, "scrapwright": 0.82, "gaoler": 0.96, "gaoler_chibi": 0.96,
	"snuffer": 1.06, "sexton": 1.00, "sexton_chibi": 1.00, "porter": 0.94, "porter_chibi": 0.94,
	"tallyman": 0.88, "tallyman_chibi": 0.88, "cook": 0.84, "cook_chibi": 0.84,
	"sluicekeeper": 1.02, "sluicekeeper_chibi": 1.02, "sower": 0.92, "sower_chibi": 0.98,
	"snarer": 0.94, "snarer_chibi": 1.00, "jointer": 0.92, "quartermaster": 0.96, "loader": 1.08, "hurdleman": 1.04, "stoker": 0.98, "stoker_chibi": 0.98, "bellman": 1.10,
	"boiler": 0.86, "boiler_chibi": 1.00,
	"reeve": 0.80,   # S22: art's measured ratio (lead's 14:58 row), copied not re-derived
	"tapster": 1.14,   # S23: art's _fit_tapster_register.json ratio (lead's 16:58 row), copied not re-derived
	"pressman": 1.16,   # S25: art's _fit_report.json pairs.pressman.ratio (lead's 17:58/18:58 rows), copied not re-derived
	"strickler": 1.04,   # S25: art's _fit_report.json pairs.strickler.ratio on origin/art (lead's 18:58 row), copied not re-derived; inert until the body merges
	"greener": 1.02,   # S28: art's _fit_greener_register.json pairs.greener.ratio (lead's 21:05 addendum), copied not re-derived
	"dyer": 1.06,   # S28: art's _fit_dyer_register.json pairs.dyer.ratio (lead's 21:58 row), copied not re-derived
	"tanner": 1.12,   # S28: art's _fit_report.json pairs.tanner.ratio (lead's 21:58 row), copied not re-derived
	"moulder": 1.18,   # S32: art's _fit_moulder_register.json pairs.moulder.ratio, copied not re-derived
	"ratcatcher": 1.07,   # S32: art's _fit_ratcatcher_register.json pairs.ratcatcher.ratio, copied not re-derived
	"drover": 1.00,   # S32: art's _fit_report.json pairs.drover.ratio, copied not re-derived
	"paviser": 1.09,   # S32: art's _fit_report.json pairs.paviser.ratio (MINIBOSSES.md 29), copied not re-derived
	"fenman": 1.03,   # S32: art's _fit_report.json pairs.fenman.ratio (MINIBOSSES.md 30, lead's 05:58 row), copied not re-derived
	"comfitmaker": 0.93,   # S33: art's _fit_comfitmaker_register.json pairs.comfitmaker.ratio, copied not re-derived
	"leech": 0.95,   # S33: art's _fit_leech_register.json pairs.leech.ratio (MINIBOSSES.md 32), copied not re-derived
	"rammer": 1.12,   # S38: art's _fit_rammer_register.json pairs.rammer.ratio (MINIBOSSES.md 34), copied not re-derived
	"beadle": 1.2,   # S35: art's _fit_beadle_register.json beadle.ratio (MINIBOSSES.md 33), copied not re-derived
	"fuller": 1.09,   # S48: art's _fit_report.json pairs.fuller.ratio (35th, lead's 17:58 tick), copied not re-derived
	"stackman": 1.16,   # S48: art's _fit_report.json pairs.stackman.ratio (36th, lead's 18:58 tick), copied not re-derived
	"dauber": 1.05,   # S65: art's _fit_report.json pairs.dauber.ratio (37th, h 2.58, tag keep), copied not re-derived
	"sealer": 0.99,   # S66: art's _fit_fit_sealer_register.json pairs.sealer.ratio (38th, h 2.42, tag treasury, verdict GREEN), copied not re-derived
	"hooper": 0.96,   # S67: art has NO hero-pair register for the Hooper, so this is _fit_report.json pairs.hooper.ratio (39th, h 2.36 / hero 2.45, tag mess), copied not re-derived
	"relief": 1.03,   # S68: art's _fit_relief_register.json pairs.relief.ratio (40th, h 2.52 / hero 2.45, tag barracks, 3/3 proving views), copied not re-derived
	"scraper": 1.04,   # S69: art's _fit_scraper_register.json pairs.scraper.ratio (41st, h 2.55 / hero 2.45, tag crypt, 3/3 proving views), copied not re-derived. MB_NAME row added at S70 once content C-147 wrote the feed
	"ferryman": 1.07,   # S71: art's _fit_ferryman_register.json pairs.ferryman.ratio (42nd, h 2.62 / hero 2.45, tag flooded - field 5, 3/3 proving views), copied not re-derived. MB_NAME row added at S72 once content C-149 wrote the feed
	"winder": 0.96,   # S73: art's _fit_winder_register.json pairs.winder.ratio (43rd, Haulback in CANON, h 2.34 / hero 2.45, tag wood - field 5, 3/3 proving views, verdict GREEN), copied not re-derived. MB_NAME row added at S75 once content C-151 wrote the feed
	"pitman": 0.94,   # S76: art's _fit_pitman_register.json pairs.pitman.ratio (44th, Underfoot in CANON, h 2.30, tag crypt - field 5, frame_edge 0 on all three views, fits_frame true), copied not re-derived
	"tither": 0.99,   # S89: art's _fit_report.json pairs.tither.ratio (45th, Tenthpart in CANON, h 2.42 / hero 2.45, tag prison - field 5, fits_frame true), copied not re-derived
	"blower": 1.01,   # S93: art's _fit_report.json pairs.blower.ratio (46th, Deadair in CANON, h 2.48 / hero 2.45, tag fogbound - field 5, fits_frame true, 3/3 proving views), copied not re-derived. MB_NAME row added at S94 once content C-169 wrote the feed
	"changer": 1.11,   # S98: art's _fit_report.json pairs.changer.ratio (47th, Evenhand in CANON, h 2.72 / hero 2.45, tag treasury - field 5, fits_frame true, 3/3 proving views), copied not re-derived
	"stopper": 0.97,   # S101: art's _fit_report.json pairs.stopper.ratio (48th, Chokewell in CANON, h 2.38 / hero 2.45, tag crypt - field 5, fits_frame true, 3/3 proving views), copied not re-derived. stopper.glb is NOT on any branch, so miniboss_model holds it out until art commits the mesh
	"almoner": 1.03,   # S107: art's _fit_report.json pairs.almoner.ratio (50th, Dolehand in CANON, h 2.52 / hero 2.45, tag shrine - field 5, fits_frame true, 3/3 proving views), copied not re-derived; almoner.glb.import committed in the same change
	"panner": 0.92,   # S111: art's _fit_report.json pairs.panner.ratio (51st, Onceround in CANON, h 2.26 / hero 2.45, tag confection - field 5, fits_frame true, 3/3 proving views), copied not re-derived
	"stiltman": 1.31,   # S112: art's _fit_report.json pairs.stiltman.ratio (52nd, Downfast in CANON, h 3.20 / hero 2.45, tag fogbound - field 5, fits_frame true, 3/3 proving views), copied not re-derived; stiltman.glb.import tracked on main
	"nightman": 0.94,   # S113: art's _fit_report.json pairs.nightman.ratio (53rd, Nightwork in CANON minibosses.py:19075, h 2.30 / hero 2.45, tag prison - field 5, fits_frame true, 3/3 proving views), copied not re-derived
	"iceman": 1.27,   # S115: art's _fit_report.json pairs.iceman.ratio (54th, Hoarback in CANON minibosses.py:19421, h 3.12 / hero 2.45, tag mess - field 5, fits_frame true), copied not re-derived. MB_NAME row added at S116 once content's by_key.iceman (C-193) landed (S98 precedent)
	"straker": 0.98,   # S117: art's _fit_report.json pairs.straker.ratio (55th, Everyhand in CANON minibosses.py:19822, h 2.40 / hero 2.45, tag wood - field 5, fits_frame true, 3/3 proving views), copied not re-derived. NO MB_NAME row until content's by_key.straker lands (S115 precedent)
	"weigher": 1.04,   # S120: art's _fit_report.json pairs.weigher.ratio (56th, Trueweight in CANON minibosses.py:20600, h 2.55 / hero 2.45, tag treasury - field 5, fits_frame true, 3/3 proving views), copied not re-derived. MB_NAME row added at S121 once content's by_key.weigher (C-198) landed
	"dredger": 0.98,   # S122: art's _fit_report.json pairs.dredger.ratio (57th, Finepass in CANON minibosses.py:20871, h 2.39 / hero 2.45, tag confection - field 5, fits_frame true, 3/3 proving views, air_px_min 160), copied not re-derived; dredger.glb + .import on main, content's C-199 by_key.dredger landed, so MB_NAME row written in the same change
	"harrowman": 1.0,   # S123: art's _fit_report.json pairs.harrowman.ratio (58th, Overturn in CANON minibosses.py:21156, h 2.45 / hero 2.45, tag grassland - field 5, fits_frame true, 3/3 proving views, air_px_min 67), copied not re-derived; harrowman.glb + .import on main, content's C-200 by_key.harrowman landed, so MB_NAME row written in the same change
	"pledgeman": 1.05,   # S124: art's _fit_report.json pairs.pledgeman.ratio (59th, Heldfast in CANON minibosses.py:21464, h 2.58 / hero 2.45, tag treasury - field 5, fits_frame true, 3/3 proving views, air_px_min 136), copied not re-derived; pledgeman.glb + .import on main, content's C-201 by_key.pledgeman landed, so MB_NAME row written in the same change
	"timberman": 1.24,   # S127: art's _fit_report.json pairs.timberman.ratio (61st, Deadfall in CANON minibosses.py:22232, h 3.05 / hero 2.45, tag crypt - field 5, fits_frame true but margin_x 0.12 - the TALLEST body in the register and the least room of any), copied not re-derived; timberman.glb + .import on main, content's C-203 by_key.timberman landed, so MB_NAME row written in the same change
	"collier": 0.86,   # S129: art's _fit_report.json pairs.collier.ratio (62nd, Halfblow in CANON minibosses.py:22643, h 2.10 / hero 2.45, tag wood - field 5, fits_frame true, margin_x 0.12, 3/3 proving views), copied not re-derived; collier.glb + .import on main, content's C-205 by_key.collier landed, so MB_NAME row written in the same change
	"overlooker": 0.98,   # S141: art's _fit_report.json pairs.overlooker.ratio (63rd, Velrick in CANON minibosses.py:23819, h 2.40 / hero 2.45, tag workshop - field 5, fits_frame true, margin_x 0.12, 3/3 proving views), copied not re-derived; overlooker.glb + .import on main, content's C-216 by_key.overlooker landed (9/8/4/8), so MB_NAME row written in the same change
	"thatcher": 1.04,   # S148: art's _fit_report.json pairs.thatcher.ratio (66th, Lastcourse in CANON minibosses.py:25131, h 2.54 / hero 2.45, tag flooded - field 5, fits_frame true, margin_x 0.12, 3/3 proving views), copied not re-derived. Pass 7 changed colour only.
	"badger": 0.99,   # S154: art's _fit_report.json pairs.badger.ratio (67th, Forestall in CANON minibosses.py:25806, h 2.43 / hero 2.45, tag mess - field 5, fits_frame true, margin_x 0.12, pair_w 3.17), copied not re-derived
	"shearman": 1.02,   # S159: art's _fit_report.json pairs.shearman.ratio (69th, Cutloose in CANON minibosses.py:26814, h 2.51, tag workshop - field 5, fits_frame true, margin_x 0.12), copied not re-derived; content's C-238 by_key.shearman landed on main (14:58 merge), so MB_NAME row written in the same change
	"hammerman": 0.92,   # S159: art's _fit_report.json pairs.hammerman.ratio (70th and last, Alltold in CANON minibosses.py:27212, h 2.26, tag firepit - field 5, fits_frame true, margin_x 0.12), copied not re-derived; content's C-238 by_key.hammerman landed on main (14:58 merge), so MB_NAME row written in the same change
	"mower": 1.03,   # S157: art's _fit_report.json pairs.mower.ratio (68th, Oneswath in CANON minibosses.py:26388, h 2.52 / hero 2.45, tag grassland - field 5, fits_frame true, margin_x 0.12, 3/3 proving views front/side/back), copied not re-derived; content's C-236 by_key.mower landed, so MB_NAME row written in the same change
	"mealman": 0.97,   # S145: art's _fit_report.json pairs.mealman.ratio (65th, Whitedamp in CANON minibosses.py:24699, h 2.37 / hero 2.45, tag mess - field 5, fits_frame true, margin_x 0.12, 3/3 proving views), copied not re-derived. Content's by_key.mealman has NOT landed, so miniboss_for holds it out and NO MB_NAME row is written yet
	"fanner": 0.95,   # S144: art's _fit_report.json pairs.fanner.ratio (64th, Blastmere in CANON minibosses.py:24245, h 2.33 / hero 2.45, tag firepit - field 5, fits_frame true, margin_x 0.12, 3/3 proving views), copied not re-derived; fanner.glb on main. The register reads RED on fanner's missing self_seen cell (art pass 4), not on this pair. Held off floors by miniboss_for until content's C-222 by_key.fanner lands
	"crimp": 0.99,   # S126: art's _fit_report.json pairs.crimp.ratio (60th, Oneshort in CANON minibosses.py:21826, h 2.42 / hero 2.45, tag barracks - field 5, fits_frame true, 3/3 proving views), copied not re-derived; crimp.glb + .import on main. MB_NAME row added at S126b once content's C-202 by_key.crimp landed
	"roper": 1.0,   # S101: art's _fit_report.json pairs.roper.ratio (49th, Drawtight in CANON, h 2.46 / hero 2.45, tag grassland - field 5, fits_frame true, 3/3 proving views), copied not re-derived. MB_NAME row added at S102 once content C-177 wrote the feed
}
## S51: MR. E's 19 Nov directive (supervisor doc sup-nov19-2150): the minibosses keep their
## bodies, mechanics and fit ratios and LOSE THEIR TRADE NAMES. The KEY stays the trade word -
## it is art's file name (MB_DIR + key + ".glb"), MB_FIT's key, THEME_MINIBOSS_MORE's entry and
## content's miniboss_feed.by_key key - so nothing that finds a body or a line moves. Only what
## a viewer READS changes: the nameplate, the "holds this chamber alone" line. A proper name
## takes no "The". These are PROPOSALS and Mr. E has final say: change a name HERE, one place.
## A key missing from this table falls back to the old capitalised trade word, so an unnamed body
## still stands up rather than going nameless. S52: row 23 of the directive's old-name column
## reads "Drizzler" - there is no such key; the live body is `strickler` (CANON 23, by_key, .glb).
## tools/_s51_names.gd now asserts this table's KEY SET against content's by_key, MB_FIT and the
## .glb stems on disk - never against a second copy of itself.
const MB_NAME := {
	"drillmaster": "Karvok", "scrapwright": "Ironhyde", "gaoler": "Shacklemaw", "snuffer": "Duskhollow", "sexton": "Gravrik", "porter": "Drudgewall",
	"tallyman": "Velmok", "cook": "Blisterhand", "sluicekeeper": "Rothenwell", "sower": "Thorncast", "snarer": "Griplash", "stoker": "Cindrak",
	"bellman": "Tolburn", "boiler": "Scaldmere", "jointer": "Halvrek", "quartermaster": "Wardgrim", "loader": "Millstone", "hurdleman": "Bramblejaw",
	"tanner": "Flenscar", "reeve": "Lockwarden", "tapster": "Dregsallow", "pressman": "Crushwright", "strickler": "Murkspit", "dyer": "Venomshade",
	"greener": "Corrodan", "moulder": "Ashform", "ratcatcher": "Skivven", "drover": "Yokebane", "paviser": "Shieldmaw", "fenman": "Bogwarden",
	"comfitmaker": "Brindle", "leech": "Gulworth", "beadle": "Ordrik", "rammer": "Breachar", "fuller": "Wrynn", "stackman": "Huskpile",
	"dauber": "Wetwall",   # S65: content's _note_c142 "the Dauber (Wetwall)" and art's CANON title, both read
	"sealer": "Leadbite",   # S66: content's _note_c143 "Leadbite" and art's CANON title (minibosses.py), both read
	"hooper": "Hoopfast",   # S67: content's _note_c144 "Hoopfast" and art's CANON title (minibosses.py:13186), both read
	"relief": "Watchturn",   # S68: content's miniboss_feed._note_c145 "Watchturn" and art's CANON title (minibosses.py:13584), both read
	"scraper": "Scourstone",   # S70: content's miniboss_feed._note_c147 "Scourstone" and art's CANON title (minibosses.py:14068), both read
	"ferryman": "Slackwater",   # S72: content's miniboss_feed._note_c149 "Slackwater" and art's CANON title (minibosses.py:14501), both read
	"winder": "Haulback",   # S75: content's miniboss_feed._note_c151 "Haulback" and art's CANON title (minibosses.py:14974), both read
	"pitman": "Underfoot",   # S76: content's miniboss_feed._note_c152 "Underfoot" and art's CANON title (minibosses.py:15251), both read
	"tither": "Tenthpart",   # S89: art's CANON title (minibosses.py:15830); content's C-167 by_key.tither has landed, so miniboss_for draws the body (S91)
	"blower": "Deadair",   # S94: content's miniboss_feed._note_c169 "Deadair" and art's CANON title (minibosses.py:16064), both read; C-169 by_key.blower landed (9/7/4/8)
	"changer": "Evenhand",   # S99: content's miniboss_feed._note_c174 "Evenhand" and art's CANON title (minibosses.py:16466), both read; C-174 by_key.changer landed (9/7/4/8)
	"roper": "Drawtight",   # S102: content's miniboss_feed._note_c177 "Drawtight" and art's CANON title (minibosses.py:17262), both read; C-177 by_key.roper landed (9/7/4/8)
	"stopper": "Chokewell",   # S103: content's miniboss_feed._note_c176 "Chokewell" and art's CANON title (minibosses.py:16881), both read; C-176 by_key.stopper landed (9/7/4/8); stopper.glb tracked on main 41f71825 - the S101/S102 hold is lifted
	"almoner": "Dolehand",   # S107: content's C-182 by_key.almoner landed (9/7/4/8) and art's CANON title (minibosses.py:17903), both read
	"panner": "Onceround",   # S111: content's C-187 by_key.panner landed (9/7/4/8), _note_c187 "Onceround", and art's CANON title (minibosses.py:18373), both read; panner.glb.import committed at S110
	"stiltman": "Downfast",   # S112: content's C-189 by_key.stiltman landed (9/7/4/8) and art's CANON title (minibosses.py:18749), both read
	"nightman": "Nightwork",   # S113: content's C-190 by_key.nightman landed (9/7/4/8) and art's CANON title (minibosses.py:19075), both read
	"iceman": "Hoarback",   # S116: content's C-193 by_key.iceman landed (9/7/4/8, fall lines name Hoarback) and art's CANON title (minibosses.py:19421), both read - the close S115 specified
	"straker": "Everyhand",   # S118: content's C-195 by_key.straker landed (9/7/4/8, fall lines name the Everyhand) and art's CANON title (minibosses.py:19931), both read - the close S117 specified
	"weigher": "Trueweight",   # S121: content's C-198 by_key.weigher landed (9/8/4/8, _note_c198 "Trueweight") and art's CANON title (minibosses.py:20600), both read - the close S120 specified
	"dredger": "Finepass",   # S122: content's C-199 by_key.dredger landed (9/8/4/8, _note_c199 "Finepass") and art's CANON title (minibosses.py:20871), both read
	"harrowman": "Overturn",   # S123: content's C-200 by_key.harrowman landed (9/8/4/8, _note_c200 "Overturn") and art's CANON title (minibosses.py:21156), both read
	"pledgeman": "Heldfast",   # S124: content's C-201 by_key.pledgeman landed (9/8/4/8, _note_c201 "Heldfast", fall lines "Heldfast is down") and art's CANON title (minibosses.py:21464), both read
	"crimp": "Oneshort",   # S126: content's C-202 by_key.crimp landed (9/8/4/8, _note_c202 "Oneshort", fall lines "Oneshort is down") and art's CANON title (minibosses.py:21826), both read
	"timberman": "Deadfall",   # S127: content's C-203 by_key.timberman landed (9/8/4/8) and art's CANON title (minibosses.py:22232), both read
	"collier": "Halfblow",   # S129: content's C-205 by_key.collier landed (9/8/4/8, fall lines name Halfblow) and art's CANON title (minibosses.py:22643), both read
	"overlooker": "Velrick",   # S141: content's C-216 by_key.overlooker landed (9/8/4/8, _note_c216) and art's CANON title (minibosses.py:23819), both read - the 63rd, closing the cascade's first open link
	"fanner": "Blastmere",   # S144: art's CANON title (minibosses.py:24245, docs/art/FANNER_THE_64th.md) - the 64th, named in the hour the team lead opened it; content's by_key.fanner (C-222) not yet landed, so the body stays held by miniboss_for
	"mealman": "Whitedamp",   # S146: art's CANON title (minibosses.py:24699, docs/art/MEALMAN_THE_65th.md) and content's C-225 by_key.mealman (9/8/4/8), both read - the 65th, shutting the cascade at 65 names / 65 feed keys
	"thatcher": "Lastcourse",   # S148: art's CANON title (minibosses.py:25131, docs/art/THATCHER_THE_66th.md) and content's C-227 by_key.thatcher (act/arrive/broken/fall), both read - the 66th, shutting the cascade at 66 names / 66 feed keys
	"badger": "Forestall",   # S154: art's CANON title (minibosses.py:25806) - the 67th, named on the 09:58 row after the team lead ticked art's fit on his own look; content's by_key.badger not yet landed, so miniboss_for holds the body until fed (fanner precedent, S144)
	"mower": "Oneswath",   # S157: art's CANON title (minibosses.py:26388, "THE MOWER - Oneswath") and content's C-236 by_key.mower (landed 12:23:17 CT), both read - the 68th, MB_NAME 67 -> 68
	"shearman": "Cutloose",   # S159: art's CANON title (minibosses.py:26814) and content's C-238 by_key.shearman, both read - the 69th, MB_NAME 68 -> 69
	"hammerman": "Alltold"}   # S159: art's CANON title (minibosses.py:27212) and content's C-238 by_key.hammerman, both read - the 70th and last, MB_NAME 69 -> 70
static func miniboss_name(key: String) -> String:
	return String(MB_NAME.get(key, key.capitalize()))
static var miniboss_no_model: Array = []
static func miniboss_model(key: String) -> String:
	for nm: String in [key + "_chibi", key]:
		var p: String = MB_DIR + nm + ".glb"
		if ResourceLoader.exists(p):
			return p
	return ""
static func miniboss_ratio(key: String, path: String) -> float:
	var nm := path.get_file().get_basename()
	return float(MB_FIT.get(nm, MB_FIT.get(key, 1.0)))
const MINIBOSS_HP_MULT := 2.0
const MINIBOSS_ATK_MULT := 1.2
const MINIBOSS_RALLY_FRAC := 0.5          # hp fraction that triggers the rally
const MINIBOSS_RALLY_MULT := 1.5          # atk multiplier applied on rally

func _setpiece_miniboss(sp: Dictionary, _at: Vector3) -> void:
	var def: Dictionary = sp.get("def", {})
	if def.is_empty():
		return
	var purse := int(sp.get("purse", 50))
	var pos: Vector3 = sp["pos"]
	# miniboss_feed: the chamber's art-lane key (dungeon_hd THEME_MINIBOSS). With one,
	# the elite takes that miniboss's NAME so the content writer's lines ("The
	# Drillmaster is down.") match what the Chronicle has been calling it.
	var mb_key := String(sp.get("mb_key", ""))
	if mb_key != "" and not miniboss_lines(mb_key, "arrive").is_empty():
		def = def.duplicate()
		def["name"] = miniboss_name(mb_key)   # S51: the character name, not the trade
		# D96: the miniboss stands up in ITS OWN BODY. The art lane's model replaces the
		# theme creature's mesh; scale is art's measured ratio to the posed hero, not ours.
		var mb_path := miniboss_model(mb_key)
		if mb_path != "":
			def["path"] = mb_path
			def["h"] = MB_HERO_H * miniboss_ratio(mb_key, mb_path)
			def["anims"] = {}          # static meshes: no armature, no clip names apply
			def["hand"] = ""           # the model carries its own tools; no KayKit props
			def["off"] = ""
			def["lift"] = 0.0
			def["tint"] = Color(1, 1, 1)   # art painted it; a theme tint would repaint it
			def["glow"] = Color(0, 0, 0)
			def["particle"] = ""
			def["mb_model"] = true
		else:
			Delve.miniboss_no_model.append(mb_key)
	else:
		mb_key = ""
	var m := Monster.new()
	m.def = def
	m.state = Monster.S.PATROL
	m.roam = 2.0
	m.position = Vector3(pos.x, 0.0, pos.z)
	dun.add_child(m)
	_admit(m)
	# scale to this floor exactly like _next_floor does for ordinary spawns, then
	# the mini-boss multipliers on top
	m.max_hp = (14.0 + float(floor_no) * 6.0) * float(def.get("hp", 1.0)) * MINIBOSS_HP_MULT
	m.hp = m.max_hp
	m.set_meta("l29c_miniboss_purse", purse)
	m.set_meta("l29c_miniboss_rallied", false)
	var nm := String(def.get("name", "an elite"))
	if mb_key != "":
		m.set_meta("mb_key", mb_key)
		_say(_miniboss_say(mb_key, "arrive"))
		Delve.setpieces_fired["miniboss_feed_arrive"] = int(Delve.setpieces_fired.get("miniboss_feed_arrive", 0)) + 1
		if not MB_NAME.has(mb_key):
			nm = "The " + nm   # S51: only a leftover trade word takes "The"; a name never does
	_say("%s holds this chamber alone - a mini-boss stands between you and the way deeper." % nm)
	Sfx.play("roar", -2.0)
	# the atk bump rides on the meta the hit code already reads nowhere, so set
	# the def value directly: a copy of the pick with "atk" scaled
	var def2 := def.duplicate()
	def2["atk"] = float(def.get("atk", 4.0)) * MINIBOSS_ATK_MULT
	m.def = def2

## L-cycle 149 (bestiary depth): a boss or elite about to swing something big
## writes a one-line TELL to the Chronicle so the stream sees it coming - the
## "watch the wind-up" beat Mr. E has asked for in bits. Gated on boss=true so
## ordinary foes do not spam. Rate-limited per-monster (BOSS_TELL_EVERY) in case
## a boss's swing window is tight: one line per cadence, not one per tick.
const BOSS_TELL_EVERY := 3.5
func _boss_tell(mon: Monster, templ: String) -> void:
	if not is_instance_valid(mon):
		return
	if not bool(mon.def.get("boss", false)):
		return
	var last := float(mon.get_meta("boss_tell_t", -99.0))
	if _t - last < BOSS_TELL_EVERY:
		return
	mon.set_meta("boss_tell_t", _t)
	_say(templ % String(mon.def.get("name", "the lord")))
	Delve.bestiary_tells = int(Delve.bestiary_tells) + 1
## Static counter so the test can read telegraph firings without reaching into a
## live delve. Reset by tools that want deterministic counts.
static var bestiary_tells := 0

## R4 rally tick: scan the floor for any wounded miniboss still carrying the
## "rallied == false" meta and, once its hp dips below half, bump its atk and
## write the Chronicle line. Called from _fight() alongside the other per-tick
## reads - every fight is a handful of monsters, so the scan cost is nothing.
func _miniboss_rally_tick() -> void:
	if dun == null or not is_instance_valid(dun):
		return
	# iterate on INSTANCE-ID so a Monster that was queue_free'd earlier this
	# tick never gets typecast back to Monster (that throws "invalid freed
	# instance" on a cast, before any has_meta / state check can run)
	for mon_v in dun.monsters:
		if not is_instance_valid(mon_v):
			continue
		var mon: Monster = mon_v
		if mon.state == Monster.S.DEAD:
			continue
		if not mon.has_meta("l29c_miniboss_rallied") or bool(mon.get_meta("l29c_miniboss_rallied")):
			continue
		if mon.hp / maxf(1.0, mon.max_hp) > MINIBOSS_RALLY_FRAC:
			continue
		mon.set_meta("l29c_miniboss_rallied", true)
		Delve.setpieces_fired["miniboss_rally"] = int(Delve.setpieces_fired.get("miniboss_rally", 0)) + 1
		var d: Dictionary = mon.def.duplicate()
		d["atk"] = float(d.get("atk", 4.0)) * MINIBOSS_RALLY_MULT
		mon.def = d
		var nm := String(mon.def.get("name", "the elite"))
		_say("%s finds its second wind - its strikes land harder." % nm)
		Sfx.play("roar", -4.0)

## ---- the wizard's lamp-stand (old expedition._check_lamp / _light_check).
## Dead centre of every floor (FloorGen puts it there). A hero who reaches it
## sets it burning: the floor is lit even with an empty satchel. It never
## refills the satchel - it changes how a floor FIGHTS, never how deep a party
## can go - and it only matters once they are in the dark.
const LAMP_REACH := 5.0
var _lamp_lit := false
var lamps_lit := 0

func _light_check() -> void:
	var now := oil < 1.0 and not _lamp_lit
	if now != dark:
		dark = now
		if dark:
			# THE ARCHITECT'S BELLS: the final lantern guttering out anywhere
			_say("Somewhere below, a bell with no clapper rings once. The dungeon is one floor deeper than it was.")
			_say("The last lantern gutters out. They are fighting blind.")
	_apply_light()

func _check_lamp() -> void:
	if _lamp_lit or dun == null or not dun.info.has("lamp"):
		return
	var lamp: Vector3 = dun.info["lamp"] + dun.global_position
	for m in _alive():
		var b: Node3D = m["body"]
		if _flat(b.global_position, lamp) > LAMP_REACH:
			continue
		_lamp_lit = true
		lamps_lit += 1
		# "Don't touch the architect's toys." - one lighting in six
		if _rng.randf() < 0.17:
			_say("A brass hand-bell rests against the stand. It has no clapper. Nobody touches it.")
		if dark:
			_say("%s sets the wizard's lamp burning. The dark pulls back from floor %d." % [m["h"]["name"], floor_no])
		var l := OmniLight3D.new()
		l.name = "wizard_lamp"
		l.light_color = Color(1.0, 0.86, 0.62)
		l.light_energy = 11.0
		l.omni_range = 26.0
		l.set_meta("e0", 11.0)
		dun.add_child(l)
		l.global_position = lamp + Vector3(0, 2.4, 0)
		_light_check()
		return

## health bars: everyone in a fight, and anyone not at full health
func _bars(foes: Array) -> void:
	for m in party:
		var b = m["body"]
		if not is_instance_valid(b):
			continue
		var near := false
		for f in foes:
			if _flat((f as Node3D).global_position, (b as Node3D).global_position) < 10.0:
				near = true
				break
		HealthBar3D.on(b, 2.05, false).set_hp(float(m["hp"]), float(m["max"]), near)
	for f in foes:
		var mo: Monster = f
		var near2 := false
		for m2 in _alive():
			if _flat((m2["body"] as Node3D).global_position, mo.global_position) < 10.0:
				near2 = true
				break
		HealthBar3D.on(mo, mo._height() + 0.25, true).set_hp(mo.hp, mo.max_hp, near2)

## the dark is shown, not just rolled: the floor's own lights sink to embers
func _apply_light() -> void:
	if dun == null:
		return
	for n in dun.find_children("*", "Light3D", true, false):
		if n.name == "wizard_lamp":
			continue
		var L: Light3D = n
		if not L.has_meta("e0"):
			L.set_meta("e0", L.light_energy)
		L.light_energy = float(L.get_meta("e0")) * (0.22 if dark else 1.0)

func _d20(adv: int) -> int:
	var a := _rng.randi_range(1, 20)
	if adv == 0:
		return a
	var b := _rng.randi_range(1, 20)
	return maxi(a, b) if adv > 0 else mini(a, b)

func _census() -> String:
	var counts := {}
	for mon in dun.monsters:
		var nm := String((mon as Monster).def.get("name", "thing"))
		counts[nm] = int(counts.get(nm, 0)) + 1
	var parts: Array = []
	for k in counts:
		var nm := String(k)
		parts.append("%d %s" % [counts[k], nm if int(counts[k]) == 1 or nm.ends_with("s") else nm + "s"])
	return ", ".join(parts) if not parts.is_empty() else "nothing stirring"

func _party_uids(ms: Array) -> Array:
	var out: Array = []
	for m in ms:
		out.append(m["uid"])
	return out

## the floor's lord while it is up and fighting (risen, alive), else null:
## the boss bar and the director watch this
func lord_fighting() -> Monster:
	if state != "fight" or dun == null or not is_instance_valid(dun) or _alive().is_empty():
		return null
	if dun.lord == null or not is_instance_valid(dun.lord):
		return null
	var l: Monster = dun.lord
	if l.state == Monster.S.DEAD or l._entering():
		return null
	return l

## S64: counters for the mana gate test - spells paid for, and caster swings taken dry
var mana_casts := 0
var mana_dry_swings := 0

func _foes() -> Array:
	var out: Array = []
	for mon in dun.monsters:
		if is_instance_valid(mon) and (mon as Monster).state != Monster.S.DEAD:
			out.append(mon)
	if dun.lord and is_instance_valid(dun.lord) and dun.lord.state != Monster.S.DEAD and not dun.lord._entering():
		out.append(dun.lord)
	return out

## ---------------------------------------------------------------- pathing
## Through the floor's occupancy grid (FloorGen cells), never through walls or
## across the void between rooms. Routes are cached and refreshed twice a second.
var _paths := {}                   # node -> [cells(world pts), t]

func _cell_of(p: Vector3) -> Vector2i:
	var G: float = dun.info["grid"]
	var hw := (float(dun.info["w"]) - 1.0) * G * 0.5
	var hh := (float(dun.info["h"]) - 1.0) * G * 0.5
	var o := dun.global_position
	return Vector2i(int(round((p.x - o.x + hw) / G)), int(round((p.z - o.z + hh) / G)))

func _cell_world(c: Vector2i) -> Vector3:
	var G: float = dun.info["grid"]
	var hw := (float(dun.info["w"]) - 1.0) * G * 0.5
	var hh := (float(dun.info["h"]) - 1.0) * G * 0.5
	return dun.global_position + Vector3(float(c.x) * G - hw, 0.05, float(c.y) * G - hh)

## L25c: the cells a body cannot stand in the middle of (an obstacle covers the centre),
## worked out once a floor
var _blocked_for: Node = null
var _blocked := {}
func _blocked_cells() -> Dictionary:
	if _blocked_for == dun:
		return _blocked
	_blocked_for = dun
	_blocked = {}
	var cells: Dictionary = dun.info["cells"]
	for c: Vector2i in cells:
		var w := _cell_world(c) - dun.global_position
		for o in dun.info.get("obstacles", []):
			if FloorGen.obst_gap(o, w.x, w.z) < 0.45:
				_blocked[c] = true
				break
	return _blocked

## L25c: the clear cells labelled by which connected patch of them they belong to (a body can
## walk between two cells of one patch without crossing furniture), worked out once a floor
var _comp_for: Node = null
var _comp := {}
func _patches() -> Dictionary:
	if _comp_for == dun:
		return _comp
	_comp_for = dun
	_comp = {}
	var cells: Dictionary = dun.info["cells"]
	var bl := _blocked_cells()
	var id := 0
	for s: Vector2i in cells:
		if bl.has(s) or _comp.has(s):
			continue
		_comp[s] = id
		var q: Array[Vector2i] = [s]
		while not q.is_empty():
			var c: Vector2i = q.pop_back()
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = c + d
				if cells.has(n) and not bl.has(n) and not _comp.has(n):
					_comp[n] = id
					q.append(n)
		id += 1
	return _comp

## L25c: a body (half-width 0.45) can stand at p: a clear floor cell, off every obstacle and
## a body's width clear of the walls (kit walls reach 0.5 m into the cell)
func _standable(p: Vector3) -> bool:
	var cells: Dictionary = dun.info["cells"]
	var c := _cell_of(p)
	if not cells.has(c) or _blocked_cells().has(c):
		return false
	var G: float = dun.info["grid"]
	var ctr := _cell_world(c)
	for dir: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if cells.has(c + dir):
			continue
		var off := (p.x - ctr.x) * float(dir.x) + (p.z - ctr.z) * float(dir.y)
		if off > G * 0.5 - 0.95:
			return false
	var o0 := dun.global_position
	for o in dun.info.get("obstacles", []):
		if FloorGen.obst_gap(o, p.x - o0.x, p.z - o0.z) < 0.5:
			return false
	return true

## L25c: where a delver stands to fight tgt. Its own side of the ring first (idx of n, turned
## by slot_off), then the nearest side round from it, then nearer in / further out - only a
## point the delver can stand on and walk to (the old fixed ring put slots round a big lord in
## the wall or the hoard, and the delver pushed at them the whole fight). Kept for half a second
## while the target holds still. Melee rings sit INSIDE reach (a tall lord's old ring did not).
func _fight_slot(m: Dictionary, b: Node3D, tgt: Monster, idx: int, n: int, ranged: bool, reach: float) -> Vector3:
	var tp := tgt.global_position
	var sp = m.get("slot_pt")
	if sp != null and _t - float(m.get("slot_t", -9.0)) < 0.5 and _flat(tp, m.get("slot_at", tp)) < 0.8 \
			and int(m.get("slot_tgt", 0)) == tgt.get_instance_id():
		return sp
	var base := float(idx) * TAU / float(maxi(n, 1)) + float(m.get("slot_off", 0.0))
	var trad := clampf(tgt._height() * 0.2, 0.3, 1.8)
	var radii: Array
	if ranged:
		radii = [5.0, 4.0, 6.5, 3.0, 8.0]
	else:
		var r0 := clampf(trad + 0.75, 1.1, reach - 0.35)
		radii = [r0, clampf(r0 - 0.4, trad + 0.45, reach - 0.35), reach - 0.2]
	var pat := _patches()
	var mine := int(pat.get(_cell_of(b.global_position), -1))
	var pick = null
	for k in range(0, 17):
		var a := base + floorf((k + 1) / 2.0) * (1.0 if k % 2 == 1 else -1.0) * TAU / 16.0
		for r in radii:
			var p := tp + Vector3(cos(a), 0, sin(a)) * float(r)
			if not _standable(p):
				continue
			if mine >= 0 and int(pat.get(_cell_of(p), -2)) != mine:
				continue
			pick = p
			break
		if pick != null:
			break
	if pick == null:
		var r_old: float = 5.0 if ranged else clampf(trad + 0.75, 1.1, reach - 0.35)
		pick = tp + Vector3(cos(base), 0, sin(base)) * r_old
	m["slot_pt"] = pick
	m["slot_at"] = tp
	m["slot_t"] = _t
	m["slot_tgt"] = tgt.get_instance_id()
	return pick

## the route through the floor's cells, around the cells furniture blocks (the plain grid if
## that leaves no way through)
func _bfs(a: Vector2i, b: Vector2i) -> Array:
	var r := _bfs_on(a, b, _blocked_cells())
	return r if not r.is_empty() or a == b else _bfs_on(a, b, {})

func _bfs_on(a: Vector2i, b: Vector2i, avoid: Dictionary) -> Array:
	var cells: Dictionary = dun.info["cells"]
	if not cells.has(a) or not cells.has(b):
		return []
	# D88: a dropped portcullis's cells are HARD - never walked, not even by the fallback that
	# ignores furniture (that fallback is how a body would otherwise be routed through the bars)
	var hard: Dictionary = dun.info.get("hard", {})
	var prev := {a: a}
	var q: Array[Vector2i] = [a]
	while not q.is_empty():
		var c: Vector2i = q.pop_front()
		if c == b:
			break
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if cells.has(n) and not prev.has(n) and not hard.has(n) and (not avoid.has(n) or n == b):
				prev[n] = c
				q.append(n)
	if not prev.has(b):
		return []
	var out: Array = []
	var cur := b
	while cur != a:
		out.push_front(_cell_world(cur))
		cur = prev[cur]
	return out

## nearest floor cell to c (rings outward), or c itself if it is floor
func _snap_cell(c: Vector2i) -> Vector2i:
	var cells: Dictionary = dun.info["cells"]
	if cells.has(c):
		return c
	for r in range(1, 12):
		var best := Vector2i(-9999, -9999)
		var bd := 1e9
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				if absi(dx) != r and absi(dz) != r:
					continue
				var n := c + Vector2i(dx, dz)
				if cells.has(n):
					var dd := float(dx * dx + dz * dz)
					if dd < bd:
						bd = dd
						best = n
		if best.x != -9999:
			return best
	return c

## move n toward `to` along the grid; true when within `stop` of it. Bodies
## only ever walk floor cells: a goal off the floor (a ring slot behind a wall,
## a point in the void between rooms) is moved to the nearest floor cell, and
## nobody takes a straight line across anything that is not floor.
## L25: who is on the move this frame (body -> frame), and how often a party was carried to the
## stairs because someone could not get there (tests read both - a stuck delver used to be hidden
## by the descent timeout)
var travel := {}
var forced := 0
var _prog := {}            # body -> [the nearest it has got to its goal, when]

## L25: no closer to where it is going for `secs` (it is pressed against something)
func stuck_on(n: Node3D, secs := 1.2) -> bool:
	var p: Array = _prog.get(n, [])
	return not p.is_empty() and _t - float(p[1]) > secs

func _go(n: Node3D, to: Vector3, spd: float, delta: float, stop := 0.3) -> bool:
	travel[n] = Engine.get_process_frames()
	var cells: Dictionary = dun.info["cells"]
	var cb_raw := _cell_of(to)
	var cb := _snap_cell(cb_raw)
	if cb != cb_raw:
		to = Vector3(_cell_world(cb).x, to.y, _cell_world(cb).z)
	# L25c: a goal inside furniture can never be reached (a ranged delver's side of a lord
	# beside the hoard) - the nearest clear cell instead
	if n is HeroBody and _blocked_cells().has(cb):
		var bd2 := 1e9
		var alt := cb
		for c: Vector2i in dun.info["cells"]:
			if not _blocked_cells().has(c):
				var d2 := Vector2(c - cb).length()
				if d2 < bd2:
					bd2 = d2
					alt = c
		cb = alt
		to = Vector3(_cell_world(cb).x, to.y, _cell_world(cb).z)
	var dist_to := _flat(n.global_position, to)
	if dist_to <= stop:
		travel.erase(n)           # arrived: not on the move
		_prog.erase(n)
		return true
	var ca_raw := _cell_of(n.global_position)
	var ca := _snap_cell(ca_raw)
	if ca != ca_raw:
		# somehow off the floor: step straight back onto the nearest cell
		_step(n, _cell_world(ca), spd, delta)
		return false
	var pts: Array = []
	var left := dist_to
	if ca != cb:
		var e: Array = _paths.get(n, [])
		if e.is_empty() or _t - float(e[1]) > 0.5 or (e[0] as Array).is_empty():
			e = [_bfs(ca, cb), _t]
			_paths[n] = e
		pts = e[0]
		# D88: no way through because a portcullis is down - this body is cut off and waiting for
		# the gate to be forced or wound up. That is a deliberate wait, not a wedge: hold still
		# and keep the watchdog's clock at zero (it would otherwise lift the body over the bars).
		if pts.is_empty() and not (dun.info.get("hard", {}) as Dictionary).is_empty():
			_prog[n] = [dist_to, _t, to, n.global_position]
			gate_held[n] = Engine.get_process_frames()
			return false
		if not pts.is_empty():
			# L25c: progress is the way LEFT along the route, not the straight line - a route that
			# bends away from a far stair or target is not being stuck
			left = _flat(n.global_position, pts[0]) + _flat(pts[-1], to)
			for i in range(1, pts.size()):
				left += _flat(pts[i - 1], pts[i])
	var pg: Array = _prog.get(n, [])
	# (a goal that moves - a delver backing off, a beast circling - starts the clock again, if the
	# body is following it and not pressed against something)
	if pg.is_empty() or left < float(pg[0]) - 0.2 or absf(left - float(pg[0])) > 12.0 \
			or (_flat(to, pg[2]) > 1.0 and _flat(n.global_position, pg[3]) > 0.5):
		_prog[n] = [left, _t, to, n.global_position]     # progress (or a new goal far from the old one)
	elif _t - float(pg[1]) > 2.0:
		unstick_log.append("f%d %s %s %s at %s -> %s (%.1f m left, %s)" % [floor_no, state, n.name, ("hero" if n is HeroBody else "mon"), n.global_position.snappedf(0.1), to.snappedf(0.1), left, "same" if ca == cb else "diff"] + _why(n, pts))
		_unstick(n, cb)
		return false
	if ca == cb:
		_step(n, to, spd, delta)
		return false
	if pts.is_empty():
		return false          # no way through: wait rather than walk a wall
	var nxt: Vector3 = pts[0]
	nxt.y = n.global_position.y
	var before := _flat(n.global_position, nxt)
	var arrived := _step(n, nxt, spd, delta)
	var after := _flat(n.global_position, nxt)
	# a waypoint inside a table can never be reached: count it as reached
	# once the body can get no closer (it is pressed against the furniture)
	if arrived or after < 0.4 or (after < 3.0 and before - after < spd * delta * 0.2):
		pts.remove_at(0)
	return false

## ---------------------------------------------------------------- D91 stage 4: in file
## A party that cannot walk abreast walks in FILE - deliberately, spaced, in an order - instead
## of piling into one cell. In a hall the delvers fall into a column: whoever is nearest the
## goal (by the route, not the crow's flight) leads, and each of the rest walks behind the one
## ahead of it, FILE_GAP back. In a room they go for the goal as before. The order is worked
## out twice a second so it does not shuffle every frame.
const FILE_GAP := 1.7
const FILE_NEAR := 7.0           # further behind than this and a delver just catches up
var _file_order: Array = []
var _file_t := -9.0
var _file_goal := Vector3.ZERO
var file_frames := 0             # frames in which someone walked in file (the D91 test reads it)
var _file_frame := -1

func _halls() -> Dictionary:
	return dun.info.get("halls", {})

func _route_len(b: Node3D, goal: Vector3) -> int:
	var r := _bfs(_snap_cell(_cell_of(b.global_position)), _snap_cell(_cell_of(goal)))
	return r.size()

func _file_of(goal: Vector3) -> Array:
	if _t - _file_t < 0.5 and _flat(goal, _file_goal) < 0.5 and _file_order.size() == _alive().size():
		return _file_order
	_file_t = _t
	_file_goal = goal
	var keyed: Array = []
	for m in _alive():
		var b: Node3D = m["body"]
		keyed.append([_route_len(b, goal) * 100.0 + _flat(b.global_position, goal), m])
	keyed.sort_custom(func(x, y): return float(x[0]) < float(y[0]))
	_file_order = []
	for k in keyed:
		_file_order.append(k[1])
	return _file_order

func _go_file(m: Dictionary, goal: Vector3, spd: float, delta: float, stop: float) -> bool:
	var b: Node3D = m["body"]
	var order := _file_of(goal)
	var i := order.find(m)
	if i > 0 and _halls().has(_snap_cell(_cell_of(b.global_position))):
		var ahead: Node3D = (order[i - 1] as Dictionary)["body"]
		var dd := _flat(b.global_position, ahead.global_position)
		if dd < FILE_NEAR and _flat(ahead.global_position, goal) > stop + FILE_GAP:
			if _file_frame != Engine.get_process_frames():
				_file_frame = Engine.get_process_frames()
				file_frames += 1
			# behind the one ahead: close up to FILE_GAP, never past them
			if dd <= FILE_GAP + 0.15:
				travel.erase(b)
				_prog.erase(b)
				return false
			_go(b, ahead.global_position, minf(spd, spd * (dd / (FILE_GAP * 2.0)) + 0.5), delta, FILE_GAP)
			return false
	return _go(b, goal, spd, delta, stop)

func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

## ---------------------------------------------------------------- D91: bodies below ground
## The dungeon had NO body separation at all - delvers and monsters stood in each other. Every
## delver and every live monster now goes into the SAME Crowd the town uses (scripts/crowd.gd,
## one copy, not a second), filled once a frame. _step takes its shove (soft ring, hard inside
## two bodies' width, and the yield that makes two meeting in a hall pass on the side); and
## _crowd_settle, at the end of every frame, parts any pair still closer than the sum of their
## body_r - which is the done test's line - so a pack converging on one hero ends as a ring.
var _crowd := Crowd.new()
var _crowd_f := -1
var crowd_worst := 0.0           # the deepest overlap the settle pass found (the D91 test reads it)

func _mrad(mon: Monster) -> float:
	var rad := float(mon.get_meta("rad", -1.0))
	if rad < 0.0:
		rad = clampf(mon._height() * 0.2, 0.3, 1.8)
		mon.set_meta("rad", rad)
	mon.body_r = rad
	return rad

func _crowd_bodies() -> Array:
	var out: Array = []
	for m in _alive():
		var b = m.get("body")
		if b != null and is_instance_valid(b):
			out.append(b)
	if dun and is_instance_valid(dun):
		for mon in _foes():
			if (mon as Monster)._entering():
				continue
			_mrad(mon)
			out.append(mon)
	return out

func _crowd_fill() -> void:
	var f := Engine.get_process_frames()
	if f == _crowd_f:
		return
	_crowd_f = f
	_crowd.reset()
	for b in _crowd_bodies():
		_crowd.add(b)

## where a body of radius r may be set down: on a floor cell, r + the wall's 0.5 m clear of any
## wall, and out of every obstacle
func _settle_ok(p: Vector3, r: float, _b: Node3D = null) -> bool:
	var cells: Dictionary = dun.info["cells"]
	var c := _cell_of(p)
	if not cells.has(c):
		return false
	var G: float = dun.info["grid"]
	var ctr := _cell_world(c)
	var keep := minf(r + 0.5, G * 0.5 - 0.05)
	for dir: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if cells.has(c + dir):
			continue
		var off := (p.x - ctr.x) * float(dir.x) + (p.z - ctr.z) * float(dir.y)
		if off > G * 0.5 - keep:
			return false
	var o0 := dun.global_position
	for o in dun.info.get("obstacles", []):
		if FloorGen.obst_gap(o, p.x - o0.x, p.z - o0.z) < 0.3:
			return false
	return true

## D91c: the settle itself now lives in crowd.gd (Crowd.settle), shared with the town - one
## copy. Up to 48 bodies it checks every pair, as the loop that lived here did.
func _crowd_settle() -> void:
	crowd_worst = Crowd.settle(_crowd_bodies(), _settle_ok)

func _step(n: Node3D, to: Vector3, spd: float, delta: float) -> bool:
	var d := Vector3(to.x - n.global_position.x, 0, to.z - n.global_position.z)
	if d.length() < 0.05:
		return true
	var p := n.global_position + d.normalized() * minf(spd * delta, d.length())
	# D91: the shared Crowd's shove and yield - the same maths the town walks by
	var md := d.normalized()
	if n is Monster:
		(n as Monster).move_dir = md
	elif n is Townsfolk:
		(n as Townsfolk).move_dir = md
	_crowd_fill()
	var shove := _crowd.push(n, md) * delta
	if shove.length() > spd * delta * 1.5:
		shove = shove.normalized() * spd * delta * 1.5
	p += Vector3(shove.x, 0.0, shove.z)
	# bodies go AROUND what stands on the floor: pushed out of every table,
	# barrel, pillar and tree they would walk into - so they slide past it
	if dun and dun.info.has("obstacles"):
		var o0 := dun.global_position
		var cells: Dictionary = dun.info["cells"]
		var step_len := minf(spd * delta, d.length())
		for o in dun.info["obstacles"]:
			# D88: a wall-shaped obstacle (a dropped portcullis, a cell) is a box: out through the
			# face the body came from, never round a rim and never through to the far side
			if (o as Array).size() >= 5:
				if FloorGen.obst_gap(o, p.x - o0.x, p.z - o0.z) >= 0.45:
					continue
				var was := n.global_position
				var q := FloorGen.obst_push(o, p.x - o0.x, p.z - o0.z, 0.45, was.x - o0.x, was.z - o0.z)
				var outp := Vector3(q.x + o0.x, p.y, q.y + o0.z)
				p = outp if cells.has(_cell_of(outp)) else n.global_position
				continue
			var c: Vector3 = (o[0] as Vector3) + o0
			var need := float(o[1]) + 0.45
			var dd := Vector2(p.x - c.x, p.z - c.z)
			if dd.length() >= need:
				continue
			var dir := dd.normalized() if dd.length() > 0.01 else Vector2(d.z, -d.x).normalized()
			# L25c: walking INTO it, slide round its rim instead of being pushed straight back (a
			# body heading dead at a table on its route stood pressed against it for good). Dead
			# on, it keeps the side it took last, so it does not dither; a side that runs into
			# stone is swapped for the other.
			var mv := Vector2(d.x, d.z).normalized()
			if dir.dot(mv) < -0.2:
				var tg := Vector2(-dir.y, dir.x)
				var side := tg.dot(mv)
				if absf(side) < 0.35:
					side = float(n.get_meta("slide", 1.0))
				var sgn := 1.0 if side >= 0.0 else -1.0
				var took := false
				for s in [sgn, -sgn]:
					var a2 := (dir + tg * float(s) * (step_len / need)).normalized()
					var rim := Vector3(c.x + a2.x * need, p.y, c.z + a2.y * need)
					if cells.has(_cell_of(rim)):
						n.set_meta("slide", float(s))
						p = rim
						took = true
						break
				if not took:
					p = n.global_position       # hold rather than go through stone
				continue
			var pushed := Vector3(c.x + dir.x * need, p.y, c.z + dir.y * need)
			if cells.has(_cell_of(pushed)):
				p = pushed
				continue
			# pushing out would cross a wall: slide round the obstacle on the
			# floor side instead (whichever way round heads toward the goal)
			var tan := Vector2(-dir.y, dir.x)
			if tan.dot(Vector2(d.x, d.z)) < 0.0:
				tan = -tan
			var slide := n.global_position + Vector3(tan.x, 0, tan.y) * step_len
			if cells.has(_cell_of(slide)):
				p = slide
			else:
				p = n.global_position       # hold rather than go through stone
	# a creature has a body, not a point: it keeps its own half-width off any
	# wall (big lords and wide beasts were walking half into the stone)
	if n is Monster and dun and dun.info.has("cells"):
		var rad := _mrad(n as Monster)
		var G: float = dun.info["grid"]
		var cl: Dictionary = dun.info["cells"]
		var cc := _cell_of(p)
		if cl.has(cc):
			var ctr := _cell_world(cc)
			for dir: Vector3 in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
				if cl.has(cc + Vector2i(int(dir.x), int(dir.z))):
					continue
				var wall: float = (ctr + dir * G * 0.5).dot(dir)
				var over: float = (p + dir * minf(rad, G * 0.5 - 0.05)).dot(dir) - wall
				if over > 0.0:
					p -= dir * over
	p.y = n.global_position.y
	# last guard: a step that would end beyond the walls is not taken
	if dun and dun.info.has("cells") and not (dun.info["cells"] as Dictionary).has(_cell_of(p)) \
			and (dun.info["cells"] as Dictionary).has(_cell_of(n.global_position)):
		return false
	n.global_position = p
	n.rotation.y = atan2(d.x, d.z)
	return _flat(p, to) < 0.05

func _process(delta: float) -> void:
	if dun == null or not is_instance_valid(dun):
		return
	_tags_tick(delta)
	_amb_tick(delta)          # S2: the quiet bed below
	_t += delta
	_gt += delta
	# S64: the mana pool refills only out of combat
	if state != "fight" and roster != null:
		for mm in _alive():
			roster.regen_mana(mm["h"], delta)
	match state:
		"fight":
			_fight(delta)
		"search":
			# L49: the floor is clear - someone is going through the chests before they move on
			_traps_tick()
			_bags_tick()
			_setpieces_tick()           # L29c: a seeker walking to a chest can trip an ambush
			_search_tick(delta)
		"descend":
			# L46: traps were only ever checked inside _fight(), so the whole walk to the stairs
			# - where most of the floor is actually crossed - was trap-free. Measured: 6 of 6
			# traps were walked within reach of, but only 2 were ever MET. They are live now
			# wherever the party is moving.
			_traps_tick()
			_bags_tick()                # S164: and so is a corpse-run bag lying on the way
			_setpieces_tick()           # L29c: ambushes trigger on the walk too, not just mid-fight
			var ex: Vector3 = dun.info["exit"] + dun.global_position
			var all_there := true
			for m in _alive():
				var b: HeroBody = m["body"]
				if not _go_file(m, ex, 5.0, delta, 0.8):
					all_there = false
					if int(travel.get(b, -1)) == Engine.get_process_frames():
						Rig.play(b._anim, "Walking_A")
					else:
						Rig.play(b._anim, "Idle")
			# L25: on to the next floor when all are at the stairs; a delver who has truly stopped
			# getting closer (3 s) is carried, and counted - the old flat 6 s cut off a long walk
			var stopped := false
			for m in _alive():
				if stuck_on(m["body"], 3.0):
					stopped = true
			if all_there or stopped or _t > 90.0:          # D91: floors grew - the walk is longer
				if not all_there:
					forced += 1
				_next_floor()
		"flee":
			# L47: the party broke off a losing fight. They RUN for the way up, visibly, and
			# the delve ends when they are there (or when they plainly cannot get there).
			_traps_tick()      # L46: and a panicked run out is no safer than the walk in
			var up: Vector3 = dun.info["entry"] + dun.global_position
			var all_up := true
			for m in _alive():
				var fb: HeroBody = m["body"]
				if not _go_file(m, up, roster.speed(m["h"]) * 1.15, delta, 0.9):
					all_up = false
					Rig.play(fb._anim, "Running_A")
			var jammed := false
			for m in _alive():
				if stuck_on(m["body"], 3.0):
					jammed = true
			if _alive().is_empty():
				_say("The scar keeps them all. No one comes home from floor %d." % floor_no)
				_finish()
			elif all_up or jammed or _t > 90.0:
				_say("%s get out alive, and come home with what they carried." % _names())
				_finish()
		"home":
			pass
	# D91: nobody ends a frame inside anybody. The settle runs LATE in the frame (a child node
	# at a high process_priority), after every Monster has taken its own patrol step - settled
	# here, a pack's wander could still put two in one spot before the frame was drawn.
	if _settler == null:
		_settler = _Settler.new()
		_settler.d = self
		_settler.process_priority = 1000
		add_child(_settler)

class _Settler extends Node:
	var d: Node
	func _process(_dt: float) -> void:
		if d.state != "home" and d.dun != null and is_instance_valid(d.dun):
			d._crowd_settle()

var _settler: Node = null

## ---------------------------------------------------------------- L47: delvers think
## Mr. E marked this the priority of the whole list: the delvers "read as mindless". The rule
## here is that a decision is only worth making if a VIEWER CAN SEE IT. So every branch below
## does two things together - the body does something visible (breaks off and runs for the way
## up, falls back to the others, drinks, switches target) AND the Chronicle says WHY. A silent
## stat change is not a decision as far as this item is concerned.
## Announcements are rate-limited per hero so a long fight reads as a few deliberate choices
## rather than a wall of chatter; the decision itself is never rate-limited, only the line.
const DECIDE_EVERY := 3.0        # s between one hero's announced decisions
const FLEE_AT := 0.22            # hp fraction at which a hero breaks off alone
const REGROUP_M := 15.0          # further than this from the party's centre is isolated
var decisions := 0               # every announced decision (the L47 test counts these)
var _fleeing_party := false      # L47: the party has broken off a losing fight
var decided := {}                # kind -> count, so the test can see a RANGE of decisions

func _decide(m: Dictionary, kind: String, line: String) -> void:
	decided[kind] = int(decided.get(kind, 0)) + 1
	decisions += 1
	if _t < float(m.get("decide_t", -99.0)) + DECIDE_EVERY:
		return                                  # thought it, acted on it, just does not say so
	m["decide_t"] = _t
	_say(line)

func _party_centre(alive: Array) -> Vector3:
	var c := Vector3.ZERO
	var n := 0
	for o in alive:
		var ob = o["body"]
		if is_instance_valid(ob):
			c += (ob as Node3D).global_position
			n += 1
	return c / maxf(1.0, float(n))

## L47: a target that makes sense instead of whatever is nearest. Finish the one that is nearly
## down, shut up the one that casts or spits from range, and otherwise take the near one.
func _pick_target(b: Node3D, foes: Array) -> Monster:
	var best: Monster = null
	var best_s := -1.0e9
	for f in foes:
		if not is_instance_valid(f):
			continue
		var mon := f as Monster
		var d := _flat((mon as Node3D).global_position, b.global_position)
		# distance is a WEIGHT, not the whole score - at 1.0/m it swamped everything and the
		# pick was just "nearest" again with extra steps
		var s := -d * 0.35
		var frac := mon.hp / maxf(1.0, mon.max_hp)
		s += (1.0 - frac) * 20.0                        # the nearer it is to down, the better
		var ways: Dictionary = mon.def.get("ways", {})
		if ways.has("cast") or ways.has("spit") or ways.has("shoot"):
			s += 14.0                                   # the one hurting us from range
		if s > best_s:
			best_s = s
			best = mon
	return best

## L47: one hero's own call, taken before they swing. Returns true when the decision has used
## their action this tick (so the attack path below is skipped).
func _think(m: Dictionary, foes: Array, alive: Array, delta: float) -> bool:
	var b = m["body"]
	if not is_instance_valid(b):
		return false
	var h: Dictionary = m["h"]
	var nm := String(h.get("name", "A delver"))
	var frac := float(m["hp"]) / maxf(1.0, float(m["max"]))

	# ALREADY RUNNING: keep going for the way up until out of the fight
	if bool(m.get("fleeing", false)):
		var up: Vector3 = dun.info["entry"] + dun.global_position
		_go(b, up, roster.speed(h) * 1.15, delta)
		Rig.play((b as HeroBody)._anim, "Running_A")
		if frac > 0.55:                                  # mended enough to turn and fight again
			m["fleeing"] = false
			_decide(m, "rejoin", "%s has the wind back and turns to fight." % nm)
		return true

	# BREAK OFF: badly hurt, nothing left to drink - get out rather than die in place
	if frac < FLEE_AT and not _has_heal_brew(h):
		m["fleeing"] = true
		_decide(m, "flee", "%s is badly hurt and breaks off, making for the way up." % nm)
		return true

	# REGROUP: cut off from the others with foes about - fall back to them
	if alive.size() > 1 and not foes.is_empty():
		var c := _party_centre(alive)
		if _flat((b as Node3D).global_position, c) > REGROUP_M:
			_go(b, c, roster.speed(h), delta)
			Rig.play((b as HeroBody)._anim, "Running_A")
			_decide(m, "regroup", "%s is cut off and falls back to the others." % nm)
			return true
	return false

func _has_heal_brew(h: Dictionary) -> bool:
	for k in HEAL_ORDER:
		if roster.brew_count(h, k) > 0:
			return true
	return false

## L47: the party's own call. A fight that is plainly lost is broken off as a party - they run
## for the way up instead of standing there being killed one by one (Mr. E's "a hurt party
## retreats rather than dying in place").
func _losing(alive: Array, foes: Array) -> bool:
	if alive.is_empty() or foes.is_empty():
		return false
	var frac := 0.0
	for m in alive:
		frac += float(m["hp"]) / maxf(1.0, float(m["max"]))
	frac /= float(alive.size())
	# badly hurt AND outnumbered, or on the brink whatever the count
	return frac < 0.18 or (frac < turn_back_at and foes.size() >= alive.size() * 2)

func _fight(delta: float) -> void:
	_check_lamp()
	_traps_tick()
	_bags_tick()                            # S164: a delver walking over a corpse-run bag
	_setpieces_tick()                       # L29c: AMBUSH triggers as the party walks past
	_miniboss_rally_tick()                  # L29c r4: half-hp rally on the mini-boss
	_blows_tick(delta)
	var foes := _foes()
	_bars(foes)
	var alive := _alive()
	if alive.is_empty():
		_say("The scar keeps them all. No one comes home from floor %d." % floor_no)
		_finish()
		return
	if foes.is_empty() and not (dun.lord and dun.lord._entering()):
		# D83: a creature that came up mid-search or on the walk to the stairs has been dealt
		# with - back to what it interrupted. The floor was already paid for and the breather
		# already taken; neither happens twice.
		if _back_to != "":
			state = _back_to
			_back_to = ""
			_t = 0.0
			_nav_reset()
			return
		# floor won: pay out, then SEARCH what is on the floor before deciding (L49)
		_loot(alive)
		if not _unsearched().is_empty():
			state = "search"
			_t = 0.0
			_nav_reset()
			return
		_floor_decision(alive)
		return

	# venom keeps working after the bite (spider, snake, adder, wasp)
	_fight_body(delta, alive, foes)

## ---- L29a: a lord changing phase, in the Chronicle. The mechanics themselves were already
## canon (Bestiary.LORD_WAYS gives all eight a real one); what was missing was any sense that a
## lord gets WORSE as it is worn down. The aura does it on the lord; this does it in words.
var lord_phases := 0                # the L29a test counts these

func _lord_phase(who: Monster, to: int) -> void:
	if not is_instance_valid(who):
		return
	lord_phases += 1
	var nm := String(who.def.get("name", "The lord"))
	if to >= 3:
		_say("%s is driven to its last - whatever it has been holding back, it is not holding it now." % nm)
	else:
		_say("%s shifts, and the fight changes with it." % nm)
	FeedHUD.card_on(town, nm, "phase %d of %d" % [to, who.phase_count],
		who.def.get("aura", Color(1, 0.8, 0.4)) as Color)

## ---------------------------------------------------------------- L49: searching, visibly
## Mr. E: "no chests, no drops, nobody searching". The loot ROLL already existed - it just
## happened invisibly the instant a floor was cleared, with no chest, nobody walking anywhere
## and nothing to watch. Now a delver walks to the chest, kneels over it for a beat, and the
## Chronicle says which way it went - BOTH outcomes, in his words.
const SEARCH_S := 1.8               # how long a delver spends over a chest
const SEARCH_REACH := 1.6
var chests_found := 0               # the L49 test / census counts these
var chests_empty := 0
var chests_unreachable := 0     # L49 regression guard: chests abandoned rather than pinning a delver
var _search_i := -1                 # which chest is being worked on
var _search_t := 0.0

func _unsearched() -> Array:
	var out: Array = []
	if dun == null or not dun.info.has("chests"):
		return out
	for c in dun.info["chests"]:
		var cd: Dictionary = c
		if not bool(cd.get("searched", false)) and is_instance_valid(cd["node"]):
			out.append(cd)
	return out

## the party's sharpest eye does the searching, as _loot already decides
func _seeker(alive: Array) -> Dictionary:
	var s: Dictionary = alive[0]
	for m in alive:
		if _search_bonus(m["h"]) > _search_bonus(s["h"]):
			s = m
	return s

func _search_tick(delta: float) -> void:
	var alive := _alive()
	var left := _unsearched()
	# L49 REGRESSION, caught by _l25_test: a chest can sit somewhere the party cannot actually
	# path to, and the seeker then ground against it for the whole 30 s window - _l25 reported
	# "floor 10 Bree ... (search)" as a stuck delver. A chest is a nice-to-have, never a reason
	# to pin someone to the floor, so an unreachable one is abandoned (see stuck_on below) and
	# the whole searching phase is capped far shorter.
	if alive.is_empty() or left.is_empty() or _t > 12.0:
		_search_t = 0.0
		_purses_left(alive)          # S83: a spilled purse is never lost to the search cap
		_floor_decision(_alive())
		return
	var cd: Dictionary = left[0]
	for c in left:
		if (c as Dictionary).has("purse"):
			cd = c          # S83: gold lying on the floor is gone to first, before any chest
			break
	var node: Node3D = cd["node"]
	var m := _nearest_to(alive, node.global_position) if cd.has("purse") else _seeker(alive)
	var b: HeroBody = m["body"]
	if not is_instance_valid(b):
		cd["searched"] = true
		return
	var at := node.global_position
	if _flat(b.global_position, at) > SEARCH_REACH:
		# give up on a chest we are plainly not getting to, rather than grinding at it
		if stuck_on(b, 2.0):
			cd["searched"] = true
			if cd.has("purse"):
				_take_purse(m, cd)
				return
			chests_unreachable += 1
			_prog.erase(b)
			_say("%s cannot get to the chest and leaves it." % m["h"]["name"])
			return
		_go(b, at, roster.speed(m["h"]), delta, SEARCH_REACH * 0.8)
		Rig.play(b._anim, "Walking_A")
		_search_t = 0.0
		return
	# at the chest: kneel over it for a beat so the search is something you can WATCH
	b.rotation.y = atan2(at.x - b.global_position.x, at.z - b.global_position.z)
	Rig.play(b._anim, "Use_Item")
	_search_t += delta
	if _search_t < SEARCH_S:
		return
	_search_t = 0.0
	cd["searched"] = true
	if cd.has("purse"):
		_take_purse(m, cd)
		return
	_open_chest(m, cd)

## ---------------------------------------------------------------- S83: SYSTEM 9 row (a)
## the miniboss purse lands as a coin pile where the body fell. Coin_Pile_2 is art's measured
## prop (dungeon_hd PROP_BATCH base_dz_m +0.0003 - effectively on the floor at any scale).
const PURSE_MODEL := "res://assets/props/Coin_Pile_2.gltf"
const PURSE_SCALE := 4.0          # h 0.0584 m * 4 = 0.23 m: reads at the RTS camera, still ankle-high
var purses_dropped := 0
var purses_taken := 0

func _drop_purse(tgt: Monster, purse: int) -> bool:
	if dun == null or not is_instance_valid(dun) or not ResourceLoader.exists(PURSE_MODEL):
		return false
	var ps = load(PURSE_MODEL)
	if not (ps is PackedScene):
		return false
	var pile: Node3D = (ps as PackedScene).instantiate()
	pile.name = "PursePile"
	pile.scale = Vector3.ONE * PURSE_SCALE
	dun.add_child(pile)
	var at := tgt.global_position
	pile.global_position = Vector3(at.x, dun.global_position.y - 0.0003 * PURSE_SCALE, at.z)
	pile.set_meta("purse", purse)
	if not dun.info.has("chests"):
		dun.info["chests"] = []
	(dun.info["chests"] as Array).append({"node": pile, "searched": false, "purse": purse})
	purses_dropped += 1
	return true

func _nearest_to(alive: Array, at: Vector3) -> Dictionary:
	var best: Dictionary = alive[0]
	var bd := INF
	for m in alive:
		var d := _flat(b_pos(m), at)
		if d < bd:
			bd = d
			best = m
	return best

## the delver who reached it gathers it; the gold is still split the old way (L29c share rule)
func _take_purse(m: Dictionary, cd: Dictionary) -> void:
	var purse := int(cd.get("purse", 0))
	cd.erase("purse")
	cd["searched"] = true
	var node: Node3D = cd["node"]
	var alive := _alive()
	if alive.is_empty() or purse <= 0:
		return
	var share := maxi(1, purse / alive.size())
	for a in alive:
		roster.award(String(a["uid"]), share, 0, 0, floor_no)
		_float_text(a, "+%d" % share, Color(1.0, 0.85, 0.35))
	_gold += share * alive.size()
	purses_taken += 1
	Delve.setpieces_fired["purse_taken"] = int(Delve.setpieces_fired.get("purse_taken", 0)) + 1
	Sfx.play("coin", -4.0)
	_say("%s gathers up the purse - %d gold, %d a share, %d ways." % [m["h"]["name"], purse, share, alive.size()])
	if is_instance_valid(node):
		node.queue_free()

func _purses_left(alive: Array) -> void:
	if dun == null or not dun.info.has("chests") or alive.is_empty():
		return
	for c in dun.info["chests"]:
		var cd: Dictionary = c
		if cd.has("purse"):
			_take_purse(_nearest_to(alive, (cd["node"] as Node3D).global_position if is_instance_valid(cd["node"]) else b_pos(alive[0])), cd)

## the find itself: an Investigation check, the chest opens, and the Chronicle reads BOTH ways
func _open_chest(m: Dictionary, cd: Dictionary) -> void:
	var h: Dictionary = m["h"]
	var node: Node3D = cd["node"]
	if is_instance_valid(node) and node.has_meta("open"):
		(node.get_meta("open") as Callable).call()
	var sd := _d20(-1 if dark and not Roster.has_trait(h, "darkvision") else 0)
	var st := sd + _search_bonus(h)
	var dc := mini(20, 10 + floor_no / 2)
	# not every chest pays out - "Not every monster drops" applies here too, and an empty one
	# is what makes a find worth watching
	if sd != 1 and (sd == 20 or st >= dc):
		var gold := int(float(floor_no) * 9.0 * (1.6 if sd == 20 else 1.0)) + _rng.randi_range(4, 18)
		chests_found += 1
		roster.award(String(m["uid"]), gold, 0, 0, floor_no)
		_gold += gold
		_snd("chest_open", node.global_position if is_instance_valid(node) else b_pos(m), -2.0)
		Sfx.play("coin", -4.0)
		_float_text(m, "+%d" % gold, Color(1.0, 0.85, 0.35))
		_say("%s searches the chest - Successfully found loot!! %d gold (Investigation %d vs DC %d)."
			% [h["name"], gold, st, dc])
	else:
		chests_empty += 1
		_float_text(m, "empty", Color(0.75, 0.75, 0.78))
		_say("%s searches the chest - ...no loot... (Investigation %d vs DC %d)." % [h["name"], st, dc])

func b_pos(m: Dictionary) -> Vector3:
	var b = m["body"]
	return (b as Node3D).global_position if is_instance_valid(b) else Vector3.ZERO

## L47: press on or climb out - the party's biggest standing decision. Split out of _fight() for
## L49 so the same call can be reached after the floor has been searched as well as straight away.
func _floor_decision(alive: Array) -> void:
		if alive.is_empty():
			return
		var frac := 0.0
		for m in alive:
			frac += float(m["hp"]) / float(m["max"])
		frac /= float(alive.size())
		if oil < 1.0:
			decided["turn_back_oil"] = int(decided.get("turn_back_oil", 0)) + 1
			decisions += 1
			_say("Out of oil, the party feels its way back up from floor %d." % floor_no)
			_finish()
		elif frac < turn_back_at or floor_no >= max_floors:
			decided["turn_back_hurt"] = int(decided.get("turn_back_hurt", 0)) + 1
			decisions += 1
			_say("Battered, the party climbs back out from floor %d." % floor_no)
			_finish()
		else:
			decided["press_on"] = int(decided.get("press_on", 0)) + 1
			decisions += 1
			_say("%s take a breather, and press on deeper." % _names())
			# a breather: clerics and sages mend between floors
			for m in alive:
				m["hp"] = minf(float(m["max"]), float(m["hp"]) + float(m["max"]) * 0.25)
			state = "descend"
			_t = 0.0
			_nav_reset()

func _fight_body(delta: float, alive: Array, foes: Array) -> void:
	# venom keeps working after the bite (spider, snake, adder, wasp)
	for m in alive:
		if float(m.get("venom", 0.0)) > 0.0:
			m["venom"] = float(m["venom"]) - delta
			m["hp"] = float(m["hp"]) - float(m.get("venom_dps", 0.0)) * delta
			if float(m["hp"]) <= 0.0:
				m["venom"] = 0.0
				_hero_hit(m)
	alive = _alive()
	if alive.is_empty():
		return
	for m in alive:
		if float(m.get("slow", 0.0)) > 0.0:
			m["slow"] = float(m["slow"]) - delta
		_status_tick(m, delta)
		# D2 spells: renew mends over time, a ward fades
		if float(m.get("hot_t", 0.0)) > 0.0:
			m["hot_t"] = float(m["hot_t"]) - delta
			_mend(m, float(m.get("hot_rate", 0.0)) * delta)
		if float(m.get("ward_t", 0.0)) > 0.0:
			m["ward_t"] = float(m["ward_t"]) - delta
	# L47: before anyone swings, does the PARTY still want this fight? A lost one is broken off
	# as a party and they run for the way up - they no longer die standing in place.
	if not bool(_fleeing_party) and _losing(alive, foes):
		_fleeing_party = true
		decisions += 1
		decided["party_retreat"] = int(decided.get("party_retreat", 0)) + 1
		_say("The fight is going badly - the party breaks off and runs for the way up from floor %d." % floor_no)
		state = "flee"
		_t = 0.0
		_nav_reset()
		return

	for m in alive:
		var b: HeroBody = m["body"]
		var h: Dictionary = m["h"]
		# L12: a potion first, if one is called for (it costs the swing)
		if _quaff(m):
			continue
		# L47: then their own call - break off, fall back, keep running
		if _think(m, foes, alive, delta):
			continue
		# healers mend whoever is lowest first
		var hp_pow := roster.heal_power(h)
		if hp_pow > 0.0:
			var low = null
			# a paladin lays on hands only when someone is close to falling
			var mark := 0.35 if String(h["class"]) == "paladin" else 0.55
			for o in alive:
				if float(o["hp"]) < float(o["max"]) * mark and (low == null or float(o["hp"]) < float(low["hp"])):
					low = o
			m["swing"] = float(m["swing"]) - delta * _pace(m)
			# S64: a mending is a spell, and a spell spends mana - a dry mender holds it until the fight ends
			if low != null and float(m["swing"]) <= 0.0 and roster.spend_mana(h):
				m["swing"] = float(Economy.healing_rules()["mend_interval_s"])   # D99: classes.json healing.mend_interval_s
				# L47: choosing WHO to mend is a decision - say so when it is a close call
				if float(low["hp"]) < float(low["max"]) * 0.35:
					_decide(m, "mend", "%s breaks off to mend %s, who is nearly down." % [h["name"], low["h"]["name"]])
				else:
					decided["mend"] = int(decided.get("mend", 0)) + 1
					decisions += 1
				# D2 spells: a sage lays renew, a cleric a ward, a paladin its hands
				var mk := String(MENDERS.get(String(h["class"]), "heal"))
				var got := Spells.cast(mk, b, low["body"], _scar_check(m, mk))
				Rig.play(b._anim, Spells.CAST_ANIM.get(got, "Spellcasting"))
				# L52: the menders were the quietest of all - name them too
				_spell_said(m, mk, got, String(low["h"]["name"]))
				# L54: the data says "its next SPELL", not "its next attack" - a mender who
				# drinks Scarwater gets the doubling too, or loses the mending to the scar
				if bool(m.get("scar_double", false)):
					m["scar_double"] = false
					hp_pow *= 2.0

				if Spells.HARM.has(got):
					# L8: the scar turned the mending into a blow - it lands on the friend
					low["hp"] = float(low["hp"]) - hp_pow * 0.5
					_hero_hit(low)
				else:
					_bless(low, got, hp_pow)
				continue
		# L47: a target chosen on sense, not just proximity (finish the nearly-dead, shut up
		# the ranged one). The switch is announced the first time a hero changes their mind.
		var tgt: Monster = _pick_target(b, foes)
		if tgt == null:
			continue
		if m.get("tgt_was") != tgt and is_instance_valid(tgt):
			if m.has("tgt_was") and is_instance_valid(m.get("tgt_was")):
				var tn := String(tgt.def.get("name", "it"))
				var frac2 := tgt.hp / maxf(1.0, tgt.max_hp)
				if frac2 < 0.34:
					_decide(m, "finish", "%s turns on the wounded %s to finish it." % [h["name"], tn])
				else:
					var w: Dictionary = tgt.def.get("ways", {})
					if w.has("cast") or w.has("spit") or w.has("shoot"):
						_decide(m, "silence", "%s goes for the %s before it strikes again from range." % [h["name"], tn])
			m["tgt_was"] = tgt
		var bd := _flat((tgt as Node3D).global_position, b.global_position)
		var caster := String(h["class"]) in Roster.CASTERS
		# L48: the hero's whole unlocked kit, class birthright + class track + species track.
		# L43 FOUND THE COST OF THIS: abilities_of() allocates an Array and walks two tables, and
		# I had it running every frame for every delver in the fight loop. The paid phase fell
		# from 16-18 fps to 14.3-14.7, under _l32_test's catastrophe floor - which is exactly
		# the regression the repaired FPS gate was supposed to start catching, caught on its
		# first honest run, on my own code. The kit only changes when the hero LEVELS, so it is
		# worked out once and kept until then.
		if int(m.get("abil_lvl", -1)) != int(h.get("level", 1)):
			m["abil_lvl"] = int(h.get("level", 1))
			m["abil"] = Roster.abilities_of(h)
		var ability: Array = m["abil"]
		var ranged := caster or String(h["class"]) == "ranger"
		var reach := 9.0 if ranged else REACH + tgt._height() * 0.15
		if bd > reach:
			# each hero takes their own side of the target instead of one point
			# L25: a delver pressed against a hoard or a wall on the way to its side of the target
			# goes round to another side instead of pushing at it for the rest of the fight
			if stuck_on(b):
				m["slot_off"] = float(m.get("slot_off", 0.0)) + 1.1
				m["slot_t"] = -9.0       # pick again from the new side
				_prog.erase(b)
			var spot := _fight_slot(m, b, tgt, party.find(m), party.size(), ranged, reach)
			_go(b, spot, roster.speed(h) * 0.9, delta)
			Rig.play(b._anim, "Running_A")
			continue
		b.rotation.y = atan2(tgt.global_position.x - b.global_position.x, tgt.global_position.z - b.global_position.z)
		if _order_holds(m):
			Delve.order_held_frames += 1          # S38: NOT a set piece - see order_held_frames
			continue                                  # S36: not your name - you hold
		m["swing"] = float(m["swing"]) - delta * _pace(m)
		if float(m["swing"]) > 0.0:
			continue
		m["swing"] = (1.3 + _rng.randf() * 0.4) * (0.6 if ability.has("flurry") else 1.0) * (0.66 if has_st(m, "haste") else 1.0)
		# 5e: d20 + attack bonus vs the creature's AC (10 + depth band)
		# L5: darkvision shrugs off the dark; a lucky halfling rolls a natural 1 again
		var adv := _hero_adv(m)
		var roll := _d20(adv)
		if roll == 1 and Roster.has_trait(h, "lucky"):
			roll = _d20(adv)
		# L12: an unseen delver's first blow ends the potion
		if has_st(m, "invisible"):
			(m["st"] as Dictionary).erase("invisible")
		var ac := 10 + floor_no / 2 + (3 if tgt.def.get("boss", false) else 0) + int((tgt.def.get("ways", {}) as Dictionary).get("guard", 0))
		# S64: the spell spends mana; a caster who has run dry swings like everyone else
		if caster and roster.spend_mana(h):
			mana_casts += 1
			_cast_at(m, tgt, roll, ac, ability)
			continue
		elif caster:
			mana_dry_swings += 1
			Rig.play(b._anim, "1H_Melee_Attack_Chop")
		else:
			Rig.play(b._anim, "1H_Melee_Attack_Chop" if String(h["class"]) != "ranger" else "1H_Ranged_Shoot")
		var lands := roll == 20 or (roll != 1 and roll + roster.attack_bonus(h) + _inspired() + (2 if has_st(m, "giant") else 0) >= ac)
		_blow_snd(m, tgt, lands, roll == 20)          # S2
		if lands:
			var dmg := _hero_damage(h, roll == 20) + (4.0 if has_st(m, "giant") else 0.0)
			dmg *= _ward(tgt) * _ability_mult(ability, tgt)
			_ability_hit(ability, m, tgt, dmg, foes)
			var was_dead := tgt.state == Monster.S.DEAD
			tgt.hurt(dmg, roll == 20, "resist" if _ward(tgt) < 1.0 else "")      # D61.1
			# a natural 20 reaches the Chronicle when it kills, or lands on a lord
			if roll == 20 and not was_dead:
				if tgt.state == Monster.S.DEAD:
					_big(m, "rolls a 20 - and the %s is gone." % String(tgt.def.get("name", "thing")))
				elif bool(tgt.def.get("boss", false)):
					_big(m, "rolls a 20 - %s reels." % String(tgt.def.get("name", "it")))
			if not was_dead and tgt.state == Monster.S.DEAD:
				_kills += 1
				_on_kill(tgt, m)
				roster.award(String(m["uid"]), 3 + floor_no, 6 + floor_no * 2, 1, floor_no)
				if tgt.def.get("boss", false):
					_say("%s falls to %s." % [tgt.def.get("name"), h["name"]])
		elif is_instance_valid(tgt) and tgt.state != Monster.S.DEAD:
			tgt.show_result("miss")      # D61.1: a miss says so
	# the creatures answer
	for f in foes:
		var mon: Monster = f
		if not is_instance_valid(mon) or mon.state == Monster.S.DEAD:
			continue   # killed earlier this same tick: never stand it back up
		var near = null
		var nd := 1e9
		for m in alive:
			if has_st(m, "invisible"):
				continue          # L12: Shadowcloak - it cannot pick them
			var d := _flat((m["body"] as Node3D).global_position, mon.global_position)
			if d < nd:
				nd = d
				near = m
		if near == null:
			continue
		var ways: Dictionary = mon.def.get("ways", {})
		var nearest := nd
		# a grudge goes for the weakest delver standing, not the nearest
		if ways.has("grudge"):
			for m in alive:
				if float(m["hp"]) / float(m["max"]) < float(near["hp"]) / float(near["max"]):
					near = m
			nd = _flat((near["body"] as Node3D).global_position, mon.global_position)
		# S156: a taunting path (Guardian, Bastion, Oathkeeper) draws it off whoever is nearest
		if not ways.has("grudge"):
			var tn := _taunter(mon.global_position, alive)
			if not tn.is_empty() and not is_same(tn, near):
				near = tn
				nd = _flat((near["body"] as Node3D).global_position, mon.global_position)
				spec_log["taunt"] += 1
		var r := REACH + mon._height() * 0.2
		var shots := float(ways.get("ranged", 0.0))
		if shots > 0.0:
			r = shots
		mon.state = Monster.S.IDLE
		if ways.has("raise") and nearest < 14.0:
			_raise_tick(mon, int(ways["raise"]), delta)
		if nearest < 16.0:
			_lord_tick(mon, ways, alive, near, delta)
		if nearest < 16.0 and mon.has_meta("mb_key"):
			_mb_way_tick(mon, alive, near, delta)     # S34: the miniboss's ONE idea
		if nd > r:
			# a creature mid-swing, mid-rise or reeling from a hit stands until it is done - no gliding
			if mon.busy():
				continue
			var chase := float(mon.def.get("spd", 3.0)) * 0.7 * _mon_pace(mon)
			_go(mon, (near["body"] as Node3D).global_position, chase, delta)
			# L26a: a fast chaser runs (its run clip, or its walk where it has none)
			mon._play("run" if chase >= RUN_AT else "walk")
			continue
		var nb: Node3D = near["body"]
		mon.rotation.y = atan2(nb.global_position.x - mon.global_position.x, nb.global_position.z - mon.global_position.z)
		mon._swing -= delta * _mon_pace(mon)
		if mon._swing > 0.0:
			continue
		mon._swing = 1.8 if not mon.def.get("boss", false) else 1.4
		var fury := 1.0
		if mon.enraged:
			var en: Dictionary = ways.get("enrage", {})
			mon._swing *= float(en.get("swing", 0.6))
			fury = float(en.get("atk", 1.3))
		var chest := nb.global_position + Vector3(0, 1.1, 0)
		if ways.has("breath"):
			_boss_tell(mon, "%s draws breath - brace.")
			mon._swing = 2.6
			mon.breathe(chest)
		elif shots > 0.0:
			if ways.has("volley"):
				_boss_tell(mon, "%s nocks a volley - cover!")
			mon._swing = 2.2
			mon.shoot(chest)
			if ways.has("volley"):
				_volley(mon, alive, near, shots)
		else:
			# L26a: a melee blow lands at the swing's contact frame, not as the swing begins
			mon._play("attack")
			_blows.append({"t": mon.impact(), "mon": mon, "near": near, "fury": fury})
			continue
		_mon_blow(mon, near, fury, shots, ways, alive)

## ---- L26a: blows in flight. A creature's melee swing is rolled when its blade comes
## down (Monster.impact(): ~0.42 of the clip), so the hero's flinch matches the swing.
## A blow whose creature died or whose mark fell meanwhile is dropped.
const RUN_AT := 3.0            # chase speed (m/s) from which a creature runs instead of walks
var _blows: Array = []
var blows_landed := 0
func _blows_tick(delta: float) -> void:
	if _blows.is_empty():
		return
	var keep: Array = []
	for b in _blows:
		b["t"] = float(b["t"]) - delta
		if float(b["t"]) > 0.0:
			keep.append(b)
			continue
		var mon = b["mon"]
		var near: Dictionary = b["near"]
		if not is_instance_valid(mon) or (mon as Monster).state == Monster.S.DEAD or float(near["hp"]) <= 0.0 \
				or not is_instance_valid(near["body"]):
			continue
		blows_landed += 1
		_mon_blow(mon, near, float(b["fury"]), 0.0, (mon as Monster).def.get("ways", {}), _alive())
	_blows = keep

## a creature's blow resolved: d20 against the delver's armour, damage, venom, breath splash
func _mon_blow(mon: Monster, near: Dictionary, fury: float, shots: float, ways: Dictionary, alive: Array) -> void:
		var nb: Node3D = near["body"]
		# L9: d20 + its to-hit vs the delver's AC; a natural 1 always misses, a natural 20 always hits and doubles the dice
		var nat := _d20(1 if dark or has_st(near, "blinded") else 0)
		var hit := nat + 2 + floor_no / 2
		if nat != 1 and (nat == 20 or hit >= roster.armour_class(near["h"])):
			var base := float(mon.def.get("boss_atk", (6.0 + float(floor_no) * 2.2) * float(mon.def.get("atk", 1.0))))
			var dmg := _mdice(base, nat == 20) * fury
			near["hp"] = float(near["hp"]) - _soak(near, dmg)
			_hero_hit(near)
			if ways.has("venom") and float(near["hp"]) > 0.0:
				near["venom"] = float(ways["venom"])
				near["venom_dps"] = base * 0.12
			if ways.has("breath") and float(near["hp"]) > 0.0:
				_give(near, "slowed" if String(mon.def.get("id", "")) == "mourncoil" else "burning", 3.0)
			# the breath splashes whoever stands beside the mark
			if ways.has("breath"):
				for o in alive:
					if o != near and float(o["hp"]) > 0.0 and _flat((o["body"] as Node3D).global_position, nb.global_position) < float(ways["breath"]):
						o["hp"] = float(o["hp"]) - _soak(o, dmg * 0.5 * _resist(o, "frost" if String(mon.def.get("id", "")) == "mourncoil" else "fire"))
						_give(o, "slowed" if String(mon.def.get("id", "")) == "mourncoil" else "burning", 3.0)
						_hero_hit(o)
		elif _has_shield(near["h"]) and shots <= 0.0 and not ways.has("breath"):
			_snd("block", (near["body"] as Node3D).global_position + Vector3(0, 1.2, 0))     # S2: a miss rings off the shield

## ---- ways (L1). A slain ooze divides; a gravecaller calls up the dead.
func _spawn_on_floor(d: Dictionary, at: Vector3) -> Monster:
	var root: Node3D = dun.info["root"]
	var m := Monster.new()
	m.def = d
	m.state = Monster.S.IDLE
	m.roam = 2.0
	var q: Vector3 = dun._out_of_props(at - root.global_position)
	m.position = Vector3(q.x, 0.0, q.z)
	root.add_child(m)
	m.max_hp = (14.0 + float(floor_no) * 6.0) * float(d.get("hp", 1.0))
	m.hp = m.max_hp
	_admit(m)
	return m

var _split_said := -1
func _on_kill(tgt: Monster, by: Dictionary = {}) -> void:
	# D70.2: the delver whose blow felled a LORD is told so, by login (roster.felled_lord)
	if not by.is_empty() and dun != null and dun.lord == tgt and roster.has_method("felled_lord"):
		roster.felled_lord(String(by["uid"]), String(tgt.def.get("name", "a lord")), floor_no)
	# S167 System 43: the ladder counts a lord or an elite for EVERY delver standing when it falls
	# (checked before the purse meta is spent below).
	if roster and roster.has_method("note_lord"):
		var is_lord := dun != null and dun.lord == tgt
		var is_mb := tgt.has_meta("l29c_miniboss_purse") or String(tgt.get_meta("mb_key", "")) != ""
		if is_lord or is_mb:
			for m in _alive():
				if is_lord:
					roster.note_lord(String(m["uid"]))
				else:
					roster.note_miniboss(String(m["uid"]))
	var ways: Dictionary = tgt.def.get("ways", {})
	if ways.has("splits"):
		var n := int(ways["splits"])
		for k in range(n):
			var a := float(k) * TAU / float(n)
			_spawn_on_floor(Bestiary.make("slimeling", String(tgt.def.get("strain", "plain"))),
				tgt.global_position + Vector3(cos(a), 0, sin(a)) * 0.9)
		if _split_said != floor_no:
			_split_said = floor_no
			_say("The %s divides." % String(tgt.def.get("name", "ooze")))
	# L29c miniboss: the elite that stands in a chamber alone carries a purse on
	# its meta. On death it pays out across every alive hero, Chronicle names
	# the kill, Delve.setpieces_fired counts a "miniboss_down" so the test can
	# see that resolve + bonus actually fired.
	if tgt.has_meta("l29c_miniboss_purse"):
		var purse := int(tgt.get_meta("l29c_miniboss_purse"))
		tgt.remove_meta("l29c_miniboss_purse")
		var alive := _alive()
		# S83 / SYSTEM 9 row (a): in a live fight the purse SPILLS where the body fell and is
		# paid only when a delver walks to it (the L49 walk-and-kneel). Anywhere else - a test
		# calling _on_kill cold, a kill on the walk to the stairs - it pays at once, as before.
		if not alive.is_empty() and state == "fight" and _back_to == "" and _drop_purse(tgt, purse):
			var mbk0 := String(tgt.get_meta("mb_key", ""))
			if mbk0 != "":
				_say(_miniboss_say(mbk0, "fall"))
				Delve.setpieces_fired["miniboss_feed_fall"] = int(Delve.setpieces_fired.get("miniboss_feed_fall", 0)) + 1
			_say("The %s's purse spills across the floor - %d gold, for whoever goes to it."
				% [String(tgt.def.get("name", "elite")), purse])
			Delve.setpieces_fired["miniboss_down"] = int(Delve.setpieces_fired.get("miniboss_down", 0)) + 1
			Delve.setpieces_fired["purse_dropped"] = int(Delve.setpieces_fired.get("purse_dropped", 0)) + 1
			alive = []
		if not alive.is_empty():
			var share := maxi(1, purse / alive.size())
			for m in alive:
				roster.award(String(m["uid"]), share, 0, 0, floor_no)
				_float_text(m, "+%d" % share, Color(1.0, 0.85, 0.35))
			_gold += share * alive.size()
			var mbk := String(tgt.get_meta("mb_key", ""))
			if mbk != "":
				# the content writer's fall line says it is down; the purse line follows plainly
				_say(_miniboss_say(mbk, "fall"))
				_say("The chamber keeps a purse of %d gold - %d a share, %d ways." % [purse, share, alive.size()])
				Delve.setpieces_fired["miniboss_feed_fall"] = int(Delve.setpieces_fired.get("miniboss_feed_fall", 0)) + 1
			else:
				_say("The %s is down. The chamber keeps a purse of %d gold - %d a share, %d ways."
					% [String(tgt.def.get("name", "elite")), purse, share, alive.size()])
			Delve.setpieces_fired["miniboss_down"] = int(Delve.setpieces_fired.get("miniboss_down", 0)) + 1
			Sfx.play("coin", -4.0)

func _raise_tick(mon: Monster, most: int, delta: float) -> void:
	_call_tick(mon, {"type": "minion", "strain": "hollowed", "name": "risen dead", "every": 9.0, "most": most,
		"rise": true, "line": "A gravecaller raises the dead on floor %d." % floor_no}, delta)

## anything that calls its kind: a gravecaller's dead, the Grubmother's brood,
## Nightwing's bats, Gnawbone's children. Never more than `most` standing at once.
func _live_called(mon: Monster) -> Array:
	var live: Array = []
	for r in mon.get_meta("risen", []):
		if is_instance_valid(r) and (r as Monster).state != Monster.S.DEAD:
			live.append(r)
	return live

func _call_tick(mon: Monster, spec: Dictionary, delta: float) -> void:
	var t := float(mon.get_meta("raise_t", 4.0)) - delta
	if t > 0.0:
		mon.set_meta("raise_t", t)
		return
	mon.set_meta("raise_t", float(spec.get("every", 9.0)))
	var live := _live_called(mon)
	if live.size() >= int(spec.get("most", 2)):
		mon.set_meta("risen", live)
		return
	mon._play("summon" if (mon.def.get("anims", {}) as Dictionary).has("summon") else "attack")
	var a := _rng.randf() * TAU
	var m := _call_one(mon, spec, mon.global_position + Vector3(cos(a), 0, sin(a)) * (1.6 + mon._height() * 0.2))
	live.append(m)
	mon.set_meta("risen", live)
	if not bool(mon.get_meta("said", false)) and String(spec.get("line", "")) != "":
		mon.set_meta("said", true)
		_say(String(spec["line"]))

func _call_one(mon: Monster, spec: Dictionary, at: Vector3) -> Monster:
	var d := Bestiary.make(String(spec["type"]), String(spec.get("strain", "plain")))
	if spec.has("name"):
		d["name"] = spec["name"]
	if bool(spec.get("rise", false)):
		d["anims"] = Bestiary.A_SKL if String(d["path"]).contains("kaykit") else d["anims"]
	d["raised"] = true
	(d["ways"] as Dictionary).erase("splits")    # a called thing does not multiply again
	var m := _spawn_on_floor(d, at)
	if bool(spec.get("rise", false)):
		m.call_deferred("rise")
	return m

## S34: each miniboss's ONE IDEA as delve-side behaviour, voiced from content's own
## miniboss_feed act/broken lines (data/lore_lines.json). Every MB_WAY_EVERY seconds while the
## party is within 16 m the idea fires and an `act` line is said; at MB_BROKEN_FRAC of its hp the
## idea is BROKEN for good (a `broken` line, and anything it built is undone). The fourteen keys
## that carry act/broken lines each get a way below; a key with no act lines gets none, silently
## by design (the sixteen S33 bodies stand up named, but content has not written their idea).
## HONEST LIMIT: "broken" is an hp threshold, not each idea's own weakness (cracking the gong,
## cutting the lines) - that needs a targetable prop per miniboss and is not built.
const MB_WAY_EVERY := 8.0
const MB_BROKEN_FRAC := 0.30
const MB_WAYS := {
	"drillmaster": "call", "sexton": "call", "sower": "call",
	"scrapwright": "plate", "stoker": "grow", "cook": "mend",
	"snuffer": "snuff", "gaoler": "hook", "tallyman": "strip", "porter": "bar",
	"sluicekeeper": "flood", "snarer": "snare", "bellman": "blink", "boiler": "set",
	"beadle": "order", "rammer": "drop", "fuller": "wring", "pitman": "pit",
	"thatcher": "thatch",
}
## S78: the Fuller KEEPS EVERY BLOW (content's C-126 words, verbatim: "Every blow you land goes into
## the cloth. It keeps them. It gives them all back at once."). Each act it counts the hp it lost
## since its last act into the trough (meta mb_store). When the trough holds MB_WRING_FULL of its
## max hp it WRINGS: everyone within MB_WRING_R takes MB_WRING_MULT of the store (DEX save halves,
## capped at MB_WRING_CAP x its atk) and the trough empties. Hitting it slowly fills it slowly;
## broken = the trough cracks and the store is spilled, never given back.
const MB_WRING_FULL := 0.20
const MB_WRING_R := 3.2
const MB_WRING_MULT := 0.5
const MB_WRING_CAP := 4.0
## S79: the Pitman OPENS THE FLOOR (art's idea, S76 hand-off: "it opens a pit under a delver, who loses
## a beat climbing out; the pit stays"). Each act a pit opens under the delver nearest it (meta
## mb_pits, at most MB_PIT_MAX - the oldest closes when a new one opens). Anyone who stands within
## MB_PIT_R of an open pit goes in and loses MB_PIT_BEAT seconds off their next swing; climbing out
## they cannot go in again for MB_PIT_CLIMB seconds. THE PIT STAYS: pits outlive the act and the break.
## Broken = it stops digging; the pits it already opened are still in the floor.
## LIVE (S113 note): the old HOLD here is spent - content's C-158 landed by_key.pitman act/broken
## (arrive 9 / act 7 / broken 4 / fall 8), so _mb_way_tick's gate admits this way on real floors.
## HONEST LIMIT: the pits are ticked by the Pitman - once it is dead they stop taking anyone (the marks
## stay in the floor as scenery); a floor-owned hazard that outlives its maker is not built.
const MB_PIT_MAX := 3
const MB_PIT_R := 1.0
const MB_PIT_BEAT := 1.5
const MB_PIT_CLIMB := 3.0
## S38: the Rammer DROPS ON THE COUNT (art's idea: "the answer is not what you do, it is when").
## Its act is the haul: the iron goes up and HOLDS for MB_DROP_HOLD seconds, then comes down on the
## pile - everyone within MB_DROP_R of the frame at that moment. A delver on the pile makes a DEX
## save to have read the hold and stepped off; ranged delvers standing off are never on it. A
## TIMING way: no hit at the haul, the whole blow lands on the count. Broken = the rope parts and
## an iron that is up never comes down.
const MB_DROP_HOLD := 2.0
const MB_DROP_R := 2.6
const MB_DROP_MULT := 2.5
## S36: the Beadle CALLS THE ORDER (art's idea, verbatim: "while it stands the party does not choose
## who acts; it calls the same hero again and again while the rest hold"). _order_uid is the hero it
## has called; while the Beadle stands unbroken and that hero lives, every OTHER hero holds their
## swing (they still take their places). It keeps calling the same hero until that one falls.
var _order_uid := ""
var _order_mon: Monster = null

## true while a standing, unbroken Beadle has called someone other than this hero
func _order_holds(m: Dictionary) -> bool:
	if _order_uid == "" or not is_instance_valid(_order_mon):
		return false
	if _order_mon.state == Monster.S.DEAD or bool(_order_mon.get_meta("mb_broken", false)):
		_order_uid = ""
		return false
	if String(m.get("uid", "")) == _order_uid:
		return false
	for o in party:
		if String(o.get("uid", "")) == _order_uid:
			return float(o["hp"]) > 0.0              # the called one is down: the order lapses
	return false
## what each caller brings: the drill's garrison, the sexton's dead (they RISE), the sower's thorn
const MB_CALLS := {"drillmaster": "warrior", "sexton": "bones", "sower": "adder"}

func _mb_way_tick(mon: Monster, alive: Array, near: Dictionary, delta: float) -> void:
	var key := String(mon.get_meta("mb_key"))
	var way := String(MB_WAYS.get(key, ""))
	if mon.has_meta("mb_pits"):
		_pit_tick(mon, alive, delta)                  # S79: the pits stay - broken or not
	if way == "" or bool(mon.get_meta("mb_broken", false)) or miniboss_lines(key, "act").is_empty():
		return
	if mon.hp / maxf(1.0, mon.max_hp) <= MB_BROKEN_FRAC:
		mon.set_meta("mb_broken", true)
		if way == "grow":
			mon.scale = Vector3.ONE                       # the fire is going: back to its own size
		if way == "order" and _order_mon == mon:
			_order_uid = ""                               # the roll is dropped: everyone acts again
		if mon.has_meta("mb_drop_t"):
			mon.remove_meta("mb_drop_t")                  # S38: the rope parts - the iron never comes down
		if mon.has_meta("mb_store"):
			mon.remove_meta("mb_store")                   # S78: the trough cracks - the store is spilled
		if mon.has_meta("mb_base_atk"):
			var d0: Dictionary = mon.def.duplicate()
			d0["atk"] = float(mon.get_meta("mb_base_atk"))
			mon.def = d0
		_say(_miniboss_say(key, "broken"))
		Delve.setpieces_fired["miniboss_broken"] = int(Delve.setpieces_fired.get("miniboss_broken", 0)) + 1
		return
	if mon.has_meta("mb_drop_t"):                     # S38: the Rammer's iron is up - wait for the count
		var dt := float(mon.get_meta("mb_drop_t")) - delta
		if dt > 0.0:
			mon.set_meta("mb_drop_t", dt)
			return
		mon.remove_meta("mb_drop_t")
		_rammer_drop(mon, alive)
		return
	var t := float(mon.get_meta("mb_way_t", MB_WAY_EVERY * 0.5)) - delta
	mon.set_meta("mb_way_t", t)
	if t > 0.0:
		return
	mon.set_meta("mb_way_t", MB_WAY_EVERY)
	var live_heroes := alive.filter(func(o): return float(o["hp"]) > 0.0)
	if live_heroes.is_empty():
		return
	var far: Dictionary = near
	for o in live_heroes:
		if _flat((o["body"] as Node3D).global_position, mon.global_position) > _flat((far["body"] as Node3D).global_position, mon.global_position):
			far = o
	match way:
		"call":
			if _live_called(mon).size() >= 2:
				return                                    # it has its two; no act line, nothing happened
			var a := _rng.randf() * TAU
			var m := _call_one(mon, {"type": String(MB_CALLS.get(key, "bones")), "rise": key == "sexton"},
				mon.global_position + Vector3(cos(a), 0, sin(a)) * (1.6 + mon._height() * 0.2))
			var live := _live_called(mon)
			live.append(m)
			mon.set_meta("risen", live)
		"plate":
			mon.hp = minf(mon.max_hp, mon.hp + mon.max_hp * 0.06)   # a plate off the floor
		"grow":
			if mon.scale.x >= 1.24:
				return
			if not mon.has_meta("mb_base_atk"):
				mon.set_meta("mb_base_atk", float(mon.def.get("atk", 4.0)))
			mon.scale *= 1.08
			var d1: Dictionary = mon.def.duplicate()
			d1["atk"] = float(d1.get("atk", 4.0)) * 1.08
			mon.def = d1
		"mend":
			for mv in dun.monsters:
				if is_instance_valid(mv) and (mv as Monster).state != Monster.S.DEAD and _flat((mv as Monster).global_position, mon.global_position) < 10.0:
					(mv as Monster).hp = minf((mv as Monster).max_hp, (mv as Monster).hp + (mv as Monster).max_hp * 0.10)
		"snuff":
			for o in live_heroes:
				_give(o, "blinded", 2.5)                  # another lamp out
		"hook":
			# the hook reels the FARTHEST delver in to stand beside it
			var hb := far["body"] as Node3D
			var to := mon.global_position + (hb.global_position - mon.global_position).normalized() * 1.6
			if (dun.info["cells"] as Dictionary).has(_cell_of(to)):
				hb.global_position = Vector3(to.x, hb.global_position.y, to.z)
			near = far
		"strip":
			_give(near, "frightened", 4.0)            # kit on the frame: the hero fights unhanded
		"bar":
			mon.set_meta("mb_guard", int(mon.get_meta("mb_guard", 0)) + 1)
			var dw: Dictionary = mon.def.duplicate()
			var wy: Dictionary = (dw.get("ways", {}) as Dictionary).duplicate()
			wy["guard"] = mini(4, int(wy.get("guard", 0)) + 1)   # the drawbar: harder to hit
			dw["ways"] = wy
			mon.def = dw
		"flood":
			for o in live_heroes:
				_give(o, "slowed", 3.0)                   # water to the ankle
		"snare":
			_give(near, "slowed", 4.0)
		"blink":
			var wp: Vector3 = (far["body"] as Node3D).global_position
			var land := wp + (wp - mon.global_position).normalized() * 1.4   # it is behind you
			if not (dun.info["cells"] as Dictionary).has(_cell_of(land)):
				land = wp
			mon.swoop(land, true)
		"set":
			_give(near, "slowed", 5.0)                # the floor goes hard round their feet
		"drop":
			mon.set_meta("mb_drop_t", MB_DROP_HOLD)        # S38: the haul - up, and it holds
		"wring":
			# S78: what it lost since its last act goes into the trough; full, it gives it all back
			var last := float(mon.get_meta("mb_last_hp", mon.max_hp))
			var store := float(mon.get_meta("mb_store", 0.0)) + maxf(0.0, last - mon.hp)
			mon.set_meta("mb_last_hp", mon.hp)
			if store >= mon.max_hp * MB_WRING_FULL:
				_fuller_wring(mon, live_heroes, store)
				store = 0.0
			mon.set_meta("mb_store", store)
		"pit":
			# S79: the floor opens under the nearest delver, and they go straight in
			var nb := near["body"] as Node3D
			var pits: Array = mon.get_meta("mb_pits", [])
			while pits.size() >= MB_PIT_MAX:
				var old: Array = pits.pop_front()
				if is_instance_valid(old[1]):
					(old[1] as Node).queue_free()
			pits.append([Vector3(nb.global_position.x, 0.0, nb.global_position.z), _pit_mark(mon, nb.global_position)])
			mon.set_meta("mb_pits", pits)
			near.erase("pit_out")                     # the one it dug under has no footing to save them
			_pit_tick(mon, [near], 0.0)
		"order":
			# the same name again while it still stands; a new one only when the called hero is down
			var called: Dictionary = {}
			for o in live_heroes:
				if _order_mon == mon and String(o.get("uid", "")) == _order_uid:
					called = o
			if called.is_empty():
				called = near
			_order_uid = String(called.get("uid", ""))
			_order_mon = mon
			near = called                             # the act line names the hero it called
		"thatch":
			pass                                      # S149: the roof is passive (see _thatch); the act only voices it
	var line := _miniboss_say_for(key, "act", near)
	if line != "":
		_say(line)
	Delve.setpieces_fired["miniboss_act"] = int(Delve.setpieces_fired.get("miniboss_act", 0)) + 1
	Delve.setpieces_fired["miniboss_act_" + way] = int(Delve.setpieces_fired.get("miniboss_act_" + way, 0)) + 1

## S38: the count. The iron comes down on the pile; whoever is on it and did not read the hold is struck.
func _rammer_drop(mon: Monster, alive: Array) -> void:
	var base := float(mon.def.get("atk", 4.0)) * MB_DROP_MULT
	for o in alive:
		if float(o["hp"]) <= 0.0:
			continue
		if _flat((o["body"] as Node3D).global_position, mon.global_position) >= MB_DROP_R:
			continue                                  # off the pile: the count passes them by
		if _rng.randi_range(1, 20) + roster.save_bonus(o["h"], "dex") >= 12 + floor_no / 4:
			Delve.rammer_read += 1                    # read the hold and stepped off in time
			continue
		o["hp"] = float(o["hp"]) - _soak(o, base)
		_give(o, "slowed", 1.5)                       # the ground jumps under them
		_hero_hit(o)
		Delve.rammer_struck += 1
	Sfx.at("hit", mon.global_position)
	if mon.is_inside_tree():
		mon.nova(MB_DROP_R)                           # S39: the count is SEEN - a shock ring the size of the pile
	Delve.setpieces_fired["miniboss_drop"] = int(Delve.setpieces_fired.get("miniboss_drop", 0)) + 1

## S78: the wring. The trough gives back what it kept, to everyone standing under the stocks.
func _fuller_wring(mon: Monster, live_heroes: Array, store: float) -> void:
	var base := minf(store * MB_WRING_MULT, float(mon.def.get("atk", 4.0)) * MB_WRING_CAP)
	for o in live_heroes:
		if _flat((o["body"] as Node3D).global_position, mon.global_position) >= MB_WRING_R:
			continue                                  # out from under it: the wring passes them by
		var save := _rng.randi_range(1, 20) + roster.save_bonus(o["h"], "dex")
		o["hp"] = float(o["hp"]) - _soak(o, base * (0.5 if save >= 12 + floor_no / 4 else 1.0))
		_hero_hit(o)
		Delve.fuller_struck += 1
	Sfx.at("hit", mon.global_position)
	if mon.is_inside_tree():
		mon.nova(MB_WRING_R)                          # the wring is SEEN - a ring the size of the stocks
	Delve.setpieces_fired["miniboss_wring"] = int(Delve.setpieces_fired.get("miniboss_wring", 0)) + 1

## S79: who is standing in an open pit goes in and loses a beat; climbing out buys MB_PIT_CLIMB seconds.
func _pit_tick(mon: Monster, alive: Array, delta: float) -> void:
	var pits: Array = mon.get_meta("mb_pits", [])
	for o in alive:
		if float(o.get("hp", 0.0)) <= 0.0:
			continue
		var po := float(o.get("pit_out", 0.0))
		if po > 0.0:
			o["pit_out"] = po - delta
			continue
		var bp := (o["body"] as Node3D).global_position
		for pv in pits:
			if _flat(bp, pv[0]) < MB_PIT_R:
				o["swing"] = float(o.get("swing", 0.0)) + MB_PIT_BEAT   # the lost beat: climbing out
				o["pit_out"] = MB_PIT_CLIMB
				Delve.pitman_fell += 1
				Delve.setpieces_fired["miniboss_pit_fell"] = int(Delve.setpieces_fired.get("miniboss_pit_fell", 0)) + 1
				break

## S79: the pit is SEEN - a dark mouth in the floor, parented beside the Pitman so it goes with its floor.
func _pit_mark(mon: Monster, at: Vector3) -> Node3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = MB_PIT_R; cm.bottom_radius = MB_PIT_R * 0.8; cm.height = 0.04; cm.radial_segments = 20
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.04, 0.03, 0.02); mat.roughness = 1.0
	cm.material = mat
	mi.mesh = cm
	var par := mon.get_parent()
	if par == null:
		return mi
	par.add_child(mi)
	mi.global_position = Vector3(at.x, 0.09, at.z)   # above the hex tiles' bevelled tops, which hid it at 0.025
	return mi

## L2: a lord's mechanics (and a unique's). Runs while the party is within 16 m.
func _lord_tick(mon: Monster, ways: Dictionary, alive: Array, near: Dictionary, delta: float) -> void:
	if ways.has("summon"):
		_call_tick(mon, ways["summon"], delta)
	if ways.has("nova"):
		var nv: Dictionary = ways["nova"]
		var t := float(mon.get_meta("nova_t", float(nv.get("every", 9.0)) * 0.6)) - delta
		mon.set_meta("nova_t", t)
		if t <= 0.0:
			mon.set_meta("nova_t", float(nv.get("every", 9.0)))
			var rr := float(nv.get("r", 6.0))
			mon.nova(rr)
			if not bool(mon.get_meta("nova_said", false)) and String(nv.get("line", "")) != "":
				mon.set_meta("nova_said", true)
				_say(String(nv["line"]))
			var base := float(mon.def.get("boss_atk", 10.0)) * float(nv.get("dmg", 0.5))
			for o in alive:
				if float(o["hp"]) > 0.0 and _flat((o["body"] as Node3D).global_position, mon.global_position) < rr:
					# a DEX save halves it (5e area rule)
					var save := _rng.randi_range(1, 20) + roster.save_bonus(o["h"], "dex")
					var elem := "frost" if nv.has("slow") else "fire"
					o["hp"] = float(o["hp"]) - _soak(o, base * (0.5 if save >= 12 + floor_no / 4 else 1.0) * _resist(o, elem))
					if nv.has("slow"):
						_give(o, "slowed", float(nv["slow"]))
					else:
						_give(o, "burning", 3.0)
					_hero_hit(o)
	if ways.has("shed"):
		var sh: Dictionary = ways["shed"]
		var marks: Array = sh["at"]
		var done := int(mon.get_meta("shed_n", 0))
		if done < marks.size() and mon.hp / maxf(1.0, mon.max_hp) <= float(marks[done]):
			mon.set_meta("shed_n", done + 1)
			for k in range(int(sh.get("n", 2))):
				var a := _rng.randf() * TAU
				var m := _call_one(mon, {"type": String(sh["type"]), "rise": true},
					mon.global_position + Vector3(cos(a), 0, sin(a)) * (1.8 + mon._height() * 0.2))
				var live := _live_called(mon)
				live.append(m)
				mon.set_meta("risen", live)
			_say(String(sh.get("line", "")))
	if ways.has("irons"):
		# S56: Lastcuff - each hp mark knocks one iron off; it hides that piece where the glb names it
		# and gains pace (read by _mon_pace through the "irons_pace" meta).
		var ir: Dictionary = ways["irons"]
		var im: Array = ir["at"]
		var off := int(mon.get_meta("irons_n", 0))
		if off < im.size() and mon.hp / maxf(1.0, mon.max_hp) <= float(im[off]):
			mon.set_meta("irons_n", off + 1)
			mon.set_meta("irons_pace", 1.0 + float(ir.get("gain", 0.2)) * float(off + 1))
			var mname := String((ir.get("meshes", {}) as Dictionary).get(str(off), ""))
			if mname != "":
				var piece := mon.find_child(mname, true, false)
				if piece is Node3D:
					(piece as Node3D).visible = false
			_say("%s sheds an iron (%d of %d)." % [String(mon.def.get("name", "It")), off + 1, im.size()])
	if ways.has("basin"):
		# S57: the Leech drinks the basin back into itself; at `tip` of its hp the basin goes over.
		var bs: Dictionary = ways["basin"]
		if not mon.get_meta("basin_tipped", false):
			if mon.hp / maxf(1.0, mon.max_hp) <= float(bs.get("tip", 0.3)):
				mon.set_meta("basin_tipped", true)
				mon.set_meta("basin", 0.0)
				_say(String(bs.get("line", "")))
			else:
				var held := float(mon.get_meta("basin", 0.0))
				var sip := minf(held, float(bs.get("rate", 4.0)) * delta)
				if sip > 0.0:
					mon.hp = minf(mon.max_hp, mon.hp + sip)
					mon.set_meta("basin", held - sip)
	if ways.has("swoop"):
		var sw: Dictionary = ways["swoop"]
		var t := float(mon.get_meta("swoop_t", float(sw.get("every", 7.0)))) - delta
		mon.set_meta("swoop_t", t)
		if t <= 0.0:
			mon.set_meta("swoop_t", float(sw.get("every", 7.0)))
			var weak: Dictionary = near
			for o in alive:
				if float(o["hp"]) > 0.0 and float(o["hp"]) / float(o["max"]) < float(weak["hp"]) / float(weak["max"]):
					weak = o
			# the swoop lands on the floor beside its mark, never in the wall behind it
			var wp: Vector3 = (weak["body"] as Node3D).global_position
			var land := wp + (mon.global_position - wp).normalized() * 1.4
			if not (dun.info["cells"] as Dictionary).has(_cell_of(land)):
				land = wp
			mon.swoop(land, true)
			if _d20(1 if dark else 0) + 2 + floor_no / 2 >= roster.armour_class(weak["h"]):
				weak["hp"] = float(weak["hp"]) - _soak(weak, _mdice(float(mon.def.get("boss_atk", 10.0)) * float(sw.get("mult", 1.5)), false))
				# L12: too fast to see coming - a CON save (DC 12) or blinded a moment
				if _rng.randi_range(1, 20) + roster.save_bonus(weak["h"], "con") < 12:
					_give(weak, "blinded", 3.0)
				_hero_hit(weak)
	if ways.has("enrage") and not mon.enraged:
		if mon.hp / maxf(1.0, mon.max_hp) <= float((ways["enrage"] as Dictionary).get("at", 0.3)):
			mon.enrage()
			_say("%s is enraged." % String(mon.def.get("name", "It")))
			FeedHUD.card_on(town, String(mon.def.get("name", "It")), "Enraged.", Color(1.0, 0.25, 0.15))

## S149: the Thatcher ROOFS THE ROOM (art's idea, THATCHER_THE_66th.md: "while it stands nothing else
## in the room can be hurt"; content's C-227 act line: "The blow goes into straw and stops."). While a
## standing, UNBROKEN Thatcher whose act lines are on disk is within MB_THATCH_R of a creature, every
## blow on that creature goes into the thatch and does nothing - the Thatcher itself is never roofed,
## so the party must take it first (or break it: at MB_BROKEN_FRAC a tie is cut and the roof opens).
## HONEST LIMIT: "the room" is a radius, not the floor's room cell - floorgen has no room id on a monster.
const MB_THATCH_R := 10.0
func _thatch(tgt: Monster) -> float:
	if dun == null or not is_instance_valid(tgt):
		return 1.0
	for mv in dun.monsters:
		if mv == tgt or not is_instance_valid(mv):
			continue
		var t: Monster = mv
		if t.state == Monster.S.DEAD or String(t.get_meta("mb_key", "")) != "thatcher" or bool(t.get_meta("mb_broken", false)):
			continue
		if t.hp / maxf(1.0, t.max_hp) <= MB_BROKEN_FRAC or miniboss_lines("thatcher", "act").is_empty():
			continue
		if _flat(t.global_position, tgt.global_position) < MB_THATCH_R:
			return 0.0
	return 1.0

## a lord warded by what it called takes only that share while any of it stands
func _ward(tgt: Monster) -> float:
	if _thatch(tgt) == 0.0:
		return 0.0                                    # S149: under the Thatcher's roof
	var ways: Dictionary = tgt.def.get("ways", {})
	if ways.has("ward") and not _live_called(tgt).is_empty():
		return float(ways["ward"])
	return 1.0

## frost and the like: a slowed hero swings at half pace
func _pace(m: Dictionary) -> float:
	return 0.5 if float(m.get("slow", 0.0)) > 0.0 else 1.0

## the Weeping Bowman looses at everyone in reach, not only its mark
func _volley(mon: Monster, alive: Array, near: Dictionary, reach: float) -> void:
	var base := float(mon.def.get("boss_atk", 10.0)) * 0.55
	for o in alive:
		if o == near or float(o["hp"]) <= 0.0:
			continue
		var ob: Node3D = o["body"]
		if _flat(ob.global_position, mon.global_position) > reach:
			continue
		mon.shoot(ob.global_position + Vector3(0, 1.1, 0))
		if _d20(1 if dark else 0) + 2 + floor_no / 2 >= roster.armour_class(o["h"]):
			o["hp"] = float(o["hp"]) - _soak(o, _mdice(base, false))
			_hero_hit(o)

## L29b: a WRITTEN line need not carry the format tokens the code assumes it does. Formatting one
## that does not throws "String formatting error" and the line is LOST from the Chronicle. Two sites
## did this - the descend line in start() and the cleared line in _loot - and both threw on ordinary
## runs, every run, for as long as the offending lines have been in the content file. The content
## file is not at fault and is not mine; the assumption here was. So: format only what asks to be
## formatted, and otherwise print the writer's line exactly as written.
func _fmt_line(line: String, args: Array) -> String:
	var want := line.count("%") - 2 * line.count("%%")
	if want != args.size():
		return line
	return line % args

## L29b: what a floor pays is multiplied by this. Kept in ONE place so a test reads the same
## number the Chronicle actually pays out, instead of a second copy of the arithmetic that can
## drift. A rare unique is a lord AND THEN SOME; a floor-unique is less than a lord.
static func boss_loot_mult(boss: bool, uniq: bool, rare_lord: bool) -> float:
	if not boss:
		return 1.0
	if rare_lord:
		return 4.5
	return 2.0 if uniq else 3.0

## Gold is PERSONAL (old rule): a lord's hoard is split between the heroes who
## brought it down; anything else found belongs to whoever prised it open, and
## searching costs half a flask. Materials go home to the town.
func _loot(alive: Array) -> void:
	var boss := dun.lord != null
	var uniq := boss and bool(dun.lord.def.get("unique", false))
	# L29b: a rare unique IS a lord, not a floor-unique - it pays better than one, not worse
	var rare_lord := boss and bool(dun.lord.def.get("lord_unique", false))
	# L9: the party's sharpest eye searches - an Investigation check (d20 + INT,
	# + proficiency for the trained, disadvantage in the dark without darkvision)
	# vs DC 10 + floor/2: it sets how much is found, what is salvaged, and whether
	# deep gear turns up.
	var seeker: Dictionary = alive[0]
	for m in alive:
		if _search_bonus(m["h"]) > _search_bonus(seeker["h"]):
			seeker = m
	var sd := _d20(-1 if dark and not Roster.has_trait(seeker["h"], "darkvision") else 0)
	var st := sd + _search_bonus(seeker["h"])
	var sdc := mini(20, 10 + floor_no / 2)
	var mult := 0.8
	if sd == 20:
		mult = 1.6
		_big(seeker, "rolls a 20 searching the floor!")
	elif sd == 1:
		mult = 0.6
	elif st >= sdc:
		mult = minf(1.35, 1.0 + 0.03 * float(st - sdc))
	var found := int(float(floor_no) * 11.0 * boss_loot_mult(boss, uniq, rare_lord) * mult)
	Sfx.play("coin", -4.0)
	_snd("chest_open", (seeker["body"] as Node3D).global_position, -2.0)      # S2: a find
	if boss:
		var share := int(float(found) / float(alive.size()))
		var took: Array = []
		for m in alive:
			roster.award(String(m["uid"]), share, 0, 0, floor_no)
			took.append(String(m["h"]["name"]))
		_gold += share * alive.size()
		_say("%s is slain on floor %d!" % [dun.lord.def.get("name", "The lord"), floor_no])
		_e3po("lord_cleared")   # D37: a lord is down - the Commander marks the beat
		FeedHUD.card_on(town, String(dun.lord.def.get("name", "The lord")),
			"Slain on floor %d by %s." % [floor_no, _names_of(_party_uids(alive))], dun.lord.def.get("aura", Color(1, 0.8, 0.4)))
		if rare_lord:
			_say("A hoard that size does not come off an ordinary %s." % String(dun.lord.def.get("lord_title", "lord")))
		_say("The hoard is split %d ways - %d gold each to %s." % [took.size(), share, ", ".join(took)])
	else:
		var f: Dictionary = seeker
		roster.award(String(f["uid"]), found, 0, 0, floor_no)
		_gold += found
		oil = maxf(0.0, oil - 0.5)
		_say("%s searches (Investigation %d) and turns up %d gold on floor %d." % [f["h"]["name"], st, found, floor_no])
		_say(_fmt_line(_pick_line("cleared", "Floor %d cleared."), [floor_no]))
	# renown (old rule): a floor cleared +1, a lord slain +6
	var eco = town.get("economy") if town else null
	if eco:
		eco.renown += (3 if uniq else 6) if boss else 1
	haul["ore"] += floor_no * 0.6
	haul["stone"] += floor_no * 0.45
	if sd != 1 and st >= sdc - floor_no / 3:
		haul["gear"] += 1.0
	if sd != 1 and st >= sdc - 2:
		haul["potion"] += 1.0
	# L3: deep floors give up gear - one roll a floor, for whoever was searching
	var finder: Dictionary = seeker
	var lordly := boss and not uniq
	var deep_find := sd == 20 or (sd != 1 and st >= 25 - floor_no / 2 - (5 if lordly else 0))
	var w_before := int(finder["h"].get("weapon", 0))
	var found_line := roster.find_gear(String(finder["uid"]), floor_no, 0.0 if deep_find else 1.0, lordly)
	if found_line != "":
		# S96 / SYSTEM 9 row (b): a found WEAPON lies on the stones first, in its own model, then is taken up
		if int(finder["h"].get("weapon", 0)) > w_before:
			_show_find(finder, roster.weapon_mesh(finder["h"]))
		_say(found_line)
		var fb: HeroBody = finder["body"]
		if is_instance_valid(fb):
			fb.refresh()
	# L12: a good search turns up a vial - the deeper, the better the brew
	if sd != 1 and st >= sdc and _rng.randf() < 0.30 + 0.02 * float(floor_no):
		var pool: Array = []
		var ps: Dictionary = Roster.potions().get("potions", {})
		for k in ps:
			if int(ps[k].get("tier", 1)) <= 1 + floor_no / 3:
				pool.append(k)
		if not pool.is_empty():
			var pk: String = pool[_rng.randi() % pool.size()]
			roster.add_brew(seeker["h"], pk, 1)
			_show_vial(seeker, pk, true)       # S31 System 5: the find lands on the floor first
			_say("%s finds a vial of %s." % [seeker["h"]["name"], ps[pk]["name"]])
	# clearing a floor is the unit of progress: everyone standing learns from it
	for m in alive:
		roster.award(String(m["uid"]), 0, floor_no * 5, 0, floor_no)

func _haul_line() -> String:
	var bits: Array = ["%d gold" % _gold]
	for k in ["ore", "stone"]:
		if int(haul[k]) > 0:
			bits.append("%d %s" % [int(haul[k]), k])
	if int(haul["gear"]) > 0:
		bits.append("%d piece%s of salvaged gear" % [int(haul["gear"]), "" if int(haul["gear"]) == 1 else "s"])
	if int(haul["potion"]) > 0:
		bits.append("%d potion%s" % [int(haul["potion"]), "" if int(haul["potion"]) == 1 else "s"])
	return ", ".join(bits.slice(0, bits.size() - 1)) + (" and " if bits.size() > 1 else "") + String(bits[-1])

func _hero_hit(m: Dictionary) -> void:
	# L19: a delver badly hurt says so, once a floor
	if float(m["hp"]) > 0.0 and float(m["hp"]) < float(m["max"]) * 0.25 and int(m.get("hurt_bark", -1)) != floor_no:
		m["hurt_bark"] = floor_no
		_bark(m, "hurt")
	if float(m["hp"]) > 0.0 and float(m["hp"]) < float(m["max"]) * MEND_AT:
		_mend_party()                 # S156: a Healer's path answers once a floor
	var b: HeroBody = m["body"]
	if is_instance_valid(b) and b.is_inside_tree():
		Rig.play(b._anim, "Hit_A")
		Sfx.at("hit", b.global_position)
		_hurt_snd(m)                  # S2: a cry, now and then
	if float(m["hp"]) > 0.0:
		return
	# one death save per delve (old rule): claw back to 1 hp on a DC 10 CON save
	if not bool(m["saved"]):
		m["saved"] = true
		# L9: a natural 20 stands them up with a quarter of their life; a natural 1 is death
		var sd := _rng.randi_range(1, 20)
		var s := sd + roster.save_bonus(m["h"], "con")
		if sd == 20:
			m["hp"] = float(m["max"]) * 0.25
			_say("%s rolls a 20 on the death save - and gets up swinging." % m["h"]["name"])
			return
		if sd != 1 and s >= 10:
			m["hp"] = 1.0
			_say("%s should be dead - and stands back up (%d)." % [m["h"]["name"], s])
			return
	if _death_ward(m):                # S156: a warded path gets a second one, and it holds
		return
	Rig.play(b._anim, "Death_A")
	_vox(m, "death", 3.0)             # S2
	b.fallen = true
	var line := roster.kill(String(m["uid"]), "the dark below", floor_no, 0)
	_say(line)
	# S164: what they carried drops where they fell, a body on the floor the rest walk past
	if roster != null and not roster.bags.is_empty():
		var nb: Dictionary = roster.bags.back()
		if String(nb.get("owner", "")) == String(m["uid"]) and int(nb.get("floor", 0)) == floor_no:
			_bag_body(nb, b.global_position)

var max_floors := 99      # test hook; canon never states one

## ---------------------------------------------------------------- S164: the corpse-run bags
## RULING sup-nov27-0209, slice 3 engine side. Roster owns the bags (drop_bag / bag_state /
## take_bags, S161); this is the BODY on the floor and the WALK-OVER. A bag left on a floor by
## an earlier delve is laid on the walk in from the stairs (floors are remade, so the spot it
## fell on is gone - the floor NUMBER is what it keeps); a bag dropped mid-floor lies where
## its owner fell. A delver who comes within BAG_REACH takes every bag on the floor they may
## (theirs inside the hour, anyone's after it); someone else's inside the hour stays put,
## seen and said once. Empty bags get no body - there is nothing to fetch.
const BAG_REACH := 2.2
const BAG_MODEL := "res://assets/props/Bag.gltf"
const BAG_SKULL := "res://assets/dungeon/Skull.glb"
var bag_nodes: Array = []          # [{node, bag}] on the current floor
var bags_taken: Array = []         # test hook: [{uid, floor, gold, potions, oil, bags}]
var _bag_seen := {}                # "uid|owner" -> true: a locked bag is said once a floor

static func _bag_worth(bag: Dictionary) -> bool:
	return int(bag.get("gold", 0)) > 0 or int(bag.get("potions", 0)) > 0 or int(bag.get("oil", 0)) > 0

func _lay_bags() -> void:
	bag_nodes.clear()
	_bag_seen.clear()
	if roster == null or dun == null or dun.info.is_empty():
		return
	var e: Vector3 = dun.info["entry"]
	var x: Vector3 = dun.info["exit"]
	var dir := Vector3(x.x - e.x, 0, x.z - e.z)
	var k := 0
	for bag: Dictionary in roster.bags:
		if int(bag.get("floor", 0)) != floor_no or roster.bag_state(bag, "") == "gone" or not _bag_worth(bag):
			continue
		# a few metres in along the way to the stairs down, nudged to the nearest clear reachable cell
		var along := minf(6.0 + 1.5 * float(k), dir.length() * 0.4)
		var at: Vector3 = e + (dir.normalized() * along if dir.length() > 0.1 else Vector3.ZERO)
		at = dun._out_of_props(at) + Vector3(float(k % 3) - 1.0, 0, 0) * 0.5
		_bag_body(bag, at + dun.global_position)
		k += 1

## the body: a sack with a skull beside it, set on the floor (batch_piece seats it on its base)
func _bag_body(bag: Dictionary, at: Vector3) -> Node3D:
	if dun == null or not _bag_worth(bag):
		return null
	var n := Node3D.new()
	n.name = "CorpseBag_" + String(bag.get("name", "?")).validate_node_name()
	var sack := DungeonHD.batch_piece(BAG_MODEL)
	if sack != null:
		sack.scale = Vector3.ONE * 0.8
		n.add_child(sack)
	var sk := DungeonHD.batch_piece(BAG_SKULL)
	if sk != null:
		sk.scale = Vector3.ONE * 0.55
		sk.position = Vector3(0.45, 0, 0.15)
		sk.rotation_degrees.y = _rng.randf_range(-40.0, 40.0)
		n.add_child(sk)
	dun.add_child(n)
	n.global_position = Vector3(at.x, dun.global_position.y, at.z)
	n.rotation_degrees.y = _rng.randf_range(0.0, 360.0)
	n.set_meta("bag_owner", String(bag.get("owner", "")))
	bag_nodes.append({"node": n, "bag": bag})
	return n

func _bags_tick() -> void:
	if bag_nodes.is_empty() or roster == null:
		return
	for m in _alive():
		var b: Node3D = m["body"]
		var uid := String(m["uid"])
		for bn: Dictionary in bag_nodes:
			var node: Node3D = bn["node"]
			if not is_instance_valid(node) or _flat(b.global_position, node.global_position) > BAG_REACH:
				continue
			var bag: Dictionary = bn["bag"]
			var st := roster.bag_state(bag, uid)
			if st == "locked":
				var key := uid + "|" + String(bag.get("owner", ""))
				if not _bag_seen.has(key):
					_bag_seen[key] = true
					_say("%s passes %s's bag. Not theirs to take - not yet." % [m["h"]["name"], bag.get("name", "someone")])
				continue
			if st not in ["owner", "anyone"]:
				continue
			var got: Dictionary = roster.take_bags(uid, floor_no)
			if int(got["bags"]) <= 0:
				continue
			var rec := got.duplicate()
			rec["uid"] = uid
			rec["floor"] = floor_no
			bags_taken.append(rec)
			var own := String(bag.get("owner", "")) == uid
			var bits := ["%dg" % int(got["gold"])]
			if int(got["potions"]) > 0:
				bits.append("%d potion%s" % [int(got["potions"]), "" if int(got["potions"]) == 1 else "s"])
			if int(got["oil"]) > 0:
				bits.append("%d flask%s of oil" % [int(got["oil"]), "" if int(got["oil"]) == 1 else "s"])
			_say(("%s finds their own bag where they fell, and takes back %s." if own else "%s turns over a dead delver's bag. Finders keepers: %s.") % [m["h"]["name"], ", ".join(bits)])
			_bags_sweep()
			return

## drop every body whose bag is no longer in the roster (taken, or swept as expired)
func _bags_sweep() -> void:
	var keep: Array = []
	for bn: Dictionary in bag_nodes:
		var live := false
		for rb in roster.bags:
			if is_same(rb, bn["bag"]):
				live = true
				break
		if live and is_instance_valid(bn["node"]):
			keep.append(bn)
		elif is_instance_valid(bn["node"]):
			(bn["node"] as Node3D).queue_free()
	bag_nodes = keep

func _finish() -> void:
	for m in party:
		var bb = m["body"]
		if is_instance_valid(bb) and bb.has_method("compact"):
			bb.compact(false)
	state = "home"
	for m in party:                   # S161: the grace-period count (first 3 delves wear no gear)
		roster.note_delve_done(String(m["uid"]))
	var out: Array = []
	for m in _alive():
		out.append(m["uid"])
	if not out.is_empty():
		_say("%s %s home to Bellmire with %s. %d %s." % [_names_of(out), "comes" if out.size() == 1 else "come", _haul_line(), _kills, ("kill" if _kills == 1 else "kills") + ("" if out.size() == 1 and party.size() == 1 else " between them")])
		if town and town.has_method("receive_haul"):
			town.receive_haul(haul)
		# L55: they are home with their takings - the smith fits them out. Before this nothing
		# ever called the forge for a viewer's hero, so they earned and never spent: tiers sat at
		# w0/a0 all stream while gold piled up. One step each at most, and only with a reserve
		# left (Roster.kit_up_after_delve). It is said aloud so the viewer sees what their gold
		# bought - an upgrade nobody can see is the same bug over again.
		for uid in out:
			if roster.has_method("came_home"):
				roster.came_home(String(uid))      # D70.2: a rare find is told on the way HOME
			var line := roster.kit_up_after_delve(String(uid))
			if line != "":
				_say(line)
	ended.emit(out)

## ---- L4: what the newer callings do in a fight
## a bard standing anywhere in the party: everyone swings truer (+1 to hit)
func _inspired() -> int:
	for o in _alive():
		if String(o["h"]["class"]) == "bard":
			return 1
	return 0

## L48: `ability` is now the hero's WHOLE unlocked kit (Roster.abilities_of), not the single
## thing their class was born with - a level-5 orc knight brings knight's cleave and bulwark
## AND orc rage. Every unlock resolves through this seam or _ability_hit/_soak, so nothing in
## the levelling table is a name with no effect behind it.
func _ability_mult(ability, tgt: Monster) -> float:
	var k := 1.0
	var list: Array = ability if ability is Array else [String(ability)]
	var undead := String(tgt.def.get("family", "")) in ["undead", "the fallen"]
	for a in list:
		match String(a):
			"smite":    # a paladin hits the dead twice as hard
				if undead:
					k *= 2.0
			"scarborn": # the scar's own are death to the same
				if undead:
					k *= 1.25
			"flurry":   # a monk hits often and light
				k *= 0.7
			"rage":
				k *= 1.20
			"keen":
				k *= 1.10
			"resolve":
				k *= 1.08
			"riposte":
				k *= 1.12
			"deadeye":
				k *= 1.15
			"arcane_surge":
				k *= 1.15
			"backstab": # a telling blow cuts deeper once the thing is already hurt
				if tgt.hp < tgt.max_hp * 0.5:
					k *= 1.40
	# a warlock's hex: everyone's blows land harder on the marked thing
	if float(tgt.get_meta("hex_t", -1.0)) > _t:
		k *= 1.25
	return k

func _ability_hit(ability, m: Dictionary, tgt: Monster, dmg: float, foes: Array) -> void:
	# L48: every unlocked ability gets its turn, not just the class's birthright
	var list: Array = ability if ability is Array else [String(ability)]
	for a in list:
		_ability_hit_one(String(a), m, tgt, dmg, foes)

func _ability_hit_one(ability: String, m: Dictionary, tgt: Monster, dmg: float, foes: Array) -> void:
	match ability:
		"drain":    # the necromancer drinks back a share of what it spends
			m["hp"] = minf(float(m["max"]), float(m["hp"]) + dmg * 0.3)
		"cleave":   # L48: the blow carries into ONE other foe standing close
			var best: Monster = null
			var bd := 3.0
			for f in foes:
				var o: Monster = f
				if o == tgt or not is_instance_valid(o) or o.state == Monster.S.DEAD:
					continue
				var d := _flat(o.global_position, tgt.global_position)
				if d < bd:
					bd = d
					best = o
			if best != null:
				var was_dead := best.state == Monster.S.DEAD
				best.hurt(dmg * 0.35 * _thatch(best), false, "resist" if _thatch(best) < 1.0 else "")   # S149: the cleave does not get under the roof; S150: and says so, as the swing does (1863)
				if not was_dead and best.state == Monster.S.DEAD:
					_kills += 1
					_on_kill(best, m)
					roster.award(String(m["uid"]), 3 + floor_no, 6 + floor_no * 2, 1, floor_no)
		"luck":     # L48: halfling luck - now and then the blow lands twice
			if is_instance_valid(tgt) and tgt.state != Monster.S.DEAD and _rng.randf() < 0.12:
				var was2 := tgt.state == Monster.S.DEAD
				tgt.hurt(dmg * 0.5, false, "resist" if _ward(tgt) < 1.0 else "")   # S150: dmg is already warded (1860); label it as 1863 does
				_float_text(m, "lucky!", Color(0.95, 0.85, 0.40), 56, 2.6)
				if not was2 and tgt.state == Monster.S.DEAD:
					_kills += 1
					_on_kill(tgt, m)
					roster.award(String(m["uid"]), 3 + floor_no, 6 + floor_no * 2, 1, floor_no)
		"hex":
			if float(tgt.get_meta("hex_t", -1.0)) <= _t:
				Spells._burst(tgt.get_parent(), tgt.global_position + Vector3(0, tgt._height() * 0.6, 0), Color(0.6, 0.2, 0.9))
			tgt.set_meta("hex_t", _t + 6.0)
		"thorns":   # thorns take whatever stands beside the mark
			for f in foes:
				var o: Monster = f
				if o != tgt and is_instance_valid(o) and o.state != Monster.S.DEAD and _flat(o.global_position, tgt.global_position) < 2.5:
					var was := o.state == Monster.S.DEAD
					o.hurt(dmg * 0.5 * _thatch(o), false, "resist" if _thatch(o) < 1.0 else "")   # S149; S150: labelled like the swing (1863)
					if not was and o.state == Monster.S.DEAD:
						_kills += 1
						_on_kill(o, m)
						roster.award(String(m["uid"]), 3 + floor_no, 6 + floor_no * 2, 1, floor_no)

## ---- D2 spells below (the desktop's Spells, used the way raids.gd uses them).
## Each caster works through its book; a mending calling lays its own spell on
## whoever is lowest. Damage lands when the spell does, after its flight.
const BOOKS := {"mage": ["bolt", "bolt", "chain", "fire"], "sage": ["frost", "bolt"], "cleric": ["smite", "bolt"],
				"necromancer": ["bolt", "chain"], "druid": ["frost", "bolt"], "warlock": ["bolt", "fire"]}
const MENDERS := {"sage": "renew", "cleric": "ward", "paladin": "heal"}

## ---------------------------------------------------------------- L52: spells that name themselves
## REFRAMED by the census, and the census was right. Mr. E reported "only one spell", but a 7-minute
## soak measured NINE distinct spells firing with a good spread (heal 295, bolt 161, mend 131,
## ward 112, smite 85, frost 46, chain 35, renew 31, fire 12). Nothing is missing: the viewer simply
## cannot TELL them apart in a pane. So this adds no spells. It makes the choice legible - every
## cast says its own name over the caster's head in that spell's own colour (Spells.COL), and the
## Chronicle names it in words.
## A scar misfire is the most readable moment in the game and was completely silent before: when the
## scar turns one spell into another, it is now called out by name, both ways.
const SPELL_WORDS := {
	"bolt": "Bolt", "heal": "Heal", "ward": "Ward", "mend": "Mend", "chain": "Chain Bolt",
	"fire": "Fire", "frost": "Frost", "smite": "Smite", "renew": "Renew",
}
const SPELL_SAY_EVERY := 2.5        # s between one caster's Chronicle lines (the float is every cast)
var spells_cast := {}               # kind -> count, for the L52 test and a census

## every cast, wherever it is cast from: the name over the caster, the count, and a calm line
func _spell_said(m: Dictionary, wanted: String, actual: String, at_whom := "") -> void:
	spells_cast[actual] = int(spells_cast.get(actual, 0)) + 1
	var word := String(SPELL_WORDS.get(actual, actual.capitalize()))
	var col: Color = Spells.COL.get(actual, Color.WHITE)
	var misfired := actual != wanted
	# the name over the caster's head, in the spell's own colour - this is the bit that makes a
	# pane readable at a glance, without reading the Chronicle at all
	_float_text(m, word if not misfired else "%s!" % word, col, 64, 3.0)
	if misfired:
		# _scar_check has ALREADY put a misfire line in the Chronicle (a lore_lines template,
		# gated to one per caster per floor). Adding a second line for the same event would be
		# exactly the feed noise L32b's pacing work set out to kill, and lore_lines.json is the
		# content writer's file, not mine to reword. So the float above carries the naming - it
		# shows what the spell BECAME, in that spell's colour - and the Chronicle keeps one line.
		return
	if _t < float(m.get("spell_say_t", -99.0)) + SPELL_SAY_EVERY:
		return                      # cast freely, just do not narrate every single one
	m["spell_say_t"] = _t
	var who := String(m["h"]["name"])
	if at_whom != "" and at_whom == who and String(Economy.healing_rules().get("self_mend", "")) != "":
		# D99: classes.json healing.voice - a mender on themself reads as the content writer's
		# phrase ("binds their own wounds"), never "X casts Heal at X"
		_say("%s %s." % [who, String(Economy.healing_rules()["self_mend"])])
	elif at_whom != "":
		_say("%s casts %s at %s." % [who, word, at_whom])
	else:
		_say("%s casts %s." % [who, word])
const CHAIN_R := 5.0        # the chain leaps to a creature this near the last
const FIRE_R := 2.6         # the fire burst catches everything this near its mark
const FROST_SLOW := 4.0     # s a frosted creature moves and swings at half pace
const SMITE_DEAD := 1.5     # smite on the dead and the lost
const WARD_SOAK := 0.35     # of the warded delver's max, soaked for WARD_T s
const WARD_T := 8.0

func _cast_at(m: Dictionary, tgt: Monster, roll: int, ac: int, ability) -> void:
	var b: HeroBody = m["body"]
	var h: Dictionary = m["h"]
	var book: Array = BOOKS.get(String(h["class"]), ["bolt"])
	var kind := String(book[int(m.get("spell_i", 0)) % book.size()])
	m["spell_i"] = int(m.get("spell_i", 0)) + 1
	var hit: Array = [tgt]
	var more: Array = []
	if kind == "chain":
		var at := tgt.global_position
		for _k in range(2):
			var nx: Monster = null
			var nd := CHAIN_R
			for f in _foes():
				if hit.has(f):
					continue
				var d := _flat((f as Node3D).global_position, at)
				if d < nd:
					nd = d
					nx = f
			if nx == null:
				break
			hit.append(nx)
			more.append(nx)
			at = nx.global_position
	var actual := Spells.cast(kind, b, tgt, _scar_check(m, kind), more)
	Rig.play(b._anim, Spells.CAST_ANIM.get(actual, "Spellcast_Shoot"))
	# L52: say which spell this was - the viewer could never tell them apart
	_spell_said(m, kind, actual, String(tgt.def.get("name", "it")) if is_instance_valid(tgt) else "")
	# L54: take the doubling NOW and clear it, before any path can return early. Consuming it
	# after the to-hit check (as the first version did) meant a spell that MISSED left the flag
	# standing and doubled the next cast instead - one draught paying twice, which is not what
	# "its next spell is doubled" says. The scar decided; a fumble spends it just the same.
	var scar_dbl := bool(m.get("scar_double", false))
	m["scar_double"] = false
	if not Spells.HARM.has(actual):
		# L8: the scar turned the blow into a mending - wild magic mends the creature
		if actual in ["heal", "renew", "mend"] and is_instance_valid(tgt) and tgt.state != Monster.S.DEAD:
			tgt.hp = minf(tgt.max_hp, tgt.hp + roster.attack(h) * (1.0 if scar_dbl else 0.5))
		return
	if not (roll == 20 or (roll != 1 and roll + roster.attack_bonus(h) + _inspired() >= ac)):
		if is_instance_valid(tgt) and tgt.state != Monster.S.DEAD:
			tgt.show_result("miss")      # D61.1: a spell that misses says so
		return
	var dmg := _hero_damage(h, roll == 20)
	dmg *= _ability_mult(ability, tgt)
	if scar_dbl:
		dmg *= 2.0
	var t := Spells.flight(actual, b, tgt)
	get_tree().create_timer(t).timeout.connect(_spell_lands.bind(actual, m, hit, dmg, roll == 20, ability))

func _spell_lands(kind: String, m: Dictionary, hit: Array, dmg: float, crit: bool, ability) -> void:
	if state != "fight" or dun == null or not is_instance_valid(dun):
		return
	var first: Monster = hit[0] if is_instance_valid(hit[0]) else null
	match kind:
		"fire":
			if first == null:
				return
			var p := first.global_position
			for f in _foes():
				if _flat((f as Node3D).global_position, p) <= FIRE_R:
					var sv := _mon_saves(f, m, 0)
					_strike(m, f, dmg * 0.8 * (0.5 if sv else 1.0), crit, "save" if sv else "")      # D61.1
		"chain":
			var k := 1.0
			for r in hit:
				if is_instance_valid(r):
					_strike(m, r, dmg * k, crit)
				k *= 0.65
		"frost":
			if first == null:
				return
			_strike(m, first, dmg * 0.7, crit)
			# L9: a CON save against the caster's spell DC shrugs the slow off
			if is_instance_valid(first) and not _mon_saves(first, m, 0):
				first.set_meta("slow_t", _t + FROST_SLOW)
		"smite":
			if first == null:
				return
			var dead := String(first.def.get("family", "")) in ["undead", "the fallen"]
			_strike(m, first, dmg * (SMITE_DEAD if dead else 1.0), crit, "vuln" if dead and SMITE_DEAD > 1.0 else "")      # D61.1: the dead take extra
		_:
			if first == null:
				return
			_strike(m, first, dmg, crit)
	if first != null and is_instance_valid(first):
		_ability_hit(ability, m, first, dmg, _foes())

## one blow from a delver to a creature, with the kill's bookkeeping
func _strike(m: Dictionary, tgt: Monster, dmg: float, crit: bool, kind := "") -> void:
	if tgt == null or not is_instance_valid(tgt) or tgt.state == Monster.S.DEAD or tgt._entering():
		return
	var w := _ward(tgt)
	tgt.hurt(dmg * w, crit, kind if kind != "" else ("resist" if w < 1.0 else ""))   # D61.1: a warded lord reads "resist"
	if tgt.state == Monster.S.DEAD:
		_kills += 1
		_on_kill(tgt, m)
		roster.award(String(m["uid"]), 3 + floor_no, 6 + floor_no * 2, 1, floor_no)
		if tgt.def.get("boss", false):
			_say("%s falls to %s." % [tgt.def.get("name"), m["h"]["name"]])

## S57: every mend to a delver passes here. While a Leech (ways.basin) stands untipped on this floor,
## the mend goes into its basin instead and the delver gets nothing; returns what actually landed.
func _leech_basin() -> Monster:
	if dun == null:
		return null
	for c in dun.monsters:
		if is_instance_valid(c) and (c as Monster).state != Monster.S.DEAD \
				and ((c as Monster).def.get("ways", {}) as Dictionary).has("basin") \
				and not (c as Monster).get_meta("basin_tipped", false):
			return c as Monster
	return null

func _mend(o: Dictionary, amt: float) -> float:
	if amt <= 0.0:
		return 0.0
	var lc := _leech_basin()
	if lc != null:
		lc.set_meta("basin", float(lc.get_meta("basin", 0.0)) + amt)
		return 0.0
	var before := float(o["hp"])
	o["hp"] = minf(float(o["max"]), before + amt)
	return float(o["hp"]) - before

## renew mends over Spells.RENEW_T; a ward soaks blows for WARD_T; heal is at once
func _bless(o: Dictionary, kind: String, pow: float) -> void:
	match kind:
		"renew":
			o["hot_t"] = Spells.RENEW_T
			o["hot_rate"] = pow * 1.3 / Spells.RENEW_T
		"ward":
			_mend(o, pow * 0.5)
			o["ward"] = float(o["max"]) * WARD_SOAK
			o["ward_t"] = WARD_T
		"heal", "mend":
			_mend(o, pow)

func _soak(o: Dictionary, dmg: float) -> float:
	# L48: the defensive unlocks live here, because this is already the one place a hero's
	# incoming damage is reduced. Bulwark is trained, stoneblood is bred; they stack, but
	# gently, and the floor keeps a blow from ever being soaked away to nothing.
	if o.has("h"):
		var kit := Roster.abilities_of(o["h"] as Dictionary)
		var cut := 1.0
		if kit.has("bulwark"):
			cut *= 0.85
		if kit.has("stoneblood"):
			cut *= 0.88
		if cut < 1.0:
			dmg = maxf(1.0, dmg * cut)
	if float(o.get("ward_t", 0.0)) <= 0.0 or float(o.get("ward", 0.0)) <= 0.0:
		return dmg
	var s := minf(float(o["ward"]), dmg)
	o["ward"] = float(o["ward"]) - s
	return dmg - s

## a frosted creature moves and swings at half pace
func _mon_pace(mon: Monster) -> float:
	var p := float(mon.get_meta("irons_pace", 1.0))     # S56: Lastcuff's shed irons
	return (0.5 if float(mon.get_meta("slow_t", -1.0)) > _t else 1.0) * p

## ---- L8 (Mr. E, Nov 11): wild magic below. The dungeon is one enormous scar,
## so every spell cast down here is a check against it: d20 + casting ability
## mod + proficiency vs DC 10 + floor/2 (cap 20). (The sage checks on WIS, its own sheet - Mr. E, L9.) A fail misfires the way it does
## on the scar's surface (Spells.cast in_scar: the next spell in the order goes
## off instead). A natural 1 always misfires, a natural 20 never. Monsters'
## spells are not checked.
const CAST_STAT := {"mage": "int", "necromancer": "int",
					"sage": "wis", "cleric": "wis", "druid": "wis", "monk": "wis",
					"warlock": "cha", "bard": "cha", "paladin": "cha"}
var scar_casts := 0
var scar_misfires := 0
var scar_touched_spells := 0    # L54: Scarwater casts the scar decided
var scar_doubles := 0           # L54: of those, the ones it doubled
var _misfire_said := {}

static func scar_dc(floor_no: int) -> int:
	return mini(20, 10 + floor_no / 2)

func _scar_check(m: Dictionary, kind: String) -> bool:
	var h: Dictionary = m["h"]
	# ---- L54 (raised by the content writer): SCARWATER. data/potions.json has given the state
	# "scar_touched" for a while - "its next spell is doubled, or misfires; the scar decides" -
	# and NOTHING in the scripts ever read it. Verified before writing a line: the only
	# scar_touched in code was fishing.gd's unrelated scar_touched_chance. So the draught was
	# bought, drunk, displayed on the hero, and did exactly nothing.
	# It resolves here because this is already where the scar decides a cast's fate, so a
	# scar-touched hero skips the usual check entirely: the scar has their spell either way.
	# One cast, decided once, and the draught is spent whichever way it falls.
	if has_st(m, "scar_touched"):
		(m.get("st", {}) as Dictionary).erase("scar_touched")
		scar_casts += 1
		scar_touched_spells += 1
		if _rng.randi() % 2 == 0:
			scar_misfires += 1
			m["scar_double"] = false
			_float_text(m, "SCAR", Spells.SCAR, 64, 3.2)
			_say("%s's Scarwater turns on them - the scar takes the spell." % h["name"])
			_bark(m, "misfire")
			return true
		m["scar_double"] = true
		scar_doubles += 1
		_float_text(m, "DOUBLED", Spells.SCAR, 72, 3.2)
		_say("%s's Scarwater holds - the scar doubles the spell." % h["name"])
		return false
	var stat := String(CAST_STAT.get(String(h["class"]), String(Roster.CLASSES[String(h["class"])].get("primary", "int"))))
	var d := _rng.randi_range(1, 20)
	var total := d + roster.mod(h, stat) + roster.prof(h)
	var miss := d == 1 or (d != 20 and total < scar_dc(floor_no))
	scar_casts += 1
	if miss:
		scar_misfires += 1
		# one Chronicle line per caster per floor, so the feed is not all sparks
		var key := "%s:%d" % [m["uid"], floor_no]
		if not _misfire_said.has(key):
			_misfire_said[key] = true
			_say(_pick_line("misfire", "%s's %s goes wrong - the scar answers (%d vs DC %d).") % [h["name"], kind, total if d != 1 else 1, scar_dc(floor_no)])
			_bark(m, "misfire")
	return miss

## ---- L9 (DnD RULE): the roll audit, dungeon side. Everything below is a d20
## or dice roll on the hero's real numbers (Roster.mod / prof / save_bonus).
func _dice(n: int, s: int) -> int:
	var t := 0
	for i in range(maxi(n, 1)):
		t += _rng.randi_range(1, maxi(s, 1))
	return t

## a delver's blow: the weapon's dice + the ability mod + a flat part that keeps
## the average exactly where it was (0.75 x Roster.attack + the muster's kit), so
## the measured balance holds and only the spread is now dice. A crit rolls the
## dice twice, as 5e does.
func _hero_damage(h: Dictionary, crit: bool) -> float:
	var d := roster.weapon_dice(h)
	var n := int(d[0])
	var s := int(d[1])
	var prim := String(Roster.CLASSES[String(h["class"])].get("primary", "str"))
	var md := roster.mod(h, prim)
	var flat := roster.attack(h) * 0.75 + kit_bonus + roster.acc_bonus(h, "dmg") - float(n) * float(s + 1) * 0.5 - float(md)
	var dice := _dice(n, s) + (_dice(n, s) if crit else 0)
	return maxf(1.0, (float(dice + md) + flat) * _aura_mult())     # S156: a Chieftain or Skald standing

## a creature's blow on 2d6: the same 0.6-1.0 of its base, mean 0.8, now dice;
## a natural 20 doubles it
func _mdice(base: float, crit: bool) -> float:
	var k := 0.6 + 0.4 * float(_dice(2, 6) - 2) / 10.0
	return base * k * (2.0 if crit else 1.0)

## big rolls reach the Chronicle - once per delver per floor
var _big_said := {}
func _big(m: Dictionary, what: String) -> void:
	var key := "%s:%d" % [m["uid"], floor_no]
	if _big_said.has(key):
		return
	_big_said[key] = true
	_say("%s %s" % [m["h"]["name"], what])

## Investigation: d20 + INT (+ proficiency for the trained searchers)
const SEARCHERS := ["rogue", "ranger", "mage", "sage", "necromancer"]
func _search_bonus(h: Dictionary) -> int:
	return roster.mod(h, "int") + (roster.prof(h) if String(h["class"]) in SEARCHERS else 0)

## initiative: d20 + DEX for each delver, d20 + 1 for each creature; who rolls
## high swings first (the first swing comes sooner the higher the roll)
func _initiative() -> void:
	var best = null
	var bi := -99
	for m in _alive():
		var d := _rng.randi_range(1, 20)
		var ini := d + roster.mod(m["h"], "dex")
		m["swing"] = 0.15 + float(maxi(0, 22 - ini)) * 0.06
		if ini > bi:
			bi = ini
			best = m
		if d == 20:
			_big(m, "rolls a 20 for initiative and is moving before anything else.")
	for mon in dun.monsters:
		if is_instance_valid(mon):
			(mon as Monster)._swing = 0.15 + float(maxi(0, 21 - _rng.randi_range(1, 20))) * 0.06
	if dun.lord and is_instance_valid(dun.lord):
		dun.lord._swing = 0.15 + float(maxi(0, 19 - _rng.randi_range(1, 20))) * 0.06

## a creature's save against a delver's spell: d20 + floor/3 (+2 for a lord) vs
## the caster's spell DC (8 + proficiency + casting mod)
func _mon_saves(mon: Monster, m: Dictionary, _kind: int) -> bool:
	var h: Dictionary = m["h"]
	var stat := String(CAST_STAT.get(String(h["class"]), String(Roster.CLASSES[String(h["class"])].get("primary", "int"))))
	var dc := 8 + roster.prof(h) + roster.mod(h, stat)
	var d := _rng.randi_range(1, 20)
	if d == 1:
		return false
	if d == 20:
		return true
	return d + floor_no / 3 + (2 if mon.def.get("boss", false) else 0) >= dc

## ---- L11: traps that visibly work. The first delver to come within reach of
## an armed trap looks for it: Perception, d20 + WIS (+ proficiency for rogue,
## ranger, monk; disadvantage in the dark without darkvision) vs DC 10 + floor/2.
## Spotted by someone with thieves' tools (rogue, bard), it is disarmed on a DEX
## (+ proficiency) check; failing that by 5 or more sets it off on them. Spotted
## by anyone else, it is stepped round. Missed, it goes off: the trap plays, a DEX
## save halves the dice, the number floats up, the Chronicle says what happened.
const SPOTTERS := ["rogue", "ranger", "monk"]
const TOOLS := ["rogue", "bard"]
const TRAP_REACH := 0.9
## L29c r5 added PoisonDart (status, not spike) and SwarmTrap (a creature spawn,
## not damage up front). PoisonDart carries a tiny immediate hit AND stacks a
## venom DoT (6 s, dps 1 + floor/4). SwarmTrap deals no immediate damage - its
## damage is whatever the pack it lets up does once the party sees it.
const TRAPS := {
	"SpikeTrap":     {"noun": "a spiked plate", "what": "spikes!", "dice": [2, 6], "sfx": "swing", "name": "a spike trap"},
	"PressurePlate": {"noun": "a plate", "what": "darts!", "dice": [3, 4], "sfx": "ui", "name": "a pressure plate"},
	"FireTrap":      {"noun": "a grate", "what": "fire!", "dice": [2, 8], "sfx": "spell", "name": "a fire grate"},
	"DartTrap":      {"noun": "a loose flagstone", "what": "darts!", "dice": [3, 4], "sfx": "swing", "name": "a dart trap"},
	"BladeTrap":     {"noun": "a slot in the floor", "what": "a blade!", "dice": [2, 8], "sfx": "swing", "name": "a blade trap"},
	"PitTrap":       {"noun": "rotten boards", "what": "the floor drops away!", "dice": [2, 6], "sfx": "hit", "name": "a pit"},
	"PoisonDart":    {"noun": "a loose flagstone", "what": "green darts!", "dice": [1, 4], "sfx": "swing", "name": "a poison-dart trap"},
	"Portcullis":    {"noun": "a portcullis", "what": "the portcullis crashes down!", "dice": [2, 8], "sfx": "hit", "name": "a portcullis"},
	"SwarmTrap":     {"noun": "a grated floor", "what": "the bars drop open - something is coming up through them!", "dice": [1, 1], "sfx": "swing", "name": "a swarm grate"},
}
## ---- S156: SYSTEM 40's REMAINDER - the paths' bespoke ways (Roster.SPEC_WAYS). Each is a
## number that changes in the delve, never a label: who the creature hits, whether a trap goes
## off, how much life the party has, whether a hero dies, how hard every blow lands.
const TAUNT_R := 9.0          # a taunter this close to a creature takes its blow instead
const MEND_AT := 0.34         # a delver under a third of their life calls the mend
const MEND_FRAC := 0.20       # ...which gives every living delver a fifth of their life
const AURA_MULT := 1.10       # while a Chieftain or Skald stands, every blow lands a tenth harder
var spec_log := {"taunt": 0, "trapsense": 0, "mend_party": 0, "death_ward": 0}
var _sense_floor := -1
var _mend_floor := -1

func _way_holders(way: String) -> Array:
	var out: Array = []
	for m in party:
		if float(m.get("hp", 0.0)) > 0.0 and Roster.spec_way(m["h"]) == way:
			out.append(m)
	return out

func _taunter(at: Vector3, alive: Array) -> Dictionary:
	var best: Dictionary = {}
	var bd := TAUNT_R
	for m in alive:
		if float(m.get("hp", 0.0)) <= 0.0 or has_st(m, "invisible") or Roster.spec_way(m["h"]) != "taunt":
			continue
		if not (m.get("body") is Node3D) or not is_instance_valid(m["body"]):
			continue
		var d := _flat((m["body"] as Node3D).global_position, at)
		if d < bd:
			bd = d
			best = m
	return best

## once a floor: the name of the delver who read the trap, or "" if no one can
func _trapsense() -> String:
	if _sense_floor == floor_no:
		return ""
	var hs := _way_holders("trapsense")
	if hs.is_empty():
		return ""
	_sense_floor = floor_no
	spec_log["trapsense"] += 1
	return String(hs[0]["h"]["name"])

func _mend_party() -> bool:
	if _mend_floor == floor_no:
		return false
	var hs := _way_holders("mend_party")
	if hs.is_empty():
		return false
	_mend_floor = floor_no
	spec_log["mend_party"] += 1
	for o in party:
		if float(o.get("hp", 0.0)) > 0.0:
			_mend(o, float(o["max"]) * MEND_FRAC)
	_say("%s the %s calls the party in close and mends them all." % [hs[0]["h"]["name"], Roster.calling_of(hs[0]["h"])])
	return true

func _death_ward(m: Dictionary) -> bool:
	if Roster.spec_way(m["h"]) != "death_ward" or bool(m.get("warded", false)):
		return false
	m["warded"] = true
	m["hp"] = 1.0
	spec_log["death_ward"] += 1
	_say("%s goes down - and the %s's ward will not let them stay down." % [m["h"]["name"], Roster.calling_of(m["h"])])
	return true

func _aura_mult() -> float:
	return AURA_MULT if not _way_holders("aura").is_empty() else 1.0

var trap_log := {"spotted": 0, "disarmed": 0, "sprung": 0, "saved": 0, "damage": 0.0}

func trap_dc() -> int:
	return mini(20, 10 + floor_no / 2)

func _traps_tick() -> void:
	if dun == null or not dun.info.has("traps"):
		return
	_gates_tick()
	for t in dun.info["traps"]:
		var tr: Dictionary = t
		if bool(tr.get("done", false)) or not is_instance_valid(tr["node"]):
			continue
		var tp: Vector3 = (tr["node"] as Node3D).global_position
		var gate := tr.has("cells")
		for m in _alive():
			if gate:
				# D88: a portcullis is met on its LINE, anywhere across the passage's width
				var l := _gate_l(tr, (m["body"] as Node3D).global_position)
				if absf(l.y) > TRAP_REACH or absf(l.x) > float(tr["span"]) * 0.5 + 0.5:
					continue
			elif _flat((m["body"] as Node3D).global_position, tp) > TRAP_REACH:
				continue
			tr["done"] = true
			_meet_trap(m, tr, force_trap_spot if not gate else -1)
			break

func _meet_trap(m: Dictionary, tr: Dictionary, force_spot := -1) -> void:
	if tr.has("cells"):
		_meet_gate(m, tr, force_spot)
		return
	var h: Dictionary = m["h"]
	var spec: Dictionary = TRAPS.get(String(tr.get("kind", "SpikeTrap")), TRAPS["SpikeTrap"])
	var dc := trap_dc()
	var pd := _d20(-1 if dark and not Roster.has_trait(h, "darkvision") else 0)
	var per := pd + roster.mod(h, "wis") + (roster.prof(h) if String(h["class"]) in SPOTTERS else 0)
	var spotted := pd != 1 and (pd == 20 or per >= dc)
	if force_spot >= 0:
		spotted = force_spot == 1
	if not spotted and force_spot < 0:
		var reader := _trapsense()          # S156: a Tracker reads the first one a floor
		if reader != "":
			spotted = true
			_say("%s reads %s before anyone walks on it." % [reader, spec["name"]])
	if spotted:
		trap_log["spotted"] += 1
		if String(h["class"]) in TOOLS:
			var td := _rng.randi_range(1, 20)
			var tt := td + roster.mod(h, "dex") + roster.prof(h)
			if td != 1 and (td == 20 or tt >= dc):
				trap_log["disarmed"] += 1
				_say("%s spots %s (Perception %d vs DC %d) and disarms it with thieves' tools (%d)." % [h["name"], spec["name"], per, dc, tt])
				_float_text(m, "disarmed", Color(0.6, 1.0, 0.7))
				return
			if tt <= dc - 5:
				_say("%s fumbles the thieves' tools on %s (%d vs DC %d) -" % [h["name"], spec["name"], tt, dc])
				_spring(m, tr, spec, dc)
				return
		_say("%s spots %s (Perception %d vs DC %d) and steps round it." % [h["name"], spec["name"], per, dc])
		_bark(m, "trap")
		_float_text(m, "spotted", Color(0.85, 0.95, 1.0))
		return
	_spring(m, tr, spec, dc)

func _spring(m: Dictionary, tr: Dictionary, spec: Dictionary, dc: int) -> void:
	var h: Dictionary = m["h"]
	trap_log["sprung"] += 1
	var node: Node3D = tr["node"]
	if node.has_meta("fire"):
		(node.get_meta("fire") as Callable).call()
	node.set_meta("fired", int(node.get_meta("fired", 0)) + 1)
	if node.is_inside_tree():
		Sfx.at(String(spec["sfx"]), node.global_position, 2.0)
	var what := String(spec["what"])
	var dice: Array = spec["dice"]
	if String(tr.get("kind", "")) == "PressurePlate" and _rng.randi() % 2 == 0:
		what = "a stone from the ceiling!"
		dice = [1, 10]
	var dmg := float(_dice(int(dice[0]), int(dice[1])) + floor_no / 2)
	if String(tr.get("kind", "")) == "FireTrap":
		dmg *= _resist(m, "fire")
	var sd := _rng.randi_range(1, 20)
	var sv := sd + roster.save_bonus(h, "dex")
	var saved := sd != 1 and (sd == 20 or sv >= dc)
	if saved:
		trap_log["saved"] += 1
		dmg = floorf(dmg * 0.5)
	# L46: a trap that has actually SPRUNG must hurt. Measured: 2d6 halved by a good save floors
	# to 0, and a fire grate against a fire-resistant delver multiplies to 0 - so a trap could
	# land, play its sound, print its line and take nothing at all. That is the "traps are inert"
	# Mr. E reported. A save halves it and resistance blunts it, but neither nullifies it now.
	var took := maxf(1.0, _soak(m, dmg))
	trap_log["damage"] += took
	m["hp"] = float(m["hp"]) - took
	_say("%s steps on %s - %s DEX %d vs DC %d, %d damage%s." % [h["name"], spec["noun"], what, sv, dc, int(took), " (halved)" if saved else ""])
	_float_text(m, "-%d" % int(took), Color(1.0, 0.35, 0.25) if not saved else Color(1.0, 0.75, 0.3))
	if String(tr.get("kind", "")) == "FireTrap" and not saved:
		_give(m, "burning", 3.0)
	# L29c r5 trap variety: PoisonDart stacks a venom DoT on a failed save; the
	# dart itself only grazes (1d4) but the venom carries the hit over the next
	# few seconds, same mechanic a snake or spider bite uses, so the fight-loop
	# venom tick reads it for free.
	if String(tr.get("kind", "")) == "PoisonDart" and not saved:
		m["venom"] = maxf(float(m.get("venom", 0.0)), 6.0)
		m["venom_dps"] = maxf(float(m.get("venom_dps", 0.0)), 1.0 + float(floor_no) / 4.0)
		trap_log["venomed"] = int(trap_log.get("venomed", 0)) + 1
		_say("%s is venomed - the poison works over the next few seconds." % h["name"])
	# SwarmTrap lets a small pack up through the grate right where the hero stepped.
	# The plain damage above is the one-point tally so the "a trap must hurt" rule
	# from L46 stays honoured; the real teeth are the pack. Count a SEPARATE
	# telemetry key so the test can see swarm-ups fire in a soak without conflating
	# them with the ordinary trap tally.
	if String(tr.get("kind", "")) == "SwarmTrap":
		trap_log["swarms"] = int(trap_log.get("swarms", 0)) + 1
		_trap_swarm(tr)
	_hero_hit(m)

## ---------------------------------------------------------------- D88: the portcullis
## Mr. E (Nov 15 16:41): "trap". It hangs raised and still over a passage, wall to wall, until a
## party crosses its line. Spotted first (Perception vs trap_dc), it is wedged open and nobody
## is cut off. Missed, it DROPS on the one crossing: a DEX save is a dive clear to the far side,
## a failure takes the fall and is thrown back. Down, it is a box obstacle across the passage and
## its cells are hard - and it SPLITS THE PARTY, by name, in the feed. Then a choice with a cost:
## wind it up with the winch if there is one on someone's side (slow, free), go the long way round
## if the floor still joins up without it, or - when there is no other route, or someone is cut
## off from the stairs or the fight - the strongest body present forces it with Athletics (STR),
## each heave costing the lifter strain. All of it is counted in trap_log for the summary.
const ATHLETES := ["knight", "barbarian", "paladin", "warden"]
const GATE_DECIDE := 2.5          # seconds the party takes to see where it stands
const GATE_WINCH := 5.0           # winding a grid up by hand
const GATE_HEAVE := 2.0           # one heave at the bars
const GATE_TRIES := 8             # after this many heaves the whole party gets it up
var _gt := 0.0                    # a clock that does not restart with a floor (the gate's waits)
var gate_story: Array = []        # tests and the summary read it: what each gate did, in words
var gate_held := {}               # body -> frame it last waited at a dropped gate (tests read it)
static var force_trap_spot := -1  # D83 test hook: 0 = every ordinary trap is missed and springs
static var force_gate_spot := -1  # test hook: 0 = every portcullis is missed and drops, 1 = spotted

## where p stands in the gate's own frame: x across the passage, y (its local z) along the way
## through - the sign of y is the SIDE
func _gate_l(g: Dictionary, p: Vector3) -> Vector2:
	var c: Vector3 = (g["at"] as Vector3) + dun.global_position
	var y := float(g["yaw"])
	var dx := p.x - c.x
	var dz := p.z - c.z
	return Vector2(dx * cos(y) - dz * sin(y), dx * sin(y) + dz * cos(y))

func _gate_w(g: Dictionary, lx: float, lz: float, y0: float) -> Vector3:
	var c: Vector3 = (g["at"] as Vector3) + dun.global_position
	var y := float(g["yaw"])
	return Vector3(c.x + lx * cos(y) + lz * sin(y), y0, c.z - lx * sin(y) + lz * cos(y))

## the routes, patches and reach all change when a gate goes down or up
func _gate_nav_changed() -> void:
	_blocked_for = null
	_comp_for = null
	_paths.clear()
	_prog.clear()
	if dun and "_reach" in dun:
		dun._reach = {}

## every floor cell that can be walked to from c without crossing a hard (dropped-gate) cell
func _gate_flood(c: Vector2i) -> Dictionary:
	var cells: Dictionary = dun.info["cells"]
	var hard: Dictionary = dun.info.get("hard", {})
	var seen := {}
	if not cells.has(c) or hard.has(c):
		return seen
	seen[c] = true
	var q: Array[Vector2i] = [c]
	while not q.is_empty():
		var a: Vector2i = q.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = a + d
			if cells.has(n) and not hard.has(n) and not seen.has(n):
				seen[n] = true
				q.append(n)
	return seen

func _gate_side_names(g: Dictionary) -> Array:
	var neg: Array = []
	var pos: Array = []
	for m in _alive():
		var l := _gate_l(g, (m["body"] as Node3D).global_position)
		(pos if l.y >= 0.0 else neg).append(String(m["h"]["name"]))
	return [neg, pos]

func _meet_gate(m: Dictionary, tr: Dictionary, force_spot := -1) -> void:
	var h: Dictionary = m["h"]
	var dc := trap_dc()
	var pd := _d20(-1 if dark and not Roster.has_trait(h, "darkvision") else 0)
	var per := pd + roster.mod(h, "wis") + (roster.prof(h) if String(h["class"]) in SPOTTERS else 0)
	var spotted := pd != 1 and (pd == 20 or per >= dc)
	if force_spot < 0:
		force_spot = force_gate_spot
	if force_spot >= 0:
		spotted = force_spot == 1
	if spotted:
		trap_log["spotted"] += 1
		trap_log["gate_wedged"] = int(trap_log.get("gate_wedged", 0)) + 1
		tr["state"] = "wedged"
		if String(h["class"]) in TOOLS:
			trap_log["disarmed"] += 1
			_say("%s spots a portcullis hanging over the passage (Perception %d vs DC %d) and wedges its gear with thieves' tools - the grid stays up." % [h["name"], per, dc])
		else:
			_say("%s spots a portcullis hanging over the passage (Perception %d vs DC %d) and jams a haft into its gear - the party passes under it." % [h["name"], per, dc])
		gate_story.append("%s spotted the portcullis and wedged it" % h["name"])
		_bark(m, "trap")
		_float_text(m, "spotted", Color(0.85, 0.95, 1.0))
		return
	_gate_drop(m, tr, dc)

func _gate_drop(m: Dictionary, tr: Dictionary, dc: int) -> void:
	var h: Dictionary = m["h"]
	var spec: Dictionary = TRAPS["Portcullis"]
	trap_log["sprung"] += 1
	trap_log["gate_drops"] = int(trap_log.get("gate_drops", 0)) + 1
	var node: Node3D = tr["node"]
	if node.has_meta("drop"):
		(node.get_meta("drop") as Callable).call()
	node.set_meta("fired", int(node.get_meta("fired", 0)) + 1)
	if node.is_inside_tree():
		Sfx.at(String(spec["sfx"]), node.global_position, 2.0)
	tr["state"] = "down"
	tr["decide_at"] = _gt + GATE_DECIDE
	# down: a wall-to-wall box, and its cells off the grid for every route
	(dun.info["obstacles"] as Array).append(tr["box"])
	var hard: Dictionary = dun.info.get("hard", {})
	for c: Vector2i in tr["cells"]:
		hard[c] = true
	dun.info["hard"] = hard
	_gate_nav_changed()
	# which way was the crosser going? the rest of the party is behind it
	var me: Node3D = m["body"]
	var lme := _gate_l(tr, me.global_position)
	var behind := 0.0
	for o in _alive():
		if o != m:
			behind += signf(_gate_l(tr, (o["body"] as Node3D).global_position).y)
	var near := signf(behind)
	if near == 0.0:
		near = signf(lme.y) if absf(lme.y) > 0.05 else -1.0
	var sd := _rng.randi_range(1, 20)
	var sv := sd + roster.save_bonus(h, "dex")
	var saved := sd != 1 and (sd == 20 or sv >= dc)
	# off the gate's cells altogether (a body left inside one could be routed out the far side)
	var G: float = dun.info["grid"]
	var clear := G * 0.5 + 0.6
	var wx := float(tr["span"]) * 0.5 - 0.6
	var side := -near if saved else near
	me.global_position = _gate_w(tr, clampf(lme.x, -wx, wx), side * clear, me.global_position.y)
	_paths.erase(me)
	if saved:
		trap_log["saved"] += 1
		_say("%s crosses under a portcullis - it crashes down! DEX %d vs DC %d: a dive clear, rolling out on the far side." % [h["name"], sv, dc])
		_float_text(m, "dive!", Color(0.6, 1.0, 0.7))
	else:
		var dmg := float(_dice(int(spec["dice"][0]), int(spec["dice"][1])) + floor_no / 2)
		var took := maxf(1.0, _soak(m, dmg))
		trap_log["damage"] += took
		m["hp"] = float(m["hp"]) - took
		_say("%s crosses under a portcullis - it crashes down on them! DEX %d vs DC %d, %d damage, and they are thrown back." % [h["name"], sv, dc, int(took)])
		_float_text(m, "-%d" % int(took), Color(1.0, 0.35, 0.25))
		_hero_hit(m)
	# anyone else under the line is shoved to the side they stood on - and so is any creature
	for o in _alive():
		if o == m:
			continue
		var ob: Node3D = o["body"]
		var l := _gate_l(tr, ob.global_position)
		if absf(l.y) < clear and absf(l.x) < wx + 1.2:
			ob.global_position = _gate_w(tr, clampf(l.x, -wx, wx), (signf(l.y) if l.y != 0.0 else near) * clear, ob.global_position.y)
	for f in _foes():
		var fb: Node3D = f
		var l2 := _gate_l(tr, fb.global_position)
		if absf(l2.y) < clear and absf(l2.x) < wx + 1.2:
			fb.global_position = _gate_w(tr, clampf(l2.x, -wx, wx), (signf(l2.y) if l2.y != 0.0 else -near) * clear, fb.global_position.y)
	# IT SPLITS THE PARTY - say who is on which side, by name
	var sides := _gate_side_names(tr)
	var far: Array = sides[1] if near < 0.0 else sides[0]
	var here: Array = sides[0] if near < 0.0 else sides[1]
	if not far.is_empty() and not here.is_empty():
		trap_log["gate_splits"] = int(trap_log.get("gate_splits", 0)) + 1
		_say("The portcullis splits the party: %s on the far side, %s cut off behind the bars." % [", ".join(far), ", ".join(here)])
		gate_story.append("a portcullis split the party (%s | %s)" % [", ".join(far), ", ".join(here)])
	else:
		gate_story.append("a portcullis came down in front of %s" % ", ".join(far + here))

func _gates_tick() -> void:
	for g in dun.info.get("gates", []):
		var tr: Dictionary = g
		match String(tr.get("state", "up")):
			"down":
				if _gt >= float(tr["decide_at"]):
					_gate_decide(tr)
			"forcing":
				if _gt >= float(tr["next_at"]):
					_gate_heave(tr)
			"winching":
				if _gt >= float(tr["next_at"]):
					trap_log["gate_winched"] = int(trap_log.get("gate_winched", 0)) + 1
					_say("The winch catches - the portcullis is up, and wedged there.")
					gate_story.append("the winch raised it")
					_gate_lift(tr, 0.0)

## the gate is down: what does the party do about it?
func _gate_decide(tr: Dictionary) -> void:
	var al := _alive()
	if al.is_empty():
		tr["state"] = "shut"
		return
	# 1. the winch, if it stands on someone's side: slow, but it costs nobody anything
	var w := int(tr.get("winch", 0))
	if w != 0:
		for o in al:
			if signf(_gate_l(tr, (o["body"] as Node3D).global_position).y) == float(w):
				tr["state"] = "winching"
				tr["next_at"] = _gt + GATE_WINCH
				var node: Node3D = tr["node"]
				if node.has_meta("raise"):
					(node.get_meta("raise") as Callable).call(GATE_WINCH)
				_say("%s finds the winch beside the gate and starts winding - the grid groans up a hand at a time." % o["h"]["name"])
				return
	# 2. is the floor still one piece without it? (the long way round)
	var d: Vector2i = tr["d"]
	var c0: Vector2i = (tr["cells"] as Array)[0]
	var reach := _gate_flood(c0 - d)
	if reach.has(c0 + d):
		tr["state"] = "shut"
		trap_log["gate_longway"] = int(trap_log.get("gate_longway", 0)) + 1
		_say("The portcullis will not be lifted here - the party goes the long way round.")
		gate_story.append("the party went the long way round")
		return
	# 3. no other route. Does anyone NEED to cross? Not if every delver, the stairs and every
	# creature still standing are on one side.
	var side := {}
	for o in al:
		side[_cell_of((o["body"] as Node3D).global_position)] = true
	var ex: Vector3 = dun.info["exit"] + dun.global_position
	var want: Array = [_cell_of(ex)]
	for f in _foes():
		want.append(_cell_of((f as Node3D).global_position))
	var first: Vector2i = side.keys()[0]
	var one := _gate_flood(first)
	var together := true
	for c in side.keys() + want:
		if not one.has(c):
			together = false
			break
	if together:
		tr["state"] = "shut"
		trap_log["gate_behind"] = int(trap_log.get("gate_behind", 0)) + 1
		_say("The portcullis stays down behind them - the way on lies ahead.")
		gate_story.append("it stayed down behind the party")
		return
	tr["state"] = "forcing"
	tr["tries"] = 0
	tr["next_at"] = _gt + 0.5
	var who := _gate_lifter(al)
	_say("There is no other way through. %s sets their shoulders to the bars." % who["h"]["name"])

## the strongest body present: STR, and Athletics for the classes trained in it
func _gate_lifter(al: Array) -> Dictionary:
	var best: Dictionary = al[0]
	var bb := -99
	for o in al:
		var h: Dictionary = o["h"]
		var b := roster.mod(h, "str") + (roster.prof(h) if String(h["class"]) in ATHLETES else 0)
		if b > bb:
			bb = b
			best = o
	return best

func _gate_heave(tr: Dictionary) -> void:
	var al := _alive()
	if al.is_empty():
		tr["state"] = "shut"
		return
	var m := _gate_lifter(al)
	var h: Dictionary = m["h"]
	var dc := trap_dc()
	tr["tries"] = int(tr["tries"]) + 1
	var bonus := roster.mod(h, "str") + (roster.prof(h) if String(h["class"]) in ATHLETES else 0)
	# after the first heave the others on that side lend their weight (advantage)
	var mine := signf(_gate_l(tr, (m["body"] as Node3D).global_position).y)
	var helpers := 0
	for o in al:
		if o != m and signf(_gate_l(tr, (o["body"] as Node3D).global_position).y) == mine:
			helpers += 1
	var d1 := _d20(1 if int(tr["tries"]) > 1 and helpers > 0 else 0)
	var tot := d1 + bonus
	# every heave costs the lifter: the price of the only way through
	var strain := float(_dice(1, 4))
	m["hp"] = maxf(1.0, float(m["hp"]) - strain)
	trap_log["gate_heaves"] = int(trap_log.get("gate_heaves", 0)) + 1
	trap_log["gate_strain"] = float(trap_log.get("gate_strain", 0.0)) + strain
	_float_text(m, "-%d" % int(strain), Color(1.0, 0.75, 0.3))
	if d1 != 1 and (d1 == 20 or tot >= dc):
		trap_log["gate_forced"] = int(trap_log.get("gate_forced", 0)) + 1
		_say("%s heaves the portcullis up (Athletics %d vs DC %d) and wedges it - %d strain for it." % [h["name"], tot, dc, int(strain)])
		gate_story.append("%s forced it on heave %d" % [h["name"], int(tr["tries"])])
		_gate_lift(tr, 0.6)
	elif int(tr["tries"]) >= GATE_TRIES:
		trap_log["gate_forced"] = int(trap_log.get("gate_forced", 0)) + 1
		_say("Every hand on the bars at once - the portcullis grinds up at last, and they wedge it.")
		gate_story.append("the whole party forced it after %d heaves" % int(tr["tries"]))
		_gate_lift(tr, 0.8)
	else:
		_say("%s strains at the bars (Athletics %d vs DC %d) - it will not shift. %d strain." % [h["name"], tot, dc, int(strain)])
		tr["next_at"] = _gt + GATE_HEAVE

## the gate is up for good: its box and its hard cells go, the routes are worked out afresh
func _gate_lift(tr: Dictionary, secs: float) -> void:
	tr["state"] = "wedged"
	(dun.info["obstacles"] as Array).erase(tr["box"])
	var hard: Dictionary = dun.info.get("hard", {})
	for c: Vector2i in tr["cells"]:
		hard.erase(c)
	var node: Node3D = tr["node"]
	if secs > 0.0 and node.has_meta("raise"):
		(node.get_meta("raise") as Callable).call(secs)
	_gate_nav_changed()

## ---------------------------------------------------------------- D83: admitting a creature
## Mr. E (Nov 15 16:22): "the traps are stuck". MEASURED (tools/_d83_test.gd), not guessed: the
## trap props all reset cleanly and leave nothing behind, and nav is not the fault (routes are a
## lazy cache, built on first use). The fault was the creatures a trap or an ambush lets up while
## the party is SEARCHING or WALKING TO THE STAIRS - which is where most traps are met. Nothing
## fights them outside "fight", so they stayed in Monster PATROL, and PATROL set their height
## from an unset ground_fn - flat 0.0 in world space, 400 m above a floor at DELVE_Y. They hung
## in the void, walked to the x/z of a goal 400 m below them and stood there for good, and the
## party walked off to the next floor without them. Every creature added to a floor after it is
## built now comes through here: it stands on THIS floor, it is a foe the fight loop knows, and
## if the party had stopped fighting, they turn and fight it, then go back to what they were doing.
var _back_to := ""                  # the state a mid-floor creature pulled the party out of
var rejoined := 0                   # the D83 test counts these

func _floor_y(_x: float, _z: float) -> float:
	return dun.global_position.y if dun != null and is_instance_valid(dun) else DELVE_Y

func _admit(mon: Monster) -> void:
	mon.ground_fn = Callable(self, "_floor_y")
	if not (dun.monsters as Array).has(mon):
		(dun.monsters as Array).append(mon)
	if state in ["search", "descend"]:
		rejoined += 1
		_back_to = state if _back_to == "" else _back_to
		state = "fight"
		_t = 0.0
		_nav_reset()

## L29c r5: a SwarmTrap springs up a short pack of theme-matched creatures
## RIGHT WHERE THE PARTY STANDS, like an AMBUSH set piece but wired from the
## trap pool. Reuses dun.monsters so the fight loop picks it up for free.
func _trap_swarm(tr: Dictionary) -> void:
	if dun == null or not is_instance_valid(dun):
		return
	var node = tr.get("node")
	if not is_instance_valid(node):
		return
	var at: Vector3 = (node as Node3D).global_position
	var theme := String(dun.info.get("theme", ""))
	var names: Array = []
	for k in range(2):
		var d := Bestiary.pick(floor_no, theme)
		var mon := Monster.new()
		mon.def = d
		mon.state = Monster.S.PATROL
		mon.roam = 2.0
		var off := Vector3(cos(float(k) * 2.1), 0.0, sin(float(k) * 2.1)) * 1.2
		mon.position = Vector3(at.x - dun.global_position.x + off.x, 0.0, at.z - dun.global_position.z + off.z)
		dun.add_child(mon)
		_admit(mon)
		mon.max_hp = (14.0 + float(floor_no) * 6.0) * float(d.get("hp", 1.0))
		mon.hp = mon.max_hp
		names.append(String(d.get("name", "something")))
	# "2 rats", not "rat, rat"
	var counts := {}
	for nm in names:
		counts[nm] = int(counts.get(nm, 0)) + 1
	var parts: Array = []
	for k in counts:
		var ks := String(k)
		var nc: int = counts[k]
		parts.append("%d %s" % [nc, ks if nc == 1 or ks.ends_with("s") else ks + "s"])
	_say("The grate pops - %s comes up through it." % ", ".join(parts))
	Sfx.play("roar", -5.0)

## ---- S31 SYSTEM 5: POTION VISUALS. A brew is a bottle you can see - in the hand when it is
## drunk, on the floor when a search turns one up. Fantasy Props MegaKit bottles (CC0, already in
## assets/props/ with its LICENSE). Mr. E's colour key: RED = mending (any potion with "heal"),
## GREEN = speed (gives haste), BLUE = everything else - this game has no mana, so blue is the
## ward/state brews. The colour and the bottle shape both come off the potion's own row.
const VIAL_PROPS := "res://assets/props/"
const VIAL_SCALE := 2.6        # a 14-26 cm bottle is invisible at stream distance; read, not real
const VIAL_RED := Color(0.92, 0.12, 0.10)
const VIAL_GREEN := Color(0.25, 0.90, 0.20)
const VIAL_BLUE := Color(0.20, 0.45, 1.00)
const VIAL_HAND := "handslot.r"   # S31c: the hand Use_Item lifts to the mouth
const VIAL_LIFT := 0.12            # S31c: the bottle stands this far up out of the fist
const VIAL_TIP := 20.0             # S31c: degrees the neck leans back toward the mouth
var _vial_scn := {}

static func vial_kind(p: Dictionary) -> String:
	if p.has("heal"):
		return "heal"
	if String(p.get("gives", "")) == "haste":
		return "speed"
	return "ward"

static func vial_colour(kind: String) -> Color:
	match kind:
		"heal":
			return VIAL_RED
		"speed":
			return VIAL_GREEN
	return VIAL_BLUE

static func vial_model(kind: String) -> String:
	match kind:
		"heal":
			return VIAL_PROPS + "Potion_1.gltf"
		"speed":
			return VIAL_PROPS + "Potion_2.gltf"
	return VIAL_PROPS + "Potion_4.gltf"

func _tint_vial(n: Node, col: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(col.r, col.g, col.b, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 1.6
	for c in n.find_children("*", "MeshInstance3D", true, false):
		(c as MeshInstance3D).material_overlay = mat

## S96 / SYSTEM 9 row (b): a deep-floor weapon find lies on the floor at the finder's feet in the weapon's own
## mesh (roster.weapon_mesh - the same path the hand will carry, no second map), turns once, and is lifted away.
## Guarded like miniboss_model: a path that does not load is skipped, never instantiated through a null.
const FIND_SCALE := 0.8
var finds_shown := 0
var _find_scn := {}

func _show_find(m: Dictionary, path: String) -> void:
	var b = m.get("body")
	if path == "" or not (b is Node3D) or not is_instance_valid(b) or not (b as Node3D).is_inside_tree():
		return
	if not ResourceLoader.exists(path):
		return
	if not _find_scn.has(path):
		_find_scn[path] = load(path)
	if not (_find_scn[path] is PackedScene):
		return
	var w: Node3D = (_find_scn[path] as PackedScene).instantiate()
	w.name = "FoundWeapon"
	w.top_level = true
	var host: Node = dun.info["root"] if dun and dun.info.has("root") else self
	host.add_child(w)
	var bn := b as Node3D
	var fwd := bn.global_transform.basis.z.normalized()
	# laid flat on the stones: the kit meshes are built along +Y, so -90 about X lays the blade down
	w.global_transform = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-90.0)).scaled(Vector3.ONE * FIND_SCALE),
		bn.global_position + fwd * 0.7 + Vector3(0, 0.04, 0))
	w.set_meta("find_path", path)
	finds_shown += 1
	var tw := w.create_tween()
	tw.tween_property(w, "rotation:y", TAU, 3.0)
	tw.tween_property(w, "global_position", bn.global_position + Vector3(0, 1.1, 0), 0.5).set_ease(Tween.EASE_IN)
	tw.tween_property(w, "scale", Vector3.ONE * 0.01, 0.25)
	tw.tween_callback(w.queue_free)

func _show_vial(m: Dictionary, key: String, on_floor: bool) -> void:
	var b = m.get("body")
	if not (b is Node3D) or not is_instance_valid(b) or not (b as Node3D).is_inside_tree():
		return
	var kind := vial_kind(Roster.potion(key))
	var path := vial_model(kind)
	if not ResourceLoader.exists(path):
		return
	if not _vial_scn.has(path):
		_vial_scn[path] = load(path)
	var v: Node3D = (_vial_scn[path] as PackedScene).instantiate()
	v.name = "Vial_" + kind
	_tint_vial(v, vial_colour(kind))
	var bn := b as Node3D
	# S31c: THE DRINK IS HELD. The 04:58 render showed the bottle hanging before the visor with both arms
	# down - nothing held it. Use_Item (drink() plays it) lifts the RIGHT hand to the mouth: measured on the
	# knight by tools/_s31c_probe.gd, handslot.r rises 0.64 -> 1.10 m at t 0.7 s, 0.3 m ahead, head bone 1.20.
	# So the bottle rides handslot.r, and the weapon in that hand is lowered out of sight for the sip.
	var sk: Skeleton3D = null if on_floor else Rig.skeleton(bn)
	if sk != null and sk.find_bone(VIAL_HAND) >= 0:
		var old := sk.get_node_or_null(NodePath("eq_vial"))
		if old:
			old.free()
		var att := BoneAttachment3D.new()
		att.name = "eq_vial"
		att.bone_name = VIAL_HAND
		sk.add_child(att)
		att.add_child(v)
		# held UPRIGHT and lifted out of the fist: the hand's own roll laid the bottle on its side inside a
		# chibi fist in the first S31c render, so it follows the hand's POSITION but keeps the world's up
		v.top_level = true
		# top_level keeps the global transform it had under the hand, roll and all, so set the basis outright:
		# upright, the neck tipped back toward the mouth - a sip, not a bottle pointed at the viewer
		var fw := bn.global_transform.basis.z
		fw = Vector3(fw.x, 0, fw.z).normalized() if Vector3(fw.x, 0, fw.z).length() > 0.01 else Vector3.BACK
		v.global_transform = Transform3D(Basis(fw.cross(Vector3.UP).normalized(), deg_to_rad(VIAL_TIP)).scaled(Vector3.ONE * VIAL_SCALE),
			att.global_position + Vector3(0, VIAL_LIFT, 0))
		var follow := func(_x: float) -> void:
			if is_instance_valid(v) and is_instance_valid(att):
				v.global_position = att.global_position + Vector3(0, VIAL_LIFT, 0)
		v.create_tween().tween_method(follow, 0.0, 1.0, 1.6)
		var wpn := sk.get_node_or_null(NodePath("eq_weapon")) as Node3D
		var wv := wpn != null and wpn.visible
		if wv:
			wpn.visible = false
		var th := v.create_tween()
		th.tween_interval(1.3)
		th.tween_property(v, "scale", Vector3.ONE * VIAL_SCALE * 0.01, 0.3)
		th.tween_callback(func():
			if wv and is_instance_valid(wpn):
				wpn.visible = true
			if is_instance_valid(att):
				att.queue_free())
		return
	v.top_level = true
	v.scale = Vector3.ONE * VIAL_SCALE
	var host: Node = dun.info["root"] if dun and dun.info.has("root") else self
	host.add_child(v)
	# S31 fit: a body LOOKS down +z (KayKit faces +z; the delve turns it by rotation.y = atan2(dx, dz)),
	# so +basis.z is in front of the face. The first cut used -z and every bottle sat behind the head.
	var fwd := bn.global_transform.basis.z.normalized()
	var tw := v.create_tween()
	if on_floor:
		# the find: on the stones at the seeker's feet, a slow turn, then picked up
		v.global_position = bn.global_position + fwd * 0.6 + Vector3(0, 0.02, 0)
		tw.tween_property(v, "rotation:y", TAU, 3.0)
		tw.tween_property(v, "global_position", bn.global_position + Vector3(0, 1.2, 0), 0.5).set_ease(Tween.EASE_IN)
		tw.tween_property(v, "scale", Vector3.ONE * 0.01, 0.25)
	else:
		# the drink: up at the mouth for as long as Use_Item reads, then gone
		# S31 fit: 0.75 m out - a chibi helmet reaches ~0.6 m past the root, so 0.35 hid the bottle in the visor
		v.global_position = bn.global_position + fwd * 0.75 + Vector3(0, 1.25, 0)
		tw.tween_property(v, "global_position", bn.global_position + fwd * 0.65 + Vector3(0, 1.55, 0), 0.9)
		tw.tween_property(v, "scale", Vector3.ONE * 0.01, 0.3)
	tw.tween_callback(v.queue_free)

## a number or word floating up off a delver's head
func _float_text(m: Dictionary, text: String, col: Color, size := 84, lift := 2.4) -> void:
	var b: Node3D = m["body"]
	if not is_instance_valid(b) or not b.is_inside_tree():
		return
	var lb := Label3D.new()
	lb.text = text
	lb.font_size = size
	lb.pixel_size = 0.006 if HudDock.split(town) else 0.01      # L21: smaller in a close side-by-side pane
	lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lb.no_depth_test = true
	lb.outline_size = 22
	lb.outline_modulate = Color(0, 0, 0, 0.95)
	lb.modulate = col
	lb.top_level = true
	# on the floor, not the hero: HeroBody renames every Label3D under it to its name
	var host: Node = dun.info["root"] if dun and dun.info.has("root") else self
	host.add_child(lb)
	var p := b.global_position + Vector3(0, lift, 0)
	lb.global_position = p
	var tw := lb.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lb, "global_position", p + Vector3(0, 1.4, 0), 1.2).set_ease(Tween.EASE_OUT)
	tw.tween_property(lb, "modulate:a", 0.0, 1.2).set_delay(0.5)
	tw.chain().tween_callback(lb.queue_free)

## ---- L12: states and potions below. A delver's states live in m["st"]
## {name: seconds}; venom ("poisoned") and frost ("slowed") keep their old
## fields so everything that already set them still does.
func has_st(m, name: String) -> bool:
	if m == null:
		return false
	match name:
		"poisoned":
			return float(m.get("venom", 0.0)) > 0.0
		"slowed":
			return float(m.get("slow", 0.0)) > 0.0
	return float((m.get("st", {}) as Dictionary).get(name, 0.0)) > 0.0

## Rally (bits/points reward): the working combat states a rallied hero carries -
## +2 to-hit & +4 damage (giant), faster swings (haste), no fear (heroism).
## Mending over time is set separately via hot_t/hot_rate (the engine's own HoT).
const RALLY_STATES := ["giant", "haste", "heroism"]
const RALLY_HOT_FRAC := 0.015      # heal this fraction of max hp per second

## Apply the rally package to one delver dict (live or just-formed).
func _rally_states(m: Dictionary, secs: float) -> void:
	for s in RALLY_STATES:
		_give(m, s, secs)
	# mend over time: top them up while the rally lasts (capped at max each tick)
	m["hot_t"] = maxf(float(m.get("hot_t", 0.0)), secs)
	m["hot_rate"] = maxf(float(m.get("hot_rate", 0.0)), float(m["max"]) * RALLY_HOT_FRAC)

## Apply a rally to a live delver right now. Returns true if the hero was found
## alive in this delve (so the caller knows not to leave a pending flag).
func apply_rally(uid: String, secs: float) -> bool:
	for m in party:
		if String(m["uid"]) == uid and float(m.get("hp", 0.0)) > 0.0:
			_rally_states(m, secs)
			_say("%s is rallied mid-delve - strength, speed, and courage surge." % String(m["h"]["name"]))
			return true
	return false

func _give(m: Dictionary, name: String, secs: float) -> void:
	if float(m.get("hp", 0.0)) <= 0.0:
		return
	if name == "frightened" and has_st(m, "heroism"):
		return
	if name == "burning" and has_st(m, "resist_fire"):
		return
	if name == "slowed" and has_st(m, "resist_frost"):
		return
	# S118 (L31 remainder b): `was` is now read - a state that is NEW on this delver
	# gets its on-apply line (the state's own word and colour out of potions.json
	# `states`, the same words the potion path floats); a refresh of a state already
	# held stays silent, so a venom that ticks every hit does not spam the floor.
	var was := has_st(m, name)
	if name == "slowed":
		m["slow"] = maxf(float(m.get("slow", 0.0)), secs)
	elif name == "poisoned":
		m["venom"] = maxf(float(m.get("venom", 0.0)), secs)
	else:
		if not m.has("st"):
			m["st"] = {}
		m["st"][name] = maxf(float((m["st"] as Dictionary).get(name, 0.0)), secs)
	if not was and has_st(m, name):
		_on_apply(m, name)

## S118: the on-apply line for a newly given state. Counted (applied_lines) so a gate
## can prove it fired without a body on the floor; drawn only when there is one.
var applied_lines := 0
func _on_apply(m: Dictionary, name: String) -> void:
	var spec: Dictionary = (Roster.potions().get("states", {}) as Dictionary).get(name, {})
	if spec.is_empty():
		return
	applied_lines += 1
	if m.has("body") and is_instance_valid(m["body"]):
		_float_text(m, String(spec["word"]), Color.html(String(spec.get("colour", "ffffff"))), 64, 2.0)

## S118 (L31 remainder a): the seconds a state has left - venom and slow keep their
## old fields, everything else is m["st"][name]. 0.0 when not held.
func st_secs(m, name: String) -> float:
	if m == null:
		return 0.0
	match name:
		"poisoned":
			return maxf(0.0, float(m.get("venom", 0.0)))
		"slowed":
			return maxf(0.0, float(m.get("slow", 0.0)))
	return maxf(0.0, float((m.get("st", {}) as Dictionary).get(name, 0.0)))

func _status_tick(m: Dictionary, delta: float) -> void:
	if not m.has("st"):
		return
	var st: Dictionary = m["st"]
	for k in st.keys():
		st[k] = float(st[k]) - delta
		if float(st[k]) <= 0.0:
			st.erase(k)
	# burning: 1d4 fire a second
	if has_st(m, "burning"):
		m["burn_acc"] = float(m.get("burn_acc", 0.0)) + delta
		if float(m["burn_acc"]) >= 1.0:
			m["burn_acc"] = 0.0
			m["hp"] = float(m["hp"]) - _soak(m, float(_dice(1, 4)))
			_hero_hit(m)

func _resist(m: Dictionary, elem: String) -> float:
	if elem == "fire" and has_st(m, "resist_fire"):
		return 0.5
	if elem == "frost" and has_st(m, "resist_frost"):
		return 0.5
	return 1.0

## advantage / disadvantage on a delver's attack (they cancel, as in 5e)
func _hero_adv(m: Dictionary) -> int:
	var h: Dictionary = m["h"]
	var dis := (dark and not Roster.has_trait(h, "darkvision") and not has_st(m, "darkvision")) \
		or has_st(m, "poisoned") or has_st(m, "blinded") or has_st(m, "frightened")
	var adv := has_st(m, "invisible")
	if adv and not dis:
		return 1
	if dis and not adv:
		return -1
	return 0

## a potion, if one is called for: low on life, a cure for what ails them, a
## lord to face, the dark. Drinking takes the delver's swing.
const HEAL_ORDER := ["supreme", "superior", "greater", "mending"]
func _quaff(m: Dictionary) -> bool:
	if float(m.get("quaff_t", 0.0)) > _t:
		return false
	var h: Dictionary = m["h"]
	var want := ""
	if float(m["hp"]) < float(m["max"]) * float(Economy.healing_rules()["quaff_below"]):   # D99: classes.json healing.quaff
		for k in HEAL_ORDER:
			if roster.brew_count(h, k) > 0:
				want = k
				break
	if want == "":
		for pair in [["poisoned", "antidote"], ["burning", "emberward"], ["slowed", "hearthwarm"], ["frightened", "bravecup"]]:
			if has_st(m, pair[0]) and roster.brew_count(h, pair[1]) > 0:
				want = pair[1]
				break
	if want == "" and dark and not Roster.has_trait(h, "darkvision") and not has_st(m, "darkvision") and roster.brew_count(h, "owl") > 0:
		want = "owl"
	if want == "" and lord_fighting() != null and not bool(m.get("buffed", false)):
		for k in ["ogre", "quickwater", "shadow", "bravecup"]:
			if roster.brew_count(h, k) > 0:
				want = k
				m["buffed"] = true
				break
	if want == "":
		return false
	# L47: reaching for a brew IS a decision, and it already has a visible tell (Use_Item, the
	# bark, the float). It just was not legible AS a decision - so it is counted and reasoned
	# like the rest now. drink() already announces a heal, so only the quieter cases speak here.
	var h2: Dictionary = m["h"]
	var why := "brew"
	if float(m["hp"]) < float(m["max"]) * float(Economy.healing_rules()["quaff_below"]):   # D99: classes.json healing.quaff
		why = "brew_hurt"
		decided[why] = int(decided.get(why, 0)) + 1
		decisions += 1
	elif lord_fighting() != null and bool(m.get("buffed", false)):
		why = "brew_lord"
		_decide(m, why, "%s steels themself for the lord." % h2["name"])
	else:
		why = "brew_cure"
		_decide(m, why, "%s drinks off what is on them." % h2["name"])
	drink(m, want)
	if is_instance_valid(m.get("body")):
		_snd("potion_drink", (m["body"] as Node3D).global_position + Vector3(0, 1.5, 0), POTION_DB)     # S2 (S3: up - it was buried)
	return true

func drink(m: Dictionary, key: String) -> void:
	var h: Dictionary = m["h"]
	var p := Roster.potion(key)
	roster.add_brew(h, key, -1)
	m["quaff_t"] = _t + 2.5
	m["swing"] = maxf(float(m.get("swing", 0.0)), 0.8)
	var b = m["body"]
	if b is HeroBody and is_instance_valid(b):
		Rig.play((b as HeroBody)._anim, "Use_Item")
	_show_vial(m, key, false)          # S31 System 5: the bottle is seen, not just the float
	if p.has("heal"):
		var hd: Array = p["heal"]
		var amt := float(_dice(int(hd[0]), int(hd[1])) + int(hd[2]))
		amt = _mend(m, amt)
		_float_text(m, "+%d" % int(amt), Color(0.45, 1.0, 0.5))
		_bark(m, "drink")
		if key != "mending":
			_say("%s drinks %s (+%d)." % [h["name"], p["name"], int(amt)])
		# any mending puts out a fire on you
		if m.has("st"):
			(m["st"] as Dictionary).erase("burning")
		return
	for c in p.get("cures", []):
		match String(c):
			"poisoned":
				m["venom"] = 0.0
			"slowed":
				m["slow"] = 0.0
			_:
				if m.has("st"):
					(m["st"] as Dictionary).erase(String(c))
	if p.has("gives"):
		if not m.has("st"):
			m["st"] = {}
		m["st"][String(p["gives"])] = float(p.get("secs", 30))
		if String(p["gives"]) == "heroism":
			m["hp"] = float(m["hp"]) + 10.0          # 5e: temporary hit points
	var spec: Dictionary = (Roster.potions().get("states", {}) as Dictionary).get(String(p.get("gives", "")), {})
	_float_text(m, String(spec.get("word", p["name"])), Color.html(String(spec.get("colour", "c0ffc0"))))
	_say("%s drinks %s." % [h["name"], p["name"]])

## the states a delver shows: [[word, colour], ...] - the bad first
func statuses(m: Dictionary) -> Array:
	var out: Array = []
	var states: Dictionary = Roster.potions().get("states", {})
	for bad in [true, false]:
		for k in states:
			if bool(states[k]["bad"]) == bad and has_st(m, k):
				# L31: [word, colour, key, bad, secs] - callers that read [0]/[1] are unchanged; S118 adds [4], the seconds left
				out.append([String(states[k]["word"]), Color.html(String(states[k]["colour"])), String(k), bad, st_secs(m, String(k))])
	return out

## the states over each delver's head (on the floor, not the body - HeroBody
## renames every Label3D under it)
var _tags := {}
var _tag_t := 0.0
func _tags_tick(delta: float) -> void:
	_tag_t -= delta
	if _tag_t > 0.0:
		return
	_tag_t = 0.2
	for m in party:
		var uid := String(m["uid"])
		var b: Node3D = m["body"]
		var sts := statuses(m) if float(m["hp"]) > 0.0 else []
		var lb = _tags.get(uid)
		if lb != null and not is_instance_valid(lb):
			lb = null          # freed with the last floor
		if sts.is_empty() or not is_instance_valid(b) or dun == null:
			if lb and is_instance_valid(lb):
				lb.visible = false
			continue
		if lb == null or not is_instance_valid(lb):
			lb = Label3D.new()
			lb.font_size = 36
			lb.offset = Vector2(0, -62)
			lb.pixel_size = 0.01
			lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			lb.no_depth_test = true
			lb.outline_size = 16
			lb.outline_modulate = Color(0, 0, 0, 0.95)
			lb.top_level = true
			dun.info["root"].add_child(lb)
			_tags[uid] = lb
		var words: Array = []
		for s in sts:
			words.append(String(s[0]))
		lb.text = " · ".join(words)
		lb.modulate = sts[0][1]
		lb.visible = true
		# anchored where the name is, pushed down in the billboard's own plane: always just under the name
		lb.global_position = b.global_position + Vector3(0, 2.3, 0)
		# L15: keep the tag readable from far off (same rule as the names)
		var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
		if cam:
			# L21: sized for the director's camera at full screen; with panes up the side-by-side lane camera is
			# ~11 m off and would draw it huge - a fixed close size then (quarter panes do not draw it at all)
			lb.pixel_size = 0.005 if HudDock.split(town) else 0.01 * clampf(cam.global_position.distance_to(lb.global_position) / 22.0, 0.4, 2.5)

## ---- L19: more of the original's voice (data/lore_lines.json)
static var _lore: Dictionary = {}
static func lore() -> Dictionary:
	if _lore.is_empty():
		var f := FileAccess.open("res://data/lore_lines.json", FileAccess.READ)
		if f:
			_lore = JSON.parse_string(f.get_as_text())
	return _lore

## ---- D98: the lord / unique arrival line, drawn from BOTH pools.
## The live lord_intros / unique_intros value is ONE STRING per id; the C-8 _alt pool is a LIST
## for the same id. Content's pick rule (lore_lines "_note"): [live] + alt, then draw - so a second
## sighting on one stream does not read word for word the first. An id with no alt list still gets
## its one live line; an id with neither gets "" (the caller already skips an empty intro).
static func intro_pool(uniq: bool, id: String) -> Array:
	var base := "unique_intros" if uniq else "lord_intros"
	var pool: Array = []
	var live := String((lore().get(base, {}) as Dictionary).get(id, ""))
	if live != "":
		pool.append(live)
	var alt = (lore().get(base + "_alt", {}) as Dictionary).get(id, [])
	if alt is Array:
		for a in alt:
			if String(a) != "":
				pool.append(String(a))
	return pool

static func intro_line(uniq: bool, id: String, rng: RandomNumberGenerator = null) -> String:
	var pool := intro_pool(uniq, id)
	if pool.is_empty():
		return ""
	return String(pool[(rng.randi() if rng else randi()) % pool.size()])

## ---- miniboss_feed reader (data/lore_lines.json "miniboss_feed".by_key[key][phase]).
## Phases: arrive / act / broken / fall. arrive and fall are wired (spawn, death);
## act and broken belong to each miniboss's own mechanic, which is not built yet -
## they are readable here so that mechanic only has to call _miniboss_say.
static func miniboss_lines(key: String, phase: String) -> Array:
	var mf: Dictionary = lore().get("miniboss_feed", {})
	var bk: Dictionary = mf.get("by_key", {})
	# S51: content is renaming the feed to the new names; read the trade key first, then the
	# new name's key (lower-case), so the gate holds whichever way content keys its rows.
	var row: Dictionary = bk.get(key, {})
	if row.is_empty() and MB_NAME.has(key):
		row = bk.get(String(MB_NAME[key]).to_lower(), {})
	return row.get(phase, [])

## one line for the event, {name} filled with an alive delver (lines that need a
## hero and have none are skipped in favour of ones that do not)
## S34: an act line names the delver the idea actually landed on ("The hook takes {name}")
func _miniboss_say_for(key: String, phase: String, who: Dictionary) -> String:
	var opts: Array = miniboss_lines(key, phase)
	if opts.is_empty():
		return ""
	var line := String(opts[_rng.randi() % opts.size()])
	if line.contains("{name}"):
		line = line.replace("{name}", String((who.get("h", {}) as Dictionary).get("name", "a delver")))
	return line

func _miniboss_say(key: String, phase: String) -> String:
	var opts: Array = miniboss_lines(key, phase)
	var al := _alive()
	if al.is_empty():
		opts = opts.filter(func(l): return not String(l).contains("{name}"))
	if opts.is_empty():
		return ""
	var line := String(opts[_rng.randi() % opts.size()])
	if line.contains("{name}"):
		line = line.replace("{name}", String(al[_rng.randi() % al.size()]["h"]["name"]))
	return line

## a variant of a stock line (same format arguments), or the stock line
func _pick_line(key: String, stock: String) -> String:
	var opts: Array = lore().get(key, [])
	return String(opts[_rng.randi() % opts.size()]) if not opts.is_empty() else stock

## a delver says something short over their head (not the Chronicle) - at most
## one bark each eight seconds
func _bark(m: Dictionary, kind: String) -> void:
	if float(m.get("hp", 0.0)) <= 0.0 or float(m.get("bark_t", -99.0)) > _t:
		return
	var opts: Array = (lore().get("barks", {}) as Dictionary).get(kind, [])
	if opts.is_empty():
		return
	m["bark_t"] = _t + 8.0
	_say_bubble(m, "\"%s\"" % String(opts[_rng.randi() % opts.size()]))

func _bark_any(kind: String) -> void:
	var al := _alive()
	if not al.is_empty():
		_bark(al[_rng.randi() % al.size()], kind)

## a bark as a speech bubble - the same parchment plate as the crier's in town
## (UiTheme.style_bubble), over the delver's head for three seconds
func _say_bubble(m: Dictionary, text: String) -> void:
	var b: Node3D = m["body"]
	if not is_instance_valid(b) or not b.is_inside_tree() or dun == null:
		return
	var lb := Label3D.new()
	UiTheme.style_bubble(lb)
	lb.width = 360.0
	lb.text = text
	lb.top_level = true
	dun.info["root"].add_child(lb)
	lb.global_position = b.global_position + Vector3(0, 3.4, 0)
	UiTheme.fit_plate(lb)
	var tw := lb.create_tween()
	tw.tween_interval(3.0)
	tw.tween_callback(lb.queue_free)

## ---- S2: the fight's sounds (the RPG sound library, Sfx kinds). All positional (Sfx.at).
##   a delver's blow   the weapon's own sound on the swing (sword_swing / dagger_stab /
##                     bow_draw then arrow_shot), then on a hit sword_clash on bone and
##                     armour or hit_impact on flesh; a miss is the swing alone. A shield
##                     calling now and then puts its shield into it (shield_bash).
##   a creature's miss on a shield-bearer: block
##   voices            male_ / female_ (Roster.voice_of): hurt on a hit (sampled: not every
##                     blow; a delver's cries and efforts share one HURT_GAP s), effort on a big swing (a 20, or one
##                     in EFFORT_ODDS), death when they fall (the death sting already ducks
##                     the music)
##   spells            Spells.cast sounds every cast itself (S1: mana_charge + its SOUND) - S3
##                     found S2 layering a second copy here and took it out
##   below             a quiet bed (AMB_KINDS) somewhere off in the dark every AMB_MIN-AMB_MAX s
const HURT_GAP := 2.5
const EFFORT_ODDS := 8
const AMB_KINDS := ["bat_screech", "spider_skitter", "skeleton_rattle", "ghost_wail"]
const AMB_MIN := 9.0
const AMB_MAX := 22.0
const AMB_DB := -16.0
## S3 (measured): the spider and skeleton files are ~10 dB quieter than the bat and the ghost -
## at one level two of the four were 25 dB under the music, i.e. never heard. Trimmed so the
## whole bed sits quiet but present, 12-24 dB under the music.
const AMB_TRIM := {"spider_skitter": 8.0, "skeleton_rattle": 8.0}
const POTION_DB := 4.0
var _amb_t := 6.0
var sounds := {}                   # kind -> times this delve asked for it (tests read it)

func _snd(kind: String, at: Vector3, db := 0.0) -> void:
	if kind == "":
		return
	sounds[kind] = int(sounds.get(kind, 0)) + 1
	Sfx.at(kind, at, db)

func _vox(m: Dictionary, what: String, db := 0.0) -> void:
	var b = m.get("body")
	if is_instance_valid(b) and (b as Node3D).is_inside_tree():
		_snd("%s_%s" % [Roster.voice_of(m["h"]), what], (b as Node3D).global_position + Vector3(0, 1.6, 0), db)

## the swing: which sound a delver's weapon makes
func _swing_snd(h: Dictionary) -> String:
	if String(h.get("class", "")) == "ranger":
		return "bow_draw"
	if roster.weapon_name(h).to_lower().contains("dagger") or String(h.get("class", "")) in ["rogue", "duelist"]:
		return "dagger_stab"
	return "sword_swing"

func _blow_snd(m: Dictionary, tgt: Monster, landed: bool, crit: bool) -> void:
	var h: Dictionary = m["h"]
	var b: Node3D = m["body"]
	var at := b.global_position + Vector3(0, 1.2, 0)
	var sw := _swing_snd(h)
	_snd(sw, at)
	if sw == "bow_draw":
		var to := tgt.global_position + Vector3(0, tgt._height() * 0.6, 0)
		get_tree().create_timer(0.22).timeout.connect(func() -> void: Sfx.at("arrow_shot", at))
		if landed:
			get_tree().create_timer(0.45).timeout.connect(func() -> void: Sfx.at("hit_impact", to))
			sounds["arrow_shot"] = int(sounds.get("arrow_shot", 0)) + 1
	elif landed:
		var hard := String(tgt.def.get("family", "")) in ["undead", "the fallen"] or bool(tgt.def.get("boss", false))
		_snd("sword_clash" if hard else "hit_impact", tgt.global_position + Vector3(0, tgt._height() * 0.55, 0), 2.0 if crit else 0.0)
	if landed and _has_shield(h) and _rng.randi_range(1, 4) == 1:
		_snd("shield_bash", at, -2.0)
	if (crit or _rng.randi_range(1, EFFORT_ODDS) == 1) and _t - float(m.get("cry_t", -99.0)) >= HURT_GAP:
		m["cry_t"] = _t                 # one voice gap a delver, shared by cries and efforts
		_vox(m, "effort", -3.0)

func _has_shield(h: Dictionary) -> bool:
	return String((Roster.CLASSES.get(String(h.get("class", "")), {}) as Dictionary).get("offhand", "")).contains("shield")

## a hurt delver cries out now and then - never every blow
func _hurt_snd(m: Dictionary) -> void:
	if float(m["hp"]) <= 0.0 or _t - float(m.get("cry_t", -99.0)) < HURT_GAP:
		return
	if _rng.randi_range(1, 2) == 1 or float(m["hp"]) < float(m["max"]) * 0.3:
		m["cry_t"] = _t
		_vox(m, "hurt")

func _amb_tick(delta: float) -> void:
	if dun == null or not is_instance_valid(dun) or state == "home":
		return
	_amb_t -= delta
	if _amb_t > 0.0:
		return
	_amb_t = _rng.randf_range(AMB_MIN, AMB_MAX)
	var alive := _alive()
	if alive.is_empty():
		return
	var b: Node3D = alive[0]["body"]
	if not is_instance_valid(b):
		return
	var a := _rng.randf() * TAU
	var k := String(AMB_KINDS[_rng.randi() % AMB_KINDS.size()])
	_snd(k, b.global_position + Vector3(cos(a), 0.3, sin(a)) * _rng.randf_range(10.0, 18.0), AMB_DB + float(AMB_TRIM.get(k, 0.0)))

## L25c: the watchdog. A body that has not got closer to its goal for 2 s (held by a wall and a
## table at once) is set down in the middle of the nearest clear cell and routes afresh.
var unsticks := 0
var unstick_log: Array = []      # tests read it: where the watchdog fired
func _unstick(n: Node3D, goal := Vector2i(-9999, -9999)) -> void:
	var cells: Dictionary = dun.info["cells"]
	var blocked := _blocked_cells()
	var here := _cell_of(n.global_position)
	# L25c: set it down where its goal can be walked to (the nearest clear cell could be a pocket
	# walled in by furniture - it was set back in the same pocket again and again)
	var pat := _patches()
	# D88: with a portcullis down the goal's patch may lie beyond the bars - set the body down on
	# ITS OWN side (the patch nearest where it stands), never lifted across the gate
	if not (dun.info.get("hard", {}) as Dictionary).is_empty():
		goal = here
	var want := int(pat.get(goal, -1))
	if want < 0 and goal.x != -9999:
		var gd := 1e9
		for c: Vector2i in pat:
			var d0 := Vector2(c - goal).length()
			if d0 < gd:
				gd = d0
				want = int(pat[c])
	var best := Vector2i(-9999, -9999)
	var bd := 1e9
	for c: Vector2i in cells:
		if blocked.has(c) or (want >= 0 and int(pat.get(c, -1)) != want) or (c == here and _flat(n.global_position, _cell_world(c)) < 0.5):
			continue          # (not where it already stands - that was a loop)
		var d := Vector2(c - here).length()
		if d < bd:
			bd = d
			best = c
	if best.x == -9999:
		return
	var w := _cell_world(best)
	n.global_position = Vector3(w.x, n.global_position.y, w.z)
	_paths.erase(n)
	_prog.erase(n)
	unsticks += 1

## debug for the L25 test: what is round a body the watchdog had to free
func _why(n: Node3D, pts: Array) -> String:
	var o0 := dun.global_position
	var near: Array = []
	for o in dun.info.get("obstacles", []):
		var c: Vector3 = (o[0] as Vector3) + o0
		var d := _flat(c, n.global_position)
		if FloorGen.obst_gap(o, n.global_position.x - o0.x, n.global_position.z - o0.z) < 2.0:
			near.append("(%.1f,%.1f r%.2f d%.2f)" % [c.x, c.z, float(o[1]), d])
	var here := _cell_of(n.global_position)
	var nb := ""
	for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var c2: Vector2i = here + dd
		nb += ("#" if not (dun.info["cells"] as Dictionary).has(c2) else ("B" if _blocked_cells().has(c2) else "."))
	var wp := ""
	for i in range(mini(3, pts.size())):
		wp += str((pts[i] as Vector3).snappedf(0.1)) + " "
	return " cell %s%s nb(+x-x+z-z)=%s wps=%s obst=%s" % [here, (" B" if _blocked_cells().has(here) else ""), nb, wp, ", ".join(near)]
