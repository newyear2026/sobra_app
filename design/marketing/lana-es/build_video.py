"""Spanish Lana character ad. Uses unmodified app sprites and real ES footage.

Run with --preview for proof frames, or without arguments for both MP4 versions.
"""
from pathlib import Path
from functools import lru_cache
import argparse
import math
import subprocess
import wave

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
SOURCE=HERE.parent/'video-v1/frames'
W,H,FPS,SECONDS=1080,1920,30,16
CREAM='#fff6e6'
BERRY='#773b50'
ROSE='#efd2d1'
TEAL='#226962'
INK='#393437'
FONTS=Path('/System/Library/Fonts/Supplemental')


@lru_cache(maxsize=50)
def font(size,style='rounded'):
    names={'rounded':'Arial Rounded Bold.ttf','sans':'Arial.ttf','serif':'Georgia.ttf','italic':'Georgia Italic.ttf'}
    path=ROOT/'assets/fonts/PixelifySans.ttf' if style=='pixel' else FONTS/names[style]
    return ImageFont.truetype(str(path),size)


def text(im,words,x,y,size=50,color=INK,style='rounded',center=False,spacing=1.07,maxw=885):
    d=ImageDraw.Draw(im);f=font(size,style)
    for j,line in enumerate(words.split('\n')):
        w=d.textlength(line,font=f)
        if w>maxw:raise ValueError(f'Text too wide ({w:.0f}): {line}')
        px=x-w/2 if center else x
        if px<0 or px+w>W:raise ValueError(f'Text outside frame: {line}')
        d.text((round(px),round(y+j*size*spacing)),line,font=f,fill=color,anchor='lt')


def ease(t):
    t=min(1,max(0,t));return t*t*(3-2*t)


def pill(im,words,x,y,w,h,bg,fg,size=35):
    ImageDraw.Draw(im).rounded_rectangle((x,y,x+w,y+h),radius=h/2,fill=bg)
    text(im,words,x+w/2,y+(h-size)/2-2,size,fg,center=True,maxw=w-38)


def star(im,x,y,r,color):
    ImageDraw.Draw(im).polygon([(x,y-r),(x+r*.23,y-r*.23),(x+r,y),(x+r*.23,y+r*.23),
        (x,y+r),(x-r*.23,y+r*.23),(x-r,y),(x-r*.23,y-r*.23)],fill=color)


def base(t,dark=False):
    bg,accent=(BERRY,'#985c70') if dark else (CREAM,'#ebd7c5')
    im=Image.new('RGB',(W,H),bg);d=ImageDraw.Draw(im)
    d.arc((645,-180,1375,550),0,360,fill=accent,width=3)
    d.arc((-350,1510,300,2160),0,360,fill=accent,width=3)
    # Stitch-like edge detail is part of the ad layout, not app UI.
    for y in range(590,1540,35):
        d.line((1015,y,1015,y+12),fill=accent,width=3)
    text(im,'Sobrita',82,152,49,CREAM if dark else BERRY,'pixel')
    text(im,'UNA APP PARA TUS GASTOS',85,221,28,CREAM if dark else BERRY,'sans')
    return im


@lru_cache(maxsize=3)
def sprite_frames(motion):
    count=8 if motion=='idle' else 12
    sheet=Image.open(ROOT/'assets/characters/alpaca'/f'{motion}-{count}.png').convert('RGBA')
    assert sheet.size==(320*count,360)
    frames=[sheet.crop((320*i,0,320*(i+1),360)) for i in range(count)]
    boxes=[s.getbbox() for s in frames]
    box=(min(b[0] for b in boxes),min(b[1] for b in boxes),max(b[2] for b in boxes),max(b[3] for b in boxes))
    return [s.crop(box) for s in frames]


@lru_cache(maxsize=180)
def scaled_sprite(motion,index,w,h):
    art=sprite_frames(motion)[index]
    scale=min(w/art.width,h/art.height)
    return art.resize((round(art.width*scale),round(art.height*scale)),Image.Resampling.NEAREST)


def lana(im,t,motion,cx,feet,w,h):
    if motion=='idle':index=int((t%2.8)/2.8*8)
    elif motion=='positive':index=int((t%4)/4*12)
    else:index=min(11,int(max(0,t)/2.2*12))
    art=scaled_sprite(motion,index,w,h)
    im.paste(art,(round(cx-art.width/2),round(feet-art.height)),art)


@lru_cache(maxsize=12)
def frame(index):
    return Image.open(SOURCE/f'{index:05}.png').convert('RGB')


