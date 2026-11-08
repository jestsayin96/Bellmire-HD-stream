extends SceneTree
## Render probe. Shot list is built from stats() so cameras follow whatever
## the generator produced (market, gates, shops, towers).
var _f := 0
var _t: Node3D
var _cam: Camera3D
var _shots: Array = []
var _i := 0

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _shot(nm: String, pos: Vector3, look: Vector3, fov: float) -> void:
    _shots.append([nm, pos, look, fov])

func _plan(st: Dictionary) -> void:
    _shot("aerial", Vector3(0, 250, 265), Vector3.ZERO, 50.0)
    _shot("street", Vector3(-96, 6.5, 10), Vector3(30, 5, 4), 64.0)
    _shot("river", Vector3(-34, 7, 108), Vector3(0, 1, 130), 60.0)
    var m: Vector3 = st.get("market", Vector3.ZERO)
    _shot("square", m + Vector3(17, 8.5, 17), m + Vector3(0, 1.5, 0), 62.0)
    var done := {}
    for sh in st.get("shops", []):
        var kind: String = sh[0]
        if done.has(kind):
            continue
        done[kind] = true
        var y: Vector3 = sh[1]
        var f: Vector3 = sh[2]
        var side := Vector3(-f.z, 0, f.x)
        _shot("shop_" + kind, y + f * 14.0 + side * 4.0 + Vector3(0, 8.0, 0), y + Vector3(0, 1.0, 0), 58.0)
    var tw: Array = st.get("towers", [])
    if not tw.is_empty():
        var t: Vector3 = tw[0]
        var o := Vector3(t.x, 0, t.z).normalized()
        if o.length() < 0.1:
            o = Vector3(0, 0, 1)
        _shot("tower", t + Vector3(22, 20, 22), t + Vector3(0, 6, 0), 58.0)
    _shot("low_aerial", Vector3(-40, 70, 120), Vector3(10, 0, 20), 55.0)
    _shot("valley", Vector3(60, 45, 330), Vector3(20, 40, -300), 62.0)
    var mp := Vector3(-200, 0, 30)
    mp.y = float(_t.call("height_at", mp.x, mp.z)) + 1.7
    var ml := Vector3(-140, 0, -20)
    ml.y = float(_t.call("height_at", ml.x, ml.z)) + 1.0
    _shot("meadow", mp, ml, 60.0)
    var sc: Dictionary = st.get("scar", {})
    if sc.has("pos"):
        var spos: Vector3 = sc["pos"]
        var sf: Vector3 = sc["fwd"]
        var ss := Vector3(-sf.z, 0, sf.x)
        _shot("scar", spos + sf * 75.0 + ss * 20.0 + Vector3(0, 30.0, 0), spos + Vector3(0, 2.0, 0), 58.0)
        var mo: Vector3 = sc["mouth"]
        var mc := mo + sf * 24.0 + ss * 7.0
        mc.y = float(_t.call("height_at", mc.x, mc.z)) + 6.0
        var ml2 := mo
        ml2.y = float(_t.call("height_at", mo.x, mo.z)) + 3.0
        _shot("scar_mouth", mc, ml2, 60.0)
        var po: Vector3 = sc["post"]
        var pc := po + sf * 13.0 + ss * 5.0
        pc.y = float(_t.call("height_at", pc.x, pc.z)) + 3.5
        var pl := po
        pl.y = float(_t.call("height_at", po.x, po.z)) + 2.5
        _shot("guild_post", pc, pl, 60.0)
        print("SCAR ", sc)
    var fl: Array = st.get("fields", [])
    if not fl.is_empty():
        var f0: Vector3 = fl[0]
        var fo := Vector3(f0.x, 0, f0.z).normalized()
        _shot("fields", f0 + fo * 35.0 + Vector3(8, 18.0, 0), f0, 58.0)
    var fa: Array = st.get("farms", [])
    if not fa.is_empty():
        var fp: Vector3 = fa[0]
        _shot("farm", fp + Vector3(24, 14.0, 24), fp, 58.0)
    _shot("north", Vector3(0, 120, 120), Vector3(0, 0, -200), 60.0)
    var seen := {}
    for v in _t.get("people"):
        var rl: String = v.gear_role if v.gear_role != "" else v.role
        if seen.has(rl) or seen.size() >= 9:
            continue
        if not v.stay and rl != "smith" and rl != "miner" and rl != "lumberjack" and rl != "farmer" and rl != "healer":
            continue
        seen[rl] = true
        _shots.append(["kit_" + rl, v, Vector3.ZERO, 48.0])      # aimed at shot time
    for sh in st.get("shops", []):
        if String(sh[0]) == "armorer":
            var ay: Vector3 = sh[1]
            var af: Vector3 = sh[2]
            var asd := Vector3(-af.z, 0, af.x)
            _shot("rack", ay - af * 1.6 + af * 3.4 + asd * 3.0 + Vector3(0, 1.7, 0), ay - af * 1.6 + asd * 0.6 + Vector3(0, 1.1, 0), 55.0)
            break
    var pens: Array = st.get("pens", [])
    for i in range(mini(pens.size(), 4)):
        var pp: Vector3 = pens[i]
        var po2 := Vector3(pp.x, 0, pp.z).normalized()
        var pc2 := pp + po2 * 16.0 + Vector3(-po2.z, 0, po2.x) * 6.0
        pc2.y = float(_t.call("height_at", pc2.x, pc2.z)) + 9.0
        var pl2 := pp
        pl2.y = float(_t.call("height_at", pp.x, pp.z)) + 0.5
        _shot("pen_%d" % i, pc2, pl2, 55.0)
    _shot("ducks", Vector3(18, 3.0, 114), Vector3(12, -0.8, 127), 50.0)
    var mk: Vector3 = st.get("market", Vector3.ZERO)
    _shot("dogs", mk + Vector3(-6, 9.0, 6), mk + Vector3(0, 0.3, 0), 62.0)
    _shot("street_low", Vector3(-60, 2.6, -6), Vector3(10, 2.0, -4), 66.0)
    _shot("valley_east", Vector3(-330, 60, 60), Vector3(300, 10, -60), 62.0)
    var lms: Dictionary = st.get("landmarks", {})
    for k in lms:
        var lp: Vector3 = lms[k][0]
        var lf: Vector3 = lms[k][1]
        var ls := Vector3(-lf.z, 0, lf.x)
        _shot(k, lp + lf * 34.0 + ls * 14.0 + Vector3(0, 16.0, 0), lp + Vector3(0, 4.0, 0), 55.0)

