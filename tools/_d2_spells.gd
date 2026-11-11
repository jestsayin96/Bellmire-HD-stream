extends SceneTree
## D2 test + render: spells aimed at the chest, never the sky; the new battle
## spells (chain, fire, frost, smite, renew, ward) land in raid combat.
## Run WINDOWED (it photographs): prints D2 ... lines and D2_SPELLS OK/FAIL.
var _t: Node3D
var _cam: Camera3D
var _rd: Raids
var _f := 0
var _out := ""
var _fail: Array = []
var _mage: Townsfolk
var _cleric: Townsfolk
var _sage: Townsfolk
var _knight: Townsfolk
var _c := Vector3.ZERO
var _bar_y: Array = []
var _shots := []
var _st := {}
var _hp0 := 0.0

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _out = ProjectSettings.globalize_path("res://renders/cycles/20261111_d2")
    DirAccess.make_dir_recursive_absolute(_out)

func _snap(nm: String) -> void:
    root.get_texture().get_image().save_png(_out + "/" + nm + ".png")
    print("SAVED ", nm)

func _body(model: String, p: Vector3, role: String) -> Townsfolk:
    var v := Townsfolk.new()
    v.model = model
    v.role = role
    v.stay = true
    v.person_name = role
    v.town = _t
    p.y = float(_t.call("height_at", p.x, p.z))
    v.position = p
    _t.add_child(v)
    return v

func _check(what: String, ok: bool, detail: String) -> void:
    print("D2 ", what, " ", "ok" if ok else "FAIL", " ", detail)
    if not ok:
        _fail.append(what)

## aim must sit 0.5..2.4 m over the caster's feet, hands 0.9..3 m
func _aim_ok(tag: String) -> void:
    var l: Dictionary = Spells.last
    var feet: Vector3 = l["feet"]
    var ay: float = (l["aim"] as Vector3).y - feet.y
    var hy: float = (l["hand"] as Vector3).y - feet.y
    _check("aim " + tag + " " + String(l["kind"]), ay >= 0.49 and ay <= 2.41 and hy >= 0.89 and hy <= 3.01,
        "aim+%.2f hand+%.2f" % [ay, hy])

func _raider(i: int) -> Dictionary:
    return _rd.raiders[i] if i < _rd.raiders.size() else {}

