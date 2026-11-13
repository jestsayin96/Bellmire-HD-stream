extends SceneTree
## U3 LOOK (L51): the Satchel. A kitted viewer's sheet in town, then the same
## viewer below with draughts and a venom running on them, then the 2x2 grid so
## the U1 caveat (is the Chronicle's 18 px line legible on stream?) can be judged
## from a 1:1 crop. WINDOWED - run with --resolution 1920x1080, no --headless.
## renders/cycles/20261113_u3.
var _t: Node3D
var _eye: RtsCamera
var _d: Delve
var _board: LeaderboardPanel
var _f := 0
var _phase := "warm"
var _mark := 0
const UID := "7001"
const OUT := "res://renders/cycles/20261113_u3"

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _save(tag: String) -> void:
    var img := root.get_texture().get_image()
    img.save_png(ProjectSettings.globalize_path(OUT + "/%s.png" % tag))
    print("SAVED ", tag, " window ", root.size)

## a 1:1 crop, so a font size can be judged instead of guessed
func _crop(tag: String, r: Rect2i) -> void:
    var img := root.get_texture().get_image()
    var box := Rect2i(Vector2i.ZERO, img.get_size()).intersection(r)
    if box.size.x <= 0 or box.size.y <= 0:
        print("CROP ", tag, " off screen ", r)
        return
    img.get_region(box).save_png(ProjectSettings.globalize_path(OUT + "/%s.png" % tag))
    print("CROP ", tag, " ", box)

func _kit() -> void:
    var r: Roster = _t.get("roster")
    var h: Dictionary = r.get_hero(UID)
    if h.is_empty():
        h = r.fresh(UID, "MireWren", "ranger", "elf")
    h["alive"] = true
    h["level"] = 6
    h["weapon"] = 3
    h["armour"] = 3
    h["gold"] = 640
    h["potions"] = 2
    h["oil"] = 3
    h["kills"] = 21
    h["deepest"] = 9
    h["brews"] = {"ogre": 1, "bravecup": 2, "quickwater": 1}
    h["acc"] = {"ring": "nightwatch_ring", "amulet": "hearth_amulet", "cloak": "guild_cloak",
        "boots": "road_boots", "gloves": "smith_gloves"}
    h["cos"] = {"hat": "wide_hat"}
    h["owned"] = ["nightwatch_ring", "hearth_amulet", "guild_cloak", "road_boots",
        "smith_gloves", "wide_hat", "scar_ring", "ward_pendant"]

func _sat():
    return _board.get("_satchel") if _board else null

func _show() -> void:
    var s = _sat()
    if s != null:
        s.uid = UID
        s.pin(true)                 # deliberate full-screen sheet - folds the grid

func _raise() -> void:
    var s = _sat()
    if s != null:
        s.raise_for(UID)

func _process(_dt: float) -> bool:
    _f += 1
    if _f == 20:
        _eye = RtsCamera.new()
        _t.add_child(_eye)
        _eye.setup(_t)
        # the shot builds its own Guild Roll - town's is behind a config gate
        _board = LeaderboardPanel.new()
        _t.add_child(_board)
        _board.setup(_t.get("roster"))
        _kit()
    if _f == 40:
        _show()                       # pin the sheet - it folds the 2x2 grid
    if _phase == "warm" and _f >= 120 and _board != null:
        var sat1 = _board.get("_satchel")
        print("U3 satchel vis ", sat1.visible, " split ", HudDock.split(_t), " pos ", sat1.global_position, " size ", sat1.size, " kids ", sat1._list.get_child_count())
        _save("1_satchel_town_1080")
        _crop("1_satchel_crop", Rect2i(1300, 270, 620, 760))
        # below now, with draughts and a venom running
        var r: Roster = _t.get("roster")
        var ids := [UID]
        for v in [["7002", "BellRinger", "cleric"], ["7003", "AshenPike", "knight"]]:
            var hh: Dictionary = r.get_hero(String(v[0]))
            if hh.is_empty():
                hh = r.fresh(String(v[0]), String(v[1]), String(v[2]))
            hh["weapon"] = 2
            hh["armour"] = 2
            ids.append(String(v[0]))
        _d = Delve.new()
        _d.town = _t
        _d.roster = r
        _d.start_floor = 3
        _d.max_floors = 3
        _t.add_child(_d)
        _d.start(ids)
        _phase = "below"
        _mark = _f
    elif _phase == "below" and _f - _mark >= 150:
        for m: Dictionary in _d.party:
            if String(m.get("uid", "")) == UID:
                m["st"] = {"haste": 23.0, "giant": 47.0, "frightened": 9.0}
                m["venom"] = 6.0
        var s2 = _sat()
        if s2 != null:
            s2._refresh()
        _phase = "states"
        _mark = _f
    elif _phase == "states" and _f - _mark >= 8:
        var s3 = _sat()
        if s3 != null:
            s3._refresh()
        _save("2_satchel_states_1080")
        _crop("2_satchel_states_crop", Rect2i(1300, 270, 620, 760))
        # the 2x2 grid, so the Chronicle's centre box can be judged at 1:1
        var s4 = _sat()
        if s4 != null:
            s4.pin(false)             # restore the grid the satchel folded
        var sp := HudDock.spot(_t)
        if sp:
            sp.put(UID, "bits", 90.0, "a viewer's hero")
            sp.put("7002", "subs", 90.0, "a subscriber")
            sp.put("7003", "points", 90.0, "channel points")
        var fd: Array = _t.get("feed")
        fd.append("A trade caravan is sighted on the west road.")
        fd.append("MireWren drinks Quickwater and the dark gives way.")
        fd.append("The watch lights the lamps along the ford.")
        _phase = "grid"
        _mark = _f
    elif _phase == "grid" and _f - _mark >= 180:
        _save("3_grid_chronicle_1080")
        var box := HudDock.centre(_t)
        _crop("3_chronicle_crop", Rect2i(int(box.position.x), int(box.position.y),
            int(box.size.x), int(box.size.y)))
        print("U3 chronicle box ", box, " CHRON_PX 18 at window ", root.size)
        print("U3_SHOT done")
        return true
    if _f > 2400:
        print("U3_SHOT timed out at phase ", _phase)
        return true
    return false
