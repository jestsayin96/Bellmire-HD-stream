extends SceneTree
## W-LIVE queue at the source (supervisor 14:58): a point-redeemed errand reaches town._on_delve
## directly. It must now land in chat.delve_queue ONCE, !muster must count it ONCE, and a later
## !delve from the same viewer must not add it twice. Headless. Prints D41Q_TEST OK/FAIL.
var _t: Node3D
var _f := 0
var _bad := 0
func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
func _ck(ok: bool, what: String) -> void:
	print("  ", "ok   " if ok else "FAIL ", what)
	if not ok:
		_bad += 1
func _process(_dt: float) -> bool:
	_f += 1
	if _f == 30:
		_t.call("chat_line", "3101", "PointsFan", "!enlist knight dwarf")
		_t.call("chat_line", "3102", "ChatFan", "!enlist mage elf")
	if _f == 60:
		var c: ChatCmd = _t.get("chat")
		var heroes: Dictionary = _t.get("heroes")
		_ck(heroes.has("3101") and heroes.has("3102"), "both heroes stand in town")
		# the errand path: what twitch_eventsub.gd calls for "Send my hero delving"
		_t.call("_on_delve", "3101")
		_ck(c.delve_queue.count("3101") == 1, "errand hero in delve_queue once (%s)" % str(c.delve_queue))
		var m: String = c._muster("3101")
		print("  muster: ", m)
		_ck(m.contains("(1)"), "!muster counts 1")
		# the chat path for another viewer, then the errand viewer types !delve as well
		c._last.clear()
		_t.call("chat_line", "3102", "ChatFan", "!delve")
		_ck(c.delve_queue.count("3102") == 1, "!delve hero in delve_queue once")
		c._last.clear()
		var r: String = c._delve("3101")
		print("  repeat !delve: ", r)
		_ck(c.delve_queue.count("3101") == 1, "errand hero still once after its own !delve")
		m = c._muster("3102")
		print("  muster: ", m)
		_ck(m.contains("(2)"), "!muster counts 2 - the union reads the same as the queue")
		_ck(c.delve_queue.size() == 2, "queue size 2")
		print("D41Q_TEST ", "OK" if _bad == 0 else "FAIL", " bad=", _bad)
		return true
	return false
