class_name Dice
extends RefCounted
## D9 (the DnD RULE, town side): Bellmire's dice. Every outcome in the streets
## that used to be a flat chance or a fixed number - a raid swing and its
## damage, a save, the watch's crossbows, a caster's bolt, a fire burst, a
## fisher's strike, a day's work, a torch on the thatch - is a roll here:
## d20 + modifier vs a DC or an AC; damage is dice + modifier. A natural 20
## always succeeds (and an attack's dice are rolled twice); a natural 1 always
## fails. Uses the global RNG, so a test can seed() it.

static var rolled := 0           # d20s rolled (tests)

static func d(sides: int) -> int:
    return randi_range(1, maxi(sides, 1))

## adv > 0: advantage (the better of two), adv < 0: disadvantage
static func d20(adv := 0) -> int:
    rolled += 1
    var a := randi_range(1, 20)
    if adv == 0:
        return a
    var b := randi_range(1, 20)
    return maxi(a, b) if adv > 0 else mini(a, b)

## n dice of `sides`, summed
static func roll(n: int, sides: int) -> int:
    var t := 0
    for _i in range(maxi(n, 0)):
        t += d(sides)
    return t

## damage: dice [n, sides] + bonus; a critical rolls the dice twice; never under 1
static func damage(dice: Array, bonus: float, crit := false) -> float:
    var n := int(dice[0])
    var s := int(dice[1])
    var t := roll(n, s) + (roll(n, s) if crit else 0)
    return maxf(1.0, float(t) + bonus)

## the average of dice [n, sides]
static func mean(dice: Array) -> float:
    return float(dice[0]) * (float(dice[1]) + 1.0) * 0.5

## an ability check or a save: d20 + bonus vs dc -> {d, total, ok}
static func check(bonus: int, dc: int, adv := 0) -> Dictionary:
    var r := d20(adv)
    var tot := r + bonus
    return {"d": r, "total": tot, "ok": r == 20 or (r != 1 and tot >= dc)}
