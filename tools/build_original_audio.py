#!/usr/bin/env python3
"""Original synthesized ambience and Foley, deterministic PCM at 22050 Hz."""
import math, random, struct, wave, pathlib
OUT=pathlib.Path(__file__).resolve().parents[1]/'assets/audio';OUT.mkdir(exist_ok=True)
RATE=22050
for name,seconds in [('wind',4),('engine',2),('step',.16),('latch',.19)]:
 rng=random.Random(725);samples=[];low=0
 for i in range(int(RATE*seconds)):
  t=i/RATE;noise=rng.uniform(-1,1);low=.97*low+.03*noise
  if name=='wind':value=low*.5*(.75+.25*math.cos(t*math.tau/seconds))
  elif name=='engine':value=.065*math.sin(t*math.tau*44)+.045*math.sin(t*math.tau*88)+.15*low+.09*noise*max(0,math.sin(t*math.tau*4))**18
  elif name=='step':value=(noise*.2+math.sin(t*math.tau*90)*.24)*math.exp(-t*28)
  else:value=(noise*.24+math.sin(t*math.tau*670)*.15)*math.exp(-t*35)
  fade=min(1,i/150,(RATE*seconds-i)/150);samples.append(struct.pack('<h',int(max(-1,min(1,value*fade))*32767)))
 with wave.open(str(OUT/(name+'.wav')),'wb') as f:f.setparams((1,2,RATE,len(samples),'NONE','not compressed'));f.writeframes(b''.join(samples))
 print(name,len(samples))
