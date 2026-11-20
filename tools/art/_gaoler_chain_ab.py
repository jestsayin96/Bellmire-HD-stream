"""_gaoler_chain_ab - DOES THE CHAIN READ AS A HEAP, OR AS A HOOP LYING FLAT?

THE FAULT, named by the team lead off the contact sheet at 02:58 CT on 20 Nov
and confirmed by me on renders/art/minibosses/gaoler_chibi/three_quarter.png
BEFORE a line of geometry was changed: Shacklemaw's drag-chain was a flat
spiral - 2.6 turns rising 0.085 m across a 0.92 m radius - and at the 3/4
camera's 14 degrees of elevation that projects to a thin ellipse. It reads as a
wire hoop lying on the floor. The creature's one idea is IT DRAGS. A hoop at
rest is the one thing a drag is not, so the idea was not carried by the
geometry, which is exactly the bar Mr. E set for this set.

THE INSTRUMENT, and it is built the way pass 11 taught this lane to build one.
`mask_of` renders a group ALONE: it answers how BIG a thing is and says nothing
about whether a viewer can SEE it. So the chain is measured the viewer's way -
ONE camera, set up once from the WHOLE body's bounds, then the same frame shot
with the chain group's objects hidden from render. The pixels that MOVED are
the chain's visible contribution, occlusion by the body included, because the
renderer did the depth and not me.

  ONE CAMERA IS THE WHOLE POINT. lordgen.render_views re-frames off the objects
  it is handed and calls add_lights every time, so an A frame and a B frame
  taken through two of those calls differ in FRAMING and in BRIGHTNESS and the
  difference mask is then the entire image. This file builds the rig once per
  view and only toggles hide_render.

THE THREE NUMBERS, and the bar was written down before any of them was read:

  heap_aspect   the heap's own silhouette height over its width in the 3/4
                frame. THIS IS THE FAULT STATED AS A NUMBER: a disc lying on
                the floor, seen from 14 degrees up, cannot be taller than about
                sin(14) = 0.24 of its width however wide it is. A heap can.
                BAR: >= 0.45.
  heap_h_frac   the heap's height in METRES over the body's, off the geometry
                rather than off the pixels - a second, independent eye, so a
                camera quirk cannot pass this alone. BAR: >= 0.20.
  heap_px       the moved mask's area, as a fraction of arm A's. A "fix" that
                works by making the chain smaller is not one. BAR: >= 0.60.

IT GOES RED ON EMPTY BY CONSTRUCTION. A heap mask under 200 px, or a zero-width
bounding box, reports RED and the row carries NO numbers: a ratio computed over
nothing reads green and means exactly nothing. The run to the hand is measured
the same way in the same pass and reported separately - two changes sharing one
render pass are still two measurements.

  blender -b -noaudio -P tools/art/_gaoler_chain_ab.py -- --repo <repo>
"""
import os
import sys
import json
import math
import argparse

import bpy
import numpy as np
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordlib as L          # noqa: E402
import lordgen as G          # noqa: E402
import minibosses as M       # noqa: E402
import minibossgen as MG     # noqa: E402

SRC = 0.02          # alpha/colour delta that counts as "this pixel moved"
KEYS = ("gaoler_chibi", "gaoler")
BAR_ASPECT = 0.45
BAR_HFRAC = 0.20
BAR_PXKEEP = 0.60
# CHANGE 2's bar, also written before any number was read: the run must stop
# projecting as a constant-width band. cv is its width's coefficient of
# variation along its own axis, bumps the count of local maxima in that
# profile - a bar has neither.
BAR_RUN_CV = 0.12
BAR_RUN_BUMPS = 4


