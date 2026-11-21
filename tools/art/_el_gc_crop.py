"""Full-resolution crop at the ground line, before|after, over white - because
a 2x thumbnail cannot show the 1-px unshadowed rim this method was predicted
to leave, and a prediction nobody checks is not a caveat, it is an excuse."""
import os, sys, json
import numpy as np, bpy
W5 = r"C:\hd adventure\bellmire-art"
MB = os.path.join(W5, "renders", "art", "minibosses")
key, view = sys.argv[sys.argv.index("--")+1], sys.argv[sys.argv.index("--")+2]
def load(p):
    im = bpy.data.images.load(p, check_existing=False)
    im.colorspace_settings.name = 'Non-Color'
    w,h = im.size; px = np.empty(w*h*4, dtype=np.float32); im.pixels.foreach_get(px)
    bpy.data.images.remove(im); return px.reshape(h,w,4)[::-1]
def ow(a):
    al=a[:,:,3:4]; return ((a[:,:,:3]*al+(1-al))*255).round().clip(0,255).astype(np.uint8)
A=load(os.path.join(MB,key,"hero_%s.png"%view)); B=load(os.path.join(MB,key+"_gc","hero_%s.png"%view))
h,w = A.shape[:2]
# find the subject's lowest row in the control, crop a band around it
m = A[:,:,3] > 0.02
rows = np.where(m.any(axis=1))[0]; cols = np.where(m.any(axis=0))[0]
r1 = min(h, int(rows.max())+30); r0 = max(0, r1-190)
c0 = max(0, int(cols.min())-20); c1 = min(w, c0+340)
a, b = ow(A)[r0:r1, c0:c1], ow(B)[r0:r1, c0:c1]
sh = np.full((a.shape[0], a.shape[1]*2+6, 4), 255, dtype=np.uint8)
sh[:, :a.shape[1], :3] = a; sh[:, a.shape[1]+6:, :3] = b
out = bpy.data.images.new("crop", width=sh.shape[1], height=sh.shape[0], alpha=True)
out.colorspace_settings.name='Non-Color'
out.pixels.foreach_set((sh[::-1].astype(np.float32)/255.0).ravel())
p = os.path.join(MB, "_el_gc_crop.png"); out.filepath_raw=p; out.file_format='PNG'; out.save()
print("CROP|", json.dumps({"path":p,"box":[r0,r1,c0,c1],"size":list(sh.shape[:2])}))
