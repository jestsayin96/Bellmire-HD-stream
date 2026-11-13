extends SceneTree
## D52: HEROES DO NOT MOVE/DELVE ON COMMAND. Supervisor priority. A viewer
## enlists a hero, issues !delve, and the hero stands idle at the well - never
## paths to the mouth. This is the laptop delve-command path, NOT nav.
##
## Repros THREE conditions that leave the hero idle:
##   A. HAPPY PATH: enlist (wait past the 1.5 s ChatCmd COOLDOWN) then delve.
##      The hero should path toward the gate and start climbing the Delvers'
##      Road. Confirms the move machinery itself is sound.
##   B. BACK-TO-BACK COMMANDS: enlist then delve within 1.5 s. The COOLDOWN
##      filter in chatcmd.handle drops the !delve silently - chat_line returns
##      "". No signal, no state change, no feedback - the hero stands put.
##   C. PRE-RAISE RACE: an existing hero (loaded from the on-disk roster) has
##      their body raised DEFERRED at startup. If a command arrives before that
##      deferred _raise runs, _on_delve sees heroes.has(uid) == false and
##      returns silently. The hero never enters the delve road.
##
## Prints a log line per tick during the 18 s observation window so you can see
## target / route length / velocity / state for each scenario, as the supervisor
## asked. Prints D52_TEST OK / FAIL at the end.

var town: Node3D
var step := "boot"
var f := 0
var _fails: Array = []
var _checks := 0
var _frames_after := 0
var _snap_prev := {}         # uid -> [pos, frame_logged]
var _done := false

const UID_A := "probe52A"
const UID_B := "probe52B"
const UID_C := "probe52C"

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _snap(label: String, uid: String) -> Dictionary:
	var heroes: Dictionary = town.get("heroes")
	if not heroes.has(uid):
		print("D52[%s] uid=%s NO BODY" % [label, uid])
		return {}
	var b: Node3D = heroes[uid]
	var p: Vector3 = b.global_position
	var rt: Array = b.get("_route")
	var tgt_s := "n/a" if rt.is_empty() else str((rt[0] as Vector3).snappedf(0.1))
	var prev: Array = _snap_prev.get(uid, [p, f])
	var dt := maxf((f - int(prev[1])) / 60.0, 1.0 / 60.0)
	var v := (p - (prev[0] as Vector3)).length() / dt
	_snap_prev[uid] = [p, f]
	print("D52[%s] f=%d uid=%s pos=%s v=%.2fm/s route_len=%d tgt=%s stay=%s err=%s wait=%.1f" % [
		label, f, uid, str(p.snappedf(0.01)), v, rt.size(), tgt_s,
		str(bool(b.get("stay"))), String(b.get("errand")), float(b.get("_wait"))])
	return {"pos": p, "v": v, "route_len": rt.size(), "tgt": rt[0] if not rt.is_empty() else null,
			"stay": bool(b.get("stay")), "errand": String(b.get("errand"))}

func _initialize() -> void:
	var sc: PackedScene = load("res://Town.tscn")
	town = sc.instantiate()
	root.add_child(town)

