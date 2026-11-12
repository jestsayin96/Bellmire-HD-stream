extends SceneTree
## W1a in the real town: load Bellmire (tools do not start the publisher - "--script"),
## let it run, then publish the town's own snapshot once and read it back as the hub
## will. Writes renders/cycles/20261112_w1a/snapshot_readback.json. Prints W1A_TOWN OK.
const PUB_KEY := "sb_publishable_q2Kn3weLLeYYXGAiow_4vw_3serNQlc"
var _t: Node3D
var _f := 0
var _go := false

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _process(_d: float) -> bool:
    _f += 1
    if _f == 600 and not _go:
        _go = true
        _run.call_deferred()
    return false

func _run() -> void:
    # tools never load the real save (persist is off under --script); READ it here so the
    # hub gets the real heroes - nothing is written back (save_all only runs when persist)
    var r: Roster = _t.get("roster")
    if r and FileAccess.file_exists(Roster.SAVE_PATH):
        r.load_all()
    var pub := SnapshotPublisher.new()
    root.add_child(pub)
    pub.setup(_t)
    var fr := []
    var t0 := Time.get_ticks_usec()
    var ok := pub.publish()
    print("W1A_TOWN publish() %.2f ms, build %.2f ms, %d bytes" % [(Time.get_ticks_usec() - t0) / 1000.0, pub.last_build_ms, pub.last_bytes])
    var got := [false, 0]
    pub.published.connect(func(c): got[0] = true; got[1] = c)
    var worst := 0.0
    var last := Time.get_ticks_usec()
    var tw := create_timer(30.0)
    while not got[0] and tw.time_left > 0.0:
        await process_frame
        var now := Time.get_ticks_usec()
        worst = maxf(worst, (now - last) / 1000.0)
        last = now
    print("W1A_TOWN answer %d (%s); worst frame while in flight %.1f ms" % [got[1], pub.last_note, worst])
    var h := HTTPRequest.new()
    h.use_threads = true
    root.add_child(h)
    h.request(pub.url + "/rest/v1/snapshot?select=payload,updated_at&id=eq.1",
        PackedStringArray(["apikey: " + PUB_KEY, "Authorization: Bearer " + PUB_KEY, "User-Agent: BellmireHD/1.0"]), HTTPClient.METHOD_GET)
    var res: Array = await h.request_completed
    var body := (res[3] as PackedByteArray).get_string_from_utf8()
    var rows: Variant = JSON.parse_string(body)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://renders/cycles/20261112_w1a"))
    var f := FileAccess.open("res://renders/cycles/20261112_w1a/snapshot_readback.json", FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify(rows, "  "))
        f.close()
    var good: bool = ok and int(got[1]) >= 200 and int(got[1]) < 300 and typeof(rows) == TYPE_ARRAY and rows.size() == 1
    if good:
        var p: Dictionary = rows[0]["payload"]
        print("W1A_TOWN read back: town %s, heroes %d, roll %d, fallen %d, commands %d" % [str(p["town"]), p["heroes"].size(), p["guild_roll"].size(), p["fallen"].size(), (p["commands"]["order"] as Array).size()])
        good = int(p["town"].get("level", 0)) >= 1 and (p["commands"]["order"] as Array).size() > 10
    print("W1A_TOWN OK" if good else "W1A_TOWN FAILED")
    quit()
