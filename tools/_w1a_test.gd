extends SceneTree
## W1a - the Supabase snapshot publisher. Offline: the off switch (no key file), the blob
## (town, guild roll, fallen, sheets, commands; plain JSON; no Twitch ids), its size and
## build time. Live (when user://supabase.json exists): one upsert from a frame that does
## not wait, the 2xx answer by signal, then a read back with the PUBLISHABLE key.
## Prints W1A_TEST OK.

const PUB_KEY := "sb_publishable_q2Kn3weLLeYYXGAiow_4vw_3serNQlc"

class FakeTown extends Node3D:
    var people: Array = []
    var roster: Roster
    var economy: Economy
    var feed: Array = []

var _fails := 0
var _live := false

func _check(name: String, ok: bool) -> void:
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
    var r := town.roster
    r.fresh("9001", "W1aTestKnight", "knight", "dwarf")
    r.fresh("9002", "W1aTestMage", "mage", "elf")
    r.fresh("9003", "W1aTestRogue", "rogue", "halfling")
    r.heroes["9001"]["deepest"] = 4
    r.heroes["9001"]["kills"] = 9
    r.kill("9003", "a test of the hub", 2, 3)

    # 1 off: no key file -> off, publish refuses, no HTTP node
    var off := SnapshotPublisher.new()
    off.key_file = "user://_w1a_no_such_file.json"
    root.add_child(off)
    off.setup(town)
    _check("1 no key file -> off, publish() refuses", not off.enabled and not off.publish() and off.get_node_or_null("SnapshotHTTP") == null)

    # 2 the blob
    var p := off.build_payload()
    _check("2 blob has every part", p.has_all(["v", "generated_at", "town", "guild_roll", "fallen", "heroes", "commands", "chronicle"]))
    _check("3 heroes = the living two, best standing first", p["heroes"].size() == 2 and p["heroes"][0]["name"] == "W1aTestKnight")
    var s0: Dictionary = p["heroes"][0]
    _check("4 sheet: stats, saves, weapon dice, armour, inventory, gear", s0.has_all(["stats", "saves", "ac", "hp", "to_hit", "weapon", "armour", "potions", "brews", "oil", "gold", "worn", "rank"]) and String(s0["weapon"]["dice"]) != "" and s0["stats"].size() == 6)
    _check("5 fallen = the rogue, with killer + epitaph", p["fallen"].size() == 1 and p["fallen"][0]["name"] == "W1aTestRogue" and p["fallen"][0]["killed_by"] == "a test of the hub")
    _check("6 guild roll lists all three (fallen too)", p["guild_roll"].size() == 3)
    _check("7 commands from data/commands.json", (p["commands"].get("order", []) as Array).size() > 10 and (p["commands"].get("commands", {}) as Dictionary).has("enlist"))
    _check("8 town block (level, souls, day)", (p["town"] as Dictionary).has_all(["level", "souls", "day", "name"]))
    var txt := JSON.stringify(p)
    _check("9 no Twitch ids in the blob", txt.find("9001") < 0 and txt.find("9002") < 0 and txt.find("\"id\"") < 0)
    var back: Variant = JSON.parse_string(txt)
    _check("10 plain JSON round trip", typeof(back) == TYPE_DICTIONARY and back["heroes"][1]["name"] == "W1aTestMage")
    # the Chronicle: newest first, typed, plain text, capped
    var lines := {
        "Aldric the Younger is killed by skeleton minion.": "death",
        "QuietArrow the ranger is cut down defending Bellmire by a bandit. Level 2, 6 kills. !reroll to rise again.": "death",
        "5 bandits are riding on the west road!": "raid",
        "The attack is driven off. The gates hold.": "raid",
        "Hero1 searches (Investigation 17) and turns up 25 gold on floor 2.": "loot",
        "The chief commissions a batch of gear.": "loot",
        "Floor 5 - a buried town, remade as a barrack room: 3 cave spiders, 1 risen bones.": "delve",
        "Petra Ashwood and 7 others descend into the scar.": "delve",
        "Bellmire grows into a market town.  (town level 3)": "town",
        "Sable Fenwick settles in Bellmire, looking for work.": "town",
        "Somewhere ahead, something counts its own bones out loud.": "lore",
        "Osric Hollow preaches on the chapel steps: the scar is a wound, not a door.": "lore",
        "BigAxe rolls a 20 - and the giant rat is gone.": "fight",
        "QuietArrow goes down and claws back up. (CON save 20)": "fight",
        "Nothing in particular happens.": "town",
    }
    town.feed.clear()
    off._chron.clear()          # a fresh feed for the test (the game's feed never shrinks)
    off._feed_seen = -1
    for ln in lines:
        town.feed.append(ln)
    town.feed.append("<script>alert(1)</script> [color=red]Bad[/color] line\u0007\nwith\tcontrols from 123456789")
    town.feed.append("x".repeat(500))
    var cp := off.build_payload()
    var ch: Array = cp["chronicle"]
    _check("18 chronicle present, one entry per line", ch.size() == lines.size() + 2)
    _check("19 newest first", ch.size() > 2 and String(ch[0]["s"]).begins_with("xxx") and String(ch[ch.size() - 1]["s"]) == lines.keys()[0])
    var typed_ok := true
    for e: Dictionary in ch:
        if String(e["s"]) in lines and lines[String(e["s"])] != String(e["t"]):
            typed_ok = false
            print("   typed %s as %s (want %s)" % [e["s"], e["t"], lines[String(e["s"])]])
    _check("20 each line typed by keyword", typed_ok)
    var shape_ok := true
    var ctl := RegEx.new()
    ctl.compile("[\\x00-\\x1F\\x7F]")
    var iso := RegEx.new()
    iso.compile("^\\d{4}-\\d\\d-\\d\\dT\\d\\d:\\d\\d:\\d\\dZ$")
    for e: Dictionary in ch:
        var es := String(e["s"])
        if e.keys().size() != 3 or not (String(e["t"]) in SnapshotPublisher.CHRON_TYPES) or iso.search(String(e["at"])) == null \
                or es.length() > SnapshotPublisher.LINE_MAX or es == "" or es.contains("<") or es.contains(">") \
                or es.contains("[color") or ctl.search(es) != null or es.contains("123456789"):
            shape_ok = false
            print("   bad entry ", e)
    print("W1A chronicle sample: ", ch[1])
    _check("21 every entry {t, s, at}: t allowed, ISO time, not HTML, no control chars, no ids, <= %d chars" % SnapshotPublisher.LINE_MAX, shape_ok)
    # more than the cap, then a later line: still newest first, still 50
    for i in 80:
        town.feed.append("Floor %d cleared." % (i + 1))
    town.feed.append("The attack is driven off. The gates hold.")
    var ch2: Array = off.build_payload()["chronicle"]
    var order_ok := ch2.size() == SnapshotPublisher.CHRON_MAX and String(ch2[0]["s"]) == "The attack is driven off. The gates hold." \
            and String(ch2[1]["s"]) == "Floor 80 cleared." and String(ch2[49]["s"]) == "Floor 32 cleared."
    for i in range(1, ch2.size()):
        if String(ch2[i - 1]["at"]) < String(ch2[i]["at"]):
            order_ok = false
    _check("22 capped at %d, newest first after more lines" % SnapshotPublisher.CHRON_MAX, order_ok)
    var cj := JSON.stringify(ch2)
    print("W1A chronicle: %d entries, %d bytes" % [ch2.size(), cj.length()])
    _check("23 chronicle under 16 KB", cj.length() < 16000)
    town.feed.clear()

    # 200 heroes: still small and quick
    for i in 200:
        r.fresh("x%d" % i, "Bulk%d" % i)
    var big := JSON.stringify(off.build_payload())
    print("W1A size 202 heroes: %d bytes, build %.2f ms" % [big.length(), off.last_build_ms])
    _check("11 202 heroes: under 400 KB and 25 ms to build", big.length() < 400000 and off.last_build_ms < 25.0)
    for i in 200:
        r.heroes.erase("x%d" % i)

    # live
    if FileAccess.file_exists(SnapshotPublisher.KEY_FILE):
        _live = true
        var pub := SnapshotPublisher.new()
        root.add_child(pub)
        pub.setup(town)
        _check("12 key file -> on, url is https", pub.enabled and pub.url.begins_with("https://"))
        var t0 := Time.get_ticks_usec()
        var started := pub.publish()
        var call_ms := (Time.get_ticks_usec() - t0) / 1000.0
        print("W1A publish() call took %.2f ms" % call_ms)
        _check("13 publish() starts and returns in under 15 ms (no waiting on the net)", started and call_ms < 15.0)
        _check("14 a second publish while one is in flight is skipped", not pub.publish())
        var tw := create_timer(30.0)
        var got := [false, 0]
        pub.published.connect(func(c): got[0] = true; got[1] = c)
        while not got[0] and tw.time_left > 0.0:
            await process_frame
        print("W1A upsert answer: %d (%s)" % [got[1], pub.last_note])
        _check("15 upsert answered 2xx", got[0] and int(got[1]) >= 200 and int(got[1]) < 300)
        # read back as the hub will
        var h := HTTPRequest.new()
        h.use_threads = true
        h.timeout = 20.0
        root.add_child(h)
        h.request(pub.url + "/rest/v1/snapshot?select=payload,updated_at&id=eq.1",
            PackedStringArray(["apikey: " + PUB_KEY, "Authorization: Bearer " + PUB_KEY, "User-Agent: BellmireHD/1.0"]),
            HTTPClient.METHOD_GET)
        var res: Array = await h.request_completed
        var body := (res[3] as PackedByteArray).get_string_from_utf8()
        var rows: Variant = JSON.parse_string(body)
        var ok: bool = typeof(rows) == TYPE_ARRAY and rows.size() == 1
        var names := []
        if ok:
            for hs in rows[0]["payload"]["heroes"]:
                names.append(hs["name"])
            print("W1A read back: updated_at %s, heroes %s" % [rows[0]["updated_at"], str(names)])
        _check("16 read back with the publishable key: our row", ok and names.has("W1aTestKnight") and rows[0]["payload"]["fallen"][0]["name"] == "W1aTestRogue")
        # a write with the publishable key must be refused (RLS)
        var w := HTTPRequest.new()
        root.add_child(w)
        w.request(pub.url + SnapshotPublisher.TABLE_PATH,
            PackedStringArray(["apikey: " + PUB_KEY, "Authorization: Bearer " + PUB_KEY, "Content-Type: application/json",
                "Prefer: resolution=merge-duplicates", "User-Agent: BellmireHD/1.0"]),
            HTTPClient.METHOD_POST, JSON.stringify([{"id": 1, "payload": {"bad": true}}]))
        var wr: Array = await w.request_completed
        print("W1A publishable-key write -> %d" % int(wr[1]))
        _check("17 a write with the publishable key is refused", int(wr[1]) >= 400)
    else:
        print("W1A live part skipped: no %s" % SnapshotPublisher.KEY_FILE)

    if _fails == 0:
        print("W1A_TEST OK%s" % ("" if _live else " (offline only)"))
    else:
        print("W1A_TEST FAILED %d" % _fails)
    quit()