def app(im,index,crop,target):
    x,y,w,h=target
    sx,sy,ex,ey=crop;sw,sh=ex-sx,ey-sy
    aspect=w/h
    if sw/sh>aspect:sx+=(sw-sh*aspect)/2;sw=sh*aspect
    else:sy+=(sh-sw/aspect)/2;sh=sw/aspect
    art=frame(index).crop((round(sx),round(sy),round(sx+sw),round(sy+sh))).resize((w,h),Image.Resampling.LANCZOS)
    mask=Image.new('L',(w,h),0)
    ImageDraw.Draw(mask).rounded_rectangle((0,0,w-1,h-1),radius=28,fill=255)
    im.paste(art,(x,y),mask)


def render(n):
    t=n/FPS
    if t<4:
        im=base(t);d=ImageDraw.Draw(im)
        text(im,'Tu lana,\ncon Lana.',79,328,121,BERRY,spacing=1.01)
        d.rounded_rectangle((82,649,925,1459),radius=85,fill=ROSE)
        d.ellipse((213,1341,794,1396),fill='#d6acac')
        lana(im,t,'positive',504,1384,661,681)
        for j,(x,y) in enumerate([(163,866),(852,798),(856,1260)]):
            star(im,x,y+6*math.sin(t*2+j),17,BERRY)
        text(im,'Una pequeña compañía para tu dinero.',83,1527,39,BERRY,'sans')
    elif t<6.6:
        u=t-4
        im=base(t,True);d=ImageDraw.Draw(im)
        text(im,'Una alpaca.\nMucha ternura.',80,331,94,CREAM,spacing=1.06)
        d.ellipse((87,676,925,1514),fill=ROSE)
        d.ellipse((288,1367,735,1411),fill='#c798a0')
        lana(im,u,'success',508,1395,626,699)
        pill(im,'LANA',320,1486,371,90,CREAM,BERRY,48)
    elif t<10.2:
        u=t-6.6
        im=base(t);d=ImageDraw.Draw(im)
        text(im,'Anota tus\ngastos.',80,328,110,BERRY,spacing=1.03)
        if u<1.8:
            ix=138+min(23,round(u/1.8*23));crop=(228,405,860,1211)
        else:
            ix=174+min(11,round((u-1.8)/1.8*11));crop=(228,876,860,1682)
        d.rounded_rectangle((78,609,930,1686),radius=38,fill=TEAL)
        app(im,ix,crop,(98,629,812,1037))
        pill(im,'Ejemplo: $85 MXN',417,559,490,73,TEAL,CREAM,35)
        text(im,'Pantalla real · Datos de ejemplo',83,1718,30,BERRY,'sans')
    elif t<12.8:
        u=t-10.2
        im=base(t);d=ImageDraw.Draw(im)
        text(im,'Tu rincón.\nTu compañía.',80,328,99,BERRY,spacing=1.07)
        d.rounded_rectangle((73,604,943,1462),radius=42,fill=ROSE)
        ix=474+min(35,round(u/2.6*35))
        app(im,ix,(229,495,851,1087),(94,625,828,788))
        pill(im,'Lana, en tu espacio.',167,1390,682,96,TEAL,CREAM,43)
        text(im,'Así se ve dentro de Sobrita.',83,1540,38,BERRY,'sans')
    else:
        u=t-12.8
        im=base(t,True);d=ImageDraw.Draw(im)
        text(im,'Tu presupuesto,\ncon compañía.',80,325,87,CREAM,spacing=1.08)
        d.rounded_rectangle((82,603,925,1270),radius=65,fill=CREAM)
        d.ellipse((151,1170,553,1204),fill='#e1cfb8')
        lana(im,u,'idle',348,1194,377,508)
        text(im,'Lana',747,815,116,BERRY,'pixel',True,maxw=360)
        text(im,'Tu nueva\ncompañera.',747,970,37,BERRY,'sans',True,spacing=1.15,maxw=350)
        pill(im,'Síguenos para el lanzamiento',82,1350,843,112,ROSE,BERRY,46)
        text(im,'Android · En pruebas',84,1501,34,CREAM,'sans')
        text(im,'Lana se vende por separado.',84,1558,32,CREAM,'sans')
    return im


