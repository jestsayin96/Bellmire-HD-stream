extends SceneTree
## S151_DICE - System 38 tavern games, economy.gd house-game logic (tavern_dice / tavern_duel).
## Headless: <console> --headless --path . --script tools/_s151_dice.gd   Prints S151_DICE OK|FAIL.
## Checks: bare roll moves no gold; min/max/purse/dead/self refusals move no gold; the max scales with
## town level; 2000 house games BALANCE (hero gold + tavern_take - tavern_paid == start) with the net
## sink (take - paid) positive and both outcomes seen; a win pays 2x stake less ceil(10%);
## ties go to the house; 2000 duels conserve gold exactly with NO cut, always end with a winner, and
## both sides win sometimes; a challenge moves no gold until the CHALLENGED accepts, and lapses. S151_RED=1 checks the ledger WITHOUT tavern_take: must FAIL.
var _fails: Array = []
var _checks := 0

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _initialize() -> void:
	var red := OS.get_environment("S151_RED") == "1"
	var e := Economy.new()
	e.dice_rng.seed = 151
	e.town_level = 1
	var h := {"name": "Tess", "gold": 100, "alive": true}
	var r0: Dictionary = e.tavern_dice(h, 0)
	_ok(bool(r0["ok"]) and bool(r0["fun"]) and int(h["gold"]) == 100 and int(r0["you"]) >= 1 and int(r0["you"]) <= 20, "bare !dice rolls 1-20 and moves no gold (%s)" % r0["text"])
	_ok(e.dice_max_bet() == 25, "max bet at town level 1 = %d" % e.dice_max_bet())
	var rmax: Dictionary = e.tavern_dice(h, 26)
	_ok(not bool(rmax["ok"]) and rmax["why"] == "max" and int(h["gold"]) == 100, "26g over a level-1 cap is refused, no gold moves")
	e.town_level = 12
	_ok(e.dice_max_bet() == 300, "max bet scales with town level: level 12 = %d" % e.dice_max_bet())
	var rp: Dictionary = e.tavern_dice(h, 150)
	_ok(not bool(rp["ok"]) and rp["why"] == "gold" and int(h["gold"]) == 100, "150g from a 100g purse is refused (%s)" % rp.get("text", ""))
	var dead := {"name": "Ghost", "gold": 100, "alive": false}
	_ok(not bool(e.tavern_dice(dead, 5)["ok"]) and int(dead["gold"]) == 100, "a dead hero cannot dice")
	_ok(not bool(e.tavern_duel(h, h, 5)["ok"]) and int(h["gold"]) == 100, "a hero cannot duel themselves")
	# house games
	var start := 0
	var heroes: Array = []
	for i in 8:
		heroes.append({"name": "H%d" % i, "gold": 100000, "alive": true})
		start += 100000
	var wins := 0
	var losses := 0
	var ties := 0
	var pay_ok := true
	var tie_ok := true
	for n in 2000:
		var hh: Dictionary = heroes[n % 8]
		var before := int(hh["gold"])
		var amt := 1 + (n % 300)
		var r: Dictionary = e.tavern_dice(hh, amt)
		if not bool(r["ok"]):
			pay_ok = false
			continue
		var d := int(hh["gold"]) - before
		if int(r["you"]) > int(r["house"]):
			wins += 1
			if d != amt - int(ceil(amt * 2 * 0.10)):
				pay_ok = false
		else:
			losses += 1
			if int(r["you"]) == int(r["house"]):
				ties += 1
				if d != -amt:
					tie_ok = false
			elif d != -amt:
				pay_ok = false
	var now := 0
	for hh in heroes:
		now += int(hh["gold"])
	var take := 0 if red else e.tavern_take
	_ok(now + take - e.tavern_paid == start, "2000 house games balance the ledger: heroes %d + take %d - paid %d == start %d" % [now, take, e.tavern_paid, start])
	_ok(wins > 0 and losses > 0 and e.tavern_take > e.tavern_paid, "both outcomes seen (wins %d, losses %d); the tavern is a SINK: take %d > paid %d, net %d gold gone" % [wins, losses, e.tavern_take, e.tavern_paid, e.tavern_take - e.tavern_paid])
	_ok(pay_ok, "every win paid 2x stake less ceil(10%) of the pot; every loss cost the stake")
	_ok(ties > 0 and tie_ok, "ties go to the house (%d ties, each cost the stake)" % ties)
	_ok(e.tavern_games == 2000, "tavern_games counted %d" % e.tavern_games)
	# duels
	var a := {"name": "Ada", "gold": 500000, "alive": true}
	var b := {"name": "Bo", "gold": 500000, "alive": true}
	var aw := 0
	var bw := 0
	var tied := 0
	var end_ok := true
	var take0 := e.tavern_take
	for n in 2000:
		var r: Dictionary = e.tavern_duel(a, b, 1 + (n % 300))
		if not bool(r["ok"]) or int(r["a"]) == int(r["b"]):
			end_ok = false
			continue
		if int(r["throws"]) > 1:
			tied += 1
		if r["winner"] == "Ada":
			aw += 1
		else:
			bw += 1
	_ok(end_ok, "every duel ended with a winner in one command")
	_ok(int(a["gold"]) + int(b["gold"]) == 1000000 and e.tavern_take == take0, "2000 duels conserve gold exactly, NO house cut (%d + %d)" % [int(a["gold"]), int(b["gold"])])
	_ok(aw > 0 and bw > 0 and tied > 0, "both sides win (Ada %d, Bo %d) and ties re-rolled %d times" % [aw, bw, tied])
	var poor := {"name": "Pip", "gold": 3, "alive": true}
	var rpo: Dictionary = e.tavern_duel(a, poor, 10)
	_ok(not bool(rpo["ok"]) and rpo["who"] == "Pip" and int(poor["gold"]) == 3, "a duel the challenged cannot cover is refused (%s)" % rpo.get("text", ""))
	# consent: a challenge moves no gold; only the challenged hero's accept settles it; offers lapse
	var c1 := {"name": "Cal", "gold": 50, "alive": true}
	var c2 := {"name": "Dee", "gold": 50, "alive": true}
	var rc: Dictionary = e.tavern_challenge(c1, c2, 20, 1000)
	_ok(bool(rc["ok"]) and bool(rc["pending"]) and int(c1["gold"]) == 50 and int(c2["gold"]) == 50, "a challenge moves no gold (%s)" % rc["text"])
	_ok(not bool(e.tavern_accept(c1, 2000)["ok"]) and int(c1["gold"]) + int(c2["gold"]) == 100, "the challenger cannot accept their own dare")
	var ra2: Dictionary = e.tavern_accept(c2, 2000)
	_ok(bool(ra2["ok"]) and int(c1["gold"]) + int(c2["gold"]) == 100 and absi(int(c1["gold"]) - 50) == 20, "the challenged accepts and the pot moves (%s)" % ra2.get("text", ""))
	_ok(not bool(e.tavern_accept(c2, 2500)["ok"]), "an accepted dare is spent - a second accept finds nothing")
	e.tavern_challenge(c1, c2, 5, 3000)
	var g1 := int(c1["gold"])
	_ok(not bool(e.tavern_accept(c2, 3000 + Economy.DICE_OFFER_MS + 1)["ok"]) and int(c1["gold"]) == g1, "a dare lapses after %d ms" % Economy.DICE_OFFER_MS)
	print("  sample: %s" % e.tavern_dice(heroes[0], 20)["text"])
	print("  sample: %s" % e.tavern_duel(a, b, 40)["text"])
	e.free()
	if _fails.is_empty():
		print("S151_DICE OK %d" % _checks)
	else:
		print("S151_DICE FAIL %d of %d: %s" % [_fails.size(), _checks, ", ".join(_fails)])
	quit()
