extends SceneTree
## D29 WORK-SOUND TEST. The silent-town complaint named footsteps, voices, WORK
## and combat. D42 gave footfalls + voices; this checks the WORK layer town.gd
## adds: the smith's anvil (a "hit" at the blacksmith yard) and market trade (a
## "coin" over the square), station-based, daytime only. Headless - audio is
## COUNTED, not heard: town.work_plays + Sfx.live().plays. No camera needed (the
## work sounds are not tied to the roaming director). Env D29_SECS (wall soak,
## default 25), D29_SCALE (time scale, default 8). Prints D29_TEST OK/FAIL.
var _t: Node3D
var _f := 0
var _t0 := 0
var _secs := 25.0
var _scale := 8.0

func _initialize() -> void:
	var s := OS.get_environment("D29_SECS")
	if s != "": _secs = maxf(5.0, float(s))
	var sc := OS.get_environment("D29_SCALE")
	if sc != "": _scale = maxf(1.0, float(sc))
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	print("D29_TEST start secs=%.0f scale=%.0f" % [_secs, _scale])

func _process(_dt: float) -> bool:
	_f += 1
	if _f == 30:
		Engine.time_scale = _scale
		_t0 = Time.get_ticks_msec()
	if _f < 30:
		return false
	if Time.get_ticks_msec() - _t0 < int(_secs * 1000.0):
		return false
	_report()
	return true

func _report() -> void:
	Engine.time_scale = 1.0
	var sfx = Sfx.live()
	var plays: Dictionary = sfx.plays if sfx else {}
	var wp := int(_t.get("work_plays"))
	var hits := int(plays.get("hit", 0))
	var coins := int(plays.get("coin", 0))
	var eco = _t.get("economy")
	var night := bool(eco.is_night()) if eco else false
	print("D29 work_plays=%d  Sfx hit=%d coin=%d  (night=%s)" % [wp, hits, coins, night])
	var ok := wp > 0 and hits > 0 and coins > 0
	print("D29_TEST %s (work>0:%s smith_hit>0:%s market_coin>0:%s)" % ["OK" if ok else "FAIL", wp > 0, hits > 0, coins > 0])
