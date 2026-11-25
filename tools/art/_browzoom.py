import os, sys
import numpy as np
from PIL import Image, ImageDraw

W5 = os.path.expanduser("~/mnt/bellmire-art")
ROOT = os.path.join(W5, "renders", "art", "minibosses", "_brow")
PANE = (0.045, 0.05, 0.065)
RUNG = 160
ARMS = sys.argv[1].split(",")
LAB = {"_bs00":"skin 0.00","_bs20":"skin 0.20","_bs40":"skin 0.40",
       "_bs60":"skin 0.60 SHIPPED","_bs80":"skin 0.80",
       "_bsoot100":"soot 1.00 pass-16 head / skin 0.60"}
# the head window, in full-res pixels (brow measured at x308-373 y129-142)
X0,X1,Y0,Y1 = 282, 402, 96, 192
TW = 728

def load(p):
    return np.asarray(Image.open(p).convert("RGBA"), np.float32)/255.0
def over(a):
    al=a[:,:,3:4]; return a[:,:,:3]*al + np.array(PANE,np.float32)*(1.0-al)
def rung(a):
    W=RUNG; H=int(round(a.shape[0]*W/float(a.shape[1])))
    im=Image.fromarray((np.clip(a,0,1)*255).astype(np.uint8),"RGBA")
    return np.asarray(im.resize((W,H),Image.BOX),np.float32)/255.0
def img(a3,w):
    im=Image.fromarray((np.clip(a3,0,1)*255).astype(np.uint8))
    s=max(1,int(round(w/float(im.width))))
    return im.resize((im.width*s, im.height*s), Image.NEAREST)

rows=[]
for arm in ARMS:
    d=os.path.join(ROOT,"collier"+arm)
    B=load(os.path.join(d,"B_front.png"))
    sc=RUNG/float(B.shape[1])
    Br=rung(B)
    full=over(B[Y0:Y1,X0:X1])
    rx0,ry0=int(X0*sc),int(Y0*sc)
    rx1,ry1=int(np.ceil(X1*sc)),int(np.ceil(Y1*sc))
    rg=over(Br[ry0:ry1,rx0:rx1])
    rows.append((arm,[img(full,TW),img(rg,TW)]))

gap=14; lab=22
wc=max(p.width for _,ps in rows for p in ps)
hc=max(p.height for _,ps in rows for p in ps)
W=2*wc+3*gap; H=len(rows)*(hc+gap+lab)+gap
sheet=Image.new("RGB",(W,H),(16,17,21)); dr=ImageDraw.Draw(sheet)
for i,(arm,ps) in enumerate(rows):
    y=gap+i*(hc+gap+lab)
    dr.text((gap,y),"%s   LEFT full 760px render  |  RIGHT the same head at the 360p rung"
            %LAB.get(arm,arm),fill=(235,235,235))
    for j,p in enumerate(ps):
        sheet.paste(p,(gap+j*(wc+gap), y+lab))
out=os.path.join(ROOT,"_browzoom_%s.png"%("-".join(a.strip("_") for a in ARMS)))
sheet.save(out); print("wrote",out,sheet.size)
