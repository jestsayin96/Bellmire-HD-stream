extends SceneTree
## U58 (headless is fine: pure colour arithmetic, no UI is drawn): every text-on-surface pair UiTheme
## declares, checked against its OWN surface at >= 4.5:1. U55 only checked the rarity inks by hand-picked
## parchment; this walks the whole theme so a retuned colour cannot silently drop under AA. Surfaces are
## alpha-flattened over the worst plausible backdrop before measuring (parchment over dark, plate over light).
func _lum(c: Color) -> float:
	var f := func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)
func _cr(a: Color, b: Color) -> float:
	var x := _lum(a); var y := _lum(b)
	return (maxf(x, y) + 0.05) / (minf(x, y) + 0.05)
func _flat(c: Color, under: Color) -> Color:
	return Color(c.r * c.a + under.r * (1.0 - c.a), c.g * c.a + under.g * (1.0 - c.a), c.b * c.a + under.b * (1.0 - c.a), 1.0)
func _initialize() -> void:
	var bad := 0
	var ph := _flat(UiTheme.PARCHMENT, Color(0, 0, 0))     # worst case: translucent parchment over black
	var pl := _flat(UiTheme.PLATE, Color(1, 1, 1))         # worst case: translucent plate over white
	var pairs := [
		["INK/parch", UiTheme.INK, ph], ["INK_SOFT/parch", UiTheme.INK_SOFT, ph], ["INK_RED/parch", UiTheme.INK_RED, ph],
		["VIEWER/parch", UiTheme.VIEWER, ph], ["GOOD/parch", UiTheme.GOOD, ph], ["BAD/parch", UiTheme.BAD, ph],
		["TEAL_ON_PARCH/parch", UiTheme.TEAL_ON_PARCH, ph], ["GOLD_ON_PARCH/parch", UiTheme.GOLD_ON_PARCH, ph],
		["INK/cream", UiTheme.INK, UiTheme.SCROLL_CREAM], ["INK/tan", UiTheme.INK, UiTheme.SCROLL_TAN],
		["ON_DARK/plate", UiTheme.ON_DARK, pl], ["ON_DARK_SOFT/plate", UiTheme.ON_DARK_SOFT, pl],
		["TEAL_ON_DARK/plate", UiTheme.TEAL_ON_DARK, pl], ["GOLD_ON_DARK/plate", UiTheme.GOLD_ON_DARK, pl],
	]
	for p in pairs:
		var c := _cr(p[1], p[2])
		var ok := c >= 4.5
		print("U58 %-22s %.2f %s" % [p[0], c, "ok" if ok else "FAIL"])
		if not ok: bad += 1
	print("U58_CONTRAST ", "OK %d pairs" % pairs.size() if bad == 0 else "FAIL %d" % bad)
	quit(0 if bad == 0 else 1)
