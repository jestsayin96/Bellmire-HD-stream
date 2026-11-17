extends SceneTree
## S22 STAFF SWEEP (cloned from _s21_staff.gd). The lead's 15:58 ruling: METHOD = a shorter staff; the NUMBER is
## measured. Seven rows of three mages, the shipped rotation (Gear.held_rot (0,0,90)) at multipliers 1.9 .. 0.7.
## Each row's LOWEST point (every mesh under the held node incl. the D94 butt ribbons, AABB corners in world space)
## is sampled through the same seven poses, Cheer included. Report: worst per row, and the LARGEST multiplier at
## which every pose clears y 0 (or NONE). Gate: S22_STAFFSWEEP OK only if 21 staves held and every row/pose sampled -
## it is a measuring instrument, the number is the answer, not the verdict. Run WINDOWED.
var _cam: Camera3D
var _f := 0
var _stage: Node3D
var _r: Roster
var _out := "res://renders/cycles/s22/sweep/"
var _fails := 0
var _rows := {}   # row -> [[held, ap, tier]]
const MULTS := [1.9, 1.7, 1.5, 1.3, 1.1, 0.9, 0.7]
var _len := {}   # row -> staff length m (idle, tier 2)
var _aps: Array = []
var _low := {}   # "row|pose" -> min y
var _nsamp := {}
var _named_miss := 0
var _axis := {}   # "row|tier" -> mesh +Y in world, read in IDLE
const D := "res://assets/gear/dungeon/"
const ART_ROT := Vector3(-85.13, -90.06, 85.26)
const POSES := ["Idle", "Walking_A", "Hit_A", "Spellcast_Shoot", "Use_Item", "Cheer", "1H_Melee_Attack_Chop"]
const POSE_FRAMES := 50
var _phase := 0   # 0 settle, 1 idle shots, 2 poses, 3 done
var _shots: Array = []
var _si := 0
var _pi := 0
var _pf := 0

func _initialize() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
    _stage = Node3D.new()
    root.add_child(_stage)
    var we := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color(0.30, 0.31, 0.34)
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(0.75, 0.75, 0.80)
    e.ambient_light_energy = 0.7
    e.tonemap_mode = Environment.TONE_MAPPER_AGX
    we.environment = e
    _stage.add_child(we)
    var sun := DirectionalLight3D.new()
    sun.rotation = Vector3(deg_to_rad(-50), deg_to_rad(150), 0)
    sun.light_energy = 1.3
    sun.shadow_enabled = true
    _stage.add_child(sun)
    var floor := MeshInstance3D.new()
    var pm := PlaneMesh.new()
    pm.size = Vector2(600, 600)
    floor.mesh = pm
    var fm := StandardMaterial3D.new()
    fm.albedo_color = Color(0.42, 0.40, 0.37)
    floor.material_override = fm
    _stage.add_child(floor)
    _cam = Camera3D.new()
    _stage.add_child(_cam)
    _r = Roster.new()
    _stage.add_child(_r)
    var ri := 0
    for mu in MULTS:
        var row := "m%03d" % int(round(mu * 100))
        _rows[row] = []
        for t in [1, 2, 3]:
            # D94's named-piece path gives a named staff its OWN sibling mesh (Shepherd's Staff at tier 1 holds
            # staff_uncommon), so "tier t holds staff_<t>" is not the contract. The contract is: a pack staff is held.
            # Try the weapon levels near t until the REAL roster path holds one; print which.
            var uid := "s22w_%s%d" % [row, t]
            var h: Dictionary = _r.fresh(uid, "staff%s%d" % [row, t], "mage", "human")
            h["armour"] = t
            h["wkind"] = "staff"
            _r.heroes[uid] = h
            for wl in [t, t - 1, t + 1, t - 2, 1, 2, 3]:
                h["weapon"] = wl
                if _r.weapon_mesh(h).begins_with(D + "staff_"):
                    break
            if not _r.weapon_mesh(h).begins_with(D + "staff_"):
                print("S22_STAFFSWEEP FAIL row %s tier %d: no pack staff reached, roster gives %s" % [row, t, _r.weapon_mesh(h)])
                _fails += 1
                continue
            print("S22_STAFFSWEEP HELD row %s slot %d: %s (%s, weapon level %d)" % [row, t, _r.weapon_name(h), _r.weapon_mesh(h).get_file(), int(h["weapon"])])
            var p := Vector3(ri * 5.0 + (t - 2) * 1.4, 0, ri * 3.0)
            _dress(h, p, row, t, mu)
        ri += 1
    _shots = [["sweep_front_all", Vector3(15.0, 4.0, -16.0), Vector3(15.0, 1.0, 9.0)]]
    ri = 0
    for row in _rows:
        var c := Vector3(ri * 5.0, 1.0, ri * 3.0)
        _shots.append(["sweep_side_%s" % row, c + Vector3(6.5, 0.4, 0), c])
        _shots.append(["sweep_front_%s" % row, c + Vector3(0, 0.5, -5.5), c])
        ri += 1

