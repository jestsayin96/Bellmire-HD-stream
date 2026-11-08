class_name Hex
extends RefCounted
## Hex COORDINATES only. There are no hex plates in this build - the ground is
## continuous. The grid survives purely as maths for placement, neighbours and
## pathing, which is what it was always actually doing.

## A hex holds one house plot, so it is sized for a real building (up to
## 8 x 10 m) plus yard. ROW_H / COL_W must stay at 0.866 for a regular hex.
const COL_W := 14.0
const ROW_H := 12.12
const COLS := 23
const ROWS := 19

static func pos(c: int, r: int) -> Vector3:
    return Vector3(c * COL_W + (r % 2) * (COL_W * 0.5) - COLS * COL_W * 0.5,
                   0.0,
                   r * ROW_H - ROWS * ROW_H * 0.5)

static func axial(h: Vector2i) -> Vector2i:
    return Vector2i(h.x - (h.y - (h.y & 1)) / 2, h.y)

static func dist(a: Vector2i, b: Vector2i) -> float:
    var p := axial(a)
    var q := axial(b)
    var dq := p.x - q.x
    var dr := p.y - q.y
    return float(absi(dq) + absi(dq + dr) + absi(dr)) / 2.0

static func neighbours(h: Vector2i) -> Array[Vector2i]:
    var odd := (h.y & 1) == 1
    var out: Array[Vector2i] = []
    var offs := ([[1,0],[0,-1],[-1,-1],[-1,0],[-1,1],[0,1]] if not odd
                 else [[1,0],[1,-1],[0,-1],[-1,0],[0,1],[1,1]])
    for o in offs:
        var n := Vector2i(h.x + int(o[0]), h.y + int(o[1]))
        if n.x >= 0 and n.x < COLS and n.y >= 0 and n.y < ROWS:
            out.append(n)
    return out

static func all_cells() -> Array[Vector2i]:
    var out: Array[Vector2i] = []
    for r in range(ROWS):
        for c in range(COLS):
            out.append(Vector2i(c, r))
    return out
