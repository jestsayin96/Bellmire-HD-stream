// web/tools/sheet_overlap.js - hero-sheet overlap/clip sweep (hub row, 18 Nov 2026).
// Usage (from web/): node tools/sheet_overlap.js <sheets|crowd> ; WEB=file:///abs/path to test a copy.
// Needs playwright. Stubs the snapshot with [] so ?mock= renders over an empty town, opens every sheet
// (?open=all) and compares the LINE BOXES (getClientRects) of every leaf pair inside each .charsheet at
// 320/360/390/600/768/900 px. getBoundingClientRect on a wrapped inline gives a false overlap - do not use it.
// Red-prove it by appending a rule such as `.sid .sname{margin-left:-40px;position:relative}` to a copy of style.css.
const { chromium } = require('playwright');
const url = (process.env.WEB||'file://'+require('path').resolve(__dirname,'..'))+'/index.html'; const MK=process.argv[2]||'sheets';
(async()=>{
const b = await chromium.launch(); const out={};
for (const w of [320,360,390,600,768,900]) {
  const ctx = await b.newContext({viewport:{width:w,height:900},deviceScaleFactor:1});
  const p = await ctx.newPage();
  await p.route(/supabase/, r=>r.fulfill({status:200,contentType:'application/json',body:'[]'})); await p.route(/irc|twitch/, r=>r.abort());
  await p.goto(url+'?mock='+MK+'&open=all&welcome=0');
  await p.waitForTimeout(1200); if(process.argv[3]==='fallen'){const t=await p.$('[role=tab]:text-matches("fallen|memorial|hall","i")'); if(t){await t.click();await p.waitForTimeout(500);}} if(false){await p.addStyleTag({content:'.sname{margin-left:-30px!important;position:relative}.sid{position:relative}.sid>*{margin-right:-20px!important}'});await p.waitForTimeout(200);}
  const r = await p.evaluate(()=>{
    const res={sheets:0,overlaps:[],clips:[],hscroll:document.documentElement.scrollWidth>innerWidth};
    const sheets=[...document.querySelectorAll('.charsheet')]; res.sheets=sheets.length;
    sheets.forEach((s,si)=>{
      const leaves=[...s.querySelectorAll('*')].filter(e=>{
        const cs=getComputedStyle(e); if(cs.display==='none'||cs.visibility==='hidden')return false;
        const rc=e.getBoundingClientRect(); if(rc.width<1||rc.height<1)return false;
        if(e.closest('details:not([open]) > :not(summary)'))return false;
        const own=[...e.childNodes].some(n=>n.nodeType===3&&n.textContent.trim());
        return own||e.tagName==='svg'||e.tagName==='IMG'||(!e.children.length&&e.tagName!=='path'&&e.tagName!=='use');
      }).filter(e=>!e.closest('svg')||e.tagName==='svg');
      const nm=e=>e.tagName.toLowerCase()+'.'+[...e.classList].join('.')+'['+(e.textContent||'').trim().slice(0,14)+']';
      for(let i=0;i<leaves.length;i++)for(let j=i+1;j<leaves.length;j++){
        const a=leaves[i],c=leaves[j]; if(a.contains(c)||c.contains(a))continue;
        let best=0;for(const A of a.getClientRects())for(const B of c.getClientRects()){const ox=Math.min(A.right,B.right)-Math.max(A.left,B.left), oy=Math.min(A.bottom,B.bottom)-Math.max(A.top,B.top);if(ox>0.5&&oy>0.5)best=Math.max(best,ox*oy);}
        if(best>=4) res.overlaps.push({sheet:si,a:nm(a),b:nm(c),px2:Math.round(best)});
      }
      leaves.forEach(e=>{const R=e.getBoundingClientRect();
        if(R.right>innerWidth+0.5||R.left<-0.5)res.clips.push({sheet:si,k:'offscreen',e:nm(e),right:Math.round(R.right)});
        if(e.scrollWidth>e.clientWidth+1&&getComputedStyle(e).overflowX!=='visible'&&e.clientWidth>0)res.clips.push({sheet:si,k:'text-clipped',e:nm(e),sw:e.scrollWidth,cw:e.clientWidth});
        let q=e.parentElement; while(q&&q!==s){const cs=getComputedStyle(q); if(cs.overflowX!=='visible'){const Q=q.getBoundingClientRect(); if(R.right>Q.right+1||R.left<Q.left-1){res.clips.push({sheet:si,k:'cut-by-ancestor',e:nm(e),anc:nm(q),by:Math.round(Math.max(R.right-Q.right,Q.left-R.left))});break;}} q=q.parentElement;}
      });
    });
    return res;});
  out[w]=r;
  if(w===360||w===320) await p.screenshot({path:require('os').tmpdir()+`/${MK}_w${w}.png`,fullPage:false});
  await ctx.close();
}
console.log(JSON.stringify(out,null,1)); await b.close();})();
