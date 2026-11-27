extends Node3D
## System 14 (Mr. E's Phase 2 list): THE GRAVEYARD KEEPER. One NPC who tends the
## kept garden of graves beside the chapel (town.gd lm_chapel), lantern in hand,
## walking from grave to grave and stooping at each. Body is the Kenney Graveyard
## Kit 5.0 keeper (CC0, assets/graveyard/LICENSE.txt) - a node-animated rig with its
## own clips (idle / walk / interact-right / holding-right), so it is driven here
## and NOT through Townsfolk/Rig, whose clip map is the KayKit library's.

const BODY := "res://assets/graveyard/character-keeper.glb"
const LANTERN := "res://assets/graveyard/lantern-candle.glb"
const KEEPER_H := 1.85          # world height, set off the measured AABB at load
const SPEED := 1.1              # a slow walk - he is old and the graves are close
const TEND_S := Vector2(5.0, 9.0)

var town: Node = null
var spots: Array = []           # Vector3 grave positions (y ignored)
var _i := 0
var _wait := 0.0
var _ap: AnimationPlayer = null
var _body: Node3D = null
var _clip := ""
var _rng := RandomNumberGenerator.new()
var height_m := 0.0             # measured, for the gate
const HAND_LOCAL := Vector3(-0.27, 0.0, 0.0)   # the fist, in arm-right's own space
const LANTERN_S := 1.3          # world scale of the lantern (0.39 m model -> ~0.5 m)
const LANTERN_TOP := 0.36       # handle ring height in the lantern's own space
var lantern: Node3D = null
var _hand: Marker3D = null
var _arm_r: Node3D = null
var _hold_q := Quaternion.IDENTITY
var _has_hold := false

func _ready() -> void:
	_rng.seed = 1414
	if not ResourceLoader.exists(BODY):
		push_warning("grave keeper: body missing, not placed")
		queue_free()
		return
	var ps := load(BODY) as PackedScene
	if ps == null:
		queue_free()
		return
	_body = ps.instantiate() as Node3D
	add_child(_body)
	var bb := _aabb(_body, Transform3D.IDENTITY)
	if bb.size.y > 0.001:
		var k := KEEPER_H / bb.size.y
		_body.scale = Vector3.ONE * k
		_body.position.y = -bb.position.y * k
		height_m = bb.size.y * k
	_ap = _find_ap(_body)
	# S143b: the lantern rides the RIGHT HAND, not the keeper root. The Kenney rig is
	# node-animated: `arm-right` is a mesh node whose arm runs along local -X to the
	# fist at x=-0.28 (measured off the glb accessor). A marker sits at that fist and
	# the lantern's handle is hung from it every frame, kept plumb (yaw only) so it
	# hangs like a lantern instead of tilting with the forearm. Walking and idling
	# hold the arm in the kit's own `holding-right` pose; tending plays interact-right
	# and the lantern follows the hand down to the grave.
	_arm_r = _find(_body, "arm-right") as Node3D
	if _arm_r:
		_hand = Marker3D.new()
		_hand.position = HAND_LOCAL
		_arm_r.add_child(_hand)
	if _ap:
		_hold_q = _pose_of("holding-right", "arm-right")
		_ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	if ResourceLoader.exists(LANTERN) and _hand:
		var lp := load(LANTERN) as PackedScene
		if lp:
			lantern = lp.instantiate() as Node3D
			add_child(lantern)
			var om := OmniLight3D.new()
			om.light_color = Color(1.0, 0.78, 0.45)
			om.light_energy = 0.9
			om.omni_range = 5.0
			om.position = Vector3(0, 0.2, 0)
			lantern.add_child(om)
	_play("idle")
	_wait = 2.0

func _aabb(n: Node, xf: Transform3D) -> AABB:
	var out := AABB()
	var have := false
	var t := xf
	if n is Node3D:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var a: AABB = t * (n as MeshInstance3D).mesh.get_aabb()
		out = a
		have = true
	for c in n.get_children():
		var ca := _aabb(c, t)
		if ca.size != Vector3.ZERO:
			out = ca if not have else out.merge(ca)
			have = true
	return out

func _find(n: Node, nm: String) -> Node:
	if String(n.name) == nm:
		return n
	for c in n.get_children():
		var f := _find(c, nm)
		if f:
			return f
	return null

# The arm-right rotation of a clip at t=0 (holding-right is a held pose).
func _pose_of(clip: String, node: String) -> Quaternion:
	if not _ap.has_animation(clip):
		return Quaternion.IDENTITY
	var a := _ap.get_animation(clip)
	for t in a.get_track_count():
		if a.track_get_type(t) == Animation.TYPE_ROTATION_3D and String(a.track_get_path(t)).ends_with(node):
			_has_hold = true
			return a.rotation_track_interpolate(t, 0.0)
	return Quaternion.IDENTITY

# Advance the rig by hand, then pin the arm and hang the lantern from the fist.
func _pose(delta: float) -> void:
	if _ap:
		_ap.advance(delta)
	if _arm_r and _has_hold and (_clip == "walk" or _clip == "idle"):
		_arm_r.quaternion = _hold_q
	if lantern and _hand:
		lantern.global_basis = Basis(Vector3.UP, global_rotation.y).scaled(Vector3.ONE * LANTERN_S)
		lantern.global_position = _hand.global_position - Vector3(0, LANTERN_TOP * LANTERN_S, 0)

func _find_ap(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var f := _find_ap(c)
		if f:
			return f
	return null

func _play(clip: String) -> void:
	if _ap == null or _clip == clip:
		return
	if _ap.has_animation(clip):
		var a := _ap.get_animation(clip)
		if a and clip != "interact-right":
			a.loop_mode = Animation.LOOP_LINEAR
		_ap.play(clip, 0.25)
		_clip = clip

func _ground(p: Vector3) -> float:
	if town and town.has_method("height_at"):
		return float(town.height_at(p.x, p.z))
	return p.y

func _process(delta: float) -> void:
	_pose(delta)
	if spots.size() < 2:
		return
	if _wait > 0.0:
		_wait -= delta
		if _wait <= 0.0:
			_i = (_i + 1 + _rng.randi() % maxi(1, spots.size() - 1)) % spots.size()
		return
	var tgt: Vector3 = spots[_i]
	var d := Vector3(tgt.x - position.x, 0, tgt.z - position.z)
	if d.length() < 0.9:
		# arrived at the grave's foot: stoop and tend it
		_play("interact-right")
		_wait = _rng.randf_range(TEND_S.x, TEND_S.y)
		return
	_play("walk")
	var step := d.normalized() * minf(SPEED * delta, d.length())
	position += step
	position.y = _ground(position)
	rotation.y = atan2(d.x, d.z)
