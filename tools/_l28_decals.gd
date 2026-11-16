extends SceneTree
## L28d: generates the dungeon detail-decal textures (self-made, CC0 - see docs/ASSETS.md):
##   godot --headless --path . --script tools/_l28_decals.gd
## writes assets/dungeon_look/decal_<kind>.png (256x256 RGBA, alpha = coverage):
##   crack  - dark branching fissures            (all floors)
##   moss   - green clumps with a soft edge       (wood, grassland, flooded)
##   blood  - a dried splat with drops and smear  (prison, barracks, crypt)
##   soot   - a scorch with a ragged black heart  (firepit, workshop)
##   veins  - white branching lines (+ decal_veins_glow: the same premultiplied on black, for emission)
## Deterministic (fixed seeds): re-running writes the same pixels.
const OUT := "res://assets/dungeon_look/"
const S := 256

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_save("crack", _lines(11, Color(0.04, 0.035, 0.03), 3, 2.6, 0.9))
	var vein := _lines(23, Color(1, 1, 1), 4, 1.7, 1.0)
	_save("veins", vein)
	_save("veins_glow", _premul(vein))
	_save("moss", _moss(5))
	_save("blood", _blood(7))
	_save("soot", _soot(13))
	print("L28_DECALS done")
	quit()

func _save(kind: String, im: Image) -> void:
	im.generate_mipmaps()
	im.clear_mipmaps()
	im.save_png(ProjectSettings.globalize_path(OUT + "decal_%s.png" % kind))
	print("L28_DECALS wrote decal_%s.png" % kind)

func _blank() -> Image:
	return Image.create(S, S, false, Image.FORMAT_RGBA8)

## soft round falloff 1 at the centre -> 0 at the rim (decals never show a square edge)
func _fall(x: float, y: float, r := 0.48) -> float:
	var d := Vector2(x / S - 0.5, y / S - 0.5).length() / r
	return clampf(1.0 - d * d, 0.0, 1.0)

## branching fissures: random walks that fork, drawn as soft discs; alpha also fades at the rim
func _lines(seed_i: int, col: Color, roots: int, width: float, alpha: float) -> Image:
	var r := RandomNumberGenerator.new()
	r.seed = seed_i
	var acc := PackedFloat32Array()
	acc.resize(S * S)
	var walkers: Array = []
	for i in roots:
		var a := r.randf() * TAU
		walkers.append([Vector2(S * 0.5, S * 0.5) + Vector2(cos(a), sin(a)) * r.randf_range(0, 20), a, width, 150 + r.randi() % 90])
	while not walkers.is_empty():
		var w: Array = walkers.pop_back()
		var p: Vector2 = w[0]
		var a: float = w[1]
		var wd: float = w[2]
		for step in int(w[3]):
			a += r.randf_range(-0.35, 0.35)
			p += Vector2(cos(a), sin(a)) * clampf(wd * 0.7, 0.5, 1.4)
			if p.x < 2 or p.y < 2 or p.x > S - 3 or p.y > S - 3:
				break
			_disc(acc, p, wd)
			if r.randf() < 0.015 and wd > 0.9:
				walkers.append([p, a + r.randf_range(0.6, 1.1) * (1.0 if r.randf() < 0.5 else -1.0), wd * 0.65, 50 + r.randi() % 70])
			wd = maxf(0.7, wd * 0.997)
	var im := _blank()
	for y in S:
		for x in S:
			var v := clampf(acc[y * S + x], 0.0, 1.0) * _fall(x, y) * alpha
			im.set_pixel(x, y, Color(col.r, col.g, col.b, v))
	return im

func _disc(acc: PackedFloat32Array, p: Vector2, rad: float) -> void:
	var ri := int(ceil(rad + 1.0))
	for dy in range(-ri, ri + 1):
		for dx in range(-ri, ri + 1):
			var x := int(p.x) + dx
			var y := int(p.y) + dy
			if x < 0 or y < 0 or x >= S or y >= S:
				continue
			var d := Vector2(x + 0.5, y + 0.5).distance_to(p)
			var v := clampf(rad + 0.5 - d, 0.0, 1.0)
			acc[y * S + x] = maxf(acc[y * S + x], v)

