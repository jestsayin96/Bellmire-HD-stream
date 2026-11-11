extends Node3D
## D3: Bellmire grows with its town level (economy.TOWN_LEVELS, the old sim.gd
## ladder: a hamlet, a village, a market town, a walled town, a free city, the
## seat of the valley). Everything is built once at the founding and only shown
## or hidden here, so a level change costs nothing and the navmesh never moves
## (every new building stands inside a house plot's own footprint).
##
## - plots fill in: house plots nearest the market stand first; the rest are
##   staked lots (pegs, line, a timber stack) until the town earns them.
## - houses upgrade: gardens at the door (village), shop signs and door lamps
##   (market town), a stone plinth and a chimney (walled town), a storey more
##   (free city), a livery pennant on the ridge (seat of the valley).
## - the wall: a timber palisade until Bellmire is "a walled town", then stone.
## - new buildings take a house plot each: the Market Hall (3), the Town
##   Stables (4), the Delvers' Guild and the Bathhouse (5), the Mage Tower (6).

const PROPS := "res://assets/props/"
const MKPROPS := "res://assets/mkprops/"
const NATURE := "res://assets/nature/"
const HORSE := "res://assets/animals/"
const HORSE_SCALE := 0.27         # town.gd ANIMALS["Horse"]
const LIVERY_BANNER := {"blue": Color(0.16, 0.26, 0.62), "green": Color(0.18, 0.45, 0.20),
    "red": Color(0.62, 0.14, 0.12), "yellow": Color(0.85, 0.66, 0.16)}
const TOP_LEVEL := 6
## share of the house plots standing at levels 1..6
const FILL := [0.40, 0.55, 0.68, 0.80, 0.91, 1.0]
const UNLOCK := {"market_hall": 3, "stables": 4, "guild": 5, "bathhouse": 5, "mage_tower": 6}
const NAMES := {"market_hall": "THE MARKET HALL", "stables": "THE TOWN STABLES",
    "guild": "THE DELVERS' GUILD", "bathhouse": "THE BATHHOUSE", "mage_tower": "THE MAGE TOWER"}
const NEWS := {
    2: ["Gardens are dug by Bellmire's doors."],
    3: ["The Market Hall is raised beside the square.", "Shop signs swing over the doors of Bellmire."],
    4: ["Stone takes the palisade's place: Bellmire is walled.", "The Town Stables open by the garrison."],
    5: ["The Delvers' Guild takes a hall of its own.", "The Bathhouse opens; steam rises over the roofs.",
        "Bellmire's houses rise a storey."],
    6: ["The Mage Tower is raised. Its windows burn all night.", "Pennants fly from every ridge."],
}

var town                        # town.gd (untyped: its fields are read by name)
var level := 0
var houses: Array = []          # plots that grow, in building order
var specials := {}              # key -> {"plot": Dictionary, "node": Node3D}
var _layers := {}               # level -> Array[Node3D], shown from that level on
var _lots: Array = []           # [plot, Node3D]
var _wood: StandardMaterial3D
var _palisade: StandardMaterial3D
var _soil: StandardMaterial3D
var _glowmat: StandardMaterial3D
var _arcane: StandardMaterial3D
var _copper: StandardMaterial3D
var _dark: StandardMaterial3D
var _paper: StandardMaterial3D
var _scenes := {}

func setup(t) -> void:
    town = t
    name = "Growth"
    _mats()
    var front: Array = []
    var back: Array = []
    for plot in town.plots:
        if plot.has("landmark") or plot.has("shop") or not plot.has("node"):
            continue
        if plot.has("back"):
            back.append(plot)
        else:
            front.append(plot)
    var by_market := func(a: Dictionary, b: Dictionary) -> bool:
        return town._dist_to_market(a["pos"]) < town._dist_to_market(b["pos"])
    front.sort_custom(by_market)
    back.sort_custom(by_market)
    houses = front + back
    var n := houses.size()
    for i in range(n):
        var plot: Dictionary = houses[i]
        var lv := 1
        while lv < TOP_LEVEL and float(i) >= float(FILL[lv - 1]) * float(n):
            lv += 1
        plot["grow"] = lv
        plot["base_sy"] = (plot["node"] as Node3D).scale.y
        _upgrade(plot)
        _lot(plot)
    _pick_specials()

