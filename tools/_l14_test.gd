extends SceneTree
## L14: one source for the command list. Every verb ChatCmd answers is in
## data/commands.json and every command there is answered; aliases route; !help
## short and detailed; typos get a nudge, other bots' commands are left alone;
## friendly gold replies; docs/COMMANDS.md matches the data. Prints L14_TEST OK.
var _fail := 0
var _checks := 0

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print(("  ok  " if c else "  FAIL ") + what)
	if not c:
		_fail += 1

# B161: the 8-space regex harvester is GONE. The supervisor granted this lane
# `tools/_l14_test.gd` at 17:37 CT on 25 Nov 2026 (scope: THIS FILE ONLY). The old
# `rx.compile("(?m)^        ...")` could not see a tab-indented or depth-12 match
# label, and it READ A DICTIONARY KEY SITTING AT LABEL DEPTH AS A VIEWER VERB -
# a false positive that would have put a non-command into `verbs` and then charged
# data/commands.json with not answering it. Proved by B159_HARVEST OK 15/15:
# 8 shape cases, 4 real-tree arms, 3 red-prove arms. No depth constant, no end
# anchor, no 8-space assumption - brackets and indentation decide.
func _strip_comment(line: String) -> String:
	var i := 0
	var n := line.length()
	while i < n:
		var c := line[i]
		if c == "\"":
			i += 1
			while i < n:
				if line[i] == "\\":
					i += 2
					continue
				if line[i] == "\"":
					i += 1
					break
				i += 1
			continue
		if c == "#":
			return line.substr(0, i)
		i += 1
	return line

func _strip_strings(line: String) -> String:
	var out := ""
	var i := 0
	var n := line.length()
	while i < n:
		var c := line[i]
		if c == "\"":
			i += 1
			while i < n:
				if line[i] == "\\":
					i += 2
					continue
				if line[i] == "\"":
					i += 1
					break
				i += 1
			out += "S"
			continue
		if c == "#":
			break
		out += c
		i += 1
	return out

func _indent_of(line: String) -> int:
	var col := 0
	for ch in line:
		if ch == " ":
			col += 1
		elif ch == "\t":
			col += 4 - (col % 4)
		else:
			break
	return col

## The replacement harvester. No depth constant, no end anchor, no 8-space assumption.
func _harvest(src: String) -> Array:
	var verbs: Array = []
	var depth := 0
	var st_ind: Array = []
	var st_lab: Array = []
	var rx_match := RegEx.new()
	rx_match.compile("^match\\b.*:$")
	var rx_lab := RegEx.new()
	rx_lab.compile("^((?:\"[^\"]*\"\\s*,\\s*)*\"[^\"]*\")\\s*:")
	var rx_word := RegEx.new()
	rx_word.compile("^\"([a-z][a-z0-9_]*)\"$")
	for raw in src.split("\n"):
		if raw.strip_edges() == "":
			continue
		var code := _strip_strings(raw)
		if code.strip_edges() == "":
			continue
		var start_depth := depth
		var ind := _indent_of(raw)
		if start_depth == 0:
			while st_ind.size() > 0 and ind <= int(st_ind[st_ind.size() - 1]):
				st_ind.pop_back()
				st_lab.pop_back()
		var body := code.strip_edges()
		var text := _strip_comment(raw).strip_edges()
		if start_depth == 0 and rx_match.search(body) != null:
			st_ind.append(ind)
			st_lab.append(-1)
		elif start_depth == 0 and st_ind.size() > 0:
			var top_ind := int(st_ind[st_ind.size() - 1])
			# only the OUTERMOST match dispatches viewer verbs; a nested `match arg:`
			# inside a label body is argument sub-dispatch, not a command.
			if ind > top_ind and st_ind.size() == 1:
				if int(st_lab[st_lab.size() - 1]) == -1:
					st_lab[st_lab.size() - 1] = ind
				if ind == int(st_lab[st_lab.size() - 1]):
					var m := rx_lab.search(text)
					if m != null:
						var parts := m.get_string(1).split(",")
						var words: Array = []
						var good := true
						for p in parts:
							var mm := rx_word.search(p.strip_edges())
							if mm != null:
								words.append(mm.get_string(1))
							else:
								good = false
						if good:
							for w in words:
								verbs.append(w)
		for ch in code:
			if ch == "(" or ch == "[" or ch == "{":
				depth += 1
			elif ch == ")" or ch == "]" or ch == "}":
				depth -= 1
				if depth < 0:
					depth = 0
	return verbs

