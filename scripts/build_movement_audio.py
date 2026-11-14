"""Deterministic layered movement Foley, 3 takes per material. No external samples."""
import math, random, struct, wave
from pathlib import Path
RATE=24000
OUT=Path(__file__).resolve().parents[1]/'assets/audio'
PROFILES={'boots':(.18,90),'armor':(.22,75),'bones':(.22,170),'shuffle':(.30,65),'hooves':(.27,100),'feathers':(.38,48),'leather':(.36,42),'spectral':(.48,260),'stone':(.27,48),'wood':(.32,80),'slither':(.32,55),'fire':(.40,95),'paws':(.20,65),'giant':(.28,36)}
for index,(name,(duration,freq)) in enumerate(PROFILES.items()):
 for take in range(3):
  rng=random.Random(1981+index*7+take)
  samples=[];low=0.;prev=0.
  freq*=1.01 if take else 1
  for i in range(int(RATE*duration)):
   t=i/RATE;u=t/duration;n=rng.uniform(-1,1);low=.94*low+.06*n;high=n-prev;prev=n
   env=(1-math.exp(-t*700))*math.exp(-t*25)
   thud=math.sin(2*math.pi*(freq*t-25*t*t))*env
   v=.35*thud+.25*low*env
   if name in ['feathers','leather']:
    sweep=math.sin(math.pi*u)**2
    v=low*sweep*2.0+high*sweep*(.035 if name=='feathers' else .015)+.12*math.sin(2*math.pi*freq*t)*sweep
   elif name=='spectral':
    env=math.sin(math.pi*u)**2
    v=(.12*math.sin(2*math.pi*freq*t)+.07*math.sin(2*math.pi*freq*1.498*t)+low*.3)*env
   elif name=='fire': v=(low*1.6+high*.04)*math.sin(math.pi*u)**2
   elif name=='slither': v=(low*1.5+high*.025)*math.sin(math.pi*u)**2
   elif name=='shuffle': v=thud*.15+low*1.2*math.sin(math.pi*u)**2
   elif name=='armor':
    v+=sum(math.sin(2*math.pi*f*t)*math.exp(-t*48) for f in [930,1433,2180])*.055
   elif name=='bones':
    v=.13*thud+sum(math.sin(2*math.pi*f*t)*math.exp(-t*65) for f in [480,770,1310])*.12
   elif name=='wood': v+=.2*math.sin(2*math.pi*220*t)*math.exp(-t*28)+low*.6*math.exp(-t*6)
   elif name=='stone': v=.7*thud+low*.8*math.exp(-t*15)
   elif name=='giant': v=.85*thud+low*.6*math.exp(-t*12)
   elif name=='hooves':
    v=.5*thud+.10*math.sin(2*math.pi*650*t)*math.exp(-t*65)
    if t>.075:
     x=t-.075;v+=.26*math.sin(2*math.pi*130*x)*math.exp(-x*40)
   elif name=='paws': v=.35*thud+low*.45*env
   v*=min(1,(duration-t)*250)
   samples.append(struct.pack('<h',int(max(-.95,min(.95,v))*26000)))
  with wave.open(str(OUT/f'move-{name}-{take}.wav'),'wb') as w:
   w.setparams((1,2,RATE,0,'NONE','not compressed'));w.writeframes(b''.join(samples))
print('Generated 42 movement cues across 14 materials')
