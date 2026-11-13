extends SceneTree
## L61 LOOK: the Chronicle as an UNFURLED SCROLL, on the 2x2 grid (the stream's resting
## state). Bring the grid up, fill the feed, let the calm pacing reveal the lines, then
## save a 1080p frame and a 1:1 crop of HudDock.centre (+20 px bleed) so the scroll - its
## spindles, finials, illuminated margin and burned wordmark - can be judged, with a lord's
## card up and again clean. WINDOWED: run with --resolution 1920x1080 and NO --headless.
## renders/cycles/20261113_l61.
var _t: Node3D
var _eye
var _f := 0
var _phase := "warm"
var _mark := 0
var _done := false
const OUT := "res://renders/cycles/20261113_l61"
const LINES := [
    "A trade caravan is sighted on the west road.",
    "MireWren drinks Quickwater and the dark gives way.",
    "The watch lights the lamps along the ford.",
    "BigAxe rolls a 20 and cleaves the mire-troll!",
    "The smith's hammer rings on past midnight.",
    "A new subscriber pledges to the Court of Bellmire.",
    "Thornwake steps on a darting trap - 7 damage.",
    "The town crier reads the day's news in the square.",
    "A rare lord stirs beneath the scar.",
]

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

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

func _feed_hud():
    for c in _t.get_children():
        if c is FeedHUD:
            return c
    return null

func _process(_dt: float) -> bool:
    _f += 1
    if _f == 20:
        _eye = RtsCamera.new(); _t.add_child(_eye); _eye.setup(_t)
    if _f == 45:
        var r: Roster = _t.get("roster")
        for v in [["6001","MireWren","ranger","elf"],["6002","BellRinger","cleric","human"],["6003","AshenPike","knight","human"]]:
            var hh: Dictionary = r.get_hero(String(v[0]))
            if hh.is_empty():
                hh = r.fresh(String(v[0]), String(v[1]), String(v[2]), String(v[3]))
            hh["alive"] = true
        var sp := HudDock.spot(_t)
        if sp:
            sp.put("6001", "bits", 90.0, "a viewer's hero")
            sp.put("6002", "subs", 90.0, "a subscriber")
            sp.put("6003", "points", 90.0, "channel points")
        var fd: Array = _t.get("feed")
        for ln in LINES:
            fd.append(ln)
        FeedHUD.card_on(_t, "Grimwarden the Hollow", "a rare lord stirs beneath the scar", Color(0.60, 0.32, 0.70))
        _phase = "fill"; _mark = _f
    elif _phase == "fill" and _f - _mark >= 780:    # ~13 s: the calm pacing reveals all lines
        var box := HudDock.centre(_t)
        print("L61 split ", HudDock.split(_t), " chronicle box ", box, " window ", root.size)
        _save("1_grid_scroll_card_1080")
        _crop("2_scroll_card_crop", Rect2i(int(box.position.x) - 20, int(box.position.y) - 20, int(box.size.x) + 40, int(box.size.y) + 40))
        var fh = _feed_hud()      # force the lord card off for a clean read of the scroll
        if fh and fh._card != null:
            fh._card_t = 0.0
            fh._card.visible = false
            fh._rebuild()
        _phase = "clean"; _mark = _f
    elif _phase == "clean" and _f - _mark >= 90 and not _done:
        _done = true
        var box2 := HudDock.centre(_t)
        _save("3_grid_scroll_clean_1080")
        _crop("4_scroll_clean_crop", Rect2i(int(box2.position.x) - 20, int(box2.position.y) - 20, int(box2.size.x) + 40, int(box2.size.y) + 40))
        print("L61_SHOT done box ", box2)
        return true
    if _f > 2600:
        print("L61_SHOT timed out at ", _phase)
        return true
    return false
