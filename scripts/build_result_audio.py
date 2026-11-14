"""Original short victory fanfare and descending defeat cue; no external samples."""
import math, wave, struct
from pathlib import Path
RATE=44100
for name,notes in {
 'victory':[(0,60,.22),(.22,64,.22),(.44,67,.25),(.72,72,1.5),(.72,64,1.5),(.72,67,1.5)],
 'defeat':[(0,60,.65),(.5,56,.65),(1,53,1.6),(1,48,1.6),(1,44,1.6)]}.items():
 samples=[0.0]*int(RATE*3.8)
 for start,key,duration in notes:
  hz=440*2**((key-69)/12)
  for i in range(int(duration*RATE)):
   t=i/RATE
   env=min(1,t/.025)*min(1,(duration-t)/.35)
   tone=sum(math.sin(2*math.pi*hz*h*t)*a for h,a in [(1,1),(2,.28),(3,.12),(4,.04)])
   samples[int(start*RATE)+i]+=tone*env*.15
 dry=samples[:]
 for delay,gain in [(.11,.19),(.23,.12),(.37,.07)]:
  offset=int(delay*RATE)
  for i in range(offset,len(samples)): samples[i]+=dry[i-offset]*gain
 peak=max(abs(v) for v in samples)
 with wave.open(str(Path('assets/audio')/('result-'+name+'.wav')),'wb') as out:
  out.setparams((1,2,RATE,0,'NONE','not compressed'))
  out.writeframes(b''.join(struct.pack('<h',int(v/peak*.72*32767)) for v in samples))
