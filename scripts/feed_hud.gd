extends CanvasLayer
class_name FeedHUD
## The chronicle on screen: the last few feed lines on a strip of parchment,
## bottom-left, newest at the bottom. Reads an Array it is handed (town.feed),
## so the town, the delve and any test harness all share one feed.
## Lines age out gently; nothing is ever posted anywhere.

const SHOW := 5
## L15: a Chronicle line is 28 px at 1080p (phone-readable); the panel is this wide at 1080p
const WIDTH := 760
var source: Array = []
var _seen := 0
var _box: VBoxContainer
var _panel: Control            # L61: a ChronicleScroll on the grid, a parchment PanelContainer at full screen
var _ages: Array = []
## the lord's name card: a dark gold-edged block at the head of the Chronicle
## when a lord rises (and again when one falls); held CARD_SECS real seconds
const CARD_SECS := 14.0
var _card: PanelContainer
var _card_title: Label
var _card_sub: Label
var _card_t := 0.0

## put a name card up in the town's Chronicle (no-op without a FeedHUD)
static func card_on(town: Node, title: String, sub: String, col: Color) -> void:
    if town == null:
        return
    for c in town.get_children():
        if c is FeedHUD:
            (c as FeedHUD).card(title, sub, col)

func _ready() -> void:
    layer = 20
    UiTheme.watch(self)
    _build()

## L15: F11 changed the UI scale - build the panel again at the new sizes
func restyle() -> void:
    var keep_t := _card_t
    var keep_title := _card_title.text if _card_title else ""
    var keep_sub := _card_sub.text if _card_sub else ""
    if _panel:
        remove_child(_panel)            # out of the tree NOW, so the new one keeps the name "Chronicle"
        _panel.remove_from_group("hud_chronicle")
        _panel.queue_free()
    _build()
    if keep_t > 0.0:
        _card_title.text = keep_title
        _card_sub.text = keep_sub
        _card.visible = true
    _rebuild()

## ---- L32b (Mr. E's original ask): with the grid up - the stream's resting state, so in
## effect always - the Chronicle lives on the CENTRE STRIP at the cross of the four panes
## (HudDock.centre): full width, one line an entry at the L15 size, a lord's card at its
## left. CALM PACING: a new line lands at most every PACE_S (no busy-moment scroll); a
## flood skips ahead to the latest FLOOD lines instead of racing through the backlog;
## each new line fades in.
const PACE_S := 0.8
const FLOOD := 8
## L39 (Mr. E, Nov 13): "the letters are super huge". The on-stream Chronicle line was the
## L15 reading size (28 px at 1080p) - right for the bottom-left panel at full screen, far
## too big for a box at the centre of the grid. The FONT shrinks first; HudDock.centre is
## then sized to the smaller text. The full-screen panel keeps 28 - he did not complain
## about that one, and it is read from further back.
const CHRON_PX := 18            # the centre box's line size at 1080p
const CARD_PX := 20             # a lord's card title in the box
const CARD_SUB_PX := 14
var _chrome := false            # "strip mode" (the name predates L32b: it was the chrome bar)
var _pace_t := 0.0
var _content: HBoxContainer      # L61: the scroll's open-vellum text area, re-placed each frame

func _build_chrome() -> void:
    # L61 (Mr. E, Nov 13): the centre Chronicle reads as an UNFURLED SCROLL now, the stream's
    # signature piece. The parchment / spindles / illuminated margin are drawn by
    # HudDock.ChronicleScroll (one cheap procedural layer, no texture). This panel just
    # supplies the live lines and a lord's card, docked inside the scroll's open vellum
    # (sheet_rect) so ink never sits on a spindle. Line size (CHRON_PX = 18) and the 8-9
    # line capacity (_chrome_lines) stay as Mr. E signed off in L39/L39b.
    _panel = HudDock.ChronicleScroll.new()
    _panel.clip_contents = true
    _panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _panel.name = "Chronicle"
    _panel.add_to_group("hud_chronicle")
    HudDock.mark(_panel, "centre")       # L32b: the strip at the cross of the panes
    add_child(_panel)
    var h := HBoxContainer.new()
    h.set_anchors_preset(Control.PRESET_TOP_LEFT)
    h.add_theme_constant_override("separation", UiTheme.px(14))
    h.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _panel.add_child(h)
    _content = h
    _card = PanelContainer.new()
    var cs := StyleBoxFlat.new()
    cs.bg_color = Color(0.10, 0.07, 0.06, 0.94)
    cs.border_color = Color(0.78, 0.62, 0.30)
    cs.set_border_width_all(2)
    cs.set_corner_radius_all(5)
    cs.content_margin_left = UiTheme.px(12)
    cs.content_margin_right = UiTheme.px(12)
    cs.content_margin_top = UiTheme.px(2)
    cs.content_margin_bottom = UiTheme.px(4)
    _card.add_theme_stylebox_override("panel", cs)
    _card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    var cv := VBoxContainer.new()
    cv.add_theme_constant_override("separation", 0)
    _card.add_child(cv)
    _card_title = Label.new()
    _card_title.add_theme_font_size_override("font_size", UiTheme.px(CARD_PX))
    _card_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
    _card_title.add_theme_constant_override("outline_size", 4)
    cv.add_child(_card_title)
    _card_sub = Label.new()
    _card_sub.autowrap_mode = TextServer.AUTOWRAP_OFF
    _card_sub.max_lines_visible = 1
    _card_sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
    _card_sub.custom_minimum_size = Vector2(UiTheme.px(240), 0)
    _card_sub.add_theme_font_size_override("font_size", UiTheme.px(CARD_SUB_PX))
    _card_sub.add_theme_color_override("font_color", Color(0.93, 0.86, 0.69))
    cv.add_child(_card_sub)
    _card.visible = false
    h.add_child(_card)
    _box = VBoxContainer.new()
    _box.add_theme_constant_override("separation", 1)
    _box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    h.add_child(_box)
    _panel.visible = false
    _place_chrome()

