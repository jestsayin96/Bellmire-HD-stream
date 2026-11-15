extends SceneTree
## D63b - THE FESTIVAL TALKS, in C6's own words. Boots the REAL Bellmire, holds
## midday, and feeds the town the C6 "festivals" pool: from the file named by env
## D63_LORE (the content branch's lore_lines.json) when set, else from
## res://data/lore_lines.json if it already carries "festivals", else a small
## fixture in C6's exact shape. Then:
##  A  every reason's OPENING comes from C6 reasons.<key> (market -> harvest).
##  B  a market festival runs: festival-goers say crowd/toast lines in their own
##     bubbles (not the feed), the Chronicle gets stalls -> notable -> E3PO in turn,
##     E3PO says his in his bubble; the CLOSING is a C6 closing.
##  C  a viewer's festival opens from viewer_paid.openings with {buyer} filled in,
##     its talk reads viewer_paid, its closing is viewer_paid.closings.
## Prints D63B_TALK OK. Writes renders/cycles/d63/talk_test.txt.
var _t: Node3D
var _f := 0
var _fails := 0
var _log: Array = []
var _phase := "boot"
var _mark := 0
var _fl: Dictionary = {}
var _src := ""
var _said0 := 0
var _feed0 := 0

func _check(name: String, ok: bool) -> void:
	var s := ("PASS " if ok else "FAIL ") + name
	print(s)
	_log.append(s)
	if not ok:
		_fails += 1

func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)

