extends SceneTree
## L28b "no two alike": every theme's room shot (all_<theme>_after_room.png) is boiled down
## to an 8x8 colour thumbnail; prints each theme's nearest neighbour and the closest pair.
## Distance = mean per-cell RGB distance (0..1.7). Prints L28_ALIKE OK when the closest pair
## is further apart than MIN.
const DIR := "res://renders/cycles/20261112_l28/"
const MIN := 0.08
const MIN_PAL := 0.05     # mean colour of the whole frame (palette only, layout ignored)
func _initialize() -> void:
	var th: Array = FloorGen.all_themes().keys()
	var v := {}
	for t in th:
		var im := Image.load_from_file(ProjectSettings.globalize_path(DIR + "all_%s_after_room.png" % t))
		if im == null:
			continue
		im.convert(Image.FORMAT_RGB8)
		im.resize(8, 8, Image.INTERPOLATE_BILINEAR)
		v[t] = im
	var pal_worst := 9.0
	var pal_pair := ""
	for a in v:
		for b in v:
			if String(a) >= String(b):
				continue
			var ia: Image = (v[a] as Image).duplicate()
			var ib: Image = (v[b] as Image).duplicate()
			ia.resize(1, 1, Image.INTERPOLATE_BILINEAR)
			ib.resize(1, 1, Image.INTERPOLATE_BILINEAR)
			var pa := ia.get_pixel(0, 0)
			var pb := ib.get_pixel(0, 0)
			var pd := Vector3(pa.r - pb.r, pa.g - pb.g, pa.b - pb.b).length()
			if pd < pal_worst:
				pal_worst = pd
				pal_pair = "%s ~ %s" % [a, b]
	var worst := 9.0
	var pair := ""
	for a in v:
		var near := 9.0
		var who := ""
		for b in v:
			if a == b:
				continue
			var d := 0.0
			for y in 8:
				for x in 8:
					var ca: Color = (v[a] as Image).get_pixel(x, y)
					var cb: Color = (v[b] as Image).get_pixel(x, y)
					d += Vector3(ca.r - cb.r, ca.g - cb.g, ca.b - cb.b).length()
			d /= 64.0
			if d < near:
				near = d
				who = b
		print("  %-11s nearest %-11s %.3f" % [a, who, near])
		if near < worst:
			worst = near
			pair = "%s ~ %s" % [a, who]
	print("  palette: closest pair %s at %.3f (min %.2f)" % [pal_pair, pal_worst, MIN_PAL])
	print("L28_ALIKE %s: %d themes, closest pair %s at %.3f (min %.2f)" % ["OK" if worst > MIN and pal_worst > MIN_PAL and v.size() == th.size() else "FAIL", v.size(), pair, worst, MIN])
	quit()
