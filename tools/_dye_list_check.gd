extends SceneTree
## C-71 recheck: an unknown !dye names a handful and the count, inside chat's 480.
func _initialize() -> void:
	var r := Roster.new()
	root.add_child(r)
	r.fresh("dyc1", "Tester", "knight")
	var s := r.dye("dyc1", "no-such-colour")
	print("DYE_REPLY (%d chars): %s" % [s.length(), s])
	print("DYE_LIST " + ("OK" if s.length() < 480 else "FAIL"))
	quit()
