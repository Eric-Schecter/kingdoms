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

rpg=SRC/'rpg/RPG Sound Pack'
def trim(a,seconds=.35): return a[:int(seconds*RATE)]
for take in range(3):
 suffix='' if take==0 else str(take+1)
 swing=trim(read(rpg/f'battle/swing{suffix}.wav'),.32)
 bite=trim(read(rpg/f'NPC/beetle/bite-small{suffix}.wav'),.22)
 metal=trim(read(rpg/f'inventory/metal-small{take+1}.wav'),.25)
 ring=trim(read(rpg/'inventory/metal-ringing.wav'),.45)
 wood=trim(read(rpg/'inventory/wood-small.wav'),.20)
 magic=trim(read(rpg/'battle/magic1.wav'),.5)
 ground=trim(read(SRC/f'fantozzi/Fantozzi-footsteps/flac/Fantozzi-StoneL{take+1}.flac'),.25)
 body=low(rate(ground,.7),.12)
 profiles={
 'blade':mix((swing,.8,0),(metal,.22,.025)),
 'thrust':mix((rate(swing,1.3),.8,0),(wood,.2,.02)),
 'claw':mix((rate(swing,.8),.55,0),(bite,.5,.025)),
 'heavy':mix((rate(swing,.7),.5,0),(body,.65,.03)),
 'bow':mix((rate(wood,1.7),.6,0),(rate(swing,1.6),.45,.018)),
 'crossbow':mix((metal,.4,0),(rate(wood,1.4),.6,0),(rate(swing,1.7),.4,.025)),
 'holy':mix((rate(ring,1.5),.6,0),(rate(magic,1.2),.35,.02)),
 'arcane':mix((magic,.7,0),(rate(swing,.85),.35,.04)),
 'death':mix((rate(magic,.65),.7,0),(rate(bite,.7),.3,.035)),
 'firebolt':mix((rate(swing,.7),.7,0),(bite,.4,.02),(body,.4,.04)),
 'lightning':mix((rate(metal,1.6),.6,0),(magic,.45,.015),(body,.55,.025)),
 'flesh-hit':mix((bite,.85,0),(body,.65,.005)),
 'metal-hit':mix((metal,.75,0),(ring,.24,.015),(body,.6,0)),
 'bone-hit':mix((rate(wood,1.35),.75,0),(bite,.5,.015)),
 'stone-hit':mix((rate(ground,.7),.9,0),(metal,.25,.02)),
 'magic-hit':mix((body,.8,0),(magic,.45,.01),(ring,.2,.02))}
 for family in ['holy','arcane','death','firebolt','lightning']:
  profiles[family+'-hit']=mix((body,.8,0),(profiles[family],.55,.008))
 for name,a in profiles.items():save(f'combat-{name}-{take}.wav',a)
print('Built 63 CC0-derived attack/release/impact mixes')
