"""_crew_prop.py - does the Rammer's crew figure read in the hero's language?

WHY THIS EXISTS. The team lead's 11:5x row made an EYE JUDGEMENT and labelled it
one: at matched height beside the hero the Rammer's operator "is blockier and
flatter-faceted than the chibi knight - its helmet is roughly a quarter of its
height against the knight's near-two-fifths". It asked me to decide whether the
crew figure wants a pass. A decision wants a number that can MOVE, so this
measures the same question off the shipped geometry.

WHAT IT DOES. It rasterises a true orthographic FRONT SILHOUETTE from the
triangles (not from vertices - a low-poly vertex profile under-samples and
invents pinches that are not in the picture), then applies ONE rule to both
figures:

    head_frac = (top row -> NECK row) / (top row -> bottom row)
    NECK = the row of minimum silhouette width in the upper half of the figure.

A head sits above a pinch in both languages - a chibi helmet wider than the
neck, a human dome narrower than the shoulders - so the same rule reads both.

IT GOES RED, NOT GREEN, WHEN:
  - a silhouette is empty, or a cluster selected for a figure has no triangles;
  - the neck search finds no strict interior minimum (a monotone profile means
    the rule did not apply, and a rule that did not apply is not a pass);
  - a fraction lands outside (0,1);
  - THE KNIGHT CONTROL misses the band 0.33-0.55. The knight is the control: if
    this cannot reproduce a figure whose proportions the house already knows by
    eye, its reading of the operator means nothing. The band is deliberately
    wide - it is a sanity rail, not the finding.

WHAT IT CANNOT SEE, SAID BEFORE THE NUMBERS. It is a silhouette: it cannot see
facet shading, colour, or whether the operator's goggles read as a face. It
measures ONE camera (front). A figure with no facing would pass it unchanged.
The faceting numbers below are per-figure face counts and mean face area; they
say how MUCH geometry there is, not whether the shading reads flat.
"""
import json, struct, sys
import numpy as np

ERRORS = []
def red(m): ERRORS.append(m)

CT = {5126: np.float32, 5125: np.uint32, 5123: np.uint16, 5121: np.uint8}
NC = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}

def load(p):
    d = open(p, 'rb').read()
    assert d[:4] == b'glTF', p
    off, ch = 12, []
    while off < len(d):
        ln, ty = struct.unpack_from('<II', d, off); off += 8
        ch.append((ty, d[off:off+ln])); off += ln
    return json.loads(ch[0][1].decode('utf-8')), ch[1][1]

def mkacc(g, blob):
    def acc(i):
        a = g['accessors'][i]; bv = g['bufferViews'][a['bufferView']]
        o = bv.get('byteOffset', 0) + a.get('byteOffset', 0); c = NC[a['type']]
        arr = np.frombuffer(blob, CT[a['componentType']], count=a['count']*c, offset=o)
        return arr.reshape(a['count'], c) if c > 1 else arr
    return acc

def trs(n):
    M = np.eye(4)
    if 'matrix' in n:
        return np.array(n['matrix'], float).reshape(4, 4).T
    if 'scale' in n:
        M[:3, :3] = M[:3, :3] @ np.diag(n['scale'])
    if 'rotation' in n:
        x, y, z, w = n['rotation']
        M[:3, :3] = np.array([
            [1-2*(y*y+z*z), 2*(x*y-z*w),   2*(x*z+y*w)],
            [2*(x*y+z*w),   1-2*(x*x+z*z), 2*(y*z-x*w)],
            [2*(x*z-y*w),   2*(y*z+x*w),   1-2*(x*x+y*y)]]) @ M[:3, :3]
    if 'translation' in n:
        M[:3, 3] = n['translation']
    return M

