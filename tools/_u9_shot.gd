extends SceneTree
## U9 LOOK (L51 finish): the Satchel's "nothing worn" hint. A BARE viewer - no
## accessories, no cosmetics - so the "No rings, no cloak, nothing on the hands.
## !wear ring" line renders (the pre-existing clip). WINDOWED 1920x1080, no --headless.
## renders/cycles/20261113_u9. Tag via env U9TAG (before|after).
var _t: Node3D
var _eye: RtsCamera
var _board: LeaderboardPanel
var _f := 0
var _done := false
const UID := "9001"
const OUT := "res://renders/cycles/20261113_u9"

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _tag() -> String:
    var t := OS.get_environment("U9TAG")
    return t if t != "" else "shot"

func _save(nm: String) -> void:
    var img := root.get_texture().get_image()
    img.save_png(ProjectSettings.globalize_path(OUT + "/%s.png" % nm))
    print("SAVED ", nm, " window ", root.size)

func _crop(nm: String, r: Rect2i) -> void:
    var img := root.get_texture().get_image()
    var box := Rect2i(Vector2i.ZERO, img.get_size()).intersection(r)
    if box.size.x <= 0 or box.size.y <= 0:
        print("CROP ", nm, " off screen ", r); return
    img.get_region(box).save_png(ProjectSettings.globalize_path(OUT + "/%s.png" % nm))
    print("CROP ", nm, " ", box)

func _kit_bare() -> void:
    var r: Roster = _t.get("roster")
    var h: Dictionary = r.get_hero(UID)
    if h.is_empty():
        h = r.fresh(UID, "Barefoot", "knight", "human")
    h["alive"] = true
    h["level"] = 2
    h["weapon"] = 1
    h["armour"] = 1
    h["gold"] = 35
    h["acc"] = {}
    h["cos"] = {}
    h["owned"] = []
    h["brews"] = {}
    h["oil"] = 0

func _sat():
    return _board.get("_satchel") if _board else null

func _process(_dt: float) -> bool:
    _f += 1
    if _f == 20:
        _eye = RtsCamera.new(); _t.add_child(_eye); _eye.setup(_t)
        _board = LeaderboardPanel.new(); _t.add_child(_board); _board.setup(_t.get("roster"))
        _kit_bare()
    if _f == 40:
        var s = _sat()
        if s != null:
            s.uid = UID; s.pin(true)
    if _f == 150 and not _done:
        _done = true
        var s = _sat()
        print("U9 satchel vis ", s.visible, " pos ", s.global_position, " size ", s.size, " kids ", s._list.get_child_count())
        var tag := _tag()
        _save("satchel_%s_1080" % tag)
        _crop("satchel_%s_crop" % tag, Rect2i(1290, 50, 630, 1000))
        print("U9_SHOT done ", tag)
        return true
    if _f > 1500:
        print("U9_SHOT timed out"); return true
    return false
