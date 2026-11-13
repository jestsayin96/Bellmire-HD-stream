extends CanvasLayer
class_name LeaderboardPanel
## L58 (Mr. E, Nov 13): THE GUILD ROLL LEAVES THE STREAM.
## L63 (Mr. E, Nov 13): THE SATCHEL LEAVES THE STREAM TOO. Per COORDINATION 13 the
## on-stream surface is exactly six things (panes, Chronicle, lane titles, now-watching,
## boss bar, in-world) - a viewer's own sheet is NOT one of them, so the L51 Satchel
## moves to the viewer hub (H11). This CanvasLayer now draws NOTHING on stream. The
## Satchel class below is kept DORMANT (not instantiated, no I key handler) so its gear /
## state / sell-price logic is still reachable if the hub wants to share it; nothing in
## this file reaches the screen any more. The setup(roster) entry point is a no-op kept
## so existing callers in town.gd compile unchanged.

var roster: Roster

func setup(r: Roster) -> void:
    # L63: still take the reference (so town.gd compiles), but do NOT subscribe to the
    # roster's changes - there is nothing on stream to raise.
    roster = r

func _ready() -> void:
    # L63: no satchel, no key handler, nothing in the tree. layer and UiTheme.watch are
    # left behind too - the file prints nothing to the stream any more.
    pass

## L63: the restyle path is gone - there is no live satchel to rebuild on an F11 scale cycle.
func restyle() -> void:
    pass


## ---------------------------------------------------------------- L51: THE SATCHEL
## Mr. E said it twice: the interface is plain and tells a viewer nothing. This is a
## viewer's own sheet on stream, in the house style - parchment, ink, the teal rule:
##
##   WORN      every piece they have on and what it GIVES, piece by piece, signed:
##             a bonus in green ink, a penalty in red. Then the numbers it all adds
##             up to - AC, hit, damage, HP, pace - read from the Roster itself, not
##             recomputed here, so the panel can never disagree with the dice.
##   RUNNING   the draughts and states on them right now, bad ones first, in the
##             state's own colour with what it actually does and the seconds left.
##   SATCHEL   what they carry: mending, oil, brews, and owned gear not worn.
##   THE COUNTER  what each of those is worth sold back, and the purse total.
##
## L58: the Guild Roll that used to share this column is gone from the stream, so
## the satchel has the column to itself; it still folds the permanent grid for its
## moment (L40's rule, kept inside this one file) and restores it when it leaves.
var _satchel: Satchel = null

func _build_satchel() -> void:
    _satchel = Satchel.new()
    _satchel.sheet = self
    add_child(_satchel)
    _satchel.build()