def _mats(key):
    """minibossgen's own material block, called through its own function so the
    probe can never drift from what ships."""
    title, height, tint, aura, theme, idea, wear, line = M.CANON[key]
    body = tuple((c * 0.80) * 0.80 + a * 0.20 for c, a in zip(tint, aura))
    dull = 1.0 - 0.45 * wear
    body = tuple(c * dull + 0.010 * wear for c in body)
    rough = 0.34 + 0.40 * wear
    metal = 0.55 * (1.0 - wear) ** 1.4
    mats = {
        'body': L.mat_solid(key + "_body", body, rough, metal),
        'dark': L.mat_solid(key + "_dark", tuple(c * 0.16 + 0.012 for c in body), 0.74, 0.04),
        'bone': L.mat_solid(key + "_bone", tuple((0.30 + c * 0.55) * dull for c in tint),
                            rough * 0.9, 0.02),
        'glow': L.mat_glow(key + "_glow", tuple(min(1.0, c / max(aura)) for c in aura), 3.2),
    }
    return M.apply_overrides(key, mats), height, dict(
        title=title, height=height, tint=tint, aura=aura, theme=theme,
        idea=idea, wear=wear, line=line)


def build_split(key):
    """Same body minibossgen ships, merged into THREE groups instead of one so
    the chain can be hidden without touching anything else. The height
    normalisation is done over the UNION, exactly as build_miniboss does it, so
    every object stands where it stands in the shipped glb."""
    mats, height, info = _mats(key)
    P = M.BUILDERS[key]()
    heap = set(getattr(P, "heap_idx", []))
    run = set(getattr(P, "run_idx", []))
    if not heap or not run:
        raise RuntimeError("%s: builder marked no heap_idx/run_idx - "
                           "the instrument cannot see the chain" % key)
    groups = {"heap": [], "run": [], "rest": []}
    for i, it in enumerate(P.items):
        groups["heap" if i in heap else "run" if i in run else "rest"].append(it)
    run_path = list(getattr(P, "run_path", []))
    if len(run_path) < 3:
        raise RuntimeError("%s: builder recorded no run_path" % key)
    vc = getattr(P, "vcols", None)
    objs, by = [], {}
    for name, items in groups.items():
        if not items:
            raise RuntimeError("%s: group %s is empty" % (key, name))
        o = M.merge_objs(key, items, mats, suffix=name, vcols=vc)
        by[name] = o
        objs.extend(o)
    mn, mx, _ = G.world_bounds(objs)
    cur = mx.z - mn.z
    k = height / cur if cur > 1e-6 else 1.0
    for ob in objs:
        ob.scale = (k, k, k)
        ob.location = (ob.location.x * k, ob.location.y * k, ob.location.z * k)
    bpy.context.view_layer.update()
    mn, mx, _ = G.world_bounds(objs)
    for ob in objs:
        ob.location = (ob.location.x, ob.location.y, ob.location.z - mn.z)
    bpy.context.view_layer.update()
    return objs, by, info, [Vector((q.x * k, q.y * k, q.z * k - mn.z))
                            for q in run_path]


def rig(objs, info, resx, resy):
    """Camera + lights, built ONCE off the whole body. Returns a shooter that
    aims the one camera at a named view and writes a frame."""
    scene = bpy.context.scene
    eng = G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = resx, resy
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    if scene.world is None:
        scene.world = bpy.data.worlds.new("w")
    scene.world.use_nodes = True
    bg = next((n for n in scene.world.node_tree.nodes if n.type == 'BACKGROUND'), None)
    if bg:
        bg.inputs['Color'].default_value = (0.045, 0.05, 0.065, 1.0)
        bg.inputs['Strength'].default_value = 1.0
    mn, mx, pts = G.world_bounds(objs)
    center = (mn + mx) / 2.0
    radius = max(0.35, (mx - mn).length / 2.0)
    G.add_lights(center, radius, info['aura'])
    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = 'ORTHO'
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam

    def aim(vname):
        az, el = dict((v[0], (v[1], v[2])) for v in G.VIEWS)[vname]
        a, e = math.radians(az), math.radians(el)
        dirv = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e),
                       math.sin(e))).normalized()
        cam.location = center + dirv * (radius * 4.0 + 2.0)
        cam.rotation_euler = dirv.to_track_quat('Z', 'Y').to_euler()
        bpy.context.view_layer.update()
        mw = cam.matrix_world
        right = (mw.to_3x3() @ Vector((1, 0, 0))).normalized()
        up = (mw.to_3x3() @ Vector((0, 1, 0))).normalized()
        fwd = (mw.to_3x3() @ Vector((0, 0, -1))).normalized()
        wide = max(abs((p - center).dot(right)) for p in pts) * 2.0
        tall = max(abs((p - center).dot(up)) for p in pts) * 2.0
        depth = [(p - cam.location).dot(fwd) for p in pts]
        cam_d.ortho_scale = max(tall, wide * (resy / float(resx))) * 1.10
        cam_d.clip_start = max(0.01, min(depth) - radius * 0.5)
        cam_d.clip_end = max(depth) + radius * 2.0 + 5.0

    def shoot(path):
        scene.render.filepath = path
        bpy.ops.render.render(write_still=True)
        return G.read_png(path)
    return aim, shoot, eng


