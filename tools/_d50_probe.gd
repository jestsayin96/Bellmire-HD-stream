extends SceneTree
## D50 PROBE - how many ordinary townsfolk are effectively FROZEN (no travel over
## the window), how long their route stays empty, and the LOD spread of visible
## folk (the stutter band). No fix; measures the complaint. Writes to stdout.
var _t
var _f := 0
var _track := {}      # id -> {start, maxd, empty, samp, lod0,lod1,lod2, near_svc}
var _ids: Array = []
func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
func _ordinary(p) -> bool:
	return p is Townsfolk and p.rank < 0 and not p.stay and p.leader == null and p.cart == null
func _sample() -> void:
	var mk = _t.get("_market_pos"); var tv = _t.get("tavern_at")
	for p in _t.get("people"):
		if not is_instance_valid(p) or not _ordinary(p): continue
		var id: int = p.get_instance_id()
		var pos: Vector3 = p.global_position
		if not _track.has(id):
			var near := false
			_track[id] = {"start":pos,"maxd":0.0,"empty":0,"samp":0,"l0":0,"l1":0,"l2":0,"name":String(p.person_name),"role":String(p.role)}
		var r: Dictionary = _track[id]
		r["samp"] += 1
		var d: float = (pos - (r["start"] as Vector3)).length()
		if d > float(r["maxd"]): r["maxd"] = d
		if (p.get("_route") as Array).is_empty(): r["empty"] += 1
		var lv: int = int(p.get("lod"))
		r["l%d"%lv] += 1
func _process(_dt: float) -> bool:
	_f += 1
	if _f % 60 == 0 and _f >= 180:   # ~1s cadence after warmup
		_sample()
	if _f >= 60*95:
		_report()
		return true
	return false
func _report() -> void:
	var n := _track.size()
	var frozen := 0; var barely := 0; var movers := 0
	var lodsum := [0,0,0]
	var frozen_list: Array = []
	for id in _track:
		var r: Dictionary = _track[id]
		lodsum[0]+=r["l0"]; lodsum[1]+=r["l1"]; lodsum[2]+=r["l2"]
		var md: float = float(r["maxd"])
		if md < 2.0:
			frozen += 1
			if frozen_list.size() < 12: frozen_list.append("%s/%s maxd=%.1f empty=%d/%d lod=[%d,%d,%d]" % [r["name"],r["role"],md,r["empty"],r["samp"],r["l0"],r["l1"],r["l2"]])
		elif md < 8.0: barely += 1
		else: movers += 1
	print("D50_PROBE ordinary=%d  frozen(<2m)=%d  barely(2-8m)=%d  movers(>8m)=%d" % [n,frozen,barely,movers])
	var tot: float = float(lodsum[0]+lodsum[1]+lodsum[2])
	if tot>0:
		print("D50_PROBE lod_share lod0=%.0f%% lod1=%.0f%% lod2=%.0f%%" % [100*lodsum[0]/tot,100*lodsum[1]/tot,100*lodsum[2]/tot])
	for s in frozen_list:
		print("  FROZEN ", s)
	quit()