def tris_knight(path):
    """every triangle of the standing body, skinned at rest. Props and the cape
    are excluded - the cape is cloth and would widen the shoulder read."""
    g, blob = load(path); acc = mkacc(g, blob); world = {}
    def walk(i, P):
        W = P @ trs(g['nodes'][i]); world[i] = W
        for c in g['nodes'][i].get('children', []):
            walk(c, W)
    for r in g['scenes'][0]['nodes']:
        walk(r, np.eye(4))
    sk = g['skins'][0]
    ibm = acc(sk['inverseBindMatrices']).reshape(-1, 4, 4).transpose(0, 2, 1)
    JM = np.stack([world[j] @ ibm[k] for k, j in enumerate(sk['joints'])])
    skipn = ('Sword', 'Shield', 'Offhand', 'Cape')
    out = []
    for i, n in enumerate(g['nodes']):
        if n.get('mesh') is None or any(s in n.get('name', '') for s in skipn):
            continue
        for pr in g['meshes'][n['mesh']]['primitives']:
            p = acc(pr['attributes']['POSITION']).astype(np.float64)
            if n.get('skin') is None:
                p = (world[i][:3, :3] @ p.T).T + world[i][:3, 3]
            else:
                J = acc(pr['attributes']['JOINTS_0']).astype(int)
                W = acc(pr['attributes']['WEIGHTS_0']).astype(np.float64)
                ph = np.c_[p, np.ones(len(p))]
                r = np.zeros((len(p), 3))
                for k in range(4):
                    r += W[:, k:k+1] * np.einsum('nij,nj->ni', JM[J[:, k]], ph)[:, :3]
                p = r
            idx = acc(pr['indices']).astype(np.int64).reshape(-1, 3)
            out.append(p[idx])
    if not out:
        red("knight: no triangles"); return np.zeros((0, 3, 3))
    return np.vstack(out)

def tris_operator(path, x_split=0.5):
    """the crew figure: the olive `_body` material entire, plus the `_dark`
    triangles whose three corners all stand in the operator's own column
    (x > x_split). The wooden tripod is `_bone`; the head block and the rope are
    the dark mass on the frame's axis and are excluded by that test."""
    g, blob = load(path); acc = mkacc(g, blob)
    byname = {m.get('name', str(i)): i for i, m in enumerate(g['meshes'])}
    bodyk = [k for k in byname if k.endswith('_body')]
    darkk = [k for k in byname if k.endswith('_dark')]
    if not bodyk or not darkk:
        red(f"operator: expected a _body and a _dark mesh, got {sorted(byname)}")
        return np.zeros((0, 3, 3))
    def tr(mi, mask_x=None):
        o = []
        for pr in g['meshes'][mi]['primitives']:
            p = acc(pr['attributes']['POSITION']).astype(np.float64)
            idx = acc(pr['indices']).astype(np.int64).reshape(-1, 3)
            t = p[idx]
            if mask_x is not None:
                t = t[(t[:, :, 0] > mask_x).all(axis=1)]
            o.append(t)
        return np.vstack(o) if o else np.zeros((0, 3, 3))
    body = tr(byname[bodyk[0]])
    helm = tr(byname[darkk[0]], x_split)
    if len(body) == 0:
        red("operator: body material has no triangles"); return np.zeros((0, 3, 3))
    if len(helm) == 0:
        red(f"operator: NO dark triangles right of x={x_split} - the helmet cluster is EMPTY")
        return np.zeros((0, 3, 3))
    return np.vstack([body, helm])

def silhouette(tris, res=600):
    """orthographic front raster: x across, y up. Scanline fill per triangle."""
    if len(tris) == 0:
        red("silhouette: no triangles in"); return None, None, None
    xs, ys = tris[:, :, 0], tris[:, :, 1]
    x0, x1 = xs.min(), xs.max(); y0, y1 = ys.min(), ys.max()
    if y1 - y0 <= 0 or x1 - x0 <= 0:
        red("silhouette: degenerate bounds"); return None, None, None
    sc = (res - 2) / (y1 - y0)
    W = int((x1 - x0) * sc) + 2
    img = np.zeros((res, W), bool)
    px = (xs - x0) * sc
    py = (y1 - ys) * sc          # row 0 is the top
    for k in range(len(tris)):
        ax, ay, bx, by, cx, cy = px[k, 0], py[k, 0], px[k, 1], py[k, 1], px[k, 2], py[k, 2]
        r0 = max(int(np.floor(min(ay, by, cy))), 0)
        r1 = min(int(np.ceil(max(ay, by, cy))), res - 1)
        for r in range(r0, r1 + 1):
            yq = r + 0.5
            hit = []
            for (X0, Y0, X1, Y1) in ((ax, ay, bx, by), (bx, by, cx, cy), (cx, cy, ax, ay)):
                if (Y0 <= yq < Y1) or (Y1 <= yq < Y0):
                    hit.append(X0 + (yq - Y0) * (X1 - X0) / (Y1 - Y0))
            if len(hit) >= 2:
                a, b = int(np.floor(min(hit))), int(np.ceil(max(hit)))
                img[r, max(a, 0):min(b + 1, W)] = True
    if not img.any():
        red("silhouette: raster is EMPTY")
        return None, None, None
    return img, (y1 - y0), (x1 - x0)

