extends SceneTree
## D60 - the Chronicle dated by the town's own calendar, and who/kind on a line.
## Loads the REAL Bellmire (tools never start the publisher - "--script"), lets it run,
## then drives real raisers (a raid, a disaster, the end of a day, a festival, a hero's
## catch through town.tag_feed) and reads the publisher's chronicle as the hub will:
##  - every row carries `day` = economy.day (the town's own day, an int)
##  - `kind` / `who` ONLY on tagged lines; cleanly ABSENT (not "" / []) on untagged lines
##  - `who` W1a-clean, every name <= 25, at most WHO_MAX
##  - every v2/v3 row field (t, s, at) still there and unchanged in meaning
##  - payload KB before (fields stripped) and after, and the delta
## Writes renders/cycles/d60/chron_readback.json. Prints D60_CHRON OK.
var _t: Node3D
var _f := 0
var _go := false
var _fails := 0

func _check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		_fails += 1

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
	var e: Economy = _t.get("economy")
	var pub := SnapshotPublisher.new()
	pub.key_file = "user://_d60_no_such_file.json"
	pub.mem_file = "user://_d60_mem.json"
	root.add_child(pub)
	pub.setup(_t)
	_check("0 publisher off without a key (no network)", not pub.enabled)
	pub.scan_feed()                          # stamp everything raised during start-up
	var day0 := int(e.day)

	# real raisers
	var rd = _t.get("raids")
	if rd and rd.has_method("raid"):
		rd.set("force_level", 4)           # a hamlet raises no raid; the test hook lets one come
		rd.call("raid", "d60 test")
	e.trigger_disaster("drought")
	e.call("_end_of_day")
	_t.set("_fest_t", 0.0)
	_t.call("_festival_pass", 0.016)
	var feed: Array = _t.get("feed")
	feed.append("D60Hero lands a Silver Trout (common)!")
	_t.call("tag_feed", "find", ["D60Hero", "Bad\u0007Name<b>ThatIsFarTooLongForTheHubCap"])
	feed.append("Something stirs in the valley tonight.")   # untagged, on purpose
	pub.scan_feed()

	var p := pub.build_payload()
	var ch: Array = p["chronicle"]
	var tagged := 0
	var untagged := 0
	var all_day := true
	var clean := true
	var absent_ok := true
	var kinds := {}
	for row: Dictionary in ch:
		if not (row.has("day") and typeof(row["day"]) == TYPE_INT and int(row["day"]) >= 1):
			all_day = false
		if not row.has_all(["t", "s", "at"]):
			clean = false
		if row.has("kind"):
			tagged += 1
			kinds[row["kind"]] = int(kinds.get(row["kind"], 0)) + 1
		else:
			untagged += 1
			if row.has("who"):
				absent_ok = false
		if row.has("kind") and String(row["kind"]) == "":
			absent_ok = false
		if row.has("who"):
			var w: Array = row["who"]
			if w.is_empty() or w.size() > SnapshotPublisher.WHO_MAX:
				absent_ok = false
			for nm in w:
				var s := String(nm)
				if s == "" or s.length() > SnapshotPublisher.NAME_MAX or s.contains("<") or s.contains("\u0007"):
					clean = false
	print("D60 rows %d  tagged %d  untagged %d  kinds %s  day0 %d now %d" % [ch.size(), tagged, untagged, kinds, day0, e.day])
	_check("1 every row carries the town's own day (int >= 1)", all_day and ch.size() > 0)
	_check("2 v2/v3 row fields t/s/at all still there", ch.all(func(r): return (r as Dictionary).has_all(["t", "s", "at"])))
	var want := ["raid", "disaster", "day", "find"]
	if not e.is_night():
		want.append("festival")         # the festival only gathers by day (town._festival_pass)
	_check("3 real raisers tagged: %s" % ", ".join(want), kinds.has_all(want))
	_check("4 untagged lines carry no kind and no who; no empty field anywhere", absent_ok and untagged > 0)
	var catch_row := {}
	var stir_row := {}
	var day_row := {}
	for row: Dictionary in ch:
		if String(row["s"]).begins_with("D60Hero lands"):
			catch_row = row
		elif String(row["s"]).begins_with("Something stirs"):
			stir_row = row
		elif String(row.get("kind", "")) == "day" and day_row.is_empty():
			day_row = row
	print("catch row: ", catch_row)
	print("untagged row: ", stir_row)
	print("day row: ", day_row)
	_check("5 the catch names its hero, W1a-clean and capped", catch_row.has("who") and String(catch_row["who"][0]) == "D60Hero"
		and (catch_row["who"] as Array).size() == 2 and String(catch_row["who"][1]).length() <= 25
		and not String(catch_row["who"][1]).contains("<") and clean)
	_check("6 the untagged line: day yes, kind/who absent", stir_row.has("day") and not stir_row.has("kind") and not stir_row.has("who"))
	_check("7 the 'Day N begins' row is dated with the same N it announces",
		not day_row.is_empty() and String(day_row["s"]).begins_with("Day %d " % int(day_row["day"])))
	_check("8 payload v unchanged (PAYLOAD_V)", int(p["v"]) == SnapshotPublisher.PAYLOAD_V)

	# size, with the new fields and without
	var after := JSON.stringify(p).length()
	var bare: Array = []
	for row: Dictionary in ch:
		var b := row.duplicate()
		b.erase("day"); b.erase("kind"); b.erase("who")
		bare.append(b)
	var p0 := p.duplicate()
	p0["chronicle"] = bare
	var before := JSON.stringify(p0).length()
	print("D60 payload before %d bytes (%.1f KB), after %d bytes (%.1f KB), delta %d bytes over %d rows (%.1f B/row)"
		% [before, before / 1024.0, after, after / 1024.0, after - before, ch.size(), float(after - before) / maxf(1, ch.size())])
	# worst case: a full CHRON_MAX ring, every row with day, kind and WHO_MAX 25-char names
	var worst := CHRON_WORST()
	print("D60 worst-case chronicle delta (50 rows, 4 x 25-char names each): %d bytes (%.1f KB)" % [worst, worst / 1024.0])
	_check("9 worst-case delta under 12 KB (D59a 244 KB + this stays far under the 400 KB bar)", worst < 12288)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://renders/cycles/d60"))
	var f := FileAccess.open("res://renders/cycles/d60/chron_readback.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"chronicle": ch, "bytes_before": before, "bytes_after": after}, "  "))
	print("D60_CHRON OK" if _fails == 0 else "D60_CHRON FAIL (%d)" % _fails)
	quit(0 if _fails == 0 else 1)

func CHRON_WORST() -> int:
	var nm := "X".repeat(25)
	var row := {"day": 9999, "kind": "disaster", "who": [nm, nm, nm, nm]}
	return (JSON.stringify(row).length() - 2 + 1) * SnapshotPublisher.CHRON_MAX
