extends CanvasLayer
class_name LeaderboardPanel
## The Guild Roll on screen: the standing board from the roster (same roll as
## the !top chat lists) and the latest of the fallen, on parchment like the
## Chronicle, top-right. L toggles it; F10 hides it with the rest of the UI.

const ROWS := 8
const FALLEN := 3
const INK := Color(0.20, 0.13, 0.08)
const GOLD := Color(0.50, 0.32, 0.02)
const DEAD := Color(0.36, 0.27, 0.19)

var roster: Roster
var _panel: PanelContainer
var _list: VBoxContainer
var _t := 0.0

func setup(r: Roster) -> void:
    roster = r
    _refresh()

func _ready() -> void:
    layer = 20
    UiTheme.watch(self)
    _build()

## L15: F11 changed the UI scale
func restyle() -> void:
    if _panel:
        _panel.queue_free()
    _build()
    _refresh()

func _build() -> void:
    _panel = PanelContainer.new()
    _panel.add_theme_stylebox_override("panel", UiTheme.parchment())
    _panel.anchor_left = 1.0
    _panel.anchor_right = 1.0
    _panel.offset_right = -UiTheme.px(18)
    _panel.offset_top = UiTheme.px(290)      # L15: below the boss bar's band at every scale
    _panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
    _panel.custom_minimum_size = Vector2(UiTheme.px(500), 0)
    add_child(_panel)
    _list = VBoxContainer.new()
    _list.add_theme_constant_override("separation", 1)
    _panel.add_child(_list)

func _unhandled_input(ev: InputEvent) -> void:
    if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_L:
        visible = not visible
        Sfx.play("ui", -8.0)
        get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
    _t -= delta
    if _t <= 0.0:
        _t = 5.0
        _refresh()

func _line(text: String, col: Color, size := 15) -> void:
    var lb := Label.new()
    lb.text = text
    lb.add_theme_font_size_override("font_size", UiTheme.px(size))
    lb.add_theme_color_override("font_color", col)
    lb.clip_text = true
    lb.custom_minimum_size = Vector2(UiTheme.px(464), 0)
    _list.add_child(lb)

func _refresh() -> void:
    if _list == null or roster == null:
        return
    for c in _list.get_children():
        c.queue_free()
    _line("The Guild Roll", Color(0.48, 0.20, 0.12), 30)
    var rows: Array = roster.leaderboard("standing", ROWS - int(round((UiTheme.scale - 1.0) * 6.0)))
    if rows.is_empty():
        _line("Nobody has enlisted yet.  !enlist <class>", DEAD, 24)
    var i := 0
    for row: Dictionary in rows:
        i += 1
        var alive := bool(row.get("alive", true))
        var t := "%d. %s  %s · lv %d · deep %d%s" % [i, String(row.get("name", "?")),
            String(row.get("rank", "Unproven")), int(row.get("level", 1)),
            int(row.get("deepest", 0)), "" if alive else "  +"]
        _line(t, (GOLD if i <= 3 else INK) if alive else DEAD, 26)
    if not roster.fallen.is_empty() and UiTheme.scale < 1.4:
        _line(" ", INK, 8)
        _line("The Fallen", Color(0.48, 0.20, 0.12), 26)
        for f: Dictionary in roster.fallen.slice(0, FALLEN):
            _line("%s the %s, lv%d - %s" % [String(f.get("name", "?")), String(f.get("class", "")),
                int(f.get("level", 1)), String(f.get("killed_by", "the dark"))], DEAD, 22)