def _profile(mask, path_px, step=6.0, reach=48):
    """Does the run's outline MODULATE along its own length - bulge, pinch,
    bulge, the way chain does - or is it an even band like a bar?

    TWO EARLIER VERSIONS OF THIS FUNCTION WERE WRONG AND THEIR OWN NUMBERS SAID
    SO, which is the only reason they were caught. Both found a PCA axis in the
    pixels and binned along it, and both reported a coefficient of variation
    around 0.4-0.5 for a PLAIN TUBE - impossible for a constant-width band. The
    first was measuring the body OCCLUDING the middle of the run and the far
    end FORESHORTENING; the second still measured the run's own BENDS, because
    where a bent line leans away from a straight axis the bin under it collects
    more pixels. Three confounds, none of them links.

    So this one does not guess an axis. It is handed the run's OWN polyline,
    already projected to pixels through the same camera that shot the frame,
    walks it at a fixed step, and measures the mask's thickness PERPENDICULAR
    TO THE LOCAL TANGENT - which is the quantity the claim is actually about.
    Samples whose centre is not in the mask are dropped, so the stretch hidden
    behind the body is excluded rather than measured, and the surviving profile
    is linearly detrended so steady foreshortening contributes nothing.

    Returns None - and the caller reports RED and withholds every number - when
    fewer than 14 samples survive."""
    h, w = mask.shape
    if len(path_px) < 3:
        return None
    # resample the projected path at a fixed pixel step
    pts = [np.array(p, dtype=float) for p in path_px]
    dense = []
    for p0, p1 in zip(pts[:-1], pts[1:]):
        seg = p1 - p0
        ln = float(np.hypot(*seg))
        n = max(1, int(ln / step))
        for i in range(n):
            dense.append((p0 + seg * (i / float(n)), seg / max(1e-6, ln)))
    prof, caps = [], 0
    for c, d in dense:
        x, y = int(round(c[0])), int(round(c[1]))
        if not (0 <= x < w and 0 <= y < h) or not mask[y, x]:
            continue
        nx, ny = -d[1], d[0]
        t, capped = 1, False
        for sgn in (1, -1):
            for r in range(1, reach):
                xx = int(round(c[0] + nx * r * sgn))
                yy = int(round(c[1] + ny * r * sgn))
                if not (0 <= xx < w and 0 <= yy < h) or not mask[yy, xx]:
                    break
                t += 1
            else:
                # the mask runs on past `reach`: the line crosses itself or
                # another part of itself here and this sample is not a width.
                # It is COUNTED, not silently clipped - a capped sample that
                # went into the profile as `reach` would read as a giant bulge.
                capped = True
        if capped:
            caps += 1
            continue
        prof.append(t)
    # A profile measured mostly at crossings is not a profile of a line.
    if len(prof) < 14 or caps > 0.25 * (len(prof) + caps):
        return None
    a = np.array(prof, dtype=float)
    x = np.arange(len(a))
    k, c0 = np.polyfit(x, a, 1)
    res = a - (k * x + c0)
    base = float(a.mean())
    bumps = int(sum(1 for i in range(1, len(res) - 1)
                    if res[i] > res[i - 1] and res[i] >= res[i + 1] and res[i] > 0))
    return {"samples": len(a), "crossings_dropped": int(caps),
            "mean_width_px": round(base, 2),
            "trend_px_per_sample": round(float(k), 4),
            "cv": round(float(res.std() / max(1e-6, base)), 4), "bumps": bumps}


