extends SceneTree
## S28: the miniboss fit table against the bodies on disk. Goes RED if a lead-handed ratio is not
## what Delve.miniboss_ratio() answers for the real .glb path, if a handed body has no model, or if
## fewer than 30 bodies were checked (an empty directory must not read green). Names every body on
## disk that falls back to 1.0 because no ratio was handed for it.
## S28_EXPECT_GREENER overrides the expected greener ratio (used only to prove the gate goes red).
func _initialize() -> void:
	var want := {"greener": 1.02, "dyer": 1.06, "tanner": 1.12, "strickler": 1.04, "pressman": 1.16, "tapster": 1.14}
	var ov := OS.get_environment("S28_EXPECT_GREENER")
	if ov != "":
		want["greener"] = float(ov)
	var fails: Array = []
	for k: String in want:
		var p := Delve.miniboss_model(k)
		if p == "":
			fails.append("%s: no model on disk" % k)
			continue
		var r := Delve.miniboss_ratio(k, p)
		print("MB_FIT_ROW %s %s ratio=%.2f want=%.2f" % [k, p.get_file(), r, want[k]])
		if absf(r - float(want[k])) > 0.0001:
			fails.append("%s: ratio %.2f != %.2f" % [k, r, want[k]])
	var n := 0
	var fallback: Array = []
	var d := DirAccess.open(Delve.MB_DIR)
	if d == null:
		fails.append("cannot open " + Delve.MB_DIR)
	else:
		for f: String in d.get_files():
			if not f.ends_with(".glb"):
				continue
			n += 1
			var stem := f.get_basename()
			var key := stem.trim_suffix("_chibi")
			if not Delve.MB_FIT.has(stem) and not Delve.MB_FIT.has(key):
				fallback.append(stem)
	if n < 30:
		fails.append("only %d bodies checked (floor 30)" % n)
	print("MB_FIT_FALLBACK_1.0 ", fallback)
	if fails.is_empty():
		print("MB_FIT_VERDICT OK (%d bodies on disk, %d handed ratios proved, %d fall back to 1.0)" % [n, want.size(), fallback.size()])
	else:
		print("MB_FIT_VERDICT FAIL ", fails)
	quit()
