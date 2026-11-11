extends SceneTree
## Twitch chat phase 1 - offline test (no network). Prints PASS/FAIL per case.

class FakeTown extends Node:
    var calls: Array = []
    func chat_line(uid: String, display: String, text: String) -> String:
        calls.append([uid, display, text])
        return ""

var _fails := 0

func _check(name: String, ok: bool) -> void:
    print(("PASS " if ok else "FAIL ") + name)
    if not ok:
        _fails += 1

func _initialize() -> void:
    var town := FakeTown.new()
    var tc := TwitchChat.new()
    tc.town = town
    tc.enabled = false                      # never opens a socket
    var msg := "@badge-info=;badges=subscriber/6;display-name=CoffeeCat320;user-id=123456 :coffeecat320!coffeecat320@coffeecat320.tmi.twitch.tv PRIVMSG #jestsayin96 :!enlist knight\r\n"

    # 1) tagged command reaches chat_line with uid, display, text
    tc._feed(msg)
    tc._drain()
    _check("1 command -> chat_line", town.calls.size() == 1 and town.calls[0] == ["123456", "CoffeeCat320", "!enlist knight"])

    # 2) PING -> PONG
    tc._feed("PING :tmi.twitch.tv\r\n")
    _check("2 ping -> pong", tc.sent.has("PONG :tmi.twitch.tv"))

    # 3) chat without "!" ignored
    tc._feed("@display-name=Bob;user-id=777 :bob!bob@bob.tmi.twitch.tv PRIVMSG #jestsayin96 :hello chat\r\n")
    tc._drain()
    _check("3 plain chat ignored", town.calls.size() == 1)

    # 4) bot ignored
    tc._feed("@display-name=StreamElements;user-id=100135110 :streamelements!streamelements@streamelements.tmi.twitch.tv PRIVMSG #jestsayin96 :!delve\r\n")
    tc._drain()
    _check("4 bot ignored", town.calls.size() == 1)

    # 5) same user again inside 3 s ignored
    tc._feed(msg)
    tc._drain()
    _check("5 cooldown", town.calls.size() == 1)

    # 6) a line split across two packets still parses
    var t2 := "@display-name=Ann;user-id=555 :ann!ann@ann.tmi.twitch.tv PRIVMSG #jestsayin96 :!fish\r\n"
    tc._feed(t2.substr(0, 30))
    tc._feed(t2.substr(30))
    tc._drain()
    _check("6 split packet", town.calls.size() == 2 and town.calls[1][2] == "!fish")

    # 7) at most 4 per frame
    for i in range(6):
        tc._feed("@display-name=U%d;user-id=9%d :u%d!u@u PRIVMSG #jestsayin96 :!delve\r\n" % [i, i, i])
    tc._drain()
    _check("7 four per frame", town.calls.size() == 6)
    tc._drain()
    _check("7b rest next frame", town.calls.size() == 8)

    print("TWITCH_PARSE ", "OK" if _fails == 0 else "%d FAILED" % _fails)
    tc.free()
    town.free()
    quit(1 if _fails > 0 else 0)
