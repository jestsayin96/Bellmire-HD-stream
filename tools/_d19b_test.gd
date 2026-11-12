extends SceneTree
## D19b: atmosphere. The custom sky shader, the weather machine (clear/overcast/
## rain), fog by weather + morning mist, rain particles, volumetric light, the
## day_phase/weather names, and the snapshot's new additive fields. Headless.
var _t: Node3D
var _f := 0

func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)

func _process(_d: float) -> bool:
	_f += 1
	if _f < 30:
		return false
	var fails: Array = []
	var dl = _t.get("daylight")
	if dl == null or dl.env == null or dl.sun == null:
		print("D19B_TEST FAIL: daylight not set up")
		return true
	var sm = dl.env.sky.sky_material
	if not (sm is ShaderMaterial):
		fails.append("sky is not the custom ShaderMaterial")
	if not dl.env.volumetric_fog_enabled:
		fails.append("volumetric fog off")
	# weather forcing: rain is thicker, darker, dimmer, wetter than clear
	dl.override_hour = 12.0
	dl.set_weather("clear", true)
	dl._process(0.0)
	var clear_fog: float = dl.env.fog_density
	var clear_sun: float = dl.sun.light_energy
	var clear_cover: float = float(sm.get_shader_parameter("cloud_cover")) if sm is ShaderMaterial else 0.0
	var clear_emitting: bool = dl.rain != null and dl.rain.emitting
	dl.set_weather("rain", true)
	dl._process(0.0)
	var rain_fog: float = dl.env.fog_density
	var rain_sun: float = dl.sun.light_energy
	var rain_cover: float = float(sm.get_shader_parameter("cloud_cover")) if sm is ShaderMaterial else 0.0
	if rain_fog <= clear_fog * 2.0:
		fails.append("rain fog not thicker (%.5f vs %.5f)" % [rain_fog, clear_fog])
	if rain_sun >= clear_sun * 0.8:
		fails.append("rain sun not dimmer (%.2f vs %.2f)" % [rain_sun, clear_sun])
	if rain_cover <= clear_cover + 0.3:
		fails.append("rain clouds not heavier")
	if dl.rain == null or not dl.rain.emitting:
		fails.append("rain particles not emitting in rain")
	if clear_emitting:
		fails.append("rain particles emitting in clear")
	if String(dl.weather) != "rain":
		fails.append("weather name not rain")
	if String(dl.day_phase()) != "day":
		fails.append("day_phase(noon) != day")
	dl.set_weather("clear", true)
	dl._process(0.0)
	if dl.rain and dl.rain.emitting:
		fails.append("rain still emitting after clear")
	# stars at night, none at noon; the phases name themselves
	dl.override_hour = 23.0
	dl._process(0.0)
	var st_n: float = float(sm.get_shader_parameter("stars")) if sm is ShaderMaterial else -1.0
	if String(dl.day_phase()) != "night":
		fails.append("day_phase(23h) != night")
	dl.override_hour = 12.0
	dl._process(0.0)
	var st_d: float = float(sm.get_shader_parameter("stars")) if sm is ShaderMaterial else -1.0
	if st_n < 0.9 or st_d > 0.05:
		fails.append("stars wrong (night %.2f noon %.2f)" % [st_n, st_d])
	dl.override_hour = 6.2
	dl._process(0.0)
	if String(dl.day_phase()) != "dawn":
		fails.append("day_phase(6.2) != dawn")
	dl.override_hour = 18.4
	dl._process(0.0)
	if String(dl.day_phase()) != "dusk":
		fails.append("day_phase(18.4) != dusk")
	# the dawn mist: fog at the gold hour beats noon fog in the same weather
	var dawn_fog: float = 0.0
	dl.override_hour = 6.2
	dl._process(0.0)
	dawn_fog = dl.env.fog_density
	if dawn_fog <= clear_fog:
		fails.append("no morning mist (%.5f vs %.5f)" % [dawn_fog, clear_fog])
	# the machine picks every weather eventually
	var seen := {}
	for i in 60:
		seen[dl._pick_weather()] = true
	if seen.size() < 3:
		fails.append("weather machine stuck: " + str(seen.keys()))
	# the snapshot's new fields (all additive, v stays 1)
	var r = _t.get("roster")
	if r and r.heroes.is_empty():
		r.fresh("9009", "D19bProbe", "knight", "dwarf")
	var sp := SnapshotPublisher.new()
	sp.key_file = "user://_d19b_no_key.json"
	root.add_child(sp)
	sp.setup(_t)
	dl.override_hour = 12.0
	dl.set_weather("clear", true)
	dl._process(0.0)
	var p: Dictionary = sp.build_payload()
	if int(p.get("v", -1)) != 1:
		fails.append("payload v changed")
	var tb: Dictionary = p.get("town", {})
	for k in ["raids_turned", "day_phase", "weather"]:
		if not tb.has(k):
			fails.append("town block missing " + str(k))
	if String(tb.get("day_phase", "")) != "day" or String(tb.get("weather", "")) != "clear":
		fails.append("town block phase/weather wrong: " + str(tb.get("day_phase")) + "/" + str(tb.get("weather")))
	if typeof(tb.get("raids_turned")) != TYPE_INT and typeof(tb.get("raids_turned")) != TYPE_FLOAT:
		fails.append("raids_turned not a number")
	var hs: Array = p.get("heroes", [])
	if hs.is_empty():
		fails.append("no hero sheet to check")
	else:
		var s0: Dictionary = hs[0]
		if int(s0.get("max_hp", 0)) <= 0:
			fails.append("sheet max_hp missing")
		if int(s0.get("xp_next", 0)) <= 0:
			fails.append("sheet xp_next missing")
		if int(s0.get("hp", 0)) != int(s0.get("max_hp", -1)):
			fails.append("hp and max_hp disagree at rest")
	print("D19B samples: clear fog=%.5f sun=%.2f cover=%.2f | rain fog=%.5f sun=%.2f cover=%.2f | stars night=%.2f noon=%.2f | dawn mist=%.5f" % [
		clear_fog, clear_sun, clear_cover, rain_fog, rain_sun, rain_cover, st_n, st_d, dawn_fog])
	if fails.is_empty():
		print("D19B_TEST OK")
	else:
		print("D19B_TEST FAIL: ", fails)
	return true
