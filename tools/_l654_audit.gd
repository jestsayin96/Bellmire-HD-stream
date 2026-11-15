extends SceneTree
## L65.4 LEGIBILITY AUDIT. WINDOWED, 1920x1080, NO --headless. Brings up the resting stream
## (2x2 grid, Chronicle running, feed lines, a lord card, spotlight panes, leaderboard), freezes
## time, captures the frame, then hides every glyph (visible_characters = 0) and captures the
## BACKDROP the text actually sits on (live 3D, plates, parchment). For every on-screen Label /
## RichTextLabel it reports the size in 1080p px and the WCAG contrast of its font colour against
## the real backdrop pixels (mean and worst 10th percentile). Floors come from UiTheme.
## renders/cycles/20261115_l654.
var _t: Node3D
var _eye
var _f := 0
var _phase := "warm"
var _mark := 0
var _done := false
var _items: Array = []
const OUT := "res://renders/cycles/20261115_l654"
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

func _alpha_chain(n: Node) -> float:
    var a := 1.0
    var c := n
    while c != null:
        if c is CanvasItem:
            a *= (c as CanvasItem).modulate.a * (c as CanvasItem).self_modulate.a
        c = c.get_parent()
    return a

func _walk(n: Node, out: Array) -> void:
    for ch in n.get_children():
        if ch is Label or ch is RichTextLabel:
            var ctl := ch as Control
            var txt := String(ch.get("text"))
            if txt.strip_edges() != "" and ctl.is_visible_in_tree() and _alpha_chain(ch) > 0.5:
                var r := ctl.get_global_rect()
                var vp := Rect2(Vector2.ZERO, Vector2(root.size))
                if r.size.x > 2 and r.size.y > 2 and vp.intersects(r):
                    out.append(ch)
        _walk(ch, out)

func _group(n: Node) -> String:
    var p := n
    var chain: Array = []
    while p != null and p != root and p != _t:
        chain.append(p.name)
        p = p.get_parent()
    chain.reverse()
    return "/".join(chain.slice(0, 2))

func _font_px(n: Node) -> int:
    if n is RichTextLabel:
        return (n as RichTextLabel).get_theme_font_size("normal_font_size")
    return (n as Label).get_theme_font_size("font_size")

func _font_col(n: Node) -> Color:
    if n is RichTextLabel:
        return (n as RichTextLabel).get_theme_color("default_color")
    return (n as Label).get_theme_color("font_color")

func _hide_glyphs(list: Array) -> void:
    for n in list:
        if n is RichTextLabel:
            (n as RichTextLabel).visible_characters = 0
        else:
            (n as Label).visible_characters = 0

func _over(fg: Color, bg: Color) -> Color:
    return Color(bg.r + (fg.r - bg.r) * fg.a, bg.g + (fg.g - bg.g) * fg.a, bg.b + (fg.b - bg.b) * fg.a, 1.0)

func _measure(list: Array, back: Image, front: Image) -> void:
    var k := UiTheme.res_k()
    var lines: Array = []
    var fails := 0
    for n in list:
        var ctl := n as Control
        var r := Rect2i(ctl.get_global_rect())
        if n is Label:
            var sb: StyleBox = (n as Label).get_theme_stylebox("normal")
            if sb:
                r = Rect2i(r.position + Vector2i(int(sb.get_margin(SIDE_LEFT)), int(sb.get_margin(SIDE_TOP))), r.size - Vector2i(int(sb.get_margin(SIDE_LEFT) + sb.get_margin(SIDE_RIGHT)), int(sb.get_margin(SIDE_TOP) + sb.get_margin(SIDE_BOTTOM))))
        r = r.intersection(Rect2i(Vector2i.ZERO, back.get_size()))
        if r.size.x <= 0 or r.size.y <= 0:
            continue
        var col := _font_col(n)
        var ratios: Array = []
        var sx := maxi(1, r.size.x / 40)
        var sy := maxi(1, r.size.y / 12)
        var y := r.position.y
        while y < r.end.y:
            var x := r.position.x
            while x < r.end.x:
                ratios.append(UiTheme.contrast(_over(col, back.get_pixel(x, y)), back.get_pixel(x, y)))
                x += sx
            y += sy
        ratios.sort()
        var p10: float = ratios[int(ratios.size() * 0.10)]
        var mean := 0.0
        for v in ratios:
            mean += float(v)
        mean /= float(ratios.size())
        var px1080 := float(_font_px(n)) / k
        var ok_size := px1080 >= float(UiTheme.FLOOR_PX) - 0.5
        var ok_con := p10 >= UiTheme.FLOOR_CONTRAST
        if not (ok_size and ok_con):
            fails += 1
        var txt := String(n.get("text")).replace("\n", " ")
        lines.append("AUDIT|%s|%s|%.0fpx|p10 %.2f|mean %.2f|%s" % [_group(n), txt.substr(0, 34), px1080, p10, mean, ("PASS" if (ok_size and ok_con) else ("FAIL size" if not ok_size else "FAIL contrast"))])
    for ln in lines:
        print(ln)
    print("AUDIT_TOTAL ", lines.size(), " elements, ", fails, " below floor (", UiTheme.FLOOR_PX, " px, ", UiTheme.FLOOR_CONTRAST, ":1)")
    var f := FileAccess.open(ProjectSettings.globalize_path(OUT + "/audit.txt"), FileAccess.WRITE)
    f.store_string("\n".join(lines) + "\nTOTAL %d elements, %d below floor (%d px, %.1f:1)\n" % [lines.size(), fails, UiTheme.FLOOR_PX, UiTheme.FLOOR_CONTRAST])
    f.close()

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
    elif _phase == "fill" and _f - _mark >= 780:
        FeedHUD.card_on(_t, "Grimwarden the Hollow", "a rare lord stirs beneath the scar", Color(0.60, 0.32, 0.70))
        _phase = "card"; _mark = _f
    elif _phase == "card" and _f - _mark >= 240:
        Engine.time_scale = 0.0
        _phase = "freeze"; _mark = _f
    elif _phase == "freeze" and _f - _mark >= 10:
        _items.clear()
        _walk(root, _items)
        var front := root.get_texture().get_image()
        front.save_png(ProjectSettings.globalize_path(OUT + "/1_live_1080.png"))
        _hide_glyphs(_items)
        _phase = "hidden"; _mark = _f
    elif _phase == "hidden" and _f - _mark >= 10 and not _done:
        _done = true
        var back := root.get_texture().get_image()
        back.save_png(ProjectSettings.globalize_path(OUT + "/2_backdrop_1080.png"))
        _measure(_items, back, null)
        print("L654_AUDIT done, window ", root.size)
        return true
    if _f > 2600:
        print("L654_AUDIT timed out at ", _phase)
        return true
    return false
