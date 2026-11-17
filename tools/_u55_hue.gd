extends SceneTree
## U55 (WINDOWED, --script): the rarity ladder on the dormant Satchel's _piece rows, one REAL named
## piece per rung out of items.json, at UI scale 100/125/150. Pass: every rung's pip colour equals
## art's RARITY_HUE, bare rungs have none, hued names are >= 4.5:1 on parchment. Shots in renders/cycles/u55/.
var _f := 0
var _step := 0
var _s: Node
var _layer: CanvasLayer
var _out := ""
var _bad := 0
func _lum(c: Color) -> float:
	var f := func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)
func _cr(a: Color, b: Color) -> float:
	var x := _lum(a); var y := _lum(b)
	return (maxf(x, y) + 0.05) / (minf(x, y) + 0.05)
func _initialize() -> void:
	_out = ProjectSettings.globalize_path("res://renders/cycles/u55/")
	DirAccess.make_dir_recursive_absolute(_out)
func _build() -> void:
	if _layer != null:
		_layer.queue_free()
	_layer = CanvasLayer.new()
	root.add_child(_layer)
	var lp := LeaderboardPanel.new()
	_layer.add_child(lp)
	_s = LeaderboardPanel.Satchel.new()
	_layer.add_child(_s)
	_s.build()
	_s.set_process(false)   # the sheet hides itself with no hero to show; this harness feeds rows directly
	_s.visible = true
	var w: Dictionary = Roster.items().get("equipment", {}).get("weapons", {})
	var seen := {}
	for k in w:
		var r := String(w[k].get("rarity", ""))
		if seen.has(r): continue
		seen[r] = true
		_s._piece(String(w[k]["name"]), "+3 atk · 1d8", UiTheme.GOOD, r)
	var a: Dictionary = Roster.items().get("equipment", {}).get("armour", {})
	for k in a:
		if String(a[k].get("rarity", "")) == "artifact":
			_s._piece(String(a[k]["name"]), "+6 AC · +20 HP", UiTheme.GOOD, "artifact"); break
	_s._piece("Hand-me-down boots (no stored rarity)", "for the look", UiTheme.INK_SOFT, "")
func _process(_d: float) -> bool:
	_f += 1
	if _f == 30:
		for r in ["", "junk", "starting", "common"]:
			if UiTheme.rarity_pip(r) != null: _bad += 1; print("FAIL bare rung has a pip: ", r)
		for r in UiTheme.RARITY_HUE:
			var p: Control = UiTheme.rarity_pip(r)
			var sb := p.get_theme_stylebox("panel") as StyleBoxFlat
			if p == null or sb.bg_color != UiTheme.RARITY_HUE[r]: _bad += 1; print("FAIL pip != art hue: ", r)
		for r in UiTheme.RARITY_INK:
			var c := _cr(UiTheme.RARITY_INK[r], Color(0.93, 0.86, 0.69))
			print("INK %s contrast %.2f" % [r, c])
			if c < 4.5: _bad += 1; print("FAIL ink contrast ", r)
	if _f < 40: return false
	var sc: float = UiTheme.STEPS[_step]
	if _f % 40 == 0 or _s == null:
		UiTheme.scale = sc
		_build()
		return false
	if _f % 40 == 20:
		var img := root.get_viewport().get_texture().get_image()
		img.save_png(_out + "u55_%d.png" % int(sc * 100))
		print("shot ", sc)
		_step += 1
		_s = null
		if _step >= 3:
			print("U55_HUE ", "OK" if _bad == 0 else "FAIL %d" % _bad)
			quit(0 if _bad == 0 else 1)
	return false
