"""15-second social cut, Brazilian Portuguese, from freshly captured Flutter footage.

Source frames come from tool/render_promo_video_pt_test.dart (app in pt, BRL).

Uses only existing app footage, typography, camera reframing and original audio.
Run with --preview for proof frames, or with no arguments for both MP4 variants.
"""
from pathlib import Path
from functools import lru_cache
import json
import math
import subprocess
import sys
import wave
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
SOURCE = HERE / 'source'
AUDIO_SOURCE = HERE.parent / 'video-v1'
W, H, FPS, DURATION = 1080, 1920, 30, 15
INK = '#23463e'
PAPER = '#faf5e9'
TEAL = '#126d62'
FONT_DIR = Path('/System/Library/Fonts/Supplemental')

@lru_cache(maxsize=30)
def font(size, bold=True, pixel=False):
    path = (HERE.parents[2]/'assets/fonts/PixelifySans.ttf') if pixel else FONT_DIR / ('Arial Rounded Bold.ttf' if bold else 'Arial.ttf')
    return ImageFont.truetype(str(path), size)

@lru_cache(maxsize=20)
def source_frame(index):
    return Image.open(SOURCE/'frames'/f'{index:05}.png').convert('RGB')

def ease(x):
    x = max(0, min(1, x))
    return x*x*(3-2*x)

def shot(canvas, index, crop, target, radius=0):
    """Uniform scale of a crop, never stretching the app UI."""
    x, y, w, h = target
    sx, sy, sw, sh = crop
    ratio = w/h
    if sw/sh > ratio:
        sx += (sw-sh*ratio)/2
        sw = sh*ratio
    else:
        sy += (sh-sw/ratio)/2
        sh = sw/ratio
    layer = source_frame(index).crop((round(sx),round(sy),round(sx+sw),round(sy+sh))).resize((w,h),Image.Resampling.LANCZOS)
    if radius:
        mask=Image.new('L',(w,h),0)
        ImageDraw.Draw(mask).rounded_rectangle((0,0,w-1,h-1),radius,fill=255)
        canvas.paste(layer,(x,y),mask)
    else:
        canvas.paste(layer,(x,y))

def text(canvas, lines, x, y, size, fill=INK, center=False, pixel=False, spacing=1.12, bold=True):
    draw=ImageDraw.Draw(canvas)
    f=font(size,bold,pixel)
    for j,line in enumerate(lines.split('\n')):
        width=draw.textlength(line,font=f)
        px=x-width/2 if center else x
        draw.text((round(px),round(y+j*size*spacing)),line,font=f,fill=fill,anchor='lt')

