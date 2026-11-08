extends SceneTree
## Roster save/load round trip (user://roster.json, the original's format).
func _initialize() -> void:
    var a := Roster.new()
    root.add_child(a)
    var h := a.fresh("2001", "SaveTest", "knight")
    h["gold"] = 123
    h["oil"] = 4
    a.fresh("2002", "DoomedTest", "mage")
    print("KILL ", a.kill("2002", "the dark below", 3, 0))
    a.save_all()
    var b := Roster.new()
    root.add_child(b)
    b.load_all()
    var hb := b.get_hero("2001")
    print("LOADED gold=", hb.get("gold"), " oil=", hb.get("oil"), " class=", hb.get("class"), " alive=", b.is_alive("2001"))
    print("FALLEN ", b.fallen.size(), " ", b.fallen[0].get("name") if b.fallen.size() > 0 else "-")
    quit()