class Satchel extends PanelContainer:
    const HOLD := 14.0              # seconds a changed hero's sheet is held up
    const ROTATE := 11.0            # pinned: seconds before the next living hero
    ## The stream runs a permanent 2x2 grid (Spotlight: "once set up, always the
    ## grid"), so a sheet can only show by FOLDING the grid for a moment. The
    ## streamer does that deliberately with I. A viewer's purchase does NOT fold the
    ## grid on its own - that would blank the game on every !buy - it just arms the
    ## sheet to open on that buyer the next time I is pressed. AUTO_FOLD flips that if
    ## Mr. E decides a purchase should pop the sheet by itself. (DECISION for Mr. E.)
    const AUTO_FOLD := false
    const SELL_BACK := 0.4          # what the counter pays for a thing already owned
    const W := 560                  # 1080p px
    const INK := Color(0.20, 0.13, 0.08)
    const SOFT := Color(0.38, 0.28, 0.19)
    const GOLD := Color(0.50, 0.32, 0.02)
    const GOOD := Color(0.10, 0.40, 0.16)
    const BAD := Color(0.60, 0.14, 0.10)
    ## a worn piece's fields -> how the sheet says them
    const GIVES := [["ac", "AC"], ["hp", "HP"], ["hit", "to hit"], ["dmg", "dmg"],
        ["saves", "saves"], ["speed", "pace"]]

    var sheet: Node = null          # the LeaderboardPanel that owns this
    var uid := ""
    var sticky := false
    var _hold := 0.0
    var _rot := 0.0
    var _tick := 0.0
    var _list: VBoxContainer = null

    func build() -> void:
        add_theme_stylebox_override("panel", UiTheme.parchment())
        anchor_left = 1.0
        anchor_right = 1.0
        offset_right = -UiTheme.px(18)
        offset_top = UiTheme.px(72)             # a folded full-screen sheet - just clear of the clock chip
        grow_horizontal = Control.GROW_DIRECTION_BEGIN
        custom_minimum_size = Vector2(UiTheme.px(W), 0)
        HudDock.mark(self, "none")              # L21/L40: it hides while the panes are up
        visible = false
        _list = VBoxContainer.new()
        _list.add_theme_constant_override("separation", 1)
        add_child(_list)

    ## ---- who the sheet is showing

    func ro() -> Roster:
        if sheet != null and is_instance_valid(sheet) and sheet.get("roster") is Roster:
            return sheet.get("roster")
        return null

    func town() -> Node:
        if sheet != null and is_instance_valid(sheet):
            return sheet.get_parent()
        return null

    ## a viewer bought, wore, rerolled or was given something. On stream the grid
    ## stays up: this just arms the sheet to open on that buyer (and refreshes it if
    ## it is already folded open). It only pops the sheet by itself when AUTO_FOLD.
    func raise_for(user_id: String) -> void:
        var r := ro()
        if r == null or not (r.heroes as Dictionary).has(user_id):
            return
        uid = user_id
        _tick = 0.0
        if visible or AUTO_FOLD:
            _hold = HOLD
            _refresh()

    func pin(on: bool) -> void:
        sticky = on
        _rot = 0.0
        if on:
            if uid == "" or ro() == null or not ro().is_alive(uid):
                _next()
            _hold = HOLD
            _refresh()
        else:
            _hold = 0.0

    ## keep the spotlight folded exactly while the sheet is on screen
    func _fold(on: bool) -> void:
        var sp := HudDock.spot(town())
        if sp != null and is_instance_valid(sp):
            sp.suspend(on)

    ## the next living hero, so a pinned satchel tours them
    func _next() -> void:
        var r := ro()
        if r == null:
            return
        var ids: Array = []
        for k in r.heroes:
            if bool((r.heroes[k] as Dictionary).get("alive", true)):
                ids.append(String(k))
        if ids.is_empty():
            uid = ""
            return
        ids.sort()
        var i := ids.find(uid)
        uid = String(ids[(i + 1) % ids.size()])

    func _process(delta: float) -> void:
        if sticky:
            _rot -= delta
            if _rot <= 0.0:
                _rot = ROTATE
                _next()
                _tick = 0.0
            _hold = HOLD
        else:
            _hold -= delta
        var r := ro()
        var want: bool = _hold > 0.0 and uid != "" and r != null and not (r.heroes as Dictionary).is_empty()
        if visible != want:
            visible = want
            _fold(want)                         # fold the grid open / restore it
            if want:
                _tick = 0.0
        if not visible:
            return
        _tick -= delta
        if _tick <= 0.0:
            _tick = 0.5                         # the seconds on the states tick down
            _refresh()

    func _exit_tree() -> void:
        _fold(false)                            # never leave the grid folded if we go away

    ## ---- the sheet

    func _line(text: String, col: Color, size := 22) -> Label:
        var lb := UiTheme.label(text, size, col)
        lb.clip_text = true
        lb.custom_minimum_size = Vector2(UiTheme.px(W - 36), 0)
        _list.add_child(lb)
        return lb

    ## a piece on the left, what it gives on the right, signed and coloured
    func _piece(what: String, gives: String, col: Color) -> void:
        var h := HBoxContainer.new()
        h.add_theme_constant_override("separation", UiTheme.px(10))
        h.custom_minimum_size = Vector2(UiTheme.px(W - 36), 0)
        var a := UiTheme.label(what, 22, INK)
        a.clip_text = true
        a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        h.add_child(a)
        var b := UiTheme.label(gives, 22, col)
        b.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        h.add_child(b)
        _list.add_child(h)

    ## "+1 AC - 2 pace" from an item's own fields; red when a piece costs you something
    func _gives_of(it: Dictionary) -> Array:
        var bits: Array = []
        var worst := 0.0
        for f: Array in GIVES:
            if not it.has(f[0]):
                continue
            var v := float(it[f[0]])
            if is_zero_approx(v):
                continue
            worst = minf(worst, v)
            var n := "%.1f" % absf(v)
            if n.ends_with(".0"):
                n = n.substr(0, n.length() - 2)
            bits.append("%s%s %s" % ["+" if v > 0.0 else "-", n, String(f[1])])
        if bits.is_empty():
            return ["for the look", SOFT]
        return [" · ".join(bits), BAD if worst < 0.0 else GOOD]

    func _refresh() -> void:
        if _list == null:
            return
        var r := ro()
        if r == null or uid == "":
            return
        var h: Dictionary = r.get_hero(uid)
        if h.is_empty():
            visible = false
            return
        for c in _list.get_children():
            c.queue_free()

        # ---- who
        _list.add_child(UiTheme.title(String(h.get("name", "?")) + "'s Satchel", 28))
        var title := r.title_of(h)
        _line("%s %s, lv %d · %s%s" % [String(h.get("species", "")).capitalize(),
            String(h.get("class", "")).capitalize(), int(h.get("level", 1)), r.rank_of(h),
            ("  ·  " + title) if title != "" else ""], SOFT, 22)
        _line("%d gold in the purse" % int(h.get("gold", 0)), GOLD, 24)

        # ---- worn, and what each piece gives
        _list.add_child(UiTheme.title("Worn", 24))
        var wt := clampi(int(h.get("weapon", 0)), 0, Roster.WEAPONS.size() - 1)
        var w: Dictionary = Roster.WEAPONS[wt]
        var wd: Array = w.get("dice", [1, 4])
        _piece(r.weapon_name(h), "+%d atk · %dd%d" % [int(w.get("atk", 0)), int(wd[0]), int(wd[1])],
            GOOD if int(w.get("atk", 0)) > 0 else SOFT)
        var at := clampi(int(h.get("armour", 0)), 0, Roster.ARMOUR.size() - 1)
        var a: Dictionary = Roster.ARMOUR[at]
        _piece(String(a.get("name", "rags")), "+%d AC · +%d HP" % [int(a.get("ac", 0)), int(a.get("hp", 0))],
            GOOD if int(a.get("ac", 0)) > 0 else SOFT)
        var worn: Array = []
        for slot in (h.get("acc", {}) as Dictionary):
            var key := String(h["acc"][slot])
            var it := Roster.item(key)
            worn.append(key)
            var g := _gives_of(it)
            _piece("%s  (%s)" % [String(it.get("name", key)), String(slot)], String(g[0]), g[1])
        for kind in (h.get("cos", {}) as Dictionary):
            var ck := String(h["cos"][kind])
            if kind == "dye":
                _piece("dyed %s" % ck, "for the look", SOFT)
                continue
            worn.append(ck)
            _piece("%s  (%s)" % [String(Roster.item(ck).get("name", ck)), String(kind)], "for the look", SOFT)
        if (h.get("acc", {}) as Dictionary).is_empty() and (h.get("cos", {}) as Dictionary).is_empty():
            # L51 finish (U9): let the "nothing worn" hint wrap instead of clipping at the panel edge
            var none_lb := _line("No rings, no cloak, nothing on the hands.  !wear ring", SOFT, 22)
            none_lb.clip_text = false
            none_lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        # the numbers it adds up to - the Roster's own, never recomputed here
        _line("Altogether:  AC %d · %+d hit · %d HP · pace %.1f"
            % [r.armour_class(h), r.attack_bonus(h), int(r.max_hp(h)), r.speed(h)], INK, 22)

        # ---- what is running on them right now
        var m := _member()
        var states: Dictionary = Roster.potions().get("states", {})
        var any := false
        for bad in [true, false]:
            for k in states:
                var sp: Dictionary = states[k]
                if bool(sp.get("bad", false)) != bad:
                    continue
                if m.is_empty() or not bool(m["d"].has_st(m["m"], String(k))):
                    continue
                if not any:
                    any = true
                    _list.add_child(UiTheme.title("Running on them", 24))
                var secs := float((m["m"].get("st", {}) as Dictionary).get(String(k), 0.0))
                var tail := "  %ds" % int(ceilf(secs)) if secs > 0.0 else ""
                var lb := _line("%s%s — %s" % [String(sp.get("word", k)).capitalize(), tail,
                    String(sp.get("does", ""))], Color.html(String(sp.get("colour", "888888"))), 21)
                lb.clip_text = false
                lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        if not any and not m.is_empty():
            _list.add_child(UiTheme.title("Running on them", 24))
            _line("Nothing - no draught, no venom.", SOFT, 22)

        # ---- the satchel, and what the counter pays
        _list.add_child(UiTheme.title("In the satchel", 24))
        var bl := _line(r.brews_line(h), INK, 22)
        bl.clip_text = false
        bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        _line("%d flask%s of lamp oil" % [int(h.get("oil", 0)), "" if int(h.get("oil", 0)) == 1 else "s"], INK, 22)
        var spare: Array = []
        for key in (h.get("owned", []) as Array):
            if not worn.has(String(key)):
                spare.append(String(key))
        # packed gear is named with its sell price in "At the counter" below, so the
        # satchel line just counts it - no need to list each piece twice
        if not spare.is_empty():
            _line("%d spare piece%s of gear (sell-back below)" % [spare.size(),
                "" if spare.size() == 1 else "s"], SOFT, 22)

        _list.add_child(UiTheme.title("At the counter", 24))
        var purse := 0                       # everything, worn included
        for key in (h.get("owned", []) as Array):
            purse += int(floorf(float(Roster.item(String(key)).get("cost", 0)) * SELL_BACK))
        var listed := 0
        for key in spare:                    # the surplus a viewer would actually sell
            var v := int(floorf(float(Roster.item(key).get("cost", 0)) * SELL_BACK))
            if v <= 0:
                continue
            listed += 1
            _piece(String(Roster.item(key).get("name", key)), "%d gold" % v, GOLD)
        for bk in (h.get("brews", {}) as Dictionary):
            var pot := Roster.potion(String(bk))
            var n := int(h["brews"][bk])
            var v2 := int(floorf(float(pot.get("cost", 0)) * SELL_BACK)) * n
            purse += v2
            if v2 <= 0:
                continue
            listed += 1
            _piece("%d x %s" % [n, String(pot.get("name", bk))], "%d gold" % v2, GOLD)
        if listed == 0:
            _line("No spare gear or draughts to sell.", SOFT, 22)
        if purse > 0:
            _piece("Sell the lot (worn too)", "%d gold" % purse, GOLD)
        # Honest about the plumbing: !sell lives at the counter in roster.gd, which is
        # the laptop's file - not this worker's. The panel offers the command only once
        # that method exists; until then it shows the prices and says so (see summary).
        if r.has_method("sell"):
            _line("!sell <what>   - the counter pays the price beside it", SOFT, 20)
        else:
            _line("Prices shown; !sell opens the counter.", SOFT, 20)

    ## the delve party member this hero is in, if they are below ({} otherwise)
    func _member() -> Dictionary:
        var t := town()
        if t == null:
            return {}
        for d in t.find_children("*", "Delve", true, false):
            if not (d is Delve) or not d.has_method("has_st"):
                continue
            for mm: Dictionary in (d as Delve).party:
                if String(mm.get("uid", "")) == uid and float(mm.get("hp", 0.0)) > 0.0:
                    return {"d": d, "m": mm}
        return {}