def chip(canvas,label,x,y,w=None,fill=TEAL,size=35,h=66,pad=60):
    # Sized to its label when no width is given: Portuguese runs longer.
    if w is None:
        w=round(ImageDraw.Draw(canvas).textlength(label,font=font(size))+2*pad)
    ImageDraw.Draw(canvas).rounded_rectangle((x,y,x+w,y+h),radius=h//2,fill=fill)
    text(canvas,label,x+w/2,y+(h-size)/2-1,size,fill='white',center=True)

def base():
    im=Image.new('RGB',(W,H),PAPER)
    d=ImageDraw.Draw(im)
    d.ellipse((730,-150,1380,450),fill='#e5ecdc')
    d.ellipse((-400,1380,360,2140),fill='#eee2cc')
    return im

def headline(im,title,subtitle=None):
    text(im,'Sobrita',82,144,43,pixel=True)
    text(im,title,82,242,72 if title.startswith('Fiz um') else 76,spacing=1.04)
    if subtitle:
        text(im,subtitle,84,350,36,bold=False,fill='#547166')

def render(n):
    t=n/FPS
    im=base()
    if t < 3:
        # The first frame already contains Michi; a gentle pullback reveals home.
        k=ease(t/3)
        ix=9+n
        crop=(280-30*k,1040-90*k,520+60*k,700+80*k)
        shot(im,min(ix,103),crop,(0,480,1080,1440))
        headline(im,'Fiz um app de orçamento')
        chip(im,'com um gatinho.',82,346,size=68,h=112)
    elif t < 6:
        headline(im,'Controle seus gastos.','R$ 85. Anotado.')
        if t < 4.2:
            ix=138+round((t-3)/1.2*23)
            crop=(230,405,620,790)
        elif t < 4.8:
            ix=174+round((t-4.2)/.6*17)
            crop=(230,880,620,790)
        else:
            ix=220+round((t-4.8)/1.2*34)
            crop=(228,391,624,790)
        shot(im,ix,crop,(68,470,850,1083),radius=28)
        chip(im,'Dados de exemplo',444-(285+2*60)//2,1580,fill=INK,size=32,h=64)
    elif t < 10:
        headline(im,'Deixe do seu jeito.','Seu cantinho aconchegante.')
        if t < 9.4:
            ix=255+round((t-6)/3.4*89)
        else:
            ix=min(353,345+round((t-9.4)/.6*8))
        # Retain the real room, placement actions and first drawer row.
        shot(im,ix,(222,499,638,970),(64,455,855,1300),radius=28)
    elif t < 12:
        headline(im,'Escolha seu\ncompanheiro.')
        u=t-10
        if u < .67:
            ix=393+round(u/.67*20)
            name='Michi'
        elif u < 1.34:
            ix=415+round((u-.67)/.67*24)
            name='Miru'
        else:
            ix=442+round((u-1.34)/.66*27)
            name='Tranqui'
        shot(im,ix,(224,510,634,582),(40,507,916,842),radius=30)
        chip(im,name,275,1364,430,size=54,h=86)
        text(im,'Alguns personagens são pagos.',490,1490,33,center=True,bold=False)
    else:
        # Closing frame keeps the same animated companion and clear launch CTA.
        ix=510+min(89,n-360)
        shot(im,ix,(240,1060,600,550),(0,594,1080,990))
        text(im,'Sobrita',81,225,154,pixel=True)
        text(im,'Orçamento com mais carinho.',84,414,53)
        chip(im,'GRÁTIS / ANDROID',85,508,fill=INK,size=33,h=65)
        d=ImageDraw.Draw(im)
        d.rounded_rectangle((77,1372,920,1536),radius=33,fill=TEAL)
        text(im,'Baixe grátis\nno Google Play.',498,1398,52,fill='white',center=True,spacing=1.13)
    return im

PROOF_TIMES=[0,.8,2.4,3.35,4.5,5.6,6.1,7.9,9.7,10.2,10.9,11.6,12.5,14.6]

def proofs():
    folder=HERE/'proofs'
    folder.mkdir(exist_ok=True)
    sheet=Image.new('RGB',(7*216,2*410),PAPER)
    for i,t in enumerate(PROOF_TIMES):
        im=render(round(t*FPS))
        im.save(folder/f'{t:04.1f}s.jpg',quality=94)
        sheet.paste(im.resize((216,384)),((i%7)*216,(i//7)*410))
        ImageDraw.Draw(sheet).text(((i%7)*216+8,(i//7)*410+389),f'{t:.1f}s',fill=INK)
    sheet.save(HERE/'review-contact-sheet.jpg',quality=93)
    render(30).save(HERE/'sobrita-social-cover.jpg',quality=95)
    print('Preview frames ready.',flush=True)

def build_audio():
    # The cut keeps the English one's timing to the frame, so its finished
    # mix (music plus the taps) fits as is and needs no numpy here.
    import shutil
    shutil.copyfile(HERE.parent/'social-v2-en'/'sobrita-social-audio.wav', HERE/'sobrita-social-audio.wav')

def build_audio_from_score():
    import numpy as np
    # Reuse our own score with a brisker tempo, retaining natural note pitch.
    subprocess.run(['ffmpeg','-y','-v','error','-i',str(AUDIO_SOURCE/'sobrita-original-music.wav'),'-af','atempo=1.333333,afade=t=out:st=14.5:d=0.5','-t','15','-ar','48000',str(HERE/'music-temp.wav')],check=True)
    with wave.open(str(HERE/'music-temp.wav')) as f:
        rate=f.getframerate()
        music=np.frombuffer(f.readframes(f.getnframes()),dtype='<i2').astype(np.float64).reshape(-1,2)/32768
    audio=np.zeros((rate*15,2))
    length=min(len(music),len(audio))
    audio[:length]=music[:length]*.57
    # Small original UI taps/chimes, quiet enough to keep the cozy tone.
    for sec,pitch in [(3.0,880),(3.28,1046.5),(4.8,1318.5),(7.1,784),(8.5,988),(10,880),(10.67,988),(11.34,1174.7),(12,1318.5)]:
        tt=np.arange(int(rate*.13))/rate
        tone=np.sin(2*np.pi*pitch*tt)*np.exp(-tt*35)*np.minimum(tt/.004,1)*.075
        start=int(sec*rate)
        audio[start:start+len(tone)]+=tone[:,None]
    with wave.open(str(HERE/'sobrita-social-audio.wav'),'wb') as f:
        f.setnchannels(2);f.setsampwidth(2);f.setframerate(rate)
        f.writeframes((np.clip(audio,-.95,.95)*32767).astype('<i2').tobytes())
    (HERE/'music-temp.wav').unlink()

def encode():
    build_audio()
    destination=HERE/'sobrita-tiktok-reels-pt-15s.mp4'
    cmd=['ffmpeg','-y','-hide_banner','-loglevel','warning','-f','rawvideo','-pixel_format','rgb24','-video_size','1080x1920','-framerate','30','-i','pipe:0','-i',str(HERE/'sobrita-social-audio.wav'),'-map','0:v:0','-map','1:a:0','-c:v','libx264','-preset','medium','-crf','18','-pix_fmt','yuv420p','-af','loudnorm=I=-18:TP=-2:LRA=7','-c:a','aac','-b:a','192k','-ar','48000','-t','15','-movflags','+faststart','-metadata','title=Sobrita — Um gatinho para o seu orçamento',str(destination)]
    proc=subprocess.Popen(cmd,stdin=subprocess.PIPE)
    try:
        for n in range(FPS*DURATION):
            proc.stdin.write(render(n).tobytes())
            if n%90==0:print(f'Rendered {n}/{FPS*DURATION} frames',flush=True)
    finally:
        proc.stdin.close()
    if proc.wait():raise RuntimeError('FFmpeg encoding failed')
    subprocess.run(['ffmpeg','-y','-v','error','-i',str(destination),'-map','0:v:0','-c:v','copy','-an','-movflags','+faststart',str(HERE/'sobrita-tiktok-reels-pt-15s-silent.mp4')],check=True)
    print(destination,flush=True)

if __name__=='__main__':
    HERE.mkdir(parents=True,exist_ok=True)
    proofs()
    if '--preview' not in sys.argv:
        encode()
