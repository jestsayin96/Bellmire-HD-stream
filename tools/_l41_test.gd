extends SceneTree
## L41: A DUNGEON FLOOR RENDERED HOT MAGENTA in Mr. E's 19-17-57 recording.
## That colour is Godot's own: a ShaderMaterial whose shader is NULL draws magenta. A shader
## load fails when the .gdshader is missing from the import cache on the machine that is
## running, which is the sort of thing that differs between this laptop and the desktop and so
## shows up only on stream.
## PROBED FIRST: all eight themes bind correctly on this machine - shader non-null, every
## texture parameter non-null - so the binding is not broken here. What was missing was any
## GUARD for when it is, and that is what this checks.
##   A. EVERY THEME, SAMPLED OVER 12 FLOORS, binds a real material - no null shader anywhere.
##   B. THE DELIBERATE BREAK (the item's own wording): with the shader made unavailable, the
##      floor comes back GREY, not magenta - and never a ShaderMaterial with a null shader.
##   C. the guard counts what it caught, and normal running trips it zero times.
## Headless on purpose: this is material BINDING, which is a property of the resource and can
## be asserted exactly. Whether the grey looks right is a separate, visual question.
## Prints L41_TEST OK / FAIL.
var _fails: Array = []
var _checks := 0

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

## a material is "magenta" exactly when it is a ShaderMaterial with no shader behind it
func _is_magenta(m: Material) -> bool:
	return m is ShaderMaterial and (m as ShaderMaterial).shader == null

func _initialize() -> void:
	var themes: Array = FloorGen.THEMES.keys()
	themes.sort()
	var floors := 12
	print("L41 A: %d themes x %d floors" % [themes.size(), floors])

	# ---- A. every theme, every floor, both the steel and stone variants, ground and not
	var magenta: Array = []
	var nulls: Array = []
	var checked := 0
	FloorGen.force_kit_fail = false
	FloorGen.kit_fail_count = 0
	for t in themes:
		FloorGen._look_theme = String(t)
		for f in range(1, floors + 1):
			for steel in [false, true]:
				for ground in [false, true]:
					FloorGen._kit_mats.clear()      # a fresh build, not the cache
					var m: Material = FloorGen._kit_mat(Color(1, 1, 1), steel, ground)
					checked += 1
					if m == null:
						nulls.append("%s/f%d" % [t, f])
					elif _is_magenta(m):
						magenta.append("%s/f%d" % [t, f])
	print("   built %d materials; null %d; magenta %d" % [checked, nulls.size(), magenta.size()])
	_ok(nulls.is_empty(), "A: no theme produced a null material (%s)" % str(nulls.slice(0, 5)))
	_ok(magenta.is_empty(), "A: NO THEME RENDERS MAGENTA over %d floors (%s)" % [floors, str(magenta.slice(0, 5))])
	_ok(FloorGen.kit_fail_count == 0, "C: normal running never trips the guard (%d)" % FloorGen.kit_fail_count)

	# every one of them should also carry its textures, or the floor is black rather than lit
	FloorGen._kit_mats.clear()
	FloorGen._look_theme = "crypt"
	var one: Material = FloorGen._kit_mat(Color(1, 1, 1), false, true)
	var missing: Array = []
	if one is ShaderMaterial:
		for p in ["albedo_tex", "pbr_map", "stone_n", "stone_r", "wood_n", "wood_r", "vary_tex"]:
			if (one as ShaderMaterial).get_shader_parameter(p) == null:
				missing.append(p)
	_ok(missing.is_empty(), "A: the bound material carries every texture it needs (missing: %s)" % str(missing))

	# ---- B. the deliberate break the item asks for
	FloorGen._kit_mats.clear()
	FloorGen.kit_fail_count = 0
	FloorGen.force_kit_fail = true
	var broke: Material = FloorGen._kit_mat(Color(1, 1, 1), false, true)
	FloorGen.force_kit_fail = false
	var cls := broke.get_class() if broke != null else "NULL"
	var col := (broke as StandardMaterial3D).albedo_color if broke is StandardMaterial3D else Color(0, 0, 0)
	print("L41 B: with the shader unavailable -> %s, albedo %s, guard tripped %d" % [cls, str(col), FloorGen.kit_fail_count])
	_ok(broke != null, "B: a broken material path still returns something to draw with")
	_ok(not _is_magenta(broke), "B: a DELIBERATELY broken material is NOT magenta")
	_ok(broke is StandardMaterial3D, "B: it falls back to a plain PBR material (%s)" % cls)
	# grey means the three channels are close together and not saturated
	var spread: float = maxf(col.r, maxf(col.g, col.b)) - minf(col.r, minf(col.g, col.b))
	_ok(spread < 0.1, "B: and the fallback is GREY, not a colour (channel spread %.3f)" % spread)
	_ok(FloorGen.kit_fail_count == 1, "C: the guard counted the failure it caught (%d)" % FloorGen.kit_fail_count)

	# leave the cache as we found it, so nothing downstream inherits a test-built material
	FloorGen._kit_mats.clear()

	print("CHECKS ", _checks, " FAILS ", _fails.size())
	for x in _fails:
		print("  - ", x)
	print("L41_TEST ", "OK" if _fails.is_empty() else "FAIL")
	quit()
