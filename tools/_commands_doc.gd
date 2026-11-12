extends SceneTree
## L14: writes docs/COMMANDS.md from data/commands.json (the one source the
## game's !help also reads). Run after changing the data:
##   <godot> --headless --path . --script res://tools/_commands_doc.gd
func _initialize() -> void:
	var c: Dictionary = ChatCmd.commands()
	var cs: Dictionary = c["commands"]
	var out := PackedStringArray()
	out.append("# Bellmire chat commands")
	out.append("")
	out.append("Generated from `data/commands.json` by `tools/_commands_doc.gd` - edit the data, not this file.")
	out.append("Type them in the stream's Twitch chat. Each viewer may send one every %s s (the game) / %s s (Twitch reader)." % [str(c.get("cooldown_s", 1.5)), str(c.get("twitch_cooldown_s", 3.0))])
	out.append("Prices are list prices: the counter is a CHA check (haggling), and guild rank takes a cut.")
	out.append("")
	out.append("| Command | Also | Arguments | Cost | What it does | Example |")
	out.append("|---|---|---|---|---|---|")
	for k in c.get("order", cs.keys()):
		var d: Dictionary = cs[k]
		var al := ", ".join(PackedStringArray((d.get("aliases", []) as Array).map(func(a): return "!" + String(a))))
		out.append("| `!%s` | %s | %s | %s | %s%s | `%s` |" % [k, al, String(d.get("args", "")).replace("|", "/"), d.get("cost", "free"), d["what"], "" if bool(d.get("needs_hero", true)) else " (no hero needed)", d.get("example", "!" + k)])
	out.append("")
	var f := FileAccess.open("res://docs/COMMANDS.md", FileAccess.WRITE)
	f.store_string("\n".join(out))
	f.close()
	print("COMMANDS_DOC wrote %d commands" % cs.size())
	quit()