func _process(_d: float) -> bool:
    _f += 1
    if _f == 30:
        var st: Dictionary = _t.call("stats")
        print("STATS ", {"people": st.get("people"), "props": st.get("props"), "nature": st.get("nature"),
            "rejected": st.get("rejected"), "furniture": st.get("furniture"), "landmarks": (st.get("landmarks", {}) as Dictionary).keys(), "overlap_dropped": st.get("overlap_dropped"), "house_box": st.get("house_box"), "plots": st.get("plots"), "towers": st.get("towers"),
            "shops": (st.get("shops", []) as Array).map(func(x): return x[0])})
        _plan(st)
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
    if _f >= 30 and (_f - 30) % 12 == 0:
        if _i > 0:
            root.get_texture().get_image().save_png("user://town_%s.png" % _shots[_i - 1][0])
            print("SAVED ", _shots[_i - 1][0])
        if _i >= _shots.size():
            var st2: Dictionary = _t.call("stats")
            print("END people=", st2.get("people"), " inside=", st2.get("inside"))
            _snapshot()
            return true
        var s: Array = _shots[_i]
        _cam.fov = float(s[3])
        if s[1] is Node3D:
            # a person: frame them where they are NOW, from in front, out of the walls
            var nd: Node3D = s[1]
            if "_route" in nd:
                nd.set("stay", true)            # hold still for the photo
            var np: Vector3 = nd.global_position
            var nf := Vector3(sin(nd.rotation.y), 0, cos(nd.rotation.y))
            var ns := Vector3(-nf.z, 0, nf.x)
            _cam.global_position = np + nf * 3.0 + ns * 1.2 + Vector3(0, 1.5, 0)
            _cam.look_at(np + Vector3(0, 0.95, 0), Vector3.UP)
        else:
            _cam.global_position = s[1]
            _cam.look_at(s[2], Vector3.UP)
        _i += 1
    return false

## SAVE THE GENERATED TOWN (Mr. E: save everything you build, every variant).
## Every run packs the finished town into a scene; run_probe.py strips the
## generator script off the root and files it under snapshots/ with a stamp.
func _own(n: Node, owner_root: Node) -> void:
    for c in n.get_children():
        if c is Camera3D:
            continue
        c.owner = owner_root
        if c.scene_file_path == "":
            _own(c, owner_root)

func _snapshot() -> void:
    _cam.get_parent().remove_child(_cam)
    _own(_t, _t)
    var ps := PackedScene.new()
    var err := ps.pack(_t)
    if err == OK:
        err = ResourceSaver.save(ps, "user://town_snapshot.tscn")
    print("SNAPSHOT ", err)
