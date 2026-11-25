extends SceneTree
## S125 - the purchase-verification receipt ledger (supervisor 23:54 directive §3), offline.
## Drives REAL channel-point redemption events through TwitchEventSub.handle_event against a
## fake town whose actions can be made to fail, then advances the ledger clock by hand.
## Verdict: S125_RECEIPTS OK (n checks) / S125_RECEIPTS n FAILED (n checks).
## RED-PROOF: run with `-- --redproof` and the ledger is emptied after every redemption (a
## ledger that verifies nothing). The gate MUST then print FAILED - it must not go quiet.

class FakeRoster extends Node:
    var heroes := {}
    func get_hero(uid: String) -> Dictionary:
        return heroes.get(uid, {})

class FakeChat extends Node:
    signal twitch_reply(user_login: String, text: String)
    var away := {}
    var delve_queue: Array = []

class FakeBody extends Node:
    var errand := ""

class FakeTown extends Node:
    var roster := FakeRoster.new()
    var chat := FakeChat.new()
    var heroes := {}
    var feed: Array = []
    var _at_mouth: Array = []
    var delve = null
    var fail_delve := 0          # how many _on_delve calls silently do nothing
    var fail_fish := 0
    var delve_calls := 0
    var fish_calls := 0
    func _on_delve(uid: String) -> void:
        delve_calls += 1
        if fail_delve > 0:
            fail_delve -= 1
            return
        chat.away[uid] = "on the road to the scar"
        if not chat.delve_queue.has(uid):
            chat.delve_queue.append(uid)
    func _on_fish(uid: String) -> void:
        fish_calls += 1
        if fail_fish > 0:
            fail_fish -= 1
            return
        (heroes[uid] as FakeBody).errand = "fish"
    func _on_rally(uid: String) -> void:
        roster.get_hero(uid)["rally_secs"] = 90.0
    func spotlight(_uid: String, _lane: String, _s: float, _r: String) -> void:
        pass

var _fails := 0
var _checks := 0
var _red := false

func _check(name: String, ok: bool) -> void:
    _checks += 1
    print(("PASS " if ok else "FAIL ") + name)
    if not ok:
        _fails += 1

func _redeem(es: TwitchEventSub, uid: String, login: String, key: String, n: int) -> void:
    es.handle_event("channel.channel_points_custom_reward_redemption.add", {
        "id": "test-redemption-%d" % n, "user_id": uid, "user_name": login, "user_login": login,
        "reward": {"id": "rid-" + key, "title": TwitchEventSub.REWARDS[key]["title"],
            "cost": TwitchEventSub.REWARDS[key]["cost"]}})
    if _red:
        es._receipts.clear()     # RED-PROOF: a ledger that holds nothing verifies nothing

func _initialize() -> void:
    _red = OS.get_cmdline_user_args().has("--redproof")
    var town := FakeTown.new()
    for u in ["u1", "u2", "u3", "u4", "u5"]:
        town.roster.heroes[u] = {"name": "Hero " + u, "potions": 0, "alive": true}
        var b := FakeBody.new()
        town.heroes[u] = b
        town.add_child(b)
    var es := TwitchEventSub.new()
    es.offline = true
    es.dry_run_chat = true
    es.town = town
    for k in TwitchEventSub.REWARDS:
        es.reward_ids[k] = "rid-" + k
    root.add_child(es)

    # 1) a patch that works: receipt opened, settled, verified on the potion count
    _redeem(es, "u1", "ann", "patch", 1)
    _check("1a receipt written for the patch", _red or (es._receipts.size() == 1 and String(es._receipts[0]["action"]) == "patch"
            and int(es._receipts[0]["expected_state"]["potions"]) == 1 and String(es._receipts[0]["redemption_id"]) == "test-redemption-1"))
    _check("1b receipt settled after the settle call", _red or bool(es._receipts[0]["settled"]))
    es._tick_receipts(3.0)
    _check("1c not checked before the window", es.receipts_verified == 0)
    es._tick_receipts(6.0)
    _check("1d patch verified off the hero's real potions", es.receipts_verified == 1 and es._receipts.is_empty())
    _check("1e exactly one potion (no retry on a match)", int(town.roster.heroes["u1"]["potions"]) == 1 and es.receipts_retried == 0)

    # 2) a delve whose action silently fails ONCE: the retry fires and then verifies
    town.fail_delve = 1
    _redeem(es, "u2", "bob", "delve", 2)
    es._tick_receipts(9.0)
    _check("2a miss -> retry fired once", es.receipts_retried == 1 and town.delve_calls == 2)
    _check("2b hero state not yet matched before the retry", town.chat.away.has("u2"))
    es._tick_receipts(9.0)
    _check("2c retry took -> verified, viewer NOT told", es.receipts_verified == 2 and es._chat_q.is_empty() and es.receipts_failed.is_empty())

    # 3) a fishing trip that fails BOTH times: the viewer is told, the failure is logged, NOT refunded
    town.fail_fish = 2
    _redeem(es, "u3", "cat", "fish", 3)
    es._tick_receipts(9.0)
    _check("3a first miss retried", es.receipts_retried == 2 and town.fish_calls == 2)
    es._tick_receipts(9.0)
    var told := false
    for q in es._chat_q:
        if String(q[0]) == "cat" and String(q[1]) == "your fishing trip didn't go through - the builders have been told. Your points are safe.":
            told = true
    _check("3b failed retry -> viewer told in chat", told)
    _check("3c failure logged with its redemption id", es.receipts_failed.size() == 1
            and String(es.receipts_failed[0]["redemption_id"]) == "test-redemption-3" and bool(es.receipts_failed[0]["failed"]))
    _check("3d ledger pruned (in memory, nothing left open)", es._receipts.is_empty())
    _check("3e retried ONCE only, never a third time", town.fish_calls == 2)

    # 4) rally and spotlight verify off real state
    _redeem(es, "u4", "dan", "rally", 4)
    _redeem(es, "u5", "eve", "spotlight", 5)
    es._tick_receipts(9.0)
    _check("4 rally + spotlight verified", es.receipts_verified == 4 and es._receipts.is_empty())

    # 5) no hero -> CANCELED path writes no receipt (nothing was bought)
    _redeem(es, "nobody", "fay", "patch", 6)
    _check("5 no-hero redemption writes no receipt", es._receipts.is_empty())

    if _checks < 15:
        _fails += 1
        print("FAIL only %d checks ran - below the floor of 15" % _checks)
    print("S125_RECEIPTS ", ("OK (%d checks)" % _checks) if _fails == 0 else ("%d FAILED (%d checks)" % [_fails, _checks]))
    es.queue_free()
    town.free()
    quit(1 if _fails > 0 else 0)
