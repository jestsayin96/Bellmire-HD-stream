extends SceneTree
## S152_REP - System 39 NPC reputation, engine half (roster.gd rep_* + the hooks in roster.gd,
## economy.gd and town.gd). Headless: <console> --headless --path . --script tools/_s152_rep.gd
## Prints S152_REP OK|FAIL. Checks: a fresh hero reads 0 at all five; completed purchases count at
## the smith and the chandler and a refused one does not; the smith's/chandler's price falls
## REP_OFF per milestone (10/25/50/100) and the fishmonger's and innkeeper's never do; staked
## tavern games and both sides of a duel count at the innkeeper, a bare roll and a refusal do not;
## an unknown key or a non-positive add is refused; the dict survives a JSON save round trip;
## and no shop line ever mentions it (SILENT). S152_RED=1 prices WITHOUT the npc key: must FAIL.
var _fails: Array = []
var _checks := 0

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _initialize() -> void:
	var red := OS.get_environment("S152_RED") == "1"
	var r := Roster.new()
	r.rng.seed = 152
	var h: Dictionary = r.fresh("u1", "Tess", "knight")
	var zero := true
	for npc: String in Roster.REP_NPCS:
		zero = zero and Roster.rep_of(h, npc) == 0
	_ok(zero, "a fresh hero stands at 0 with all five (%s)" % Roster.rep_line(h))
	_ok(Roster.REP_NPCS.size() == 5, "five townsfolk keep a ledger")
	h["gold"] = 0
	var t0 := r.buy_potion("u1")
	_ok(Roster.rep_of(h, "chandler") == 0, "a purchase refused for gold does not count (%s)" % t0)
	h["gold"] = 100000
	var lines: Array = []
	lines.append(r.buy_potion("u1"))
	lines.append(r.buy_oil("u1", 2))
	_ok(Roster.rep_of(h, "chandler") == 2, "a potion and an oil purchase count 2 at the chandler (%d)" % Roster.rep_of(h, "chandler"))
	lines.append(r.buy_armour("u1"))
	lines.append(r.buy_weapon("u1"))
	_ok(Roster.rep_of(h, "smithy") == 2, "armour fitted and a weapon forged count 2 at the smith (%d)" % Roster.rep_of(h, "smithy"))
	var silent := true
	for ln: String in lines:
		var low := ln.to_lower()
		silent = silent and not ("reputation" in low or "standing" in low or "milestone" in low)
	_ok(silent, "no shop line mentions reputation - the milestones are silent")
	# prices: rank off is 0 for a fresh hero (standing 0), so the rep cut is all there is
	var base := 1000
	var want := [1000, 980, 960, 940, 920]
	var at := [9, 10, 25, 50, 100]
	var price_ok := true
	for i in at.size():
		for npc: String in ["smithy", "chandler"]:
			h["reputation"][npc] = at[i]
			var got := r.cost_for(h, base) if red else r.cost_for(h, base, npc)
			if got != want[i]:
				price_ok = false
				print("    %s at %d: %d, want %d" % [npc, at[i], got, want[i]])
	_ok(price_ok, "smith and chandler price falls 2% a milestone: 10/25/50/100 -> 980/960/940/920 of 1000")
	h["reputation"]["fishmonger"] = 100
	h["reputation"]["innkeeper"] = 100
	_ok(r.cost_for(h, base, "fishmonger") == 1000 and r.cost_for(h, base, "innkeeper") == 1000, "the fishmonger and innkeeper take nothing off a price")
	_ok(Roster.rep_tier(h, "fishmonger") == 4 and Roster.rep_tier({"reputation": {"fishmonger": 49}}, "fishmonger") == 2, "fishmonger tier 4 at 100, tier 2 at 49 (the catch-luck bonus town.gd adds)")
	h["reputation"]["innkeeper"] = 0
	var e := Economy.new()
	e.dice_rng.seed = 152
	e.town_level = 4
	e.tavern_dice(h, 0)
	_ok(Roster.rep_of(h, "innkeeper") == 0, "a bare roll for luck does not count")
	e.tavern_dice(h, 99999)
	_ok(Roster.rep_of(h, "innkeeper") == 0, "a refused stake does not count")
	for n in 5:
		e.tavern_dice(h, 10)
	_ok(Roster.rep_of(h, "innkeeper") == 5, "five staked games count 5 at the innkeeper (%d)" % Roster.rep_of(h, "innkeeper"))
	var b: Dictionary = {"name": "Bram", "gold": 500, "alive": true}
	e.tavern_duel(h, b, 20)
	_ok(Roster.rep_of(h, "innkeeper") == 6 and Roster.rep_of(b, "innkeeper") == 1, "a duel counts at the innkeeper for BOTH players")
	_ok(Roster.rep_add(h, "smith", 1) == -1 and not h["reputation"].has("smith"), "an unknown key is refused and opens no sixth ledger")
	var before := Roster.rep_of(h, "smithy")
	_ok(Roster.rep_add(h, "smithy", 0) == -1 and Roster.rep_add(h, "smithy", -5) == -1 and Roster.rep_of(h, "smithy") == before, "a zero or negative add is refused - reputation never decays")
	var back: Dictionary = JSON.parse_string(JSON.stringify(h))
	var trip := true
	for npc: String in Roster.REP_NPCS:
		trip = trip and Roster.rep_of(back, npc) == Roster.rep_of(h, npc)
	_ok(trip, "the reputation dict survives the save file's JSON round trip")
	_ok(Roster.rep_of({}, "smithy") == 0 and Roster.rep_of({"reputation": "junk"}, "smithy") == 0, "an old save with no (or a broken) reputation reads 0")
	print("  rep_line: " + Roster.rep_line(h))
	e.free()
	r.free()
	if _fails.is_empty():
		print("S152_REP OK %d" % _checks)
	else:
		print("S152_REP FAIL %d of %d: %s" % [_fails.size(), _checks, ", ".join(_fails)])
	quit()
