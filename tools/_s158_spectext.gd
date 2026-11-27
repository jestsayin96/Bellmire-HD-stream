extends SceneTree
## S158: every SPECS path reads its blurb out of data/lore_lines.json spec_text (C-237), none is empty,
## each equals the data string, and no SPECS row still carries a placeholder "blurb" of its own.
func _initialize() -> void:
	var f := FileAccess.open("res://data/lore_lines.json", FileAccess.READ)
	var st: Dictionary = (JSON.parse_string(f.get_as_text()) as Dictionary)["spec_text"]
	var n := 0
	var bad: Array = []
	for cls: String in Roster.SPECS:
		for p: String in Roster.SPECS[cls]:
			n += 1
			var want := String(((st.get(cls, {}) as Dictionary).get(p, {}) as Dictionary).get("blurb", ""))
			var got := Roster.spec_blurb(cls, p)
			if OS.get_environment("S158_RED") == "1":
				want = "the old placeholder"
			if got == "" or got != want or (Roster.SPECS[cls][p] as Dictionary).has("blurb"):
				bad.append("%s/%s" % [cls, p])
	var line := String(Roster.spec_blurb("knight", "guardian"))
	print("S158 sample knight/guardian: ", line)
	if n == 30 and bad.is_empty() and line != "":
		print("S158_SPECTEXT OK %d paths read from spec_text, 0 placeholders" % n)
	else:
		print("S158_SPECTEXT FAIL n=%d bad=%s" % [n, str(bad)])
	quit()
