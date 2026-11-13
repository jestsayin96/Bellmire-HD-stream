extends SceneTree
## L46: "TRAPS DO NO DAMAGE" (Mr. E believes spikes and traps are inert; L11 claims working
## traps). The plan says VERIFY FIRST, so this measures before it judges.
##   A. VERIFY - run real delves over several floors and report Delve.trap_log (spotted /
##      disarmed / sprung / saved / damage) together with HOW CLOSE a delver ever got to each
##      trap. That separates "the damage code is broken" from "the trap never fires at all".
##   B. THE DAMAGE PATH - force a trap on a hero and require real hp loss, a floating number
##      and a Chronicle line (the three things the plan asks for).
##   C. A DELVER CAN DIE TO A TRAP - the plan's own DONE wording, scripted rather than hoped for.
## Headless: delve arithmetic, not HUD. Prints L46_TEST OK / FAIL.
var _r: Roster
var _d: Delve
var _f := 0
var _fails: Array = []
var _checks := 0
var _part := "A"
var _near := {}                  # trap node -> closest any delver ever came (m)
var _tot := {"spotted": 0, "disarmed": 0, "sprung": 0, "saved": 0, "damage": 0.0}
var _seen_floors := {}
var _feed_traps := 0

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _new_delve(floors: int) -> void:
	_d = Delve.new()
	_d.roster = _r
	_d.max_floors = floors
	root.add_child(_d)
	var ids: Array = []
	var V := [["4601", "Ashvein", "knight"], ["4602", "Brelda", "mage"],
			  ["4603", "Corrin", "cleric"], ["4604", "Dunmar", "barbarian"]]
	for v in V:
		var h: Dictionary = _r.fresh(v[0], v[1], v[2])
		h["weapon"] = 2
		h["armour"] = 2
		h["oil"] = 9
		ids.append(v[0])
	_d.start(ids)

func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)
	_new_delve(8)

func _soak_tick() -> void:
	if _d.dun == null or not _d.dun.info.has("traps"):
		return
	_seen_floors[_d.floor_no] = true
	for t in _d.dun.info["traps"]:
		var tr: Dictionary = t
		if not is_instance_valid(tr["node"]):
			continue
		var tp: Vector3 = (tr["node"] as Node3D).global_position
		var key := (tr["node"] as Node3D).get_instance_id()
		for m in _d._alive():
			var b = m["body"]
			if not is_instance_valid(b):
				continue
			var d: float = Vector2((b as Node3D).global_position.x - tp.x,
								   (b as Node3D).global_position.z - tp.z).length()
			if not _near.has(key) or d < float(_near[key]):
				_near[key] = d

func _bank() -> void:
	for k in _tot:
		_tot[k] += _d.trap_log.get(k, 0)

