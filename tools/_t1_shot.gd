extends SceneTree
## T1 render: the town with TwitchEventSub fed recorded EventSub frames (offline - no
## socket): cheers, a sub, a resub, a gift bomb, a follow, our reward and fightoverlay's.
## The Chronicle must show the bits/sub/follow lines and nothing for fightoverlay's
## reward. Windowed. -> renders/cycles/20261112_t1/
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _dir := ""
var _ev: TwitchEventSub
var _n := 0

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _dir = ProjectSettings.globalize_path("res://renders/cycles/20261112_t1/")
    DirAccess.make_dir_recursive_absolute(_dir)

func _frame(kind: String, e: Dictionary) -> String:
    _n += 1
    return JSON.stringify({"metadata": {"message_id": "shot%d" % _n, "message_type": "notification"},
        "payload": {"subscription": {"type": kind}, "event": e}})

func _u(id: String, nm: String, more: Dictionary) -> Dictionary:
    var d := {"user_id": id, "user_login": nm.to_lower(), "user_name": nm}
    d.merge(more)
    return d

func _process(_d: float) -> bool:
    _f += 1
    if _f == 2:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        _cam.fov = 55.0
        _t.get("raids").set("_raid_t", 99999.0)
        (_t.get("economy") as Economy).clock = 11.0 / 24.0
    if _f == 120:
        _t.call("chat_line", "7001", "BigAxe", "!enlist knight dwarf")
        _t.call("chat_line", "7002", "MossyMage", "!enlist mage elf")
        _t.call("chat_line", "7003", "Corvin", "!enlist ranger")
        _ev = TwitchEventSub.new()
        _ev.offline = true
        _ev.dry_run_chat = true
        _t.add_child(_ev)
        _ev.setup(_t)
        _ev.reward_ids = {"spotlight": "bm-reward-1"}
    if _f == 200:
        _ev.on_message(_frame("channel.cheer", _u("7001", "BigAxe", {"bits": 500, "is_anonymous": false})))
        _ev.on_message(_frame("channel.subscribe", _u("7002", "MossyMage", {"is_gift": false, "tier": "1000"})))
        _ev.on_message(_frame("channel.subscription.message", _u("7003", "Corvin", {"cumulative_months": 7})))
        _ev.on_message(_frame("channel.subscription.gift", _u("7001", "BigAxe", {"total": 3, "is_anonymous": false})))
        _ev.on_message(_frame("channel.follow", _u("7009", "NewFriend", {})))
        _ev.on_message(_frame("channel.channel_points_custom_reward_redemption.add",
            _u("7002", "MossyMage", {"id": "r1", "reward": {"id": "fightoverlay-1", "title": "Summon the Boss"}})))
        _ev.on_message(_frame("channel.channel_points_custom_reward_redemption.add",
            _u("7003", "Corvin", {"id": "r2", "reward": {"id": "bm-reward-1", "title": "Spotlight my hero"}})))
        print("T1_SHOT spotlights: ", _ev.spotlights)
    if _f == 380:
        var m: Vector3 = _t.get("_market_pos")
        m.y = _t.height_at(m.x, m.z)
        _cam.global_position = m + Vector3(-10, 9, -12)
        _cam.look_at(m, Vector3.UP)
    if _f == 400:
        root.get_texture().get_image().save_png(_dir + "chronicle_events.png")
        print("SAVED chronicle_events")
        var fd: Array = _t.get("feed")
        print("T1_SHOT feed tail: ", fd.slice(maxi(0, fd.size() - 8)))
        print("T1_SHOTS DONE")
        return true
    return false
