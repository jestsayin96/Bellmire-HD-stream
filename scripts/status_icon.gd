extends Control
## L31 remainder: a delver's state as an ICON, not only a word. A round ink-rimmed
## badge in the state's own colour (data/potions.json `states`.colour - nothing
## restated here) with a glyph drawn per state key. Bad states get a red rim so
## "something is wrong with this hero" reads at stream distance before the word does.
## Unknown keys still draw: the badge and the first letter of the word, never blank.

var key := ""
var word := ""
var col := Color.WHITE
var bad := false

func setup(k: String, w: String, c: Color, is_bad: bool, d: float) -> Control:
	key = k
	word = w
	col = c
	bad = is_bad
	custom_minimum_size = Vector2(d, d)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_text = w
	return self

func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := Vector2(s, s) * 0.5
	var r := s * 0.5
	var ink := Color(0.10, 0.07, 0.05)
	draw_circle(c, r, Color(0.78, 0.16, 0.12) if bad else ink)
	draw_circle(c, r * 0.84, col.darkened(0.15))
	var g := ink
	var w := maxf(1.5, s * 0.09)
	var u := r * 0.55
	match key:
		"poisoned":   # a drop
			draw_circle(c + Vector2(0, u * 0.35), u * 0.55, g)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -u), c + Vector2(-u * 0.5, u * 0.2), c + Vector2(u * 0.5, u * 0.2)]), g)
		"burning", "resist_fire":   # a flame
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -u), c + Vector2(u * 0.6, u * 0.2), c + Vector2(u * 0.3, u * 0.8), c + Vector2(-u * 0.3, u * 0.8), c + Vector2(-u * 0.6, u * 0.2)]), g)
			if key == "resist_fire":
				draw_line(c + Vector2(-u, u), c + Vector2(u, -u), Color(1, 1, 1, 0.9), w)
		"slowed", "resist_frost":   # a snowflake
			for i in 3:
				var a := PI / 3.0 * i
				var v := Vector2(cos(a), sin(a)) * u
				draw_line(c - v, c + v, g, w)
			if key == "resist_frost":
				draw_arc(c, u * 1.05, 0, TAU, 20, g, w * 0.7)
		"blinded":   # an eye struck through
			draw_arc(c + Vector2(0, u * 0.6), u * 1.1, PI * 1.2, PI * 1.8, 10, g, w)
			draw_arc(c - Vector2(0, u * 0.6), u * 1.1, PI * 0.2, PI * 0.8, 10, g, w)
			draw_line(c + Vector2(-u, -u), c + Vector2(u, u), g, w)
		"frightened":   # a wide-open mouth and two eyes
			draw_circle(c + Vector2(-u * 0.45, -u * 0.35), u * 0.2, g)
			draw_circle(c + Vector2(u * 0.45, -u * 0.35), u * 0.2, g)
			draw_circle(c + Vector2(0, u * 0.45), u * 0.35, g)
		"haste":   # two chevrons
			for dx in [-0.45, 0.35]:
				draw_polyline(PackedVector2Array([c + Vector2((dx - 0.3) * u, -u * 0.7), c + Vector2((dx + 0.3) * u, 0), c + Vector2((dx - 0.3) * u, u * 0.7)]), g, w)
		"giant":   # a fist-up arrow
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -u), c + Vector2(u * 0.8, 0), c + Vector2(-u * 0.8, 0)]), g)
			draw_rect(Rect2(c + Vector2(-u * 0.3, 0), Vector2(u * 0.6, u * 0.9)), g)
		"invisible":   # a dashed ring
			for i in 8:
				var a0 := TAU / 8.0 * i
				draw_arc(c, u * 0.85, a0, a0 + TAU / 16.0, 4, g, w)
		"heroism":   # a star
			var pts := PackedVector2Array()
			for i in 10:
				var a := -PI / 2.0 + PI / 5.0 * i
				pts.append(c + Vector2(cos(a), sin(a)) * (u if i % 2 == 0 else u * 0.42))
			draw_colored_polygon(pts, g)
		"darkvision":   # an open eye
			draw_arc(c + Vector2(0, u * 0.6), u * 1.1, PI * 1.2, PI * 1.8, 10, g, w)
			draw_arc(c - Vector2(0, u * 0.6), u * 1.1, PI * 0.2, PI * 0.8, 10, g, w)
			draw_circle(c, u * 0.3, g)
		"warded":   # a shield
			draw_colored_polygon(PackedVector2Array([c + Vector2(-u * 0.75, -u * 0.8), c + Vector2(u * 0.75, -u * 0.8), c + Vector2(u * 0.65, u * 0.2), c + Vector2(0, u), c + Vector2(-u * 0.65, u * 0.2)]), g)
		"regenerating":   # a cross
			draw_rect(Rect2(c + Vector2(-u * 0.25, -u * 0.8), Vector2(u * 0.5, u * 1.6)), g)
			draw_rect(Rect2(c + Vector2(-u * 0.8, -u * 0.25), Vector2(u * 1.6, u * 0.5)), g)
		"scar_touched":   # a jagged scar
			draw_polyline(PackedVector2Array([c + Vector2(-u * 0.8, -u * 0.7), c + Vector2(-u * 0.1, -u * 0.1), c + Vector2(-u * 0.4, u * 0.1), c + Vector2(u * 0.8, u * 0.8)]), g, w * 1.2)
		_:
			var f := get_theme_default_font()
			var t := word.substr(0, 1).to_upper() if word != "" else "?"
			var fs := int(s * 0.6)
			var ts := f.get_string_size(t, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
			draw_string(f, c + Vector2(-ts.x * 0.5, ts.y * 0.32), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, g)
