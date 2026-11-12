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
var _panel: PanelContainer
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
        _panel.queue_free()
    _build()
    if keep_t > 0.0:
        _card_title.text = keep_title
        _card_sub.text = keep_sub
        _card.visible = true
    _rebuild()

func _build() -> void:
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

var _grid := false

func card_showing() -> bool:
    return _card != null and _card.visible

func _process(delta: float) -> void:
    if _card_t > 0.0:
        _card_t -= delta / maxf(Engine.time_scale, 0.001)    # real seconds at any speed
        if _card_t <= 0.0:
            _card.visible = false
            _rebuild()
    # L17: the spotlight grid (root 3D off) - the Chronicle drops to 3 lines so it does not bury the subs pane
    var g := get_viewport() != null and get_viewport().disable_3d
    if g != _grid:
        _grid = g
        _rebuild()
    if source.size() != _seen:
        _seen = source.size()
        _rebuild()
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
    if _grid:
        show = mini(show, 3)
    var lines := source.slice(maxi(0, source.size() - maxi(1, show - 2 if card_showing() else show)))
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
        lb.add_theme_font_size_override("font_size", UiTheme.px(28))
        # older lines fade toward the parchment; the newest is full ink
        var k := float(i + 1) / float(lines.size())
        lb.add_theme_color_override("font_color", Color(0.16, 0.10, 0.06).lerp(Color(0.40, 0.30, 0.20), 1.0 - k))
        _box.add_child(lb)
    _panel.visible = not lines.is_empty() or card_showing()
