"""Problem-first Spanish promo, using three real form submissions and their ledger.

Input: source/frames captured by tool/render_three_expenses_promo_test.dart.
Output: 18-second music and silent MP4s, cover, and storyboard proof frames.
"""
from pathlib import Path
from functools import lru_cache
import argparse
import json
import math
import subprocess
import wave

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
W,H,FPS,DURATION=1080,1920,30,18
PAPER='#faf4e7'
INK='#263a38'
TEAL='#176c62'
WHITE='#fffdf7'
ACCENTS=['#f3d9c5','#d6e7e5','#f0e5b9']
NAMES=['Café','Taxi','Antojo']
AMOUNTS=[45,80,35]
FONTS=Path('/System/Library/Fonts/Supplemental')


@lru_cache(maxsize=80)
def font(size,style='bold'):
    if style=='pixel':path=ROOT/'assets/fonts/PixelifySans.ttf'
    else:path=FONTS/{'bold':'Arial Rounded Bold.ttf','sans':'Arial.ttf','mono':'Courier New Bold.ttf'}[style]
    return ImageFont.truetype(str(path),size)


def text(im,label,x,y,size=50,color=INK,style='bold',center=False,spacing=1.08,maxw=885):
    d=ImageDraw.Draw(im);f=font(size,style)
    for j,line in enumerate(label.split('\n')):
        width=d.textlength(line,font=f)
        if width>maxw:raise ValueError(f'Overwide text ({width:.0f}): {line}')
        left=x-width/2 if center else x
        if left<0 or left+width>W:raise ValueError(f'Outside frame: {line}')
        d.text((round(left),round(y+j*size*spacing)),line,font=f,fill=color,anchor='lt')


def ease(t):
    t=min(1,max(0,t));return t*t*(3-2*t)


def pill(im,label,x,y,w,h=82,bg=TEAL,fg=WHITE,size=36):
    ImageDraw.Draw(im).rounded_rectangle((x,y,x+w,y+h),radius=h/2,fill=bg)
    text(im,label,x+w/2,y+(h-size)/2-2,size,fg,center=True,maxw=w-38)


def base(t,bg=PAPER):
    im=Image.new('RGB',(W,H),bg);d=ImageDraw.Draw(im)
    for x in range(56,W,48):
        for y in range(75,H,48):
            d.ellipse((x,y,x+2,y+2),fill='#e0d8c5' if bg==PAPER else '#3b7e72')
    text(im,'Sobrita',81,158,49,INK if bg==PAPER else PAPER,'pixel')
    text(im,'REGISTRA TUS GASTOS',84,223,28,TEAL if bg==PAPER else PAPER,'sans')
    return im


@lru_cache(maxsize=18)
def raw(index):
    return Image.open(HERE/'source/frames'/f'{index:05}.png').convert('RGB')


def panel(im,index,crop,target,zoom=1):
    x,y,w,h=target;sx,sy,ex,ey=crop
    sw,sh=ex-sx,ey-sy;aspect=w/h
    if sw/sh>aspect:sx+=(sw-sh*aspect)/2;sw=sh*aspect
    else:sy+=(sh-sw/aspect)/2;sh=sw/aspect
    if zoom!=1:
        sx+=sw*(1-1/zoom)/2;sy+=sh*(1-1/zoom)/2;sw/=zoom;sh/=zoom
    art=raw(index).crop((round(sx),round(sy),round(sx+sw),round(sy+sh))).resize((w,h),Image.Resampling.LANCZOS)
    mask=Image.new('L',(w,h),0)
    ImageDraw.Draw(mask).rounded_rectangle((0,0,w-1,h-1),radius=28,fill=255)
    im.paste(art,(x,y),mask)


def check(im,x,y,color=TEAL,r=22):
    d=ImageDraw.Draw(im)
    d.ellipse((x-r,y-r,x+r,y+r),fill=color)
    d.line((x-r*.45,y,x-r*.1,y+r*.3,x+r*.48,y-r*.34),fill=WHITE,width=5)


@lru_cache(maxsize=8)
def michi(index):
    sheet=Image.open(ROOT/'assets/characters/michi/idle-8.png').convert('RGBA')
    return sheet.crop((320*index,0,320*(index+1),360)).resize((249,280),Image.Resampling.NEAREST)