def head_fraction(img, label):
    """NECK = the narrowest row between the HEAD'S OWN WIDEST row and the
    figure's widest row (shoulders or arms). The first version of this searched
    the whole upper half and found the CROWN TAPER instead - both figures came
    back at 0.048 and the knight control caught it. A dome narrows at the top;
    the neck is the pinch BELOW the head's widest point, not above it."""
    rows = np.where(img.any(axis=1))[0]
    top, bot = rows[0], rows[-1]
    H = bot - top + 1
    w = img.sum(axis=1).astype(float)
    # THE WIDEST ROW IS SEARCHED IN THE LOWER 55% ONLY, AND HERE IS WHY.
    # The Rammer's operator has an arm RAISED to the rope, so its widest row sits
    # level with its own head and the first version of this rule refused to apply
    # (head_widest == body_widest == row 69) - which was the rule being honest.
    # The restriction is a change to the rule, so it is controlled: the knight's
    # arms hang and its widest row is at 53% of height, inside the searched zone,
    # so the knight's number must NOT move when this is switched on. It does not
    # (0.483 before and after). If it ever does, that is RED below.
    lo_zone = top + int(H * 0.45)
    body_row = lo_zone + int(np.argmax(w[lo_zone:bot + 1]))
    head_zone = w[top:top + max(3, int(H * 0.45))]
    if head_zone.size < 3 or head_zone.max() <= 0:
        red(f"{label}: head zone EMPTY"); return None, None
    head_row = top + int(np.argmax(head_zone))        # the head's own widest
    if not (head_row < body_row):
        red(f"{label}: the head's widest row ({head_row}) is not above the figure's "
            f"widest row ({body_row}) - the rule did not apply")
        return None, None
    seg = w[head_row + 1:body_row]
    if seg.size < 2:
        red(f"{label}: no rows between the head's widest and the body's widest "
            f"- no neck to find"); return None, None
    neck = head_row + 1 + int(np.argmin(seg))
    if not (w[neck] < w[head_row] * 0.92 and w[neck] < w[body_row] * 0.92):
        red(f"{label}: no strict neck - the narrowest row between head and body "
            f"({w[neck]:.0f} px) is not 8% under both ({w[head_row]:.0f}, "
            f"{w[body_row]:.0f}); the profile has no pinch")
        return None, None
    f = (neck - top) / H
    if not (0.0 < f < 1.0):
        red(f"{label}: head fraction {f:.3f} outside (0,1)")
    return f, {"top_row": int(top), "head_widest_row": int(head_row),
               "neck_row": int(neck), "body_widest_row": int(body_row),
               "bottom_row": int(bot), "rows": int(H),
               "neck_width_px": int(w[neck]), "head_width_px": int(w[head_row]),
               "max_width_px": int(w.max())}

def facets(tris):
    if len(tris) == 0:
        return {}
    cr = np.cross(tris[:, 1] - tris[:, 0], tris[:, 2] - tris[:, 0])
    ar = 0.5 * np.linalg.norm(cr, axis=1)
    h = tris[:, :, 1].max() - tris[:, :, 1].min()
    return {"faces": int(len(ar)), "height": round(float(h), 3),
            "faces_per_unit_height": round(len(ar) / h, 1),
            "mean_face_area": round(float(ar.mean()), 5),
            "median_face_area": round(float(np.median(ar)), 5)}

def figure(tris, label):
    img, h, w = silhouette(tris)
    if img is None:
        return None
    f, meta = head_fraction(img, label)
    if f is None:
        return None
    d = {"head_frac": round(f, 3), "height_units": round(float(h), 3),
         "width_units": round(float(w), 3)}
    d.update(meta); d.update(facets(tris))
    return d



# =====================================================================
# THE SECOND READING, AND IT IS THE ONE THAT ANSWERS THE EYE.
#
# The neck rule above works on the knight and FAILS ON THE OPERATOR, and the
# failure is interesting rather than annoying: the operator's arm is RAISED to
# the rope, so in silhouette the arm fuses with the head, the head's widest row
# IS the arm, and the "neck" the rule then finds at row 216 is the waist. The
# number it returns for the operator, 0.361, IS NOT A HEAD FRACTION and must not
# be shipped as one. A silhouette cannot tell an arm from a head.
#
# So this reading uses DEPTH AND MATERIAL. It rasterises the figure through one
# orthographic camera with a z-buffer, records WHICH material won each pixel,
# and then asks the viewer's question directly: how far down the figure is the
# head material still VISIBLE? Occlusion is done by the raster, not by me - the
# knight's head mesh runs down inside its own collar and must not be counted,
# and a bbox cannot know that.
#
# RED on empty: zero visible head pixels, or a head that reaches the floor.
# CROSS-CHECK: on the knight the two independent methods must agree within 0.06.
# If they disagree, both are suspect and the run says so.

