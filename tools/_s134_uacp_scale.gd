extends SceneTree
# S134 - System 12 (NPC variety) step S110c-2, part a: the 20 Quaternius UACP bodies are now IN
# assets/characters/uacp/ (CC0, LICENSE.txt beside them) and IMPORTED. This gate loads them the
# way the game will - as res:// PackedScenes through the import cache - and measures a PER-BODY
# scale, as the 10:58 row requires, instead of S133's single 0.7249 constant.
#
# WHY HEAD-BONE HEIGHT, NOT AABB HEIGHT: S133 found Witch 4.292 and Wizard/Elf 4.096 are HAT
# height. A mesh AABB counts the hat; the rest pose of the skeleton's Head bone does not. So the
# per-body scale is k = (KayKit ADV mean head-bone y) / (this body's head-bone y), and the AABB
# scale is printed beside it so the hat bias is on the record body by body.
#
# Transforms are accumulated LOCALLY up to the instanced root (S133's lesson: global_transform off
# a node not in the tree returns identity).
#
# Verdict: UACP_SCALE OK / UACP_SCALE FAIL.
#   `-- --redprove`      adds a body that does not exist                  -> must FAIL
#   `-- --redprove-bone` asks every body for a bone that does not exist     -> must FAIL
const UACP := "res://assets/characters/uacp/"
const ADV := "res://addons/kaykit_character_pack_adventures/Characters/gltf/"
const BODIES := ["BlueSoldier_Female", "BlueSoldier_Male", "Chef_Female", "Chef_Male", "Elf",
	"Goblin_Female", "Goblin_Male", "Knight_Golden_Female", "Knight_Golden_Male", "Knight_Male",
	"OldClassy_Female", "OldClassy_Male", "Soldier_Female", "Soldier_Male", "Viking_Female",
	"Viking_Male", "Witch", "Wizard", "Worker_Female", "Worker_Male"]
## a scale outside this band means the instrument, not the body, is wrong
const K_MIN := 0.40
const K_MAX := 1.20
## a surface whose albedo alpha is under this while transparency is on draws nothing.
## RED-PROVED on the real defect: run against the pre-fix import it FAILS 20/20 (PROGRESS S134).
const _alpha_floor := 0.5
var _cut := 0

func _local_xf(node: Node, top: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var w: Node = node
	while w != null and w != top.get_parent():
		if w is Node3D:
			xf = (w as Node3D).transform * xf
		w = w.get_parent()
	return xf

## [head_y or -1, aabb_h, ymin]
func _measure(n: Node, bone_names: Array) -> Array:
	var box := AABB()
	var first := true
	var head_y := -1.0
	var st: Array = [n]
	while not st.is_empty():
		var c: Node = st.pop_back()
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			var ab: AABB = _local_xf(c, n) * mi.get_aabb()
			box = ab if first else box.merge(ab)
			first = false
			# S134 FINDING: the FBX->glb conversion shipped every material with base alpha 0.0
			# and alphaMode MASK, so Godot imported ALPHA_SCISSOR at alpha 0 and the bodies drew
			# NOTHING while every number above still measured. Count surfaces that cut away.
			if mi.mesh:
				for si in mi.mesh.get_surface_count():
					var mat = mi.get_active_material(si)
					if mat is BaseMaterial3D:
						var bm := mat as BaseMaterial3D
						if bm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED and bm.albedo_color.a < _alpha_floor:
							_cut += 1
		if c is Skeleton3D and head_y < 0.0:
			var sk := c as Skeleton3D
			for bn in bone_names:
				var i := sk.find_bone(bn)
				if i >= 0:
					var p: Vector3 = (_local_xf(sk, n) * sk.get_bone_global_rest(i)).origin
					head_y = p.y
					break
		for g in c.get_children():
			st.append(g)
	return [head_y, box.size.y, box.position.y]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var red := "--redprove" in args
	var red_bone := "--redprove-bone" in args
	var fails: Array = []
	var adv_head: Array = []
	var adv_h: Array = []
	for nm in ["Rogue", "Knight", "Barbarian", "Mage"]:
		var ps = load(ADV + nm + ".glb")
		if ps == null:
			fails.append("ADV " + nm + ": no load")
			continue
		var n: Node = (ps as PackedScene).instantiate()
		var m := _measure(n, ["head", "Head"])
		print("S134 ADV %s head_y=%.3f h=%.3f" % [nm, m[0], m[1]])
		if m[0] > 0.0:
			adv_head.append(m[0])
		adv_h.append(m[1])
		n.free()
	if adv_head.size() != 4:
		fails.append("ADV head bone found on %d/4" % adv_head.size())
	var ah := 0.0
	for v in adv_head:
		ah += v
	ah /= max(1, adv_head.size())
	var aa := 0.0
	for v in adv_h:
		aa += v
	aa /= max(1, adv_h.size())
	var list: Array = BODIES.duplicate()
	if red:
		list.append("Nobody_Redprove")
	var bones: Array = ["NoSuchBone_Redprove"] if red_bone else ["Head", "head"]
	var ok_n := 0
	var table := {}
	for nm in list:
		var path: String = UACP + nm + ".glb"
		if not ResourceLoader.exists(path):
			fails.append(nm + ": not imported")
			continue
		var ps = load(path)
		if not (ps is PackedScene):
			fails.append(nm + ": no PackedScene")
			continue
		var n: Node = (ps as PackedScene).instantiate()
		if n == null:
			fails.append(nm + ": instantiate null")
			continue
		_cut = 0
		var m := _measure(n, bones)
		n.free()
		if _cut > 0:
			fails.append(nm + ": %d surfaces cut away (alpha)" % _cut)
			continue
		if m[0] <= 0.0:
			fails.append(nm + ": no head bone")
			continue
		var k: float = ah / m[0]
		var k_box: float = aa / m[1] if m[1] > 0.0 else 0.0
		print("S134 UACP %-20s head_y=%.3f h=%.3f ymin=%.3f  k_head=%.4f k_aabb=%.4f  hat_bias=%+.1f%%" % [nm, m[0], m[1], m[2], k, k_box, (k / k_box - 1.0) * 100.0 if k_box > 0.0 else 0.0])
		if k < K_MIN or k > K_MAX:
			fails.append(nm + ": k %.3f out of band" % k)
			continue
		table[nm] = snappedf(k, 0.0001)
		ok_n += 1
	print("S134 ADV mean head_y=%.3f h=%.3f" % [ah, aa])
	print("S134 TABLE ", JSON.stringify(table))
	var ks: Array = table.values()
	if fails.is_empty() and ok_n == BODIES.size():
		print("UACP_SCALE OK %d bodies imported from res://, per-body k %.4f-%.4f (head-bone, hat-free), 0 cut-away surfaces" % [ok_n, ks.min(), ks.max()])
	else:
		print("UACP_SCALE FAIL ok=%d/%d fails=%s" % [ok_n, list.size(), str(fails)])
	quit()
