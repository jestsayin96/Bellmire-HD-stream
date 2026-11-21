"""Instalment 5 adoption sheet: the AFTER state over white, one row per body,
front | side | back. No before column - the before for 26 of these is in git
and for the other 18 is the old light, and what this sheet has to answer is
simpler: does every cell now show a body standing on a floor, and did anything
break. Over white, because that is where the fault was named."""
import os, sys, json
import numpy as np, bpy
W5 = r"C:\hd adventure\bellmire-art"
MB = os.path.join(W5, "renders", "art", "minibosses")
KEYS = sys.argv[sys.argv.index("--") + 1].split(",")
OUT = sys.argv[sys.argv.index("--") + 2]
def load(p):
    im = bpy.data.images.load(p, check_existing=False)
    im.colorspace_settings.name = 'Non-Color'
    w,h = im.size; px = np.empty(w*h*4, dtype=np.float32); im.pixels.foreach_get(px)
    bpy.data.images.remove(im); return px.reshape(h,w,4)[::-1]
def ow(a):
    al=a[:,:,3:4]; return ((a[:,:,:3]*al+(1-al))*255).round().clip(0,255).astype(np.uint8)
rows=[]; stat={}
for k in KEYS:
    cells=[]
    for v in ("front","side","back"):
        p=os.path.join(MB,k,"hero_%s.png"%v)
        if not os.path.isfile(p): cells=None; break
        a=load(p); w=ow(a)
        # darkness of the floor pixels (alpha>0 where it is thin) over white
        thin=(a[:,:,3]>0.02)&(a[:,:,3]<0.60)
        stat.setdefault(k,{})[v]={"thin_px":int(thin.sum()),
            "thin_mean_dark":round(float((255-w.min(axis=2))[thin].mean()),1) if thin.any() else 0.0}
        cells.append(w[::3,::3])
    if cells: rows.append(np.hstack(cells))
th,tw = rows[0].shape[:2]
sheet=np.full((th*len(rows), tw, 4), 255, dtype=np.uint8)
for i,r in enumerate(rows):
    sheet[i*th:i*th+r.shape[0], :r.shape[1], :3]=r
    sheet[i*th,:,:3]=40
o=bpy.data.images.new("i5",width=sheet.shape[1],height=sheet.shape[0],alpha=True)
o.colorspace_settings.name='Non-Color'
o.pixels.foreach_set((sheet[::-1].astype(np.float32)/255.0).ravel())
p=os.path.join(MB,OUT); o.filepath_raw=p; o.file_format='PNG'; o.save()
print("I5LOOK|", json.dumps({"sheet":p,"size":list(sheet.shape[:2]),"stat":stat}))
