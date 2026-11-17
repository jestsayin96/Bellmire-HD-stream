extends SceneTree
## L14: writes docs/COMMANDS.md from data/commands.json (the one source the
## game's !help also reads). Run after changing the data:
##   <godot> --headless --path . --script res://tools/_commands_doc.gd
func _initialize() -> void:
	var c: Dictionary = ChatCmd.commands()
	var cs: Dictionary = c.get("commands", {})
	# D99/B18: an empty or missing data file must not truncate the doc and read green
	if cs.is_empty():
		print("COMMANDS_DOC FAIL: data/commands.json gave 0 commands - docs/COMMANDS.md left untouched")
		quit(1)
		return
	var out := PackedStringArray()
	out.append("# Bellmire chat commands")
	out.append("")
	out.append("Generated from `data/commands.json` by `tools/_commands_doc.gd` - edit the data, not this file.")
	out.append("Type them in the stream's Twitch chat. Each viewer may send one every %s s (the game) / %s s (Twitch reader)." % [str(c.get("cooldown_s", 1.5)), str(c.get("twitch_cooldown_s", 3.0))])
	out.append("Prices are list prices: the counter is a CHA check (haggling), and guild rank takes a cut.")
	out.append("")
	out.append("| Command | Also | Arguments | Cost | What it does | Example |")
	out.append("|---|---|---|---|---|---|")
	# a present-but-short `order` would gutter the doc and still print the full count: the doc
	# is written only when every command gets a row, and the count printed is the rows written
	var order: Array = c.get("order", cs.keys())
	var missing: Array = cs.keys().filter(func(k): return not order.has(k))
	var unknown: Array = order.filter(func(k): return not cs.has(k))
	if not missing.is_empty() or not unknown.is_empty():
		print("COMMANDS_DOC FAIL: `order` misses %s and names unknown %s - docs/COMMANDS.md left untouched" % [missing, unknown])
		quit(1)
		return
	var rows := 0
	for k in order:
		var d: Dictionary = cs[k]
		rows += 1
		var al := ", ".join(PackedStringArray((d.get("aliases", []) as Array).map(func(a): return "!" + String(a))))
		out.append("| `!%s` | %s | %s | %s | %s%s | `%s` |" % [k, al, String(d.get("args", "")).replace("|", "/"), d.get("cost", "free"), d["what"], "" if bool(d.get("needs_hero", true)) else " (no hero needed)", d.get("example", "!" + k)])
	out.append("")
	var f := FileAccess.open("res://docs/COMMANDS.md", FileAccess.WRITE)
	if f == null:
		print("COMMANDS_DOC FAIL: docs/COMMANDS.md would not open for writing (%s)" % error_string(FileAccess.get_open_error()))
		quit(1)
		return
	f.store_string("\n".join(out))
	f.close()
	print("COMMANDS_DOC OK wrote %d commands" % rows)
	quit()
