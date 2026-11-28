
import bpy, numpy as np, os, math
rx = r"C:\hd adventure\bellmire-art\renders\art\gear_t5\_rx"
cells = os.path.join(rx,"cells"); sd = os.path.join(rx,"_sheets")
os.makedirs(sd, exist_ok=True)
for view in ("front","side","back"):
    ks = sorted(f[:-len("_%s.png"%view)] for f in os.listdir(cells) if f.endswith("_%s.png"%view))
    assert ks, "RED ON EMPTY - no cells for %s"%view
    arrs=[]
    for k in ks:
        im = bpy.data.images.load(os.path.join(cells,"%s_%s.png"%(k,view)), check_existing=False)
        w,h = im.size
        a = np.array(im.pixels[:], dtype=np.float32).reshape(h,w,4)[::-1]  # Blender is bottom-up
        arrs.append(a); bpy.data.images.remove(im)
    q=4; ch,cw = arrs[0].shape[0]//q, arrs[0].shape[1]//q
    cols=5; rows=int(math.ceil(len(ks)/float(cols)))
    sh=np.zeros((rows*ch, cols*cw,4),dtype=np.float32)
    for i,a in enumerate(arrs):
        s=a[::q,::q,:][:ch,:cw,:]; r,c=divmod(i,cols)
        sh[r*ch:r*ch+s.shape[0], c*cw:c*cw+s.shape[1],:]=s
    assert float(sh[:,:,3].max())>0.02, "RED - blank sheet %s"%view
    p=os.path.join(sd,"rx_%s.png"%view)
    o=bpy.data.images.new("s_"+view, sh.shape[1], sh.shape[0], alpha=True)
    o.pixels = sh[::-1].reshape(-1)   # write back bottom-up
    o.filepath_raw=p; o.file_format='PNG'; o.save()
    print("SHEET",view,p,",".join(ks))
print("SHEETS_DONE")