func _load_lore() -> void:
	var paths: Array = []
	if OS.get_environment("D63_LORE") != "":
		paths.append(OS.get_environment("D63_LORE"))
	paths.append("res://data/lore_lines.json")
	for p in paths:
		var f := FileAccess.open(p, FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if d is Dictionary and (d as Dictionary).get("festivals") is Dictionary:
				_fl = d["festivals"]
				_src = p
				return
	_src = "fixture"
	_fl = {"reasons": {"harvest": ["FX harvest"], "raid_survived": ["FX raid"], "lord_felled": ["FX lord"],
		"hero_home": ["FX hero {who}"], "town_level": ["FX level"], "viewer_gift": ["FX gift {buyer}"]},
		"crowd": ["FX crowd"], "toasts": ["FX toast"], "stalls": ["FX stall"],
		"notables": [{"who": "Agnes Gatewood", "line": "FX notable"}], "e3po": ["FX e3po"], "closings": ["FX close"],
		"viewer_paid": {"openings": ["FXV open {buyer}"], "crowd": ["FXV crowd {buyer}"], "toasts": ["FXV toast {buyer}"],
			"stalls": ["FXV stall {buyer}"], "e3po": ["FXV e3po {buyer}"],
			"notables": [{"who": "Agnes Gatewood", "line": "FXV notable {buyer}"}], "closings": ["FXV close {buyer}"]}}

func _strs(a) -> Array:
	var out: Array = []
	for x in a:
		out.append(String(x["line"]) if x is Dictionary else String(x))
	return out

func _in(line: String, pool: Array, buyer := "") -> bool:
	for p in pool:
		if String(p).format({"buyer": buyer, "who": "a hero", "town": ""}) == line:
			return true
		if buyer == "" and String(p) == line:
			return true
	return false

func _bubbles() -> Array:
	var out: Array = []
	for p in (_t.get("people") as Array):
		if is_instance_valid(p) and p.get("said_once") > 0 and p.get("_shout") != null:
			out.append(String(p._shout.text).trim_prefix("\"").trim_suffix("\""))
	return out

func _process(_d: float) -> bool:
	_f += 1
	var eco = _t.get("economy")
	if eco and _f > 30:
		eco.clock = 0.50
		eco._dis_cool = 1e9
	var rd = _t.get("raids")
	if rd and _f > 30:
		rd.set("_raid_t", 9999.0)
	match _phase:
		"boot":
			if _f == 600:
				_load_lore()
				_t.set("_fest_lore", _fl)
				_t.set("_fest_lore_ok", true)
				_check("0 C6 pool loaded from %s (%d keys)" % [_src, _fl.size()], _fl.has("reasons") and _fl.has("viewer_paid"))
				# A: every reason's opening
				var m := {"market": "harvest", "raid": "raid_survived", "level": "town_level", "hero": "hero_home"}
				for r in m:
					var pool: Array = _strs(_fl["reasons"][m[r]])
					var got := String(_t.call("_fest_pick", "openings", r))
					_check("A %s opens from reasons.%s: %s" % [r, m[r], got.left(70)], _in(got, pool))
				_t.set("festival", false)
				_t.set("_fest_gap", 999.0)
				_feed0 = (_t.get("feed") as Array).size()
				_check("B0 market festival starts", bool(_t.call("start_festival", "market")))
				var fd: Array = _t.get("feed")
				_check("B1 its Chronicle line is a C6 harvest opening", _in(String(fd[_feed0]), _strs(_fl["reasons"]["harvest"])))
				_phase = "B_run"
				_mark = _f
		"B_run":
			if (_f - _mark) % 60 == 0:
				_t.set("_fest_left", 999.0)
				_t.set("_fest_news_t", minf(float(_t.get("_fest_news_t")), 1.0))
				_t.set("_fest_bark_t", minf(float(_t.get("_fest_bark_t")), 0.5))   # the test hurries the talk
			if _f - _mark == 1500:
				_check("B2 festival-goers raised %d lines in their own bubbles" % int(_t.get("fest_barks")), int(_t.get("fest_barks")) >= 3)
				var crowd: Array = _strs(_fl["crowd"]) + _strs(_fl["toasts"])
				var bs := _bubbles()
				var ok_b := not bs.is_empty()
				for b in bs:
					if not _in(b, crowd):
						ok_b = false
						print("  stray bubble: ", b)
				_check("B3 every bubble is a C6 crowd/toast line (%d seen)" % bs.size(), ok_b)
				var fd: Array = (_t.get("feed") as Array).slice(_feed0)
				var st := false
				var nb := false
				var e3 := false
				for l in fd:
					st = st or _in(String(l), _strs(_fl["stalls"]))
					nb = nb or _in(String(l), _strs(_fl["notables"]))
					e3 = e3 or _in(String(l), _strs(_fl["e3po"]))
				_check("B4 the Chronicle got a stall, a notable and E3PO (%s/%s/%s, news=%d)" % [st, nb, e3, int(_t.get("fest_news"))], st and nb and e3)
				var crowd_in_feed := false
				for l in fd:
					crowd_in_feed = crowd_in_feed or _in(String(l), _strs(_fl["crowd"]))
				_check("B5 crowd lines stay OFF the Chronicle", not crowd_in_feed)
				var nt = _t.get("notables")
				var e3b := false
				if nt and nt.get("_e3po") != null and is_instance_valid(nt._e3po):
					for l in (nt._e3po.shout_lines as Array):
						e3b = e3b or _in(String(l), _strs(_fl["e3po"]))
				_check("B6 E3PO says his line in his own bubble", e3b)
				_feed0 = (_t.get("feed") as Array).size()
				_t.set("_fest_left", 0.0)
			if _f - _mark == 1510:
				var fd: Array = (_t.get("feed") as Array).slice(_feed0)
				var ok := false
				for l in fd:
					var base := String(l).split("  (")[0]
					ok = ok or _in(base, _strs(_fl["closings"]))
				_check("B7 it closes on a C6 closing", ok and not bool(_t.get("festival")))
				_t.set("_fest_gap", 999.0)
				_feed0 = (_t.get("feed") as Array).size()
				_check("C0 a viewer's festival starts", bool(_t.call("start_festival", "gift", [], "PatronX")))
				var vp: Dictionary = _fl["viewer_paid"]
				var op := String((_t.get("feed") as Array)[_feed0])
				_check("C1 opens from viewer_paid.openings naming the buyer: %s" % op.left(80), _in(op, _strs(vp["openings"]), "PatronX"))
				_phase = "C_run"
				_mark = _f
		"C_run":
			if (_f - _mark) % 60 == 0:
				_t.set("_fest_left", 999.0)
				_t.set("_fest_news_t", minf(float(_t.get("_fest_news_t")), 1.0))
			if _f - _mark == 900:
				var vp: Dictionary = _fl["viewer_paid"]
				var fd: Array = (_t.get("feed") as Array).slice(_feed0 + 1)
				var ok := false
				for l in fd:
					ok = ok or _in(String(l), _strs(vp["stalls"]) + _strs(vp["notables"]) + _strs(vp["e3po"]), "PatronX")
				_check("C2 the paid festival's talk reads viewer_paid", ok)
				_feed0 = (_t.get("feed") as Array).size()
				_t.set("_fest_left", 0.0)
			if _f - _mark == 910:
				var vp: Dictionary = _fl["viewer_paid"]
				var fd: Array = (_t.get("feed") as Array).slice(_feed0)
				var ok := false
				for l in fd:
					ok = ok or _in(String(l).split("  (")[0], _strs(vp["closings"]), "PatronX")
				_check("C3 closes on viewer_paid.closings", ok)
				_finish()
				return true
	if _f > 8000:
		_check("timeout", false)
		_finish()
		return true
	return false

func _finish() -> void:
	var out := ProjectSettings.globalize_path("res://renders/cycles/d63")
	DirAccess.make_dir_recursive_absolute(out)
	var f := FileAccess.open(out + "/talk_test.txt", FileAccess.WRITE)
	if f:
		f.store_string("source " + _src + "\n" + "\n".join(_log) + "\n")
	print("D63B_TALK OK" if _fails == 0 else "D63B_TALK FAIL %d" % _fails)
