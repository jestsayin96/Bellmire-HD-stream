extends Node
## S24 (System 2 engine half): the pack staff's POSE-AWARE grip, handled where staffs are placed and nowhere else.
## Gear.equip slides a pack staff's grip toward the butt (STAFF_GRIP_SHIFT) so the shaft clears the floor in
## the low poses (S21: Idle needs >= +0.20 of shift). The one pose that then inverts is the raised, turned-over
## fist (Cheer): the head would hang down into the floor. So this node watches the HAND, not the clip: when the
## slot's -X (the shaft's "up" under the held rotation, measured S19) turns toward the ground, the staff is turned
## end for end in the fist so its head points up again; when the hand comes back, so does the staff. No pose
## names, no per-clip table - the slot every other weapon uses is untouched.
const UP_ROT := Vector3(0, 0, 90)      # Gear.held_rot for a pack staff: mesh +Y -> slot -X
const FLIP_ROT := Vector3(0, 0, -90)   # end for end: mesh +Y -> slot +X
const HYST := 0.15                     # slot +X world-y band, so a hand passing level does not flicker
var held: Node3D
var flipped := false

func _process(_dt: float) -> void:
    var att := get_parent() as Node3D
    if att == null or held == null or not is_instance_valid(held):
        return
    var r := held.rotation_degrees
    # only ever touch the two rotations this node owns (a harness or another caller may set its own)
    if not (r.is_equal_approx(UP_ROT) or r.is_equal_approx(FLIP_ROT)):
        return
    var xy := att.global_transform.basis.x.normalized().y   # slot +X in world: -0.99 (down) in Idle
    if not flipped and xy > HYST:
        flipped = true
        held.rotation_degrees = FLIP_ROT
    elif flipped and xy < -HYST:
        flipped = false
        held.rotation_degrees = UP_ROT
