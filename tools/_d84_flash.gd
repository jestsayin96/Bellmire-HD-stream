extends SceneTree
## D84 "the white figures" test. WINDOWED (the hit-flash material surgery is
## skipped headless, which is why no headless test ever saw it).
##  A. Cause: HeroBody and Cavalry override Townsfolk._process and never called
##     _tick_flash, so one raid hit left them lit white (emission 1.6) for good.
##     Flash a hero, a cavalry rider and a plain guard; each must be LIT the next
##     frame and DARK again within 0.6 s. The hero also takes _death_fx (0.5 s).
##  B. Null-surface logger: every body (Townsfolk/HeroBody/Cavalry/animals) is
##     scanned every 5 s for 60 s for a surface with no active material.
##  C. Shots: the hero at night mid-flash (what the bug froze) and 1 s after.
var _t: Node3D
var _f := 0
var _fail := 0
var _cam: Camera3D
const UID := "d84probe"

## the probe hero must not stay in the live roster: snapshot it, restore at the end
const RS := "user://roster.json"
const RB := "user://roster.json.d84bak"
var _had_roster := false

func _restore_roster() -> void:
    if _had_roster:
        DirAccess.copy_absolute(ProjectSettings.globalize_path(RB), ProjectSettings.globalize_path(RS))
        DirAccess.remove_absolute(ProjectSettings.globalize_path(RB))
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(RS))
    print("D84 roster restored (had=%s)" % _had_roster)

func _initialize() -> void:
    _had_roster = FileAccess.file_exists(RS)
    if _had_roster:
        DirAccess.copy_absolute(ProjectSettings.globalize_path(RS), ProjectSettings.globalize_path(RB))
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    print("D84 start renderer=%s" % DisplayServer.get_name())
    _run()

func _wait(s: float) -> void:
    await create_timer(s).timeout

func _bodies() -> Array:
    var out: Array = []
    var st: Array = [_t]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is Townsfolk or (c is Node3D and c.get_script() != null and String(c.get_script().resource_path).ends_with("animal.gd")):
            out.append(c)
            continue
        for g in c.get_children():
            st.append(g)
    return out

func _null_surfaces(b: Node) -> int:
    var n := 0
    var st: Array = [b]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is MeshInstance3D and (c as MeshInstance3D).visible and (c as MeshInstance3D).mesh != null:
            var mi: MeshInstance3D = c
            if mi.material_override == null:
                for i in mi.mesh.get_surface_count():
                    if mi.get_active_material(i) == null:
                        n += 1
        for g in c.get_children():
            st.append(g)
    return n

func _scan(tag: String) -> int:
    var bad := 0
    var bodies := _bodies()
    for b in bodies:
        var n := _null_surfaces(b)
        if n > 0:
            bad += 1
            print("D84_NULL %s %s class=%s model=%s surfaces=%d" % [tag, b.name, b.get_class() if b.get_script() == null else String(b.get_script().resource_path).get_file(), str(b.get("model")), n])
    var lit := 0
    for b in bodies:
        if b.has_method("flash_lit") and int(b.call("flash_lit")) > 0:
            lit += 1
    print("D84_SCAN %s bodies=%d null_bodies=%d lit=%d" % [tag, bodies.size(), bad, lit])
    return bad

func _check(who: String, b: Node, fx: String, hold: float) -> void:
    b.call(fx)
    await process_frame
    await process_frame
    var on := int(b.call("flash_lit"))
    await _wait(hold)
    var off := int(b.call("flash_lit"))
    var ok := on > 0 and off == 0
    if not ok:
        _fail += 1
    print("D84_FLASH %s %s %s lit_after_1f=%d lit_after_%.1fs=%d flash_t=%.2f" % ["OK" if ok else "FAIL", who, fx, on, hold, off, float(b.get("_flash_t"))])

func _run() -> void:
    await _wait(4.0)
    _t.call("chat_line", UID, "D84Probe", "!enlist knight")
    await _wait(3.0)
    var hs: Dictionary = _t.get("heroes")
    var hero = hs.get(UID)
    var cav = null
    var guard = null
    for p in _t.get("cavalry"):
        if is_instance_valid(p) and p is Cavalry and (cav == null or (p as Node3D).visible):
            cav = p          # a rider, on duty if any is (off duty they are hidden, not gone)
    if cav != null and not (cav as Node3D).visible:
        (cav as Node3D).visible = true
    for p in _t.get("people"):
        if not is_instance_valid(p) or not (p as Node3D).visible:
            continue
        if p is Cavalry:
            continue
        elif not (p is Cavalry) and not (p is HeroBody) and guard == null and (p as Townsfolk)._mdl != null:
            guard = p
    print("D84 picked hero=%s cav=%s plain=%s" % [hero != null, cav != null, guard != null])
    if hero == null or cav == null or guard == null:
        _fail += 1
    if hero: await _check("HeroBody", hero, "_flash", 0.6)
    if cav: await _check("Cavalry", cav, "_flash", 0.6)
    if guard: await _check("Townsfolk", guard, "_flash", 0.6)
    var bad := 0
    for k in 12:
        bad += _scan("t%02d" % (k * 5))
        await _wait(5.0)
    if bad > 0:
        _fail += 1
    if hero:
        (_t.get("daylight") as Daylight).override_hour = 23.0
        await _wait(2.0)
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        _cam.fov = 40.0
        var hp: Vector3 = (hero as Node3D).global_position
        _cam.global_position = hp + Vector3(3.2, 2.2, 3.2)
        _cam.look_at(hp + Vector3(0, 1.0, 0), Vector3.UP)
        hero.call("_flash")
        await process_frame
        await process_frame
        root.get_texture().get_image().save_png("res://renders/cycles/d84/d84_knight_night_midflash.png")
        await _wait(1.0)
        root.get_texture().get_image().save_png("res://renders/cycles/d84/d84_knight_night_after.png")
        var lit := int(hero.call("flash_lit"))
        print("D84_SHOT saved, hero lit after 1 s = %d" % lit)
        if lit != 0:
            _fail += 1
        await _check("HeroBody", hero, "_death_fx", 0.9)
    _t.queue_free()
    await process_frame
    _restore_roster()
    print("D84_TEST %s fails=%d" % ["OK" if _fail == 0 else "FAIL", _fail])
    quit(0 if _fail == 0 else 1)
