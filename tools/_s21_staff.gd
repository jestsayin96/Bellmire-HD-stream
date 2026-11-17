extends SceneTree
## S21 (System 2 engine half, the staff settlement; cloned from _s19_hand.gd). Two open questions on the
## pack staff, both settled by measurement and by a picture, not by argument:
##   (1) MINE vs ART'S. Row A is what ships: Gear.held_rot (0,0,90) x1.9, measured in Godot on handslot.r.
##       Row B is art's handed-over Blender euler (-85.13,-90.06,85.26) x1.30, applied as given.
##       Row C is my rotation at art's scale x1.30, so scale and rotation are judged separately.
##   (2) THE FLOOR. Art measured 1.30 as the largest scale whose butt clears the floor (0.43 below the grip).
##       Row A is x1.9, so does its butt go through the floor in a lower pose? Each row's LOWEST VERTEX in world
##       space is sampled every frame through seven poses the game actually plays.
## Gate: S21_STAFF OK only if 9 staves are held, row A's shaft points UP (mesh +Y world y >= 0.9) on all three
## tiers, every pose produced samples, and row A's lowest vertex never goes below the floor (y < 0.0).
## Rows B/C are comparison rows: their numbers are printed, they do not gate. Run WINDOWED.
var _cam: Camera3D
var _f := 0
var _stage: Node3D
var _r: Roster
var _out := "res://renders/cycles/s21/"
var _fails := 0
var _rows := {"A": [], "B": [], "C": []}   # row -> [[held, ap, tier]]
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
    for row in ["A", "B", "C"]:
        for t in [1, 2, 3]:
            # D94's named-piece path gives a named staff its OWN sibling mesh (Shepherd's Staff at tier 1 holds
            # staff_uncommon), so "tier t holds staff_<t>" is not the contract. The contract is: a pack staff is held.
            # Try the weapon levels near t until the REAL roster path holds one; print which.
            var uid := "s21_%s%d" % [row, t]
            var h: Dictionary = _r.fresh(uid, "staff%s%d" % [row, t], "mage", "human")
            h["armour"] = t
            h["wkind"] = "staff"
            _r.heroes[uid] = h
            for wl in [t, t - 1, t + 1, t - 2, 1, 2, 3]:
                h["weapon"] = wl
                if _r.weapon_mesh(h).begins_with(D + "staff_"):
                    break
            if not _r.weapon_mesh(h).begins_with(D + "staff_"):
                print("S21_STAFF FAIL row %s tier %d: no pack staff reached, roster gives %s" % [row, t, _r.weapon_mesh(h)])
                _fails += 1
                continue
            print("S21_STAFF HELD row %s slot %d: %s (%s, weapon level %d)" % [row, t, _r.weapon_name(h), _r.weapon_mesh(h).get_file(), int(h["weapon"])])
            var p := Vector3(ri * 5.0 + (t - 2) * 1.4, 0, ri * 3.0)
            _dress(h, p, row, t)
        ri += 1
    _shots = [["s21_front_all", Vector3(5.0, 1.6, -9.0), Vector3(5.0, 1.0, 3.0)]]
    ri = 0
    for row in ["A", "B", "C"]:
        var c := Vector3(ri * 5.0, 1.0, ri * 3.0)
        _shots.append(["s21_side_%s" % row, c + Vector3(6.5, 0.4, 0), c])
        _shots.append(["s21_front_%s" % row, c + Vector3(0, 0.5, -5.5), c])
        ri += 1

func _dress(h: Dictionary, p: Vector3, row: String, t: int) -> void:
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
        print("S21_STAFF FAIL row %s tier %d: nothing held" % [row, t])
        _fails += 1
        return
    Gear.tint_piece(held, look.get("piece", {}))
    Gear.deco_piece(held, look.get("piece", {}))
    if row == "B":
        held.rotation_degrees = ART_ROT
    if row != "A":
        held.scale = held.scale * (1.30 / Gear.hand_scale(_r.weapon_mesh(h)))
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
                for e in _rows["A"]:   # which mesh is the low one (idle), and where is the hand
                    var hn: Node3D = e[0]
                    var st: Array = [hn]
                    while not st.is_empty():
                        var c: Node = st.pop_back()
                        if c is MeshInstance3D and (c as MeshInstance3D).mesh:
                            var mi: MeshInstance3D = c
                            var lo := INF
                            for i in range(8):
                                lo = minf(lo, (mi.global_transform * mi.mesh.get_aabb().get_endpoint(i)).y)
                            print("S21_STAFF MESH A t%d %s vis=%s low %.3f aabb %s" % [e[2], mi.name, str(mi.is_visible_in_tree()), lo, str(mi.mesh.get_aabb())])
                        for g in c.get_children():
                            st.append(g)
                    print("S21_STAFF HAND A t%d hand y %.3f" % [e[2], hn.get_parent().global_position.y])
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
            _save("s21_pose_A_%s" % POSES[_pi])
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
            print("S21_STAFF AXIS (idle) row %s tier %d: mesh +Y in world %s, scale %.3f" % [row, e[2], str(up.snapped(Vector3.ONE * 0.01)), hn.scale.y])
            if row == "A" and up.y < 0.9:
                print("S21_STAFF FAIL row A tier %d: shaft not upright (y %.2f)" % [e[2], up.y])
                _fails += 1
    if held_n < 9:
        print("S21_STAFF FLOOR UNMET: %d staves held, need 9" % held_n)
        _fails += 1
    for row in ["A", "B", "C"]:
        var worst := INF
        var worst_pose := ""
        for pose in POSES:
            var k := "%s|%s" % [row, pose]
            if int(_nsamp.get(k, 0)) == 0:
                print("S21_STAFF FAIL row %s pose %s: no samples" % [row, pose])
                _fails += 1
                continue
            var lo := float(_low[k])
            print("S21_STAFF LOW row %s %-22s lowest vertex y %.3f m (%d samples)" % [row, pose, lo, _nsamp[k]])
            if lo < worst:
                worst = lo
                worst_pose = pose
        print("S21_STAFF WORST row %s: %.3f m in %s%s" % [row, worst, worst_pose, "  <- BELOW THE FLOOR" if worst < 0.0 else ""])
        if row == "A" and worst < 0.0:
            _fails += 1
    print("S21_STAFF %s (%d staves, %d poses, %d failures)" % ["OK" if _fails == 0 else "FAIL", held_n, POSES.size(), _fails])
    return true
