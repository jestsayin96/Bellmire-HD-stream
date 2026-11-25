extends SceneTree
# tools/art/_tex_path_probe.gd - ART LANE, tools/art/ only.
# THE DECISIVE MEASUREMENT, and it reverses what a file listing suggests.
# ResourceLoader.exists("res://...png") answers TRUE for a PNG that is NOT on
# disk, because the .import sidecar registers the resource against a cached
# .ctex. So "the source PNG is missing" does NOT mean "the sidecar is dead".
# This asks the only question that settles it: WHERE does each body's albedo
# texture actually come from - an external res:// path, or inside the .glb.
#
# 24 Nov 23:5x CT: the body list was HARDCODED to the three bodies that the
# broodglut find happened to need. A probe that can only ever be pointed at
# three bodies cannot answer the question for the fourth, so the list now
# comes from TEXPATH_BODIES (comma separated) and falls back to those three.
# RED ON EMPTY, twice over: an empty body list is a FAIL, and a body that
# yields ZERO material slots is a FAIL - that is the shape of a probe that
# loaded nothing and printed a clean sheet.
func _init():
	var env: String = OS.get_environment("TEXPATH_BODIES").strip_edges()
	var bodies: Array = []
	if env != "":
		for part in env.split(","):
			var s: String = part.strip_edges()
			if s != "":
				bodies.append(s)
	else:
		bodies = ["lastcuff", "broodglut", "pledgeman"]
	var fails := 0
	if bodies.is_empty():
		print("TEXPATH FAIL empty body list - RED ON EMPTY")
		fails += 1
	for n in bodies:
		var p: String = "res://assets/monsters/minibosses/%s.glb" % n
		var ps = load(p)
		if ps == null:
			print("TEXPATH FAIL %s load null" % n)
			fails += 1
			continue
		var inst = ps.instantiate()
		var stack: Array = [inst]
		var i := 0
		var external := 0
		while stack.size() > 0:
			var node = stack.pop_back()
			if node is MeshInstance3D and node.mesh != null:
				var m: Mesh = node.mesh
				for s in range(m.get_surface_count()):
					var mat = node.get_active_material(s)
					i += 1
					if mat == null:
						print("TEXPATH %s slot%d mat=null" % [n, i])
						continue
					var ap := "<none>"
					var nm := "<none>"
					if mat is BaseMaterial3D:
						var t = mat.albedo_texture
						if t != null:
							ap = t.resource_path
							if ap == "":
								ap = "<EMBEDDED, no resource_path> %dx%d" % [t.get_width(), t.get_height()]
						var nt = mat.normal_texture
						if nt != null:
							nm = nt.resource_path
							if nm == "":
								nm = "<EMBEDDED>"
					# AN EXTERNAL res:// PNG IS THE BROODGLUT FAULT'S SHAPE: the
					# body ships and its skin does not, unless that PNG is tracked.
					if ap.begins_with("res://") and ap.ends_with(".png"):
						external += 1
						print("TEXPATH %s slot%d EXTERNAL-ALBEDO %s" % [n, i, ap])
					if nm.begins_with("res://") and nm.ends_with(".png"):
						external += 1
						print("TEXPATH %s slot%d EXTERNAL-NORMAL %s" % [n, i, nm])
					print("TEXPATH %s slot%d mat=%s albedo=%s normal=%s" % [n, i, mat.resource_name, ap, nm])
			for c in node.get_children():
				stack.append(c)
		if i == 0:
			print("TEXPATH FAIL %s zero material slots - an instrument that measured nothing is not a pass" % n)
			fails += 1
		print("TEXPATH SUMMARY %s slots=%d external_png_refs=%d" % [n, i, external])
		inst.free()
	print("TEXPATH_DONE bodies=%d fails=%d" % [bodies.size(), fails])
	quit(0 if fails == 0 else 1)
