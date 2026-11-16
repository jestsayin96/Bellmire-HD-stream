
import os,sys,glob
import numpy as np
sys.path.append(os.path.join(r"C:\hd adventure\bellmire-art","tools","art"))
import lordgen as G
out=os.path.join(r"C:\hd adventure\bellmire-art","renders","art","_look")
os.makedirs(out,exist_ok=True)
res={}
src=sorted(glob.glob(os.path.join(r"C:\hd adventure\bellmire-art","renders","art","d94","_row_*.png")))+[os.path.join(r"C:\hd adventure\bellmire-art","renders","art","d94","_overview.png")]
for p in src:
    a=G.read_png(p)
    h,w=a.shape[0],a.shape[1]
    k=max(1,int(round(w/1700.0)))
    hh,ww=h//k,w//k
    b=a[:hh*k,:ww*k].reshape(hh,k,ww,k,a.shape[2]).mean(axis=(1,3))
    q=os.path.join(out,os.path.basename(p))
    G.write_png(q,b)
    res[os.path.basename(p)]=[w,h,ww,hh]
print("LOOKSCALE",res)
