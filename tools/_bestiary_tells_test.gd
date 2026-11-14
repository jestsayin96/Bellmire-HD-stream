extends SceneTree
## L-cycle 149 - monster telegraphs. Supervisor wants bestiary depth: a BOSS
## about to swing something big should give the stream a one-line tell so the
## wind-up is visible, not just the hit. _boss_tell in delve.gd writes a
## templated line, rate-limited BOSS_TELL_EVERY seconds per monster, and only
## for monsters with def.boss == true - ordinary foes stay silent so the
## Chronicle is not drowned.
##
## What is measured:
##   A. a boss monster passed to _boss_tell writes the Chronicle line once,
##      increments Delve.bestiary_tells, sets the cooldown meta.
##   B. a second call INSIDE BOSS_TELL_EVERY writes NOTHING (cooldown).
##   C. the same call on a NON-boss monster writes NOTHING (ordinary foes
##      stay silent).
##   D. after BOSS_TELL_EVERY seconds the cooldown releases and the tell fires
##      again.
## Prints BESTIARY_TELLS_TEST OK / FAIL. Headless; FakeTown with feed[].

class FakeTown extends Node3D:
	var feed: Array = []
	var economy = null

var _d: Delve
var _fakes: FakeTown
var _r: Roster
var _fails: Array = []
var _checks := 0

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)
	_fakes = FakeTown.new()
	root.add_child(_fakes)
	_d = Delve.new()
	_d.roster = _r
	_d.town = _fakes
	_d.floor_no = 5
	root.add_child(_d)

	# a boss monster rig: just enough def for _boss_tell. Canon lord names in
	# Bestiary are "The Hollow King" / "Nightwing" etc - capitalised, no
	# leading "the" from the template.
	var mb := Monster.new()
	mb.def = {"name": "The Hollow King", "boss": true, "hp": 200.0, "atk": 10.0}
	root.add_child(mb)

	# a NON-boss for the negative check
	var ord := Monster.new()
	ord.def = {"name": "a ratkin", "boss": false, "hp": 10.0, "atk": 1.0}
	root.add_child(ord)

	# --- A: a boss tell writes the line and bumps the counter
	Delve.bestiary_tells = 0
	_fakes.feed.clear()
	_d._t = 100.0                 # any _t; we will offset by BOSS_TELL_EVERY below
	_d._boss_tell(mb, "%s draws breath - brace.")
	print("A: feed=%s bestiary_tells=%d" % [_fakes.feed, Delve.bestiary_tells])
	_ok(_fakes.feed.size() == 1, "A: exactly one line written (%d)" % _fakes.feed.size())
	_ok(String(_fakes.feed[0]).contains("Hollow King"),
		"A: the monster's name is in the line (%s)" % String(_fakes.feed[0]))
	_ok(Delve.bestiary_tells == 1, "A: Delve.bestiary_tells counted (%d)" % Delve.bestiary_tells)
	_ok(mb.has_meta("boss_tell_t"), "A: cooldown meta set on the monster")

	# --- B: inside the cooldown, a second call is silent
	_d._boss_tell(mb, "%s draws breath - brace.")
	_ok(_fakes.feed.size() == 1, "B: inside cooldown, no second line (%d)" % _fakes.feed.size())
	_ok(Delve.bestiary_tells == 1, "B: counter unchanged (%d)" % Delve.bestiary_tells)

	# --- C: non-boss monster never writes
	_d._boss_tell(ord, "%s draws breath - brace.")
	_ok(_fakes.feed.size() == 1, "C: non-boss writes nothing (feed size=%d)" % _fakes.feed.size())
	_ok(Delve.bestiary_tells == 1, "C: counter unchanged for non-boss (%d)" % Delve.bestiary_tells)

	# --- D: after BOSS_TELL_EVERY seconds the tell fires again
	_d._t = 100.0 + Delve.BOSS_TELL_EVERY + 0.1
	_d._boss_tell(mb, "%s draws breath - brace.")
	_ok(_fakes.feed.size() == 2, "D: past the cooldown, tell fires again (%d)" % _fakes.feed.size())
	_ok(Delve.bestiary_tells == 2, "D: counter incremented past cooldown (%d)" % Delve.bestiary_tells)

	print("")
	print("CHECKS ", _checks, " FAILS ", _fails.size())
	for fl in _fails:
		print("  - ", fl)
	print("BESTIARY_TELLS_TEST ", "OK" if _fails.is_empty() else "FAIL")

func _process(_dt: float) -> bool:
	return true
