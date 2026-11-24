extends SceneTree
## U88 (WINDOWED, --script): the REAL Satchel._refresh path with a ringed, gloved hero. The worn-accessory
## row must carry the item's own rarity pip (data/items.json), a common must stay bare. Shot per UI scale
## in renders/cycles/u88/. Prints U88_WORN OK.
class FakeSheet extends Node:
	var roster: Roster
var _f := 0
var _step := 0
var _bad := 0
var _n := 0  # U154: rows walked
var _out := ""
var _layer: CanvasLayer
var _sat: Node
func _initialize() -> void:
	_out = ProjectSettings.globalize_path("res://renders/cycles/u88/")
	DirAccess.make_dir_recursive_absolute(_out)
func _build() -> void:
	if _layer != null:
		_layer.queue_free()
	_layer = CanvasLayer.new()
	root.add_child(_layer)
	var sheet := FakeSheet.new()
	_layer.add_child(sheet)
	sheet.roster = Roster.new()
	sheet.roster.fresh("8801", "U88Ringed", "knight", "dwarf")
	var h: Dictionary = sheet.roster.heroes["8801"]
	h["acc"] = {"ring": "scarglass_ring", "gloves": "mender_wraps", "ring2": "market_ring"}
	_sat = LeaderboardPanel.Satchel.new()
	sheet.add_child(_sat)
	_sat.sheet = sheet
	_sat.build()
	_sat.set_process(false)
	_sat.uid = "8801"
	_sat.visible = true
	_sat._refresh()
	_sat.visible = true
func _pips() -> Dictionary:
	var out := {}
	for h in _sat._list.get_children():
		if h is HBoxContainer and h.get_child_count() >= 3:
			out[String((h.get_child(1) as Label).text)] = h.get_child(0) is PanelContainer or h.get_child(0) is Panel
	return out
func _process(_d: float) -> bool:
	_f += 1
	if _f < 30: return false
	var sc: float = UiTheme.STEPS[_step]
	if _f % 40 == 30:
		UiTheme.scale = sc
		_build()
		return false
	if _f % 40 == 10 and _sat != null:
		var p := _pips()
		print("ROWS @", sc, " ", p)
		_n += p.size()
		var want := {"Scarglass Ring  (ring)": true, "Mender Wraps  (gloves)": true}
		for k in p:
			var low := String(k).to_lower()
			if low.begins_with("scarglass") or low.begins_with("mender"):
				if not p[k]: _bad += 1; print("FAIL no pip on ", k)
			elif low.begins_with("market"):
				if p[k]: _bad += 1; print("FAIL common got a pip ", k)
		var n := 0
		for k in p:
			if p[k]: n += 1
		if n < 2: _bad += 1; print("FAIL fewer than 2 pips, got ", n)
		root.get_viewport().get_texture().get_image().save_png(_out + "u88_%d.png" % int(sc * 100))
		_step += 1
		_sat = null
		if _step >= 3:
			if _n == 0: print("U88_WORN NO VERDICT - 0 rows walked"); _bad += 1
			print("U88_WORN ", "OK" if _bad == 0 else "FAIL %d" % _bad, " rows=", _n)
			quit(0 if _bad == 0 else 1)
	return false
