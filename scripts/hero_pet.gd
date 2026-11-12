class_name HeroPet
extends Node3D
## L13: a hero's pet (a cosmetic, !wear corgi). One of the CC0 farm animals,
## small, heeling a step behind and to the side of its hero: it walks when it
## has to catch up and idles when the hero stands. top_level, so it moves on its
## own instead of being bolted to the hero.

var owner_body: Node3D
var model := ""
var scale_f := 0.35
var _ap: AnimationPlayer
var _walk := ""
var _idle := ""
var _side := 1.0

func _ready() -> void:
	top_level = true
	_side = 1.0 if randf() < 0.5 else -1.0
	var ps: PackedScene = load(model) if ResourceLoader.exists(model) else null
	if ps == null:
		return
	var m: Node3D = ps.instantiate()
	m.scale = Vector3.ONE * scale_f
	add_child(m)
	var st: Array = [m]
	while not st.is_empty():
		var c: Node = st.pop_back()
		if c is AnimationPlayer:
			_ap = c
		for g in c.get_children():
			st.append(g)
	if _ap:
		for a in _ap.get_animation_list():
			var s := String(a)
			if s.begins_with("Walk") and _walk == "":
				_walk = s
			if s.begins_with("Idle") and _idle == "":
				_idle = s
			if s == "clip":
				_walk = s
				_idle = s
		for a in [_walk, _idle]:
			if a != "" and _ap.has_animation(a):
				_ap.get_animation(a).loop_mode = Animation.LOOP_LINEAR
	if owner_body and is_instance_valid(owner_body):
		global_position = _spot()

func _spot() -> Vector3:
	var b := owner_body.global_basis
	return owner_body.global_position + b.x * 0.75 * _side - b.z * 0.55

func _process(delta: float) -> void:
	if owner_body == null or not is_instance_valid(owner_body):
		queue_free()
		return
	visible = owner_body.is_visible_in_tree()
	var want := _spot()
	var to := want - global_position
	to.y = 0.0
	var d := to.length()
	if d > 12.0:
		global_position = want          # left behind (a new floor): catch up at once
		return
	if d > 0.25:
		var step := minf(d, (2.5 + d * 1.5) * delta)
		global_position += to.normalized() * step
		global_position.y = owner_body.global_position.y
		rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), delta * 8.0)
		_play(_walk)
	else:
		global_position.y = owner_body.global_position.y
		_play(_idle)

func _play(nm: String) -> void:
	if _ap and nm != "" and _ap.has_animation(nm) and _ap.current_animation != nm:
		_ap.play(nm, 0.2)
