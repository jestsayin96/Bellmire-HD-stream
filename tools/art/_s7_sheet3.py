# Contact sheet: five shells x four states, so the trade is visible in one picture.
import bpy, sys, os, numpy as np
A=sys.argv[sys.argv.index("--")+1:]
OUT=A[0]; R=600
W5=r"C:\hd adventure\bellmire-art"
B=os.path.join(W5,"renders","art","s7_armour")
COLS=[("fit6","A_%s_front.png","as shipped"),
      ("fit8","J_%s_front.png","ray conform"),
      ("fit10","L118_%s_front.png","scale 1.18"),
      ("fit8","J_%s_back.png","ray conform, back")]
NAMES=["Armor_Black","Armor_Golden","Armor_Leather","Armor_Metal","Armor_Metal2"]
def load(p):
    im=bpy.data.images.load(p); im.colorspace_settings.name='Non-Color'
    a=np.array(im.pixels[:],dtype=np.float32).reshape(R,R,4)
    bpy.data.images.remove(im); return a
H=len(NAMES)*R; W=len(COLS)*R
sheet=np.zeros((H,W,4),dtype=np.float32)
miss=[]
for r,n in enumerate(NAMES):
    for c,(d,pat,_) in enumerate(COLS):
        p=os.path.join(B,d,pat%n)
        if not os.path.exists(p): miss.append(p); continue
        sheet[(len(NAMES)-1-r)*R:(len(NAMES)-r)*R, c*R:(c+1)*R]=load(p)
out=bpy.data.images.new("sheet",W,H,alpha=True)
out.pixels=sheet.reshape(-1).tolist()
out.filepath_raw=OUT; out.file_format='PNG'; out.save()
opaque=int((sheet[:,:,3]>0.02).sum())
print("SHEET opaque=%d missing=%d"%(opaque,len(miss)))
if opaque==0: print("RED blank sheet")
for m in miss: print("MISSING",m)
print("DONE")
