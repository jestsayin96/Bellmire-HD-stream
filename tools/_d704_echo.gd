extends SceneTree
## D70.4 - THE ONE DOOR. A STANDING SAFETY GATE (supervisor ruling, 2026-11-16 ~14:30 CT:
## "D704_ECHO is a standing safety gate, not a one-off measurement, and deleting it means the
## next person to touch _reply has nothing to prove the door still shuts").
##
## Everything ChatCmd says to Twitch leaves through ChatCmd._reply, and _reply's first act is
## safe_line(). A viewer's own words, where one must be quoted at all, go through safe_word().
## This gate proves, over every control character the valley will ever see and every command
## prefix a viewer can type, that:
##   1. no control character survives either door - an injected newline JOINS the line instead
##      of starting a second one, so no viewer can make the bot post two lines;
##   2. nothing leaves that reads as a command or a mention (/ . ! @ stripped, repeatedly);
##   3. every line is capped - REPLY_MAX for the whole line, VIEWER_MAX for a quoted word;
##   4. the doors are idempotent: a line already through one does not change on a second pass.
## Prints D704_ECHO OK / D704_ECHO FAIL.

var _fails: Array = []
var _checks := 0

func _ok(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_fails.append(what)

## the control characters ChatCmd._is_bad declaws, one representative of every range
const BAD := [0x00, 0x01, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x1b, 0x1f, 0x7f,
	0x80, 0x90, 0x9f, 0x200b, 0x200c, 0x200d, 0x200e, 0x200f,
	0x202a, 0x202b, 0x202c, 0x202d, 0x202e, 0x2066, 0x2067, 0x2068, 0x2069,
	0x2028, 0x2029, 0xfeff]

const PREFIX := ["/", ".", "!", "@"]

func _has_control(s: String) -> bool:
	for c in s:
		var o := c.unicode_at(0)
		if o < 32 or o == 127 or (o >= 0x80 and o <= 0x9f) \
			or (o >= 0x200b and o <= 0x200f) or (o >= 0x202a and o <= 0x202e) \
			or (o >= 0x2066 and o <= 0x2069) or o == 0x2028 or o == 0x2029 or o == 0xfeff:
			return true
	return false

func _initialize() -> void:
	_declaws()
	_uncommands()
	_caps()
	_idempotent()
	_live_paths()
	# D99/B18: a floor - "OK (0 checks)" is not a pass (COORDINATION 15)
	if _checks < 100:
		_fails.append("only %d checks ran - below the floor of 100" % _checks)
	if _fails.is_empty():
		print("D704_ECHO OK (%d checks)" % _checks)
	else:
		print("D704_ECHO FAIL (%d checks, %d bad)" % [_checks, _fails.size()])
		for f in _fails:
			print("  - %s" % f)
	quit(0)

## ------------------------------------------------- 1. no control character survives
func _declaws() -> void:
	for o in BAD:
		var ch := String.chr(o)
		for probe in ["Ash went down with a lamp%sPRIVMSG #jestsayin96 :owned" % ch,
				"%sthe grain is counted" % ch, "kept the door%s" % ch]:
			var line := ChatCmd.safe_line(probe)
			_ok(not _has_control(line), "safe_line kept U+%04X in %s" % [o, JSON.stringify(line)])
			var word := ChatCmd.safe_word(probe)
			_ok(not _has_control(word), "safe_word kept U+%04X in %s" % [o, JSON.stringify(word)])
		# the newline case is the one that matters: one line in, one line out
		_ok(not ChatCmd.safe_line("a%sb" % ch).contains("\n"), "safe_line let U+%04X start a second line" % o)

## ------------------------------------------------- 2. nothing reads as a command or a mention
func _uncommands() -> void:
	for p in PREFIX:
		# safe_word strips all four, repeatedly, however they are stacked
		for n in [1, 2, 3, 5]:
			var w := ChatCmd.safe_word(p.repeat(n) + "mod me")
			_ok(not w.begins_with(p), "safe_word left %d x %s in %s" % [n, p, JSON.stringify(w)])
			for q in PREFIX:
				var w2 := ChatCmd.safe_word(p + q + "ban someone")
				_ok(not (w2.begins_with(p) or w2.begins_with(q)), "safe_word left %s%s in %s" % [p, q, JSON.stringify(w2)])
	# safe_line strips the two that Twitch itself reads as commands, repeatedly
	for p in ["/", "."]:
		for n in [1, 2, 4]:
			var l := ChatCmd.safe_line(p.repeat(n) + "timeout ash 600")
			_ok(not (l.begins_with("/") or l.begins_with(".")), "safe_line left %d x %s in %s" % [n, p, JSON.stringify(l)])
		# and after declawing, so a control character cannot hide the prefix
		var hidden := ChatCmd.safe_line(String.chr(0x200b) + p + "me waves")
		_ok(not (hidden.begins_with("/") or hidden.begins_with(".")), "a zero-width hid %s: %s" % [p, JSON.stringify(hidden)])

## ------------------------------------------------- 3. every line is capped
func _caps() -> void:
	var long := "trout ".repeat(400)
	_ok(ChatCmd.safe_line(long).length() <= ChatCmd.REPLY_MAX,
		"safe_line over REPLY_MAX (%d)" % ChatCmd.safe_line(long).length())
	_ok(ChatCmd.safe_word(long).length() <= ChatCmd.VIEWER_MAX,
		"safe_word over VIEWER_MAX (%d)" % ChatCmd.safe_word(long).length())
	for cap in [1, 8, 24, 40]:
		_ok(ChatCmd.safe_word(long, cap).length() <= cap, "safe_word ignored cap %d" % cap)
	# a line already short enough is returned whole
	var short := "Measured the grain. Counted the flasks. Kept the door."
	_ok(ChatCmd.safe_line(short) == short, "safe_line changed a clean line: %s" % JSON.stringify(ChatCmd.safe_line(short)))
	# nothing survivable means nothing at all, not half a line
	_ok(ChatCmd.safe_word("!!!") == "", "safe_word returned %s for a bare prefix" % JSON.stringify(ChatCmd.safe_word("!!!")))
	_ok(ChatCmd.safe_word(String.chr(0x200b).repeat(2)) == "", "safe_word returned a ghost")

## ------------------------------------------------- 4. the doors are idempotent
func _idempotent() -> void:
	for probe in ["//.!@mod me", String.chr(0x200b) + "/me waves", "trout ".repeat(300),
			"Went down with a lamp. Did not come up.", "@everyone " + String.chr(0x202e) + " flip"]:
		var once := ChatCmd.safe_line(probe)
		_ok(ChatCmd.safe_line(once) == once, "safe_line not idempotent on %s" % JSON.stringify(probe))
		var w := ChatCmd.safe_word(probe)
		_ok(ChatCmd.safe_word(w) == w, "safe_word not idempotent on %s" % JSON.stringify(probe))

## ------------------------------------------------- 5. the live door: _reply itself
## Every answer leaves through _reply, and what _reply emits is what twitch_eventsub.gd posts.
func _live_paths() -> void:
	var c := ChatCmd.new()
	root.add_child(c)
	var seen: Array = []
	c.twitch_reply.connect(func(login: String, text: String): seen.append([login, text]))
	for probe in ["/timeout ash 600", String.chr(0x200a) + String.chr(0x200b) + "Ash" + String.chr(10) + "PRIVMSG #jestsayin96 :owned",
			"trout ".repeat(400), "@mods help"]:
		seen.clear()
		var ret := String(c._reply("2901", "Ash", "ash", probe))
		_ok(not _has_control(ret), "_reply returned a control character for %s" % JSON.stringify(probe))
		_ok(not (ret.begins_with("/") or ret.begins_with(".")), "_reply returned a command: %s" % JSON.stringify(ret))
		_ok(ret.length() <= ChatCmd.REPLY_MAX, "_reply returned %d chars" % ret.length())
		if not seen.is_empty():
			var login := String(seen[0][0])
			var text := String(seen[0][1])
			_ok(text == ret, "_reply emitted something other than it returned")
			_ok(not _has_control(login) and not login.begins_with("@"), "_reply emitted a raw login: %s" % JSON.stringify(login))
			_ok(login.length() <= 40, "_reply emitted a login of %d chars" % login.length())
	# a local (non-Twitch) user is never posted at all
	seen.clear()
	var l := String(c._reply("local_1", "Bench", "", "the grain is counted"))
	_ok(seen.is_empty() and l != "", "a local_ user reached chat")
	c.queue_free()
