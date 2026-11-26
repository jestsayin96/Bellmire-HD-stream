"""Read a .glb's world-space AABB from its JSON chunk in pure python.

WHY THIS EXISTS: the Blender MCP bridge is the art lane's only route to Blender,
and when it is down the lane cannot measure a body at all. This reads the glTF
accessor min/max for every POSITION, pushes the eight corners of each mesh AABB
through that node's accumulated world matrix, and unions the result.

IT IS GEOMETRY ONLY. It answers HOW BIG a body is. It says NOTHING about whether
the body READS - no render, no visibility, no occlusion. Do not write its output
into a fit register as if it were a fit pass.
"""
import json, struct, sys, math

def _chunks(path):
    with open(path, "rb") as f:
        magic, ver, total = struct.unpack("<III", f.read(12))
        assert magic == 0x46546C67, f"{path}: not a glb (magic {magic:#x})"
        js = None
        while f.tell() < total:
            ln, ty = struct.unpack("<II", f.read(8))
            data = f.read(ln)
            if ty == 0x4E4F534A:
                js = json.loads(data.decode("utf-8"))
                break
        assert js is not None, f"{path}: no JSON chunk"
        return js

def _mat(node):
    if "matrix" in node:                      # glTF matrices are column-major
        m = node["matrix"]
        return [[m[0], m[4], m[8], m[12]],
                [m[1], m[5], m[9], m[13]],
                [m[2], m[6], m[10], m[14]],
                [m[3], m[7], m[11], m[15]]]
    t = node.get("translation", [0.0, 0.0, 0.0])
    r = node.get("rotation", [0.0, 0.0, 0.0, 1.0])   # x,y,z,w
    s = node.get("scale", [1.0, 1.0, 1.0])
    x, y, z, w = r
    R = [[1-2*(y*y+z*z), 2*(x*y-z*w),   2*(x*z+y*w)],
         [2*(x*y+z*w),   1-2*(x*x+z*z), 2*(y*z-x*w)],
         [2*(x*z-y*w),   2*(y*z+x*w),   1-2*(x*x+y*y)]]
    return [[R[i][0]*s[0], R[i][1]*s[1], R[i][2]*s[2], t[i]] for i in range(3)] + [[0,0,0,1]]

def _mul(a, b):
    return [[sum(a[i][k]*b[k][j] for k in range(4)) for j in range(4)] for i in range(4)]

def _xform(m, p):
    return [sum(m[i][k]*p[k] for k in range(3)) + m[i][3] for i in range(3)]

def bounds(path):
    js = _chunks(path)
    meshes = js.get("meshes", [])
    accs = js.get("accessors", [])
    nodes = js.get("nodes", [])
    lo = [math.inf]*3; hi = [-math.inf]*3; nacc = 0
    scene = js.get("scenes", [{}])[js.get("scene", 0)]
    stack = [(i, [[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]) for i in scene.get("nodes", range(len(nodes)))]
    while stack:
        idx, parent = stack.pop()
        node = nodes[idx]
        world = _mul(parent, _mat(node))
        if "mesh" in node:
            for prim in meshes[node["mesh"]].get("primitives", []):
                ai = prim.get("attributes", {}).get("POSITION")
                if ai is None: continue
                a = accs[ai]
                mn, mx = a.get("min"), a.get("max")
                if not mn or not mx: continue
                nacc += 1
                for cx in (mn[0], mx[0]):
                    for cy in (mn[1], mx[1]):
                        for cz in (mn[2], mx[2]):
                            p = _xform(world, [cx, cy, cz])
                            for k in range(3):
                                lo[k] = min(lo[k], p[k]); hi[k] = max(hi[k], p[k])
        for c in node.get("children", []): stack.append((c, world))
    assert nacc, f"{path}: RED ON EMPTY - no POSITION accessor with min/max; a size computed over zero accessors is not a measurement"
    return {"accessors": nacc,
            "min": [round(v, 6) for v in lo], "max": [round(v, 6) for v in hi],
            "size_x": round(hi[0]-lo[0], 4), "size_y": round(hi[1]-lo[1], 4), "size_z": round(hi[2]-lo[2], 4)}

if __name__ == "__main__":
    for p in sys.argv[1:]:
        print(p, json.dumps(bounds(p)))
