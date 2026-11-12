import sys
from PIL import Image
src, outdir = sys.argv[1], sys.argv[2]
im = Image.open(src).convert('RGBA'); W,H = im.size; px = im.load()
def coinish(c):
    r,g,b,a=c; return a>200 and r>90 and r-b>40
def glass(c):
    r,g,b,a=c; return a>200 and b>r+20 and b>140
def white(c):
    r,g,b,a=c; return a>200 and r>232 and g>232 and b>232
Y0,Y1,X0,X1=560,1000,372,850
inside=set()
for y in range(Y0,Y1):
    row=[x for x in range(X0,X1) if glass(px[x,y]) or coinish(px[x,y]) or white(px[x,y])]
    for x in row: inside.add((x,y))
# empty jar: coin pixels become the jar's own interior glass, with the
# bottom band copied from the edge of the same row
empty=im.copy(); ep=empty.load()
body=px[700,640]
print('body glass', body)
for y in range(660,1000):
    edge=None
    for x in range(X0,424):
        if glass(px[x,y]): edge=px[x+20,y] if glass(px[x+20,y]) else px[x,y]
    for x in range(X0,X1):
        if coinish(px[x,y]):
            ep[x,y]= edge if (y>985 and edge) else body
# a pixel-art coin on a 13px grid, coloured from the original coins
pat=["..OOOOO..",
     ".OYYYYYO.",
     "OYHHYYYDO",
     "OYHYYYYDO",
     "OYYYYYYDO",
     "OYYYYYDDO",
     ".ODYYDDO.",
     "..OOOOO.."]
col={'O':(122,62,14,255),'Y':(246,182,38,255),'H':(255,232,128,255),'D':(214,128,24,255)}
C=13
cw,ch=len(pat[0])*C,len(pat)*C
def draw(out,ox,oy):
    op=out.load()
    for j,line in enumerate(pat):
        for i,k in enumerate(line):
            if k=='.': continue
            for yy in range(C):
                for xx in range(C):
                    X,Y=ox+i*C+xx,oy+j*C+yy
                    if (X,Y) in inside and not white(ep[X,Y]):
                        op[X,Y]=col[k]
rows=[]  # bottom-up rows of coin positions
bottom=992
for r in range(7):
    y=bottom-ch-r*(ch-3*C)
    off=0 if r%2==0 else cw//2
    xs=list(range(X0+8-off, X1, cw-C))
    rows.append([(x,y) for x in xs])
def stage(n):
    out=empty.copy()
    for r in rows[:n]:
        for (x,y) in r: draw(out,x,y)
    return out
for pct,n in {0:0,25:2,50:3,75:5,100:7}.items():
    stage(n).save(f'{outdir}/jar-{pct}.png')
