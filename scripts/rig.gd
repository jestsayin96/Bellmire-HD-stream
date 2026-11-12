class_name Rig

const LOOPING := ["Idle", "Idle_B", "Idle_Combat", "Running_A", "Running_B", "Running_C",
    "Walking_A", "Walking_B", "Walking_C", "Walking_D_Skeletons", "2H_Melee_Idle",
    "Spellcasting", "Blocking", "Unarmed_Idle", "Lie_Idle", "Sit_Floor_Idle",
    # Quaternius creatures
    "Bat_Flying", "Slime_Idle", "Slime_Walk", "Skeleton_Idle", "Skeleton_Running",
    "Dragon_Flying"]

static func find(n: Node) -> AnimationPlayer:
    var st: Array = [n]
    while st.size() > 0:
        var c: Node = st.pop_back()
        if c is AnimationPlayer:
            return c
        for g in c.get_children():
            st.append(g)
    return null

## D17a: NO T-POSE. A body whose AnimationPlayer has nothing playing stands in
## whatever pose its last clip left it in - or the bind T-pose if the clip it was
## asked for was never there. So: a missing clip falls back to the model's own
## idle (logged once per clip name), and every one-shot (an attack, a cheer, a
## hit, a cast) is queued back into the loop the body was in before it (walk,
## idle, the saddle); a death settles into its held _Pose clip. `fallback =
## false` gives the old behaviour (tools/_d17a_test.gd --old).
static var fallback := true
static var misses := 0          # distinct clip names asked for and missing
static var fell_back := 0       # plays that went to the idle instead
static var chained := 0         # one-shots given a clip to return to
static var _missed := {}

const IDLES := ["Idle", "Unarmed_Idle", "Idle_B", "2H_Melee_Idle", "Skeleton_Idle",
    "Slime_Idle", "Bat_Flying", "Dragon_Flying"]

static func loops(nm: String) -> bool:
    return nm in LOOPING or nm.ends_with("_Pose") or nm.ends_with("_Idle")

static func prep(ap: AnimationPlayer) -> void:
    if ap == null:
        return
    for nm in ap.get_animation_list():
        var a: Animation = ap.get_animation(nm)
        if a == null:
            continue
        var lp: bool = loops(String(nm)) if fallback else nm in LOOPING
        a.loop_mode = Animation.LOOP_LINEAR if lp else Animation.LOOP_NONE
    # a queued return (attack -> walk) blends instead of snapping
    if fallback:
        ap.playback_default_blend_time = 0.2

## the model's own resting loop (cached on the player)
static func idle_of(ap: AnimationPlayer) -> String:
    if ap.has_meta("rig_idle"):
        return String(ap.get_meta("rig_idle"))
    var pick := ""
    for nm in IDLES:
        if ap.has_animation(nm):
            pick = nm
            break
    if pick == "":
        for nm in ap.get_animation_list():
            var s := String(nm)
            if s != "RESET" and s != "T-Pose" and ap.get_animation(nm).loop_mode != Animation.LOOP_NONE:
                pick = s
                break
    if pick == "":
        for nm in ap.get_animation_list():
            var s := String(nm)
            if s != "RESET" and s != "T-Pose":
                pick = s
                break
    ap.set_meta("rig_idle", pick)
    return pick

## what a one-shot hands back to when it ends ("" = hold the last frame)
static func after(ap: AnimationPlayer, nm: String) -> String:
    if nm.begins_with("Death_"):
        var p := nm + "_Pose"
        return p if ap.has_animation(p) else ""
    var back := String(ap.get_meta("rig_loop", ""))
    if back == "" or not ap.has_animation(back):
        back = idle_of(ap)
    return back