# =====================================================================
# WHERE DOES THE CREW FIGURE SIT IN ITS OWN FAMILY?
# "Blockier and flatter-faceted THAN THE CHIBI KNIGHT" is one comparison, and
# the operator is not a hero. The question that decides whether it wants a pass
# is whether it is an outlier among THE THIRTY-FOUR BODIES THIS LANE SHIPPED.
# Faces per unit of height is defined for every glb, so this survey needs no
# per-body heuristic and cannot quietly pick its own favourites.
def survey(dirpath):
    import os
    rows = []
    for fn in sorted(os.listdir(dirpath)):
        if not fn.endswith('.glb'):
            continue
        try:
            g, blob = load(os.path.join(dirpath, fn)); acc = mkacc(g, blob)
            tris = []
            for m in g['meshes']:
                for pr in m['primitives']:
                    pos = acc(pr['attributes']['POSITION']).astype(np.float64)
                    idx = acc(pr['indices']).astype(np.int64).reshape(-1, 3)
                    tris.append(pos[idx])
            t = np.vstack(tris)
            d = facets(t)
            d['name'] = fn[:-4]
            rows.append(d)
        except Exception as e:
            red(f"survey: {fn} unreadable: {e}")
    if not rows:
        red("survey: no bodies read - EMPTY")
    return rows


def knight_groups(path):
    """{head: helmet + head meshes, body: everything else standing}"""
    g, blob = load(path); acc = mkacc(g, blob); world = {}
    def walk(i, P):
        W = P @ trs(g['nodes'][i]); world[i] = W
        for c in g['nodes'][i].get('children', []):
            walk(c, W)
    for r in g['scenes'][0]['nodes']:
        walk(r, np.eye(4))
    sk = g['skins'][0]
    ibm = acc(sk['inverseBindMatrices']).reshape(-1, 4, 4).transpose(0, 2, 1)
    JM = np.stack([world[j] @ ibm[k] for k, j in enumerate(sk['joints'])])
    skipn = ('Sword', 'Shield', 'Offhand', 'Cape')
    head, body = [], []
    for i, n in enumerate(g['nodes']):
        nm = n.get('name', '')
        if n.get('mesh') is None or any(x in nm for x in skipn):
            continue
        for pr in g['meshes'][n['mesh']]['primitives']:
            p = acc(pr['attributes']['POSITION']).astype(np.float64)
            if n.get('skin') is None:
                p = (world[i][:3, :3] @ p.T).T + world[i][:3, 3]
            else:
                J = acc(pr['attributes']['JOINTS_0']).astype(int)
                W = acc(pr['attributes']['WEIGHTS_0']).astype(np.float64)
                ph = np.c_[p, np.ones(len(p))]; r = np.zeros((len(p), 3))
                for k in range(4):
                    r += W[:, k:k+1] * np.einsum('nij,nj->ni', JM[J[:, k]], ph)[:, :3]
                p = r
            idx = acc(pr['indices']).astype(np.int64).reshape(-1, 3)
            (head if ('Helmet' in nm or 'Head' in nm) else body).append(p[idx])
    if not head or not body:
        red("knight_groups: head or body group EMPTY"); return None
    return {"body": np.vstack(body), "head": np.vstack(head)}

