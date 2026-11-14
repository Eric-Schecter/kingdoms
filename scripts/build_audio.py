"""Original deterministic folk battle loop and layered combat foley; stdlib only."""
import math, random, wave, array
from pathlib import Path
R=22050
out=Path(__file__).resolve().parents[1]/'assets/audio'
rng=random.Random(17)
def save(name,data,loop=False):
 peak=max(max(map(abs,data)),.001)
 gain=min(1,.85/peak)
 pcm=array.array('h',(int(max(-1,min(1,x*gain))*32767) for x in data))
 with wave.open(str(out/(name+'.wav')),'wb') as w:
  w.setnchannels(1);w.setsampwidth(2);w.setframerate(R);w.writeframes(pcm.tobytes())
def note(buf,start,dur,midi,amp,voice):
 f=440*2**((midi-69)/12);base=int(start*R)
 for k in range(int(dur*R)):
  t=k/R;env=min(1,t/.018)*min(1,(dur-t)/.08)
  if voice=='pluck': env*=math.exp(-t*4);v=math.sin(2*math.pi*f*t)+.3*math.sin(4*math.pi*f*t)
  elif voice=='reed': v=math.sin(2*math.pi*f*t+.015*math.sin(2*math.pi*5*t))+.18*math.sin(6*math.pi*f*t)
  else: v=math.sin(2*math.pi*f*t)+.15*math.sin(4*math.pi*f*t)
  buf[(base+k)%len(buf)]+=v*amp*env
beat=60/104;duration=beat*64
buf=[0.] * int(duration*R)
chords=[(50,57,62,65),(46,53,58,62),(48,55,60,64),(45,52,57,61)]
melodies=[[74,77,76,74,69,72,74,69],[70,74,77,74,72,70,69,65],[72,76,79,76,74,72,67,72],[73,76,81,79,76,73,69,73]]
for bar in range(16):
 chord=chords[bar%4]
 for b in range(8):note(buf,(bar*4+b*.5)*beat,beat*.7,chord[b%4],.105,'pluck')
 for b in [0,2]:note(buf,(bar*4+b)*beat,beat*1.6,chord[0]-12,.12,'bass')
 for b,m in enumerate(melodies[bar%4]):note(buf,(bar*4+b*.5)*beat,beat*.43,m+(0 if bar<8 else -12),.11,'reed')
 for b in range(4):
  start=int((bar*4+b)*beat*R)
  for k in range(int(.15*R)):
   t=k/R;env=math.exp(-t*28)
   drum=math.sin(2*math.pi*(95*t-110*t*t)) if b%2==0 else rng.uniform(-1,1)*.5
   buf[(start+k)%len(buf)]+=drum*env*.14
# Circular room reflection keeps the loop boundary continuous.
wet=buf[:]
for delay,gain in [(.093,.18),(.173,.11)]:
 d=int(delay*R)
 for i in range(len(buf)):wet[i]+=buf[(i-d)%len(buf)]*gain
save('storybook-battle',wet)
for name,dur in [('swing',.22),('steel',.32),('arrow',.24),('magic',.55),('claw',.28),('impact',.28),('bone',.27)]:
 data=[];smooth=0
 for k in range(int(dur*R)):
  t=k/R;u=t/dur;n=rng.uniform(-1,1);smooth=.7*smooth+.3*n
  if name=='swing':v=smooth*math.sin(math.pi*u)**1.4*.8
  elif name=='steel':v=(math.sin(2*math.pi*1450*t)+.6*math.sin(2*math.pi*2243*t))*math.exp(-22*t)*.26+n*math.exp(-65*t)*.3
  elif name=='arrow':v=(smooth*.6+math.sin(2*math.pi*(620*t-700*t*t))*.22)*math.exp(-13*t)
  elif name=='magic':v=(math.sin(2*math.pi*(420*t+540*t*t))+.35*math.sin(2*math.pi*840*t))*math.sin(math.pi*u)*.22
  elif name=='claw':v=n*math.exp(-18*t)*.3+math.sin(2*math.pi*130*t)*math.exp(-13*t)*.25
  elif name=='bone':v=n*math.exp(-35*t)*.45+math.sin(2*math.pi*780*t)*math.exp(-30*t)*.15
  else:v=(math.sin(2*math.pi*(110*t-80*t*t))*.5+smooth*.4)*math.exp(-17*t)
  data.append(v*min(1,t/.002)*min(1,(dur-t)/.01))
 save(name,data)
print('Built original 36.9s loop and 7 combat sounds')

# Revised stereo combat layer: transient + body + material + short room tail.
for name in ['swing','steel','arrow','magic','magic-impact','claw','impact','bone']:
 dur=1.15 if name=='magic-impact' else .85 if name=='magic' else .65
 data=[];low=0.;phase=0.
 for k in range(int(dur*R)):
  t=k/R;n=rng.uniform(-1,1);low=.88*low+.12*n;high=n-low
  if name=='swing':
   env=math.exp(-((t-.10)/.065)**2)
   v=(low*2.0+high*.14)*env+math.sin(2*math.pi*(170*t-220*t*t))*.12*env
  elif name in ['impact','claw','bone','steel']:
   bass=math.sin(2*math.pi*(88*t-65*t*t))*math.exp(-t*22)*.5
   crack=high*math.exp(-t*85)*.7
   if name=='steel': material=sum(math.sin(2*math.pi*f*t)*math.exp(-t*d) for f,d in [(1123,17),(1877,24),(2911,31)])*.14
   elif name=='bone': material=high*sum(math.exp(-((t-c)/.006)**2) for c in [.016,.045,.083])*.22
   elif name=='claw': material=high*math.exp(-t*18)*.22
   else: material=low*math.exp(-t*14)*.8
   v=bass+crack+material
  elif name=='arrow':
   v=high*math.exp(-t*65)*.5+math.sin(2*math.pi*(310*t-170*t*t))*math.exp(-t*23)*.28+low*math.exp(-((t-.06)/.04)**2)*.7
  elif name=='magic':
   phase+=2*math.pi*(260+700*min(t/.38,1))/R
   env=min(t/.045,1)*math.exp(-t*5)
   v=(math.sin(phase)+.4*math.sin(phase*1.5)+.25*math.sin(phase*2.01))*.24*env+high*.11*env
  else:
   v=math.sin(2*math.pi*(66*t-18*t*t))*math.exp(-t*12)*.55+high*math.exp(-t*55)*.5
   for j,f in enumerate([523.25,622.25,783.99,1046.5]):
    q=t-j*.025
    if q>=0:v+=math.sin(2*math.pi*f*q)*math.exp(-q*5.5)*.12
  data.append(v*min(1,t/.0015)*min(1,(dur-t)/.03))
 pcm=array.array('h')
 for i,v in enumerate(data):
  for channel in range(2):
   sample=v*.82
   for delay,gain in [(.037+channel*.009,.21),(.079-channel*.006,.13),(.137+channel*.012,.08)]:
    d=int(delay*R)
    if i>=d:sample+=data[i-d]*gain
   pcm.append(int(math.tanh(sample*1.2)*.88*32767))
 with wave.open(str(out/(name+'.wav')),'wb') as w:
  w.setnchannels(2);w.setsampwidth(2);w.setframerate(R);w.writeframes(pcm.tobytes())
print('Rebuilt 8 layered stereo combat effects')