def render(n):
    t=n/FPS
    if t<2.4:
        im=base(t)
        text(im,'¿Cuánto gastaste\nhoy?',79,336,93,spacing=1.03)
        for i,(name,amount) in enumerate(zip(NAMES,AMOUNTS)):
            u=ease((t-i*.35)/.3)
            y=661+i*219+round((1-u)*25)
            d=ImageDraw.Draw(im)
            d.rounded_rectangle((82,y,916,y+178),radius=28,fill=ACCENTS[i])
            text(im,f'0{i+1}',112,y+64,43,TEAL,'mono')
            text(im,name,237,y+54,62)
            text(im,f'${amount}',774,y+53,66,center=True)
        text(im,'Café, taxi y un antojo…',83,1365,52)
        pill(im,'Vamos a anotarlos.',82,1481,835,106,size=54)
        text(im,'Ejemplo en pesos mexicanos',85,1630,31,TEAL,'sans')
    elif t<10.8:
        i=min(2,int((t-2.4)/2.8));u=t-(2.4+i*2.8);start=i*104
        im=base(t)
        text(im,f'{NAMES[i]}: ${AMOUNTS[i]}',80,327,96)
        text(im,f'{i+1} de 3 · MXN',84,462,41,TEAL,'sans')
        # Match cuts between actual amount, note/save, and saved-dialog footage.
        if u<1.0:
            ix=start+6+min(23,round(u*23))
            crop=(44,195,1036,1455)
        elif u<2.1:
            ix=start+30+min(23,round((u-1)/1.1*23))
            crop=(44,770,1036,2030)
        else:
            ix=start+60+min(21,round((u-2.1)/.7*21))
            crop=(44,606,1036,1866)
        d=ImageDraw.Draw(im)
        d.rounded_rectangle((72,550,932,1637),radius=42,fill=ACCENTS[i])
        panel(im,ix,crop,(86,564,832,1059))
        # These are editorial steps, outside the authentic app panel.
        for j in range(3):
            x=112+j*275
            if j<i or (j==i and u>=2.1):check(im,x,1691)
            else:d.ellipse((x-20,1671,x+20,1711),outline=TEAL,width=3)
            text(im,NAMES[j],x+35,1669,35,TEAL)
        text(im,'Pantallas reales · Datos de ejemplo',84,1771,28,TEAL,'sans')
    elif t<15:
        u=t-10.8;im=base(t)
        text(im,'Hoy gastaste',80,323,72)
        text(im,'$160',74,426,160,TEAL,'mono')
        text(im,'MXN',602,514,52,TEAL,'sans')
        d=ImageDraw.Draw(im)
        ix=312+min(59,round(u/4.2*59))
        if u<1.6:
            d.rounded_rectangle((72,649,932,1792),radius=40,fill='#d6e7e5')
            # Native $160 cycle total AND the three rows under Hoy.
            # All transactions in this isolated demo are from the same day.
            panel(im,ix,(42,380,1038,1710),(87,665,830,1108))
        else:
            text(im,'Los tres, en un solo lugar.',82,680,49)
            d.rounded_rectangle((72,798,932,1502),radius=40,fill='#d6e7e5')
            # A tighter uniform crop makes each real transaction readable.
            panel(im,ix,(42,980,1038,1782),(87,814,830,668))
            pill(im,'45 + 80 + 35 = 160',82,1555,835,111,bg=TEAL,size=47)
            text(im,'Pantalla real · Datos de ejemplo',85,1713,30,TEAL,'sans')
    else:
        u=t-15;im=base(t,TEAL);d=ImageDraw.Draw(im)
        text(im,'Ahora sabes\nen qué se fue.',80,329,97,PAPER,spacing=1.04)
        d.rounded_rectangle((80,655,922,1189),radius=42,fill=PAPER)
        text(im,'3 gastos registrados',126,714,48,INK)
        text(im,'$160',119,821,146,TEAL,'mono')
        text(im,'MXN',132,1010,45,TEAL,'sans')
        art=michi(int((u%2.8)/2.8*8))
        im.paste(art,(625,853),art)
        text(im,'Un registro a la vez.',82,1271,59,PAPER)
        pill(im,'Síguenos para el lanzamiento',80,1415,842,113,bg=PAPER,fg=TEAL,size=46)
        text(im,'Android · En pruebas',84,1572,35,PAPER,'sans')
        text(im,'Demostración con datos de ejemplo.',84,1633,28,PAPER,'sans')
    return im


