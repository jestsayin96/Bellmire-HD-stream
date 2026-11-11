extends SceneTree
## L6: bake the KayKit Adventurers 2.0 (CC0) bodies into ready hero scenes.
## The 2.0 files carry no animations and the free tier has only idle / walk /
## run / hit / death. Its Rig_Medium has the SAME bones and rest poses as the
## 1.0 rig the game already animates; only the node path differs (Rig_Medium vs
## Rig). So: one shared AnimationLibrary = every 1.0 animation re-pathed onto
## Rig_Medium, with 2.0's own versions of the moves it has laid over the top
## (Idle_A plays as "Idle"). Each body is saved as hero_<Name>.tscn with an
## AnimationPlayer pointing at that library - a scene any KayKit loader can use.
const SRC := "res://assets/characters/kaykit_adv2/"
const OLD := "res://addons/kaykit_character_pack_adventures/Characters/gltf/Knight.glb"
const BODIES := ["Knight", "Barbarian", "Mage", "Ranger", "Rogue", "Rogue_Hooded"]
const NATIVE := {"Idle": "Idle_A", "Idle_B": "Idle_B", "Walking_A": "Walking_A", "Walking_B": "Walking_B",
	"Walking_C": "Walking_C", "Running_A": "Running_A", "Running_B": "Running_B", "Hit_A": "Hit_A", "Hit_B": "Hit_B",
	"Death_A": "Death_A", "Death_A_Pose": "Death_A_Pose", "Death_B": "Death_B", "Death_B_Pose": "Death_B_Pose",
	"Interact": "Interact", "PickUp": "PickUp", "Throw": "Throw", "Use_Item": "Use_Item",
	"Jump_Full_Long": "Jump_Full_Long", "Jump_Full_Short": "Jump_Full_Short", "Jump_Idle": "Jump_Idle",
	"Jump_Land": "Jump_Land", "Jump_Start": "Jump_Start"}

func _ap_of(n: Node) -> AnimationPlayer:
	var st: Array = [n]
	while not st.is_empty():
		var c: Node = st.pop_back()
		if c is AnimationPlayer:
			return c
		for g in c.get_children():
			st.append(g)
	return null

func _initialize() -> void:
	var probe: Node = (load(SRC + "Knight.glb") as PackedScene).instantiate()
	var sk := Gear.skeleton(probe)
	var lib := AnimationLibrary.new()
	# 1. every 1.0 animation, re-pathed; tracks for bones 2.0 lacks (IK helpers) dropped
	var old: Node = (load(OLD) as PackedScene).instantiate()
	var oap := _ap_of(old)
	var n_old := 0
	for nm in oap.get_animation_list():
		var a: Animation = oap.get_animation(nm).duplicate(true)
		for t in range(a.get_track_count() - 1, -1, -1):
			var p := String(a.track_get_path(t))
			if not p.begins_with("Rig/Skeleton3D:"):
				a.remove_track(t)
				continue
			var bone := p.substr("Rig/Skeleton3D:".length())
			if sk.find_bone(bone) < 0:
				a.remove_track(t)
				continue
			a.track_set_path(t, NodePath("Rig_Medium/Skeleton3D:" + bone))
		lib.add_animation(nm, a)
		n_old += 1
	old.free()
	# 2. the 2.0 rig's own moves win where it has them
	var n_new := 0
	for f in ["Rig_Medium_General.glb", "Rig_Medium_MovementBasic.glb"]:
		var nn: Node = (load(SRC + f) as PackedScene).instantiate()
		var nap := _ap_of(nn)
		for want in NATIVE:
			var src := String(NATIVE[want])
			if nap.has_animation(src):
				if lib.has_animation(want):
					lib.remove_animation(want)
				lib.add_animation(want, nap.get_animation(src).duplicate(true))
				n_new += 1
		nn.free()
	probe.free()
	var err := ResourceSaver.save(lib, SRC + "adv2_anims.res")
	print("BAKE library: %d from 1.0, %d native 2.0, saved %s" % [n_old, n_new, error_string(err)])
	lib = load(SRC + "adv2_anims.res")
	for b in BODIES:
		var root: Node = (load(SRC + b + ".glb") as PackedScene).instantiate()
		var ap := AnimationPlayer.new()
		ap.name = "AnimationPlayer"
		root.add_child(ap)
		ap.owner = root
		ap.root_node = NodePath("..")
		ap.add_animation_library("", lib)
		var ps := PackedScene.new()
		var e2 := ps.pack(root)
		var e3 := ResourceSaver.save(ps, SRC + "hero_%s.tscn" % b)
		print("BAKE hero_%s.tscn pack %s save %s" % [b, error_string(e2), error_string(e3)])
		root.free()
	quit()