def operator_groups(path, x_split=0.5):
    """{head: the dark triangles standing in the operator's own column,
        body: the olive `_body` material}"""
    g, blob = load(path); acc = mkacc(g, blob)
    byname = {m.get('name', str(i)): i for i, m in enumerate(g['meshes'])}
    bk = [k for k in byname if k.endswith('_body')]
    dk = [k for k in byname if k.endswith('_dark')]
    if not bk or not dk:
        red("operator_groups: no _body/_dark mesh"); return None
    def tr(mi, mask=None):
        o = []
        for pr in g['meshes'][mi]['primitives']:
            p = acc(pr['attributes']['POSITION']).astype(np.float64)
            idx = acc(pr['indices']).astype(np.int64).reshape(-1, 3)
            t = p[idx]
            if mask is not None:
                t = t[(t[:, :, 0] > mask).all(axis=1)]
            o.append(t)
        return np.vstack(o) if o else np.zeros((0, 3, 3))
    body = tr(byname[bk[0]]); head = tr(byname[dk[0]], x_split)
    # THE OPERATOR'S BOOTS ARE DARK TOO. The first run of this group reached the
    # figure's floor and the "is this a head" guard caught it. Keep only the TOP
    # cluster of the dark column, split at the largest vertical gap, and REFUSE
    # (red) if there is no real gap - no gap means helmet and boots are one mass
    # and the group cannot be called a head.
    if len(head):
        cy = head[:, :, 1].mean(axis=1)
        order = np.argsort(cy); cys = cy[order]
        gaps = np.diff(cys)
        gi = int(np.argmax(gaps)) if len(gaps) else -1
        if gi < 0 or gaps[gi] < 0.15:
            red(f"operator_groups: the dark column has no vertical gap over 0.15 "
                f"(largest {0.0 if gi < 0 else gaps[gi]:.3f}) - helmet and boots are "
                f"one cluster, this group is not a head")
            return None
        head = head[order[gi + 1:]]
    if len(body) == 0 or len(head) == 0:
        red(f"operator_groups: body {len(body)} tris, head {len(head)} tris - EMPTY group")
        return None
    return {"body": body, "head": head}


def zraster(groups, res=520):
    """groups: {label: tris}. One orthographic front camera over the union.
    Returns (label_image, rows, meta). Nearest triangle wins each pixel."""
    allt = np.vstack([t for t in groups.values() if len(t)])
    if len(allt) == 0:
        red("zraster: nothing to draw"); return None, None
    x0, x1 = allt[:, :, 0].min(), allt[:, :, 0].max()
    y0, y1 = allt[:, :, 1].min(), allt[:, :, 1].max()
    sc = (res - 2) / (y1 - y0)
    W = int((x1 - x0) * sc) + 2
    lab = np.zeros((res, W), np.int8)          # 0 = empty
    zb = np.full((res, W), np.inf)
    for li, (name, tris) in enumerate(groups.items(), start=1):
        for k in range(len(tris)):
            t = tris[k]
            px = (t[:, 0] - x0) * sc
            py = (y1 - t[:, 1]) * sc
            pz = -t[:, 2]                      # +Z is the FRONT of a body here
            r0 = max(int(np.floor(py.min())), 0)
            r1 = min(int(np.ceil(py.max())), res - 1)
            for r in range(r0, r1 + 1):
                yq = r + 0.5
                hits = []
                for a, b in ((0, 1), (1, 2), (2, 0)):
                    Y0, Y1 = py[a], py[b]
                    if (Y0 <= yq < Y1) or (Y1 <= yq < Y0):
                        u = (yq - Y0) / (Y1 - Y0)
                        hits.append((px[a] + u * (px[b] - px[a]),
                                     pz[a] + u * (pz[b] - pz[a])))
                if len(hits) < 2:
                    continue
                hits.sort()
                (xa, za), (xb, zb_) = hits[0], hits[-1]
                ca, cb = int(np.floor(xa)), int(np.ceil(xb))
                ca, cb = max(ca, 0), min(cb, W - 1)
                if cb < ca:
                    continue
                cols = np.arange(ca, cb + 1)
                u = np.zeros(len(cols)) if xb == xa else (cols + 0.5 - xa) / (xb - xa)
                zs = za + np.clip(u, 0, 1) * (zb_ - za)
                m = zs < zb[r, ca:cb + 1]
                if m.any():
                    zb[r, ca:cb + 1] = np.where(m, zs, zb[r, ca:cb + 1])
                    lab[r, ca:cb + 1] = np.where(m, li, lab[r, ca:cb + 1])
    if not (lab > 0).any():
        red("zraster: label image is EMPTY"); return None, None
    return lab, {"res": res, "cols": W, "units_tall": float(y1 - y0)}

def visible_head(groups, head_label, figure_name):
    lab, meta = zraster(groups)
    if lab is None:
        return None
    body_rows = np.where((lab > 0).any(axis=1))[0]
    top, bot = int(body_rows[0]), int(body_rows[-1])
    H = bot - top + 1
    li = list(groups).index(head_label) + 1
    hm = (lab == li)
    if hm.sum() == 0:
        red(f"{figure_name}: the head material is NOT VISIBLE anywhere - 0 pixels")
        return None
    hrows = np.where(hm.any(axis=1))[0]
    hbot = int(hrows[-1])
    if hbot >= bot - 2:
        red(f"{figure_name}: head material visible down to the figure's own floor "
            f"- the group is not a head")
        return None
    f = (hbot - top + 1) / H
    if not (0.0 < f < 1.0):
        red(f"{figure_name}: visible head fraction {f:.3f} outside (0,1)")
    return {"visible_head_frac": round(f, 3), "head_px": int(hm.sum()),
            "head_bottom_row": hbot, "top_row": top, "bottom_row": bot,
            "rows": H, "raster": meta}

