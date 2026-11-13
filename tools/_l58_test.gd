extends SceneTree
## L58 (WINDOWED): the on-stream Guild Roll has left the stream (the panel is removed
## from leaderboard_panel.gd); the L51 Satchel in that same file still works; and the
## standings data behind !guild / !ranks and the hub snapshot is intact. A bare boot
## has no Twitch config so the town does not spawn the panel - the test builds it, the
## way tools/_board_test.gd does. Saves two 1080p frames. COORDINATION 4: windowed.
const DIR := "C:/hd adventure/bellmire-hud/renders/cycles/20261113_u8_l58/"
var _t: Node3D
var _board: LeaderboardPanel
var _f := 0
var _fail := 0
var _uid := "local_mre"

func _ok(c: bool, what: String) -> void:
    print(("  ok  " if c else "  FAIL ") + what)
    if not c:
        _fail += 1

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _no_guild_label() -> bool:
    for cl in root.find_children("*", "CanvasLayer", true, false):
        for lb in (cl as Node).find_children("*", "Label", true, false):
            if String((lb as Label).text).findn("guild roll") != -1:
                return false
    return true

func _save(name: String) -> void:
    var img := root.get_texture().get_image()
    var e := img.save_png(DIR + name)
    print("SAVED %s err=%d size=%dx%d" % [DIR + name, e, img.get_width(), img.get_height()])

func _process(_d: float) -> bool:
    _f += 1
    if _f == 1:
        DisplayServer.window_set_size(Vector2i(1920, 1080))
    if _f == 30:
        _t.call("chat_line", _uid, "MrE", "!enlist ranger")
        _t.call("chat_line", "v2", "Pike", "!enlist knight")
        _t.call("chat_line", "v3", "Wren", "!enlist mage")
        _board = LeaderboardPanel.new()
        _t.add_child(_board)
        _board.setup(_t.roster)
    if _f == 90:
        _ok(_board != null, "the HUD LeaderboardPanel builds")
        _ok(_no_guild_label(), "no on-stream label reads 'The Guild Roll' (L58: the roll is gone)")
        _ok(_board.get("_panel") == null, "the Guild Roll on-stream panel field is gone")
        _ok(_board.get("_satchel") != null, "the L51 Satchel still exists in the same file")
        _save("u8_resting_1080.png")
    if _f == 95 and _board != null and is_instance_valid(_board._satchel):
        _board._satchel.raise_for(_uid)
        _board._satchel.pin(true)
    if _f == 150:
        var sat = _board._satchel if _board != null else null
        _ok(sat != null and is_instance_valid(sat), "satchel instance present")
        if sat != null and is_instance_valid(sat):
            _ok(sat.visible, "I folds the satchel up (visible on stream)")
            _ok(sat._list != null and sat._list.get_child_count() >= 4, "the satchel sheet has real content (%d rows)" % (sat._list.get_child_count() if sat._list else -1))
        var rows: Array = _t.roster.leaderboard("standing", 10) if _t.roster != null else []
        _ok(rows.size() >= 1, "roster.leaderboard('standing') still answers (!guild/!ranks + hub snapshot): %d rows" % rows.size())
        _save("u8_satchel_1080.png")
        print("L58_TEST %s - %d fails" % ["OK" if _fail == 0 else "FAIL", _fail])
        return true
    if _f > 400:
        print("L58_TEST FAIL - timeout, %d fails" % _fail)
        return true
    return false
