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
var legacy_margin := false      # U112: a test switch - the pre-U111 geometry (4px pad, label fills the box) for the A/B capture

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

## ---- L67: THE FEED MUST SURVIVE A RAID. Everything below is the stated policy; the numbers
## are the ones the DONE test measures against.
## PRIORITY (L67.1): every line is classed once, on arrival. 3 = a death, a boss or lord, a
## raid; 2 = a town-level event, or a line the town tagged with a named hero (a viewer's own
## action); 1 = ordinary town life; 0 = a routine pickup / errand. Town tags (town.feed_tags,
## D60) win over words; words only fill in for untagged lines.
const P_ROUTINE := 0
const P_NORMAL := 1
const P_TOWN := 2
const P_CRIT := 3
const PROTECT_FROM := 2         # a line at this priority or above is never dropped for being routine
## MERGING (L67.2): a repeat is the same line once digits are ignored, seen again within
## MERGE_S real seconds of the earlier copy being raised. It becomes "<line>  x3", not a line.
const MERGE_S := 30.0
## RATE AND DECAY (L67.3): at most one line ADMITTED to the scroll every PACE_S (= 1.25
## lines/s). Each line dwells on screen at least DWELL[priority] real seconds before a line
## may take its place; a higher priority may displace a lower one after DWELL_FLOOR. What
## waits is capped at QUEUE_MAX; overflow drops the LOWEST priority, oldest first, and a
## routine line that waited STALE_S is dropped as stale. Every drop is in feed_log.
const DWELL := [4.0, 7.0, 12.0, 18.0]
const DWELL_FLOOR := 3.0
const QUEUE_MAX := 10
const STALE_S := 40.0
const LOG_MAX := 900
const RE_TOWN := "town level|grows into|falls back to|caravan|festival|bounty|raised to level|granary|coffer|hunger"
const RE_CRIT := "\\b(dies|died|has fallen|fallen|slain|killed|falls|lord|boss|raid|raiders|raiding|besiege|besieged|ablaze|warband|scar)\\b"
const RE_LOW := "picks up|gathers|finds a|sips|drinks|eats|sweeps|chops|fetches|fills|hauls|mends|sells a|buys a|harvest"
var feed_log: Array = []        # every ADMIT / MERGE / DROP, with the clock, priority and text
var stats := {"seen": 0, "admitted": 0, "merged": 0, "dropped": 0, "dropped_protected": 0,
    "min_gap": 999.0, "by_pri": [0, 0, 0, 0]}
var _clock := 0.0               # real seconds (time_scale divided out)
var _cursor := 0                # how far into source the classifier has read
var _pending: Array = []        # classed lines waiting for a slot: {text,key,pri,t,n}
var _shown: Array = []          # the lines on the scroll: {text,key,pri,t,at,n}
var _last_admit := -1.0
var _re_town: RegEx
var _re_crit: RegEx
var _re_low: RegEx
## L39 (Mr. E, Nov 13): "the letters are super huge". The on-stream Chronicle line was the
## L15 reading size (28 px at 1080p) - right for the bottom-left panel at full screen, far
## too big for a box at the centre of the grid. The FONT shrinks first; HudDock.centre is
## then sized to the smaller text. The full-screen panel keeps 28 - he did not complain
## about that one, and it is read from further back.
const CHRON_PX := 21            # the centre box's line size at 1080p (L61: 18 -> 21, Mr. E approved)
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
    cs.bg_color = UiTheme.PLATE
    cs.border_color = UiTheme.EDGE_ON_DARK
    cs.set_border_width_all(UiTheme.BORDER)
    cs.set_corner_radius_all(UiTheme.RADIUS)
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
    _card_title.add_theme_color_override("font_outline_color", UiTheme.ON_DARK_SHADOW)
    _card_title.add_theme_constant_override("outline_size", 4)
    cv.add_child(_card_title)
    _card_sub = Label.new()
    _card_sub.autowrap_mode = TextServer.AUTOWRAP_OFF
    _card_sub.max_lines_visible = 1
    _card_sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
    _card_sub.custom_minimum_size = Vector2(UiTheme.px(150), 0)
    _card_sub.add_theme_font_size_override("font_size", UiTheme.px(CARD_SUB_PX))
    _card_sub.add_theme_color_override("font_color", UiTheme.ON_DARK)
    # U109: sub line is ellipsis-trimmed; its old 240px floor made the card 396px at 150% and left the
    # Chronicle text a 200px column. 150px keeps the card readable and the text a column.
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
        var sr := _vellum()
        _content.position = sr.position
        _content.size = sr.size
        _content.custom_minimum_size = sr.size

