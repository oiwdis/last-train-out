"""Generate the original cutout tree atlas and tileable density field used beside the route."""
from pathlib import Path
import math
import random

import numpy as np
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / 'assets/environment'


def tree(seed, low):
    rng = random.Random(seed)
    limbs, leaves = [], []

    def branch(base, direction, length, radius, level):
        direction = direction / np.linalg.norm(direction)
        tip = base + length * direction
        limbs.append((base, tip, radius, rng.uniform(.7, 1.15)))
        if level < 1:
            for _ in range(70):
                sample = tip + np.array([rng.gauss(0,.23),rng.gauss(0,.2),rng.gauss(0,.22)])
                leaves.append((sample, rng.uniform(.025,.08), rng.uniform(.64,1.22)))
            return
        for i in range(3 if level < 4 else 4):
            yaw = rng.uniform(0,2*math.pi) + i*2.4
            bend = np.array([math.cos(yaw), rng.uniform(.16,1.0), math.sin(yaw)])
            twig = direction*.55 + bend*rng.uniform(.72,1.28)
            branch(base+(tip-base)*rng.uniform(.47,.99),twig,length*rng.uniform(.58,.84),radius*.54,level-1)

    branch(np.zeros(3),np.array([.06,1.,.03]),1.7 if low else 3.0,.075 if low else .115,4)
    if low:
        branch(np.array([.16,.05,0]),np.array([.65,.8,-.1]),1.45,.06,3)
    all_points = np.array([p for p,_,_ in leaves] + [np.zeros(3)])
    scale = min(475/(np.ptp(all_points[:,0])+.22),477/(all_points[:,1].max()+.2))
    # Keep each trunk planted at the center of its card.
    scale = min(scale,245/max(abs(all_points[:,0].min()),all_points[:,0].max()))
    image = Image.new('RGBA',(512,512))
    draw = ImageDraw.Draw(image)
    project = lambda p: (256+p[0]*scale,507-p[1]*scale)
    for a,b,r,v in sorted(limbs,key=lambda l:l[1][2]):
        draw.line([project(a),project(b)],fill=tuple(int(c*v) for c in (92,83,62))+(255,),width=max(1,round(2*r*scale)))
    top = all_points[:,1].max()
    for p,r,v in sorted(leaves,key=lambda v:v[0][2]):
        x,y=project(p); radius=max(.65,r*scale)
        light=v*(.72+.23*p[1]/top+.08*math.sin(p[0]*2.5)+.035*p[2])
        base = (91,103,61) if not low else (104,110,71)
        color=tuple(round(c*light) for c in base)+(255,)
        draw.ellipse((x-radius,y-radius*.55,x+radius*.65,y+radius*.63),fill=color)
    return image


def fog_field(seed):
    rng = np.random.default_rng(seed)
    n = 256
    frequency = np.fft.fftfreq(n)*n
    radius = frequency[:,None]**2 + frequency[None,:]**2
    noise = np.fft.fft2(rng.normal(size=(n,n)))
    field = np.fft.ifft2(noise*(1+radius/14)**(-.99)).real
    return np.clip((field-field.mean())/(field.std()*5)+.5,0,1)


if __name__ == '__main__':
    atlas = Image.new('RGBA',(1024,1024))
    for i in range(4):
        atlas.paste(tree(37+i*81,i>=2),((i%2)*512,(i//2)*512))
    atlas.save(OUT/'railway_copse.png',optimize=True)
    field = np.stack([fog_field(2026),fog_field(41),fog_field(1950)],axis=2)
    Image.fromarray(np.uint8(np.round(field*255))).save(OUT/'fog_density.png',optimize=True)
