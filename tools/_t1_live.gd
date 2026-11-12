extends SceneTree
## T1 - Twitch phase 2, LIVE check on CruzaderPC (needs the two tokens in user://).
## Validates both tokens, looks up Bellmire's rewards, opens the EventSub socket and
## subscribes, then FORCES an expiry of both tokens and proves the refresh path:
## new tokens from Twitch, saved to user://, read back, validated. Chat is a dry run -
## nothing is posted. Prints T1_LIVE OK.

var ev: TwitchEventSub
var _t0 := 0.0
var _stage := 0
var _fails := 0
var _old := {}

func _check(name: String, ok: bool) -> void:
    print(("PASS " if ok else "FAIL ") + name)
    if not ok:
        _fails += 1

func _initialize() -> void:
    ev = TwitchEventSub.new()
    ev.dry_run_chat = true
    root.add_child(ev)
    ev.call_deferred("setup", null)       # like the town: in the tree before the first request
    _t0 = Time.get_ticks_msec() / 1000.0

func _el() -> float:
    return Time.get_ticks_msec() / 1000.0 - _t0

func _process(_d: float) -> bool:
    if _stage == 0 and (ev.subs_ok.size() + ev.subs_failed.size() >= 6 or _el() > 40.0):
        _stage = 1
        _check("1 broadcaster token valid", ev.seconds_left("broadcaster") > 0.0)
        _check("2 bot token valid", ev.seconds_left("bot") > 0.0)
        _check("3 EventSub welcome", ev.session_id != "")
        _check("4 all six subscriptions", ev.subs_ok.size() == 6)
        _check("4b no refresh before the forced expiry", ev.refreshes["broadcaster"] == 0 and ev.refreshes["bot"] == 0)
        print("T1_LIVE subs_failed=%s" % [ev.subs_failed])
        print("T1_LIVE rewards_ok=%s ids=%s note=%s" % [ev.rewards_ok, ev.reward_ids, ev.rewards_note])
        for who in ["broadcaster", "bot"]:
            _old[who] = String(ev.tokens[who].get("access_token", ""))
            _old[who + "_n"] = ev.refreshes[who]
            ev.force_expiry(who)
        print("T1_LIVE forced expiry of both tokens at %.1f s" % _el())
    if _stage == 1 and ((ev.refreshes["broadcaster"] > _old["broadcaster_n"] and ev.refreshes["bot"] > _old["bot_n"]) or _el() > 70.0):
        _stage = 2
        _check("5 broadcaster refreshed", ev.refreshes["broadcaster"] == _old["broadcaster_n"] + 1 and ev.seconds_left("broadcaster") > 3000.0)
        _check("6 bot refreshed", ev.refreshes["bot"] == _old["bot_n"] + 1 and ev.seconds_left("bot") > 3000.0)
        for who in ["broadcaster", "bot"]:
            var path := ev._token_path(who)
            var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
            _check("7 %s new token saved and read back" % who, typeof(j) == TYPE_DICTIONARY
                and String(j["access_token"]) == String(ev.tokens[who]["access_token"])
                and String(j["access_token"]) != String(_old[who]) and j.has("obtained_at"))
        ev._validate("broadcaster")
        ev._validate("bot")
    if _stage == 2 and _el() > 85.0:
        _stage = 3
        _check("8 socket still open after refresh", ev._ws.get_ready_state() == WebSocketPeer.STATE_OPEN and ev.session_id != "")
        _check("9 keepalives arriving", ev._quiet < ev._keepalive + 1.0)
        ev._ws.close()
        print("T1_LIVE ", "OK" if _fails == 0 else "%d FAILED" % _fails)
        quit(1 if _fails > 0 else 0)
    return false