func _process(_dt: float) -> bool:
	_f += 1
	match _part:
		"A":
			_soak_tick()
			if _d.state == "home" or _f > 60 * 240:
				_bank()
				# how near did anyone ACTUALLY get? TRAP_REACH is the trigger radius.
				var within := 0
				var closest := 9999.0
				var dists: Array = []
				for k in _near:
					var d := float(_near[k])
					dists.append(snappedf(d, 0.1))
					closest = minf(closest, d)
					if d <= Delve.TRAP_REACH:
						within += 1
				dists.sort()
				print("L46 VERIFY: floors seen %s, traps tracked %d" % [str(_seen_floors.keys()), _near.size()])
				print("   trap_log totals: ", _tot)
				print("   TRAP_REACH = %.2f m; traps a delver came within reach of: %d of %d" % [Delve.TRAP_REACH, within, _near.size()])
				print("   closest approach per trap (m, sorted): ", dists.slice(0, 20))
				print("   closest of all: %.2f m" % closest)
				_ok(_near.size() > 0, "A: traps are actually placed on the floors (%d)" % _near.size())
				_ok(int(_tot["sprung"]) > 0,
					"A: at least one trap SPRANG over a multi-floor delve (%d sprung, %d spotted, %d disarmed)"
					% [int(_tot["sprung"]), int(_tot["spotted"]), int(_tot["disarmed"])])
				_ok(float(_tot["damage"]) > 0.0, "A: sprung traps applied real hp loss (%.1f total)" % float(_tot["damage"]))
				# L46's real defect: traps sat where nobody walked. Laying them on keep_clear (the
				# way through) must put most of them in the party's path, not in a far corner.
				_ok(float(within) / maxf(1.0, float(_near.size())) >= 0.5,
					"A: most traps are laid where the party actually walks - %d of %d met within %.2f m"
					% [within, _near.size(), Delve.TRAP_REACH])
				_ok(int(_tot["spotted"]) + int(_tot["sprung"]) >= 2,
					"A: traps are MET often enough to read on stream (%d met over %s floors)"
					% [int(_tot["spotted"]) + int(_tot["sprung"]), str(_seen_floors.size())])
				_drop()
				_part = "B"
				_f = 0
				_new_delve(3)
			return false
		"B":
			# ---- the damage path, forced so it cannot be missed by luck
			if _d.state == "fight" and _d.dun != null and _d._alive().size() > 0 and _d.dun.info.has("traps") \
					and not (_d.dun.info["traps"] as Array).is_empty():
				var m: Dictionary = _d._alive()[0]
				var before := float(m["hp"])
				var feed_before := 0
				var tr: Dictionary = (_d.dun.info["traps"] as Array)[0]
				var spec: Dictionary = Delve.TRAPS.get(String(tr.get("kind", "SpikeTrap")), Delve.TRAPS["SpikeTrap"])
				_d._spring(m, tr, spec, _d.trap_dc())
				var after := float(m["hp"])
				print("L46 damage path: %s %0.1f -> %0.1f hp, trap_log %s" % [m["h"]["name"], before, after, str(_d.trap_log)])
				_ok(after < before, "B: springing a trap takes real hp (%.1f -> %.1f)" % [before, after])
				_ok(float(_d.trap_log["damage"]) > 0.0, "B: the damage is recorded in trap_log (%.1f)" % float(_d.trap_log["damage"]))
				# L46: a sprung trap can never take NOTHING - a good save used to floor 2d6 to 0,
				# and a fire grate against a resistant delver multiplied to 0. Spring a batch and
				# require every single one to land at least a point.
				var zeroes := 0
				var tries := 0
				for t2 in (_d.dun.info["traps"] as Array):
					for who in _d._alive():
						tries += 1
						var h0 := float(who["hp"])
						var sp2: Dictionary = Delve.TRAPS.get(String((t2 as Dictionary).get("kind", "SpikeTrap")), Delve.TRAPS["SpikeTrap"])
						_d._spring(who, t2, sp2, _d.trap_dc())
						if float(who["hp"]) >= h0:
							zeroes += 1
						who["hp"] = h0                      # put them back; this is a probe
				_ok(zeroes == 0, "B: no sprung trap took ZERO hp over %d springs (%d did nothing)" % [tries, zeroes])
				_drop()
				_part = "C"
				_f = 0
				_new_delve(3)
			elif _f > 60 * 120:
				_ok(false, "B: never reached a floor with a trap to force")
				_drop()
				_part = "C"
				_f = 0
				_new_delve(3)
			return false
		"C":
			# ---- a delver CAN die to a trap (the plan's DONE wording)
			if _d.state == "fight" and _d.dun != null and _d._alive().size() > 0 and _d.dun.info.has("traps") \
					and not (_d.dun.info["traps"] as Array).is_empty():
				var m: Dictionary = _d._alive()[0]
				var tr: Dictionary = (_d.dun.info["traps"] as Array)[0]
				var spec: Dictionary = Delve.TRAPS.get(String(tr.get("kind", "SpikeTrap")), Delve.TRAPS["SpikeTrap"])

				# FIRST: at 1 hp with the death save still in hand. Canon (the old rule, in
				# _hero_hit) gives ONE death save a delve - a DC 10 CON save claws them back to
				# 1 hp. So a trap that takes them under is SUPPOSED to leave them standing here.
				# An earlier draft of this test called that a failure; it is the rule working.
				m["hp"] = 1.0
				m["saved"] = false
				_d._spring(m, tr, spec, _d.trap_dc())
				var after_save := float(m["hp"])
				print("L46 lethality 1/2 (death save in hand): %s left on %.1f, saved=%s"
					% [m["h"]["name"], after_save, str(m["saved"])])
				_ok(bool(m["saved"]), "C: a lethal trap BURNS the one death save a delve (canon)")

				# SECOND: the save is spent, so the next trap must actually kill.
				m["hp"] = 1.0
				var dmg_before := float(_d.trap_log["damage"])
				_d._spring(m, tr, spec, _d.trap_dc())
				print("L46 lethality 2/2 (save spent): %s left on %.1f hp; this spring took %.1f"
					% [m["h"]["name"], float(m["hp"]), float(_d.trap_log["damage"]) - dmg_before])
				_ok(float(m["hp"]) <= 0.0,
					"C: with the death save spent, a delver on 1 hp DIES to a trap (left on %.1f)" % float(m["hp"]))
				_part = "END"
			elif _f > 60 * 120:
				_ok(false, "C: never reached a floor with a trap to test lethality")
				_part = "END"
			return false
		"END":
			print("CHECKS ", _checks, " FAILS ", _fails.size())
			for f in _fails:
				print("  - ", f)
			print("L46_TEST ", "OK" if _fails.is_empty() else "FAIL")
			return true
	return false

func _drop() -> void:
	if _d != null and is_instance_valid(_d):
		_d.queue_free()
