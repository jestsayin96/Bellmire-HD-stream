import os, sys
import numpy as np
from PIL import Image, ImageDraw
W5=os.path.expanduser("~/mnt/bellmire-art")
ROOT=os.path.join(W5,"renders","art","minibosses","_brow")
PANE=(0.045,0.05,0.065); RUNG=160
ARMS=sys.argv[1].split(","); VIEW=sys.argv[2] if len(sys.argv)>2 else "front"
LAB={"_bh055":"head soot 0.55 = PASS 17 SHIPPED","_bh075":"head soot 0.75",
     "_bh085":"head soot 0.85","_bh100":"head CLEAN of soot (trunk still 0.55)"}
def load(p): return np.asarray(Image.open(p).convert("RGBA"),np.float32)/255.0
def over(a):
    al=a[:,:,3:4]; return a[:,:,:3]*al+np.array(PANE,np.float32)*(1.0-al)
def rung(a):
    W=RUNG;H=int(round(a.shape[0]*W/float(a.shape[1])))
    im=Image.fromarray((np.clip(a,0,1)*255).astype(np.uint8),"RGBA")
    return np.asarray(im.resize((W,H),Image.BOX),np.float32)/255.0
cols=[]
for arm in ARMS:
    B=load(os.path.join(ROOT,"collier"+arm,"B_%s.png"%VIEW))
    # trim to the body's own bbox so the man fills the panel
    ys,xs=np.where(B[:,:,3]>2/255.)
    y0,y1,x0,x1=ys.min(),ys.max()+1,xs.min(),xs.max()+1
    full=Image.fromarray((np.clip(over(B[y0:y1,x0:x1]),0,1)*255).astype(np.uint8))
    full=full.resize((int(full.width*1.1),int(full.height*1.1)),Image.LANCZOS)
    Br=rung(B); sc=RUNG/float(B.shape[1])
    rg=over(Br[int(y0*sc):int(np.ceil(y1*sc)),int(x0*sc):int(np.ceil(x1*sc))])
    rgi=Image.fromarray((np.clip(rg,0,1)*255).astype(np.uint8))
    s=max(1,int(round(full.height/float(rgi.height))))
    rgi=rgi.resize((rgi.width*s,rgi.height*s),Image.NEAREST)
    cols.append((arm,full,rgi))
gap=16;lab=22
H=max(max(f.height,r.height) for _,f,r in cols)+lab+2*gap
W=sum(f.width+r.width+gap for _,f,r in cols)+gap*(len(cols)+1)
sheet=Image.new("RGB",(W,H),(16,17,21));dr=ImageDraw.Draw(sheet)
x=gap
for arm,f,r in cols:
    dr.text((x,gap-4),"%s  (%s: full | 360p rung)"%(LAB.get(arm,arm),VIEW),fill=(235,235,235))
    sheet.paste(f,(x,gap+lab)); x+=f.width+6
    sheet.paste(r,(x,gap+lab)); x+=r.width+gap
out=os.path.join(ROOT,"_bodyzoom_%s_%s.png"%(VIEW,"-".join(a.strip("_") for a in ARMS)))
sheet.save(out);print("wrote",out,sheet.size)
