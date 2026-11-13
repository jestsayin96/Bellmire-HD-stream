extends SceneTree
## L29a: LORD MECHANICS - "each canon lord gets a real mechanic (adds/phase/hazard/enrage);
## boss_bar shows phase; per-phase trappings."
## MEASURED BEFORE BUILDING, as every item this session has needed: all EIGHT canon lords already
## carried a real mechanic in Bestiary.LORD_WAYS, so that half was already true and no new
## mechanic was invented on top of working canon. What did not exist was a PHASE - only three of
## the eight had any threshold that changed behaviour, and nothing exposed a phase for a bar to
## read. That is what was added, and this checks it.
##   A. EVERY canon lord still has a real mechanic (the half that was already true - guarded so
##      it cannot quietly regress).
##   B. EVERY lord now has phases, an ordinary creature does not, and the thresholds are sane.
##   C. PHASES ADVANCE as a lord is worn down, one step at a time, and never go backwards.
##   D. THE TRAPPING IS REAL: crossing a phase visibly changes the lord (its aura) and emits the
##      signal a bar or the Chronicle can listen to.
## Headless: this is bestiary/monster state, assertable exactly. Prints L29A_TEST OK / FAIL.
var _fails: Array = []
var _checks := 0

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _lord(key: String) -> Monster:
	var b: Dictionary = (Bestiary.BOSS_DEFS[key] as Dictionary).duplicate()
	b["id"] = key
	var m := Monster.new()
	m.def = Bestiary.boss_def(b, 10)
	get_root().add_child(m)
	return m

var _f := 0

func _process(_dt: float) -> bool:
	_f += 1
	if _f < 20:
		return false
	_run()
	return true

## L29a: the work runs in _process, NOT _initialize. A node added during _initialize never
## enters the tree, so _ready never fires and a lord would report phase_count 1 - which looked
## exactly like a product bug until I checked is_inside_tree() and found the harness at fault.
func _run() -> void:
	var lords: Array = Bestiary.BOSS_DEFS.keys()
	lords.sort()

	# ---- A. the half that was already true, now guarded
	var no_mech: Array = []
	for k in lords:
		if (Bestiary.LORD_WAYS.get(String(k), {}) as Dictionary).is_empty():
			no_mech.append(String(k))
	print("L29a: %d canon lords, %d without a mechanic" % [lords.size(), no_mech.size()])
	_ok(no_mech.is_empty(), "A: every canon lord has a real mechanic (missing: %s)" % str(no_mech))

	# ---- B. phases exist, and only for lords
	var no_phase: Array = []
	for k in lords:
		var m := _lord(String(k))
		if m.phase_count < 2:
			no_phase.append(String(k))
		if m.phase != 1:
			no_phase.append("%s(starts at %d)" % [k, m.phase])
		m.free()
	_ok(no_phase.is_empty(), "B: every lord has phases and starts in phase 1 (bad: %s)" % str(no_phase))

	var grunt := Monster.new()
	grunt.def = Bestiary.make("bones", "plain")
	get_root().add_child(grunt)
	_ok(grunt.phase_count == 1, "B: an ordinary creature has NO phases (count %d)" % grunt.phase_count)
	grunt.free()

	_ok(Monster.PHASE_AT.size() == 2 and float(Monster.PHASE_AT[0]) > float(Monster.PHASE_AT[1]),
		"B: the thresholds descend (%s)" % str(Monster.PHASE_AT))
	_ok(Monster.phase_for(1.0) == 1 and Monster.phase_for(0.5) == 2 and Monster.phase_for(0.1) == 3,
		"B: health maps to the right phase (1.0->1, 0.5->2, 0.1->3)")

	# ---- C. phases advance as it is worn down, one step at a time, never backwards
	var lord := _lord("hollow_king")
	var seen: Array = [lord.phase]
	var fired: Array = []
	lord.phase_changed.connect(func(_w, to): fired.append(to))
	var back := false
	var jumped := false
	var last := lord.phase
	for i in 40:
		lord.hurt(lord.max_hp * 0.03)
		if lord.state == Monster.S.DEAD:
			break
		if lord.phase < last:
			back = true
		if lord.phase > last + 1:
			jumped = true
		if lord.phase != last:
			seen.append(lord.phase)
		last = lord.phase
	print("L29a: phases seen while wearing it down: %s; signal fired for %s" % [str(seen), str(fired)])
	_ok(seen.size() >= 3, "C: the lord passed through every phase (%s)" % str(seen))
	_ok(not back, "C: a phase NEVER goes backwards, even as hp moves")
	_ok(not jumped, "C: phases advance one step at a time, never skipping")
	_ok(fired.size() == seen.size() - 1, "C: the signal fired once per change (%d for %d)" % [fired.size(), seen.size() - 1])

	# ---- D. the trapping is real: the aura actually changed
	var l2 := _lord("gravewyrm")
	var aura := l2.get_node_or_null("aura")
	var before := 0.0
	var am: StandardMaterial3D = null
	for c in l2.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).material_override is StandardMaterial3D:
			var mm := (c as MeshInstance3D).material_override as StandardMaterial3D
			if mm.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED and mm.albedo_color.a < 0.9:
				am = mm
				before = mm.albedo_color.a
				break
	l2.hurt(l2.max_hp * 0.5)        # into phase 2
	var after := am.albedo_color.a if am != null else -1.0
	print("L29a: aura alpha %.2f -> %.2f at phase %d" % [before, after, l2.phase])
	_ok(am != null, "D: the lord has an aura to change")
	_ok(after > before, "D: crossing a phase VISIBLY changes the lord (aura %.2f -> %.2f)" % [before, after])
	l2.free()
	lord.free()

	print("CHECKS ", _checks, " FAILS ", _fails.size())
	for x in _fails:
		print("  - ", x)
	print("L29A_TEST ", "OK" if _fails.is_empty() else "FAIL")
	quit()