def _box(mask):
    ys, xs = np.nonzero(mask)
    if ys.size == 0:
        return None
    return int(xs.min()), int(xs.max()), int(ys.min()), int(ys.max())


def _moved(A, B):
    """A pixel moved if its colour OR its coverage changed. Alpha is in the
    test on purpose: the chain against the transparent background changes
    nothing but alpha, and a colour-only test would call that invisible."""
    return np.abs(A[..., 0:4] - B[..., 0:4]).max(axis=2) > SRC


def arm(name, key, tmp, resx, resy):
    G.purge()
    objs, by, info, run_world = build_split(key)
    # geometry eye, independent of any camera
    def ext(group):
        mn, mx, _ = G.world_bounds(by[group])
        return mn, mx
    hmn, hmx = ext("heap")
    bmn, bmx = G.world_bounds(objs)[0:2]
    body_h = bmx.z - bmn.z
    row = {"arm": name, "key": key,
           "heap_h_m": round(float(hmx.z - hmn.z), 3),
           "body_h_m": round(float(body_h), 3),
           "heap_h_frac": round(float((hmx.z - hmn.z) / max(1e-6, body_h)), 4),
           "body_span_m": round(float(max(bmx.x - bmn.x, bmx.y - bmn.y)), 3),
           "views": {}}
    aim, shoot, eng = rig(objs, info, resx, resy)
    row["engine"] = eng
    for vname in ("front", "three_quarter", "side"):
        aim(vname)
        A = shoot(os.path.join(tmp, "%s_%s_%s_all.png" % (key, name, vname))).copy()
        for ob in by["heap"]:
            ob.hide_render = True
        B = shoot(os.path.join(tmp, "%s_%s_%s_noheap.png" % (key, name, vname))).copy()
        for ob in by["heap"]:
            ob.hide_render = False
        for ob in by["run"]:
            ob.hide_render = True
        C = shoot(os.path.join(tmp, "%s_%s_%s_norun.png" % (key, name, vname))).copy()
        for ob in by["run"]:
            ob.hide_render = False
        heap_m, run_m = _moved(A, B), _moved(A, C)
        # the run's own polyline through THE SAME camera, in pixels
        path_px = []
        for q in run_world:
            co = world_to_camera_view(bpy.context.scene, bpy.context.scene.camera, q)
            path_px.append((co.x * resx, (1.0 - co.y) * resy))
        fig = A[..., 3] > 0.02
        fb = _box(fig)
        v = {"heap_px": int(heap_m.sum()), "run_px": int(run_m.sum()),
             "fig_px": int(fig.sum())}
        hb, rb = _box(heap_m), _box(run_m)
        if v["heap_px"] < 200 or hb is None or (hb[1] - hb[0]) < 2 or fb is None:
            v["verdict"] = "RED - the heap moved nothing measurable here; no numbers"
            row["views"][vname] = v
            continue
        hw, hh = hb[1] - hb[0] + 1, hb[3] - hb[2] + 1
        v.update({"heap_bbox_wh_px": [hw, hh],
                  "heap_aspect": round(hh / float(hw), 4),
                  "heap_fill": round(v["heap_px"] / float(hw * hh), 4),
                  "heap_h_over_fig_px": round(hh / float(fb[3] - fb[2] + 1), 4)})
        pr = (_profile(run_m, path_px)
              if (rb is not None and v["run_px"] >= 300) else None)
        if pr is not None:
            v["run_bbox_wh_px"] = [rb[1] - rb[0] + 1, rb[3] - rb[2] + 1]
            v["run_profile"] = pr
        else:
            v["run_note"] = ("RED - the run mask is too small or too short to "
                             "profile; its numbers are withheld")
        row["views"][vname] = v
    return row


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--res", default="700x980")
    args = ap.parse_args(argv)
    resx, resy = (int(x) for x in args.res.split("x"))
    tmp = os.path.join(args.repo, "renders", "art", "minibosses", "_gaoler_ab")
    os.makedirs(tmp, exist_ok=True)
    keep = dict(M.DRAG_HEAP)

    def shape(flat, links):
        M.DRAG_HEAP.clear()
        M.DRAG_HEAP.update(M.DRAG_HEAP_FLAT if flat else keep)
        M.RUN_LINKS["on"] = links

    rows = []
    for key in KEYS:
        # a -> b isolates CHANGE 1, the heap. b -> d isolates CHANGE 2, the
        # links on the run. Two changes in one render pass, measured apart.
        shape(True, False)
        rows.append(arm("a_flat_pass1", key, tmp, resx, resy))
        shape(False, False)
        rows.append(arm("b_heap", key, tmp, resx, resy))
        shape(False, True)
        rows.append(arm("d_heap_runlinks", key, tmp, resx, resy))
    shape(False, True)

    # THE VERDICT, against the bar written in this file's header before any
    # number was read. Measured on the 3/4 view, because that is the view the
    # fault was found in and the one the stream sees.
    verdict = {}
    for key in KEYS:
        A = [r for r in rows if r["key"] == key and r["arm"] == "a_flat_pass1"][0]
        B = [r for r in rows if r["key"] == key and r["arm"] == "b_heap"][0]
        va, vb = A["views"].get("three_quarter", {}), B["views"].get("three_quarter", {})
        if "heap_aspect" not in va or "heap_aspect" not in vb:
            verdict[key] = {"verdict": "RED - a 3/4 arm carried no numbers"}
            continue
        keepfrac = vb["heap_px"] / float(max(1, va["heap_px"]))
        verdict[key] = {
            "aspect_a": va["heap_aspect"], "aspect_b": vb["heap_aspect"],
            "h_frac_a": A["heap_h_frac"], "h_frac_b": B["heap_h_frac"],
            "px_kept": round(keepfrac, 4),
            "span_a_m": A["body_span_m"], "span_b_m": B["body_span_m"],
            "verdict": "PASS" if (vb["heap_aspect"] >= BAR_ASPECT
                                  and B["heap_h_frac"] >= BAR_HFRAC
                                  and keepfrac >= BAR_PXKEEP) else "FAIL"}
        # CHANGE 2, judged on its own numbers against its own bar.
        D = [r for r in rows if r["key"] == key and r["arm"] == "d_heap_runlinks"][0]
        vd = D["views"].get("three_quarter", {})
        pb, pd = vb.get("run_profile"), vd.get("run_profile")
        if not pb or not pd:
            verdict[key]["run"] = "RED - a run arm could not be profiled"
        else:
            verdict[key]["run"] = {
                "cv_plain": pb["cv"], "cv_links": pd["cv"],
                "bumps_plain": pb["bumps"], "bumps_links": pd["bumps"],
                "verdict": "PASS" if (pd["cv"] >= BAR_RUN_CV
                                      and pd["bumps"] >= BAR_RUN_BUMPS
                                      and pd["cv"] > pb["cv"] * 1.4) else "FAIL"}
    out = os.path.join(args.repo, "renders", "art", "minibosses",
                       "_gaoler_chain_ab.json")
    with open(out, "w") as f:
        json.dump({"src": SRC, "bar": {"heap_aspect": BAR_ASPECT,
                                       "heap_h_frac": BAR_HFRAC,
                                       "px_kept": BAR_PXKEEP,
                                       "run_cv": BAR_RUN_CV,
                                       "run_bumps": BAR_RUN_BUMPS},
                   "verdict": verdict, "rows": rows}, f, indent=1)
    print("GAOLER_CHAIN_AB " + json.dumps(verdict))


if __name__ == "__main__":
    main()