if __name__ == '__main__':
    KN = "addons/kaykit_character_pack_adventures/Characters/gltf/Knight.glb"
    OP = "assets/monsters/minibosses/rammer.glb"
    out = {}
    kn = figure(tris_knight(KN), "knight")
    op = figure(tris_operator(OP), "operator")
    out["neck_rule"] = {"knight": kn, "operator": op,
                        "operator_note": "SEE THE COMMENT ABOVE: the raised arm fuses "
                        "with the head, so this number is NOT the operator's head."}
    if kn and not (0.33 <= kn["head_frac"] <= 0.55):
        red(f"CONTROL FAILED: knight neck-rule head fraction {kn['head_frac']} outside "
            f"0.33-0.55 - the instrument is the suspect, not the operator")
    kg, og = knight_groups(KN), operator_groups(OP)
    kv = visible_head(kg, "head", "knight") if kg else None
    ov = visible_head(og, "head", "operator") if og else None
    out["visible_head"] = {"knight": kv, "operator": ov}
    # THE CROSS-CHECK, AND WHAT IT IS ENTITLED TO ASK. The neck rule finds the
    # PINCH; the visible-head rule finds the LOWEST VISIBLE HEAD PIXEL, which on a
    # helmed figure is the throat piece below that pinch. They are different
    # landmarks, so demanding equality was wrong - my first tolerance of 0.06
    # failed the knight at 0.483 vs 0.550 and the failure was mine, not the model's.
    # What it may ask: the visible head must reach AT OR BELOW the pinch, and not
    # by more than 0.12 of the figure's height.
    if kn and kv:
        d = kv["visible_head_frac"] - kn["head_frac"]
        if not (-0.01 <= d <= 0.12):
            red(f"CROSS-CHECK FAILED on the knight: neck pinch {kn['head_frac']} vs "
                f"lowest visible head pixel {kv['visible_head_frac']} (delta {d:+.3f} "
                f"outside -0.01..+0.12) - two methods disagree, both are suspect")
    if kv and ov:
        out["visible_head_ratio_knight_over_operator"] = round(
            kv["visible_head_frac"] / ov["visible_head_frac"], 2)
    kf, of_ = facets(np.vstack(list(kg.values()))) if kg else {}, facets(np.vstack(list(og.values()))) if og else {}
    out["faceting"] = {"knight": kf, "operator": of_}
    if kf and of_:
        out["faceting"]["faces_per_unit_height_ratio"] = round(
            kf["faces_per_unit_height"] / of_["faces_per_unit_height"], 2)
        out["faceting"]["mean_face_area_ratio_operator_over_knight"] = round(
            of_["mean_face_area"] / kf["mean_face_area"], 2)
    out["survey"] = sorted(survey("assets/monsters/minibosses"),
                           key=lambda r: r["faces_per_unit_height"])

    # ---------------------------------------------------------------- red proof
    # A GREEN THAT CANNOT GO RED IS NOT A PASS. Two deliberate perturbations,
    # both of which MUST fail, and the run is RED if either comes back green.
    saved = list(ERRORS)
    proofs = {}
    del ERRORS[:]
    bad = operator_groups(OP, x_split=9.0)          # no dark triangles out there
    proofs["empty_head_column"] = "RED" if (bad is None and ERRORS) else "GREEN - BAD"
    del ERRORS[:]
    if kg:
        swapped = {"body": kg["head"], "head": kg["body"]}   # body called the head
        vh = visible_head(swapped, "head", "knight_swapped")
        proofs["body_labelled_head"] = "RED" if (vh is None and ERRORS) else "GREEN - BAD"
    del ERRORS[:]
    ERRORS.extend(saved)
    for k, v in proofs.items():
        if v != "RED":
            red(f"RED PROOF FAILED: perturbation '{k}' did not fail the instrument")
    out["red_proofs"] = proofs
    out["errors"] = ERRORS
    out["verdict"] = "RED" if ERRORS else "GREEN"
    print(json.dumps(out, indent=2))
    sys.exit(1 if ERRORS else 0)
