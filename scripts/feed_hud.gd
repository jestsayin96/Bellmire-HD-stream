extends CanvasLayer
class_name FeedHUD
## The chronicle on screen: the last few feed lines on a strip of parchment,
## bottom-left, newest at the bottom. Reads an Array it is handed (town.feed),
## so the town, the delve and any test harness all share one feed.
## Lines age out gently; nothing is ever posted anywhere.

const SHOW := 6
var source: Array = []
var _seen := 0
var _box: VBoxContainer
var _panel: PanelContainer
var _ages: Array = []

func _ready() -> void:
    layer = 20
    _panel = PanelContainer.new()
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.93, 0.86, 0.69, 0.88)       # parchment
    sb.border_color = Color(0.45, 0.30, 0.16, 0.95)   # inked edge
    sb.set_border_width_all(3)
    sb.set_corner_radius_all(6)
    sb.content_margin_left = 16
    sb.content_margin_right = 16
    sb.content_margin_top = 10
    sb.content_margin_bottom = 10
    sb.shadow_color = Color(0, 0, 0, 0.35)
    sb.shadow_size = 6
    _panel.add_theme_stylebox_override("panel", sb)
    _panel.anchor_left = 0.0
    _panel.anchor_top = 1.0
    _panel.anchor_bottom = 1.0
    _panel.offset_left = 18
    _panel.offset_bottom = -18
    _panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
    _panel.custom_minimum_size = Vector2(560, 0)
    add_child(_panel)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 2)
    _panel.add_child(v)
    var title := Label.new()
    title.text = "The Chronicle"
    title.add_theme_font_size_override("font_size", 15)
    title.add_theme_color_override("font_color", Color(0.48, 0.20, 0.12))
    v.add_child(title)
    _box = VBoxContainer.new()
    _box.add_theme_constant_override("separation", 1)
    v.add_child(_box)
    _panel.visible = false

func _process(delta: float) -> void:
    if source.size() != _seen:
        _seen = source.size()
        _rebuild()
    for i in _ages.size():
        _ages[i] = float(_ages[i]) + delta
    # the panel itself fades when the town has been quiet a while
    var newest: float = _ages.back() if not _ages.is_empty() else 999.0
    _panel.modulate.a = clampf(1.0 - (newest - 40.0) / 8.0, 0.0, 1.0)

func _rebuild() -> void:
    for c in _box.get_children():
        c.queue_free()
    var lines := source.slice(maxi(0, source.size() - SHOW))
    while _ages.size() < source.size():
        _ages.append(0.0)
    for i in lines.size():
        var lb := Label.new()
        lb.text = String(lines[i])
        lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        lb.custom_minimum_size = Vector2(528, 0)
        lb.add_theme_font_size_override("font_size", 17)
        # older lines fade toward the parchment; the newest is full ink
        var k := float(i + 1) / float(lines.size())
        lb.add_theme_color_override("font_color", Color(0.20, 0.13, 0.08).lerp(Color(0.55, 0.45, 0.33), 1.0 - k))
        _box.add_child(lb)
    _panel.visible = not lines.is_empty()