## ---------------------------------------------------------------- levels
func show_level(lv: int, quiet := false) -> void:
    lv = clampi(lv, 1, TOP_LEVEL)
    var was := level
    level = lv
    for k in _layers:
        for nd in _layers[k]:
            if is_instance_valid(nd):
                (nd as Node3D).visible = lv >= int(k)
    for plot in houses:
        var up: bool = lv >= int(plot["grow"])
        plot["unbuilt"] = not up
        var h: Node3D = plot["node"]
        if not is_instance_valid(h):
            continue
        h.visible = up
        h.scale.y = float(plot["base_sy"]) * (1.2 if lv >= 5 else 1.0)
    for e in _lots:
        if is_instance_valid(e[1]):
            (e[1] as Node3D).visible = lv < int((e[0] as Dictionary)["grow"])
    for key in specials:
        var sp: Dictionary = specials[key]
        var plot: Dictionary = sp["plot"]
        var on: bool = lv >= int(UNLOCK[key])
        (sp["node"] as Node3D).visible = on
        if on:
            plot["special"] = key
        else:
            plot.erase("special")
        var h: Node3D = plot["node"]
        if not is_instance_valid(h):
            continue
        if key == "guild":
            if on:
                h.scale.y = float(plot["base_sy"]) * 1.32
        elif on:
            h.visible = false
    var wm: Material = town._stone() if lv >= 4 else _palisade
    for w in town.wall_parts:
        if is_instance_valid(w):
            w.set("material_override", wm)
    if quiet or was <= 0 or lv <= was:
        return
    var feed: Array = town.feed
    var built := 0
    for plot in houses:
        if int(plot["grow"]) > was and int(plot["grow"]) <= lv:
            built += 1
    if built > 0:
        feed.append("%d new houses go up in Bellmire." % built)
    for l in range(was + 1, lv + 1):
        for line in NEWS.get(l, []):
            feed.append(String(line))

func stats() -> Dictionary:
    var built := 0
    for plot in houses:
        if not plot.get("unbuilt", false):
            built += 1
    var open: Array = []
    for key in specials:
        if (specials[key]["node"] as Node3D).visible:
            open.append(key)
    return {"level": level, "houses": houses.size(), "built": built, "specials": open,
            "stone_wall": level >= 4}

## ---------------------------------------------------------------- helpers
func _mats() -> void:
    var src = town._mat.get("MI_WoodTrim")
    _wood = (src as StandardMaterial3D).duplicate() if src != null else StandardMaterial3D.new()
    _wood.uv1_triplanar = true
    _wood.uv1_scale = Vector3(0.35, 0.35, 0.35)
    _wood.albedo_color = Color(0.58, 0.44, 0.32)
    _palisade = _wood.duplicate()
    _palisade.uv1_world_triplanar = true
    _palisade.uv1_scale = Vector3(0.5, 0.12, 0.5)
    _palisade.albedo_color = Color(0.52, 0.38, 0.26)
    _soil = StandardMaterial3D.new()
    _soil.albedo_color = Color(0.30, 0.22, 0.15)
    _soil.roughness = 1.0
    _glowmat = StandardMaterial3D.new()
    _glowmat.albedo_color = Color(1.0, 0.78, 0.45)
    _glowmat.emission_enabled = true
    _glowmat.emission = Color(1.0, 0.70, 0.35)
    _glowmat.emission_energy_multiplier = 2.2
    _arcane = StandardMaterial3D.new()
    _arcane.albedo_color = Color(0.72, 0.55, 1.0)
    _arcane.emission_enabled = true
    _arcane.emission = Color(0.62, 0.42, 1.0)
    _arcane.emission_energy_multiplier = 3.0
    _copper = StandardMaterial3D.new()
    _copper.albedo_color = Color(0.36, 0.62, 0.55)
    _copper.metallic = 0.6
    _copper.roughness = 0.45
    _dark = StandardMaterial3D.new()
    _dark.albedo_color = Color(0.14, 0.10, 0.08)
    _paper = StandardMaterial3D.new()
    _paper.albedo_color = Color(0.90, 0.86, 0.74)

func _layer(lv: int, nd: Node3D) -> Node3D:
    if not _layers.has(lv):
        _layers[lv] = []
    (_layers[lv] as Array).append(nd)
    return nd