## U40: the open vellum with a breathing gap under the scroll rail and above the lower rail. A full stack
## used to start FLUSH under the top rail at 100% grid (a flush line reads as clipped on stream).
func _vellum() -> Rect2:
    var sr := (_panel as HudDock.ChronicleScroll).sheet_rect()
    var pad := float(UiTheme.px(6))
    if sr.size.y <= pad * 3.0:
        return sr
    return Rect2(sr.position.x, sr.position.y + pad, sr.size.x, sr.size.y - pad * 1.5)

## L36: at full screen the Chronicle is the bottom-left panel and the chat box the bottom-right one;
## from 125% up their widths meet. While chat is up and they would share columns, the panel rides
## ABOVE the chat box instead of under it (nothing shrinks, nothing is cut). In the grid the strip
## and the chrome bar are separate bands by construction (HudDock.centre / chrome).
func _clear_of_chat() -> void:
    if _panel == null:
        return
    var base := -UiTheme.px(18)
    var cr := HudDock.chat_rect(get_parent())
    var want := base
    if cr.size.x > 0.0 and cr.size.y > 0.0:
        var left_x := _panel.offset_left + _panel.get_parent_area_size().x * _panel.anchor_left
        var right_x := left_x + maxf(_panel.size.x, float(UiTheme.px(WIDTH)))
        if right_x + float(UiTheme.px(8)) > cr.position.x:
            want = -(HudDock.screen().y - cr.position.y) - float(UiTheme.px(8))
    if absf(_panel.offset_bottom - want) > 0.5:
        _panel.offset_bottom = want

## how many one-line entries fit the scroll's open vellum (L39b: up to 9)
func _chrome_lines() -> int:
    var inner: float
    if _panel is HudDock.ChronicleScroll:
        inner = _vellum().size.y
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
    cs.bg_color = UiTheme.PLATE
    cs.border_color = UiTheme.EDGE_ON_DARK
    cs.set_border_width_all(UiTheme.BORDER)
    cs.set_corner_radius_all(UiTheme.RADIUS)
    cs.content_margin_left = UiTheme.px(14)
    cs.content_margin_right = UiTheme.px(14)
    cs.content_margin_top = UiTheme.px(6)
    cs.content_margin_bottom = UiTheme.px(10)
    _card.add_theme_stylebox_override("panel", cs)
    var cv := VBoxContainer.new()
    cv.add_theme_constant_override("separation", 0)
    _card.add_child(cv)
    _card_title = Label.new()
    _card_title.add_theme_font_size_override("font_size", UiTheme.px(UiTheme.T_WORDMARK))
    _card_title.add_theme_color_override("font_outline_color", UiTheme.ON_DARK_SHADOW)
    _card_title.add_theme_constant_override("outline_size", 6)
    cv.add_child(_card_title)
    _card_sub = Label.new()
    _card_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _card_sub.custom_minimum_size = Vector2(UiTheme.px(WIDTH - 70), 0)
    _card_sub.add_theme_font_size_override("font_size", UiTheme.px(UiTheme.T_NUMERAL))
    _card_sub.add_theme_color_override("font_color", UiTheme.ON_DARK)
    cv.add_child(_card_sub)
    _card.visible = false
    v.add_child(_card)
    _box = VBoxContainer.new()
    _box.add_theme_constant_override("separation", 1)
    v.add_child(_box)
    _panel.visible = false

func card(title: String, sub: String, col: Color) -> void:
    # U126 (Mr. E 21 Nov 10:17 directive): the boss info card is OUT of the Chronicle - it is for
    # event text only; boss info lives on the hub. The card stays built but never shows.
    if true:
        return
    if _card == null:
        return
    _card_title.text = title
    _card_title.add_theme_color_override("font_color", col.lightened(0.35))
    _card_sub.text = sub
    var cs := _card.get_theme_stylebox("panel") as StyleBoxFlat
    if cs:
        cs.border_color = col.lerp(UiTheme.EDGE_ON_DARK, 0.4)
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
    else:
        _clear_of_chat()
    # L32b calm pacing, now L67: classify what arrived, merge repeats, admit by priority at
    # no more than one line per PACE_S, hold each line its dwell
    _tick_feed(delta / maxf(Engine.time_scale, 0.001))
    # the panel itself fades when the town has been quiet a while
    var newest: float = (_clock - _last_admit) if _last_admit >= 0.0 else 999.0
    _panel.modulate.a = 1.0 if _card_t > 0.0 else clampf(1.0 - (newest - 40.0) / 8.0, 0.0, 1.0)