func _dress(h: Dictionary, p: Vector3, row: String, t: int, mu: float) -> void:
    var host := Node3D.new()
    _stage.add_child(host)
    host.position = p
    host.rotation.y = PI
    var m: Node3D = (load("res://addons/kaykit_character_pack_adventures/Characters/gltf/" + String(Roster.CLASSES[h["class"]]["model"])) as PackedScene).instantiate()
    host.add_child(m)
    Gear.strip_props(m)
    var look := _r.weapon_look(h)
    var held := Gear.equip(m, _r.weapon_mesh(h), "handslot.r", "weapon", float(look["scale"]), float(look["glow"]))
    if held == null:
        print("S22_STAFFSWEEP FAIL row %s tier %d: nothing held" % [row, t])
        _fails += 1
        return
    Gear.tint_piece(held, look.get("piece", {}))
    Gear.deco_piece(held, look.get("piece", {}))
    held.scale = held.scale * (mu / Gear.hand_scale(_r.weapon_mesh(h)))
    if t == 2:
        _len[row] = Gear._local_aabb(held).size.y * held.scale.y
    var ap := Rig.find(m)
    if ap:
        Rig.prep(ap)
        Rig.play(ap, "Idle")
        _aps.append(ap)
    var lb := Label3D.new()
    lb.text = "%s t%d x%.2f" % [row, t, held.scale.y / maxf(float(look["scale"]), 0.001) * (1.0 if row == "A" else 1.0)]
    lb.font_size = 26
    lb.pixel_size = 0.004
    lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    lb.outline_size = 10
    lb.position = p + Vector3(0, 2.9, 0)
    _stage.add_child(lb)
    _rows[row].append([held, ap, t])

func _lowest(n: Node3D) -> float:
    var lo := INF
    var st: Array = [n]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is MeshInstance3D and (c as MeshInstance3D).mesh and (c as MeshInstance3D).visible:
            var mi: MeshInstance3D = c
            # run 6 read raw vertex arrays and gave -1.08 m for a staff the picture shows standing ON the floor
            # (compressed positions). Each mesh's own AABB corners in world space: conservative, cannot read that low.
            var xf := mi.global_transform
            var bb: AABB = mi.mesh.get_aabb()
            for i in range(8):
                lo = minf(lo, (xf * bb.get_endpoint(i)).y)
        for g in c.get_children():
            st.append(g)
    return lo

func _sample(pose: String) -> void:
    for row in _rows:
        for e in _rows[row]:
            if not is_instance_valid(e[0]):
                continue
            var k := "%s|%s" % [row, pose]
            _low[k] = minf(float(_low.get(k, INF)), _lowest(e[0]))
            _nsamp[k] = int(_nsamp.get(k, 0)) + 1

func _aim(s: Array) -> void:
    _cam.fov = 40.0
    _cam.global_position = s[1]
    _cam.look_at(s[2], Vector3.UP)

func _save(nm: String) -> void:
    root.get_texture().get_image().save_png(ProjectSettings.globalize_path(_out + "%s.png" % nm))

