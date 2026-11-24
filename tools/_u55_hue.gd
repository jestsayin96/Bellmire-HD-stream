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
var _n := 0  # U154: rows + rungs actually walked
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
## U56: the LAYOUT gate U55 lacked. Every row is [pip, name, value]: the value must sit whole inside the
## row, the name must end clear of it by the separation, and a name that does not fit must carry an
## ellipsis (text_overrun_behavior) rather than a bare cut. U55 passed a row that read "(no stored r".
func _check_rows(sc: float) -> void:
	for h in _s._list.get_children():
		if not (h is HBoxContainer) or h.get_child_count() < 3:
			continue
		_n += 1
		var a: Label = h.get_child(1)
		var b: Label = h.get_child(2)
		var ra: Rect2 = a.get_global_rect()
		var rb: Rect2 = b.get_global_rect()
		var rh: Rect2 = h.get_global_rect()
		var sep: float = float(h.get_theme_constant("separation"))
		var full: float = a.get_theme_font("font").get_string_size(a.text, HORIZONTAL_ALIGNMENT_LEFT, -1, a.get_theme_font_size("font_size")).x
		if ra.end.x + sep - 0.5 > rb.position.x:
			_bad += 1; print("FAIL row collides @", sc, ": ", a.text)
		if rb.end.x > rh.end.x + 0.5:
			_bad += 1; print("FAIL value leaves row @", sc, ": ", b.text)
		if b.size.x + 0.5 < b.get_minimum_size().x:
			_bad += 1; print("FAIL value squeezed @", sc, ": ", b.text)
		if full > a.size.x + 0.5 and a.text_overrun_behavior != TextServer.OVERRUN_TRIM_ELLIPSIS:
			_bad += 1; print("FAIL bare cut, no ellipsis @", sc, ": ", a.text)
		print("ROW @%.2f name %.0f/%.0f px %s | %s" % [sc, full, a.size.x, "ELLIPSIS" if full > a.size.x + 0.5 else "fits", a.text.left(28)])

func _check_frame(img: Image, sc: float) -> void:
	## U57: a frame a human would fail as BLANK or HERO-LESS must fail the gate too. Sample a 48x27 grid;
	## count distinct quantised colours and the share of samples that differ from the most common one.
	var seen := {}
	var w := img.get_width(); var h := img.get_height()
	for gy in 27:
		for gx in 48:
			var c := img.get_pixel(int((gx + 0.5) * w / 48.0), int((gy + 0.5) * h / 27.0))
			var k := "%d,%d,%d" % [int(c.r * 15.0), int(c.g * 15.0), int(c.b * 15.0)]
			seen[k] = int(seen.get(k, 0)) + 1
	var top := 0
	for k in seen: top = maxi(top, int(seen[k]))
	var share := 1.0 - float(top) / (48.0 * 27.0)
	print("FRAME @%.2f distinct %d non-dominant %.1f%%" % [sc, seen.size(), share * 100.0])
	if seen.size() < 8 or share < 0.05:
		_bad += 1; print("FAIL frame reads blank @", sc)

func _process(_d: float) -> bool:
	_f += 1
	if _f == 30:
		for r in ["", "junk", "starting", "common"]:
			if UiTheme.rarity_pip(r) != null: _bad += 1; print("FAIL bare rung has a pip: ", r)
		for r in UiTheme.RARITY_HUE:
			var p: Control = UiTheme.rarity_pip(r)
			var sb := p.get_theme_stylebox("panel") as StyleBoxFlat
			if p == null or sb.bg_color != UiTheme.RARITY_HUE[r]: _bad += 1; print("FAIL pip != art hue: ", r)
		var py := FileAccess.get_file_as_string("res://tools/art/icons.py")
		var m := RegEx.create_from_string("RARITY_HUE_PARCHMENT\\[\"uncommon\"\\]\\s*=\\s*\\(([0-9.]+),\\s*([0-9.]+),\\s*([0-9.]+)\\)").search(py)
		if m == null:
			_bad += 1; print("FAIL could not read RARITY_HUE_PARCHMENT from icons.py")
		else:
			var want := Color(float(m.get_string(1)), float(m.get_string(2)), float(m.get_string(3)))
			var got: Color = UiTheme.RARITY_HUE["uncommon"]
			if not got.is_equal_approx(want): _bad += 1; print("FAIL uncommon != art pewter ", got, want)
			else: print("uncommon == art pewter ", got)
		for r in UiTheme.RARITY_INK:
			_n += 1
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
		_check_frame(img, sc)
		_check_rows(sc)
		print("shot ", sc)
		_step += 1
		_s = null
		if _step >= 3:
			if _n == 0: print("U56_HUE NO VERDICT - 0 rows/rungs walked"); _bad += 1
			print("U56_HUE ", "OK" if _bad == 0 else "FAIL %d" % _bad, " walked=", _n)
			quit(0 if _bad == 0 else 1)
	return false
