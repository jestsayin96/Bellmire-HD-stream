extends SceneTree
## B11. Two questions the supervisor set, both answered by measurement rather than reading.
##
## 1) DOES !delve NEED A GUARD AGAINST `away`? YES, and this gate is why. B9 refused to guess
##    because a wrong guard locks viewers out of !delve on stream. `away` has exactly three
##    writers, all in the delve lifecycle, and one eraser beside the queue's own - so a hero
##    with an away-state is on a delve and nothing else. On `main` _on_delve sets away and
##    queues NOTHING, so without the guard a point-redeemed errand hero can !delve into a
##    second slot. The guard is checked here in both the queued and the away-only shape.
##
## 2) IS THE !muster UNION READ REDUNDANT? YES, AND IT IS OUT (B12). D41's source-queueing
##    reached main at 16:58, this gate read B11_SOURCE_QUEUEING YES, and the union came out
##    the same run. The gate now holds the drop to its terms: the queue is the ONLY source of
##    membership (a name that exists only in `away` must NOT appear), the count must not move,
##    and a hero already below must still drop out - which she does not do by herself, because
##    the town erases the queue when the DELVE ENDS, not when the party goes down.
## Headless. Prints B11_MUSTER OK/FAIL.
var _t: Node3D
var _f := 0
var _bad := 0
func _ck(ok: bool, what: String) -> void:
	print("  ", "ok   " if ok else "FAIL ", what)
	if not ok:
		_bad += 1
func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
func _process(_dt: float) -> bool:
	_f += 1
	if _f == 30:
		_t.call("chat_line", "5101", "ErrandFan", "!enlist knight dwarf")
		_t.call("chat_line", "5102", "ChatFan", "!enlist mage elf")
		_t.call("chat_line", "5103", "IdleFan", "!enlist rogue human")
		return false
	if _f != 60:
		return false

	var c: ChatCmd = _t.get("chat")
	var heroes: Dictionary = _t.get("heroes")
	_ck(heroes.has("5101") and heroes.has("5102") and heroes.has("5103"), "three heroes stand in town")

	var m0: String = c._muster("5103")
	_ck(m0.contains("Nobody at the dungeon mouth"), "empty muster reads empty")

	# ---- the errand path: a point redemption reaches town._on_delve, never !delve ----
	_t.call("_on_delve", "5101")
	var queued_at_source: bool = c.delve_queue.has("5101")
	print("B11_SOURCE_QUEUEING ", "YES" if queued_at_source else "NO")
	_ck(c.away.has("5101"), "the town wrote an away-state for the errand hero")

	# whichever branch we are on, the muster must SEE her - that is the viewer-facing promise
	var m1: String = c._muster("5101")
	print("  muster: ", m1)
	_ck(m1.contains("(1)"), "!muster counts the errand hero (1)")
	_ck(m1.contains("first in line"), "and tells her her place")
	# THE DROP RESTS ON THIS AND NOTHING ELSE. If D41 ever leaves this branch the muster goes
	# blind to every errand, so the premise is an assertion now, not a printed note.
	_ck(queued_at_source, "D41 queues the errand at the SOURCE - the union has nothing left to add")
	# the union is OUT: a name that lives only in `away` must not reach the muster
	c.away["5199"] = "waiting at the mouth of the scar"
	var mu: String = c._muster("5103")
	print("  muster (away-only name present): ", mu)
	_ck(mu.contains("(1)"), "count unmoved - no name enters the muster from away")
	c.away.erase("5199")

	# ---- the chat path for a second viewer, and the ORDER chat put the names in ----
	c._last.clear()
	_t.call("chat_line", "5102", "ChatFan", "!delve")
	_ck(c.delve_queue.count("5102") == 1, "!delve hero queued once")
	var m2: String = c._muster("5102")
	print("  muster: ", m2)
	_ck(m2.contains("(2)"), "!muster counts 2 - both paths in one list")
	# SUPERVISOR RULING 2026-11-16 18:58 CT. The union-era line asserted the reverse of what the
	# muster now does. B12 made delve_queue the ONE source, read in the order things happened:
	# the errand (5101) is queued at the source FIRST, the !delve (5102) arrives SECOND. The old
	# line demanded chat-first because the muster used to be two lists glued together, and it
	# would have the muster tell a viewer who was first in the queue that she is second.
	# THE CODE WAS RIGHT AND THE GATE WAS STALE. The assertion is now the queue's own order.
	_ck(m2.find("ErrandFan") < m2.find("ChatFan"), "the muster prints in delve_queue order - the errand queued first")

	# a bystander gets the invitation, not a place, and does not inflate the count
	var m3: String = c._muster("5103")
	_ck(m3.contains("!delve to go with them") and m3.contains("(2)"), "bystander invited, not counted")

	# ---- THE GUARD. an errand hero on the road types !delve ----
	c._last.clear()
	var r1: String = c._delve("5101")
	print("  !delve (on the road): ", r1)
	_ck(c.delve_queue.count("5101") <= 1, "the guard refused her a second slot")
	_ck(not r1.contains("sets out"), "she is not sent out twice")
	_ck(r1.contains("on the road to the scar"), "she is told where she actually is")

	# the state the old line lied about: already below
	c.away["5101"] = "below, in the scar"
	c._last.clear()
	var r2: String = c._delve("5101")
	print("  !delve (below): ", r2)
	_ck(not r2.contains("sets out"), "a hero below cannot re-enter the queue")
	_ck(r2.contains("below, in the scar"), "a hero below is told she is below")
	_ck(not r2.contains("waiting at the dungeon mouth"), "she is NOT told she waits at the mouth")
	# and she drops out of the muster the moment she is below - by the exclusion, which is the
	# one thing `away` is still read for. Her name is STILL in the queue while she is down.
	var m4: String = c._muster("5102")
	print("  muster (one below): ", m4)
	_ck(c.delve_queue.has("5101"), "the queue still holds her below - it clears at delve END, not descent")
	_ck(not m4.contains("ErrandFan"), "a hero below is not at the mouth any more")
	_ck(m4.contains("(1)"), "and she is not counted while she is down")

	# ---- the guard costs a free hero NOTHING: no away-state, no queue entry ----
	c._last.clear()
	var r3: String = c._delve("5103")
	print("  !delve (free hero): ", r3)
	_ck(r3.contains("sets out"), "a hero with no away-state still descends - the guard locks nobody out")
	_ck(c.delve_queue.has("5103"), "and her name goes in")

	print("B11_MUSTER ", "OK" if _bad == 0 else "FAIL", " bad=", _bad)
	return true