def preview():
    proof=HERE/'proofs';proof.mkdir(exist_ok=True)
    times=[0,1.2,2.7,4.7,5.8,6.9,8.9,10.8,12.2,13.3,14.2,15.7]
    contact=Image.new('RGB',(6*216,2*410),CREAM)
    for i,t in enumerate(times):
        im=render(round(t*FPS));im.save(proof/f'{t:04.1f}s.jpg',quality=94)
        contact.paste(im.resize((216,384)),((i%6)*216,(i//6)*410))
        ImageDraw.Draw(contact).text(((i%6)*216+8,(i//6)*410+390),f'{t:.1f}s',fill=BERRY)
    contact.save(HERE/'review-contact-sheet.jpg',quality=95)
    render(36).save(HERE/'sobrita-lana-cover.jpg',quality=96)
    print('Spanish Lana proof frames ready.',flush=True)


def music():
    sr=48000;audio=np.zeros((sr*SECONDS,2));rng=np.random.default_rng(60610)
    def add(a,start,pan=0):
        at=round(sr*start)
        if at>=len(audio):return
        end=min(at+len(a),len(audio));a=a[:end-at]
        audio[at:end,0]+=a*np.sqrt((1-pan)/2)
        audio[at:end,1]+=a*np.sqrt((1+pan)/2)
    def note(midi,start,vol=.08,duration=.85,soft=False,pan=0):
        tt=np.arange(round(duration*sr))/sr;freq=440*2**((midi-69)/12)
        signal=np.sin(2*np.pi*freq*tt)+.12*np.sin(2*np.pi*freq*2*tt)
        signal*=np.exp(-tt*(2.4 if soft else 6))*np.minimum(tt/(.025 if soft else .006),1)
        signal*=np.minimum((duration-tt)/.06,1)*vol
        add(signal,start,pan)
    # Original eight-bar theme at 120 BPM, with alternating music-box voices.
    bars=[[77,81,84,81],[79,81,86,84],[81,77,74,77],[79,76,72,76],
          [77,81,84,89],[86,84,81,79],[77,74,77,81],[79,77,76,77]]
    roots=[53,50,46,48,53,50,46,53]
    for b,pitches in enumerate(bars):
        for beat,pitch in enumerate(pitches):
            at=b*2+beat*.5
            note(pitch,at,.088 if beat%2==0 else .06,pan=(-.22 if beat%2 else .22))
            if beat%2==0:
                note(roots[b],at,.055,1.5,True)
                note(roots[b]+7,at+.022,.026,1.25,True)
            else:
                tt=np.arange(round(sr*.07))/sr
                add(rng.normal(0,1,len(tt))*np.exp(-tt*80)*.013,at)
    for at in [1.45,4,6.6,8.4,10.2,12.8]:
        note(89,at,.06,.3);note(96,at+.07,.045,.25)
    dry=audio.copy()
    for delay,gain in [(.12,.10),(.26,.065)]:
        k=round(sr*delay);audio[k:]+=dry[:-k,::-1]*gain
    audio*=np.minimum(np.arange(len(audio))/(sr*.035),1)[:,None]
    audio*=np.minimum(np.arange(len(audio))[::-1]/(sr*.6),1)[:,None]
    audio*=.57/max(np.abs(audio).max(),.01)
    path=HERE/'original-lana-theme.wav'
    with wave.open(str(path),'wb') as f:
        f.setnchannels(2);f.setsampwidth(2);f.setframerate(sr)
        f.writeframes((audio*32767).astype('<i2').tobytes())
    return path


def encode():
    audio=music();path=HERE/'sobrita-lana-es-16s.mp4'
    cmd=['ffmpeg','-y','-hide_banner','-loglevel','warning','-f','rawvideo','-pixel_format','rgb24',
        '-video_size',f'{W}x{H}','-framerate',str(FPS),'-i','pipe:0','-i',str(audio),
        '-map','0:v:0','-map','1:a:0','-c:v','libx264','-threads','4','-preset','medium','-crf','18',
        '-pix_fmt','yuv420p','-af','loudnorm=I=-18:TP=-2:LRA=7','-c:a','aac','-b:a','192k',
        '-ar','48000','-t',str(SECONDS),'-movflags','+faststart','-metadata','title=Sobrita — Tu lana, con Lana',str(path)]
    proc=subprocess.Popen(cmd,stdin=subprocess.PIPE)
    try:
        for n in range(FPS*SECONDS):
            proc.stdin.write(render(n).tobytes())
            if n%120==0:print(f'Rendered {n}/{FPS*SECONDS}',flush=True)
    finally:proc.stdin.close()
    if proc.wait():raise RuntimeError('FFmpeg render failed')
    subprocess.run(['ffmpeg','-y','-v','error','-i',str(path),'-map','0:v:0','-c:v','copy','-an',
        '-movflags','+faststart',str(HERE/'sobrita-lana-es-16s-silent.mp4')],check=True)
    print('Both Spanish Lana videos complete.',flush=True)


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--preview',action='store_true');args=p.parse_args()
    preview()
    if not args.preview:encode()