func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, yaw := 0.0) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = size
    mi.mesh = bm
    mi.material_override = mat
    mi.position = pos
    mi.rotation.y = yaw
    parent.add_child(mi)
    return mi

func _cyl(parent: Node3D, r_top: float, r_bot: float, h: float, pos: Vector3, mat: Material, seg := 16) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = r_top
    cm.bottom_radius = r_bot
    cm.height = h
    cm.radial_segments = seg
    mi.mesh = cm
    mi.material_override = mat
    mi.position = pos
    parent.add_child(mi)
    return mi

func _prop(parent: Node3D, dir_path: String, nm: String, pos: Vector3, yaw: float, sc: float) -> Node3D:
    var path := dir_path + nm + ".gltf"
    if not ResourceLoader.exists(path):
        path = dir_path + nm + ".glb"
    if not ResourceLoader.exists(path):
        return null
    if not _scenes.has(path):
        _scenes[path] = load(path)
    var nd: Node3D = (_scenes[path] as PackedScene).instantiate()
    nd.position = pos
    nd.rotation.y = yaw
    nd.scale = Vector3.ONE * sc
    parent.add_child(nd)
    if dir_path == MKPROPS:
        town._dress(nd, "red")
    return nd

func _label(parent: Node3D, text: String, pos: Vector3, size := 52, col := Color(0.95, 0.88, 0.66)) -> Label3D:
    var lb := Label3D.new()
    lb.text = text
    lb.font_size = size
    lb.pixel_size = 0.0062
    lb.modulate = col
    lb.outline_size = 14
    lb.outline_modulate = Color(0.10, 0.06, 0.03)
    lb.position = pos
    parent.add_child(lb)
    return lb

## the plot's frame: origin on the ground at the plot, +Z toward the street
func _frame(plot: Dictionary) -> Node3D:
    var nd := Node3D.new()
    var p: Vector3 = plot["pos"]
    nd.position = Vector3(p.x, town.height_at(p.x, p.z), p.z)
    nd.rotation.y = float(plot["yaw"])
    add_child(nd)
    return nd

func _shape_box(plot: Dictionary) -> Array:
    var sh := String(plot.get("shape", "a"))
    if town._house_box.has(sh):
        return town._house_box[sh]
    return [Vector2(5.0, 5.0), Vector2.ZERO, 7.0]

## ---------------------------------------------------------------- houses
## Upgrades hang off the house node itself, in its own (unscaled) frame, so
## they follow its scale, its storey and a raid's wreck.
func _upgrade(plot: Dictionary) -> void:
    var h: Node3D = plot["node"]
    var bx := _shape_box(plot)
    var he: Vector2 = bx[0]
    var c: Vector2 = bx[1]
    var top: float = float(bx[2])
    var sh := String(plot.get("shape", "a"))
    var door: Vector3 = town._house_door.get(sh, Vector3(c.x, 0.0, c.y + he.y))
    var lv := String(town.livery_of.get(plot["district"], "red"))
    var tint: Color = LIVERY_BANNER.get(lv, Color(0.6, 0.2, 0.15))
    var cloth := StandardMaterial3D.new()
    cloth.albedo_color = tint
    cloth.roughness = 0.9
    # village: a planter either side of the door
    var garden := Node3D.new()
    h.add_child(garden)
    for sgn in [-1.0, 1.0]:
        var gp := Vector3(door.x + float(sgn) * 1.75, 0.0, door.z + 0.42)
        _box(garden, Vector3(1.1, 0.45, 0.42), gp + Vector3(0, 0.22, 0), _wood)
        _box(garden, Vector3(1.0, 0.04, 0.34), gp + Vector3(0, 0.44, 0), _soil)
        var nm: String = ["Flower_3_Group", "Flower_4_Group", "Bush_Common_Flowers"][int(absf(gp.x * 7.0 + h.position.x)) % 3]
        _prop(garden, NATURE, nm, gp + Vector3(0, 0.45, 0), 0.0, 0.5 if nm != "Bush_Common_Flowers" else 0.32)
    _layer(2, garden)
    # market town: a hanging sign in the district's colour and a lamp by the door
    var signs := Node3D.new()
    h.add_child(signs)
    var sx := door.x + 1.35
    _box(signs, Vector3(0.08, 0.08, 1.0), Vector3(sx, 2.95, door.z + 0.45), _wood)
    _box(signs, Vector3(0.05, 0.62, 0.78), Vector3(sx, 2.55, door.z + 0.62), cloth)
    _box(signs, Vector3(0.07, 0.68, 0.06), Vector3(sx, 2.55, door.z + 1.03), _wood)
    _box(signs, Vector3(0.22, 0.3, 0.22), Vector3(door.x - 1.2, 2.3, door.z + 0.2), _glowmat)
    _layer(3, signs)
    # walled town: a stone plinth round the back and sides, and a chimney
    var stone := Node3D.new()
    h.add_child(stone)
    var sm: Material = town._stone()
    var ix := maxf(he.x - 0.55, 1.0)
    var iz := maxf(he.y - 0.55, 1.0)
    _box(stone, Vector3(ix * 2.0, 1.2, 0.36), Vector3(c.x, 0.3, c.y - iz), sm)
    for sgn in [-1.0, 1.0]:
        _box(stone, Vector3(0.36, 1.2, iz * 2.0 - 0.6), Vector3(c.x + float(sgn) * ix, 0.3, c.y - 0.3), sm)
    var ch_h := top * 0.45 + 0.9
    var chp := Vector3(c.x + he.x * 0.42, top * 0.55 + ch_h * 0.5, c.y - he.y * 0.38)
    _box(stone, Vector3(0.9, ch_h, 0.9), chp, sm)
    _box(stone, Vector3(1.1, 0.18, 1.1), chp + Vector3(0, ch_h * 0.5, 0), sm)
    _layer(4, stone)
    # seat of the valley: a pennant on the ridge
    var pen := Node3D.new()
    h.add_child(pen)
    _box(pen, Vector3(0.09, 2.2, 0.09), Vector3(c.x - he.x * 0.25, top + 0.6, c.y), _wood)
    _box(pen, Vector3(1.1, 0.5, 0.04), Vector3(c.x - he.x * 0.25 + 0.58, top + 1.4, c.y), cloth)
    _layer(6, pen)