func _process(delta: float) -> bool:
    _f += 1
    if _f == 15:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        _cam.fov = 50.0
        _rd = _t.get("raids")
        _rd.set("_raid_t", 99999.0)
        _rd.force_level = 5
        _rd.raid("scar")
        _rd.set_process(false)         # the test drives the fight
        _c = Vector3(-14, 0, 175)      # open meadow past the bridge
        for i in range(_rd.raiders.size()):
            var n: Node3D = _rd.raiders[i]["node"]
            var p := _c + Vector3(3.0 + float(i % 3) * 1.6, 0, float(i / 3) * 1.8 - 1.5)
            p.y = float(_t.call("height_at", p.x, p.z))
            n.global_position = p
            n.rotation.y = -PI * 0.5
        _mage = _body("Mage.glb", _c + Vector3(-1.2, 0, -1.5), "mage")
        _cleric = _body("Mage.glb", _c + Vector3(-1.2, 0, 0.0), "cleric")
        _sage = _body("Mage.glb", _c + Vector3(-1.2, 0, 1.5), "sage")
        _knight = _body("Knight.glb", _c + Vector3(1.0, 0, 0.6), "guard")
        _cam.global_position = _c + Vector3(0.5, 3.2, 8.5)
        _cam.look_at(_c + Vector3(0.5, 1.1, 0), Vector3.UP)
    if _f < 40:
        return false
    if _f == 40:
        # 1) the climbing bar: delve and the old raids asked for _height()+0.25
        # every frame; the bar must hold still
        var m: Monster = _raider(0)["node"]
        for k in range(120):
            var hb := HealthBar3D.on(m, m._height() + 0.25, true)
            hb.set_hp(10.0, 30.0, true)
            _bar_y.append(hb.position.y)
        _check("bar holds", absf(float(_bar_y[-1]) - float(_bar_y[0])) < 0.05,
            "bar y %.2f -> %.2f after 120 asks" % [_bar_y[0], _bar_y[-1]])
        # 2) aim: every spell, at a body, at its feet, at chest+_height style, at the sky
        var tgt: Node3D = _raider(0)["node"]
        for kind in Spells.ORDER:
            Spells.cast(kind, _mage, tgt)
            _aim_ok("body")
            Spells.cast(kind, _mage, tgt.global_position)
            _aim_ok("feet")
            Spells.cast(kind, _mage, tgt.global_position + Vector3(0, 30.0, 0))
            _aim_ok("sky")
            var flat := Vector2((Spells.last["aim"] as Vector3).x - tgt.global_position.x, (Spells.last["aim"] as Vector3).z - tgt.global_position.z).length()
            _check("aim on target " + kind, flat < 0.05, "%.3f m off" % flat)
    # 3) the raid spells, one caster at a time; the fight is driven by hand
    if _f == 120:
        _st = {"hp": 42.0, "max": 42.0, "atk": 19.0, "ac": 12, "to_hit": 6, "speed": 4.0, "target": null,
               "swing": 0.0, "cls": "mage", "name": "Test Mage"}
        _hp0 = 0.0
        _n0 = _rd.raiders.size()
        for r in _rd.raiders:
            _hp0 += float(r["hp"])
    if _f >= 120 and _f < 720 and not _rd.raiders.is_empty():
        _rd._cast_engage(_mage, _st, _rd.raiders[0], delta)
        for r in _rd.raiders:
            var n: Node3D = r["node"]
            HealthBar3D.on(n, Spells.body_height(n) + 0.25, true).set_hp(float(r["hp"]), float(r["max"]), true)
        var k := String(Spells.last.get("kind", ""))
        if not _shots.has(k) and (k == "chain" or k == "fire") and int(_st.get("spell_i", 0)) > 0:
            _shots.append(k)
            _shot_f[k] = _f + (8 if k == "chain" else 14)
    for k2 in _shot_f.keys():
        if _f == int(_shot_f[k2]):
            _snap("raid_" + k2)
    if _f == 140:
        _snap("raid_bolt")
    if _f == 720:
        var hp1 := 0.0
        for r in _rd.raiders:
            hp1 += float(r["hp"])
        print("D2 mage cast %d spells" % int(_st.get("spell_i", 0)))
        _check("mage hurts raiders", hp1 < _hp0 or _rd.raiders.size() < _n0, "hp %.0f -> %.0f, %d raiders left" % [_hp0, hp1, _rd.raiders.size()])
        # cleric: a hurt guard near it gets a ward that soaks a blow
        _rd._fighters[_knight] = {"hp": 10.0, "max": 64.0, "atk": 11.0, "ac": 14, "to_hit": 3, "speed": 4.0,
                                  "target": null, "swing": 0.0, "post": _knight.global_position, "yaw": 0.0, "stay": true}
        var cst := {"hp": 60.0, "max": 60.0, "atk": 12.0, "ac": 13, "to_hit": 4, "speed": 4.0, "target": null,
                    "swing": 0.0, "cls": "cleric", "name": "Test Cleric"}
        if not _rd.raiders.is_empty():
            _rd._cast_engage(_cleric, cst, _rd.raiders[0], 0.016)
        var ks: Dictionary = _rd._fighters[_knight]
        _check("cleric wards the hurt", float(ks.get("ward", 0.0)) > 0.0, "ward %.1f" % float(ks.get("ward", 0.0)))
        var left := _rd._ward_soaks(ks, 10.0)
        _check("ward soaks", left < 10.0, "10 dmg -> %.1f" % left)
        _snap("raid_ward")
        # cleric again (the guard is blessed now): a smite on a raider
        cst["swing"] = 0.0
        if not _rd.raiders.is_empty():
            _rd._cast_engage(_cleric, cst, _rd.raiders[0], 0.016)
            _check("cleric smites", String(Spells.last.get("kind", "")) == "smite", String(Spells.last.get("kind", "")))
        _smite_f = _f + 12
    if _f == _smite_f:
        _snap("raid_smite")
        # sage: renew on a hurt guard (mends over time), then frost on a raider
        _rd._fighters[_knight]["hp"] = 12.0
        _rd._fighters[_knight]["blessed_t"] = 0.0
        _sst = {"hp": 50.0, "max": 50.0, "atk": 9.0, "ac": 12, "to_hit": 4, "speed": 4.0, "target": null,
                "swing": 0.0, "cls": "sage", "name": "Test Sage"}
        if not _rd.raiders.is_empty():
            _rd._cast_engage(_sage, _sst, _rd.raiders[0], 0.016)
        _check("sage renews", float(_rd._fighters[_knight].get("hot_t", 0.0)) > 0.0, "hot_t %.1f" % float(_rd._fighters[_knight].get("hot_t", 0.0)))
        _renew_f = _f
    if _renew_f > 0 and _f > _renew_f and _f <= _renew_f + 120:
        _rd._tick_blessings(delta)
    if _renew_f > 0 and _f == _renew_f + 20:
        _snap("raid_renew")
    if _renew_f > 0 and _f == _renew_f + 121:
        var hp := float(_rd._fighters[_knight]["hp"])
        _check("renew mends over time", hp > 12.5, "12 -> %.1f" % hp)
        _sst["swing"] = 0.0
        _rd._fighters[_knight]["hp"] = 64.0
        if not _rd.raiders.is_empty():
            var r0: Dictionary = _rd.raiders[0]
            for i in range(6):           # a few tries: a d20 can miss
                _sst["swing"] = 0.0
                _rd._cast_engage(_sage, _sst, r0, 0.016)
                if String(Spells.last.get("kind", "")) == "frost":
                    _rd._spell_lands("frost", [r0], (r0["node"] as Node3D).global_position, 40.0, 30, "Test Sage")
                    break
            _check("frost slows", float(r0.get("slow_t", 0.0)) > 0.0 and _rd._speed(r0) < float(r0["speed"]),
                "slow_t %.1f speed %.1f of %.1f" % [float(r0.get("slow_t", 0.0)), _rd._speed(r0), float(r0["speed"])])
        _frost_f = _f + 10
    if _frost_f > 0 and _f == _frost_f:
        _snap("raid_frost")
        # in a scar every spell misfires in turn
        var a := Spells.cast("bolt", _mage, _knight, true)
        _check("scar misfire", a == "heal", "bolt -> " + a)
        print("D2_SPELLS ", "OK" if _fail.is_empty() else "FAIL " + str(_fail))
        return true
    return _f > 60 * 60

var _shot_f := {}
var _smite_f := -1
var _renew_f := -1
var _frost_f := -1
var _sst := {}
var _n0 := 0
