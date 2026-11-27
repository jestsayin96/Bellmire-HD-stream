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
	if ResourceLoader.exists(LANTERN):
		var lp := load(LANTERN) as PackedScene
		if lp:
			var lan := lp.instantiate() as Node3D
			lan.scale = Vector3.ONE * 1.3
			lan.position = Vector3(0.38, 0.55, 0.22)
			add_child(lan)
			var om := OmniLight3D.new()
			om.light_color = Color(1.0, 0.78, 0.45)
			om.light_energy = 0.9
			om.omni_range = 5.0
			om.position = Vector3(0, 0.3, 0)
			lan.add_child(om)
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