static func play(ap: AnimationPlayer, nm: String, blend := 0.15) -> void:
    if ap == null:
        return
    if not ap.has_animation(nm):
        if not fallback:
            return
        if not _missed.has(nm):
            _missed[nm] = true
            misses += 1
            print("RIG: no clip '%s' on %s - playing its idle" % [nm, ap.get_parent().name if ap.get_parent() else "?"])
        fell_back += 1
        nm = idle_of(ap)
        if nm == "":
            return
    if loops(nm):
        if fallback:
            ap.set_meta("rig_loop", nm)
        if ap.current_animation == nm:
            return
        if fallback:
            ap.clear_queue()
        ap.play(nm, blend)
        return
    ap.play(nm, blend)
    if fallback:
        ap.clear_queue()
        var nxt := after(ap, nm)
        if nxt != "" and nxt != nm:
            ap.queue(nxt)
            chained += 1

static func tint(n: Node, col: Color) -> void:
    var st: Array = [n]
    while st.size() > 0:
        var c: Node = st.pop_back()
        if c is MeshInstance3D:
            var m: MeshInstance3D = c
            if m.mesh:
                for i in range(m.mesh.get_surface_count()):
                    var src: Material = m.get_active_material(i)
                    if src is StandardMaterial3D:
                        var d: StandardMaterial3D = src.duplicate()
                        d.albedo_color = col
                        m.set_surface_override_material(i, d)
        for g in c.get_children():
            st.append(g)


# ===========================================================================
# EQUIPMENT
# The KayKit rigs carry dedicated attachment bones - `handslot.r` and
# `handslot.l` - so a weapon mesh parented there follows the hand through every
# animation. This is what makes the gear economy visible: a viewer who buys a
# dragontooth blade should SEE it, not read a number.
# ===========================================================================
const EQUIP_DIR := "res://addons/kaykit_character_pack_adventures/Assets/gltf/"

static func skeleton(n: Node) -> Skeleton3D:
    var st: Array = [n]
    while st.size() > 0:
        var c: Node = st.pop_back()
        if c is Skeleton3D:
            return c
        for g in c.get_children():
            st.append(g)
    return null

# `slot` is our own name for the attachment so re-equipping replaces rather
# than stacking. `bone` is the rig's bone, normally handslot.r / handslot.l.
static func equip(model_root: Node, mesh: String, bone := "handslot.r",
                  slot := "weapon", scale := 1.0, glow := 0.0) -> Node3D:
    var sk := skeleton(model_root)
    if sk == null:
        return null
    var tag := "eq_" + slot
    var old := sk.get_node_or_null(NodePath(tag))
    if old:
        old.free()                       # free, not queue_free: we re-add now
    if mesh == "":
        return null
    if sk.find_bone(bone) < 0:
        return null
    var ps: PackedScene = load(EQUIP_DIR + mesh)
    if ps == null:
        return null
    var att := BoneAttachment3D.new()
    att.name = tag
    att.bone_name = bone
    sk.add_child(att)
    var m: Node3D = ps.instantiate()
    m.scale = Vector3(scale, scale, scale)
    att.add_child(m)
    if glow > 0.0:
        _ignite(m, glow)
    return m

# higher weapon tiers reuse the same geometry, so they separate themselves by
# burning: a runed blade smoulders, a dragontooth one is lit from within
static func _ignite(n: Node, amount: float) -> void:
    var st: Array = [n]
    while st.size() > 0:
        var c: Node = st.pop_back()
        if c is MeshInstance3D:
            var mi: MeshInstance3D = c
            if mi.mesh:
                for i in range(mi.mesh.get_surface_count()):
                    var src: Material = mi.get_active_material(i)
                    if src is StandardMaterial3D:
                        var dup: StandardMaterial3D = src.duplicate()
                        dup.emission_enabled = true
                        dup.emission = Color(1.0, 0.62, 0.22).lerp(
                            Color(0.65, 0.85, 1.0), clampf(amount - 0.5, 0.0, 1.0) * 0.7)
                        # 1.6 blew the blade out to a white blob with the glow
                        # post-pass on top. It should smoulder, not illuminate.
                        dup.emission_energy_multiplier = amount * 0.30
                        mi.set_surface_override_material(i, dup)
        for g in c.get_children():
            st.append(g)

static func unequip(model_root: Node, slot := "weapon") -> void:
    var sk := skeleton(model_root)
    if sk == null:
        return
    var old := sk.get_node_or_null(NodePath("eq_" + slot))
    if old:
        old.free()
