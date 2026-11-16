extends SceneTree
## D32 CURVE - measures the real levelling pace of the town under the new 12-tier
## ladder, no delves (so renown stays ~0 and this shows the POP-DRIVEN climb and
## its ceiling; the upper tiers are renown-gated by design). Logs one row per
## in-game day to user://_d32_curve.csv: day,pop,renown,score,level,name.
var _t
var _last_day := 0
var _rows: Array = []
var _founding_level := -1
var _err := false
func _initialize() -> void:
	Engine.time_scale = 15.0
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
func _process(_d: float) -> bool:
	var eco = _t.get("economy")
	if eco == null:
		return false
	if _founding_level < 0 and eco.town_level > 0 and eco.get("_founded"):
		_founding_level = eco.town_level
	var day: int = eco.day
	if day != _last_day:
		_last_day = day
		var row := "%d,%d,%d,%d,%d,%s" % [day, eco.population(), eco.renown, eco.town_score(), eco.town_level, eco.town_name]
		_rows.append(row)
		if day >= 30:
			_finish(eco)
			return true
	if Engine.get_process_frames() > 90000:
		_finish(eco)
		return true
	return false
func _finish(eco) -> void:
	var f := FileAccess.open("user://_d32_curve.csv", FileAccess.WRITE)
	f.store_line("day,pop,renown,score,level,name")
	for r in _rows:
		f.store_line(String(r))
	f.close()
	print("D32_CURVE founding_level=", _founding_level, " days=", _rows.size(),
		" final_level=", eco.town_level, " final_score=", eco.town_score(),
		" final_pop=", eco.population())
	print("D32_CURVE_CSV ", ProjectSettings.globalize_path("user://_d32_curve.csv"))
	quit()