## The instrument it replaces, kept ONLY as the contrast arm of the B162 red-prove
## below. B159 proved the fault: this 8-space anchor reads a dictionary key sitting
## at label depth as a viewer verb. It is here so the replacement can be shown to
## fail where its predecessor lied, and for nothing else - only that one arm calls it.
func _harvest_old(src: String) -> Array:
	var rx := RegEx.new()
	rx.compile("(?m)^        ((?:\"[a-z]+\", )*\"[a-z]+\"):")
	var verbs: Array = []
	for mt in rx.search_all(src):
		for w in mt.get_string(1).split(", "):
			verbs.append(w.replace("\"", ""))
	return verbs

func _initialize() -> void:
	# B80: ONE load, held whole - the doc check below needs `order` too, and a second
	# commands() call would not re-clear _guard_faults (see the note just under this).
	var cdata: Dictionary = ChatCmd.commands()
	var cs: Dictionary = cdata["commands"]
	# B73: the COMMANDS_DATA guard count is READ here, and a non-empty answer moves _fail.
	# From B48 until B73 chatcmd.gd:884 said "any gate can ask" and no gate in tools/ ever did
	# (git grep guard_faults -- tools/ was rc=1, zero hits) while 91 append sites accumulated.
	# Read immediately after the first commands() load: the loader clears _guard_faults only
	# when _cmds is empty, so a later load would not re-clear and a later read could pass blind.
	var faults: Array[String] = ChatCmd.guard_faults()
	_ok(faults.is_empty(), "no COMMANDS_DATA guard arm fired on the load (%d fired: %s)" % [faults.size(), faults])
	# the verbs in ChatCmd's match block, read from its source
	var src := FileAccess.get_file_as_string("res://scripts/chatcmd.gd")
	var verbs: Array = _harvest(src)
	var missing: Array = []
	for v in verbs:
		if not cs.has(ChatCmd.canonical(v)) and not v.begins_with("test"):   # L17: !test* are local-only, never documented
			missing.append(v)
	_ok(verbs.size() >= 20 and missing.is_empty(), "every verb ChatCmd answers is in the data (%d verbs; missing %s)" % [verbs.size(), missing])
	var unanswered: Array = []
	for k in cs:
		if not verbs.has(k):
			unanswered.append(k)
	_ok(unanswered.is_empty(), "every command in the data is answered (unanswered %s)" % [unanswered])
	# B162 (team lead, 17:58 CT 25 Nov): RED-PROVE THE REPLACEMENT WHERE ITS
	# PREDECESSOR LIED. The two drift checks above read the REAL tree, where this fault
	# is INVISIBLE - chatcmd.gd happens to carry no dictionary key at label depth today,
	# so both of them would stay green if the parse regressed to the 8-space anchor.
	# This arm feeds the new parse the EXACT shape that fooled the old one (B159 case 6:
	# a `{` opened in a label body with `"gold": 1,` sitting back at label indent) and
	# asserts `gold` is not harvested, keeping the old instrument alongside as the
	# contrast. Red if the parse ever regresses, and red if it over-harvests.
	var dict_shape := "func h(c):\n    match c:\n        \"delve\":\n            var d = {\n        \"gold\": 1,\n            }\n        \"forge\":\n            pass\n"
	var new_g: Array = _harvest(dict_shape)
	var old_g: Array = _harvest_old(dict_shape)
	_ok(not new_g.has("gold") and new_g == ["delve", "forge"] and old_g.has("gold"), "the dictionary key at label depth is NOT harvested - new %s, the replaced 8-space regex %s" % [new_g, old_g])
	var r := Roster.new()
	root.add_child(r)
	var cc := ChatCmd.new(r)
	r.fresh("u1", "Ash", "knight", "human")
	r.get_hero("u1")["gold"] = 40
	for pair in [["!stats", "Ash the human knight"], ["!inv", "Ash carries"], ["!commands", "Commands:"], ["!lamp", "buys"], ["!help forge", "60 / 160 / 420"]]:
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
	# B173/B174: THE BARE !help LINE IS THE WIDEST THING THIS LANE SENDS, AND IT GROWS WITH
	# THE COMMAND SET. It is built from `order`, so every command added to data/commands.json
	# makes it len(name)+2 chars longer, and when it passes REPLY_MAX safe_line CUTS IT - in
	# the most-typed answer in the set, with no gate anywhere saying so. Measured off the real
	# source and the real data at B174: 352 of 440 with the hub URL on the end, headroom 88,
	# so ELEVEN more mean-length (6-char) commands fit and the TWELFTH overflows - EIGHT at
	# the longest existing name. (B173 first found this cliff and its mechanism holds, but it
	# read a 59-char hub_url that is not in the data; the real one is 49, and every headline
	# number moved. The figures above are B174's, off the real string.) This arm turns the
	# cliff from a silent truncation on stream into a RED here, at the moment the command
	# that crosses it is added.
	var hs_sent := ChatCmd.safe_line(hs)
	_ok(hs.length() <= ChatCmd.REPLY_MAX and hs_sent == hs, "the bare !help line fits REPLY_MAX uncut: %d of %d, headroom %d chars (~%d more 6-char commands)" % [hs.length(), ChatCmd.REPLY_MAX, ChatCmd.REPLY_MAX - hs.length(), int((ChatCmd.REPLY_MAX - hs.length()) / 8)])
	# AND THE RED-PROVE, because an arm that only ever reads a green number is not an
	# instrument. ONE character over the cap does NOT cost one character: _cut backtracks to
	# the last space, so the overflow takes the whole final word with it - on the real line
	# that is the 49-char hub URL, and the viewer is left with "All of it:" and no link. Fed a
	# line exactly ONE over, this asserts the real safe_line both caps it AND loses more than
	# it overflowed by, which is the fault worth knowing about rather than the cap itself.
	# NOTE the padding here is a PROXY: the real line overflows in the MIDDLE, by a command
	# being added, not at the end. The assertion is deliberately environment-independent -
	# "one over costs more than one" - so it holds whether or not hub_url() is set here.
	var over := hs
	while over.length() < ChatCmd.REPLY_MAX + 1:
		over += "x"
	var over_sent := ChatCmd.safe_line(over)
	var lost := over.length() - over_sent.length()
	_ok(over_sent.length() <= ChatCmd.REPLY_MAX and lost > 1, "one char over the cap costs %d chars, not 1 - the cut falls back to a word boundary (%d -> %d)" % [lost, over.length(), over_sent.length()])
	cc._last.clear()
	var out := cc.handle("u1", "Ash", "!forg")
	_ok(out.contains("did you mean !forge"), "a typo is nudged: %s" % out)
	cc._last.clear()
	_ok(cc.handle("u1", "Ash", "!discord") == "" and cc.handle("u2", "Bo", "!so somebody") == "", "other bots' commands are left alone")
	# fightoverlay shares the chat (data/commands.json "foreign"): its words, its v-prefix and
	# their near misses get NO reply and NO nudge; Bellmire's own typos still get one
	var silent: Array = []
	for w in ["!hug", "!hugg", "!jump", "!8ball", "!royale", "!boss", "!fightt", "!clas", "!vstats", "!vstat", "!vhelp", "!vroll", "!vshop", "!valley", "!vanything", "!roll", "!roll 2d6", "!rol"]:
		cc._last.clear()
		if cc.handle("u1", "Ash", w) != "":
			silent.append(w)
	_ok(silent.is_empty(), "fightoverlay's commands, its v-prefix and near misses stay silent (answered: %s)" % [silent])
	for pair in [["!hro", "!hero"], ["!fsh", "!fish"], ["!enlst", "!enlist"], ["!memoral", "!memorial"]]:
		cc._last.clear()
		out = cc.handle("u1", "Ash", pair[0])
		_ok(out.contains("did you mean " + pair[1]), "Bellmire's own typo %s is still nudged: %s" % [pair[0], out])
	cc._last.clear()
	var rk := cc.handle("u1", "Ash", "!ranks")
	_ok(rk != "" and not rk.contains("did you mean"), "!ranks still answers the Guild Roll: %s" % rk.substr(0, 60))
	# T1 contract: twitch_reply carries the plain answer for the desktop to send; never for local_*
	var tw: Array = []
	cc.twitch_reply.connect(func(lg: String, tx: String) -> void: tw.append([lg, tx]))
	cc._last.clear()
	var hr := cc.handle("u1", "Ash", "!hero")
	_ok(tw.size() == 1 and tw[0][0] == "ash" and tw[0][1] == hr and not String(tw[0][1]).begins_with("@"), "twitch_reply: the plain !hero answer for ash (%s)" % [tw])
	cc._last.clear()
	cc.handle("u1", "Ash", "!inventory", "ash_login")
	_ok(tw.size() == 2 and tw[1][0] == "ash_login", "twitch_reply: the login when one is given")
	cc._last.clear()
	cc.handle("local_mre", "MrE", "!help")
	cc._last.clear()
	cc.handle("u1", "Ash", "!hug")
	_ok(tw.size() == 2, "twitch_reply: nothing for the local keyboard or for fightoverlay's words (%d)" % tw.size())
	var clash: Array = []
	for k in cs:
		for n in [k] + Array(cs[k].get("aliases", [])):
			if ChatCmd.foreign(String(n), false):
				clash.append(n)
	_ok(clash.is_empty(), "no Bellmire command or alias is another app's or starts with its prefix (clash: %s)" % [clash])
	cc._last.clear()
	out = cc.handle("u1", "Ash", "!armoury")
	_ok(out.contains("needs ") and out.contains(" gold for leather - you have "), "a friendly gold reply: %s" % out)
	# the doc is the data - B80: EVERY PUBLISHED FIELD, NOT A 30-CHAR PREFIX OF ONE.
	# Until B80 this compared "`!<name>`" and what.substr(0, 30). The `what` strings run to
	# 195 chars, so 165 of them were ungated, and four of the 31 are shorter than 30 entirely.
	# B79's prose-only red arm drifted the data against the doc (doc sha edff7faa -> 00014f22)
	# and this check stayed GREEN - it read command names, not published words. The rows below
	# are built the way tools/_commands_doc.gd builds them, off the same keys in the same
	# `order`, so the comparison is against WHAT THE GENERATOR PUBLISHES, byte for byte. If the
	# two ever disagree the GENERATOR WINS and this block is the thing to fix.
	var doc := FileAccess.get_file_as_string("res://docs/COMMANDS.md")
	var doc_order: Array = cdata.get("order", cs.keys())
	var want_rows := PackedStringArray()
	for k in doc_order:
		var dd: Dictionary = cs[k]
		var dal := ", ".join(PackedStringArray((dd.get("aliases", []) as Array).map(func(a): return "!" + String(a))))
		want_rows.append("| `!%s` | %s | %s | %s | %s%s | `%s` |" % [k, dal, String(dd.get("args", "")).replace("|", "/"), dd.get("cost", "free"), dd["what"], "" if bool(dd.get("needs_hero", true)) else " (no hero needed)", dd.get("example", "!" + k)])
	var have_rows := PackedStringArray()
	for ln in doc.split("\n"):
		if String(ln).begins_with("| `!"):
			have_rows.append(String(ln))
	var unpublished: Array = []   # the data says it; the doc does not carry it as written
	for rw in want_rows:
		if not have_rows.has(rw):
			unpublished.append(String(rw).substr(0, 44))
	var stale: Array = []         # the doc publishes it; the data does not say it
	for rw in have_rows:
		if not want_rows.has(rw):
			stale.append(String(rw).substr(0, 44))
	_ok(unpublished.is_empty(), "docs/COMMANDS.md carries every field the data publishes, verbatim (%d rows; unpublished %s)" % [want_rows.size(), unpublished])
	_ok(stale.is_empty() and have_rows.size() == want_rows.size(), "docs/COMMANDS.md publishes nothing the data does not say (%d rows; stale %s)" % [have_rows.size(), stale])
	# B22 (B21 Faults 3+4): the count is printed, a floor sits under it, and rc agrees.
	# Twenty-two checks and two checks used to read identically in the log.
	if _checks < 20:
		_fail += 1
		print("  FAIL only %d checks ran - below the floor of 20" % _checks)
	print(("L14_TEST OK (%d checks)" % _checks) if _fail == 0 else ("L14_TEST FAIL %d (%d checks)" % [_fail, _checks]))
	quit(0 if _fail == 0 else 1)
