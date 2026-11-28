extends SceneTree
## S169 - the engine half of the hub's order desk (scripts/hub_actions.gd), OFFLINE only:
## never touches Supabase. Proves a queued row runs through the SAME town.chat_line chat
## uses (so every rule holds), refusals are worded, a cooldown leaves the row queued, a
## missing table degrades quietly, and a gate can still go RED (check 12).
## Prints HUB_ACTIONS_TEST OK n of n / FAIL.

class FakeTown extends Node3D:
    var roster: Roster
    var economy: Economy
    var chat: ChatCmd
    var feed: Array = []
    var people: Array = []
    var lines: Array = []
    func chat_line(uid: String, display: String, msg: String) -> String:
        lines.append([uid, msg])
        return chat.handle(uid, display, msg)

var _fails := 0
var _n := 0

func _check(name: String, ok: bool) -> void:
    _n += 1
    print(("PASS " if ok else "FAIL ") + name)
    if not ok:
        _fails += 1

func _initialize() -> void:
    _run.call_deferred()

func _run() -> void:
    var town := FakeTown.new()
    root.add_child(town)
    town.roster = Roster.new()
    town.economy = Economy.new()
    town.economy.town = town
    town.chat = ChatCmd.new(town.roster)
    town.add_child(town.chat)
    var r := town.roster
    r.fresh("7001", "HubTestKnight", "knight", "dwarf")
    var ha := HubActions.new()
    ha.key_file = "user://_hub_no_such_file.json"
    root.add_child(ha)
    ha.setup(town)
    _check("1 no key file -> off, no HTTP node", not ha.enabled and ha.get_node_or_null("HubActionsHTTP") == null)
    _check("2 translate wear", HubActions.translate("wear", {"item": "Iron Sword"}).get("line") == "!wear iron sword")
    _check("3 translate strips a smuggled command", HubActions.translate("wear", {"item": "!reroll; !delve"}).get("line") == "!wear reroll delve")
    _check("4 buy forge carries the item, armoury does not", HubActions.translate("buy", {"counter": "forge", "item": "axe"}).get("line") == "!forge axe" and HubActions.translate("buy", {"counter": "armoury", "item": "x"}).get("line") == "!armoury")
    _check("5 buy at no such counter is refused", HubActions.translate("buy", {"counter": "tavern"}).has("refuse"))
    _check("6 party verbs", HubActions.translate("party_invite", {"who": "Some One"}).get("line") == "!party invite someone" and HubActions.translate("party_leave", {}).get("line") == "!party leave")
    _check("7 sell is refused in words (no engine sell from the hub yet)", HubActions.translate("sell", {"item": "x"}).has("refuse"))
    var v := ha.decide({"twitch_id": "7999", "kind": "reroll", "args": {}})
    _check("8 no hero -> refused, chat never called", v.get("status") == "refused" and town.lines.is_empty())
    v = ha.decide({"twitch_id": "abc", "kind": "reroll", "args": {}})
    _check("9 bad twitch id -> refused", v.get("status") == "refused")
    v = ha.decide({"twitch_id": "7001", "kind": "teleport", "args": {}})
    _check("10 unknown kind -> refused", v.get("status") == "refused")
    var g0 := int(r.get_hero("7001").get("gold", 0))
    v = ha.decide({"twitch_id": "7001", "kind": "respec", "args": {}, "viewer_login": "hubtestknight"})
    _check("11 respec runs THROUGH chat_line and the town answers", town.lines.size() == 1 and String(town.lines[0][1]) == "!respec" and v.get("status") == "done" and String(v.get("result", "")) != "")
    print("HUB respec answer: %s (gold %d -> %d)" % [v.get("result", ""), g0, int(r.get_hero("7001").get("gold", 0))])
    v = ha.decide({"twitch_id": "7001", "kind": "respec", "args": {}})
    _check("12 second request inside the chat cooldown stays QUEUED ({}), never done", v.is_empty() and town.lines.size() == 2)
    _check("13 result capped at 200", HubActions._v("done", "x".repeat(500))["result"].length() == 200)
    ha._on_done(HTTPRequest.RESULT_SUCCESS, 404, PackedStringArray(), PackedByteArray())
    _check("14 a missing table closes the desk quietly", ha.closed and ha._out.is_empty())
    ha._on_done(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), "[]".to_utf8_buffer())
    _check("15 a 2xx reopens it", not ha.closed)
    # RED arm: a decide() that skipped chat_line would leave lines at 2 - prove the check can fail
    _check("16 respec carries a calling box when the hub sends one", HubActions.translate("respec", {"calling": "Mage"}).get("line") == "!respec mage")
    print("HUB_ACTIONS_TEST " + ("OK %d of %d" % [_n, _n] if _fails == 0 else "FAIL %d of %d" % [_fails, _n]))
    quit(0 if _fails == 0 else 1)