## a staked lot: pegs, a line, cleared earth and the timber waiting for it
func _lot(plot: Dictionary) -> void:
    var bx := _shape_box(plot)
    var he: Vector2 = bx[0]
    var c: Vector2 = bx[1]
    var lot := _frame(plot)
    var hx := maxf(he.x - 0.7, 1.5)
    var hz := maxf(he.y - 0.7, 1.5)
    _box(lot, Vector3(hx * 2.0, 0.06, hz * 2.0), Vector3(c.x, 0.02, c.y), _soil)
    for sx in [-1.0, 1.0]:
        for sz in [-1.0, 1.0]:
            _box(lot, Vector3(0.12, 1.0, 0.12), Vector3(c.x + float(sx) * hx, 0.4, c.y + float(sz) * hz), _wood)
    for sz in [-1.0, 1.0]:
        _box(lot, Vector3(hx * 2.0, 0.025, 0.025), Vector3(c.x, 0.78, c.y + float(sz) * hz), _paper)
    for sx in [-1.0, 1.0]:
        _box(lot, Vector3(0.025, 0.025, hz * 2.0), Vector3(c.x + float(sx) * hx, 0.78, c.y), _paper)
    # timber stacked on two sleepers, a crate of nails
    var tp := Vector3(c.x - hx * 0.35, 0.0, c.y - hz * 0.2)
    for i in range(2):
        _box(lot, Vector3(0.25, 0.2, 1.6), tp + Vector3(-1.2 + 2.4 * float(i), 0.1, 0), _wood)
    for r in range(3):
        for k in range(3 - r):
            _box(lot, Vector3(3.4, 0.24, 0.24), tp + Vector3(0, 0.32 + 0.24 * float(r), -0.3 + 0.27 * float(k) + 0.13 * float(r)), _wood)
    _prop(lot, PROPS, "Crate_Wooden", Vector3(c.x + hx * 0.45, 0.0, c.y + hz * 0.3), 0.4, 1.3)
    _lots.append([plot, lot])

