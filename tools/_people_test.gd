extends SceneTree
## Headless check: do townsfolk actually walk to doors and go in?
var _t: Node3D
var _f := 0
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _process(_d: float) -> bool:
    _f += 1
    if _f % 600 == 0:
        var inside := 0
        var walking := 0
        for v in _t.get("people"):
            if v.inside:
                inside += 1
            elif not v._route.is_empty():
                walking += 1
        print("T=", _f / 60, "s inside=", inside, " walking=", walking)
    return _f >= 4800
