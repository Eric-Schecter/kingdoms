"""Build movement mixes from locally preserved, credited open-licensed recordings.
Requires ffmpeg. No network or API; see assets/audio/sources/CREDITS.md.
"""
import array, math, subprocess, wave
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'assets/audio'; SRC=OUT/'sources'; RATE=44100
cache={}
def read(path):
 path=str(path)
 if path not in cache:
  raw=subprocess.check_output(['ffmpeg','-v','error','-i',path,'-f','f32le','-ac','1','-ar',str(RATE),'-'])
  a=array.array('f');a.frombytes(raw)
  # Preserve initial transient, remove dead air and DC.
  peak=max(abs(v) for v in a); active=[i for i,v in enumerate(a) if abs(v)>peak*.025]
  a=list(a[max(0,active[0]-220):min(len(a),active[-1]+441)]) if active else list(a)
  mean=sum(a)/len(a);a=[v-mean for v in a];peak=max(abs(v) for v in a)
  cache[path]=[v/peak*.75 for v in a]
 return cache[path][:]
def rate(a,speed):
 return [a[min(int(i*speed),len(a)-1)] for i in range(int(len(a)/speed))]
def low(a,alpha=.15):
 out=[];v=0
 for x in a: v+=alpha*(x-v);out.append(v)
 return out
def mix(*layers):
 n=max(len(a)+int(delay*RATE) for a,g,delay in layers);out=[0.]*n
 for a,g,delay in layers:
  offset=int(delay*RATE)
  for i,v in enumerate(a): out[offset+i]+=v*g
 return out
def save(name,a):
 a=a[:int(.65*RATE)]
 # Short natural tails with no hard cut; normalize to consistent peak headroom.
 peak=max(abs(x) for x in a);gain=min(4,.78/max(peak,.001))
 for i in range(len(a)):
  a[i]*=gain*min(1,i/150,(len(a)-i)/650)
 with wave.open(str(OUT/name),'wb') as w:
  w.setparams((1,2,RATE,0,'NONE','not compressed'))
  w.writeframes(array.array('h',[int(max(-.98,min(.98,x))*32767) for x in a]).tobytes())
for take in range(3):
 f=SRC/'fantozzi/Fantozzi-footsteps/flac'
 sand=read(f/f'Fantozzi-SandL{take+1}.flac')
 stone=read(f/f'Fantozzi-StoneL{take+1}.flac')
 h=SRC/'hael/footsteps'
 metal=read(h/('step_metal.ogg' if take==0 else f'step_metal ({take+1}).ogg'))
 cloth=read(h/f'step_cloth{take+1}.ogg')
 leather=read(h/['step_lth1.ogg','step_lth2.ogg','step_lth33.ogg'][take])
 wings=read(SRC/'wings/wings_flap_large.flac')
 start=int([0,1.047,2.094][take]*RATE);flap=wings[start:start+int(.51*RATE)]
 hoof=read(SRC/'horse/grass.mp3')
 hoof=rate(hoof,1+take*.025)
 profiles={
 'boots':mix((sand,.85,0),(leather,.22,.025)),
 'armor':mix((sand,.7,0),(metal,.65,.015),(cloth,.15,.045)),
 'bones':mix((rate(stone,1.3),.65,0),(rate(metal,1.5),.3,.035)),
 'shuffle':mix((rate(sand,.8),.7,0),(cloth,.5,.07)),
 'hooves':mix((hoof,.85,0),(metal,.12,.03)),
 'feathers':mix((rate(flap,1.1),.85,0),(cloth,.2,.04)),
 'leather':mix((rate(flap,.85),.8,0),(rate(leather,.8),.25,.02)),
 'spectral':mix((low(rate(list(reversed(flap)),.9)),.7,0),(low(flap),.25,.12)),
 'stone':mix((rate(stone,.68),.85,0),(rate(metal,.7),.25,.03)),
 'wood':mix((rate(leather,.7),.55,0),(rate(stone,.8),.65,.025)),
 'slither':mix((rate(sand,.75),.6,0),(cloth,.5,.08)),
 'fire':mix((rate(sand,1.35),.5,0),(flap,.45,.03),(rate(cloth,1.2),.35,.09)),
 'paws':mix((low(sand,.3),.85,0),(leather,.15,.02)),
 'giant':mix((rate(stone,.55),.9,0),(rate(sand,.8),.35,.03))}
 for name,a in profiles.items():save(f'move-{name}-{take}.wav',a)
print('Built 42 sample-based movement mixes, peak ceiling -2.1 dBFS')