## the scroll fills the centre box (a small margin); the lines / lord card dock inside the
## open vellum (ChronicleScroll.sheet_rect), clear of the spindles and the illuminated margin
func _place_chrome() -> void:
    var r := HudDock.centre(get_parent())
    if r.size.y <= 0.0 or _panel == null:
        return
    var m := float(UiTheme.px(6))
    _panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
    _panel.custom_minimum_size = Vector2.ZERO
    _panel.position = r.position + Vector2(m, m)
    _panel.size = Vector2(r.size.x - 2.0 * m, r.size.y - 2.0 * m)
    if _content != null and _panel is HudDock.ChronicleScroll:
        var sr := (_panel as HudDock.ChronicleScroll).sheet_rect()
        _content.position = sr.position
        _content.size = sr.size
        _content.custom_minimum_size = sr.size

## how many one-line entries fit the scroll's open vellum (L39b: up to 9)
func _chrome_lines() -> int:
    var inner: float
    if _panel is HudDock.ChronicleScroll:
        inner = (_panel as HudDock.ChronicleScroll).sheet_rect().size.y
    else:
        var r := HudDock.centre(get_parent())
        inner = r.size.y - float(UiTheme.px(6)) * 2.0 - float(UiTheme.px(12))
    var fs := UiTheme.px(CHRON_PX)
    var lh := ThemeDB.fallback_font.get_height(fs) + 1.0
    return clampi(int(floor(inner / maxf(lh, 1.0))), 2, 9)   # L39b: the taller box holds 8-9 lines

func _build() -> void:
    if _chrome:
        _build_chrome()
        return
    _panel = PanelContainer.new()
    var sb := UiTheme.parchment()
    _panel.add_theme_stylebox_override("panel", sb)
    _panel.anchor_left = 0.0
    _panel.anchor_top = 1.0
    _panel.anchor_bottom = 1.0
    _panel.offset_left = UiTheme.px(18)
    _panel.offset_bottom = -UiTheme.px(18)
    _panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
    _panel.custom_minimum_size = Vector2(UiTheme.px(WIDTH), 0)
    _panel.name = "Chronicle"
    _panel.add_to_group("hud_chronicle")
    HudDock.mark(_panel, "centre")      # L32b: with the panes up it is rebuilt on the centre strip
    add_child(_panel)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 2)
    _panel.add_child(v)
    v.add_child(UiTheme.title("The Chronicle", 26))       # L16: the house title
    _card = PanelContainer.new()
    var cs := StyleBoxFlat.new()
    cs.bg_color = Color(0.10, 0.07, 0.06, 0.94)
    cs.border_color = Color(0.78, 0.62, 0.30)
    cs.set_border_width_all(2)
    cs.set_corner_radius_all(5)
    cs.content_margin_left = UiTheme.px(14)
    cs.content_margin_right = UiTheme.px(14)
    cs.content_margin_top = UiTheme.px(6)
    cs.content_margin_bottom = UiTheme.px(10)
    _card.add_theme_stylebox_override("panel", cs)
    var cv := VBoxContainer.new()
    cv.add_theme_constant_override("separation", 0)
    _card.add_child(cv)
    _card_title = Label.new()
    _card_title.add_theme_font_size_override("font_size", UiTheme.px(46))
    _card_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
    _card_title.add_theme_constant_override("outline_size", 6)
    cv.add_child(_card_title)
    _card_sub = Label.new()
    _card_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _card_sub.custom_minimum_size = Vector2(UiTheme.px(WIDTH - 70), 0)
    _card_sub.add_theme_font_size_override("font_size", UiTheme.px(28))
    _card_sub.add_theme_color_override("font_color", Color(0.93, 0.86, 0.69))
    cv.add_child(_card_sub)
    _card.visible = false
    v.add_child(_card)
    _box = VBoxContainer.new()
    _box.add_theme_constant_override("separation", 1)
    v.add_child(_box)
    _panel.visible = false