## ---------------------------------------------------------------- new buildings
func _pick_specials() -> void:
    var used := {}
    var lm: Dictionary = town.landmarks
    var near := func(key: String) -> Vector3:
        return (lm[key][0] as Vector3) if lm.has(key) else Vector3.ZERO
    _special("market_hall", func(p: Dictionary) -> float: return town._dist_to_market(p["pos"]), used)
    var bar: Vector3 = near.call("lm_barracks")
    _special("stables", func(p: Dictionary) -> float: return (p["pos"] as Vector3).distance_to(bar), used)
    var hall: Vector3 = near.call("lm_hall")
    _special("guild", func(p: Dictionary) -> float: return (p["pos"] as Vector3).distance_to(hall), used)
    _special("bathhouse", func(p: Dictionary) -> float:
        var q: Vector3 = p["pos"]
        return town.river_dist(q.x, q.z), used)
    var chap: Vector3 = near.call("lm_chapel")
    _special("mage_tower", func(p: Dictionary) -> float: return (p["pos"] as Vector3).distance_to(chap), used)

func _special(key: String, score: Callable, used: Dictionary) -> void:
    var best: Dictionary = {}
    var bs := INF
    for plot in houses:
        if plot.has("back") or used.has(plot["cell"]) or int(plot["grow"]) > int(UNLOCK[key]):
            continue
        var he: Vector2 = _shape_box(plot)[0]
        if minf(he.x, he.y) < 3.2:
            continue
        var s: float = score.call(plot)
        if s < bs:
            bs = s
            best = plot
    if best.is_empty():
        push_warning("growth: no plot for " + key)
        return
    used[best["cell"]] = true
    var nd := _frame(best)
    nd.name = key
    nd.visible = false
    match key:
        "market_hall":
            _market_hall(nd, best)
        "stables":
            _stables(nd, best)
        "guild":
            _guild(nd, best)
        "bathhouse":
            _bathhouse(nd, best)
        "mage_tower":
            _mage_tower(nd, best)
    specials[key] = {"plot": best, "node": nd}

var _roofs := {}
## the district's roof tiles, laid world-triplanar: a PrismMesh's own UVs
## stretch the tiles across the whole slope
func _roof_mat(plot: Dictionary) -> Material:
    var lv := String(town.livery_of.get(plot["district"], "red"))
    if _roofs.has(lv):
        return _roofs[lv]
    var m = town._roof.get(lv)
    if m == null:
        return town._stone()
    var d := (m as StandardMaterial3D).duplicate() as StandardMaterial3D
    d.uv1_triplanar = true
    d.uv1_world_triplanar = true
    d.uv1_scale = Vector3(0.45, 0.45, 0.45)
    _roofs[lv] = d
    return d

## an open hall on stone pillars, stalls under its roof
func _market_hall(nd: Node3D, plot: Dictionary) -> void:
    var bx := _shape_box(plot)
    var he: Vector2 = bx[0]
    var c: Vector2 = bx[1]
    var hx := he.x * 0.9
    var hz := he.y * 0.9
    var sm: Material = town._stone()
    _box(nd, Vector3(hx * 2.0, 0.3, hz * 2.0), Vector3(c.x, 0.05, c.y), sm)
    for px in [-1.0, 0.0, 1.0]:
        for pz in [-1.0, 1.0]:
            _box(nd, Vector3(0.55, 3.6, 0.55), Vector3(c.x + float(px) * (hx - 0.4), 1.9, c.y + float(pz) * (hz - 0.4)), sm)
    for pz in [-1.0, 1.0]:
        _box(nd, Vector3(hx * 2.0, 0.4, 0.45), Vector3(c.x, 3.85, c.y + float(pz) * (hz - 0.4)), _wood)
    for px in [-1.0, 1.0]:
        _box(nd, Vector3(0.45, 0.4, hz * 2.0), Vector3(c.x + float(px) * (hx - 0.4), 3.85, c.y), _wood)
    var roof := MeshInstance3D.new()
    var pm := PrismMesh.new()
    pm.size = Vector3(hx * 2.0 + 0.9, 2.6, hz * 2.0 + 0.9)
    roof.mesh = pm
    roof.material_override = _roof_mat(plot)
    roof.position = Vector3(c.x, 4.05 + 1.3, c.y)
    nd.add_child(roof)
    for sgn in [-1.0, 1.0]:
        _prop(nd, PROPS, "Stall_Empty", Vector3(c.x + float(sgn) * hx * 0.45, 0.2, c.y + 0.6), 0.0, 1.45)
    _prop(nd, PROPS, "Barrel_Apples", Vector3(c.x - hx * 0.15, 0.2, c.y - hz * 0.5), 0.0, 1.45)
    _prop(nd, PROPS, "FarmCrate_Apple", Vector3(c.x + hx * 0.2, 0.2, c.y - hz * 0.55), 0.3, 1.45)
    _prop(nd, PROPS, "FarmCrate_Carrot", Vector3(c.x + hx * 0.55, 0.2, c.y - hz * 0.4), -0.2, 1.45)
    _prop(nd, PROPS, "Stall_Cart_Empty", Vector3(c.x - hx * 0.6, 0.2, c.y - hz * 0.45), 0.5, 1.45)
    _label(nd, NAMES["market_hall"], Vector3(c.x, 4.75, c.y + hz + 0.5), 60)