## how many lines the scroll holds right now (the card, the UI scale and the box all move it)
func _cap() -> int:
    var show := SHOW - int(round((UiTheme.scale - 1.0) * 4.0))
    if _chrome:
        show = mini(_chrome_lines(), 5) + (2 if card_showing() else 0)   # L71: fewer, whole entries; height-fit trims further
    return maxi(1, show - 2 if card_showing() else show)

## L74: which shown line the height/cap trim takes - lowest priority, oldest within it, never the newest
func _trim_index(ents: Array) -> int:
    var w := 0
    for i in range(0, maxi(1, ents.size() - 1)):
        if int(ents[i]["pri"]) < int(ents[w]["pri"]):
            w = i
    return w

func _rebuild() -> void:
    for c in _box.get_children():
        c.queue_free()
    var lines: Array = []
    # L74: when the box holds fewer lines than are up (a scale step, the card), the line that
    # goes is the lowest-priority one, oldest first - never simply the oldest. A P_CRIT line keeps
    # its place; only the newest line is exempt from being the one trimmed.
    var ents: Array = _shown.duplicate()
    while ents.size() > _cap():
        ents.remove_at(_trim_index(ents))
    for e in ents:
        lines.append(_text_of(e))
    var fs := UiTheme.px(CHRON_PX if _chrome else 28)
    var wrap_w := 0.0
    if _chrome:
        # L71: the Chronicle never ends a sentence in an ellipsis. Lines WRAP (two lines an entry,
        # three at the outside), fewer entries are shown, and the OLDEST are dropped until the
        # whole text fits the vellum's height. The roll's outcome is never the part that is cut.
        var avail := _chrome_text_w()
        wrap_w = avail
        # U114: measure with the font the Labels will really draw with (the theme's), not the engine
        # fallback: at 100% the two disagree and a 7-line stack was judged to fit a 5-line vellum.
        var font: Font = _box.get_theme_font("font", "Label")
        if font == null:
            font = ThemeDB.fallback_font
        var budget := _chrome_h()
        for i in lines.size():
            lines[i] = tidy(String(lines[i]))
        while lines.size() > 1 and _stack_h(lines, font, fs, avail) > budget:
            var ti := _trim_index(ents)
            lines.remove_at(ti)
            ents.remove_at(ti)
        if lines.size() == 1 and _stack_h(lines, font, fs, avail) > budget:
            lines[0] = tidy(String(lines[0]), true)       # last resort: detail goes, outcome stays
        # U107: at 150% with a lord's card up the vellum is narrow and ONE line still wrapped past
        # the lower rail ("descend into the scar, and" ran off the scroll). Last, last resort: the
        # font steps down (never below 70% of the Chronicle size) until the stack fits the vellum.
        var fs_floor := int(floor(float(fs) * 0.7))
        while fs > fs_floor and _stack_h(lines, font, fs, avail) > budget:
            fs -= 1
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
            lb.max_lines_visible = -1                     # L71: no ellipsis in the centre box, ever
            lb.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
            lb.clip_text = false
            lb.custom_minimum_size = Vector2(wrap_w, 0)
            lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL if legacy_margin else Control.SIZE_SHRINK_BEGIN   # U111: width = the padded wrap width, not the box
        lb.add_theme_font_size_override("font_size", fs)
        # older lines fade toward the parchment; the newest is full ink
        var k := float(i + 1) / float(lines.size())
        lb.add_theme_color_override("font_color", UiTheme.INK.lerp(UiTheme.INK_SOFT, 1.0 - k))
        _box.add_child(lb)
    _panel.visible = not lines.is_empty() or card_showing()

## L71: width the wrapped lines have inside the vellum (less the lord's card when it is up)
func _chrome_text_w() -> float:
    var w := 300.0
    if _panel is HudDock.ChronicleScroll:
        w = _vellum().size.x
    if card_showing() and _card != null:
        # U109: the card never takes more than 40% of the vellum; the text keeps at least 60%
        w -= minf(_card.get_combined_minimum_size().x + float(UiTheme.px(14)), w * 0.4)
    # U111: right padding - U110's 150% frame had a word touching the vellum edge (~2px margin)
    return maxf(w - (4.0 if legacy_margin else float(UiTheme.px(10))), 120.0)