func card(title: String, sub: String, col: Color) -> void:
    if _card == null:
        return
    _card_title.text = title
    _card_title.add_theme_color_override("font_color", col.lightened(0.35))
    _card_sub.text = sub
    var cs := _card.get_theme_stylebox("panel") as StyleBoxFlat
    if cs:
        cs.border_color = col.lerp(Color(0.78, 0.62, 0.30), 0.4)
    _card.visible = true
    _card_t = CARD_SECS
    _rebuild()


func card_showing() -> bool:
    return _card != null and _card.visible

func _process(delta: float) -> void:
    if _card_t > 0.0:
        _card_t -= delta / maxf(Engine.time_scale, 0.001)    # real seconds at any speed
        if _card_t <= 0.0:
            _card.visible = false
            _rebuild()
    # L21: the spotlight panes up -> the Chronicle moves to the chrome bar (and back)
    var g := HudDock.split(get_parent())
    if g != _chrome:
        _chrome = g
        restyle()
    if _chrome:
        _place_chrome()
    # L32b calm pacing: _seen is the reveal cursor into source - it advances one line
    # per PACE_S at most; a flood (a busy moment) skips the cursor to the latest FLOOD
    # lines rather than racing the strip through the backlog
    if source.size() < _seen:
        _seen = source.size()
        _rebuild()
    _pace_t = maxf(0.0, _pace_t - delta / maxf(Engine.time_scale, 0.001))
    if source.size() > _seen and _pace_t <= 0.0:
        if source.size() - _seen > FLOOD:
            _seen = source.size() - FLOOD
        _seen += 1
        _pace_t = PACE_S
        _rebuild()
        _fade_in_newest()
    for i in _ages.size():
        _ages[i] = float(_ages[i]) + delta
    # the panel itself fades when the town has been quiet a while
    var newest: float = _ages.back() if not _ages.is_empty() else 999.0
    _panel.modulate.a = 1.0 if _card_t > 0.0 else clampf(1.0 - (newest - 40.0) / 8.0, 0.0, 1.0)

func _rebuild() -> void:
    for c in _box.get_children():
        c.queue_free()
    # with a card up, fewer lines, so the Chronicle does not climb into the party frames
    # L15: bigger text, fewer lines (5 at 100%, 4 at 125%, 3 at 150%)
    var show := SHOW - int(round((UiTheme.scale - 1.0) * 4.0))
    if _chrome:
        show = _chrome_lines() + (2 if card_showing() else 0)     # the card sits beside the lines there
    # L32b: only lines the pacing cursor has revealed (_seen), newest-revealed last
    var upto := source.slice(0, mini(_seen, source.size()))
    var lines := upto.slice(maxi(0, upto.size() - maxi(1, show - 2 if card_showing() else show)))
    while _ages.size() < source.size():
        _ages.append(0.0)
    for i in lines.size():
        var lb := Label.new()
        lb.text = String(lines[i])
        lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        # L18 review: a !hero sheet wrapped to 5 lines and buried the left of the screen -
        # two lines an entry at most, the rest cut with an ellipsis (the full text is in chat)
        lb.max_lines_visible = 2
        lb.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
        lb.custom_minimum_size = Vector2(UiTheme.px(WIDTH - 40), 0)
        if _chrome:
            # L39 the centre box: one line an entry. The box is narrow, so a long line ends
            # in an ellipsis rather than being cut mid-glyph (clip_text) - the full text is
            # in chat either way.
            lb.autowrap_mode = TextServer.AUTOWRAP_OFF
            lb.max_lines_visible = 1
            lb.clip_text = false
            lb.custom_minimum_size = Vector2.ZERO
            lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        lb.add_theme_font_size_override("font_size", UiTheme.px(CHRON_PX if _chrome else 28))
        # older lines fade toward the parchment; the newest is full ink
        var k := float(i + 1) / float(lines.size())
        lb.add_theme_color_override("font_color", Color(0.16, 0.10, 0.06).lerp(Color(0.40, 0.30, 0.20), 1.0 - k))
        _box.add_child(lb)
    _panel.visible = not lines.is_empty() or card_showing()

## L32b: a newly revealed line fades in instead of popping
func _fade_in_newest() -> void:
    var kids := _box.get_children()
    if kids.is_empty():
        return
    var lb := kids[kids.size() - 1] as Label
    if lb == null:
        return
    lb.modulate.a = 0.0
    var tw := lb.create_tween()
    tw.tween_property(lb, "modulate:a", 1.0, 0.3)