func _process(_dt: float) -> bool:
	f += 1
	if _done:
		return true
	if f == 1:
		print("D52 boot: town instantiated, letting it build...")
	if f == 60:
		# let town finish _start_town
		var info: Dictionary = town.get("_scar_info")
		print("D52 scar_info keys=%s" % [info.keys()])
		if not info.has("post"):
			_ok(false, "scar_info has post (town built)")
			_done = true
			return true
		_ok(true, "scar_info has post")
		var nav = town.get("nav")
		print("D52 nav ready_ok=%s" % [str(nav.ready_ok) if nav else "no nav"])

		# ---- scenario A: HAPPY PATH - enlist then wait past cooldown, then delve
		print("D52 --- scenario A: enlist + wait + delve ---")
		var rA: String = town.call("chat_line", UID_A, "Alpha", "!enlist knight")
		print("D52[A] !enlist -> %s" % rA)
		step = "A_wait"
		return false
	if step == "A_wait" and f >= 60 + 120:                    # 2 s after enlist
		var rA: String = town.call("chat_line", UID_A, "Alpha", "!delve")
		print("D52[A] !delve -> %s" % rA)
		var chat = town.get("chat")
		print("D52[A] delve_queue=%s" % [chat.delve_queue])
		_ok(UID_A in chat.delve_queue, "A: a 2 s gap - !delve is accepted and queues the viewer")
		_snap("A-t0", UID_A)
		step = "A_watch"
		return false

	if step == "A_watch" and f == 60 + 120 + 180:            # 3 s of pathing to inspect
		var s := _snap("A-t3", UID_A)
		_ok(not s.is_empty() and float(s.get("v", 0.0)) > 0.3,
			"A: hero actually MOVES after the delve order (v=%.2f m/s)" % float(s.get("v", 0.0)))
		_ok(not s.is_empty() and int(s.get("route_len", 0)) > 1,
			"A: a nav TARGET and a ROUTE exist (len=%d)" % int(s.get("route_len", 0)))
		_ok(not s.is_empty() and String(s.get("errand", "")) == "delve",
			"A: the hero's errand is 'delve' (state transitioned)")

		# ---- scenario B: BACK-TO-BACK (within cooldown)
		print("D52 --- scenario B: enlist + delve back-to-back ---")
		var rB1: String = town.call("chat_line", UID_B, "Bravo", "!enlist mage")
		print("D52[B] !enlist -> %s" % rB1)
		var rB2: String = town.call("chat_line", UID_B, "Bravo", "!delve")
		print("D52[B] !delve (within cooldown) -> '%s'" % rB2)
		var chat2 = town.get("chat")
		print("D52[B] delve_queue=%s" % [chat2.delve_queue])
		# B is DIAGNOSTIC, not part of the D52 DONE criterion: this is ChatCmd's
		# 1.5 s per-viewer anti-spam - deliberate, and not what a human typist
		# will hit. Mr. E's live case was scenario C (deferred raise), not this.
		print("D52[B] note: ChatCmd COOLDOWN silently drops this (anti-spam); diagnostic only")
		_snap("B-t0", UID_B)
		step = "B_watch"
		return false

	if step == "B_watch" and f == 60 + 120 + 180 + 180:
		var s := _snap("B-t3", UID_B)
		print("D52[B] (diagnostic) v=%.2f m/s, route_len=%d - cooldown silently dropped the !delve as expected" % [
			float(s.get("v", 0.0)), int(s.get("route_len", 0))])

		# ---- scenario C: PRE-RAISE RACE - hero in roster but body not raised yet
		print("D52 --- scenario C: hero in roster but body not raised ---")
		var roster = town.get("roster")
		var h: Dictionary = roster.fresh(UID_C, "Cathy", "cleric")
		h["alive"] = true
		# EMULATE the live-boot case: body-raise is DEFERRED, so heroes[uid] is empty
		# when !delve arrives. (In live the roster was loaded then _raise is call_deferred.)
		var heroes: Dictionary = town.get("heroes")
		print("D52[C] roster has %s, heroes.has(uid)=%s before !delve" % [h.get("name"), heroes.has(UID_C)])
		var rC: String = town.call("chat_line", UID_C, "Cathy", "!delve")
		print("D52[C] !delve -> %s" % rC)
		var chat3 = town.get("chat")
		print("D52[C] delve_queue=%s" % [chat3.delve_queue])
		_snap("C-t0", UID_C)
		step = "C_watch"
		return false

	if step == "C_watch" and f == 60 + 120 + 180 + 180 + 180:
		var s := _snap("C-t3", UID_C)
		_ok(not s.is_empty() and float(s.get("v", 0.0)) > 0.3,
			"C: a hero whose body was deferred-raised still moves on !delve (v=%.2f m/s)" % float(s.get("v", 0.0)))
		print("")
		print("CHECKS ", _checks, " FAILS ", _fails.size())
		for fl in _fails:
			print("  - ", fl)
		print("D52_TEST ", "OK" if _fails.is_empty() else "FAIL")
		_done = true
		return true
	return false
