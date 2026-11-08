extends SceneTree
var _f := 0
func _initialize() -> void:
    root.add_child((load("res://Town.tscn") as PackedScene).instantiate())
func _process(_d: float) -> bool:
    _f += 1
    if _f == 5:
        print("ALIVE animals=", root.get_child(root.get_child_count() - 1).get("animals").size())
    return _f >= 6
