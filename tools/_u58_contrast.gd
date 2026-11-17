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
# U59: ENUMERATE, DO NOT RECITE. Every Color constant UiTheme declares must be classified below, so a colour
# added tomorrow with no entry is a FAIL (UNCLASSIFIED), not a silence. TEXT colours are measured against
# the surface(s) they are drawn on; CHIPPED text is held by UiTheme.chip_bg's own ratio; FILL colours are
# not text (fills, rules, edges, shadows, glints); UNMEASURED is text whose surface is not a theme colour -
# named and counted so the gap stays visible instead of hiding.
const TEXT := {
	"INK": ["parch", "cream", "tan"], "INK_SOFT": ["parch"], "INK_RED": ["parch"], "VIEWER": ["parch"],
	"GOOD": ["parch"], "BAD": ["parch"], "TEAL_ON_PARCH": ["parch"], "GOLD_ON_PARCH": ["parch"],
	"ON_DARK": ["plate"], "ON_DARK_SOFT": ["plate"], "TEAL_ON_DARK": ["plate"], "GOLD_ON_DARK": ["plate"],
}
const CHIPPED := ["ON_KIND", "WHITE"]
const UNMEASURED := ["WORD_HI", "TAG_GOLD"]
const FILL := ["PARCH", "EDGE", "TEAL", "BAND", "PARCHMENT", "PARCHMENT_SOLID", "PLATE", "PLATE_SOLID", "ON_DARK_SHADOW",
	"EDGE_ON_DARK", "SHADOW", "SCROLL_CREAM", "SCROLL_TAN", "SCROLL_TAN_DK", "SCROLL_WOOD_LT", "SCROLL_WOOD_DK",
	"SCROLL_BRASS", "SCROLL_BRASS_DK", "SCROLL_GOLD", "SCROLL_BURN", "SCROLL_GRAIN", "SCROLL_GRAIN_HI",
	"SCROLL_STAIN", "SCROLL_STAIN_2", "SCROLL_RULE", "SCROLL_EDGE_SHADE", "SCROLL_SHEET_SHADOW", "SCROLL_GLINT",
	"SCROLL_SEAL", "SCROLL_SEAL_PIP", "WORD_SHADOW", "AURA_DEFAULT", "TAG_OUTLINE"]
func _initialize() -> void:
	var bad := 0
	var surf := {
		"parch": _flat(UiTheme.PARCHMENT, Color(0, 0, 0)),     # worst case: translucent parchment over black
		"plate": _flat(UiTheme.PLATE, Color(1, 1, 1)),         # worst case: translucent plate over white
		"cream": UiTheme.SCROLL_CREAM, "tan": UiTheme.SCROLL_TAN,
	}
	var consts: Dictionary = (load("res://scripts/ui_theme.gd") as GDScript).get_script_constant_map()
	var seen := 0
	var checked := 0
	for k in consts:
		if typeof(consts[k]) != TYPE_COLOR:
			continue
		seen += 1
		if TEXT.has(k):
			for sname in TEXT[k]:
				var c := _cr(consts[k], surf[sname])
				var ok := c >= 4.5
				print("U59 %-16s on %-6s %.2f %s" % [k, sname, c, "ok" if ok else "FAIL"])
				checked += 1
				if not ok: bad += 1
		elif k in CHIPPED or k in FILL:
			pass
		elif k in UNMEASURED:
			print("U59 %-16s UNMEASURED (text; surface is not a theme colour)" % k)
		else:
			print("U59 %-16s UNCLASSIFIED - add it to TEXT, CHIPPED, UNMEASURED or FILL" % k)
			bad += 1
	# the reverse: a name listed above that UiTheme no longer has is a stale entry, also a FAIL
	for k in TEXT.keys() + CHIPPED + UNMEASURED + FILL:
		if not consts.has(k) or typeof(consts[k]) != TYPE_COLOR:
			print("U59 %-16s STALE - listed here, not a Color constant in UiTheme" % k)
			bad += 1
	print("U59_CONTRAST ", ("OK %d colours walked, %d pairs, %d unmeasured" % [seen, checked, UNMEASURED.size()]) if bad == 0 else "FAIL %d" % bad)
	quit(0 if bad == 0 else 1)