func _noise(seed_i: int, freq: float, oct := 4) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.seed = seed_i
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = freq
	n.fractal_type = FastNoiseLite.FRACTAL_FBM
	n.fractal_octaves = oct
	return n

func _moss(seed_i: int) -> Image:
	var big := _noise(seed_i, 0.012)
	var fine := _noise(seed_i + 1, 0.09, 2)
	var im := _blank()
	for y in S:
		for x in S:
			var v := (big.get_noise_2d(x, y) * 0.5 + 0.5) * 1.6 - 0.35 + fine.get_noise_2d(x, y) * 0.25
			var a := clampf((v - 0.35) * 3.0, 0.0, 1.0) * _fall(x, y, 0.5)
			var t := clampf(fine.get_noise_2d(x + 99, y) * 0.5 + 0.5, 0.0, 1.0)
			var c := Color(0.16, 0.30, 0.10).lerp(Color(0.38, 0.52, 0.16), t)
			im.set_pixel(x, y, Color(c.r, c.g, c.b, a * 0.92))
	return im

func _blood(seed_i: int) -> Image:
	var r := RandomNumberGenerator.new()
	r.seed = seed_i
	var edge := _noise(seed_i, 0.03, 3)
	var acc := PackedFloat32Array()
	acc.resize(S * S)
	var blobs: Array = [[Vector2(S * 0.5, S * 0.5), 46.0]]
	for i in 14:                       # drops thrown out from the heart
		var a := r.randf() * TAU
		var d := r.randf_range(55, 105)
		blobs.append([Vector2(S * 0.5, S * 0.5) + Vector2(cos(a), sin(a)) * d, r.randf_range(3, 9)])
	var sa := r.randf() * TAU            # one smear dragged away
	for k in 30:
		blobs.append([Vector2(S * 0.5, S * 0.5) + Vector2(cos(sa), sin(sa)) * (20.0 + k * 2.6), 20.0 - k * 0.5])
	for y in S:
		for x in S:
			var m := 0.0
			for b in blobs:
				var bp: Vector2 = b[0]
				var rr: float = b[1] * (1.0 + edge.get_noise_2d(x, y) * 0.45)
				m = maxf(m, clampf((rr - Vector2(x, y).distance_to(bp)) / 3.0, 0.0, 1.0))
			acc[y * S + x] = m
	var im := _blank()
	var tone := _noise(seed_i + 3, 0.05, 2)
	for y in S:
		for x in S:
			var t := clampf(tone.get_noise_2d(x, y) * 0.5 + 0.5, 0.0, 1.0)
			var c := Color(0.20, 0.015, 0.01).lerp(Color(0.38, 0.03, 0.02), t)
			im.set_pixel(x, y, Color(c.r, c.g, c.b, acc[y * S + x] * 0.88 * _fall(x, y, 0.52)))
	return im

func _soot(seed_i: int) -> Image:
	var n := _noise(seed_i, 0.02, 5)
	var im := _blank()
	for y in S:
		for x in S:
			var f := _fall(x, y, 0.5)
			var v := clampf(f * 1.25 + n.get_noise_2d(x, y) * 0.55 - 0.25, 0.0, 1.0)
			im.set_pixel(x, y, Color(0.03, 0.025, 0.02, v * 0.85))
	return im

## emission mask for a decal: colour x alpha on black, opaque (a decal's emission ignores alpha)
func _premul(src: Image) -> Image:
	var im := _blank()
	for y in S:
		for x in S:
			var c := src.get_pixel(x, y)
			im.set_pixel(x, y, Color(c.r * c.a, c.g * c.a, c.b * c.a, 1.0))
	return im