## a long timber barn, open to the street, a horse in each stall
func _stables(nd: Node3D, plot: Dictionary) -> void:
    var bx := _shape_box(plot)
    var he: Vector2 = bx[0]
    var c: Vector2 = bx[1]
    var hx := he.x * 0.9
    var hz := he.y * 0.85
    _box(nd, Vector3(hx * 2.0, 0.12, hz * 2.0), Vector3(c.x, 0.04, c.y), _soil)
    _box(nd, Vector3(hx * 2.0, 3.2, 0.3), Vector3(c.x, 1.5, c.y - hz), _wood)
    for sgn in [-1.0, 1.0]:
        _box(nd, Vector3(0.3, 3.2, hz * 2.0), Vector3(c.x + float(sgn) * hx, 1.5, c.y), _wood)
    var stalls := maxi(2, int(hx * 2.0 / 3.2))
    var w := hx * 2.0 / float(stalls)
    for i in range(stalls + 1):
        var x := c.x - hx + w * float(i)
        _box(nd, Vector3(0.28, 3.2, 0.28), Vector3(x, 1.5, c.y + hz - 0.15), _wood)
        if i > 0 and i < stalls:
            _box(nd, Vector3(0.14, 1.5, hz * 1.2), Vector3(x, 0.75, c.y - hz * 0.4), _wood)
    _box(nd, Vector3(hx * 2.0, 0.35, 0.35), Vector3(c.x, 3.1, c.y + hz - 0.15), _wood)
    var roof := MeshInstance3D.new()
    var pm := PrismMesh.new()
    pm.size = Vector3(hz * 2.0 + 1.2, 2.2, hx * 2.0 + 0.8)
    roof.mesh = pm
    roof.rotation.y = PI * 0.5
    roof.material_override = _roof_mat(plot)
    roof.position = Vector3(c.x, 3.25 + 1.1, c.y + 0.2)
    nd.add_child(roof)
    for i in range(stalls):
        if i % 2 == 1 and stalls > 2:
            continue
        var hp := Vector3(c.x - hx + w * (float(i) + 0.5), 0.1, c.y + hz * 0.5)
        var horse := _prop(nd, HORSE, "Horse", hp, 0.0, HORSE_SCALE)
        if horse:
            horse.name = "StableHorse"
            horse.rotation.y = PI * (0.5 if i % 4 == 0 else -0.5)    # stood side-on in the stall
    for i in range(stalls):
        _prop(nd, PROPS, "FarmCrate_Empty", Vector3(c.x - hx + w * (float(i) + 0.5) + w * 0.3, 0.1, c.y - hz + 0.6), 0.0, 1.3)
    _prop(nd, PROPS, "Bucket_Wooden_1", Vector3(c.x + hx - 0.8, 0.1, c.y + hz - 0.9), 0.0, 1.45)
    _box(nd, Vector3(hx * 1.2, 0.8, 0.08), Vector3(c.x, 3.85, c.y + hz + 0.05), _wood)
    _label(nd, NAMES["stables"], Vector3(c.x, 3.85, c.y + hz + 0.12), 54)