func _chrome_h() -> float:
    if _panel is HudDock.ChronicleScroll:
        return _vellum().size.y
    return 200.0

func _stack_h(lines: Array, font: Font, fs: int, w: float) -> float:
    var h := 0.0
    for t in lines:
        h += font.get_multiline_string_size(String(t), HORIZONTAL_ALIGNMENT_LEFT, w, fs).y + 1.0
    return h

## L71: the HUD's own tightening of the Chronicle's WORDING. Roll detail is kept ("Perception 20
## vs DC 13") but padded phrasing goes; with `hard` the bracketed detail goes and the outcome stays.
static func tidy(t: String, hard := false) -> String:
    var s := t.replace("!!", "!").replace("Successfully found", "Found").replace("...no loot...", "no loot")
    s = s.replace("(halved)", "halved")
    if s.ends_with(" -"):
        s = s.substr(0, s.length() - 2)
    if hard:
        var re := RegEx.new()
        re.compile("\\s*\\([^)]*\\)")
        s = re.sub(s, "", true)
    return s

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


## ================================================================ L67: THE FEED UNDER LOAD
## one clock, real seconds: a 4x test and a 1x stream obey the same stated numbers
func _tick_feed(dt: float) -> void:
    _clock += dt
    _ingest()
    _pace_t = maxf(0.0, _pace_t - dt)
    # a routine line that has waited past STALE_S is news no longer - drop it, in the log
    for i in range(_pending.size() - 1, -1, -1):
        var e: Dictionary = _pending[i]
        if int(e["pri"]) < PROTECT_FROM and _clock - float(e["t"]) > STALE_S:
            _drop(e, "stale")
            _pending.remove_at(i)
    if _pending.is_empty() or _pace_t > 0.0:
        return
    var i := _best_pending()
    var e: Dictionary = _pending[i]
    if _shown.size() >= _cap():
        var v := _evict_index(int(e["pri"]))
        if v < 0:
            return                          # every line up is inside its dwell - the newcomer waits
        _shown.remove_at(v)
    _pending.remove_at(i)
    _admit(e)

## read what the town raised since last frame: class it, merge repeats, keep the queue bounded
func _ingest() -> void:
    if source.size() < _cursor:             # the source was cleared (a test, a new town)
        _cursor = source.size()
        _pending.clear()
        _shown.clear()
        _rebuild()
    var tags: Dictionary = {}
    var tv = get_parent().get("feed_tags") if get_parent() != null else null
    if tv is Dictionary:
        tags = tv
    var touched := false
    while _cursor < source.size():
        var text := String(source[_cursor])
        _cursor += 1
        stats["seen"] = int(stats["seen"]) + 1
        var key := _key_of(text)
        var pri := classify(text, tags.get(text, {}))
        if _merge_into(key, text):
            touched = true
            continue
        _pending.append({"text": text, "key": key, "pri": pri, "t": _clock, "n": 1})
    # overflow: the LOWEST priority goes first, oldest first within it
    while _pending.size() > QUEUE_MAX:
        var w := 0
        for i in _pending.size():
            var a: Dictionary = _pending[i]
            var b: Dictionary = _pending[w]
            if int(a["pri"]) < int(b["pri"]) or (int(a["pri"]) == int(b["pri"]) and float(a["t"]) < float(b["t"])):
                w = i
        _drop(_pending[w], "overflow")
        _pending.remove_at(w)
    if touched:
        _rebuild()

## a repeat: the same line, digits ignored, within MERGE_S of the earlier copy being raised
func _merge_into(key: String, text: String) -> bool:
    for e: Dictionary in _pending:
        if e["key"] == key:
            e["n"] = int(e["n"]) + 1
            e["text"] = text
            stats["merged"] = int(stats["merged"]) + 1
            _flog("MERGE pending n=%d '%s'" % [int(e["n"]), text])
            return true
    for i in range(_shown.size() - 1, -1, -1):
        var e: Dictionary = _shown[i]
        if e["key"] == key and _clock - float(e["t"]) <= MERGE_S:
            e["n"] = int(e["n"]) + 1
            e["text"] = text
            e["t"] = _clock                 # a live repeat keeps the window open
            stats["merged"] = int(stats["merged"]) + 1
            _flog("MERGE shown n=%d '%s'" % [int(e["n"]), text])
            return true
    return false

## highest priority first, oldest first within it
func _best_pending() -> int:
    var w := 0
    for i in _pending.size():
        var a: Dictionary = _pending[i]
        var b: Dictionary = _pending[w]
        if int(a["pri"]) > int(b["pri"]) or (int(a["pri"]) == int(b["pri"]) and float(a["t"]) < float(b["t"])):
            w = i
    return w

