import json
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
p=Path('docs/validation/milestone35/native-final/performance')
d=json.loads((p/'integration-matrix.json').read_text())
locations=list(dict.fromkeys(r['location'] for r in d['results']))
colors=['#317a64','#d09738','#ac4955']
fig,axes=plt.subplots(2,1,figsize=(13,8),sharex=True,layout='constrained')
x=np.arange(len(locations));w=.24
for i,preset in enumerate(['Low','Medium','High']):
 steady=[next(r for r in d['results'] if r['location']==loc and r['preset']==preset and r['stage']=='steady') for loc in locations]
 worst=[max(r['worst_ms'] for r in d['results'] if r['location']==loc and r['preset']==preset) for loc in locations]
 axes[0].bar(x+(i-1)*w,[r['p99_ms'] for r in steady],w,color=colors[i],label=preset)
 axes[1].bar(x+(i-1)*w,worst,w,color=colors[i])
 for j,v in enumerate(worst):
  if v>=130:axes[1].text(j+(i-1)*w,v*1.10,f'{v:.0f}',ha='center',va='bottom',fontsize=8,rotation=90 if v<200 else 0)
axes[0].set_title('Steady p99 — 600 sampled frames per case',loc='left',fontsize=12)
axes[0].set_ylabel('Frame interval (ms)');axes[0].legend(ncol=3,frameon=False,loc='upper right')
axes[0].axhline(33.333,color='#666',ls='--',lw=.8);axes[0].text(11.5,33.7,'33.3 ms',ha='right',fontsize=8,color='#555')
axes[1].set_title('Worst frame across entry and steady samples — logarithmic scale',loc='left',fontsize=12)
axes[1].set_yscale('log');axes[1].set_ylim(10,5000);axes[1].set_ylabel('Worst interval (ms)')
labels=['Harlow','Warehouse A','Warehouse B','Cab','Passenger car','Curve','Ashford','Workshop','Blackwater','Near fog','Inside fog','Results']
axes[1].set_xticks(x,labels,rotation=30,ha='right')
for ax in axes:
 ax.set_axisbelow(True);ax.grid(axis='y',alpha=.18);ax.spines[['top','right']].set_visible(False)
fig.suptitle('Milestone 3.5 • hosted Apple M1 Virtual / Vulkan • 960 × 540 windowed\nNot a physical 2020 M1 fullscreen result',fontsize=14)
fig.savefig(p/'frame-time-tails.png',dpi=150)