## the house stays, raised high: guild banners, a notice board, a hung sign
func _guild(nd: Node3D, plot: Dictionary) -> void:
    var bx := _shape_box(plot)
    var he: Vector2 = bx[0]
    var c: Vector2 = bx[1]
    var lv := String(town.livery_of.get(plot["district"], "red"))
    var cloth := StandardMaterial3D.new()
    cloth.albedo_color = LIVERY_BANNER.get(lv, Color(0.6, 0.2, 0.15))
    var gold := StandardMaterial3D.new()
    gold.albedo_color = Color(0.85, 0.66, 0.22)
    gold.metallic = 0.7
    var fz := c.y + he.y + 0.25
    for sgn in [-1.0, 1.0]:
        var x := c.x + float(sgn) * (he.x - 0.4)
        _box(nd, Vector3(0.16, 7.5, 0.16), Vector3(x, 3.75, fz), _wood)
        _box(nd, Vector3(1.3, 3.2, 0.06), Vector3(x, 5.4, fz + 0.12), cloth)
        _box(nd, Vector3(1.4, 0.12, 0.1), Vector3(x, 7.05, fz + 0.12), gold)
    var sh := String(plot.get("shape", "a"))
    var door: Vector3 = town._house_door.get(sh, Vector3(c.x, 0.0, c.y + he.y))
    _box(nd, Vector3(3.6, 0.8, 0.1), Vector3(door.x, 3.75, door.z + 0.35), _wood)
    _label(nd, NAMES["guild"], Vector3(door.x, 3.75, door.z + 0.42), 46)
    # the notice board where the deep's work is pinned
    var bp := Vector3(door.x - 2.6, 0.0, door.z + 0.9)
    for sgn in [-1.0, 1.0]:
        _box(nd, Vector3(0.12, 2.0, 0.12), bp + Vector3(float(sgn) * 0.8, 1.0, 0), _wood)
    _box(nd, Vector3(1.8, 1.1, 0.08), bp + Vector3(0, 1.45, 0), _wood)
    for i in range(5):
        _box(nd, Vector3(0.32, 0.4, 0.02), bp + Vector3(-0.6 + 0.3 * float(i), 1.45 + 0.18 * float(i % 2) - 0.08, 0.06), _paper)
    _prop(nd, PROPS, "WeaponStand", Vector3(door.x + 2.6, 0.0, door.z + 0.9), 0.0, 1.45)

## stone walls, a copper dome, steam
func _bathhouse(nd: Node3D, plot: Dictionary) -> void:
    var bx := _shape_box(plot)
    var he: Vector2 = bx[0]
    var c: Vector2 = bx[1]
    var hx := he.x * 0.85
    var hz := he.y * 0.82
    var sm: Material = town._stone()
    _box(nd, Vector3(hx * 2.0, 3.4, hz * 2.0), Vector3(c.x, 1.5, c.y), sm)
    _box(nd, Vector3(hx * 2.0 + 0.4, 0.3, hz * 2.0 + 0.4), Vector3(c.x, 3.3, c.y), sm)
    var r := minf(hx, hz) * 0.72
    var dome := MeshInstance3D.new()
    var sp := SphereMesh.new()
    sp.radius = r
    sp.height = r
    sp.is_hemisphere = true
    dome.mesh = sp
    dome.material_override = _copper
    dome.position = Vector3(c.x, 3.45, c.y)
    nd.add_child(dome)
    _cyl(nd, 0.25, 0.3, 0.9, Vector3(c.x, 3.45 + r + 0.3, c.y), _copper, 8)
    # the door, two lamps, a low step
    var fz := c.y + hz
    _box(nd, Vector3(1.6, 2.3, 0.12), Vector3(c.x, 1.15, fz + 0.02), _dark)
    _box(nd, Vector3(2.4, 0.2, 0.8), Vector3(c.x, 0.1, fz + 0.4), sm)
    for sgn in [-1.0, 1.0]:
        _box(nd, Vector3(0.25, 0.35, 0.25), Vector3(c.x + float(sgn) * 1.25, 2.2, fz + 0.15), _glowmat)
    # small vents with steam rising off the roof
    for v in [Vector3(-hx * 0.65, 0, -hz * 0.6), Vector3(hx * 0.65, 0, -hz * 0.55), Vector3(0, 0, -hz * 0.75)]:
        var vp := Vector3(c.x, 3.6, c.y) + (v as Vector3)
        _box(nd, Vector3(0.5, 0.5, 0.5), vp, sm)
        var steam := CPUParticles3D.new()
        steam.amount = 14
        steam.lifetime = 3.5
        steam.direction = Vector3.UP
        steam.spread = 18.0
        steam.gravity = Vector3(0.15, 0.35, 0.0)
        steam.initial_velocity_min = 0.4
        steam.initial_velocity_max = 0.8
        steam.scale_amount_min = 0.6
        steam.scale_amount_max = 1.4
        var pm := SphereMesh.new()
        pm.radius = 0.35
        pm.height = 0.7
        pm.radial_segments = 8
        pm.rings = 4
        var smat := StandardMaterial3D.new()
        smat.albedo_color = Color(0.95, 0.95, 0.95, 0.28)
        smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        pm.material = smat
        steam.mesh = pm
        steam.position = vp + Vector3(0, 0.3, 0)
        nd.add_child(steam)
    _label(nd, NAMES["bathhouse"], Vector3(c.x, 2.85, fz + 0.1), 50)