## the shown line a newcomer of priority `pri` may replace: one past its dwell, or a LOWER
## priority one past DWELL_FLOOR; the lowest priority and the oldest of those. -1 = none may go
func _evict_index(pri: int) -> int:
    var w := -1
    for i in _shown.size():
        var e: Dictionary = _shown[i]
        var age := _clock - float(e["at"])
        var epri := int(e["pri"])
        var rd := _read_s(e)             # L74: a long line is held long enough to READ, whatever its class
        var ok: bool = age >= maxf(float(DWELL[epri]), rd) or (pri > epri and age >= maxf(DWELL_FLOOR, rd))
        if not ok:
            continue
        if w < 0:
            w = i
            continue
        var b: Dictionary = _shown[w]
        if epri < int(b["pri"]) or (epri == int(b["pri"]) and float(e["at"]) < float(b["at"])):
            w = i
    return w

## L74: seconds to read a line at READ_CPS plus the eye finding it; capped so one huge line cannot pin the scroll
const READ_CPS := 18.0
const SCAN_S := 1.0
const READ_CAP_S := 10.0
func _read_s(e: Dictionary) -> float:
    return minf(float(_text_of(e).length()) / READ_CPS + SCAN_S, READ_CAP_S)

func _admit(e: Dictionary) -> void:
    e["at"] = _clock
    _shown.append(e)
    if _last_admit >= 0.0:
        stats["min_gap"] = minf(float(stats["min_gap"]), _clock - _last_admit)
    _last_admit = _clock
    _pace_t = PACE_S
    stats["admitted"] = int(stats["admitted"]) + 1
    (stats["by_pri"] as Array)[int(e["pri"])] = int((stats["by_pri"] as Array)[int(e["pri"])]) + 1
    _flog("ADMIT pri=%d q=%d '%s'" % [int(e["pri"]), _pending.size(), String(e["text"])])
    _rebuild()
    _fade_in_newest()

func _drop(e: Dictionary, why: String) -> void:
    stats["dropped"] = int(stats["dropped"]) + 1
    if int(e["pri"]) >= PROTECT_FROM:
        stats["dropped_protected"] = int(stats["dropped_protected"]) + 1
    _flog("DROP %s pri=%d '%s'" % [why, int(e["pri"]), String(e["text"])])

func _text_of(e: Dictionary) -> String:
    var n := int(e["n"])
    if n <= 1:
        return String(e["text"])
    # L74: the "x5" binds to the last word (no-break space) so it never wraps onto a line alone
    var t := String(e["text"])
    var sp := t.rfind(" ")
    if sp > 0:
        t = t.substr(0, sp) + "\u00a0" + t.substr(sp + 1)
    return "%s\u00a0x%d" % [t, n]

func _flog(msg: String) -> void:
    feed_log.append("t=%.1f %s" % [_clock, msg])
    if feed_log.size() > LOG_MAX:
        feed_log = feed_log.slice(feed_log.size() - LOG_MAX)

func log_text() -> String:
    return "\n".join(feed_log)

## "A goblin falls (3)" and "A goblin falls (4)" are one line: digits do not make a new one
func _key_of(text: String) -> String:
    var out := ""
    var in_num := false
    for ch in text.to_lower():
        var d: bool = ch >= "0" and ch <= "9"
        if d and in_num:
            continue                        # 89 and 149 are the same number as far as a repeat goes
        out += "#" if d else ch
        in_num = d
    return out

## L67.1: tag first (the raiser knew), words second (the raiser did not)
func classify(text: String, tag: Dictionary) -> int:
    if _re_town == null:
        _re_town = RegEx.create_from_string(RE_TOWN)
        _re_crit = RegEx.create_from_string(RE_CRIT)
        _re_low = RegEx.create_from_string(RE_LOW)
    var kind := String(tag.get("kind", ""))
    if kind in ["raid", "death", "lord", "boss"]:
        return P_CRIT
    if kind != "" and kind != "misc" and not tag.has("who"):
        return P_TOWN
    if tag.has("who"):
        return P_TOWN                       # a named hero's own action
    var low := text.to_lower()
    if _re_town.search(low) != null:
        return P_TOWN
    if _re_crit.search(low) != null:
        return P_CRIT
    if _re_low.search(low) != null:
        return P_ROUTINE
    return P_NORMAL
