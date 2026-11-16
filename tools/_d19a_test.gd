extends SceneTree
## D19a: day/night verification. Drives Daylight.override_hour across the day and
## checks the sun arc/colour, dawn-dusk warmth, real night dark, and that the
## lamps/windows (and the new night bloom) rise after dark. Headless, no renders.
var _t: Node3D
var _f := 0
func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)

func _sample(dl, h: float) -> Dictionary:
	dl.override_hour = h
	dl._process(0.0)
	var lamp_e := -1.0
	for pair in dl._lights:
		if is_instance_valid(pair[0]):
			lamp_e = (pair[0] as OmniLight3D).light_energy
			break
	var glass_e := -1.0
	if not dl._glass.is_empty():
		glass_e = (dl._glass[0] as StandardMaterial3D).emission_energy_multiplier
	return {
		"night": dl.nightness(h), "gold": dl.goldness(h),
		"sun_e": dl.sun.light_energy, "sun_x": rad_to_deg(dl.sun.rotation.x),
		"amb_e": dl.env.ambient_light_energy, "glow": dl.env.glow_intensity,
		"lamp_e": lamp_e, "glass_e": glass_e,
	}

func _process(_d: float) -> bool:
	_f += 1
	if _f < 30:
		return false
	var dl = _t.get("daylight")
	if dl == null or dl.sun == null or dl.env == null:
		print("D19A_TEST FAIL: daylight not set up (dl=", dl, ")")
		return true
	var fails: Array = []
	if dl._lights.is_empty():
		fails.append("no town OmniLights captured")
	var noon := _sample(dl, 12.0)
	var dawn := _sample(dl, 6.0)
	var dusk := _sample(dl, 18.5)
	var night := _sample(dl, 22.0)
	var deep := _sample(dl, 2.0)
	# nightness shape
	if noon["night"] != 0.0: fails.append("nightness(noon) != 0")
	if deep["night"] < 0.99: fails.append("nightness(2am) not full")
	if dawn["night"] <= 0.0 or dawn["night"] >= 1.0: fails.append("nightness(dawn) not mid")
	# dawn/dusk warmth
	if dawn["gold"] < 0.5: fails.append("goldness(dawn) weak")
	if noon["gold"] > 0.2: fails.append("goldness(noon) too high")
	# sun arc + real night dark
	if noon["sun_e"] <= night["sun_e"]: fails.append("sun not brighter at noon than night")
	if noon["sun_x"] >= -20.0: fails.append("sun not high at noon (x=%.1f)" % noon["sun_x"])
	# lamps rise after dark
	if not dl._lights.is_empty() and night["lamp_e"] <= noon["lamp_e"]:
		fails.append("lamps not brighter at night")
	# windows glow at night (if any glass)
	if noon["glass_e"] >= 0.0 and night["glass_e"] <= noon["glass_e"]:
		fails.append("window emission not up at night")
	# night bloom
	if night["glow"] <= noon["glow"]: fails.append("glow not up at night")
	print("D19A samples:")
	for nm in [["noon",noon],["dawn",dawn],["dusk",dusk],["night",night],["2am",deep]]:
		var s = nm[1]
		print("  %-5s night=%.2f gold=%.2f sun_e=%.2f sun_x=%.0f amb=%.2f glow=%.2f lamp=%.2f glass=%.2f" % [nm[0], s["night"], s["gold"], s["sun_e"], s["sun_x"], s["amb_e"], s["glow"], s["lamp_e"], s["glass_e"]])
	print("D19A lights=", dl._lights.size(), " glass=", dl._glass.size())
	if fails.is_empty():
		print("D19A_TEST OK")
	else:
		print("D19A_TEST FAIL: ", fails)
	return true
