extends SceneTree
## L14: one source for the command list. Every verb ChatCmd answers is in
## data/commands.json and every command there is answered; aliases route; !help
## short and detailed; typos get a nudge, other bots' commands are left alone;
## friendly gold replies; docs/COMMANDS.md matches the data. Prints L14_TEST OK.
var _fail := 0

func _ok(c: bool, what: String) -> void:
	print(("  ok  " if c else "  FAIL ") + what)
	if not c:
		_fail += 1

func _initialize() -> void:
	var cs: Dictionary = ChatCmd.commands()["commands"]
	# the verbs in ChatCmd's match block, read from its source
	var src := FileAccess.get_file_as_string("res://scripts/chatcmd.gd")
	var rx := RegEx.new()
	rx.compile("(?m)^        ((?:\"[a-z]+\", )*\"[a-z]+\"):")
	var verbs: Array = []
	for mt in rx.search_all(src):
		for w in mt.get_string(1).split(", "):
			verbs.append(w.replace("\"", ""))
	var missing: Array = []
	for v in verbs:
		if not cs.has(ChatCmd.canonical(v)):
			missing.append(v)
	_ok(verbs.size() >= 20 and missing.is_empty(), "every verb ChatCmd answers is in the data (%d verbs; missing %s)" % [verbs.size(), missing])
	var unanswered: Array = []
	for k in cs:
		if not verbs.has(k):
			unanswered.append(k)
	_ok(unanswered.is_empty(), "every command in the data is answered (unanswered %s)" % [unanswered])
	var r := Roster.new()
	root.add_child(r)
	var cc := ChatCmd.new(r)
	r.fresh("u1", "Ash", "knight", "human")
	r.get_hero("u1")["gold"] = 40
	for pair in [["!stats", "Ash the human knight"], ["!inv", "Ash carries"], ["!commands", "Commands:"], ["!valley", "Commands:"], ["!lamp", "buys"], ["!help forge", "60 / 160 / 420"]]:
		cc._last.clear()
		var out := cc.handle("u1", "Ash", pair[0])
		_ok(out.contains(pair[1]), "%s -> %s" % [pair[0], out.substr(0, 90)])
	cc._last.clear()
	var hs := cc.handle("u1", "Ash", "!help")
	var all_in := true
	for k in cs:
		if not hs.contains("!" + k):
			all_in = false
	_ok(all_in, "!help names every command")
	cc._last.clear()
	var out := cc.handle("u1", "Ash", "!forg")
	_ok(out.contains("did you mean !forge"), "a typo is nudged: %s" % out)
	cc._last.clear()
	_ok(cc.handle("u1", "Ash", "!discord") == "" and cc.handle("u2", "Bo", "!so somebody") == "", "other bots' commands are left alone")
	cc._last.clear()
	out = cc.handle("u1", "Ash", "!armoury")
	_ok(out.contains("needs ") and out.contains(" gold for leather - you have "), "a friendly gold reply: %s" % out)
	# the doc is the data
	var before := FileAccess.get_file_as_string("res://docs/COMMANDS.md")
	var ok_doc := true
	for k in cs:
		if not before.contains("`!%s`" % k) or not before.contains(String(cs[k]["what"]).substr(0, 30)):
			ok_doc = false
	_ok(ok_doc, "docs/COMMANDS.md carries every command from the data")
	print("L14_TEST OK" if _fail == 0 else "L14_TEST FAIL %d" % _fail)
	quit()