## a round stone tower, a tiled cap, windows that burn violet
func _mage_tower(nd: Node3D, plot: Dictionary) -> void:
    var bx := _shape_box(plot)
    var he: Vector2 = bx[0]
    var c: Vector2 = bx[1]
    var r := clampf(minf(he.x, he.y) * 0.72, 2.4, 4.4)
    var hgt := 17.0
    var sm: Material = town._stone()
    _cyl(nd, r + 0.45, r + 0.6, 1.4, Vector3(c.x, 0.4, c.y), sm, 20)
    _cyl(nd, r, r + 0.15, hgt, Vector3(c.x, hgt * 0.5, c.y), sm, 20)
    for y in [hgt * 0.36, hgt * 0.7, hgt - 0.2]:
        _cyl(nd, r + 0.2, r + 0.2, 0.4, Vector3(c.x, float(y), c.y), sm, 20)
    for y in [hgt * 0.52, hgt * 0.84]:
        for k in range(4):
            var a := TAU * float(k) / 4.0 + (0.4 if y > hgt * 0.6 else 0.0)
            var wp := Vector3(c.x + sin(a) * (r + 0.02), float(y), c.y + cos(a) * (r + 0.02))
            _box(nd, Vector3(0.55, 1.2, 0.2), wp, _arcane, a)
    # the cap: MegaKit's round tiled tower roof, fitted to the drum
    var cap := _prop(nd, MKPROPS, "Roof_Tower_RoundTiles", Vector3.ZERO, 0.0, 1.0)
    if cap:
        var ab := AABB()
        var first := true
        for m in cap.find_children("*", "MeshInstance3D", true, false):
            var mi := m as MeshInstance3D
            var a2: AABB = mi.transform * mi.get_aabb()
            ab = a2 if first else ab.merge(a2)
            first = false
        var k2 := (r * 2.0 + 1.2) / maxf(ab.size.x, 0.1)
        cap.scale = Vector3.ONE * k2
        cap.position = Vector3(c.x - ab.get_center().x * k2, hgt - ab.position.y * k2, c.y - ab.get_center().z * k2)
        for m in cap.find_children("*", "MeshInstance3D", true, false):
            (m as MeshInstance3D).material_override = _roof_mat(plot)
    else:
        _cyl(nd, 0.05, r + 0.8, 5.0, Vector3(c.x, hgt + 2.5, c.y), _roof_mat(plot), 20)
    # a crystal turning slowly over the cap, and its light
    var crystal := MeshInstance3D.new()
    var pm := PrismMesh.new()
    pm.size = Vector3(0.7, 1.4, 0.7)
    crystal.mesh = pm
    crystal.material_override = _arcane
    crystal.position = Vector3(c.x, hgt + r * 1.6 + 2.0, c.y)
    crystal.name = "TowerCrystal"
    nd.add_child(crystal)
    var tw := crystal.create_tween().set_loops()
    tw.tween_property(crystal, "rotation:y", TAU, 6.0).from(0.0)
    var l := OmniLight3D.new()
    l.light_color = Color(0.70, 0.50, 1.0)
    l.light_energy = 2.2
    l.omni_range = 16.0
    l.position = crystal.position
    nd.add_child(l)
    # door
    _box(nd, Vector3(1.4, 2.4, 0.3), Vector3(c.x, 1.3, c.y + r + 0.05), _dark)
    _box(nd, Vector3(0.22, 0.3, 0.22), Vector3(c.x - 1.0, 2.4, c.y + r + 0.25), _arcane)
    _label(nd, NAMES["mage_tower"], Vector3(c.x, 3.1, c.y + r + 0.3), 50, Color(0.85, 0.75, 1.0))
