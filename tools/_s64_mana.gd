## S64: the mana gate. A mage spends MANA_COST per spell, runs dry, regenerates; a knight is
## never gated; the paladin (a mender) draws on a pool. Prints S64_MANA OK / FAIL.
## RED ARM: pass `-- red` and the test demands an UNGATED mage (spells free) - it must FAIL.
extends SceneTree

func _init() -> void:
	var red := OS.get_cmdline_user_args().has("red")
	var r := Roster.new()
	var bad: Array = []
	var mage := {"class": "mage", "stats": {"int": 16, "wis": 10, "cha": 10, "con": 10}, "armour": 0}
	var knight := {"class": "knight", "stats": {"str": 16, "cha": 10, "con": 10, "wis": 10, "int": 10}, "armour": 0}
	var pal := {"class": "paladin", "stats": {"cha": 14, "wis": 10, "str": 14, "con": 10, "int": 10}, "armour": 0}
	var mx := r.mana_max(mage)
	var want_mx := Roster.MANA_BASE + 3.0 * Roster.MANA_PER_MOD   # INT 16 -> +3
	if absf(mx - want_mx) > 0.001:
		bad.append("mage max %s != %s" % [mx, want_mx])
	var n := 0
	for i in range(100):
		if not r.spend_mana(mage):
			break
		n += 1
	var want_n := int(floor(want_mx / Roster.MANA_COST))
	if red:
		want_n = 100          # the lie: spells are free
	if n != want_n:
		bad.append("mage cast %d before dry, want %d" % [n, want_n])
	if r.spend_mana(mage) and not red:
		bad.append("dry mage cast anyway")
	var before := float(mage["mana"])
	r.regen_mana(mage, 2.0)
	if absf(float(mage["mana"]) - (before + 2.0 * Roster.MANA_REGEN)) > 0.001:
		bad.append("regen %s -> %s" % [before, mage["mana"]])
	r.regen_mana(mage, 999.0)
	if absf(float(mage["mana"]) - mx) > 0.001:
		bad.append("regen overfills %s" % mage["mana"])
	for k in ["mana", "mana_max", "mana_regen"]:
		if not mage.has(k):
			bad.append("mage publishes no " + k)
	for i in range(50):
		if not r.spend_mana(knight):
			bad.append("knight gated")
			break
	if r.mana_max(knight) != 0.0:
		bad.append("knight has a pool")
	if not r.uses_mana(pal) or r.mana_max(pal) <= 0.0:
		bad.append("paladin has no pool")
	r.free()
	print("S64_MANA %s mage max=%.0f casts_before_dry=%d cost=%.0f regen=%.0f/s %s" % [
		"OK" if bad.is_empty() else "FAIL", mx, n, Roster.MANA_COST, Roster.MANA_REGEN, str(bad)])
	quit(0 if bad.is_empty() else 1)