def previews():
    out=HERE/'proofs';out.mkdir(exist_ok=True)
    times=[0,1.5,2.6,3.7,4.8,5.4,6.5,7.6,8.4,9.4,10.2,11.3,13.8,15.5,17.5]
    sheet=Image.new('RGB',(5*216,3*410),PAPER)
    for i,t in enumerate(times):
        im=render(round(t*FPS));im.save(out/f'{t:04.1f}s.jpg',quality=94)
        sheet.paste(im.resize((216,384)),((i%5)*216,(i//5)*410))
        ImageDraw.Draw(sheet).text(((i%5)*216+8,(i//5)*410+390),f'{t:.1f}s',fill=INK)
    sheet.save(HERE/'review-contact-sheet.jpg',quality=94)
    render(45).save(HERE/'sobrita-three-expenses-cover.jpg',quality=96)
    print('Proof frames ready.',flush=True)


def audio():
    rate=48000;buf=np.zeros((rate*DURATION,2));rng=np.random.default_rng(160)
    def add(a,start,pan=0):
        at=round(start*rate)
        if at>=len(buf):return
        end=min(len(buf),at+len(a));a=a[:end-at]
        buf[at:end,0]+=a*np.sqrt((1-pan)/2);buf[at:end,1]+=a*np.sqrt((1+pan)/2)
    def note(midi,start,vol=.07,dur=.7,bass=False,pan=0):
        tt=np.arange(round(dur*rate))/rate;f=440*2**((midi-69)/12)
        a=(np.sin(2*np.pi*f*tt)+.12*np.sin(2*np.pi*2*f*tt))*np.exp(-tt*(3 if bass else 8))
        a*=np.minimum(tt/.007,1)*np.minimum((dur-tt)/.04,1)*vol
        add(a,start,pan)
    def tap(start,vol=.024):
        tt=np.arange(round(rate*.085))/rate
        add(rng.normal(0,1,len(tt))*np.exp(-tt*80)*vol,start)
    # An understated original beat; save chimes mark each completed entry.
    melody=[74,78,81,78,76,74,69,71]
    for beat in range(36):
        at=beat*.5;root=[50,47,55,57][(beat//4)%4]
        if beat%2==0:
            note(root,at,.068,1.1,True)
            note(melody[beat%8]+12,at,.05,.72,pan=.2)
        else:tap(at,.027)
        note(melody[(beat+3)%8],at+.25,.034,.55,pan=-.2)
    for at in [2.4,5.2,8,10.8,15]:
        note(86,at,.085,.32);note(93,at+.08,.038,.24)
    for at in [4.5,7.3,10.1]:
        note(81,at,.075,.25);note(86,at+.065,.065,.3)
    dry=buf.copy();delay=round(rate*.13);buf[delay:]+=dry[:-delay,::-1]*.085
    buf*=np.minimum(np.arange(len(buf))/(rate*.03),1)[:,None]
    buf*=np.minimum(np.arange(len(buf))[::-1]/(rate*.45),1)[:,None]
    buf*=.56/max(.01,np.max(np.abs(buf)))
    path=HERE/'original-expenses-theme.wav'
    with wave.open(str(path),'wb') as f:
        f.setnchannels(2);f.setsampwidth(2);f.setframerate(rate)
        f.writeframes((buf*32767).astype('<i2').tobytes())
    return path


def encode():
    path=HERE/'sobrita-three-expenses-es-18s.mp4';sound=audio()
    p=subprocess.Popen(['ffmpeg','-y','-hide_banner','-loglevel','warning','-f','rawvideo',
        '-pixel_format','rgb24','-video_size',f'{W}x{H}','-framerate',str(FPS),'-i','pipe:0',
        '-i',str(sound),'-map','0:v:0','-map','1:a:0','-c:v','libx264','-threads','4',
        '-preset','medium','-crf','18','-pix_fmt','yuv420p','-af','loudnorm=I=-18:TP=-2:LRA=7',
        '-c:a','aac','-ar','48000','-b:a','192k','-t',str(DURATION),'-movflags','+faststart',
        '-metadata','title=Sobrita — ¿Cuánto gastaste hoy?',str(path)],stdin=subprocess.PIPE)
    try:
        for n in range(FPS*DURATION):
            p.stdin.write(render(n).tobytes())
            if n%120==0:print(f'Rendered {n}/{FPS*DURATION}',flush=True)
    finally:p.stdin.close()
    if p.wait():raise RuntimeError('FFmpeg failed')
    subprocess.run(['ffmpeg','-y','-v','error','-i',str(path),'-map','0:v:0','-c:v','copy','-an',
        '-movflags','+faststart',str(HERE/'sobrita-three-expenses-es-18s-silent.mp4')],check=True)
    print('Both videos complete.',flush=True)


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--preview',action='store_true');args=p.parse_args()
    manifest=json.loads((HERE/'source/manifest.json').read_text())
    assert manifest['today_spent_centavos']==16000
    assert sorted(e['amountCentavos'] for e in manifest['transactions'])==[3500,4500,8000]
    assert len(list((HERE/'source/frames').glob('*.png')))==372
    previews()
    if not args.preview:encode()