func _process(_d: float) -> bool:
    _f += 1
    if _phase == 0:
        if _f >= 40:
            _phase = 1
            _aim(_shots[0])
        return false
    if _phase == 1:
        if (_f - 40) % 10 == 9:
            if _si == 0:
                for e in _rows["m190"]:   # which mesh is the low one (idle), and where is the hand
                    var hn: Node3D = e[0]
                    var st: Array = [hn]
                    while not st.is_empty():
                        var c: Node = st.pop_back()
                        if c is MeshInstance3D and (c as MeshInstance3D).mesh:
                            var mi: MeshInstance3D = c
                            var lo := INF
                            for i in range(8):
                                lo = minf(lo, (mi.global_transform * mi.mesh.get_aabb().get_endpoint(i)).y)
                            print("S22_STAFFSWEEP MESH A t%d %s vis=%s low %.3f aabb %s" % [e[2], mi.name, str(mi.is_visible_in_tree()), lo, str(mi.mesh.get_aabb())])
                        for g in c.get_children():
                            st.append(g)
                    print("S22_STAFFSWEEP HAND A t%d hand y %.3f" % [e[2], hn.get_parent().global_position.y])
                for row in _rows:
                    for e in _rows[row]:
                        _axis["%s|%d" % [row, e[2]]] = (e[0] as Node3D).global_transform.basis.y.normalized()
            _save(_shots[_si][0])
            _si += 1
            if _si >= _shots.size():
                _phase = 2
                _pf = 0
                _aim(_shots[1])   # side of row A for the pose shots
                for ap in _aps:
                    Rig.play(ap, POSES[0])
                return false
            _aim(_shots[_si])
        return false
    if _phase == 2:
        _pf += 1
        if _pf > 6:
            _sample(POSES[_pi])
        if _pf == 28:
            _save("sweep_pose_m190_%s" % POSES[_pi])
        if _pf >= POSE_FRAMES:
            _pi += 1
            _pf = 0
            if _pi >= POSES.size():
                _phase = 3
                return _report()
            for ap in _aps:
                Rig.play(ap, POSES[_pi])
        return false
    return true

func _report() -> bool:
    var held_n := 0
    for row in _rows:
        held_n += (_rows[row] as Array).size()
        for e in _rows[row]:
            var hn: Node3D = e[0]
            var up: Vector3 = _axis.get("%s|%d" % [row, e[2]], Vector3.ZERO)
            print("S22_STAFFSWEEP AXIS (idle) row %s tier %d: mesh +Y in world %s, scale %.3f" % [row, e[2], str(up.snapped(Vector3.ONE * 0.01)), hn.scale.y])
            if up.y < 0.9:
                print("S22_STAFFSWEEP FAIL row %s tier %d: shaft not upright (y %.2f)" % [row, e[2], up.y])
                _fails += 1
    if held_n < 21:
        print("S22_STAFFSWEEP FLOOR UNMET: %d staves held, need 21" % held_n)
        _fails += 1
    var best := 0.0
    for row in _rows:
        var worst := INF
        var worst_pose := ""
        for pose in POSES:
            var k := "%s|%s" % [row, pose]
            if int(_nsamp.get(k, 0)) == 0:
                print("S22_STAFFSWEEP FAIL row %s pose %s: no samples" % [row, pose])
                _fails += 1
                continue
            var lo := float(_low[k])
            print("S22_STAFFSWEEP LOW row %s %-22s lowest vertex y %.3f m (%d samples)" % [row, pose, lo, _nsamp[k]])
            if lo < worst:
                worst = lo
                worst_pose = pose
        print("S22_STAFFSWEEP WORST row %s: %.3f m in %s%s" % [row, worst, worst_pose, "  <- BELOW THE FLOOR" if worst < 0.0 else ""])
        var mu := float(row.substr(1)) / 100.0
        print("S22_STAFFSWEEP ROW x%.2f staff length %.2f m (tier 2) worst %.3f m in %s -> %s" % [mu, float(_len.get(row, 0.0)), worst, worst_pose, "CLEARS" if worst >= 0.0 else "BELOW"])
        if worst >= 0.0 and mu > best:
            best = mu
    print("S22_STAFFSWEEP LARGEST CLEARING MULTIPLIER: %s" % ("x%.2f" % best if best > 0.0 else "NONE of 1.9..0.7"))
    print("S22_STAFFSWEEP %s (%d staves, %d poses, %d failures)" % ["OK" if _fails == 0 else "FAIL", held_n, POSES.size(), _fails])
    return true
